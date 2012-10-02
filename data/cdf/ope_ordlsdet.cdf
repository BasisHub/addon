[[OPE_ORDLSDET.QTY_SHIPPED.AVAL]]
rem --- Check if Serial and validate quantity
if callpoint!.getDevObject("lotser_flag")="S"
	if abs(num(callpoint!.getUserInput()))<>1
		msg_id$="IV_SERIAL_ONE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
endif

rem --- Signs must be the same
if sgn(num(callpoint!.getColumnData("OPE_ORDLSDET.QTY_ORDERED")))<>sgn(num(callpoint!.getUserInput()))
	msg_id$=""
	gosub disp_message
	callpoint!.setStatus("ABORT")
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

rem --- Signs must be the same
if sgn(num(callpoint!.getColumnData("OPE_ORDLSDET.QTY_SHIPPED")))<>sgn(num(callpoint!.getUserInput()))
	msg_id$=""
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif

rem --- Ship Qty must be <= Order Qty
if abs(num(callpoint!.getColumnData("OPE_ORDLSDET.QTY_SHIPPED")))>abs(num(callpoint!.getUserInput()))
	msg_id$="SHIP_EXCEEDS_ORD"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
[[OPE_ORDLSDET.<CUSTOM>]]
rem --- Calculate total quantities and compare to order line
[[OPE_ORDLSDET.AGRE]]
rem --- populate key area of detail records

	myrow=callpoint!.getValidationRow()

	curVect!=gridVect!.getItem(0)
	dim cur_rec$:dtlg_param$[1,3]
	cur_rec$=curVect!.getItem(myrow)
	
	ar_type$=callpoint!.getDevObject("ar_type")
	cust$=callpoint!.getDevObject("cust")
	order$=callpoint!.getDevObject("order")
	int_seq$=callpoint!.getDevObject("int_seq")

	cur_rec.ar_type$=ar_type$
	cur_rec.customer_id$=cust$
	cur_rec.order_no$=order$
	cur_rec.orddet_seq_ref$=int_seq$
[[OPE_ORDLSDET.LOTSER_NO.BINP]]
rem --- call the lot lookup window and set default lot, lot location, lot comment and qty
rem --- save current row/column so we'll know where to set focus when we return from lot lookup

if cvs(callpoint!.getColumnData("OPE_ORDLSDET.LOTSER_NO"),3)=""
	rem jpb grid! = Form!.getChildWindow(1109).getControl(5900)
	rem jpb return_to_row = grid!.getSelectedRow()
	rem jpb return_to_col = grid!.getSelectedColumn()

	rem --- Set data for the lookup form
	wh$=callpoint!.getDevObject("wh")
	item$=callpoint!.getDevObject("item")
	lsmast_dev=num(callpoint!.getDevObject("lsmast_dev"))
	dim lsmast_tpl$:callpoint!.getDevObject("lsmast_tpl")

	dim dflt_data$[3,1]
	dflt_data$[1,0] = "ITEM_ID"
	dflt_data$[1,1] = item$
	dflt_data$[2,0] = "WAREHOUSE_ID"
	dflt_data$[2,1] = wh$
	dflt_data$[3,0] = "LOTS_TO_DISP"
	dflt_data$[3,1] = "O"; rem --- default to open lots

	rem --- Call the lookup form
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"IVC_LOTLOOKUP",
:		stbl("+USER_ID"),
:		"",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]

	rem --- Set the detail grid to the data selected in the lookup
	if callpoint!.getDevObject("selected_lot")<>null()
		callpoint!.setColumnData( "OPE_ORDLSDET.LOTSER_NO",   str(callpoint!.getDevObject("selected_lot")) )
		lot_avail = num( callpoint!.getDevObject("selected_lot_avail") )
		callpoint!.setColumnData( "OPE_ORDLSDET.QTY_ORDERED", str(lot_avail) )
		callpoint!.setStatus("MODIFIED-REFRESH")
	endif
endif
[[OPE_ORDLSDET.LOTSER_NO.AVAL]]
rem --- validate open lot number
	wh$=callpoint!.getDevObject("wh")
	item$=callpoint!.getDevObject("item")
	lsmast_dev=num(callpoint!.getDevObject("lsmast_dev"))
	dim lsmast_tpl$:callpoint!.getDevObject("lsmast_tpl")

	readrecord(lsmast_dev,key=firm_id$+wh$+item$+callpoint!.getUserInput())lsmast_tpl$
	if lsmast_tpl.closed_flag$<>"Y"
		escape
	endif
[[OPE_ORDLSDET.LOTSER_NO.AINQ]]
escape; rem ainq
