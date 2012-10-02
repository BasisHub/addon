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
	vectPort!=SysGUI!.makeVector()

	if gridFiles!.getNumRows()=0 or (num(callpoint!.getDevObject("source_ok"))+num(callpoint!.getDevObject("target_ok"))<>2)
		callpoint!.setStatus("ABORT")
	else
		for curr_row=1 to gridFiles!.getNumRows()
			if gridFiles!.getCellState(curr_row-1,0)=1 then
				vectPort!.addItem(gridFiles!.getCellText(curr_row-1,1))
			endif
		next curr_row
		msg_id$="AD_DATAPORT_CONF"
		gosub disp_message
		if msg_opt$="Y" and vectPort!.size()<>0
			callpoint!.setDevObject("source_version",callpoint!.getColumnData("ADX_DATAPORT.ADDON_VERSION"))
			callpoint!.setDevObject("source_folder",callpoint!.getColumnData("ADX_DATAPORT.SOURCE_DIR"))
			callpoint!.setDevObject("destin_folder",callpoint!.getColumnData("ADX_DATAPORT.TARGET_DIR"))
			callpoint!.setDevObject("vectPort",vectPort!)
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

	endif

	source!=util.getControl(callpoint!,"ADX_DATAPORT.SOURCE_DIR")		
	source!.setBackColor(tempColor!)

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
		for curr_row=1 to TempRows!.size()
			if gridFiles!.getCellState(TempRows!.getItem(curr_row-1),0)=0
				gridFiles!.setCellState(TempRows!.getItem(curr_row-1),0,1)
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

	use ::ado_util.src::util

rem --- disable Scan button until we have valid source dir

	callpoint!.setOptionEnabled("SCAN",0)

rem --- set valid/invalid background colors for source/target dir ctls

	source_dir!=util.getControl(callpoint!,"ADX_DATAPORT.ADDON_VERSION")
	callpoint!.setDevObject("valid_color",source_dir!.getBackColor())
	call stbl("+DIR_SYP")+"bac_create_color.bbj","+ENTRY_ERROR_COLOR","255,224,224",error_color!,""
	callpoint!.setDevObject("error_color",error_color!)
   	callpoint!.setDevObject("indent_color",SysGUI!.makeColor(96,96,96))

	
rem --- create grid 

	nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))
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
