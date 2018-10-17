[[ADX_UPDATEXML.BSHO]]
rem --- Declare Java classes used

	use java.io.File
	use ::adc_updatexmlfiles.aon::UpdateSyncXmlFiles
[[ADX_UPDATEXML.UPGRADE.AINP]]
rem --- Enable/disable input field for backup sync location

	old_sync_path$=callpoint!.getColumnData("ADX_UPDATEXML.OLD_SYNC_PATH")
	gosub able_backup_sync_dir
[[ADX_UPDATEXML.SYNC_BACKUP_DIR.AVAL]]
rem --- Validate directory for backup sync location

	loc_dir$ = callpoint!.getUserInput()
	gosub validate_backup_sync_dir
	callpoint!.setUserInput(loc_dir$)
[[ADX_UPDATEXML.OLD_SYNC_PATH.AVAL]]
rem --- Validate directory for old data/sync location

	loc_dir$ = callpoint!.getUserInput()
	gosub validate_old_sync_dir
	callpoint!.setUserInput(loc_dir$)

rem --- Enable/disable input field for backup sync location

	old_sync_path$=loc_dir$
	gosub able_backup_sync_dir
[[ADX_UPDATEXML.ASVA]]
rem --- Validate directory for new data/sync location

	loc_dir$ = callpoint!.getColumnData("ADX_UPDATEXML.NEW_SYNC_PATH")
	gosub validate_new_sync_dir
	if !success then callpoint!.setStatus("ABORT")

rem --- Validate directory for old data/sync location

	if num(callpoint!.getColumnData("ADX_UPDATEXML.UPGRADE"))
		loc_dir$ = callpoint!.getColumnData("ADX_UPDATEXML.OLD_SYNC_PATH")
		gosub validate_old_sync_dir
		if !success then callpoint!.setStatus("ABORT")
	endif

rem --- Validate directory for backup sync location

	if num(callpoint!.getColumnData("ADX_UPDATEXML.UPGRADE"))
		loc_dir$ = callpoint!.getColumnData("ADX_UPDATEXML.SYNC_BACKUP_DIR")
		gosub validate_backup_sync_dir
		if !success then callpoint!.setStatus("ABORT")
	endif
[[ADX_UPDATEXML.<CUSTOM>]]
able_backup_sync_dir: rem --- Enable/disable input field for backup sync location

	upgrade=num(callpoint!.getColumnData("ADX_UPDATEXML.UPGRADE"))
	if upgrade
		rem --- Sync backup dir isn't needed if old barista/admin_backup dir exists
		path$=old_sync_path$
                gosub parse_aon_path
		sync_backup_dir$=aon_dir$(1,pos("/"=aon_dir$,-1))+"barista/admin_backup"

		dir_found=0
		tmp_dev=unt
		open(tmp_dev,err=*next)sync_backup_dir$; dir_found=1
		close(tmp_dev,err=*next)

		if dir_found
			callpoint!.setColumnEnabled("ADX_UPDATEXML.SYNC_BACKUP_DIR",0)
			callpoint!.setColumnData("ADX_UPDATEXML.SYNC_BACKUP_DIR",sync_backup_dir$)
		else
			callpoint!.setColumnEnabled("ADX_UPDATEXML.SYNC_BACKUP_DIR",1)
		endif
	else
		callpoint!.setColumnEnabled("ADX_UPDATEXML.SYNC_BACKUP_DIR",0)
		callpoint!.setColumnData("ADX_UPDATEXML.SYNC_BACKUP_DIR","")
	endif
	callpoint!.setStatus("REFRESH")

	return

parse_aon_path: rem --- Enable/disable input field for backup sync location
	aon_dir$ = ""

	rem --- Flip directory path separators to "/"
	pos=pos("\"=path$)
	while pos
	path$=path$(1, pos-1)+"/"+path$(pos+1)
		pos=pos("\"=path$)
	wend

	rem --- Get aon directory location from path
	if pos("/aon/"=path$+"/")
		aon_dir$=path$(1, pos("/aon/"=path$+"/",-1) + len("/aon") - 1)
	else
		rem --- aon directory not found, so use directory containing the data directory
		if pos("/data/"=path$+"/")
			aon_dir$=path$(1, pos("/data/"=path$+"/",-1) - 1)
		endif
	endif

	return

validate_new_sync_dir: rem --- Validate directory for new data/sync location

	success=0

	focus$="ADX_UPDATEXML.NEW_SYNC_PATH"
	check_dir_name=1
	not_download_loc=1
	gosub validate_sync_dir

	rem --- can't be the same as old data/sync location
	if loc_dir$ = callpoint!.getColumnData("ADX_UPDATEXML.OLD_SYNC_PATH")
		msg_id$="AD_BAD_NEW_SYNC_DIR"
		gosub disp_message
		callpoint!.setFocus(focus$)
		callpoint!.setStatus("ABORT")
		return
	endif

	rem --- Get version of source Addon installation from source data/sync/adm_modules~01007514ad.xml
	utility! = new UpdateSyncXmlFiles(rdForm!,0)
	oldVers! = utility!.getModuleVersion(new File(loc_dir$))
	if oldVers!.get("AD")<>null() and num(oldVers!.get("AD"))<18
		rem --- The Barista instance for new data/sync location must be v18 or later.
		msg_id$="AD_NEW_LOC_NOT_V18"
		gosub disp_message
		callpoint!.setFocus(focus$)
		callpoint!.setStatus("ABORT")
	endif

	success=1

	return

validate_old_sync_dir: rem --- Validate directory for old data/sync location

	success=0

	focus$="ADX_UPDATEXML.OLD_SYNC_PATH"
	check_dir_name=1
	not_download_loc=0
	gosub validate_sync_dir

	rem --- can't be the same as new data/sync location
	if loc_dir$ = callpoint!.getColumnData("ADX_UPDATEXML.NEW_SYNC_PATH")
		msg_id$="AD_BAD_OLD_SYNC_DIR"
		gosub disp_message
		callpoint!.setFocus(focus$)
		callpoint!.setStatus("ABORT")
		return
	endif

	success=1

	return

validate_backup_sync_dir: rem --- Validate directory for backup sync location

	success=0

	focus$="ADX_UPDATEXML.SYNC_BACKUP_DIR"
	check_dir_name=0
	not_download_loc=0
	gosub validate_sync_dir

	success=1

	return

validate_sync_dir: rem --- Validate directory for data/sync location

	rem --- remove trailing slash from path
	gosub remove_trailing_slash

	rem --- Directory must exist
	testDir$=loc_dir$
	gosub verify_dir_exists
	if !exists
		callpoint!.setFocus(focus$)
		callpoint!.setStatus("ABORT")
		return
	endif

	if check_dir_name
		rem --- Directory must be named data/sync
		testDir$=loc_dir$
		gosub verify_dir_name
		if !name_ok
			callpoint!.setFocus(focus$)
			callpoint!.setStatus("ABORT")
			return
		endif
	endif

	rem --- Don�t allow current download location
	if not_download_loc
		testLoc$=loc_dir$
		gosub verify_not_download_loc
		if !loc_ok
			callpoint!.setFocus(focus$)
			callpoint!.setStatus("ABORT")
			return
		endif
	endif

	return

remove_trailing_slash: rem --- rem --- Remove trailing slashes (/ and \) from new data/sync location

	while len(loc_dir$) and pos(loc_dir$(len(loc_dir$),1)="/\")
		loc_dir$ = loc_dir$(1, len(loc_dir$)-1)
	wend

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

verify_dir_exists: rem --- Directory must exist

	exists=0
	testChan=unt
	open(testChan, err=dir_missing)testDir$
	close(testChan)
	exists=1

dir_missing:
	if !exists
		msg_id$="AD_DIR_MISSING"
		dim msg_tokens$[1]
		msg_tokens$[1]=testDir$
		gosub disp_message
	endif

	return

verify_dir_name: rem --- Directory must be named data/sync

	rem --- path must end with /data/sync or \data\sync
	name_ok=0
	posx=pos("/data/sync"=testDir$, -1)
	if posx=0
		posx=pos("\data\sync"=testDir$, -1)
	endif
	if posx and len(testDir$(posx))=len("/data/sync")
		name_ok=1
	else
		msg_id$="AD_BAD_SYNC_DIR"
		gosub disp_message
	endif

	return
[[ADX_UPDATEXML.NEW_SYNC_PATH.AVAL]]
rem --- Validate directory for new data/sync location

	loc_dir$ = callpoint!.getUserInput()
	gosub validate_new_sync_dir
	callpoint!.setUserInput(loc_dir$)
