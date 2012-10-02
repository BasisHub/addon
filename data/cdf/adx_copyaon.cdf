[[ADX_COPYAON.ASHO]]
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
[[ADX_COPYAON.BSHO]]
rem --- Declare Java classes used

	use java.io.File
	use ::ado_file.src::FileObject
[[ADX_COPYAON.AREC]]
rem --- Initialize aon new install location
rem --- Default to /aon_prod/vnnnn (where nnnn=new version)
rem --- Get vnnnn from VERSION_ID in the ADM_MODULES table

	synVersion$="00"
	comp_id$=STBL("+AON_APPCOMPANY")
	prod_id$="AD"

	sql_chan=sqlunt
	sqlopen(sql_chan)stbl("+DBNAME")
	sql_prep$="SELECT version_id FROM adm_modules"
	sql_prep$=sql_prep$+" WHERE asc_comp_id='" + comp_id$ + "' and asc_prod_id='" + prod_id$ + "'"
	sqlprep(sql_chan)sql_prep$
	dim select_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)
	while 1
		select_tpl$=sqlfetch(sql_chan,err=*break) 
		synVersion$=cvs(select_tpl.version_id$,3)
	wend
	sqlclose(sql_chan)

	rem --- Remove decimal point from version
	dotPos = pos("."=synVersion$)
	if(dotPos) then
		synVersion$ = synVersion$(1, dotPos - 1) + synVersion$(dotPos + 1)
	endif

	rem --- Verify target syn dir doesn't exist
	rem --- As necessary, append _i to target syn dir
	version$=synVersion$
	i=0
	testChan=unt
	while 1
		targetDir$=modsDir$+"/v"+version$
		open(testChan,err=*break)targetDir$
		close(testChan)
		 i=i+1
		version$=synVersion$+"_"+str(i)
	wend
	targetDir$=targetDir$+"/config/"
	synVersion$=version$

	new_loc$ = "/aon_prod/v" + synVersion$
	callpoint!.setColumnData("ADX_COPYAON.NEW_INSTALL_LOC", new_loc$)
	callpoint!.setStatus("REFRESH")
[[ADX_COPYAON.<CUSTOM>]]
validate_aon_dir: rem --- Validate directory for aon new install location

	abort=0

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
		abort=1
		return
	endif

	rem --- Read-Write-Execute directory permissions are required

	if !FileObject.isDirWritable(new_loc$)
		msg_id$="AD_DIR_NOT_WRITABLE"
		dim msg_tokens$[1]
		msg_tokens$[1]=new_loc$
		gosub disp_message

		callpoint!.setColumnData("ADX_COPYAON.NEW_INSTALL_LOC", new_loc$)
		callpoint!.setFocus("ADX_COPYAON.NEW_INSTALL_LOC")
		callpoint!.setStatus("ABORT")
		abort=1
		return
	endif

	rem --- Cannot be currently used by Addon

	testChan=unt
	open(testChan, err=*return)new_loc$ + "/aon/data"; rem --- successful return here
	close(testChan)

	rem --- Location is used by Addon
	msg_id$="AD_INSTALL_LOC_USED"
	gosub disp_message
		callpoint!.setColumnData("ADX_COPYAON.NEW_INSTALL_LOC", new_loc$)
		callpoint!.setFocus("ADX_COPYAON.NEW_INSTALL_LOC")
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
[[ADX_COPYAON.ASVA]]
rem --- Validate directory for aon new install location

	new_loc$ = callpoint!.getColumnData("ADX_COPYAON.NEW_INSTALL_LOC")
	gosub validate_aon_dir
	callpoint!.setColumnData("ADX_COPYAON.NEW_INSTALL_LOC", new_loc$)
	if abort then break
[[ADX_COPYAON.NEW_INSTALL_LOC.AVAL]]
rem --- Validate directory for aon new install location

	new_loc$ = callpoint!.getUserInput()
	gosub validate_aon_dir
	callpoint!.setUserInput(new_loc$)
	if abort then break
