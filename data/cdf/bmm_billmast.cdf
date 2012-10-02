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

	num_files=7
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="BMM_BILLMAT",open_opts$[1]="OTA"
	open_tables$[2]="BMM_BILLOPER",open_opts$[2]="OTA"
	open_tables$[3]="BMM_BILLCMTS",open_opts$[3]="OTA"
	open_tables$[4]="BMM_BILLSUB",open_opts$[4]="OTA"
	open_tables$[5]="IVM_ITEMMAST",open_opts$[5]="OTA"
	open_tables$[6]="IVS_PARAMS",open_opts$[6]="OTA"
	open_tables$[7]="BMC_OPCODES",open_opts$[7]="OTA"
	gosub open_tables

	call stbl("+DIR_PGM")+"adc_application.aon","AP",info$[all]
	callpoint!.setDevObject("ap_installed",info$[20])

	ivs01_dev=num(open_chans$[6])
	dim ivs01a$:open_tpls$[6]
	read record (ivs01_dev,key=firm_id$+"IV00")ivs01a$
	callpoint!.setDevObject("dflt_whse",ivs01a.warehouse_id$)
