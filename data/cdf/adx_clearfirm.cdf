[[ADX_CLEARFIRM.AOPT-CLRF]]
rem --- Open/Lock files

	vectFiles! = callpoint!.getDevObject("vectFiles")
	vectFilesMaster! = callpoint!.getDevObject("vectFilesMaster")
	numcols = num(user_tpl.gridFilesCols$)
	firm$=callpoint!.getColumnData("ADX_CLEARFIRM.FIRM_ID_ENTRY")

	if vectFiles!.size() > 0
		for curr_row=0 to vectFiles!.size()/(numcols)-1
			if vectFiles!.getItem(curr_row*numcols)="Y"
				num_files=1
				dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
				open_tables$[1]=vectFiles!.getItem(curr_row * numcols + 3)
				open_opts$[1]="OTASN"
				gosub open_tables
				table_dev=num(open_chans$[1])
				if cvs(firm$,2)=""
					open_tables$[1]=vectFiles!.getItem(curr_row * numcols + 3)
					open_opts$[1]="CX"
					gosub open_tables
					call "adc_clearfile.aon",table_dev
				else
					call "adc_clearpartial.aon","N",table_dev,firm$,status
					open_tables$[1]=vectFiles!.getItem(curr_row * numcols + 3)
					open_opts$[1]="CX"
					gosub open_tables
				endif
			endif
		next curr_row

		callpoint!.setColumnData("ADX_CLEARFIRM.ASC_COMP_ID","")
		callpoint!.setColumnData("ADX_CLEARFIRM.ASC_PROD_ID","")
		callpoint!.setColumnData("ADX_CLEARFIRM.FIRM_ID_ENTRY","")
		callpoint!.setStatus("REFRESH")

		vectFiles!.clear()
		vectFilesMaster!.clear()
		callpoint!.setDevObject("vectFiles",vectFiles!)
		callpoint!.setDevObject("vectFilesMaster",vectFilesMaster!)

		gosub create_reports_vector
		gosub fill_grid

		if cvs(firm$,2)=""
			prompt$="All firms cleared for selected table(s)."
			x=msgbox(prompt$,64,task_description$)
		else
			prompt$="Selected table(s) cleared for firm "+firm$+"."
			x=msgbox(prompt$,64,task_description$)
		endif
	endif
[[ADX_CLEARFIRM.FIRM_ID_ENTRY.AVAL]]
rem --- Set number of recs for firm selected

	firm$=cvs(callpoint!.getUserInput(),3)
	gosub set_firm_recs
[[ADX_CLEARFIRM.ASC_PROD_ID.AVAL]]
rem --- Set Filter
	gosub filter_recs
	firm$=cvs(callpoint!.getColumnData("ADX_CLEARFIRM.FIRM_ID_ENTRY"),3)
	gosub set_firm_recs
[[ADX_CLEARFIRM.ASC_COMP_ID.AVAL]]
rem --- Set Filter
	gosub filter_recs
	firm$=cvs(callpoint!.getColumnData("ADX_CLEARFIRM.FIRM_ID_ENTRY"),3)
	gosub set_firm_recs
[[ADX_CLEARFIRM.ACUS]]
rem --- Process custom event
rem --- Select/de-select checkboxes in grid

rem This routine is executed when callbacks have been set to run a 'custom event'.
rem Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind of event it is.
rem See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info.

	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ctl_ID=dec(gui_event.ID$)

	if ctl_ID <> num(user_tpl.gridFilesCtlID$) then break; rem --- exit callpoint

	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
	endif

	gridFiles! = callpoint!.getDevObject("gridFiles")
	numcols = gridFiles!.getNumColumns()
	vectFiles! = callpoint!.getDevObject("vectFiles")
	vectFilesMaster! = callpoint!.getDevObject("vectFilesMaster")
	curr_row = dec(notice.row$)
	curr_col = dec(notice.col$)

	switch notice.code
		case 12; rem --- grid_key_press
			if notice.wparam=32 gosub switch_value
			break

		case 14; rem --- grid_mouse_up
			if notice.col=0 gosub switch_value
			break

		case 7; rem --- edit stop

		break
	swend
[[ADX_CLEARFIRM.<CUSTOM>]]
rem ==========================================================================
format_grid: rem --- Use Barista program to format the grid
rem ==========================================================================

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0] = callpoint!.getColumnAttributeTypes()
	def_inv_cols = num(user_tpl.gridFilesCols$)
	num_rpts_rows = num(user_tpl.gridFilesRows$)
	dim attr_inv_col$[def_inv_cols,len(attr_def_col_str$[0,0])/5]

	attr_inv_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SELECT"
	attr_inv_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=""
	attr_inv_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"
	attr_inv_col$[1,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="1"
	attr_inv_col$[1,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="C"

	attr_inv_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ASC_COMP_ID"
	attr_inv_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Company ID"
	attr_inv_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="80"

	attr_inv_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ASC_PROD_ID"
	attr_inv_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Product ID"
	attr_inv_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="80"

	attr_inv_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="FILE_NAME"
	attr_inv_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="File Name"
	attr_inv_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="150"

	attr_inv_col$[5,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DESCRIPTION"
	attr_inv_col$[5,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Description"
	attr_inv_col$[5,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="300"

	attr_inv_col$[6,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="RECS"
	attr_inv_col$[6,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Records to delete"
	attr_inv_col$[6,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_inv_col$[6,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[6,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]="##,###,##0"

	attr_inv_col$[7,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="TOTAL_RECS"
	attr_inv_col$[7,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Records in file"
	attr_inv_col$[7,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_inv_col$[7,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[7,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]="##,###,##0"
	for curr_attr=1 to def_inv_cols
		attr_inv_col$[0,1] = attr_inv_col$[0,1] + 
:			pad("DDM_TABLES." + attr_inv_col$[curr_attr, fnstr_pos("DVAR", attr_def_col_str$[0,0], 5)], 40)
	next curr_attr

	attr_disp_col$=attr_inv_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridFiles!,"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC-CHECKS-DATES",num_rpts_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_inv_col$[all]

	return

rem ==========================================================================
fill_grid: rem --- Fill the grid with data in vectFiles!
rem ==========================================================================

	SysGUI!.setRepaintEnabled(0)
	gridFiles! = callpoint!.getDevObject("gridFiles")
	vectFiles! = callpoint!.getDevObject("vectFiles")
	minrows = num(user_tpl.gridFilesRows$)

	if vectFiles!.size() then
		numrow = vectFiles!.size() / gridFiles!.getNumColumns()
		gridFiles!.clearMainGrid()
		gridFiles!.setColumnStyle(0,SysGUI!.GRID_STYLE_UNCHECKED)
		gridFiles!.setNumRows(numrow)
		gridFiles!.setCellText(0,0,vectFiles!)

		for wk=0 to vectFiles!.size()-1 step gridFiles!.getNumColumns()
			if vectFiles!.getItem(wk) = "Y" then 
				gridFiles!.setCellStyle(wk / gridFiles!.getNumColumns(), 0, SysGUI!.GRID_STYLE_CHECKED)
			endif
			gridFiles!.setCellText(wk / gridFiles!.getNumColumns(), 0, "")
		next wk

		gridFiles!.resort()
	else
		gridFiles!.clearMainGrid()
		gridFiles!.setColumnStyle(0, SysGUI!.GRID_STYLE_UNCHECKED)
		gridFiles!.setNumRows(0)
	endif

	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
create_reports_vector: rem --- Create a vector from the file to fill the grid
rem ==========================================================================

rem --- fill with File information

	ddm_tables_dev=fnget_dev("DDM_TABLES")
	dim ddm_tables$:fnget_tpl$("DDM_TABLES")
	read (ddm_tables_dev,key="",dom=*next)
	rows=0

	modules$=callpoint!.getDevObject("modules")

	call pgmdir$+"adc_progress.aon","NC","DDM_TABLES","","","",0,ddm_tables_dev,1,meter_num,status

	while 1
		read record (ddm_tables_dev, end=*break) ddm_tables$

		call pgmdir$+"adc_progress.aon","S","","","","",0,channel,1,meter_num,status

	rem --- Now fill vectors
	rem --- Items 1 thru n+1 in FilesMaster must equal items 0 thru n in Files

		if pos(ddm_tables.dd_alias_type$="MXVSD")>0 and pos(ddm_tables.asc_prod_id$=modules$,3) > 0 then
			if ddm_tables.asc_prod_id$ <> "ADB" or
:				((ddm_tables.asc_prod_id$="ADB") and
:				 (cvs(ddm_tables.dd_table_alias$,2)="ADQ_FAXEMAIL") or
:				 (cvs(ddm_tables.dd_table_alias$,2)="ADS_MASKS") or
:				 (cvs(ddm_tables.dd_table_alias$,2)="ADS_SEQUENCES"))
				num_files=1
				dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
				open_tables$[1]=cvs(ddm_tables.dd_table_alias$,2),open_opts$[1]="OTASN"
				gosub open_tables
				table_chn=num(open_chans$[1]),table_tpl$=open_tpls$[1]

				if table_chn >0
					table_fin$=xfin(table_chn)
					dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
					open_tables$[1]=cvs(ddm_tables.dd_table_alias$,2),open_opts$[1]="CX"
					gosub open_tables

					tot_recs=0
					if pos(ddm_tables.dd_alias_type$="VMX")>0
						tot_recs=dec(table_fin$(77,4))
					endif

					vectFiles!.addItem("N"); rem 0
					vectFiles!.addItem(ddm_tables.asc_comp_id$);rem 1
					vectFiles!.addItem(ddm_tables.asc_prod_id$);rem 2
					vectFiles!.addItem(ddm_tables.dd_table_alias$); rem 3
					vectFiles!.addItem(ddm_tables.dd_alias_desc$); rem 4
					vectFiles!.addItem(str(tot_recs)); rem 5
					vectFiles!.addItem(str(tot_recs)); rem 6

					vectFilesMaster!.addItem("Y"); rem 0 - Filtered Y or N
					vectFilesMaster!.addItem("N"); rem 1 - Selected Y or N
					vectFilesMaster!.addItem(ddm_tables.asc_comp_id$);rem 2
					vectFilesMaster!.addItem(ddm_tables.asc_prod_id$); rem 3
					vectFilesMaster!.addItem(ddm_tables.dd_table_alias$); rem 4
					vectFilesMaster!.addItem(ddm_tables.dd_alias_desc$); rem 5
					vectFilesMaster!.addItem(str(tot_recs)); rem 6
					vectFilesMaster!.addItem(str(tot_recs)); rem 7
					rows=rows+1
				endif
			endif
		endif
	wend

	callpoint!.setDevObject("vectFiles",vectFiles!)
	callpoint!.setDevObject("vectFilesMaster",vectFilesMaster!)
	callpoint!.setStatus("REFRESH")
	
	call pgmdir$+"adc_progress.aon","D","","","","",0,0,0,meter_num,status

	return

rem ==========================================================================
checkout_licenses: rem --- checkout licenses each module
rem ==========================================================================


	rem --- Checkout the licenses for each module to make sure we can open the tables.

	adm_modules_dev=fnget_dev("ADM_MODULES")
	dim adm_modules_tpl$:fnget_tpl$("ADM_MODULES")
	read (adm_modules_dev,key="",dom=*next)

	modules$=""

	while 1
		read record(adm_modules_dev,end=*break) adm_modules_tpl$
		feature$=cvs(adm_modules_tpl.asc_comp_id$,2)+cvs(adm_modules_tpl.asc_prod_id$,2)
		version$=cvs(adm_modules_tpl.version_id$,3)

		call stbl("+DIR_SYP")+"bax_lcheckout.bbj",feature$,version$,rd_check_handle,rd_license_type$,rd_license_status$,table_chans$[all]

		if checkout<>-1 or err=0 or err=100
			lcheckin(checkout,err=*next)
			if rd_license_status$<>"INVALID" and
:			   pos(adm_modules_tpl.asc_comp_id$+adm_modules_tpl.asc_prod_id$="01007514DDB01007514SQB",11)=0
				modules$=modules$+pad(adm_modules_tpl.asc_prod_id$,3)
			endif
		endif
	wend

	callpoint!.setDevObject("modules",modules$)

	return

rem ==========================================================================
switch_value: rem --- Switch Check Values
rem ==========================================================================

	SysGUI!.setRepaintEnabled(0)

	gridFiles! = callpoint!.getDevObject("gridFiles")
	vectFiles! = callpoint!.getDevObject("vectFiles")
	vectFilesMaster! = callpoint!.getDevObject("vectFilesMaster")

	TempRows! = gridFiles!.getSelectedRows()
	numcols   = gridFiles!.getNumColumns()
	any_checked$="N"

	if TempRows!.size() > 0 then
		for curr_row=1 to TempRows!.size()
			row_no = num(TempRows!.getItem(curr_row-1))

		rem --- Not checked -> checked

			if gridFiles!.getCellState(row_no,0) = 0 then 
				gridFiles!.setCellState(row_no,0,1)
				vectFiles!.setItem(row_no * numcols, "Y")

		rem --- Checked -> not checked

			else
				gridFiles!.setCellState(row_no,0,0)
				vectFiles!.setItem(row_no * numcols, "N")
			endif
		next curr_row
	endif

	gosub enable_button

	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
filter_recs: rem --- Set grid vector based on filters
rem ==========================================================================
	vectFilesMaster! = callpoint!.getDevObject("vectFilesMaster")
	vectFiles! = callpoint!.getDevObject("vectFiles")
	vect_size = num(vectFilesMaster!.size())

	if vect_size then 

	rem --- Reset all select to include flags to Yes

		for x=1 to vect_size step user_tpl.MasterCols
			vectFilesMaster!.setItem(x-1,"Y")
		next x

	rem --- Set variables using either getColumnData or getUserInput, depending on where gosub'd from

		if callpoint!.getVariableName()="ADX_CLEARFIRM.ASC_COMP_ID"
			filter_comp_id$=callpoint!.getUserInput()
			filter_prod_id$=callpoint!.getColumnData("ADX_CLEARFIRM.ASC_PROD_ID")
		else
			if callpoint!.getVariableName()="ADX_CLEARFIRM.ASC_PROD_ID"
				filter_comp_id$=callpoint!.getColumnData("ADX_CLEARFIRM.ASC_COMP_ID")
				filter_prod_id$=callpoint!.getUserInput()
			endif
		endif

	rem --- Set all excluded filtered flags to No 

		for x=1 to vect_size step user_tpl.MasterCols
			select_rec$="Y"

			if filter_comp_id$<>"" and cvs(filter_comp_id$,2)<>vectFilesMaster!.getItem(x-1+2)
				select_rec$="N"
			endif

			if filter_prod_id$<>"" and filter_prod_id$<>vectFilesMaster!.getItem(x-1+3)
				select_rec$="N"
			endif

			if select_rec$="N"
				vectFilesMaster!.setItem(x-1,"N")
			endif
		next x

	rem --- Clear and reset visible grid

		vectFiles!.clear()

		for x=1 to vect_size step user_tpl.MasterCols
			if vectFilesMaster!.getItem(x-1)="Y"
				for y=1 to num(user_tpl.gridFilesCols$)
					vectFiles!.addItem(vectFilesMaster!.getItem(x-1+y))
				next y
			endif
		next x

		gosub enable_button

		callpoint!.setDevObject("vectFilesMaster",vectFilesMaster!)
		callpoint!.setDevObject("vectFiles",vectFiles!)
		gosub fill_grid
	endif

	return

rem ==========================================================================
enable_button:
rem ==========================================================================
	numcols = num(user_tpl.gridFilesCols$)
	if vectFiles!.size() > 0 then
		for curr_row=1 to vectFiles!.size()/(numcols)-1
			if vectFiles!.getItem(curr_row*numcols)="Y"
				any_checked$="Y"
			endif
		next curr_row
	endif

	if any_checked$="Y"
		callpoint!.setOptionEnabled("CLRF",1)
	else
		callpoint!.setOptionEnabled("CLRF",0)
	endif

	return

rem ==========================================================================
set_value: rem --- Set Check Values for all rows - on/off
		rem --- on_value$="Y" to set all to on
		rem --- on_value$="N" to set all to off
rem ==========================================================================

	SysGUI!.setRepaintEnabled(0)

	gridFiles! = callpoint!.getDevObject("gridFiles")
	vectFiles! = callpoint!.getDevObject("vectFiles")
	vectFilesMaster! = callpoint!.getDevObject("vectFilesMaster")

	TempRows! = gridFiles!.getSelectedRows()
	numcols   = gridFiles!.getNumColumns()

	vect_size = num(vectFilesMaster!.size())
	rows = 0

	for x=1 to vect_size step user_tpl.MasterCols
		if vectFilesMaster!.getItem(x-1)="Y"
			rows=rows+1
		endif
	next x

	if rows > 0 then
		for curr_row=1 to rows
			row_no = curr_row-1

		rem --- set as checked
			if on_value$="Y" then 

				gridFiles!.setCellState(row_no,0,1)

				vectFiles!.setItem(row_no * numcols, "Y")

		rem --- Checked -> not checked

			else
				gridFiles!.setCellState(row_no,0,0)
				vectFiles!.setItem(row_no * numcols, "N")
			endif
		next curr_row
	endif

	gosub enable_button

	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
set_firm_recs:
rem ==========================================================================

	SysGUI!.setRepaintEnabled(0)
	vectFiles! = callpoint!.getDevObject("vectFiles")
	vectFilesMaster! = callpoint!.getDevObject("vectFilesMaster")

	TempRows! = vectFiles!
	numcols   = num(user_tpl.gridFilesCols$)

	if TempRows!.size() > 0 then
		for curr_row=0 to TempRows!.size()/(num(user_tpl.gridFilesCols$))-1
			if cvs(firm$,2)=""
				vectFiles!.setItem(curr_row * numcols + 5, vectFiles!.getItem(curr_row * numcols + 6))
			else
				num_files=1
				dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
				open_tables$[1]=vectFiles!.getItem(curr_row * numcols + 3),open_opts$[1]="OTASN"
				gosub open_tables
				table_chn=num(open_chans$[1]),table_tpl$=open_tpls$[1]
				if pos("firm_id:"=table_tpl$)=1
					sql_prep$="select count (firm_id) from "+vectFiles!.getItem(curr_row * numcols + 3) + " where "
					sql_prep$=sql_prep$+"firm_id = '"+firm$+"'"
					sql_chan=sqlunt
					sqlopen(sql_chan,err=*next)stbl("+DBNAME")
					sqlprep(sql_chan)sql_prep$
					dim read_tpl$:sqltmpl(sql_chan)
					sqlexec(sql_chan)
					while 1
						read_tpl$=sqlfetch(sql_chan,err=*break)
						vectFiles!.setItem(curr_row * numcols + 5, str(read_tpl.col001))
						break
					wend
					sqlclose(sql_chan)
				endif
				open_tables$[1]=vectFiles!.getItem(curr_row * numcols + 3),open_opts$[1]="CX"
				gosub open_tables
			endif
		next curr_row
	endif

	SysGUI!.setRepaintEnabled(1)

	gosub fill_grid

	return
rem ==========================================================================
rem --- Functions
rem ==========================================================================

rem --- fn_filter_txt: Check Operator data for text fields

	def fn_filter_txt(q1$,q2$,q3$)
		ret_val=0
		switch num(q1$)
			case 1; if q2$<q3$ ret_val=1; endif; break
			case 2; if q2$=q3$ ret_val=1; endif; break
			case 3; if q2$>q3$ ret_val=1; endif; break
			case 4; if q2$<=q3$ ret_val=1; endif; break
			case 5; if q2$>=q3$ ret_val=1; endif; break
			case 6; if q2$<>q3$ ret_val=1; endif; break
		swend
		return ret_val
	fnend

rem ==========================================================================
#include std_missing_params.src
rem ==========================================================================
[[ADX_CLEARFIRM.AWIN]]
rem --- Open/Lock files

	use ::ado_util.src::util
	use ::ado_func.src::func

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="DDM_TABLES",open_opts$[1]="OTA"
	open_tables$[2]="ADM_MODULES",open_opts$[2]="OTA"

	gosub open_tables

	user_tpl_str$ = "gridFilesCols:c(5), " +
:		"gridFilesRows:c(5), " +
:		"gridFilesCtlID:c(5)," +
:		"MasterCols:n(5)"
	dim user_tpl$:user_tpl_str$

	UserObj! = BBjAPI().makeVector()
	vectFiles! = BBjAPI().makeVector()
	vectFilesMaster! = BBjAPI().makeVector()
	nxt_ctlID = num(stbl("+CUSTOM_CTL",err=std_error))
	ignore$ = stbl("+CUSTOM_CTL", str(nxt_ctlID+1))

	gridFiles! = Form!.addGrid(nxt_ctlID,5,140,800,300); rem --- ID, x, y, width, height

	user_tpl.gridFilesCtlID$ = str(nxt_ctlID)
	user_tpl.gridFilesCols$ = "7"
	user_tpl.gridFilesRows$ = "10"
	user_tpl.MasterCols = 8

	gosub format_grid
	util.resizeWindow(Form!, SysGui!)

	callpoint!.setDevObject("gridFiles",gridFiles!)
	callpoint!.setDevObject("vectFiles",vectFiles!)
	callpoint!.setDevObject("vectFilesMaster",vectFilesMaster!)

rem --- Misc other init

	gridFiles!.setColumnEditable(0,1)
	gridFiles!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)
	gridFiles!.setTabAction(gridFiles!.GRID_NAVIGATE_GRID)

	gosub checkout_licenses
	gosub create_reports_vector
	gosub fill_grid

rem --- Set callbacks - processed in ACUS callpoint

	gridFiles!.setCallback(gridFiles!.ON_GRID_KEY_PRESS,"custom_event")
	gridFiles!.setCallback(gridFiles!.ON_GRID_MOUSE_UP,"custom_event")
	gridFiles!.setCallback(gridFiles!.ON_GRID_EDIT_STOP,"custom_event")

	callpoint!.setOptionEnabled("CLRF",0)
