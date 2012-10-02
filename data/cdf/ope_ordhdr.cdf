[[OPE_ORDHDR.TAX_CODE.AVAL]]
rem --- Set code in the Order Helper object

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	ordHelp!.setTaxCode(callpoint!.getColumnData("OPE_ORDHDR.TAX_CODE"))
[[OPE_ORDHDR.AOPT-CRAT]]
print "Hdr:AOPT:CRAT"; rem debug

rem --- Do Credit Action

	gosub do_credit_action

	if action$ <> "U" then
		user_tpl.do_end_of_form = 0			
		callpoint!.setStatus("NEWREC")
	end
[[OPE_ORDHDR.DISC_CODE.AVAL]]
rem --- Set discount code for use in Order Totals

	user_tpl.disc_code$ = callpoint!.getUserInput()
[[OPE_ORDHDR.AOPT-TTLS]]
print "Hdr:AOPT:TTLS"; rem debug

rem --- Launch the totals form

	gosub do_totals
	user_tpl.do_totals_form = 0
	rem callpoint!.setStatus("NEWREC")
[[OPE_ORDHDR.AREC]]
rem --- Clear availability information
	
	gosub clear_avail
[[OPE_ORDHDR.ARAR]]
print "Hdr:ARAR"; rem debug

rem --- Set data

	user_tpl.order_date$ = callpoint!.getColumnData("OPE_ORDHDR.ORDER_DATE")

rem --- Set flags

	user_tpl.user_entry$ = "N"; rem user entered an order (not navigated)

	callpoint!.setDevObject("credit_status_done", "N")
	callpoint!.setDevObject("credit_action_done", "N")

	callpoint!.setOptionEnabled("DINV",0)
	callpoint!.setOptionEnabled("CINV",0)
	callpoint!.setOptionEnabled("RPRT",0)
	callpoint!.setOptionEnabled("PRNT",0)
	callpoint!.setOptionEnabled("CRCH",0)
	callpoint!.setOptionEnabled("CRAT",0)
	callpoint!.setOptionEnabled("TTLS",0)

rem --- Clear order helper object

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	ordHelp!.newOrder()

rem --- Reset all previous values

	user_tpl.prev_line_code$   = ""
	user_tpl.prev_item$        = ""
	user_tpl.prev_qty_ord      = 0
	user_tpl.prev_boqty        = 0
	user_tpl.prev_shipqty      = 0
	user_tpl.prev_ext_price    = 0
	user_tpl.prev_taxable      = 0
	user_tpl.prev_ext_cost     = 0
	user_tpl.prev_disc_code$   = ""
	user_tpl.prev_ship_to$     = ""
	user_tpl.prev_sales_total  = 0

	user_tpl.new_order = 1
	user_tpl.credit_limit_warned = 0
	user_tpl.shipto_warned = 0
[[OPE_ORDHDR.BREX]]
print "Hdr:BREX"; rem debug

rem --- Is record deleted?

	if user_tpl.record_deleted then
		break; rem --- exit callpoint
	endif

rem --- Is flag down?

	if !user_tpl.do_end_of_form then
		user_tpl.do_end_of_form = 1
		break; rem --- exit callpoint
	endif	

rem --- Are both Customer and Order entered?

	if cvs(callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID"), 2) = "" or 
:		cvs(callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO"), 2) = ""
:	then
		break; rem --- exit callpoint
	endif

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))

	if ordHelp!.getCust_id() = "" or ordHelp!.getOrder_no() = "" then
		break; rem --- exit callpoint
	endif

rem --- Calculate taxes and write it back
	
	discount_amt = num(callpoint!.getColumnData("OPE_ORDHDR.DISCOUNT_AMT"))
	freight_amt = num(callpoint!.getColumnData("OPE_ORDHDR.FREIGHT_AMT"))
	gosub get_disk_rec

	if record_found then
		ordhdr_rec.tax_amount = ordHelp!.calculateTax(discount_amt, freight_amt)
		ordhdr_rec$ = field(ordhdr_rec$)
		write record (ordhdr_dev) ordhdr_rec$
		callpoint!.setStatus("SETORIG")
	endif

rem --- Credit action

	if ordHelp!.calcOverCreditLimit() and callpoint!.getDevObject("credit_action_done") <> "Y" then
		gosub do_credit_action
	endif

rem --- Does the total of lot/serial# match the qty ordered for each detail line?

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	ordHelp!.setLotSerialFlag( user_tpl.lotser_flag$ )

	if user_tpl.lotser_flag$ <> "N" then

		declare BBjVector recs!
		recs! = BBjAPI().makeVector()

		recs! = cast( BBjVector, gridVect!.getItem(0) )
		dim gridrec$:dtlg_param$[1,3]

	rem --- Detail loop

		for row=0 to recs!.size()-1
			gridrec$ = recs!.getItem(row)

			if ordHelp!.isLottedSerial(gridrec.item_id$) then
				lot_ser_total = ordHelp!.totalLotSerialAmount( gridrec.internal_seq_no$ )

				if lot_ser_total <> gridrec.qty_ordered then
					if user_tpl.lotser_flag$ = "L" then
						lot_ser$ = "lots"
					else
						lot_ser$ = "serial numbers"
					endif
				
					msg_id$ = "OP_ITEM_LS_TOTAL"
					dim msg_tokens$[3]
					msg_tokens$[0] = str(gridrec.qty_ordered)
					msg_tokens$[1] = cvs(gridrec.item_id$, 2)
					msg_tokens$[2] = lot_ser$
					msg_tokens$[3] = str(lot_ser_total)
					gosub disp_message
				endif
			endif
		next row
	endif
[[OPE_ORDHDR.AOPT-PRNT]]
print "Hdr:AOPT:PRNT"; rem debug

rem --- Print a counter Picking Slip

	if user_tpl.credit_installed$ <> "Y" or 
:		user_tpl.pick_hold$ = "Y"         or
:		callpoint!.getColumnData("OPE_ORDHDR.INVOICE_TYPE") = "P" 
:	then

	rem --- No need to check credit first

		gosub do_picklist
		user_tpl.do_end_of_form = 0
		callpoint!.setStatus("NEWREC")
	else

	rem --- Can't print until released from credit

		gosub force_print_status
		gosub do_credit_action

		if pos(action$ = "XU") or (action$ = "R" and callpoint!.getColumnData("OPE_ORDHDR.PRINT_STATUS") = "N") then 

		rem --- Couldn't do credit action, or did credit action w/ no problem, or released from credit but didn't print

			gosub do_picklist
			user_tpl.do_end_of_form = 0
			callpoint!.setStatus("NEWREC")
		else
			if action$ = "R" and callpoint!.getColumnData("OPE_ORDHDR.PRINT_STATUS") = "Y" then 

			rem --- Released from credit and did print

				user_tpl.do_end_of_form = 0
				callpoint!.setStatus("NEWREC")
			else
				print "---Not printing because there was no credit action"; rem debug
			endif
		endif
	endif
[[OPE_ORDHDR.BWRI]]
print "Hdr:BWRI"; rem debug

rem --- Has customer and order number been entered?

	cust_id$  = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
	order_no$ = callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")

	if cvs(cust_id$, 2) = "" or cvs(order_no$, 2) = "" then
		callpoint!.setStatus("ABORT")
	endif

rem --- Check Ship-to's

	rem if !user_tpl.shipto_warned then
		shipto_type$ = callpoint!.getColumnData("OPE_ORDHDR.SHIPTO_TYPE")
		shipto_var$  = "OPE_ORDHDR.SHIPTO_NO"

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
[[OPE_ORDHDR.CUSTOMER_ID.AVAL]]
print "CUSTOMER_ID:AVAL"; rem debug
	
	cust_id$ = callpoint!.getUserInput()
	gosub display_customer

rem --- Set customer in OrderHelper object

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	ordHelp!.setCust_id(cust_id$)

rem --- Show customer data

	if callpoint!.getColumnData("OPE_ORDHDR.CASH_SALE") <> "Y" then 
		gosub display_aging
		gosub check_credit

		if user_tpl.credit_installed$ = "Y" and user_tpl.display_bal$ = "A" then
			call user_tpl.pgmdir$+"opc_creditmgmnt.aon", cust_id$, "", table_chans$[all], callpoint!, status
			callpoint!.setDevObject("credit_status_done", "Y")
			callpoint!.setStatus("ACTIVATE")
		endif
	endif

	gosub disp_cust_comments

rem --- Enable buttons

	if cvs(callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO"), 2) = "" then
		callpoint!.setOptionEnabled("DINV",1)
		callpoint!.setOptionEnabled("CINV",1)
	endif

	callpoint!.setOptionEnabled("CRCH",1)
	gosub enable_credit_action
[[OPE_ORDHDR.SLSPSN_CODE.AVAL]]
print "Hdr:SLSPSN_CODE.AVAL"; rem debug

rem --- Set Commission Percent

	slsp$ = callpoint!.getUserInput()
	gosub get_comm_percent
[[OPE_ORDHDR.AOPT-CRCH]]
print "Hdr:AOPT:CRCH"; rem debug

rem --- Do credit status (management)

	cust_id$  = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
	order_no$ = callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO"); rem can be null

	print "---Credit installed: ", user_tpl.credit_installed$; rem debug
	print "---Display balance : ", user_tpl.display_bal$; rem debug

	if user_tpl.credit_installed$ = "Y" and user_tpl.display_bal$ <> "N" and cvs(cust_id$, 2) <> "" then
		print "---about to start credit management"; rem debug
		call user_tpl.pgmdir$+"opc_creditmgmnt.aon", cust_id$, order_no$, table_chans$[all], callpoint!, status
		callpoint!.setDevObject("credit_status_done", "Y")
		callpoint!.setStatus("ACTIVATE")
	endif
[[OPE_ORDHDR.BPRK]]
print "Hdr:BPRK"; rem debug

rem --- Is previous record an order and not void?

	file_name$ = "OPE_ORDHDR"
	ope01_dev = fnget_dev(file_name$)
	dim ope01a$:fnget_tpl$(file_name$)
	start_block = 1

	while 1
		if start_block then
			p_key$ = keyp(ope01_dev, end=*endif)
			read record (ope01_dev, key=p_key$) ope01a$

			if ope01a.firm_id$ = firm_id$ then 
				if ope01a.ordinv_flag$ = "O" and ope01a.invoice_type$ <> "V" then
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
			read (ope01_dev, key=firm_id$+$ff$, dom=*next, end=*break)
		endif
	wend
[[OPE_ORDHDR.SHIPTO_NO.BINP]]
print "SHIPTO:BINP"; rem debug

rem --- Save old value

	user_tpl.prev_ship_to$ = callpoint!.getColumnData("OPE_ORDHDR.SHIPTO_NO")
[[OPE_ORDHDR.APFE]]
print "Hdr:APFE"; rem debug

rem --- Enable buttons as appropriate

	if cvs(callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID"),2)<>""
		callpoint!.setOptionEnabled("CRCH",1)
		gosub enable_credit_action

		if cvs(callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO"),2)=""
			callpoint!.setOptionEnabled("DINV",1)
			callpoint!.setOptionEnabled("CINV",1)
			callpoint!.setOptionEnabled("RPRT",0)
			callpoint!.setOptionEnabled("PRNT",0)
			callpoint!.setOptionEnabled("TTLS",0)
			callpoint!.setOptionEnabled("CRAT",0)
		else
			callpoint!.setOptionEnabled("DINV",0)
			callpoint!.setOptionEnabled("CINV",0)
			callpoint!.setOptionEnabled("RPRT",1)
			callpoint!.setOptionEnabled("PRNT",1)
			callpoint!.setOptionEnabled("TTLS",1)
			callpoint!.setOptionEnabled("CRAT",1)
		endif
	endif
[[OPE_ORDHDR.BPFX]]
print "Hdr:BPFX"; rem debug

rem --- Disable buttons

	callpoint!.setOptionEnabled("CRCH",0)
	callpoint!.setOptionEnabled("CRAT",0)
	callpoint!.setOptionEnabled("DINV",0)
	callpoint!.setOptionEnabled("CINV",0)
	callpoint!.setOptionEnabled("PRNT",0)
	callpoint!.setOptionEnabled("RPRT",0)
	callpoint!.setOptionEnabled("TTLS",0)
[[OPE_ORDHDR.BNEK]]
print "Hdr:BNEK"; rem debug

rem --- Is next record an order and not void?

	file_name$ = "OPE_ORDHDR"
	ope01_dev = fnget_dev(file_name$)
	dim ope01a$:fnget_tpl$(file_name$)
	start_block = 1

	while 1
		if start_block then
			read record (ope01_dev, dir=0, end=*endif) ope01a$

			if ope01a.firm_id$ = firm_id$ then
				if ope01a.ordinv_flag$ = "O" and ope01a.invoice_type$ <> "V" then
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
			read (ope01_dev, key=firm_id$, dom=*next)
		endif
	wend
[[OPE_ORDHDR.ADIS]]
print "Hdr:ADIS"; rem debug

rem --- Check locked status

	gosub check_lock_flag

	if locked=1 then 
		user_tpl.do_end_of_form = 0
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

rem --- Reprint order?

	if callpoint!.getColumnData("OPE_ORDHDR.REPRINT_FLAG") <> "Y" then
		cust_id$  = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
		order_no$ = callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")
		ar_type$  = callpoint!.getColumnData("OPE_ORDHDR.AR_TYPE")
		reprint   = 0
		gosub check_if_reprintable

		if reprintable then 
			msg_id$="OP_REPRINT_ORDER"
			gosub disp_message
			
			if msg_opt$ = "Y" then
				if user_tpl.credit_installed$ = "Y" and 
:					user_tpl.pick_hold$ = "N" 			and 
:					callpoint!.getColumnData("OPE_ORDHDR.CREDIT_FLAG") = "C" 
:				then
					msg_id$="OP_ORD_ON_CR_HOLD"
				else
					msg_id$="OP_ORD_PRINT_BATCH"
					callpoint!.setColumnData("OPE_ORDHDR.REPRINT_FLAG", "Y")
					print "---Reprint_flag set to Y"; rem debug
					callpoint!.setColumnData("OPE_ORDHDR.PRINT_STATUS", "N")
					gosub add_to_batch_print
				endif

				gosub disp_message
			endif
		endif
	endif

rem --- Show customer data
	
	cust_id$ = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
	order_no$ = callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")
	gosub display_customer

	if callpoint!.getColumnData("OPE_ORDHDR.CASH_SALE") <> "Y" then 
		gosub display_aging
      gosub check_credit
	endif

	gosub disp_cust_comments

rem --- Display Ship to information

	ship_to_type$ = callpoint!.getColumnData("OPE_ORDHDR.SHIPTO_TYPE")
	ship_to_no$   = callpoint!.getColumnData("OPE_ORDHDR.SHIPTO_NO")
	order_no$     = callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")
	gosub ship_to_info

rem --- Display order total

	callpoint!.setColumnData("<<DISPLAY>>.ORDER_TOT", callpoint!.getColumnData("OPE_ORDHDR.TOTAL_SALES"))
	print "---Update Order Total (column data): ", callpoint!.getColumnData("OPE_ORDHDR.TOTAL_SALES")

rem --- Backorder and Credit Hold

	if callpoint!.getColumnData("OPE_ORDHDR.BACKORD_FLAG") = "B" then
		callpoint!.setColumnData("<<DISPLAY>>.BACKORDERED", "Backorder")
	endif

	if callpoint!.getColumnData("OPE_ORDHDR.CREDIT_FLAG") = "C" then
		callpoint!.setColumnData("<<DISPLAY>>.CREDIT_HOLD", "Credit Hold")
	endif

rem --- Enable buttons

	callpoint!.setOptionEnabled("PRNT",1)
	callpoint!.setOptionEnabled("RPRT",1)
	callpoint!.setOptionEnabled("TTLS",1)

rem --- Set all previous values

	user_tpl.prev_taxable      = num(callpoint!.getColumnData("OPE_ORDHDR.TAXABLE_AMT"))
	user_tpl.prev_ext_cost     = num(callpoint!.getColumnData("OPE_ORDHDR.TOTAL_COST"))
	user_tpl.prev_disc_code$   = callpoint!.getColumnData("OPE_ORDHDR.DISC_CODE")
	user_tpl.prev_ship_to$     = callpoint!.getColumnData("OPE_ORDHDR.SHIPTO_NO")
	user_tpl.prev_sales_total  = num(callpoint!.getColumnData("OPE_ORDHDR.TOTAL_SALES"))

rem --- Set codes	and flags

	user_tpl.price_code$   = callpoint!.getColumnData("OPE_ORDHDR.PRICE_CODE")
	user_tpl.pricing_code$ = callpoint!.getColumnData("OPE_ORDHDR.PRICING_CODE")
	user_tpl.order_date$   = callpoint!.getColumnData("OPE_ORDHDR.ORDER_DATE")
	user_tpl.disc_code$    = callpoint!.getColumnData("OPE_ORDHDR.DISC_CODE")
	user_tpl.new_order     = 0

rem --- Set OrderHelper object fields

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	ordHelp!.setCust_id(callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID"))
	ordHelp!.setOrder_no(callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO"))
	ordHelp!.setInv_type(callpoint!.getColumnData("OPE_ORDHDR.INVOICE_TYPE"))
	ordHelp!.setTaxCode(callpoint!.getColumnData("OPE_ORDHDR.TAX_CODE"))
	print "---OrderHelper object fields set"; rem debug

rem --- Clear availability

	gosub clear_avail
[[OPE_ORDHDR.BOVE]]
print "Hdr:BOVE"; rem debug

rem --- Restrict lookup to orders

	alias_id$ = "OPE_ORDHDR"
	inq_mode$ = "EXM_ITEM"
	key_pfx$  = firm_id$
	key_id$   = "PRIMARY"
	cust_id$  = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")

	dim filter_defs$[3,1]
	filter_defs$[1,0] = "OPE_ORDHDR.ORDINV_FLAG"
	filter_defs$[1,1] = "='O'"
	filter_defs$[2,0] = "OPE_ORDHDR.INVOICE_NO"
	filter_defs$[2,1] = "<>'V'"

	if cvs(cust_id$, 2) <> "" then
		filter_defs$[3,0] = "OPE_ORDHDR.CUSTOMER_ID"
		filter_defs$[3,1] = "='" + cust_id$ + "'"
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
	else
		callpoint!.setStatus("ABORT")
	endif
[[OPE_ORDHDR.AOPT-RPRT]]
rem --- Check for printing in next batch and set

	if user_tpl.credit_installed$="Y" and user_tpl.pick_hold$<>"Y" and
:		callpoint!.getColumnData("OPE_ORDHDR.CREDIT_FLAG")="C"
:	then
		msg_id$ = "OP_CR_HOLD_NOPRINT"
	else
		order_no$ = callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")
		gosub add_to_batch_print
		callpoint!.setColumnData("OPE_ORDHDR.REPRINT_FLAG","Y")
		print "---Reprint_flag set to Y"; rem debug
		callpoint!.setStatus("SAVE")
		msg_id$ = "OP_BATCH_PRINT"
	endif

	dim msg_tokens$[1]
	msg_tokens$[1] = "order"
	gosub disp_message
[[OPE_ORDHDR.ADEL]]
rem --- Remove from ope-04

	ope_prntlist_dev=fnget_dev("OPE_PRNTLIST")
	remove (ope_prntlist_dev,key=firm_id$+"O"+"  "+
:		callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")+
:		callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO"),dom=*next)

rem --- Set flags

	user_tpl.record_deleted = 1
	user_tpl.first_read     = 1

rem --- clear availability

	gosub clear_avail
[[OPE_ORDHDR.ORDER_DATE.AVAL]]
rem --- Set user template info

	user_tpl.order_date$=callpoint!.getUserInput()
[[OPE_ORDHDR.PRICING_CODE.AVAL]]
rem --- Set user template info

	user_tpl.pricing_code$=callpoint!.getUserInput()
[[OPE_ORDHDR.PRICE_CODE.AVAL]]
rem --- Set user template info

	user_tpl.price_code$=callpoint!.getUserInput()
[[OPE_ORDHDR.ASIZ]]
print "Hdr:ASIZ"; rem debug

rem --- Create Empty Availability window

	grid! = util.getGrid(Form!)
	grid!.setSize(grid!.getWidth(), grid!.getHeight() - 75)

	cwin! = util.getChild(Form!).getControl(15000)
	cwin!.setLocation(cwin!.getX(), grid!.getY() + grid!.getHeight())
	cwin!.setSize(grid!.getWidth(), cwin!.getHeight())

	mwin!=cwin!.getControl(15999)
	mwin!.setSize(grid!.getWidth(), mwin!.getHeight())
[[OPE_ORDHDR.AFMC]]
rem print 'show', "Hdr:AFMC"; rem debug

rem --- Inits

	use ::ado_util.src::util
	use ::ado_order.src::OrderHelper
	use ::adc_array.aon::ArrayObject

rem --- Create Inventory Availability window

	grid!  = util.getGrid(Form!)
	child! = util.getChild(Form!)
	cxt    = SysGUI!.getAvailableContext()

	mwin! = child!.addChildWindow(15000, 0, 10, 100, 75, "", $00000800$, cxt)
	mwin!.addGroupBox(15999, 0, 5, grid!.getWidth(), 65, "Inventory Availability", $$)

	mwin!.addStaticText(15001,15,25,75,15,"On Hand:",$$)
	mwin!.addStaticText(15002,15,40,75,15,"Committed:",$$)
	mwin!.addStaticText(15003,215,25,75,15,"Available:",$$)
	mwin!.addStaticText(15004,215,40,75,15,"On Order:",$$)
	mwin!.addStaticText(15005,415,25,75,15,"Warehouse:",$$)
	mwin!.addStaticText(15006,415,40,75,15,"Type:",$$)

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
 	userObj!.addItem(mwin!.addStaticText(15109,695,50,160,15,"",$0000$)); rem Alt/Super (10)
[[OPE_ORDHDR.BDEL]]
print "Hdr:BDEL"; rem debug

rem --- Remove committments for detail records by calling ATAMO

	ope11_dev = fnget_dev("OPE_ORDDET")
	dim ope11a$:fnget_tpl$("OPE_ORDDET")

	opc_linecode_dev = fnget_dev("OPC_LINECODE")
	dim opc_linecode$:fnget_tpl$("OPC_LINECODE")

	ivs01_dev = fnget_dev("IVS_PARAMS")
	dim ivs01a$:fnget_tpl$("IVS_PARAMS")
	read record (ivs01_dev, key=firm_id$+"IV00") ivs01a$

	ope33_dev = fnget_dev("OPE_ORDSHIP")
	cashrct_dev = fnget_dev("OPE_INVCASH")
	creddate_dev = fnget_dev("OPE_CREDDATE")

	ar_type$  = callpoint!.getColumnData("OPE_ORDHDR.AR_TYPE")
	cust$     = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
	ord$      = callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")
	ord_date$ = callpoint!.getColumnData("OPE_ORDHDR.ORDER_DATE")
	inv_type$ = callpoint!.getColumnData("OPE_ORDHDR.INVOICE_TYPE")

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
[[OPE_ORDHDR.AOPT-CINV]]
rem --- Credit Historical Invoice

	if cvs(callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID"),2)="" or
:	   cvs(callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO"),2)<>""
:	then
		msg_id$="OP_NO_HIST"
		gosub disp_message
	else
		key_pfx$=firm_id$+
:			callpoint!.getColumnData("OPE_ORDHDR.AR_TYPE")+
:			callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
		line_sign=-1
		gosub copy_order
	endif
[[OPE_ORDHDR.AOPT-DINV]]
rem --- Duplicate Historical Invoice

	if cvs(callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID"),2)="" or
:	   cvs(callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO"),2)<>""
:	then 
		msg_id$="OP_NO_HIST"
		gosub disp_message
	else
		key_pfx$=firm_id$+
:			callpoint!.getColumnData("OPE_ORDHDR.AR_TYPE")+
:			callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
		line_sign=1
		gosub copy_order
	endif
[[OPE_ORDHDR.SHIPTO_NO.AVAL]]
print "SHIPTO:AVAL"; rem debug

rem --- Remove manual ship-record, if necessary

	ship_to_no$ = callpoint!.getUserInput()
	cust_id$    = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
	order_no$   = callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")

	if user_tpl.prev_ship_to$ = "000099" and ship_to_no$ <> "000099" then
		remove (fnget_dev("OPE_ORDSHIP"), key=firm_id$+cust_id$+order_no$, dom=*next)
	endif

rem --- Display Ship to information

	ship_to_type$ = callpoint!.getColumnData("OPE_ORDHDR.SHIPTO_TYPE")
	gosub ship_to_info
[[OPE_ORDHDR.ORDER_NO.AVAL]]
print "ORDER_NO:AVAL"; rem debug

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

	rem debug
	rem print "   new_seq: ", new_seq$
	rem print "  order_no: ", order_no$
	rem print "user_entry: ", user_tpl.user_entry$

rem --- Does order exist?

	ope01_dev = fnget_dev("OPE_ORDHDR")
	dim ope01a$:fnget_tpl$("OPE_ORDHDR")

	ar_type$ = callpoint!.getColumnData("OPE_ORDHDR.AR_TYPE")
	cust_id$ = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")

	found = 0
	start_block = 1

	if start_block then
		find record (ope01_dev, key=firm_id$+ar_type$+cust_id$+order_no$, dom=*endif) ope01a$
		found = 1
	endif

	rem print "     found:", found; rem debug

rem --- A new record must be the next sequence

	if found = 0 and new_seq$ = "N" then
		msg_id$ = "OP_NEW_ORD_USE_SEQ"
		gosub disp_message	
		callpoint!.setFocus("OPE_ORDHDR.ORDER_NO")
		break; rem --- exit from callpoint
	endif

	user_tpl.hist_ord$ = "N"

rem --- Existing record

	if found then 

	rem --- Check for void

		if ope01a.invoice_type$ = "V" then
			msg_id$="OP_ORDINV_VOID"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break; rem --- exit from callpoint			
		endif

	rem --- Check for invoice
		
		if ope01a.ordinv_flag$ = "I" then
			msg_id$ = "OP_IS_INVOICE"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break; rem --- exit from callpoint			
		endif		

	rem --- Check locked status

		gosub check_lock_flag

		if locked=1 then 
			user_tpl.do_end_of_form = 0
			callpoint!.setStatus("ABORT")
			break; rem --- exit callpoint
		endif

	rem --- Check if reprintable ***DISABLED***

	goto end_of_reprintable

		if callpoint!.getColumnData("OPE_ORDHDR.REPRINT_FLAG") <> "Y" then
			reprint = 0
			gosub check_if_reprintable

			if reprintable then 
				msg_id$="OP_REPRINT_ORDER"
				gosub disp_message
				
				if msg_opt$ = "Y" then
					if user_tpl.credit_installed$ = "Y" and user_tpl.pick_hold$ = "N" and ope01a.credit_flag$ = "C" then
						msg_id$="OP_ORD_ON_CR_HOLD"
					else
						msg_id$="OP_ORD_PRINT_BATCH"
						callpoint!.setColumnData("OPE_ORDHDR.REPRINT_FLAG", "Y")
						print "---Reprint_flag set to Y"; rem debug
						callpoint!.setColumnData("OPE_ORDHDR.PRINT_STATUS", "N")
						gosub add_to_batch_print
					endif

					gosub disp_message
				else
					rem callpoint!.setStatus("NEWREC")
					rem break; rem ---- exit callpoint
				endif
			endif
		endif

end_of_reprintable:
        
	rem --- Set Codes		
        
		user_tpl.price_code$   = ope01a.price_code$
		user_tpl.pricing_code$ = ope01a.pricing_code$
		user_tpl.order_date$   = ope01a.order_date$

	else

	rem --- New record

		cust_id$   = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
		order_no$  = callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")
		callpoint!.setColumnData("OPE_ORDHDR.INVOICE_TYPE","S")

		rem --- Set dflt invoice type in OrderHelper object

		ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
		ordHelp!.setInv_type("S")

		arm02_dev=fnget_dev("ARM_CUSTDET")
		dim arm02a$:fnget_tpl$("ARM_CUSTDET")
		read record (arm02_dev, key=firm_id$+cust_id$+"  ", dom=*next) arm02a$

		arm01_dev=fnget_dev("ARM_CUSTMAST")
		dim arm01a$:fnget_tpl$("ARM_CUSTMAST")
		read record (arm01_dev,key=firm_id$+cust_id$, dom=*next) arm01a$

		callpoint!.setColumnData("OPE_ORDHDR.SHIPMNT_DATE",user_tpl.def_ship$)
		callpoint!.setColumnData("OPE_ORDHDR.INVOICE_TYPE","S")
		callpoint!.setColumnData("OPE_ORDHDR.ORDINV_FLAG","O")
		callpoint!.setColumnData("OPE_ORDHDR.INVOICE_DATE",sysinfo.system_date$)
		callpoint!.setColumnData("OPE_ORDHDR.AR_SHIP_VIA",arm01a.ar_ship_via$)
		callpoint!.setColumnData("OPE_ORDHDR.SLSPSN_CODE",arm02a.slspsn_code$)
		callpoint!.setColumnData("OPE_ORDHDR.TERMS_CODE",arm02a.ar_terms_code$)
		callpoint!.setColumnData("OPE_ORDHDR.DISC_CODE",arm02a.disc_code$)
		callpoint!.setColumnData("OPE_ORDHDR.AR_DIST_CODE",arm02a.ar_dist_code$)
		callpoint!.setColumnData("OPE_ORDHDR.PRINT_STATUS","N")
		callpoint!.setColumnData("OPE_ORDHDR.MESSAGE_CODE",arm02a.message_code$)
		callpoint!.setColumnData("OPE_ORDHDR.TERRITORY",arm02a.territory$)
		callpoint!.setColumnData("OPE_ORDHDR.ORDER_DATE",sysinfo.system_date$)
		callpoint!.setColumnData("OPE_ORDHDR.TAX_CODE",arm02a.tax_code$)
		callpoint!.setColumnData("OPE_ORDHDR.PRICING_CODE",arm02a.pricing_code$)
		callpoint!.setColumnData("OPE_ORDHDR.ORD_TAKEN_BY",sysinfo.user_id$)

		ordHelp!.setTaxCode(arm02a.tax_code$)

		slsp$ = arm02a.slspsn_code$
		gosub get_comm_percent

		gosub get_op_params

		if cust_id$ = ars01a.customer_id$
			callpoint!.setColumnData("OPE_ORDHDR.CASH_SALE", "Y")
        else
			callpoint!.setColumnData("OPE_ORDHDR.CASH_SALE", "N")
		endif

		user_tpl.price_code$   = ""
		user_tpl.pricing_code$ = arm02a.pricing_code$
		user_tpl.order_date$   = sysinfo.system_date$

	endif

rem --- Set lock (debug, not working correctly at the moment)

	rem callpoint!.setColumnData("OPE_ORDHDR.LOCK_STATUS", "Y")
	callpoint!.setColumnData("OPE_ORDHDR.LOCK_STATUS", "N"); rem debug, forcing the lock off for now
	rem callpoint!.setStatus("SAVE")

rem --- Add to batch print list

	order_no$ = callpoint!.getUserInput()
	gosub add_to_batch_print

rem --- Enable/Disable buttons

	callpoint!.setOptionEnabled("DINV",0)
	callpoint!.setOptionEnabled("CINV",0)

	if new_seq$ = "N" then 
		if user_tpl.credit_installed$="Y" and user_tpl.pick_hold$<>"Y" and
:			callpoint!.getColumnData("OPE_ORDHDR.CREDIT_FLAG")="C"
:		then
			callpoint!.setOptionEnabled("RPRT",0)
		else
			callpoint!.setOptionEnabled("RPRT",1)
		endif
	endif

	callpoint!.setStatus("REFRESH")

rem --- Set order in OrderHelper object

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	ordHelp!.setOrder_no(order_no$)
[[OPE_ORDHDR.SHIPTO_TYPE.AVAL]]
rem -- Deal with which Ship To type

	ship_to_type$ = callpoint!.getUserInput()
	ship_to_no$   = callpoint!.getColumnData("OPE_ORDHDR.SHIPTO_NO")
	cust_id$      = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
	order_no$     = callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")

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
[[OPE_ORDHDR.ASHO]]
print "Hdr:ASHO"; rem debug

rem --- Get default dates, POS station

	call stbl("+DIR_SYP")+"bam_run_prog.bbj", "OPE_ORDDATES", stbl("+USER_ID"), "MNT", "", table_chans$[all]
	user_tpl.def_ship$   = stbl("OPE_DEF_SHIP")
	user_tpl.def_commit$ = stbl("OPE_DEF_COMMIT")

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
[[OPE_ORDHDR.INVOICE_TYPE.AVAL]]
rem --- Enable/disable expire date based on value

	inv_type$ = callpoint!.getUserInput()

	if inv_type$ = "S" then
		callpoint!.setColumnEnabled("OPE_ORDHDR.EXPIRE_DATE", -1)
	else
		callpoint!.setColumnEnabled("OPE_ORDHDR.EXPIRE_DATE", 1)
	endif

rem --- Void this order

	if inv_type$ = "V" then
		callpoint!.setColumnData("OPE_ORDHDR.LOCK_STATUS", "")
		callpoint!.setColumnData("OPE_ORDHDR.PRINT_STATUS", "Y")
		callpoint!.setColumnData("OPE_ORDHDR.ORDINV_FLAG", "I")

	rem --- Add to batch print

		ope_prntlist_dev = fnget_dev("OPE_PRNTLIST")
		dim ope_prntlist$:fnget_tpl$("OPE_PRNTLIST")

		ope_prntlist.firm_id$     = firm_id$
		ope_prntlist.ordinv_flag$ = "I"
		ope_prntlist.ar_type$     = "  "
		ope_prntlist.customer_id$ = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
		ope_prntlist.order_no$    = callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")

		write record (ope_prntlist_dev) ope_prntlist$

	rem --- Save and exit

		callpoint!.setColumnData("OPE_ORDHDR.INVOICE_TYPE", "V")
		gosub get_disk_rec
		ordhdr_rec$ = field(ordhdr_rec$)
		write record (ordhdr_dev) ordhdr_rec$

		user_tpl.do_end_of_form = 0
		callpoint!.setStatus("NEWREC")
		break; rem --- exit callpoint
	endif

rem --- Convert Quote?

	if rec_data.invoice_type$="S" then 
		if inv_type$="P" then 
			msg_id$="OP_NO_CONVERT"
			gosub disp_message
			callpoint!.setStatus("ABORT-REFRESH")
		endif
	else
		if rec_data.invoice_type$="P" and inv_type$="S" then 
			msg_id$="CONVERT_QUOTE"
			gosub disp_message

			if msg_opt$ = "Y" then 
				callpoint!.setColumnData("OPE_ORDHDR.PRINT_STATUS","N")
				ope11_dev        = fnget_dev("OPE_ORDDET")
				ivs01_dev        = fnget_dev("IVS_PARAMS")
				opc_linecode_dev = fnget_dev("OPC_LINECODE")
				dim ope11a$:fnget_tpl$("OPE_ORDDET")
				dim ivs01a$:fnget_tpl$("IVS_PARAMS")
				dim opc_linecode$:fnget_tpl$("OPC_LINECODE")
				
				read record (ivs01_dev, key=firm_id$+"IV00") ivs01a$

				old_prec = tcb(14)
				precision num(ivs01a.precision$)

				ar_type$ = callpoint!.getColumnData("OPE_ORDHDR.AR_TYPE")
				cust$    = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
				ord$     = callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")
				read record (ope11_dev, key=firm_id$+ar_type$+cust$+ord$, dom=*next)

				while 1
					read record (ope11_dev, end=*break) ope11a$

					if pos(firm_id$+ar_type$+cust$+ord$=ope11a.firm_id$+
:						ope11a.ar_type$+ope11a.customer_id$+ope11a.order_no$)<>1 
:              then
						break
					endif

					read record (opc_linecode_dev, key=firm_id$+ope11a.line_code$, dom=*continue) opc_linecode$
					ope11a.commit_flag$ = "Y"
					ope11a.pick_flag$   = "N"
					if ope11a.est_shp_date$>user_tpl.def_commit$ then ope11a.commit_flag$="N"

					if ope11a.commit_flag$="N" then 
						if opc_linecode.line_type$<>"O" then 
							ope11a.qty_backord = 0
							ope11a.qty_shipped = 0
							ope11a.ext_price   = 0
							ope11a.taxable_amt = 0
						else 
							if ope11a.ext_price<>0 then 
								ope11a.unit_price  = ope11a.ext_price
								ope11a.ext_price   = 0
								ope11a.taxable_amt = 0
							endif
						endif
					endif

					if pos(opc_linecode.line_type$="SP")>0 and opc_linecode.dropship$<>"N" and
:						ope11a.commit_flag$<>"N"
:					then
						wh_id$    = ope11a.warehouse_id$
						item_id$  = ope11a.item_id$
						ls_id$    = ""
						qty       = ope11a.qty_ordered
						line_sign = 1
						gosub update_totals
					endif

					ope11a$=field(ope11a$)
					write record (ope11_dev) ope11a$
				wend

				precision old_prec
				rec_data.invoice_type$ = "S"
			endif
		endif
	endif

rem --- Set type in OrderHelper object

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	ordHelp!.setInv_type(inv_type$)
[[OPE_ORDHDR.CUSTOMER_ID.AINP]]
print "CUSTOMER_ID:AINP"; rem debug

rem --- If cash customer, get correct customer number

	if user_tpl.cash_sale$="Y" and cvs(callpoint!.getUserInput(),1+2+4)="C" then
		callpoint!.setColumnData("OPE_ORDHDR.CUSTOMER_ID", user_tpl.cash_cust$)
		callpoint!.setColumnData("OPE_ORDHDR.CASH_SALE", "Y")
		user_tpl.is_cash_sale = 1
		callpoint!.setStatus("REFRESH")
	endif
[[OPE_ORDHDR.AWRI]]
print "Hdr:AWRI"; rem debug

rem --- Write/Remove manual ship to file

	cust_id$    = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
	order_no$   = callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")
	ordship_dev = fnget_dev("OPE_ORDSHIP")
	
	if callpoint!.getColumnData("OPE_ORDHDR.SHIPTO_TYPE") <> "M" then 
		remove (ordship_dev, key=firm_id$+cust_id$+order_no$, dom=*next)
	else
		dim ordship_tpl$:fnget_tpl$("OPE_ORDSHIP")
		read record (ordship_dev, key=firm_id$+cust_id$+order_no$, dom=*next) ordship_tpl$

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
[[OPE_ORDHDR.<CUSTOM>]]
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
              rem     (ope_db, 5400-5499)
rem ==========================================================================

	if user_tpl.credit_limit<>0 and !user_tpl.credit_limit_warned and user_tpl.balance>=user_tpl.credit_limit then
   	if user_tpl.credit_installed$ <> "Y" then
      	msg_id$ = "OP_OVER_CREDIT_LIMIT"
			dim msg_tokens$[1]
			msg_tokens$[1] = str(user_tpl.credit_limit:user_tpl.amount_mask$)
         gosub disp_message
      endif  
   
		callpoint!.setColumnData("<<DISPLAY>>.CREDIT_HOLD", "*** Credit Limit Exceeded ***") 
		user_tpl.credit_limit_warned = 1
   endif

	return

rem ==========================================================================
ship_to_info: rem --- Get and display Bill To Information
              rem      IN: ship_to_type$
              rem          cust_id$
              rem          ship_to_no$
              rem          order_no$
rem ==========================================================================

	if ship_to_type$<>"M" then 

		if ship_to_type$="S" then 
			custship_dev=fnget_dev("ARM_CUSTSHIP")
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
			callpoint!.setColumnData("<<DISPLAY>>.SNAME","Same")
			callpoint!.setColumnData("<<DISPLAY>>.SADD1","")
			callpoint!.setColumnData("<<DISPLAY>>.SADD2","")
			callpoint!.setColumnData("<<DISPLAY>>.SADD3","")
			callpoint!.setColumnData("<<DISPLAY>>.SADD4","")
			callpoint!.setColumnData("<<DISPLAY>>.SCITY","")
			callpoint!.setColumnData("<<DISPLAY>>.SSTATE","")
			callpoint!.setColumnData("<<DISPLAY>>.SZIP","")
		endif

	else

		ordship_dev=fnget_dev("OPE_ORDSHIP")
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
check_lock_flag: rem --- Check manual record lock
                 rem     OUT: locked = 1 or 0
rem ==========================================================================

	locked=0

	switch pos( callpoint!.getColumnData("OPE_ORDHDR.LOCK_STATUS") = "NYS12" )
		case 2
			msg_id$="ORD_LOCKED"
			dim msg_tokens$[1]

			if callpoint!.getColumnData("OPE_ORDHDR.PRINT_STATUS")="B" then 
				msg_tokens$[1]=" by Batch Printing"
				gosub disp_message

				if msg_opt$="Y"
					callpoint!.setColumnData("OPE_ORDHDR.LOCK_STATUS","N")
					callpoint!.setStatus("SAVE")
				else
					locked=1
				endif
			endif

			break

		case 3
			msg_id$="ORD_ON_REG"
			gosub disp_message
			locked=1
			break

		case 4
		case 5
			msg_id$="INVOICE_IN_UPDATE"
			gosub disp_message
			locked=1
			break
	swend

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
			ope01_dev = fnget_dev("OPE_ORDHDR")
			dim ope01a$:fnget_tpl$("OPE_ORDHDR")
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

			dim ope11a$:fnget_tpl$("OPE_ORDDET")
			ope11_dev=fnget_dev("OPE_ORDDET")

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
update_totals: rem --- Update Order/Invoice Totals & Commit Inventory
               rem      IN: wh_id$
               rem          item_id$
               rem          ls_id$ 
               rem          qty
rem ==========================================================================

	inv_type$ = callpoint!.getColumnData("OPE_ORDHDR.INVOICE_TYPE")

	call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",iv_files[all],ivs01a$,iv_info$[all],iv_refs$[all],iv_refs[all],table_chans$[all],status
	iv_info$[1] = wh_id$
	iv_info$[2] = item_id$
	iv_info$[3] = ls_id$
	iv_refs[0]  = qty

	while 1
		if pos(opc_linecode.line_type$="SP")=0 then break
		if opc_linecode.dropship$="Y" or inv_type$="P" then break; rem "Dropship or quote
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

	inv_type$ = callpoint!.getColumnData("OPE_ORDHDR.INVOICE_TYPE")

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
pricing: rem --- Call Pricing routine
         rem      IN: ope11a$ - Order Detail record
         rem          seq_id$ - order number
         rem          ivm02_dev
         rem          ivs01_dev
rem ==========================================================================

	ope01_dev = fnget_dev("OPE_ORDHDR")
	dim ope01a$:fnget_tpl$("OPE_ORDHDR")

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
disp_cust_comments: rem --- Display customer comment
                    rem      IN: cust_id$
rem ==========================================================================

	cmt_text$=""
	arm05_dev=fnget_dev("ARM_CUSTCMTS")
	dim arm05a$:fnget_tpl$("ARM_CUSTCMTS")
	more=1

	read (arm05_dev, key=firm_id$+cust_id$, dom=*next)

	while more
		read record (arm05_dev, end=*break) arm05a$
		if arm05a.firm_id$+arm05a.customer_id$ <> firm_id$+cust_id$ then break
		cmt_text$ = cmt_text$ + cvs(arm05a.std_comments$,3) + $0A$
	wend

	callpoint!.setColumnData("<<DISPLAY>>.comments", cmt_text$)
	callpoint!.setStatus("REFRESH")

	return

rem ==========================================================================
add_to_batch_print: rem --- Add to batch print file
                    rem      IN: order_no$
rem ==========================================================================

	ope_prntlist_dev = fnget_dev("OPE_PRNTLIST")
	dim ope_prntlist$:fnget_tpl$("OPE_PRNTLIST")

	ope_prntlist.firm_id$     = firm_id$
	ope_prntlist.ordinv_flag$ = "O"
	ope_prntlist.ar_type$     = "  "
	ope_prntlist.customer_id$ = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
	ope_prntlist.order_no$    = order_no$

	write record (ope_prntlist_dev) ope_prntlist$

	return

rem ==========================================================================
check_if_reprintable: rem --- Are There Reprintable Detail Lines? 
                      rem      IN: ar_type$
                      rem          cust_id$
                      rem          order_no$
                      rem     OUT: reprintable = 1/0
rem ==========================================================================

	reprintable = 0
	
	ope11_dev = fnget_dev("OPE_ORDDET")
	dim ope11a$:fnget_tpl$("OPE_ORDDET")
	read (ope11_dev, key=firm_id$+ar_type$+cust_id$+order_no$, dom=*next)

	while 1
		read record (ope11_dev, end=*break) ope11a$
		if pos(firm_id$+ar_type$+cust_id$+order_no$ = ope11a$) <> 1 then break

		if ope11a.pick_flag$ = "Y" then 
			reprintable = 1
			break
		endif
	wend

	return 

rem ==========================================================================
enable_credit_action:
rem ==========================================================================

	inv_type$ = callpoint!.getColumnData("OPE_ORDHDR.INVOICE_TYPE")
	cust_id$  = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
	order_no$ = callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")

	if user_tpl.credit_installed$ = "Y" and inv_type$ <> "P" and cvs(cust_id$, 2) <> "" and cvs(order_no$, 2) <> "" then
		callpoint!.setOptionEnabled("CRAT",1)
	else
		callpoint!.setOptionEnabled("CRAT",0)
	endif

	return

rem ==========================================================================
do_credit_action: rem --- Launch the credit action program / form
                  rem     OUT: action$
rem ==========================================================================

	inv_type$ = callpoint!.getColumnData("OPE_ORDHDR.INVOICE_TYPE")
	cust_id$  = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
	order_no$ = callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")
	action$   = "X"; rem Never called opc_creditaction.aon

rem --- Should we call Credit Action?

	if user_tpl.credit_installed$ = "Y" and inv_type$ <> "P" and cvs(cust_id$, 2) <> "" and cvs(order_no$, 2) <> "" then
		callpoint!.setDevObject("run_by", "order")
		call user_tpl.pgmdir$+"opc_creditaction.aon", cust_id$, order_no$, table_chans$[all], callpoint!, action$, status
		if status = 999 then goto std_exit

	rem --- Delete the order

		if action$ = "D" then 
			callpoint!.setStatus("DELETE")
			return
		endif

		if pos(action$="HC")<>0 then

		rem --- Order on hold

			callpoint!.setColumnData("OPE_ORDHDR.CREDIT_FLAG","C")
		else
			if action$="R" then

			rem --- Order released

				callpoint!.setColumnData("OPE_ORDHDR.CREDIT_FLAG","R")	
				terms$ = str(callpoint!.getDevObject("new_terms_code"))

				if terms$ <> "" then
					callpoint!.setColumnData("OPE_ORDHDR.TERMS_CODE", terms$)
				endif
			else
				callpoint!.setColumnData("OPE_ORDHDR.CREDIT_FLAG","")			
			endif
		endif

	rem --- Order was printed within the credit action program

		if str(callpoint!.getDevObject("document_printed")) = "Y" then 
			callpoint!.setColumnData("OPE_ORDHDR.PRINT_STATUS", "Y")
		endif

	rem --- Write these flags back to the disk

		gosub get_disk_rec
		ordhdr_rec$ = field(ordhdr_rec$)
		write record (ordhdr_dev) ordhdr_rec$
		callpoint!.setStatus("SETORIG")		

	endif

	return

rem ==========================================================================
do_picklist: rem --- Print a Pick List
rem ==========================================================================

	print "in do_picklist..."; rem debug

	if callpoint!.getColumnData("OPE_ORDHDR.PRINT_STATUS") = "Y" then 
		callpoint!.setColumnData("OPE_ORDHDR.REPRINT_FLAG", "Y")
		print "---Reprint_flag set to Y"; rem debug

	rem --- Write flag to file so opc_picklist can see it

		gosub get_disk_rec
		ordhdr_rec$ = field(ordhdr_rec$)
		write record (ordhdr_dev) ordhdr_rec$
		callpoint!.setStatus("SETORIG")
	endif

	call user_tpl.pgmdir$+"opc_picklist.aon", cust_id$, order_no$, callpoint!, table_chans$[all], status
	if status = 999 then goto std_exit
	callpoint!.setColumnData("OPE_ORDHDR.PRINT_STATUS", "Y")

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
force_print_status: rem --- Force print status to N and write
rem ==========================================================================

	print "in force_print_status..."; rem debug

	callpoint!.setColumnData("OPE_ORDHDR.PRINT_STATUS", "N")

rem --- Write flag to file so opc_creditaction can see it

	gosub get_disk_rec
	ordhdr_rec$ = field(ordhdr_rec$)
	write record (ordhdr_dev) ordhdr_rec$

	callpoint!.setStatus("SETORIG")
	print "---Print status written, """, ordhdr_rec.print_status$, """"; rem debug
	print "out"; rem debug

	return

rem ==========================================================================
get_comm_percent: rem --- Get commission percent from salesperson file
                  rem      IN: slsp$ - salesperson code
rem ==========================================================================

	file$ = "ARC_SALECODE"
	salecode_dev = fnget_dev(file$)
	dim salecode_rec$:fnget_tpl$(file$)

	start_block = 1

	if start_block then
		find record (salecode_dev, key=firm_id$+"F"+slsp$, dom=*endif) salecode_rec$
		callpoint!.setColumnData("OPE_ORDHDR.COMM_PERCENT", salecode_rec.comm_rate$)
		callpoint!.setStatus("REFRESH")
	endif

	return

rem ==========================================================================
do_totals: rem --- Run the totals form and write back
rem ==========================================================================

rem --- Call the form

	dim dflt_data$[4,1]
	dflt_data$[1,0] = "TOTAL_SALES"
	dflt_data$[1,1] = callpoint!.getColumnData("OPE_ORDHDR.TOTAL_SALES")
	dflt_data$[2,0] = "DISCOUNT_AMT"
	dflt_data$[2,1] = callpoint!.getColumnData("OPE_ORDHDR.DISCOUNT_AMT")
	dflt_data$[3,0] = "TAX_AMOUNT"
	dflt_data$[3,1] = callpoint!.getColumnData("OPE_ORDHDR.TAX_AMOUNT")
	dflt_data$[4,0] = "FREIGHT_AMT"
	dflt_data$[4,1] = callpoint!.getColumnData("OPE_ORDHDR.FREIGHT_AMT")

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

rem --- Get disk record with updated form data

	gosub get_disk_rec

rem --- Set fields from the Order Totals form and write back

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))

	ordhdr_rec.total_sales  = ordHelp!.getExtPrice()
	ordhdr_rec.total_cost   = ordHelp!.getExtCost()
	ordhdr_rec.taxable_amt  = ordHelp!.getTaxable()
	ordhdr_rec.freight_amt  = ordHelp!.getFreight()
	ordhdr_rec.discount_amt = ordHelp!.getDiscount()
	ordhdr_rec.tax_amount   = ordHelp!.getTaxAmount()

	ordhdr_rec$ = field(ordhdr_rec$)
	write record (ordhdr_dev) ordhdr_rec$
	callpoint!.setStatus("SETORIG")

	callpoint!.setColumnData("OPE_ORDHDR.TOTAL_SALES",  ordhdr_rec.total_sales$)
	callpoint!.setColumnData("OPE_ORDHDR.TOTAL_COST",   ordhdr_rec.total_cost$)
	callpoint!.setColumnData("OPE_ORDHDR.TAXABLE_AMT",  ordhdr_rec.taxable_amt$)
	callpoint!.setColumnData("OPE_ORDHDR.FREIGHT_AMT",  ordhdr_rec.freight_amt$)
	callpoint!.setColumnData("OPE_ORDHDR.DISCOUNT_AMT", ordhdr_rec.discount_amt$)
	callpoint!.setColumnData("OPE_ORDHDR.TAX_AMOUNT",   ordhdr_rec.tax_amount$)
	callpoint!.setStatus("REFRESH")
	
	return

rem ==========================================================================
get_disk_rec: rem --- Get disk record, update with current form data
              rem     OUT: record_found - true/false (1/0)
              rem          ordhdr_rec$, updated (if record found)
              rem          ordhdr_dev
rem ==========================================================================

	file_name$  = "OPE_ORDHDR"
	ordhdr_dev  = fnget_dev(file_name$)
	ordhdr_tpl$ = fnget_tpl$(file_name$)
	dim ordhdr_rec$:ordhdr_tpl$

	cust_id$  = callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
	order_no$ = callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")
	record_found = 0
	start_block = 1

	if start_block then
		read record (ordhdr_dev, key=firm_id$+"  "+cust_id$+order_no$, dom=*endif) ordhdr_rec$
		record_found = 1

	rem --- Copy in any form data that's changed

		ordhdr_rec$ = util.copyFields(ordhdr_tpl$, callpoint!)
	endif

	return
[[OPE_ORDHDR.BSHO]]
print "Hdr:BSHO"; rem debug

rem --- Documentation
rem     Old s$(7,1) = 0 -> user_tpl.hist_ord$ = "Y" - order came from history
rem                 = 1 -> user_tpl.hist_ord$ = "N"

rem --- Open needed files

	num_files=40
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
	open_tables$[35]="OPM_POINTOFSALE",open_opts$[35]="OTA"
	open_tables$[36]="ARC_SALECODE", open_opts$[36]="OTA"
	open_tables$[37]="OPC_DISCCODE", open_opts$[37]="OTA"
	open_tables$[38]="OPC_TAXCODE",  open_opts$[38]="OTA"
	open_tables$[39]="OPE_ORDHDR",   open_opts$[39]="OTA"
	open_tables$[40]="ARC_TERMCODE", open_opts$[40]="OTA"

	gosub open_tables

rem --- Set table_chans$[all] into util object for getDev() and getTmpl()

	declare ArrayObject tableChans!

	call stbl("+DIR_PGM")+"adc_array.aon::str_array2object", table_chans$[all], tableChans!, status
	if status = 999 then goto std_exit
	util.setTableChans(tableChans!)

rem --- get AR Params

	dim ars01a$:open_tpls$[4]
	read record (num(open_chans$[4]), key=firm_id$+"AR00") ars01a$

	dim ars_credit$:open_tpls$[7]
	read record (num(open_chans$[7]), key=firm_id$+"AR01") ars_credit$

rem --- get IV Params

	dim ivs01a$:open_tpls$[29]
	read record (num(open_chans$[29]), key=firm_id$+"IV00") ivs01a$

rem --- see if blank warehouse exists

	blank_whse$="N"
	dim ivm10c$:open_tpls$[28]
	start_block = 1
	
	if start_block then
		read record (num(open_chans$[28]), key=firm_id$+"C"+ivm10c.warehouse_id$, dom=*endif) ivm10c$
		blank_whse$="Y"
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
		column!.addItem("OPE_ORDHDR.JOB_NO")
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
	callpoint!.setDevObject("credit_hold_control", util.getControl(callpoint!, "<<DISPLAY>>.CREDIT_HOLD")); rem used in opc_creditcheck
	callpoint!.setDevObject("backordered_control", util.getControl(callpoint!, "<<DISPLAY>>.BACKORDERED")); rem used in opc_creditcheck

rem --- Setup user_tpl$

	tpl$ = 
:		"credit_installed:c(1), " +
:		"balance:n(15), " +
:     "credit_limit:n(15), " +
:     "display_bal:c(1), " +
:     "ord_tot:n(15), " +
:     "def_ship:c(8), " + 
:     "def_commit:c(8), " +
:     "blank_whse:c(1), " +
:     "line_code:c(1), " +
:     "line_type:c(1), " +
:     "dropship_whse:c(1), " +
:     "def_whse:c(10), " +
:     "avail_oh:u(1), " +
:     "avail_comm:u(1), " +
:     "avail_avail:u(1), " +
:     "avail_oo:u(1), " +
:     "avail_wh:u(1), " +
:     "avail_type:u(1), " +
:     "dropship_flag:u(1), " +
:     "manual_price:u(1), " +
:     "alt_super:u(1), " +
:     "ord_tot_obj:u(1), " +
:     "price_code:c(2), " +
:     "pricing_code:c(4), " +
:     "order_date:c(8), " +
:     "pick_hold:c(1), " +
:     "pgmdir:c(1*), " +
:     "skip_whse:c(1), " +
:     "warehouse_id:c(2), " +
:     "user_entry:c(1), " +
:     "cur_row:n(5), " +
:     "skip_ln_code:c(1), " +
:     "hist_ord:c(1), " +
:     "cash_sale:c(1), " +
:     "cash_cust:c(6), " +
:     "bo_col:u(1), " +
:		"shipped_col:u(1), " +
:		"prod_type_col:u(1), " +
:		"unit_price_col:u(1), " +
:     "allow_bo:c(1), " +
:     "amount_mask:c(1*)," +
:     "line_taxable:c(1), " +
:     "item_taxable:c(1), " +
:     "min_line_amt:n(5), " +
:     "min_ord_amt:n(5), " +
:     "item_price:n(15), " +
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
:     "prev_disc_code:c(1*), "+
:     "prev_ship_to:c(1*), " +
:		"prev_sales_total:n(15), " +
:		"prev_unitprice:n(15), " +
:		"is_cash_sale:u(1), " +
:		"detail_modified:u(1), " +
:		"record_deleted:u(1), " +
:		"item_wh_failed:u(1), " +
:		"do_end_of_form:u(1), " +
:		"do_totals_form:u(1), " +
:		"disc_code:c(1*), " +
:		"tax_code:c(1*), " +
:		"new_order:u(1), " +
:		"credit_limit_warned:u(1), " +
:		"shipto_warned:u(1), " +
:		"first_read:u(1)"

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
	user_tpl.prev_taxable      = 0
	user_tpl.prev_ext_cost     = 0
	user_tpl.prev_disc_code$   = ""
	user_tpl.prev_ship_to$     = ""
	user_tpl.prev_sales_total  = 0; rem used in totals section to hold the order sale total
	user_tpl.prev_unitprice    = 0

rem --- Save the indices of the controls for the Avail Window, setup in AFMC

	user_tpl.avail_oh      = 2
	user_tpl.avail_comm    = 3
	user_tpl.avail_avail   = 4
	user_tpl.avail_oo      = 5
	user_tpl.avail_wh      = 6
	user_tpl.avail_type    = 7
	user_tpl.dropship_flag = 8
	user_tpl.manual_price  = 9
	user_tpl.alt_super     = 10
	user_tpl.ord_tot_obj   = 11; rem set here in BSHO

rem --- Set variables for called forms (OPE_ORDLSDET)

	callpoint!.setDevObject("lotser_flag", ivs01a.lotser_flag$)

rem --- Set up Lot/Serial button (and others) properly

	switch pos(ivs01a.lotser_flag$="LS")
		case 1; callpoint!.setOptionText("LENT","Lot Entry"); break
		case 2; callpoint!.setOptionText("LENT","Serial Entry"); break
		case default; break
	swend

	callpoint!.setOptionEnabled("LENT",0)
	callpoint!.setOptionEnabled("RCPR",0)
	callpoint!.setOptionEnabled("DINV",0)
	callpoint!.setOptionEnabled("CINV",0)
	callpoint!.setOptionEnabled("RPRT",0)
	callpoint!.setOptionEnabled("PRNT",0)
	callpoint!.setOptionEnabled("ADDL",0)
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
