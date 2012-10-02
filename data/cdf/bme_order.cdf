[[BME_ORDER.ORDER_NO.AVAL]]
rem --- Check to make sure the order selected is an Order

	ope01_dev=fnget_dev("OPE_ORDHDR")
	dim ope01a$:fnget_tpl$("OPE_ORDHDR")

	cust$=callpoint!.getColumnData("BME_ORDER.CUSTOMER_ID")
	order$=callpoint!.getUserInput()
	read record(ope01_dev,key=firm_id$+"  "+cust$+order$)ope01a$

	if ope01a.ordinv_flag$<>"O"
		msg_id$="OP_ORDER_TYPE"
		gosub disp_message
		callpoint!.setColumnData("BME_ORDER.ORDER_NO","",1)
		callpoint!.setStatus("ABORT")
	endif
[[BME_ORDER.PROD_DATE.AVAL]]
rem --- make sure production date is in an appropriate GL period

	gl$=callpoint!.getDevObject("glint")
	prod_date$=callpoint!.getUserInput()        
	if gl$="Y" 
		call stbl("+DIR_PGM")+"glc_datecheck.aon",prod_date$,"Y",per$,yr$,status
		if status>99
			callpoint!.setStatus("ABORT")
		endif
	endif
[[BME_ORDER.BSHO]]
rem --- Check to see if OP is installed

	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","OP",info$[all]
	callpoint!.setDevObject("OP_installed",info$[20])
	if info$[20]<>"Y"
		msg_id$="AD_NO_OP"
		gosub disp_message
		release
	endif

rem --- Open Files

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="OPE_ORDHDR",open_opts$[1]="OTA"
	gosub open_tables

rem --- Additional Init
	gl$="N"
	status=0
	source$=pgm(-2)
	call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"IV",glw11$,gl$,status
	if status<>0 goto std_exit
	callpoint!.setDevObject("glint",gl$)
