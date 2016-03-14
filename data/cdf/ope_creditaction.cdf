[[OPE_CREDITACTION.BSHO]]
rem --- Get credit password

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARS_CREDIT", open_opts$[1]="OTA"

	gosub open_tables

	credit_dev=num(open_chans$[1])
	dim credit_rec$:open_tpls$[1]
	dim user_tpl$:"password:c(6*)"
	start_block = 1

	if start_block then
		find record(credit_dev, key=firm_id$+"AR01", dom=*endif) credit_rec$
		user_tpl.password$ = cvs(credit_rec.cred_passwd$, 2)
	endif
	
	callpoint!.setDevObject("credit_action", "none")
[[OPE_CREDITACTION.ARAR]]
rem --- Display default status

	credit_action = num(callpoint!.getColumnData("OPE_CREDITACTION.CREDIT_ACTION"))
	gosub display_status
[[OPE_CREDITACTION.<CUSTOM>]]
rem ==========================================================================
display_status: rem --- Display Status by Action
rem                      IN: credit_action
rem ==========================================================================

    switch credit_action 
		case 1
			callpoint!.setColumnData("OPE_CREDITACTION.CREDIT_STATUS", Translate!.getTranslation("AON_ORDER_WILL_BE_HELD"))
			break
		case 2
			callpoint!.setColumnData("OPE_CREDITACTION.CREDIT_STATUS", Translate!.getTranslation("AON_CUSTOMER'S_ORDERS_WILL_BE_HELD"))
			break
		case 3
			callpoint!.setColumnData("OPE_CREDITACTION.CREDIT_STATUS", Translate!.getTranslation("AON_ORDER_WILL_BE_RELEASED"))
			if callpoint!.getDevObject("cred_action_from_print_now")="Y"
				callpoint!.setColumnData("OPE_CREDITACTION.PRINT_AFTER_REL","Y",1)
				callpoint!.setDevObject("cred_action_from_print_now","")
			endif
			break
		case 4
			callpoint!.setColumnData("OPE_CREDITACTION.CREDIT_STATUS", Translate!.getTranslation("AON_ORDER_WILL_BE_DELETED"))
			break
		case default
	swend

	callpoint!.setStatus("REFRESH")

return

rem ==========================================================================
print_doc: rem --- Print Counter Order or Invoice
rem ==========================================================================
	
	run_by$   = callpoint!.getDevObject("run_by")
	cust_id$  = callpoint!.getDevObject("cust_id")
	order_no$ = callpoint!.getDevObject("order_no")
	pick_or_quote$ = callpoint!.getDevObject("pick_or_quote")

	if cvs(cust_id$,2) <> "" and cvs(order_no$, 2) <> "" then

	rem --- Mark order/invoice as released and needs to be reprinted

		file_name$="OPE_ORDHDR"
		ordhdr_dev = fnget_dev(file_name$)
		dim ordhdr_rec$:fnget_tpl$(file_name$)

		read(ordhdr_dev, key=firm_id$+"E"+"  "+cust_id$+order_no$,knum="AO_STATUS",dom=*next)
		while 1
			ordhdr_key$=key(ordhdr_dev,end=*break)
			if pos(firm_id$+"E"+"  "+cust_id$+order_no$=ordhdr_key$)=1
				extract record (ordhdr_dev) ordhdr_rec$; rem Advisory Locking
				ordhdr_rec.credit_flag$  = "R"
				ordhdr_rec.reprint_flag$ = "Y"
				ordhdr_rec$ = field(ordhdr_rec$)
				write record (ordhdr_dev) ordhdr_rec$
				rem callpoint!.setStatus("SETORIG")
				break
			endif
		wend

	rem --- Which print program to run?

		if run_by$ = "order" then

			user_id$=stbl("+USER_ID")
		 
			dim dflt_data$[3,1]
			dflt_data$[1,0]="CUSTOMER_ID"
			dflt_data$[1,1]=cust_id$
			dflt_data$[2,0]="ORDER_NO"
			dflt_data$[2,1]=order_no$
			dflt_data$[3,0]="INVOICE_TYPE"
			dflt_data$[3,1]=pick_or_quote$
		 
			call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:			                       "OPR_ODERPICKDMD",
:			                       user_id$,
:			                       "",
:			                       "",
:			                       table_chans$[all],
:			                       "",
:			                       dflt_data$[all]

		else
			rem --- should not be called by Invoice Entry, since Invoice Entry doesn't do the credit check per bug 4603
			if run_by$ = "invoice" then
				call stbl("+DIR_PGM")+"opc_invoice.aon::on_demand", cust_id$, order_no$, callpoint!, table_chans$[all], status
				if status = 999 then goto std_exit
			endif
		endif

		callpoint!.setDevObject("document_printed", "Y")
	endif

	return
[[OPE_CREDITACTION.ASVA]]
rem --- Make sure everything is entered

	credit_action = num(callpoint!.getColumnData("OPE_CREDITACTION.CREDIT_ACTION"))
	terms$        = callpoint!.getColumnData("OPE_CREDITACTION.AR_TERMS_CODE")
	pswd$         = callpoint!.getColumnData("OPE_CREDITACTION.ENTER_CRED_PSWRD")

	switch credit_action

	rem --- Hold this order

		case 1
			callpoint!.setDevObject("credit_action", "1")
			break

	rem --- Hold all future orders

		case 2

			if pswd$ <> user_tpl.password$ then
				msg_id$ = "OP_INVALID_PASSWD"
				gosub disp_message
				callpoint!.setStatus("ABORT")
			else
				callpoint!.setDevObject("credit_action", "2")
			endif

			break

	rem --- Release this order

		case 3

			abort = 0

			if terms$ = "" then 
				msg_id$ = "OP_TERM_NOT_ENTERED"
				gosub disp_message
				abort = 1
			else
				callpoint!.setDevObject("new_terms_code", terms$)
			endif

			if pswd$ <> user_tpl.password$ then
				msg_id$ = "OP_INVALID_PASSWD"
				gosub disp_message
				abort = 1
			endif

			if abort then 
				callpoint!.setStatus("ABORT")
			else
				if callpoint!.getColumnData("OPE_CREDITACTION.PRINT_AFTER_REL") = "Y" then
					gosub print_doc
				endif

				callpoint!.setDevObject("credit_action", "3")
			endif

			break

	rem --- Delete this order

		case 4

			msg_id$="OP_REALLY_DELETE"
			gosub disp_message

			if msg_opt$<>"Y" then 
				callpoint!.setStatus("ABORT")
			else
				callpoint!.setDevObject("credit_action", "4")
			endif

			break

		case default

	swend
[[OPE_CREDITACTION.CREDIT_ACTION.AVAL]]
rem --- Send back credit action response
	
	credit_action = num(callpoint!.getUserInput())
	gosub display_status
	callpoint!.setDevObject("credit_action", str(credit_action))
