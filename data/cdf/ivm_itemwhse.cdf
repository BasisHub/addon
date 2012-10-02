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
ivs01_dev=fnget_dev("IVS_PARAMS")
dim ivs01a$:fnget_tpl$("IVS_PARAMS")

ivs01a_key$=firm_id$+"IV00"
find record (ivs01_dev,key=ivs01a_key$,err=std_missing_params) ivs01a$

if pos(ivs01a.lifofifo$="LF")=0 disable_str$=disable_str$+"LIFO;"; rem --- these are AOPTions, give AOPT code only
if pos(ivs01a.lotser_flag$="LS")=0 disable_str$=disable_str$+"IVM_LSMASTER;"

if disable_str$<>"" call stbl("+DIR_SYP")+"bam_enable_pop.bbj",Form!,enable_str$,disable_str$
[[IVM_ITEMWHSE.AOPT-HIST]]
iv_item_id$=callpoint!.getColumnData("IVM_ITEMWHSE.ITEM_ID")
iv_whse_id$=callpoint!.getColumnData("IVM_ITEMWHSE.WAREHOUSE_ID")
rem --- call stbl("+DIR_SYP")+"ivm_itemWhseActivity.aon",
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
[[IVM_ITEMWHSE.AENA]]
rem --- open item master file and get stocking level for this item; 
rem --- if stocked by item, disable whse form stocking ctls

rem ivm01_dev=fnget_dev("IVM_ITEMMAST")
rem dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")
rem wky$=callpoint!.getKeyPrefix()

rem	readrecord(ivm01_dev,key=wky$)ivm01a$
rem	if ivm01a.stock_level$="I"
rem	fields_to_disable$="BUYER_CODE      LEAD_TIME       ORDER_POINT     EOQ             SAFETY_STOCK    " +
rem :	"ABC_CODE        VENDOR_ID       MAXIMUM_QTY     ORD_PNT_CODE    EOQ_CODE        " +
rem :	"SAF_STK_CODE    "
rem	wmap$=callpoint!.getAbleMap()
rem	ctl_stat$="I"
rem	for wfield=1 to len(fields_to_disable$)-1 step 16
rem		ctl_name$="IVM_ITEMWHSE."+cvs(fields_to_disable$(wfield,16),3)					
rem		wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
rem		wpos=pos(wctl$=wmap$,8)
rem		wmap$(wpos+6,1)=ctl_stat$
rem	next wfield
rem	callpoint!.setAbleMap(wmap$)
rem	callpoint!.setStatus("ABLEMAP-REFRESH")
rem	endif
