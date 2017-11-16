[[GMS_PARAMS.BEND]]
rem --- close the gmClient

	gmClient!=callpoint!.getDevObject("gmClient")
	gmClient!.close()

[[GMS_PARAMS.ARNF]]
rem --- if no param rec yet exists, initialize w/ just firm and 'GM'

	gms_params_dev=fnget_dev("GMS_PARAMS")
	rec_data.firm_id$=firm_id$
	rec_data.gm$="GM"

	writerecord(gms_params_dev)rec_data$

	callpoint!.setStatus("RECORD")
[[GMS_PARAMS.GM_MASTER_USER.AVAL]]
rem --- Must test connection if connection configuration changed
	if callpoint!.getUserInput()<>callpoint!.getColumnData("GMS_PARAMS.GM_MASTER_USER") then
		callpoint!.setDevObject("testWebService","yes")
	endif
[[GMS_PARAMS.GM_MASTER_PW.AVAL]]
rem --- Must test connection if connection configuration changed
	if callpoint!.getUserInput()<>callpoint!.getColumnData("GMS_PARAMS.GM_MASTER_PW") then
		callpoint!.setDevObject("testWebService","yes")
	endif
[[GMS_PARAMS.GM_GOLDDIR.AVAL]]
rem --- Must test connection if connection configuration changed
	if callpoint!.getUserInput()<>callpoint!.getColumnData("GMS_PARAMS.GM_GOLDDIR") then
		callpoint!.setDevObject("testWebService","yes")
	endif
[[GMS_PARAMS.GM_COMDIR.AVAL]]
rem --- Must test connection if connection configuration changed
	if callpoint!.getUserInput()<>callpoint!.getColumnData("GMS_PARAMS.GM_COMDIR") then
		callpoint!.setDevObject("testWebService","yes")
	endif
[[GMS_PARAMS.GM_SYSDIR.AVAL]]
rem --- Must test connection if connection configuration changed
	if callpoint!.getUserInput()<>callpoint!.getColumnData("GMS_PARAMS.GM_SYSDIR") then
		callpoint!.setDevObject("testWebService","yes")
	endif
[[GMS_PARAMS.WEBSERVICE_URL.AVAL]]
rem --- Must test connection if connection configuration changed
	if callpoint!.getUserInput()<>callpoint!.getColumnData("GMS_PARAMS.WEBSERVICE_URL") then
		callpoint!.setDevObject("testWebService","yes")
	endif
[[GMS_PARAMS.AOPT-TSWB]]
rem --- Test web service
	callpoint!.setDevObject("testWebService","no")

	rem --- Start the Barista MDI Progress Meter
	grpSpace!=BBjAPI().getGroupNamespace()
	grpSpace!.setValue("+build_task","ON")

	rem --- Create PostMethod for request
	restUrl$ = cvs(callpoint!.getColumnData("GMS_PARAMS.WEBSERVICE_URL"),2)
	method! = new PostMethod(restUrl$)

	rem --- Have HttpClient execute the PostMethod
	client! = new HttpClient()
	seterr connection_failed
	errmsg$=""
	sc% = client!.executeMethod(method!)
	seterr std_error
	method!.releaseConnection()
	if sc% = HttpStatus.SC_OK then
		rem --- Verify can load the GoldMine XML interface API
		aonData! = new java.util.Properties()
		aonData!.setProperty("SysDir",cvs(callpoint!.getColumnData("GMS_PARAMS.GM_SYSDIR"),2))
		gmGoldDir$ = cvs(callpoint!.getColumnData("GMS_PARAMS.GM_GOLDDIR"),2)
		if gmGoldDir$(len(gmGoldDir$),1) <> ":" then gmGoldDir$ = gmGoldDir$ + ":"
		aonData!.setProperty("GoldDir",gmGoldDir$)
		gmComDir$ = cvs(callpoint!.getColumnData("GMS_PARAMS.GM_COMDIR"),2)
		if gmComDir$(len(gmComDir$),1) <> ":" then gmComDir$ = gmComDir$ + ":"
		aonData!.setProperty("CommonDir",gmComDir$)
		aonData!.setProperty("User",cvs(callpoint!.getColumnData("GMS_PARAMS.GM_MASTER_USER"),2))
		aonData!.setProperty("Password",cvs(callpoint!.getColumnData("GMS_PARAMS.GM_MASTER_PW"),2))
		aonData!.setProperty("SQLUser",cvs(callpoint!.getColumnData("GMS_PARAMS.DB_USER"),2))
		aonData!.setProperty("SQLPassword",cvs(callpoint!.getColumnData("GMS_PARAMS.DB_PASSWORD"),2))
                
		gmClient!=callpoint!.getDevObject("gmClient")
		xmlRequest$ = gmClient!.buildXMLRequest("LoadAPI", aonData!, firm_id$)
		xmlResponse$ = gmClient!.postRequest(xmlRequest$, firm_id$)
		props!=gmClient!.parseXMLResponse(xmlResponse$, firm_id$)

		rem --- Check status of LoadAPI method
		if props!.containsKey("statusCode") and cvs(props!.getProperty("statusCode"),3)<>"1" then
			errmsg$=cvs(props!.getProperty("statusText"),3)
			goto connection_failed
		else
			rem --- Connection successful
			grpSpace!.setValue("+build_task","OFF")
			msg_id$="WEB_SERVICE_CONN_OK"
			dim msg_tokens$[1]
			msg_tokens$[1]="GoldMine web service."
			gosub disp_message
			goto TSWB_done
		endif
	else
		errmsg$="HTTP Error "+str(sc%)
		goto connection_failed
	endif

connection_failed: rem --- Connection failed/error
	grpSpace!.setValue("+build_task","OFF")
	msg_id$="WEB_SERVICE_CONN_NOK"
	dim msg_tokens$[2]
	msg_tokens$[1]="GoldMine web service."
	if errmsg$="" then
		msg_tokens$[2]=errmes(-1)
	else
		msg_tokens$[2]=errmsg$
	endif
	gosub disp_message

TSWB_done: rem --- All done here
[[GMS_PARAMS.DB_USER.AVAL]]
rem --- Must test connection if connection configuration changed
	if callpoint!.getUserInput()<>callpoint!.getColumnData("GMS_PARAMS.DB_USER") then
		callpoint!.setDevObject("testDbConn","yes")
	endif
[[GMS_PARAMS.DB_PASSWORD.AVAL]]
rem --- Must test connection if connection configuration changed
	if callpoint!.getUserInput()<>callpoint!.getColumnData("GMS_PARAMS.DB_PASSWORD") then
		callpoint!.setDevObject("testDbConn","yes")
	endif
[[GMS_PARAMS.DB_URL.AVAL]]
rem --- Must test connection if connection configuration changed
	if callpoint!.getUserInput()<>callpoint!.getColumnData("GMS_PARAMS.DB_URL") then
		callpoint!.setDevObject("testDbConn","yes")
	endif
[[GMS_PARAMS.BSHO]]
rem --- Use needed Java classes
	use org.apache.commons.httpclient.HttpClient
	use org.apache.commons.httpclient.HttpStatus
	use org.apache.commons.httpclient.methods.PostMethod

rem --- Initialize dev objects
	callpoint!.setDevObject("testDbConn","no")
	callpoint!.setDevObject("testWebService","no")

rem --- Get GoldMine interface client
	use ::gmo_GmInterfaceClient.aon::GmInterfaceClient
	gmClient!=new GmInterfaceClient()
	callpoint!.setDevObject("gmClient",gmClient!)
[[GMS_PARAMS.BWRI]]
rem --- Must test DB connection before saving any changes to the DB connection configuration
	if callpoint!.getDevObject("testDbConn")="yes" then
		msg_id$="GM_TEST_DB_CONN"
		gosub disp_message
	endif

rem --- Must test web service connection before saving any changes to the web service connection configuration
	if callpoint!.getDevObject("testWebService")="yes" then
		msg_id$="GM_TEST_WS_CONN"
		gosub disp_message
	endif
[[GMS_PARAMS.AOPT-TCON]]
rem --- Test database connection
	callpoint!.setDevObject("testDbConn","no")

	rem --- Start the Barista MDI Progress Meter
	grpSpace!=BBjAPI().getGroupNamespace()
	grpSpace!.setValue("+build_task","ON")

	db_url$=callpoint!.getColumnData("GMS_PARAMS.DB_URL")
	db_alias$=callpoint!.getColumnData("GMS_PARAMS.DB_ALIAS")
	db_user$=callpoint!.getColumnData("GMS_PARAMS.DB_USER")
	db_password$=callpoint!.getColumnData("GMS_PARAMS.DB_PASSWORD")

	java.lang.Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver")
	connURL$=db_url$+";"
	connURL$=connURL$+"databaseName="+db_alias$+";"
	connURL$=connURL$+"user="+db_user$+";"
	connURL$=connURL$+"password="+db_password$+";"
	chan=sqlunt
	sqlopen(chan,err=connect_nok)connURL$

	grpSpace!.setValue("+build_task","OFF")
	msg_id$="SQL_DB_CONN_OK"
	dim msg_tokens$[1]
	msg_tokens$[1]="GoldMine database."
	gosub disp_message
	goto connection_test_end

connect_nok:
	grpSpace!.setValue("+build_task","OFF")
	msg_id$="SQL_DB_CONN_NOK"
	dim msg_tokens$[1]
	msg_tokens$[1]=errmes(-1)
	gosub disp_message

connection_test_end:
	sqlclose(chan,err=*next)
[[GMS_PARAMS.AREC]]
rem --- Default wait time to 60 seconds
	callpoint!.setColumnData("GMS_PARAMS.WAIT_TIME","60")
