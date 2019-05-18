[[ARE_CCPMT.RECEIPT_DATE.AVAL]]
rem --- validate receipt date

	gl$=callpoint!.getDevObject("gl_interface")
	recpt_date$=callpoint!.getUserInput()        
	if gl$="Y" 
		call stbl("+DIR_PGM")+"glc_datecheck.aon",recpt_date$,"Y",per$,yr$,status
		if status>99
			callpoint!.setStatus("ABORT")
		endif
	endif

gosub reset_timer
[[ARE_CCPMT.CASH_REC_CD.AVAL]]
rem --- get cash rec code and associated credit card params; if hosted, disable data collection fields
rem --- only execute if vectInvoices! not yet populated
rem --- this avoids re-running this code via the ASVA (Barista re-validates last enabled control?)

	vectInvoices!=callpoint!.getDevObject("vectInvoices")
	rem --- only execute if vectInvoices! hasn't yet been built - i.e., don't execute again in ASVA final validation check
	rem --- or if cash rec code has been changed

	if !vectInvoices!.size() or callpoint!.getUserInput()<>callpoint!.getColumnData("ARE_CCPMT.CASH_REC_CD")

		ars_cc_custsvc=fnget_dev("ARS_CC_CUSTSVC")
		arc_cashcode=fnget_dev("ARC_CASHCODE")
		are_cashhdr=fnget_dev("ARE_CASHHDR")

		dim ars_cc_custsvc$:fnget_tpl$("ARS_CC_CUSTSVC")
		dim arc_cashcode$:fnget_tpl$("ARC_CASHCODE")
		dim are_cashhdr$:fnget_tpl$("ARE_CASHHDR")

		cash_cd$=callpoint!.getUserInput()

		readrecord(arc_cashcode,key=firm_id$+"C"+cash_cd$,dom=std_missing_params)arc_cashcode$
		readrecord(ars_cc_custsvc,key=firm_id$+cash_cd$,dom=std_missing_params)ars_cc_custsvc$

		if cvs(callpoint!.getColumnData("ARE_CCPMT.CNTRY_ID"),3)=""
			callpoint!.setColumnData("ARE_CCPMT.CNTRY_ID",ars_cc_custsvc.dflt_cntry_id$,1)
		endif

		gateway_id$=ars_cc_custsvc.gateway_id$
		gosub get_gateway_config
		if msg_id$<>"" then break; rem --- 'token' string found in config; needs to be substituted for legit value before continuing

		callpoint!.setDevObject("ars_cc_custsvc",ars_cc_custsvc$)
		callpoint!.setDevObject("interface_tp",ars_cc_custsvc.interface_tp$)
		if ars_cc_custsvc.interface_tp$="A"
			rem --- Set timer for form when interface_tp$="A" (using internal API, so collecting sensitive info)
			timer_key!=10000
			BBjAPI().createTimer(timer_key!,60,"custom_event")
			enable_flag=1
		else
			enable_flag=0
			callpoint!.setColumnData("ARE_CCPMT.CARD_NO","",1)
			callpoint!.setColumnData("ARE_CCPMT.SECURITY_CD","",1)
			callpoint!.setColumnData("ARE_CCPMT.NAME_FIRST","",1)
			callpoint!.setColumnData("ARE_CCPMT.NAME_LAST","",1)
			callpoint!.setColumnData("ARE_CCPMT.MONTH","",1)
			callpoint!.setColumnData("ARE_CCPMT.YEAR","",1)

			rem --- for hosted, make sure expected config attributes exist
			config_attribs!=BBjAPI().makeVector()
			if gateway_id$="PAYFLOWPRO"
				config_attribs!.add("PARTNER")
				config_attribs!.add("VENDOR")
				config_attribs!.add("USER")
				config_attribs!.add("PWD")
				config_attribs!.add("testMode")
				config_attribs!.add("server")
				config_attribs!.add("requestTokenURL")
				config_attribs!.add("launchURL")
				config_attribs!.add("silentPostServlet")
				config_attribs!.add("silentPostFailureServlet")
				config_attribs!.add("silentPostFailureServlet")
			else
				config_attribs!.add("name")
				config_attribs!.add("transactionKey")
				config_attribs!.add("server")
				config_attribs!.add("launchPage")
				config_attribs!.add("gatewayURL")
				config_attribs!.add("confirmationPage")
				config_attribs!.add("webhookServlet")
				config_attribs!.add("environment")
				config_attribs!.add("testMode")
			endif
			for wk=0 to config_attribs!.size()-1
				if gw_config!.get(config_attribs!.get(wk))=null()
					dim msg_tokens$[1]
					msg_tokens$[0]=Translate!.getTranslation("AON_MISSING_GATEWAY_CONFIG","One or more configuration values for the payment gateway are missing.",1)+$0A$+"("+gateway_id$+")"
					msg_id$="GENERIC_WARN"
					gosub disp_message
					callpoint!.setStatus("EXIT")
					break
				endif
			next wk
		endif
		callpoint!.setColumnEnabled("ARE_CCPMT.ADDRESS_LINE_1",enable_flag)
		callpoint!.setColumnEnabled("ARE_CCPMT.ADDRESS_LINE_2",enable_flag)
		callpoint!.setColumnEnabled("ARE_CCPMT.CARD_NO",enable_flag)
		callpoint!.setColumnEnabled("ARE_CCPMT.CITY",enable_flag)
		callpoint!.setColumnEnabled("ARE_CCPMT.CNTRY_ID",enable_flag)
		callpoint!.setColumnEnabled("ARE_CCPMT.EMAIL_ADDR",enable_flag)
		callpoint!.setColumnEnabled("ARE_CCPMT.MONTH",enable_flag)
		callpoint!.setColumnEnabled("ARE_CCPMT.NAME_FIRST",enable_flag)
		callpoint!.setColumnEnabled("ARE_CCPMT.NAME_LAST",enable_flag)
		callpoint!.setColumnEnabled("ARE_CCPMT.PHONE_NO",enable_flag)
		callpoint!.setColumnEnabled("ARE_CCPMT.SECURITY_CD",enable_flag)
		callpoint!.setColumnEnabled("ARE_CCPMT.STATE_CODE",enable_flag)
		callpoint!.setColumnEnabled("ARE_CCPMT.YEAR",enable_flag)
		callpoint!.setColumnEnabled("ARE_CCPMT.ZIP_CODE",enable_flag)

		rem --- load up open invoices

		gosub get_open_invoices
		gosub fill_grid

		are_cashhdr.firm_id$=firm_id$
		are_cashhdr.customer_id$=callpoint!.getColumnData("ARE_CCPMT.CUSTOMER_ID")
		are_cashhdr.receipt_date$=callpoint!.getColumnData("ARE_CCPMT.RECEIPT_DATE")
		are_cashhdr.cash_rec_cd$=cash_cd$

		receipt_found=0
		dflt_batch_desc$=cvs(ars_cc_custsvc.batch_desc$,3)
		dflt_deposit_desc$=cvs(ars_cc_custsvc.deposit_desc$,3)

		extractrecord(are_cashhdr,key=
:			are_cashhdr.firm_id$+
:			are_cashhdr.ar_type$+
:			are_cashhdr.reserved_key_01$+
:			are_cashhdr.receipt_date$+
:			are_cashhdr.customer_id$+
:			are_cashhdr.cash_rec_cd$+
:			are_cashhdr.ar_check_no$+
:			are_cashhdr.reserved_key_02$,dom=*next)are_cashhdr$;receipt_found=1

		if receipt_found
			if num(are_cashhdr.batch_no$)<>0
				dflt_batch_no$=are_cashhdr.batch_no$
			else
				dflt_batch_no$=""
			endif
			if num(are_cashhdr.deposit_id$)<>0
				dflt_deposit_id$=are_cashhdr.deposit_id$
			else
				dflt_deposit_id$=""
			endif
		endif
			
		rem --- Get batching information, supplying batch number that must be used if this receipt already exists and is batched (batch#<>0)

		call stbl("+DIR_PGM")+"adc_getbatch.aon","ARE_CASHHDR","",table_chans$[all],dflt_batch_desc$,dflt_batch_no$
		callpoint!.setColumnData("ARE_CCPMT.BATCH_NO",stbl("+BATCH_NO"),1)
		if receipt_found then read(are_cashhdr);rem --- can release temp extract on are_cashhdr now that batch is soft-locked (or if not batching)

		rem --- Get deposit info, supplying deposit number that must be used if this receipt already exists and contains a deposit ID

		if callpoint!.getDevObject("br_interface")="Y" then

			rem --- init temp stbls for use inside deposit form

			xwk$=stbl("+cc_cash_rec_cd",ars_cc_custsvc.cash_rec_cd$);rem --- don't allow cash rec code to be changed on deposit form
			xwk$=stbl("+cc_receipt_date",callpoint!.getColumnData("ARE_CCPMT.RECEIPT_DATE"))

			callpoint!.setDevObject("deposit_id","")

			dim dflt_data$[4,1]
			dflt_data$[1,0]="DESCRIPTION"
			dflt_data$[1,1]=dflt_deposit_desc$
			dflt_data$[2,0]="CASH_REC_CD"
			dflt_data$[2,1]=ars_cc_custsvc.cash_rec_cd$
			dflt_data$[3,0]="BATCH_NO"
			dflt_data$[3,1]=stbl("+BATCH_NO")
			if dflt_deposit_id$<>""
				dflt_data$[4,0]="DEPOSIT_ID"
				dflt_data$[4,1]=dflt_deposit_id$
				key_pfx$=firm_id$+stbl("+BATCH_NO")+"E"+dflt_deposit_id$;rem --- 'E' is trans status Entry
			else
				key_pfx$=firm_id$+stbl("+BATCH_NO")+"E"
			endif

			call stbl("+DIR_SYP")+"bam_run_prog.bbj", "ARE_DEPOSIT", stbl("+USER_ID"), "MNT", key_pfx$, table_chans$[all],"",dflt_data$[all]
			callpoint!.setColumnData("ARE_CCPMT.DEPOSIT_ID",str(callpoint!.getDevObject("deposit_id")),1)	

			rem --- DEPOSIT_ID is required, so ABORT if we didn't select one
			if callpoint!.getDevObject("deposit_id")=""
				callpoint!.setStatus("ABORT")
			endif

			rem --- clear temp stbls
			xwk$=stbl("!CLEAR","+cc_cash_rec_cd")
			xwk$=stbl("!CLEAR","+cc_receipt_date")	
		endif
	endif
[[ARE_CCPMT.CASH_REC_CD.BINQ]]
rem --- restrict inquiry to cash rec codes associated with credit card payments

	dim filter_defs$[1,2]
	filter_defs$[0,0]="ARC_CASHCODE.FIRM_ID"
	filter_defs$[0,1]="='"+firm_id$+"'"
	filter_defs$[0,2]="LOCK"
	filter_defs$[1,0]="ARS_CC_CUSTSVC.USE_CUSTSVC_CC"
	filter_defs$[1,1]="='Y'"
	filter_defs$[1,2]="LOCK"

	dim search_defs$[3]

	call stbl("+DIR_SYP")+"bax_query.bbj",
:		gui_dev,
:		Form!,
:		"AR_CREDIT_CODES",
:		"",
:		table_chans$[all],
:		selected_keys$,
:		filter_defs$[all],
:		search_defs$[all],
:		"",
:		""

	if selected_keys$<>""
		call stbl("+DIR_SYP")+"bac_key_template.bbj",
:			"ARC_CASHCODE",
:			"PRIMARY",
:			arc_cashcode_key$,
:			table_chans$[all],
:			status$
		dim arc_cashcode_key$:arc_cashcode_key$
		arc_cashcode_key$=selected_keys$
		callpoint!.setColumnData("ARE_CCPMT.CASH_REC_CD",arc_cashcode_key.cash_rec_cd$,1)
	endif

	callpoint!.setDevObject("cash_rec_cd",selected_keys$)
	callpoint!.setStatus("ACTIVATE-ABORT")
[[ARE_CCPMT.ZIP_CODE.AVAL]]
gosub reset_timer
[[ARE_CCPMT.YEAR.AINV]]
gosub reset_timer
[[ARE_CCPMT.STATE_CODE.AVAL]]
gosub reset_timer
[[ARE_CCPMT.SECURITY_CD.AVAL]]
gosub reset_timer
[[ARE_CCPMT.PHONE_NO.AVAL]]
gosub reset_timer
[[ARE_CCPMT.NAME_LAST.AVAL]]
gosub reset_timer
[[ARE_CCPMT.NAME_FIRST.AVAL]]
gosub reset_timer
[[ARE_CCPMT.MONTH.AVAL]]
rem --- validate month

	month$=cvs(callpoint!.getUserInput(),3)

	if month$<>""
		if num(month$)<1 or num(month$)>12 then callpoint!.setStatus("ABORT")
	endif

	gosub reset_timer
[[ARE_CCPMT.EMAIL_ADDR.AVAL]]
gosub reset_timer
[[ARE_CCPMT.CNTRY_ID.AVAL]]
gosub reset_timer
[[ARE_CCPMT.ADDRESS_LINE_2.AVAL]]
gosub reset_timer
[[ARE_CCPMT.ADDRESS_LINE_1.AVAL]]
gosub reset_timer
[[ARE_CCPMT.BEND]]
rem --- if vectInvoices! contains any selected items, get confirmation that user really wants to exit

	progWin!=callpoint!.getDevObject("progwin")
	if progWin!<>null() then progWin!.destroy(err=*next)

	vectInvoices!=callpoint!.getDevObject("vectInvoices")
	grid_cols = num(callpoint!.getDevObject("grid_cols"))
	selected=0
	if vectInvoices!.size(err=*endif)
		for wk=0 to vectInvoices!.size()-1 step grid_cols
			selected=selected+iff(vectInvoices!.get(wk)="Y",1,0)
		next wk
	endif

	if callpoint!.getDevObject("payment_status")="payment"
		msg_id$="GENERIC_WARN_CANCEL"
		dim msg_tokens$[1]
		msg_tokens$[0]=Translate!.getTranslation("AON_PAYMENT_TRANSACTION_IN_PROCESS","Payment transaction in process. Response not yet received.",1)
		msg_tokens$[0]=msg_tokens$[0]+$0A$+Translate!.getTranslation("AON_MANUALLY_CREATE_CASH_RECEIPT","If you click OK to exit, you will need to manually confirm successful payment and enter the Cash Receipt.",1)
		gosub disp_message
		if msg_opt$<>"O" then callpoint!.setStatus("ABORT")
	endif

	if selected
		msg_id$="GENERIC_WARN_CANCEL"
		dim msg_tokens$[1]
		msg_tokens$[0]=Translate!.getTranslation("AON_EXIT_WITHOUT_PROCESSING_THIS_PAYMENT","Exit without processing this payment?",1)+$0A$+Translate!.getTranslation("AON_SELECT_OK_OR_CANCEL","Select OK to exit, or Cancel to return to the form.",1)
		gosub disp_message
		if msg_opt$<>"O" then callpoint!.setStatus("ABORT")
	endif

	BBjAPI().removeTimer(10000,err=*next)

	gosub remove_batch_lock
[[ARE_CCPMT.AREC]]

[[ARE_CCPMT.CARD_NO.AVAL]]
rem ==============================================
rem -- mod10_check; see if card number field contains valid cc# format
rem ==============================================

	cc_digits$ = ""
	cc_curr_digit = 0
	cc_card$=callpoint!.getUserInput()

	if cvs(cc_card$,3)<>""
		for cc_temp = len(cc_card$) to 1 step -1
		cc_curr_digit = cc_curr_digit + 1
		cc_no = num(cc_card$(cc_temp,1)) * iff(mod(cc_curr_digit,2)=0, 2, 1)
		cc_digits$ = str(cc_no) + cc_digits$
		next cc_temp

		cc_total = 0
		for cc_temp = 1 to len(cc_digits$)
		cc_total = cc_total + num(cc_digits$(cc_temp, 1))
		next cc_temp

		if mod(cc_total, 10) <> 0
			callpoint!.setMessage("INVALID_CREDIT_CARD")
			callpoint!.setStatus("ABORT")
		endif
	endif

	gosub reset_timer
[[ARE_CCPMT.ASVA]]
rem --- if using J2Pay (interface_tp$='A'), check for mandatory data, confirm, then process

	interface_tp$=callpoint!.getDevObject("interface_tp")

	if interface_tp$="A"

		if cvs(callpoint!.getColumnData("ARE_CCPMT.ADDRESS_LINE_1"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.CARD_NO"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.CITY"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.CNTRY_ID"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.CUSTOMER_ID"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.FIRM_ID"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.MONTH"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.NAME_FIRST"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.NAME_LAST"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.PHONE_NO"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.SECURITY_CD"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.STATE_CODE"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.YEAR"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.ZIP_CODE"),3)="" or
:			num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT"))=0

			rem only BillPro requires email, so not making mandatory for all...add to statement above if desired
			rem cvs(callpoint!.getColumnData("ARE_CCPMT.EMAIL_ADDR"),3)="" or

			dim msg_tokens$[1]
			msg_tokens$[0]=Translate!.getTranslation("AON_PLEASE_FILL_IN_ALL_REQUIRED_FIELDS")
			msg_id$="GENERIC_WARN"
			gosub disp_message
			callpoint!.setStatus("ABORT-ACTIVATE")
			break
		endif

		curr$=date(0:"%Yd%Mz")
		if curr$>callpoint!.getColumnData("ARE_CCPMT.YEAR")+callpoint!.getColumnData("ARE_CCPMT.MONTH")
			dim msg_tokens$[1]
			msg_tokens$[0]=Translate!.getTranslation("AON_ACCORDING_TO_MONTH_AND_YEAR_ENTERED_THIS_CARD_HAS_EXPIRED")
			msg_id$="GENERIC_WARN"
			gosub disp_message
			callpoint!.setStatus("ABORT-ACTIVATE")
			break
		endif

		msg_id$="CONF_CC_PAYMENT"
		msg_opt$=""
		dim msg_tokens$[1]
		msg_tokens$[0]=cvs(str(num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT")):callpoint!.getDevObject("ar_a_mask")),3)
		gosub disp_message
		if msg_opt$<>"Y"
			callpoint!.setStatus("ABORT-ACTIVATE")
			break
		endif

		dim ars_cc_custsvc$:fnget_tpl$("ARS_CC_CUSTSVC")
		ars_cc_custsvc$=callpoint!.getDevObject("ars_cc_custsvc")
		gateway_id$=ars_cc_custsvc.gateway_id$
		gw_config!=callpoint!.getDevObject("gw_config")

		vectInvoices!=callpoint!.getDevObject("vectInvoices")
		apply_amt!=cast(BBjNumber, num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT")))
		cust_id$=callpoint!.getColumnData("ARE_CCPMT.CUSTOMER_ID")
		cash_rec_cd$=callpoint!.getColumnData("ARE_CCPMT.CASH_REC_CD")

		rem --- Use J2Pay library
		gw! = new GatewayFactory()
		apiSampleParameters! = new JSONObject()
	
		gateway! = gw!.getGateway(AvailableGateways.valueOf(cvs(gateway_id$,3)))
		apiSampleParameters! = gateway!.getApiSampleParameters()
		paramKeys! = apiSampleParameters!.keys()
		msg_id$=""

		while paramKeys!.hasNext()
			gw_attrib$=paramKeys!.next()
			param!=gw_config!.get(gw_attrib$)
			if param!=null()
				dim msg_tokens$[1]
				msg_tokens$[0]=Translate!.getTranslation("AON_MISSING_GATEWAY_CONFIG")+$0A$+"("+gateway_id$+")"
				msg_id$="GENERIC_WARN"
				gosub disp_message
				callpoint!.setStatus("EXIT")
				break
			endif
			apiSampleParameters!.put(gw_attrib$,param!.toString())
		wend
		if msg_id$<>"" then break

		ip$=iff(gw_config!.get("ip")=null(),"127.0.0.1",gw_config!.get("ip"))
		gateway!.setTestMode(Boolean.valueOf(gw_config!.get("testMode")))

		customer! = new Customer()
		customer!.setFirstName(cvs(callpoint!.getColumnData("ARE_CCPMT.NAME_FIRST"),3))
		customer!.setLastName(cvs(callpoint!.getColumnData("ARE_CCPMT.NAME_LAST"),3))
		customer!.setCountry(Country.valueOf(cvs(callpoint!.getColumnData("ARE_CCPMT.CNTRY_ID"),3)))
		customer!.setState(cvs(callpoint!.getColumnData("ARE_CCPMT.STATE_CODE"),3))
		customer!.setCity(cvs(callpoint!.getColumnData("ARE_CCPMT.CITY"),3))
		customer!.setAddress(cvs(callpoint!.getColumnData("ARE_CCPMT.ADDRESS_LINE_1"),3)+" "+cvs(callpoint!.getColumnData("ARE_CCPMT.ADDRESS_LINE_2"),3))
		customer!.setZip(cvs(callpoint!.getColumnData("ARE_CCPMT.ZIP_CODE"),3))
		customer!.setPhoneNumber(cvs(callpoint!.getColumnData("ARE_CCPMT.PHONE_NO"),3))
		customer!.setEmail(cvs(callpoint!.getColumnData("ARE_CCPMT.EMAIL_ADDR"),3))
		customer!.setIp(ip$);rem --- only required by BillPro

		customerCard! = new CustomerCard()
		customerCard!.setName(cvs(callpoint!.getColumnData("ARE_CCPMT.NAME_FIRST"),3)+" "+cvs(callpoint!.getColumnData("ARE_CCPMT.NAME_LAST"),3))
		customerCard!.setNumber(cvs(callpoint!.getColumnData("ARE_CCPMT.CARD_NO"),3))
		customerCard!.setCvv(cvs(callpoint!.getColumnData("ARE_CCPMT.SECURITY_CD"),3))
		customerCard!.setExpiryMonth(cvs(callpoint!.getColumnData("ARE_CCPMT.MONTH"),3))
		customerCard!.setExpiryYear(cvs(callpoint!.getColumnData("ARE_CCPMT.YEAR"),3))

		callpoint!.setColumnData("ARE_CCPMT.NAME_FIRST","",1)
		callpoint!.setColumnData("ARE_CCPMT.NAME_LAST","",1)
		callpoint!.setColumnData("ARE_CCPMT.CARD_NO","",1)
		callpoint!.setColumnData("ARE_CCPMT.SECURITY_CD","",1)
		callpoint!.setColumnData("ARE_CCPMT.MONTH","",1)
		callpoint!.setColumnData("ARE_CCPMT.YEAR","",1)

		response! = new HTTPResponse()
		response! = gateway!.purchase(apiSampleParameters!, customer!, customerCard!, Currency.USD, apply_amt!.floatValue())
 
		rem --- process returned response
		trans_id$=""
		trans_msg$=Translate!.getTranslation("AON_NO_RESPONSE","No response received. Transaction not processed.",1)
		cash_msg$=""

		full_response!=response!.getJSONResponse()
		if full_response!<>null()
			trans_id$=full_response!.get("lr").get("transactionId",err=*next)
			trans_msg$=full_response!.get("lr").get("message")

			rem --- if transaction was approved, create cash receipt
			if response!.isSuccessful()
				gosub create_cash_receipt
			endif

			rem --- write response text to art_response
			if trans_id$<>""
				response_text$=full_response!.toString()
				trans_amount$=str(full_response!.get("lr").get("amount",err=*next))
				trans_approved$=iff(response!.isSuccessful(),"A","D");rem A=approved, D=declined
				if trans_approved$="D" and trans_amount$="" then trans_amount$=str(apply_amt!);rem use amount we submitted if it isn't in the return response
				gosub write_to_response_log
			endif
		endif

		gosub remove_batch_lock
		if callpoint!.getDevObject("br_interface")="Y" then gosub update_deposit

		dim msg_tokens$[1]
		msg_tokens$[0]=trans_msg$+$0A$+cash_msg$
		msg_id$="GENERIC_OK"
		gosub disp_message
		callpoint!.setStatus("EXIT")
	else
		rem --- interface_tp$="H" (hosted page), check to make sure one or more invoices selected, confirm, then process

		apply_amt!=cast(BBjNumber, num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT")))
		masked_amt$=cvs(str(num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT")):callpoint!.getDevObject("ar_a_mask")),3)

		if apply_amt!=0
			dim msg_tokens$[1]
			msg_tokens$[0]=Translate!.getTranslation("AON_PLEASE_SELECT_INVOICES_FOR_PAYMENT","Please select invoices for payment.",1)
			msg_id$="GENERIC_WARN"
			gosub disp_message
			callpoint!.setStatus("ABORT-ACTIVATE")
			break
		endif

		msg_id$="CONF_CC_PAYMENT"
		msg_opt$=""
		dim msg_tokens$[1]
		msg_tokens$[0]=masked_amt$
		gosub disp_message

		if msg_opt$<>"Y"
			callpoint!.setStatus("ABORT-ACTIVATE")
		else

			dim ars_cc_custsvc$:fnget_tpl$("ARS_CC_CUSTSVC")
			ars_cc_custsvc$=callpoint!.getDevObject("ars_cc_custsvc")
			gateway_id$=ars_cc_custsvc.gateway_id$
			gw_config!=callpoint!.getDevObject("gw_config")

			vectInvoices!=callpoint!.getDevObject("vectInvoices")
			cust_id$=callpoint!.getColumnData("ARE_CCPMT.CUSTOMER_ID")

		        rem --- using Authorize.net or PayPal hosted page
		        switch gateway_id$
				case "PAYFLOWPRO"

					rem --- get random number to send when requesting secure token
					rem --- set namespace variable using that number
					rem --- PayPal returns that number in the response, so can match number in response to number we're sending to be sure we're processing our payment and not someone else's (multi-user)
					sid!=UUID.randomUUID()
					sid$=sid!.toString()
					callpoint!.setDevObject("sid",sid$)
					ns!=BBjAPI().getNamespace("aon","credit_receipt_payflowpro",1)
					ns!.setValue(sid$,"init")
					ns!.setCallbackForVariableChange(sid$,"custom_event")
		           
					rem --- use BBj's REST API to send sid$ and receive back secure token
					client!=new BBWebClient()
					request!=new BBWebRequest()
					request!.setURI(gw_config!.get("requestTokenURL"))
					request!.setMethod("POST")
					request!.setContent("PARTNER="+gw_config!.get("PARTNER")+"&VENDOR="+gw_config!.get("VENDOR")+"&USER="+gw_config!.get("USER")+"&PWD="+gw_config!.get("PWD")+"&TRXTYPE=S&AMT="+str(apply_amt!:"###,###.00")+"&CREATESECURETOKEN=Y&SECURETOKENID="+sid!.toString())
					response! = client!.sendRequest(request!) 
					content!=response!.getBody()
					response!.close()

					tokenID!=content!.substring(content!.indexOf("SECURETOKEN=")+11)
					tokenID$=tokenID!.substring(1,tokenID!.indexOf("&"))

					rem --- If successful in getting secure token, launch hosted page.
					rem --- PayPal Silent Post configuration will contain return URL that runs a BBJSP servlet once payment is completed (or declined).
					rem --- Servlet updates namespace variable sid$ with response text.
					rem --- Registered callback for namespace variable change will cause PayPal response routine in ACUS to get executed,
					rem --- which will record response in art_response and post cash receipt, if applicable.

					if content!.contains("RESULT=0")
						rem --- set devObject to indicate 'payment' status - check when exiting and warn if still in "payment" status (i.e., no response received yet)
						callpoint!.setDevObject("payment_status","payment")
						setprogbar!=BBjAPI().getNamespace("aon","credit_progbar",1)
						setprogbar!.setValue(sid$,"init")
						setprogbar!.setCallbackForVariableChange(sid$,"custom_event")
						returnCode=scall("bbj "+$22$+"are_hosted.aon"+$22$+" - -g"+gateway_id$+" -t"+tokenID$+" -s"+sid$+" -l"+gw_config!.get("launchURL"))
					else
						trans_msg$=Translate!.getTranslation("AON_UNABLE_TO_ACQUIRE_SECURE_TOKEN")+$0A$+content!
						dim msg_tokens$[1]
						msg_tokens$[0]=trans_msg$
						msg_id$="GENERIC_WARN"
						gosub disp_message
						callpoint!.setStatus("EXIT")
					endif
				break
				case "AUTHORIZE "
					ns!=BBjAPI().getNamespace("aon","credit_receipt_authorize",1)
					ns!.setCallbackForNamespace("custom_event")

					rem --- Create the order object to add to transaction request
					rem --- Currently filling with unique ID so we can link this auth-capture to returned response
					rem --- Authorize.net next API version should allow refID to be passed that will be returned in Webhook, obviating need for unique ID in order

					sid!=UUID.randomUUID()
					sid$=sid!.toString()
					callpoint!.setDevObject("sid",sid$)
					order! = new OrderType()
					order!.setInvoiceNumber(cust_id$)
					order!.setDescription(sid$)

					confirmation_page$=fnbuildURL$(gw_config!.get("confirmationPage"))
					embed_info$="sid="+sid$
					confirmation_page$=confirmation_page$+"?"+URLEncoder.encode(embed_info$, "UTF-8")
					launch_page$=fnbuildURL$(gw_config!.get("launchPage"))

					ApiOperationBase.setEnvironment(Environment.valueOf(gw_config!.get("environment")))

					merchantAuthenticationType!  = new MerchantAuthenticationType() 
					merchantAuthenticationType!.setName(gw_config!.get("name"))
					merchantAuthenticationType!.setTransactionKey(gw_config!.get("transactionKey"))
					ApiOperationBase.setMerchantAuthentication(merchantAuthenticationType!)

					rem Create the payment transaction request
					txnRequest! = new TransactionRequestType()
					txnRequest!.setTransactionType(TransactionTypeEnum.AUTH_CAPTURE_TRANSACTION.value())
					txnRequest!.setAmount(new BigDecimal(apply_amt!).setScale(2, RoundingMode.CEILING))
					txnRequest!.setOrder(order!)

					setting1! = new SettingType()
					setting1!.setSettingName("hostedPaymentButtonOptions")
					setting1!.setSettingValue("{"+$22$+"text"+$22$+": "+$22$+"Pay"+$22$+"}")
	                        
					setting2! = new SettingType()
					setting2!.setSettingName("hostedPaymentOrderOptions")
					setting2!.setSettingValue("{"+$22$+"show"+$22$+": false}")

					setting3! = new SettingType()
					setting3!.setSettingName("hostedPaymentReturnOptions")
					setting3!.setSettingValue("{"+$22$+"showReceipt"+$22$+": true, "+$22$+"url"+$22$+": "+$22$+confirmation_page$+$22$+", "+$22$+"urlText"+$22$+": "+$22$+"Continue"+$22$+"}")

					setting4! = new SettingType()
					setting4!.setSettingName("hostedPaymentPaymentOptions")
					setting4!.setSettingValue("{"+$22$+"showBankAccount"+$22$+": false}")

					alist! = new ArrayOfSetting()
					alist!.getSetting().add(setting1!)
					alist!.getSetting().add(setting2!)
					alist!.getSetting().add(setting3!)
					alist!.getSetting().add(setting4!)

					apiRequest! = new GetHostedPaymentPageRequest()
					apiRequest!.setTransactionRequest(txnRequest!)
					apiRequest!.setHostedPaymentSettings(alist!)

					controller! = new GetHostedPaymentPageController(apiRequest!)
					controller!.execute()

					authResponse! = new GetHostedPaymentPageResponse()
					authResponse! = controller!.getApiResponse()

					rem --- if GetHostedPaymentPageResponse() indicates success, launch our 'starter' page.
					rem --- 'starter' page gets passed the token, and has a 'proceed to checkout' button, which does a POST to https://test.authorize.net/payment/payment, passing along the token.
					rem --- Authorize.net is configured with Webhook for the auth-capture transaction. Webhook contains URL that runs our BBJSP servlet.
					rem --- Servlet updates namespace variable 'authresp' with response text
					rem --- registered callback for variable change will cause authorize_response routine to get executed
					rem --- authorize_response will parse trans_id from the webhook, then send a getTransactionDetailsRequest
					rem --- returned getTransactionDetailsResponse should contain order with our sid$ in the order description
					rem --- if sid$ matches saved_sid$, then this is our response (and not someone else's who might also be processing payments)
					rem --- assuming this is our response, record the Webhook response in art_response and create cash receipt, if applicable

					if authResponse!.getMessages().getResultCode()=MessageTypeEnum.OK
						rem --- set devObject to indicate 'payment' status - check when exiting and warn if still in "payment" status (i.e., no response received yet)
						callpoint!.setDevObject("payment_status","payment")
						setprogbar!=BBjAPI().getNamespace("aon","credit_progbar",1)
						setprogbar!.setValue(sid$,"init")
						setprogbar!.setCallbackForVariableChange(sid$,"custom_event")
						returnCode=scall("bbj "+$22$+"are_hosted.aon"+$22$+" - -g"+gateway_id$+" -t"+authResponse!.getToken()+" -a"+masked_amt$+" -l"+launch_page$+" -u"+gw_config!.get("gatewayURL")+" -s"+sid$)
					else
						trans_msg$=Translate!.getTranslation("AON_UNABLE_TO_ACQUIRE_SECURE_TOKEN")+$0a$+authResponse!.getMessages().getMessage().get(0).getCode()+$0a$+authResponse!.getMessages().getMessage().get(0).getText()
						dim msg_tokens$[1]
						msg_tokens$[0]=trans_msg$
						msg_id$="GENERIC_WARN"
						gosub disp_message
						callpoint!.setStatus("EXIT")
					endif
				break
				case default
					rem --- shouldn't get here unless new hosted gateway is specified in params, added to adc_gatewayhdr, and no case has been built for handling it
				break
			swend
		endif
	endif
[[ARE_CCPMT.ACUS]]
rem --- Process custom event -- used in this pgm to select/de-select checkboxes in grid
rem --- See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info
rem --- This routine is executed when callbacks have been set to run a 'custom event'
rem --- Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind
rem --- of event it is... in this case, we're toggling checkboxes on/off in form grid control

	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ev!=BBjAPI().getLastEvent()

	if ev!.getEventName()="BBjNamespaceEvent"

		vectInvoices!=callpoint!.getDevObject("vectInvoices")
		apply_amt!=cast(BBjNumber, num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT")))
		cust_id$=callpoint!.getColumnData("ARE_CCPMT.CUSTOMER_ID")
		cash_rec_cd$=callpoint!.getColumnData("ARE_CCPMT.CASH_REC_CD")

		gw_config!=callpoint!.getDevObject("gw_config")
		gateway_id$=gw_config!.get("gateway_id")

		trans_msg$=Translate!.getTranslation("AON_UNTRAPPED_NAMESPACE_EVENT")
		cash_msg$=""

		ns_name$=ev!.getNamespaceName()
		ns!=BBjAPI().getExistingNamespace(ns_name$)
		if pos("authorize"=ns_name$)
			rem --- response (webhook) from Authorize.net
			newValue! = new JSONObject(ev!.getNewValue())
			trans_id$=newValue!.get("payload").get("id")

			ApiOperationBase.setEnvironment(Environment.valueOf(gw_config!.get("environment")))

			merchantAuthenticationType!  = new MerchantAuthenticationType() 
			merchantAuthenticationType!.setName(gw_config!.get("name"))
			merchantAuthenticationType!.setTransactionKey(gw_config!.get("transactionKey"))
			ApiOperationBase.setMerchantAuthentication(merchantAuthenticationType!)

			getRequest! = new GetTransactionDetailsRequest()
			getRequest!.setMerchantAuthentication(merchantAuthenticationType!)
			getRequest!.setTransId(trans_id$)

			controller! = new GetTransactionDetailsController(getRequest!)
			controller!.execute()
			authResponse! = controller!.getApiResponse()
			if authResponse!.getMessages().getResultCode()=MessageTypeEnum.OK
				resp_cust$=authResponse!.getTransaction().getOrder().getInvoiceNumber()
				resp_sid$=authResponse!.getTransaction().getOrder().getDescription()
				resp_code=authResponse!.getTransaction().getResponseCode()
				payment_amt$=str(authResponse!.getTransaction().getAuthAmount())
				trans_msg$=authResponse!.getMessages().getMessage().get(0).getCode()+$0a$+authResponse!.getMessages().getMessage().get(0).getText()

				rem if resp_sid$ matches callpoint!.getDevObject("sid") then this is a response to OUR payment
				rem this is a workaround until Authorize.net returns our assigned refID in the webhook response
				rem until then, don't know if this event got triggered by us, or someone else processing a credit card payment
				rem so we have to put the sid$ in something that gets returned in the full response, and get that full response
				rem instead of just using the returned webhook
				rem may want to always get full response to record in art_response anyway, since webhook payload is abridged   
   
				if resp_sid$=callpoint!.getDevObject("sid")
					response_text$=newValue!.toString()
					trans_amount$=payment_amt$
					trans_approved$=iff(resp_code,"A","D");rem A=approved, D=declined
					if resp_code
						gosub create_cash_receipt
					else
						cash_msg$=""
					endif
					gosub write_to_response_log
				else
					rem --- if webhook response came in for a different transaction, just resume (keep waiting for OUR response)
					rem --- this could happen if >1 session is accepting a credit card payment at the same time
					break
				endif
				callpoint!.setDevObject("payment_status","response")
			else
				trans_msg$=Translate!.getTranslation("AON_UNABLE_TO_PROCESS_GETTRANSACTIONDETAILSREQUEST_METHOD")
			endif
			ns!.removeCallbackForNamespace()

		else
			if pos("payflowpro"=ns_name$)
				rem --- response (silent post) from PayPal
				old_value$=ev!.getOldValue()
				if old_value$="init"
					new_value$=ev!.getNewValue()
					trans_id$=fnparse$(new_value$,"PNREF=","&")
					payment_amt$=str(num(fnparse$(new_value$,"AMT=","&")))
					trans_msg$=fnparse$(new_value$,"RESPMSG=","&")
					result$=fnparse$(new_value$,"RESULT=","&")
					if result$="0"
						gosub create_cash_receipt
					else
						cash_msg$=""
					endif
					if cvs(trans_id$,3)<>""
						response_text$=new_value$
						trans_amount$=payment_amt$
						trans_approved$=iff(result$="0","A","D");rem A=approved, D=declined
						gosub write_to_response_log
					endif
					rem --- set devObject to indicate 'response' status
					callpoint!.setDevObject("payment_status","response")
				endif
				sid$=callpoint!.getDevObject("sid")
				ns!.removeCallbackForVariableChange(sid$)
			else
				if pos("credit_progbar"=ns_name$)
					bbjHome$ =  System.getProperty("basis.BBjHome")
					title$=form!.getTitle()
					progtext$=Translate!.getTranslation("AON_AWAITING_RESPONSE","Awaiting response",1)+"..."
					progWin! = SysGui!.addWindow(SysGUI!.getAvailableContext(),Form!.getX()+Form!.getWidth()/2,Form!.getY()+Form!.getHeight()/2,300,100,title$,$000C0000$)
					nxt_ctlID=util.getNextControlID()
					progWin!.addImageCtrl(nxt_ctlID,15,15,33,33,bbjHome$+"/utils/reporting/bbjasper/images/CreatingReport.gif")
					nxt_ctlID=util.getNextControlID()
					sText!=progWin!.addStaticText(nxt_ctlID,75,20,150,50,progtext$)
					font! = sText!.getFont()
					fontBold! = SysGui!.makeFont(font!.getName(), font!.getSize()+2, SysGui!.BOLD)
					sText!.setFont(fontBold!)
					nxt_ctlID=util.getNextControlID()
					cncl!=progWin!.addButton(nxt_ctlID,100,70,75,25,Translate!.getTranslation("AON_CANCEL"))
					cncl!.setCallback(cncl!.ON_BUTTON_PUSH,"custom_event")
					callpoint!.setDevObject("progwincancel",nxt_ctlID)
					callpoint!.setDevObject("progwin",progWin!)
					break
				endif
			endif
		endif

		gosub remove_batch_lock
		if callpoint!.getDevObject("br_interface")="Y" then gosub update_deposit

		progWin!=callpoint!.getDevObject("progwin")
		if progWin!<>null() then progWin!.destroy(err=*next)

		dim msg_tokens$[1]
		msg_tokens$[0]=trans_msg$+$0A$+cash_msg$
		msg_id$="GENERIC_OK"
		gosub disp_message
		callpoint!.setStatus("EXIT")

	else
		if ev!.getEventName()="BBjTimerEvent" and gui_event.y=10000
			BBjAPI().removeTimer(10000)
			callpoint!.setStatus("EXIT")
		else
			ctl_ID=dec(gui_event.ID$)
			if ctl_ID=num(callpoint!.getDevObject("openInvoicesGridId"))
				if gui_event.code$="N"
					notify_base$=notice(gui_dev,gui_event.x%)
					dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
					notice$=notify_base$
					curr_row = dec(notice.row$)
					curr_col = dec(notice.col$)
				endif
				switch notice.code
					case 12;rem grid_key_press
						if notice.wparam=32 gosub switch_value
					break
					case 14;rem grid_mouse_up
						if notice.col=0 gosub switch_value
					break
					case 7;rem edit stop - can only edit pay and disc taken cols
						if curr_col=num(callpoint!.getDevObject("pay_col")) or curr_col=num(callpoint!.getDevObject("disc_taken_col"))  then
							vectInvoices!=callpoint!.getDevObject("vectInvoices")
							openInvoicesGrid!=callpoint!.getDevObject("openInvoicesGrid")
							grid_cols = num(callpoint!.getDevObject("grid_cols"))
							inv_bal_col=num(callpoint!.getDevObject("inv_bal_col"))
							disc_col=num(callpoint!.getDevObject("disc_col"))
							pay_col=num(callpoint!.getDevObject("pay_col"))
							disc_taken_col=num(callpoint!.getDevObject("disc_taken_col"))
							end_bal_col=num(callpoint!.getDevObject("end_bal_col"))
							oa_inv$=callpoint!.getDevObject("oa_inv")
							tot_pay=num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT"))
							vect_pay_amt=num(vectInvoices!.get(curr_row*grid_cols+pay_col))
							vect_disc_taken=num(vectInvoices!.get(curr_row*grid_cols+disc_taken_col))
							vect_inv_bal=num(vectInvoices!.get(curr_row*grid_cols+inv_bal_col))
							grid_pay_amt = num(openInvoicesGrid!.getCellText(curr_row,pay_col))
							grid_disc_taken = num(openInvoicesGrid!.getCellText(curr_row,disc_taken_col))
							if grid_pay_amt<0 then grid_pay_amt=0
							if grid_disc_taken<0 then grid_disc_taken=0
							if grid_pay_amt<=0 then grid_disc_taken=0
							openInvoicesGrid!.setCellText(curr_row,end_bal_col,str(vect_inv_bal-grid_pay_amt-grid_disc_taken))
							if vectInvoices!.get(curr_row*grid_cols+1)<>oa_inv$ and num(openInvoicesGrid!.getCellText(curr_row,end_bal_col))<0
								msg_id$="GENERIC_WARN"
								dim msg_tokens$[1]
								msg_tokens$[1]=Translate!.getTranslation("AON_CREDIT_BALANCE_PLEASE_CORRECT","You have created a credit balance. Please correct the payment or discount amounts.",1)
								gosub disp_message
								grid_pay_amt=0
								grid_disc_taken=0
							endif
							tot_pay=tot_pay-vect_pay_amt+grid_pay_amt
							vectInvoices!.set(curr_row*grid_cols+pay_col,str(grid_pay_amt))
							vectInvoices!.set(curr_row*grid_cols+disc_taken_col,str(grid_disc_taken))
							vectInvoices!.set(curr_row*grid_cols+end_bal_col,str(vect_inv_bal-grid_pay_amt-grid_disc_taken))
							openInvoicesGrid!.setCellText(curr_row,pay_col,str(grid_pay_amt))
							openInvoicesGrid!.setCellText(curr_row,disc_taken_col,str(grid_disc_taken))
							openInvoicesGrid!.setCellText(curr_row,end_bal_col,str(vect_inv_bal-grid_pay_amt-grid_disc_taken))
							callpoint!.setColumnData("<<DISPLAY>>.APPLY_AMT",str(tot_pay),1)
							if grid_pay_amt>0
								vectInvoices!.set(curr_row*grid_cols,"Y")
								openInvoicesGrid!.setCellState(curr_row,0,1)
							else
								vectInvoices!.set(curr_row*grid_cols,"")
								openInvoicesGrid!.setCellState(curr_row,0,0)
							endif
							gosub reset_timer
							callpoint!.setDevObject("vectInvoices",vectInvoices!)
							callpoint!.setDevObject("openInvoicesGrid",openInvoicesGrid!)
						endif
					break
					case 8;rem edit start
						grid_cols = num(callpoint!.getDevObject("grid_cols"))
						comment_col=grid_cols-1
		 				if curr_col=comment_col
							vectInvoices!=callpoint!.getDevObject("vectInvoices")
							openInvoicesGrid!=callpoint!.getDevObject("openInvoicesGrid")
							disp_text$=openInvoicesGrid!.getCellText(clicked_row,comment_col)
							sv_disp_text$=disp_text$

							editable$="YES"
							force_loc$="NO"
							baseWin!=null()
							startx=0
							starty=0
							shrinkwrap$="NO"
							html$="NO"
							dialog_result$=""
							spellcheck=1

							call stbl("+DIR_SYP")+ "bax_display_text.bbj",
:								"Cash Receipts Detail Comments",
:								disp_text$, 
:								table_chans$[all], 
:								editable$, 
:								force_loc$, 
:								baseWin!, 
:								startx, 
:								starty, 
:								shrinkwrap$, 
:								html$, 
:								dialog_result$,
:								spellcheck

							if disp_text$<>sv_disp_text$
								openInvoicesGrid!.setCellText(curr_row,comment_col,disp_text$)
								vectInvoices!.setItem(curr_row*grid_cols+comment_col,disp_text$)
							endif

							callpoint!.setStatus("ACTIVATE")
						endif
					break
					case default
					break
				swend
			else
				if ev!.getEventName()="BBjButtonPushEvent" and ctl_ID=callpoint!.getDevObject("progwincancel")
					progwin!=callpoint!.getDevObject("progwin")
					progwin!.destroy()
				endif
			endif
		endif
	endif
[[ARE_CCPMT.ASIZ]]
rem --- Resize grids
	formHeight=Form!.getHeight()
	formWidth=Form!.getWidth()
	openInvoicesGrid!=callpoint!.getDevObject("openInvoicesGrid")
	gridYpos=openInvoicesGrid!.getY()
	gridXpos=openInvoicesGrid!.getX()
	availableHeight=formHeight-gridYpos

	openInvoicesGrid!.setSize(formWidth-2*gridXpos,availableHeight-8)
	openInvoicesGrid!.setFitToGrid(1)
[[ARE_CCPMT.AWIN]]
rem --- Declare classes used

	use java.math.BigDecimal
	use java.math.RoundingMode
	use java.net.URLEncoder
	use java.util.Iterator
	use java.util.UUID

	use org.json.JSONObject

	use com.tranxactive.j2pay.gateways.parameters.Customer
	use com.tranxactive.j2pay.gateways.parameters.CustomerCard
	use com.tranxactive.j2pay.gateways.parameters.Currency
	use com.tranxactive.j2pay.gateways.parameters.Country

	use com.tranxactive.j2pay.gateways.core.Gateway
	use com.tranxactive.j2pay.gateways.core.GatewayFactory
	use com.tranxactive.j2pay.gateways.core.AvailableGateways
	use com.tranxactive.j2pay.gateways.core.GatewaySampleParameters

	use com.tranxactive.j2pay.net.HTTPResponse
	use com.tranxactive.j2pay.net.JSONHelper

	use net.authorize.Environment
	use net.authorize.api.contract.v1.MerchantAuthenticationType
	use net.authorize.api.contract.v1.TransactionRequestType
	use net.authorize.api.contract.v1.SettingType
	use net.authorize.api.contract.v1.ArrayOfSetting
	use net.authorize.api.contract.v1.MessageTypeEnum
	use net.authorize.api.contract.v1.TransactionTypeEnum
	use net.authorize.api.contract.v1.GetHostedPaymentPageRequest
	use net.authorize.api.contract.v1.GetHostedPaymentPageResponse
	use net.authorize.api.contract.v1.GetTransactionDetailsRequest
	use net.authorize.api.contract.v1.OrderType
	use net.authorize.api.controller.base.ApiOperationBase
	use net.authorize.api.controller.GetHostedPaymentPageController
	use net.authorize.api.controller.GetTransactionDetailsController

	use ::ado_util.src::util	
	use ::sys/prog/bao_encryptor.bbj::Encryptor

	use ::REST/BBWebClient.bbj::BBWebClient
	use ::REST/BBWebClient.bbj::BBWebRequest
	use ::REST/BBWebClient.bbj::BBWebResponse

rem --- set devObjects
	call stbl("+DIR_PGM")+"adc_getmask.aon","","AR","A","",ar_a_mask$,0,0
	callpoint!.setDevObject("ar_a_mask",ar_a_mask$)
	callpoint!.setDevObject("payment_status","")
	callpoint!.setDevObject("vectInvoices",BBjAPI().makeVector())

rem --- Open files

	num_files=10
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ART_INVHDR",open_opts$[1]="OTA"
	open_tables$[2]="ART_RESPHDR",open_opts$[2]="OTA"
	open_tables$[3]="ART_RESPDET",open_opts$[3]="OTA"	
	open_tables$[4]="ARE_CASHHDR",open_opts$[4]="OTA"
	open_tables$[5]="ARE_CASHDET",open_opts$[5]="OTA"
	open_tables$[6]="ARE_CASHBAL",open_opts$[6]="OTA"
	open_tables$[7]="ARS_CC_CUSTSVC",open_opts$[7]="OTA"
	open_tables$[8]="ARS_GATEWAYDET",open_opts$[8]="OTA"
	open_tables$[9]="ARS_PARAMS",open_opts$[9]="OTA"
	open_tables$[10]="ARE_DEPOSIT",open_opts$[10]="OTA"

	gosub open_tables

rem --- Get Bank Rec interface flag
	ars_params=fnget_dev("ARS_PARAMS")
	dim ars_params$:fnget_tpl$("ARS_PARAMS")
	readrecord(ars_params,key=firm_id$+"AR00",dom=std_missing_params)ars_params$
	callpoint!.setDevObject("br_interface",ars_params.br_interface$)
	callpoint!.setDevObject("deposit_id","")

rem --- Interface to gl?
	gl$="N"
	status=0
	call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,"ARE_CASHHDR","AR",glw11$,gl$,status
	if status<>0 goto std_exit

	callpoint!.setDevObject("gl_interface",gl$)

rem --- Add open invoice grid to form
	nxt_ctlID = util.getNextControlID()
	tmpCtl!=callpoint!.getControl("ARE_CCPMT.EMAIL_ADDR")
	grid_y=tmpCtl!.getY()+tmpCtl!.getHeight()+5
	openInvoicesGrid! = Form!.addGrid(nxt_ctlID,5,grid_y,895,125); rem --- ID, x, y, width, height
	callpoint!.setDevObject("openInvoicesGrid",openInvoicesGrid!)
	callpoint!.setDevObject("openInvoicesGridId",str(nxt_ctlID))
	callpoint!.setDevObject("grid_cols","12")
	callpoint!.setDevObject("grid_rows","10")
	callpoint!.setDevObject("inv_bal_col","5")
	callpoint!.setDevObject("disc_col","6")
	callpoint!.setDevObject("pay_col","8")
	callpoint!.setDevObject("disc_taken_col","9")
	callpoint!.setDevObject("end_bal_col","10")
	callpoint!.setDevObject("interface_tp","")

	gosub format_grid

	openInvoicesGrid!.setTabAction(SysGUI!.GRID_NAVIGATE_GRID)
	openInvoicesGrid!.setTabActionSkipsNonEditableCells(1)
	openInvoicesGrid!.setColumnEditable(8,1)
	openInvoicesGrid!.setColumnEditable(9,1)
	openInvoicesGrid!.setColumnEditable(11,1)

rem --- Reset window size
	util.resizeWindow(Form!, SysGui!)

rem --- set callbacks - processed in ACUS callpoint
	openInvoicesGrid!.setCallback(openInvoicesGrid!.ON_GRID_KEY_PRESS,"custom_event")
	openInvoicesGrid!.setCallback(openInvoicesGrid!.ON_GRID_MOUSE_UP,"custom_event")
	openInvoicesGrid!.setCallback(openInvoicesGrid!.ON_GRID_EDIT_STOP,"custom_event")
	openInvoicesGrid!.setCallback(openInvoicesGrid!.ON_GRID_EDIT_START,"custom_event")
[[ARE_CCPMT.<CUSTOM>]]
rem ==========================================================================
format_grid: rem --- Let Barista create/format the grid
rem ==========================================================================

	ar_a_mask$=callpoint!.getDevObject("ar_a_mask")

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0] = callpoint!.getColumnAttributeTypes()
	grid_cols = num(callpoint!.getDevObject("grid_cols"))
	grid_rows = num(callpoint!.getDevObject("grid_rows"))
	dim attr_grid_col$[grid_cols,len(attr_def_col_str$[0,0])/5]

	column_no = 1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SELECT"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_PAY")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"
	attr_grid_col$[column_no,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="1"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="5"

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="INVOICE_NO"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_INVOICE_NO")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="10"

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="INVOICE_DATE"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_INVOICE_DATE")
	attr_grid_col$[column_no,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="5"
	attr_grid_col$[column_no,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="10"

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DUE_DATE"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DUE_DATE")
	attr_grid_col$[column_no,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="5"
	attr_grid_col$[column_no,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="10"

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="AMOUNT"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_AMOUNT")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	attr_grid_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=ar_a_mask$

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="BALANCE"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_BALANCE")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	attr_grid_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=ar_a_mask$

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="AVAIL_DISC"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_AVAIL_DISC")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	attr_grid_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=ar_a_mask$

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DISC_DATE"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DISC_DATE")
	attr_grid_col$[column_no,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="5"
	attr_grid_col$[column_no,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="10"

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="PAY_AMOUNT"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_PAYMENT_AMT")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	attr_grid_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=ar_a_mask$

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DISC_TAKEN"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DISC_AMT")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	attr_grid_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=ar_a_mask$

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="END_BALANCE"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_END_BALANCE")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	attr_grid_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=ar_a_mask$

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="COMMENT"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_COMMENTS")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="100"

	for curr_attr=1 to grid_cols
		attr_grid_col$[0,1] = attr_grid_col$[0,1] + 
:			pad("ARE_CCPMT." + attr_grid_col$[curr_attr, fnstr_pos("DVAR", attr_def_col_str$[0,0], 5)], 40)
	next curr_attr

	attr_disp_col$=attr_grid_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,openInvoicesGrid!,"COLH-LINES-LIGHT-AUTO-SIZEC-MULTI-DATES-CHECKS",grid_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_grid_col$[all]

	return

rem ==========================================================================
get_open_invoices: rem --- create vector of invoices with bal>0, taking into account anything entered but not yet posted
rem ==========================================================================

	art_invhdr=fnget_dev("ART_INVHDR")
	dim art_invhdr$:fnget_tpl$("ART_INVHDR")
	are_cashbal=fnget_dev("ARE_CASHBAL")
	dim are_cashbal$:fnget_tpl$("ARE_CASHBAL")

	cust_id$=callpoint!.getColumnData("ARE_CCPMT.CUSTOMER_ID")
	ar_type$=art_invhdr.ar_type$;rem --- ar_type always '  '

	vectInvoices!=BBjAPI().makeVector()
	oa_inv$="OA"+stbl("+SYSTEM_DATE")(4)
	callpoint!.setDevObject("oa_inv",oa_inv$)
	oa_flag=0

	read (art_invhdr,key=firm_id$+ar_type$+cust_id$,dom=*next)

	while 1
		invky$=key(art_invhdr,end=*break)
		if pos(firm_id$+ar_type$+cust_id$=invky$)<>1 then break
		readrecord(art_invhdr)art_invhdr$
		inv_bal=num(art_invhdr.invoice_bal$)
		if inv_bal and arc_cashcode.disc_flag$="Y" and stbl("+SYSTEM_DATE")<= pad(art_invhdr.disc_date$,8) 
			disc_amt=art_invhdr.disc_allowed-art_invhdr.disc_taken
			if disc_amt<0 then disc_amt=0
		else
			disc_amt=0
		endif

		rem --- applied but not yet posted
		redim are_cashbal$
		read record(are_cashbal,key=firm_id$+ar_type$+are_cashbal.reserved_str$+cust_id$+art_invhdr.ar_inv_no$,dom=*next)are_cashbal$
		if arc_cashcode.disc_flag$="Y" then disc_amt=disc_amt-num(are_cashbal.discount_amt$)
		inv_bal=inv_bal-num(are_cashbal.apply_amt$)-num(are_cashbal.discount_amt$)

		if inv_bal<=0 then continue
		vectInvoices!.add("")
		vectInvoices!.add(art_invhdr.ar_inv_no$)
		vectInvoices!.add(date(jul(art_invhdr.invoice_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		vectInvoices!.add(date(jul(art_invhdr.inv_due_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		vectInvoices!.add(art_invhdr.invoice_amt$)
		vectInvoices!.add(str(inv_bal))
		vectInvoices!.add(str(disc_amt))
		vectInvoices!.add(date(jul(art_invhdr.disc_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		vectInvoices!.add("0")
		vectInvoices!.add("0")
		vectInvoices!.add(str(inv_bal))
		vectInvoices!.add(art_invhdr.memo_1024$)
		if art_invhdr.ar_inv_no$=oa_inv$ then oa_flag=1
	wend
	rem --- add final row (if need-be) to accommodate on-account payment (e.g., taking a deposit or pre-payment)
	if !oa_flag
		vectInvoices!.add("")
		vectInvoices!.add(oa_inv$)
		vectInvoices!.add(date(jul(stbl("+SYSTEM_DATE"),"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		vectInvoices!.add(date(jul(stbl("+SYSTEM_DATE"),"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		vectInvoices!.add("0")
		vectInvoices!.add("0")
		vectInvoices!.add("0")
		vectInvoices!.add(date(jul(stbl("+SYSTEM_DATE"),"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		vectInvoices!.add("0")
		vectInvoices!.add("0")
		vectInvoices!.add("0")
		vectInvoices!.add("")
	endif

	callpoint!.setDevObject("vectInvoices",vectInvoices!)

	return

rem ==========================================================================
fill_grid: rem --- fill grid with vector of unpaid invoices
rem ==========================================================================
	if info(3,6)<>"5" then SysGUI!.setRepaintEnabled(0)
	openInvoicesGrid!=callpoint!.getDevObject("openInvoicesGrid")
	if vectInvoices!.size()

		numrow=vectInvoices!.size()/openInvoicesGrid!.getNumColumns()
		openInvoicesGrid!.clearMainGrid()
		openInvoicesGrid!.setColumnStyle(0,SysGUI!.GRID_STYLE_UNCHECKED)
		openInvoicesGrid!.setNumRows(numrow)
		openInvoicesGrid!.setCellText(0,0,vectInvoices!)
		openInvoicesGrid!.resort()
	endif
	if info(3,6)<>"5" then SysGUI!.setRepaintEnabled(1)
return

rem ==========================================================================
switch_value:rem --- Switch Check Values
rem ==========================================================================
	if info(3,6)<>"5" then SysGUI!.setRepaintEnabled(0)
	openInvoicesGrid!=callpoint!.getDevObject("openInvoicesGrid")
	vectInvoices!=callpoint!.getDevObject("vectInvoices")
	grid_cols=num(callpoint!.getDevObject("grid_cols"))
	inv_bal_col=num(callpoint!.getDevObject("inv_bal_col"))
	disc_col=num(callpoint!.getDevObject("disc_col"))
	pay_col=num(callpoint!.getDevObject("pay_col"))
	disc_taken_col=num(callpoint!.getDevObject("disc_taken_col"))
	end_bal_col=num(callpoint!.getDevObject("end_bal_col"))

	TempRows!=openInvoicesGrid!.getSelectedRows()
	tot_pay=num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT"))

	if TempRows!.size()>0
		for curr_row=1 to TempRows!.size()
			if openInvoicesGrid!.getCellState(TempRows!.getItem(curr_row-1),0)=0
				openInvoicesGrid!.setCellState(TempRows!.getItem(curr_row-1),0,1)
				inv_disc_taken=num(vectInvoices!.get(TempRows!.getItem(curr_row-1)*grid_cols+disc_col))
				inv_pay=num(vectInvoices!.get(TempRows!.getItem(curr_row-1)*grid_cols+inv_bal_col))-inv_disc_taken
				vectInvoices!.set(TempRows!.getItem(curr_row-1)*grid_cols,"Y")
				vectInvoices!.set(TempRows!.getItem(curr_row-1)*grid_cols+pay_col,str(inv_pay))
				vectInvoices!.set(TempRows!.getItem(curr_row-1)*grid_cols+disc_taken_col,str(inv_disc_taken))
				vectInvoices!.set(TempRows!.getItem(curr_row-1)*grid_cols+end_bal_col,"0")
				openInvoicesGrid!.setCellText(TempRows!.getItem(curr_row-1),pay_col,str(inv_pay))
				openInvoicesGrid!.setCellText(TempRows!.getItem(curr_row-1),disc_taken_col,str(inv_disc_taken))
				openInvoicesGrid!.setCellText(TempRows!.getItem(curr_row-1),end_bal_col,"0")
				tot_pay=tot_pay+inv_pay
			else
				openInvoicesGrid!.setCellState(num(TempRows!.getItem(curr_row-1)),0,0)
				inv_pay=num(vectInvoices!.get(TempRows!.getItem(curr_row-1)*grid_cols+pay_col))
				inv_bal=num(vectInvoices!.get(TempRows!.getItem(curr_row-1)*grid_cols+inv_bal_col))
				vectInvoices!.set(TempRows!.getItem(curr_row-1)*grid_cols,"")
				vectInvoices!.set(TempRows!.getItem(curr_row-1)*grid_cols+pay_col,"0")
				vectInvoices!.set(TempRows!.getItem(curr_row-1)*grid_cols+disc_taken_col,"0")
				vectInvoices!.set(TempRows!.getItem(curr_row-1)*grid_cols+end_bal_col,str(inv_bal))
				openInvoicesGrid!.setCellText(TempRows!.getItem(curr_row-1),pay_col,"0")
				openInvoicesGrid!.setCellText(TempRows!.getItem(curr_row-1),disc_taken_col,"0")
				openInvoicesGrid!.setCellText(TempRows!.getItem(curr_row-1),end_bal_col,str(inv_bal))
				tot_pay=tot_pay-inv_pay
			endif
		next curr_row
		callpoint!.setDevObject("openInvoicesGrid",openInvoicesGrid!)
		callpoint!.setDevObject("vectInvoices",vectInvoices!)

	endif

	callpoint!.setColumnData("<<DISPLAY>>.APPLY_AMT",str(tot_pay),1)

	if info(3,6)<>"5" then SysGUI!.setRepaintEnabled(1)

	gosub reset_timer

	return

rem ==========================================================================
create_cash_receipt:
rem --- in: firm_id$, cust_id$, cash_rec_cd$, apply_amt!, trans_id$, vectInvoices!
rem ==========================================================================

	are_cashhdr=fnget_dev("ARE_CASHHDR")
	are_cashdet=fnget_dev("ARE_CASHDET")
	are_cashbal=fnget_dev("ARE_CASHBAL")

	dim are_cashhdr$:fnget_tpl$("ARE_CASHHDR")
	dim are_cashdet$:fnget_tpl$("ARE_CASHDET")
	dim are_cashbal$:fnget_tpl$("ARE_CASHBAL")

	cash_msg$=Translate!.getTranslation("AON_CASH_RECEIPT_HAS_BEEN_ENTERED","Cash Receipt has been entered.",1)

	batch_no$=stbl("+BATCH_NO")
	deposit_id$=callpoint!.getDevObject("deposit_id")

	redim are_cashhdr$

	are_cashhdr.firm_id$=firm_id$
	are_cashhdr.receipt_date$=callpoint!.getColumnData("ARE_CCPMT.RECEIPT_DATE")
	are_cashhdr.customer_id$=cust_id$
	are_cashhdr.cash_rec_cd$=cash_rec_cd$

	receipt_found=0

	extractrecord(are_cashhdr,key=
:		are_cashhdr.firm_id$+
:		are_cashhdr.ar_type$+
:		are_cashhdr.reserved_key_01$+
:		are_cashhdr.receipt_date$+
:		are_cashhdr.customer_id$+
:		are_cashhdr.cash_rec_cd$+
:		are_cashhdr.ar_check_no$+
:		are_cashhdr.reserved_key_02$,dom=*next)are_cashhdr$;receipt_found=1

	if receipt_found
		if cvs(are_cashhdr.batch_no$,3)<>batch_no$ or cvs(are_cashhdr.deposit_id$,3)<>deposit_id$
			cash_msg$=Translate!.getTranslation("AON_BATCH_DEPOSIT_MISMATCH_CASH_RECEIPT_NOT_ENTERED",
:				"A cash receipt matching this customer, date and cash receipt code has already been entered using a different batch and/or deposit."+$0A$+
:				"You will need to MANUALLY adjust that cash receipt to reflect this credit card transaction.",1) 
		endif
	endif

	are_cashhdr.payment_amt=are_cashhdr.payment_amt+apply_amt!
	are_cashhdr.batch_no$=batch_no$
	are_cashhdr.deposit_id$=deposit_id$
	are_cashhdr$=field(are_cashhdr$)
	writerecord(are_cashhdr)are_cashhdr$

	rem --- now write are_cashdet and are_cashbal recs for each invoice in vectInvoices!
	for inv_row=0 to vectInvoices!.size()-1 step num(callpoint!.getDevObject("grid_cols"))
		pay_flag$=vectInvoices!.get(inv_row)
		if pay_flag$="Y"
			ar_inv_no$=vectInvoices!.get(inv_row+1)
			invoice_pay$=vectInvoices!.get(inv_row+num(callpoint!.getDevObject("pay_col")))
			invoice_disc$=vectInvoices!.get(inv_row+num(callpoint!.getDevObject("disc_taken_col")))
			invoice_cmt$=vectInvoices!.get(inv_row+num(callpoint!.getDevObject("grid_cols"))-1)
            
			redim are_cashdet$
			redim are_cashbal$

			are_cashdet.firm_id$=firm_id$
			are_cashdet.receipt_date$=are_cashhdr.receipt_date$
			are_cashdet.customer_id$=are_cashhdr.customer_id$
			are_cashdet.cash_rec_cd$=are_cashhdr.cash_rec_cd$
			are_cashdet.ar_inv_no$=ar_inv_no$

			extractrecord(are_cashdet,key=
:				are_cashdet.firm_id$+
:				are_cashdet.ar_type$+
:				are_cashdet.reserved_key_01$+
:				are_cashdet.receipt_date$+
:				are_cashdet.customer_id$+
:				are_cashdet.cash_rec_cd$+
:				are_cashdet.ar_check_no$+
:				are_cashdet.reserved_key_02$+
:				are_cashdet.ar_inv_no$,dom=*next)are_cashdet$;rem advisory locking

			are_cashdet.apply_amt=are_cashdet.apply_amt+num(invoice_pay$)
			are_cashdet.discount_amt=are_cashdet.discount_amt+num(invoice_disc$)
			are_cashdet.batch_no$=are_cashhdr.batch_no$
			are_cashdet.memo_1024$=iff(cvs(are_cashdet.memo_1024$,3)="",invoice_cmt$,are_cashdet.memo_1024$+invoice_cmt$)
			are_cashdet.firm_id$=field(are_cashdet$)
			writerecord(are_cashdet)are_cashdet$

			are_cashbal.firm_id$=firm_id$
			are_cashbal.customer_id$=are_cashhdr.customer_id$
			are_cashbal.ar_inv_no$=ar_inv_no$

			extractrecord(are_cashbal,key=
:				are_cashbal.firm_id$+
:				are_cashbal.ar_type$+
:				are_cashbal.reserved_str$+
:				are_cashbal.customer_id$+
:				are_cashbal.ar_inv_no$,dom=*next)are_cashbal$

			are_cashbal.apply_amt=are_cashbal.apply_amt+num(invoice_pay$)
			are_cashbal$=field(are_cashbal$)
			writerecord(are_cashbal)are_cashbal$

		endif
	next inv_row
    
	return

rem ==========================================================================
write_to_response_log:rem --- write to art_resphdr/det
rem --- in: firm_id$, cust_id$, trans_id$, response_text$, vectInvoices!
rem ==========================================================================

	art_resphdr=fnget_dev("ART_RESPHDR")
	art_respdet=fnget_dev("ART_RESPDET")

	dim art_resphdr$:fnget_tpl$("ART_RESPHDR")
	dim art_respdet$:fnget_tpl$("ART_RESPDET")

	rem --- get sequence number for response records
	call stbl("+DIR_SYP")+"bas_sequences.bbj","CREDIT_TRANS_NO",credit_trans_no$,rd_table_chans$[all],"QUIET"

	art_resphdr.firm_id$=firm_id$
	art_resphdr.credit_trans_no$=credit_trans_no$
	art_resphdr.customer_id$=cust_id$
	art_resphdr.transaction_id$=trans_id$
	art_resphdr.trans_type$="S";rem Sale
	art_resphdr.gateway_id$=gateway_id$
	art_resphdr.amount$=trans_amount$
	art_resphdr.approve_decline$=trans_approved$
	art_resphdr.response_text$=response_text$
	art_resphdr.created_user$=sysinfo.user_id$
	art_resphdr.created_date$=date(0:"%Yd%Mz%Dz")
	art_resphdr.created_time$=date(0:"%Hz%mz")
	art_resphdr.deposit_id$=deposit_id$
	art_resphdr.batch_no$=batch_no$
	art_resphdr$=field(art_resphdr$)
	writerecord(art_resphdr)art_resphdr$

	next_seq=1
	seq_mask$=fill(len(art_respdet.sequence_no$),"0")
	
	for inv_row=0 to vectInvoices!.size()-1 step num(callpoint!.getDevObject("grid_cols"))
		pay_flag$=vectInvoices!.get(inv_row)
		invoice_pay$=vectInvoices!.get(inv_row+num(callpoint!.getDevObject("pay_col")))
		if pay_flag$="Y"
			ar_inv_no$=vectInvoices!.get(inv_row+1)
			redim art_respdet$
			art_respdet.firm_id$=firm_id$
			art_respdet.credit_trans_no$=credit_trans_no$
			art_respdet.sequence_no$=str(next_seq:seq_mask$)
			art_respdet.customer_id$=cust_id$
			art_respdet.transaction_id$=trans_id$
			art_respdet.ar_inv_no$=ar_inv_no$;rem actual invoice selected or OAymmdd
			art_respdet.order_no$="";rem for future use by OP
			art_respdet.apply_amt$=invoice_pay$
			art_respdet$=field(art_respdet$)
			writerecord(art_respdet)art_respdet$
			next_seq=next_seq+1
		endif
	next inv_row

	return

rem ==========================================================================
remove_batch_lock:rem --- remove software lock on batch, if batching
rem ==========================================================================

	batch$=stbl("+BATCH_NO",err=*next)
	if num(batch$)<>0
		lock_table$="ADM_PROCBATCHES"
		lock_record$=firm_id$+stbl("+PROCESS_ID")+batch$
		lock_type$="X"
		lock_status$=""
		lock_disp$=""
		call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$
	endif

	return

rem ==========================================================================
update_deposit:rem --- update deposit record
rem ==========================================================================

	are_deposit=fnget_dev("ARE_DEPOSIT")
	dim are_deposit$:fnget_tpl$("ARE_DEPOSIT")
	batch_no$=callpoint!.getColumnData("ARE_CCPMT.BATCH_NO")
	deposit_id$=callpoint!.getColumnData("ARE_CCPMT.DEPOSIT_ID")
	extractrecord(are_deposit,key=firm_id$+batch_no$+"E"+deposit_id$,knum="AO_BATCH_STAT",dom=*next)are_deposit$
	if are_deposit.deposit_id$=deposit_id$ then
		are_deposit.tot_deposit_amt=are_deposit.tot_deposit_amt+num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT"))
		writerecord(are_deposit)are_deposit$
	endif

	return

rem ==========================================================================
get_gateway_config:rem --- get config for specified gateway
rem --- in: gateway_id$; out: hashmap gw_config! containing config entries
rem ==========================================================================

	ars_gatewaydet=fnget_dev("ARS_GATEWAYDET")
	dim ars_gatewaydet$:fnget_tpl$("ARS_GATEWAYDET")

	encryptor! = new Encryptor()
	config_id$ = "GATEWAY_AUTH"
	encryptor!.setConfiguration(config_id$)

	read(ars_gatewaydet,key=firm_id$+gateway_id$,knum=0,dom=*next)
	gw_config!=new java.util.HashMap()

	while 1
		readrecord(ars_gatewaydet,end=*break)ars_gatewaydet$
		if pos(firm_id$+gateway_id$=ars_gatewaydet$)<>1 then break
		if gw_config!.get("gateway_id")=null() then gw_config!.put("gateway_id",gateway_id$)
		cfg_value$=encryptor!.decryptData(cvs(ars_gatewaydet.config_value$,3))
		if pos("token>"=cfg_value$)
			dim msg_tokens$[1]
			msg_tokens$[0]=Translate!.getTranslation("AON_INVALID_GATEWAY_CONFIG","One or more configuration values for the payment gateway are invalid.",1)+$0A$+"("+gateway_id$+")"
			msg_id$="GENERIC_WARN"
			gosub disp_message
			callpoint!.setStatus("EXIT")
			break
		else
			msg_id$=""
			gw_config!.put(cvs(ars_gatewaydet.config_attr$,3),cfg_value$)
		endif
	wend

	callpoint!.setDevObject("gw_config",gw_config!)

	return

rem ==========================================================================
reset_timer: rem --- reset timer for another 10 seconds from each AVAL, or from grid switch_value
rem ==========================================================================

rem --- Set timer for form - closes after a minute of inactivity
rem --- Only used when interface_tp$="A" (so sensitive info like credit card number and cvv don't remain visible)

	if callpoint!.getDevObject("interface_tp")="A"
		timer_key!=10000
		BBjAPI().removeTimer(10000)
		BBjAPI().createTimer(timer_key!,60,"custom_event")
	endif

	return

rem =====================================================================
rem functions
rem =====================================================================
rem --- parse PayPal response text
rem --- wkx0$=response, wkx1$=key to look for, wkx2$=delim used to separate key/value pairs

def fnparse$(wkx0$,wkx1$,wkx2$)

	wkx3$=""
	wk1=pos(wkx1$=wkx0$)
	if wk1
		wkx3$=wkx0$(wk1+len(wkx1$))
		wk2=pos(wkx2$=wkx3$)
		if wk2
			wkx3$=wkx3$(1,wk2-1)
		endif
	endif
	return wkx3$
	fnend

def fnbuildURL$(config_value$)

	wkURL$="https://"+gw_config!.get("server")
	wkURL$=iff(wkURL$(len(wkURL$),1)="/",wkURL$,wkURL$+"/")
	wkURL$=wkURL$+cvs(stbl("+DBNAME_API"),11)+"/"+config_value$
	return wkURL$
	fnend

#include std_missing_params.src
