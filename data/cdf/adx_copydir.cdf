[[ADX_COPYDIR.BSHO]]
rem --- Inits

	use java.io.File
	declare File source! 
	declare File target! 
[[ADX_COPYDIR.ASVA]]
rem --- Validate source directory

	loc_dir$ = callpoint!.getColumnData("ADX_COPYDIR.SOURCE_DIR")
	gosub validate_source_dir

rem --- Validate target directory

	loc_dir$ = callpoint!.getColumnData("ADX_COPYDIR.TARGET_DIR")
	gosub validate_target_dir
[[ADX_COPYDIR.TARGET_DIR.AVAL]]
rem --- Validate target directory

	loc_dir$ = callpoint!.getUserInput()
	gosub validate_target_dir
[[ADX_COPYDIR.SOURCE_DIR.AVAL]]
rem --- Validate source directory

	loc_dir$ = callpoint!.getUserInput()
	gosub validate_source_dir
[[ADX_COPYDIR.<CUSTOM>]]
validate_source_dir: rem --- Validate source directory

	focus$="ADX_COPYDIR.SOURCE_DIR"

	rem --- Directory must exist
	source! = new File(loc_dir$)
	if ! source!.exists()
		msg_id$="AD_DIR_MISSING"
		dim msg_tokens$[1]
		msg_tokens$[1]=loc_dir$
		gosub disp_message
		callpoint!.setFocus(focus$)
		callpoint!.setStatus("ABORT")
		return
	endif
	
	rem --- Directory must be a directory
	if ! source!.isDirectory()
		msg_id$="AD_BAD_DIR"
		dim msg_tokens$[1]
		msg_tokens$[1]=loc_dir$
		gosub disp_message
		callpoint!.setFocus(focus$)
		callpoint!.setStatus("ABORT")
		return
	endif

	rem --- Directory must be readable
	if ! source!.canRead()
		msg_id$="AD_NOT_READABLE"
		dim msg_tokens$[1]
		msg_tokens$[1]=loc_dir$
		gosub disp_message
		callpoint!.setFocus(focus$)
		callpoint!.setStatus("ABORT")
		return
	endif

	rem --- can't be the same as target directory
	if loc_dir$ = callpoint!.getColumnData("ADX_COPYDIR.TARGET_DIR")
		msg_id$="AD_SAME_DIR"
		gosub disp_message
		callpoint!.setFocus(focus$)
		callpoint!.setStatus("ABORT")
		return
	endif

	return

validate_target_dir: rem --- Validate target directory

	focus$="ADX_COPYDIR.TARGET_DIR"

	rem --- Must be a writable directory if it exists
	target! = new File(loc_dir$)
	if target!.exists()
		rem --- Must be a directory
		if ! target!.isDirectory()
			msg_id$="AD_BAD_DIR"
			dim msg_tokens$[1]
			msg_tokens$[1]=loc_dir$
			gosub disp_message
			callpoint!.setFocus(focus$)
			callpoint!.setStatus("ABORT")
			return
		endif

		rem --- Must be writable
		if ! target!.canWrite()
			msg_id$="AD_NOT_WRITABLE"
			dim msg_tokens$[1]
			msg_tokens$[1]=loc_dir$
			gosub disp_message
			callpoint!.setFocus(focus$)
			callpoint!.setStatus("ABORT")
			return
		endif
	endif

	rem --- can't be the same as source directory
	if loc_dir$ = callpoint!.getColumnData("ADX_COPYDIR.SOURCE_DIR")
		msg_id$="AD_SAME_DIR"
		gosub disp_message
		callpoint!.setFocus(focus$)
		callpoint!.setStatus("ABORT")
		return
	endif

	return
