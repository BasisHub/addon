[[OPE_ORDDET.LINE_CODE.AVEC]]
rem --- Line code may not be displayed correctly when selected via arrow key instead of mouse
	callpoint!.setStatus("REFRESH:LINE_CODE")
[[OPE_ORDDET.LINE_CODE.AINP]]
print "Det:LINE_CODE:AINP"; rem debug

rem --- Grab and print what's in the input buffer

	line_code$ = callpoint!.getUserInput()
	print "Here's the pre-validate value of UserInput: ",line_code$
[[OPE_ORDDET.ITEM_ID.AINV]]
print "Det:ITEM_ID.AINV"; rem debug

rem --- Check for item synonyms

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::grid_entry"
[[OPE_ORDDET.WAREHOUSE_ID.BINP]]
print "Det:WAREHOUSE_ID.BINP"; rem debug

rem --- Enable repricing, options, lots

	gosub enable_repricing
	gosub enable_addl_opts
	gosub able_lot_button
[[OPE_ORDDET.AOPT-ADDL]]
print "Det:AOPT.ADDL"; rem debug

rem --- Additional Options

	if user_tpl.line_type$ = "M" then break; rem --- exit callpoint

rem --- Save current row/column so we'll know where to set focus when we return

	declare BBjStandardGrid grid!
	grid! = util.getGrid(Form!)
	return_to_row = grid!.getSelectedRow()
	return_to_col = grid!.getSelectedColumn()

rem --- Setup a templated string to pass information back and forth from form

	declare BBjTemplatedString a!

	tmpl$ =  "LINE_TYPE:C(1)," +
:				"INVOICE_TYPE:C(1)," +
:				"COMMIT_FLAG:C(1)," +
:				"MAN_PRICE:C(1)," +
:				"PRINT_FLAG:C(1)," +
:				"EST_SHP_DATE:C(8)," +
:				"STD_LIST_PRC:N(7*)," +
:				"DISC_PERCENT:N(7*)," +
:				"UNIT_PRICE:N(7*)"
	a! = BBjAPI().makeTemplatedString(tmpl$)

	dim dflt_data$[7,1]
	dflt_data$[1,0] = "STD_LIST_PRC"
	dflt_data$[1,1] = callpoint!.getColumnData("OPE_ORDDET.STD_LIST_PRC")
	dflt_data$[2,0] = "DISC_PERCENT"
	dflt_data$[2,1] = callpoint!.getColumnData("OPE_ORDDET.DISC_PERCENT")
	dflt_data$[3,0] = "NET_PRICE"
	dflt_data$[3,1] = callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE")
	dflt_data$[4,0] = "EST_SHP_DATE"
	dflt_data$[4,1] = callpoint!.getColumnData("OPE_ORDDET.EST_SHP_DATE")
	dflt_data$[5,0] = "COMMIT_FLAG"
	dflt_data$[5,1] = callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG")
	dflt_data$[6,0] = "MAN_PRICE"
	dflt_data$[6,1] = callpoint!.getColumnData("OPE_ORDDET.MAN_PRICE")
	dflt_data$[7,0] = "PRINTED"
	dflt_data$[7,1] = callpoint!.getColumnData("OPE_ORDDET.PICK_FLAG")
	
	a!.setFieldValue("LINE_TYPE",    user_tpl.line_type$)
	a!.setFieldValue("INVOICE_TYPE", callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE"))
	a!.setFieldValue("STD_LIST_PRC", callpoint!.getColumnData("OPE_ORDDET.STD_LIST_PRC"))
	a!.setFieldValue("DISC_PERCENT", callpoint!.getColumnData("OPE_ORDDET.DISC_PERCENT"))
	a!.setFieldValue("UNIT_PRICE",   callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
	a!.setFieldValue("EST_SHP_DATE", callpoint!.getColumnData("OPE_ORDDET.EST_SHP_DATE"))
	a!.setFieldValue("COMMIT_FLAG",  callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG"))
	a!.setFieldValue("MAN_PRICE",    callpoint!.getColumnData("OPE_ORDDET.MAN_PRICE"))
	a!.setFieldValue("PRINT_FLAG",   callpoint!.getColumnData("OPE_ORDDET.PICK_FLAG"))

	callpoint!.setDevObject("additional_options", a!)

	orig_commit$ = callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG")

rem --- Call form

	call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:		"OPE_ADDL_OPTS", 
:		stbl("+USER_ID"), 
:		"MNT", 
:		"", 
:		table_chans$[all], 
:		"",
:		dflt_data$[all]

rem --- Write back here

	a! = cast(BBjTemplatedString, callpoint!.getDevObject("additional_options"))
	callpoint!.setColumnData("OPE_ORDDET.STD_LIST_PRC", a!.getFieldAsString("STD_LIST_PRC"))
	callpoint!.setColumnData("OPE_ORDDET.DISC_PERCENT", a!.getFieldAsString("DISC_PERCENT"))
	callpoint!.setColumnData("OPE_ORDDET.UNIT_PRICE",   a!.getFieldAsString("UNIT_PRICE"))
	callpoint!.setColumnData("OPE_ORDDET.EST_SHP_DATE", a!.getFieldAsString("EST_SHP_DATE"))
	callpoint!.setColumnData("OPE_ORDDET.COMMIT_FLAG",  a!.getFieldAsString("COMMIT_FLAG"))
	callpoint!.setColumnData("OPE_ORDDET.MAN_PRICE",    a!.getFieldAsString("MAN_PRICE"))
	callpoint!.setColumnData("OPE_ORDDET.PICK_FLAG",    a!.getFieldAsString("PRINT_FLAG"))

rem --- Need to commit?

	if callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE") <> "P" then
		if callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG") = "N" then
			if user_tpl.line_type$ <> "O" then
				callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", "0")
				callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED", "0")
				callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE", "0")
				callpoint!.setColumnData("OPE_ORDDET.TAXABLE_AMT", "0")
			else
				if num(callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE")) then
					callpoint!.setColumnData("OPE_ORDDET.UNIT_PRICE", str(callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE")))
					callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE", "0")
					callpoint!.setColumnData("OPE_ORDDET.TAXABLE_AMT", "0")
				endif
			endif
		endif

		if orig_commit$ = "N" and callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG") = "Y" then
			callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED", str(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED")))

			if user_tpl.line_type$ = "O" and 
:				num(callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE")) = 0 and 
:				num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE")) 
:			then
				callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE", str(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE")))
				callpoint!.setColumnData("OPE_ORDDET.UNIT_PRICE", "0")
				callpoint!.setColumnData("OPE_ORDDET.STD_LIST_PRC", "0")
			endif
		endif
	endif

	qty_shipped = num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
	unit_price  = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
	gosub disp_ext_amt

	callpoint!.setStatus("REFRESH")

rem --- Return focus to where we were (Detail line grid)

	util.forceEdit(Form!, return_to_row, return_to_col)
[[OPE_ORDDET.AGDR]]
rem --- Disable by line type

	line_code$ = callpoint!.getColumnData("OPE_ORDDET.LINE_CODE")
	gosub disable_by_linetype
[[OPE_ORDDET.UNIT_PRICE.BINP]]
rem --- Enable repricing, options, lots

	gosub enable_repricing
	gosub enable_addl_opts
	gosub able_lot_button

rem --- Has a valid whse/item been entered?

	if user_tpl.item_wh_failed then
		item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
		wh$   = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
		warn  = 1
		gosub check_item_whse
	endif
[[OPE_ORDDET.QTY_ORDERED.AVEC]]
print "Det:QTY_ORDERED.AVEC"; rem debug

rem --- Enable buttons

	gosub able_lot_button
	gosub enable_repricing
	gosub enable_addl_opts
[[OPE_ORDDET.QTY_ORDERED.AVAL]]
print "Det:QTY_ORDERED.AVAL"; rem debug

rem --- Set shipped and back ordered

	qty_ord    = num(callpoint!.getUserInput())
	unit_price = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))

	print "---Qty<>prev? ", qty_ord<>user_tpl.prev_qty_ord; rem debug
	print "---Unit Price:", unit_price; rem debug

	if qty_ord = 0 then
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

	if qty_ord < 0 then
		callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED", str(qty_ord))
		callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", "0")
		rem callpoint!.setColumnEnabled("OPE_ORDDET.QTY_SHIPPED", 0)
		rem callpoint!.setColumnEnabled("OPE_ORDDET.QTY_BACKORD", 0)
		util.disableGridColumn(Form!, user_tpl.bo_col)
		util.disableGridColumn(Form!, user_tpl.shipped_col)
	endif

	if qty_ord <> user_tpl.prev_qty_ord then
		callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", "0")

		if callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG") = "Y" or
:			callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE") = "P"
:		then
			callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED", str(qty_ord))
		else
			callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED", "0")
		endif
	endif

rem --- Recalc quantities and extended price

	if user_tpl.line_type$ <> "N" and
:		callpoint!.getColumnData("OPE_ORDDET.MAN_PRICE") <> "Y" and
:		( (qty_ord and qty_ord <> user_tpl.prev_qty_ord) or unit_price = 0 )
:	then
		gosub pricing
	endif

	qty_shipped = num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
	gosub disp_ext_amt
[[OPE_ORDDET.QTY_BACKORD.BINP]]
rem --- Set previous qty / enable repricing, options, lots

	user_tpl.prev_boqty = num(callpoint!.getColumnData("OPE_ORDDET.QTY_BACKORD"))
	gosub enable_repricing
	gosub enable_addl_opts
	gosub able_lot_button

rem --- Has a valid whse/item been entered?

	if user_tpl.item_wh_failed then
		item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
		wh$   = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
		warn  = 1
		gosub check_item_whse
	endif
[[OPE_ORDDET.QTY_SHIPPED.BINP]]
rem --- Set previous amount / enable repricing, options, lots

	user_tpl.prev_shipqty = num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
	gosub enable_repricing
	gosub enable_addl_opts
	gosub able_lot_button

rem --- Has a valid whse/item been entered?

	if user_tpl.item_wh_failed then
		item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
		wh$   = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
		warn  = 1
		gosub check_item_whse
	endif
[[OPE_ORDDET.QTY_ORDERED.BINP]]
print "Det:QTY_ORDERED.BINP"; rem debug

rem --- Get prev qty / enable repricing, options, lots

	user_tpl.prev_qty_ord = num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	print "---Prev Qty set"; rem debug
	gosub enable_repricing
	gosub enable_addl_opts
	gosub able_lot_button

rem --- Has a valid whse/item been entered?

	if user_tpl.item_wh_failed then
		item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
		wh$   = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
		warn  = 1
		gosub check_item_whse
	endif
[[OPE_ORDDET.ITEM_ID.BINP]]
rem --- Set previous item / enable repricing, options, lot

	user_tpl.prev_item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	gosub enable_repricing
	gosub enable_addl_opts
	gosub able_lot_button
[[OPE_ORDDET.LINE_CODE.BINP]]
print "Det:LINE_CODE.BINP"; rem debug

rem --- Set previous value / enable repricing, options, lots

	user_tpl.prev_line_code$ = callpoint!.getColumnData("OPE_ORDDET.LINE_CODE")
	gosub enable_repricing
	gosub enable_addl_opts
	gosub able_lot_button
[[OPE_ORDDET.BWRI]]
rem --- Set values based on line type

	file$ = "OPC_LINECODE"
	dim linecode_rec$:fnget_tpl$(file$)
	line_code$ = callpoint!.getColumnData("OPE_ORDDET.LINE_CODE")
	print "---Line code: """, line_code$, """"; rem debug
	find record(fnget_dev(file$), key=firm_id$+line_code$) linecode_rec$

rem --- If line type is Memo, clear the extended price

	if linecode_rec.line_type$ = "M" then 
		callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE", "0")
	endif

rem --- Clear quantities if line type is Memo or Other

	if pos(linecode_rec.line_type$="MO") then
		callpoint!.setColumnData("OPE_ORDDET.QTY_ORDERED", "0")
		callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", "0")
		callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED", "0")
	endif

rem --- Set product types for certain line types 

	if pos(linecode_rec.line_type$="NOP") then
		if linecode_rec.prod_type_pr$ = "D" then			
			callpoint!.setColumnData("OPE_ORDDET.PRODUCT_TYPE", linecode_rec.product_type$)
		else
			if linecode_rec.prod_type_pr$ = "N" then
				callpoint!.setColumnData("OPE_ORDDET.PRODUCT_TYPE", "")
			endif
		endif
	endif
[[OPE_ORDDET.EXT_PRICE.AVAL]]
rem --- Round 

	if num(callpoint!.getUserInput()) <> num(callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE"))
		callpoint!.setUserInput( str(round( num(callpoint!.getUserInput()), 2)) )
	endif
[[OPE_ORDDET.WAREHOUSE_ID.AVEC]]
print "Det:WAREHOUSE_ID.AVEC"; rem debug

rem --- Set Recalc Price button

	gosub enable_repricing
[[OPE_ORDDET.ITEM_ID.AVEC]]
print "Det:ITEM_ID.AVEC"; rem debug

rem --- Set buttons

	gosub enable_repricing
	gosub able_lot_button

rem --- Set item tax flag

	gosub set_item_taxable
[[OPE_ORDDET.AOPT-RCPR]]
print "Det:AOPT.RCPR"; rem debug

rem --- Are things set for a reprice?

	print "---Line type: """, user_tpl.line_type$, """"; rem debug

	if pos(user_tpl.line_type$="SP") then
		qty_ord = num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
		print "---Qty ordered:", qty_ord; rem debug

		if qty_ord then 

		rem --- Save current column so we'll know where to set focus when we return

			return_to_col = util.getGrid(Form!).getSelectedColumn()

		rem --- Do repricing

			gosub pricing
			callpoint!.setDevObject("rcpr_row",str(callpoint!.getValidationRow()))
			callpoint!.setColumnData("OPE_ORDDET.MAN_PRICE", "N")
			gosub manual_price_flag

		endif
	endif
[[OPE_ORDDET.STD_LIST_PRC.BINP]]
rem --- Enable the Recalc Price button, Additional Options, Lots

	gosub enable_repricing
	gosub enable_addl_opts
	gosub able_lot_button
[[OPE_ORDDET.AWRI]]
rem --- Commit inventory

rem --- Turn off the print flag in the header?

	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow()) = "Y" or
:	   callpoint!.getGridRowModifyStatus(callpoint!.getValidationRow()) ="Y" or
:	   callpoint!.getGridRowDeleteStatus(callpoint!.getValidationRow()) = "Y"
		callpoint!.setHeaderColumnData("OPE_ORDHDR.PRINT_STATUS","N")
		callpoint!.setDevObject("msg_printed","N")
	endif

rem --- Is this row deleted?

	if callpoint!.getGridRowModifyStatus( callpoint!.getValidationRow() ) <> "Y" then 
		goto awri_update_hdr; rem --- exit callpoint
	endif

rem --- Get current and prior values

	curr_whse$ = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
	curr_item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	curr_qty   = num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	line_ship_date$=callpoint!.getColumnData("OPE_ORDDET.EST_SHP_DATE")
	curr_commit$=callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG")

	prior_whse$ = callpoint!.getColumnUndoData("OPE_ORDDET.WAREHOUSE_ID")
	prior_item$ = callpoint!.getColumnUndoData("OPE_ORDDET.ITEM_ID")
	prior_qty   = num(callpoint!.getColumnUndoData("OPE_ORDDET.QTY_ORDERED"))
	prior_commit$=callpoint!.getColumnUndoData("OPE_ORDDET.COMMIT_FLAG")

rem --- Don't commit or uncommit Quotes

	if callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE") = "P" goto awri_update_hdr

rem --- Has there been any change?

	if	(curr_whse$ <> prior_whse$ or 
:		 curr_item$ <> prior_item$ or 
:		 curr_qty   <> prior_qty) and
:		curr_commit$ = prior_commit$
:	then

rem --- Initialize inventory item update

		status=999
		call user_tpl.pgmdir$+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
		if status then goto awri_update_hdr

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

				if line_ship_date$<=user_tpl.def_commit$				
					call user_tpl.pgmdir$+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
					if status then goto awri_update_hdr
				endif
			endif

rem --- Commit quantity for current item and warehouse

			if curr_whse$<>"" and curr_item$<>"" and curr_qty<>0 then
				items$[1] = curr_whse$
				items$[2] = curr_item$
				refs[0]   = curr_qty 

				print "-----Commit: item = ", cvs(items$[2], 2), ", WH: ", items$[1], ", qty =", refs[0]; rem debug

				if line_ship_date$<=user_tpl.def_commit$				
					call user_tpl.pgmdir$+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
					if status then goto awri_update_hdr
				endif
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

				if line_ship_date$<=user_tpl.def_commit$
					call user_tpl.pgmdir$+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
					if status then goto awri_update_hdr
				endif
			endif

		endif

	endif

rem --- Only do the next if the commit flag has been changed
	if curr_commit$ <> prior_commit$

rem --- Initialize inventory item update
		status=999
		call user_tpl.pgmdir$+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
		if status then goto awri_update_hdr

rem --- Flag changed from Commit to Uncommit: uncommit previous

		if curr_commit$ ="N" and prior_commit$ = "Y"

rem --- Uncommit prior quantity

			if prior_qty<>0 then
				items$[1] = prior_whse$
				items$[2] = prior_item$
				refs[0]   = prior_qty
				call user_tpl.pgmdir$+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				if status then goto awri_update_hdr
			endif
		endif

		if curr_commit$ = "Y" and prior_commit$ <> "Y"

rem --- Commit current quantity

			if curr_qty<>0 then
				items$[1] = curr_whse$
				items$[2] = curr_item$
				refs[0]   = curr_qty 
				call user_tpl.pgmdir$+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				if status then goto awri_update_hdr
			endif
		endif
	endif

awri_update_hdr: rem --- Update header

	gosub disp_grid_totals

	file$ = "OPC_LINECODE"
	dim opc_linecode$:fnget_tpl$(file$)
	line_code$=callpoint!.getColumnData("OPE_ORDDET.LINE_CODE")
	find record (fnget_dev(file$), key=firm_id$+line_code$, dom=*endif) opc_linecode$

	if callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE") <> "P" 
		if opc_linecode.line_type$<>"M"
			callpoint!.setDevObject("details_changed","Y")
		endif
	endif

rem input "Det:Done with AWRI: ", *; rem debug
[[OPE_ORDDET.BDGX]]
rem --- Disable detail-only buttons

	callpoint!.setOptionEnabled("LENT",0)
	callpoint!.setOptionEnabled("RCPR",0)
	callpoint!.setOptionEnabled("ADDL",0)

rem --- Set header total amounts

	use ::ado_order.src::OrderHelper

	cust_id$  = cvs(callpoint!.getColumnData("OPE_ORDDET.CUSTOMER_ID"), 2)
	order_no$ = cvs(callpoint!.getColumnData("OPE_ORDDET.ORDER_NO"), 2)
	inv_type$ = callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE")

	if cust_id$<>"" and order_no$<>"" then

		ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
		ordHelp!.totalSalesDisk(cust_id$, order_no$, inv_type$)
		
		callpoint!.setHeaderColumnData( "OPE_ORDHDR.TOTAL_SALES", str(ordHelp!.getExtPrice()) )
		callpoint!.setHeaderColumnData( "OPE_ORDHDR.TAXABLE_AMT", str(ordHelp!.getTaxable()) )
		callpoint!.setHeaderColumnData( "OPE_ORDHDR.TOTAL_COST",  str(ordHelp!.getExtCost()) )

		callpoint!.setStatus("REFRESH;SETORIG")

	endif


	
[[OPE_ORDDET.AGCL]]
rem --- Set detail defaults and disabled columns

	callpoint!.setTableColumnAttribute("OPE_ORDDET.LINE_CODE","DFLT", user_tpl.line_code$)
	callpoint!.setTableColumnAttribute("OPE_ORDDET.WAREHOUSE_ID","DFLT", user_tpl.warehouse_id$)

rem	if user_tpl.skip_ln_code$ = "Y" then
rem		callpoint!.setColumnEnabled(-1, "OPE_ORDDET.LINE_CODE", 0)
rem	endif

	if user_tpl.skip_whse$ = "Y" then
		rem callpoint!.setColumnEnabled(-1, "OPE_ORDDET.WAREHOUSE_ID", 0)
		item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
		wh$   = user_tpl.warehouse_id$
		gosub set_avail	
	endif

rem --- Did we change rows?

	currRow = callpoint!.getValidationRow()

	if currRow <> user_tpl.cur_row
		gosub clear_avail
		user_tpl.cur_row = currRow

		item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
		wh$   = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
		gosub set_avail
	endif
[[OPE_ORDDET.AOPT-LENT]]
print "Det:AOPT.LENT"; rem debug

rem --- Save current row/column so we'll know where to set focus when we return from lot lookup

	declare BBjStandardGrid grid!
	grid! = util.getGrid(Form!)
	return_to_row = grid!.getSelectedRow()
	return_to_col = grid!.getSelectedColumn()

rem --- Go get Lot Numbers

	item_id$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	gosub lot_ser_check

rem --- Is this item lot/serial?

	if lotted$ = "Y" then
		ar_type$ = "  "
		cust$    = callpoint!.getColumnData("OPE_ORDDET.CUSTOMER_ID")
		order$   = callpoint!.getColumnData("OPE_ORDDET.ORDER_NO")
		int_seq$ = callpoint!.getColumnData("OPE_ORDDET.INTERNAL_SEQ_NO")

		if cvs(cust$,2) <> "" then

		rem --- Run the Lot/Serial# detail entry form
		rem      IN: call/enter list
		rem          the DevObjects set below
		rem          DevObject("lotser_flag"): set in OPE_ORDHDR

			callpoint!.setDevObject("from",          "order_entry")
			callpoint!.setDevObject("wh",            callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID"))
			callpoint!.setDevObject("item",          callpoint!.getColumnData("OPE_ORDDET.ITEM_ID"))
			callpoint!.setDevObject("ord_qty",       callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
			callpoint!.setDevObject("dropship_line", user_tpl.line_dropship$)
			callpoint!.setDevObject("invoice_type",  callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE"))
			callpoint!.setDevObject("unit_cost",       callpoint!.getColumnData("OPE_ORDDET.UNIT_COST"))

			grid!.focus()

			dim dflt_data$[3,1]
			dflt_data$[1,0] = "AR_TYPE"
			dflt_data$[1,1] = ar_type$
			dflt_data$[2,0] = "CUSTOMER_ID"
			dflt_data$[2,1] = cust$
			dflt_data$[3,0] = "ORDER_NO"
			dflt_data$[3,1] = order$
			lot_pfx$ = firm_id$+ar_type$+cust$+order$+int_seq$

			print "---Launch OPE_ORDLSDET..."; rem debug
			call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:				"OPE_ORDLSDET", 
:				stbl("+USER_ID"), 
:				"MNT", 
:				lot_pfx$, 
:				table_chans$[all], 
:				dflt_data$[all]
			print "---back for OPE_ORDLSDET"; rem debug

		rem --- Updated qty shipped, backordered, extension

			qty_shipped = num(callpoint!.getDevObject("total_shipped"))
			qty_ordered = num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
			unit_price  = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
			callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED", str(qty_shipped))

			if qty_ordered > 0 then
				callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", str(max(qty_ordered - qty_shipped, 0)) )
			else
				callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", str(min(qty_ordered - qty_shipped, 0)) )
			endif

			gosub disp_ext_amt
			callpoint!.setStatus("REFRESH")

		rem --- Return focus to where we were (Detail line grid)

			util.forceEdit(Form!, return_to_row, return_to_col)
		endif
	endif
[[OPE_ORDDET.BUDE]]
rem --- add and recommit Lot/Serial records (if any) and detail lines if not

	if callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG")="Y"
		action$="CO"
		gosub uncommit_iv
	endif

	gosub calculate_discount
[[OPE_ORDDET.AREC]]
rem --- Backorder is zero and disabled on a new record

	rem user_tpl.new_detail = 1
	rem The above is not reliable; use callpoint!.getRecordMode()

	callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", "0")
	callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.QTY_BACKORD", 0)
   print "---New record"; rem debug
   print "---BO qty cleared"; rem debug

rem --- Set defaults for new record

	inv_type$  = callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE")
	ship_date$ = callpoint!.getHeaderColumnData("OPE_ORDHDR.SHIPMNT_DATE")

	callpoint!.setColumnData("OPE_ORDDET.MAN_PRICE", "N")
	callpoint!.setColumnData("OPE_ORDDET.EST_SHP_DATE", ship_date$)

	rem print "---Ship Date: ", ship_date$; rem debug
	rem print "---Commit   : ", user_tpl.def_commit$; rem debug	

	if inv_type$ = "P" or ship_date$ > user_tpl.def_commit$ then
		rem print "---Commit = No"; rem debug
 		callpoint!.setColumnData("OPE_ORDDET.COMMIT_FLAG", "N")
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.QTY_SHIPPED", 0)
	else
		rem print "---Commit = Yes"; rem debug
		callpoint!.setColumnData("OPE_ORDDET.COMMIT_FLAG", "Y")
 	endif

rem --- Enable/disable backorder

	gosub able_backorder

	callpoint!.setStatus("REFRESH")

rem --- Buttons start disabled

	callpoint!.setOptionEnabled("LENT",0)
	callpoint!.setOptionEnabled("RCPR",0)
	callpoint!.setOptionEnabled("ADDL",0)

rem --- Force focus on Line Code since Barista is skipping it (rem'd since Barista bug 3999 fixed)

rem	callpoint!.setFocus(num(callpoint!.getValidationRow()),"OPE_ORDDET.LINE_CODE")
[[OPE_ORDDET.BDEL]]
rem --- remove and uncommit Lot/Serial records (if any) and detail lines if not

	if callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG")="Y"
		action$="UC"
		gosub uncommit_iv
	endif

	gosub calculate_discount
[[OPE_ORDDET.AGRN]]
rem (Fires regardles of new or existing row.  Use callpoint!.getRecordMode() to distinguish the two)

rem --- See if we're coming back from Recalc button

	if callpoint!.getDevObject("rcpr_row") <> ""
		callpoint!.setFocus(num(callpoint!.getDevObject("rcpr_row")),"OPE_ORDDET.UNIT_PRICE")
		callpoint!.setDevObject("rcpr_row","")
		callpoint!.setDevObject("details_changed","Y")
		break
	endif

rem --- Disable Line Code if existing record

	if callpoint!.getGridRowNewStatus(num(callpoint!.getValidationRow())) = ""
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.LINE_CODE", 0)
	else
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.LINE_CODE", 1)
	endif

rem --- Disable by line type (Needed because Barista is skipping Line Code)

	if callpoint!.getGridRowNewStatus(num(callpoint!.getValidationRow())) = ""
		line_code$ = callpoint!.getColumnData("OPE_ORDDET.LINE_CODE")
		gosub disable_by_linetype
	endif

rem --- Disable cost if necessary

	if pos(user_tpl.line_type$="SP") and num(callpoint!.getColumnData("OPE_ORDDET.UNIT_COST")) then
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.UNIT_COST", 0)
	endif

rem --- Set enable/disable back order

	gosub able_backorder

rem --- Disable Shipped?

	if callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG") = "N" then
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.QTY_SHIPPED", 0)
	endif

rem --- Set item tax flag

	gosub set_item_taxable

rem --- Set item price if item and whse exist

	item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	wh$   = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")

	if item$<>"" and wh$<>"" then
		file$ = "IVM_ITEMWHSE"
		dim itemwhse$:fnget_tpl$(file$)
		start_block = 1
		
		if start_block then
			find record (fnget_dev(file$), key=firm_id$+wh$+item$, dom=*endif) itemwhse$
			user_tpl.item_price = itemwhse.cur_price
		endif
	endif

rem --- Set previous values

	user_tpl.prev_ext_price  = num(callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE"))
	user_tpl.prev_ext_cost   = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_COST")) * num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	user_tpl.prev_line_code$ = callpoint!.getColumnData("OPE_ORDDET.LINE_CODE")
	user_tpl.prev_item$      = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	user_tpl.prev_qty_ord    = num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	user_tpl.prev_boqty      = num(callpoint!.getColumnData("OPE_ORDDET.QTY_BACKORD"))
	user_tpl.prev_shipqty    = num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
	user_tpl.prev_unitprice  = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))

rem --- Set buttons

	rem if !user_tpl.new_detail then...

	gosub able_lot_button

	if callpoint!.getRecordMode() = "C" then
		gosub enable_repricing
		gosub enable_addl_opts
	endif

rem --- Set availability info

	gosub set_avail
[[OPE_ORDDET.AGRE]]
rem --- Clear/set flags

	rem user_tpl.new_detail = 0

	round_precision = num(callpoint!.getDevObject("precision"))
	this_row = callpoint!.getValidationRow()
	print "---This Row:", this_row; rem debug
	print "---getGridRowNewStatus: ", callpoint!.getGridRowNewStatus(this_row); rem debug
	print "---getGridRowModifyStatus: ", callpoint!.getGridRowModifyStatus(this_row); rem debug

	if callpoint!.getGridRowNewStatus(this_row) <> "Y" and callpoint!.getGridRowModifyStatus(this_row) <> "Y" then
		break; rem --- exit callpoint
	endif

	print "---Passed Grid Row Status tests..."; rem debug
	user_tpl.detail_modified = 1

rem --- Returns

	if num( callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED") ) < 0 then
		callpoint!.setColumnData( "OPE_ORDDET.QTY_SHIPPED", callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED") )
		callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", "0")
	endif

rem --- What is extended price?

	unit_price = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))

	if pos(user_tpl.line_type$="SNP") then
		ext_price = round( num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED")) * unit_price, 2 )
	else
		ext_price = round( num(callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE")), 2 )
	endif

rem --- Has customer credit been exceeded?

	gosub calc_grid_totals
	
	rem print "---over credit limit?"; rem debug
	if user_tpl.balance - user_tpl.prev_ext_price + ttl_ext_price > user_tpl.credit_limit then 
		rem print "---yes"; rem debug
		gosub credit_exceeded
	endif

	if callpoint!.getGridRowNewStatus(this_row) = "Y" or
:		callpoint!.getGridRowModifyStatus(this_row) = "Y"

		gosub calculate_discount

	endif

rem --- Check for minimum line extension

	commit_flag$    = callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG")
	qty_backordered = num(callpoint!.getColumnData("OPE_ORDDET.QTY_BACKORD"))

	if user_tpl.line_type$ <> "M" and 
:		qty_backorderd = 0         and 
:		commit_flag$ = "Y"         and
:		abs(ext_price) < user_tpl.min_line_amt 
:	then
		msg_id$ = "OP_LINE_UNDER_MIN"
		dim msg_tokens$[1]
		msg_tokens$[1] = str(user_tpl.min_line_amt:user_tpl.amount_mask$)
		gosub disp_message
	endif
	
rem --- Warehouse and Item must be correct

	wh$   = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
	item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	warn  = 1

	gosub check_item_whse	

	if user_tpl.item_wh_failed then 

		rem callpoint!.setStatus("ABORT")

		rem --- using this instead to force focus if item/whse invalid -- i.e., don't let user leave corrupt row
		callpoint!.setFocus(this_row,"OPE_ORDDET.ITEM_ID")
		break; rem --- exit callpoint

	else

	rem --- Clear line type

		user_tpl.line_type$ = ""
		print "---Line Type cleared"; rem debug

	endif

rem --- Set taxable amount

	if user_tpl.line_taxable$ = "Y" and 
:		( pos(user_tpl.line_type$ = "OMN") or user_tpl.item_taxable$ = "Y" ) 
:	then 
		callpoint!.setColumnData("OPE_ORDDET.TAXABLE_AMT", str(ext_price))
	endif

rem --- Set price and discount

	std_price  = num(callpoint!.getColumnData("OPE_ORDDET.STD_LIST_PRC"))
	disc_per   = num(callpoint!.getColumnData("OPE_ORDDET.DISC_PERCENT"))
	
	if std_price then
		callpoint!.setColumnData("OPE_ORDDET.DISC_PERCENT", str(round(100 - unit_price * 100 / std_price, 2)) )
	else
		if disc_per <> 100 then
			callpoint!.setColumnData("OPE_ORDDET.STD_LIST_PRC", str(round(unit_price * 100 / (100 - disc_per), round_precision)) )
		endif
	endif
	
rem --- Set amounts for non-commited "other" type detail lines

	if callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE") <> "P" and
:		callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG") = "N"         and
:		user_tpl.line_type$ = "O"                                        and
:		ext_price <> 0
:	then
		callpoint!.setColumnData("OPE_ORDDET.UNIT_PRICE", str(round(ext_price, 2)) )
		callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE", "0")
		callpoint!.setColumnData("OPE_ORDDET.TAXABLE_AMT", "0")
	endif

rem --- Set header order totals

	gosub disp_grid_totals

	callpoint!.setStatus("MODIFIED;REFRESH")
[[OPE_ORDDET.UNIT_PRICE.AVAL]]
print "Det:UNIT_PRICE:AVAL"; rem debug

rem --- Set Manual Price flag and round price
	round_precision = num(callpoint!.getDevObject("precision"))
	unit_price = round(num(callpoint!.getUserInput()),round_precision)
	if num(callpoint!.getUserInput()) <> num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
		callpoint!.setUserInput(str(unit_price))
	endif

	if pos(user_tpl.line_type$="SP") and 
:		user_tpl.prev_unitprice 		and 
:		unit_price <> user_tpl.prev_unitprice 
:	then 
		callpoint!.setColumnData("OPE_ORDDET.MAN_PRICE", "Y")
		gosub manual_price_flag
	endif

rem --- Display Extended Price

	qty_shipped = num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
	gosub disp_ext_amt
[[OPE_ORDDET.AUDE]]
rem --- redisplay totals

	gosub disp_grid_totals

	callpoint!.setDevObject("details_changed","Y")
[[OPE_ORDDET.ADEL]]
rem --- redisplay totals

	gosub disp_grid_totals

	callpoint!.setDevObject("details_changed","Y")
[[OPE_ORDDET.WAREHOUSE_ID.AVAL]]
print "Det:WAREHOUSE_ID.AVAL"; rem debug

rem --- Check item/warehouse combination, Set Available

	item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	wh$   = callpoint!.getUserInput()
	warn  = 0

rem --- Item probably isn't set yet, but we don't know for sure

	gosub check_item_whse
	if !user_tpl.item_wh_failed then gosub set_avail
[[OPE_ORDDET.ITEM_ID.AVAL]]
print "Det:ITEM_ID.AVAL"; rem debug

rem --- Check item/warehouse combination and setup values

	item$ = callpoint!.getUserInput()
	wh$   = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")

	if item$<>user_tpl.prev_item$ then
		gosub clear_all_numerics
	endif

	warn = 0
	gosub check_item_whse

	if !user_tpl.item_wh_failed then 
		gosub set_avail
		callpoint!.setColumnData("OPE_ORDDET.UNIT_COST", ivm02a.unit_cost$)
		callpoint!.setColumnData("OPE_ORDDET.STD_LIST_PRC", ivm02a.cur_price$)
		if pos(user_tpl.line_prod_type_pr$="DN")=0
			callpoint!.setColumnData("OPE_ORDDET.PRODUCT_TYPE", ivm01a.product_type$)
		endif
		user_tpl.item_price = ivm02a.cur_price
		if pos(user_tpl.line_type$="SP") and num(ivm02a.unit_cost$)=0 or (user_tpl.line_dropship$="Y" and user_tpl.dropship_cost$="Y")
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.UNIT_COST",1)
		endif
		callpoint!.setStatus("REFRESH")
	endif
[[OPE_ORDDET.QTY_SHIPPED.AVAL]]
print "Det:QTY_SHIPPED.AVAL"; rem debug

rem --- recalc quantities and extended price

	shipqty    = num(callpoint!.getUserInput())
	ordqty     = num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	cash_sale$ = callpoint!.getHeaderColumnData("OPE_ORDHDR.CASH_SALE")

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
		callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", "0")
		callpoint!.setStatus("REFRESH")
		print "---BO set to zero"; rem debug
	else
		if user_tpl.prev_shipqty <> shipqty then
			callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", str(max(0, ordqty - shipqty)) )
			callpoint!.setStatus("REFRESH")
			print "---BO set to", max(0, ordqty - shipqty); rem debug
		endif
	endif

rem --- Update header

	qty_shipped = shipqty
	unit_price  = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
	gosub disp_ext_amt
[[OPE_ORDDET.QTY_BACKORD.AVAL]]
print "Det:QTY_BACKORD.AVAL"; rem debug

rem --- Recalc quantities and extended price

	boqty  = num(callpoint!.getUserInput())
	ordqty = num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	qtyshipped = num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))

	if boqty = 0 then
		user_tpl.prev_boqty = 0
	endif

	qty_shipped = ordqty - boqty

	if boqty <> user_tpl.prev_boqty then
		if qty_shipped < 0 then
			callpoint!.setUserInput(str(user_tpl.prev_boqty))
			msg_id$ = "BO_EXCEEDS_ORD"
			gosub disp_message
			callpoint!.setStatus("ABORT-REFRESH")
			break; rem --- exit callpoint
		endif
	endif

	callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED", str(qty_shipped))
	unit_price = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
	gosub disp_ext_amt
[[OPE_ORDDET.<CUSTOM>]]
rem ==========================================================================
disp_grid_totals: rem --- Get order totals and display, save header totals
rem ==========================================================================

	gosub calculate_discount

	callpoint!.setHeaderColumnData("OPE_ORDHDR.TOTAL_SALES", str(ttl_ext_price))
	discamt! = UserObj!.getItem(num(callpoint!.getDevObject("disc_amt_disp")))
	discamt!.setValue(disc_amt)
	sub_tot = num(callpoint!.getHeaderColumnData("<<DISPLAY>>.SUBTOTAL"))
	freight_amt = num(callpoint!.getHeaderColumnData("OPE_ORDHDR.FREIGHT_AMT"))
	sub_tot = ttl_ext_price - disc_amt
	net_sales = sub_tot + ttl_tax + freight_amt
	totamt! = UserObj!.getItem(num(callpoint!.getDevObject("total_sales_disp")))
	totamt!.setValue(ttl_ext_price)
	subamt! = UserObj!.getItem(num(callpoint!.getDevObject("subtot_disp")))
	subamt!.setValue(sub_tot)
	netamt! = UserObj!.getItem(num(callpoint!.getDevObject("net_sales_disp")))
	netamt!.setValue(net_sales)
	tamt! = UserObj!.getItem(user_tpl.ord_tot_obj)
	tamt!.setValue(net_sales)

	taxamt! = UserObj!.getItem(num(callpoint!.getDevObject("tax_amt_disp")))
	taxamt!.setValue(ttl_tax)

rem --- Only activate the next 2 lines if you have enabled the Total Cost amount on the Totals tab
rem	costamt! = UserObj!.getItem(num(callpoint!.getDevObject("total_cost")))
rem	costamt!.setValue(ttl_ext_cost)

	callpoint!.setHeaderColumnData("OPE_ORDHDR.TOTAL_COST",str(ttl_ext_cost))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.SUBTOTAL", str(sub_tot))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.NET_SALES", str(net_sales))
	callpoint!.setHeaderColumnData("OPE_ORDHDR.TAX_AMOUNT", str(ttl_tax))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.ORDER_TOT", str(net_sales))

	callpoint!.setStatus("REFRESH")

	cm$=callpoint!.getDevObject("msg_credit_memo")

	if cm$="Y" and ttl_ext_price>=0 callpoint!.setDevObject("msg_credit_memo","N")
	if cm$<>"Y" and ttl_ext_price<0 callpoint!.setDevObject("msg_credit_memo","Y")
	call user_tpl.pgmdir$+"opc_creditmsg.aon","D",callpoint!,UserObj!

	return

rem ==========================================================================
calculate_discount: rem --- Calculate Discount Amount
rem ==========================================================================

	rem --- Don't update discount unless extended price has changed,
	rem --- otherwise might overwrite manually entered discount.
	if user_tpl.prev_ext_price<>num(callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE"))
		disc_code$=callpoint!.getDevObject("disc_code")

		file_name$ = "OPC_DISCCODE"
		disccode_dev = fnget_dev(file_name$)
		dim disccode_rec$:fnget_tpl$(file_name$)

		find record (disccode_dev, key=firm_id$+disc_code$, dom=*next) disccode_rec$

		ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
		if ordHelp!.getInv_type() = "" then
			ttl_ext_price = 0
		else
			ttl_ext_price = ordHelp!.totalSales( cast(BBjVector, GridVect!.getItem(0)), cast(Callpoint, callpoint!) )
		endif

		disc_amt = round(disccode_rec.disc_percent * ttl_ext_price / 100, 2)
		callpoint!.setHeaderColumnData("OPE_ORDHDR.DISCOUNT_AMT",str(disc_amt))
	endif

	disc_amt=num(callpoint!.getHeaderColumnData("OPE_ORDHDR.DISCOUNT_AMT"))
	gosub calc_grid_totals

	return

rem ==========================================================================
calc_grid_totals: rem --- Roll thru all detail lines, totaling ext_price
                  rem     OUT: ttl_ext_price
rem ==========================================================================

	rem print "Det:in calc_grid_totals..."; rem debug

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))

	if ordHelp!.getInv_type() = "" then
		ttl_ext_price = 0
		ttl_ext_cost = 0
		ttl_taxable = 0
	else
		ttl_ext_price = ordHelp!.totalSales( cast(BBjVector, GridVect!.getItem(0)), cast(Callpoint, callpoint!) )
		ttl_ext_cost = ordHelp!.totalCost( cast(BBjVector, GridVect!.getItem(0)), cast(Callpoint, callpoint!) )
		ttl_taxable = ordHelp!.totalTaxable( cast(BBjVector, GridVect!.getItem(0)), cast(Callpoint, callpoint!) )
	endif

	freight_amt = num(callpoint!.getHeaderColumnData("OPE_ORDHDR.FREIGHT_AMT"))
	ttl_tax = ordHelp!.calculateTax(disc_amt, freight_amt, ttl_taxable, ttl_ext_price)

	return

rem ==========================================================================
pricing: rem --- Call Pricing routine
         rem      IN: qty_ord
         rem     OUT: price (UNIT_PRICE), disc (DISC_PERCENT), STD_LINE_PRC
         rem          enter_price_message (0/1)
rem ==========================================================================

	round_precision = num(callpoint!.getDevObject("precision"))
	print "in pricing..."; rem debug

	enter_price_message = 0

	wh$   = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
	item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	cust$ = callpoint!.getColumnData("OPE_ORDDET.CUSTOMER_ID")
	ord$  = callpoint!.getColumnData("OPE_ORDDET.ORDER_NO")

	if cvs(item$, 2)="" or cvs(wh$, 2)="" then 
		print "---No item or WH, exiting"
		callpoint!.setStatus("ABORT")
		return
	endif

	warn = 0
	gosub check_item_whse

	if user_tpl.item_wh_failed then 
		print "---Item/WH don't match, exiting"
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

	call stbl("+DIR_PGM")+"opc_pricing.aon",
:		pc_files[all],
:		firm_id$,
:		wh$,
:		item$,
:		user_tpl.price_code$,
:		cust$,
:		user_tpl.order_date$,
:		user_tpl.pricing_code$,
:		qty_ord,
:		typeflag$,
:		price,
:		disc,
:		status

	if status=999 then exitto std_exit

	if price=0 then
		msg_id$="ENTER_PRICE"
		gosub disp_message
		util.forceEdit(Form!, user_tpl.unit_price_col)
		enter_price_message = 1
	else
		callpoint!.setColumnData("OPE_ORDDET.UNIT_PRICE", str(round(price, round_precision)) )
		callpoint!.setColumnData("OPE_ORDDET.DISC_PERCENT", str(disc))
	endif

	if disc=100 then
		callpoint!.setColumnData("OPE_ORDDET.STD_LIST_PRC", str(user_tpl.item_price))
	else
		callpoint!.setColumnData("OPE_ORDDET.STD_LIST_PRC", str( round((price*100) / (100-disc), round_precision) ))
	endif

	rem callpoint!.setStatus("REFRESH")
	callpoint!.setStatus("REFRESH:UNIT_PRICE")

rem --- Recalc and display extended price

	qty_shipped = num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
	unit_price = price
	gosub disp_ext_amt

	user_tpl.prev_unitprice = unit_price

	rem debug
	print "---Price Out:", price
	print "---Discount :", disc
	print "---Type Flag: ", typeflag$
	print "out"

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
	endif

	userObj!.getItem(user_tpl.avail_oh).setText(avail$[1])
	userObj!.getItem(user_tpl.avail_comm).setText(avail$[2])
	userObj!.getItem(user_tpl.avail_avail).setText(avail$[3])
	userObj!.getItem(user_tpl.avail_oo).setText(avail$[4])
	userObj!.getItem(user_tpl.avail_wh).setText(avail$[5])
	userObj!.getItem(user_tpl.avail_type).setText(avail$[6])

	if user_tpl.line_dropship$ = "Y" then
		userObj!.getItem(user_tpl.dropship_flag).setText(Translate!.getTranslation("AON_**DROPSHIP**"))
	else
		userObj!.getItem(user_tpl.dropship_flag).setText("")
	endif

 	if good_item$="Y"
 		switch pos(ivm01a.alt_sup_flag$="AS")
 			case 1
 				userObj!.getItem(user_tpl.alt_super).setText(Translate!.getTranslation("AON_ALTERNATE:_")+cvs(ivm01a.alt_sup_item$,3))
 			break
 			case 2
 				userObj!.getItem(user_tpl.alt_super).setText(Translate!.getTranslation("AON_SUPERSEDED:_")+cvs(ivm01a.alt_sup_item$,3))
 			break
 			case default
 				userObj!.getItem(user_tpl.alt_super).setText("")
 			break
 		swend
	else
		userObj!.getItem(user_tpl.alt_super).setText("")
 	endif

	gosub manual_price_flag

	return

rem ==========================================================================
manual_price_flag: rem --- Set manual price flag
rem ==========================================================================

	if callpoint!.getColumnData("OPE_ORDDET.MAN_PRICE") = "Y" then 
		userObj!.getItem(user_tpl.manual_price).setText(Translate!.getTranslation("AON_**MANUAL_PRICE**"))
	else
		userObj!.getItem(user_tpl.manual_price).setText("")
	endif

	return

rem ==========================================================================
clear_avail: rem --- Clear Availability Window
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
uncommit_iv: rem --- Uncommit Inventory
             rem --- Make sure action$ is set before entry
rem ==========================================================================

	rem print "in uncommit_iv"; rem debug

	ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")

	ope_ordlsdet_dev=fnget_dev("OPE_ORDLSDET")
	dim ope_ordlsdet$:fnget_tpl$("OPE_ORDLSDET")

	ord_type$ = callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE")
	cust$    = callpoint!.getColumnData("OPE_ORDDET.CUSTOMER_ID")
	ar_type$ = callpoint!.getColumnData("OPE_ORDDET.AR_TYPE")
	order$   = callpoint!.getColumnData("OPE_ORDDET.ORDER_NO")
	seq$     = callpoint!.getColumnData("OPE_ORDDET.INTERNAL_SEQ_NO")
	wh$      = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
	item$    = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	ord_qty  = num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	line_ship_date$=callpoint!.getColumnData("OPE_ORDDET.EST_SHP_DATE")

	if cvs(item$, 2)<>"" and cvs(wh$, 2)<>"" and ord_qty and ord_type$<>"P" then
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
		read record (ivm_itemmast_dev, key=firm_id$+item$, dom=*next) ivm_itemmast$

		items$[1]=wh$
		items$[2]=item$
		refs[0]=ord_qty

		if ivm_itemmast.lotser_item$<>"Y" or ivm_itemmast.inventoried$<>"Y" then
			if line_ship_date$<=user_tpl.def_commit$
				call stbl("+DIR_PGM")+"ivc_itemupdt.aon",action$,channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
			endif
		else
			found_lot=0
			read (ope_ordlsdet_dev, key=firm_id$+ar_type$+cust$+order$+seq$, dom=*next)

			while 1
				read record (ope_ordlsdet_dev, end=*break) ope_ordlsdet$
				if pos(firm_id$+ar_type$+cust$+order$+seq$=ope_ordlsdet$)<>1 then break
				items$[3] = ope_ordlsdet.lotser_no$
				refs[0]   = ope_ordlsdet.qty_ordered
				if line_ship_date$<=user_tpl.def_commit$
					call stbl("+DIR_PGM")+"ivc_itemupdt.aon",action$,channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				endif
				remove (ope_ordlsdet_dev, key=firm_id$+ar_type$+cust$+order$+seq$+ope_ordlsdet.sequence_no$)
				found_lot=1
			wend

			if found_lot=0
				if line_ship_date$<=user_tpl.def_commit$
					call stbl("+DIR_PGM")+"ivc_itemupdt.aon",action$,channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				endif
			endif
		endif
	endif

	rem print "out"; rem debug

	return

rem =============================================================================
disable_by_linetype: rem --- Set enable/disable based on line type
		rem --- <<CALLPOINT>> enable in item#, memo, ordered, price, shipped and ext price on form handles enable/disable
		rem --- based strictly on line type, via the callpoint!.setStatus("ENABLE:"+opc_linecode.line_type$) command.
		rem --- cost, product type and backordered are enabled/disabled directly based on additional conditions
		rem      IN: line_code$

rem =============================================================================

	print "in disable_by_linetype..."; rem debug
	rem print "---getValidRow() =", callpoint!.getValidRow(); rem debug

	user_tpl.line_type$ = ""
	user_tpl.line_taxable$ = ""
	user_tpl.line_dropship$ = ""
	user_tpl.line_prod_type_pr$ = ""
	start_block = 1

	if callpoint!.getCallpointEvent()="OPE_ORDDET.LINE_CODE.AVAL"
		line_code$=callpoint!.getUserInput()
	else
		line_code$=callpoint!.getColumnData("OPE_ORDDET.LINE_CODE")
	endif

	if cvs(line_code$,2) <> "" then
		print "---line code is "+ line_code$+ " and came from "+callpoint!.getCallpointEvent(); rem debug

		file$ = "OPC_LINECODE"
		dim opc_linecode$:fnget_tpl$(file$)

		if start_block then
			find record (fnget_dev(file$), key=firm_id$+line_code$, dom=*endif) opc_linecode$
			callpoint!.setStatus("ENABLE:"+opc_linecode.line_type$)

			user_tpl.line_type$     = opc_linecode.line_type$
			user_tpl.line_taxable$  = opc_linecode.taxable_flag$
			user_tpl.line_dropship$ = opc_linecode.dropship$
			user_tpl.line_prod_type_pr$ = opc_linecode.prod_type_pr$
			print "---Line Type set (", user_tpl.line_type$, ")"; rem debug

			if pos(opc_linecode.line_type$="SP")>0 and num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))<>0
				callpoint!.setOptionEnabled("RCPR",1)
			else
				callpoint!.setOptionEnabled("RCPR",0)
			endif
		endif
	endif

rem --- Disable/enable unit cost (can't just enable/disable this field by line type)

	if pos(user_tpl.line_type$="NSP") = 0 
		rem --- always disable cost if line type Memo or Other
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.UNIT_COST", 0)
	else
		if user_tpl.line_dropship$ = "Y" 
			if user_tpl.dropship_cost$ = "N" 
				rem --- if a drop-shipable line code, but enter cost on drop-ship param isn't set, disable, else enable cost
				callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.UNIT_COST", 0)
			else
				callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.UNIT_COST", 1)
			endif
		else
			if user_tpl.line_type$="N"
				rem --- always have cost enabled for Nonstock
				callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.UNIT_COST", 1)
			else				
				rem --- Standard or sPecial line 
				rem --- note: when item id is entered, cost will get enabled in that AVAL if S or P and cost = 0 (or dropshippable)
				callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.UNIT_COST", 0)				
			endif
		endif
	endif

rem --- Product Type Processing

	if cvs(line_code$,2) <> "" 
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.PRODUCT_TYPE", 0)
		if opc_linecode.prod_type_pr$ = "E" 
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.PRODUCT_TYPE", 1)
		endif
	endif

rem --- Disable Back orders if necessary

	if user_tpl.allow_bo$ = "N" or pos(user_tpl.line_type$ = "MO") or callpoint!.getHeaderColumnData("OPE_ORDHDR.CASH_SALE") = "Y" or callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG") = "N"
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.QTY_BACKORD", 0)
	else
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.QTY_BACKORD", 1)
	endif

	print "out"; rem debug

	return

rem ===========================================================================
check_item_whse: rem --- Check that a warehouse record exists for this item
                 rem      IN: wh$
                 rem          item$
                 rem          warn    (1=warn if failed, 0=no warning)
                 rem     OUT: user_tpl.item_wh_failed
                 rem          ivm02_dev
                 rem          ivm02a$ 
rem ===========================================================================

	rem print "in check_item_whse..."; rem debug

	user_tpl.item_wh_failed = 0
	this_row = callpoint!.getValidationRow()

	rem print "---This Row:", this_row; rem debug
	rem print "---Grid Row Delete Status: ", callpoint!.getGridRowDeleteStatus(this_row); rem debug

	if callpoint!.getGridRowDeleteStatus(this_row) <> "Y" then
		if pos(user_tpl.line_type$="SP") then
			rem print "---checking..."; rem debug
			file$ = "IVM_ITEMWHSE"
			ivm02_dev = fnget_dev(file$)
			dim ivm02a$:fnget_tpl$(file$)
			user_tpl.item_wh_failed = 1
			
			if cvs(item$, 2) <> "" and cvs(wh$, 2) <> "" then
				find record (ivm02_dev, key=firm_id$+wh$+item$, knum="PRIMARY", dom=*endif) ivm02a$
				user_tpl.item_wh_failed = 0
			endif

			if user_tpl.item_wh_failed and warn then 
				callpoint!.setMessage("IV_NO_WHSE_ITEM")
				callpoint!.setStatus("ABORT")
			endif
		endif
	endif

	rem print "out"; rem debug

	return

rem ==========================================================================
clear_all_numerics: rem --- Clear all order detail numeric fields
rem ==========================================================================

	callpoint!.setColumnData("OPE_ORDDET.UNIT_COST", "0")
	callpoint!.setColumnData("OPE_ORDDET.UNIT_PRICE", "0")
	callpoint!.setColumnData("OPE_ORDDET.QTY_ORDERED", "0")
	callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", "0")
	callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED", "0")
	callpoint!.setColumnData("OPE_ORDDET.STD_LIST_PRC", "0")
	callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE", "0")
	callpoint!.setColumnData("OPE_ORDDET.TAXABLE_AMT", "0")
	callpoint!.setColumnData("OPE_ORDDET.DISC_PERCENT", "0")
	callpoint!.setColumnData("OPE_ORDDET.COMM_PERCENT", "0")
	callpoint!.setColumnData("OPE_ORDDET.COMM_AMT", "0")
	callpoint!.setColumnData("OPE_ORDDET.SPL_COMM_PCT", "0")

	print "---All numerics cleared"; rem debug

	return

rem ==========================================================================
enable_addl_opts: rem --- Enable the Additional Options button
rem ==========================================================================

	if user_tpl.line_type$ <> "M" then 
		item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
		wh$   = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
		warn  = 0
		gosub check_item_whse

		if !user_tpl.item_wh_failed and num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED")) then
			callpoint!.setOptionEnabled("ADDL",1)
		endif
	endif

	return

rem ==========================================================================
enable_repricing: rem --- Enable the Recalc Pricing button
rem ==========================================================================

	print "in enable_repricing..."; rem debug
	print "---Line type: """, user_tpl.line_type$, """"; rem debug

	if pos(user_tpl.line_type$="SP") then 
		item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
		wh$   = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
		warn  = 0
		gosub check_item_whse

		if !user_tpl.item_wh_failed and num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED")) then
			callpoint!.setOptionEnabled("RCPR",1)
		endif
	endif

	print "out"; rem debug

	return

rem ==========================================================================
able_lot_button: rem --- Enable/disable Lot/Serial button
                 rem      IN: item_id$ (for lot_ser_check)
                 rem     OUT: lotted$
rem ==========================================================================

	item_id$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	qty_ord  = num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	gosub lot_ser_check

	if lotted$ = "Y" and callpoint!.getDevObject("inventoried")="Y" and qty_ord <> 0 and callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE")<>"P" then
		callpoint!.setOptionEnabled("LENT",1)
	else
		callpoint!.setOptionEnabled("LENT",0)
	endif

	return

rem ==========================================================================
lot_ser_check: rem --- Check for lotted item
               rem      IN: item_id$
               rem     OUT: lotted$ - Y/N
               rem          DevObject "inventoried"
rem ==========================================================================

	lotted$="N"

	if cvs(item_id$, 2)<>"" and pos(user_tpl.lotser_flag$ = "LS") then 
		ivm01_dev=fnget_dev("IVM_ITEMMAST")
		dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")
		start_block = 1

		if start_block then
			read record (ivm01_dev, key=firm_id$+item_id$, dom=*endif) ivm01a$
			callpoint!.setDevObject("inventoried",ivm01a.inventoried$)

		rem --- In Invoice Entry, non-inventoried lotted/serial can enter lots

			if ivm01a.lotser_item$="Y" then
				lotted$="Y"
			endif
		endif
	endif

	return

rem ==========================================================================
disp_ext_amt: rem --- Calculate and display the extended amount
              rem      IN: qty_shipped
              rem          unit_price
              rem     OUT: ext_price set
rem ==========================================================================

	previous_ext_price = num(callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE"))
	callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE", str(round(qty_shipped * unit_price, 2)) )
	rem print "---Ext price set to", qty_shipped * unit_price; rem debug
	gosub check_if_tax
	gosub disp_grid_totals
	callpoint!.setStatus("MODIFIED;REFRESH")

	return

rem ==========================================================================
set_item_taxable: rem --- Set the item taxable flag
rem ==========================================================================

	if pos(user_tpl.line_type$="SP") then
		item_id$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
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
credit_exceeded: rem --- Credit Limit Exceeded (ope_dd, 5500-5599)
rem ==========================================================================

	arm02_dev=fnget_dev("ARM_CUSTDET")
	dim arm02a$:fnget_tpl$("ARM_CUSTDET")
	read record (arm02_dev,key=firm_id$+callpoint!.getHeaderColumnData("OPE_ORDHDR.CUSTOMER_ID")+"  ",dom=*next) arm02a$
	if arm02a.cred_hold$<>"E"
		if user_tpl.credit_limit <> 0 and !user_tpl.credit_limit_warned then
			msg_id$ = "OP_OVER_CREDIT_LIMIT"
			dim msg_tokens$[1]
			msg_tokens$[1] = str(user_tpl.credit_limit:user_tpl.amount_mask$)
			gosub disp_message
			callpoint!.setHeaderColumnData("<<DISPLAY>>.CREDIT_HOLD", Translate!.getTranslation("AON_***_OVER_CREDIT_LIMIT_***"))
			callpoint!.setHeaderColumnData("OPE_ORDHDR.CREDIT_FLAG","C")
			callpoint!.setDevObject("msg_exceeded","Y")
			user_tpl.credit_limit_warned = 1
		endif
	endif
	return

rem ==========================================================================
able_backorder: rem --- All the factors for enabling or disabling back orders
rem ==========================================================================

	if user_tpl.allow_bo$ = "N" or 
:		pos(user_tpl.line_type$="MO") or
:		callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG") = "N" or
:		user_tpl.is_cash_sale
:	then
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.QTY_BACKORD", 0)
	else
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.QTY_BACKORD", 1)

		rem if user_tpl.new_detail then...

		if callpoint!.getRecordMode() = "A" then
			callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", "0")
         print "---BO qty cleared"; rem debug
		endif
	endif
    
	return

rem ==========================================================================
check_if_tax: rem --- Check If Taxable
rem ==========================================================================

	callpoint!.setColumnData("OPE_ORDDET.TAXABLE_AMT", "0")
	gosub calc_grid_totals

   if user_tpl.balance + ttl_ext_price > user_tpl.credit_limit then 
		gosub credit_exceeded
	endif

	if user_tpl.line_taxable$ = "Y" or 
:		( pos(user_tpl.line_type$="OMN") and user_tpl.item_taxable$ = "Y" )
:	then 
		callpoint!.setColumnData("OPE_ORDDET.TAXABLE_AMT", callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE"))
	endif

	return

rem ==========================================================================
#include std_missing_params.src
rem ==========================================================================

rem ==========================================================================
rem 	Use util object
rem ==========================================================================

	use ::ado_util.src::util
[[OPE_ORDDET.LINE_CODE.AVAL]]
print "Det:LINE_CODE:AVAL"; rem debug

rem --- Set enable/disable based on line type

	line_code$ = callpoint!.getUserInput()
	gosub disable_by_linetype

rem --- Has line code changed?

	if line_code$ <> user_tpl.prev_line_code$ then
		callpoint!.setColumnData("OPE_ORDDET.MAN_PRICE", "N")
		callpoint!.setColumnData("OPE_ORDDET.PRODUCT_TYPE", "")
		callpoint!.setColumnData("OPE_ORDDET.WAREHOUSE_ID", user_tpl.def_whse$)
		callpoint!.setColumnData("OPE_ORDDET.ITEM_ID", "")
		callpoint!.setColumnData("OPE_ORDDET.ORDER_MEMO", "")
		callpoint!.setColumnData("OPE_ORDDET.EST_SHP_DATE", callpoint!.getHeaderColumnData("OPE_ORDHDR.SHIPMNT_DATE"))
		callpoint!.setColumnData("OPE_ORDDET.COMMIT_FLAG", "Y")
		callpoint!.setColumnData("OPE_ORDDET.PICK_FLAG", "")
		callpoint!.setColumnData("OPE_ORDDET.VENDOR_ID", "")
		callpoint!.setColumnData("OPE_ORDDET.DROPSHIP", "")

		if opc_linecode.line_type$="O" then
			if cvs(callpoint!.getColumnData("OPE_ORDDET.ORDER_MEMO"),3) = "" then
				callpoint!.setColumnData("OPE_ORDDET.ORDER_MEMO",opc_linecode.code_desc$)
			endif
		endif

		gosub clear_all_numerics
		gosub clear_avail
		user_tpl.item_wh_failed = 1

	endif

rem --- Disable / Enable Backorder

	gosub able_backorder

rem --- set Product Type if indicated by line code record

	if opc_linecode.prod_type_pr$ = "D" 
		callpoint!.setColumnData("OPE_ORDDET.PRODUCT_TYPE", opc_linecode.product_type$)
	endif	
	if opc_linecode.prod_type_pr$ = "N"
		callpoint!.setColumnData("OPE_ORDDET.PRODUCT_TYPE", "")
	endif
