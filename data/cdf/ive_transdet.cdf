[[IVE_TRANSDET.AGRN]]
print "after grid row entry (AGRN)"; rem debug

rem --- Set item/warehouse defaults

	item$ = callpoint!.getColumnData("IVE_TRANSDET.ITEM_ID")
	whse$ = callpoint!.getColumnData("IVE_TRANSDET.WAREHOUSE_ID")
	gosub get_whse_item

rem --- Disable cost entry until we know it's legal

	util.disableGridCell(Form!, 10); rem --- Cost
[[IVE_TRANSDET.LOTSER_NO.AVAL]]
print "in LOTSER_NO.AVAL"; rem debug

rem --- Read the lot/Serial# record, if found

	whse$  = callpoint!.getColumnData("IVE_TRANSDET.WAREHOUSE_ID")
	item$  = callpoint!.getColumnData("IVE_TRANSDET.ITEM_ID")
	ls_no$ = callpoint!.getUserInput()

	ls_file$ = "IVM_LSMASTER"
	dim ls_rec$:fnget_tpl$(ls_file$)
	user_tpl.ls_found = 0

	find record (fnget_dev(ls_file$), key=firm_id$+whse$+item$+ls_no$, dom=ls_not_found) ls_rec$
	user_tpl.ls_found = 1
	print "lot ", ls_no$, " found"; rem debug

	rem --- Set header display values

	m9$     = user_tpl.m9$
	loc$    = ls_rec.ls_location$
	qoh$    = str( ls_rec.qty_on_hand:m9$ )
	commit$ = str( ls_rec.qty_commit:m9$ )
	avail   = ls_rec.qty_on_hand - ls_rec.qty_commit
	avail$  = str( avail:m9$ )
			
	user_tpl.avail  = avail
	user_tpl.commit = ls_rec.qty_commit
	user_tpl.qoh    = ls_rec.qty_on_hand

	gosub set_display_fields
	
ls_not_found:

	rem --- Enable/disable comment and location fields based on whether L/S found

	gosub ls_loc_cmt

	rem --- Check lot/serial quantities

	gosub test_ls
[[IVE_TRANSDET.LOTSER_NO.BINP]]
print "in LOTSER_NO.BINP"; rem debug

rem --- Should user enter a lot of look it up?

	rem --- Receipts and negative Adjustments require new lot entry

	trans_qty = num( callpoint!.getColumnData("IVE_TRANSDET.TRANS_QTY") )
	if user_tpl.trans_type$ = "R" or (user_tpl.trans_type$ = "A" and trans_qty < 0 ) then 
		print "Trans Type: ", user_tpl.trans_type$
		print "Receipt or negative Adjustment, exitting..."
		break; rem --- exit callpoint
	endif

rem --- Call the lot lookup window and set default lot, lot location, lot comment and qty

	rem --- Save current row/column so we'll know where to set focus when we return from lot lookup

	declare BBjStandardGrid grid!
	grid! = util.getGrid(Form!)
	return_to_row = grid!.getSelectedRow()
	return_to_col = grid!.getSelectedColumn()

	rem --- Set data for the lookup form

	item$ = callpoint!.getColumnData("IVE_TRANSDET.ITEM_ID")
	whse$ = callpoint!.getColumnData("IVE_TRANSDET.WAREHOUSE_ID")

	if item$ = "" or whse$ = "" then 
		callpoint!.setMessage("IV_NO_ITEM_WHSE")
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

	dim dflt_data$[3,1]
	dflt_data$[1,0] = "ITEM_ID"
	dflt_data$[1,1] = item$
	dflt_data$[2,0] = "WAREHOUSE_ID"
	dflt_data$[2,1] = whse$
	dflt_data$[3,0] = "LOTS_TO_DISP"
	dflt_data$[3,1] = "O"; rem --- Open lots only

	rem --- Call the lookup form

	print "Launching Lot Lookup..."; rem debug
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	                       "IVC_LOTLOOKUP",
:	                       stbl("+USER_ID"),
:	                       "",
:	                       "",
:	                       table_chans$[all],
:	                       "",
:	                       dflt_data$[all]

	rem --- Set the detail grid to the data selected in the lookup

	if callpoint!.getDevObject("selected_lot") <> null() then
		callpoint!.setColumnData( "IVE_TRANSDET.LOTSER_NO",   str(callpoint!.getDevObject("selected_lot"))  )
		callpoint!.setColumnData( "IVE_TRANSDET.LS_LOCATION", str(callpoint!.getDevObject("selected_lot_loc")) )
		callpoint!.setColumnData( "IVE_TRANSDET.LS_COMMENTS", str(callpoint!.getDevObject("selected_lot_cmt")) )
		rem user_tpl.avail = num( callpoint!.getDevObject("selected_lot_avail") )
		rem callpoint!.setStatus("MODIFIED-REFRESH")
		callpoint!.setStatus("REFRESH")
		rem callpoint!.setStatus("REFGRID")
		print "Set Lot, Location, and Comment"; rem debug
	endif

	rem --- return focus to where we were (lot number)
	util.forceEdit(Form!, return_to_row, return_to_col)
	
[[IVE_TRANSDET.BUDE]]
print "before record undelete (BUDE)"; rem debug

rem --- Re-commit quantity

	status = 999
	call user_tpl.pgmdir$+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
	if status then goto std_exit

	curr_whse$   = callpoint!.getColumnData("IVE_TRANSDET.WAREHOUSE_ID")
	curr_item$   = callpoint!.getColumnData("IVE_TRANSDET.ITEM_ID")
	curr_qty     = num( callpoint!.getColumnData("IVE_TRANSDET.TRANS_QTY") )
	curr_lotser$ = callpoint!.getColumnData("IVE_TRANSDET.LOTSER_NO")

	if curr_whse$ <> "" and curr_item$ <> "" and curr_qty <> 0 then 
		print "re-committing item ", curr_item$, ", amount", curr_qty; rem debug

		rem --- Adjustments reverse the commitment
		if user_tpl.trans_type$ = "A" then 
			refs[0] = -curr_qty 
		else 
			refs[0] = curr_qty
		endif

		items$[1] = curr_whse$
		items$[2] = curr_item$
		items$[3] = curr_lotser$
		call user_tpl.pgmdir$+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
	endif
[[IVE_TRANSDET.BDEL]]
print "before record delete (BDEL)"; rem debug

rem --- Uncommit quantity

	status = 999
	call user_tpl.pgmdir$+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
	if status then goto std_exit

	curr_whse$   = callpoint!.getColumnData("IVE_TRANSDET.WAREHOUSE_ID")
	curr_item$   = callpoint!.getColumnData("IVE_TRANSDET.ITEM_ID")
	curr_qty     = num( callpoint!.getColumnData("IVE_TRANSDET.TRANS_QTY") )
	curr_lotser$ = callpoint!.getColumnData("IVE_TRANSDET.LOTSER_NO")

	if curr_whse$ <> "" and curr_item$ <> "" and curr_qty <> 0 then 
		print "uncommitting item ", curr_item$, ", amount", curr_qty; rem debug

		rem --- Adjustments reverse the commitment
		if user_tpl.trans_type$ = "A" then 
			refs[0] = -curr_qty 
		else 
			refs[0] = curr_qty
		endif

		items$[1] = curr_whse$
		items$[2] = curr_item$
		items$[3] = curr_lotser$
		call user_tpl.pgmdir$+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
	endif
[[IVE_TRANSDET.AREC]]
print "after new record (AREC)"; rem debug

rem --- Display defaults for this row

	if user_tpl.multi_whse$ <> "Y" then
		callpoint!.setColumnData("IVE_TRANSDET.WAREHOUSE_ID",user_tpl.warehouse_id$)
		print "Set default warehouse"; rem debug
	endif

	if user_tpl.gl$ = "Y" and user_tpl.trans_post_gl$ = "Y" then
		callpoint!.setColumnData("IVE_TRANSDET.GL_ACCOUNT",user_tpl.trans_adj_acct$)
		print "Set default GL account"; rem debug
	endif

	callpoint!.setStatus("REFRESH")
	rem callpoint!.setStatus("MODIFIED-REFRESH")
	rem callpoint!.setStatus("REFGRID")
[[IVE_TRANSDET.AGCL]]
print "after grid clear (AGCL)"; rem debug

	rem --- We'll be using the "util" object throughout.
	rem --- It doesn't matter where the "use" statement is
	use ::ado_util.src::util
[[IVE_TRANSDET.TRANS_QTY.BINP]]
print "in TRANS_QTY.BINP"; rem debug

rem --- Serialized receipt or issue must be 1

 	if user_tpl.trans_type$ = "I" or user_tpl.trans_type$ = "R" then
		if user_tpl.this_item_lot_or_ser and user_tpl.serialized then
			if num( callpoint!.getColumnData("IVE_TRANSDET.TRANS_QTY") ) = 0 then
				callpoint!.setColumnData("IVE_TRANSDET.TRANS_QTY","1")
				print "Set quantity to one because this item is serialized"; rem debug
				rem callpoint!.setStatus("MODIFIED-REFRESH")
				callpoint!.setStatus("REFRESH")
			endif
		endif
	endif
[[IVE_TRANSDET.WAREHOUSE_ID.AVAL]]
rem --- Set item/warehouse defaults

	item$ = callpoint!.getColumnData("IVE_TRANSDET.ITEM_ID")
	whse$ = callpoint!.getUserInput()
	gosub get_whse_item
[[IVE_TRANSDET.UNIT_COST.AVAL]]
rem --- Calculate and display extended cost

	unit_cost = num( callpoint!.getUserInput() )
	trans_qty = num( callpoint!.getColumnData("IVE_TRANSDET.TRANS_QTY") )
	gosub calc_ext_cost
[[IVE_TRANSDET.<CUSTOM>]]
rem ==========================================================================
calc_ext_cost: rem --- Calculate and display extended cost
               rem ---  IN: unit_cost
               rem ---    : trans_qty
               rem --- OUT: Extended cost calculated and displayed
rem ==========================================================================

	callpoint!.setColumnData("IVE_TRANSDET.TOTAL_COST", str(unit_cost * trans_qty) )
	print "Updated total cost"; rem debug
	callpoint!.setStatus("REFRESH")
	rem callpoint!.setStatus("MODIFIED-REFRESH")
	rem callpoint!.setStatus("REFGRID")

return

rem ==========================================================================
get_whse_item: rem --- Get warehouse and item records and display
               rem      IN: item$ = the current item ID
               rem          whse$ = the current warehouse
               rem     OUT: default values set and displayed,
               rem          fields disable/enabled
rem ==========================================================================

	print "in get_whse_item: item$ = """, item$, """, whse$: """, whse$, """"; rem debug

	rem --- Are both columns set?

	if item$ <> "" and whse$ <> "" then

		rem --- Get records

		file_name$ = "IVM_ITEMMAST"
		dim ivm01a$:fnget_tpl$(file_name$)
		find record (fnget_dev(file_name$), key=firm_id$+item$) ivm01a$

		file_name$ = "IVM_ITEMWHSE"
		dim ivm02a$:fnget_tpl$(file_name$)
		find record (fnget_dev(file_name$), key=firm_id$+whse$+item$, dom=no_whse_rec) ivm02a$

		rem --- Set header display values to warehouse

		loc$   = ivm02a.location$
		qoh    = ivm02a.qty_on_hand
		commit = ivm02a.qty_commit

		user_tpl.avail  = qoh - commit
		user_tpl.commit = commit
		user_tpl.qoh    = qoh

		rem --- Disable/Enable Lot/Serial if needed

		user_tpl.this_item_lot_or_ser = ( user_tpl.ls$="Y" and ivm01a.lotser_item$="Y" and ivm01a.inventoried$="Y" )
		cols! = BBjAPI().makeVector()
		cols!.addItem(7); rem --- lot
		cols!.addItem(8); rem --- location
		cols!.addItem(9); rem --- comment
		this_row = callpoint!.getValidationRow()
	
		if user_tpl.this_item_lot_or_ser then
			print "enabling lot/serial fields"; rem debug
			util.enableGridCells(Form!, cols!, this_row)
		else
			print "disabling lot/serial fields"; rem debug
			util.disableGridCells(Form!, cols!, this_row)
		endif

		rem --- Get lot/serial# info, if any

		user_tpl.ls_found = 0
		ls_no$ = callpoint!.getColumnData("IVE_TRANSDET.LOTSER_NO")

		if user_tpl.this_item_lot_or_ser and ls_no$ <> "" then
			file_name$ = "IVM_LSMAST"
			dim ivm07a$:fnget_tpl$(file_name$)
			find record(fnget_dev(file_name$),key=firm_id$+whse$+item$+ls_no$,dom=*endif) ivm07a$
			print "lot ", ls_no$, " found"; rem debug

			rem --- Set flags and header display values
			
			loc$   = ivm07a.ls_location$
			qoh    = ivm07a.qty_on_hand
			commit = ivm07a.qty_commit

			user_tpl.ls_found = 1
			user_tpl.avail    = qoh - commit
			user_tpl.commit   = commit
			user_tpl.qoh      = qoh

		endif

		rem --- Enable/disable comment and location fields based on whether L/S found

		gosub ls_loc_cmt

		rem --- Set cost and extension
		
		orig_item$ = callpoint!.getColumnDiskData("IVE_TRANSDET.ITEM_ID")
		orig_whse$ = callpoint!.getColumnDiskData("IVE_TRANSDET.WAREHOUSE_ID")
		new_record = ( cvs(orig_whse$,3) = "" or cvs(orig_item$,3) = "" )

		if new_record or orig_whse$ <> whse$ or orig_item$ <> item$ then

			callpoint!.setColumnData("IVE_TRANSDET.UNIT_COST", ivm02a.unit_cost$)
			unit_cost = num( ivm02a.unit_cost$ )
			trans_qty = num( callpoint!.getColumnData("IVE_TRANSDET.TRANS_QTY") )
			gosub calc_ext_cost

			rem --- Set header display values (whse or L/S)

			m9$     = user_tpl.m9$
			qoh$    = str( qoh:m9$ )		
			commit$ = str( commit:m9$ )
			avail   = qoh - commit
			avail$  = str( avail:m9$ )
			
			user_tpl.avail  = avail
			user_tpl.commit = commit

			gosub set_display_fields

		endif

	endif

	goto whse_item_done

no_whse_rec: rem --- No Warehouse Record error

	callpoint!.setMessage("IV_NO_WHSE_ITEM")
	rem call stbl("+DIR_SYP")+"bac_message.bbj","IV_NO_WHSE_ITEM",msg_tokens$[all],msg_opt$,table_chans$[all]
	rem callpoint!.setStatus("ABORT")

whse_item_done:

return

rem ==========================================================================
test_qty: rem --- Test whether the transaction quantity is valid
          rem      IN: trans_qty
rem ==========================================================================

	failed = 0
	dim msg_tokens$[0]
	
	rem --- Can never be zero
	if trans_qty = 0 then
		msg_id$ = "IV_QTY_ZERO"
		goto test_qty_err
	endif
	
	rem --- Issuse and Receipts can't be negative
	if (user_tpl.trans_type$ = "I" or user_tpl.trans_type$ = "R") and trans_qty < 0 then
		msg_id$ = "IV_QTY_NEGATIVE"
		goto test_qty_err
	endif

	rem --- When adjusting, serialized items can only have a qty of 1 or -1
 	if user_tpl.trans_type$ = "A" or user_tpl.trans_type$ = "C" then
		if user_tpl.this_item_lot_or_ser and user_tpl.serialized then
			if trans_qty <> 1 and trans_qty <> -1 then
				msg_id$ = "IV_SERIAL_ONE"
				goto test_qty_err
			endif
		endif
	endif

	rem --- At this point, if the item is lotted or serialied, the qty is ok
	if user_tpl.this_item_lot_or_ser then goto test_qty_end

	rem --- Is the quantity more than available?
	if (user_tpl.trans_type$ = "I" or 
:		(user_tpl.trans_type$ = "A" and trans_qty < 0) or 
:		(user_tpl.trans_type$ = "C" and trans_qty > 0) ) and
:		abs(trans_qty) > user_tpl.avail 
:	then
		msg_id$ = "IV_QTY_OVER_AVAIL"
		msg_tokens$[0] = str(user_tpl.avail)
		goto test_qty_err
	endif

	rem --- Check committed
	if user_tpl.trans_type$ = "C" and trans_qty < 0 and trans_qty + user_tpl.commit < 0 then
		msg_id$ = "IV_COMMIT_DECREASE"
		msg_token$[0] = str(user_tpl.commit)
		goto test_qty_err
	endif

	rem --- Passed
	goto test_qty_end

test_qty_err: rem --- Failed

	gosub disp_message
	failed = 1

test_qty_end:

return

rem ==========================================================================
test_ls: rem --- Test whether lot/serial# quantities are valid
         rem     IN: assumes that user_tpl.avail, commit, and qoh are set
rem ==========================================================================

	failed = 0
	if !(user_tpl.this_item_lot_or_ser) then goto test_ls_end
	dim msg_tokens$[0]
	trans_qty = num( callpoint!.getColumnData("IVE_TRANSDET.TRANS_QTY") )

	rem --- Do you need an existing lot/serial#?
	if !(user_tpl.ls_found) and 
:		 (user_tpl.trans_type$ = "C" or user_tpl.trans_type$ = "I" or
:		 (user_tpl.trans_type$ = "A" and trans_qty < 0))
:	then
		msg_id$ = "IV_LOT_MUST_EXIST"
		goto test_ls_err
	endif

	rem --- Is quantity more than available?
	if (user_tpl.trans_type$ = "I" or 
:		(user_tpl.trans_type$ = "A" and trans_qty < 0) or
:		(user_tpl.trans_type$ = "C" and trans_qty > 0)) and 
:		abs(trans_qty) > user_tpl.avail 
:	then
		msg_id$ = "IV_QTY_OVER_AVAIL"
		msg_tokens$[0] = str( user_tpl.avail )
		goto test_ls_err
	endif

	rem --- Check committed
	if user_tpl.trans_type$ = "C" and trans_qty < 0 and trans_qty + user_tpl.commit < 0 then
		msg_id$ = "IV_COMMIT_DECREASE"
		msg_token$[0] = str(user_tpl.commit)
		goto test_ls_err
	endif

	rem --- Can only receive to a non-existing or zero QOH serial number
	if (user_tpl.trans_type$ = "R" or
:		(user_tpl.trans_type$ = "A" and trans_qty > 0)) and
:		user_tpl.ls_found and user_tpl.serialized and user_tpl.qoh > 0
:	then
		msg_id$ = "IV_SER_ZERO_QOH"
		msg_tokens$[0] = str( user_tpl.qoh )
		goto test_ls_err
	endif

	rem --- Passed
	goto test_ls_end

test_ls_err: rem --- Failed

	gosub disp_message
	failed = 1

test_ls_end:

return


rem ==========================================================================
set_display_fields: rem --- Set the values of the header display fields
                    rem      IN: loc$    = location
                    rem          qoh$    = quantity on hand
                    rem          commit$ = committed qty
                    rem          avail$  = available qty
rem ==========================================================================

	rem --- Get the header controls
	location!    = UserObj!.getItem( user_tpl.location_obj )
	qty_on_hand! = UserObj!.getItem( user_tpl.qoh_obj )
	qty_commit!  = UserObj!.getItem( user_tpl.commit_obj )
	qty_avail!   = UserObj!.getItem( user_tpl.avail_obj )

	rem --- Display
	location!.setText( loc$ )
	qty_on_hand!.setText( qoh$ )
	qty_commit!.setText( commit$ )
	qty_avail!.setText( avail$ )

	rem --- Sets the values for Barista internally
	callpoint!.setHeaderColumnData("<<DISPLAY>>.LOCATION", loc$)
	callpoint!.setHeaderColumnData("<<DISPLAY>>.QTY_ON_HAND", qoh$)
	callpoint!.setHeaderColumnData("<<DISPLAY>>.QTY_COMMIT", commit$)
	callpoint!.setHeaderColumnData("<<DISPLAY>>.QTY_AVAIL", avail$)

	callpoint!.setStatus("REFRESH")

return


rem ==========================================================================
ls_loc_cmt: rem --- Enable/disable comment and location fields based on whether L/S found
rem                 IN: assumes user_tpl.ls_found is set
rem ==========================================================================

	if user_tpl.this_item_lot_or_ser then 
		cols! = BBjAPI().makeVector()
		cols!.addItem(8); rem --- lot loc
		cols!.addItem(9); rem -- lot comment

		if user_tpl.ls_found then
			util.disableGridCells(Form!, cols!)
		else
			util.enableGridCells(Form!, cols!)
		endif
	endif

return
[[IVE_TRANSDET.TRANS_QTY.AVAL]]
print "in TRANS_QTY.AVAL"; rem debug

rem --- Check the transaction qty

	trans_qty = num( callpoint!.getUserInput() )
	gosub test_qty

	if !(failed) then 

		rem --- Calculate and display extended cost
		trans_qty = num( callpoint!.getUserInput() )
		unit_cost = num( callpoint!.getColumnData("IVE_TRANSDET.UNIT_COST") )
		gosub calc_ext_cost

		rem --- Enter cost only for receipts and adjusting up (that is, incoming)
		if user_tpl.trans_type$ = "R" or (user_tpl.trans_type$ = "A" and trans_qty > 0) then
			util.enableGridCell(Form!, 10); rem --- Cost
		endif

	endif
[[IVE_TRANSDET.AGRE]]
print "after grid row exit (AGRE)"; rem debug

rem --- Is this row deleted?

	this_row = callpoint!.getValidationRow()
	print "row", this_row; rem debug
	
	if callpoint!.getGridRowDeleteStatus(this_row) = "Y" then 
		print "row is deleted, exitting"; rem debug
		break; rem --- exit callpoint
	endif

rem --- Tests to make sure trans qty is correct

	if user_tpl.this_item_lot_or_ser then 

		gosub test_ls
		if failed then
			callpoint!.setStatus("ABORT")
			break; rem --- exit callpoint
		endif

	else

		trans_qty = num( callpoint!.getColumnData("IVE_TRANSDET.TRANS_QTY") )
		gosub test_qty
		if failed then
			callpoint!.setStatus("ABORT")
			break; rem --- exit callpoint
		endif

	endif

rem --- Commit inventory

	rem --- Receipts do not commit

	if user_tpl.trans_type$ = "R" then 
		print "Receipts don't commit"; rem debug
		break; rem --- exit callpoint
	endif

	rem --- Has this row changed?

	if callpoint!.getGridRowModifyStatus(this_row) <> "Y" then
		print "row not modified, exitting"; rem debug
		break; rem --- exit callpoint
	endif

	print "row has been modified..."; rem debug

	rem --- Get current and prior values

	curVect!  = gridVect!.getItem(0)
	undoVect! = gridVect!.getItem(1)

	dim cur_rec$:dtlg_param$[1,3]
	dim undo_rec$:dtlg_param$[1,3]

	cur_rec$  = curVect!.getItem(this_row)
	undo_rec$ = undoVect!.getItem(this_row)

	curr_whse$   = cur_rec.warehouse_id$
	curr_item$   = cur_rec.item_id$
	curr_qty     = num( cur_rec.trans_qty$ )
	curr_lotser$ = cur_rec.lotser_no$

	if undo_rec$ <> "" then
		prior_whse$   = undo_rec.warehouse_id$
		prior_item$   = undo_rec.item_id$
		prior_qty     = num( undo_rec.trans_qty$ )
		prior_lotser$ = undo_rec.lotser_no$
	else
		prior_whse$   = ""
		prior_item$   = ""
		prior_qty     = 0
		prior_lotser$ = ""
	endif

	rem debug to end
	if (curr_whse$<>prior_whse$) then
		print "Warehouses don't match or new"
	else
		print "Warehouses match"
	endif

	if (curr_item$<>prior_item$) then
		print "Items don't match or new"
	else
		print "Items match"
	endif

	print "Change in quantity:", curr_qty - prior_qty
	rem end debug

	rem --- Has there been any change?

	if (curr_whse$   <> "" and curr_item$ <> "") and 
:		(curr_whse$   <> prior_whse$   or 
:		 curr_item$   <> prior_item$   or 
:		 curr_qty     <> prior_qty     or
:      curr_lotser$ <> prior_lotser$) 
:	then

		rem --- Initialize inventory item update

		print "initializing ATAMO..."
		status = 999
		call user_tpl.pgmdir$+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
		if status then 
			callpoint!.setStatus("EXIT")
			break; rem --- exit callpoint
		endif

		rem --- Items or warehouses are different: uncommit previous

		if (prior_whse$   <> "" and prior_whse$   <> curr_whse$) or 
:		   (prior_item$   <> "" and prior_item$   <> curr_item$) or
:			(prior_lotser$ <> "" and prior_lotser$ <> curr_lotser$)
:		then

			rem --- Uncommit prior item and warehouse

			if prior_whse$ <> "" and prior_item$ <> "" then
			
				print "uncomtting old item or warehouse..."; rem debug
				items$[1] = prior_whse$
				items$[2] = prior_item$
				items$[3] = prior_lotser$
				
				rem --- Adjustments reverse the commitment
				if user_tpl.trans_type$ = "A" then
					refs[0] = -prior_qty
				else
					refs[0] = prior_qty
				endif
				
				call user_tpl.pgmdir$+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				if status then 
					callpoint!.setStatus("EXIT")
					break; rem --- exit callpoint
				endif

			endif

			rem --- Commit quantity for current item and warehouse

			print "committing current item and warehouse..."; rem debug
			items$[1] = curr_whse$
			items$[2] = curr_item$
			items$[3] = curr_lotser$
			refs[0]   = curr_qty 

			call user_tpl.pgmdir$+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
			if status then 
				callpoint!.setStatus("EXIT")
				break; rem --- exit callpoint
			endif

		endif

		rem --- New record or item and warehouse haven't changed: commit difference

		if	(prior_whse$   = "" or prior_whse$   = curr_whse$) and 
:			(prior_item$   = "" or prior_item$   = curr_item$) and
:			(prior_lotser$ = "" or prior_lotser$ = curr_lotser$)
:		then

			rem --- Commit quantity for current item and warehouse

			print "committing new or current item and warehouse..."; rem debug
			items$[1] = curr_whse$
			items$[2] = curr_item$
			items$[3] = curr_lotser$
			refs[0]   = curr_qty - prior_qty

			call user_tpl.pgmdir$+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
			if status then 
				callpoint!.setStatus("EXIT")
				break; rem --- exit callpoint
			endif

		endif

		print "done committing"; rem debug

	endif
[[IVE_TRANSDET.BGDR]]

[[IVE_TRANSDET.ITEM_ID.AVAL]]
print "in ITEM_ID After Column Validation (AVAL)"; rem debug

rem --- Set and display default values

	item$ = callpoint!.getUserInput()
	whse$ = callpoint!.getColumnData("IVE_TRANSDET.WAREHOUSE_ID")
	gosub get_whse_item