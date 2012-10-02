[[SFM_CAL_COPY.OP_CODE.AVAL]]
rem --- Create vector excluding the current Op Code

	current_opcode$=callpoint!.getUserInput()
	gosub get_first_last
	if cvs(first_date$,2)=""
		msg_id$="SF_NO_OP_CAL"
		gosub disp_message
		callpoint!.setUserInput("")
		callpoint!.setFocus("SFM_CAL_COPY.OP_CODE")
	else
		vectOps!=UserObj!.getItem(num(user_tpl.vectOpsOfst$))
		vectOps!.clear()
		gosub create_reports_vector
		gosub fill_grid
		UserObj!.setItem(num(user_tpl.vectOpsOfst$),vectOps!)
	endif
[[SFM_CAL_COPY.ACUS]]
rem --- Process custom event
rem --- Select/de-select checkboxes in grid and edit payment and discount amounts

rem This routine is executed when callbacks have been set to run a 'custom event'.
rem Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind of event it is.
rem See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info.

	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ctl_ID=dec(gui_event.ID$)

	if ctl_ID <> num(user_tpl.gridOpsCtlID$) then break; rem --- exit callpoint

	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
	endif

	gridOps! = UserObj!.getItem(num(user_tpl.gridOpsOfst$))
	numcols = gridOps!.getNumColumns()
	vectOps! = UserObj!.getItem(num(user_tpl.vectOpsOfst$))
	curr_row = dec(notice.row$)
	curr_col = dec(notice.col$)

	switch notice.code
		case 12; rem --- grid_key_press
			if notice.wparam=32 gosub switch_value
			break

		case 14; rem --- grid_mouse_up
			if notice.col=0 gosub switch_value
			break

		break
	swend
[[SFM_CAL_COPY.ASVA]]
rem --- Update calendar based on what's checked in the grid

	vectSelected!=BBjAPI().makeVector()
	vectOps!=UserObj!.getItem(num(user_tpl.vectOpsOfst$))
	if vectOps!.size()
		for row=0 to vectOps!.size()-1 step num(user_tpl.gridOpsCols$)
			if vectOps!.getItem(row)="Y"
				vectSelected!.addItem(vectOps!.getItem(row+1))
			endif
		next row
	endif

	if vectSelected!.size()=0
	        msg_id$="SF_OP_SELECTION "
	        gosub disp_message
		break
	endif

rem --- Now create a vector of all of the source records

	vectOldOps!=BBjAPI().makeVector()
	cal_dev=fnget_dev("SFM_OPCALNDR")
	dim cal$:fnget_tpl$("SFM_OPCALNDR")
	op_code$=callpoint!.getColumnData("SFM_CAL_COPY.OP_CODE")
	from_date$=callpoint!.getColumnData("SFM_CAL_COPY.COPY_FROM_DT")
	thru_date$=callpoint!.getColumnData("SFM_CAL_COPY.COPY_THRU_DT")
	read (cal_dev,key=firm_id$+op_code$,dom=*next)
	while 1
		read record (cal_dev,end=*break) cal$
		if pos(firm_id$+op_code$=cal$)<>1 break
		if cal.year$+cal.month$<from_date$(1,6) continue
		if cal.year$+cal.month$>thru_date$(1,6) continue
		vectOldOps!.addItem(cal$)
	wend

rem --- Now loop through vectOldOps to create/update new Op Codes

	if vectOldOps!.size()>0
		for x=0 to vectOldOps!.size()-1
			dim cal$:fattr(cal$)
			cal$=vectOldOps!.getItem(x)
			for y=0 to vectSelected!.size()-1
				dim calnew$:fattr(cal$)

				rem --- Figure out first and last day to copy

				if cal.year$+cal.month$=from_date$(1,6)
						start_day=num(from_date$(7,2))
						if calnew.year$+cal_month$=thru_date$(1,6)
							end_day=num(thru_date$(7,2))
						else
							end_day=cal.days_in_mth
						endif
				else
					if cal.year$+cal.month$=thru_date$(1,6)
						start_day=1
						end_day=num(thru_date$(7,2))
					endif
				endif

				read record (cal_dev,key=firm_id$+vectSelected!.getItem(y)+cal.year$+cal.month$,dom=*next) calnew$
				if cvs(calnew.firm_id$,2)=""
				rem --- new record

					calnew$=cal$
					calnew.op_code$=vectSelected!.getItem(y)
					for z=1 to 31
						if z<start_day or z>end_day
							field calnew$,"hrs_per_day_"+str(z:"00")=-1
						else
							field calnew$,"hrs_per_day_"+str(z:"00")=field (cal$,"hrs_per_day_"+str(z:"00"))
						endif
					next z
					calnew$=field(calnew$)
					write record (cal_dev) calnew$

				else
				rem --- Existing record

					calnew.op_code$=vectSelected!.getItem(y)
	
					rem --- loop through record and set each day
					for z=start_day to end_day
						field calnew$,"hrs_per_day_"+str(z:"00")=field (cal$,"hrs_per_day_"+str(z:"00"))
					next z
					calnew$=field(calnew$)
					write record (cal_dev) calnew$
				endif
			next y
		next x
	endif

	msg_id$="UPDATE_COMPLETE"
	gosub disp_message
[[SFM_CAL_COPY.ASIZ]]
rem --- Resize the grid

	if UserObj!<>null() then
		gridOps!=UserObj!.getItem(num(user_tpl.gridOpsOfst$))
		gridOps!.setColumnWidth(0,25)
		gridOps!.setColumnWidth(1,50)
		gridOps!.setSize(Form!.getWidth()-(gridOps!.getX()*2),Form!.getHeight()-(gridOps!.getY()+10))
		gridOps!.setFitToGrid(1)
	endif
[[SFM_CAL_COPY.AWIN]]
rem --- Initial setup

	use ::ado_util.src::util
	use ::ado_func.src::func

rem --- Open tables

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	if callpoint!.getDevObject("bm_interface")="Y"
		open_tables$[1]="BMC_OPCODES",open_opts$[1]="OTA"
	else
		open_tables$[1]="SFC_OPRTNCOD",open_opts$[1]="OTA"
	endif
	open_tables$[2]="SFM_OPCALNDR",open_opts$[2]="OTA"
	gosub open_tables

	callpoint!.setDevObject("opcode_dev",num(open_chans$[1]))
	callpoint!.setDevObject("opcode_tpl",open_tpls$[1])

rem --- Add grid to store invoices, with checkboxes for user to select one or more

	user_tpl_str$ = "gridOpsOfst:c(5), " +
:		"gridOpsCols:c(5), " +
:		"gridOpsRows:c(5), " +
:		"gridOpsCtlID:c(5)," +
:		"vectOpsOfst:c(5)"
	dim user_tpl$:user_tpl_str$

	UserObj! = BBjAPI().makeVector()
	vectOps! = BBjAPI().makeVector()
	nxt_ctlID = util.getNextControlID()

	gridOps! = Form!.addGrid(nxt_ctlID,5,140,800,300); rem --- ID, x, y, width, height

	user_tpl.gridOpsCtlID$ = str(nxt_ctlID)
	user_tpl.gridOpsCols$ = "3"
	user_tpl.gridOpsRows$ = "10"

	gosub format_grid
	util.resizeWindow(Form!, SysGui!)

	UserObj!.addItem(gridOps!)
	user_tpl.gridOpsOfst$="0"

	UserObj!.addItem(vectOps!); rem --- vector of Op Codes
	user_tpl.vectOpsOfst$="1"

rem --- Misc other init

	gridOps!.setColumnEditable(0,1)
	gridOps!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)
	gridOps!.setTabAction(gridOps!.GRID_NAVIGATE_GRID)

rem --- Set callbacks - processed in ACUS callpoint

	gridOps!.setCallback(gridOps!.ON_GRID_KEY_PRESS,"custom_event")
	gridOps!.setCallback(gridOps!.ON_GRID_MOUSE_UP,"custom_event")
[[SFM_CAL_COPY.<CUSTOM>]]
rem ==========================================================================
format_grid: rem --- Use Barista program to format the grid
rem ==========================================================================

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0] = callpoint!.getColumnAttributeTypes()
	def_op_cols = num(user_tpl.gridOpsCols$)
	num_rpts_rows = num(user_tpl.gridOpsRows$)
	dim attr_op_col$[def_op_cols,len(attr_def_col_str$[0,0])/5]

	attr_op_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SELECT"
	attr_op_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=""
	attr_op_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"
	attr_op_col$[1,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="1"
	attr_op_col$[1,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="C"

	attr_op_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="OP_CODE"
	attr_op_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_OP_CODE")
	attr_op_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"

	attr_op_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DESCRIPTION"
	attr_op_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DESCRIPTION")
	attr_op_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"

	for curr_attr=1 to def_op_cols
		attr_op_col$[0,1] = attr_op_col$[0,1] + 
:			pad("SFM_CAL_COPY." + attr_op_col$[curr_attr, fnstr_pos("DVAR", attr_def_col_str$[0,0], 5)], 40)
	next curr_attr

	attr_disp_col$=attr_op_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridOps!,"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC-CHECKS-DATES",num_rpts_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_op_col$[all]

	return

rem ==========================================================================
fill_grid: rem --- Fill the grid with data in vectOps!
rem ==========================================================================

	SysGUI!.setRepaintEnabled(0)
	gridOps! = UserObj!.getItem(num(user_tpl.gridOpsOfst$))
	minrows = num(user_tpl.gridOpsRows$)

	if vectOps!.size() then
		numrow = vectOps!.size() / gridOps!.getNumColumns()
		gridOps!.clearMainGrid()
		gridOps!.setColumnStyle(0,SysGUI!.GRID_STYLE_UNCHECKED)
		gridOps!.setNumRows(numrow)
		gridOps!.setCellText(0,0,vectOps!)

		for wk=0 to vectOps!.size()-1 step gridOps!.getNumColumns()
			if vectOps!.getItem(wk) = "Y" then 
				gridOps!.setCellStyle(wk / gridOps!.getNumColumns(), 0, SysGUI!.GRID_STYLE_CHECKED)
			endif
			gridOps!.setCellText(wk / gridOps!.getNumColumns(), 0, "")
		next wk

		gridOps!.resort()
	else
		gridOps!.clearMainGrid()
		gridOps!.setColumnStyle(0, SysGUI!.GRID_STYLE_UNCHECKED)
		gridOps!.setNumRows(0)
	endif

	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
create_reports_vector: rem --- Create a vector from the file to fill the grid
rem	current_opcode$ - input
rem ==========================================================================

	more=1
	opcode_dev=callpoint!.getDevObject("opcode_dev")
	opcode_tpl$=callpoint!.getDevObject("opcode_tpl")
	read (opcode_dev,key=firm_id$,dom=*next)
	rows=0

	while more
		dim opcode$:opcode_tpl$
		read record (opcode_dev, end=*break) opcode$
		if pos(firm_id$=opcode$)<>1 then break
		if opcode.op_code$=current_opcode$ continue

	rem --- Now fill vector

		vectOps!.addItem(""); rem 0
		vectOps!.addItem(opcode.op_code$); rem 1
		vectOps!.addItem(opcode.code_desc$); rem 2

		rows=rows+1
	wend

	callpoint!.setStatus("REFRESH")
	
	return

rem ==========================================================================
switch_value: rem --- Switch Check Values
rem ==========================================================================

	SysGUI!.setRepaintEnabled(0)

	gridOps!       = UserObj!.getItem(num(user_tpl.gridOpsOfst$))
	vectOps!       = UserObj!.getItem(num(user_tpl.vectOpsOfst$))

	TempRows! = gridOps!.getSelectedRows()
	numcols   = gridOps!.getNumColumns()

	if TempRows!.size() > 0 then
		for curr_row=1 to TempRows!.size()
			row_no = num(TempRows!.getItem(curr_row-1))

		rem --- Not checked -> checked

			if gridOps!.getCellState(row_no,0) = 0 then 
				gridOps!.setCellState(row_no,0,1)
				vectOps!.setItem(row_no * numcols, "Y")
		rem --- Checked -> not checked
			else
				rem --- re-initialize
				gridOps!.setCellState(row_no,0,0)
				vectOps!.setItem(row_no * numcols, "")
			endif
		next curr_row
	endif

	SysGUI!.setRepaintEnabled(1)

	return

rem ========================================================
get_first_last:
rem - current_opcode$	(in)
rem ========================================================

	cal_dev=fnget_dev("SFM_OPCALNDR")
	dim cal$:fnget_tpl$("SFM_OPCALNDR")

	first_date$="        "

	read (cal_dev,key=firm_id$+current_opcode$,dom=*next)
	while 1
		read record (cal_dev,end=*break) cal$
		if pos(firm_id$+current_opcode$=cal$)<>1 break
		first_day$="01"
		for x=1 to cal.days_in_mth
			if nfield(cal$,"hrs_per_day_"+str(x:"00"))>=0
				first_day$=str(x:"00")
				break
			endif
		next x
		first_date$=cal.year$+cal.month$+first_day$
		callpoint!.setColumnData("SFM_CAL_COPY.FIRST_SCHED_DT",first_date$)
		break
	wend

	last_date$="        "
	read (cal_dev,key=firm_id$+current_opcode$,dom=*next)
	while 1
		read record (cal_dev,end=*break) cal$
		if pos(firm_id$+current_opcode$=cal$)<>1 break
		last_day$=str(cal.days_in_mth:"00")
		for x=cal.days_in_mth to 1 step -1
			if nfield(cal$,"hrs_per_day_"+str(x:"00"))>=0 
				last_day$=str(x:"00")
				break
			endif
		next x
		last_date$=cal.year$+cal.month$+last_day$
	wend
	callpoint!.setColumnData("SFM_CAL_COPY.LAST_SCHED_DT",last_date$)

	return

#include std_missing_params.src
[[SFM_CAL_COPY.BFMC]]
rem --- See if BOM is being used

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFS_PARAMS",open_opts$[1]="OTA"
	gosub open_tables

	sfs_params=num(open_chans$[1])
	dim sfs_params$:open_tpls$[1]

	read record(sfs_params,key=firm_id$+"SF00",dom=std_missing_params) sfs_params$

	if sfs_params.bm_interface$<>"Y"
		callpoint!.setTableColumnAttribute("SFM_CAL_CREATE.OP_CODE","DTAB","SFC_OPRTNCOD")
	endif

	callpoint!.setDevObject("bm_interface",sfs_params.bm_interface$)
