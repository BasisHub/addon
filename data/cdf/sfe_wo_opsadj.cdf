[[SFE_WO_OPSADJ.AFMC]]
rem --- set preset val for batch_no

	callpoint!.setTableColumnAttribute("SFE_WO_OPSADJ.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[SFE_WO_OPSADJ.BEND]]
rem --- Ask user if they really want to exit

	vectOps! = UserObj!.getItem(num(user_tpl.vectOpsOfst$))
	vectOrig! = UserObj!.getItem(num(user_tpl.vectOrigOfst$))

	if vectOrig! <> vectOps!
		msg_id$="SAVE_CHANGES"
		gosub disp_message
		if msg_opt$="C"
			callpoint!.setStatus("ABORT")
			break
		endif
		if msg_opt$="Y"
			gosub save_changes
			break
		endif
	endif
[[SFE_WO_OPSADJ.ARAR]]
rem --- Display Work Order Number

	wo_no$=callpoint!.getDevObject("wo_no")
	callpoint!.setColumnData("SFE_WO_OPSADJ.WO_NO",wo_no$,1)
[[SFE_WO_OPSADJ.ASVA]]
rem --- Now write the Adjustment Entry records out

	gosub save_changes
[[SFE_WO_OPSADJ.ASIZ]]
rem --- Resize the grid

	if UserObj!<>null() then
		gridOps!=UserObj!.getItem(num(user_tpl.gridOpsOfst$))
		gridOps!.setSize(Form!.getWidth()-(gridOps!.getX()*2),Form!.getHeight()-(gridOps!.getY()+10))
		gridOps!.setFitToGrid(0)
	endif
[[SFE_WO_OPSADJ.ACUS]]
rem Event template:
rem CONTEXT:I(2),CODE:U(1),ID:U(2),FLAGS:U(1),X:U(2),Y:U(2)
rem Generic template:
rem CONTEXT:U(2),CODE:U(1),ID:U(2),OBJTYPE:I(2)
rem Notice template:
rem CONTEXT:U(2),CODE:U(1),ID:U(2),OBJTYPE:I(2),MSG:I(4),WPARAM:I(4),LPARAM:I(4),COL:I(4),ROW:I(4),TEXTCOLOR:C(3),BACKCOLOR:C(3),ALIGNMENT:U(1),STYLE:I(4),IMGIDX:I(4),X:I(2),Y:I(2),W:U(2),H:U(2),PTX:I(2),PTY:I(2),BUF:C(1*)

goto no_debug;rem jpb

dim event$:tmpl(gui_dev),generic$:noticetpl(0,0)
event$=sysgui!.getLastEventString()
print 'show',
: "event context="+str(event.context),
: " code="+str(event.code)+"(s/b n)",
: " id="+str(event.id),
: " flags="+str(event.flags)+"(s/b 12)",
: " x="+str(event.x),
: " y="+str(event.y)
 
rem control id 5000 is what was used for the custom grid, so change it as necessary in the following line
if event.code$="N"  then
      generic$=notice(gui_dev,event.x)
      dim notice$:noticetpl(generic.objtype,event.flags)
      notice$=generic$
      if event.flags=12 or event.flags=6 then
            print "GridKeypress: $"+hta(notice.wparam$)+"$: ",
            keycode=notice.wparam
            gosub keycode
      endif
endif
no_debug:
rem --- above is for testing

rem --- Process custom event
rem --- Select/de-select checkboxes in grid and edit payment and discount amounts

rem This routine is executed when callbacks have been set to run a 'custom event'.
rem Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind of event it is.
rem See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info.

rem print 'show'
rem open (unt)"X0"
s!=bbjAPI().getSysGui()
e!=s!.getLastEvent()

rem escape;rem ? e!.getKeyCode() and e!.isControlDown()
rem	if last_event!.getKeyCode()=6 and last_event!.isControlDown() = true escape


	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ctl_ID=dec(gui_event.ID$)

	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
	endif

	gridOps! = UserObj!.getItem(num(user_tpl.gridOpsOfst$))
	numcols = gridOps!.getNumColumns()
	vectOps! = UserObj!.getItem(num(user_tpl.vectOpsOfst$))
	vectOpsMaster! = UserObj!.getItem(num(user_tpl.vectOpsMasterOfst$))
	curr_row = dec(notice.row$);rem 0 based
	curr_col = dec(notice.col$);rem 0 based
	grid_ctx=gridOps!.getContextID()

rem if curr_col=17 escape; rem print e!.getKeyCode()
rem escape;rem ? e!.getKeyCode() and e!.isControlDown()
rem	if last_event!.getKeyCode()=6 and last_event!.isControlDown() = true escape

	switch notice.code

		case 32; rem grid cell validation
rem --- New Work Order Number

			if curr_col=17
				wo_no$=notice.buf$
				wo_no$=str(num(wo_no$):callpoint!.getDevObject("wo_no_mask"))
				sfe_womast=fnget_dev("SFE_WOMASTR")
				dim sfe_womast$:fnget_tpl$("SFE_WOMASTR")
				if num(wo_no$)<>0
					found=0
					while 1
						read record (sfe_womast,key=firm_id$+sfe_womast.wo_location$+wo_no$,dom=*break) sfe_womast$
						found=1
						break
					wend
					if found=0
						gridOps!.setCellText(curr_row,17,"")
						msg_id$="INPUT_ERR_DATA"
						gosub disp_message
						gridOps!.focus()
						sysgui!.setContext(grid_ctx)
						gridOps!.accept(0)
						gridOps!.startEdit(curr_row,curr_col)
						break
					endif
					if sfe_womast.wo_status$="C"
						gridOps!.setCellText(curr_row,17,"")
						msg_id$="WO_CLOSED"
						gosub disp_message
						gridOps!.focus()
						sysgui!.setContext(grid_ctx)
						gridOps!.accept(0)
						gridOps!.startEdit(curr_row,curr_col)
						break
					endif
				else
					wo_no$=callpoint!.getDevObject("wo_no")
				endif

				vectOps!.setItem((curr_row*num(user_tpl.gridOpsCols$))+17,wo_no$)
				gridOps!.accept(1)
				gridOps!.setCellText(curr_row,17,wo_no$)
				break
			endif

rem --- Rates or Units

			if curr_col = 6 or curr_col=8  or curr_col=10 or curr_col=12 then
				if curr_col=6
					dir=num(notice.buf$)
					ohd=num(gridOps!.getCellText(curr_row,8))
					setup=num(gridOps!.getCellText(curr_row,10))
					units=num(gridOps!.getCellText(curr_row,12))
				endif
				if curr_col=8
					dir=num(gridOps!.getCellText(curr_row,6))
					ohd=num(notice.buf$)
					setup=num(gridOps!.getCellText(curr_row,10))
					units=num(gridOps!.getCellText(curr_row,12))
				endif
				if curr_col=10
					dir=num(gridOps!.getCellText(curr_row,6))
					ohd=num(gridOps!.getCellText(curr_row,8))
					setup=num(notice.buf$)
					units=num(gridOps!.getCellText(curr_row,12))
				endif
				if curr_col=12
					dir=num(gridOps!.getCellText(curr_row,6))
					ohd=num(gridOps!.getCellText(curr_row,8))
					setup=num(gridOps!.getCellText(curr_row,10))
					units=num(notice.buf$)
				endif
				tot_ext=(units+setup)*(dir+ohd)
				gridOps!.setCellText(curr_row,14,str(tot_ext))
				vectOps!.setItem((curr_row*num(user_tpl.gridOpsCols$))+6,str(dir))
				vectOps!.setItem((curr_row*num(user_tpl.gridOpsCols$))+8,str(ohd))
				vectOps!.setItem((curr_row*num(user_tpl.gridOpsCols$))+10,str(setup))
				vectOps!.setItem((curr_row*num(user_tpl.gridOpsCols$))+12,str(units))
				gridOps!.accept(1)
				break
			endif

rem --- New Qty Complete
			if curr_col=16
				vectOps!.setItem((curr_row*num(user_tpl.gridOpsCols$))+16,notice.buf$)
				gridOps!.accept(1)
				break
			endif

rem --- New Tran Date
			if curr_col=18
				tran_date$=notice.buf$
				input_value$=tran_date$
				gosub validate_date
				if len(msg_id$)>0
					dim msg_tokens$[1]
					msg_tokens$[1]=Translate!.getTranslation("AON_ADJUST")+" "+Translate!.getTranslation("AON_DATE")
					gosub disp_message
					gridOps!.focus()
					sysgui!.setContext(grid_ctx)
					gridOps!.accept(0)
					gridOps!.startEdit(curr_row,curr_col)
					break
				endif
				tran_date$=temp_date$
				if len(cvs(tran_date$,2))=0
					tran_date$=gridOps!.getCellText(curr_row,0)
					input_value$=vectOps!.getItem((curr_row*num(user_tpl.gridOpsCols$)))
				endif
				vectOps!.setItem((curr_row*num(user_tpl.gridOpsCols$))+18,fndate$(input_value$))
				gridOps!.setCellText(curr_row,curr_col,fndate$(input_value$))
			endif
			gridOps!.accept(1)
			break

		case 19; rem row change

			if vectOps!.size()=0 break
			gosub switch_colors
			break

		case 6;rem "Special Key"
			if notice.wparam=8
				gridOps!.endEdit()
			endif
			break

		case 12; rem Lookup
			if curr_col=17
rem				escape;rem ? notice.wparam
			endif
			break
		case 1; rem Lookup
			if curr_col=17
rem				escape;rem ? notice.wparam
			endif
			break

		case 14; rem --- grid_mouse_up
			if notice.col=0 gosub switch_value
			break

	swend

	UserObj!.setItem(num(user_tpl.vectOpsOfst$),vectOps!)
	UserObj!.setItem(num(user_tpl.vectOpsMasterOfst$),vectOpsMaster!)
[[SFE_WO_OPSADJ.AWIN]]
rem --- Open/Lock files

	use ::ado_util.src::util
	use ::ado_func.src::func

	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="SFT_OPNOPRTR",open_opts$[1]="OTA"
rem	open_tables$[2]="APM_VENDMAST",open_opts$[2]="OTA"
	open_tables$[3]="SFS_PARAMS",open_opts$[3]="OTA"
	open_tables$[4]="SFE_WOOPRADJ",open_opts$[4]="OTA"
	open_tables$[5]="SFE_WOMASTR",open_opts$[5]="OTA"

	gosub open_tables

	sft01_dev=num(open_chans$[1]),sft01_tpl$=open_tpls$[1]
rem	apm01_dev=num(open_chans$[2]),apm01_tpl$=open_tpls$[2]
	sfs_params=num(open_chans$[3]),sfs_params_tpl$=open_tpls$[3]

rem --- Dimension string templates

	dim sft01a$:sft01_tpl$
rem	dim apm01a$:apm01_tpl$
	dim sfs_params$:sfs_params_tpl$

rem --- Get parameter record

	readrecord(sfs_params,key=firm_id$+"SF00")sfs_params$

rem --- Add grid to store Operations, with checkboxes for user to select one or more

	user_tpl_str$ = "gridOpsOfst:c(5), " +
:		"gridOpsCols:c(5), " +
:		"gridOpsRows:c(5), " +
:		"gridOpsCtlID:c(5)," +
:		"vectOpsOfst:c(5), " +
:		"vectOpsMasterOfst:c(5), " +
:		"vectOrigOfst:c(5)"

	dim user_tpl$:user_tpl_str$

	UserObj! = BBjAPI().makeVector()
	vectOps! = BBjAPI().makeVector()
	vectOrig!= BBjAPI().makeVector()
	vectOpsMaster! = BBjAPI().makeVector()
	nxt_ctlID = util.getNextControlID()

	gridOps! = Form!.addGrid(nxt_ctlID,5,60,1500,250); rem --- ID, x, y, width, height, flags
	gridOps!.setHorizontalScrollBarAlways(1)

	user_tpl.gridOpsCtlID$ = str(nxt_ctlID)
	user_tpl.gridOpsCols$ = "19"
	user_tpl.gridOpsRows$ = "10"
	callpoint!.setDevObject("wo_no_len",len(sft01a.wo_no$))
	callpoint!.setDevObject("wo_no_mask",fill(len(sft01a.wo_no$),"0"))

	gosub format_grid
	util.resizeWindow(Form!, SysGui!)

	UserObj!.addItem(gridOps!)
	user_tpl.gridOpsOfst$="0"

	UserObj!.addItem(vectOps!); rem --- vector of Open Ops
	user_tpl.vectOpsOfst$="1"

	UserObj!.addItem(vectOpsMaster!); rem --- vector of Master Open Ops
	user_tpl.vectOpsMasterOfst$="2"

	UserObj!.addItem(vectOrig!); rem --- vector of original displayed vector
	user_tpl.vectOrigOfst$="3"

rem --- Misc other init

	call stbl("+DIR_SYP")+"bac_create_color.bbj","+ENTRY_ERROR_COLOR","255,224,224",diff_color!,""
	same_color!=SysGUI!.makeColor(7)
	callpoint!.setDevObject("diff_color",diff_color!)
	callpoint!.setDevObject("same_color",same_color!)
	gridOps!.setColumnEditable(0,1)
	gridOps!.setColumnEditable(6,1)
	gridOps!.setColumnEditable(8,1)
	gridOps!.setColumnEditable(10,1)
	gridOps!.setColumnEditable(12,1)
	gridOps!.setColumnEditable(16,1)
	gridOps!.setColumnEditable(17,1)
	gridOps!.setColumnEditable(18,1)
	gridOps!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)
	gridOps!.setTabAction(gridOps!.GRID_NAVIGATE_GRID)
	gridOps!.setTabActionSkipsNonEditableCells(1)
	gridOps!.setEnterAsTab(1)

	gosub create_reports_vector
	gosub fill_grid

rem --- Set callbacks - processed in ACUS callpoint

	gridOps!.setCallback(gridOps!.ON_GRID_CELL_VALIDATION,"custom_event")
	gridOps!.setCallback(gridOps!.ON_GRID_SELECT_ROW,"custom_event")
	gridOps!.setCallback(gridOps!.ON_GRID_SPECIAL_KEY,"custom_event")
	gridOps!.setCallback(gridOps!.ON_GRID_KEYPRESS,"custom_event")
	gridOps!.setCallback(gridOps!.ON_GRID_MOUSE_UP,"custom_event")
	gridOps!.setCallback(gridOps!.ON_GRID_MOUSE_DOWN,"custom_event")
[[SFE_WO_OPSADJ.<CUSTOM>]]
rem ==========================================================================
format_grid: rem --- Use Barista program to format the grid
rem ==========================================================================

	call stbl("+DIR_PGM")+"adc_getmask.aon","","SF","A","",m1$,0,0

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0] = callpoint!.getColumnAttributeTypes()
	def_ops_cols = num(user_tpl.gridOpsCols$)
	num_rpts_rows = num(user_tpl.gridOpsRows$)
	dim attr_ops_col$[def_ops_cols,len(attr_def_col_str$[0,0])/5]

	attr_ops_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SELECT"
	attr_ops_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=""
	attr_ops_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"
	attr_ops_col$[1,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="1"
	attr_ops_col$[1,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="C"

	attr_ops_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ORIG_TRANS_DATE"
	attr_ops_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_TRANSACTION_DATE")
	attr_ops_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	attr_ops_col$[2,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="D"
	attr_ops_col$[2,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	attr_ops_col$[2,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=stbl("+DATE_MASK")
	attr_ops_col$[2,fnstr_pos("MSKI",attr_def_col_str$[0,0],5)]=stbl("+DATE_MASK")

	attr_ops_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="EMP_ID"
	attr_ops_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_EMPLOYEE")
	attr_ops_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"

	attr_ops_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="EMP_NAME"
	attr_ops_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_NAME")
	attr_ops_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="180"

	attr_ops_col$[5,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="OP_CODE"
	attr_ops_col$[5,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_OP_CODE")
	attr_ops_col$[5,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="75"

	attr_ops_col$[6,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ORIG_DIRECT"
	attr_ops_col$[6,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ORIG")+" "+Translate!.getTranslation("AON_DIRECT")
	attr_ops_col$[6,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_ops_col$[6,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_ops_col$[6,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_ops_col$[7,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="NEW_DIRECT"
	attr_ops_col$[7,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ADJUST")+" "+Translate!.getTranslation("AON_DIRECT")
	attr_ops_col$[7,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_ops_col$[7,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_ops_col$[7,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_ops_col$[8,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ORIG_OVHD"
	attr_ops_col$[8,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ORIG")+" "+Translate!.getTranslation("AON_OVHD")
	attr_ops_col$[8,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_ops_col$[8,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_ops_col$[8,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_ops_col$[9,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="NEW_OVHD"
	attr_ops_col$[9,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ADJUST")+" "+Translate!.getTranslation("AON_OVHD")
	attr_ops_col$[9,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_ops_col$[9,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_ops_col$[9,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_ops_col$[10,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ORIG_SETUP"
	attr_ops_col$[10,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ORIG")+" "+Translate!.getTranslation("AON_SETUP")
	attr_ops_col$[10,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_ops_col$[10,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_ops_col$[10,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_ops_col$[11,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="NEW_SETUP"
	attr_ops_col$[11,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ADJUST")+" "+Translate!.getTranslation("AON_SETUP")
	attr_ops_col$[11,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_ops_col$[11,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_ops_col$[11,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_ops_col$[12,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ORIG_UNITS"
	attr_ops_col$[12,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ORIG")+" "+Translate!.getTranslation("AON_UNITS")
	attr_ops_col$[12,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_ops_col$[12,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_ops_col$[12,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_ops_col$[13,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="NEW_UNITS"
	attr_ops_col$[13,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ADJUST")+" "+Translate!.getTranslation("AON_UNITS")
	attr_ops_col$[13,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_ops_col$[13,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_ops_col$[13,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_ops_col$[14,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ORIG_EXT"
	attr_ops_col$[14,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ORIG")+" "+Translate!.getTranslation("AON_TOTAL")
	attr_ops_col$[14,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_ops_col$[14,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_ops_col$[14,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_ops_col$[15,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="NEW_EXT"
	attr_ops_col$[15,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ADJUST")+" "+Translate!.getTranslation("AON_TOTAL")
	attr_ops_col$[15,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_ops_col$[15,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_ops_col$[15,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_ops_col$[16,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ORIG_COMPLETE"
	attr_ops_col$[16,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ORIG")+" "+Translate!.getTranslation("AON_COMPLETE")
	attr_ops_col$[16,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_ops_col$[16,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_ops_col$[16,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_ops_col$[17,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="NEW_COMPLETE"
	attr_ops_col$[17,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ADJUST")+" "+Translate!.getTranslation("AON_COMPLETE")
	attr_ops_col$[17,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_ops_col$[17,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_ops_col$[17,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_ops_col$[18,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="NEW_WO"
	attr_ops_col$[18,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ADJUST")+" "+Translate!.getTranslation("AON_WO")
	attr_ops_col$[18,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"
	attr_ops_col$[18,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_ops_col$[18,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=callpoint!.getDevObject("wo_no_mask")
	attr_ops_col$[18,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]=str(callpoint!.getDevObject("wo_no_len"))
rem	attr_ops_col$[18,fnstr_pos("DTAB",attr_def_col_str$[0,0],5)]="SFE_WOMASTR"
	attr_ops_col$[18,fnstr_pos("DCOL",attr_def_col_str$[0,0],5)]="DESC"

	attr_ops_col$[19,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="NEW_DATE"
	attr_ops_col$[19,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ADJUST")+" "+Translate!.getTranslation("AON_DATE")
	attr_ops_col$[19,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_ops_col$[19,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="D"
	attr_ops_col$[19,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"
	attr_ops_col$[19,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	attr_ops_col$[19,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=stbl("+DATE_MASK",err=*next)

	for curr_attr=1 to def_ops_cols
		attr_ops_col$[0,1] = attr_ops_col$[0,1] + 
:			pad("SFE_WO_OPSADJ." + attr_ops_col$[curr_attr, fnstr_pos("DVAR", attr_def_col_str$[0,0], 5)], 40)
	next curr_attr

	attr_disp_col$=attr_ops_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridOps!,"CHECKS-COLH-DATES-LIGHT-LINES-SIZEC",num_rpts_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_ops_col$[all]

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
		gridOps!.setNumRows(numrow)
		gridOps!.setCellText(0,0,vectOps!)

		gosub switch_colors
	else
		gridOps!.clearMainGrid()
		gridOps!.setNumRows(0)
	endif

	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
create_reports_vector: rem --- Create a vector from the file to fill the grid
rem ==========================================================================

	sfe_opsadj=fnget_dev("SFE_WOOPRADJ")
	if callpoint!.getDevObject("pr")="Y"
		empmast_dev=fnget_dev("PRM_EMPLMAST")
		dim empmast$:fnget_tpl$("PRM_EMPLMAST")
		call stbl("+DIR_PGM")+"adc_getmask.aon","","PR","I","",emp_mask$,0,emp_len
	else
		empmast_dev=fnget_dev("SFM_EMPLMAST")
		dim empmast$:fnget_tpl$("SFM_EMPLMAST")
		call stbl("+DIR_PGM")+"adc_getmask.aon","","SF","I","",emp_mask$,0,emp_len
	endif
	more=1
	wo_loc$=callpoint!.getDevObject("wo_loc")
	wo_no$=callpoint!.getDevObject("wo_no")
	read (sft01_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)

	while more
		read record (sft01_dev, end=*break) sft01a$
		if pos(firm_id$=sft01a$)<>1 then break
		if wo_no$<>sft01a.wo_no$ break
		dim empmast$:fattr(empmast$)
		read record(empmast_dev, key=firm_id$+sft01a.employee_no$, dom=*next) empmast$
		dim sfe_opsadj$:fnget_tpl$("SFE_WOOPRADJ")
		found=0
		while 1
			read record (sfe_opsadj,key=firm_id$+wo_loc$+wo_no$+sft01a.trans_date$+sft01a.trans_seq$,dom=*break)sfe_opsadj$
			found=1
			break
		wend

	rem --- Now fill vectors

		vectOps!.addItem(""); rem 0
		vectOps!.addItem(fndate$(sft01a.trans_date$)); rem 1
		vectOps!.addItem(func.alphaMask(sft01a.employee_no$(1,emp_len),emp_mask$)); rem 2
		vectOps!.addItem(cvs(empmast.empl_surname$,2)+", "+cvs(empmast.empl_givname$,2)); rem 3
		vectOps!.addItem(sft01a.op_code$); rem 4
		vectOps!.addItem(str(sft01a.direct_rate)); rem 5
		if found=1
			vectOps!.addItem(str(sfe_opsadj.new_dir_rate)); rem 6
		else
			vectOps!.addItem(str(sft01a.direct_rate)); rem 6
		endif
		vectOps!.addItem(str(sft01a.ovhd_rate)); rem 7
		if found=1
			vectOps!.addItem(str(sfe_opsadj.new_ovr_rate)); rem 8
		else
			vectOps!.addItem(str(sft01a.ovhd_rate)); rem 8
		endif
		vectOps!.addItem(str(sft01a.setup_time)); rem 9
		if found=1
			vectOps!.addItem(str(sfe_opsadj.new_set_hrs)); rem 10
		else
			vectOps!.addItem(str(sft01a.setup_time)); rem 10
		endif
		vectOps!.addItem(str(sft01a.units)); rem 11
		if found=1
			vectOps!.addItem(str(sfe_opsadj.new_units)); rem 12
		else
			vectOps!.addItem(str(sft01a.units)); rem 12
		endif
		vectOps!.addItem(str(sft01a.ext_cost)); rem 13
		if found=1
			vectOps!.addItem(str((sfe_opsadj.new_set_hrs+sfe_opsadj.new_units)*(sfe_opsadj.new_dir_rate+sfe_opsadj.new_ovr_rate))); rem 14
		else
			vectOps!.addItem(str(sft01a.ext_cost)); rem 14
		endif
		vectOps!.addItem(str(sft01a.complete_qty)); rem 15
		if found=1
			vectOps!.addItem(str(sfe_opsadj.new_qty_comp)); rem 16
			vectOps!.addItem(sfe_opsadj.new_wo_no$); rem 17
			vectOps!.addItem(fndate$(sfe_opsadj.new_trn_date$)); rem 18
		else
			vectOps!.addItem(str(sft01a.complete_qty)); rem 16
			vectOps!.addItem(wo_no$); rem 17
			vectOps!.addItem(fndate$(sft01a.trans_date$)); rem 18
		endif

		vectOpsMaster!.addItem(sft01a.trans_seq$);rem keep track of sequence

	wend

	vectOrig! = vectOps!.clone()
	UserObj!.setItem(num(user_tpl.vectOrigOfst$),vectOrig!)

	callpoint!.setStatus("REFRESH")
	
	return

rem ==========================================================
validate_date:rem --- YYYYMMDD
rem input_value$: input and output (anything in, ccyymmdd out)
rem msg_id$: output (blank if valid date, INPUT_ERR_DATE if invalid)
rem temp_date$: output (mm/dd/ccyy)
rem ==========================================================

	if cvs(input_value$,2)="" return
	if num(input_value$,err=*next)<=0 input_value$=""; return 

	date_value$="",temp_date$="",input_value_sav$=input_value$
	date_mask$=stbl("+DATE_MASK")
	msg_id$="INPUT_ERR_DATE"

rem --- expand entered value as needed and do validity check based on JUL() function
	if len(input_value$)<>7 or input_value$<"2000000" or input_value$>"2999999"
		date_value$=str(jul(input_value$,date_mask$,err=*next))
	else
		date_value$=input_value$
	endif

	if date_value$="" or date_value$="-1"
		input_value$=input_value_sav$
		return
	endif

rem --- re-display extended, validated value in localized format, store "on disk" format in input var
	temp_date$=date(num(date_value$),date_mask$)
	if rdEventCtl!<>null() rdEventCtl!.setText(temp_date$)
	input_value$=date(num(date_value$):"%Yd%Mz%Dz")

	msg_id$=""

	return

rem ===============================================================
switch_colors:
rem ===============================================================

rem --- Now switch colors on all rows
	if vectOps!.size()=0 break
	cols=num(user_tpl.gridOpsCols$)
	for row=1 to vectOps!.size()-1 step cols
		change$="N"
		if num(vectOps!.getItem(((row-1)/cols)*cols+5))<>num(vectOps!.getItem(((row-1)/cols)*cols+6))
			gridOps!.setCellBackColor((row-1)/cols,6,callpoint!.getDevObject("diff_color"))
			change$="Y"
		else
			gridOps!.setCellBackColor((row-1)/cols,6,callpoint!.getDevObject("same_color"))
		endif
		if num(vectOps!.getItem(((row-1)/cols)*cols+7))<>num(vectOps!.getItem(((row-1)/cols)*cols+8))
			gridOps!.setCellBackColor((row-1)/cols,8,callpoint!.getDevObject("diff_color"))
			change$="Y"
		else
			gridOps!.setCellBackColor((row-1)/cols,8,callpoint!.getDevObject("same_color"))
		endif
		if num(vectOps!.getItem(((row-1)/cols)*cols+9))<>num(vectOps!.getItem(((row-1)/cols)*cols+10))
			gridOps!.setCellBackColor((row-1)/cols,10,callpoint!.getDevObject("diff_color"))
			change$="Y"
		else
			gridOps!.setCellBackColor((row-1)/cols,10,callpoint!.getDevObject("same_color"))
		endif	
		if num(vectOps!.getItem(((row-1)/cols)*cols+11))<>num(vectOps!.getItem(((row-1)/cols)*cols+12))
			gridOps!.setCellBackColor((row-1)/cols,12,callpoint!.getDevObject("diff_color"))
			change$="Y"
		else
			gridOps!.setCellBackColor((row-1)/cols,12,callpoint!.getDevObject("same_color"))
		endif
		if num(vectOps!.getItem(((row-1)/cols)*cols+15))<>num(vectOps!.getItem(((row-1)/cols)*cols+16))
			gridOps!.setCellBackColor((row-1)/cols,16,callpoint!.getDevObject("diff_color"))
			change$="Y"
		else
			gridOps!.setCellBackColor((row-1)/cols,16,callpoint!.getDevObject("same_color"))
		endif
		if vectOps!.getItem(((row-1)/cols)*cols+17)<>callpoint!.getDevObject("wo_no")
			gridOps!.setCellBackColor((row-1)/cols,17,callpoint!.getDevObject("diff_color"))
			change$="Y"
		else
			gridOps!.setCellBackColor((row-1)/cols,17,callpoint!.getDevObject("same_color"))
		endif
		if vectOps!.getItem(((row-1)/cols)*cols+18)<>vectOps!.getItem(((row-1)/cols)*cols+1)
			gridOps!.setCellBackColor((row-1)/cols,18,callpoint!.getDevObject("diff_color"))
			change$="Y"
		else
			gridOps!.setCellBackColor((row-1)/cols,18,callpoint!.getDevObject("same_color"))
		endif
		if change$="Y"
			gridOps!.setCellStyle((row-1)/cols, 0, SysGUI!.GRID_STYLE_CHECKED)
		else
			gridOps!.setCellStyle((row-1)/cols, 0, SysGUI!.GRID_STYLE_UNCHECKED)
		endif
	next row

	return

rem ==========================================================================
switch_value: rem --- Switch Check Values
rem ==========================================================================

	SysGUI!.setRepaintEnabled(0)

rem	gridOps!       = UserObj!.getItem(num(user_tpl.gridOps$))
rem	vectOps!       = UserObj!.getItem(num(user_tpl.vectOpsOfst$))

	TempRows! = gridOps!.getSelectedRows()
	numcols   = gridOps!.getNumColumns()

	if TempRows!.size() > 0 then
		for curr_row=1 to TempRows!.size()
			row_no = num(TempRows!.getItem(curr_row-1))

			if gridOps!.getCellState(row_no,0) = 0 then
		rem --- not checked - leave alone

				gridOps!.setCellState(row_no, 0, 0)

			else
		rem --- Checked -> not checked

				orig_dir$ = gridOps!.getCellText(row_no,5)
				orig_ovh$=gridOps!.getCellText(row_no,7)
				orig_setup$=gridOps!.getCellText(row_no,9)
				orig_units$=gridOps!.getCellText(row_no,11)
				orig_ext$=gridOps!.getCellText(row_no,13)
				orig_comp$=gridOps!.getCellText(row_no,15)
				orig_wo$=callpoint!.getDevObject("wo_no")
				orig_date$=gridOps!.getCellText(row_no,1)

				gridOps!.setCellState(row_no,0,0)
				gridOps!.setCellText(row_no, 6, orig_dir$)
				gridOps!.setCellText(row_no,8,orig_ovh$)
				gridOps!.setCellText(row_no,10,orig_setup$)
				gridOps!.setCellText(row_no,12,orig_units$)
				gridOps!.setCellText(row_no,14,orig_ext$)
				gridOps!.setCellText(row_no,16,orig_comp$)
				gridOps!.setCellText(row_no,17,orig_wo$)
				gridOps!.setCellText(row_no,18,orig_date$)

				gridOps!.setCellBackColor(rowno,6,callpoint!.getDevObject("same_color"))
				gridOps!.setCellBackColor(rowno,8,callpoint!.getDevObject("same_color"))
				gridOps!.setCellBackColor(rowno,10,callpoint!.getDevObject("same_color"))
				gridOps!.setCellBackColor(rowno,12,callpoint!.getDevObject("same_color"))
				gridOps!.setCellBackColor(rowno,14,callpoint!.getDevObject("same_color"))
				gridOps!.setCellBackColor(rowno,16,callpoint!.getDevObject("same_color"))
				gridOps!.setCellBackColor(rowno,17,callpoint!.getDevObject("same_color"))
				gridOps!.setCellBackColor(rowno,18,callpoint!.getDevObject("same_color"))

				vectOps!.setItem((row_no*numcols)+6,orig_dir$)
				vectOps!.setItem((row_no*numcols)+8,orig_ovh$)
				vectOps!.setItem((row_no*numcols)+10,orig_setup$)
				vectOps!.setItem((row_no*numcols)+12,orig_units$)
				vectOps!.setItem((row_no*numcols)+14,orig_ext$)
				vectOps!.setItem((row_no*numcols)+16,orig_comp$)
				vectOps!.setItem((row_no*numcols)+17,orig_wo$)
				vectOps!.setItem((row_no*numcols)+18,orig_date$)

			endif
		next curr_row
	endif

	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
save_changes:
rem ==========================================================================

rem --- Now write the Adjustment Entry records out

	vectOps! = UserObj!.getItem(num(user_tpl.vectOpsOfst$))
	vectOpsMaster! = UserObj!.getItem(num(user_tpl.vectOpsMasterOfst$))

	sfe_opsadj=fnget_dev("SFE_WOOPRADJ")
	dim sfe_opsadj$:fnget_tpl$("SFE_WOOPRADJ")

	cols=num(user_tpl.gridOpsCols$)
	mast=0
	wo_no$=callpoint!.getDevObject("wo_no")
	wo_loc$=callpoint!.getDevObject("wo_loc")

	if vectOps!.size()
		for x=0 to vectOps!.size()-1 step cols
			tran_date$=vectOps!.getItem(x+1)
			if len(cvs(tran_date$,2))=10
				tran_date$=tran_date$(7,4)+tran_date$(1,2)+tran_date$(4,2)
			endif
			tran_seq$=vectOpsMaster!.getItem(mast)
			old_dir_rate=num(vectOps!.getItem(x+5))
			new_dir_rate=num(vectOps!.getItem(x+6))
			old_ovr_rate=num(vectOps!.getItem(x+7))
			new_ovr_rate=num(vectOps!.getItem(x+8))
			old_set_hrs=num(vectOps!.getItem(x+9))
			new_set_hrs=num(vectOps!.getItem(x+10))
			old_units=num(vectOps!.getItem(x+11))
			new_units=num(vectOps!.getItem(x+12))
			old_qty_comp=num(vectOps!.getItem(x+15))
			new_qty_comp=num(vectOps!.getItem(x+16))
			new_wo$=vectOps!.getItem(x+17)
			if cvs(new_wo$,2)="" new_wo$=wo_no$
			new_date$=vectOps!.getItem(x+18)
			if cvs(new_date$,2)="" new_date$=trans_date$
			if len(cvs(new_date$,2))=10
				new_date$=new_date$(7,4)+new_date$(1,2)+new_date$(4,2)
			endif
			if tran_date$<>new_date$ or
:			   old_dir_rate<>new_dir_rate or
:			   old_ovr_rate<>new_ovr_rate or
:			   old_set_hrs<>new_set_hrs or
:			   old_units<>new_units or
:			   old_qty_comp<>new_qty_comp or
:			   wo_no$<>new_wo$
rem --- Write entry Record
				sfe_opsadj.firm_id$=firm_id$
				sfe_opsadj.wo_location$=wo_loc$
				sfe_opsadj.wo_no$=wo_no$
				sfe_opsadj.trans_date$=tran_date$
				sfe_opsadj.trans_seq$=tran_seq$
				sfe_opsadj.new_wo_no$=new_wo$
				sfe_opsadj.new_trn_date$=new_date$
				sfe_opsadj.new_units=new_units
				sfe_opsadj.new_dir_rate=new_dir_rate
				sfe_opsadj.new_ovr_rate=new_ovr_rate
				sfe_opsadj.new_set_hrs=new_set_hrs
				sfe_opsadj.new_qty_comp=new_qty_comp
				sfe_opsadj.batch_no$=callpoint!.getColumnData("SFE_WO_OPSADJ.BATCH_NO")
				sfe_opsadj$=field(sfe_opsadj$)
				write record (sfe_opsadj) sfe_opsadj$
			else
rem --- Remove Entry Record
				remove (sfe_opsadj,key=firm_id$+wo_loc$+wo_no$+tran_date$+tran_seq$,dom=*next)
			endif
			mast=mast+1
		next x
	endif
 	return

rem --- below is for testing

keycode:
keycode$=bin(keycode,2)
if asc(and(keycode$,$1000$)) then print "SHIFT+",
if asc(and(keycode$,$2000$)) then 
      print "CTRL+",
      switch dec(keycode$)
          case dec($2000$); print "@ (NUL (null))"; break
          case dec($2001$); print "A (SOH (start of heading))"; break
          case dec($2002$); print "B (STX (start of text))"; break
          case dec($2003$); print "C (ETX (end of text))"; break
          case dec($2004$); print "D (EOT (end of transmission))"; break
          case dec($2005$); print "E (ENQ (enquiry))"; break
          case dec($2006$); print "F (ACK (acknowledge))"; break
          case dec($2007$); print "G (BEL (bell))"; break
          case dec($2008$); print "H (BS (backspace))"; break
          case dec($2009$); print "I (HT (horizontal tab))"; break
          case dec($200A$); print "J (LF (line feed))"; break
          case dec($200B$); print "K (VT (vertical tab))"; break
          case dec($200C$); print "L (FF (form feed))"; break
          case dec($200D$); print "M (CR (carriage return))"; break
          case dec($200E$); print "N (SO (shift out))"; break
          case dec($200F$); print "O (SI (shift in))"; break
          case dec($2010$); print "P (DLE (data link escape))"; break
          case dec($2011$); print "Q (DC1 (device control 1))"; break
          case dec($2012$); print "R (DC2 (device control 2))"; break
          case dec($2013$); print "S (DC3 (device control 3))"; break
          case dec($2014$); print "T (DC4 (device control 4))"; break
          case dec($2015$); print "U (NAK (negative acknowledge))"; break
          case dec($2016$); print "V (SYN (synchronous idle))"; break
          case dec($2017$); print "W (ETB (end of transmission block))"; break
          case dec($2018$); print "X (CAN (cancel))"; break
          case dec($2019$); print "Y (EM (end of medium))"; break
          case dec($201A$); print "Z (SUB (substitute))"; break
          case dec($201B$); print "[ (ESC (escape))"; break
          case dec($201C$); print "\ (FS (file separator))"; break
          case dec($201D$); print "] (GS (group separator))"; break
          case dec($201E$); print "^ (RS (record separator))"; break
          case dec($201F$); print "_ (US (unit separator))"; break
      swend
endif
if asc(and(keycode$,$4000$)) then print "ALT+",
if asc(and(keycode$,$8000$)) then print "CMD+",
switch dec(and(keycode$,$0fff$))
    case dec($0009$); print "Tab"; break
    case dec($001b$); print "Escape"; break
    case dec($007f$); print "Delete"; break
    case dec($012d$); print "Up arrow"; break
    case dec($012e$); print "Down arrow"; break
    case dec($012f$); print "Right arrow"; break
    case dec($0130$); print "Left arrow"; break
    case dec($0131$); print "Page up"; break
    case dec($0132$); print "Page down"; break
    case dec($0133$); print "Home"; break
    case dec($0134$); print "End"; break
    case dec($0135$); print "Ctrl-Home"; break
    case dec($0136$); print "Ctrl-End"; break
    case dec($0138$); print "Insert"; break
    case dec($0139$); print "Ctrl-Right arrow"; break
    case dec($013a$); print "Ctrl-Left arrow"; break
    case dec($013b$); print "Backtab"; break
    case dec($013e$); print "Keypad 0"; break
    case dec($013f$); print "Keypad 1"; break
    case dec($0140$); print "Keypad 2"; break
    case dec($0141$); print "Keypad 3"; break
    case dec($0142$); print "Keypad 4"; break
    case dec($0143$); print "Keypad 5"; break
    case dec($0144$); print "Keypad 6"; break
    case dec($0145$); print "Keypad 7"; break
    case dec($0146$); print "Keypad 8"; break
    case dec($0147$); print "Keypad 9"; break
    case dec($014b$); print "F1"; break
    case dec($014c$); print "F2"; break
    case dec($014d$); print "F3"; break
    case dec($014e$); print "F4"; break
    case dec($014f$); print "F5"; break
    case dec($0150$); print "F6"; break
    case dec($0151$); print "F7"; break
    case dec($0152$); print "F8"; break
    case dec($0153$); print "F9"; break
    case dec($0154$); print "F10"; break
    case dec($0155$); print "F11"; break
    case dec($0156$); print "F12"; break
    case dec($0174$); print "Keypad *"; break
    case dec($0175$); print "Keypad -"; break
    case dec($0176$); print "Keypad +"; break
    case dec($0177$); print "Keypad /"; break
    case dec($0006$); print "Ctl-F"; break
    case default; print and(keycode$,$0fff$); break
swend
return
