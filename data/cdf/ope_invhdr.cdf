[[OPE_INVHDR.BWRI]]
print "Hdr:BWRI"; rem debug

rem --- Unlock order (This doesn't work as desired)

	callpoint!.setColumnData("OPE_INVHDR.LOCK_STATUS", "N")
	print "---Clear lock"; rem debug
[[OPE_INVHDR.ASVA]]

[[OPE_INVHDR.AOPT-MINV]]
rem --- Change an Order into an Invoice

	gosub check_print_flag

	if !locked and 
:		callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID") <> "" and 
:		callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")    <> "" and 
:		callpoint!.getColumnData("OPE_INVHDR.ORDINV_FLAG") = "O" 
:	then

	rem --- Set Invoice number

		call stbl("+DIR_SYP")+"bas_sequences.bbj","INVOICE_NO",inv_no$,table_chans$[all]
		
		if inv_no$ = "" then
			callpoint!.setStatus("ABORT")
		else
			callpoint!.setColumnData("OPE_INVHDR.AR_INV_NO", inv_no$)
			callpoint!.setColumnData("OPE_INVHDR.ORDINV_FLAG", "I")
			callpoint!.setColumnData("OPE_INVHDR.INVOICE_DATE", sysinfo.system_date$)
			callpoint!.setColumnData("OPE_INVHDR.PRINT_STATUS", "N")
			callpoint!.setColumnData("OPE_INVHDR.LOCK_STATUS", "Y")
			print "---Set lock"; rem debug
			callpoint!.setColumnData("OPE_INVHDR.LOCK_STATUS", "N"); rem debug, forcing the lock off for now, this isn't working correctly
			user_tpl.old_disc_code$ = ""
			user_tpl.price_code$ = "Y"
			order_no$ = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")
			gosub add_to_batch_print
			callpoint!.setStatus("SAVE;REFRESH")
		endif
		
	endif
[[OPE_INVHDR.SLSPSN_CODE.AVAL]]
rem --- Set Commission Percent

	file$ = "ARC_SALECODE"
	salecode_dev = fnget_dev(file$)
	dim salecode_rec$:fnget_tpl$(file$)
	slsp$ = callpoint!.getUserInput()
	start_block = 1

	if start_block then
		find record (salecode_dev, key=firm_id$+"E"+slsp$, dom=*endif) salecode_rec$
		callpoint!.setColumnData("OPE_INVHDR.COMM_PERCENT", salescode_rec.comm_percent$)
		callpoint!.setStatus("REFRESH")
	endif
[[OPE_INVHDR.SHIPTO_TYPE.AVAL]]
rem -- Deal with which Ship To type

	callpoint!.setColumnData("<<DISPLAY>>.SNAME","")
	callpoint!.setColumnData("<<DISPLAY>>.SADD1","")
	callpoint!.setColumnData("<<DISPLAY>>.SADD2","")
	callpoint!.setColumnData("<<DISPLAY>>.SADD3","")
	callpoint!.setColumnData("<<DISPLAY>>.SADD4","")
	callpoint!.setColumnData("<<DISPLAY>>.SCITY","")
	callpoint!.setColumnData("<<DISPLAY>>.SSTATE","")
	callpoint!.setColumnData("<<DISPLAY>>.SZIP","")

	ship_to_type$ = callpoint!.getUserInput()
	ship_to_no$   = callpoint!.getColumnData("OPE_INVHDR.SHIPTO_NO")
	cust_id$      = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	ord_no$       = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")

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
	ord_no$     = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")

	if user_tpl.old_ship_to$ = "000099" and ship_to_no$ <> "000099" then
		remove (fnget_dev("OPE_ORDSHIP"), key=firm_id$+cust_id$+ord_no$, dom=*next)
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
rem --- Remove from ope-04

	ope_prntlist_dev=fnget_dev("OPE_PRNTLIST")
	remove (ope_prntlist_dev,key=firm_id$+"O"+"  "+
:		callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")+
:		callpoint!.getColumnData("OPE_INVHDR.ORDER_NO"),dom=*next)
[[OPE_INVHDR.ARER]]
rem --- Set flag

	user_tpl.user_entry$ = "N"; rem user entered an order (not navagated)
[[OPE_INVHDR.SHIPTO_NO.BINP]]
rem --- Save old value

	user_tpl.old_ship_to$ = callpoint!.getColumnData("OPE_INVHDR.SHIPTO_NO")
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
[[OPE_INVHDR.AOPT-CRCH]]
rem --- Credit check?

	cust_id$ = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")

	if user_tpl.credit_installed$ = "Y" and user_tpl.display_bal$ <> "N" and cvs(cust_id$, 2) <> "" then
		call user_tpl.pgmdir$+"opc_creditmgmnt.aon", cust_id$, table_chans$[all], callpoint!
	endif
[[OPE_INVHDR.APFE]]
rem --- Enable / Disable buttons

	callpoint!.setOptionEnabled("CRCH",1)

	if cvs(callpoint!.getColumnData("OPE_INVHDR.ORDER_NO"),2)=""
		callpoint!.setOptionEnabled("DINV",1)
		callpoint!.setOptionEnabled("CINV",1)
		callpoint!.setOptionEnabled("MINV",0)
	else
		callpoint!.setOptionEnabled("MINV",1)
	endif
[[OPE_INVHDR.BPFX]]
rem --- Disable buttons

	callpoint!.setOptionEnabled("CRCH",0)
	callpoint!.setOptionEnabled("DINV",0)
	callpoint!.setOptionEnabled("CINV",0)
	callpoint!.setOptionEnabled("MINV",0)

[[OPE_INVHDR.BDEL]]
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
	ars_cred_dev = fnget_dev("OPE_CREDCUST")

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
			ord_seq$ = ope11a.line_no$
			gosub remove_lot_ser_det
		endif

	wend

	remove (ope33_dev, key=firm_id$+cust$+ord$, dom=*next)
	remove (cashrct_dev, key=firm_id$+ar_type$+cust$+ord$, err=*next)

	if user_tpl.credit_installed$="Y" then
		remove (ars_cred_dev, key=firm_id$+cust$+ord_date$+ord$, err=*next)	
	endif
[[OPE_INVHDR.BPRK]]
rem --- Is previous record not a quote and not void?

	file_name$ = "OPE_INVHDR"
	ope01_dev = fnget_dev(file_name$)
	dim ope01a$:fnget_tpl$(file_name$)
	start_block = 1

	while 1
		if start_block then
			p_key$ = keyp(ope01_dev, end=*endif)
			read record (ope01_dev, key=p_key$) ope01a$

			if ope01a.firm_id$ = firm_id$ then 
				if ope01a.ordinv_flag$ <> "P" and ope01a.invoice_type$ <> "V" then
					break
				else
					read (ope01_dev, dir=-1, end=*endif)
					continue
				endif
			endif
		endif

		rem --- If EOF or past firm, rewind to last record in this firm
		read (ope01_dev, key=firm_id$+$ff$, dom=*next, end=*break)
	wend
[[OPE_INVHDR.BNEK]]
rem --- Is next record not a quote and not void?

	file_name$ = "OPE_INVHDR"
	ope01_dev = fnget_dev(file_name$)
	dim ope01a$:fnget_tpl$(file_name$)
	dim first_rec$:fnget_tpl$(file_name$)
	start_block = 1
	first_time  = 1

	while 1
		if start_block then
			read record (ope01_dev, dir=0, end=*endif) ope01a$

		rem --- Get first record
			if first_time then
				first_rec$ = ope01a$
				first_time = 0
			else

			rem --- Is this the first record again?
				if firm_id$            = first_rec.firm_id$     and 
:					ope01a.customer_id$ = first_rec.customer_id$ and 
:					ope01a.order_no$    = first_rec.order_no$
:				then
					exitto bnek_none_found
				endif
			endif

		rem --- The wrong firm will "fall thru"
			if ope01a.firm_id$ = firm_id$ then
				if ope01a.invoice_type$ <> "P" and ope01a.invoice_type$ <> "V" then
					break; rem --- found a good record
				else
					read (ope01_dev, end=*endif)
					continue; rem --- look again
				endif
			endif
		endif

	rem --- If EOF or wrong firm, rewind to first record of the firm
		read (ope01_dev, key=firm_id$, dom=*next)
	wend

	goto bnek_done

bnek_none_found:

	msg_id$ = "OP_ALL_WRONG_TYPE"
	gosub disp_message
	callpoint!.setStatus("ABORT")

bnek_done:
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
	else
		callpoint!.setStatus("ABORT")
	endif
[[OPE_INVHDR.AWRI]]
rem --- Write/Remove manual ship to file

	cust_id$ = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	ord_no$  = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")
	ordship_dev = fnget_dev("OPE_ORDSHIP")
	
	if callpoint!.getColumnData("OPE_INVHDR.SHIPTO_TYPE") <> "M" then 
		remove (ordship_dev,key=firm_id$+cust_id$+ord_no$,dom=*next)
	else
		dim ordship_tpl$:fnget_tpl$("OPE_ORDSHIP")
		read record (ordship_dev, key=firm_id$+cust_id$+ord_no$ ,dom=*next) ordship_tpl$

		ordship_tpl.firm_id$     = firm_id$
		ordship_tpl.customer_id$ = cust_id$
		ordship_tpl.order_no$    = ord_no$
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

[[OPE_INVHDR.ADIS]]
rem --- Show customer data
	
	cust_id$ = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	gosub display_customer

	if callpoint!.getColumnData("OPE_INVHDR.CASH_SALE") <> "Y" then 
		gosub display_aging
      gosub check_credit

		
	rem --- Only display if user did not enter the customer, that is, used the nav arrows

		if user_tpl.user_entry$ = "N" then
			if user_tpl.credit_installed$ = "Y" and user_tpl.display_bal$ = "A" then
				call user_tpl.pgmdir$+"opc_creditmgmnt.aon", cust_id$, table_chans$[all], callpoint!
			endif
		endif
	endif

	gosub disp_cust_comments

rem --- Display Ship to information

	ship_to_type$ = callpoint!.getColumnData("OPE_INVHDR.SHIPTO_TYPE")
	ship_to_no$   = callpoint!.getColumnData("OPE_INVHDR.SHIPTO_NO")
	ord_no$       = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")
	gosub ship_to_info

rem --- Display order total

	callpoint!.setColumnData("<<DISPLAY>>.ORDER_TOT", callpoint!.getColumnData("OPE_INVHDR.TOTAL_SALES"))

rem --- Backorder and Credit Hold

	if callpoint!.getColumnData("OPE_INVHDR.BACKORD_FLAG") = "B" then
		callpoint!.setColumnData("<<DISPLAY>>.BACKORDERED", "Backorder")
	endif

	if callpoint!.getColumnData("OPE_INVHDR.CREDIT_FLAG") = "C" then
		callpoint!.setColumnData("<<DISPLAY>>.CREDIT_HOLD", "Credit Hold")
	endif

	user_tpl.old_ship_to$   = callpoint!.getColumnData("OPE_INVHDR.SHIPTO_NO")
	user_tpl.old_disc_code$ = callpoint!.getColumnData("OPE_INVHDR.DISC_CODE")

 rem --- Check locked status

	gosub check_lock_flag

	if locked then
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

rem --- Check Print flag

	gosub check_print_flag

	if locked then
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

rem --- Set Codes
        
	user_tpl.price_code$   = callpoint!.getColumnData("OPE_INVHDR.PRICE_CODE")
	user_tpl.pricing_code$ = callpoint!.getColumnData("OPE_INVHDR.PRICING_CODE")
	user_tpl.order_date$   = callpoint!.getColumnData("OPE_INVHDR.ORDER_DATE")
[[OPE_INVHDR.ORDER_NO.AVAL]]
print "Hdr:ORDER_NO.AVAL"; rem debug

rem --- Do we need to create a new order number?

	new_seq$ = "N"
	user_tpl.user_entry$ = "N"
	ord_no$ = callpoint!.getUserInput()

	if cvs(ord_no$, 2) = "" then 
		print "---ord_no$ is null"; rem debug

		rem --- Option on order no field to assign a new sequence on null must be cleared
		call stbl("+DIR_SYP")+"bas_sequences.bbj","ORDER_NO",ord_no$,table_chans$[all]
		
		if ord_no$ = "" then
			callpoint!.setStatus("ABORT")
			print "---abort"; rem debug
			break; rem --- exit callpoint
		else
			callpoint!.setUserInput(ord_no$)
			new_seq$ = "Y"
			print "---new_seq$ set"; rem debug
		endif
	else
		user_tpl.user_entry$ = "Y"
		print "---ord_no$ is not null"; rem debug
	endif

rem --- Does order exist?

	ope01_dev = fnget_dev("OPE_INVHDR")
	dim ope01a$:fnget_tpl$("OPE_INVHDR")

	ar_type$ = callpoint!.getColumnData("OPE_INVHDR.AR_TYPE")
	cust_id$ = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")

	found = 0
	start_block = 1

	if start_block then
		find record (ope01_dev, key=firm_id$+ar_type$+cust_id$+ord_no$, dom=*endif) ope01a$
		found = 1
	endif

	rem ---debug
	if found then 
		print "---order number found"
	else
		print "---order number not found"
	endif

rem --- A new record must be the next sequence

	if found = 0 and new_seq$ = "N" then
		msg_id$ = "OP_NEW_ORD_USE_SEQ"
		gosub disp_message	
		callpoint!.setFocus("OPE_INVHDR.ORDER_NO")
		exit; rem --- exit from callpoint
	endif

	rem callpoint!.setDevObject("order", ord_no$); rem Needed?
	user_tpl.hist_ord$ = "N"

rem --- Existing record

	if found then 

	rem --- Check for void

		if ope01a.invoice_type$ = "V" then
			callpoint!.setStatus("ABORT")
			exit; rem --- exit from callpoint			
		endif

	rem --- Check for quote
		
		if ope01a.invoice_type$ = "P" then
			msg_id$ = "OP_IS_QUOTE"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			exit; rem --- exit from callpoint			
		endif		

	rem --- Backorder and Credit Hold

		if ope01a.backord_flag$ = "B" then
			callpoint!.setColumnData("<<DISPLAY>>.BACKORDERED", "Backorder")
		endif

		if ope01a.credit_flag$ = "C" then
			callpoint!.setColumnData("<<DISPLAY>>.CREDIT_HOLD", "Credit Hold")
		endif

		user_tpl.old_ship_to$   = ope01a.shipto_no$
		user_tpl.old_disc_code$ = ope01a.disc_code$

	rem --- Display Ship to information

		ship_to_type$ = ope01a.shipto_type$
		ship_to_no$   = ope01a.shipto_no$
		ord_no$       = ope01a.order_no$
		gosub ship_to_info

	rem --- Display order total

		callpoint!.setColumnData("<<DISPLAY>>.ORDER_TOT", str(ope01a.total_sales:user_tpl.amount_mask$))

	rem --- Check locked status

		gosub check_lock_flag

		if locked then
			callpoint!.setStatus("ABORT")
			break; rem --- exit callpoint
		endif

	rem --- Check Print flag

		gosub check_print_flag

		if locked then
			callpoint!.setStatus("ABORT")
			break; rem --- exit callpoint
		endif
		
	rem --- Set Codes
        
		user_tpl.price_code$ = "Y"
		if reprint then callpoint!.setColumnData("OPE_INVHDR.REPRINT_FLAG", "Y")

		user_tpl.price_code$   = ope01a.price_code$
		user_tpl.pricing_code$ = ope01a.pricing_code$
		user_tpl.order_date$   = ope01a.order_date$
  
	else

rem --- New record, set default

		call stbl("+DIR_SYP")+"bas_sequences.bbj", "INVOICE_NO", invoice_no$, table_chans$[all]
		callpoint!.setColumnData("OPE_INVHDR.AR_INV_NO", invoice_no$)

      cust_id$ = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
		ord_no$  = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")
		callpoint!.setColumnData("OPE_INVHDR.INVOICE_TYPE","S")
        
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
		callpoint!.setColumnData("OPE_INVHDR.MESSAGE_CODE",arm02a.message_code$)
		callpoint!.setColumnData("OPE_INVHDR.TERRITORY",arm02a.territory$)
		callpoint!.setColumnData("OPE_INVHDR.ORDER_DATE",sysinfo.system_date$)
		callpoint!.setColumnData("OPE_INVHDR.TAX_CODE",arm02a.tax_code$)
		callpoint!.setColumnData("OPE_INVHDR.PRICING_CODE",arm02a.pricing_code$)
      callpoint!.setColumnData("OPE_INVHDR.ORD_TAKEN_BY",sysinfo.user_id$)

		gosub get_op_params

		if cust_id$ = ars01a.customer_id$
			callpoint!.setColumnData("OPE_INVHDR.CASH_SALE", "Y")
		else 
			callpoint!.setColumnData("OPE_INVHDR.CASH_SALE", "N")
		endif

		user_tpl.price_code$   = ""
		user_tpl.pricing_code$ = arm02a.pricing_code$
		user_tpl.order_date$   = sysinfo.system_date$

	endif

rem --- New or existing order

	order_no$ = callpoint!.getUserInput()
	gosub add_to_batch_print
	callpoint!.setColumnData("OPE_INVHDR.LOCK_STATUS", "Y")
	print "---Set lock"; rem debug
	callpoint!.setColumnData("OPE_INVHDR.LOCK_STATUS", "N"); rem debug, forcing the lock off for now, not working correctly

rem --- Enable/Disable buttons

	callpoint!.setOptionEnabled("DINV",0)
	callpoint!.setOptionEnabled("CINV",0)
	callpoint!.setOptionEnabled("MINV",1)

	callpoint!.setStatus("MODIFIED;REFRESH")
[[OPE_INVHDR.CUSTOMER_ID.AVAL]]
rem --- Show customer data
	
	cust_id$ = callpoint!.getUserInput()
	gosub display_customer

	if callpoint!.getColumnData("OPE_INVHDR.CASH_SALE") <> "Y" then 
		gosub display_aging
      gosub check_credit

		if user_tpl.credit_installed$ = "Y" and user_tpl.display_bal$ = "A" then
			call user_tpl.pgmdir$+"opc_creditmgmnt.aon", cust_id$, table_chans$[all], callpoint!
		endif
	endif

	gosub disp_cust_comments

rem --- Enable Duplicate buttons

	if cvs(callpoint!.getColumnData("OPE_INVHDR.ORDER_NO"),2) = "" then
		callpoint!.setOptionEnabled("DINV", 1)
		callpoint!.setOptionEnabled("CINV", 1)
	endif
[[OPE_INVHDR.CUSTOMER_ID.AINP]]
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
              rem      IN: custdet_tpl$ (cust detail record)
rem ==========================================================================

	if custdet_tpl.credit_limit and user_tpl.balance>=user_tpl.credit_limit then
   	if user_tpl.credit_installed$ <> "Y" then
      	msg_id$ = "OP_OVER_CREDIT_LIMIT"
			dim msg_token$[1]
			msg_token$[1] = str(custdet_tpl.credit_limit:user_tpl.amount_mask$)
         gosub disp_message
      endif  
   
		callpoint!.setColumnData("<<DISPLAY>>.CREDIT_HOLD", "*** Credit Limit Exceeded ***") 
   endif

return

rem ==========================================================================
ship_to_info: rem --- Get and display Bill To Information
              rem      IN: cust_id$
              rem          ship_to_type$
              rem          ship_to_no$
              rem          ord_no$
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

		ordship_dev = fnget_dev("OPE_ORDSHIP")
		dim ordship_tpl$:fnget_tpl$("OPE_ORDSHIP")
		read record (ordship_dev, key=firm_id$+cust_id$+ord_no$, dom=*next) ordship_tpl$

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
disp_ord_tot: rem --- Display order total
rem ==========================================================================

	user_tpl.ord_tot=0

	ope11_dev=fnget_dev("OPE_ORDDET")
	dim ope11a$:fnget_tpl$("OPE_ORDDET")

	opc_linecode_dev=fnget_dev("OPC_LINECODE")
	dim opc_linecode$:fnget_tpl$("OPC_LINECODE")

	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")

	ar_type$ = callpoint!.getColumnData("OPE_INVHDR.AR_TYPE")
	cust_id$ = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	ord_no$  = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")

	read (ope11_dev, key=firm_id$+ar_type$+cust_id$+ord_no$, dom=*next)

	while 1
		read record (ope11_dev, end=*break) ope11a$

		if ope11a.firm_id$+ope11a.ar_type$+ope11a.customer_id$+ope11a.order_no$ <> 
:			firm_id$+ar_type$+cust_id$+ord_no$ 
:		then
			break
		endif

		dim opc_linecode$:fattr(opc_linecode$)
		read record (opc_linecode_dev, key=firm_id$+ope11a.line_code$, dom=*next) opc_linecode$

		if pos(opc_linecode.line_type$="SNP") then 
			user_tpl.ord_tot = user_tpl.ord_tot + (ope11a.unit_price * ope11a.qty_ordered)
		else
			if opc_linecode.line_type$ = "O" then 
				user_tpl.ord_tot = user_tpl.ord_tot + ope11a.ext_price
			endif
		endif

		rem --- this does nothing...
		dim ivm01a$:fattr(ivm01a$)
		read record (ivm01_dev, key=firm_id$+ope11a.item_id$, dom=*next) ivm01a$

		if ivm01a.taxable_flag$="Y" and opc_linecode.taxable_flag$="Y" then 
			ope11a.taxable_amt = ope11a.ext_price
		endif
		rem ---

	wend

	callpoint!.setColumnData("<<DISPLAY>>.ORDER_TOT", str(user_tpl.ord_tot))
	callpoint!.setStatus("REFRESH")

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

	locked=0
	on pos( callpoint!.getColumnData("OPE_INVHDR.LOCK_STATUS") = "NYS12" ) goto 
:		end_lock,end_lock,locked,on_invoice,update_stat,update_stat,end_lock

locked:

	msg_id$="ORD_LOCKED"
	dim msg_tokens$[1]

	if callpoint!.getColumnData("OPE_INVHDR.PRINT_STATUS")="B" then 
		msg_tokens$[1]=" by Batch Print"
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

	if msg_opt$="CANCEL" then
		locked=1
		callpoint!.setStatus("ABORT")
	endif

	goto end_lock

update_stat:

	msg_id$="INVOICE_IN_UPDATE"
	gosub disp_message
	locked=1

end_lock:

return

rem ==========================================================================
add_to_batch_print: rem --- Add to batch print file
                    rem      IN: order_no$
rem ==========================================================================

	ope_prntlist_dev = fnget_dev("OPE_PRNTLIST")
	dim ope_prntlist$:fnget_tpl$("OPE_PRNTLIST")

	ope_prntlist.firm_id$     = firm_id$
	ope_prntlist.ordinv_flag$ = "I"
	ope_prntlist.ar_type$     = "  "
	ope_prntlist.customer_id$ = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	ope_prntlist.order_no$    = order_no$

	write record (ope_prntlist_dev) ope_prntlist$
	print "---Added to print batch"; rem debug
	print "---order:", ope_prntlist.order_no$

return

rem ==========================================================================
check_print_flag: rem --- Check print flag
                  rem     OUT: locked = 1/0
                  rem          printed$ = Y/N
rem ==========================================================================

	printed$ = "N"
	locked = 0
	ar_type$      = callpoint!.getColumnData("OPE_INVHDR.AR_TYPE")
	cust_id$      = callpoint!.getColumnData("OPE_INVHDR.CUSTOMER_ID")
	order_no$     = callpoint!.getColumnData("OPE_INVHDR.ORDER_NO")
	print_status$ = callpoint!.getColumnData("OPE_INVHDR.PRINT_STATUS")
	ordinv_flag$  = callpoint!.getColumnData("OPE_INVHDR.ORDINV_FLAG")
		 
	if ordinv_flag$ = "O" then 
		if print_status$ <> "Y" then 
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
					callpoint!.setStatus("SAVE")
					printed$ = "Y"
					gosub add_to_batch_print
				endif
			else
				gosub add_to_batch_print
			endif
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

	inv_type$ = callpoint!.getColumnData("OPE_INVHDR.INVOICE_TYPE")

	call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",iv_files[all],ivs01a$,iv_info$[all],iv_refs$[all],iv_refs[all],table_chans$[all],status
	iv_info$[1] = wh_id$
	iv_info$[2] = item_id$
	iv_info$[3] = ls_id$
	iv_refs[0]  = qty

	while 1
		if pos(opc_linecode.line_type$="SP")=0 then break
		if opc_linecode.dropship$="Y" or inv_type$="P" then break; REM "Drop ship or quote
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
                    rem          ord_seq$ = detail line number
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
		if ord_seq$<>ope21a.line_no$ then break

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
:			"OPT_ORDHDR",
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
:				"OPT_ORDDET",
:				"LOOKUP",
:				table_chans$[all],
:				key_pfx_det$,
:				"PRIMARY",
:				rd_key_det$

			if cvs(rd_key_det$,2)<>"" then 
				opt01_dev = fnget_dev("OPT_ORDHDR")
				dim opt01a$:fnget_tpl$("OPT_ORDHDR")
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

			dim opt11a$:fnget_tpl$("OPT_ORDDET")
			opt11_dev=fnget_dev("OPT_ORDDET")

			dim ope11a$:fnget_tpl$("OPE_INVDET")
			ope11_dev=fnget_dev("OPE_INVDET")

			ivm01_dev=fnget_dev("IVM_ITEMMAST")
			dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")

			read (opt11_dev, key=firm_id$+opt01a.ar_type$+opt01a.customer_id$+opt01a.ar_inv_no$, dom=*next)

			opc_linecode_dev = fnget_dev("OPC_LINECODE")
			dim opc_linecode$:fnget_tpl$("OPC_LINECODE")

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

	call stbl("+DIR_PGM")+"opc_pc.aon",pc_files[all],firm_id$,wh$,item$,user_tpl.price_code$,cust$,
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

rem --- Open needed files

	num_files=36
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
	open_tables$[23]="OPT_ORDHDR",   open_opts$[23]="OTA"
	open_tables$[24]="OPT_ORDDET",   open_opts$[24]="OTA"
	open_tables$[25]="OPE_ORDDET",   open_opts$[25]="OTA"
	open_tables$[26]="OPT_INVSHIP",  open_opts$[26]="OTA"
	open_tables$[27]="OPE_CREDCUST", open_opts$[27]="OTA"
	open_tables$[28]="IVC_WHSECODE", open_opts$[28]="OTA"
	open_tables$[29]="IVS_PARAMS",   open_opts$[29]="OTA"
	open_tables$[30]="OPE_ORDLSDET", open_opts$[30]="OTA"
	open_tables$[31]="IVM_ITEMPRIC", open_opts$[31]="OTA"
	open_tables$[32]="IVC_PRICCODE", open_opts$[32]="OTA"
	open_tables$[33]="ARM_CUSTCMTS", open_opts$[33]="OTA"
	open_tables$[34]="OPE_PRNTLIST", open_opts$[34]="OTA"
	open_tables$[35]="OPM_POINTOFSALE", open_opts$[35]="OTA"
	open_tables$[36]="ARC_SALECODE", open_opts$[36]="OTA"
	
gosub open_tables

rem --- get AR Params

	dim ars01a$:open_tpls$[4]
	read record (num(open_chans$[4]), key=firm_id$+"AR00") ars01a$

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

rem --- Save totals object

	UserObj!.addItem( util.getControl(callpoint!, "<<DISPLAY>>.ORDER_TOT") )

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
:		"avail_oh:c(5), " +
:		"avail_comm:c(5), " +
:		"avail_avail:c(5), " +
:		"avail_oo:c(5), " +
:		"avail_wh:c(5), " +
:		"avail_type:c(5*), " +
:		"dropship_flag:c(5*), " +
:		"ord_tot_1:c(5*), " +
:		"price_code:c(2), " +
:		"pricing_code:c(4), " +
:		"order_date:c(8), " +
:		"pick_hold:c(1), " +
:		"never_checked:u(1), " +
:		"pgmdir:c(1*), " +
:		"skip_whse:c(1), " +
:		"warehouse_id:c(2), " +
:		"user_entry:c(1), " +
:		"cur_row:n(5), " +
:		"skip_ln_code:c(1), " +
:		"hist_ord:c(1), " +
:		"old_ship_to:c(1*), " +
:		"old_disc_code:c(1*), "+
:		"cash_sale:c(1), " +
:		"cash_cust:c(6), " +
:		"bo_col:u(1), " +
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
:		"is_cash_sale:u(1)"

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
	user_tpl.bo_col            = 8
	user_tpl.never_checked     = 1
	user_tpl.is_cash_sale      = 0

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

	user_tpl.avail_oh$      ="2"
	user_tpl.avail_comm$    ="3"
	user_tpl.avail_avail$   ="4"
	user_tpl.avail_oo$      ="5"
	user_tpl.avail_wh$      ="6"
	user_tpl.avail_type$    ="7"
	user_tpl.dropship_flag$ ="8"
	user_tpl.ord_tot_1$     ="9"

rem --- Clear variables

	rem callpoint!.setDevObject("cust","")
	rem callpoint!.setDevObject("ar_type","")
	rem callpoint!.setDevObject("order","")
	rem callpoint!.setDevObject("int_seq","")
	rem callpoint!.setDevObject("wh","")
	rem callpoint!.setDevObject("item","")
	rem callpoint!.setDevObject("lsmast_dev",open_chans$[11])
	rem callpoint!.setDevObject("lsmast_tpl",open_tpls$[11])
	rem callpoint!.setDevObject("lotser_flag",ivs01a.lotser_flag$)
	rem callpoint!.setDevObject("default_linecode",ars01a.line_code$)

rem --- Set Lot/Serial button up properly

	switch pos(ivs01a.lotser_flag$="LS")
		case 1; callpoint!.setOptionText("LENT","Lot Entry"); break
		case 2; callpoint!.setOptionText("LENT","Serial Entry"); break
		case default; break
	swend

	callpoint!.setOptionEnabled("LENT",0)
	callpoint!.setOptionEnabled("RCPR",0)
	callpoint!.setOptionEnabled("DINV",0)
	callpoint!.setOptionEnabled("CINV",0)
	callpoint!.setOptionEnabled("CRCH",1)
	callpoint!.setOptionEnabled("MINV",0)
[[OPE_INVHDR.AFMC]]
rem print 'show', "Hdr:AFMC"; rem debug

rem --- Inits

	use ::ado_util.src::util

rem --- Create Inventory Availability window

	grid!  = util.getGrid(Form!)
	child! = util.getChild(Form!)
	cxt    = SysGUI!.getAvailableContext()

	mwin! = child!.addChildWindow(15000, 0, 10, child!.getWidth(), 75, "", $00000800$, cxt)
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
	userObj!.addItem(mwin!.addStaticText(15107,695,25,75,15,"",$0000$)); rem Drop Ship text
