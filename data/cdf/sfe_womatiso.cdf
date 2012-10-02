[[SFE_WOMATISO.BEND]]
rem --- Clear qty_to_issue and girdOps! if did not push OK button, i.e. hit Cancel or Exit

	if callpoint!.getDevObject("did_asva")<>"y" then
		callpoint!.setDevObject("qty_to_issue",0)

		selected_ops!=callpoint!.getDevObject("selected_ops")
		iter!=selected_ops!.keySet().iterator()
		while iter!.hasNext()
			op_seq$=iter!.next()
			selected_ops!.put(op_seq$,"")
		wend
		callpoint!.setDevObject("selected_ops",selected_ops!)
	endif
[[SFE_WOMATISO.ASVA]]
rem --- Validate qty_to_issue

	qty_to_issue=num(callpoint!.getColumnData("SFE_WOMATISO.QTY_TO_ISSUE"))
	gosub validate_qty_to_issue
	if !issue_qty_ok then
		callpoint!.setFocus("SFE_WOMATISO.QTY_TO_ISSUE")
		break
	endif

	callpoint!.setDevObject("did_asva","y")
	callpoint!.setStatus("EXIT")
[[SFE_WOMATISO.QTY_TO_ISSUE.AVAL]]
rem --- Validate qty_to_issue

	qty_to_issue=num(callpoint!.getUserInput())
	gosub validate_qty_to_issue
	if !issue_qty_ok then
		break
	endif

	callpoint!.setDevObject("qty_to_issue",qty_to_issue)

[[SFE_WOMATISO.AREC]]
rem --- Intialize qty_remain and qty_to_issue fields

	qty_remain=callpoint!.getDevObject("qty_remain")
	callpoint!.setColumnData("<<DISPLAY>>.QTY_REMAIN",str(qty_remain),1)
	callpoint!.setColumnData("SFE_WOMATISO.QTY_TO_ISSUE",str(qty_remain),1)
	callpoint!.setDevObject("qty_to_issue",qty_remain)

rem --- Set flag to capture when OK button is pushed

	callpoint!.setDevObject("did_asva","n")
[[SFE_WOMATISO.BSHO]]
rem --- Initialize remaining quantity that can be issued

	sfe_womastr_dev=fnget_dev("SFE_WOMASTR")
	dim sfe_womastr$:fnget_tpl$("SFE_WOMASTR")

	firm_loc_wo$=callpoint!.getDevObject("firm_loc_wo")
	findrecord(sfe_womastr_dev,key=firm_loc_wo$,dom=*next)sfe_womastr$

	callpoint!.setDevObject("qty_remain",sfe_womastr.sch_prod_qty-sfe_womastr.qty_cls_todt)
[[SFE_WOMATISO.ACUS]]
rem --- Process custom event

rem This routine is executed when callbacks have been set to run a 'custom event'.
rem Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind of event it is.
rem See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info.

	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ctl_ID=dec(gui_event.ID$)

	if ctl_ID <> num(callpoint!.getDevObject("ops_grid_id")) then break; rem --- exit callpoint

	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
	endif

	switch notice.code
		case 12;rem grid_key_press
			if notice.wparam=32 then gosub switch_value
			break
		case 14;rem grid_mouse_up
			if notice.col=0 then gosub switch_value
			break
	swend
[[SFE_WOMATISO.<CUSTOM>]]
format_grid: rem --- Format grid

	def_rpts_cols=5
	num_rpts_rows=0

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()

	dim attr_rpts_col$[def_rpts_cols,len(attr_def_col_str$[0,0])/5]
	attr_rpts_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SELECT"
	attr_rpts_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=""
	attr_rpts_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"
	attr_rpts_col$[1,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="1"
	attr_rpts_col$[1,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="C"

	attr_rpts_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="OP_SEQ"
	attr_rpts_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_SEQ")
	attr_rpts_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="35"

	attr_rpts_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="OP_CODE"
	attr_rpts_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_OP_CODE")
	attr_rpts_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="40"

	attr_rpts_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="CODE_DESC"
	attr_rpts_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DESCRIPTION")
	attr_rpts_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="300"

	attr_rpts_col$[5,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="INTERNAL_SEQ_NO"
	attr_rpts_col$[5,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=""
	attr_rpts_col$[5,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="1"

	for curr_attr=1 to def_rpts_cols
		attr_rpts_col$[0,1]=attr_rpts_col$[0,1]+pad("OPS."+attr_rpts_col$[curr_attr,
:			fnstr_pos("DVAR",attr_def_col_str$[0,0],5)],40)
	next curr_attr

	attr_disp_col$=attr_rpts_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridOps!,"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC-DATES-CHECKS",num_rpts_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_rpts_col$[all]

	return

switch_value: rem --- Switch checkbox values

	SysGUI!.setRepaintEnabled(0)
	gridOps!=callpoint!.getDevObject("gridOps")
	TempRows!=gridOps!.getSelectedRows()
	if TempRows!.size()>0
		selected_ops!=callpoint!.getDevObject("selected_ops")
		for curr_row=1 to TempRows!.size()
			if gridOps!.getCellState(TempRows!.getItem(curr_row-1),0)=0
				gridOps!.setCellState(TempRows!.getItem(curr_row-1),0,1)
				selected_ops!.put(gridOps!.getCellText(TempRows!.getItem(curr_row-1),1),gridOps!.getCellText(TempRows!.getItem(curr_row-1),4))
			else
				gridOps!.setCellState(num(TempRows!.getItem(curr_row-1)),0,0)
				selected_ops!.put(gridOps!.getCellText(TempRows!.getItem(curr_row-1),1),"")
			endif
		next curr_row
	endif

	SysGUI!.setRepaintEnabled(1)

	return

fill_grid: rem --- Fill the grid with data

	sfe_wooprtn_dev=fnget_dev("SFE_WOOPRTN")
	dim sfe_wooprtn$:fnget_tpl$("SFE_WOOPRTN")
	opcode_dev=callpoint!.getDevObject("opcode_dev")
	opcode_tpl$=callpoint!.getDevObject("opcode_tpl")
	selected_ops!=callpoint!.getDevObject("selected_ops")

	vectRows!=SysGUI!.makeVector()
	firm_loc_wo$=callpoint!.getDevObject("firm_loc_wo")
	read(sfe_wooprtn_dev,key=firm_loc_wo$,dom=*next)
	while 1
		sfe_wooprtn_key$=key(sfe_wooprtn_dev,end=*break)
		if pos(firm_loc_wo$=sfe_wooprtn_key$)<>1 then break

		readrecord(sfe_wooprtn_dev,key=sfe_wooprtn_key$)sfe_wooprtn$
		if sfe_wooprtn.line_type$="M" then continue

		dim opcode$:opcode_tpl$
		findrecord(opcode_dev,key=firm_id$+sfe_wooprtn.op_code$,dom=*next)opcode$

		vectRows!.addItem("")
		vectRows!.addItem(sfe_wooprtn.op_seq$)
		vectRows!.addItem(sfe_wooprtn.op_code$)
		if cvs(opcode.code_desc$,2)<>"" then
			vectRows!.addItem(opcode.code_desc$)
		else
			vectRows!.addItem(sfe_wooprtn.code_desc$)
		endif
		vectRows!.addItem(sfe_wooprtn.internal_seq_no$)

		selected_ops!.put(sfe_wooprtn.op_seq$,"")
	wend

	SysGUI!.setRepaintEnabled(0)
	gridOps!=callpoint!.getDevObject("gridOps")
	if vectRows!.size()
		numrow=vectRows!.size()/gridOps!.getNumColumns()
		gridOps!.clearMainGrid()
		gridOps!.setNumRows(numrow)
		gridOps!.setCellText(0,0,vectRows!)
		gridOps!.resort()
		gridOps!.setSelectedRow(0)

		rem --- Initialize all operations selected
		for row=0 to numrow-1
			rem --- Set selected checkbox
			gridOps!.setCellState(row,0,1)
			selected_ops!.put(gridOps!.getCellText(row,1),gridOps!.getCellText(row,4))
		next row
	endif
	SysGUI!.setRepaintEnabled(1)
	return

validate_qty_to_issue: rem --- Validate qty_to_issue

	issue_qty_ok=1
	qty_remain=callpoint!.getDevObject("qty_remain")

	if qty_to_issue>qty_remain then
		msg_id$="SF_ISS_QTY_RIGHT"
		dim msg_tokens$[2]
		msg_tokens$[1]=str(qty_remain)
		msg_tokens$[2]=str(qty_to_issue)
		gosub disp_message
		if msg_opt$="N" then
			issue_qty_ok=0
			callpoint!.setColumnData("SFE_WOMATISO.QTY_TO_ISSUE",str(callpoint!.getDevObject("qty_to_issue")),1)
			callpoint!.setStatus("ABORT")
		endif
	endif

	return
[[SFE_WOMATISO.AWIN]]
rem --- Add grid to form for selecting Operations

	use java.util.Iterator
	use java.util.HashMap
	use ::ado_util.src::util

	nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))
	gridOps!=Form!.addGrid(nxt_ctlID,10,60,400,200); rem --- ID, x, y, width, height
	callpoint!.setDevObject("gridOps",gridOps!)
	callpoint!.setDevObject("ops_grid_id",str(nxt_ctlID))

	gosub format_grid
	gridOps!.setColumnStyle(0,SysGUI!.GRID_STYLE_UNCHECKED)
	gridOps!.setColumnEditable(0,1)

	rem --- HashMap to hold internal_seq_no for selected grid rows
	selected_ops!=new HashMap()
	callpoint!.setDevObject("selected_ops",selected_ops!)

	gosub fill_grid
	util.resizeWindow(Form!, SysGui!)

	rem --- Set callbacks - processed in ACUS callpoint
	gridOps!.setCallback(gridOps!.ON_GRID_KEY_PRESS,"custom_event")		
	gridOps!.setCallback(gridOps!.ON_GRID_MOUSE_UP,"custom_event")
