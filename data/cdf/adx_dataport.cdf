[[ADX_DATAPORT.ASIZ]]
rem --- resize grid if window size changes

	gridFiles!=callpoint!.getDevObject("gridFiles")
	if gridFiles!<>null()
		gridFiles!.setColumnWidth(0,25)
		gridFiles!.setSize(Form!.getWidth()-(gridFiles!.getX()*2),Form!.getHeight()-(gridFiles!.getY()+40))
		gridFiles!.setFitToGrid(1)
	endif
[[ADX_DATAPORT.ACUS]]
rem process custom event -- used in this pgm to select/de-select checkboxes in grid
rem see basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info
rem this routine is executed when callbacks have been set to run a "custom event"
rem analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind
rem of event it is... in this case, we're toggling checkboxes on/off in form grid control

dim gui_event$:tmpl(gui_dev)
dim notify_base$:noticetpl(0,0)
gui_event$=SysGUI!.getLastEventString()
ctl_ID=dec(gui_event.ID$)

if ctl_ID=num(callpoint!.getDevObject("grid_ctlID"))
	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
	endif

	switch notice.code
		case 12;rem grid_key_press
			if notice.wparam=32 gosub switch_value
		break
		case 14;rem grid_mouse_up
			if notice.col=0 gosub switch_value
		break
	swend
endif
[[ADX_DATAPORT.AOPT-SCAN]]
scan_source:rem --- Scan Source Directory and build vectors to populate gridFiles!

	source_dir$=callpoint!.getColumnData("ADX_DATAPORT.SOURCE_DIR")
	if cvs(source_dir$,3)=""
		callpoint!.setOptionEnabled("SCAN",0)
		break
	endif
	if pos(source_dir$(len(source_dir$),1)="\/")=0 then
		source_dir$=source_dir$+"/"
	endif

	ddm03_dev=unt
	if num(callpoint!.getColumnData("ADX_DATAPORT.ADDON_VERSION"))=6
		open(ddm03_dev)callpoint!.getColumnData("ADX_DATAPORT.SOURCE_DIR")+"/DDM-03"
	else
		open(ddm03_dev)callpoint!.getColumnData("ADX_DATAPORT.SOURCE_DIR")+"/ddm-03"
	endif

	source_dir_dev=unt
  	open(source_dir_dev)callpoint!.getColumnData("ADX_DATAPORT.SOURCE_DIR")

 	gridVect!=SysGUI!.makeVector()
	recs_found=0

	type_str$=""
	typeVect!=SysGUI!.makeVector()
	dir_files$=""
	indent$="   "

	while 1
		readrecord(source_dir_dev,end=*break)dir_file$
		if pos("."=dir_file$)=1 then continue
		if pos("_"=dir_file$)=1 then continue
		if pos("DD"=cvs(dir_file$,4))=1 then continue
		if pos("W-"=cvs(dir_file$,4))=3 then continue
		if pos("SH"=cvs(dir_file$,4))=1 then continue
		if pos("Z"=cvs(dir_file$,4))=1 then continue
		if len(cvs(dir_file$,3))>6 then continue
		if pos("WOX-"=cvs(dir_file$,4))=1 then continue
		if cvs(dir_file$,4)="SYM-09" then continue
		if cvs(dir_file$,4)="SYM-19" then continue
		if cvs(dir_file$,4)="SYM-39" then continue
		if cvs(dir_file$,4)="SYM-49" then continue
		if cvs(dir_file$,4)="GLM-18" then continue
		if cvs(dir_file$,4)="GLW-11" then continue
		if cvs(dir_file$,4)="PRX-10" then continue
		dir_files$=dir_files$+pad(dir_file$,6)
	wend

	dir_files$=ssort(dir_files$,6)
    
	if len(dir_files$)<>0
    
		for xwk=1 to len(dir_files$) step 6
			dir_file$=dir_files$(xwk,6)
			recid_str$=""
			read(ddm03_dev,key=dir_file$,dom=*next,err=*continue)
			while 1
				ddm03_dev_key$=key(ddm03_dev,end=*break)
				if pos(dir_file$=ddm03_dev_key$)<>1 then break
				read(ddm03_dev)ddm03_dev_00$,ddm03_dev_01$
				gridVect!.addItem("")
				if ddm03_dev_key$(7,1)="A" or ddm03_dev_key$(1,6)<>cvs(gridVect!.getItem(gridVect!.size()-4),3) then
					gridVect!.addItem(ddm03_dev_00$(1,6))
				else
					gridVect!.addItem(indent$+ddm03_dev_00$(1,6))
				endif
				gridVect!.addItem(ddm03_dev_00$(7,1))
				gridVect!.addItem(ddm03_dev_01$(1,30))
				recs_found=recs_found+1
				if ddm03_dev_key$(7,1)<>"A" and ddm03_dev_key$(1,6)=cvs(gridVect!.getItem(gridVect!.size()-7),3) then
					if recid_str$="" then
						recid_str$=recid_str$+ddm03_dev_key$(1,7)+":"+str(recs_found-1:"0000")
						gridVect!.insertItem(gridVect!.size()-8,"")
						gridVect!.insertItem(gridVect!.size()-8,ddm03_dev_00$(1,6))
						gridVect!.insertItem(gridVect!.size()-8,"")
						gridVect!.insertItem(gridVect!.size()-8,Translate!.getTranslation("AON_MULTIPLE_RECORD_TYPES"))
						gridVect!.setItem(gridVect!.size()-7,indent$+ddm03_dev_00$(1,6))
						recs_found=recs_found+1
					endif
					recid_str$=recid_str$+ddm03_dev_key$(1,7)+":"+str(recs_found:"0000")
				endif
			wend
			if recid_str$<>"" then
				type_str$=type_str$+recid_str$(1,6)
				typeVect!.addItem(recid_str$)
			endif
		next xwk
    
	endif

	SysGUI!.setRepaintEnabled(0)
	gridFiles!=callpoint!.getDevObject("gridFiles")
	gridFiles!.setNumRows(0)
	gridFiles!.setNumRows(recs_found)
	gridFiles!.setCellText(0,0,gridVect!)

	for curr_row=1 to recs_found
		if pos(indent$=gridFiles!.getCellText(curr_row-1,1))=1 then
		gridFiles!.setCellStyle(curr_row-1,0,gridFiles!.GRID_STYLE_INPUTE)
		gridFiles!.setRowForeColor(curr_row-1,callpoint!.getDevObject("indent_color"))
	endif
	next curr_row

	SysGUI!.setRepaintEnabled(1)

	gridFiles!.deselectAllCells()
	gridVect!.clear()

	gridFiles!.focus()

	close (ddm03_dev)
	close (source_dir_dev)
[[ADX_DATAPORT.TARGET_DIR.AVAL]]
rem --- make sure target directory exists

	gosub check_target_dir

	if !num(callpoint!.getDevObject("target_ok")) 
		msg_id$="AD_DATAPORT_DIR"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[ADX_DATAPORT.SOURCE_DIR.AVAL]]
rem --- make sure source directory exists, and contains legacy data dictionary files

	gosub check_source_dir

  	if num(callpoint!.getDevObject("source_ok"))
		callpoint!.setOptionEnabled("SCAN",1)
 
	else
		gridVect!=SysGUI!.makeVector()
		typeVect!=SysGUI!.makeVector()
		gridFiles!=callpoint!.getDevObject("gridFiles")
		gridFiles!.clearMainGrid()
		gridFiles!.setNumRows(0)
		msg_id$="AD_DATAPORT_DICT"
		gosub disp_message
		callpoint!.setOptionEnabled("SCAN",0)
		callpoint!.setStatus("ABORT")
	endif
[[ADX_DATAPORT.ASVA]]
rem --- confirm ready to port selected files?

	gridFiles!=callpoint!.getDevObject("gridFiles")

	if gridFiles!.getNumRows()=0 or (num(callpoint!.getDevObject("source_ok"))+num(callpoint!.getDevObject("target_ok"))<>2)
		callpoint!.setStatus("ABORT")
	else
		source_version$=callpoint!.getColumnData("ADX_DATAPORT.ADDON_VERSION")
		version_cvs = iff(source_version$="6",4,8)
		selected_files!=new java.util.HashMap()
		for curr_row=1 to gridFiles!.getNumRows()
			if gridFiles!.getCellState(curr_row-1,0)=1 then
				file_name$=cvs(gridFiles!.getCellText(curr_row-1,1),3+version_cvs)
				selected_files!.put(file_name$,file_name$)
			endif
		next curr_row
		msg_id$="AD_DATAPORT_CONF"
		gosub disp_message
		if msg_opt$="Y" and selected_files!.size()<>0
			callpoint!.setDevObject("source_version",source_version$)
			callpoint!.setDevObject("source_folder",callpoint!.getColumnData("ADX_DATAPORT.SOURCE_DIR"))
			callpoint!.setDevObject("destin_folder",callpoint!.getColumnData("ADX_DATAPORT.TARGET_DIR"))
    
			rem --- Locate aon/data directory, if possible
			num_files=1
			dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
			open_tables$[1]="DDM_SYSTEMS",open_opts$[1]="OTA"
			gosub open_tables
			ddm_systems=num(open_chans$[1]);dim ddm_systems$:open_tpls$[1]
    
			aonDir$=""
			readrecord(ddm_systems,key=pad("ADDON",16," "),knum="SYSTEM_ID",err=*next)ddm_systems$
			if cvs(ddm_systems.mount_dir$,2)<>"" then
				aonDir$=ddm_systems.mount_dir$
			endif

			rem --- Auto-select all files in a config/adx_conversionCtrl.ini dependency group when any in the group is selected
			convCtrlIniFileName$=aonDir$+"config/adx_conversionCtrl.ini"
			convCtrlIniFile!=new File(convCtrlIniFileName$,err=*next)
			if convCtrlIniFile!.exists() then
				fileReader!=new FileReader(convCtrlIniFile!)
				convCtrl!=new Properties()
				convCtrl!.load(fileReader!)
				fileReader!.close()

				rem --- Build cross reference between current file names and old file names
				file_xref!=new HashMap()
				dim file_xref$:"old_filename:c(16*=124),new_filename:c(16*=124),comments:c(1*)"
				file_xref=unt
				open (file_xref)stbl("+DATAPORT_FILES")+"file_xref"
				while 1
					read (file_xref,end=*break)file_xref$
					if len(file_xref$) then
						if len(cvs(file_xref.old_filename$,3))=7
							file_xref.old_filename$=cvs(file_xref.old_filename$(1,6),3)+file_xref.old_filename$(7,1)
						endif
						keyval$=cvs(file_xref.new_filename$,11)
						dataval$=cvs(file_xref.old_filename$,11)
						file_xref!.put(keyval$,dataval$)
					endif
				wend
				close (file_xref)

	 			rem --- Get file dependencies for ALL versions
				fileDependencies!=new HashMap()
				versionsVect!=BBjAPI().makeVector()
				versionsVect!.addAll(java.util.Arrays.asList(convCtrl!.getProperty("conversion_versions").split(";")))
				if versionsVect!.size() then
					convCtrlKeys!=convCtrl!.stringPropertyNames()
					for i=0 to versionsVect!.size()-1
						version$=versionsVect!.getItem(i)
						iter!=convCtrlKeys!.iterator()
						while iter!.hasNext()
							key$=iter!.next()
							if pos(version$+"_"=key$)=1 then
								file$=key$(pos("_"=key$)+1)
								if !fileDependencies!.containsKey(file$) then
									fileDependencies!.put(file$,convCtrl!.getProperty(key$))
								else
									rem --- Add new dependencies to existing dependencies for this file
									filelist$=fileDependencies!.get(file$)
									newFiles!=BBjAPI().makeVector()
									newFiles!.addAll(java.util.Arrays.asList(convCtrl!.getProperty(key$).split(";")))
									for j=0 to newFiles!.size()-1
										nextFile$=newFiles!.getItem(j)
										if pos(nextFile$=filelist$)=0 then
											filelist$=filelist$+";"+nextFile$
										endif
									next j
									fileDependencies!.put(file$,filelist$)
								endif
							endif
						wend
					next i
				endif

				rem --- Auto-select files in dependency groups when any in the group is selected
				dependencyKeys!=fileDependencies!.keySet()
				iter!=dependencyKeys!.iterator()
				while iter!.hasNext()
					newFiles!=BBjAPI().makeVector()
					newFiles!.addAll(java.util.Arrays.asList(fileDependencies!.get(iter!.next()).split(";")))
					rem --- Any in group selected?
					group_file_selected=0
					for j=0 to newFiles!.size()-1
						file_name$=newFiles!.getItem(j)
						if file_xref!.containsKey(file_name$) then
							file_name$=file_xref!.get(file_name$)
						endif
						file_name$=cvs(file_name$,version_cvs)
						if selected_files!.containsKey(file_name$) then
							group_file_selected=1
							break
						endif
					next j
					rem --- Select entire dependency group?
					if group_file_selected then
						for j=0 to newFiles!.size()-1
							file_name$=newFiles!.getItem(j)
							if file_xref!.containsKey(file_name$) then
								file_name$=file_xref!.get(file_name$)
							endif
							file_name$=cvs(file_name$,version_cvs)
							if !selected_files!.containsKey(file_name$)
								selected_files!.put(file_name$,file_name$)
							endif
						next j
					endif
				wend
				vectPort!=SysGUI!.makeVector()
				vectPort!.addAll(selected_files!.values())
				callpoint!.setDevObject("vectPort",vectPort!)
			else
				rem --- Report can't find the required config/adx_conversionCtrl.ini initialization file
				msg_id$="AD_FILE_MISSING"
				dim msg_tokens$[1]
				msg_tokens$[1]=convCtrlIniFileName$
				gosub disp_message
				callpoint!.setStatus("ABORT")
				break
			endif
		else
			callpoint!.setStatus("ABORT")
		endif
	endif
[[ADX_DATAPORT.<CUSTOM>]]
rem --- check source directory -- is it there?  Does it contain legacy dictionary files?=======

check_source_dir: 

	temp_chan=unt
	tempColor!=callpoint!.getDevObject("error_color")
	temp_dir$=callpoint!.getUserInput()
	callpoint!.setDevObject("source_ok",0)

	if temp_dir$<>"" then

		if pos(temp_dir$(len(temp_dir$),1)="\/")=0 then
			temp_dir$=temp_dir$+"/"
		endif

		open(temp_chan,err=*endif)temp_dir$
		close(temp_chan)
		version=num(callpoint!.getColumnData("ADX_DATAPORT.ADDON_VERSION"))

		if version=6 then cvs_check=4 else cvs_check=0
		open(temp_chan,err=*endif)temp_dir$+cvs("ddm-03",cvs_check)
		close(temp_chan)
		tempColor!=callpoint!.getDevObject("valid_color")
		callpoint!.setDevObject("source_ok",1)

		gosub check_for_batched_files
	endif

	source!=util.getControl(callpoint!,"ADX_DATAPORT.SOURCE_DIR")		
	source!.setBackColor(tempColor!)

return

rem --- check for existing batched files, and build HashMap of them ==============================

check_for_batched_files:

	batched_files!=new java.util.HashMap()

	rem --- Open batch processing files
	sym49_dev=unt
	open(sym49_dev,err=close_files)temp_dir$+cvs("sym-49",cvs_check)
	dim sym49_k$(3),batch_number$(3),process_id$(10)
	sym09_dev=unt
	open(sym09_dev,err=close_files)temp_dir$+cvs("sym-09",cvs_check)
	dim sym09_k$(10),description$(30)
	sym39_dev=unt
	open(sym39_dev,err=close_files)temp_dir$+cvs("sym-39",cvs_check)
	dim sym39_k$(16),file_name$(6)

	rem --- Check sym-49 to see if there are any open batches
	process_not_found$=Translate!.getTranslation("AON_PROCESS")+" "+Translate!.getTranslation("AON_NOT_FOUND")+": "
	read(sym49_dev,key="",dom=*next)
	while 1
		sym49_k$(1)=key(sym49_dev,end=*break)
		read(sym49_dev)*,process_id$(1)
		batch_number$(1)=sym49_k$

		rem --- Check sym-09 to get process description for this open batch
		description$(1)=process_not_found$+process_id$
		read(sym09_dev,key=process_id$,dom=*next)*,description$(1)

		rem --- Check sym-39 to get files in this open batch
		read(sym39_dev,key=process_id$,dom=*next)
		while 1
			sym39_k$(1)=key(sym39_dev,end=*break)
			if pos(process_id$=sym39_k$)<> 1 then break
			read(sym39_dev)
			file_name$(1)=sym39_k$(11)
			if batched_files!.containsKey(file_name$) then
				rem --- batched_file! already includes this file, so just add this batch to the list of batches
				vec!=cast(BBjVector,batched_files!.get(file_name$))
				batches$=vec!.getItem(0)
				batches$=batches$+"; "+batch_number$
				vec!.setItem(0,batches$)
			else
				rem --- batched_file! doesn't includes this file, so add it
				vec!=BBjAPI().makeVector()
				vec!.addItem(batch_number$)
				vec!.addItem(description$)
				batched_files!.put(file_name$,vec!)
			endif
		wend
	wend

close_files:
	if sym09_dev then close(sym09_dev,err=*next)
	if sym39_dev then close(sym39_dev,err=*next)
	if sym49_dev then close(sym49_dev,err=*next)
	callpoint!.setDevObject("batched_files",batched_files!)

return

rem --- check target directory -- is it there? ==============================

check_target_dir: 

	temp_chan=unt
	tempColor!=callpoint!.getDevObject("error_color")
	temp_dir$=callpoint!.getUserInput()
	callpoint!.setDevObject("target_ok",0)

	if temp_dir$<>"" then

		if pos(temp_dir$(len(temp_dir$),1)="\/")=0 then
			temp_dir$=temp_dir$+"/"
		endif

		open(temp_chan,err=*endif)temp_dir$
		close(temp_chan)
		tempColor!=callpoint!.getDevObject("valid_color")
		callpoint!.setDevObject("target_ok",1)

	endif

	target!=util.getControl(callpoint!,"ADX_DATAPORT.TARGET_DIR")		
	target!.setBackColor(tempColor!)

return

switch_value: rem --- Switch Check Values===============================

	SysGUI!.setRepaintEnabled(0)
	gridFiles!=callpoint!.getDevObject("gridFiles")
	TempRows!=gridFiles!.getSelectedRows()
	if TempRows!.size()>0
		batched_files!=callpoint!.getDevObject("batched_files")
		for curr_row=1 to TempRows!.size()
			if gridFiles!.getCellState(TempRows!.getItem(curr_row-1),0)=0
				rem --- Don't allow selecting this file if it's batched
				file_name$=gridFiles!.getCellText(TempRows!.getItem(curr_row-1),1)
				if batched_files!.containsKey(file_name$) then
					vec!=cast(BBjVector,batched_files!.get(file_name$))
					msg_id$="CANNOT_PORT_BATCHED"
					dim msg_tokens$[3]
					msg_tokens$[1]=vec!.getItem(1)
					msg_tokens$[2]=file_name$
					msg_tokens$[3]=vec!.getItem(0)
					gosub disp_message
				else
					gridFiles!.setCellState(TempRows!.getItem(curr_row-1),0,1)
				endif
			else
				gridFiles!.setCellState(num(TempRows!.getItem(curr_row-1)),0,0)
			endif
		next curr_row
	endif

	SysGUI!.setRepaintEnabled(1)

	return

format_grid: rem --- format the grid that will display legacy filenames==============

dim attr_def_col_str$[0,0]
attr_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()
def_cols=4
num_rows=0
dim attr_col$[def_cols,len(attr_def_col_str$[0,0])/5]

attr_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SELECT"
attr_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=""
attr_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"
attr_col$[1,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="1"
attr_col$[1,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="C"

attr_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="FILE_ID"
attr_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_FILE_ID")
attr_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"

attr_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="REC_ID"
attr_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_REC_ID")
attr_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"

attr_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DESC"
attr_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DESCRIPTION")
attr_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="300"

for curr_attr=1 to def_cols

	attr_col$[0,1]=attr_col$[0,1]+pad("FILES."+attr_col$[curr_attr,
:		fnstr_pos("DVAR",attr_def_col_str$[0,0],5)],40)

next curr_attr

attr_disp_col$=attr_col$[0,1]

call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridFiles!,"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC-DATES-CHECKS",num_rows,
:	attr_def_col_str$[all],attr_disp_col$,attr_col$[all]

return
[[ADX_DATAPORT.BSHO]]
rem --- inits

	use java.io.File
	use java.io.FileReader
	use java.util.HashMap
	use java.util.Properties
	use ::ado_util.src::util
	use ::ado_file.src::FileObject

rem --- disable Scan button until we have valid source dir

	callpoint!.setOptionEnabled("SCAN",0)

rem --- set valid/invalid background colors for source/target dir ctls

	source_dir!=util.getControl(callpoint!,"ADX_DATAPORT.ADDON_VERSION")
	callpoint!.setDevObject("valid_color",source_dir!.getBackColor())
	call stbl("+DIR_SYP")+"bac_create_color.bbj","+ENTRY_ERROR_COLOR","255,224,224",error_color!,""
	callpoint!.setDevObject("error_color",error_color!)
   	callpoint!.setDevObject("indent_color",SysGUI!.makeColor(96,96,96))

	
rem --- create grid 

	nxt_ctlID = util.getNextControlID()
	callpoint!.setDevObject("grid_ctlID",str(nxt_ctlID))
	gridFiles!=Form!.addGrid(nxt_ctlID,50,100,500,300)
	
	gosub format_grid
		
rem	gridFiles!.setColumnEditable(0,1)
rem	gridFiles!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)
	
	util.resizeWindow(Form!, SysGui!)
	
	rem --- set callbacks - processed in ACUS callpoint
	gridFiles!.setCallback(gridFiles!.ON_GRID_KEY_PRESS,"custom_event")		
	gridFiles!.setCallback(gridFiles!.ON_GRID_MOUSE_UP,"custom_event")

	callpoint!.setDevObject("gridFiles",gridFiles!)
