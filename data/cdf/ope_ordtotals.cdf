[[OPE_ORDTOTALS.BSHO]]
print "OPE_ORDTOTALS:BSHO"; rem debug

rem --- Get order header record and totals

	use ::ado_order.src::OrderHelper
	declare OrderHelper ordHelp!

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	ordHelp!.totalSalesDisk()

	file_name$ = "OPE_ORDHDR"
	dim ordhdr_rec$:fnget_tpl$(file_name$)
	ordhdr_dev = fnget_dev(file_name$)
	found = 0
	start_block = 1

	if start_block then
		find record (ordhdr_dev, key=firm_id$+"  "+ordHelp!.getCust_id()+ordHelp!.getOrder_no(), dom=*endif) ordhdr_rec$
		found = 1
	endif

	if found then
		user_tpl.disc_code$ = ordhdr_rec.disc_code$
		user_tpl.tax_code$  = ordhdr_rec.tax_code$
	else
		callpoint!.setStatus("EXIT")
	endif
[[OPE_ORDTOTALS.BEND]]
print "BEND"; rem debug

rem (not called if the Run button pushed)

rem --- The thought here is that is the user pushes the "x" button, we should abandon the changes
rem gosub send_back_values
	
	print "---changes NOT updated"; rem debug
	print "OPE_ORDTOTALS:END"; rem debug
[[OPE_ORDTOTALS.ARAR]]
print "OPE_ORDTOTALS:ARAR"; rem debug

rem --- Get order helper object

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))	

rem --- Get Amount mask

	call stbl("+DIR_PGM")+"adc_getmask.aon","","IV","A","",amount_mask$,0,mask_len

rem --- Set Current Discount amount and Freight amount from Dev Objects

	callpoint!.setColumnData("OPE_ORDTOTALS.DISCOUNT_AMT",str(callpoint!.getDevObject("disc_amt")))
	callpoint!.setColumnData("OPE_ORDTOTALS.FREIGHT_AMT",str(callpoint!.getDevObject("frt_amt")))

rem --- Store DevObjects in case user aborts form
	callpoint!.setDevObject("tax_amt",callpoint!.getColumnData("OPE_ORDTOTALS.TAX_AMOUNT"))

rem --- Get current discounts

	file_name$ = "OPC_DISCCODE"
	disccode_dev = fnget_dev(file_name$)
	dim disccode_rec$:fnget_tpl$(file_name$)

	find record (disccode_dev, key=firm_id$+user_tpl.disc_code$, dom=*next) disccode_rec$
	new_disc_per = disccode_rec.disc_percent

	prev_disc_amt = num(callpoint!.getColumnData("OPE_ORDTOTALS.DISCOUNT_AMT"))
	new_disc_amt = round(new_disc_per * ordHelp!.getExtPrice() / 100, 2)

	if user_tpl.prev_sales_total <> 0 then
		prev_disc_per = round(100 * prev_disc_amt / user_tpl.prev_sales_total, 2)
	else
		prev_disc_per = 0
	endif

rem --- Change discount?

	print "---New order?", user_tpl.new_order; rem debug

	if new_disc_amt <> prev_disc_amt then
		if user_tpl.new_order then
			discount_amt = new_disc_amt
			callpoint!.setColumnData("OPE_ORDTOTALS.DISCOUNT_AMT", str(discount_amt))
		else

		rem --- Replace discounts?

			msg_id$ = "OP_REPLACE_DISC"
			dim msg_tokens$[4]
			msg_tokens$[1] = cvs( str(prev_disc_per:"##0.00-"), 3) + "%"
			msg_tokens$[2] = cvs( str(prev_disc_amt:amount_mask$), 3)
			msg_tokens$[3] = cvs( str(new_disc_per:"##0.00-"), 3) + "%"
			msg_tokens$[4] = cvs( str(new_disc_amt:amount_mask$), 3)
			gosub disp_message

			if msg_opt$ = "Y" then
				discount_amt = new_disc_amt
				callpoint!.setColumnData("OPE_ORDTOTALS.DISCOUNT_AMT", str(discount_amt))
			endif
		endif
	endif

rem --- Calculate and display Discount and Tax

	freight_amt = num(callpoint!.getColumnData("OPE_ORDTOTALS.FREIGHT_AMT"))
	discount_amt = num(callpoint!.getColumnData("OPE_ORDTOTALS.DISCOUNT_AMT"))
	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	tax_amount = ordHelp!.calculateTax(discount_amt, freight_amt,num(callpoint!.getColumnData("OPE_ORDTOTALS.TOTAL_SALES")))
	callpoint!.setColumnData("OPE_ORDTOTALS.TAX_AMOUNT", str(tax_amount))

rem --- Store DevObject in case user aborts form
	callpoint!.setDevObject("tax_amt",callpoint!.getColumnData("OPE_ORDTOTALS.TAX_AMOUNT"))

	gosub display_fields
[[OPE_ORDTOTALS.ASVA]]
print "ASVA"; rem debug

rem (Doesn't get here if you click the close button "x")

	gosub send_back_values

	print "---changes updated"; rem debug
	print "OPE_ORDTOTALS:END"; rem debug
[[OPE_ORDTOTALS.FREIGHT_AMT.AVAL]]
print "FREIGHT_AMT.AVAL"; rem debug

rem --- Save freight and recalculate tax

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	freight_amt = num(callpoint!.getUserInput())
	callpoint!.setColumnData("OPE_ORDTOTALS.FREIGHT_AMT", str(freight_amt))
	discount_amt = num(callpoint!.getColumnData("OPE_ORDTOTALS.DISCOUNT_AMT"))
	tax_amount = ordHelp!.calculateTax(discount_amt, freight_amt,num(callpoint!.getColumnData("OPE_ORDTOTALS.TOTAL_SALES")))
	callpoint!.setColumnData("OPE_ORDTOTALS.TAX_AMOUNT", str(tax_amount))

	gosub display_fields
[[OPE_ORDTOTALS.DISCOUNT_AMT.AVAL]]
print "DISCOUNT_AMT.AVAL"; rem debug

rem --- Save discount and recalculate tax

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
	discount_amt = num(callpoint!.getUserInput())
	callpoint!.setColumnData("OPE_ORDTOTALS.DISCOUNT_AMT", str(discount_amt))
	freight_amt = num(callpoint!.getColumnData("OPE_ORDTOTALS.FREIGHT_AMT"))
	tax_amount = ordHelp!.calculateTax(discount_amt, freight_amt,num(callpoint!.getColumnData("OPE_ORDTOTALS.TOTAL_SALES")))
	callpoint!.setColumnData("OPE_ORDTOTALS.TAX_AMOUNT", str(tax_amount))

	gosub display_fields
	
[[OPE_ORDTOTALS.<CUSTOM>]]
rem ==========================================================================
tax_calc: rem --- Calculate tax amount
          rem      IN: discount_amt
          rem          ordHelp!
          rem          taxcode dev, rec$, and rec2$
          rem     OUT: tax_amount
rem ==========================================================================

	print "in tax_calc..."; rem debug
	print "---taxable amount in:", ordHelp!.getTaxable(); rem debug
	print "---discount amount in:", discount_amt

	rem if ordHelp!.getTaxable() <> 0 then 
	rem 	taxable_amt = round(ordHelp!.getTaxable() - disc_per_in * ordHelp!.getTaxable() / 100, 2)
	rem else
	rem 	taxable_amt = 0
	rem endif

	taxable_amt = max(ordHelp!.getTaxable() - discount_amt, 0)
	print "---taxable amount after discount:", taxable_amt; rem debug

	if taxcode_rec.tax_frt_flag$ = "Y" then 
		taxable_amt = taxable_amt + num(callpoint!.getColumnData("OPE_ORDTOTALS.FREIGHT_AMT"))
	endif

	rem print "---taxable amount after tax freight:", taxable_amt; rem debug

	tax_amount = 0
	tax_calc = round(taxcode_rec.tax_rate * taxable_amt / 100, 2)

	print "---Top level tax amount:", tax_calc; rem debug

	if taxcode_rec.op_max_limit <> 0 and abs(tax_calc) > taxcode_rec.op_max_limit then
		tax_calc = taxcode_rec.op_max_limit * sgn(tax_calc)
	endif

	rem print "---tax amount after limit:", tax_calc; rem debug

	tax_amount = tax_calc

	for i=1 to 10
		tax_code$ = field(taxcode_rec$, "AR_TOT_CODE_" + str(i:"00"))
		if cvs(tax_code$,2) = "" then continue
		find record (taxcode_dev, key=firm_id$+tax_code$, dom=*continue) taxcode_rec2$
		tax_calc = round(taxcode_rec2.tax_rate * taxable_amt / 100, 2)

		if taxcode_rec2.op_max_limit <> 0 and abs(tax_calc) > taxcode_rec2.op_max_limit then
			tax_calc = taxcode_rec2.op_max_limit * sgn(tax_calc)
		endif

		tax_amount = tax_amount + tax_calc
	next i

	print "---tax amount after all levels:", tax_amount; rem debug

	callpoint!.setColumnData("OPE_ORDTOTALS.TAX_AMOUNT", str(tax_amount))
	callpoint!.setStatus("REFRESH")

	print "out"; rem debug

	return

rem ==========================================================================
get_sales_tax: rem --- Get sales tax
               rem     OUT: taxcode_rec$
rem ==========================================================================

	file_name$ = "OPC_TAXCODE"
	taxcode_dev = fnget_dev(file_name$)
	dim taxcode_rec$:fnget_tpl$(file_name$)
	dim taxcode_rec2$:fnget_tpl$(file_name$)
	find record (taxcode_dev, key=firm_id$+user_tpl.tax_code$, dom=*next) taxcode_rec$

	return

rem ==========================================================================
send_back_values: rem --- Send back the entered values
rem ==========================================================================

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))

	ordHelp!.setFreight(   num(callpoint!.getColumnData("OPE_ORDTOTALS.FREIGHT_AMT")) )
	ordHelp!.setDiscount(  num(callpoint!.getColumnData("OPE_ORDTOTALS.DISCOUNT_AMT")) )
	ordHelp!.setTaxAmount( num(callpoint!.getColumnData("OPE_ORDTOTALS.TAX_AMOUNT")) )

	callpoint!.setDevObject("tax_amt",callpoint!.getColumnData("OPE_ORDTOTALS.TAX_AMOUNT"))
	callpoint!.setDevObject("disc_amt",callpoint!.getColumnData("OPE_ORDTOTALS.DISCOUNT_AMT"))
	callpoint!.setDevObject("frt_amt",callpoint!.getColumnData("OPE_ORDTOTALS.FREIGHT_AMT"))
	return

rem ==========================================================================
display_fields: rem --- Display net sales and subtotal
                rem      IN: discount_amt
                rem          ordHelp!
                rem          freight_amt
                rem          tax_amount
rem ==========================================================================

	tax_amt = num(callpoint!.getColumnData("OPE_ORDTOTALS.TAX_AMOUNT"))
	net_sales = ordHelp!.getExtPrice() - discount_amt + tax_amount + freight_amt
	callpoint!.setColumnData("<<DISPLAY>>.SUBTOTAL", str(ordHelp!.getExtPrice() - discount_amt))
	callpoint!.setColumnData("<<DISPLAY>>.NET_SALES", str(net_sales))
	callpoint!.setStatus("REFRESH")

	return

rem ==========================================================================
calc_disc_per: rem --- Calculate discount percent
               rem      IN: discount_amt
               rem     OUT: disc_per_in
rem *** NOTE! *** disc_per_in is currently not used; was used in tax_calc
rem ==========================================================================

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))

	if ordHelp!.getExtPrice() <> 0 then 
		disc_per_in = round(100 * discount_amt / ordHelp!.getExtPrice(), 2)
	else
		disc_per_in = 0
	endif

	return
