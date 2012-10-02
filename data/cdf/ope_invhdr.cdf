[[OPE_INVHDR.DISCOUNT_AMT.AVAL]]
rem --- Discount Amount cannot exceed Total Sales Amount

	disc_amt = num(callpoint!.getUserInput())
	total_sales = num(callpoint!.getColumnData("OPE_INVHDR.TOTAL_SALES"))
	if disc_amt > total_sales then
		disc_amt = total_sales
		callpoint!.setUserInput(str(disc_amt))
	endif

rem --- Recalculate Tax Amount and Totals

	freight_amt = num(callpoint!.getColumnData("OPE_INVHDR.FREIGHT_AMT"))
	gosub calculate_tax
	gosub disp_totals
[[OPE_INVHDR.FREIGHT_AMT.AVAL]]
rem --- Recalculate Tax Amount and Totals

	disc_amt = num(callpoint!.getColumnData("OPE_INVHDR.DISCOUNT_AMT"))
	freight_amt = num(callpoint!.getUserInput())
	gosub calculate_tax
	gosub disp_totals

rem --- Unremark this next line if we ever get around to fixing bug 4797 which blocks 4753 which this line should solve
rem	callpoint!.setFocus("OPE_INVHDR.DISCOUNT_AMT")
[[OPE_INVHDR.FREIGHT_AMT.BINP]]
rem --- Now we've been on the Totals tab

	callpoint!.setDevObject("was_on_tot_tab","Y")
[[OPE_INVHDR.DISCOUNT_AMT.BINP]]
rem --- Now we've been on the Totals tab

	callpoint!.setDevObject("was_on_tot_tab","Y")
[[OPE_INVHDR.AOPT-UINV]]
rem --- Invoice History Header, set to void

	file_name$      = "OPT_INVHDR"
	opt_invhdr_dev  = fnget_dev(file_name$)
	opt_invhdr_tpl$ = fnget_tpl$(file_name$)
	dim opt_invhdr_rec$:opt_invhdr_tpl$
	file_name$      = "OPE_INVHDR"
	ope_invhdr_dev  = fnget_dev(file_name$)
	ope_invhdr_tpl$ = fnget_tpl$(file_name$)
	dim ope_invhdr_rec$:ope_invhdr_tpl$
	file_name$ = "OPE_PRNTLIST"
	prntlist_dev = fnget_dev(file_name$)
	dim prntlist_rec$:fnget_tpl$(file_name$)

	cust_id$  = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	order_no$ = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")

	opt_invhdr_rec$ = util.copyFields(opt_invhdr_tpl$, callpoint!)
	opt_invhdr_rec.invoice_type$ = "V"

	opt_invhdr_rec$ = field(opt_invhdr_rec$)
	if cvs(opt_invhdr_rec.ar_inv_no$,2)<>""
		write record (opt_invhdr_dev) opt_invhdr_rec$
	endif

rem --- Reprint order"

	msg_id$ = "OP_REPRINT_ALSO"
	gosub disp_message
	reprint$ = msg_opt$

rem --- Reset Invoice record to Order

	ope_invhdr_rec$ = util.copyFields(ope_invhdr_tpl$, callpoint!)

	ope_invhdr_rec.ar_inv_no$ = ""
	ope_invhdr_rec.ordinv_flag$ = "O"
	ope_invhdr_rec.print_status$ = "Y"
	ope_invhdr_rec.lock_status$ = "N"
	ope_invhdr_rec.invoice_date$=""

	callpoint!.setColumnData("OPE_INVHDR.AR_INV_NO", "")
	callpoint!.setColumnData("OPE_INVHDR.ORDINV_FLAG", "O")
	callpoint!.setColumnData("OPE_INVHDR.PRINT_STATUS", "Y")
	callpoint!.setColumnData("OPE_INVHDR.LOCK_STATUS", "N")
	callpoint!.setColumnData("OPE_INVHDR.TAX_AMOUNT", "0")
	callpoint!.setColumnData("OPE_INVHDR.FREIGHT_AMT", "0")
	callpoint!.setColumnData("OPE_INVHDR.DISCOUNT_AMT", "0")
	callpoint!.setColumnData("OPE_INVHDR.INVOICE_DATE","")
		
	if reprint$ = "Y" then
		ope_invhdr_rec.reprint_flag$ = "Y"
		callpoint!.setColumnData("OPE_INVHDR.REPRINT_FLAG", "Y")
	else
		ope_invhdr_rec.reprint_flag$ = ""
		callpoint!.setColumnData("OPE_INVHDR.REPRINT_FLAG", "")
	endif

	ope_invhdr_rec$ = field(ope_invhdr_rec$)
	write record (ope_invhdr_dev) ope_invhdr_rec$
	callpoint!.setStatus("SETORIG")

rem --- Reset the print file

	remove (prntlist_dev, key=firm_id$+"I  "+cust_id$+order_no$, dom=*next)

	if reprint$ = "Y" then
		prntlist_rec.firm_id$     = firm_id$
		prntlist_rec.ordinv_flag$ = "O"
		prntlist_rec.customer_id$ = cust_id$
		prntlist_rec.order_no$    = order_no$

		write record (prntlist_dev) prntlist_rec$
	endif

rem --- All Done

	user_tpl.do_end_of_form = 0
	callpoint!.setStatus("NEWREC")
[[OPE_INVHDR.AOPT-CRCH]]
print "Hdr:AOPT:CRCH"; rem debug

rem --- Force totalling open orders for credit status

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	ordHelp!.forceTotalOpenOrders()

rem --- Do credit status (management)

	cust_id$  = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	order_no$ = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO"); rem can be null

	if user_tpl.credit_installed$ = "Y" and user_tpl.display_bal$ <> "N" and cvs(cust_id$, 2) <> "" then
		print "---about to start credit management"; rem debug
		call user_tpl.pgmdir$+"opc_creditmgmnt.aon", cust_id$, order_no$, table_chans$[all], callpoint!, status
		callpoint!.setDevObject("credit_status_done", "Y")
		callpoint!.setStatus("ACTIVATE")
	endif
[[OPE_INVHDR.TAX_CODE.AVAL]]
rem --- Set code in the Order Helper object

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	ordHelp!.setTaxCode(callpoint!.getUserInput())

rem --- Calculate Taxes

	discount_amt = num(callpoint!.getColumnData("OPE_INVHDR.DISCOUNT_AMT"))
	freight_amt = num(callpoint!.getColumnData("OPE_INVHDR.FREIGHT_AMT"))
	tax_amount = ordHelp!.calculateTax(discount_amt, freight_amt,num(callpoint!.getColumnData("OPE_INVHDR.TAXABLE_AMT")))
	callpoint!.setColumnData("OPE_INVHDR.TAX_AMOUNT",str(tax_amount))
	callpoint!.setStatus("REFRESH")
[[OPE_INVHDR.ARAR]]
print "Hdr:ARAR"; rem debug

	callpoint!.setDevObject("was_on_tot_tab","N")

rem --- Check for void

	if callpoint!.getColumnData("INVOICE_TYPE") = "V" then
		msg_id$="OP_ORDINV_VOID"
		gosub disp_message
		callpoint!.setStatus("NEWREC")
		break; rem --- exit from callpoint			
	endif

rem --- Check for quote
		
	if callpoint!.getColumnData("INVOICE_TYPE") = "P" then
		msg_id$ = "OP_IS_QUOTE"
		gosub disp_message
		callpoint!.setStatus("NEWREC")
		sysGUI!.flushEvents(err=*next)
		break; rem --- exit from callpoint			
	endif		

rem --- Set flags

	user_tpl.user_entry$ = "N"; rem user entered an order (not navigated)

	callpoint!.setDevObject("credit_status_done", "N")
	callpoint!.setDevObject("credit_action_done", "N")

	callpoint!.setOptionEnabled("DINV",0)
	callpoint!.setOptionEnabled("CINV",0)
	callpoint!.setOptionEnabled("RPRT",0)
	callpoint!.setOptionEnabled("PRNT",0)
	callpoint!.setOptionEnabled("CRCH",0)
	callpoint!.setOptionEnabled("TTLS",0)

rem --- Clear order helper object

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	ordHelp!.newOrder()
	ordHelp!.setCust_id(callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID"))

rem --- Reset all previous values

	user_tpl.prev_line_code$   = ""
	user_tpl.prev_item$        = ""
	user_tpl.prev_qty_ord      = 0
	user_tpl.prev_boqty        = 0
	user_tpl.prev_shipqty      = 0
	user_tpl.prev_ext_price    = 0
	user_tpl.prev_ext_cost     = 0
	user_tpl.prev_disc_code$   = ""
	user_tpl.prev_ship_to$     = ""
	user_tpl.prev_sales_total  = 0

	user_tpl.new_order = 1
	user_tpl.credit_limit_warned = 0
	user_tpl.shipto_warned = 0
	callpoint!.setDevObject("disc_code",callpoint!.getColumnData("OPE_INVHDR.DISC_CODE"))

	disc_amt = num(callpoint!.getColumnData("OPE_INVHDR.DISCOUNT_AMT"))
	freight_amt = num(callpoint!.getColumnData("OPE_INVHDR.FREIGHT_AMT"))
	gosub disp_totals


rem --- setup messages

	if cvs(callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID"),2) = "" or
:	   cvs(callpoint!.getColumnData("OPE_INVHDR.ORDER_NO"),2) = ""
		break
	endif
	gosub init_msgs
	callpoint!.setDevObject("msg_printed",callpoint!.getColumnData("PRINT_STATUS"))
	if callpoint!.getColumnData("OPE_INVHDR.BACKORD_FLAG") = "B"
		callpoint!.setDevObject("msg_backorder","Y")
	endif
	if callpoint!.getColumnData("OPE_INVHDR.INVOICE_TYPE")="P"
		callpoint!.setDevObject("msg_quote","Y")
	endif
	if num(callpoint!.getColumnData("OPE_INVHDR.TOTAL_SALES")) < 0
		callpoint!.setDevObject("msg_credit_memo","Y")
	endif
	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	over_credit_limit = ordHelp!.calcOverCreditLimit()
	if over_credit_limit = 1
		callpoint!.setDevObject("msg_exceeded","Y")
	else
		callpoint!.setDevObject("msg_credit_okay","Y")
	endif
	if callpoint!.getColumnData("OPE_INVHDR.CREDIT_FLAG")="C"
		callpoint!.setDevObject("msg_hold","Y")
	endif
	if callpoint!.getColumnData("OPE_INVHDR.CREDIT_FLAG")="R"
		callpoint!.setDevObject("msg_released","Y")
	endif

	call user_tpl.pgmdir$+"opc_creditmsg.aon","H",callpoint!,UserObj!
[[OPE_INVHDR.DISC_CODE.AVAL]]
rem --- Set discount code for use in Order Totals

	user_tpl.disc_code$ = callpoint!.getUserInput()
	callpoint!.setDevObject("disc_code",user_tpl.disc_code$)

	file_name$ = "OPC_DISCCODE"
	disccode_dev = fnget_dev(file_name$)
	dim disccode_rec$:fnget_tpl$(file_name$)

	find record (disccode_dev, key=firm_id$+user_tpl.disc_code$, dom=*next) disccode_rec$
	new_disc_per = disccode_rec.disc_percent

	new_disc_amt = round(disccode_rec.disc_percent * num(callpoint!.getColumnData("OPE_INVHDR.TOTAL_SALES")) / 100, 2)
	callpoint!.setColumnData("OPE_INVHDR.DISCOUNT_AMT",str(new_disc_amt))

	disc_amt = new_disc_amt
	freight_amt = num(callpoint!.getColumnData("OPE_INVHDR.FREIGHT_AMT"))
	gosub disp_totals
[[OPE_INVHDR.AOPT-CASH]]
rem --- Customer wants to pay cash; Launch invoice totals first

	gosub do_totals

rem --- Now launch Cash Transaction

	gosub get_cash

rem --- Do we need to print an invoice first?

	if callpoint!.getDevObject( "print_invoice" ) = "Y" then
		gosub do_invoice
	endif

rem --- Now start a new record

	user_tpl.do_end_of_form = 0
	callpoint!.setStatus("NEWREC")
[[OPE_INVHDR.AOPT-RPRT]]
rem --- Check for printing in next batch and set

	if user_tpl.credit_installed$="Y" and user_tpl.pick_hold$<>"Y" and
:		callpoint!.getColumnData("OPE_INVHDR.CREDIT_FLAG")="C"
:	then
		msg_id$ = "OP_CR_HOLD_NOPRINT"
	else
		order_no$ = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")
		gosub add_to_batch_print
		callpoint!.setColumnData("OPE_INVHDR.REPRINT_FLAG","Y")
		callpoint!.setStatus("SAVE")
		msg_id$ = "OP_BATCH_PRINT"
	endif

	dim msg_tokens$[1]
	msg_tokens$[1] = Translate!.getTranslation("AON_INVOICE")
	gosub disp_message
[[OPE_INVHDR.AREC]]
rem --- clear availability

	gosub clear_avail
	callpoint!.setDevObject("was_on_tot_tab","N")

	gosub init_msgs
[[OPE_INVHDR.INVOICE_TYPE.AVAL]]
print "Hdr:INVOICE_TYPE.AVAL"; rem debug

rem --- Enable/disable expire date based on value

	inv_type$ = callpoint!.getUserInput()
	print "---Invoice Type: ", inv_type$; rem debug

	if inv_type$ = "S" then
		callpoint!.setColumnEnabled("OPE_INVHDR.EXPIRE_DATE", -1)
	else
		callpoint!.setColumnEnabled("OPE_INVHDR.EXPIRE_DATE", 1)
	endif

rem --- Set type in OrderHelper object

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	ordHelp!.setInv_type(callpoint!.getUserInput())
[[OPE_INVHDR.AOPT-PRNT]]
print "Hdr:AOPT.PRNT"; rem debug

rem --- Print a counter Invoice

	if callpoint!.getColumnData("OPE_INVHDR.ORDINV_FLAG") <> "I" then
		gosub make_invoice
	endif

	if user_tpl.credit_installed$ <> "Y" then

	rem --- No need to check credit first

		gosub do_invoice
		print "---Printed, starting new record..."; rem debug
		user_tpl.do_end_of_form = 0
		callpoint!.setStatus("NEWREC")
	else

	rem --- Can't print until released from credit

		gosub force_print_status
		gosub do_credit_action

		print "---Print Status: """, callpoint!.getColumnData("OPE_INVHDR.PRINT_STATUS"), """"; rem debug

		if pos(action$ = "XU") or (action$ = "R" and callpoint!.getColumnData("OPE_INVHDR.PRINT_STATUS") = "N") then 

		rem --- Couldn't do credit action, or did credit action w/ no problem, or released from credit but didn't print

			gosub do_invoice
			print "---Printed in header, starting new record..."; rem debug
			user_tpl.do_end_of_form = 0
			callpoint!.setStatus("NEWREC")
		else
			if action$ = "R" and callpoint!.getColumnData("OPE_INVHDR.PRINT_STATUS") = "Y" then 

			rem --- Released from credit and did print

				print "---Release and printed, starting new record..."; rem debug
				user_tpl.do_end_of_form = 0
				callpoint!.setStatus("NEWREC")
			else
				print "---Not printing because there was no credit action"; rem debug
			endif
		endif
	endif
[[OPE_INVHDR.BREX]]
print "Hdr:BREX"; rem debug

rem --- Are both Customer and Order entered?

	if cvs(callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID"), 2) = "" or 
:		cvs(callpoint!.getColumnData("OPE_INVHDR.ORDER_NO"), 2) = ""
:	then
		callpoint!.setStatus("EXIT")
		break; rem --- exit callpoint
	endif

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))

	if ordHelp!.getCust_id() = "" or ordHelp!.getOrder_no() = "" then
		callpoint!.setStatus("EXIT")
		break; rem --- exit callpoint
	endif

rem --- Is record deleted?

	if user_tpl.record_deleted then
		break; rem --- exit callpoint
	endif

rem --- Is flag down?

	print "---Should BREX be run? ", iff(user_tpl.do_end_of_form, "yes", "no"); rem debug

	if !user_tpl.do_end_of_form then
		user_tpl.do_end_of_form = 1
		break; rem --- exit callpoint
	endif	

rem --- Calculate taxes and write it back

	discount_amt = num(callpoint!.getColumnData("OPE_INVHDR.DISCOUNT_AMT"))
	freight_amt = num(callpoint!.getColumnData("OPE_INVHDR.FREIGHT_AMT"))
	gosub get_disk_rec
	ordhdr_rec.tax_amount = ordHelp!.calculateTax(discount_amt, freight_amt,num(callpoint!.getColumnData("OPE_INVHDR.TAXABLE_AMT")))
	ordhdr_rec$ = field(ordhdr_rec$)
	write record (ordhdr_dev) ordhdr_rec$
	callpoint!.setStatus("SETORIG")

rem --- Credit action

	if ordHelp!.calcOverCreditLimit() and callpoint!.getDevObject("credit_action_done") <> "Y" then
		gosub do_credit_action
	endif

rem --- Does the total of lot/serial# match the qty shipped for each detail line?

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	ordHelp!.setLotSerialFlag( user_tpl.lotser_flag$ )

	if user_tpl.lotser_flag$ <> "N" then

		declare BBjVector recs!
		recs! = BBjAPI().makeVector()

		recs! = cast( BBjVector, gridVect!.getItem(0) )
		dim gridrec$:dtlg_param$[1,3]

	rem --- Detail loop

		if recs!.size() then 
			for row=0 to recs!.size()-1
				gridrec$ = recs!.getItem(row)

				if ordHelp!.isLottedSerial(gridrec.item_id$) then
					lot_ser_total = ordHelp!.totalLotSerialAmount( gridrec.internal_seq_no$ )

					if lot_ser_total <> gridrec.qty_shipped then
						if user_tpl.lotser_flag$ = "L" then
							lot_ser$ = Translate!.getTranslation("AON_LOTS")
						else
							lot_ser$ = Translate!.getTranslation("AON_SERIAL_NUMBERS")
						endif
					
						msg_id$ = "OP_ITEM_LS_TOTAL"
						dim msg_tokens$[3]
						msg_tokens$[0] = str(gridrec.qty_shipped)
						msg_tokens$[1] = cvs(gridrec.item_id$, 2)
						msg_tokens$[2] = lot_ser$
						msg_tokens$[3] = str(lot_ser_total)
						gosub disp_message
					endif
				endif
			next row
		endif
	endif

rem --- Cash Transaction

	rem if user_tpl.cash_sale$ = "Y" then
	if callpoint!.getColumnData("OPE_INVHDR.CASH_SALE") = "Y" then
		gosub get_cash
	endif
[[OPE_INVHDR.BWRI]]
print "Hdr:BWRI"; rem debug

rem --- Has customer and order number been entered?

	cust_id$  = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	order_no$ = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")

	if cvs(cust_id$, 2) = "" or cvs(order_no$, 2) = "" then
		callpoint!.setStatus("ABORT")
	endif

rem --- Check Ship-to's

	rem if !user_tpl.shipto_warned then
		shipto_type$ = callpoint!.getColumnData("OPE_INVHDR.SHIPTO_TYPE")
		shipto_var$  = "OPE_INVHDR.SHIPTO_NO"

		if shipto_type$ = "S" and cvs(callpoint!.getColumnData(shipto_var$), 2) = "" then
			msg_id$ = "OP_SHIPTO_NO_MISSING"
			gosub disp_message
			callpoint!.setFocus(shipto_var$)
			user_tpl.shipto_warned = 1
			break; rem --- exit callpoint
		else
			ship_addr1_var$ = "<<DISPLAY>>.SADD1"

			if shipto_type$ = "M" and cvs(callpoint!.getColumnData(ship_addr1_var$), 2) = "" then
				msg_id$ = "OP_MAN_SHIPTO_NEEDED"
				gosub disp_message
				callpoint!.setFocus(ship_addr1_var$)
				user_tpl.shipto_warned = 1
				break; rem --- exit callpoint
			endif
		endif
	rem endif
[[OPE_INVHDR.AOPT-MINV]]
print "Hdr:APOT:MINV"; rem debug

rem --- Make order into an invoice

	gosub make_invoice

	if locked then
		user_tpl.do_end_of_form = 0
		callpoint!.setStatus("NEWREC")
		break; rem --- exit callpoint
	endif
[[OPE_INVHDR.SLSPSN_CODE.AVAL]]
rem --- Set Commission Percent

	slsp$ = callpoint!.getUserInput()
	gosub get_comm_percent
[[OPE_INVHDR.SHIPTO_TYPE.AVAL]]
rem -- Deal with which Ship To type

	ship_to_type$ = callpoint!.getUserInput()
	ship_to_no$   = callpoint!.getColumnData("OPE_INVHDR.SHIPTO_NO")
	cust_id$      = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	order_no$     = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")

	gosub ship_to_info

rem --- Disable Ship To fields

	declare BBjVector column!
	column! = BBjAPI().makeVector()

	column!.addItem("<<DISPLAY>>.SNAME")
	column!.addItem("<<DISPLAY>>.SADD1")
	column!.addItem("<<DISPLAY>>.SADD2")
	column!.addItem("<<DISPLAY>>.SADD3")
	column!.addItem("<<DISPLAY>>.SADD4")
	column!.addItem("<<DISPLAY>>.SCITY")
	column!.addItem("<<DISPLAY>>.SSTATE")
	column!.addItem("<<DISPLAY>>.SZIP")

	if ship_to_type$="M"
		status = 1
	else
		status = -1
	endif

	callpoint!.setColumnEnabled(column!, status)
[[OPE_INVHDR.SHIPTO_NO.AVAL]]
rem --- Remove manual ship-record, if necessary

	ship_to_no$ = callpoint!.getUserInput()
	cust_id$    = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	order_no$   = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")

	if user_tpl.prev_ship_to$ = "000099" and ship_to_no$ <> "000099" then
		remove (fnget_dev("OPE_ORDSHIP"), key=firm_id$+cust_id$+order_no$, dom=*next)
	endif

rem --- Display Ship to information

	ship_to_type$ = callpoint!.getColumnData("OPE_INVHDR.SHIPTO_TYPE")
	gosub ship_to_info
[[OPE_INVHDR.PRICE_CODE.AVAL]]
rem --- Set user template info

	user_tpl.price_code$=callpoint!.getUserInput()
[[OPE_INVHDR.PRICING_CODE.AVAL]]
rem --- Set user template info

	user_tpl.pricing_code$=callpoint!.getUserInput()
[[OPE_INVHDR.ORDER_DATE.AVAL]]
rem --- Set user template info

	user_tpl.order_date$=callpoint!.getUserInput()
[[OPE_INVHDR.ADEL]]
rem --- Remove invoice from ope-04 and rewrite as order (void)

	ope_prntlist_dev=fnget_dev("OPE_PRNTLIST")
	dim ope_prntlist$:fnget_tpl$("OPE_PRNTLIST")
	remove (ope_prntlist_dev,key=firm_id$+"O"+"  "+
:		callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")+
:		callpoint!.getColumnData("OPE_INVHDR.ORDER_NO"),dom=*next)
	ope_prntlist.firm_id$=firm_id$
	ope_prntlist.ordinv_flag$="I"
	ope_prntlist.customer_id$=callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	ope_prntlist.order_no$=callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")
	ope_prntlist$=field(ope_prntlist$)
	write record (ope_prntlist_dev)ope_prntlist$

rem --- Set flag

	user_tpl.record_deleted = 1
	user_tpl.first_read     = 1

rem --- clear availability

	gosub clear_avail

	file_name$ = "OPE_INVHDR"
	ope01_dev = fnget_dev(file_name$)
	ope01_tpl$=fnget_tpl$(file_name$)
	dim ope01a$:ope01_tpl$
	ope01a$ = util.copyFields(ope01_tpl$, callpoint!)
	ope01a.sequence_000$="000"
	ope01a.invoice_type$ = "V"
	ope01a.print_status$="Y"

	ope01a$ = field(ope01a$)
	write record (ope01_dev) ope01a$
[[OPE_INVHDR.SHIPTO_NO.BINP]]
rem --- Save old value

	user_tpl.prev_ship_to$ = callpoint!.getColumnData("OPE_INVHDR.SHIPTO_NO")
[[OPE_INVHDR.AOPT-CINV]]
rem --- Credit Historical Invoice

	if cvs(callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID"),2)="" or
:	   cvs(callpoint!.getColumnData("OPE_INVHDR.ORDER_NO"),2)<>""
:	then
		msg_id$="OP_NO_HIST"
		gosub disp_message
	else
		key_pfx$=firm_id$+
:			callpoint!.getColumnData("OPE_INVHDR.AR_TYPE")+
:			callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
		line_sign=-1
		gosub copy_order
	endif
[[OPE_INVHDR.AOPT-DINV]]
rem --- Duplicate Historical Invoice

	if cvs(callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID"),2)="" or
:	   cvs(callpoint!.getColumnData("OPE_INVHDR.ORDER_NO"),2)<>""
:	then 
		msg_id$="OP_NO_HIST"
		gosub disp_message
	else
		key_pfx$=firm_id$+
:			callpoint!.getColumnData("OPE_INVHDR.AR_TYPE")+
:			callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
		line_sign=1
		gosub copy_order
	endif
[[OPE_INVHDR.APFE]]
print "Hdr:APFE"; rem debug

rem --- Enable / Disable buttons

	callpoint!.setOptionEnabled("CRCH",0)

	if cvs(callpoint!.getColumnData("OPE_INVHDR.ORDER_NO"),2) = "" then
		if cvs(callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID"),2) = ""
			callpoint!.setOptionEnabled("DINV",0)
			callpoint!.setOptionEnabled("CINV",0)
		else
			callpoint!.setOptionEnabled("DINV",1)
			callpoint!.setOptionEnabled("CINV",1)
		endif
		callpoint!.setOptionEnabled("PRNT",0)
		callpoint!.setOptionEnabled("MINV",0)
		callpoint!.setOptionEnabled("UINV",0)
	else
		if cvs(callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID"),2) = "" then
			callpoint!.setOptionEnabled("PRNT",0)
			callpoint!.setOptionEnabled("CASH",0)
		else
			callpoint!.setOptionEnabled("PRNT",1)
			callpoint!.setOptionEnabled("TTLS",1)
			callpoint!.setOptionEnabled("CRCH",1)
			if user_tpl.cash_sale$="Y" then callpoint!.setOptionEnabled("CASH",1)

			if callpoint!.getColumnData("OPE_INVHDR.ORDINV_FLAG")<> "I" then
				callpoint!.setOptionEnabled("MINV",1)	
				callpoint!.setOptionEnabled("UINV",0)
			else
				callpoint!.setOptionEnabled("UINV",1)
			endif
		endif
	endif


rem --- Set Backordered text field

	call user_tpl.pgmdir$+"opc_creditmsg.aon","H",callpoint!,UserObj!
[[OPE_INVHDR.BPFX]]
print "Hdr:BPFX"; rem debug

rem --- Disable buttons

	callpoint!.setOptionEnabled("CRCH",0)
	callpoint!.setOptionEnabled("CRAT",0)
	callpoint!.setOptionEnabled("DINV",0)
	callpoint!.setOptionEnabled("CINV",0)
	callpoint!.setOptionEnabled("MINV",0)
	callpoint!.setOptionEnabled("UINV",0)
	callpoint!.setOptionEnabled("PRNT",0)
	callpoint!.setOptionEnabled("CASH",0)
	callpoint!.setOptionEnabled("TTLS",0)
[[OPE_INVHDR.BDEL]]
print "Hdr:BDEL"; rem debug

rem --- Set table variables
	file_name$ = "OPE_PRNTLIST"
	prntlist_dev = fnget_dev(file_name$)
	dim prntlist_rec$:fnget_tpl$(file_name$)

rem --- Retain Order is No

	callpoint!.setColumnData("OPE_INVHDR.INVOICE_TYPE","V")
	prntlist_rec.firm_id$     = firm_id$
	prntlist_rec.ordinv_flag$ = "I"
	prntlist_rec.customer_id$ = cust_id$
	prntlist_rec.order_no$    = order_no$
	callpoint!.setStatus("SAVE-NEWREC-REFRESH")

	write record (prntlist_dev) prntlist_rec$

rem --- Remove committments for detail records by calling ATAMO

	ope11_dev = fnget_dev("OPE_INVDET")
	dim ope11a$:fnget_tpl$("OPE_INVDET")

	opc_linecode_dev = fnget_dev("OPC_LINECODE")
	dim opc_linecode$:fnget_tpl$("OPC_LINECODE")

	ivs01_dev = fnget_dev("IVS_PARAMS")
	dim ivs01a$:fnget_tpl$("IVS_PARAMS")
	read record (ivs01_dev, key=firm_id$+"IV00") ivs01a$

	ope33_dev = fnget_dev("OPE_ORDSHIP")
	cashrct_dev = fnget_dev("OPE_INVCASH")
	creddate_dev = fnget_dev("OPE_CREDDATE")

	ar_type$  = callpoint!.getColumnData("OPE_INVHDR.AR_TYPE")
	cust$     = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	ord$      = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")
	ord_date$ = callpoint!.getColumnData("OPE_INVHDR.ORDER_DATE")
	inv_type$ = callpoint!.getColumnData("OPE_INVHDR.INVOICE_TYPE")

	read (ope11_dev, key=firm_id$+ar_type$+cust$+ord$, dom=*next)

	while 1
		read record (ope11_dev, end=*break) ope11a$

		if firm_id$<>ope11a.firm_id$ then break
		if ar_type$<>ope11a.ar_type$ then break
		if cust$<>ope11a.customer_id$ then break
		if ord$<>ope11a.order_no$ then break

		read record (opc_linecode_dev, key=firm_id$+ope11a.line_code$) opc_linecode$

		if opc_linecode.dropship$<>"Y" and ope11a.commit_flag$="Y" and inv_type$<>"P" then
			if pos(opc_linecode.line_type$="SP") then
				wh_id$    = ope11a.warehouse_id$
				item_id$  = ope11a.item_id$
				ls_id$    = ""
				qty       = ope11a.qty_ordered
				line_sign = -1
				gosub update_totals
			endif
		endif

		if pos(user_tpl.lotser_flag$="LS") then 
			ord_seq$ = ope11a.internal_seq_no$
			gosub remove_lot_ser_det
		endif

	wend

	remove (ope33_dev, key=firm_id$+cust$+ord$, dom=*next)
	remove (cashrct_dev, key=firm_id$+ar_type$+cust$+ord$, err=*next)

	if user_tpl.credit_installed$="Y" then
		remove (creddate_dev, key=firm_id$+ord_date$+cust$+ord$, err=*next)	
	endif
[[OPE_INVHDR.BPRK]]
rem --- Previous record must be an invoice

	file_name$ = "OPE_INVHDR"
	ope01_dev = fnget_dev(file_name$)
	dim ope01a$:fnget_tpl$(file_name$)
	start_block = 1

	while 1
		if start_block then
			p_key$ = keyp(ope01_dev, end=*endif)
			read record (ope01_dev, key=p_key$) ope01a$

			if ope01a.firm_id$ = firm_id$ then 
				if ope01a.invoice_type$ = "S" and ope01a.ordinv_flag$ = "I" then
					user_tpl.first_read = 0
					break
				else
					read (ope01_dev, dir=-1, end=*endif)
					continue
				endif
			endif
		endif

	rem --- If EOF or past firm, rewind to last record in this firm, unless it's the first read

		if user_tpl.first_read then
			msg_id$ = "OP_ALL_WRONG_TYPE"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		else
			read (ope01_dev, key=firm_id$+$ff$, dom=*break, end=*break)
			break
		endif
	wend
[[OPE_INVHDR.BNEK]]
rem --- Next record must be an invoice 

	file_name$ = "OPE_INVHDR"
	ope01_dev = fnget_dev(file_name$)
	dim ope01a$:fnget_tpl$(file_name$)
	start_block = 1

	while 1
		if start_block then
			read record (ope01_dev, dir=0, end=*endif) ope01a$

			if ope01a.firm_id$ = firm_id$ then
				if ope01a.invoice_type$ = "S" and ope01a.ordinv_flag$ = "I" then
					user_tpl.first_read = 0
					break
				else
					read (ope01_dev, end=*endif)
					continue
				endif
			endif
		endif

	rem --- If EOF or wrong firm, rewind to first record of the firm, unless it's the first read
		
		if user_tpl.first_read then
			msg_id$ = "OP_ALL_WRONG_TYPE"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		else
			read (ope01_dev, key=firm_id$, dom=*break)
			break
		endif
	wend
[[OPE_INVHDR.SHIPTO_TYPE.BINP]]
rem --- Do we need to create a new order number?

	if cvs(callpoint!.getColumnData("OPE_INVHDR.ORDER_NO"),2)=""
		call stbl("+DIR_SYP")+"bas_sequences.bbj","ORDER_NO",seq_id$,table_chans$[all]
		
		if len(seq_id$)=0 
			callpoint!.setStatus("ABORT")
			break; rem --- exit callpoint
		else
			callpoint!.setColumnData("OPE_INVHDR.ORDER_NO",seq_id$)
			callpoint!.setStatus("REFRESH")
		endif
	endif
[[OPE_INVHDR.BOVE]]
rem --- Restrict lookup to orders

	alias_id$ = "OPE_INVHDR"
	inq_mode$ = "EXM_ITEM"
	key_pfx$  = firm_id$
	key_id$   = "PRIMARY"
	cust_id$  = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")

	dim filter_defs$[2,1]
	filter_defs$[1,0] = "OPE_INVHDR.INVOICE_TYPE"
	filter_defs$[1,1] = "<>'V' AND OPE_INVHDR.INVOICE_TYPE <>'P'"

	if cvs(cust_id$, 2) <> "" then
		filter_defs$[2,0] = "OPE_INVHDR.CUSTOMER_ID"
		filter_defs$[2,1] = "='" + cust_id$ + "'"
	endif


	call stbl("+DIR_SYP")+"bam_inquiry.bbj",
:		gui_dev,
:		Form!,
:		alias_id$,
:		inq_mode$,
:		table_chans$[all],
:		key_pfx$,
:		key_id$,
:		selected_key$,
:		filter_defs$[all],
:		search_defs$[all]

	if selected_key$<>"" then 
		callpoint!.setStatus("RECORD:[" + selected_key$ +"]")
		callpoint!.setStatus("ACTIVATE")
	else
		callpoint!.setStatus("ABORT")
	endif
[[OPE_INVHDR.AWRI]]
rem --- Write/Remove manual ship to file

	cust_id$    = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	order_no$   = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")
	ordship_dev = fnget_dev("OPE_ORDSHIP")
	
	if callpoint!.getColumnData("OPE_INVHDR.SHIPTO_TYPE") <> "M" then 
		remove (ordship_dev,key=firm_id$+cust_id$+order_no$,dom=*next)
	else
		dim ordship_tpl$:fnget_tpl$("OPE_ORDSHIP")
		read record (ordship_dev, key=firm_id$+cust_id$+order_no$ ,dom=*next) ordship_tpl$

		ordship_tpl.firm_id$     = firm_id$
		ordship_tpl.customer_id$ = cust_id$
		ordship_tpl.order_no$    = order_no$
		ordship_tpl.name$        = callpoint!.getColumnData("<<DISPLAY>>.SNAME")
		ordship_tpl.addr_line_1$ = callpoint!.getColumnData("<<DISPLAY>>.SADD1")
		ordship_tpl.addr_line_2$ = callpoint!.getColumnData("<<DISPLAY>>.SADD2")
		ordship_tpl.addr_line_3$ = callpoint!.getColumnData("<<DISPLAY>>.SADD3")
		ordship_tpl.addr_line_4$ = callpoint!.getColumnData("<<DISPLAY>>.SADD4")
		ordship_tpl.city$        = callpoint!.getColumnData("<<DISPLAY>>.SCITY")
		ordship_tpl.state_code$  = callpoint!.getColumnData("<<DISPLAY>>.SSTATE")
		ordship_tpl.zip_code$    = callpoint!.getColumnData("<<DISPLAY>>.SZIP")

		ordship_tpl$ = field(ordship_tpl$)
		write record (ordship_dev) ordship_tpl$
	endif

rem --- Set flag

	user_tpl.first_read = 0
[[OPE_INVHDR.ADIS]]
print "Hdr:ADIS"; rem debug

rem --- Check locked status

	gosub check_lock_flag

	if locked then
		user_tpl.do_end_of_form = 0
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

rem --- Check Print flag

	gosub check_print_flag

	if locked then
		user_tpl.do_end_of_form = 0
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

rem --- Check for order, force to an Invoice

	if callpoint!.getColumnData("OPE_INVHDR.ORDINV_FLAG") = "O" then

		gosub make_invoice
		if locked then
			user_tpl.do_end_of_form = 0
			break; rem --- exit callpoint
		endif
	endif

rem --- Show customer data
	
	cust_id$ = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	order_no$ = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")

	if cvs(cust_id$,3)=""
		callpoint!.setStatus("NEWREC")
		break
	endif

	gosub display_customer

	if callpoint!.getColumnData("OPE_INVHDR.CASH_SALE") <> "Y" then 
		gosub display_aging
		gosub check_credit
	endif

	gosub disp_cust_comments

rem --- Display Ship to information

	ship_to_type$ = callpoint!.getColumnData("OPE_INVHDR.SHIPTO_TYPE")
	ship_to_no$   = callpoint!.getColumnData("OPE_INVHDR.SHIPTO_NO")
	order_no$     = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")
	gosub ship_to_info

rem --- Enable buttons

	callpoint!.setOptionEnabled("PRNT", 1)
	callpoint!.setOptionEnabled("TTLS",1)
	callpoint!.setOptionEnabled("UINV",1)
	if user_tpl.cash_sale$="Y" then callpoint!.setOptionEnabled("CASH", 1)

	if callpoint!.getColumnData("OPE_INVHDR.ORDINV_FLAG") = "I" then
		callpoint!.setOptionEnabled("MINV", 0)
		callpoint!.setOptionEnabled("UINV",1)
	else
		callpoint!.setOptionEnabled("MINV", 1)
		callpoint!.setOptionEnabled("UINV",0)
	endif

rem --- Set all previous values

	user_tpl.prev_ext_cost     = num(callpoint!.getColumnData("OPE_INVHDR.TOTAL_COST"))
	user_tpl.prev_disc_code$   = callpoint!.getColumnData("OPE_INVHDR.DISC_CODE")
	user_tpl.prev_ship_to$     = callpoint!.getColumnData("OPE_INVHDR.SHIPTO_NO")
	user_tpl.prev_sales_total  = num(callpoint!.getColumnData("OPE_INVHDR.TOTAL_SALES"))

rem --- Set other codes
        
	user_tpl.price_code$   = callpoint!.getColumnData("OPE_INVHDR.PRICE_CODE")
	user_tpl.pricing_code$ = callpoint!.getColumnData("OPE_INVHDR.PRICING_CODE")
	user_tpl.order_date$   = callpoint!.getColumnData("OPE_INVHDR.ORDER_DATE")
	user_tpl.disc_code$    = callpoint!.getColumnData("OPE_INVHDR.DISC_CODE")
	user_tpl.new_order     = 0

rem --- Set OrderHelper object fields

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	ordHelp!.setCust_id(callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID"))
	ordHelp!.setOrder_no(callpoint!.getColumnData("OPE_INVHDR.ORDER_NO"))
	ordHelp!.setInv_type(callpoint!.getColumnData("OPE_INVHDR.INVOICE_TYPE"))
	ordHelp!.setTaxCode(callpoint!.getColumnData("OPE_INVHDR.TAX_CODE"))

rem --- Clear availability

	gosub clear_avail
[[OPE_INVHDR.ORDER_NO.AVAL]]
print "Hdr:ORDER_NO.AVAL"; rem debug

rem --- Do we need to create a new order number?

	new_seq$ = "N"
	user_tpl.user_entry$ = "N"
	order_no$ = callpoint!.getUserInput()

	if cvs(order_no$, 2) = "" then 

	rem --- Option on order no field to assign a new sequence on null must be cleared

		call stbl("+DIR_SYP")+"bas_sequences.bbj","ORDER_NO",order_no$,table_chans$[all]
		
		if order_no$ = "" then
			callpoint!.setStatus("ABORT")
			break; rem --- exit callpoint
		else
			callpoint!.setUserInput(order_no$)
			new_seq$ = "Y"
		endif
	else
		user_tpl.user_entry$ = "Y"
	endif

rem --- Does order exist?

	ope01_dev = fnget_dev("OPE_INVHDR")
	dim ope01a$:fnget_tpl$("OPE_INVHDR")

	ar_type$ = callpoint!.getColumnData("OPE_INVHDR.AR_TYPE")
	cust_id$ = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")

	found = 0
	start_block = 1

	if start_block then
		find record (ope01_dev, key=firm_id$+ar_type$+cust_id$+order_no$, dom=*endif) ope01a$
		found = 1
	endif

rem --- A new record must be the next sequence

	if found = 0 and new_seq$ = "N" then
		msg_id$ = "OP_NEW_ORD_USE_SEQ"
		gosub disp_message	
		callpoint!.setFocus("OPE_INVHDR.ORDER_NO")
		break; rem --- exit from callpoint
	endif

	user_tpl.hist_ord$ = "N"

rem --- Existing record

	if found then 

	rem --- Check for void

		if ope01a.invoice_type$ = "V" then
			msg_id$="OP_ORDINV_VOID"
			gosub disp_message
			callpoint!.setStatus("NEWREC")
			break; rem --- exit from callpoint			
		endif

	rem --- Check for quote
		
		if ope01a.invoice_type$ = "P" then
			msg_id$ = "OP_IS_QUOTE"
			gosub disp_message
			callpoint!.setStatus("NEWREC")
			break; rem --- exit from callpoint			
		endif		

	rem --- Check for order, force to an Invoice

		if ope01a.invoice_type$ = "O" then

			gosub make_invoice

			if locked then
				user_tpl.do_end_of_form = 0
				break; rem --- exit callpoint
			endif
		endif

	rem --- Set Codes
	        
		user_tpl.price_code$   = ope01a.price_code$
		user_tpl.pricing_code$ = ope01a.pricing_code$
		user_tpl.order_date$   = ope01a.order_date$

rem --- New record, set default  

	else

		call stbl("+DIR_SYP")+"bas_sequences.bbj", "INVOICE_NO", invoice_no$, table_chans$[all]

		if invoice_no$ = "" then
			callpoint!.setStatus("ABORT")
		endif

		callpoint!.setColumnData("OPE_INVHDR.AR_INV_NO", invoice_no$)

	        cust_id$  = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
		order_no$ = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")
		callpoint!.setColumnData("OPE_INVHDR.INVOICE_TYPE","S")

	rem --- Set default invoice type in OrderHelper object

		ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
		ordHelp!.setInv_type("S")
        
		arm02_dev = fnget_dev("ARM_CUSTDET")
		dim arm02a$:fnget_tpl$("ARM_CUSTDET")
		read record (arm02_dev, key=firm_id$+cust_id$+"  ", dom=*next) arm02a$

		arm01_dev = fnget_dev("ARM_CUSTMAST")
		dim arm01a$:fnget_tpl$("ARM_CUSTMAST")
		read record (arm01_dev, key=firm_id$+cust_id$, dom=*next) arm01a$
		
		callpoint!.setColumnData("OPE_INVHDR.INVOICE_TYPE","S")
		callpoint!.setColumnData("OPE_INVHDR.ORDINV_FLAG","I")
		callpoint!.setColumnData("OPE_INVHDR.INVOICE_DATE",sysinfo.system_date$)
		callpoint!.setColumnData("OPE_INVHDR.SHIPMNT_DATE",sysinfo.system_date$)
		callpoint!.setColumnData("OPE_INVHDR.AR_SHIP_VIA",arm01a.ar_ship_via$)
		callpoint!.setColumnData("OPE_INVHDR.SLSPSN_CODE",arm02a.slspsn_code$)
		callpoint!.setColumnData("OPE_INVHDR.TERMS_CODE",arm02a.ar_terms_code$)
		callpoint!.setColumnData("OPE_INVHDR.DISC_CODE",arm02a.disc_code$)
		callpoint!.setColumnData("OPE_INVHDR.AR_DIST_CODE",arm02a.ar_dist_code$)
		callpoint!.setColumnData("OPE_INVHDR.PRINT_STATUS","N")
		print "---Print Status: N"; rem debug
		callpoint!.setColumnData("OPE_INVHDR.MESSAGE_CODE",arm02a.message_code$)
		callpoint!.setColumnData("OPE_INVHDR.TERRITORY",arm02a.territory$)
		callpoint!.setColumnData("OPE_INVHDR.ORDER_DATE",sysinfo.system_date$)
		callpoint!.setColumnData("OPE_INVHDR.TAX_CODE",arm02a.tax_code$)
		callpoint!.setColumnData("OPE_INVHDR.PRICING_CODE",arm02a.pricing_code$)
		callpoint!.setColumnData("OPE_INVHDR.ORD_TAKEN_BY",sysinfo.user_id$)

		callpoint!.setDevObject("disc_code",arm02a.disc_code$)
		user_tpl.disc_code$    = arm02a.disc_code$

		ordHelp!.setTaxCode(arm02a.tax_code$)

		slsp$ = arm02a.slspsn_code$
		gosub get_comm_percent

		gosub get_op_params

		if cust_id$ = ars01a.customer_id$
			callpoint!.setColumnData("OPE_INVHDR.CASH_SALE", "Y")
		else 
			callpoint!.setColumnData("OPE_INVHDR.CASH_SALE", "N")
		endif

		user_tpl.price_code$   = ""
		user_tpl.pricing_code$ = arm02a.pricing_code$
		user_tpl.order_date$   = sysinfo.system_date$

		callpoint!.setOptionEnabled("MINV",1)
		callpoint!.setOptionEnabled("UINV",0)

	endif

rem --- New or existing order

	order_no$ = callpoint!.getUserInput()
	gosub add_to_batch_print
	rem callpoint!.setColumnData("OPE_INVHDR.LOCK_STATUS", "Y")
	callpoint!.setColumnData("OPE_INVHDR.LOCK_STATUS", "N"); rem debug, forcing the lock off for now, not working correctly

rem --- Disable buttons

	callpoint!.setOptionEnabled("DINV", 0)
	callpoint!.setOptionEnabled("CINV", 0)

	callpoint!.setStatus("MODIFIED;REFRESH")

rem --- Set order in OrderHelper object

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	ordHelp!.setOrder_no(order_no$)
[[OPE_INVHDR.CUSTOMER_ID.AVAL]]
print "Hdr:CUSTOMER_ID.AVAL"; rem debug

rem --- Display customer

	cust_id$ = callpoint!.getUserInput()
	gosub display_customer

	custdet_dev = fnget_dev("ARM_CUSTDET")
	dim custdet_tpl$:fnget_tpl$("ARM_CUSTDET")

	find record (custdet_dev, key=firm_id$+cust_id$+"  ") custdet_tpl$

rem --- Set customer in OrderHelper object

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	ordHelp!.setCust_id(cust_id$)

rem --- Show customer data

	if callpoint!.getColumnData("OPE_INVHDR.CASH_SALE") <> "Y" then 
		gosub display_aging
		gosub check_credit

		if callpoint!.getDevObject("current_customer") <> cust_id$
			if user_tpl.credit_installed$ = "Y" and user_tpl.display_bal$ = "A" then
				call user_tpl.pgmdir$+"opc_creditmgmnt.aon", cust_id$, "", table_chans$[all], callpoint!, status
				callpoint!.setDevObject("credit_status_done", "Y")
				callpoint!.setStatus("ACTIVATE")
			endif
		endif
	endif

	callpoint!.setDevObject("current_customer",cust_id$)
	callpoint!.setDevObject("disc_code",custdet_tpl.disc_code$)
	user_tpl.disc_code$    = custdet_tpl.disc_code$

	gosub disp_cust_comments

rem --- Enable Duplicate buttons, printer

	if cvs(callpoint!.getColumnData("OPE_INVHDR.ORDER_NO"),2) = "" then
		callpoint!.setOptionEnabled("DINV", 1)
		callpoint!.setOptionEnabled("CINV", 1)
	endif

	callpoint!.setOptionEnabled("CRCH",1)
[[OPE_INVHDR.CUSTOMER_ID.AINP]]
print "Hdr:CUSTOMER_ID.AINP"; rem debug

rem --- If cash customer, get correct customer number

	if user_tpl.cash_sale$="Y" and cvs(callpoint!.getUserInput(),1+2+4)="C" then
		callpoint!.setColumnData("OPE_INVHDR.CUSTOMER_ID", user_tpl.cash_cust$)
		callpoint!.setColumnData("OPE_INVHDR.CASH_SALE", "Y")
		user_tpl.is_cash_sale = 1
		callpoint!.setStatus("REFRESH")
	endif
[[OPE_INVHDR.<CUSTOM>]]
rem ==========================================================================
display_customer: rem --- Get and display Bill To Information
                  rem      IN: cust_id$
rem ==========================================================================

	custmast_dev = fnget_dev("ARM_CUSTMAST")
	dim custmast_tpl$:fnget_tpl$("ARM_CUSTMAST")
	find record (custmast_dev, key=firm_id$+cust_id$) custmast_tpl$

	callpoint!.setColumnData("<<DISPLAY>>.BADD1",  custmast_tpl.addr_line_1$)
	callpoint!.setColumnData("<<DISPLAY>>.BADD2",  custmast_tpl.addr_line_2$)
	callpoint!.setColumnData("<<DISPLAY>>.BADD3",  custmast_tpl.addr_line_3$)
	callpoint!.setColumnData("<<DISPLAY>>.BADD4",  custmast_tpl.addr_line_4$)
	callpoint!.setColumnData("<<DISPLAY>>.BCITY",  custmast_tpl.city$)
	callpoint!.setColumnData("<<DISPLAY>>.BSTATE", custmast_tpl.state_code$)
	callpoint!.setColumnData("<<DISPLAY>>.BZIP",   custmast_tpl.zip_code$)

	return

rem ==========================================================================
display_aging: rem --- Display customer aging
               rem      IN: cust_id$
rem ==========================================================================

	custdet_dev = fnget_dev("ARM_CUSTDET")
	dim custdet_tpl$:fnget_tpl$("ARM_CUSTDET")

	find record (custdet_dev, key=firm_id$+cust_id$+"  ") custdet_tpl$

	user_tpl.balance = custdet_tpl.aging_future+
:		custdet_tpl.aging_cur+
:		custdet_tpl.aging_30+
:		custdet_tpl.aging_60+
:		custdet_tpl.aging_90+
:		custdet_tpl.aging_120

	callpoint!.setColumnData("<<DISPLAY>>.AGING_120",    custdet_tpl.aging_120$)
	callpoint!.setColumnData("<<DISPLAY>>.AGING_30",     custdet_tpl.aging_30$)
	callpoint!.setColumnData("<<DISPLAY>>.AGING_60",     custdet_tpl.aging_60$)
	callpoint!.setColumnData("<<DISPLAY>>.AGING_90",     custdet_tpl.aging_90$)
	callpoint!.setColumnData("<<DISPLAY>>.AGING_CUR",    custdet_tpl.aging_cur$)
	callpoint!.setColumnData("<<DISPLAY>>.AGING_FUTURE", custdet_tpl.aging_future$)
	callpoint!.setColumnData("<<DISPLAY>>.TOT_AGING",    user_tpl.balance$)

	user_tpl.credit_limit = custdet_tpl.credit_limit

	return

rem ==========================================================================
check_credit: rem --- Check credit limit of customer
              rem     (ope_cb, 5400-5499)
rem ==========================================================================

	if user_tpl.credit_limit<>0 and !user_tpl.credit_limit_warned and user_tpl.balance>=user_tpl.credit_limit then
   	if user_tpl.credit_installed$ <> "Y" then
      	msg_id$ = "OP_OVER_CREDIT_LIMIT"
			dim msg_tokens$[1]
			msg_tokens$[1] = str(custdet_tpl.credit_limit:user_tpl.amount_mask$)
         gosub disp_message
      endif  
   
		callpoint!.setDevObject("msg_exceeded","Y")
		user_tpl.credit_limit_warned = 1
   endif

	return

rem ==========================================================================
ship_to_info: rem --- Get and display Bill To Information
              rem      IN: cust_id$
              rem          ship_to_type$
              rem          ship_to_no$
              rem          order_no$
rem ==========================================================================

	if ship_to_type$<>"M" then

		if ship_to_type$="S" then
			custship_dev = fnget_dev("ARM_CUSTSHIP")
			dim custship_tpl$:fnget_tpl$("ARM_CUSTSHIP")
			read record (custship_dev, key=firm_id$+cust_id$+ship_to_no$, dom=*next) custship_tpl$

			callpoint!.setColumnData("<<DISPLAY>>.SNAME",custship_tpl.name$)
			callpoint!.setColumnData("<<DISPLAY>>.SADD1",custship_tpl.addr_line_1$)
			callpoint!.setColumnData("<<DISPLAY>>.SADD2",custship_tpl.addr_line_2$)
			callpoint!.setColumnData("<<DISPLAY>>.SADD3",custship_tpl.addr_line_3$)
			callpoint!.setColumnData("<<DISPLAY>>.SADD4",custship_tpl.addr_line_4$)
			callpoint!.setColumnData("<<DISPLAY>>.SCITY",custship_tpl.city$)
			callpoint!.setColumnData("<<DISPLAY>>.SSTATE",custship_tpl.state_code$)
			callpoint!.setColumnData("<<DISPLAY>>.SZIP",custship_tpl.zip_code$)
		else
			callpoint!.setColumnData("<<DISPLAY>>.SNAME",Translate!.getTranslation("AON_SAME"))
			callpoint!.setColumnData("<<DISPLAY>>.SADD1","")
			callpoint!.setColumnData("<<DISPLAY>>.SADD2","")
			callpoint!.setColumnData("<<DISPLAY>>.SADD3","")
			callpoint!.setColumnData("<<DISPLAY>>.SADD4","")
			callpoint!.setColumnData("<<DISPLAY>>.SCITY","")
			callpoint!.setColumnData("<<DISPLAY>>.SSTATE","")
			callpoint!.setColumnData("<<DISPLAY>>.SZIP","")
		endif

	else

		ordship_dev = fnget_dev("OPE_ORDSHIP")
		dim ordship_tpl$:fnget_tpl$("OPE_ORDSHIP")
		read record (ordship_dev, key=firm_id$+cust_id$+order_no$, dom=*endif) ordship_tpl$

		callpoint!.setColumnData("<<DISPLAY>>.SNAME",ordship_tpl.name$)
		callpoint!.setColumnData("<<DISPLAY>>.SADD1",ordship_tpl.addr_line_1$)
		callpoint!.setColumnData("<<DISPLAY>>.SADD2",ordship_tpl.addr_line_2$)
		callpoint!.setColumnData("<<DISPLAY>>.SADD3",ordship_tpl.addr_line_3$)
		callpoint!.setColumnData("<<DISPLAY>>.SADD4",ordship_tpl.addr_line_4$)
		callpoint!.setColumnData("<<DISPLAY>>.SCITY",ordship_tpl.city$)
		callpoint!.setColumnData("<<DISPLAY>>.SSTATE",ordship_tpl.state_code$)
		callpoint!.setColumnData("<<DISPLAY>>.SZIP",ordship_tpl.zip_code$)
	endif

	callpoint!.setStatus("REFRESH")

	return

rem ==========================================================================
get_op_params:
rem ==========================================================================

	ars01_dev = fnget_dev("ARS_PARAMS")
	dim ars01a$:fnget_tpl$("ARS_PARAMS")

	read record (ars01_dev, key=firm_id$+"AR00") ars01a$

	return

rem ==========================================================================
disp_cust_comments: rem --- Display customer comments
                    rem      IN: cust_id$
rem ==========================================================================

	cmt_text$ = ""
	arm05_dev = fnget_dev("ARM_CUSTCMTS")
	dim arm05a$:fnget_tpl$("ARM_CUSTCMTS")
	more = 1

	read (arm05_dev, key=firm_id$+cust_id$, dom=*next)

	while more
		read record (arm05_dev, end=*break) arm05a$
		if arm05a.firm_id$+arm05a.customer_id$ <> firm_id$+cust$ then break
		cmt_text$ = cmt_text$ + cvs(arm05a.std_comments$,3) + $0A$
	wend

	callpoint!.setColumnData("<<DISPLAY>>.comments", cmt_text$)
	callpoint!.setStatus("REFRESH")

	return

rem ==========================================================================
check_lock_flag: rem --- Check manual record lock
                 rem     OUT: locked = 1 or 0
rem ==========================================================================

	print "in check_lock_flag..."; rem debug

	locked=0
	on pos( callpoint!.getColumnData("OPE_INVHDR.LOCK_STATUS") = "NYS12" ) goto 
:		end_lock,end_lock,locked,on_invoice,update_stat,update_stat,end_lock

locked:

	msg_id$="ORD_LOCKED"
	dim msg_tokens$[1]

	if callpoint!.getColumnData("OPE_INVHDR.PRINT_STATUS")="B" then 
		msg_tokens$[1]=Translate!.getTranslation("AON__BY_BATCH_PRINT")
		gosub disp_message

		if msg_opt$="Y"
			callpoint!.setColumnData("OPE_INVHDR.LOCK_STATUS", "N")
			callpoint!.setStatus("SAVE"); rem --- unlock at BWRI doesn't seem to work
			print "---Clear lock"; rem debug
		else
			locked=1

		endif

	endif

	goto end_lock

on_invoice:

	msg_id$="ORD_ON_REG"
	gosub disp_message

	locked=1
	callpoint!.setStatus("ABORT")

	goto end_lock

update_stat:

	msg_id$="INVOICE_IN_UPDATE"
	gosub disp_message
	locked=1


end_lock:

	print "out"; rem debug

	return

rem ==========================================================================
add_to_batch_print: rem --- Add to batch print file
                    rem      IN: order_no$
rem ==========================================================================

	ope_prntlist_dev = fnget_dev("OPE_PRNTLIST")
	dim ope_prntlist$:fnget_tpl$("OPE_PRNTLIST")
	cust_id$ = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")

	remove (ope_prntlist_dev, key=firm_id$+"O  "+cust_id$+order_no$, dom=*next)

	ope_prntlist.firm_id$     = firm_id$
	ope_prntlist.ordinv_flag$ = "I"
	ope_prntlist.ar_type$     = "  "
	ope_prntlist.customer_id$ = cust_id$
	ope_prntlist.order_no$    = order_no$

	ope_prntlist$ = field(ope_prntlist$)
	write record (ope_prntlist_dev) ope_prntlist$
	print "---Added to print batch"; rem debug
	print "---order:", ope_prntlist.order_no$

	return

rem ==========================================================================
check_print_flag: rem --- Check print flag
                  rem     OUT: locked = 1/0
rem ==========================================================================

	print "in check_print_flag..."; rem debug

	locked = 0
	ar_type$      = callpoint!.getColumnData("OPE_INVHDR.AR_TYPE")
	cust_id$      = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	order_no$     = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")
	print_status$ = callpoint!.getColumnData("OPE_INVHDR.PRINT_STATUS")
	ordinv_flag$  = callpoint!.getColumnData("OPE_INVHDR.ORDINV_FLAG")

	print "---Print status: """, print_status$, """"; rem debug
	print "---picklist_warned flag:", user_tpl.picklist_warned; rem debug
		 
	if ordinv_flag$ = "O" then 
		if print_status$ <> "Y" and !user_tpl.picklist_warned then 
			user_tpl.picklist_warned = 1
			msg_id$ = "OP_PICKLIST_NOT_DONE"
			gosub disp_message

			if msg_opt$ = "N" then
				gosub unlock_order
				locked=1
			endif
		endif
	else
		if ordinv_flag$ = "I" then 
			if print_status$ <> "N" then 
				msg_id$ = "OP_REPRINT_INVOICE"
				gosub disp_message

				if msg_opt$ = "N" then 
					gosub unlock_order
					locked=1
				else
					callpoint!.setColumnData("OPE_INVHDR.PRINT_STATUS", "N")
					print "---Print Status: N"; rem debug
					callpoint!.setStatus("SAVE")
					gosub add_to_batch_print
				endif
			else
				gosub add_to_batch_print
			endif
		endif
	endif

	print "out"; rem debug

	return 

rem ==========================================================================
update_totals: rem --- Update Order/Invoice Totals & Commit Inventory
               rem      IN: wh_id$
               rem          item_id$
               rem          ls_id$ 
               rem          qty
rem ==========================================================================

	inv_type$ = callpoint!.getColumnData("OPE_INVHDR.INVOICE_TYPE")

	call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",iv_files[all],ivs01a$,iv_info$[all],iv_refs$[all],iv_refs[all],table_chans$[all],status
	iv_info$[1] = wh_id$
	iv_info$[2] = item_id$
	iv_info$[3] = ls_id$
	iv_refs[0]  = qty

	while 1
		if pos(opc_linecode.line_type$="SP")=0 then break
		if opc_linecode.dropship$="Y" or inv_type$="P" then break; REM "Dropship or quote
		if line_sign>0 then iv_action$="OE" else iv_action$="UC"
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon",iv_action$,iv_files[all],ivs01a$,iv_info$[all],iv_refs$[all],iv_refs[all],table_chans$[all],iv_status
		break
	wend

	return

rem ==========================================================================
remove_lot_ser_det: rem --- Remove Lot/Serial Detail
                    rem      IN: ar_type$
                    rem          cust$
                    rem          ord$     = order number
                    rem          ord_seq$ = internal seq number
rem ==========================================================================

	inv_type$ = callpoint!.getColumnData("OPE_INVHDR.INVOICE_TYPE")

	ope21_dev = fnget_dev("OPE_ORDLSDET")
	dim ope21a$:fnget_tpl$("OPE_ORDLSDET")
	read (ope21_dev, key=firm_id$+ar_type$+cust$+ord$+ord_seq$, dom=*next)

	while 1
		read record (ope21_dev, end=*break) ope21a$

		if firm_id$<>ope21a.firm_id$ then break
		if ar_type$<>ope21a.ar_type$ then break
		if cust$<>ope21a.customer_id$ then break
		if ord$<>ope21a.order_no$ then break
		if ord_seq$<>ope21a.orddet_seq_ref$ then break

		if opc_linecode.dropship$<>"Y" and inv_type$<>"P" then 
			wh_id$    = ope11a.warehouse_id$
			item_id$  = ope11a.item_id$
			ls_id$    = ""
			qty       = ope21a.qty_ordered
			line_sign = 1
			gosub update_totals

			ls_id$    = ope21a.lotser_no$
			line_sign = -1
			gosub update_totals
		endif

		remove (ope21_dev, key=firm_id$+ar_type$+cust$+ord$+ord_seq$+ope21a.sequence_no$)
	wend

	return

rem ==========================================================================
copy_order: rem --- Duplicate or Credit Historical Invoice
            rem      IN: key_pfx$  = a/r type + cust_id
            rem          line_sign = 1/-1
rem ==========================================================================

	copy_ok$="Y"

	while 1
		rd_key$ = ""
		call stbl("+DIR_SYP")+"bam_inquiry.bbj",
:			gui_dev,
:			Form!,
:			"OPT_INVHDR",
:			"LOOKUP",
:			table_chans$[all],
:			key_pfx$,
:			"PRIMARY",
:			rd_key$

		if cvs(rd_key$,2)<>"" then 
			key_pfx_det$ = rd_key$
			call stbl("+DIR_SYP")+"bam_inquiry.bbj",
:				gui_dev,
:				Form!,
:				"OPT_INVDET",
:				"LOOKUP",
:				table_chans$[all],
:				key_pfx_det$,
:				"PRIMARY",
:				rd_key_det$

			if cvs(rd_key_det$,2)<>"" then 
				opt01_dev = fnget_dev("OPT_INVHDR")
				dim opt01a$:fnget_tpl$("OPT_INVHDR")
				read record (opt01_dev, key=rd_key$) opt01a$
				break
			endif

		else
			copy_ok$="N"
			break
		endif

	wend

	reprice$="N"

	if copy_ok$="Y" then 

		if line_sign=1 then 
			msg_id$ = "OP_REPRICE_ORD"
			gosub disp_message
			reprice$ = msg_opt$
		endif

		call stbl("+DIR_SYP")+"bas_sequences.bbj","ORDER_NO",seq_id$,rd_table_chans$[all]

		if seq_id$<>"" then 
			ope01_dev = fnget_dev("OPE_INVHDR")
			dim ope01a$:fnget_tpl$("OPE_INVHDR")
			call stbl("+DIR_PGM")+"adc_copyfile.aon",opt01a$,ope01a$,status

			ope01a.ar_inv_no$      = ""
			ope01a.backord_flag$   = ""
			ope01a.comm_amt        = ope01a.comm_amt*line_sign
			ope01a.customer_po_no$ = ""
			ope01a.discount_amt    = ope01a.discount_amt*line_sign
			ope01a.expire_date$    = ""
			ope01a.freight_amt     = ope01a.freight_amt*line_sign
			ope01a.invoice_date$   = user_tpl.def_ship$
			ope01a.invoice_type$   = "S"
			ope01a.lock_status$ = "N"
			ope01a.order_date$     = sysinfo.system_date$
			ope01a.order_no$       = seq_id$
			ope01a.ordinv_flag$    = "O"
			ope01a.ord_taken_by$   = sysinfo.user_id$
			ope01a.print_status$   = "N"
			ope01a.reprint_flag$   = ""
			ope01a.shipmnt_date$   = user_tpl.def_ship$
			ope01a.taxable_amt     = ope01a.taxable_amt*line_sign
			ope01a.tax_amount      = ope01a.tax_amount*line_sign
			ope01a.total_cost      = ope01a.total_cost*line_sign
			ope01a.total_sales     = ope01a.total_sales*line_sign

			write record (ope01_dev) ope01a$
			callpoint!.setStatus("SETORIG")

			user_tpl.price_code$   = ope01a.price_code$
			user_tpl.pricing_code$ = ope01a.pricing_code$
			user_tpl.order_date$   = ope01a.order_date$

		rem --- Copy Manual Ship To if any

			if opt01a.shipto_type$="M" then 
				dim ope31a$:fnget_tpl$("OPE_ORDSHIP")
				ope31_dev=fnget_dev("OPE_ORDSHIP")

				dim opt31a$:fnget_tpl$("OPT_INVSHIP")
				opt31_dev=fnget_dev("OPT_INVSHIP")

				read record (opt31_dev, key=firm_id$+opt01a.customer_id$+opt01a.ar_inv_no$, dom=*next) opt31a$
				call stbl("+DIR_PGM")+"adc_copyfile.aon",opt31a$,ope31a$,status
				if status=999 then exitto std_exit
				ope31a.order_no$ = ope01a.order_no$
				ope31a$ = field(ope31a$)
				write record (ope31_dev) ope31a$
			endif

		rem --- Copy detail lines

			dim opt11a$:fnget_tpl$("OPT_INVDET")
			opt11_dev=fnget_dev("OPT_INVDET")

			dim ope11a$:fnget_tpl$("OPE_INVDET")
			ope11_dev=fnget_dev("OPE_INVDET")

			ivm01_dev=fnget_dev("IVM_ITEMMAST")
			dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")

			read (opt11_dev, key=firm_id$+opt01a.ar_type$+opt01a.customer_id$+opt01a.ar_inv_no$, dom=*next)

			opc_linecode_dev = fnget_dev("OPC_LINECODE")
			dim opc_linecode$:fnget_tpl$("OPC_LINECODE")

			disp_line_no=0

			while 1
				read record (opt11_dev, end=*break) opt11a$

				if firm_id$+opt01a.ar_type$+opt01a.customer_id$+opt01a.ar_inv_no$ <>
:					opt11a.firm_id$+opt11a.ar_type$+opt11a.customer_id$+opt11a.ar_inv_no$ 
:				then 
					break
				endif

				call stbl("+DIR_PGM")+"adc_copyfile.aon",opt11a$,ope11a$,status

				if cvs(opt11a.line_code$,2)<>"" then 
					read record (opc_linecode_dev, key=firm_id$+opt11a.line_code$, dom=*next) opc_linecode$
				endif

				if pos(opc_linecode.line_type$="SP") and reprice$="Y" then 
					gosub pricing
				endif

				if opc_linecode.line_type$<>"M" then 
					if opc_linecode.line_type$="O" and ope11a.commit_flag$="N" then 
						ope11a.ext_price  = ope11a.unit_price
						ope11a.unit_price = 0			
					endif

					if line_sign=-1 then 
						ope11a.qty_ordered = -ope11a.qty_shipped
						ope11a.ext_price   = -ope11a.ext_price
					endif

					if opc_linecode.line_type$<>"O" then 
						ope11a.qty_shipped = ope11a.qty_ordered
						ope11a.qty_backord = 0
						ope11a.taxable_amt = 0
						ope11a.ext_price   = round(ope11a.unit_price * ope11a.qty_shipped, 2)
					endif

					if pos(opc_linecode.line_type$="SP")=0 then 
						if opc_linecode.taxable_flag$="Y" then 
							ope11a.taxable_amt = ope11a.ext_price
						endif
					else
						read record (ivm01_dev, key=firm_id$+ope11a.item_id$, dom=*next) ivm01a$
						if opc_linecode.taxable_flag$="Y" and ivm01a.taxable_flag$="Y" then 
							ope11a.taxable_amt = ope11a.ext_price
						endif
					endif
				endif

				ope11a.order_no$     = ope01a.order_no$
				ope11a.est_shp_date$ = ope01a.shipmnt_date$
				ope11a.commit_flag$  = "Y"
				ope11a.pick_flag$    = "N"

				if ope11a.est_shp_date$>user_tpl.def_commit$ then 
					ope11a.commit_flag$ = "N"
				endif

				if user_tpl.blank_whse$="N" and cvs(ope11a.warehouse_id$,2)="" and 
:					opc_linecode.dropship$="Y" and user_tpl.dropship_whse$="N"
:				then
					ope11a.warehouse_id$ = user_tpl.def_whse$
				endif

				call stbl("+DIR_SYP")+"bas_sequences.bbj","INTERNAL_SEQ_NO",int_seq_no$,table_chans$[all]
				ope11a.internal_seq_no$=int_seq_no$
				disp_line_no=disp_line_no+1
				line_no_mask$=callpoint!.getDevObject("line_no_mask")
				ope11a.line_no$=str(disp_line_no:line_no_mask$)

				ope11a$ = field(ope11a$)
				write record (ope11_dev) ope11a$
			wend

			callpoint!.setStatus("RECORD:["+firm_id$+ope01a.ar_type$+ope01a.customer_id$+ope01a.order_no$+"]")
			user_tpl.hist_ord$ = "Y"

		endif

	endif

	return

rem ==========================================================================
pricing: rem --- Call Pricing routine
         rem      IN: ope11a$ - Order Detail record
         rem          seq_id$ - order number
         rem          ivm02_dev
         rem          ivs01_dev
rem ==========================================================================

	ope01_dev = fnget_dev("OPE_INVHDR")
	dim ope01a$:fnget_tpl$("OPE_INVHDR")

	ivm02_dev = fnget_dev("IVM_ITEMWHSE")
	dim ivm02a$:fnget_tpl$("IVM_ITEMWHSE")

	ivs01_dev = fnget_dev("IVS_PARAMS")
	dim ivs01a$:fnget_tpl$("IVS_PARAMS")

	ordqty   =ope11a.qty_ordered
	wh$      =ope11a.warehouse_id$
	item$    =ope11a.item_id$
	ar_type$ =ope11a.ar_type$
	cust$    =ope11a.customer_id$
	ord$     =seq_id$
	read record (ope01_dev, key=firm_id$+ar_type$+cust$+ord$) ope01a$

	dim pc_files[6]
	pc_files[1] = fnget_dev("IVM_ITEMMAST")
	pc_files[2] = ivm02_dev
	pc_files[3] = fnget_dev("IVM_ITEMPRIC")
	pc_files[4] = fnget_dev("IVC_PRICCODE")
	pc_files[5] = fnget_dev("ARS_PARAMS")
	pc_files[6] = ivs01_dev

	call stbl("+DIR_PGM")+"opc_pricing.aon",pc_files[all],firm_id$,wh$,item$,user_tpl.price_code$,cust$,
:		user_tpl.order_date$,user_tpl.pricing_code$,ordqty,typeflag$,price,disc,status
	if status=999 then exitto std_exit

	if price=0 then
		msg_id$="ENTER_PRICE"
		gosub disp_message
	else
		ope11a.unit_price   = price
		ope11a.disc_percent = disc
	endif

	if disc=100 then
		read record (ivm02_dev, key=firm_id$+wh$+item$) ivm02a$
		ope11a.std_list_prc = ivm02a.cur_price
	else
		ope11a.std_list_prc = (price*100)/(100-disc)
	endif

	return

rem ==========================================================================
unlock_order: REM --- Unlock Order
rem ==========================================================================
	
	callpoint!.setColumnData("OPE_INVHDR.LOCK_STATUS", "N")
   callpoint!.setStatus("SAVE")

	return 

rem ==========================================================================
force_print_status: rem --- Force print status to N and write
rem ==========================================================================

	print "in force_print_status..."; rem debug

	if callpoint!.getColumnData("OPE_INVHDR.PRINT_STATUS") = "Y" then
		callpoint!.setColumnData("OPE_INVHDR.PRINT_STATUS", "N")

	rem --- Write flag to file so opc_creditaction can see it

		gosub get_disk_rec
		ordhdr_rec$ = field(ordhdr_rec$)
		write record (ordhdr_dev) ordhdr_rec$

		callpoint!.setStatus("SETORIG")
		print "---Print status written, """, ordhdr_rec.print_status$, """"; rem debug
	endif

	print "out"; rem debug

	return

rem ==========================================================================
do_credit_action: rem --- Launch the credit action program / form
rem ==========================================================================

rem --- Invoicing should only allow this if already on Credit Hold.

rem --- The following line will prevent credit action from ever being called.
action$="U"
return

	if callpoint!.getColumnData("OPE_INVHDR.CREDIT_FLAG") <> "C"
		action$="U"
		return
	endif

	print "in do_credit_action..."; rem debug

	inv_type$ = callpoint!.getColumnData("OPE_INVHDR.INVOICE_TYPE")
	cust_id$  = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	order_no$ = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")

rem --- Should we call Credit Action?

	if user_tpl.credit_installed$ = "Y" and inv_type$ <> "P" and cvs(cust_id$, 2) <> "" and cvs(order_no$, 2) <> "" then
		callpoint!.setDevObject("run_by", "invoice")
		call user_tpl.pgmdir$+"opc_creditaction.aon", cust_id$, order_no$, table_chans$[all], callpoint!, action$, status
		if status = 999 then goto std_exit

	rem --- Delete the order

		if action$ = "D" then 
			callpoint!.setStatus("DELETE")
			return
		endif

		if pos(action$="HC")<>0 then

		rem --- Order on hold

			callpoint!.setColumnData("OPE_INVHDR.CREDIT_FLAG","C")
		else
			if action$="R" then

			rem --- Order released

				callpoint!.setColumnData("OPE_INVHDR.CREDIT_FLAG","R")
				terms$ = str(callpoint!.getDevObject("new_terms_code"))

				if terms$ <> "" then
					callpoint!.setColumnData("OPE_INVHDR.TERMS_CODE", terms$)
				endif
				callpoint!.setDevObject("msg_released","Y")
				callpoint!.setDevObject("msg_hold","")
				call user_tpl.pgmdir$+"opc_creditmsg.aon","H",callpoint!,UserObj!
			else
				callpoint!.setColumnData("OPE_INVHDR.CREDIT_FLAG","")			
			endif
		endif

	rem --- Order was printed within the credit action program

		if str(callpoint!.getDevObject("document_printed")) = "Y" then 
			callpoint!.setColumnData("OPE_INVHDR.PRINT_STATUS", "Y")
			print "---Print Status: Y"; rem debug
		endif

	endif

	print "---action$: """, action$, """"; rem debug
	print "out"; rem debug

	return

rem ==========================================================================
do_invoice: rem --- Print an Invoice
rem ==========================================================================

	print "in do_invoice..."; rem debug

rem --- Make sure everything's written back to disk

	gosub get_disk_rec
	ordhdr_rec$ = field(ordhdr_rec$)
	write record (ordhdr_dev) ordhdr_rec$

rem --- Call printing program

	call user_tpl.pgmdir$+"opc_invoice.aon::on_demand", cust_id$, order_no$, callpoint!, table_chans$[all], status
	if status = 999 then goto std_exit

	callpoint!.setColumnData("OPE_INVHDR.PRINT_STATUS", "Y")

	msg_id$ = "OP_INVOICE_DONE"
	gosub disp_message

	print "---Print Status: Y"; rem debug
	print "out"; rem debug

	return

rem ==========================================================================
clear_avail: rem --- Clear Availability Information
rem ==========================================================================

	userObj!.getItem(user_tpl.avail_oh).setText("")
	userObj!.getItem(user_tpl.avail_comm).setText("")
	userObj!.getItem(user_tpl.avail_avail).setText("")
	userObj!.getItem(user_tpl.avail_oo).setText("")
	userObj!.getItem(user_tpl.avail_wh).setText("")
	userObj!.getItem(user_tpl.avail_type).setText("")
	userObj!.getItem(user_tpl.dropship_flag).setText("")
	userObj!.getItem(user_tpl.manual_price).setText("")
	userObj!.getItem(user_tpl.alt_super).setText("")

	return

rem ==========================================================================
get_comm_percent: rem --- Get commission percent from salesperson file
                  rem      IN: slsp$ - salesperson code
rem ==========================================================================

return;rem --- Remove this line if the client decides they want to see the Commission percent

	file$ = "ARC_SALECODE"
	salecode_dev = fnget_dev(file$)
	dim salecode_rec$:fnget_tpl$(file$)

	start_block = 1

	if start_block then
		find record (salecode_dev, key=firm_id$+"F"+slsp$, dom=*endif) salecode_rec$
		callpoint!.setColumnData("OPE_INVHDR.COMM_PERCENT", salecode_rec.comm_rate$)
		callpoint!.setStatus("REFRESH")
	endif

	return

rem ==========================================================================
make_invoice: rem --- Change an Order into an Invoice
rem ==========================================================================

	print "in make_invoice..."; rem debug

	gosub check_print_flag

	if !locked and 
:		callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID") <> "" and 
:		callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")    <> "" and 
:		callpoint!.getColumnData("OPE_INVHDR.ORDINV_FLAG") = "O" 
:	then

	rem --- Set Invoice number

		call stbl("+DIR_SYP")+"bas_sequences.bbj","INVOICE_NO",inv_no$,table_chans$[all]
		
		if inv_no$ = "" then
			callpoint!.setStatus("NEWREC")
			locked = 1
			print "---No to new invoice number"; rem debug
		else
			callpoint!.setColumnData("OPE_INVHDR.AR_INV_NO", inv_no$)
			callpoint!.setColumnData("OPE_INVHDR.ORDINV_FLAG", "I")
			callpoint!.setColumnData("OPE_INVHDR.INVOICE_DATE", sysinfo.system_date$)
			callpoint!.setColumnData("OPE_INVHDR.PRINT_STATUS", "N")
			print "---Print Status: N"; rem debug
			callpoint!.setColumnData("OPE_INVHDR.LOCK_STATUS", "Y")
			print "---Set lock"; rem debug
			callpoint!.setColumnData("OPE_INVHDR.LOCK_STATUS", "N"); rem debug, forcing the lock off for now, this isn't working correctly
			user_tpl.prev_disc_code$ = ""
			user_tpl.price_code$ = "Y"
			order_no$ = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")
			gosub add_to_batch_print
			callpoint!.setOptionEnabled("MINV",0)
			callpoint!.setOptionEnabled("UINV",1)
			callpoint!.setStatus("SAVE;REFRESH")
		endif
		
	endif

	print "out"; rem debug

	return

rem ==========================================================================
get_cash: rem --- Launch the Cash Transaction form
rem ==========================================================================

	print "Hdr: in get_cash..."; rem debug

	custmast_dev = fnget_dev("ARM_CUSTMAST")
	dim custmast_tpl$:fnget_tpl$("ARM_CUSTMAST")
	cust_id$=callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	find record (custmast_dev, key=firm_id$+cust_id$) custmast_tpl$

	callpoint!.setDevObject("tax_amount",   callpoint!.getColumnData("OPE_INVHDR.TAX_AMOUNT"))
	callpoint!.setDevObject("freight_amt",  callpoint!.getColumnData("OPE_INVHDR.FREIGHT_AMT"))
	callpoint!.setDevObject("discount_amt", callpoint!.getColumnData("OPE_INVHDR.DISCOUNT_AMT"))

	dim dflt_data$[3,1]
	dflt_data$[1,0]="INVOICE_DATE"
	dflt_data$[1,1]=callpoint!.getColumnData("OPE_INVHDR.INVOICE_DATE")
	dflt_data$[2,0]="AR_INV_NO"
	dflt_data$[2,1]=callpoint!.getColumnData("OPE_INVHDR.AR_INV_NO")
	dflt_data$[3,0]="CUSTOMER_NAME"
	dflt_data$[3,1]=custmast_tpl.customer_name$

	order_no$ = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")
	key_pfx$  = firm_id$+"  "+cust_id$+order_no$

	print "---Calling cash form..."; rem debug

	call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:		"OPE_INVCASH", 
:		stbl("+USER_ID"), 
:		"", 
:		key_pfx$, 
:		table_chans$[all], 
:		"",
:		dflt_data$[all]

	print "---Setting cash sale flag"; rem debug
	callpoint!.setColumnData("OPE_INVHDR.CASH_SALE", "Y")

rem --- Write flag to disk

	gosub get_disk_rec

	ordhdr_rec$ = field(ordhdr_rec$)
	write record (ordhdr_dev) ordhdr_rec$
	print "out"; rem debug

	return

rem ==========================================================================
do_totals: rem --- Run the totals form and write back
rem ==========================================================================

rem --- Call the form

	dim dflt_data$[4,1]
	dflt_data$[1,0] = "TOTAL_SALES"
	dflt_data$[1,1] = callpoint!.getColumnData("OPE_INVHDR.TOTAL_SALES")
	dflt_data$[2,0] = "DISCOUNT_AMT"
	dflt_data$[2,1] = callpoint!.getColumnData("OPE_INVHDR.DISCOUNT_AMT")
	dflt_data$[3,0] = "TAX_AMOUNT"
	dflt_data$[3,1] = callpoint!.getColumnData("OPE_INVHDR.TAX_AMOUNT")
	dflt_data$[4,0] = "FREIGHT_AMT"
	dflt_data$[4,1] = callpoint!.getColumnData("OPE_INVHDR.FREIGHT_AMT")

rem --- Set Dev Objects for use in the form

	callpoint!.setDevObject("disc_amt",str(callpoint!.getColumnData("OPE_INVHDR.DISCOUNT_AMT")))
	callpoint!.setDevObject("frt_amt",str(callpoint!.getColumnData("OPE_INVHDR.FREIGHT_AMT")))

	call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:		"OPE_ORDTOTALS", 
:		stbl("+USER_ID"), 
:		"", 
:		"", 
:		table_chans$[all],
:		"", 
:		dflt_data$[all],
:		user_tpl$,
:		UserObj!

rem --- Set fields from the Order Totals form and write back

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))

	callpoint!.setColumnData("OPE_INVHDR.TOTAL_SALES",  str(ordHelp!.getExtPrice()))
	callpoint!.setColumnData("OPE_INVHDR.TOTAL_COST",   str(ordHelp!.getExtCost()))
	callpoint!.setColumnData("OPE_INVHDR.TAXABLE_AMT",  str(ordHelp!.getTaxable()))

	total_amt=num(ordHelp!.getExtPrice())
	disc_amt=num(callpoint!.getDevObject("disc_amt"))
	tax_amt=num(callpoint!.getDevObject("tax_amt"))
	frt_amt=num(callpoint!.getDevObject("frt_amt"))
	callpoint!.setColumnData("OPE_INVHDR.DISCOUNT_AMT", str(disc_amt))
	callpoint!.setColumnData("<<DISPLAY>>.SUBTOTAL",str(total_amt - disc_amt))
	callpoint!.setColumnData("OPE_INVHDR.TAX_AMOUNT",   str(tax_amt))
	callpoint!.setColumnData("OPE_INVHDR.FREIGHT_AMT", str(frt_amt))
	callpoint!.setColumnData("<<DISPLAY>>.NET_SALES",str((total_amt - disc_amt) + tax_amt + frt_amt))
	callpoint!.setColumnData("<<DISPLAY>>.ORDER_TOT",str((total_amt - disc_amt) + tax_amt + frt_amt))
	callpoint!.setStatus("REFRESH-SAVE")
	
	return

rem ==========================================================================
get_disk_rec: rem --- Get disk record, update with current form data
              rem     OUT: ordhdr_rec$, updated
              rem          ordhdr_tpl$
              rem          ordhdr_dev
              rem          cust_id$
              rem          order_no$
rem ==========================================================================

	print "in: get_disk_rec..."; rem debug

	file_name$  = "OPE_ORDHDR"
	ordhdr_dev  = fnget_dev(file_name$)
	ordhdr_tpl$ = fnget_tpl$(file_name$)
	dim ordhdr_rec$:ordhdr_tpl$

	cust_id$  = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	order_no$ = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")

	found = 0
	start_block = 1

	if start_block then
		read record (ordhdr_dev, key=firm_id$+"  "+cust_id$+order_no$, dom=*endif) ordhdr_rec$
		found = 1
	endif

rem --- Copy in any form data that's changed

	ordhdr_rec$ = util.copyFields(ordhdr_tpl$, callpoint!)

rem debug --- This is a Barista kludge

	if !found then 
		write record (ordhdr_dev, key=firm_id$+"  "+cust_id$+order_no$, dom=*endif) ordhdr_rec$
		callpoint!.setStatus("SETORIG")
	endif

	print "---Record found: ", iff(found, "yes", "no"); rem debug
	print "out"; rem debug

	return

rem ==========================================================================
disp_totals: rem --- Get order totals and display, save header totals
rem IN: disc_amt
rem IN: freight_amt
rem ==========================================================================

	ttl_ext_price = num(callpoint!.getColumnData("OPE_INVHDR.TOTAL_SALES"))
	tax_amt = num(callpoint!.getColumnData("OPE_INVHDR.TAX_AMOUNT"))
	sub_tot = ttl_ext_price - disc_amt
	net_sales = sub_tot + tax_amt + freight_amt

	callpoint!.setColumnData("OPE_INVHDR.TOTAL_COST",str(ttl_ext_cost))
	callpoint!.setColumnData("<<DISPLAY>>.SUBTOTAL", str(sub_tot))
	callpoint!.setColumnData("<<DISPLAY>>.NET_SALES", str(net_sales))
	callpoint!.setColumnData("<<DISPLAY>>.ORDER_TOT",str(net_sales))

	callpoint!.setStatus("REFRESH")

	return

rem ==========================================================================
init_msgs: rem --- Clear out DevObjects for messages
rem ==========================================================================

	callpoint!.setDevObject("msg_printed","")
	callpoint!.setDevObject("msg_backorder","")
	callpoint!.setDevObject("msg_quote","")
	callpoint!.setDevObject("msg_credit_memo","")
	callpoint!.setDevObject("msg_exceeded","")
	callpoint!.setDevObject("msg_hold","")
	callpoint!.setDevObject("msg_credit_okay","")
	callpoint!.setDevObject("msg_released","")

	return

rem ==========================================================================
calculate_tax: rem --- Calculate and display Tax Amount
rem IN: disc_amt
rem IN: freight_amt
rem ==========================================================================

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	tax_amount = ordHelp!.calculateTax(disc_amt, freight_amt,num(callpoint!.getColumnData("OPE_INVHDR.TAXABLE_AMT")))

	callpoint!.setColumnData("OPE_INVHDR.TAX_AMOUNT",str(tax_amount))
	callpoint!.setStatus("REFRESH")

	return
[[OPE_INVHDR.ASHO]]
print "Hdr:ASHO"; rem debug

rem --- Get default POS station

	call stbl("+DIR_SYP")+"bam_run_prog.bbj", "OPE_INVSTATION", stbl("+USER_ID"), "MNT", "", table_chans$[all]

    rem --- Check for a POS record by station

	station$ = "DEFAULT"
	station$ = stbl("OPE_DEF_STATION", err=*next)

	file$ = "OPM_POINTOFSALE"
	dim pointofsale_rec$:fnget_tpl$(file$)

	find record (fnget_dev(file$), key=firm_id$+pad(station$, 16), dom=no_pointofsale) pointofsale_rec$
	goto end_pointofsale

no_pointofsale: rem --- Should we create a default record?

	msg_id$ = "POS_REC_NOT_FOUND"
	dim msg_tokens$[1]
	msg_tokens$[1] = cvs(station$, 2)

	gosub disp_message

	if msg_opt$ = "N" then
		callpoint!.setStatus("EXIT")
		break; rem --- Exit callpoint
	endif

rem --- Create a default POS record

	dim sysinfo$:stbl("+SYSINFO_TPL")
	sysinfo$=stbl("+SYSINFO")

	pointofsale_rec.firm_id$         = firm_id$
	pointofsale_rec.default_station$ = pad(station$, 16)
	pointofsale_rec.skip_whse$       = "N"
	pointofsale_rec.val_ctr_prt$     = sysinfo.printer_id$
	pointofsale_rec.val_rec_prt$     = sysinfo.printer_id$
	pointofsale_rec.cntr_printer$    = sysinfo.printer_id$
	pointofsale_rec.rec_printer$     = sysinfo.printer_id$

	write record (pointofsale_dev) pointofsale_rec$
		
end_pointofsale:

	user_tpl.skip_whse$    = pointofsale_rec.skip_whse$
	user_tpl.warehouse_id$ = pointofsale_rec.warehouse_id$	
[[OPE_INVHDR.ASIZ]]
print "Hdr:ASIZ"; rem debug

rem --- Create Empty Availability window

	grid! = util.getGrid(Form!)
	grid!.setSize(grid!.getWidth(), grid!.getHeight() - 75)

	cwin! = util.getChild(Form!).getControl(15000)
	cwin!.setLocation(cwin!.getX(), grid!.getY() + grid!.getHeight())
	cwin!.setSize(grid!.getWidth(), cwin!.getHeight())

	mwin! = cwin!.getControl(15999)
	mwin!.setSize(grid!.getWidth(), mwin!.getHeight())
[[OPE_INVHDR.BSHO]]
print "Hdr:BSHO"; rem debug

rem --- Documentation
rem     Old s$(7,1) = 0 -> user_tpl.hist_ord$ = "Y" - order came from history
rem                 = 1 -> user_tpl.hist_ord$ = "N"

rem --- Open needed files

	num_files=41
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="ARM_CUSTMAST",  open_opts$[1]="OTA"
	open_tables$[2]="ARM_CUSTSHIP",  open_opts$[2]="OTA"
	open_tables$[3]="OPE_ORDSHIP",   open_opts$[3]="OTA"
	open_tables$[4]="ARS_PARAMS",    open_opts$[4]="OTA"
	open_tables$[5]="ARM_CUSTDET",   open_opts$[5]="OTA"
	open_tables$[6]="OPE_INVCASH",   open_opts$[6]="OTA"
	open_tables$[7]="ARS_CREDIT",    open_opts$[7]="OTA"
	open_tables$[8]="OPC_LINECODE",  open_opts$[8]="OTA"
	open_tables$[9]="GLS_PARAMS",    open_opts$[9]="OTA"
	open_tables$[10]="GLS_PARAMS",   open_opts$[10]="OTA"
	open_tables$[11]="IVM_LSMASTER", open_opts$[11]="OTA"
	open_tables$[12]="IVX_LSCUST",   open_opts$[12]="OTA"
	open_tables$[13]="IVM_ITEMMAST", open_opts$[13]="OTA"
	open_tables$[15]="IVX_LSVEND",   open_opts$[15]="OTA"
	open_tables$[16]="IVM_ITEMWHSE", open_opts$[16]="OTA"
	open_tables$[17]="IVM_ITEMACT",  open_opts$[17]="OTA"
	open_tables$[18]="IVT_ITEMTRAN", open_opts$[18]="OTA"
	open_tables$[19]="IVM_ITEMTIER", open_opts$[19]="OTA"
	open_tables$[20]="IVM_ITEMACT",  open_opts$[20]="OTA"
	open_tables$[21]="IVM_ITEMVEND", open_opts$[21]="OTA"
	open_tables$[22]="IVT_LSTRANS",  open_opts$[22]="OTA"
	open_tables$[23]="OPT_INVHDR",   open_opts$[23]="OTA"
	open_tables$[24]="OPT_INVDET",   open_opts$[24]="OTA"
	open_tables$[25]="OPE_ORDDET",   open_opts$[25]="OTA"
	open_tables$[26]="OPT_INVSHIP",  open_opts$[26]="OTA"
	open_tables$[27]="OPE_CREDDATE", open_opts$[27]="OTA"
	open_tables$[28]="IVC_WHSECODE", open_opts$[28]="OTA"
	open_tables$[29]="IVS_PARAMS",   open_opts$[29]="OTA"
	open_tables$[30]="OPE_ORDLSDET", open_opts$[30]="OTA"
	open_tables$[31]="IVM_ITEMPRIC", open_opts$[31]="OTA"
	open_tables$[32]="IVC_PRICCODE", open_opts$[32]="OTA"
	open_tables$[33]="ARM_CUSTCMTS", open_opts$[33]="OTA"
	open_tables$[34]="OPE_PRNTLIST", open_opts$[34]="OTA"
	open_tables$[35]="OPM_POINTOFSALE", open_opts$[35]="OTA"
	open_tables$[36]="ARC_SALECODE", open_opts$[36]="OTA"
	open_tables$[37]="OPC_DISCCODE", open_opts$[37]="OTA"
	open_tables$[38]="OPC_TAXCODE",  open_opts$[38]="OTA"
	open_tables$[39]="OPE_ORDHDR",   open_opts$[39]="OTA"
	open_tables$[40]="ARC_TERMCODE", open_opts$[40]="OTA"
	open_tables$[41]="IVM_ITEMSYN",open_opts$[41]="OTA"
	
gosub open_tables

rem --- Set table_chans$[all] into util object for getDev() and getTmpl()

	declare ArrayObject tableChans!

	call stbl("+DIR_PGM")+"adc_array.aon::str_array2object", table_chans$[all], tableChans!, status
	if status = 999 then goto std_exit
	util.setTableChans(tableChans!)

rem --- get AR Params

	dim ars01a$:open_tpls$[4]
	read record (num(open_chans$[4]), key=firm_id$+"AR00") ars01a$
	if ars01a.op_totals_warn$="" ars01a.op_totals_warn$="4"
	callpoint!.setDevObject("totals_warn",ars01a.op_totals_warn$)

	dim ars_credit$:open_tpls$[7]
	read record (num(open_chans$[7]), key=firm_id$+"AR01") ars_credit$

rem --- get IV Params

	dim ivs01a$:open_tpls$[29]
	read record (num(open_chans$[29]), key=firm_id$+"IV00") ivs01a$

rem --- See if blank warehouse exists

	blank_whse$ = "N"
	dim ivm10c$:open_tpls$[28]
	start_block = 1
	
	if start_block then
		read record (num(open_chans$[28]), key=firm_id$+"C"+ivm10c.warehouse_id$, dom=*endif) ivm10c$
		blank_whse$ = "Y"
	endif

rem --- Disable display fields

	declare BBjVector column!
	column! = BBjAPI().makeVector()

	column!.addItem("<<DISPLAY>>.BADD1")
	column!.addItem("<<DISPLAY>>.BADD2")
	column!.addItem("<<DISPLAY>>.BADD3")
	column!.addItem("<<DISPLAY>>.BADD4")
	column!.addItem("<<DISPLAY>>.BCITY")
	column!.addItem("<<DISPLAY>>.BSTATE")
	column!.addItem("<<DISPLAY>>.BZIP")
	column!.addItem("<<DISPLAY>>.ORDER_TOT")

	if ars01a.job_nos$<>"Y" then 
		column!.addItem("OPE_INVHDR.JOB_NO")
	endif

	callpoint!.setColumnEnabled(column!, -1)

	column!.clear()
	column!.addItem("<<DISPLAY>>.SNAME")
	column!.addItem("<<DISPLAY>>.SADD1")
	column!.addItem("<<DISPLAY>>.SADD2")
	column!.addItem("<<DISPLAY>>.SADD3")
	column!.addItem("<<DISPLAY>>.SADD4")
	column!.addItem("<<DISPLAY>>.SCITY")
	column!.addItem("<<DISPLAY>>.SSTATE")
	column!.addItem("<<DISPLAY>>.SZIP")
	callpoint!.setColumnEnabled(column!, -1)

	column!.addItem("<<DISPLAY>>.AGING_FUTURE")
	column!.addItem("<<DISPLAY>>.AGING_CUR")
	column!.addItem("<<DISPLAY>>.AGING_30")
	column!.addItem("<<DISPLAY>>.AGING_60")
	column!.addItem("<<DISPLAY>>.AGING_90")
	column!.addItem("<<DISPLAY>>.AGING_120")
	column!.addItem("<<DISPLAY>>.TOT_AGING")
	callpoint!.setColumnEnabled(column!, -1)

rem --- Save display control objects

	UserObj!.addItem( util.getControl(callpoint!, "<<DISPLAY>>.ORDER_TOT") )
	UserObj!.addItem( util.getControl(callpoint!, "<<DISPLAY>>.SUBTOTAL") )
	UserObj!.addItem( util.getControl(callpoint!, "<<DISPLAY>>.NET_SALES") )
	UserObj!.addItem( util.getControl(callpoint!, "OPE_INVHDR.TOTAL_SALES") )
	UserObj!.addItem( util.getControl(callpoint!, "OPE_INVHDR.TOTAL_COST") )
	UserObj!.addItem( util.getControl(callpoint!, "OPE_INVHDR.TAX_AMOUNT") )
	UserObj!.addItem( util.getControl(callpoint!, "OPE_INVHDR.DISCOUNT_AMT") )
	UserObj!.addItem( util.getControl(callpoint!, "<<DISPLAY>>.BACKORDERED") )
	UserObj!.addItem( util.getControl(callpoint!, "<<DISPLAY>>.CREDIT_HOLD") )

	callpoint!.setDevObject("credit_hold_control", util.getControl(callpoint!, "<<DISPLAY>>.CREDIT_HOLD")); rem used in opc_creditcheck
	callpoint!.setDevObject("backordered_control", util.getControl(callpoint!, "<<DISPLAY>>.BACKORDERED")); rem used in opc_creditcheck

rem --- Setup user_tpl$
    
	tpl$ = 
:		"credit_installed:c(1), " +
:		"balance:n(15), " +
:		"credit_limit:n(15), " +
:		"display_bal:c(1), " +
:		"ord_tot:n(15), " +
:		"def_ship:c(8), " + 
:		"def_commit:c(8), " +
:		"blank_whse:c(1), " +
:		"line_code:c(1), " +
:		"line_type:c(1), " +
:		"dropship_whse:c(1), " +
:		"def_whse:c(10), " +
:		"avail_oh:u(1), " +
:		"avail_comm:u(1), " +
:		"avail_avail:u(1), " +
:		"avail_oo:u(1), " +
:		"avail_wh:u(1), " +
:		"avail_type:u(1), " +
:		"dropship_flag:u(1), " +
:		"manual_price:u(1), " +
:		"alt_super:u(1), " +
:		"ord_tot_obj:u(1), " +
:		"price_code:c(2), " +
:		"pricing_code:c(4), " +
:		"order_date:c(8), " +
:		"pick_hold:c(1), " +
:		"pgmdir:c(1*), " +
:		"skip_whse:c(1), " +
:		"warehouse_id:c(2), " +
:		"user_entry:c(1), " +
:		"cur_row:n(5), " +
:		"skip_ln_code:c(1), " +
:		"hist_ord:c(1), " +
:		"cash_sale:c(1), " +
:		"cash_cust:c(6), " +
:		"bo_col:u(1), " +
:		"shipped_col:u(1), " +
:		"prod_type_col:u(1), " +
:		"unit_price_col:u(1), " +
:		"allow_bo:c(1), " +
:		"amount_mask:c(1*)," +
:		"line_taxable:c(1), " +
:		"item_taxable:c(1), " +
:		"min_line_amt:n(5), " +
:		"min_ord_amt:n(5), " +
:		"item_price:n(15), " +
:		"line_dropship:c(1), " +
:		"dropship_cost:c(1), " +
:		"lotser_flag:c(1), " +
:		"new_detail:u(1), " +
:		"prev_line_code:c(1*), " +
:		"prev_item:c(1*), " +
:		"prev_qty_ord:n(15), " +
:		"prev_boqty:n(15), " +
:		"prev_shipqty:n(15), " +
:		"prev_ext_price:n(15), " +
:		"prev_taxable:n(15), " +
:		"prev_ext_cost:n(15), " +
:		"prev_disc_code:c(1*), "+
:		"prev_ship_to:c(1*), " +
:		"prev_sales_total:n(15), " +
:		"prev_unitprice:n(15), " +
:		"is_cash_sale:u(1), " +
:		"detail_modified:u(1), " +
:		"record_deleted:u(1), " +
:		"item_wh_failed:u(1), " +
:		"do_end_of_form:u(1), " +
:		"picklist_warned:u(1), " +
:		"do_totals_form:u(1), " +
:		"disc_code:c(1*), " +
:		"tax_code:c(1*), " +
:		"new_order:u(1), " +
:		"credit_limit_warned:u(1), " +
:		"shipto_warned:u(1), " +
:		"first_read:u(1), " +
:		"line_prod_type_pr:c(1)"

	dim user_tpl$:tpl$

	user_tpl.credit_installed$ = ars_credit.sys_install$
	user_tpl.pick_hold$        = ars_credit.pick_hold$
	user_tpl.display_bal$      = ars_credit.display_bal$
	user_tpl.blank_whse$       = blank_whse$
	user_tpl.dropship_whse$    = ars01a.dropshp_whse$
	user_tpl.amount_mask$      = ars01a.amount_mask$
	user_tpl.line_code$        = ars01a.line_code$
	user_tpl.skip_ln_code$     = ars01a.skip_ln_code$
	user_tpl.cash_sale$        = ars01a.cash_sale$
	user_tpl.cash_cust$        = ars01a.customer_id$
	user_tpl.allow_bo$         = ars01a.backorders$
	user_tpl.dropship_cost$    = ars01a.dropshp_cost$
	user_tpl.min_ord_amt       = num(ars01a.min_ord_amt$)
	user_tpl.min_line_amt      = num(ars01a.min_line_amt$)
	user_tpl.def_whse$         = ivs01a.warehouse_id$
	user_tpl.lotser_flag$      = ivs01a.lotser_flag$
	user_tpl.pgmdir$           = stbl("+DIR_PGM",err=*next)
	user_tpl.cur_row           = -1
	user_tpl.is_cash_sale      = 0
	user_tpl.detail_modified   = 0
	user_tpl.record_deleted    = 0
	user_tpl.item_wh_failed    = 1
	user_tpl.do_end_of_form    = 1
	user_tpl.picklist_warned   = 0
	user_tpl.do_totals_form    = 1
	user_tpl.new_order         = 0
	user_tpl.credit_limit_warned = 0
	user_tpl.shipto_warned     = 0
	user_tpl.first_read        = 1

rem --- Columns for the util disableCell() method

	user_tpl.bo_col            = 9
	user_tpl.shipped_col       = 10
	user_tpl.prod_type_col     = 5
	user_tpl.unit_price_col    = 8

	user_tpl.prev_line_code$   = ""
	user_tpl.prev_item$        = ""
	user_tpl.prev_qty_ord      = 0
	user_tpl.prev_boqty        = 0
	user_tpl.prev_shipqty      = 0
	user_tpl.prev_ext_price    = 0; rem used in detail section to hold the line extension 
	user_tpl.prev_ext_cost     = 0
	user_tpl.prev_disc_code$   = ""
	user_tpl.prev_ship_to$     = ""
	user_tpl.prev_sales_total  = 0; rem used in totals section to hold the order sale total
	user_tpl.prev_unitprice    = 0

rem --- Ship and Commit dates

	dim sysinfo$:stbl("+SYSINFO_TPL")
	sysinfo$=stbl("+SYSINFO")

	pgmdir$ = ""
	pgmdir$ = stbl("+DIR_PGM")

	orddate$ = sysinfo.system_date$
	comdate$ = orddate$
	shpdate$ = orddate$

	comdays = num(ars01a.commit_days$)
	shpdays = num(ars01a.def_shp_days$)

	if comdays then call pgmdir$+"adc_daydates.aon", orddate$, comdate$, comdays
	if shpdays then call pgmdir$+"adc_daydates.aon", orddate$, shpdate$, shpdays

	user_tpl.def_ship$   = shpdate$
	user_tpl.def_commit$ = comdate$

rem --- Save the indices of the controls for the Avail Window, setup in AFMC

	user_tpl.avail_oh      = 2
	user_tpl.avail_comm    = 3
	user_tpl.avail_avail   = 4
	user_tpl.avail_oo      = 5
	user_tpl.avail_wh      = 6
	user_tpl.avail_type    = 7
	user_tpl.dropship_flag = 8
	user_tpl.manual_price  = 9
	user_tpl.alt_super = 10
	user_tpl.ord_tot_obj   = 11; rem set here in BSHO

	callpoint!.setDevObject("subtot_disp","12")
	callpoint!.setDevObject("net_sales_disp","13")
	callpoint!.setDevObject("total_sales_disp","14")
	callpoint!.setDevObject("total_cost","15")
	callpoint!.setDevObject("tax_amt_disp","16")
	callpoint!.setDevObject("precision",ivs01a.precision$)
	callpoint!.setDevObject("disc_amt_disp","17")
	callpoint!.setDevObject("backord_disp","18")
	callpoint!.setDevObject("credit_disp","19")

rem --- Set variables for called forms (OPE_ORDLSDET)

	callpoint!.setDevObject("lotser_flag",ivs01a.lotser_flag$)

rem --- Set up Lot/Serial button (and others) properly

	switch pos(ivs01a.lotser_flag$="LS")
		case 1; callpoint!.setOptionText("LENT",Translate!.getTranslation("AON_LOT_ENTRY")); break
		case 2; callpoint!.setOptionText("LENT",Translate!.getTranslation("AON_SERIAL_ENTRY")); break
		case default; break
	swend

rem --- Enable buttons

	callpoint!.setOptionEnabled("LENT",0)
	callpoint!.setOptionEnabled("RCPR",0)
	callpoint!.setOptionEnabled("DINV",0)
	callpoint!.setOptionEnabled("CINV",0)
	callpoint!.setOptionEnabled("MINV",0)
	callpoint!.setOptionEnabled("UINV",0)
	callpoint!.setOptionEnabled("PRNT",0)
	callpoint!.setOptionEnabled("CASH",0)
	callpoint!.setOptionEnabled("TTLS",0)
	callpoint!.setOptionEnabled("CRCH",0)
	callpoint!.setOptionEnabled("CRAT",0)

rem --- Parse table_chans$[all] into an object

	declare ArrayObject tableChans!

	call pgmdir$+"adc_array.aon::str_array2object", table_chans$[all], tableChans!, status
	util.setTableChans(tableChans!)

rem --- Order Helper object

	declare OrderHelper ordHelp!

	ordHelp! = new OrderHelper(firm_id$, int(num(ivs01a.precision$)), callpoint!, dtlg_param$[1,3])
	callpoint!.setDevObject("order_helper_object", ordHelp!)

rem --- get mask for display sequence number used in detail lines (needed when creating duplicate/credit)

	call stbl("+DIR_PGM")+"adc_getmask.aon","LINE_NO","","","",line_no_mask$,0,0
	callpoint!.setDevObject("line_no_mask",line_no_mask$)

rem --- Set object for which customer number is being shown

	callpoint!.setDevObject("current_customer","")

rem --- setup message_tpl$

	gosub init_msgs
[[OPE_INVHDR.AFMC]]
rem print 'show', "Hdr:AFMC"; rem debug

rem --- Inits

	use ::ado_util.src::util
	use ::ado_order.src::OrderHelper
	use ::adc_array.aon::ArrayObject

rem --- Create Inventory Availability window

	grid!  = util.getGrid(Form!)
	child! = util.getChild(Form!)
	cxt    = SysGUI!.getAvailableContext()

	mwin! = child!.addChildWindow(15000, 0, 10, child!.getWidth(), 75, "", $00000800$, cxt)
	mwin!.addGroupBox(15999, 0, 5, grid!.getWidth(), 65, Translate!.getTranslation("AON_INVENTORY_AVAILABILITY"), $$)

	mwin!.addStaticText(15001,15,25,75,15,Translate!.getTranslation("AON_ON_HAND:"),$$)
	mwin!.addStaticText(15002,15,40,75,15,Translate!.getTranslation("AON_COMMITTED:"),$$)
	mwin!.addStaticText(15003,215,25,75,15,Translate!.getTranslation("AON_AVAILABLE:"),$$)
	mwin!.addStaticText(15004,215,40,75,15,Translate!.getTranslation("AON_ON_ORDER:"),$$)
	mwin!.addStaticText(15005,415,25,75,15,Translate!.getTranslation("AON_WAREHOUSE:"),$$)
	mwin!.addStaticText(15006,415,40,75,15,Translate!.getTranslation("AON_TYPE:"),$$)

rem --- Save controls in the global userObj! (vector)

	userObj! = SysGUI!.makeVector()
	userObj!.addItem(grid!) 
	userObj!.addItem(mwin!)

	userObj!.addItem(mwin!.addStaticText(15101,90,25,75,15,"",$8000$))
	userObj!.addItem(mwin!.addStaticText(15102,90,40,75,15,"",$8000$))
	userObj!.addItem(mwin!.addStaticText(15103,295,25,75,15,"",$8000$))
	userObj!.addItem(mwin!.addStaticText(15104,295,40,75,15,"",$8000$))
	userObj!.addItem(mwin!.addStaticText(15105,490,25,75,15,"",$0000$))
	userObj!.addItem(mwin!.addStaticText(15106,490,40,75,15,"",$0000$))
	userObj!.addItem(mwin!.addStaticText(15107,695,20,75,15,"",$0000$)); rem Dropship text (8)
	userObj!.addItem(mwin!.addStaticText(15108,695,35,160,15,"",$0000$)); rem Manual Price  (9)
	userObj!.addItem(mwin!.addStaticText(15109,695,50,160,15,"",$0000$)); rem Alt/Super  (10)
