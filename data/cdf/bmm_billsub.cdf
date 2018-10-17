[[BMM_BILLSUB.MEMO_1024.AVAL]]
rem --- Store first part of memo_1024 in ext_comment.
rem --- This AVAL is hit if user navigates via arrows or clicks on the memo_1024 field, and double-clicks or ctrl-F to bring up editor.
rem --- If use Comment field, or use ctrl-C or Comments button, code in the comment_entry subroutine is hit instead.
	disp_text$=callpoint!.getUserInput()
	if disp_text$<>callpoint!.getColumnUndoData("BMM_BILLSUB.MEMO_1024")
		dim ext_comments$(60)
		ext_comments$(1)=disp_text$(1,pos($0A$=disp_text$+$0A$)-1)
		callpoint!.setColumnData("BMM_BILLSUB.MEMO_1024",disp_text$,1)
		callpoint!.setColumnData("BMM_BILLSUB.EXT_COMMENTS",ext_comments$,1)
		callpoint!.setStatus("MODIFIED")
	endif
[[BMM_BILLSUB.AOPT-COMM]]
rem --- Launch Comments dialog
	gosub comment_entry
[[BMM_BILLSUB.EXT_COMMENTS.BINP]]
rem --- Launch Comments dialog
	gosub comment_entry
	callpoint!.setStatus("ABORT")
[[BMM_BILLSUB.VENDOR_ID.AVAL]]
rem "VENDOR INACTIVE - FEATURE"
vendor_id$ = callpoint!.getUserInput()
apm01_dev=fnget_dev("APM_VENDMAST")
apm01_tpl$=fnget_tpl$("APM_VENDMAST")
dim apm01a$:apm01_tpl$
apm01a_key$=firm_id$+vendor_id$
find record (apm01_dev,key=apm01a_key$,err=*break) apm01a$
if apm01a.vend_inactive$="Y" then
   call stbl("+DIR_PGM")+"adc_getmask.aon","VENDOR_ID","","","",m0$,0,vendor_size
   msg_id$="AP_VEND_INACTIVE"
   dim msg_tokens$[2]
   msg_tokens$[1]=fnmask$(apm01a.vendor_id$(1,vendor_size),m0$)
   msg_tokens$[2]=cvs(apm01a.vendor_name$,2)
   gosub disp_message
   callpoint!.setStatus("ACTIVATE")
endif

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
#include std_functions.src
rem ===================================================================
calc_display:
rem --- qty_req:		input
rem --- alt_factor:		input
rem --- divisor:			input
rem --- unit_cost:		input
rem ===================================================================

	old_prec = tcb(14)
	precision callpoint!.getDevObject("this_precision")

	net_qty=1*BmUtils.netSubQtyReq(qty_req,alt_factor,divisor)
	total_cost=net_qty*unit_cost

	callpoint!.setColumnData("<<DISPLAY>>.NET_QTY",str(net_qty))
	callpoint!.setColumnData("<<DISPLAY>>.TOTAL_COST",str(total_cost))

	precision old_prec

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

comment_entry:
rem --- on a line where you can access the ls_comments field, pop the new memo_1024 editor instead
rem --- the editor can be popped on demand for any line using the Comments button (alt-C),
rem --- but will automatically pop for lines where the ext_comments field is enabled.
rem ==========================================================================

	disp_text$=callpoint!.getColumnData("BMM_BILLSUB.MEMO_1024")
	sv_disp_text$=disp_text$

	editable$="YES"
	force_loc$="NO"
	baseWin!=null()
	startx=0
	starty=0
	shrinkwrap$="NO"
	html$="NO"
	dialog_result$=""

	call stbl("+DIR_SYP")+ "bax_display_text.bbj",
:		"Comments/Message Line",
:		disp_text$, 
:		table_chans$[all], 
:		editable$, 
:		force_loc$, 
:		baseWin!, 
:		startx, 
:		starty, 
:		shrinkwrap$, 
:		html$, 
:		dialog_result$

	if disp_text$<>sv_disp_text$
		ext_comments$=disp_text$(1,pos($0A$=disp_text$+$0A$)-1)
		callpoint!.setColumnData("BMM_BILLSUB.MEMO_1024",disp_text$,1)
		callpoint!.setColumnData("BMM_BILLSUB.EXT_COMMENTS",ext_comments$,1)
		callpoint!.setStatus("MODIFIED")
	endif

	callpoint!.setStatus("ACTIVATE")

	return
[[BMM_BILLSUB.BGDR]]
rem --- Display Net Qty and Total Cost

	qty_req=num(callpoint!.getColumnData("BMM_BILLSUB.QTY_REQUIRED"))
	alt_factor=num(callpoint!.getColumnData("BMM_BILLSUB.ALT_FACTOR"))
	divisor=num(callpoint!.getColumnData("BMM_BILLSUB.DIVISOR"))
	unit_cost=num(callpoint!.getColumnData("BMM_BILLSUB.UNIT_COST"))
	gosub calc_display
[[BMM_BILLSUB.BSHO]]
	use ::ado_func.src::func
	use ::ado_util.src::util
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

	ldat$=""
	if ops_lines!.size()>0
		descVect!=BBjAPI().makeVector()
		codeVect!=BBjAPI().makeVector()
		for x=0 to ops_lines!.size()-1
			descVect!.addItem(ops_items!.getItem(x))
			codeVect!.addItem(ops_lines!.getItem(x))
		next x
		ldat$=func.buildListButtonList(descVect!,codeVect!)
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

rem --- Set column size for memo_1024 field very small so it doesn't take up room, but still available for hover-over of memo contents
	maintGrid!=Form!.getControl(num(stbl("+GRID_CTL")))
	col_hdr$=callpoint!.getTableColumnAttribute("BMM_BILLSUB.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(maintGrid!, col_hdr$)
	maintGrid!.setColumnWidth(memo_1024_col,15)
