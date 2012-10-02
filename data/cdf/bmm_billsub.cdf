[[BMM_BILLSUB.OBSOLT_DATE.AVAL]]
rem --- Check for valid dates

	eff_date$=callpoint!.getColumnData("BMM_BILLSUB.EFFECT_DATE")
	obs_date$=callpoint!.getUserInput()
	msg_id$="BM_EFF_OBS"
	gosub check_dates
[[BMM_BILLSUB.EFFECT_DATE.AVAL]]
rem --- Check for valid dates

	eff_date$=callpoint!.getUserInput()
	obs_date$=callpoint!.getColumnData("BMM_BILLSUB.OBSOLT_DATE")
	msg_id$="BM_OBS_EFF"
	gosub check_dates
[[BMM_BILLSUB.ALT_FACTOR.AVAL]]
rem --- Display Net Qty and Total Cost

	qty_req=num(callpoint!.getColumnData("BMM_BILLSUB.QTY_REQUIRED"))
	alt_factor=num(callpoint!.getUserInput())
	divisor=num(callpoint!.getColumnData("BMM_BILLSUB.DIVISOR"))
	unit_cost=num(callpoint!.getColumnData("BMM_BILLSUB.UNIT_COST"))
	gosub calc_display
[[BMM_BILLSUB.UNIT_COST.AVAL]]
rem --- Display Net Qty and Total Cost

	qty_req=num(callpoint!.getColumnData("BMM_BILLSUB.QTY_REQUIRED"))
	alt_factor=num(callpoint!.getColumnData("BMM_BILLSUB.ALT_FACTOR"))
	divisor=num(callpoint!.getColumnData("BMM_BILLSUB.DIVISOR"))
	unit_cost=num(callpoint!.getUserInput())
	gosub calc_display
[[BMM_BILLSUB.QTY_REQUIRED.AVAL]]
rem --- Display Net Qty and Total Cost

	qty_req=num(callpoint!.getUserInput())
	alt_factor=num(callpoint!.getColumnData("BMM_BILLSUB.ALT_FACTOR"))
	divisor=num(callpoint!.getColumnData("BMM_BILLSUB.DIVISOR"))
	unit_cost=num(callpoint!.getColumnData("BMM_BILLSUB.UNIT_COST"))
	gosub calc_display
[[BMM_BILLSUB.DIVISOR.AVAL]]
rem --- Don't allow Divisor to be 0

	if num(callpoint!.getUserInput())=0
		msg_id$="DIVISOR_NOT_ZERO"
		gosub disp_message
		callpoint!.setColumnData("BMM_BILLSUB.DIVISOR","1",1)
		callpoint!.setFocus(callpoint!.getValidationRow(),"BMM_BILLSUB.DIVISOR")
	endif

rem --- Display Net Qty and Total Cost

	qty_req=num(callpoint!.getColumnData("BMM_BILLSUB.QTY_REQUIRED"))
	alt_factor=num(callpoint!.getColumnData("BMM_BILLSUB.ALT_FACTOR"))
	divisor=num(callpoint!.getUserInput())
	unit_cost=num(callpoint!.getColumnData("BMM_BILLSUB.UNIT_COST"))
	gosub calc_display
[[BMM_BILLSUB.<CUSTOM>]]
rem ===================================================================
calc_display:
rem --- qty_req:		input
rem --- alt_factor:		input
rem --- divisor:			input
rem --- unit_cost:		input
rem ===================================================================

	net_qty=BmUtils.netSubQtyReq(qty_req,alt_factor,divisor)
	total_cost=net_qty*unit_cost

	callpoint!.setColumnData("<<DISPLAY>>.NET_QTY",str(net_qty))
	callpoint!.setColumnData("<<DISPLAY>>.TOTAL_COST",str(total_cost))

	return

rem ===================================================================
check_dates:
rem eff_date$	input
rem obs_date$	input
rem msg_id$	input
rem ===================================================================

	if cvs(obs_date$,3)<>""
		if obs_date$<=eff_date$
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	endif

	return
[[BMM_BILLSUB.BGDR]]
rem --- Display Net Qty and Total Cost

	qty_req=num(callpoint!.getColumnData("BMM_BILLSUB.QTY_REQUIRED"))
	alt_factor=num(callpoint!.getColumnData("BMM_BILLSUB.ALT_FACTOR"))
	divisor=num(callpoint!.getColumnData("BMM_BILLSUB.DIVISOR"))
	unit_cost=num(callpoint!.getColumnData("BMM_BILLSUB.UNIT_COST"))
	gosub calc_display
[[BMM_BILLSUB.BSHO]]
	use ::bmo_BmUtils.aon::BmUtils
	declare BmUtils bmUtils!

rem --- Only show form if A/P is installed

	if callpoint!.getDevObject("ap_installed") <> "Y"
		callpoint!.setMessage("AP_NOT_INST")
		callpoint!.setStatus("EXIT")
	endif

rem --- fill listbox for use with Op Sequence

	bmm03_dev=fnget_dev("BMM_BILLOPER")
	dim bmm03a$:fnget_tpl$("BMM_BILLOPER")
	bmm08_dev=fnget_dev("BMC_OPCODES")
	dim bmm08a$:fnget_tpl$("BMC_OPCODES")
	bill_no$=callpoint!.getDevObject("master_bill")

	ops_lines!=SysGUI!.makeVector()
	ops_items!=SysGUI!.makeVector()
	ops_list!=SysGUI!.makeVector()
	ops_lines!.addItem("000000000000")
	ops_items!.addItem("")
	ops_list!.addItem("")

	read(bmm03_dev,key=firm_id$+bill_no$,dom=*next)
	while 1
		read record (bmm03_dev,end=*break) bmm03a$
		if pos(firm_id$+bill_no$=bmm03a$)<>1 break
		if bmm03a.line_type$<>"S" continue
		dim bmm08a$:fattr(bmm08a$)
		read record (bmm08_dev,key=firm_id$+bmm03a.op_code$,dom=*next)bmm08a$
		ops_lines!.addItem(bmm03a.internal_seq_no$)
		ops_items!.addItem(bmm03a.op_code$)
		ops_list!.addItem(bmm03a.op_code$+" - "+bmm08a.code_desc$)
	wend

	if ops_lines!.size()>0
		ldat$=""
		for x=0 to ops_lines!.size()-1
			ldat$=ldat$+ops_items!.getItem(x)+"~"+ops_lines!.getItem(x)+";"
		next x
	endif

	callpoint!.setTableColumnAttribute("BMM_BILLSUB.OP_INT_SEQ_REF","LDAT",ldat$)
	my_grid!=Form!.getControl(5000)
	ListColumn=11
	my_control!=my_grid!.getColumnListControl(ListColumn)
	my_control!.removeAllItems()
	my_control!.insertItems(0,ops_list!)
	my_grid!.setColumnListControl(ListColumn,my_control!)
