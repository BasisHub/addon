[[OPE_ORDDET.EXT_PRICE.BINP]]
rem --- Set previous extended price

	user_tpl.prev_ext_price  = num(callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE"))
[[OPE_ORDDET.ADGE]]
rem --- Disable header buttons

	callpoint!.setOptionEnabled("CRCH",0)
	callpoint!.setOptionEnabled("COMM",0)
	callpoint!.setOptionEnabled("CRAT",0)
	callpoint!.setOptionEnabled("DINV",0)
	callpoint!.setOptionEnabled("CINV",0)
	callpoint!.setOptionEnabled("PRNT",0)
	callpoint!.setOptionEnabled("RPRT",0)
[[OPE_ORDDET.EXT_PRICE.AVEC]]
rem --- Extend price now that grid vector has been updated, if the backorder quantity has changed
if num(callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE")) <> user_tpl.prev_ext_price then
	qty_shipped = num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
	unit_price = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
	gosub disp_ext_amt
endif
[[OPE_ORDDET.QTY_SHIPPED.AVEC]]
rem --- Extend price now that grid vector has been updated, if the shipped quantity has changed
qty_shipped = num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
if qty_shipped <> user_tpl.prev_shipqty then
	unit_price = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
	gosub disp_ext_amt
endif
[[OPE_ORDDET.QTY_BACKORD.AVEC]]
rem --- Extend price now that grid vector has been updated, if the backorder quantity has changed
if num(callpoint!.getColumnData("OPE_ORDDET.QTY_BACKORD")) <> user_tpl.prev_boqty then
	qty_shipped = num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
	unit_price = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
	gosub disp_ext_amt
endif
[[OPE_ORDDET.UNIT_PRICE.AVEC]]
rem --- Extend price now that grid vector has been updated, if the unit price has changed
unit_price = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
if unit_price <> user_tpl.prev_unitprice then
	qty_shipped = num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
	gosub disp_ext_amt
endif
[[OPE_ORDDET.LINE_CODE.AVEC]]
rem --- Line code may not be displayed correctly when selected via arrow key instead of mouse
	callpoint!.setStatus("REFRESH:LINE_CODE")
[[OPE_ORDDET.ITEM_ID.AINV]]
rem --- Check for item synonyms

	rem --- Get starting item so we know if it gets changed
	item_id$=callpoint!.getUserInput()

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::grid_entry"

	rem --- Item will not have changed if AVAL did an ABORT 
	if item_id$=callpoint!.getUserInput() then
		callpoint!.setFocus(num(callpoint!.getValidationRow()),"OPE_ORDDET.ITEM_ID",1)
	endif
[[OPE_ORDDET.WAREHOUSE_ID.BINP]]
rem --- Enable repricing, options, lots

	gosub enable_repricing
	gosub enable_addl_opts
	gosub able_lot_button

rem --- Force focus when Warehouse Code entry is skipped

	if callpoint!.getDevObject("skipWHCode") = "Y" then
		callpoint!.setDevObject("skipWHCode","N"); rem --- skip warehouse code entry only once
		if pos(user_tpl.line_type$="SP") then 
			callpoint!.setFocus(num(callpoint!.getValidationRow()),"OPE_ORDDET.ITEM_ID",1)
		else
			callpoint!.setFocus(num(callpoint!.getValidationRow()),"OPE_ORDDET.ORDER_MEMO",1)
		endif
		break
	endif
[[OPE_ORDDET.AOPT-ADDL]]
print "Det:AOPT.ADDL"; rem debug

rem --- Additional Options

	if user_tpl.line_type$ = "M" then break; rem --- exit callpoint

rem --- Save current context so we'll know where to return

	declare BBjStandardGrid grid!
	grid! = util.getGrid(Form!)
	grid_ctx=grid!.getContextID()

rem --- Setup a templated string to pass information back and forth from form

	declare BBjTemplatedString a!

	tmpl$ =  "LINE_TYPE:C(1)," +
:				"LINE_DROPSHIP:C(1)," +
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
	a!.setFieldValue("LINE_DROPSHIP",user_tpl.line_dropship$)
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

	committed_changed=0
	if callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE") <> "P" and user_tpl.line_dropship$ = "N" then

		if orig_commit$ = "Y" and callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG") = "N" then
			committed_changed=1
			if user_tpl.line_type$ <> "O" then
				callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", "0")
				callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED", "0")
				callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE", "0")
				callpoint!.setColumnData("OPE_ORDDET.TAXABLE_AMT", "0")
			else
				callpoint!.setColumnData("OPE_ORDDET.UNIT_PRICE", str(callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE")))
				callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE", "0")
				callpoint!.setColumnData("OPE_ORDDET.TAXABLE_AMT", "0")
			endif
		endif

		if orig_commit$ = "N" and callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG") = "Y" then
			committed_changed=1
			callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED", str(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED")))
			if user_tpl.line_taxable$ = "Y" and ( pos(user_tpl.line_type$ = "OMN") or user_tpl.item_taxable$ = "Y" ) then 
				callpoint!.setColumnData("OPE_ORDDET.TAXABLE_AMT", str(ext_price))
			endif

			if user_tpl.line_type$ = "O" and 
:			num(callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE")) = 0 and 
:			num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE")) 
:			then
				callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE", str(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE")))
				callpoint!.setColumnData("OPE_ORDDET.UNIT_PRICE", "0")
				callpoint!.setColumnData("OPE_ORDDET.STD_LIST_PRC", "0")
			endif
		endif

	endif

	rem --- Grid vector must be updated before updating Totals tab
	declare BBjVector dtlVect!
	dtlVect!=cast(BBjVector, GridVect!.getItem(0))
	dim dtl_rec$:dtlg_param$[1,3]
	dtl_rec$=cast(BBjString, dtlVect!.getItem(callpoint!.getValidationRow()))
	dtl_rec.commit_flag$=callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG")
	dtl_rec.est_shp_date$=callpoint!.getColumnData("OPE_ORDDET.EST_SHP_DATE")
	dtl_rec.std_list_prc=num(callpoint!.getColumnData("OPE_ORDDET.STD_LIST_PRC"))
	dtl_rec.disc_percent=num(callpoint!.getColumnData("OPE_ORDDET.DISC_PERCENT"))
	dtl_rec.unit_price=num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
	dtl_rec.qty_backord=num(callpoint!.getColumnData("OPE_ORDDET.QTY_BACKORD"))
	dtl_rec.qty_shipped=num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
	dtl_rec.ext_price=num(callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE"))
	dtl_rec.taxable_amt=num(callpoint!.getColumnData("OPE_ORDDET.TAXABLE_AMT"))
	dtlVect!.setItem(callpoint!.getValidationRow(),dtl_rec$)
	GridVect!.setItem(0,dtlVect!)

	qty_shipped = num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
	unit_price  = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
	gosub disp_ext_amt

	gosub able_lot_button
	gosub able_backorder
	gosub able_qtyshipped

	callpoint!.setStatus("REFRESH")

rem --- Return focus to where we were (Detail line grid)

	sysgui!.setContext(grid_ctx)
[[OPE_ORDDET.AGDR]]
rem --- Disable by line type

	line_code$ = callpoint!.getColumnData("OPE_ORDDET.LINE_CODE")
	gosub disable_by_linetype
[[OPE_ORDDET.UNIT_PRICE.BINP]]
rem --- Set previous unit price / enable repricing, options, lots

	user_tpl.prev_unitprice  = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
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
rem --- Extend price now that grid vector has been updated, if the order quantity has changed

if num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED")) <> user_tpl.prev_qty_ord then
	qty_shipped = num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
	unit_price = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
	gosub disp_ext_amt
endif

rem --- Enable buttons
	gosub able_lot_button
	gosub enable_repricing
	gosub enable_addl_opts

if callpoint!.getDevObject("focusPrice")="Y"
 	callpoint!.setFocus(callpoint!.getValidationRow(),"OPE_ORDDET.UNIT_PRICE",1)
endif
[[OPE_ORDDET.QTY_ORDERED.AVAL]]
rem --- Set shipped and back ordered

	qty_ord    = num(callpoint!.getUserInput())

	if qty_ord = 0 then
		msg_id$="OP_QTY_ZERO"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

	if qty_ord < 0 then
		callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED", str(qty_ord))
		callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", "0")
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

rem --- Recalc quantities

	unit_price = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
	if user_tpl.line_type$ <> "N" and
:		callpoint!.getColumnData("OPE_ORDDET.MAN_PRICE") <> "Y" and
:		( (qty_ord and qty_ord <> user_tpl.prev_qty_ord) or unit_price = 0 )
:	then
		gosub pricing
	endif
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

rem --- init devobject for use when forcing focus to price, if need-be

	callpoint!.setDevObject("focusPrice","")
[[OPE_ORDDET.ITEM_ID.BINP]]
rem --- Set previous item / enable repricing, options, lot

	user_tpl.prev_item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	gosub enable_repricing
	gosub enable_addl_opts
	gosub able_lot_button
[[OPE_ORDDET.LINE_CODE.BINP]]

rem --- Set previous value / enable repricing, options, lots

	user_tpl.prev_line_code$ = callpoint!.getColumnData("OPE_ORDDET.LINE_CODE")
	gosub enable_repricing
	gosub enable_addl_opts
	gosub able_lot_button

rem --- Force focus on Warehouse when Line Code entry is skipped

	if callpoint!.getDevObject("skipLineCode") = "Y" then
		callpoint!.setDevObject("skipLineCode","N"); rem --- skip line code entry only once
		if  callpoint!.getDevObject("skipWHCode") = "Y" then
			callpoint!.setDevObject("skipWHCode","N")
			callpoint!.setFocus(num(callpoint!.getValidationRow()),"OPE_ORDDET.ITEM_ID",1)
		else
			callpoint!.setFocus(num(callpoint!.getValidationRow()),"OPE_ORDDET.WAREHOUSE_ID",1)
		endif

		rem --- initialize detail line for default line_code
		line_code$ = callpoint!.getColumnData("OPE_ORDDET.LINE_CODE")
		gosub line_code_init
		break
	endif
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

rem --- Order quantity is required for S, N and P line types

	if pos(linecode_rec.line_type$="SNP") then
		if num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED")) = 0 then
			msg_id$="OP_QTY_ZERO"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
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

rem --- For uncommitted "O" line type sales (not quotes), move ext_price to unit_price until committed
	if callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE") <> "P" and
:	callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG") = "N" and user_tpl.line_type$ = "O" 
:	then
		rem --- Don't overwrite existing unit_price with zero
		if num(callpoint!.getUserInput()) then
			callpoint!.setColumnData("OPE_ORDDET.UNIT_PRICE", callpoint!.getUserInput())
			callpoint!.setUserInput("0")
			callpoint!.setColumnData("OPE_ORDDET.TAXABLE_AMT", "0")
			callpoint!.setStatus("REFRESH")
		endif
	endif
[[OPE_ORDDET.WAREHOUSE_ID.AVEC]]
rem --- Set Recalc Price button

	gosub enable_repricing
[[OPE_ORDDET.ITEM_ID.AVEC]]
rem --- Set buttons

	gosub enable_repricing
	gosub able_lot_button

rem --- Set item tax flag

	gosub set_item_taxable
[[OPE_ORDDET.AOPT-RCPR]]
rem --- Are things set for a reprice?

	if pos(user_tpl.line_type$="SP") then
		qty_ord = num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
		print "---Qty ordered:", qty_ord; rem debug

		if qty_ord then 

			rem --- Save current column so we'll know where to set focus when we return

			return_to_col = util.getGrid(Form!).getSelectedColumn()

			rem --- Do repricing

			gosub pricing

			rem --- Grid vector must be updated before updating Totals tab
			qty_shipped = num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
			unit_price = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
			declare BBjVector dtlVect!
			dtlVect!=cast(BBjVector, GridVect!.getItem(0))
			dim dtl_rec$:dtlg_param$[1,3]
			dtl_rec$=cast(BBjString, dtlVect!.getItem(callpoint!.getValidationRow()))
			dtl_rec.qty_shipped=qty_shipped
			dtl_rec.unit_price=unit_price
			dtlVect!.setItem(callpoint!.getValidationRow(),dtl_rec$)
			GridVect!.setItem(0,dtlVect!)
			gosub disp_ext_amt

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

	prior_whse$ = callpoint!.getDevObject("prior_whse")
	prior_item$ = callpoint!.getDevObject("prior_item")
	prior_qty   = callpoint!.getDevObject("prior_qty")
	prior_commit$=callpoint!.getDevObject("prior_commit")

rem --- Don't commit/uncommit Quotes or DropShips

	if user_tpl.line_dropship$ = "Y" or callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE") = "P" goto awri_update_hdr

rem --- Has there been any change?

	if callpoint!.getGridRowNewStatus(num(callpoint!.getValidationRow()))="Y" or
:		((curr_whse$ <> prior_whse$ or  curr_item$ <> prior_item$ or curr_qty   <> prior_qty) and curr_commit$ = prior_commit$)
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

rem --- Only do the next if the commit flag has been changed (i.e. via Additional button/form)
rem --- Note: AWRI will have been executed before launching that form to do first/main commit.
rem --- When form is dismissed, row is marked modified, so when leaving it, AWRI will fire again,
rem --- and that's when this code should be hit.

	if curr_commit$ <> prior_commit$

rem --- Initialize inventory item update
		status=999
		call user_tpl.pgmdir$+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
		if status then goto awri_update_hdr

		action$=""
		if curr_commit$ ="N" and prior_commit$ = "Y" then action$="UC"
		if curr_commit$ = "Y" and prior_commit$ <> "Y" then action$="CO"

		rem --- uncommit or commit, depending on action$

		if curr_qty<>0 and action$<>"" and curr_item$<>"" then
			items$[1] = curr_whse$
			items$[2] = curr_item$
			refs[0]   = curr_qty
			call user_tpl.pgmdir$+"ivc_itemupdt.aon",action$,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
		endif

	endif

awri_update_hdr: rem --- Update header

	rem --- disp_grid_totals already executed in AGRE, so no need to do it again here
	rem gosub disp_grid_totals

	file$ = "OPC_LINECODE"
	dim opc_linecode$:fnget_tpl$(file$)
	line_code$=callpoint!.getColumnData("OPE_ORDDET.LINE_CODE")
	find record (fnget_dev(file$), key=firm_id$+line_code$, dom=*endif) opc_linecode$

	if callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE") <> "P" 
		if opc_linecode.line_type$<>"M"
			callpoint!.setDevObject("details_changed","Y")
		endif
	endif

rem --- set prior's = curr's here, since row has been written
rem --- this way, if we stay on the same row, as will be the case if we've pressed Recalc, Lot/Ser, or Additional buttons,
rem --- then next time thru AWRI it won't see a false difference between curr and pri, so won't over-commit

	callpoint!.setDevObject("prior_whse", curr_whse$)
	callpoint!.setDevObject("prior_item", curr_item$)
	callpoint!.setDevObject("prior_qty", curr_qty)
	callpoint!.setDevObject("prior_commit", curr_commit$)
[[OPE_ORDDET.BDGX]]
rem --- Disable detail-only buttons

	callpoint!.setOptionEnabled("LENT",0)
	callpoint!.setOptionEnabled("RCPR",0)
	callpoint!.setOptionEnabled("ADDL",0)

rem --- Set header total amounts

	use ::ado_order.src::OrderHelper

	cust_id$  = callpoint!.getColumnData("OPE_ORDDET.CUSTOMER_ID")
	order_no$ = callpoint!.getColumnData("OPE_ORDDET.ORDER_NO")
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
rem --- Save current context so we'll know where to return from lot lookup

	declare BBjStandardGrid grid!
	grid! = util.getGrid(Form!)
	grid_ctx=grid!.getContextID()

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
			callpoint!.setDevObject("ord_qty", callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
			callpoint!.setDevObject("qty_shipped",callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
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
			unit_price  = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
			callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED", str(qty_shipped))
			callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE", str(round(qty_shipped * unit_price, 2)))

			qty_ordered = num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
			if qty_ordered > 0 then
				qty_backord=max(qty_ordered - qty_shipped, 0)
			else
				qty_backord=min(qty_ordered - qty_shipped, 0)
			endif
			callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", str(qty_backord))

			rem --- Grid vector must be updated before updating the discount amount
			declare BBjVector dtlVect!
			dtlVect!=cast(BBjVector, GridVect!.getItem(0))
			dim dtl_rec$:dtlg_param$[1,3]
			dtl_rec$=cast(BBjString, dtlVect!.getItem(callpoint!.getValidationRow()))
			if dtl_rec.qty_shipped=qty_shipped
				qty_shipped_changed=0
			else
				dtl_rec.qty_shipped=qty_shipped
				dtl_rec.qty_backord=qty_backord
				dtl_rec.ext_price=round(qty_shipped * unit_price, 2)
				qty_shipped_changed=1
				dtlVect!.setItem(callpoint!.getValidationRow(),dtl_rec$)
				GridVect!.setItem(0,dtlVect!)
			endif

			gosub disp_ext_amt
			callpoint!.setStatus("REFRESH")

		rem --- Return focus to where we were (Detail line grid)

			sysgui!.setContext(grid_ctx)

		endif
	endif
[[OPE_ORDDET.BUDE]]
rem --- add and recommit Lot/Serial records (if any) and detail lines if not

	if callpoint!.getGridRowNewStatus(num(callpoint!.getValidationRow()))<>"Y" and
:		callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG")="Y"
:	then
		action$="CO"
		gosub uncommit_iv
	endif
[[OPE_ORDDET.AREC]]
rem --- Backorder is zero and disabled on a new record

	callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", "0")
	callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.QTY_BACKORD", 0)

rem --- Set defaults for new record

	inv_type$  = callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE")
	ship_date$ = callpoint!.getHeaderColumnData("OPE_ORDHDR.SHIPMNT_DATE")

	callpoint!.setColumnData("OPE_ORDDET.MAN_PRICE", "N")
	callpoint!.setColumnData("OPE_ORDDET.EST_SHP_DATE", ship_date$)

	rem --- For new lines may want to skip line code entry the first time.
	callpoint!.setDevObject("skipLineCode",user_tpl.skip_ln_code$)

	rem --- For new lines may want to skip warehouse code entry the first time.
	callpoint!.setDevObject("skipWHCode",user_tpl.skip_whse$)

	rem --- Get line type of default line
	file$ = "OPC_LINECODE"
	dim opc_linecode$:fnget_tpl$(file$)
	find record (fnget_dev(file$), key=firm_id$+user_tpl.line_code$, dom=*next) opc_linecode$

	rem --- Allow blank memo lines when default line code is a Memo line type
	if opc_linecode.line_type$="M" then
		line_code$=user_tpl.line_code$
		gosub line_code_init
		callpoint!.setStatus("MODIFIED")
	endif

	if inv_type$ = "P" or ship_date$ > user_tpl.def_commit$ then
 		callpoint!.setColumnData("OPE_ORDDET.COMMIT_FLAG", "N")
	else
		callpoint!.setColumnData("OPE_ORDDET.COMMIT_FLAG", "Y")
 	endif

rem --- Buttons start disabled

	callpoint!.setOptionEnabled("LENT",0)
	callpoint!.setOptionEnabled("RCPR",0)
	callpoint!.setOptionEnabled("ADDL",0)
	callpoint!.setStatus("REFRESH")
[[OPE_ORDDET.BDEL]]
rem --- remove and uncommit Lot/Serial records (if any) and detail lines if not

	if callpoint!.getGridRowNewStatus(num(callpoint!.getValidationRow()))<>"Y" and
:		callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG")="Y"
:	then
		action$="UC"
		gosub uncommit_iv
	endif
[[OPE_ORDDET.AGRN]]
rem (Fires regardles of new or existing row.  Use callpoint!.getGridRowNewStatus(callpoint!.getValidationRow()) to distinguish the two)

rem --- See if we're coming back from Recalc button

	if callpoint!.getDevObject("rcpr_row") <> ""
		callpoint!.setFocus(num(callpoint!.getDevObject("rcpr_row")),"OPE_ORDDET.UNIT_PRICE")
		callpoint!.setDevObject("rcpr_row","")
		callpoint!.setDevObject("details_changed","Y")
		break
	endif

rem --- Disable by line type (Needed because Barista is skipping Line Code)

	if callpoint!.getGridRowNewStatus(num(callpoint!.getValidationRow())) <> "Y"
		line_code$ = callpoint!.getColumnData("OPE_ORDDET.LINE_CODE")
		gosub disable_by_linetype
    else
        gosub able_backorder
        gosub able_qtyshipped
	endif

rem --- Disable cost if necessary

	if pos(user_tpl.line_type$="SP") and num(callpoint!.getColumnData("OPE_ORDDET.UNIT_COST")) then
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.UNIT_COST", 0)
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

	round_precision = num(callpoint!.getDevObject("precision"))
	user_tpl.prev_ext_price  = num(callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE"))
	user_tpl.prev_ext_cost   = round(num(callpoint!.getColumnData("OPE_ORDDET.UNIT_COST")) * num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED")),round_precision)
	user_tpl.prev_line_code$ = callpoint!.getColumnData("OPE_ORDDET.LINE_CODE")
	user_tpl.prev_item$      = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	user_tpl.prev_qty_ord    = num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	user_tpl.prev_boqty      = num(callpoint!.getColumnData("OPE_ORDDET.QTY_BACKORD"))
	user_tpl.prev_shipqty    = num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
	user_tpl.prev_unitprice  = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
	callpoint!.setDevObject("prior_whse",callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID"))
	callpoint!.setDevObject("prior_item",callpoint!.getColumnData("OPE_ORDDET.ITEM_ID"))
	callpoint!.setDevObject("prior_qty",user_tpl.prev_qty_ord)
	callpoint!.setDevObject("prior_commit",callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG"))

	callpoint!.setDevObject("whse_item_warned","")

rem --- Set buttons

	gosub able_lot_button

	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow()) <> "Y" then
		gosub enable_repricing
		gosub enable_addl_opts
	endif

rem --- Set availability info

	gosub set_avail

rem --- May want to skip line code entry, and/or warehouse code entry, the first time.
	callpoint!.setDevObject("skipLineCode",user_tpl.skip_ln_code$)
	callpoint!.setDevObject("skipWHCode",user_tpl.skip_whse$)
[[OPE_ORDDET.AGRE]]
rem --- Skip if (not a new row and not row modifed) or row deleted

	this_row = callpoint!.getValidationRow()
	if callpoint!.getGridRowNewStatus(this_row) <> "Y" and callpoint!.getGridRowModifyStatus(this_row) <> "Y" then
		break; rem --- exit callpoint
	endif

	if  callpoint!.getGridRowDeleteStatus(this_row) = "Y"
		break; rem --- exit callpoint
	endif

	user_tpl.detail_modified = 1
	
rem --- Warehouse and Item must be correct, don't let user leave corrupt row

	wh$   = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
	item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	warn  = 1

	gosub check_item_whse	

	if user_tpl.item_wh_failed then 
		callpoint!.setFocus(this_row,"OPE_ORDDET.WAREHOUSE_ID",1)
		break; rem --- exit callpoint
	endif

rem --- Returns

	if num( callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED") ) < 0 then
		callpoint!.setColumnData( "OPE_ORDDET.QTY_SHIPPED", callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
		callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", "0")
	endif

rem --- Verify Qty Ordered is not 0

	if pos(user_tpl.line_type$="SNP") then
		if num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED")) = 0
			msg_id$="OP_QTY_ZERO"
			gosub disp_message
			callpoint!.setFocus(this_row,"OPE_ORDDET.QTY_ORDERED",1)
			callpoint!.setStatus("ABORT")
			break; rem --- exit callpoint
		endif
	endif

rem --- What is extended price?

	unit_price = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))

	if pos(user_tpl.line_type$="SNP") then
		ext_price = round( num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED")) * unit_price, 2 )
	else
		ext_price = round( num(callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE")), 2 )
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
		callpoint!.setColumnData("OPE_ORDDET.DISC_PERCENT", str(round(100 - unit_price * 100 / std_price, 2)))
	else
		if disc_per <> 100 then
			round_precision = num(callpoint!.getDevObject("precision"))
			callpoint!.setColumnData("OPE_ORDDET.STD_LIST_PRC", str(round(unit_price * 100 / (100 - disc_per), round_precision)))
		endif
	endif
	
rem --- For uncommitted "O" line type sales (not quotes), move ext_price to unit_price until committed

	if callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE") <> "P" and
:		callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG") = "N"         and
:		user_tpl.line_type$ = "O"                                        and
:		ext_price <> 0
:	then
		callpoint!.setColumnData("OPE_ORDDET.UNIT_PRICE", str(round(ext_price, 2)))
		callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE", "0")
		callpoint!.setColumnData("OPE_ORDDET.TAXABLE_AMT", "0")
	endif

rem --- Set header order totals

	gosub disp_grid_totals

rem --- Has customer credit been exceeded?

	if user_tpl.balance - user_tpl.prev_ext_price + ttl_ext_price > user_tpl.credit_limit then 
		gosub credit_exceeded
	endif

	callpoint!.setStatus("MODIFIED-REFRESH")
[[OPE_ORDDET.UNIT_PRICE.AVAL]]
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

rem --- Don't extend price until grid vector has been updated
	rem qty_shipped = num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
	rem gosub disp_ext_amt
[[OPE_ORDDET.AUDE]]
rem --- redisplay totals

	gosub disp_grid_totals

	callpoint!.setDevObject("details_changed","Y")
[[OPE_ORDDET.ADEL]]
rem --- redisplay totals

	gosub disp_grid_totals

	callpoint!.setDevObject("details_changed","Y")
[[OPE_ORDDET.WAREHOUSE_ID.AVAL]]
rem --- Check item/warehouse combination, Set Available

	wh$   = callpoint!.getUserInput()

	if wh$<>callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID") then
		gosub clear_all_numerics
		callpoint!.setStatus("REFRESH")
	endif

	item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	if cvs(item$,2)="" then
		warn = 0
	else
		rem --- Skip warning if already warned for this whse-item combination
		if callpoint!.getDevObject("whse_item_warned")=wh$+":"+item$ then
			warn = 0
		else
			warn = 1
		endif
	endif
	gosub check_item_whse

rem --- Item probably isn't set yet, but we don't know for sure

	if !user_tpl.item_wh_failed then gosub set_avail
[[OPE_ORDDET.ITEM_ID.AVAL]]
rem --- Check item/warehouse combination and setup values

	item$ = callpoint!.getUserInput()

	if item$<>user_tpl.prev_item$ then
		gosub clear_all_numerics
	endif

	wh$   = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
	if cvs(wh$,2)="" then
		warn = 0
	else
		rem --- Skip warning if already warned for this whse-item combination
		if callpoint!.getDevObject("whse_item_warned")=wh$+":"+item$ then
			warn = 0
		else
			warn = 1
		endif
	endif
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
rem --- recalc quantities and extended price

	shipqty    = num(callpoint!.getUserInput())
	ordqty     = num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	cash_sale$ = callpoint!.getHeaderColumnData("OPE_ORDHDR.CASH_SALE")

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
	else
		if user_tpl.prev_shipqty <> shipqty then
			callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", str(max(0, ordqty - shipqty)) )
			callpoint!.setStatus("REFRESH")
		endif
	endif

rem --- Don't extend price until grid vector has been updated
	rem qty_shipped = shipqty
	rem unit_price  = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
	rem gosub disp_ext_amt
[[OPE_ORDDET.QTY_BACKORD.AVAL]]
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

rem --- Don't extend price until grid vector has been updated
	rem unit_price = num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
	rem gosub disp_ext_amt
[[OPE_ORDDET.<CUSTOM>]]
rem ==========================================================================
disp_grid_totals: rem --- Get order totals and display, save header totals
rem ==========================================================================

	gosub calculate_discount

	freight_amt = num(callpoint!.getHeaderColumnData("OPE_ORDHDR.FREIGHT_AMT"))
	sub_tot = ttl_ext_price - disc_amt
	net_sales = sub_tot + ttl_tax + freight_amt

	salesamt! = UserObj!.getItem(num(callpoint!.getDevObject("total_sales_disp")))
	salesamt!.setValue(ttl_ext_price)
	discamt! = UserObj!.getItem(num(callpoint!.getDevObject("disc_amt_disp")))
	discamt!.setValue(disc_amt)
	subamt! = UserObj!.getItem(num(callpoint!.getDevObject("subtot_disp")))
	subamt!.setValue(sub_tot)
	netamt! = UserObj!.getItem(num(callpoint!.getDevObject("net_sales_disp")))
	netamt!.setValue(net_sales)
	taxamt! = UserObj!.getItem(num(callpoint!.getDevObject("tax_amt_disp")))
	taxamt!.setValue(ttl_tax)
rem	frghtamt! = UserObj!.getItem(num(callpoint!.getDevObject("freight_amt")))
rem	frghtamt!.setValue(freight_amt)
	ordamt! = UserObj!.getItem(user_tpl.ord_tot_obj)
	ordamt!.setValue(net_sales)

	callpoint!.setHeaderColumnData("OPE_ORDHDR.TOTAL_SALES", str(ttl_ext_price))
	callpoint!.setHeaderColumnData("OPE_ORDHDR.DISCOUNT_AMT",str(disc_amt))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.SUBTOTAL", str(sub_tot))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.NET_SALES", str(net_sales))
	callpoint!.setHeaderColumnData("OPE_ORDHDR.TAX_AMOUNT", str(ttl_tax))
	callpoint!.setHeaderColumnData("OPE_ORDHDR.FREIGHT_AMT",str(freight_amt))
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

	gosub calc_grid_totals

	rem --- Don't update discount unless extended price has changed, otherwise might overwrite manually entered discount.
	rem --- Must always update for a new, deleted  or undeleted record, or when from lot/serial entry and qty_shipped was 
	rem --- changed, or when from Additional and committed was changed.
	disc_amt=num(callpoint!.getHeaderColumnData("OPE_ORDHDR.DISCOUNT_AMT"))
	if user_tpl.prev_ext_price<>num(callpoint!.getColumnData("OPE_ORDDET.EXT_PRICE")) or 
:	callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" or
:	callpoint!.getGridRowDeleteStatus(callpoint!.getValidationRow())="Y" or
:	callpoint!.getEvent()="AUDE" or
:	(callpoint!.getEvent()="AOPT-LENT" and qty_shipped_changed) or
:	(callpoint!.getEvent()="AOPT-ADDL" and committed_changed) then
		disc_code$=callpoint!.getDevObject("disc_code")

		file_name$ = "OPC_DISCCODE"
		disccode_dev = fnget_dev(file_name$)
		dim disccode_rec$:fnget_tpl$(file_name$)

		find record (disccode_dev, key=firm_id$+disc_code$, dom=*next) disccode_rec$

		ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))
		if ordHelp!.getInv_type() = "" then
			ttl_ext_price = 0
		else
            ttl_ext_price=totalsVect!.getItem(0)
		endif

		disc_amt = round(disccode_rec.disc_percent * ttl_ext_price / 100, 2)
		callpoint!.setHeaderColumnData("OPE_ORDHDR.DISCOUNT_AMT",str(disc_amt))
	endif

	return

rem ==========================================================================
calc_grid_totals: rem --- Roll thru all detail lines, totaling ext_price
                  rem     OUT: ttl_ext_price
rem ==========================================================================

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))

	if ordHelp!.getInv_type() = "" then
		ttl_ext_price = 0
		ttl_ext_cost = 0
		ttl_taxable = 0
	else
		totalsVect!=ordHelp!.totalSalesCostTaxable(cast(BBjVector, GridVect!.getItem(0)), cast(Callpoint, callpoint!))
		ttl_ext_price=totalsVect!.getItem(0)
		ttl_ext_cost=totalsVect!.getItem(1)
		ttl_taxable=totalsVect!.getItem(2)
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
	enter_price_message = 0
	callpoint!.setDevObject("focusPrice","")

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
		enter_price_message = 1
		callpoint!.setDevObject("focusPrice","Y")
		callpoint!.setStatus("ACTIVATE")
	else
		callpoint!.setColumnData("OPE_ORDDET.UNIT_PRICE", str(round(price, round_precision)) )
		callpoint!.setColumnData("OPE_ORDDET.DISC_PERCENT", str(disc))
		callpoint!.setDevObject("focusPrice","")
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
	if pos(user_tpl.line_type$="NSP")
		callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE", str(round(qty_shipped * unit_price, 2)) )
	endif

	user_tpl.prev_unitprice = unit_price

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

	if cvs(item$, 2)<>"" and cvs(wh$, 2)<>"" and ord_qty and ord_type$<>"P" and user_tpl.line_dropship$ = "N" then
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
		rem --- <<CALLPOINT>> enable in item#, memo, ordered, price and ext price on form handles enable/disable
		rem --- based strictly on line type, via the callpoint!.setStatus("ENABLE:"+opc_linecode.line_type$) command.
		rem --- cost, product type, backordered and shipped are enabled/disabled directly based on additional conditions
		rem      IN: line_code$
rem =============================================================================

	file$ = "OPC_LINECODE"
	dim opc_linecode$:fnget_tpl$(file$)
	find record (fnget_dev(file$), key=firm_id$+line_code$, dom=*next) opc_linecode$
	rem --- Shouldn't be possible to have a bad line_code$ at this point.
	rem --- If it happens, add error trap to send to OPE_ORDDET.LINE_CODE.

	callpoint!.setStatus("ENABLE:"+opc_linecode.line_type$)
	user_tpl.line_type$     = opc_linecode.line_type$
	user_tpl.line_taxable$  = opc_linecode.taxable_flag$
	user_tpl.line_dropship$ = opc_linecode.dropship$
	user_tpl.line_prod_type_pr$ = opc_linecode.prod_type_pr$


	if pos(opc_linecode.line_type$="SP")>0 and num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))<>0
		callpoint!.setOptionEnabled("RCPR",1)
	else
		callpoint!.setOptionEnabled("RCPR",0)
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
	gosub able_backorder

rem --- Disable qty shipped if necessary
	gosub able_qtyshipped

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
				callpoint!.setDevObject("whse_item_warned",wh$+":"+item$)
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

	return

rem ==========================================================================
enable_addl_opts: rem --- Enable the Additional Options button
rem ==========================================================================

	if user_tpl.line_type$ <> "M" then 
		item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
		wh$   = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
		warn  = 0
		gosub check_item_whse

		if (!user_tpl.item_wh_failed and num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))) or
:		user_tpl.line_type$ = "O" then
			callpoint!.setOptionEnabled("ADDL",1)
		else
			callpoint!.setOptionEnabled("ADDL",0)
		endif
	endif

	return

rem ==========================================================================
enable_repricing: rem --- Enable the Recalc Pricing button
rem ==========================================================================

	if pos(user_tpl.line_type$="SP") then 
		item$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
		wh$   = callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
		warn  = 0
		gosub check_item_whse

		if !user_tpl.item_wh_failed and num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED")) then
			callpoint!.setOptionEnabled("RCPR",1)
		endif
	endif

	return

rem ==========================================================================
able_lot_button: rem --- Enable/disable Lot/Serial button
                 rem     OUT: lotted$
rem ==========================================================================

	item_id$ = callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	qty_ord  = num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	gosub lot_ser_check

	if lotted$ = "Y" and qty_ord <> 0 and 
:	callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE")<>"P" and
:	callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG") = "Y" 
:	then
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
              rem           unit_price
              rem     OUT: ext_price set
rem ==========================================================================

	if pos(user_tpl.line_type$="NSP")
		rem --- Grid vector must be updated before updating Totals tab
		ext_price=round(qty_shipped * unit_price, 2)
		callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE", str(ext_price) )
		declare BBjVector dtlVect!
		dtlVect!=cast(BBjVector, GridVect!.getItem(0))
		dim dtl_rec$:dtlg_param$[1,3]
		dtl_rec$=cast(BBjString, dtlVect!.getItem(callpoint!.getValidationRow()))
		dtl_rec.ext_price=ext_price
		dtlVect!.setItem(callpoint!.getValidationRow(),dtl_rec$)
		GridVect!.setItem(0,dtlVect!)
	endif
	gosub disp_grid_totals
	gosub check_if_tax
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
:	pos(user_tpl.line_type$="MO") or
:	callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG") = "N" or
:	callpoint!.getHeaderColumnData("OPE_ORDHDR.CASH_SALE") = "Y"
:	then
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.QTY_BACKORD", 0)
	else
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.QTY_BACKORD", 1)

		if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow()) = "Y" then
			callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD", "0")
		endif
	endif
    
	return

rem ==========================================================================
able_qtyshipped: rem --- All the factors for enabling or disabling qty shipped
rem ==========================================================================

	if pos(user_tpl.line_type$="NSP") and
:	callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG") = "Y"
:	then
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.QTY_SHIPPED", 1)
	else
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"OPE_ORDDET.QTY_SHIPPED", 0)
	endif

    
	return

rem ==========================================================================
check_if_tax: rem --- Check If Taxable
rem ==========================================================================

	callpoint!.setColumnData("OPE_ORDDET.TAXABLE_AMT", "0")

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
line_code_init: rem --- Initialize detail line for this line_code
rem ==========================================================================

	rem --- Set enable/disable based on line type
	gosub disable_by_linetype

	rem --- Has line code changed?
	if line_code$ <> user_tpl.prev_line_code$ then
		user_tpl.prev_line_code$=line_code$
		callpoint!.setColumnData("OPE_ORDDET.MAN_PRICE", "N")
		callpoint!.setColumnData("OPE_ORDDET.PRODUCT_TYPE", "")
		callpoint!.setColumnData("OPE_ORDDET.WAREHOUSE_ID", user_tpl.def_whse$)
		callpoint!.setColumnData("OPE_ORDDET.ITEM_ID", "")
		callpoint!.setColumnData("OPE_ORDDET.ORDER_MEMO", "")
		callpoint!.setColumnData("OPE_ORDDET.EST_SHP_DATE", callpoint!.getHeaderColumnData("OPE_ORDHDR.SHIPMNT_DATE"))
		callpoint!.setColumnData("OPE_ORDDET.PICK_FLAG", "")
		callpoint!.setColumnData("OPE_ORDDET.VENDOR_ID", "")
		callpoint!.setColumnData("OPE_ORDDET.DROPSHIP", "")

		if callpoint!.getHeaderColumnData("OPE_ORDHDR.INVOICE_TYPE") = "P" or 
:		callpoint!.getHeaderColumnData("OPE_ORDHDR.SHIPMNT_DATE") > user_tpl.def_commit$ 
:		then
 			callpoint!.setColumnData("OPE_ORDDET.COMMIT_FLAG", "N")
		else
			callpoint!.setColumnData("OPE_ORDDET.COMMIT_FLAG", "Y")
	 	endif

		if opc_linecode.line_type$="O" then
			if cvs(callpoint!.getColumnData("OPE_ORDDET.ORDER_MEMO"),3) = "" then
				callpoint!.setColumnData("OPE_ORDDET.ORDER_MEMO",opc_linecode.code_desc$)
			endif
		endif

		gosub clear_all_numerics
		gosub clear_avail
		user_tpl.item_wh_failed = 1
	endif

	rem --- set Product Type if indicated by line code record
	if opc_linecode.prod_type_pr$ = "D" 
		callpoint!.setColumnData("OPE_ORDDET.PRODUCT_TYPE", opc_linecode.product_type$)
	endif	
	if opc_linecode.prod_type_pr$ = "N"
		callpoint!.setColumnData("OPE_ORDDET.PRODUCT_TYPE", "")
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
rem --- Initialize detail line for this line_code

	line_code$ = callpoint!.getUserInput()
	gosub line_code_init
