[[IVE_TRANSDET.LOTSER_NO.BINP]]
rem --- Disable this cell if necessary

	print "in LOTSER_NO, BINP"

	rem item$ = callpoint!.getColumnData("IVE_TRANSDET.ITEM_ID")
	rem whse$ = callpoint!.getColumnData("IVE_TRANSDET.WAREHOUSE_ID")
	rem gosub get_whse_item

	rem if !(user_tpl.this_item_lot_or_ser%) then callpoint!.setStatus("ABORT")
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
calc_ext_cost: rem --- Calculate and display extended cost
rem  IN: unit_cost
rem    : trans_qty
rem OUT: Extended cost calculated and displayed

	callpoint!.setColumnData("IVE_TRANSDET.TOTAL_COST", str(unit_cost * trans_qty) )
	callpoint!.setStatus("MODIFIED-REFRESH")

return

get_whse_item: rem --- Get warehouse and item records and display
rem  IN: item$ = the current item ID
rem    : whse$ = the current warehouse
rem OUT: default values set and displayed

	print "in get_whse_item: item$ = """, item$, """, whse$: """, whse$, """"

	rem --- Are both columns set?

	if item$ <> "" and whse$ <> "" then

		rem --- Get records

		ivm01_dev   = fnget_dev("IVM_ITEMMAST")
		ivm01a_tpl$ = fnget_tpl$("IVM_ITEMMAST")
		dim ivm01a$:ivm01a_tpl$
		find record(ivm01_dev,key=firm_id$+item$) ivm01a$

		ivm02_dev   = fnget_dev("IVM_ITEMWHSE")
		ivm02a_tpl$ = fnget_tpl$("IVM_ITEMWHSE")
		dim ivm02a$:ivm02a_tpl$
		find record(ivm02_dev,key=firm_id$+whse$+item$,dom=no_whse_rec) ivm02a$

		rem --- Display Lot/Serial if needed

		user_tpl.this_item_lot_or_ser% = ( user_tpl.ls$="Y" and ivm01a.lotser_item$="Y" and ivm01a.inventoried$="Y" )

		print "this_item_lot_or_ser: ", iff(user_tpl.this_item_lot_or_ser%, "Y", "N")
		print "lot/serial okay: ", user_tpl.ls$
		print "lot/serial item: ", ivm01a.lotser_item$
		print "inventoried    : ", ivm01a.inventoried$

		rem w!=Form!.getChildWindow(1109); rem window with grid in it
		rem c!=w!.getControl(5900); rem grid control

		rem if user_tpl.this_item_lot_or_ser% then
			rem c!.setColumnEditable(5,1) ; rem cell 6 (zero based), editable
			rem c!.setColumnEditable(6,1)
			rem c!.setColumnEditable(7,1)
		rem else
			rem c!.setColumnEditable(5,0); rem not editable
			rem c!.setColumnEditable(6,0)
			rem c!.setColumnEditable(7,0)
		rem endif

		rem --- Set cost and extension
		
		orig_item$ = callpoint!.getColumnDiskData("IVE_TRANSDET.ITEM_ID")
		orig_whse$ = callpoint!.getColumnDiskData("IVE_TRANSDET.WAREHOUSE_ID")
		new_record = ( cvs(orig_whse$,3) = "" or cvs(orig_item$,3) = "" )

		if new_record or orig_whse$ <> whse$ or orig_item$ <> item$ then
			callpoint!.setColumnData("IVE_TRANSDET.UNIT_COST", ivm02a.unit_cost$)
			unit_cost = num( ivm02a.unit_cost$ )
			trans_qty = num( callpoint!.getColumnData("IVE_TRANSDET.TRANS_QTY") )
			gosub calc_ext_cost

			rem --- Set header display values

			location!    = UserObj!.getItem( user_tpl.location_obj )
			qty_on_hand! = UserObj!.getItem( user_tpl.qoh_obj )
			qty_commit!  = UserObj!.getItem( user_tpl.commit_obj )
			qty_avail!   = UserObj!.getItem( user_tpl.avail_obj )

			rem --- Header values
			m9$     = user_tpl.m9$
			loc$    = ivm02a.location$
			qoh     = num( ivm02a.qty_on_hand$ )
			qoh$    = str( qoh:m9$ )
			commit  = num( ivm02a.qty_commit$ )
			commit$ = str( commit:m9$ )
			avail$  = str( (qoh - commit):m9$ )

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

		endif

	endif

	goto whse_item_done

	rem No Warehouse Record error

	no_whse_rec:
	call stbl("+DIR_SYP")+"bac_message.bbj","IV_NO_WHSE_ITEM",msg_tokens$[all],msg_opt$,table_chans$[all]
	rem callpoint!.setStatus("ABORT")

	whse_item_done:

return
[[IVE_TRANSDET.TRANS_QTY.AVAL]]
rem --- Calculate and display extended cost

	trans_qty = num( callpoint!.getUserInput() )
	unit_cost = num( callpoint!.getColumnData("IVE_TRANSDET.UNIT_COST") )
	gosub calc_ext_cost
[[IVE_TRANSDET.AGDS]]
print "after grid display (not row)"; rem debug
[[IVE_TRANSDET.AWRI]]
print "after record write"
[[IVE_TRANSDET.ARAR]]
print "after array transfer"
[[IVE_TRANSDET.AGRE]]
	print "***after grid row exit"

	this_row = callpoint!.getValidationRow()

	if callpoint!.getGridRowModifyStatus(this_row)<>"Y"
		print "row ",this_row," not modified..."
	else
		print "row ",this_row," modified..."
		curVect!  = gridVect!.getItem(0)
		undoVect! = gridVect!.getItem(1)
		diskVect! = gridVect!.getItem(2)

		dim cur_rec$:dtlg_param$[1,3]
		dim undo_rec$:dtlg_param$[1,3]
		dim disk_rec$:dtlg_param$[1,3]

		curr_whse$  = cur_rec.warehouse_id$
		curr_item$  = cur_rec.item_id$
		curr_qty    = num( cur_rec.trans_qty$ )
		prior_whse$ = disk_rec.warehouse_id$
		prior_item$ = disk_rec.item_id$
		prior_qty   = num( disk_rec.trans_qty$ )

		if (curr_whse$<>prior_whse$) then
			print "Warehouses don't match"
		else
			print "Warehouses match"
		endif

		if (curr_item$<>prior_item$) then
			print "Items don't match"
		else
			print "Items match"
		endif

		print "Change in quantity:", curr_qty - prior_qty

	endif
			
[[IVE_TRANSDET.AGDR]]
print "after grid display row"
[[IVE_TRANSDET.BWRI]]
print "before record write"
[[IVE_TRANSDET.BGDR]]
print "before grid display row"
[[IVE_TRANSDET.ITEM_ID.AVAL]]
rem --- Old code for reference
rem 2245 FIND (IVM01_DEV,KEY=D0$,DOM=2220)IOL=IVM01A; rem D0$(1),D1$(1),D2$(1),D3$,D4$,D5$,D6$,D[ALL]
rem 2250 LET L0$(1)=N0$+W1$,AVAIL=0
rem 2255 FIND (IVM02_DEV,KEY=L0$,DOM=2220)IOL=IVM02A; rem L0$(1),L1$,L2$,L[ALL]
rem 2260 LET AVAIL=L[0]-L[2]
rem 2265 IF VALIDATE OR W1$=PREV_WH_ITEM$ THEN GOTO 2390
rem 2270 DIM W[2]
rem 2275 LET W2$(1)="",W[1]=L[11]

rem --- Set and display default values

	item$ = callpoint!.getUserInput()
	whse$ = callpoint!.getColumnData("IVE_TRANSDET.WAREHOUSE_ID")
	gosub get_whse_item
