[[OPE_ORDLSDET.BEND]]
rem --- Check total quantity from all lines against ordered quantity

	lot_qty=0
	dim gridrec$:fattr(rec_data$)
	numrecs=GridVect!.size()

	if numrecs>0

		for reccnt=0 to numrecs-1
			gridrec$=GridVect!.getItem(reccnt)

			if cvs(gridrec$,3)<>""
				if callpoint!.getGridRowDeleteStatus(reccnt)<>"Y"
					lot_qty=lot_qty+gridrec.qty_ordered
				endif
			endif

		next reccnt

	endif

	if lot_qty<>num(callpoint!.getDevObject("ord_qty"))
		msg_id$="OP_LOT_QTY_UNEQUAL"
		dim msg_tokens$[3]
		msg_tokens$[1]=str(lot_qty)

		if callpoint!.getDevObject("lotser_flag")="L"
			msg_tokens$[2]="Lot numbers"
		else
			msg_tokens$[2]="Serial numbers"
		endif

		msg_tokens$[3]=str(callpoint!.getDevObject("ord_qty"))
		gosub disp_message
		if msg_opt$="N" callpoint!.setStatus("ABORT")
	endif
[[OPE_ORDLSDET.<CUSTOM>]]

check_avail: rem --- check for available quantity

	wh$    = callpoint!.getDevObject("wh")
	item$  = callpoint!.getDevObject("item")
	ls_no$ = callpoint!.getColumnData("OPE_ORDLSDET.LOTSER_NO")

	lsmast_dev=num(callpoint!.getDevObject("lsmast_dev"))
	dim lsmast_tpl$:callpoint!.getDevObject("lsmast_tpl")

	repeat
		read record(lsmast_dev, key=firm_id$+wh$+item$+ls_no$, dom=*break) lsmast_tpl$

		if lot_qty >= 0 and lot_qty > lsmast_tpl.qty_on_hand - lsmast_tpl.qty_commit
			dim msg_tokens$[1]
			msg_tokens$[1] = str(lsmast_tpl.qty_on_hand - lsmast_tpl.qty_commit)
			msg_id$="IV_QTY_OVER_AVAIL"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	until 1

return
[[OPE_ORDLSDET.BSHO]]
rem --- Set Lot/Serial button up properly

	switch pos(callpoint!.getDevObject("lotser_flag")="LS")
		case 1; callpoint!.setOptionText("LLOK","Lot Lookup"); break
		case 2; callpoint!.setOptionText("LLOK","Serial Lookup"); break
		case default; callpoint!.setOptionEnabled("LLOK",0); break
	swend
[[OPE_ORDLSDET.AOPT-LLOK]]
	rem jpb grid! = Form!.getChildWindow(1109).getControl(5900)

rem --- Set data for the lookup form

	wh$=callpoint!.getDevObject("wh")
	item$=callpoint!.getDevObject("item")
	lsmast_dev=num(callpoint!.getDevObject("lsmast_dev"))
	dim lsmast_tpl$:callpoint!.getDevObject("lsmast_tpl")

rem --- See if there are any open lots

	read(lsmast_dev,key=firm_id$+wh$+item$+" ",knum=4,dom=*next)
	lsmast_key$=key(lsmast_dev,end=*next)

	if pos(firm_id$+wh$+item$+" "=lsmast_key$)=1
		dim dflt_data$[3,1]
		dflt_data$[1,0] = "ITEM_ID"
		dflt_data$[1,1] = item$
		dflt_data$[2,0] = "WAREHOUSE_ID"
		dflt_data$[2,1] = wh$
		dflt_data$[3,0] = "LOTS_TO_DISP"
		dflt_data$[3,1] = "O"; rem --- default to open lots

rem --- Call the lookup form

		call stbl("+DIR_SYP")+"bam_run_prog.bbj","IVC_LOTLOOKUP",stbl("+USER_ID"),"","",table_chans$[all],"",dflt_data$[all]

rem --- Set the detail grid to the data selected in the lookup

		if callpoint!.getDevObject("selected_lot")<>null()
			callpoint!.setColumnData( "OPE_ORDLSDET.LOTSER_NO",str(callpoint!.getDevObject("selected_lot")))
			lot_avail = num(callpoint!.getDevObject("selected_lot_avail"))
			callpoint!.setColumnData("OPE_ORDLSDET.QTY_ORDERED",str(lot_avail))
			callpoint!.setStatus("MODIFIED-REFRESH")
		endif

	else
		msg_id$="IV_NO_OPENLOTS"
		gosub disp_message
	endif
[[OPE_ORDLSDET.QTY_SHIPPED.AVAL]]
rem --- Check if Serial and validate quantity
if callpoint!.getDevObject("lotser_flag")="S"
	if abs(num(callpoint!.getUserInput()))<>1
		msg_id$="IV_SERIAL_ONE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
endif

rem --- Ship Qty must be <= Order Qty
if abs(num(callpoint!.getColumnData("OPE_ORDLSDET.QTY_ORDERED")))<abs(num(callpoint!.getUserInput()))
	msg_id$="SHIP_EXCEEDS_ORD"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
[[OPE_ORDLSDET.QTY_ORDERED.AVAL]]
rem --- Check if Serial and validate quantity

	if callpoint!.getDevObject("lotser_flag")="S"
		if abs(num(callpoint!.getUserInput()))<>1
			msg_id$="IV_SERIAL_ONE"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	endif

rem --- Ship Qty must be <= Order Qty

	if abs(num(callpoint!.getColumnData("OPE_ORDLSDET.QTY_SHIPPED")))>abs(num(callpoint!.getUserInput()))
		msg_id$="SHIP_EXCEEDS_ORD"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif

rem --- Now check for Sales Line quantity

		line_qty=num(callpoint!.getDevObject("ord_qty"))
		lot_qty=num(callpoint!.getUserInput())
		gosub check_avail
[[OPE_ORDLSDET.LOTSER_NO.BINP]]
rem --- call the lot lookup window and set default lot, lot location, lot comment and qty
rem --- save current row/column so we'll know where to set focus when we return from lot lookup
[[OPE_ORDLSDET.LOTSER_NO.AVAL]]
rem --- validate open lot number

	wh$    = callpoint!.getDevObject("wh")
	item$  = callpoint!.getDevObject("item")
   ls_no$ = callpoint!.getUserInput()

	lsmast_dev = num(callpoint!.getDevObject("lsmast_dev"))
	dim lsmast_tpl$:callpoint!.getDevObject("lsmast_tpl")

	got_rec$="N"
	start_block = 1

	if start_block then
		read record (lsmast_dev, key=firm_id$+wh$+item$+ls_no$, dom=*endif) lsmast_tpl$
		got_rec$ = "Y"
	endif

	if got_rec$ = "N"
		msg_id$="IV_LOT_MUST_EXIST"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	else
		if lsmast_tpl.closed_flag$ = "C"
			msg_id$ = "IV_SERLOT_CLOSED"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		else
	endif
[[OPE_ORDLSDET.LOTSER_NO.AINQ]]
escape; rem ainq
