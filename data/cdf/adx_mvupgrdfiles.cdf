[[ADX_MVUPGRDFILES.DB_NAME.AVAL]]
rem --- Validate database

	focus$="ADX_MVUPGRDFILES.DB_NAME"
	db_name$ = cvs(callpoint!.getUserInput(),3)
	gosub validate_db
[[ADX_MVUPGRDFILES.FILE_LOC.AVAL]]
rem --- Validate directory location

	focus$="ADX_MVUPGRDFILES.FILE_LOC"
	loc_dir$ = cvs(callpoint!.getUserInput(),3)
	gosub validate_dir
[[ADX_MVUPGRDFILES.<CUSTOM>]]
validate_dir: rem --- Validate directory location

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

	return

remove_trailing_slash: rem --- Remove trailing slashes (/ and \) from new data/sync location

	while len(loc_dir$) and pos(loc_dir$(len(loc_dir$),1)="/\")
		loc_dir$ = loc_dir$(1, len(loc_dir$)-1)
	wend

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

validate_db: rem --- Validate database

	rem --- Currently this utility can only use the database used by this Barista/Addon instance.
	if db_name$<>stbl("+DBNAME_API") then
		msg_id$="AD_DB_NOT_ACCESSIBLE"
		dim msg_tokens$[1]
		msg_tokens$[1]=db_name$
		gosub disp_message

		callpoint!.setFocus(focus$)
		callpoint!.setStatus("ABORT")
		return
	endif

	return
[[ADX_MVUPGRDFILES.ASVA]]
rem --- Validate directory location

	focus$="ADX_MVUPGRDFILES.FILE_LOC"
	loc_dir$ = cvs(callpoint!.getColumnData(focus$),3)
	gosub validate_dir
	if !exists
		release
	endif

rem --- Validate database

	focus$="ADX_MVUPGRDFILES.DB_NAME"
	db_name$ = cvs(callpoint!.getColumnData(focus$),3)
	gosub validate_db
