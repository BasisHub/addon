[[ADX_UPGRADEWIZ.ASHO]]
rem --- Don't allow running the utility if Addon doesn't exist at Basis download location

	bbjHome$ = System.getProperty("basis.BBjHome")
	aonSynFile$ = bbjHome$+"/apps/aon/config/addon.syn"
	aonExists = 0
	tmp_dev = unt
	open(tmp_dev, err=*next)aonSynFile$; aonExists = 1
	close(tmp_dev,err=*next)
	if !aonExists then
		msg_id$="AD_DOWNLOAD_MISSING"
		dim msg_tokens$[1]
		msg_tokens$[1]=bbjHome$
		gosub disp_message
		callpoint!.setStatus("EXIT")
	endif
[[ADX_UPGRADEWIZ.DB_NAME.AVAL]]
rem --- Validate new database name

	db_name$ = callpoint!.getUserInput()
	gosub validate_new_db_name
	callpoint!.setUserInput(db_name$)
	if abort then break
[[ADX_UPGRADEWIZ.ACUS]]
rem --- Process custom event
rem --- Edit STBL target value

rem This routine is executed when callbacks have been set to run a 'custom event'.
rem Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind of event it is.
rem See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info.

	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ctl_ID=dec(gui_event.ID$)

	if ctl_ID <> num(callpoint!.getDevObject("stbl_grid_id")) then break; rem --- exit callpoint

	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
	endif

	switch notice.code
		case 32; rem --- on_grid_cell_validation
			rem --- Make sure we get all entries in the grid
			e!=SysGUI!.getLastEvent()
			e!.accept(1)
			break
	swend
[[ADX_UPGRADEWIZ.ASIZ]]
	gridStbls!=callpoint!.getDevObject("gridStbls")
	gridStbls!.setSize(Form!.getWidth()-(gridStbls!.getX()*2),Form!.getHeight()-(gridStbls!.getY()+10))
	gridStbls!.setFitToGrid(1)
[[ADX_UPGRADEWIZ.AWIN]]
rem --- Add grid to form for updating STBLs and PREFIXs with paths

	use ::ado_util.src::util

	nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))
	callpoint!.setDevObject("nxt_ctlID",nxt_ctlID)

	gridStbls!=Form!.addGrid(nxt_ctlID,10,160,850,260); rem --- ID, x, y, width, height
	callpoint!.setDevObject("gridStbls",gridStbls!)

	callpoint!.setDevObject("stbl_grid_id",str(nxt_ctlID))
	callpoint!.setDevObject("def_rpts_cols",4)
	callpoint!.setDevObject("min_rpts_rows",15)

	gosub format_grid

	rem --- misc other init
	gridStbls!.setColumnEditable(3,1)
	gridStbls!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)

	callpoint!.setDevObject("newSynRows",SysGUI!.makeVector())
	callpoint!.setDevObject("oldSynRows",SysGUI!.makeVector())
	gosub create_reports_vector
	gosub fill_grid
	util.resizeWindow(Form!, SysGui!)

	rem --- set callbacks - processed in ACUS callpoint
	gridStbls!.setCallback(gridStbls!.ON_GRID_CELL_VALIDATION,"custom_event")
[[ADX_UPGRADEWIZ.ASVA]]
rem --- Validate new aon install location

	new_aon_loc$ = callpoint!.getColumnData("ADX_UPGRADEWIZ.NEW_AON_LOC")
	gosub validate_new_aon_loc
	callpoint!.setColumnData("ADX_UPGRADEWIZ.NEW_AON_LOC",new_aon_loc$)
	if abort then break

rem --- Validate old aon install location

	old_aon_loc$ = callpoint!.getColumnData("ADX_UPGRADEWIZ.OLD_AON_LOC")
	gosub validate_old_aon_loc
	callpoint!.setColumnData("ADX_UPGRADEWIZ.OLD_AON_LOC",old_aon_loc$)
	if abort then break

rem --- Validate old barista install location

	old_bar_loc$ = callpoint!.getColumnData("ADX_UPGRADEWIZ.OLD_BAR_LOC")
	gosub validate_old_bar_loc
	callpoint!.setColumnData("ADX_UPGRADEWIZ.OLD_BAR_LOC",old_bar_loc$)
	if abort then break

rem --- Validate sync backup directory

	sync_backup_dir$ = callpoint!.getColumnData("ADX_UPGRADEWIZ.SYNC_BACKUP_DIR")
	gosub validate_sync_backup_dir
	callpoint!.setColumnData("ADX_UPGRADEWIZ.SYNC_BACKUP_DIR",sync_backup_dir$)
	if abort then break

rem --- Make sure we get all entries in the grid by setting focus on some control besides the grid

	ctl!=callpoint!.getControl("ADX_UPGRADEWIZ.NEW_AON_LOC")
	ctl!.focus()

rem --- Build hash of STBL source and target values and array of PREFIX source and target values to pass to backend program

	declare HashMap stblMap!
	declare ArrayList aList!

	stblMap!=new HashMap()
	pfxList!=new ArrayList()
	gridStbls!=callpoint!.getDevObject("gridStbls")

	for i=0 to gridStbls!.getNumRows()-1
		type$=cvs(gridStbls!.getCellText(i,0),3)

		if type$="STBL" or type$="SYSSTBL"
			aList!=new ArrayList()
			aList!.add(gridStbls!.getCellText(i,2)); rem --- source value
			aList!.add(gridStbls!.getCellText(i,3)); rem --- target value
			stblMap!.put(gridStbls!.getCellText(i,1), aList!)
		endif

		if type$="PREFIX" or type$="SYSPFX"
			aList!=new ArrayList()
			aList!.add(gridStbls!.getCellText(i,2)); rem --- source value
			aList!.add(gridStbls!.getCellText(i,3)); rem --- target value
			pfxList!.add(aList!)
		endif
	next i

	callpoint!.setDevObject("stblMap",stblMap!)
	callpoint!.setDevObject("pfxList",pfxList!)
[[ADX_UPGRADEWIZ.SYNC_BACKUP_DIR.AVAL]]
rem --- Validate sync backup directory

	sync_backup_dir$ = callpoint!.getUserInput()
	gosub validate_sync_backup_dir
	callpoint!.setUserInput(sync_backup_dir$)
	if abort then break
[[ADX_UPGRADEWIZ.OLD_BAR_LOC.AVAL]]
rem --- Validate old barista install location

	old_bar_loc$ = callpoint!.getUserInput()
	gosub validate_old_bar_loc
	callpoint!.setUserInput(old_bar_loc$)
	if abort then break

rem --- Initialize old Barista admin_backup as needed
	if cvs(callpoint!.getColumnData("ADX_UPGRADEWIZ.SYNC_BACKUP_DIR"),3)="" then
		bar_dir$=old_bar_loc$+"/barista"
		gosub able_backup_sync_dir
	endif
[[ADX_UPGRADEWIZ.BSHO]]
rem --- Declare Java classes used

	use java.io.File
	use java.util.ArrayList
	use java.util.HashMap

rem --- Initialize new aon location and old aon location values so can tell later if they have changed

	callpoint!.setDevObject("prev_new_aon_loc","")
	callpoint!.setDevObject("prev_old_aon_loc","")
[[ADX_UPGRADEWIZ.OLD_AON_LOC.AVAL]]
rem --- Validate old aon install location

	old_aon_loc$ = callpoint!.getUserInput()
	gosub validate_old_aon_loc
	callpoint!.setUserInput(old_aon_loc$)
	if abort then break

rem --- Initialize old Barista install location as needed

	if cvs(callpoint!.getColumnData("ADX_UPGRADEWIZ.OLD_BAR_LOC"),3)="" then
		old_bar_loc$=old_aon_loc$
		gosub able_old_bar_loc
	endif

rem --- Initialize old Barista admin_backup as needed
	if cvs(callpoint!.getColumnData("ADX_UPGRADEWIZ.SYNC_BACKUP_DIR"),3)="" then
		bar_dir$=cvs(callpoint!.getColumnData("ADX_UPGRADEWIZ.OLD_BAR_LOC"),3)+"/barista"
		gosub able_backup_sync_dir
	endif
	
rem --- Set defaults for data STBLs
	if cvs(old_aon_loc$,3)<>cvs(callpoint!.getDevObject("prev_old_aon_loc"),3) then
		rem --- Capture old aon location value so can tell later if it's been changed
		callpoint!.setDevObject("prev_old_aon_loc",old_aon_loc$)

		rem --- Initialize aon directory from new aon location
		filePath$=callpoint!.getDevObject("prev_new_aon_loc")
		gosub fix_path
		aonDir$=filePath$+"/aon/"

		rem --- Use addon.syn file from old aon location
		synFile$=old_aon_loc$+"/aon/config/addon.syn"
		
		rem --- Initialize grid
		gosub create_reports_vector
		callpoint!.setDevObject("oldSynRows",vectRows!)
		if cvs(callpoint!.getDevObject("prev_new_aon_loc"),3)<>"" then
			callpoint!.setStatus("REFRESH")
			gosub fill_grid
			util.resizeWindow(Form!, SysGui!)
		endif
	endif
[[ADX_UPGRADEWIZ.<CUSTOM>]]
validate_new_db_name: rem --- Validate new database name

	abort=0

	rem --- Barista uses all upper case db names
	db_name$=cvs(db_name$,4)

	rem --- Don't allow database if it's already in Enterprise Manager
	call stbl("+DIR_SYP")+"bac_em_login.bbj",SysGUI!,Form!,rdAdmin!,rd_status$
	if rd_status$="ADMIN" then
		db! = rdAdmin!.getDatabase(db_name$,err=dbNotFound)

		rem --- This db already exists, so don't allow it
		msg_id$="AD_DB_EXISTS"
		gosub disp_message
	endif

	rem --- Abort, need to re-enter database name
	callpoint!.setColumnData("ADX_UPGRADEWIZ.DB_NAME", db_name$)
	callpoint!.setFocus("ADX_UPGRADEWIZ.DB_NAME")
	callpoint!.setStatus("ABORT")
	abort=1

dbNotFound:
	rem --- Okay to use this db name, it doesn't already exist
	callpoint!.setDevObject("rdAdmin", rdAdmin!)

	return

validate_new_aon_loc: rem --- Validate new aon install location

	abort=0

	rem --- Remove trailing slashes (/ and \) from aon new install location

	while len(new_aon_loc$) and pos(new_aon_loc$(len(new_aon_loc$),1)="/\")
		new_aon_loc$ = new_aon_loc$(1, len(new_aon_loc$)-1)
	wend

	rem --- Remove trailing “/aon”

	if len(new_aon_loc$)>=4 and pos(new_aon_loc$(1+len(new_aon_loc$)-4)="/aon\aon" ,4)
		new_aon_loc$ = new_aon_loc$(1, len(new_aon_loc$)-4)
	endif

	rem --- Don’t allow current download location

	testLoc$=new_aon_loc$
	gosub verify_not_download_loc
	if !loc_ok
		callpoint!.setColumnData("ADX_UPGRADEWIZ.NEW_AON_LOC", new_aon_loc$)
		callpoint!.setFocus("ADX_UPGRADEWIZ.NEW_AON_LOC")
		callpoint!.setStatus("ABORT")
		abort=1
		return
	endif

	rem --- Cannot be currently used by Addon

	testChan=unt
	open(testChan, err=*return)new_aon_loc$ + "/aon/data"
	close(testChan)

	rem --- Addon already at this location
	msg_id$="AD_INSTALL_LOC_USED"
	gosub disp_message

	callpoint!.setColumnData("ADX_UPGRADEWIZ.NEW_AON_LOC", new_aon_loc$)
	callpoint!.setFocus("ADX_UPGRADEWIZ.NEW_AON_LOC")
	callpoint!.setStatus("ABORT")
	abort=1

	return

verify_not_download_loc: rem --- Verify not using current download location

	loc_ok=1
	bbjHome$ = System.getProperty("basis.BBjHome")
	if ((new File(testLoc$)).getAbsolutePath()).toLowerCase().startsWith((new File(bbjHome$)).getAbsolutePath().toLowerCase()+File.separator)
		msg_id$="AD_INSTALL_LOC_BAD"
		dim msg_tokens$[1]
		msg_tokens$[1]=bbjHome$
		gosub disp_message
		loc_ok=0
	endif

	return

validate_old_aon_loc: rem --- Validate old aon install location

	abort=0

	rem --- Remove trailing slashes (/ and \) from aon new install location

	while len(old_aon_loc$) and pos(old_aon_loc$(len(old_aon_loc$),1)="/\")
		old_aon_loc$ = old_aon_loc$(1, len(old_aon_loc$)-1)
	wend

	rem --- Remove trailing “/aon”

	if len(old_aon_loc$)>=4 and pos(old_aon_loc$(1+len(old_aon_loc$)-4)="/aon\aon" ,4)
		old_aon_loc$ = old_aon_loc$(1, len(old_aon_loc$)-4)
	endif

	rem --- Confirm currently used by Addon

	testChan=unt
	open(testChan, err=not_aon_loc)old_aon_loc$ + "/aon/config/addon.syn"
	close(testChan)
	
	return

not_aon_loc:	rem --- Addon not at this location
	msg_id$="AD_NOT_AON_LOC"
	gosub disp_message

	callpoint!.setColumnData("ADX_UPGRADEWIZ.OLD_AON_LOC", old_aon_loc$)
	callpoint!.setFocus("ADX_UPGRADEWIZ.OLD_AON_LOC")
	callpoint!.setStatus("ABORT")
	abort=1

	return

validate_old_bar_loc: rem --- Validate old bar install location

	abort=0

	rem --- Remove trailing slashes (/ and \) from aon new install location

	while len(old_bar_loc$) and pos(old_bar_loc$(len(old_bar_loc$),1)="/\")
		old_bar_loc$ = old_bar_loc$(1, len(old_bar_loc$)-1)
	wend

	rem --- Remove trailing “/barista”

	if len(old_bar_loc$)>=8 and pos(old_bar_loc$(1+len(old_bar_loc$)-8)="/barista\barista" ,8)
		old_bar_loc$ = old_bar_loc$(1, len(old_bar_loc$)-8)
	endif

	rem --- Confirm currently used by Barista

	testChan=unt
	open(testChan, err=not_bar_loc)old_bar_loc$ + "/barista/sys/config/enu/barista.cfg"
	close(testChan)
	
	return

not_bar_loc:	rem --- Barista not at this location
	msg_id$="AD_NOT_BAR_LOC"
	gosub disp_message

	callpoint!.setColumnData("ADX_UPGRADEWIZ.OLD_BAR_LOC", old_bar_loc$)
	callpoint!.setFocus("ADX_UPGRADEWIZ.OLD_BAR_LOC")
	callpoint!.setStatus("ABORT")
	abort=1

	return

validate_sync_backup_dir: rem --- Validate sync backup directory

	abort=0

	rem --- Remove trailing slashes (/ and \) from aon new install location

	while len(sync_backup_dir$) and pos(sync_backup_dir$(len(sync_backup_dir$),1)="/\")
		sync_backup_dir$ = sync_backup_dir$(1, len(sync_backup_dir$)-1)
	wend


	rem --- Directory must exist
	testChan=unt
	open(testChan, err=dir_missing)sync_backup_dir$
	close(testChan)
	
	return

dir_missing: rem --- Directory doesn't exist
	msg_id$="AD_DIR_MISSING"
	dim msg_tokens$[1]
	msg_tokens$[1]=testDir$
	gosub disp_message

	callpoint!.setColumnData("ADX_UPGRADEWIZ.SYNC_BACKUP_DIR", old_bar_loc$)
	callpoint!.setFocus("ADX_UPGRADEWIZ.SYNC_BACKUP_DIR")
	callpoint!.setStatus("ABORT")
	abort=1

	return

able_old_bar_loc: rem --- Enable/disable input field for old Barista location

		rem --- Check for old Barista barista.cfg file
		bar_found=0
		testChan=unt 
		open(testChan, err=*next)old_bar_loc$ + "/barista/sys/config/enu/barista.cfg"; bar_found=1
		close(testChan)

		if bar_found then
			rem --- Initialize and disable old Barista location
			callpoint!.setColumnEnabled("ADX_UPGRADEWIZ.OLD_BAR_LOC",0)
			callpoint!.setColumnData("ADX_UPGRADEWIZ.OLD_BAR_LOC",old_bar_loc$)
		else
			rem --- Enable old Barista location
			callpoint!.setColumnEnabled("ADX_UPGRADEWIZ.OLD_BAR_LOC",1)
		endif

	callpoint!.setStatus("REFRESH")

	return

able_backup_sync_dir: rem --- Enable/disable input field for sync backup directory

		rem --- Check for old Barista admin_backup
		backup_found=0
		testChan=unt 
		open(testChan, err=*next)bar_dir$ + "/admin_backup"; backup_found=1
		close(testChan)

		if backup_found then
			rem --- Initialize and disable sync backup directory
			callpoint!.setColumnEnabled("ADX_UPGRADEWIZ.SYNC_BACKUP_DIR",0)
			callpoint!.setColumnData("ADX_UPGRADEWIZ.SYNC_BACKUP_DIR",bar_dir$ + "/admin_backup")
		else
			rem --- Enable sync backup directory
			callpoint!.setColumnEnabled("ADX_UPGRADEWIZ.SYNC_BACKUP_DIR",1)
		endif

	callpoint!.setStatus("REFRESH")

	return

format_grid: rem --- Format grid

	def_rpts_cols=callpoint!.getDevObject("def_rpts_cols")
	num_rpts_rows=callpoint!.getDevObject("min_rpts_rows")

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()

	dim attr_rpts_col$[def_rpts_cols,len(attr_def_col_str$[0,0])/5]
	attr_rpts_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="TYPE"
	attr_rpts_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_TYPE")
	attr_rpts_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"

	attr_rpts_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="STBL"
	attr_rpts_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="STBL"
	attr_rpts_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="150"

	attr_rpts_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="STBL_SOURCE"
	attr_rpts_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_SOURCE")
	attr_rpts_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="325"

	attr_rpts_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="STBL_TARGET"
	attr_rpts_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_TARGET")
	attr_rpts_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="325"
	attr_rpts_col$[4,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="256"

	for curr_attr=1 to def_rpts_cols
		attr_rpts_col$[0,1]=attr_rpts_col$[0,1]+pad("UPGRADEWIZ."+attr_rpts_col$[curr_attr,
:			fnstr_pos("DVAR",attr_def_col_str$[0,0],5)],40)
	next curr_attr

	attr_disp_col$=attr_rpts_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridStbls!,"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC",num_rpts_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_rpts_col$[all]

	return

fill_grid: rem --- Fill the grid with data in vectRows!

	newSynRows!=callpoint!.getDevObject("newSynRows")
	oldSynRows!=callpoint!.getDevObject("oldSynRows")
	gosub merge_vect_rows

	SysGUI!.setRepaintEnabled(0)
	gridStbls!=callpoint!.getDevObject("gridStbls")
	if vectRows!.size()
		numrow=vectRows!.size()/gridStbls!.getNumColumns()
		gridStbls!.clearMainGrid()
		gridStbls!.setNumRows(numrow)
		gridStbls!.setCellText(0,0,vectRows!)
		gridStbls!.resort()
		gridStbls!.setSelectedRow(0)
	endif
	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
merge_vect_rows: rem --- Merge new and old syn row vectors into a single a vector of STBLs and PREFIXs
		rem      IN: newSynRows!
		rem          oldSynRows!
		rem     OUT: vectRows!
rem ==========================================================================

	vectRows!=newSynRows!
	if oldSynRows!.size()>0
		numCols=num(callpoint!.getDevObject("def_rpts_cols"))

		for i=0 to oldSynRows!.size()-1 step numCols
			type$=oldSynRows!.getItem(i+0)
			addLine=0

			rem --- replace target value of STBL and SYSSTBL lines with target value from OLD syn file
			if type$="STBL" or type$="SYSSTBL"
				stbl$=oldSynRows!.getItem(i+1)
				addLine=1
				for j=0 to vectRows!.size()-1 step numCols
					if vectRows!.getItem(j+1)<>stbl$ then continue
					if stbl$="+MDI_TITLE" then
						vectRows!.setItem(j+3, callpoint!.getColumnData("ADX_UPGRADEWIZ.APP_DESC"))
					else
						vectRows!.setItem(j+3, oldSynRows!.getItem(i+3))
					endif
					addLine=0
					break
				next j
			endif

			rem --- replace target value of PREFIX and SYSPFX lines with target value from OLD syn file
			if type$="PREFIX" or type$="SYSPFX"
				source$=oldSynRows!.getItem(i+2)
				addLine=1
				for j=0 to vectRows!.size()-1 step numCols
					if vectRows!.getItem(j+1)<>source$ then continue
					vectRows!.setItem(j+3, oldSynRows!.getItem(i+3))
					addLine=0
					break
				next j
			endif
				
			rem --- if STBL/SYSSTBL or PREFIX/SYSPFX not found, add it
			if addLine then
				vectRows!.addItem(oldSynRows!.getItem(i+0))
				vectRows!.addItem(oldSynRows!.getItem(i+1))
				vectRows!.addItem(oldSynRows!.getItem(i+2))
				vectRows!.addItem(oldSynRows!.getItem(i+3))
			endif
		next i
	endif

	return

rem ==========================================================================
create_reports_vector: rem --- Create a vector of STBLs and PREFIXs from the source syn file to fill the grid
		rem      IN: aonDir$
		rem          synFile$
		rem     OUT: vectRows!
rem ==========================================================================

	synDev=unt, more=0
	open(synDev,isz=-1,err=*next)synFile$; more=1

	oldaonDir$=""
	vectRows!=SysGUI!.makeVector()
	while more
		read(synDev,end=*break)record$

		rem --- get old aon path from SYSDIR/DIR line
		rem --- it must be replaced everywhere with current aon path.
		if(pos("DIR="=record$) = 1 or pos("SYSDIR="=record$) = 1) then
			xpos = pos("="=record$)
			oldaonDir$= cvs(record$(xpos+1),3)
		endif

		rem --- process SYSSTBL/STBL lines
		if(pos("STBL="=record$) = 1 or pos("SYSSTBL="=record$) = 1) then
			xpos = pos(" "=record$)
			stbl$ = record$(xpos+1, pos("="=record$(xpos+1))-1)
			source_value$=cvs(record$(pos("="=record$,1,2)+1),3)
			gosub source_target_value
			vectRows!.addItem("STBL")
			vectRows!.addItem(stbl$)
			vectRows!.addItem(source_value$)
			vectRows!.addItem(target_value$)
		endif

		rem --- process SYSPFX/PREFIX lines
		if(pos("PREFIX"=record$) = 1 or pos("SYSPFX"=record$) = 1) then
			source_value$=cvs(record$(pos("="=record$)+1),3)
			gosub source_target_value
			vectRows!.addItem("PREFIX")
			vectRows!.addItem("")
			vectRows!.addItem(source_value$)
			vectRows!.addItem(target_value$)
		endif
	wend
	close(synDev)
	
	return

source_target_value: rem -- Set default new target value based on new config location

	target_value$=source_value$

	rem --- If source holds a path, then need to initialize default new target value
	declare File aFile!
	aFile! = new File(source_value$)
	if aFile!.exists() and aonDir$<>"" and oldaonDir$<>"" then
		record$=target_value$
		search$=oldaonDir$
		replace$=aonDir$
		gosub search_replace
		target_value$=record$
	endif

	filePath$=target_value$
	gosub fix_path
	target_value$=filePath$

	return

fix_path: rem --- Flip directory path separators

	pos=pos("\"=filePath$)
	while pos
		filePath$=filePath$(1, pos-1)+"/"+filePath$(pos+1)
		pos=pos("\"=filePath$)
	 wend

	return
    
search_replace: rem --- Search record$ for search$, and replace with replace$
	rem --- Assumes only one occurrence of search$ per line so don't have 
	rem --- to deal with situation where pos(search$=replace$)>0
	pos = pos(search$=record$)
	if(pos) then
		record$ = record$(1, pos - 1) + replace$ + record$(pos + len(search$))
	endif
    return
[[ADX_UPGRADEWIZ.NEW_AON_LOC.AVAL]]
rem --- Validate new aon install location

	new_aon_loc$ = callpoint!.getUserInput()
	gosub validate_new_aon_loc
	callpoint!.setUserInput(new_aon_loc$)
	if abort then break

rem --- Set defaults for data STBLs
	if cvs(new_aon_loc$,3)<>cvs(callpoint!.getDevObject("prev_new_aon_loc"),3) then
		rem --- Capture new aon location value so can tell later if it's been changed
		callpoint!.setDevObject("prev_new_aon_loc",new_aon_loc$)

		rem --- Initialize aon directory from new aon location
		filePath$=new_aon_loc$
		gosub fix_path
		aonDir$=filePath$+"/aon/"

		rem --- Use addon.syn file from BASIS product download location
		bbjHome$ = System.getProperty("basis.BBjHome")
		synFile$=bbjHome$+"/apps/aon/config/addon.syn"
		
		rem --- Initialize grid
		gosub create_reports_vector
		callpoint!.setDevObject("newSynRows",vectRows!)
		if cvs(callpoint!.getDevObject("prev_old_aon_loc"),3)<>"" then
			callpoint!.setStatus("REFRESH")
			gosub fill_grid
			util.resizeWindow(Form!, SysGui!)
		endif
	endif
