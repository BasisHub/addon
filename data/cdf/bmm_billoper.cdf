[[BMM_BILLOPER.LINE_TYPE.AVAL]]
rem --- Enable/disable Comments button
	line_type$=callpoint!.getColumnData("BMM_BILLOPER.LINE_TYPE")
	gosub enable_comments
[[BMM_BILLOPER.AOPT-COMM]]
rem --- Launch Comments dialog
	gosub comment_entry
[[BMM_BILLOPER.EXT_COMMENTS.BINP]]
rem --- Launch Comments dialog
	gosub comment_entry
	callpoint!.setStatus("ABORT")
[[BMM_BILLOPER.MEMO_1024.AVAL]]
rem --- Store first part of memo_1024 in ext_comment.
rem --- This AVAL is hit if user navigates via arrows or clicks on the memo_1024 field, and double-clicks or ctrl-F to bring up editor.
rem --- If use Comment field, or use ctrl-C or Comments button, code in the comment_entry subroutine is hit instead.
	disp_text$=callpoint!.getUserInput()
	if disp_text$<>callpoint!.getColumnUndoData("BMM_BILLOPER.MEMO_1024")
		dim ext_comments$(60)
		ext_comments$(1)=disp_text$(1,pos($0A$=disp_text$+$0A$)-1)
		callpoint!.setColumnData("BMM_BILLOPER.MEMO_1024",disp_text$,1)
		callpoint!.setColumnData("BMM_BILLOPER.EXT_COMMENTS",ext_comments$,1)
		callpoint!.setStatus("MODIFIED")
	endif
[[BMM_BILLOPER.MEMO_1024.BINQ]]
rem --- (Barista Bug 9179 workaround) If grid cell isn't editable, then abort so new text can't be entered via edit control.
	maintGrid!=Form!.getControl(num(stbl("+GRID_CTL")))
	col_hdr$=callpoint!.getTableColumnAttribute("BMM_BILLOPER.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(maintGrid!, col_hdr$)
	this_row=callpoint!.getValidationRow()
	isEditable=maintGrid!.isCellEditable(this_row,memo_1024_col)
	if !isEditable then callpoint!.setStatus("ABORT")
[[BMM_BILLOPER.AGDR]]
rem --- Track wo_op_ref in Map to insure they are unique
	refnumMap!=callpoint!.getDevObject("refnumMap")
	lastOpRef=callpoint!.getDevObject("lastOpRef")
	wo_op_ref$=callpoint!.getColumnData("BMM_BILLOPER.WO_OP_REF")
	refnumMap!.put(wo_op_ref$,"")
	if num(wo_op_ref$)>lastOpRef then
		callpoint!.setDevObject("lastOpRef",num(wo_op_ref$))
	endif

rem --- Enable/disable Comments button
	line_type$=callpoint!.getColumnData("BMM_BILLOPER.LINE_TYPE")
	gosub enable_comments
[[BMM_BILLOPER.BDEL]]
rem --- Update refnumMap!
	refnumMap!=callpoint!.getDevObject("refnumMap")
	wo_op_ref$=callpoint!.getColumnData("BMM_BILLOPER.WO_OP_REF")
	refnumMap!.remove(wo_op_ref$)
[[BMM_BILLOPER.WO_OP_REF.BINP]]
rem ---  Initialize and capture starting wo_op_ref
	prev_wo_op_ref$=callpoint!.getColumnData("BMM_BILLOPER.WO_OP_REF")

	rem --- initialize wo_op_ref
	dim bmm_billoper$:fnget_tpl$("BMM_BILLOPER")
	wk$=fattr(bmm_billoper$,"WO_OP_REF")
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

	callpoint!.setColumnData("BMM_BILLOPER.WO_OP_REF",prev_wo_op_ref$,1)
	callpoint!.setDevObject("prev_wo_op_ref",prev_wo_op_ref$)
[[BMM_BILLOPER.WO_OP_REF.AVAL]]
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
[[BMM_BILLOPER.BUDE]]
rem --- Verify wo_op_ref is unique
	refnumMap!=callpoint!.getDevObject("refnumMap")
	wo_op_ref$=callpoint!.getColumnData("BMM_BILLOPER.WO_OP_REF")
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
[[BMM_BILLOPER.AGRN]]
rem --- Set Op Code DevObject

	callpoint!.setDevObject("op_code",callpoint!.getColumnData("BMM_BILLOPER.OP_CODE"))

rem --- Enable/disable Comments button
	line_type$=callpoint!.getColumnData("BMM_BILLOPER.LINE_TYPE")
	gosub enable_comments
[[BMM_BILLOPER.AREC]]
rem --- Set Op Code DevObject

	callpoint!.setDevObject("op_code","")
[[BMM_BILLOPER.EFFECT_DATE.AVAL]]
rem --- Check for valid dates

	eff_date$=callpoint!.getUserInput()
	obs_date$=callpoint!.getColumnData("BMM_BILLOPER.OBSOLT_DATE")
	msg_id$="BM_OBS_EFF"
	gosub check_dates
[[BMM_BILLOPER.OBSOLT_DATE.AVAL]]
rem --- Check for valid dates

	eff_date$=callpoint!.getColumnData("BMM_BILLOPER.EFFECT_DATE")
	obs_date$=callpoint!.getUserInput()
	msg_id$="BM_EFF_OBS"
	gosub check_dates
[[BMM_BILLOPER.BGDR]]
rem --- Display Total Hours

	hrs_pc=num(callpoint!.getColumnData("BMM_BILLOPER.HRS_PER_PCE"))
	pc_hr=num(callpoint!.getColumnData("BMM_BILLOPER.PCS_PER_HOUR"))
	setup=num(callpoint!.getColumnData("BMM_BILLOPER.SETUP_TIME"))
	op_code$=callpoint!.getColumnData("BMM_BILLOPER.OP_CODE")
	gosub calc_hours
[[BMM_BILLOPER.OP_CODE.AVAL]]
rem --- Setup default data for new S type line

	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" or
:		callpoint!.getUserInput()<>callpoint!.getDevObject("op_code")
		bmm08=fnget_dev("BMC_OPCODES")
		dim bmm08$:fnget_tpl$("BMC_OPCODES")
		op_code$=callpoint!.getUserInput()
		read record (bmm08,key=firm_id$+op_code$,dom=*next)bmm08$
		callpoint!.setColumnData("BMM_BILLOPER.MOVE_TIME",bmm08.move_time$)
		callpoint!.setColumnData("BMM_BILLOPER.PCS_PER_HOUR",bmm08.pcs_per_hour$)
		callpoint!.setColumnData("BMM_BILLOPER.SETUP_TIME",bmm08.setup_time$)
		callpoint!.setColumnData("BMM_BILLOPER.HRS_PER_PCE","1")
		callpoint!.setColumnData("<<DISPLAY>>.QUEUE_TIME",bmm08.queue_time$)
		callpoint!.setColumnData("BMM_BILLOPER.MOVE_TIME",bmm08.move_time$)
		hrs_pc=1
		pc_hr=bmm08.pcs_per_hour
		setup=bmm08.setup_time
		gosub calc_hours
		callpoint!.setDevObject("op_code",op_code$)
	endif
[[BMM_BILLOPER.SETUP_TIME.AVAL]]
rem --- Display Total Hours

	hrs_pc=num(callpoint!.getColumnData("BMM_BILLOPER.HRS_PER_PCE"))
	pc_hr=num(callpoint!.getColumnData("BMM_BILLOPER.PCS_PER_HOUR"))
	setup=num(callpoint!.getUserInput())
	op_code$=callpoint!.getColumnData("BMM_BILLOPER.OP_CODE")
	gosub calc_hours
[[BMM_BILLOPER.PCS_PER_HOUR.AVAL]]
rem --- Display Total Hours

	hrs_pc=num(callpoint!.getColumnData("BMM_BILLOPER.HRS_PER_PCE"))
	pc_hr=num(callpoint!.getUserInput())
	setup=num(callpoint!.getColumnData("BMM_BILLOPER.SETUP_TIME"))
	op_code$=callpoint!.getColumnData("BMM_BILLOPER.OP_CODE")
	gosub calc_hours
[[BMM_BILLOPER.HRS_PER_PCE.AVAL]]
rem --- Display Total Hours

	hrs_pc=num(callpoint!.getUserInput())
	pc_hr=num(callpoint!.getColumnData("BMM_BILLOPER.PCS_PER_HOUR"))
	setup=num(callpoint!.getColumnData("BMM_BILLOPER.SETUP_TIME"))
	op_code$=callpoint!.getColumnData("BMM_BILLOPER.OP_CODE")
	gosub calc_hours
[[BMM_BILLOPER.<CUSTOM>]]
rem ===================================================================
calc_hours:
rem --- hrs_pc:			input
rem --- pc_hr:			input
rem --- setup:			input
rem --- op_code:		input
rem ===================================================================

	old_prec = tcb(14)
	precision callpoint!.getDevObject("this_precision")

	bmm08=fnget_dev("BMC_OPCODES")
	dim bmm08$:fnget_tpl$("BMC_OPCODES")
	read record (bmm08,key=firm_id$+op_code$,dom=*next)bmm08$
	direct_rate=bmm08.direct_rate*1.0
	oh_rate=bmm08.ovhd_factor

	yield_pct=callpoint!.getDevObject("yield")
	lot_size=callpoint!.getDevObject("lotsize")
	direct_cost=1*BmUtils.directCost(hrs_pc,direct_rate,pc_hr,yield_pct,setup,lot_size)
	oh_cost=direct_cost*oh_rate
	if pc_hr=0 pc_hr=1
	net_hrs=100*(hrs_pc/pc_hr)/yield_pct+setup/lot_size
	callpoint!.setColumnData("<<DISPLAY>>.DIRECT_RATE",str(direct_rate),1)
	callpoint!.setColumnData("<<DISPLAY>>.DIRECT_COST",str(direct_cost),1)
	callpoint!.setColumnData("<<DISPLAY>>.OVHD_COST",str(oh_cost),1)
	callpoint!.setColumnData("<<DISPLAY>>.TOT_COST",str(direct_cost+oh_cost),1)
	callpoint!.setColumnData("<<DISPLAY>>.QUEUE_TIME",bmm08.queue_time$,1)
	callpoint!.setColumnData("<<DISPLAY>>.NET_HRS",str(net_hrs),1)

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

rem ==========================================================================
comment_entry:
rem --- on a line where you can access the ext_comments field, pop the new memo_1024 editor instead
rem --- the editor can be popped on demand for any line using the Comments button (alt-C),
rem --- but will automatically pop for lines where the ext_comments field is enabled.
rem ==========================================================================

	disp_text$=callpoint!.getColumnData("BMM_BILLOPER.MEMO_1024")
	sv_disp_text$=disp_text$

	rem --- Comments are only editable for line type M
	line_type$=callpoint!.getColumnData("BMM_BILLOPER.LINE_TYPE")
	if line_type$="M" then
		editable$="YES"
	else
		editable$="NO"
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
		callpoint!.setColumnData("BMM_BILLOPER.MEMO_1024",disp_text$,1)
		callpoint!.setColumnData("BMM_BILLOPER.EXT_COMMENTS",ext_comments$,1)
		callpoint!.setStatus("MODIFIED")
	endif

	callpoint!.setStatus("ACTIVATE")

	return

rem ========================================================
enable_comments:
rem line_type:	input
rem ========================================================

	if line_type$="M" then
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"BMM_BILLOPER.MEMO_1024",1)
		callpoint!.setOptionEnabled("COMM",1)
	else
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"BMM_BILLOPER.MEMO_1024",0)
		callpoint!.setOptionEnabled("COMM",0)
	endif

	return
[[BMM_BILLOPER.BSHO]]
rem --- Setup java class for Derived Data Element

	use ::ado_util.src::util
	use ::bmo_BmUtils.aon::BmUtils
	declare BmUtils bmUtils!

rem --- Set column size for memo_1024 field very small so it doesn't take up room, but still available for hover-over of memo contents

	maintGrid!=Form!.getControl(num(stbl("+GRID_CTL")))
	col_hdr$=callpoint!.getTableColumnAttribute("BMM_BILLOPER.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(maintGrid!, col_hdr$)
	maintGrid!.setColumnWidth(memo_1024_col,15)

rem --- Open files for later use

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="BMC_OPCODES",open_opts$[1]="OTA"
	gosub open_tables

rem --- init data

	refnumMap!=new java.util.HashMap()
	callpoint!.setDevObject("refnumMap",refnumMap!)
	callpoint!.setDevObject("lastOpRef",0)

rem --- Disable WO_OP_REF when locked
	if callpoint!.getDevObject("lock_ref_num")="Y" then
		opts$=callpoint!.getTableColumnAttribute("BMM_BILLOPER.WO_OP_REF","OPTS")
		callpoint!.setTableColumnAttribute("BMM_BILLOPER.WO_OP_REF","OPTS",opts$+"C"); rem --- makes read only
	endif
