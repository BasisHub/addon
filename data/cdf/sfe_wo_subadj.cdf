[[SFE_WO_SUBADJ.AFMC]]
rem --- set preset val for batch_no

	callpoint!.setTableColumnAttribute("SFE_WO_SUBADJ.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[SFE_WO_SUBADJ.BEND]]
rem --- Ask user if they really want to exit

	vectSubs! = UserObj!.getItem(num(user_tpl.vectSubsOfst$))
	vectOrig! = UserObj!.getItem(num(user_tpl.vectOrigOfst$))

	if vectOrig! <> vectSubs!
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
[[SFE_WO_SUBADJ.ARAR]]
rem --- Display Work Order Number

	wo_no$=callpoint!.getDevObject("wo_no")
	callpoint!.setColumnData("SFE_WO_SUBADJ.WO_NO",wo_no$,1)
[[SFE_WO_SUBADJ.ASVA]]
rem --- Now write the Adjutment Entry records out

	gosub save_changes
[[SFE_WO_SUBADJ.ASIZ]]
rem --- Resize the grid

	if UserObj!<>null() then
		gridSubs!=UserObj!.getItem(num(user_tpl.gridSubsOfst$))
		gridSubs!.setSize(Form!.getWidth()-(gridSubs!.getX()*2),Form!.getHeight()-(gridSubs!.getY()+10))
		gridSubs!.setFitToGrid(1)
	endif
[[SFE_WO_SUBADJ.ACUS]]
rem --- Process custom event
rem --- Select/de-select checkboxes in grid and edit payment and discount amounts

rem This routine is executed when callbacks have been set to run a 'custom event'.
rem Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind of event it is.
rem See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info.

	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ctl_ID=dec(gui_event.ID$)

rem	if ctl_ID <> num(user_tpl.gridSubsCtlID$) then break; rem --- exit callpoint

	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
	endif

	gridSubs! = UserObj!.getItem(num(user_tpl.gridSubsOfst$))
	numcols = gridSubs!.getNumColumns()
	vectSubs! = UserObj!.getItem(num(user_tpl.vectSubsOfst$))
	vectSubsMaster! = UserObj!.getItem(num(user_tpl.vectSubsMasterOfst$))
	curr_row = dec(notice.row$);rem 0 based
	curr_col = dec(notice.col$);rem 0 based
	grid_ctx=gridSubs!.getContextID()

	switch notice.code

		case 32; rem grid cell validation
rem --- New Work Order Number

			if curr_col=11
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
						gridSubs!.setCellText(cur_row,11,"")
						msg_id$="INPUT_ERR_DATA"
						gosub disp_message
						gridSubs!.focus()
						sysgui!.setContext(grid_ctx)
						gridSubs!.accept(0)
						gridSubs!.startEdit(curr_row,curr_col)
						break
					endif
					if sfe_womast.wo_status$="C"
						gridSubs!.setCellText(cur_row,11,"")
						msg_id$="WO_CLOSED"
						gosub disp_message
						gridSubs!.focus()
						sysgui!.setContext(grid_ctx)
						gridSubs!.accept(0)
						gridSubs!.startEdit(curr_row,curr_col)
						break
					endif
				else
					wo_no$=callpoint!.getDevObject("wo_no")
				endif

				vectSubs!.setItem((curr_row*num(user_tpl.gridSubsCols$))+11,wo_no$)
				gridSubs!.setCellText(curr_row,11,wo_no$)
				gridSubs!.accept(1)
				break
			endif

rem --- Units or Cost

			if curr_col = 6 or curr_col=8 then
				if curr_col=6
					units=num(notice.buf$)
					cost=num(gridSubs!.getCellText(curr_row,8))
				endif
				if curr_col=8
					cost=num(notice.buf$)
					units=num(gridSubs!.getCellText(curr_row,6))
				endif
				tot_ext=units*cost
				gridSubs!.setCellText(curr_row,10,str(tot_ext))
				vectSubs!.setItem((curr_row*num(user_tpl.gridSubsCols$))+6,str(units))
				vectSubs!.setItem((curr_row*num(user_tpl.gridSubsCols$))+8,str(cost))
				gridSubs!.accept(1)
				break
			endif

rem --- New Tran Date
			if curr_col=12
				tran_date$=notice.buf$
				input_value$=tran_date$
				gosub validate_date
				if len(msg_id$)>0
					dim msg_tokens$[1]
					msg_tokens$[1]=Translate!.getTranslation("AON_ADJUST")+" "+Translate!.getTranslation("AON_DATE")
					gosub disp_message
					gridSubs!.focus()
					sysgui!.setContext(grid_ctx)
					gridSubs!.accept(0)
					gridSubs!.startEdit(curr_row,curr_col)
					break
				endif
				tran_date$=temp_date$
				if len(cvs(tran_date$,2))=0
					tran_date$=gridSubs!.getCellText(curr_row,0)
					input_value$=vectSubs!.getItem((curr_row*num(user_tpl.gridSubsCols$)))
				endif

				vectSubs!.setItem((curr_row*num(user_tpl.gridSubsCols$))+12,fndate$(input_value$))
				gridSubs!.setCellText(curr_row,curr_col,fndate$(input_value$))
			endif
			gridSubs!.accept(1)
			break

		case 19; rem row change

			if vectSubs!.size()=0 break
			gosub switch_colors
			break

		case 6; rem "Special Key" - escape
			if notice.wparam=8
				gridSubs!.endEdit()
			endif
			break

		case 12; rem Lookup
			if curr_col=11
				keycode=notice.wparam
				keycode$=bin(keycode,2)
				if asc(and(keycode$,$2000$)) and keycode$=$2006$
					key_pfx$=firm_id$
					call stbl("+DIR_SYP")+"bac_key_template.bbj","SFE_WOMASTR","PRIMARY",key_tpl$,table_chans$[all],status$
					dim sel_key$:key_tpl$
					call stbl("+DIR_SYP")+"bam_inquiry.bbj",gui_dev,Form!,"SFE_WOMASTR","SELECT",table_chans$[all],key_pfx$,"",sel_key$
					if len(sel_key$)>0
						VectOps!.setItem((curr_row*num(user_tpl.gridOpsCols$))+17,sel_key.wo_no$)
						gridOps!.setCellText(curr_row,curr_col,sel_key.wo_no$)
					endif
				endif
			endif
			break

		case 14; rem --- grid_mouse_up
			if notice.col=0 gosub switch_value
			break

	swend

	UserObj!.setItem(num(user_tpl.vectSubsOfst$),vectSubs!)
	UserObj!.setItem(num(user_tpl.vectSubsMasterOfst$),vectSubsMaster!)
[[SFE_WO_SUBADJ.AWIN]]
rem --- Open/Lock files

	use ::ado_util.src::util
	use ::ado_func.src::func

	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="SFT_OPNSUBTR",open_opts$[1]="OTA"
	open_tables$[2]="APM_VENDMAST",open_opts$[2]="OTA"
	open_tables$[3]="SFS_PARAMS",open_opts$[3]="OTA"
	open_tables$[4]="SFE_WOSUBADJ",open_opts$[4]="OTA"
	open_tables$[5]="SFE_WOMASTR",open_opts$[5]="OTA"

	gosub open_tables

	sft31_dev=num(open_chans$[1]),sft31_tpl$=open_tpls$[1]
	apm01_dev=num(open_chans$[2]),apm01_tpl$=open_tpls$[2]
	sfs_params=num(open_chans$[3]),sfs_params_tpl$=open_tpls$[3]

rem --- Dimension string templates

	dim sft31a$:sft31_tpl$
	dim apm01a$:apm01_tpl$
	dim sfs_params$:sfs_params_tpl$

rem --- Get parameter record

	readrecord(sfs_params,key=firm_id$+"SF00")sfs_params$

rem --- Add grid to store Subcontracts, with checkboxes for user to select one or more

	user_tpl_str$ = "gridSubsOfst:c(5), " +
:		"gridSubsCols:c(5), " +
:		"gridSubsRows:c(5), " +
:		"gridSubsCtlID:c(5)," +
:		"vectSubsOfst:c(5), " +
:		"vectSubsMasterOfst:c(5), " +
:		"vectOrigOfst:c(5)"

	dim user_tpl$:user_tpl_str$

	UserObj! = BBjAPI().makeVector()
	vectSubs! = BBjAPI().makeVector()
	vectSubsMaster! = BBjAPI().makeVector()
	nxt_ctlID = util.getNextControlID()

	gridSubs! = Form!.addGrid(nxt_ctlID,5,60,900,250); rem --- ID, x, y, width, height

	user_tpl.gridSubsCtlID$ = str(nxt_ctlID)
	user_tpl.gridSubsCols$ = "13"
	user_tpl.gridSubsRows$ = "10"
	callpoint!.setDevObject("wo_no_len",len(sft31a.wo_no$))
	callpoint!.setDevObject("wo_no_mask",fill(len(sft31a.wo_no$),"0"))

	gosub format_grid
	util.resizeWindow(Form!, SysGui!)

	UserObj!.addItem(gridSubs!)
	user_tpl.gridSubsOfst$="0"

	UserObj!.addItem(vectSubs!); rem --- vector of Open Subs
	user_tpl.vectSubsOfst$="1"

	UserObj!.addItem(vectSubsMaster!); rem --- vector of Master Open Subs
	user_tpl.vectSubsMasterOfst$="2"

	UserObj!.addItem(vectOrig!); rem --- vector of original displayed vector
	user_tpl.vectOrigOfst$="3"

rem --- Misc other init

	call stbl("+DIR_SYP")+"bac_create_color.bbj","+ENTRY_ERROR_COLOR","255,224,224",diff_color!,""
	same_color!=SysGUI!.makeColor(7)
	callpoint!.setDevObject("diff_color",diff_color!)
	callpoint!.setDevObject("same_color",same_color!)
	gridSubs!.setColumnEditable(0,1)
	gridSubs!.setColumnEditable(6,1)
	gridSubs!.setColumnEditable(8,1)
	gridSubs!.setColumnEditable(11,1)
	gridSubs!.setColumnEditable(12,1)
	gridSubs!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)
	gridSubs!.setTabAction(gridSubs!.GRID_NAVIGATE_GRID)
	gridSubs!.setTabActionSkipsNonEditableCells(1)
	gridSubs!.setEnterAsTab(1)

	gosub create_reports_vector
	gosub fill_grid

rem --- Set callbacks - processed in ACUS callpoint

	gridSubs!.setCallback(gridSubs!.ON_GRID_CELL_VALIDATION,"custom_event")
	gridSubs!.setCallback(gridSubs!.ON_GRID_SELECT_ROW,"custom_event")
	gridSubs!.setCallback(gridSubs!.ON_GRID_SPECIAL_KEY,"custom_event")
	gridSubs!.setCallback(gridSubs!.ON_GRID_KEYPRESS,"custom_event")
	gridSubs!.setCallback(gridSubs!.ON_GRID_MOUSE_UP,"custom_event")
	gridSubs!.setCallback(gridSubs!.ON_GRID_MOUSE_DOWN,"custom_event")
[[SFE_WO_SUBADJ.<CUSTOM>]]
rem ==========================================================================
format_grid: rem --- Use Barista program to format the grid
rem ==========================================================================

	call stbl("+DIR_PGM")+"adc_getmask.aon","","SF","A","",m1$,0,0

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0] = callpoint!.getColumnAttributeTypes()
	def_sub_cols = num(user_tpl.gridSubsCols$)
	num_rpts_rows = num(user_tpl.gridSubsRows$)
	dim attr_sub_col$[def_sub_cols,len(attr_def_col_str$[0,0])/5]

	attr_sub_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SELECT"
	attr_sub_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=""
	attr_sub_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"
	attr_sub_col$[1,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="1"
	attr_sub_col$[1,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="C"

	attr_sub_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ORIG_TRANS_DATE"
	attr_sub_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_TRANSACTION_DATE")
	attr_sub_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="40"

	attr_sub_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="VEND_ID"
	attr_sub_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_VENDOR")
	attr_sub_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"

	attr_sub_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="VEND_NAME"
	attr_sub_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_NAME")
	attr_sub_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="180"

	attr_sub_col$[5,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="PO_NO"
	attr_sub_col$[5,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_PO_NO")
	attr_sub_col$[5,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="75"

	attr_sub_col$[6,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ORIG_UNITS"
	attr_sub_col$[6,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ORIG")+" "+Translate!.getTranslation("AON_UNITS")
	attr_sub_col$[6,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_sub_col$[6,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_sub_col$[6,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_sub_col$[7,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="NEW_UNITS"
	attr_sub_col$[7,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ADJUST")+" "+Translate!.getTranslation("AON_UNITS")
	attr_sub_col$[7,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_sub_col$[7,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_sub_col$[7,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_sub_col$[8,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ORIG_COST"
	attr_sub_col$[8,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ORIG")+" "+Translate!.getTranslation("AON_COST")
	attr_sub_col$[8,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_sub_col$[8,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_sub_col$[8,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_sub_col$[9,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="NEW_COST"
	attr_sub_col$[9,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ADJUST")+" "+Translate!.getTranslation("AON_COST")
	attr_sub_col$[9,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_sub_col$[9,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_sub_col$[9,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_sub_col$[10,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ORIG_EXT"
	attr_sub_col$[10,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ORIG")+" "+Translate!.getTranslation("AON_TOTAL")
	attr_sub_col$[10,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_sub_col$[10,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_sub_col$[10,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_sub_col$[11,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="NEW_EXT"
	attr_sub_col$[11,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ADJUST")+" "+Translate!.getTranslation("AON_TOTAL")
	attr_sub_col$[11,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_sub_col$[11,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_sub_col$[11,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_sub_col$[12,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="NEW_WO"
	attr_sub_col$[12,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ADJUST")+" "+Translate!.getTranslation("AON_WO")
	attr_sub_col$[12,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"
	attr_sub_col$[12,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_sub_col$[12,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=callpoint!.getDevObject("wo_no_mask")
	attr_sub_col$[12,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]=str(callpoint!.getDevObject("wo_no_len"))
	attr_sub_col$[12,fnstr_pos("DTAB",attr_def_col_str$[0,0],5)]="SFE_WOMASTR"
	attr_sub_col$[12,fnstr_pos("DCOL",attr_def_col_str$[0,0],5)]="ITEM_ID"
	attr_sub_col$[12,fnstr_pos("DKEY",attr_def_col_str$[0,0],5)]=firm_id$+"  "

	attr_sub_col$[13,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="NEW_DATE"
	attr_sub_col$[13,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ADJUST")+" "+Translate!.getTranslation("AON_DATE")
	attr_sub_col$[13,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_sub_col$[13,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="D"
	attr_sub_col$[13,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"
	attr_sub_col$[13,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	attr_sub_col$[13,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=stbl("+DATE_MASK",err=*next)

	for curr_attr=1 to def_sub_cols
		attr_sub_col$[0,1] = attr_sub_col$[0,1] + 
:			pad("SFE_WO_SUBADJ." + attr_sub_col$[curr_attr, fnstr_pos("DVAR", attr_def_col_str$[0,0], 5)], 40)
	next curr_attr

	attr_disp_col$=attr_sub_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridSubs!,"CHECKS-COLH-DATES-LINES-LIGHT-SIZEC-CELL",num_rpts_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_sub_col$[all]

	return

rem ==========================================================================
fill_grid: rem --- Fill the grid with data in vectSubs!
rem ==========================================================================

	SysGUI!.setRepaintEnabled(0)
	gridSubs! = UserObj!.getItem(num(user_tpl.gridSubsOfst$))
	minrows = num(user_tpl.gridSubsRows$)

	if vectSubs!.size() then
		numrow = vectSubs!.size() / gridSubs!.getNumColumns()
		gridSubs!.clearMainGrid()
		gridSubs!.setNumRows(numrow)
		gridSubs!.setCellText(0,0,vectSubs!)

		gosub switch_colors
	else
		gridSubs!.clearMainGrid()
		gridSubs!.setNumRows(0)
	endif

	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
create_reports_vector: rem --- Create a vector from the file to fill the grid
rem ==========================================================================

	sfe_subadj=fnget_dev("SFE_WOSUBADJ")

	call stbl("+DIR_PGM")+"adc_getmask.aon","VENDOR_ID","","","",m0$,0,vendor_len
	more=1
	wo_loc$=callpoint!.getDevObject("wo_loc")
	wo_no$=callpoint!.getDevObject("wo_no")
	read (sft31_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)

	while more
		read record (sft31_dev, end=*break) sft31a$
		if pos(firm_id$=sft31a$)<>1 then break
		if wo_no$<>sft31a.wo_no$ break
		dim apm01a$:fattr(apm01a$)
		read record(apm01_dev, key=firm_id$+sft31a.vendor_id$, dom=*next) apm01a$
		dim sfe_subadj$:fnget_tpl$("SFE_WOSUBADJ")
		found=0
		while 1
			read record (sfe_subadj,key=firm_id$+wo_loc$+wo_no$+sft31a.trans_date$+sft31a.trans_seq$,dom=*break)sfe_subadj$
			found=1
			break
		wend

	rem --- Now fill vectors

		vectSubs!.addItem(""); rem 0
		vectSubs!.addItem(fndate$(sft31a.trans_date$)); rem 1
		vectSubs!.addItem(func.alphaMask(sft31a.vendor_id$(1,vendor_len),m0$)); rem 2
		vectSubs!.addItem(apm01a.vendor_name$); rem 3
		vectSubs!.addItem(sft31a.po_no$); rem 4
		vectSubs!.addItem(str(sft31a.units)); rem 5
		if found=1
			vectSubs!.addItem(str(sfe_subadj.new_units)); rem 6
		else
			vectSubs!.addItem(str(sft31a.units)); rem 6
		endif
		vectSubs!.addItem(str(sft31a.unit_cost)); rem 7
		if found=1
			vectSubs!.addItem(str(sfe_subadj.new_unit_cst)); rem 8
		else
			vectSubs!.addItem(str(sft31a.unit_cost)); rem 8
		endif
		vectSubs!.addItem(str(sft31a.ext_cost)); rem 9
		if found=1
			vectSubs!.addItem(str(sfe_subadj.new_units*sfe_subadj.new_unit_cst)); rem 10
			vectSubs!.addItem(sfe_subadj.new_wo_no$); rem 11
			vectSubs!.addItem(fndate$(sfe_subadj.new_trn_date$)); rem 12
		else
			vectSubs!.addItem(str(sft31a.ext_cost)); rem 10
			vectSubs!.addItem(wo_no$);rem 11
			vectSubs!.addItem(fndate$(sft31a.trans_date$)); rem 12
		endif
		vectSubsMaster!.addItem(sft31a.trans_seq$);rem keep track of sequence

	wend

	vectOrig! = vectSubs!.clone()
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

rem ==========================================================
switch_colors:
rem ==========================================================

	cols=num(user_tpl.gridSubsCols$)
	for row=1 to vectSubs!.size()-1 step cols
		change$="N"
		if vectSubs!.getItem(((row-1)/cols)*cols+5)<>vectSubs!.getItem(((row-1)/cols)*cols+6)
			gridSubs!.setCellBackColor((row-1)/cols,6,callpoint!.getDevObject("diff_color"))
			change$="Y"
		else
			gridSubs!.setCellBackColor((row-1)/cols,6,callpoint!.getDevObject("same_color"))
		endif
		if vectSubs!.getItem(((row-1)/cols)*cols+7)<>vectSubs!.getItem(((row-1)/cols)*cols+8)
			gridSubs!.setCellBackColor((row-1)/cols,8,callpoint!.getDevObject("diff_color"))
			change$="Y"
		else
			gridSubs!.setCellBackColor((row-1)/cols,8,callpoint!.getDevObject("same_color"))
		endif
		if vectSubs!.getItem(((row-1)/cols)*cols+11)<>callpoint!.getDevObject("wo_no")
			gridSubs!.setCellBackColor((row-1)/cols,11,callpoint!.getDevObject("diff_color"))
			change$="Y"
		else
			gridSubs!.setCellBackColor((row-1)/cols,11,callpoint!.getDevObject("same_color"))
		endif
		if vectSubs!.getItem(((row-1)/cols)*cols+12)<>vectSubs!.getItem(((row-1)/cols)*cols+1)
			gridSubs!.setCellBackColor((row-1)/cols,12,callpoint!.getDevObject("diff_color"))
			change$="Y"
		else
			gridSubs!.setCellBackColor((row-1)/cols,12,callpoint!.getDevObject("same_color"))
		endif
		if change$="Y"
			gridSubs!.setCellStyle((row-1)/cols, 0, SysGUI!.GRID_STYLE_CHECKED)
		else
			gridSubs!.setCellStyle((row-1)/cols, 0, SysGUI!.GRID_STYLE_UNCHECKED)
		endif
	next row

	return

rem ==========================================================================
switch_value: rem --- Switch Check Values
rem ==========================================================================

	SysGUI!.setRepaintEnabled(0)

rem	gridSubs!       = UserObj!.getItem(num(user_tpl.gridSubs$))
rem	vectsubs!       = UserObj!.getItem(num(user_tpl.vectSubsOfst$))

	TempRows! = gridSubs!.getSelectedRows()
	numcols   = gridSubs!.getNumColumns()

	if TempRows!.size() > 0 then
		for curr_row=1 to TempRows!.size()
			row_no = num(TempRows!.getItem(curr_row-1))

			if gridSubs!.getCellState(row_no,0) = 0 then
		rem --- not checked - leave alone

				gridSubs!.setCellState(row_no, 0, 0)

			else
		rem --- Checked -> not checked

				orig_units$ = gridSubs!.getCellText(row_no,5)
				orig_cost$=gridSubs!.getCellText(row_no,7)
				orig_ext$=gridSubs!.getCellText(row_no,9)
				orig_wo$=callpoint!.getDevObject("wo_no")
				orig_date$=gridSubs!.getCellText(row_no,1)

				gridSubs!.setCellState(row_no,0,0)
				gridSubs!.setCellText(row_no, 6, orig_units$)
				gridSubs!.setCellText(row_no,8,orig_cost$)
				gridSubs!.setCellText(row_no,10,orig_ext$)
				gridSubs!.setCellText(row_no,11,orig_wo$)
				gridSubs!.setCellText(row_no,12,orig_date$)

				gridSubs!.setCellBackColor(rowno,6,callpoint!.getDevObject("same_color"))
				gridSubs!.setCellBackColor(rowno,8,callpoint!.getDevObject("same_color"))
				gridSubs!.setCellBackColor(rowno,10,callpoint!.getDevObject("same_color"))
				gridSubs!.setCellBackColor(rowno,11,callpoint!.getDevObject("same_color"))
				gridSubs!.setCellBackColor(rowno,12,callpoint!.getDevObject("same_color"))

				vectSubs!.setItem((row_no*numcols)+6,orig_units$)
				vectSubs!.setItem((row_no*numcols)+8,orig_cost$)
				vectSubs!.setItem((row_no*numcols)+10,orig_ext$)
				vectSubs!.setItem((row_no*numcols)+11,orig_wo$)
				vectSubs!.setItem((row_no*numcols)+12,orig_date$)

			endif
		next curr_row
	endif

	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
save_changes:
rem ==========================================================================

rem --- Now write the Adjutment Entry records out

	vectSubs! = UserObj!.getItem(num(user_tpl.vectSubsOfst$))
	vectSubsMaster! = UserObj!.getItem(num(user_tpl.vectSubsMasterOfst$))

	sfe_subadj=fnget_dev("SFE_WOSUBADJ")
	dim sfe_subadj$:fnget_tpl$("SFE_WOSUBADJ")

	cols=num(user_tpl.gridSubsCols$)
	mast=0
	wo_no$=callpoint!.getDevObject("wo_no")
	wo_loc$=callpoint!.getDevObject("wo_loc")

	if vectSubs!.size()
		for x=0 to vectSubs!.size()-1 step cols
			tran_date$=vectSubs!.getItem(x+1)
			if len(cvs(tran_date$,2))=10
				tran_date$=tran_date$(7,4)+tran_date$(1,2)+tran_date$(4,2)
			endif
			tran_seq$=vectSubsMaster!.getItem(mast)
			old_units=num(vectSubs!.getItem(x+5))
			new_units=num(vectSubs!.getItem(x+6))
			old_cost=num(vectSubs!.getItem(x+7))
			new_cost=num(vectSubs!.getItem(x+8))
			new_wo$=vectSubs!.getItem(x+11)
			if cvs(new_wo$,2)="" new_wo$=wo_no$
			new_date$=vectSubs!.getItem(x+12)
			if cvs(new_date$,2)="" new_date$=tran_date$
			if len(cvs(new_date$,2))=10
				new_date$=new_date$(7,4)+new_date$(1,2)+new_date$(4,2)
			endif
			if tran_date$ <> new_date$ or
:			   old_units <> new_units or
:			   old_cost <> new_cost or
:			   wo_no$ <> new_wo$
rem --- Write entry Record
				sfe_subadj.firm_id$=firm_id$
				sfe_subadj.wo_location$=wo_loc$
				sfe_subadj.wo_no$=wo_no$
				sfe_subadj.trans_date$=tran_date$
				sfe_subadj.trans_seq$=tran_seq$
				sfe_subadj.new_wo_no$=new_wo$
				sfe_subadj.new_trn_date$=new_date$
				sfe_subadj.new_units=new_units
				sfe_subadj.new_unit_cst=new_cost
				sfe_subadj.batch_no$=callpoint!.getColumnData("SFE_WO_SUBADJ.BATCH_NO")
				sfe_subadj$=field(sfe_subadj$)
				write record (sfe_subadj) sfe_subadj$
			else
rem --- Remove Entry Record
				remove (sfe_subadj,key=firm_id$+wo_loc$+wo_no$+tran_date$+tran_seq$,dom=*next)
			endif
			mast=mast+1
		next x
	endif

	return
