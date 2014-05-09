[[BMM_BILLSUB.BUDE]]
rem --- Verify wo_ref_num is unique
	refnumMap!=callpoint!.getDevObject("refnumMap")
	wo_ref_num$=callpoint!.getColumnData("BMM_BILLSUB.WO_REF_NUM")
	if cvs(wo_ref_num$,2)<>"" then
		if refnumMap!.containsKey(wo_ref_num$) then
			msg_id$="SF_DUP_REF_NUM"
			dim msg_tokens$[1]
			msg_tokens$[1]=wo_ref_num$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		else
			refnumMap!.put(wo_ref_num$,"")
		endif
	endif
[[BMM_BILLSUB.BDEL]]
rem --- Update refnumMap!
	refnumMap!=callpoint!.getDevObject("refnumMap")
	wo_ref_num$=callpoint!.getColumnData("BMM_BILLSUB.WO_REF_NUM")
	if cvs(wo_ref_num$,2)<>"" then
		refnumMap!.remove(wo_ref_num$)
	endif
[[BMM_BILLSUB.WO_REF_NUM.AVAL]]
rem --- Verify wo_ref_num is unique
	wo_ref_num$=callpoint!.getUserInput()
	prev_wo_ref_num$=callpoint!.getDevObject("prev_wo_ref_num")
	refnumMap!=callpoint!.getDevObject("refnumMap")
	if wo_ref_num$<>prev_wo_ref_num$ then
		if refnumMap!.containsKey(wo_ref_num$) then
			msg_id$="SF_DUP_REF_NUM"
			dim msg_tokens$[1]
			msg_tokens$[1]=wo_ref_num$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		else
			if cvs(wo_ref_num$,2)<>"" then refnumMap!.put(wo_ref_num$,"")
			if cvs(prev_wo_ref_num$,2)<>"" then refnumMap!.remove(prev_wo_ref_num$)
		endif
	endif
[[BMM_BILLSUB.AGDR]]
rem --- Track wo_ref_num in Map to insure they are unique
	refnumMap!=callpoint!.getDevObject("refnumMap")
	wo_ref_num$=callpoint!.getColumnData("BMM_BILLSUB.WO_REF_NUM")
	if cvs(wo_ref_num$,2)<>"" then
		refnumMap!.put(wo_ref_num$,"")
	endif
[[BMM_BILLSUB.WO_REF_NUM.BINP]]
rem --- Capture starting wo_ref_num
	prev_wo_ref_num$=callpoint!.getColumnData("BMM_BILLSUB.WO_REF_NUM")
	callpoint!.setDevObject("prev_wo_ref_num",prev_wo_ref_num$)
[[BMM_BILLSUB.BDTW]]
use ::ado_util.src::util
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

rem --- init data

	refnumMap!=new java.util.HashMap()
	callpoint!.setDevObject("refnumMap",refnumMap!)

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
		ops_items!.addItem(bmm03a.wo_op_ref$)
		ops_list!.addItem(bmm03a.wo_op_ref$+" - "+bmm03a.op_code$+" - "+bmm08a.code_desc$)
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
	col_hdr$=callpoint!.getTableColumnAttribute("BMM_BILLSUB.OP_INT_SEQ_REF","LABS")
	col_ref=util.getGridColumnNumber(my_grid!, col_hdr$)
	my_control!=my_grid!.getColumnListControl(col_ref)
	my_control!.removeAllItems()
	my_control!.insertItems(0,ops_list!)
	my_grid!.setColumnListControl(col_ref,my_control!)
    	my_grid!.setColumnHeaderCellText(ListColumn,"Op Ref")

rem --- Disable WO_REF_NUM when locked
	if callpoint!.getDevObject("lock_ref_num")="Y" then
		opts$=callpoint!.getTableColumnAttribute("BMM_BILLSUB.WO_REF_NUM","OPTS")
		callpoint!.setTableColumnAttribute("BMM_BILLSUB.WO_REF_NUM","OPTS",opts$+"C"); rem --- makes read only
	endif
