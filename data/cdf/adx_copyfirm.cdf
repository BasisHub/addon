[[ADX_COPYFIRM.FILES_TO_COPY.AINP]]
rem --- Skip if files_to_copy hasn't changed
	files_to_copy$=callpoint!.getUserInput()
	if files_to_copy$=callpoint!.getColumnData("ADX_COPYFIRM.FILES_TO_COPY") then break

rem --- Update checked/uncheck grid rows
	callpoint!.setColumnData("ADX_COPYFIRM.FILES_TO_COPY",files_to_copy$,1)
	gosub fill_grid
[[ADX_COPYFIRM.UPDT_REC_COUNT.AINP]]
rem --- Skip if files_to_copy hasn't changed
	updt_rec_count$=callpoint!.getUserInput()
	if updt_rec_count$=callpoint!.getColumnData("ADX_COPYFIRM.UPDT_REC_COUNT") then break

rem --- Get record counts for from firm
	firm$=cvs(callpoint!.getColumnData("ADX_COPYFIRM.FIRM_ID_ENTRY"),3)	
	gosub set_firm_recs
	callpoint!.setColumnData("ADX_COPYFIRM.UPDT_REC_COUNT",updt_rec_count$,1)
	gosub fill_grid
[[ADX_COPYFIRM.AREC]]
rem --- Initializations
	rem --- Set asc_comp_id and files_to_copy
	callpoint!.setColumnData("ADX_COPYFIRM.ASC_COMP_ID","01007514")
	callpoint!.setColumnData("ADX_COPYFIRM.FILES_TO_COPY","T")
	callpoint!.setColumnEnabled("ADX_COPYFIRM.FILES_TO_COPY",1)

	rem --- Set updt_rec_count
	callpoint!.setColumnData("ADX_COPYFIRM.UPDT_REC_COUNT","Y")
[[ADX_COPYFIRM.ASIZ]]
rem --- resize grid
	gridFiles!=callpoint!.getDevObject("gridFiles")
	gridFiles!.setSize(Form!.getWidth()-(gridFiles!.getX()*2),Form!.getHeight()-(gridFiles!.getY()+40))
	gridFiles!.setFitToGrid(1)
	callpoint!.setDevObject("gridFiles",gridFiles!)
[[ADX_COPYFIRM.ASVA]]
rem --- Confirm ready to copy data
	numSelected=0
	vectFiles!=callpoint!.getDevObject("vectFiles")
	if vectFiles!.size() > 0 then
		numcols = num(user_tpl.gridFilesCols$)
		for curr_row=0 to vectFiles!.size()/(numcols)-1
			if vectFiles!.getItem(curr_row*numcols)="Y"
				numSelected=numSelected+1
			endif
		next curr_row
	endif
	from_firm$=callpoint!.getColumnData("ADX_COPYFIRM.FIRM_ID_ENTRY")
	to_firm$=callpoint!.getColumnData("ADX_COPYFIRM.TO_FIRM_ID")

	if numSelected and cvs(from_firm$,2)<>"" and cvs(to_firm$,2)<>"" then
		dim msg_tokens$[2]
		msg_tokens$[1]=from_firm$
		msg_tokens$[2]=to_firm$
		msg_id$="AD_COPY_FIRM_CONF"
		gosub disp_message
		if msg_opt$<>"Y"then
			callpoint!.setStatus("ABORT")
			break
		endif
	else
		msg_id$="AD_NO_SELECTION"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Copy selected data
	if numSelected then
		rem --- Start progress meter
		meter_title$=Form!.getTitle()
		meter_total_recs=numSelected
		meter_proc_recs=0
		table_alias$=""
		meter_action$="WIN-LST-OK"
		gosub disp_meter

		rem --- Flip directory path separators
		filePath$=stbl("+DIR_DAT")
		gosub fix_path
		dataDir$=filePath$

		rem --- Get aon directory location from aon/data path
		aonDir$=dataDir$(1, pos("/data"=dataDir$,-1)-1)

		rem --- Create logs directory under aon directory
		logpath$=aonDir$+"/logs"
            	FileObject.makeDirs(new File(logpath$))

            	rem --- create and open log file
            	log$ = logpath$+"/copyfirmtofirm_"+DATE(0:"%Yd%Mz%Dz")+"_"+DATE(0:"%Hz%mz")+".txt"
		erase log$,err=*next
		string log$
            	log_dev=unt
		open (log_dev)log$
            
		rem --- write log header info
		print (log_dev)"copyfirmtofirm log started: " + date(0:"%Yd-%Mz-%Dz@%Hz:%mz:%sz")
		print (log_dev)"Started by: "+stbl("+USER_ID")
		print (log_dev)"Company ID: "+callpoint!.getColumnData("ADX_COPYFIRM.ASC_COMP_ID")
		print (log_dev)"Product ID: "+callpoint!.getColumnData("ADX_COPYFIRM.ASC_PROD_ID")
		print (log_dev)"From Firm ID: "+from_firm$
		print (log_dev)"To Firm ID: "+to_firm$
		if callpoint!.getColumnData("ADX_COPYFIRM.FILES_TO_COPY")="A" then
			print (log_dev)"Copy all files"
		else
			print (log_dev)"Copy all files except transaction files"
		endif
		print (log_dev)

            
		rem --- Use bax_mount_sel to get rdMountVect! containing hashes of mounted system and backup directory info for use in bax_xmlrec_exp.bbj
		exp_add_only$=""
		dev_mode$=""
		call stbl("+DIR_SYP")+"bax_mount_sel.bbj",rdMountVect!,table_chans$[all],dev_mode$

		rem --- Process selected files
		sql_chan=sqlunt
		sqlopen(sql_chan,err=*endif)stbl("+DBNAME")
		numcols = num(user_tpl.gridFilesCols$)
		for curr_row=0 to vectFiles!.size()/(numcols)-1
			rem --- Increment progress meter
			meter_data$=cvs(vectFiles!.getItem(curr_row * numcols + 3),2)
			table_alias$=meter_data$
			meter_proc_recs=meter_proc_recs+1
			meter_action$="MTR-LST"
			gosub disp_meter

			if vectFiles!.getItem(curr_row*numcols)="Y"
				num_files=2
				dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
				open_tables$[1]=vectFiles!.getItem(curr_row * numcols + 3)
				open_tables$[2]=vectFiles!.getItem(curr_row * numcols + 3)
				open_opts$[1]="OTASN"
				open_opts$[2]="OTASN"
				gosub open_tables
				from_table_dev=num(open_chans$[1])
				to_table_dev=num(open_chans$[2])
				table_tpl$=open_tpls$[1]

				rem --- Update log w/ file name and number of recs in file
				from_recs$="?"
				sql_prep$="select count (firm_id) from "+vectFiles!.getItem(curr_row * numcols + 3) + " where "
				sql_prep$=sql_prep$+"firm_id = '"+from_firm$+"'"
				if 1 then
					sqlprep(sql_chan,err=*endif)sql_prep$
					dim read_tpl$:sqltmpl(sql_chan)
					sqlexec(sql_chan,err=*endif)
					read_tpl$=sqlfetch(sql_chan,err=*endif)
					from_recs$=str(read_tpl.col001)
				endif
				print (log_dev)"File: "+table_alias$+"("+open_tables$[1]+")"
				print (log_dev)"Firm "+from_firm$+" records in file: "+from_recs$

				rem --- Now copy the records
				if pos("firm_id:c"=table_tpl$)>0
					tot_recs_copied=0
					read(from_table_dev,key=from_firm$,dom=*next)
					while 1
						rem --- Read from record
						dim rec_tpl$:table_tpl$
						readrecord (from_table_dev,end=*break)rec_tpl$
						if rec_tpl.firm_id$ <> from_firm$ break
						rec_tpl.firm_id$ = to_firm$

						rem --- Create admin_backup records for admin data (adm_firms, ads_masks and ads_sequences) changes
						if table_alias$="ADM_FIRMS" or table_alias$="ADS_MASKS" or table_alias$="ADS_SEQUENCES" then
							if pos(newFirm$="0102",2) then
								rec_tpl.user_modified$="M"
							else
								rec_tpl.user_modified$="A"
							endif
							exp_action$=rec_tpl.user_modified$
							call stbl("+DIR_SYP")+"bax_xmlrec_exp.bbj",table_alias$,rec_tpl$,exp_action$,exp_add_only$,dev_mode$,rdMountVect!,table_chans$[all]
						endif

						rem --- Write to record
						writerecord (to_table_dev)rec_tpl$
						tot_recs_copied=tot_recs_copied+1
					wend
					rem --- Close the from and to files
					num_files=1
					dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
					open_tables$[1]=vectFiles!.getItem(curr_row * numcols + 3)
					open_opts$[1]="CX"
					gosub open_tables
					print (log_dev)"Records copied to firm "+to_firm$+": "+str(tot_recs_copied)
					print (log_dev)
				endif
			else
				print (log_dev)"Table "+table_alias$+" skipped"
				print (log_dev)
			endif
		next curr_row
		sqlclose(sql_chan,err=*next)

		print (log_dev)"Copyfirmtofirm log finished: " + date(0:"%Yd-%Mz-%Dz@%Hz:%mz:%sz")
		close (log_dev)

		rem --- Stop progress meter
		meter_data$=""
		meter_proc_recs=meter_total_recs
		meter_action$="LST-END"
		gosub disp_meter
	endif
[[ADX_COPYFIRM.TO_FIRM_ID.AVAL]]
rem --- Skip if to_firm_id hasn't changed
	to_firm_id$=callpoint!.getUserInput()
	if to_firm_id$=callpoint!.getColumnData("ADX_COPYFIRM.TO_FIRM_ID") then break

rem --- Firms 99 and ZZ not allowed for to_firm_id
	if pos(to_firm_id$="99ZZ",2) then
		dim msg_tokens$[1]
		msg_tokens$[1]=to_firm_id$
		msg_id$="AD_FIRM_ID_BAD"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Make sure 2 firms aren't the same
	from_firm$=callpoint!.getColumnData("ADX_COPYFIRM.FIRM_ID_ENTRY")
	to_firm$=callpoint!.getUserInput()
	if cvs(to_firm$,2)<>"" then 
		gosub check_firms
		if from_firm$=to_firm$
			callpoint!.setStatus("ABORT")
			break
		endif
	endif
[[ADX_COPYFIRM.FIRM_ID_ENTRY.AVAL]]
rem --- Skip if firm_id_entry hasn't changed
	from_firm$=callpoint!.getUserInput()
	if from_firm$=callpoint!.getColumnData("ADX_COPYFIRM.FIRM_ID_ENTRY") then break

rem --- Firm ZZ not allowed for firm_id_entry
	if pos(from_firm$="ZZ",2) then
		dim msg_tokens$[1]
		msg_tokens$[1]=from_firm$
		msg_id$="AD_FIRM_ID_BAD"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Make sure 2 firms aren't the same
	to_firm$=callpoint!.getColumnData("ADX_COPYFIRM.TO_FIRM_ID")
	if cvs(to_firm$,2)<>"" then 
		gosub check_firms
		if from_firm$=to_firm$
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

rem --- Set number of recs for firm selected
	updt_rec_count$=callpoint!.getColumnData("ADX_COPYFIRM.UPDT_REC_COUNT")
	if updt_rec_count$="Y"
		firm$=callpoint!.getUserInput()
		gosub set_firm_recs
		gosub fill_grid
	endif
[[ADX_COPYFIRM.ASC_PROD_ID.AVAL]]
rem --- Skip if asc_prod_id hasn't changed
	asc_prod_id$=callpoint!.getUserInput()
	if asc_prod_id$=callpoint!.getColumnData("ADX_COPYFIRM.ASC_PROD_ID") then break

rem --- Set Filter and update grid
	gosub filter_recs
	updt_rec_count$=callpoint!.getColumnData("ADX_COPYFIRM.UPDT_REC_COUNT")
	firm$=cvs(callpoint!.getColumnData("ADX_COPYFIRM.FIRM_ID_ENTRY"),3)
	gosub set_firm_recs
	gosub fill_grid
[[ADX_COPYFIRM.ASC_COMP_ID.AVAL]]
rem --- Skip if asc_comp_id hasn't changed
	asc_comp_id$=callpoint!.getUserInput()
	if asc_comp_id$=callpoint!.getColumnData("ADX_COPYFIRM.ASC_COMP_ID") then break

rem --- Disable and clear asc_prod_id unless asc_comp_id was entered
	if cvs(asc_comp_id$,2)="" then
		callpoint!.setColumnData("ADX_COPYFIRM.ASC_PROD_ID","",1)
		callpoint!.setColumnEnabled("ADX_COPYFIRM.ASC_PROD_ID",0)
	else
		callpoint!.setColumnEnabled("ADX_COPYFIRM.ASC_PROD_ID",1)
	endif

rem --- Initialize files_to_copy
	if asc_comp_id$="01007514" then
		callpoint!.setColumnData("ADX_COPYFIRM.FILES_TO_COPY","T",1)
		callpoint!.setColumnEnabled("ADX_COPYFIRM.FILES_TO_COPY",1)
	else
		callpoint!.setColumnData("ADX_COPYFIRM.FILES_TO_COPY","A",1)
		callpoint!.setColumnEnabled("ADX_COPYFIRM.FILES_TO_COPY",0)
	endif

rem --- Set Filter and update grid
	gosub filter_recs
	updt_rec_count$=callpoint!.getColumnData("ADX_COPYFIRM.UPDT_REC_COUNT")
	firm$=cvs(callpoint!.getColumnData("ADX_COPYFIRM.FIRM_ID_ENTRY"),3)
	gosub set_firm_recs
	gosub fill_grid
[[ADX_COPYFIRM.ACUS]]
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
	curr_row = dec(notice.row$)
	curr_col = dec(notice.col$)

	rem --- Do NOT allow selecting aps_report and ars_report tables in grid
	if cvs(gridFiles!.getCellText(curr_row,1),2)<>"01007514" or cvs(gridFiles!.getCellText(curr_row,2),2)<>"AD" or 
:	pos(":"+cvs(gridFiles!.getCellText(curr_row,3),2)+":"=":APS_REPORT:ARS_REPORT:")=0  then
		switch notice.code
			case 12; rem --- grid_key_press
				if notice.wparam=32 gosub switch_value
				break

			case 14; rem --- grid_mouse_up
				if notice.col=0 gosub switch_value
				break
		swend
	endif
[[ADX_COPYFIRM.<CUSTOM>]]
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
	attr_inv_col$[6,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Records to copy"
	attr_inv_col$[6,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_inv_col$[6,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[6,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]="##,###,##0"

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
	vectFilesMaster! = callpoint!.getDevObject("vectFilesMaster")

	if vectFiles!.size() then
		numrow = vectFiles!.size() / gridFiles!.getNumColumns()
		gridFiles!.clearMainGrid()
		gridFiles!.setColumnStyle(0,SysGUI!.GRID_STYLE_UNCHECKED)
		gridFiles!.setNumRows(numrow)
		gridFiles!.setCellText(0,0,vectFiles!)

		rem --- Check/uncheck grid rows
		for wk=0 to vectFiles!.size()-1 step gridFiles!.getNumColumns()
			row=wk/gridFiles!.getNumColumns()
			gridFiles!.setCellText(row, 0, "")

			if cvs(vectFiles!.getItem(wk+1),2)="01007514" and cvs(vectFiles!.getItem(wk+2),2)="AD" and 
:			pos(":"+cvs(vectFiles!.getItem(wk+3),2)+":"=":APS_REPORT:ARS_REPORT:")  then
				rem --- Do NOT allow selecting Addon's aps_report and ars_report tables in grid
				gridFiles!.setCellStyle(row, 0, SysGUI!.GRID_STYLE_UNCHECKED)
				gridFiles!.setRowBackColor(row,callpoint!.getDevObject("notEditableColor"))
				vectFiles!.setItem(wk, "N")
				vectFilesMaster!.setItem(row*user_tpl.MasterCols+1, "N")
			else
				gridFiles!.setRowBackColor(row,callpoint!.getDevObject("editableColor"))
				if vectFiles!.getItem(wk) = "Y" then 
					gridFiles!.setCellStyle(row, 0, SysGUI!.GRID_STYLE_CHECKED)
				else
					gridFiles!.setCellStyle(row, 0, SysGUI!.GRID_STYLE_UNCHECKED)
				endif

				rem --- Some Addon tables get special handling 
				if cvs(vectFiles!.getItem(wk+1),2)="01007514" then
					rem --- Initialize Addon work tables unchecked
					if pos("W_"=vectFiles!.getItem(wk+3))=3 then
						gridFiles!.setCellStyle(row, 0, SysGUI!.GRID_STYLE_UNCHECKED)
						vectFiles!.setItem(wk, "N")
						vectFilesMaster!.setItem(row*user_tpl.MasterCols+1, "N")
					endif

					rem --- Initialize Addon entry and history tables unchecked when transactions are excluded
					if pos("E_"=vectFiles!.getItem(wk+3))=3  or pos("T_"=vectFiles!.getItem(wk+3))=3 then
						if callpoint!.getColumnData("ADX_COPYFIRM.FILES_TO_COPY")="T" then
							gridFiles!.setCellStyle(row, 0, SysGUI!.GRID_STYLE_UNCHECKED)
							vectFiles!.setItem(wk, "N")
							vectFilesMaster!.setItem(row*user_tpl.MasterCols+1, "N")
						else
							gridFiles!.setCellStyle(row, 0, SysGUI!.GRID_STYLE_CHECKED)
							vectFiles!.setItem(wk, "Y")
							vectFilesMaster!.setItem(row*user_tpl.MasterCols+1, "Y")
						endif
					endif
				endif
			endif
		next wk

		gridFiles!.resort()
	else
		gridFiles!.clearMainGrid()
		gridFiles!.setColumnStyle(0, SysGUI!.GRID_STYLE_UNCHECKED)
		gridFiles!.setNumRows(0)
	endif

	callpoint!.setDevObject("gridFiles",gridFiles!)
	callpoint!.setDevObject("vectFiles",vectFiles!)
	callpoint!.setDevObject("vectFilesMaster",vectFilesMaster!)
	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
create_reports_vector: rem --- Create a vector from ddm_table to fill the grid
rem ==========================================================================

	modules$=callpoint!.getDevObject("modules")

	ddm_tables_dev=fnget_dev("DDM_TABLES")
	dim ddm_tables$:fnget_tpl$("DDM_TABLES")
	read (ddm_tables_dev,key="",dom=*next)
	while 1
		read record (ddm_tables_dev, end=*break) ddm_tables$
			rem --- Now fill vectors
			rem --- Items 1 thru n+1 in vectFilesMaster! must equal items 0 thru n in vectFiles!

		if pos(ddm_tables.dd_alias_type$="MXVSD")>0 and pos(ddm_tables.asc_prod_id$=modules$,3) > 0 then
			if ddm_tables.asc_prod_id$ <> "ADB" or
:				(ddm_tables.asc_prod_id$="ADB" and
:				 (cvs(ddm_tables.dd_table_alias$,2)="ADS_MASKS" or
:				 cvs(ddm_tables.dd_table_alias$,2)="ADS_SEQUENCES"))

				rem --- Skip files that haven't been created yet
				tablePath$=cvs(ddm_tables.dd_table_path$,3)
				if pos("["=tablePath$)=1 then
					rem --- Using stbl for path
					tablePath$=tablePath$(2)
					tablePath$=tablePath$(1,len(tablePath$)-1)
					dataDir$=stbl(tablePath$)
				else
					dataDir$=tablePath$
				endif
				if pos(dataDir$="\/")=0 and pos(":"=dataDir$)<>2 then
					rem --- Relative path
					dataDir$=dir("")+dataDir$
				endif
				dataFile$=cvs(ddm_tables.dd_file_name$,2)
				if cvs(dataFile$,2)="" then dataFile$=cvs(dataFile$,10)
				thisFile!=new File(dataDir$+dataFile$,err=*continue)
				if !thisFile!.exists() then continue

				rem --- Filter on asc_comp_id set in AREC
				if ddm_tables.asc_comp_id$="01007514" then
					vectFiles!.addItem("Y"); rem 0 - Selected Y or N
					vectFiles!.addItem(ddm_tables.asc_comp_id$);rem 1
					vectFiles!.addItem(ddm_tables.asc_prod_id$);rem 2
					vectFiles!.addItem(ddm_tables.dd_table_alias$); rem 3
					vectFiles!.addItem(ddm_tables.dd_alias_desc$); rem 4
					vectFiles!.addItem(""); rem 5 - Number of records to copy
				endif

				rem --- Filter on asc_comp_id set in AREC
				if ddm_tables.asc_comp_id$="01007514" then
					vectFilesMaster!.addItem("Y"); rem 0 - Filtered Yes
				else
					vectFilesMaster!.addItem("N"); rem 0 - Filtered N0
				endif
				vectFilesMaster!.addItem("Y"); rem 1 - Selected Y or N
				vectFilesMaster!.addItem(ddm_tables.asc_comp_id$);rem 2
				vectFilesMaster!.addItem(ddm_tables.asc_prod_id$); rem 3
				vectFilesMaster!.addItem(ddm_tables.dd_table_alias$); rem 4
				vectFilesMaster!.addItem(ddm_tables.dd_alias_desc$); rem 5
				vectFilesMaster!.addItem(""); rem 6 - Number of records to copy
			endif
		endif
	wend

	callpoint!.setDevObject("vectFiles",vectFiles!)
	callpoint!.setDevObject("vectFilesMaster",vectFilesMaster!)
	callpoint!.setStatus("REFRESH")
	
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

			if gridFiles!.getCellState(row_no,0) = 0 then 
				rem --- Not checked -> checked
				gridFiles!.setCellState(row_no,0,1)
				vectFiles!.setItem(row_no * numcols, "Y")
				vectFilesMaster!.setItem(row_no*user_tpl.MasterCols+1, "Y")
			else
				rem --- Checked -> not checked
				gridFiles!.setCellState(row_no,0,0)
				vectFiles!.setItem(row_no * numcols, "N")
				vectFilesMaster!.setItem(row_no*user_tpl.MasterCols+1, "N")
			endif
		next curr_row
	endif

	callpoint!.setDevObject("gridFiles",gridFiles!)
	callpoint!.setDevObject("vectFiles",vectFiles!)
	callpoint!.setDevObject("vectFilesMaster",vectFilesMaster!)
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

		if callpoint!.getVariableName()="ADX_COPYFIRM.ASC_COMP_ID"
			filter_comp_id$=callpoint!.getUserInput()
			filter_prod_id$=callpoint!.getColumnData("ADX_COPYFIRM.ASC_PROD_ID")
		else
			if callpoint!.getVariableName()="ADX_COPYFIRM.ASC_PROD_ID"
				filter_comp_id$=callpoint!.getColumnData("ADX_COPYFIRM.ASC_COMP_ID")
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

		callpoint!.setDevObject("vectFilesMaster",vectFilesMaster!)
		callpoint!.setDevObject("vectFiles",vectFiles!)
		gosub fill_grid
	endif

	return

rem ==========================================================================
set_firm_recs:
rem --- in: firm$
rem --- in: updt_rec_count$
rem ==========================================================================

	if cvs(firm$,2)="" then return

	SysGUI!.setRepaintEnabled(0)
	vectFiles! = callpoint!.getDevObject("vectFiles")

	TempRows! = vectFiles!
	numcols   = num(user_tpl.gridFilesCols$)
	ddm_table_dev=fnget_dev("DDM_TABLES")

	call pgmdir$+"adc_progress.aon","NC","","Processing...","","",0,ddm_table_dev,1,meter_num,status

	if TempRows!.size() > 0 then
		sql_chan=sqlunt
		sqlopen(sql_chan,err=*endif)stbl("+DBNAME")
		for curr_row=0 to TempRows!.size()/(num(user_tpl.gridFilesCols$))-1
			call pgmdir$+"adc_progress.aon","S","","","","",0,curr_row,1,meter_num,status
			if updt_rec_count$="Y" then
				rem --- Update record count
				sql_prep$="select count (firm_id) from "+vectFiles!.getItem(curr_row * numcols + 3) + " where "
				sql_prep$=sql_prep$+"firm_id = '"+firm$+"'"
				sqlprep(sql_chan,err=*continue)sql_prep$
				dim read_tpl$:sqltmpl(sql_chan)
				sqlexec(sql_chan,err=*continue)
				while 1
					read_tpl$=sqlfetch(sql_chan,err=*break)
					vectFiles!.setItem(curr_row * numcols + 5, str(read_tpl.col001))
					break
				wend
			else
				rem --- Clear existing record count
				vectFiles!.setItem(curr_row * numcols + 5, "")
			endif
		next curr_row
		sqlclose(sql_chan,err=*next)
	endif

	callpoint!.setDevObject("vectFiles",vectFiles!)
	SysGUI!.setRepaintEnabled(1)
	call pgmdir$+"adc_progress.aon","D","","","","",0,0,0,meter_num,status

	return

rem ==========================================================================
check_firms:
rem IN: from_firm$
rem IN: to_firm$
rem ==========================================================================

	if from_firm$=to_firm$
		dim msg_tokens$[2]
		msg_tokens$[0]=from_firm$
		msg_tokens$[1]=to_firm$
		msg_id$ = "ADMIN_COPY_FIRM_SAME"
		gosub disp_message
	endif

	return

rem ==========================================================================
fix_path: rem --- Flip directory path separators
rem IN: filePath$
rem OUT: filePath$
rem ==========================================================================

	pos=pos("\"=filePath$)
	while pos
		filePath$=filePath$(1, pos-1)+"/"+filePath$(pos+1)
	pos=pos("\"=filePath$)
	wend

	return

rem ==========================================================================
get_RGB: rem --- Parse Red, Green and Blue segments from RGB$ string
	rem --- input: RGB$
	rem --- output: R
	rem --- output: G
	rem --- output: B
rem ==========================================================================
	comma1=pos(","=RGB$,1,1)
	comma2=pos(","=RGB$,1,2)
	R=num(RGB$(1,comma1-1))
	G=num(RGB$(comma1+1,comma2-comma1-1))
	B=num(RGB$(comma2+1))

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
[[ADX_COPYFIRM.AWIN]]
rem --- Open/Lock files

	use java.io.File
    	use ::ado_file.src::FileObject
	use ::ado_func.src::func
	use ::ado_util.src::util

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

	tmpCtl!=callpoint!.getControl("UPDT_REC_COUNT")
	tmp_y=tmpCtl!.getY()
	tmp_h=tmpCtl!.getHeight()
	wnd_w=Form!.getWidth()
	wnd_h=Form!.getHeight()

	gridFiles! = Form!.addGrid(nxt_ctlID,5,tmp_y+tmp_h+10,wnd_w-5,wnd_h-tmp_y-tmp_h-5); rem --- ID, x, y, width, height

	user_tpl.gridFilesCtlID$ = str(nxt_ctlID)
	user_tpl.gridFilesCols$ = "6"
	user_tpl.gridFilesRows$ = "10"
	user_tpl.MasterCols = 7

	gosub format_grid

	callpoint!.setDevObject("gridFiles",gridFiles!)
	callpoint!.setDevObject("vectFiles",vectFiles!)
	callpoint!.setDevObject("vectFilesMaster",vectFilesMaster!)

	rem --- Set background color for editable grid rows
	RGB$="255,255,255"
	gosub get_RGB
	callpoint!.setDevObject("editableColor",BBjAPI().getSysGui().makeColor(R,G,B))

	rem --- Set background color for not editable grid rows
	RGB$="231,236,255"
	RGB$=stbl("+GRID_NONEDIT_COLOR",err=*next)
	gosub get_RGB
	callpoint!.setDevObject("notEditableColor",BBjAPI().getSysGui().makeColor(R,G,B))

rem --- Misc other init

	gridFiles!.setColumnEditable(0,1)
	gridFiles!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)
	gridFiles!.setTabAction(gridFiles!.GRID_NAVIGATE_GRID)

	gosub checkout_licenses
	gosub create_reports_vector
	callpoint!.setColumnData("ADX_COPYFIRM.FILES_TO_COPY","T")
	gosub fill_grid

rem --- Set callbacks - processed in ACUS callpoint

	gridFiles!.setCallback(gridFiles!.ON_GRID_KEY_PRESS,"custom_event")
	gridFiles!.setCallback(gridFiles!.ON_GRID_MOUSE_UP,"custom_event")
	gridFiles!.setCallback(gridFiles!.ON_GRID_EDIT_STOP,"custom_event")
	callpoint!.setDevObject("gridFiles",gridFiles!)
