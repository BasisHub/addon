[[BMM_BILLMAST.<CUSTOM>]]
#include std_missing_params.src
[[BMM_BILLMAST.AENA]]
rem --- Disable Barista menu items
	wctl$="31031"; rem --- Save-As menu item in barista.ini
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)="X"
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP")
[[BMM_BILLMAST.ADIS]]
rem --- set DevObjects

	callpoint!.setDevObject("lock_ref_num",callpoint!.getColumnData("BMM_BILLMAST.LOCK_REF_NUM"))
[[BMM_BILLMAST.LOCK_REF_NUM.AVAL]]
rem --- Notify when LOCK_REF_NUM is changed
	prev_lockrefnum$=callpoint!.getDevObject("prev_lockrefnum")
	lock_ref_num$=callpoint!.getUserInput()
	callpoint!.setDevObject("lock_ref_num",lock_ref_num$)
	if lock_ref_num$<>prev_lockrefnum$ then
		dim msg_tokens$[2]
		if lock_ref_num$="Y" then
			msg_tokens$[1] = "lock"
			msg_tokens$[2] = "cannot"
		else
			msg_tokens$[1] = "unlock"
			msg_tokens$[2] = "can"
		endif
		msg_id$="SF_REFNUM_LOCK"
		gosub disp_message
		if msg_opt$<>"Y" then 
			callpoint!.setColumnData("BMM_BILLMAST.LOCK_REF_NUM",prev_lockrefnum$,1)
			callpoint!.setStatus("ABORT")
		endif
	endif
[[BMM_BILLMAST.LOCK_REF_NUM.BINP]]
rem --- Need to know if LOCK_REF_NUM is changed
	prev_lockrefnum$=callpoint!.getColumnData("BMM_BILLMAST.LOCK_REF_NUM")
	callpoint!.setDevObject("prev_lockrefnum",prev_lockrefnum$)
[[BMM_BILLMAST.BILL_NO.AINP]]
rem --- Make sure item exists before allowing user to continue
[[BMM_BILLMAST.AOPT-PLST]]
rem --- Go run the Pick List form

	bill_no$=callpoint!.getColumnData("BMM_BILLMAST.BILL_NO")

	dim dflt_data$[2,1]
	dflt_data$[1,0]="BILL_NO_1"
	dflt_data$[1,1]=bill_no$
	dflt_data$[2,0]="BILL_NO_2"
	dflt_data$[2,1]=bill_no$
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"BMR_PACKINGLIST",
:		stbl("+USER_ID"),
:		"MNT",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]
[[BMM_BILLMAST.AOPT-AINQ]]
rem --- Go run the Availability Inquiry form

	callpoint!.setDevObject("master_bill",callpoint!.getColumnData("BMM_BILLMAST.BILL_NO"))

	dim dflt_data$[3,1]
	dflt_data$[1,0]="QTY_REQUIRED"
	dflt_data$[1,1]="1"
	dflt_data$[2,0]="PROD_DATE"
	dflt_data$[2,1]=stbl("+SYSTEM_DATE")
	dflt_data$[3,0]="WAREHOUSE_ID"
	dflt_data$[3,1]=callpoint!.getDevObject("dflt_whse")
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"BMM_AVAILABILITY",
:		stbl("+USER_ID"),
:		"MNT",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]
[[BMM_BILLMAST.AOPT-HCPY]]
rem --- Go run the Hard Copy form

	callpoint!.setDevObject("master_bill",callpoint!.getColumnData("BMM_BILLMAST.BILL_NO"))

	dim dflt_data$[2,1]
	dflt_data$[1,0]="PROD_DATE"
	dflt_data$[1,1]=stbl("+SYSTEM_DATE")
	dflt_data$[2,0]="INCLUDE_COMMENT"
	dflt_data$[2,1]="Y"
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"BMM_DETAILLIST",
:		stbl("+USER_ID"),
:		"MNT",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]
[[BMM_BILLMAST.AOPT-TOTL]]
rem --- Go run the Copy form

	callpoint!.setDevObject("master_bill",callpoint!.getColumnData("BMM_BILLMAST.BILL_NO"))
	callpoint!.setDevObject("lotsize",num(callpoint!.getColumnData("BMM_BILLMAST.STD_LOT_SIZE")))

	dim dflt_data$[2,1]
	dflt_data$[1,0]="PROD_DATE"
	dflt_data$[1,1]=stbl("+SYSTEM_DATE")
	dflt_data$[2,0]="WAREHOUSE_ID"
	dflt_data$[2,1]=callpoint!.getDevObject("dflt_whse")
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"BME_TOTALS",
:		stbl("+USER_ID"),
:		"MNT",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]
[[BMM_BILLMAST.STD_LOT_SIZE.AVAL]]
rem --- Set devobject

	callpoint!.setDevObject("lotsize",num(callpoint!.getUserInput()))
[[BMM_BILLMAST.BILL_NO.AVAL]]
rem --- Set DevObject
rem "Inventory Inactive Feature"
item_id$=callpoint!.getUserInput()
ivm01_dev=fnget_dev("IVM_ITEMMAST")
ivm01_tpl$=fnget_tpl$("IVM_ITEMMAST")
dim ivm01a$:ivm01_tpl$
ivm01a_key$=firm_id$+item_id$
find record (ivm01_dev,key=ivm01a_key$,err=*break)ivm01a$
if ivm01a.item_inactive$="Y" then
   msg_id$="IV_ITEM_INACTIVE"
   dim msg_tokens$[2]
   msg_tokens$[1]=cvs(ivm01a.item_id$,2)
   msg_tokens$[2]=cvs(ivm01a.display_desc$,2)
   gosub disp_message
   callpoint!.setStatus("ACTIVATE-ABORT")
   goto std_exit
endif

	item$=callpoint!.getUserInput()
	if cvs(item$,3)="" break
	callpoint!.setDevObject("master_bill",item$)

rem --- set defaults for new record

	bmm01_dev=fnget_dev("BMM_BILLMAST")
	new_rec$="Y"
	while 1
		find(bmm01_dev,key=firm_id$+item$,dom=*break)
		new_rec$="N"
		break
	wend

	if new_rec$="Y"
		ivm01_dev=fnget_dev("IVM_ITEMMAST")
		dim ivm01$:fnget_tpl$("IVM_ITEMMAST")
		read record (ivm01_dev,key=firm_id$+item$)ivm01$
		callpoint!.setColumnData("BMM_BILLMAST.CREATE_DATE",stbl("+SYSTEM_DATE"),1)
		callpoint!.setColumnData("BMM_BILLMAST.UNIT_MEASURE",ivm01.unit_of_sale$,1)
		callpoint!.setColumnData("BMM_BILLMAST.STD_LOT_SIZE","1",1)
		callpoint!.setColumnData("BMM_BILLMAST.EST_YIELD","100",1)
		callpoint!.setStatus("MODIFIED")
	endif
[[BMM_BILLMAST.AOPT-COPY]]
rem --- Go run the Copy form

	callpoint!.setDevObject("master_bill",callpoint!.getColumnData("BMM_BILLMAST.BILL_NO"))
	callpoint!.setDevObject("new_bill","")

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"BMC_COPYBILL",
:		stbl("+USER_ID"),
:		"MNT",
:		"",
:		table_chans$[all]

	rem --- Set LOCK_REF_NUM=Y for copied BOM
	callpoint!.setColumnData("BMM_BILLMAST.LOCK_REF_NUM","Y",1)
	lockRefNum!=callpoint!.getControl("BMM_BILLMAST.LOCK_REF_NUM")
	lockRefNum!.setSelected(1)

	if callpoint!.getDevObject("new_bill")<>""
		new_bill$=callpoint!.getDevObject("new_bill")
		callpoint!.setColumnData("BMM_BILLMAST.BILL_NO",new_bill$)
		callpoint!.setStatus("RECORD:["+firm_id$+new_bill$+"]-REFRESH")
	endif
[[BMM_BILLMAST.AREC]]
rem --- set devobject

	callpoint!.setDevObject("yield",100)
	callpoint!.setDevObject("master_bill","")
	callpoint!.setDevObject("lotsize",1)
	callpoint!.setColumnData("<<DISPLAY>>.WHERE_LAST_USED","",1)
	callpoint!.setColumnData("BMM_BILLMAST.LOCK_REF_NUM","N")
	callpoint!.setDevObject("lock_ref_num",callpoint!.getColumnData("BMM_BILLMAST.LOCK_REF_NUM"))
[[BMM_BILLMAST.EST_YIELD.AVAL]]
rem --- Set devobject

	callpoint!.setDevObject("yield",num(callpoint!.getUserInput()))
[[BMM_BILLMAST.ARAR]]
rem --- Set DevObjects

	callpoint!.setDevObject("yield",num(callpoint!.getColumnData("BMM_BILLMAST.EST_YIELD")))
	callpoint!.setDevObject("master_bill",callpoint!.getColumnData("BMM_BILLMAST.BILL_NO"))
	callpoint!.setDevObject("lotsize",num(callpoint!.getColumnData("BMM_BILLMAST.STD_LOT_SIZE")))

	source$=callpoint!.getColumnData("BMM_BILLMAST.SOURCE_CODE")
	in_prod$=Translate!.getTranslation("AON_IN_PRODUCTION_ENTRY")
	in_wo$=Translate!.getTranslation("AON_IN_WORK_ORDERS")
	if source$="B"
		callpoint!.setColumnData("<<DISPLAY>>.WHERE_LAST_USED",in_prod$,1)
	else
		if source$="W"
			callpoint!.setColumnData("<<DISPLAY>>.WHERE_LAST_USED",in_wo$,1)
		else
			callpoint!.setColumnData("<<DISPLAY>>.WHERE_LAST_USED","",1)
		endif
	endif
	
[[BMM_BILLMAST.BSHO]]
rem --- Set DevObjects required

	callpoint!.setDevObject("yield",100)
	callpoint!.setDevObject("master_bill","")
	callpoint!.setDevObject("lotsize",1)

	num_files=8
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="BMM_BILLMAT",open_opts$[1]="OTA"
	open_tables$[2]="BMM_BILLOPER",open_opts$[2]="OTA"
	open_tables$[3]="BMM_BILLCMTS",open_opts$[3]="OTA"
	open_tables$[4]="BMM_BILLSUB",open_opts$[4]="OTA"
	open_tables$[5]="IVM_ITEMMAST",open_opts$[5]="OTA"
	open_tables$[6]="IVS_PARAMS",open_opts$[6]="OTA"
	open_tables$[7]="BMC_OPCODES",open_opts$[7]="OTA"
	open_tables$[8]="BMS_PARAMS",open_opts$[8]="OTA"

	gosub open_tables

	ivs01_dev=num(open_chans$[6])
	dim ivs01a$:open_tpls$[6]
	bms01_dev=num(open_chans$[8])
	dim bms01a$:open_tpls$[8]

	call stbl("+DIR_PGM")+"adc_application.aon","AP",info$[all]
	callpoint!.setDevObject("ap_installed",info$[20])

	read record (ivs01_dev,key=firm_id$+"IV00",err=std_missing_params)ivs01a$
	callpoint!.setDevObject("dflt_whse",ivs01a.warehouse_id$)
	callpoint!.setDevObject("iv_precision",num(ivs01a.precision$))

	read record (bms01_dev,key=firm_id$+"BM00")bms01a$
	callpoint!.setDevObject("bm_precision",bms01a.bm_precision)
	if num(ivs01a.precision$)>bms01a.bm_precision then
		callpoint!.setDevObject("this_precision",num(ivs01a.precision$))
	else
		callpoint!.setDevObject("this_precision",bms01a.bm_precision)
	endif
