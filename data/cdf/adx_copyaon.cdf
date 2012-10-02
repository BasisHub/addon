[[ADX_COPYAON.AREC]]
rem --- Initialize aon new install location
rem --- Default to /aon_prod/vnnnn (where nnnn=new version)
rem --- Get new version from SYS line of download addon.syn file

	bbjHome$ = System.getProperty("basis.BBjHome")
	download_loc$ = bbjHome$ + "/apps/aon"
	synChan=unt
	open(synChan,isz=-1, err=file_not_found)download_loc$ + "/config/addon.syn"

	while 1
		read(synChan,end=*break)record$
		rem --- locate SYS line
		if(pos("SYS="=record$) = 1) then
			rem --- parse version from SYS line
			start$ = "^Version "
			startLen = len(start$)
			startPos = pos(start$=record$)
			end$ = " - "
			endPos = pos(end$=record$(startPos + startLen))
			synVersion$ = cvs(record$(startPos + startLen, endPos - 1),3)
			rem -- remove decimal point
			dotPos = pos("."=synVersion$)
			if(dotPos) then
				synVersion$ = synVersion$(1, dotPos - 1) + synVersion$(dotPos + 1)
			endif
			break
		endif
	wend
	close(synChan)


	new_loc$ = "/aon_prod/v" + synVersion$

	callpoint!.setColumnData("ADX_COPYAON.NEW_INSTALL_LOC", new_loc$)
	callpoint!.setStatus("REFRESH")
	break

file_not_found:

	rem --- Can't initialize aon new install location
[[ADX_COPYAON.<CUSTOM>]]
validate_aon_dir: rem --- Validate directory for aon new install location

	rem --- Remove trailing slashes (/ and \) from aon new install location

	while len(new_loc$) and pos(new_loc$(len(new_loc$),1)="/\")
		new_loc$ = new_loc$(1, len(new_loc$)-1)
	wend

	rem --- Remove trailing “/aon”

	if len(new_loc$)>=4 and pos(new_loc$(1+len(new_loc$)-4)="/aon\aon" ,4)
		new_loc$ = new_loc$(1, len(new_loc$)-4)
	endif

	rem --- Don’t allow current download location

	testLoc$=new_loc$
	gosub verify_not_download_loc
	if !loc_ok
		callpoint!.setColumnData("ADX_COPYAON.NEW_INSTALL_LOC", new_loc$)
		callpoint!.setFocus("ADX_COPYAON.NEW_INSTALL_LOC")
		callpoint!.setStatus("ABORT")
		return
	endif

	rem --- Cannot be currently used by Barista/Addon

	testChan=unt
	open(testChan, err=test_file_2)new_loc$ + "/barista/sys"
	close(testChan)
	goto location_used

test_file_2:
	open(testChan, err=*return)new_loc$ + "/aon/data"
	close(testChan)

location_used:
	msg_id$="AD_INSTALL_LOC_USED"
	gosub disp_message

	callpoint!.setColumnData("ADX_COPYAON.NEW_INSTALL_LOC", new_loc$)
	callpoint!.setFocus("ADX_COPYAON.NEW_INSTALL_LOC")
	callpoint!.setStatus("ABORT")

	return

verify_not_download_loc: rem --- Verify not using current download location
	rem --- Some needed improvements
	rem --- Doesn't handle . or .. relative paths
	rem --- Doesn't handle symbolic links
	rem --- / vs \ may be an issue
	rem --- Should be case insensitive for Windows
	rem --- basis.BBjHome includes the Windows drive id

	loc_ok=1
	bbjHome$ = System.getProperty("basis.BBjHome")
	if pos(bbjHome$=testLoc$)=1
		msg_id$="AD_INSTALL_LOC_BAD"
		dim msg_tokens$[1]
		msg_tokens$[1]=bbjHome$
		gosub disp_message
		loc_ok=0
	endif

	return
[[ADX_COPYAON.ASVA]]
rem --- Validate directory for aon new install location

	new_loc$ = callpoint!.getColumnData("ADX_COPYAON.NEW_INSTALL_LOC")
	gosub validate_aon_dir
	callpoint!.setColumnData("ADX_COPYAON.NEW_INSTALL_LOC", new_loc$)
[[ADX_COPYAON.NEW_INSTALL_LOC.AVAL]]
rem --- Validate directory for aon new install location

	new_loc$ = callpoint!.getUserInput()
	gosub validate_aon_dir
	callpoint!.setUserInput(new_loc$)
