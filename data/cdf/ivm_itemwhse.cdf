[[IVM_ITEMWHSE.ARAR]]
rem --- Get total on Open PO lines

	podet_dev=fnget_dev("POE_PODET")
	dim podet_tpl$:fnget_tpl$("POE_PODET")

	whse$=callpoint!.getColumnData("IVM_ITEMWHSE.WAREHOUSE_ID")
	item$=callpoint!.getColumnData("IVM_ITEMWHSE.ITEM_ID")
	po_qty=0

	read(podet_dev,key=firm_id$+whse$+item$,knum="WHSE_ITEM",dom=*next)

	while 1
		read record (podet_dev,end=*break) podet_tpl$
		if firm_id$<>podet_tpl.firm_id$ break
		if whse$<>podet_tpl.warehouse_id$ break
		if item$<>podet_tpl.item_id$ break
		po_qty = po_qty + (podet_tpl.qty_ordered - podet_tpl.qty_received)
	wend

	callpoint!.setColumnData("<<DISPLAY>>.ON_ORD_PO",str(po_qty))

rem --- Get total on Open SO lines

	opdet_dev=fnget_dev("OPE_ORDDET")
	dim opdet_tpl$:fnget_tpl$("OPE_ORDDET")

	op_qty=0

	read(opdet_dev,key=firm_id$+item$+whse$,knum="AO_ITEM_WH_CUST",dom=*next)

	while 1
		read record (opdet_dev,end=*break) opdet_tpl$
		if firm_id$<>opdet_tpl.firm_id$ break
		if whse$<>opdet_tpl.warehouse_id$ break
		if item$<>opdet_tpl.item_id$ break
		if opdet_tpl.commit_flag$ = "Y"
			op_qty = op_qty + opdet_tpl.qty_ordered
		endif
	wend

	callpoint!.setColumnData("<<DISPLAY>>.COMMIT_SO",str(op_qty))

rem --- Get total on WO Finished Goods (On Order)

	if callpoint!.getDevObject("wo_installed") = "Y"
		womast_dev=fnget_dev("SFE_WOMASTR")
		dim womast_tpl$:fnget_tpl$("SFE_WOMASTR")

		womast_qty=0

		read(womast_dev,key=firm_id$+whse$+item$,knum="AO_WH_ITM_LOC_WO",dom=*next)

		while 1
			read record (womast_dev,end=*break) womast_tpl$
			if firm_id$<>womast_tpl.firm_id$ break
			if whse$<>womast_tpl.warehouse_id$ break
			if item$<>womast_tpl.item_id$ break
			if womast_tpl.wo_status$ = "O"
				womast_qty = womast_qty + (womast_tpl.sch_prod_qty - womast_tpl.qty_cls_todt)
			endif
		wend

		callpoint!.setColumnData("<<DISPLAY>>.ON_ORD_WO",str(womast_qty))
	endif
[[IVM_ITEMWHSE.BDEL]]
rem --- Allow this warehouse to be deleted?

	action$ = "W"
	whse$   = callpoint!.getColumnData("IVM_ITEMWHSE.WAREHOUSE_ID")
	item$   = callpoint!.getColumnData("IVM_ITEMWHSE.ITEM_ID")

	call stbl("+DIR_PGM")+"ivc_deleteitem.aon", action$, whse$, item$, rd_table_chans$[all], status
	if status then callpoint!.setStatus("ABORT")
[[IVM_ITEMWHSE.UNIT_COST.AVAL]]
rem --- Set default costs from unit cost

unit_cost$ = callpoint!.getUserInput()

if num( callpoint!.getColumnData("IVM_ITEMWHSE.LANDED_COST") ) = 0 then
	callpoint!.setColumnData("IVM_ITEMWHSE.LANDED_COST",unit_cost$)
endif

if num( callpoint!.getColumnData("IVM_ITEMWHSE.LAST_PO_COST") ) = 0 then
	callpoint!.setColumnData("IVM_ITEMWHSE.LAST_PO_COST",unit_cost$)
endif

if num( callpoint!.getColumnData("IVM_ITEMWHSE.AVG_COST") ) = 0 then
	callpoint!.setColumnData("IVM_ITEMWHSE.AVG_COST",unit_cost$)
endif

if num( callpoint!.getColumnData("IVM_ITEMWHSE.STD_COST") ) = 0 then
	callpoint!.setColumnData("IVM_ITEMWHSE.STD_COST",unit_cost$)
endif

if num( callpoint!.getColumnData("IVM_ITEMWHSE.REP_COST") ) = 0 then
	callpoint!.setColumnData("IVM_ITEMWHSE.REP_COST",unit_cost$)
endif

callpoint!.setStatus("REFRESH")
[[IVM_ITEMWHSE.ADIS]]
rem --- If select in Physical Intentory, location and cycle can't change

if callpoint!.getColumnData("IVM_ITEMWHSE.SELECT_PHYS") = "Y" then
	callpoint!.setColumnEnabled("IVM_ITEMWHSE.LOCATION",0)
	callpoint!.setColumnEnabled("IVM_ITEMWHSE.PI_CYCLECODE",0)
	call stbl("+DIR_SYP")+"bac_message.bbj","IV_PHY_INV_SELECT",msg_tokens$[all],msg_opt$,table_chans$[all]
else
	callpoint!.setColumnEnabled("IVM_ITEMWHSE.LOCATION",1)
	callpoint!.setColumnEnabled("IVM_ITEMWHSE.PI_CYCLECODE",1)
endif
[[IVM_ITEMWHSE.SAFETY_STOCK.AVAL]]
if num(callpoint!.getUserInput())<0 then callpoint!.setStatus("ABORT")
[[IVM_ITEMWHSE.ORDER_POINT.AVAL]]
if num(callpoint!.getUserInput())<0 then callpoint!.setStatus("ABORT")
[[IVM_ITEMWHSE.MAXIMUM_QTY.AVAL]]
if num(callpoint!.getUserInput())<0 then callpoint!.setStatus("ABORT")
[[IVM_ITEMWHSE.LEAD_TIME.AVAL]]
if num(callpoint!.getUserInput())<0 or fpt(num(callpoint!.getUserInput())) then callpoint!.setStatus("ABORT")
[[IVM_ITEMWHSE.EOQ.AVAL]]
if num(callpoint!.getUserInput())<0 then callpoint!.setStatus("ABORT")
[[IVM_ITEMWHSE.ABC_CODE.AVAL]]
if (callpoint!.getUserInput()<"A" or callpoint!.getUserInput()>"Z") and callpoint!.getUserInput()<>" " callpoint!.setStatus("ABORT")
[[IVM_ITEMWHSE.<CUSTOM>]]
#include std_missing_params.src
[[IVM_ITEMWHSE.BSHO]]
rem --- Open extra tables

num_files=3
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="POE_PODET",open_opts$[1]="OTA"
open_tables$[2]="OPE_ORDDET",open_opts$[2]="OTA"
if callpoint!.getDevObject("wo_installed") = "Y"
	open_tables$[3]="SFE_WOMASTR",open_opts$[3]="OTA"
endif
gosub open_tables

rem --- Get IV params

ivs01_dev=fnget_dev("IVS_PARAMS")
dim ivs01a$:fnget_tpl$("IVS_PARAMS")

ivs01a_key$=firm_id$+"IV00"
find record (ivs01_dev,key=ivs01a_key$,err=std_missing_params) ivs01a$

rem --- Disable Option menu options

if pos(ivs01a.lifofifo$="LF")=0 disable_str$=disable_str$+"LIFO;"; rem --- these are AOPTions, give AOPT code only
if pos(ivs01a.lotser_flag$="LS")=0 disable_str$=disable_str$+"IVM_LSMASTER;"

if disable_str$<>"" call stbl("+DIR_SYP")+"bam_enable_pop.bbj",Form!,enable_str$,disable_str$

rem --- Get item defaults

ivs10d_dev = fnget_dev("IVS_DEFAULTS")
dim ivs10d$:fnget_tpl$("IVS_DEFAULTS")

ivs10d_key$ = firm_id$ + "D"
find record(ivs10d_dev, key=ivs10d_key$, dom=*next) ivs10d$

callpoint!.setTableColumnAttribute("IVM_ITEMWHSE.BUYER_CODE","DFLT",ivs10d.buyer_code$)
callpoint!.setTableColumnAttribute("IVM_ITEMWHSE.AR_DIST_CODE","DFLT",ivs10d.ar_dist_code$)
callpoint!.setTableColumnAttribute("IVM_ITEMWHSE.ABC_CODE","DFLT",ivs10d.abc_code$)
callpoint!.setTableColumnAttribute("IVM_ITEMWHSE.EOQ_CODE","DFLT",ivs10d.eoq_code$)
callpoint!.setTableColumnAttribute("IVM_ITEMWHSE.ORD_PNT_CODE","DFLT",ivs10d.ord_pnt_code$)
callpoint!.setTableColumnAttribute("IVM_ITEMWHSE.SAF_STK_CODE","DFLT",ivs10d.saf_stk_code$)

rem -- if AR dist by item param is not checked, disable the dist code field
if callpoint!.getDevObject("di")<>"Y"
	callpoint!.setColumnEnabled("AR_DIST_CODE",-1)
endif


rem --- disable lot/serial master if this isn't a lotted/serialized item
if str(callpoint!.getDevObject("lot_serial_item"))<>"Y"
	callpoint!.setOptionEnabled("IVM_LSMASTER",0)
else
	callpoint!.setOptionEnabled("IVM_LSMASTER",1)
endif
[[IVM_ITEMWHSE.AOPT-HIST]]
iv_item_id$=callpoint!.getColumnData("IVM_ITEMWHSE.ITEM_ID")
iv_whse_id$=callpoint!.getColumnData("IVM_ITEMWHSE.WAREHOUSE_ID")
rem --- call stbl("+DIR_PGM")+"ivm_itemWhseActivity.aon",
:	gui_dev,
:	Form!,
:	iv_whse_id$,
:	iv_item_id$,                                       
:	table_chans$[all]

rem --- run dir_pgm$+"ivr_itmWhseAct.aon"
call stbl("+DIR_PGM")+"ivr_itmWhseAct.aon",iv_item_id$,iv_whse_id$,table_chans$[all]
[[IVM_ITEMWHSE.AOPT-LIFO]]
cp_item_id$=callpoint!.getColumnData("IVM_ITEMWHSE.ITEM_ID")
cp_whse_id$=callpoint!.getColumnData("IVM_ITEMWHSE.WAREHOUSE_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[4,1]
dflt_data$[1,0]="ITEM_ID_1"
dflt_data$[1,1]=cp_item_id$
dflt_data$[2,0]="ITEM_ID_2"
dflt_data$[2,1]=cp_item_id$
dflt_data$[3,0]="WAREHOUSE_ID_1"
dflt_data$[3,1]=cp_whse_id$
dflt_data$[4,0]="WAREHOUSE_ID_2"
dflt_data$[4,1]=cp_whse_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"IVR_LIFOFIFO",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]
[[IVM_ITEMWHSE.AOPT-IHST]]
cp_item_id$=callpoint!.getColumnData("IVM_ITEMWHSE.ITEM_ID")
cp_whse_id$=callpoint!.getColumnData("IVM_ITEMWHSE.WAREHOUSE_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[4,1]
dflt_data$[1,0]="ITEM_ID_1"
dflt_data$[1,1]=cp_item_id$
dflt_data$[2,0]="ITEM_ID_2"
dflt_data$[2,1]=cp_item_id$
dflt_data$[3,0]="WAREHOUSE_ID_1"
dflt_data$[3,1]=cp_whse_id$
dflt_data$[4,0]="WAREHOUSE_ID_2"
dflt_data$[4,1]=cp_whse_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"IVR_TRANSHIST",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]
