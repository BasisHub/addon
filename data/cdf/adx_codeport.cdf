[[ADX_CODEPORT.ASVA]]
rem --- check/warn if destination dir not empty; check selected files to make sure they're tokenized pgms

	file_count=0
	target_dev=unt
	target_dir$=callpoint!.getColumnData("ADX_CODEPORT.TARGET_DIR")
	open(target_dev)target_dir$
	while file_count=0
		readrecord(target_dev,end=*break)target_file$
		if pos("."=target_file$)=1 then continue
		if target_file$(len(target_file$),1)="/" then continue
		file_count=file_count+1
	wend
	
	if file_count>0
		msg_id$="NOT_EMPTY"
		gosub disp_message
		if msg_opt$="C"
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

	srcFiles!=SysGUI!.makeVector()
	gridFiles!=callpoint!.getDevObject("gridFiles")
	num_rows=gridFiles!.getNumRows()
	source_dir$=callpoint!.getColumnData("ADX_CODEPORT.SOURCE_DIR")
	if pos(source_dir$(len(source_dir$),1)="\/")=0 then
		source_dir$=source_dir$+"/"
	endif
	bad_source=0

	if num_rows
		for xwk=0 to num_rows-1
			chk$=str(gridFiles!.getCellState(xwk,0))
			if chk$="1" then srcFiles!.addItem(gridFiles!.getCellText(xwk,1))
		next xwk
	endif
	
	if srcFiles!.size()
		for xwk=0 to srcFiles!.size()-1
			src_dev=unt
			dim xwk$(1)
			open(src_dev,err=*next)source_dir$+srcFiles!.getItem(xwk)
			xwk$=fid(src_dev,err=*next)
			if xwk$(1,1)<>$04$ then bad_source=bad_source+1
			close(src_dev)
		next xwk
	else
		msg_id$="NO_FILES"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

	if bad_source>0  
		msg_id$="NOT_TOKENIZED"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	else
		callpoint!.setDevObject("srcFiles",srcFiles!)
	endif
[[ADX_CODEPORT.AOPT-SCAN]]
rem --- refresh grid of source programs

source_dir$=callpoint!.getColumnData("ADX_CODEPORT.SOURCE_DIR")
if cvs(source_dir$,3)<>"" then gosub scan_source
[[ADX_CODEPORT.SOURCE_DIR.AVAL]]
rem --- scan the specified source directory and refresh/create grid of candidate programs

source_dir$=callpoint!.getUserInput()
if cvs(source_dir$,3)<>"" then gosub scan_source
[[ADX_CODEPORT.BSHO]]
rem --- inits

	use ::ado_util.src::util

rem --- disable Scan button until we have valid source dir

	callpoint!.setOptionEnabled("SCAN",1)

rem --- set valid/invalid background colors for source/target dir ctls

	source_dir!=util.getControl(callpoint!,"ADX_CODEPORT.ADDON_VERSION")
	callpoint!.setDevObject("valid_color",source_dir!.getBackColor())
	call stbl("+DIR_SYP")+"bac_create_color.bbj","+ENTRY_ERROR_COLOR","255,224,224",error_color!,""
	callpoint!.setDevObject("error_color",error_color!)
   	callpoint!.setDevObject("indent_color",SysGUI!.makeColor(96,96,96))

	
rem --- create grid 

	nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))
	callpoint!.setDevObject("grid_ctlID",str(nxt_ctlID))
	gridFiles!=Form!.addGrid(nxt_ctlID,130,150,250,250)
	
	gosub format_grid
		
	util.resizeWindow(Form!, SysGui!)
	
	rem --- set callbacks - processed in ACUS callpoint
	gridFiles!.setCallback(gridFiles!.ON_GRID_KEY_PRESS,"custom_event")		
	gridFiles!.setCallback(gridFiles!.ON_GRID_MOUSE_UP,"custom_event")

	callpoint!.setDevObject("gridFiles",gridFiles!)
[[ADX_CODEPORT.<CUSTOM>]]
scan_source:rem --- Scan Source Directory and build vectors to populate gridFiles!==================
rem --- source_dir$ is incoming

	if cvs(source_dir$,3)=""
		callpoint!.setOptionEnabled("SCAN",0)
		return
	endif
	if pos(source_dir$(len(source_dir$),1)="\/")=0 then
		source_dir$=source_dir$+"/"
	endif

	source_dir_dev=unt
  	open(source_dir_dev)source_dir$

 	gridVect!=SysGUI!.makeVector()
	all_files$=""
	recs_found=0

	while 1
		readrecord(source_dir_dev,end=*break)dir_file$
		if pos("."=dir_file$)=1 then continue	
		if pos("/"=dir_file$)<>0 then continue
		all_files$=all_files$+pad(dir_file$,10)
	wend

	all_files$=ssort(all_files$,10)
	for xwk=0 to len(all_files$)-1 step 10
		gridVect!.addItem("");rem for checkbox
		gridVect!.addItem(cvs(all_files$(xwk+1,10),3))
		recs_found=recs_found+1
	next xwk

	gridFiles!=callpoint!.getDevObject("gridFiles")
	gridFiles!.setNumRows(0)
	gridFiles!.setNumRows(recs_found)
	gridFiles!.setColumnWidth(0,50)
	gridFiles!.setColumnWidth(1,200)
	gridFiles!.setCellText(0,0,gridVect!)

	gridFiles!.deselectAllCells()
	gridVect!.clear()

	close (source_dir_dev)

return

switch_value: rem --- Switch Check Values===============================

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
return

format_grid: rem --- format the grid that will display legacy filenames==============

dim attr_def_col_str$[0,0]
attr_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()
def_cols=2
num_rows=0
dim attr_col$[def_cols,len(attr_def_col_str$[0,0])/5]

attr_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SELECT"
attr_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=""
attr_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
attr_col$[1,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="1"
attr_col$[1,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="C"

attr_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SRC_PROGRAM"
attr_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("SRC_PROGRAM","Source Programs")
attr_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="200"


for curr_attr=1 to def_cols

	attr_col$[0,1]=attr_col$[0,1]+pad("FILES."+attr_col$[curr_attr,
:		fnstr_pos("DVAR",attr_def_col_str$[0,0],5)],40)

next curr_attr

attr_disp_col$=attr_col$[0,1]

call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridFiles!,"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC-DATES-CHECKS",num_rows,
:	attr_def_col_str$[all],attr_disp_col$,attr_col$[all]


return
[[ADX_CODEPORT.ACUS]]
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
[[ADX_CODEPORT.ASIZ]]
rem --- resize grid if window size changes

	gridFiles!=callpoint!.getDevObject("gridFiles")
	if gridFiles!<>null()
		gridFiles!.setColumnWidth(0,25)
		gridFiles!.setSize(Form!.getWidth()-(gridFiles!.getX()*2),Form!.getHeight()-(gridFiles!.getY()+40))
		gridFiles!.setFitToGrid(1)
	endif
