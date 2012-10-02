[[OPE_INVDET.LINE_CODE.BINP]]
user_tpl.prev_line_code$ = callpoint!.getColumnData("OPE_INVDET.LINE_CODE")
[[OPE_INVDET.ITEM_ID.BINP]]
user_tpl.prev_item$ = callpoint!.getColumnData("OPE_INVDET.ITEM_ID")
[[OPE_INVDET.QTY_ORDERED.BINP]]
user_tpl.prev_qty_ord = num(callpoint!.getColumnData("OPE_INVDET.QTY_ORDERED"))
[[OPE_INVDET.QTY_SHIPPED.BINP]]
user_tpl.prev_shipqty = num(callpoint!.getColumnData("OPE_INVDET.QTY_SHIPPED"))
[[OPE_INVDET.QTY_BACKORD.BINP]]
user_tpl.prev_boqty = num(callpoint!.getColumnData("OPE_INVDET.QTY_BACKORD"))
[[OPE_INVDET.BWRI]]
print "Det:BWRI"; rem debug

rem --- Set values based on line type

	file$ = "OPC_LINECODE"
	dim linecode_rec$:fnget_tpl$(file$)
	line_code$ = callpoint!.getColumnData("OPE_INVDET.LINE_CODE")

	find record(fnget_dev(file$), key=firm_id$+line_code$) linecode_rec$

rem --- If line type is Memo, clear the extended price

	if linecode_rec.line_type$ = "M" then 
		callpoint!.setColumnData("OPE_INVDET.EXT_PRICE", "0")
	endif

rem --- Clear quantities if line type is Memo or Other

	if pos(linecode_rec.line_type$="MO") then
		callpoint!.setColumnData("OPE_INVDET.QTY_ORDERED", "0")
		callpoint!.setColumnData("OPE_INVDET.QTY_BACKORD", "0")
		callpoint!.setColumnData("OPE_INVDET.QTY_SHIPPED", "0")
	endif

rem --- Set product types for certain line types 

	if pos(linecode_rec.line_type$="NOP") then
		if linecode_rec.prod_type_pr$ = "D" then			
			callpoint!.setColumnData("OPE_INVDET.PRODUCT_TYPE", linecode_rec.product_type$)
		else
			if linecode_rec.prod_type_pr$ = "N" then
				callpoint!.setColumnData("OPE_INVDET.PRODUCT_TYPE", "")
			endif
		endif
	endif
[[OPE_INVDET.EXT_PRICE.AVAL]]
rem --- Round 

	callpoint!.setUserInput( str(round(num(callpoint!.getUserInput()), 2)) )
[[OPE_INVDET.WAREHOUSE_ID.AVEC]]
print "Det:WAREHOUSE_ID.AVEC"; rem debug

rem --- Set Recalc Price button

	gosub enable_repricing
[[OPE_INVDET.ITEM_ID.AVEC]]
print "Det:ITEM_ID.AVEC"; rem debug

rem --- Set buttons

	gosub enable_repricing
	gosub able_lot_button

rem --- Set item tax flag

	gosub set_item_taxable
[[OPE_INVDET.AOPT-RCPR]]
rem --- Reprice

	if pos(user_tpl.line_type$="SP") then
		qty_ord = num(callpoint!.getColumnData("OPE_INVDET.QTY_ORDERED"))
		if qty_ord then gosub pricing
	endif
[[OPE_INVDET.STD_LIST_PRC.AVAL]]
rem --- Disable Recalc Price button

	callpoint!.setOptionEnabled("RCPR",0)
[[OPE_INVDET.STD_LIST_PRC.BINP]]
rem --- Enable the Recalc Price button

	callpoint!.setOptionEnabled("RCPR",1)
[[OPE_INVDET.AWRI]]
print "Det:AWRI"; rem debug

rem --- Commit inventory

rem --- Is this row deleted?

	if callpoint!.getGridRowModifyStatus( callpoint!.getValidationRow() ) <> "Y" then 
		break; rem --- exit callpoint
	endif

rem --- Get current and prior values

	curr_whse$ = callpoint!.getColumnData("OPE_INVDET.WAREHOUSE_ID")
	curr_item$ = callpoint!.getColumnData("OPE_INVDET.ITEM_ID")
	curr_qty   = num(callpoint!.getColumnData("OPE_INVDET.QTY_ORDERED"))

	prior_whse$ = callpoint!.getColumnUndoData("OPE_INVDET.WAREHOUSE_ID")
	prior_item$ = callpoint!.getColumnUndoData("OPE_INVDET.ITEM_ID")
	prior_qty   = num(callpoint!.getColumnUndoData("OPE_INVDET.QTY_ORDERED"))

rem --- Has there been any change?

	if	curr_whse$ <> prior_whse$ or 
:		curr_item$ <> prior_item$ or 
:		curr_qty   <> prior_qty
:	then

rem --- Initialize inventory item update

		status=999
		call user_tpl.pgmdir$+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
		if status then exitto std_exit

rem --- Items or warehouses are different: uncommit previous

		if (prior_whse$<>"" and prior_whse$<>curr_whse$) or 
:		   (prior_item$<>"" and prior_item$<>curr_item$)
:		then

rem --- Uncommit prior item and warehouse

			if prior_whse$<>"" and prior_item$<>"" and prior_qty<>0 then
				items$[1] = prior_whse$
				items$[2] = prior_item$
				refs[0]   = prior_qty

				print "---Uncommit: item = ", cvs(items$[2], 2), ", WH: ", items$[1], ", qty =", refs[0]; rem debug
				
				call user_tpl.pgmdir$+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				if status then exitto std_exit
			endif

rem --- Commit quantity for current item and warehouse

			if curr_whse$<>"" and curr_item$<>"" and curr_qty<>0 then
				items$[1] = curr_whse$
				items$[2] = curr_item$
				refs[0]   = curr_qty 

				print "-----Commit: item = ", cvs(items$[2], 2), ", WH: ", items$[1], ", qty =", refs[0]; rem debug

				call user_tpl.pgmdir$+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				if status then exitto std_exit
			endif

		endif

rem --- New record or item and warehouse haven't changed: commit difference

		if	(prior_whse$="" or prior_whse$=curr_whse$) and 
:			(prior_item$="" or prior_item$=curr_item$) 
:		then

rem --- Commit quantity for current item and warehouse

			if curr_whse$<>"" and curr_item$<>"" and curr_qty - prior_qty <> 0
				items$[1] = curr_whse$
				items$[2] = curr_item$
				refs[0]   = curr_qty - prior_qty

				print "-----Commit: item = ", cvs(items$[2], 2), ", WH: ", items$[1], ", qty =", refs[0]; rem debug

				call user_tpl.pgmdir$+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				if status then exitto std_exit
			endif

		endif

	endif

rem --- Update header

	gosub disp_grid_totals

rem input "Det:Done with AWRI: ", *; rem debug
[[OPE_INVDET.AGDS]]
print "Det:AGDS"; rem debug

rem --- Disable Back orders if necessary

	cust_id$   = callpoint!.getColumnData("OPE_INVDET.CUSTOMER_ID")
	cash_sale$ = callpoint!.getHeaderColumnData("OPE_INVHDR.CASH_SALE")

	if user_tpl.allow_bo$ = "N"        or
:		pos(user_tpl.line_type$ = "MO") or
:		cash_sale$ = "Y"
:	then
		util.disableGridColumn(Form!, user_tpl.bo_col)
		print "---BO Disabled"; rem debug
	else
[[OPE_INVDET.BDGX]]
print "Det:BDGX"; rem debug

rem --- Disable detail-only buttons

	callpoint!.setOptionEnabled("LENT",0)
	callpoint!.setOptionEnabled("RCPR",0)
[[OPE_INVDET.AGCL]]
print "Det:AGCL"; rem debug

rem --- Set detail defaults and disabled columns

	callpoint!.setTableColumnAttribute("OPE_INVDET.LINE_CODE","DFLT", user_tpl$.line_code$)
	callpoint!.setTableColumnAttribute("OPE_INVDET.WAREHOUSE_ID","DFLT", user_tpl.warehouse_id$)

	if user_tpl.skip_ln_code$ = "Y" then
		callpoint!.setColumnEnabled(-1, "OPE_INVDET.LINE_CODE", 0)
		rem debug: which row are we on?
		rem line_code$ = user_tpl$.line_code$
		rem gosub disable_by_linetype
	endif

	if user_tpl.skip_whse$ = "Y" then
		callpoint!.setColumnEnabled(-1, "OPE_INVDET.WAREHOUSE_ID", 0)
		item$ = callpoint!.getColumnData("OPE_INVDET.ITEM_ID")
		wh$   = user_tpl.warehouse_id$
		gosub set_avail	
	endif

rem --- Did we change rows?

	currRow = callpoint!.getValidationRow()

	if currRow <> user_tpl.cur_row
		gosub clear_avail
		user_tpl.cur_row = currRow

		item$ = callpoint!.getColumnData("OPE_INVDET.ITEM_ID")
		wh$   = callpoint!.getColumnData("OPE_INVDET.WAREHOUSE_ID")
		gosub set_avail
	endif
[[OPE_INVDET.AOPT-LENT]]
rem --- Save current row/column so we'll know where to set focus when we return from lot lookup

	declare BBjStandardGrid grid!
	grid! = util.getGrid(Form!)
	return_to_row = grid!.getSelectedRow()
	return_to_col = grid!.getSelectedColumn()

rem --- Go get Lot Numbers

	ivm_itemmast_dev = fnget_dev("IVM_ITEMMAST")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")

	item$ = callpoint!.getColumnData("OPE_INVDET.ITEM_ID")
	read record (ivm_itemmast_dev, key=firm_id$+item$, dom=*next) ivm_itemmast$

rem --- Is this item lot/serial?

	if ivm_itemmast.lotser_item$ = "Y" and ivm_itemmast.inventoried$ = "Y"
		callpoint!.setOptionEnabled("LENT",0)
		callpoint!.setDevObject("int_seq", callpoint!.getColumnData("OPE_INVDET.INTERNAL_SEQ_NO"))
		callpoint!.setDevObject("wh",      callpoint!.getColumnData("OPE_INVDET.WAREHOUSE_ID"))
		callpoint!.setDevObject("item",    callpoint!.getColumnData("OPE_INVDET.ITEM_ID"))
		callpoint!.setDevObject("ord_qty", callpoint!.getColumnData("OPE_INVDET.QTY_ORDERED"))

		ar_type$ = "  "
		cust$    = callpoint!.getColumnData("OPE_INVDET.CUSTOMER_ID")
		order$   = callpoint!.getColumnData("OPE_INVDET.ORDER_NO")
		int_seq$ = callpoint!.getColumnData("OPE_INVDET.INTERNAL_SEQ_NO")

		if cvs(cust$,2) <> ""
			grid!.focus()
			dim dflt_data$[3,1]
			dflt_data$[1,0] = "AR_TYPE"
			dflt_data$[1,1] = ar_type$
			dflt_data$[2,0] = "CUSTOMER_ID"
			dflt_data$[2,1] = cust$
			dflt_data$[3,0] = "ORDER_NO"
			dflt_data$[3,1] = order$
			lot_pfx$ = firm_id$+ar_type$+cust$+order$+int_seq$

			call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:				"OPE_ORDLSDET", 
:				stbl("+USER_ID"), 
:				"MNT", 
:				lot_pfx$, 
:				table_chans$[all], 
:				dflt_data$[all]

rem --- return focus to where we were (Detail line grid)

			util.forceEdit(Form!, return_to_row, return_to_col)
		endif
	endif
[[OPE_INVDET.BUDE]]
print "Det:BUDE"; rem debug

rem --- add and recommit Lot/Serial records (if any) and detail lines if not

	if callpoint!.getColumnData("OPE_INVDET.COMMIT_FLAG")="Y"
		action$="CO"
		gosub uncommit_iv
	endif
[[OPE_INVDET.AREC]]
print "Det:AREC"; rem debug

rem --- Disable skipped columns (debug: disabled, line code won't be set yet)

	rem line_code$ = callpoint!.getColumnData("OPE_INVDET.LINE_CODE")
	rem gosub disable_by_linetype

rem --- Backorder is zero and disabled on a new record

	user_tpl.new_detail = 1
	callpoint!.setColumnData("OPE_INVDET.QTY_BACKORD", "0")
	callpoint!.setColumnEnabled("OPE_INVDET.QTY_BACKORD", 0)
	print "---BO cleared and disabled"

rem --- Set defaults for new record

	inv_type$  = callpoint!.getHeaderColumnData("OPE_INVHDR.INVOICE_TYPE")
	ship_date$ = callpoint!.getHeaderColumnData("OPE_INVHDR.SHIPMNT_DATE")

	callpoint!.setColumnData("OPE_INVDET.MAN_PRICE", "N")
	callpoint!.setColumnData("OPE_INVDET.EST_SHP_DATE", ship_date$)
	
	if inv_type$ = "P" or ship_date$ > user_tpl.def_commit$ then
 		callpoint!.setColumnData("OPE_INVDET.COMMIT_FLAG", "N")
		callpoint!.setColumnEnabled("OPE_INVDET.QTY_SHIPPED", "0")
		print "--- Shipped disabled, commit flag is N"; rem debug
	else
		callpoint!.setColumnData("OPE_INVDET.COMMIT_FLAG", "Y")
 	endif

rem --- Enable/disable backorder

	gosub able_backorder

	callpoint!.setStatus("REFRESH")
[[OPE_INVDET.BDEL]]
print "Det:BDEL"; rem debug

rem --- remove and uncommit Lot/Serial records (if any) and detail lines if not

	if callpoint!.getColumnData("OPE_INVDET.COMMIT_FLAG")="Y"
		action$="UC"
		gosub uncommit_iv
	endif
[[OPE_INVDET.UNIT_PRICE.AVEC]]
rem --- Update header

	gosub disp_grid_totals

rem --- Recalc and display extended price

	gosub disp_ext_amt
[[OPE_INVDET.AGRN]]
print "Det:AGRN"; rem debug

rem (fires regardles of new or existing row)

rem --- Set line type

	line_code$ = callpoint!.getColumnData("OPE_INVDET.LINE_CODE")
	gosub disable_by_linetype

rem --- Disable cost if necessary

	if pos(user_tpl.line_type$="SP") and num(callpoint!.getColumnData("OPE_INVDET.UNIT_COST")) then
		callpoint!.setColumnEnabled("OPE_INVDET.UNIT_COST", 0)
	endif

rem --- Set enable/disable based on line type

	gosub able_backorder

rem --- Disable Shipped?

	if callpoint!.getColumnData("OPE_INVDET.COMMIT_FLAG") = "N" then
		callpoint!.setColumnEnabled("OPE_INVDET.QTY_SHIPPED", 0)
		print "---Shipped disabled, commit flag is N"; rem debug
	endif

rem --- Set item tax flag

	gosub set_item_taxable

rem --- Set item price if item and whse exist

	item$ = callpoint!.getColumnData("OPE_INVDET.ITEM_ID")
	wh$   = callpoint!.getColumnData("OPE_INVDET.WAREHOUSE_ID")

	if item$<>"" and wh$<>"" then
		file$ = "IVM_ITEMWHSE"
		dim itemwhse$:fnget_tpl$(file$)
		start_block = 1
		
		if start_block then
			find record (fnget_dev(file$), key=firm_id$+wh$+item$, dom=*endif) itemwhse$
			user_tpl.item_price = itemwhse.cur_price
		endif
	endif

rem --- Set buttons

	gosub enable_repricing
	gosub able_lot_button
[[OPE_INVDET.AGRE]]
print "Det:AGRE"; rem debug

rem --- Has customer credit been exceeded?

	gosub calc_grid_totals
	ext_price      = num(callpoint!.getColumnData("OPE_INVDET.EXT_PRICE"))
	prev_ext_price = num(callpoint!.getColumnUndoData("OPE_INVDET.EXT_PRICE"))
	
	if user_tpl.balance + ext_price - prev_ext_price + tamt > user_tpl.credit_limit then 
		gosub credit_exceeded
	endif

rem --- Check for minimum line extension

	commit_flag$    = callpoint!.getColumnData("OPE_INVDET.COMMIT_FLAG")
	qty_backordered = num(callpoint!.getColumnData("OPE_INVDET.QTY_BACKORD"))

	if user_tpl.line_type$ <> "M" and 
:		qty_backorderd = 0         and 
:		commit_flag$ = "Y"         and
:		abs(ext_price) < user_tpl.min_line_amt 
:	then
		msg_id$ = "OP_LINE_UNDER_MIN"
		dim msg_tokens$[1]
		msg_tokens$ = str(user_tpl.min_line_amt:user_tpl.amount_mask$)
		gosub disp_message
	endif
	
rem --- Warehouse and Item must be correct

	wh$   = callpoint!.getColumnData("OPE_INVDET.WAREHOUSE_ID")
	item$ = callpoint!.getColumnData("OPE_INVDET.ITEM_ID")
	warn  = 1

	print "---Checking item/wh..."; rem debug
	gosub check_item_whse	

	if failed then 
		callpoint!.setStatus("ABORT")
	else

	rem --- Set objects (why?)

		rem callpoint!.setDevObject("int_seq", callpoint!.getColumnData("OPE_INVDET.INTERNAL_SEQ_NO"))
		rem callpoint!.setDevObject("wh",      callpoint!.getColumnData("OPE_INVDET.WAREHOUSE_ID"))
		rem callpoint!.setDevObject("item",    callpoint!.getColumnData("OPE_INVDET.ITEM_ID"))
		rem callpoint!.setDevObject("ord_qty", callpoint!.getColumnData("OPE_INVDET.QTY_ORDERED"))

	rem --- Clear line type

		user_tpl.line_type$ = ""

	endif

rem --- Set taxable amount

	if user_tpl.line_taxable$ = "Y" and 
:		( pos(user_tpl.line_type$ = "OMN") or user_tpl.item_taxable$ = "Y" ) 
:	then 
		callpoint!.setColumnData("OPE_INVDET.TAXABLE_AMT", str(ext_price))
	endif

rem --- Set price and discount

	std_price  = num(callpoint!.getColumnData("OPE_INVDET.STD_LIST_PRC"))
	disc_per   = num(callpoint!.getColumnData("OPE_INVDET.DISC_PERCENT"))
	unit_price = num(callpoint!.getColumnData("OPE_INVDET.UNIT_PRICE"))
	
	if std_price then
		callpoint!.setColumnData("OPE_INVDET.DISC_PERCENT", str(100 - unit_price * 100 / std_price))
	else
		if disc_per <> 100 then
			callpoint!.setColumnData("OPE_INVDET.STD_LIST_PRC", str(unit_price * 100 / (100 - disc_per)) )
		endif
	endif
	
rem --- Set amounts for non-commited "other" type detail lines

	ext_price = num(callpoint!.getColumnData("OPE_INVDET.EXT_PRICE"))

	if callpoint!.getHeaderColumnData("OPE_INVHDR.INVOICE_TYPE") <> "P" and
:		callpoint!.getColumnData("OPE_INVDET.COMMIT_FLAG") = "N"         and
:		user_tpl.line_type$ = "O"                                        and
:		ext_price <> 0
:	then
		callpoint!.setColumnData("OPE_INVDET.UNIT_PRICE", str(ext_price))
		callpoint!.setColumnData("OPE_INVDET.EXT_PRICE", "0")
		callpoint!.setColumnData("OPE_INVDET.TAXABLE_AMT", "0")
	endif
[[OPE_INVDET.UNIT_COST.AVAL]]
rem --- Disable Cost field if there is a value in it
rem g!=form!.getChildWindow(1109).getControl(5900)
rem enable_color!=g!.getCellBackColor(0,0)
rem disable_color!=g!.getLineColor()

rem r=g!.getSelectedRow()
rem if num(callpoint!.getUserInput())=0
rem 	g!.setCellEditable(r,5,1)
rem	g!.setCellBackColor(r,5,enable_color!)
rem else
rem 	g!.setCellEditable(r,5,0)
rem 	g!.setCellBackColor(r,5,disable_color!)
rem endif
[[OPE_INVDET.EXT_PRICE.AVEC]]
rem --- Update header

	gosub disp_grid_totals
[[OPE_INVDET.UNIT_PRICE.AVAL]]
rem --- See if this should be repriced
rem 	if num(callpoint!.getUserInput())<0
rem 		dim op_chans[6]
rem 		op_chans[1]=fnget_dev("IVM_ITEMMAST")
rem 		op_chans[2]=fnget_dev("IVM_ITEMWHSE")
rem 		op_chans[4]=fnget_dev("IVM_ITEMPRIC")
rem 		op_chans[5]=fnget_dev("ARS_PARAMS")
rem 		op_chans[6]=fnget_dev("IVS_PARAMS")
rem 		whs$=callpoint!.getColumnData("OPE_INVDET.WAREHOUSE_ID")
rem 		item$=callpoint!.getColumnData("OPE_INVDET.ITEM_ID")
rem 		listcd$=""
rem 		cust$=callpoint!.getColumnData("OPE_INVDET.CUSTOMER_ID")
rem 		date$=user_tpl.order_date$
rem 		priccd$=user_tpl.price_code$
rem 		ordqty=num(callpoint!.getColumnData("OPE_INVDET.QTY_ORDERED"))
rem 		type_price$=""
rem 		call stbl("+DIR_PGM")+"opc_pc.aon",op_chans[all],firm_id$,whs$,item$,listcd$,cust$,date$,priccd$,ordqty,type_price$,price,disc,status
rem 		callpoint!.setUserInput(str(price))
rem 	endif

	gosub disp_ext_amt
	gosub disp_grid_totals
[[OPE_INVDET.AUDE]]
print "Det:AUDE"; rem debug

rem --- redisplay totals

	gosub disp_grid_totals
[[OPE_INVDET.ADEL]]
print "Det:ADEL"; rem debug

rem --- redisplay totals

	gosub disp_grid_totals
[[OPE_INVDET.WAREHOUSE_ID.AVAL]]
print "Det:WAREHOUSE_ID.AVAL"; rem debug

rem --- Check item/warehouse combination, Set Available

	item$ = callpoint!.getColumnData("OPE_INVDET.ITEM_ID")
	wh$   = callpoint!.getUserInput()
	warn  = 1

rem Item probably isn't set yet, but we don't know

	if cvs(item$, 2)<>"" then
		gosub check_item_whse
		if !failed then gosub set_avail
	endif
[[OPE_INVDET.ITEM_ID.AVAL]]
print "Det:ITEM_ID.AVAL"; rem debug

rem --- Check item/warehouse combination and setup values

	start_block = 1
	item$ = callpoint!.getUserInput()
	wh$   = callpoint!.getColumnData("OPE_INVDET.WAREHOUSE_ID")

	if item$<>user_tpl.prev_item$ then
		gosub clear_all_numerics
	endif

	if cvs(item$, 2)<>"" then
		warn = 1
		gosub check_item_whse

		if !failed then 
			gosub set_avail
			callpoint!.setColumnData("OPE_INVDET.UNIT_COST", ivm02a.unit_cost$)
			callpoint!.setColumnData("OPE_INVDET.STD_LIST_PRC", ivm02a.cur_price$)
			callpoint!.setColumnData("OPE_INVDET.PRODUCT_TYPE", ivm01a.product_type$)
			user_tpl.item_price = ivm02a.cur_price
			callpoint!.setStatus("REFRESH")
		endif
	endif
[[OPE_INVDET.QTY_ORDERED.AVEC]]
print "Det:QTY_ORDERED.AVEC"; rem debug

rem --- Set shipped and back ordered

	qty_ord    = num(callpoint!.getColumnData("OPE_INVDET.QTY_ORDERED"))
	unit_price = num(callpoint!.getColumnData("OPE_INVDET.UNIT_PRICE"))

	if qty_ord<>user_tpl.prev_qty_ord or unit_price = 0 then

		if qty_ord<>user_tpl.prev_qty_ord then
			callpoint!.setColumnData("OPE_INVDET.QTY_BACKORD", "0")
			print "---Backord cleared"; rem debug

			if callpoint!.getColumnData("OPE_INVDET.COMMIT_FLAG") = "Y" or
:				callpoint!.getHeaderColumnData("OPE_INVHDR.INVOICE_TYPE") = "P"
:			then
				callpoint!.setColumnData("OPE_INVDET.QTY_SHIPPED", str(qty_ord))
				print "---Shipped set to", qty_ord; rem debug
			else
				callpoint!.setColumnData("OPE_INVDET.QTY_SHIPPED", "0")
				print "---Shipped cleared"; rem debug
			endif
		endif

rem --- Recalc quantities and extended price

		if qty_ord and unit_price = 0 and user_tpl.line_type$ <> "N" then
			gosub pricing
		endif

		gosub disp_ext_amt

	endif

rem --- Update header

	gosub disp_grid_totals

rem --- Set Lot/Serial button up properly

	gosub able_lot_button

rem --- Set Recalc Price button

	gosub enable_repricing

rem --- Remove lot records if qty goes to 0 (lotted$ set in able_lot_button)

	if lotted$="Y" then
		rem *** do lotted logic
	endif
[[OPE_INVDET.ADIS]]
rem ---display extended price
	ordqty=num(rec_data.qty_ordered)
	unit_price=num(rec_data.unit_price)
	new_ext_price=ordqty*unit_price
	callpoint!.setColumnData("OPE_INVDET.EXT_PRICE",str(new_ext_price))
	callpoint!.setStatus("MODIFIED-REFRESH")
[[OPE_INVDET.QTY_SHIPPED.AVAL]]
print "Det:QTY_SHIPPED.AVAL"; rem debug

rem --- recalc quantities and extended price

	shipqty    = num(callpoint!.getUserInput())
	ordqty     = num(callpoint!.getColumnData("OPE_INVDET.QTY_ORDERED"))
	cash_sale$ = callpoint!.getHeaderColumnData("OPE_INVHDR.CASH_SALE")

print "---Shipped:", shipqty; rem debug
print "---Prev   :", user_tpl.prev_shipqty
print "---Ordered:", ordqty

	if shipqty > ordqty then 
		callpoint!.setUserInput(str(user_tpl.prev_shipqty))
		msg_id$="SHIP_EXCEEDS_ORD"
		gosub disp_message
		callpoint!.setStatus("ABORT-REFRESH")
		break; rem --- exit callpoint
	endif

	if user_tpl.allow_bo$ = "N" or cash_sale$ = "Y" then
		callpoint!.setColumnData("OPE_INVDET.QTY_BACKORD", "0")
		print "---BO set to zero"; rem debug
	else
		if user_tpl.prev_shipqty <> shipqty then
			callpoint!.setColumnData("OPE_INVDET.QTY_BACKORD", str(max(0, ordqty - shipqty)) )
			print "---BO set to", max(0, ordqty - shipqty); rem debug
		endif
	endif

rem --- update header

	gosub disp_grid_totals
[[OPE_INVDET.QTY_BACKORD.AVAL]]
print "Det:QTY_BACKORD.AVAL"; rem debug

rem --- Recalc quantities and extended price

	boqty  = num(callpoint!.getUserInput())
	ordqty = num(callpoint!.getColumnData("OPE_INVDET.QTY_ORDERED"))

print "--- BO qty:", boqty; rem debug
print "---Prev BO:", user_tpl.prev_boqty
print "---Ord Qty:", ordqty

	if boqty > ordqty then
		callpoint!.setUserInput(str(user_tpl.prev_boqty))
		msg_id$ = "BO_EXCEEDS_ORD"
		gosub disp_message
		callpoint!.setStatus("ABORT-REFRESH")
		break; rem --- exit callpoint
	endif

	if boqty = 0 and !user_tpl.new_detail then
		callpoint!.setUserInput(str(ordqty))
		print "---Bo qty set to ordered:", ordqty; rem debug
		boqty = ordqty
	endif

	if boqty <> user_tpl.prev_boqty then
		callpoint!.setColumnData("OPE_INVDET.QTY_SHIPPED", str(ordqty - boqty))
		print "---Shipped set to:", ordqty - boqty; rem debug
		gosub disp_ext_amt
	endif

rem --- Update header

	gosub disp_grid_totals
[[OPE_INVDET.<CUSTOM>]]
rem ==========================================================================
disp_grid_totals: rem --- Get order totals and display, save header totals
rem ==========================================================================

	gosub calc_grid_totals

	tamt! = UserObj!.getItem(num(user_tpl.ord_tot_1$))
	tamt!.setValue(user_tpl.ord_tot)
	callpoint!.setHeaderColumnData("OPE_INVHDR.TOTAL_SALES", user_tpl.ord_tot$)
	callpoint!.setStatus("REFRESH")

return

rem ==========================================================================
calc_grid_totals: rem --- Roll thru all detail line, totaling ext_price
                  rem     OUT: user_tpl.ord_tot
rem ==========================================================================

	print "Det: in calc_grid_totals"; rem debug

	recVect! = GridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs = recVect!.size()
	tamt = 0

	if numrecs>0 then 

		for reccnt=0 to numrecs-1
			gridrec$ = recVect!.getItem(reccnt)

			if cvs(gridrec$,3)<>"" then 
				if callpoint!.getGridRowDeleteStatus(reccnt)<>"Y" then 
					opc_linecode_dev = fnget_dev("OPC_LINECODE")
					dim opc_linecode$:fnget_tpl$("OPC_LINECODE")
					read record (opc_linecode_dev, key=firm_id$+gridrec.line_code$, dom=*next) opc_linecode$

					if pos(opc_linecode.line_code$="SPN") then
						tamt = tamt + (gridrec.unit_price * gridrec.qty_ordered)
					else
						tamt = tamt + gridrec.ext_price
					endif
				endif
			endif
		next reccnt

		user_tpl.ord_tot = tamt
		print "---Order Total:", tamt; rem debug
	endif

return

rem ==========================================================================
pricing: rem --- Call Pricing routine
         rem      IN: qty_ord
         rem     OUT: price (UNIT_PRICE), disc (DISC_PERCENT), STD_LINE_PRC
rem ==========================================================================

print "Det:in pricing"; rem debug

	wh$      = callpoint!.getColumnData("OPE_INVDET.WAREHOUSE_ID")
	item$    = callpoint!.getColumnData("OPE_INVDET.ITEM_ID")
	ar_type$ = callpoint!.getColumnData("OPE_INVDET.AR_TYPE")
	cust$    = callpoint!.getColumnData("OPE_INVDET.CUSTOMER_ID")
	ord$     = callpoint!.getColumnData("OPE_INVDET.ORDER_NO")

	if cvs(item$, 2)="" or cvs(wh$, 2)="" then 
		callpoint!.setStatus("ABORT")
		return
	endif

	warn = 0
	gosub check_item_whse

	if failed then 
		callpoint!.setStatus("ABORT")
		return
	endif

	dim pc_files[6]
	pc_files[1] = fnget_dev("IVM_ITEMMAST")
	pc_files[2] = fnget_dev("IVM_ITEMWHSE")
	pc_files[3] = fnget_dev("IVM_ITEMPRIC")
	pc_files[4] = fnget_dev("IVC_PRICCODE")
	pc_files[5] = fnget_dev("ARS_PARAMS")
	pc_files[6] = fnget_dev("IVS_PARAMS")

	call stbl("+DIR_PGM")+"opc_pricing.aon",pc_files[all],firm_id$,wh$,item$,user_tpl.price_code$,cust$,
:		user_tpl.order_date$,user_tpl.pricing_code$,qty_ord,typeflag$,price,disc,status
	if status=999 then exitto std_exit

	if price=0 then
		msg_id$="ENTER_PRICE"
		gosub disp_message
	else
		callpoint!.setColumnData("OPE_INVDET.UNIT_PRICE", str(price))
		callpoint!.setColumnData("OPE_INVDET.DISC_PERCENT", str(disc))
		print "---Unit Price set to", price; rem debug
		print "---Discount set to", disc; rem debug
	endif

	if disc=100 then
		callpoint!.setColumnData("OPE_INVDET.STD_LIST_PRC", str(user_tpl.item_price))
		print "---List Price set to", user_tpl.item_price; rem debug
	else
		callpoint!.setColumnData("OPE_INVDET.STD_LIST_PRC", str((price*100)/(100-disc)) )
		print "---List Price set to", (price*100)/(100-disc); rem debug
	endif

rem --- Recalc and display extended price

	gosub disp_ext_amt

return

rem ==========================================================================
set_avail: rem --- Set data in Availability window
           rem      IN: item$
           rem          wh$
rem ==========================================================================

	dim avail$[6]

	ivm01_dev = fnget_dev("IVM_ITEMMAST")
	dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")

	ivm02_dev = fnget_dev("IVM_ITEMWHSE")
	dim ivm02a$:fnget_tpl$("IVM_ITEMWHSE")

	ivc_whcode_dev = fnget_dev("IVC_WHSECODE")
	dim ivm10c$:fnget_tpl$("IVC_WHSECODE")

	good_item$="N"
	start_block = 1

	if start_block then
		read record (ivm01_dev, key=firm_id$+item$, dom=*endif) ivm01a$
		read record (ivm02_dev, key=firm_id$+wh$+item$, dom=*endif) ivm02a$
		read record (ivc_whcode_dev, key=firm_id$+"C"+wh$, dom=*endif) ivm10c$
		good_item$="Y"
	endif

	if good_item$="Y" then
		avail$[1] = str(ivm02a.qty_on_hand)
		avail$[2] = str(ivm02a.qty_commit)
		avail$[3] = str(ivm02a.qty_on_hand-ivm02a.qty_commit)
		avail$[4] = str(ivm02a.qty_on_order)
		avail$[5] = ivm10c.short_name$
		avail$[6] = ivm01a.item_type$

		userObj!.getItem(num(user_tpl.avail_oh$)).setText(avail$[1])
		userObj!.getItem(num(user_tpl.avail_comm$)).setText(avail$[2])
		userObj!.getItem(num(user_tpl.avail_avail$)).setText(avail$[3])
		userObj!.getItem(num(user_tpl.avail_oo$)).setText(avail$[4])
		userObj!.getItem(num(user_tpl.avail_wh$)).setText(avail$[5])
		userObj!.getItem(num(user_tpl.avail_type$)).setText(avail$[6])

		rem --- Set Drop Ship flag

		dropship_idx = num(user_tpl.dropship_flag$)
		userObj!.getItem(dropship_idx).setText("")

		if user_tpl.line_dropship$="Y"
			userObj!.getItem(dropship_idx).setText("**Drop Ship**")
		endif

	endif

return

rem ==========================================================================
clear_avail: rem --- Clear Availability Window
rem ==========================================================================

	userObj!.getItem(num(user_tpl.avail_oh$)).setText("")
	userObj!.getItem(num(user_tpl.avail_comm$)).setText("")
	userObj!.getItem(num(user_tpl.avail_avail$)).setText("")
	userObj!.getItem(num(user_tpl.avail_oo$)).setText("")
	userObj!.getItem(num(user_tpl.avail_wh$)).setText("")
	userObj!.getItem(num(user_tpl.avail_type$)).setText("")
	userObj!.getItem(num(user_tpl.dropship_flag$)).setText("")

return

rem ==========================================================================
check_new_row: rem --- Check to see if we're on a new row, *** DEPRECATED, see AGCL
rem ==========================================================================

	currRow = callpoint!.getValidationRow()

	if currRow <> user_tpl.cur_row
		gosub clear_avail
		user_tpl.cur_row = currRow
		gosub set_avail
	endif

return

rem ==========================================================================
lot_ser_check: rem --- Check for lotted item
               rem      IN: item$
               rem     OUT: lotted$ - Y/N
               rem          setDevObject - int_seq, wh, item (DISABLED, why needed?)
rem ==========================================================================

	lotted$="N"

	if cvs(item_id$, 2)<>"" and pos(user_tpl.lotser_flag$ = "LS") then 
		ivm01_dev=fnget_dev("IVM_ITEMMAST")
		dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")
		start_block = 1

		if start_block then
			read record (ivm01_dev, key=firm_id$+item$, dom=*endif) ivm01a$

			if ivm01a.lotser_item$="Y" and ivm01a.inventoried$="Y" then
				lotted$="Y"
				rem callpoint!.setDevObject("int_seq", callpoint!.getColumnData("OPE_INVDET.INTERNAL_SEQ_NO"))
				rem callpoint!.setDevObject("wh",      callpoint!.getColumnData("OPE_INVDET.WAREHOUSE_ID")
				rem callpoint!.setDevObject("item",    item$)
			endif
		endif
	endif

return

rem ==========================================================================
retrieve_row_data: rem *** DEPRECATED (not used)
rem ==========================================================================

	currow=callpoint!.getValidationRow()

	mod_stat$=callpoint!.getGridRowModifyStatus(currow)
	new_stat$=callpoint!.getGridRowNewStatus(currow)

	curVect!=gridVect!.getItem(0)
	dim cur_rec$:dtlg_param$[1,3]
	cur_rec$=curVect!.getItem(currow)

	undoVect!=gridVect!.getItem(1)
	dim undo_rec$:dtlg_param$[1,3]
	undo_rec$=curVect!.getItem(currow)

	diskVect!=gridVect!.getItem(2)
	dim disk_rec$:dtlg_param$[1,3]
	disk_rec$=curVect!.getItem(currow)

return

rem ==========================================================================
uncommit_iv: rem --- Uncommit Inventory
rem              --- Make sure action$ is set before entry
rem ==========================================================================

print "Det: in uncommit_iv"; rem deebug

	ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")

	ope_ordlsdet_dev=fnget_dev("OPE_ORDLSDET")
	dim ope_ordlsdet$:fnget_tpl$("OPE_ORDLSDET")

	cust$    = callpoint!.getColumnData("OPE_INVDET.CUSTOMER_ID")
	ar_type$ = callpoint!.getColumnData("OPE_INVDET.AR_TYPE")
	order$   = callpoint!.getColumnData("OPE_INVDET.ORDER_NO")
	seq$     = callpoint!.getColumnData("OPE_INVDET.INTERNAL_SEQ_NO")
	wh$      = callpoint!.getColumnData("OPE_INVDET.WAREHOUSE_ID")
	item$    = callpoint!.getColumnData("OPE_INVDET.ITEM_ID")
	ord_qty  = num(callpoint!.getColumnData("OPE_INVDET.QTY_ORDERED"))

	if cvs(item$, 2)<>"" and cvs(wh$, 2)<>"" and ord_qty then
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
		read record (ivm_itemmast_dev, key=firm_id$+item$, dom=*next) ivm_itemmast$

		items$[1]=wh$
		items$[2]=item$
		refs[0]=ord_qty

		if ivm_itemmast.lotser_item$<>"Y" or ivm_itemmast.inventoried$<>"Y" then
			call stbl("+DIR_PGM")+"ivc_itemupdt.aon",action$,channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
		else
			found_lot=0
			read (ope_ordlsdet_dev, key=firm_id$+ar_type$+cust$+order$+seq$, dom=*next)

			while 1
				read record (ope_ordlsdet_dev, end=*break) ope_ordlsdet$
				if pos(firm_id$+ar_type$+cust$+order$+seq$=ope_ordlsdet$)<>1 then break
				items$[3] = ope_ordlsdet.lotser_no$
				refs[0]   = ope_ordlsdet.qty_ordered
				call stbl("+DIR_PGM")+"ivc_itemupdt.aon",action$,channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				remove (ope_ordlsdet_dev, key=firm_id$+ar_type$+cust$+order$+seq$+ope_ordlsdet.sequence_no$)
				found_lot=1
			wend

			if found_lot=0
				call stbl("+DIR_PGM")+"ivc_itemupdt.aon",action$,channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
			endif
		endif
	endif

return

rem ==========================================================================
disable_linecode_whse: rem --- Disable line code and warehouse columns
                       rem --- These come from parameters and POS records
rem *** DEPRECATED *** Currently not used
rem ==========================================================================

	if user_tpl.skip_ln_code$ = "Y" then
		callpoint!.setColumnEnabled("OPE_INVDET.LINE_CODE", 0)
	endif

	if user_tpl.skip_whse$ = "Y" then
		callpoint!.setColumnEnabled("OPE_INVDET.WAREHOUSE_ID", 0)
	endif

return

rem ==========================================================================
disable_by_linetype: rem --- Set enable/disable based on line type
                     rem --- These work from the CALLPOINT enable in the form
                     rem      IN: line_code$
rem ==========================================================================

print "Det: in disable_by_linetype..."; rem debug

	start_block = 1

	if cvs(line_code$,2) <> "" then
		file$ = "OPC_LINECODE"
		dim opc_linecode$:fnget_tpl$(file$)

		if start_block then
			find record (fnget_dev(file$), key=firm_id$+line_code$, dom=*endif) opc_linecode$
			callpoint!.setStatus("ENABLE:"+opc_linecode.line_type$)

			rem debug
			print "---line code set: """, opc_linecode.line_type$, """"
			if opc_linecode.line_type$ = user_tpl.line_type$ then
				print "---line code was already set"
			else
				print "---line code was: """, user_tpl.line_type$, """"
			endif
			rem debug end

			user_tpl.line_type$     = opc_linecode.line_type$
			user_tpl.line_taxable$  = opc_linecode.taxable_flag$
			user_tpl.line_dropship$ = opc_linecode.dropship$
		endif
	endif

rem --- Disable / enable unit cost

	if pos(user_tpl.line_type$="NSP") = 0 then
		callpoint!.setColumnEnabled("OPE_INVDET.UNIT_COST", 0)
	else
		if user_tpl.line_dropship$ = "Y" and user_tpl.dropship_cost = "N" then
			callpoint!.setColumnEnabled("OPE_INVDET.UNIT_COST", 0)
		else
			if pos(user_tpl.line_type$="SP") and num(callpoint!.getColumnData("OPE_INVDET.UNIT_COST")) = 0
				callpoint!.setColumnEnabled("OPE_INVDET.UNIT_COST", 0)
			endif
		endif
	endif

return

rem ===========================================================================
check_item_whse: rem --- Check that a warehouse record exists for this item
                 rem      IN: wh$
                 rem          item$
                 rem          warn    (1=warn if failed, 0=no warning)
                 rem     OUT: failed  (true/false)
                 rem          ivm02_dev
                 rem          ivm02a$ 
rem ===========================================================================

print "Det: in check_item_whse"; rem debug

	if pos(user_tpl.line_type$="SP") then
		file$ = "IVM_ITEMWHSE"
		ivm02_dev = fnget_dev(file$)
		dim ivm02a$:fnget_tpl$(file$)
		start_block = 1
		
		if start_block then
			failed = 1
			find record (ivm02_dev, key=firm_id$+wh$+item$, dom=*endif) ivm02a$
			failed = 0
		endif

		if failed and warn then callpoint!.setMessage("IV_NO_WHSE_ITEM")
	endif

return

rem ==========================================================================
clear_all_numerics: rem --- Clear all order detail numeric fields
rem ==========================================================================

		callpoint!.setColumnData("OPE_INVDET.UNIT_COST", "0")
		callpoint!.setColumnData("OPE_INVDET.UNIT_PRICE", "0")
		callpoint!.setColumnData("OPE_INVDET.QTY_ORDERED", "0")
		callpoint!.setColumnData("OPE_INVDET.QTY_BACKORD", "0")
		callpoint!.setColumnData("OPE_INVDET.QTY_SHIPPED", "0")
		callpoint!.setColumnData("OPE_INVDET.STD_LIST_PRC", "0")
		callpoint!.setColumnData("OPE_INVDET.EXT_PRICE", "0")
		callpoint!.setColumnData("OPE_INVDET.TAXABLE_AMT", "0")
		callpoint!.setColumnData("OPE_INVDET.DISC_PERCENT", "0")
		callpoint!.setColumnData("OPE_INVDET.COMM_PERCENT", "0")
		callpoint!.setColumnData("OPE_INVDET.COMM_AMT", "0")
		callpoint!.setColumnData("OPE_INVDET.SPL_COMM_PCT", "0")

return

rem ==========================================================================
enable_repricing: rem --- Enable the Recalc Pricing button
rem ==========================================================================

print "Det: in enable_repricing..."; rem debug

	if pos(user_tpl.line_type$="SP") then 
		item$ = callpoint!.getColumnData("OPE_INVDET.ITEM_ID")
		wh$   = callpoint!.getColumnData("OPE_INVDET.WAREHOUSE_ID")
		warn  = 0
		gosub check_item_whse

		if !failed and num(callpoint!.getColumnData("OPE_INVDET.QTY_ORDERED")) then
			callpoint!.setOptionEnabled("RCPR",1)
		endif
	endif

return

rem ==========================================================================
able_lot_button: rem --- Enable/disable Lot/Serial button
                 rem      IN: item$ (for lot_ser_check)
rem ==========================================================================

	item$   = callpoint!.getColumnData("OPE_INVDET.ITEM_ID")
	qty_ord = num(callpoint!.getColumnData("OPE_INVDET.QTY_ORDERED"))
	gosub lot_ser_check

	if pos(user_tpl.lotser_flag$ = "LS") and 
:		qty_ord <> 0                      and
:		lotted$ = "Y"
:	then
		callpoint!.setOptionEnabled("LENT",1)
	else
		callpoint!.setOptionEnabled("LENT",0)
	endif

return

rem ==========================================================================
disp_ext_amt: rem --- Calculate and display the extended amount
rem ==========================================================================

	ord_qty    = num(callpoint!.getColumnData("OPE_INVDET.QTY_ORDERED"))
	unit_price = num(callpoint!.getColumnData("OPE_INVDET.UNIT_PRICE"))
	callpoint!.setColumnData("OPE_INVDET.EXT_PRICE", str(ord_qty * unit_price))
	print "---Ext price set to", ord_qty * unit_price; rem debug
	callpoint!.setStatus("MODIFIED;REFRESH")

return

rem ==========================================================================
set_item_taxable: rem --- Set the item taxable flag
rem ==========================================================================

	if pos(user_tpl.line_type$="SP") then
		item_id$ = callpoint!.getColumnData("OPE_INVDET.ITEM_ID")
		file$    = "IVM_ITEMMAST"
		dim itemmast$:fnget_tpl$(file$)
		start_block = 1

		if start_block then
			find record (fnget_dev(file$), key=firm_id$+item_id$, dom=*endif) itemmast$
			user_tpl.item_taxable$ = itemmast.taxable_flag$
		endif
	endif

return

rem ==========================================================================
credit_exceeded: rem --- Credit Limit Exceeded
rem ==========================================================================

	if user_tpl.credit_limit and user_tpl.never_checked then
		msg_id$ = "OP_OVER_CREDIT_LIMIT"
		dim msg_tokens$[1]
		msg_tokens$[1] = str(user_tpl.credit_limit:user_tpl.amount_mask$)
		gosub disp_message
		callpoint!.setHeaderColumnData("<<DISPLAY>>.CREDIT_HOLD", "*** Over Credit Limit ***")
		user_tpl.never_checked = 0
	endif

return

rem ==========================================================================
able_backorder: rem --- All the factors for enabling or disabling back orders
rem ==========================================================================

	print "Det:in able_backorder"; rem debug	

	if user_tpl.allow_bo$ = "N" or 
:		pos(user_tpl.line_type$="MO") or
:		callpoint!.getColumnData("OPE_INVDET.COMMIT_FLAG") = "N" or
:		user_tpl.is_cash_sale
:	then
		callpoint!.setColumnEnabled("OPE_INVDET.QTY_BACKORD", 0)
		print "---BO disabled"; rem debug
	else
		callpoint!.setColumnEnabled("OPE_INVDET.QTY_BACKORD", 1)
		print "---BO enable"; rem debug

		if user_tpl.new_detail then
			callpoint!.setColumnData("OPE_INVDET.QTY_BACKORD", "0")
			print "---BO cleared"; rem debug
		endif
	endif

return

rem ==========================================================================
#include std_missing_params.src
rem ==========================================================================

rem ==========================================================================
rem 	Use util object
rem ==========================================================================

	use ::ado_util.src::util
[[OPE_INVDET.LINE_CODE.AVAL]]
print "Det:LINE_CODE:AVAL"; rem debug

rem --- Set enable/disable based on line type

	line_code$ = callpoint!.getUserInput()
	gosub disable_by_linetype

rem --- Has line code changed?

	if line_code$ <> user_tpl.prev_line_code$ then
		callpoint!.setColumnData("OPE_INVDET.MAN_PRICE", "N")
		callpoint!.setColumnData("OPE_INVDET.PRODUCT_TYPE", "")
		callpoint!.setColumnData("OPE_INVDET.WAREHOUSE_ID", user_tpl.def_whse$)
		callpoint!.setColumnData("OPE_INVDET.ITEM_ID", "")
		callpoint!.setColumnData("OPE_INVDET.ORDER_MEMO", "")
		callpoint!.setColumnData("OPE_INVDET.EST_SHP_DATE", callpoint!.getHeaderColumnData("OPE_INVHDR.SHIPMNT_DATE"))
		callpoint!.setColumnData("OPE_INVDET.COMMIT_FLAG", "Y")
		callpoint!.setColumnData("OPE_INVDET.PICK_FLAG", "")
		callpoint!.setColumnData("OPE_INVDET.VENDOR_ID", "")
		callpoint!.setColumnData("OPE_INVDET.DROPSHIP", "")

		gosub clear_all_numerics
		gosub disp_grid_totals
		gosub clear_avail

	endif

rem --- Disable / Enable Backorder

	gosub able_backorder
