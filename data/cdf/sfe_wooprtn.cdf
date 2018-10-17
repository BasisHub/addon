[[SFE_WOOPRTN.LINE_TYPE.AVAL]]
rem --- Enable/disable comments field
	if cvs(callpoint!.getColumnData("SFE_WOOPRTN.WO_OP_REF"),2)<>"" then
		line_type$=callpoint!.getUserInput()
		gosub enable_comments
	endif
[[SFE_WOOPRTN.AGRN]]
rem --- Enable/disable comments
	line_type$=callpoint!.getColumnData("SFE_WOOPRTN.LINE_TYPE")
	gosub enable_comments
[[SFE_WOOPRTN.MEMO_1024.BINQ]]
rem --- (Barista Bug 9179 workaround) If grid cell isn't editable, then abort so new text can't be entered via edit control.
	maintGrid!=Form!.getControl(num(stbl("+GRID_CTL")))
	col_hdr$=callpoint!.getTableColumnAttribute("SFE_WOOPRTN.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(maintGrid!, col_hdr$)
	this_row=callpoint!.getValidationRow()
	isEditable=maintGrid!.isCellEditable(this_row,memo_1024_col)
	if !isEditable then callpoint!.setStatus("ABORT")
[[SFE_WOOPRTN.MEMO_1024.AVAL]]
rem --- Store first part of memo_1024 in ext_comment.
rem --- This AVAL is hit if user navigates via arrows or clicks on the memo_1024 field, and double-clicks or ctrl-F to bring up editor.
rem --- If use Comment field, or use ctrl-C or Comments button, code in the comment_entry subroutine is hit instead.
	disp_text$=callpoint!.getUserInput()
	if disp_text$<>callpoint!.getColumnUndoData("SFE_WOOPRTN.MEMO_1024")
		dim ext_comments$(60)
		ext_comments$(1)=disp_text$(1,pos($0A$=disp_text$+$0A$)-1)
		callpoint!.setColumnData("SFE_WOOPRTN.MEMO_1024",disp_text$,1)
		callpoint!.setColumnData("SFE_WOOPRTN.EXT_COMMENTS",ext_comments$,1)
		callpoint!.setStatus("MODIFIED")
	endif
[[SFE_WOOPRTN.AOPT-COMM]]
rem --- Launch Comments dialog
	gosub comment_entry
[[SFE_WOOPRTN.EXT_COMMENTS.BINP]]
rem --- Launch Comments dialog
	gosub comment_entry
	callpoint!.setStatus("ABORT")
[[SFE_WOOPRTN.BUDE]]
rem --- Verify wo_op_ref is unique
	refnumMap!=callpoint!.getDevObject("refnumMap")
	wo_op_ref$=callpoint!.getColumnData("SFE_WOOPRTN.WO_OP_REF")
	if refnumMap!.containsKey(wo_op_ref$) then
		msg_id$="SF_DUP_REF_NUM"
		dim msg_tokens$[1]
		msg_tokens$[1]=wo_op_ref$
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	else
		refnumMap!.put(wo_op_ref$,"")
	endif
[[SFE_WOOPRTN.WO_OP_REF.AVAL]]
rem --- Verify wo_op_ref is unique
	wo_op_ref$=callpoint!.getUserInput()
	prev_wo_op_ref$=callpoint!.getDevObject("prev_wo_op_ref")
	refnumMap!=callpoint!.getDevObject("refnumMap")
	if wo_op_ref$<>prev_wo_op_ref$ then
		if refnumMap!.containsKey(wo_op_ref$) then
			msg_id$="SF_DUP_REF_NUM"
			dim msg_tokens$[1]
			msg_tokens$[1]=wo_op_ref$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		else
			refnumMap!.remove(prev_wo_op_ref$)
			refnumMap!.put(wo_op_ref$,"")
			if num(prev_wo_op_ref$)=callpoint!.getDevObject("lastOpRef") then
				callpoint!.setDevObject("lastOpRef",num(prev_wo_op_ref$)-1)
			endif
			if num(wo_op_ref$)>callpoint!.getDevObject("lastOpRef") then
				callpoint!.setDevObject("lastOpRef",num(wo_op_ref$))
			endif
		endif
	endif

rem --- Enable/disable comments field
	line_type$=callpoint!.getColumnData("SFE_WOOPRTN.LINE_TYPE")
	gosub enable_comments
[[SFE_WOOPRTN.WO_OP_REF.BINP]]
rem ---  Initialize and capture starting wo_op_ref
	prev_wo_op_ref$=callpoint!.getColumnData("SFE_WOOPRTN.WO_OP_REF")

	rem --- initialize wo_op_ref
	dim sfe_wooprtn$:fnget_tpl$("SFE_WOOPRTN")
	wk$=fattr(sfe_wooprtn$,"WO_OP_REF")
	opRef_mask$=fill(dec(wk$(10,2)),"0")
	maxOpRef=num(fill(dec(wk$(10,2)),"9"))
	refnumMap!=callpoint!.getDevObject("refnumMap")
	while cvs(prev_wo_op_ref$,2)=""
		rem --- with 6 digit wo_op_ref, would need 1,000,000 operations to create an endless loop
		nextOpRef=1+callpoint!.getDevObject("lastOpRef")
		if nextOpRef>maxOpRef then nextOpRef=1
		callpoint!.setDevObject("lastOpRef",nextOpRef)

		rem --- new wo_op_ref must be unique
		newOpRef$=str(nextOpRef,opRef_mask$)
		if !refnumMap!.containsKey(newOpRef$) then
			refnumMap!.put(newOpRef$,"")
			prev_wo_op_ref$=newOpRef$
		endif
	wend

	callpoint!.setColumnData("SFE_WOOPRTN.WO_OP_REF",prev_wo_op_ref$,1)
	callpoint!.setDevObject("prev_wo_op_ref",prev_wo_op_ref$)
[[SFE_WOOPRTN.BFMC]]
rem --- set validation table for op codes to use sf codes if no bom interface (or bom not installed)

	if callpoint!.getDevObject("bm")<>"Y"
		callpoint!.setTableColumnAttribute("SFE_WOOPRTN.OP_CODE","DTAB","SFC_OPRTNCOD")
	endif

[[SFE_WOOPRTN.BDEL]]
rem --- Update refnumMap!
	refnumMap!=callpoint!.getDevObject("refnumMap")
	wo_op_ref$=callpoint!.getColumnData("SFE_WOOPRTN.WO_OP_REF")
	refnumMap!.remove(wo_op_ref$)

rem --- v6 didn't do this, but before deleting, check to make sure the op isn't used in a material or subcontract line
[[SFE_WOOPRTN.REQUIRE_DATE.AVAL]]
rem --- Deal with Schedule Records

	if callpoint!.getUserInput()<>callpoint!.getColumnData("SFE_WOOPRTN.REQUIRE_DATE")
		gosub remove_sched
		setup_time=num(callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME"))
		hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
		pcs_per_hr=num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))
		yield=num(callpoint!.getDevObject("wo_est_yield"))
		run_time=SfUtils.opUnits(hrs_per_pc,pcs_per_hr,yield)
		move_time=num(callpoint!.getColumnData("SFE_WOOPRTN.MOVE_TIME"))
		add_date$=callpoint!.getUserInput()
		gosub add_sched
	endif
[[SFE_WOOPRTN.MOVE_TIME.AVAL]]
rem --- Deal with Schedule Records

	setup_time=num(callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME"))
	hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
	pcs_per_hr=num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))
	yield=num(callpoint!.getDevObject("wo_est_yield"))
	run_time=SfUtils.opUnits(hrs_per_pc,pcs_per_hr,yield)
	move_time=num(callpoint!.getUserInput())
	add_date$=callpoint!.getColumnData("SFE_WOOPRTN.REQUIRE_DATE")
	if callpoint!.getUserInput()<>callpoint!.getColumnData("SFE_WOOPRTN.MOVE_TIME")
		gosub remove_sched
		gosub add_sched
	endif

rem --- Calculate totals

	hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
	pcs_per_hr=num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))
	dir_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.DIRECT_RATE"))
	ovhd_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.OVHD_RATE"))
	setup=num(callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME"))
	gosub calc_totals
[[SFE_WOOPRTN.SETUP_TIME.AVAL]]
rem --- Deal with Schedule Records

	setup_time=num(callpoint!.getUserInput())
	hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
	pcs_per_hr=num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))
	yield=num(callpoint!.getDevObject("wo_est_yield"))
	run_time=SfUtils.opUnits(hrs_per_pc,pcs_per_hr,yield)
	move_time=num(callpoint!.getColumnData("SFE_WOOPRTN.MOVE_TIME"))
	add_date$=callpoint!.getColumnData("SFE_WOOPRTN.REQUIRE_DATE")

	if callpoint!.getUserInput()<>callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME")
		gosub remove_sched
		gosub add_sched
	endif

rem --- Calculate totals

	hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
	pcs_per_hr=num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))
	dir_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.DIRECT_RATE"))
	ovhd_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.OVHD_RATE"))
	setup=num(callpoint!.getUserInput())
	gosub calc_totals
[[SFE_WOOPRTN.PCS_PER_HOUR.AVAL]]
rem --- Check for valid quantity

	if num(callpoint!.getUserInput())=0
		msg_id$="VALUE_GT_ZERO"
		gosub disp_message
		callpoint!.setColumnData("SFE_WOOPRTN.PCS_PER_HOUR","1",1)
		callpoint!.setFocus(callpoint!.getValidationRow(),"SFE_WOOPRTN.PCS_PER_HOUR")
	endif

rem --- Deal with Schedule Records

	setup_time=num(callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME"))
	hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
	pcs_per_hr=num(callpoint!.getUserInput())
	yield=num(callpoint!.getDevObject("wo_est_yield"))
	run_time=SfUtils.opUnits(hrs_per_pc,pcs_per_hr,yield)
	move_time=num(callpoint!.getColumnData("SFE_WOOPRTN.MOVE_TIME"))
	add_date$=callpoint!.getColumnData("SFE_WOOPRTN.REQUIRE_DATE")

	if callpoint!.getUserInput()<>callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME")
		gosub remove_sched
		gosub add_sched
	endif

rem --- Calculate totals

	hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
	pcs_per_hr=num(callpoint!.getUserInput())
	dir_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.DIRECT_RATE"))
	ovhd_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.OVHD_RATE"))
	setup=num(callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME"))
	gosub calc_totals
[[SFE_WOOPRTN.HRS_PER_PCE.AVAL]]
rem --- Calculate totals

	hrs_per_pc=num(callpoint!.getUserInput())
	pcs_per_hr=num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))
	dir_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.DIRECT_RATE"))
	ovhd_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.OVHD_RATE"))
	setup=num(callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME"))
	gosub calc_totals
[[SFE_WOOPRTN.OP_CODE.AVAL]]
rem --- Display Queue time

	op_code$=callpoint!.getUserInput()
	gosub disp_queue

	hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
	pcs_per_hr=num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))
	dir_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.DIRECT_RATE"))
	ovhd_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.OVHD_RATE"))
	setup=num(callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME"))
	gosub calc_totals
[[SFE_WOOPRTN.<CUSTOM>]]
rem ===============================================================
disp_queue:
rem	op_code$:	input
rem ===============================================================

	opcode_dev=num(callpoint!.getDevObject("opcode_chan"))
	dim opcode$:callpoint!.getDevObject("opcode_tpl")
	callpoint!.setColumnData("SFE_WOOPRTN.CODE_DESC","",0)

	while 1
		read record (opcode_dev,key=firm_id$+op_code$,dom=*break)opcode$
		callpoint!.setColumnData("<<DISPLAY>>.QUEUE_TIME",opcode.queue_time$,1)
		callpoint!.setColumnData("SFE_WOOPRTN.CODE_DESC",opcode.code_desc$,0)
		break
	wend

	if opcode.pcs_per_hour=0 opcode.pcs_per_hour=1
	if num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))=0
		callpoint!.setColumnData("SFE_WOOPRTN.PCS_PER_HOUR",opcode.pcs_per_hour$,1)
	endif
	if num(callpoint!.getColumnData("SFE_WOOPRTN.DIRECT_RATE"))=0
		callpoint!.setColumnData("SFE_WOOPRTN.DIRECT_RATE",opcode.direct_rate$)
	endif
	if num(callpoint!.getColumnData("SFE_WOOPRTN.OVHD_RATE"))=0
		dir_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.DIRECT_RATE"))
		callpoint!.setColumnData("SFE_WOOPRTN.OVHD_RATE",str(dir_rate*opcode.ovhd_factor))
	endif
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y"
		callpoint!.setColumnData("SFE_WOOPRTN.SETUP_TIME",opcode.setup_time$,1)
		callpoint!.setColumnData("SFE_WOOPRTN.MOVE_TIME",opcode.move_time$,1)
	endif

	hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
	pcs_per_hr=num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))
	dir_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.DIRECT_RATE"))
	ovhd_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.OVHD_RATE"))
	setup=num(callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME"))
	setup_time=setup
	gosub calc_totals

	return

rem ===============================================================
calc_totals:
rem	hrs_per_pc:	input
rem	pcs_per_hr:	input
rem dir_rate:		input
rem ovhd_rate:	input
rem setup:		input
rem ===============================================================

	yield=num(callpoint!.getDevObject("wo_est_yield"))
	sched_qty=num(callpoint!.getDevObject("prod_qty"))

	run_time=SfUtils.opUnits(hrs_per_pc,pcs_per_hr,yield)
	unit_cost=SfUtils.opUnitsDollars(hrs_per_pc,dir_rate,ovhd_rate,pcs_per_hr,yield)
	callpoint!.setColumnData("SFE_WOOPRTN.RUNTIME_HRS",str(run_time))
	callpoint!.setColumnData("SFE_WOOPRTN.UNIT_COST",str(unit_cost),1)

	old_tot_time=num(callpoint!.getColumnData("SFE_WOOPRTN.TOTAL_TIME"))
	new_tot_time=SfUtils.opTime(1,sched_qty,hrs_per_pc,pcs_per_hr,yield,setup)
	new_tot_dols=SfUtils.opTotStdCost(sched_qty,hrs_per_pc,dir_rate,ovhd_rate,pcs_per_hr,yield,setup)
	callpoint!.setColumnData("SFE_WOOPRTN.TOTAL_TIME",str(new_tot_time))
	callpoint!.setColumnData("SFE_WOOPRTN.TOT_STD_COST",str(new_tot_dols))

rem	if old_tot_time<>new_tot_time * need to make this happen every time - 12/12/12
		gosub remove_sched
rem jpb need to add the correct records back in - not happening right now.
rem jpb None of the input variables are being sent in * I think this is happening now - need more testing - 12/12/12
		gosub add_sched
rem	endif * need to make this happen every time - 12/12/12

	return

rem ===============================================================
remove_sched:
rem ===============================================================

	sfm05_dev=fnget_dev("SFE_WOSCHDL")
	dim sfm05a$:fnget_tpl$("SFE_WOSCHDL")
	wo_no$=callpoint!.getColumnData("SFE_WOOPRTN.WO_NO")
	isn$=callpoint!.getColumnData("SFE_WOOPRTN.INTERNAL_SEQ_NO")

	read (sfm05_dev,key=firm_id$+wo_no$+isn$,knum="AON_WONUM",dom=*next)
	while 1
		extract record (sfm05_dev,end=*break) sfm05a$; rem --- Advisory locking
		if pos(firm_id$+wo_no$+isn$=sfm05a.firm_id$+sfm05a.wo_no$+sfm05a.oper_seq_ref$)<>1 break
		remove (sfm05_dev,key=firm_id$+sfm05a.op_code$+sfm05a.sched_date$+sfm05a.wo_no$+sfm05a.oper_seq_ref$)
	wend

	return

rem ===============================================================
add_sched:
rem setup_time:	input
rem run_time:		input
rem move_time:	input
rem add_date$:	input
rem ===============================================================

	if callpoint!.getColumnData("SFE_WOOPRTN.LINE_TYPE")="S"
		sfm05_dev=fnget_dev("SFE_WOSCHDL")
		dim sfm05a$:fnget_tpl$("SFE_WOSCHDL")
		queue_time=num(callpoint!.getColumnData("<<DISPLAY>>.QUEUE_TIME"))

		sfm05a.firm_id$=firm_id$
		sfm05a.op_code$=callpoint!.getColumnData("SFE_WOOPRTN.OP_CODE")
		sfm05a.sched_date$=add_date$
		sfm05a.wo_no$=callpoint!.getColumnData("SFE_WOOPRTN.WO_NO")
		sfm05a.oper_seq_ref$=callpoint!.getColumnData("SFE_WOOPRTN.INTERNAL_SEQ_NO")
		sfm05a.queue_time=queue_time
		sfm05a.setup_time=setup_time
		sfm05a.runtime_hrs=run_time
		sfm05a.move_time=move_time
		sfm05a$=field(sfm05a$)
		write record (sfm05_dev) sfm05a$
	endif

	return

rem ========================================================
comment_entry:
rem --- on a line where you can access the ls_comments field, pop the new memo_1024 editor instead
rem --- the editor can be popped on demand for any line using the Comments button (alt-C),
rem --- but will automatically pop for lines where the ext_comments field is enabled.
rem ==========================================================================

	disp_text$=callpoint!.getColumnData("SFE_WOOPRTN.MEMO_1024")
	sv_disp_text$=disp_text$

	rem --- Comments are not editable if WO is closed, or line type isn't M
	line_type$=callpoint!.getColumnData("SFE_WOOPRTN.LINE_TYPE")
	if callpoint!.getDevObject("wo_status")="C" or pos(line_type$="M")=0 then
		editable$="NO"
	else
		editable$="YES"
	endif

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
		callpoint!.setColumnData("SFE_WOOPRTN.MEMO_1024",disp_text$,1)
		callpoint!.setColumnData("SFE_WOOPRTN.EXT_COMMENTS",ext_comments$,1)
		callpoint!.setStatus("MODIFIED")
	endif

	callpoint!.setStatus("ACTIVATE")

	return

rem ========================================================
enable_comments:
rem line_type:	input
rem ========================================================

	if callpoint!.getDevObject("wo_status")<>"C" and pos(line_type$="M") then
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOOPRTN.MEMO_1024",1)
		callpoint!.setOptionEnabled("COMM",1)
	else
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOOPRTN.MEMO_1024",0)
		callpoint!.setOptionEnabled("COMM",0)
	endif

	return
[[SFE_WOOPRTN.AGDR]]
rem --- Enable/disable comments
	line_type$=callpoint!.getColumnData("SFE_WOOPRTN.LINE_TYPE")
	gosub enable_comments

rem --- Track wo_op_ref in Map to insure they are unique
	refnumMap!=callpoint!.getDevObject("refnumMap")
	lastOpRef=callpoint!.getDevObject("lastOpRef")
	wo_op_ref$=callpoint!.getColumnData("SFE_WOOPRTN.WO_OP_REF")
	refnumMap!.put(wo_op_ref$,"")
	if num(wo_op_ref$)>lastOpRef then
		callpoint!.setDevObject("lastOpRef",num(wo_op_ref$))
	endif


rem --- Display Queue time

	op_code$=callpoint!.getColumnData("SFE_WOOPRTN.OP_CODE")
	add_date$=callpoint!.getColumnData("SFE_WOOPRTN.REQUIRE_DATE")
	setup=num(callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME"))
	move_time=num(callpoint!.getColumnData("SFE_WOOPRTN.MOVE_TIME"))

	gosub disp_queue
[[SFE_WOOPRTN.BSHO]]
use ::ado_util.src::util
use ::sfo_SfUtils.aon::SfUtils
declare SfUtils sfUtils!


rem --- Set column size for memo_1024 field very small so it doesn't take up room, but still available for hover-over of memo contents

	maintGrid!=Form!.getControl(num(stbl("+GRID_CTL")))
	col_hdr$=callpoint!.getTableColumnAttribute("SFE_WOOPRTN.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(maintGrid!, col_hdr$)
	maintGrid!.setColumnWidth(memo_1024_col,15)

rem --- init data

	refnumMap!=new java.util.HashMap()
	callpoint!.setDevObject("refnumMap",refnumMap!)
	callpoint!.setDevObject("lastOpRef",0)

rem --- Disable grid if Closed Work Order

	if callpoint!.getDevObject("wo_status")="C"
		opts$=callpoint!.getTableAttribute("OPTS")
		callpoint!.setTableAttribute("OPTS",opts$+"BID")

		x$=callpoint!.getTableColumns()
		for x=1 to len(x$) step 40
			opts$=callpoint!.getTableColumnAttribute(cvs(x$(x,40),2),"OPTS")
			callpoint!.setTableColumnAttribute(cvs(x$(x,40),2),"OPTS",opts$+"C"); rem - makes cells read only
		next x
	endif

rem --- Disable WO_OP_REF when locked
	if callpoint!.getDevObject("lock_ref_num")="Y" then
		opts$=callpoint!.getTableColumnAttribute("SFE_WOOPRTN.WO_OP_REF","OPTS")
		callpoint!.setTableColumnAttribute("SFE_WOOPRTN.WO_OP_REF","OPTS",opts$+"C"); rem --- makes read only
	endif
