[[BMM_BILLMAST.AOPT-TOTL]]
rem --- Go run the Copy form

	callpoint!.setDevObject("master_bill",callpoint!.getColumnData("BMM_BILLMAST.BILL_NO"))
	callpoint!.setDevObject("lotsize",num(callpoint!.getColumnData("BMM_BILLMAST.STD_LOT_SIZE")))

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"BME_TOTALS",
:		stbl("+USER_ID"),
:		"MNT",
:		"",
:		table_chans$[all]
[[BMM_BILLMAST.STD_LOT_SIZE.AVAL]]
rem --- Set devobject

	callpoint!.setDevObject("lotsize",num(callpoint!.getUserInput()))
[[BMM_BILLMAST.BILL_NO.AVAL]]
rem --- Set DevObject

	item$=callpoint!.getUserInput()
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
		callpoint!.setColumnData("BMM_BILLMAST.CREATE_DATE",stbl("+SYSTEM_DATE"))
		callpoint!.setColumnData("BMM_BILLMAST.UNIT_MEASURE",ivm01.unit_of_sale$)
		callpoint!.setColumnData("BMM_BILLMAST.STD_LOT_SIZE","1")
		callpoint!.setColumnData("BMM_BILLMAST.EST_YIELD","100")
		callpoint!.setStatus("REFRESH")
	endif
[[BMM_BILLMAST.AOPT-COPY]]
rem --- Go run the Copy form

	callpoint!.setDevObject("master_bill",callpoint!.getColumnData("BMM_BILLMAST.BILL_NO"))

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"BMC_COPYBILL",
:		stbl("+USER_ID"),
:		"MNT",
:		"",
:		table_chans$[all]
[[BMM_BILLMAST.AREC]]
rem --- set devobject

	callpoint!.setDevObject("yield",0)
	callpoint!.setDevObject("master_bill","")
	callpoint!.setDevObject("lotsize",0)
[[BMM_BILLMAST.EST_YIELD.AVAL]]
rem --- Set devobject

	callpoint!.setDevObject("yield",num(callpoint!.getUserInput()))
[[BMM_BILLMAST.ARAR]]
rem --- Set DevObjects

	callpoint!.setDevObject("yield",num(callpoint!.getColumnData("BMM_BILLMAST.EST_YIELD")))
	callpoint!.setDevObject("master_bill",callpoint!.getColumnData("BMM_BILLMAST.BILL_NO"))
	callpoint!.setDevObject("lotsize",num(callpoint!.getColumnData("BMM_BILLMAST.STD_LOT_SIZE")))
[[BMM_BILLMAST.BSHO]]
rem --- Set DevObjects required

	callpoint!.setDevObject("yield",0)
	callpoint!.setDevObject("master_bill","")
	callpoint!.setDevObject("lotsize",0)

	num_files=6
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="BMM_BILLMAT",open_opts$[1]="OTA"
	open_tables$[2]="BMM_BILLOPER",open_opts$[2]="OTA"
	open_tables$[3]="BMM_BILLCMTS",open_opts$[3]="OTA"
	open_tables$[4]="BMM_BILLSUB",open_opts$[4]="OTA"
	open_tables$[5]="IVM_ITEMMAST",open_opts$[5]="OTA"
	open_tables$[6]="IVS_PARAMS",open_opts$[6]="OTA"
	gosub open_tables

	call stbl("+DIR_PGM")+"adc_application.aon","AP",info$[all]
	callpoint!.setDevObject("ap_installed",info$[20])

	ivs01_dev=num(open_chans$[6])
	dim ivs01a$:open_tpls$[6]
	read record (ivs01_dev,key=firm_id$+"IV00")ivs01a$
	callpoint!.setDevObject("dflt_whse",ivs01a.warehouse_id$)
