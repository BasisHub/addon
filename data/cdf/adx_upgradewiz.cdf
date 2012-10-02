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

rem This routine is executed when callbacks have been set to run a 'custom event'.
rem Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind of event it is.
rem See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info.

	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ctl_ID=dec(gui_event.ID$)

	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
	endif

	rem --- Edit app grid
	if ctl_ID=num(callpoint!.getDevObject("app_grid_id")) then

		e!=SysGUI!.getLastEvent()
		appGrid!=callpoint!.getDevObject("appGrid")
		appRowVect!=callpoint!.getDevObject("appRowVect")
		app_grid_def_cols=num(callpoint!.getDevObject("app_grid_def_cols"))
		index=e!.getRow()*app_grid_def_cols

		switch notice.code
			case 7; rem --- ON_GRID_EDIT_STOP
				rem --- Capture changes to app target
				if e!.getColumn()=5 then
					rem --- Modified target
					target$=cvs(appGrid!.getCellText(e!.getRow(),5),3)
					if target$<>appRowVect!.getItem(index+5) then
						rem --- Update appRowVect! for modified target
						appRowVect!.removeItem(index+5)
						appRowVect!.insertItem(index+5, target$); rem Target

						rem --- Update stblRowVect! for modified target (remove old, add new)
						stblRowVect!=callpoint!.getDevObject("stblRowVect")
						appName$=appRowVect!.get(index+0)
						gosub remove_app_stbl_vector; rem --- remove old rows
						oldDir$=appRowVect!.get(index+4)
						synFile$=oldDir$+"config/"+cvs(appName$,8)+".syn"
						newDir$=target$
						gosub build_stbl_vector; rem --- add new rows
						callpoint!.setDevObject("stblRowVect",stblRowVect!)
						gosub fill_stbl_grid
					endif
				endif
			break
			case 12; rem --- ON_GRID_KEY_PRESS
				rem ---  Allow space-bar toggle of checkboxes
				if (e!.getColumn()=2 or e!.getColumn()=3) and notice.wparam=32 then
					onoff=iff(appGrid!.getCellState(e!.getRow(),e!.getColumn()),0,1)
					gosub update_app_grid
				endif
			break
			case 30; rem --- ON_GRID_CHECK_ON and ON_GRID_CHECK_OFF
				rem --- isChecked() is the state when event sent before control is updated,
				rem --- so use !isChecked() to get current state of control
				if e!.getColumn()=2 or e!.getColumn()=3 then
					onoff=!e!.isChecked()
					gosub update_app_grid
				endif
			break
		swend
	endif

	rem --- Edit stbl grid
	if ctl_ID=num(callpoint!.getDevObject("stbl_grid_id")) then

		e!=SysGUI!.getLastEvent()
		stblGrid!=callpoint!.getDevObject("stblGrid")
		stblRowVect!=callpoint!.getDevObject("stblRowVect")
		stbl_grid_def_cols=num(callpoint!.getDevObject("stbl_grid_def_cols"))
		index=e!.getRow()*stbl_grid_def_cols

		switch notice.code
			case 7; rem --- ON_GRID_EDIT_STOP
				rem --- Capture changes to STBL target
				if e!.getColumn()=3 then
					rem --- Update stblRowVect! for modified target
					stblRowVect!.removeItem(index+3)
					stblRowVect!.insertItem(index+3, cvs(stblGrid!.getCellText(e!.getRow(),3),3)); rem Target
				endif
			break
		swend
	endif
[[ADX_UPGRADEWIZ.ASIZ]]
rem --- Resize grids

	formHeight=Form!.getHeight()
	formWidth=Form!.getWidth()
	appGrid!=callpoint!.getDevObject("appGrid")
	appYpos=appGrid!.getY()
	appXpos=appGrid!.getX()
	availableHeight=formHeight-appYpos
	appHeight=int((availableHeight-15)/4)
	stblYpos=160+appHeight+15
	stblHeight=int(3*(availableHeight-15)/4)

	rem --- Resize application grid
	appGrid!.setSize(formWidth-2*appXpos,appHeight)
	appGrid!.setFitToGrid(1)

	rem --- Resize STBL grid
	stblGrid!=callpoint!.getDevObject("stblGrid")
	stblGrid!.setLocation(10,stblYpos)
	stblGrid!.setSize(formWidth-2*appXpos,stblHeight)
	stblGrid!.setFitToGrid(1)
[[ADX_UPGRADEWIZ.AWIN]]
rem --- Add grids to form

	use ::ado_util.src::util

	rem --- Get column headings for grids
	aon_application_label$=Translate!.getTranslation("AON_APPLICATION")
	aon_app_parent_label$=Translate!.getTranslation("AON_APP_PARENT")
	aon_copy_label$=Translate!.getTranslation("AON_COPY")
	aon_install_label$=Translate!.getTranslation("AON_INSTALL")
	aon_source_label$=Translate!.getTranslation("AON_SOURCE")
	aon_stbl_prefix_lable$=Translate!.getTranslation("AON_STBL_PREFIX")
	aon_target_label$=Translate!.getTranslation("AON_TARGET")

	rem --- Add grid to form for applications to be copied and/or installed
	nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))
	appGrid!=Form!.addGrid(nxt_ctlID,10,160,850,80); rem --- ID, x, y, width, height
	callpoint!.setDevObject("appGrid",appGrid!)
	callpoint!.setDevObject("app_grid_id",str(nxt_ctlID))
	callpoint!.setDevObject("app_grid_def_cols",6)
	callpoint!.setDevObject("app_grid_min_rows",4)
	gosub format_app_grid
	appGrid!.setColumnStyle(2,SysGUI!.GRID_STYLE_UNCHECKED)
	appGrid!.setColumnEditable(2,1)
	appGrid!.setColumnStyle(3,SysGUI!.GRID_STYLE_UNCHECKED)
	appGrid!.setColumnEditable(3,1)
	appGrid!.setColumnEditable(5,1)
	appGrid!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)

	rem --- Add grid to form for updating STBLs and PREFIXs with paths
	nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))+1
	stblGrid!=Form!.addGrid(nxt_ctlID,10,255,850,250); rem --- ID, x, y, width, height
	callpoint!.setDevObject("stblGrid",stblGrid!)
	callpoint!.setDevObject("stbl_grid_id",str(nxt_ctlID))
	callpoint!.setDevObject("stbl_grid_def_cols",4)
	callpoint!.setDevObject("stbl_grid_min_rows",16)
	gosub format_stbl_grid
	stblGrid!.setColumnEditable(3,1)
	stblGrid!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)

	rem --- misc other init
	util.resizeWindow(Form!, SysGui!)

	rem --- set callbacks - processed in ACUS callpoint
	appGrid!.setCallback(appGrid!.ON_GRID_CHECK_ON,"custom_event")
	appGrid!.setCallback(appGrid!.ON_GRID_CHECK_OFF,"custom_event")
	appGrid!.setCallback(appGrid!.ON_GRID_KEY_PRESS,"custom_event")
	rem --- Currently ON_GRID_CELL_EDIT_STOP results in the loss of user input when 
	rem --- they Run Process (F5) before leaving the cell where text was entered.
	appGrid!.setCallback(appGrid!.ON_GRID_EDIT_STOP,"custom_event")
	rem --- Currently ON_GRID_CELL_EDIT_STOP results in the loss of user input when 
	rem --- they Run Process (F5) before leaving the cell where text was entered.
	stblGrid!.setCallback(stblGrid!.ON_GRID_EDIT_STOP,"custom_event")
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

rem --- Validate sync backup directory when not doing Create Sync File Backup

	if callpoint!.getDevObject("do_sync_backup")=0 then
		sync_backup_dir$ = callpoint!.getColumnData("ADX_UPGRADEWIZ.SYNC_BACKUP_DIR")
		gosub validate_sync_backup_dir
		callpoint!.setColumnData("ADX_UPGRADEWIZ.SYNC_BACKUP_DIR",sync_backup_dir$)
		if abort then break
	endif

rem --- Make sure we get all entries in the grid by setting focus on some control besides the grid

	ctl!=callpoint!.getControl("ADX_UPGRADEWIZ.NEW_AON_LOC")
	ctl!.focus()

rem --- Capture app grid in Vector (order is important) for backend programs

	declare Vector appVect!
	declare ArrayList aList!

	appVect!=new Vector()
	appGrid!=callpoint!.getDevObject("appGrid")
	appRowVect!=callpoint!.getDevObject("appRowVect")
	app_grid_def_cols=num(callpoint!.getDevObject("app_grid_def_cols"))

	for i=0 to appRowVect!.size()-1 step app_grid_def_cols
		aList!=new ArrayList()
		aList!.add(appRowVect!.getItem(i+0)); rem Application
		aList!.add(appRowVect!.getItem(i+1)); rem App Parent
		aList!.add(appRowVect!.getItem(i+2)); rem Install
		aList!.add(appRowVect!.getItem(i+3)); rem Copy
		aList!.add(appRowVect!.getItem(i+4)); rem Source
		aList!.add(appRowVect!.getItem(i+5)); rem Target
		appVect!.add(aList!)
	next i

	callpoint!.setDevObject("appVect",appVect!)

rem --- Capture stbl grid in data structur for backend programs

	declare HashMap appStblMap!
	declare Vector stblVect!

	appStblMap!=new HashMap()
	stblRowVect!=callpoint!.getDevObject("stblRowVect")
	stbl_grid_def_cols=num(callpoint!.getDevObject("stbl_grid_def_cols"))

	for i=0 to stblRowVect!.size()-1 step stbl_grid_def_cols
		aList!=new ArrayList()
		aList!.add(stblRowVect!.getItem(i+0)); rem Application
		aList!.add(stblRowVect!.getItem(i+1)); rem STBL or <prefix>
		aList!.add(stblRowVect!.getItem(i+2)); rem Source
		aList!.add(stblRowVect!.getItem(i+3)); rem Target

		app$=stblRowVect!.getItem(i+0)
		if appStblMap!.containsKey(app$) then
			stblVect! = cast(Vector, appStblMap!.get(app$))
			stblVect!.add(aList!)
		else
			stblVect! = new Vector()
			stblVect!.add(aList!)
			appStblMap!.put(app$, stblVect!)
		endif
	next i

	callpoint!.setDevObject("appStblMap",appStblMap!)
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
		
	rem --- Re-initialize app grid whenever old barista location changes
	if cvs(old_bar_loc$,3)<>cvs(callpoint!.getDevObject("prev_old_bar_loc"),3) then
		callpoint!.setDevObject("prev_old_bar_loc",old_bar_loc$)

		rem --- Initialize app grid, i.e. set defaults for data apps
		gosub create_app_vector
		callpoint!.setDevObject("appRowVect",appRowVect!)
		gosub fill_app_grid
		util.resizeWindow(Form!, SysGui!)
		callpoint!.setStatus("REFRESH")
	endif


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
	use java.util.Iterator
	use java.util.Vector
	use ::ado_file.src::FileObject
	use ::adx_upgradewiz.aon::AppHeritage

rem --- Initialize location values so can tell later if they have changed

	callpoint!.setDevObject("prev_new_aon_loc","")
	callpoint!.setDevObject("prev_old_aon_loc","")
	callpoint!.setDevObject("prev_old_bar_loc","")
[[ADX_UPGRADEWIZ.OLD_AON_LOC.AVAL]]
rem --- Validate old aon install location

	old_aon_loc$ = callpoint!.getUserInput()
	gosub validate_old_aon_loc
	callpoint!.setUserInput(old_aon_loc$)
	if abort then break
	
rem --- Initializations when old aon install location changes
	if cvs(old_aon_loc$,3)<>cvs(callpoint!.getDevObject("prev_old_aon_loc"),3) then
		rem --- Capture old aon location value so can tell later if it's been changed
		callpoint!.setDevObject("prev_old_aon_loc",old_aon_loc$)

		rem --- Initialize old Barista install location
		old_bar_loc$=old_aon_loc$
		gosub able_old_bar_loc

		rem --- Initialize old Barista admin_backup
		bar_dir$=cvs(callpoint!.getColumnData("ADX_UPGRADEWIZ.OLD_BAR_LOC"),3)+"/barista"
		gosub able_backup_sync_dir

		rem --- Initialize aon directory from new aon location
		filePath$=callpoint!.getDevObject("prev_new_aon_loc")
		gosub fix_path
		newDir$=filePath$+"/aon/"

		rem --- Use addon.syn file from old aon location
		synFile$=old_aon_loc$+"/aon/config/addon.syn"
		
		rem --- Initialize STBL grid, i.e. set defaults for data STBLs
		stblRowVect!=SysGUI!.makeVector()
		gosub build_stbl_vector
		callpoint!.setDevObject("oldSynRows",stblRowVect!)
		if cvs(callpoint!.getDevObject("prev_new_aon_loc"),3)<>"" then
			gosub init_stbl_grid
			util.resizeWindow(Form!, SysGui!)
			callpoint!.setStatus("REFRESH")
		endif
		
		rem --- Re-initialize app grid whenever old barista location changes
		rem --- Must be done after stbl grid is initialized
		if cvs(old_bar_loc$,3)<>cvs(callpoint!.getDevObject("prev_old_bar_loc"),3) then
			callpoint!.setDevObject("prev_old_bar_loc",old_bar_loc$)

			rem --- Initialize app grid, i.e. set defaults for data apps
			gosub create_app_vector
			callpoint!.setDevObject("appRowVect",appRowVect!)
			gosub fill_app_grid
			util.resizeWindow(Form!, SysGui!)
			callpoint!.setStatus("REFRESH")
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

	rem --- Read-Write-Execute directory permissions are required

	if !FileObject.isDirWritable(new_aon_loc$)
		msg_id$="AD_DIR_NOT_WRITABLE"
		dim msg_tokens$[1]
		msg_tokens$[1]=new_aon_loc$
		gosub disp_message

		callpoint!.setColumnData("ADX_COPYAON.NEW_INSTALL_LOC", new_aon_loc$)
		callpoint!.setFocus("ADX_COPYAON.NEW_INSTALL_LOC")
		callpoint!.setStatus("ABORT")
		abort=1
		return
	endif

	rem --- Cannot be currently used by Addon

	testChan=unt
	open(testChan, err=*return)new_aon_loc$ + "/aon/data"; rem --- successful return here
	close(testChan)

	rem --- Location is used by Addon
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

	rem --- Check version of old Barista (will automatically do Create Sync File Backup if at least version 12)
	rem --- Locate the database for old Barista
	dbname$ = ""
	oldBarDir$=bar_dir$
	if pos(":"=oldBarDir$)=0 then oldBarDir$=dsk("")+oldBarDir$
	sourceChan=unt
	open(sourceChan,isz=-1)oldBarDir$+"/sys/config/enu/barista.cfg"
	while 1
		read(sourceChan,end=*break)record$
		rem --- get database from SET +DBNAME line
		if pos("SET +DBNAME="=record$)=1 then
			dbname$=record$(pos("="=record$)+1)
			break
		endif
	wend
	close(sourceChan)

	rem --- Query old ADM_MODULES for Barista Administration version
	sql_chan=sqlunt
	sqlopen(sql_chan)dbname$
	sql_prep$="SELECT version_id FROM adm_modules where asc_comp_id='01007514' and asc_prod_id='ADB'"
	sqlprep(sql_chan)sql_prep$
	dim select_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)
	select_tpl$=sqlfetch(sql_chan,err=*break) 
	adb_version$=cvs(select_tpl.version_id$,3)
	sqlclose(sql_chan)

	rem --- Automatically do Create Sync File Backup if old Barista is at least version 12
	if num(adb_version$)>=12 then
		do_sync_backup=1
	else
		do_sync_backup=0
	endif
	callpoint!.setDevObject("do_sync_backup",do_sync_backup)

	if backup_found or do_sync_backup then
		rem --- Initialize and disable sync backup directory
		callpoint!.setColumnEnabled("ADX_UPGRADEWIZ.SYNC_BACKUP_DIR",0)
		callpoint!.setColumnData("ADX_UPGRADEWIZ.SYNC_BACKUP_DIR",bar_dir$ + "/admin_backup")
	else
		rem --- Enable sync backup directory
		callpoint!.setColumnEnabled("ADX_UPGRADEWIZ.SYNC_BACKUP_DIR",1)
		callpoint!.setColumnData("ADX_UPGRADEWIZ.SYNC_BACKUP_DIR","")
	endif

	callpoint!.setStatus("REFRESH")

	return

format_app_grid: rem --- Format application grid

	app_grid_def_cols=callpoint!.getDevObject("app_grid_def_cols")
	app_rpts_rows=callpoint!.getDevObject("app_grid_min_rows")

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()

	dim attr_rpts_col$[app_grid_def_cols,len(attr_def_col_str$[0,0])/5]
	attr_rpts_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="APP"
	attr_rpts_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=aon_application_label$
	attr_rpts_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="55"

	attr_rpts_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="APP_PARENT"
	attr_rpts_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=aon_app_parent_label$
	attr_rpts_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="55"

	attr_rpts_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="INSTALL"
	attr_rpts_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=aon_install_label$
	attr_rpts_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"

	attr_rpts_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="COPY"
	attr_rpts_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=aon_copy_label$
	attr_rpts_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"

	attr_rpts_col$[5,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="APP_SOURCE"
	attr_rpts_col$[5,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=aon_source_label$
	attr_rpts_col$[5,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="345"

	attr_rpts_col$[6,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="APP_TARGET"
	attr_rpts_col$[6,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=aon_target_label$
	attr_rpts_col$[6,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="345"
	attr_rpts_col$[6,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="256"

	for curr_attr=1 to app_grid_def_cols
		attr_rpts_col$[0,1]=attr_rpts_col$[0,1]+pad("UPGRADEWIZ."+attr_rpts_col$[curr_attr,
:			fnstr_pos("DVAR",attr_def_col_str$[0,0],5)],40)
	next curr_attr

	attr_disp_col$=attr_rpts_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,appGrid!,"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC",app_rpts_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_rpts_col$[all]

	return

rem ==========================================================================
create_app_vector: rem --- Create a vector of applications from the OLD ddm_systems table to fill the app grid
		rem      IN: old_bar_loc$
		rem     OUT: appRowVect!
rem ==========================================================================

	rem --- Application heritage must come from OLD system.
	rem --- Locate the database for the OLD system, and quiry the DDM_SYSTEMS table.
	dbname$ = ""
	bar_dir$=old_bar_loc$+"/barista"
	if pos(":"=bar_dir$)=0 then bar_dir$=dsk("")+bar_dir$
	sourceChan=unt
	open(sourceChan,isz=-1)bar_dir$+"/sys/config/"+cvs(stbl("+LANGUAGE_ORIGIN"),8)+"/barista.cfg"
	while 1
		read(sourceChan,end=*break)record$
		rem --- get database from SET +DBNAME line
		if pos("SET +DBNAME="=record$)=1 then
			dbname$=record$(pos("="=record$)+1)
		break
		endif
		wend
	close(sourceChan)

	rem --- Build HashMap of all parent and child applications. The HashMap is keyed by the parent,
	rem --- and holds a Vector of all the children for that parent.
	declare HashMap appMap!
	appMap! = new HashMap()
	declare Vector rootVect!
	rootVect! = new Vector()
	declare Vector childVect!
	declare HashMap propMap!
	sql_chan=sqlunt
	sqlopen(sql_chan)dbname$
	sql_prep$="SELECT mount_sys_id, mount_dir, parent_sys_id FROM ddm_systems order by mount_seq_no"
	sqlprep(sql_chan)sql_prep$
	dim select_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)
	while 1
		select_tpl$=sqlfetch(sql_chan,err=*break) 
		child$=cvs(select_tpl.mount_sys_id$,3)
		child_dir$=cvs(select_tpl.mount_dir$,3)
		parent$=cvs(select_tpl.parent_sys_id$,3)
		propMap! = new HashMap()
		propMap!.put("mount_sys_id",child$)
		propMap!.put("mount_dir",child_dir$)
		propMap!.put("parent_sys_id",parent$)
		if parent$="" then
			rootVect!.add(propMap!)
		else
			if appMap!.containsKey(parent$) then
				childVect! = cast(Vector, appMap!.get(parent$))
				childVect!.add(propMap!)
			else
				childVect! = new Vector()
				childVect!.add(propMap!)
				appMap!.put(parent$, childVect!)
			endif
		endif
	wend
	sqlclose(sql_chan)

	rem --- Build rows for app grid
	appRowVect!=SysGUI!.makeVector()
	rootIter!=rootVect!.iterator()
	while rootIter!.hasNext()
		rootProps!=cast(HashMap, rootIter!.next())

		rem --- Add root app row unless ADDON
		rootApp$=cast(BBjString, rootProps!.get("mount_sys_id"))
		if rootApp$<>"ADDON" then
			appRowVect!.addItem(rootApp$); rem App
			appRowVect!.addItem(""); rem Parent
			appRowVect!.addItem("y"); rem Install
			appRowVect!.addItem("n"); rem Copy
			appRowVect!.addItem(cast(BBjString, rootProps!.get("mount_dir"))); rem Source
			appRowVect!.addItem(""); rem Target
		endif

		rem --- Add child app rows for this root app
		declare AppHeritage heritage!
		heritage! = new AppHeritage(appMap!)
		declare Vector descendentVect!
		descendentVect! = heritage!.getDescendents(rootApp$)
		if descendentVect!.size()>0 then
			for i=0 to descendentVect!.size()-1
				childProps! = cast(HashMap, descendentVect!.get(i))
				appRowVect!.addItem(cast(BBjString, childProps!.get("mount_sys_id"))); rem App
				appRowVect!.addItem(cast(BBjString, childProps!.get("parent_sys_id"))); rem Parent
				appRowVect!.addItem("y"); rem Install
				if rootApp$="ADDON" then
					appRowVect!.addItem("y"); rem Copy
				else
					appRowVect!.addItem("n"); rem Copy
				endif
				appRowVect!.addItem(cast(BBjString, childProps!.get("mount_dir"))); rem Source
				if rootApp$="ADDON" then
					sourceDir$=cast(BBjString, childProps!.get("mount_dir"))
					gosub build_target_dir
					appRowVect!.addItem(targetDir$); rem Target
				else
					appRowVect!.addItem(""); rem Target
				endif
			next i
		endif
	wend

	rem ---Make sure grid has at least minimum number of rows
	while appRowVect!.size()<callpoint!.getDevObject("app_grid_def_cols")*callpoint!.getDevObject("app_grid_min_rows")
		appRowVect!.addItem(""); rem App
		appRowVect!.addItem(""); rem Parent
		appRowVect!.addItem(""); rem Install
		appRowVect!.addItem(""); rem Copy
		appRowVect!.addItem(""); rem Source
		appRowVect!.addItem(""); rem Target
	wend
	
	return

fill_app_grid: rem --- Fill the app grid with data in appRowVect!

	SysGUI!.setRepaintEnabled(0)
	stblRowVect!=callpoint!.getDevObject("stblRowVect")
	appGrid!=callpoint!.getDevObject("appGrid")
	appGrid!.clearMainGrid()
	if appRowVect!.size()
		numrow=appRowVect!.size()/appGrid!.getNumColumns()
		appGrid!.setNumRows(numrow)
		appGrid!.setCellText(0,0,appRowVect!)

		rem --- Set cell properties
		for i=0 to appRowVect!.size()-1 step appGrid!.getNumColumns()
			row=i/appGrid!.getNumColumns()

			rem --- Disable blank rows
			if appRowVect!.getItem(i)="" then
				appGrid!.setRowEditable(row, 0)
			endif

			rem --- Set install checkbox
			if appRowVect!.getItem(i+2) = "y" then 
				appGrid!.setCellStyle(row, 2, SysGUI!.GRID_STYLE_CHECKED)
				appGrid!.setCellEditable(row,3,1); rem Copy
				appGrid!.setCellEditable(row,5,1); rem Target
			else
				appGrid!.setCellStyle(row, 2, SysGUI!.GRID_STYLE_UNCHECKED)
				appGrid!.setCellEditable(row,3,0); rem Copy
				appGrid!.setCellEditable(row,5,0); rem Target
			endif
			appGrid!.setCellText(row, 2, "")

			rem --- Set copy checkbox
			if appRowVect!.getItem(i+3) = "y" then 
				appGrid!.setCellStyle(row, 3, SysGUI!.GRID_STYLE_CHECKED)
				appGrid!.setCellEditable(row,5,1); rem Target

				rem --- Update stblRowVect! for copied application
				appName$=appRowVect!.getItem(i+0)
				oldDir$=appRowVect!.getItem(i+4)
				synFile$=oldDir$+"config/"+cvs(appName$,8)+".syn"
				newDir$=appRowVect!.getItem(i+5)
				gosub build_stbl_vector
			else
				appGrid!.setCellStyle(row, 3, SysGUI!.GRID_STYLE_UNCHECKED)
				appGrid!.setCellEditable(row,5,0); rem Target
			endif
			appGrid!.setCellText(row, 3, "")
		next i
	endif
	rem --- Update stbl grid with stblRowVect! updated for copied applications
	callpoint!.setDevObject("stblRowVect",stblRowVect!)
	gosub fill_stbl_grid
	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
update_app_grid: rem --- Update app grid row when checkboxes are checked/unchecked
		rem      IN: e!
		rem      IN: appGrid!
		rem      IN: appRowVect!
		rem      IN: onoff
rem ==========================================================================

	SysGUI!.setRepaintEnabled(0)
	stblRowVect!=callpoint!.getDevObject("stblRowVect")
    	app_grid_def_cols=callpoint!.getDevObject("app_grid_def_cols")
	index=e!.getRow()*app_grid_def_cols

	rem --- Install checkbox
	if e!.getColumn()=2 then
		if onoff then
			rem --- Checked
			appGrid!.setCellStyle(e!.getRow(),2,SysGUI!.GRID_STYLE_CHECKED); rem Install
			appGrid!.setCellEditable(e!.getRow(),3,1); rem Copy
			sourceDir$=appRowVect!.get(index+4)
			appGrid!.setCellText(e!.getRow(),4,sourceDir$); rem Source

			rem --- Update appRowVect! for checked install
			appRowVect!.removeItem(index+2)
			appRowVect!.insertItem(index+2, "y"); rem Install
			appRowVect!.removeItem(index+4)
			appRowVect!.insertItem(index+4, sourceDir$); rem Source
		else
			rem --- Unchecked
			appGrid!.setCellStyle(e!.getRow(),2,SysGUI!.GRID_STYLE_UNCHECKED); rem Install
			appGrid!.setCellStyle(e!.getRow(),3,SysGUI!.GRID_STYLE_UNCHECKED); rem Copy
			appGrid!.setCellEditable(e!.getRow(),3,0); rem Copy
			appGrid!.setCellText(e!.getRow(),4,""); rem Source
			appGrid!.setCellText(e!.getRow(),5,""); rem Target
			appGrid!.setCellEditable(e!.getRow(),5,0); rem Target

			rem --- Update appRowVect! for unchecked install
			appRowVect!.removeItem(index+2)
			appRowVect!.insertItem(index+2, "n"); rem Install
			appRowVect!.removeItem(index+3)
			appRowVect!.insertItem(index+3, "n"); rem Copy
			appRowVect!.removeItem(index+4)
			appRowVect!.insertItem(index+4, ""); rem Source
			appRowVect!.removeItem(index+5)
			appRowVect!.insertItem(index+5, ""); rem Target

			rem --- Update stblRowVect! for uncopied application
			appName$=appRowVect!.get(index+0)
			gosub remove_app_stbl_vector
		endif
	endif

	rem --- Copy checkbox
	if e!.getColumn()=3 then
		if onoff then
			rem --- Checked
			appGrid!.setCellStyle(e!.getRow(),3,SysGUI!.GRID_STYLE_CHECKED); rem Copy
			sourceDir$=appRowVect!.get(index+4)
			gosub build_target_dir
			appGrid!.setCellText(e!.getRow(),5,targetDir$); rem Target
			appGrid!.setCellEditable(e!.getRow(),5,1); rem Target

			rem --- Update appRowVect! for checked copy
			appRowVect!.removeItem(index+3)
			appRowVect!.insertItem(index+3, "y"); rem Copy
			appRowVect!.removeItem(index+5)
			appRowVect!.insertItem(index+5, targetDir$); rem Target

			rem --- Update stblRowVect! for copied application
			appName$=appRowVect!.get(index+0)
			oldDir$=appRowVect!.get(index+4)
			synFile$=oldDir$+"config/"+cvs(appName$,8)+".syn"
			newDir$=appRowVect!.get(index+5)
			gosub build_stbl_vector
		else
			rem --- Unchecked
			appGrid!.setCellStyle(e!.getRow(),3,SysGUI!.GRID_STYLE_UNCHECKED); rem Copy
			appGrid!.setCellText(e!.getRow(),5,""); rem Target
			appGrid!.setCellEditable(e!.getRow(),5,0); rem Target

			rem --- Update appRowVect! for unchecked copy
			appRowVect!.removeItem(index+3)
			appRowVect!.insertItem(index+3, "n"); rem Copy
			appRowVect!.removeItem(index+5)
			appRowVect!.insertItem(index+5, ""); rem Target

			rem --- Update stblRowVect! for uncopied application
			appName$=appRowVect!.get(index+0)
			gosub remove_app_stbl_vector
		endif
	endif

	rem --- Update stbl grid with stblRowVect! updated for copied/uncopied applications
	callpoint!.setDevObject("stblRowVect",stblRowVect!)
	gosub fill_stbl_grid
	SysGUI!.setRepaintEnabled(1)

	return

format_stbl_grid: rem --- Format STBL grid

	stbl_grid_def_cols=callpoint!.getDevObject("stbl_grid_def_cols")
	stbl_rpts_rows=callpoint!.getDevObject("stbl_grid_min_rows")

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()

	dim attr_rpts_col$[stbl_grid_def_cols,len(attr_def_col_str$[0,0])/5]
	attr_rpts_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="TYPE"
	attr_rpts_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=aon_application_label$
	attr_rpts_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="55"

	attr_rpts_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="STBL"
	attr_rpts_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=aon_stbl_prefix_lable$
	attr_rpts_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="150"

	attr_rpts_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="STBL_SOURCE"
	attr_rpts_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=aon_source_label$
	attr_rpts_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="345"

	attr_rpts_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="STBL_TARGET"
	attr_rpts_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=aon_target_label$
	attr_rpts_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="345"
	attr_rpts_col$[4,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="256"

	for curr_attr=1 to stbl_grid_def_cols
		attr_rpts_col$[0,1]=attr_rpts_col$[0,1]+pad("UPGRADEWIZ."+attr_rpts_col$[curr_attr,
:			fnstr_pos("DVAR",attr_def_col_str$[0,0],5)],40)
	next curr_attr

	attr_disp_col$=attr_rpts_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,stblGrid!,"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC",stbl_rpts_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_rpts_col$[all]

	return

init_stbl_grid: rem --- Initialize the STBL grid with data in stblRowVect! for only ADDON

	newSynRows!=callpoint!.getDevObject("newSynRows")
	oldSynRows!=callpoint!.getDevObject("oldSynRows")
	gosub merge_vect_rows
	callpoint!.setDevObject("stblRowVect",stblRowVect!)
	gosub fill_stbl_grid

	return

fill_stbl_grid: rem --- Fill the STBL grid with data in stblRowVect!

	SysGUI!.setRepaintEnabled(0)
	stblGrid!=callpoint!.getDevObject("stblGrid")
	if stblRowVect!.size()
		numrow=stblRowVect!.size()/stblGrid!.getNumColumns()
		stblGrid!.clearMainGrid()
		stblGrid!.setNumRows(numrow)
		stblGrid!.setCellText(0,0,stblRowVect!)
	endif
	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
merge_vect_rows: rem --- Merge new and old syn row vectors into a single vector of STBLs and PREFIXs
		rem      IN: newSynRows!
		rem          oldSynRows!
		rem     OUT: stblRowVect!
rem ==========================================================================

	stblRowVect!=oldSynRows!
	if newSynRows!.size()>0
		numCols=num(callpoint!.getDevObject("stbl_grid_def_cols"))

		for i=0 to newSynRows!.size()-1 step numCols
			type$=newSynRows!.getItem(i+1)
			addLine=0

			rem --- replace updated target value of old STBL lines as needed
			if type$<>"<prefix>"
				stbl$=newSynRows!.getItem(i+1)
				addLine=1
				for j=0 to stblRowVect!.size()-1 step numCols
					if stblRowVect!.getItem(j+1)<>stbl$ then continue
					if stbl$="+MDI_TITLE" then
						stblRowVect!.setItem(j+3, callpoint!.getColumnData("ADX_UPGRADEWIZ.APP_DESC"))
					endif
					addLine=0
					break
				next j
			endif

			rem --- replace updated target value of old PREFIX lines as needed
			if type$="<prefix>"
				source$=newSynRows!.getItem(i+2)
				addLine=1
				for j=0 to stblRowVect!.size()-1 step numCols
					if stblRowVect!.getItem(j+2)<>source$ then continue
					addLine=0
					break
				next j
			endif
				
			rem --- if new STBL or new PREFIX not found, add it
			if addLine then
				stblRowVect!.addItem(newSynRows!.getItem(i+0)); rem App
				stblRowVect!.addItem(newSynRows!.getItem(i+1)); rem STBL or PRFIX
				stblRowVect!.addItem(newSynRows!.getItem(i+2)); rem Source
				stblRowVect!.addItem(newSynRows!.getItem(i+3)); rem Target
			endif
		next i
	endif

	return

rem ==========================================================================
remove_app_stbl_vector: rem --- Remove application from stblRowVect!
		rem      IN: appName$
		rem  IN-OUT: stblRowVect!
rem ==========================================================================

	if stblRowVect!.size()>0 then
		tempVect!=SysGUI!.makeVector()
		numCols=num(callpoint!.getDevObject("stbl_grid_def_cols"))

		rem --- copy stblRowVect! to tempVect!
		for j=0 to stblRowVect!.size()-1 step numCols
			rem --- skip if application is the one being removed
			if stblRowVect!.getItem(j+0)=appName$ then continue
			tempVect!.addItem(stblRowVect!.getItem(j+0)); rem App
			tempVect!.addItem(stblRowVect!.getItem(j+1)); rem STBL or PRFIX
			tempVect!.addItem(stblRowVect!.getItem(j+2)); rem Source
			tempVect!.addItem(stblRowVect!.getItem(j+3)); rem Target
		next j

		rem --- assign tempVect! to stblRowVect!
		stblRowVect!=tempVect!
	endif

	return

rem ==========================================================================
build_stbl_vector: rem --- Create a vector of STBLs and PREFIXs from the source syn file to fill the STBL grid.
		rem      IN: newDir$
		rem      IN: synFile$
		rem  IN-OUT: stblRowVect!
rem ==========================================================================

	synDev=unt, more=0
	open(synDev,isz=-1,err=*return)synFile$; more=1

	oldDir$=""
	while more
		read(synDev,end=*break)record$

		rem  --- get application name
		rem --- parse from SYS line
		if pos("SYS="=record$) = 1 then
			xpos = pos("="=record$)
			appName$= record$(xpos+1,pos(";"=record$(xpos+1))-1)
		endif
		rem --- parse from SYSID line
		if pos("SYSID="=record$) = 1 then
			xpos = pos("="=record$)
			appName$= cvs(record$(xpos+1),3)
		endif

		rem --- get old aon path from SYSDIR/DIR line
		rem --- it must be replaced everywhere with current aon path.
		if(pos("DIR="=record$) = 1 or pos("SYSDIR="=record$) = 1) then
			xpos = pos("="=record$)
			oldDir$= cvs(record$(xpos+1),3)
		endif

		rem --- process SYSSTBL/STBL lines
		if(pos("STBL="=record$) = 1 or pos("SYSSTBL="=record$) = 1) then
			xpos = pos(" "=record$)
			stbl$ = record$(xpos+1, pos("="=record$(xpos+1))-1)
			source_value$=cvs(record$(pos("="=record$,1,2)+1),3)
			gosub source_target_value
			stblRowVect!.addItem(appName$)
			stblRowVect!.addItem(stbl$)
			stblRowVect!.addItem(source_value$)
			stblRowVect!.addItem(target_value$)
		endif

		rem --- process SYSPFX/PREFIX lines
		if(pos("PREFIX"=record$) = 1 or pos("SYSPFX"=record$) = 1) then
			source_value$=cvs(record$(pos("="=record$)+1),3)
			gosub source_target_value
			stblRowVect!.addItem(appName$)
			stblRowVect!.addItem("<prefix>")
			stblRowVect!.addItem(source_value$)
			stblRowVect!.addItem(target_value$)
		endif
	wend
	close(synDev)
	
	return

rem ==========================================================================
source_target_value: rem -- Set default new target value based on new config location
		rem      IN: newDir$
		rem      IN: oldDir$
		rem      IN: source_value$
		rem      OUT: target_value$
rem ==========================================================================

	target_value$=source_value$

	rem --- If source holds a path, then need to initialize default new target value
	declare File aFile!
	aFile! = new File(source_value$)
	if aFile!.exists() and newDir$<>"" and oldDir$<>"" then
		record$=target_value$
		search$=oldDir$
		replace$=newDir$
		gosub search_replace
		target_value$=record$
	endif

	filePath$=target_value$
	gosub fix_path
	target_value$=filePath$

	return

rem ==========================================================================
build_target_dir: rem --- Build target dir from source dir and new aon location
		rem      IN: sourceDir$
		rem     OUT: targetDir$
rem ==========================================================================

	filePath$=callpoint!.getDevObject("prev_new_aon_loc")
	gosub fix_path
	if filePath$(len(filePath$))<>"/" then filePath$=filePath$+"/"
	aonLoc$=filePath$

	filePath$=sourceDir$
	gosub fix_path
	if len(filePath$)=0 then
		targetDir$=aonLoc$
	else
		if filePath$(len(filePath$))<>"/" then filePath$=filePath$+"/"
		targetDir$=aonLoc$+filePath$(pos("/"=filePath$,-1,2)+1)
	endif

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
		newDir$=filePath$+"/aon/"

		rem --- Use addon.syn file from BASIS product download location
		bbjHome$ = System.getProperty("basis.BBjHome")
		synFile$=bbjHome$+"/apps/aon/config/addon.syn"
		
		rem --- Initialize STBL grid, i.e. set defaults for data STBLs
		stblRowVect!=SysGUI!.makeVector()
		gosub build_stbl_vector
		callpoint!.setDevObject("newSynRows",stblRowVect!)
		if cvs(callpoint!.getDevObject("prev_old_aon_loc"),3)<>"" then
			gosub init_stbl_grid
			util.resizeWindow(Form!, SysGui!)
			callpoint!.setStatus("REFRESH")
		endif
	endif
