[[OPT_SHIPTRACK.BSHO]]
rem --- Open files
    num_files=1
    dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
    open_tables$[1]="ARC_CARRIERCODE",open_opts$[1]="OTA@"

    gosub open_tables
[[OPT_SHIPTRACK.AOPT-SHPT]]
rem --- Launches carrier's shipment tracking web page for a package (tracking number)
	tracking_no$=callpoint!.getColumnData("OPT_SHIPTRACK.TRACKING_NO")
	carrier_code$=callpoint!.getColumnData("OPT_SHIPTRACK.CARRIER_CODE")

	rem --- Get carrier's website URL from arc_carriercode
	arcCarrierCode_dev=fnget_dev("@ARC_CARRIERCODE")
	dim arcCarrierCode$:fnget_tpl$("@ARC_CARRIERCODE")
	readrecord(arcCarrierCode_dev,key=firm_id$+carrier_code$,dom=*next)arcCarrierCode$

	rem --- Launch web page for the tracking number
	carrier_url$=cvs(arcCarrierCode.carrier_url$,3)
	if carrier_url$<>"" then
		if carrier_url$(len(carrier_url$))<>"=" then carrier_url$=carrier_url$+"="
		tracking_url$=carrier_url$+cvs(tracking_no$,2)
		webpageCounter!=callpoint!.getDevObject("webpageCounter")
		if webpageCounter!=null() then webpageCounter!="0"
		webpageCounter$=str(1+num(webpageCounter!))
		returnCode=scall("bbj "+$22$+"opt_shiptrack.aon"+$22$+" - -u"+tracking_url$+" -c"+webpageCounter$+" &")
		callpoint!.setDevObject("webpageCounter",webpageCounter$)
	else
		msg_id$="AR_MISSING_CARRIER_C"
		dim msg_tokens$[1]
		msg_tokens$[1]=carrier_code$
		gosub disp_message
	endif
[[OPT_SHIPTRACK.ACT_FREIGHT_AMT.AVAL]]
rem --- Initialize CUST_FREIGHT_AMT to ACT_FREIGHT_AMT for new records
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" and num(callpoint!.getColumnData("OPT_SHIPTRACK.CUST_FREIGHT_AMT"))=0 then
		callpoint!.setColumnData("OPT_SHIPTRACK.CUST_FREIGHT_AMT",callpoint!.getUserInput(),1)
	endif
[[OPT_SHIPTRACK.AREC]]
rem --- Disable Void
	callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"OPT_SHIPTRACK.VOID_FLAG",-1)

rem --- Initialize Ship Date
	sysinfo$=stbl("+SYSINFO")
	callpoint!.setColumnData("OPT_SHIPTRACK.CREATE_DATE",sysinfo.system_date$,1)
