[[ADX_INSTALLWIZ.AREC]]
rem --- Initialize new record
	callpoint!.setColumnData("ADX_INSTALLWIZ.INSTALL_TYPE","Q")
[[ADX_INSTALLWIZ.NEW_INSTALL_LOC.AVAL]]
rem --- Validate directory for aon new install location

	new_loc$ = callpoint!.getUserInput()
	gosub validate_aon_dir
	if abort then
		callpoint!.setStatus("ABORT")
		break
	endif
	callpoint!.setUserInput( new_loc$)
[[ADX_INSTALLWIZ.INSTALL_TYPE.AVAL]]
rem --- Use adx_firmsetup form to get new firm ID, name, address, etc
	callpoint!.setDevObject("formData",null())
	if callpoint!.getUserInput()<>"Q" then
		dim dflt_data$[3,1]
		dflt_data$[1,0] = "DATA_LOCATION"
		dflt_data$[1,1] = callpoint!.getColumnData("ADX_INSTALLWIZ.NEW_INSTALL_LOC")+"/aon/data/"
		dflt_data$[2,0] = "INSTALL_TYPE"
		dflt_data$[2,1] = callpoint!.getUserInput()
		dflt_data$[3,0] = "NEW_INSTALL"
		dflt_data$[3,1] = "1"; rem --- Yes, it's for a new install

		call stbl("+DIR_SYP")+"bam_run_prog.bbj","ADX_FIRMSETUP",stbl("+USER_ID"),"MNT","",table_chans$[all],"",dflt_data$[all]

		formData!=callpoint!.getDevObject("formData")
		if formData!=null() then
			rem --- Exited adx_firmsetup form finishing it
			callpoint!.setStatus("ABORT")
			break
		endif

		rem --- Display new firm ID
		callpoint!.setColumnData("ADX_INSTALLWIZ.NEW_FIRM_ID",formData!.getProperty("NEW_FIRM_ID"),1)
		callpoint!.setFocus("ADX_INSTALLWIZ.APP_HELP")
		callpoint!.setStatus("ACTIVATE")
	endif
	
[[ADX_INSTALLWIZ.DB_NAME.AVAL]]
rem --- Validate new database name

	db_name$ = callpoint!.getUserInput()
	gosub validate_new_db_name
	callpoint!.setUserInput(db_name$)
	if abort then break
[[ADX_INSTALLWIZ.ASHO]]
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
[[ADX_INSTALLWIZ.BSHO]]
rem --- Declare Java classes used

	use java.io.File
	use ::ado_file.src::FileObject

rem --- Open/Lock files

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ADM_MODULES",open_opts$[1]="OTA"

	gosub open_tables

[[ADX_INSTALLWIZ.<CUSTOM>]]
validate_new_db_name: rem --- Validate new database name

	abort=0

	rem --- Barista uses all upper case db names
	db_name$=cvs(db_name$,4)

	rem --- Don't allow database if it's already in Enterprise Manager, unless installing PRB Payroll for the first time
	call stbl("+DIR_SYP")+"bac_em_login.bbj",SysGUI!,Form!,rdAdmin!,rd_status$
	if rd_status$="ADMIN" then
		db! = rdAdmin!.getDatabase(db_name$,err=dbNotFound)

		rem --- Okay to use this db if PRB Payroll is being installed, and it does not exist yet at new install location.
		dim adm_modules$:fnget_tpl$("ADM_MODULES")
		findrecord(fnget_dev("ADM_MODULES"),key="01004419"+"PRB",dom=*next)adm_modules$
		if adm_modules.sys_install$="Y" then
			prbabsDir_exists=0
			testChan=unt
			open(testChan,err=*next)new_loc$ + "/prbabs/data"; prbabsDir_exists=1
			close(testChan,err=*next)
			if !prbabsDir_exists then goto dbNotFound
		endif

		rem --- This db already exists, so don't allow it
		msg_id$="AD_DB_EXISTS"
		gosub disp_message
	endif

	rem --- Abort, need to re-enter database name
	callpoint!.setColumnData("ADX_INSTALLWIZ.DB_NAME", db_name$)
	callpoint!.setFocus("ADX_INSTALLWIZ.DB_NAME")
	callpoint!.setStatus("ABORT")
	abort=1

dbNotFound:
	rem --- Okay to use this db name, it doesn't already exist
	callpoint!.setDevObject("rdAdmin", rdAdmin!)

	return

validate_aon_dir: rem --- Validate directory for aon new install location

	abort=0

	rem --- Flip directory path separators

	filePath$=new_loc$
	gosub fix_path
	new_loc$=filePath$

	rem --- Remove trailing slashes (/ and \) from aon new install location

	while len(new_loc$) and pos(new_loc$(len(new_loc$),1)="/\")
		new_loc$ = new_loc$(1, len(new_loc$)-1)
	wend

	rem --- Remove trailing “/aon”

	if len(new_loc$)>=4 and pos(new_loc$(1+len(new_loc$)-4)="/aon\aon" ,4)
		new_loc$ = new_loc$(1, len(new_loc$)-4)
	endif

	rem --- Fix path for this OS
	current_dir$=dir("")
	current_drive$=dsk("",err=*next)
    	FileObject.makeDirs(new File(new_loc$))
	chdir(new_loc$)
	new_loc$=current_drive$+dir("")
	chdir(current_dir$)

	rem --- Don’t allow current download location

	testLoc$=new_loc$
	gosub verify_not_download_loc
	if !loc_ok
		callpoint!.setColumnData("ADX_INSTALLWIZ.NEW_INSTALL_LOC", new_loc$)
		callpoint!.setFocus("ADX_INSTALLWIZ.NEW_INSTALL_LOC")
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

		callpoint!.setColumnData("ADX_INSTALLWIZ.NEW_INSTALL_LOC", new_loc$)
		callpoint!.setFocus("ADX_INSTALLWIZ.NEW_INSTALL_LOC")
		callpoint!.setStatus("ABORT")
		abort=1
		return
	endif

	rem --- Cannot be currently used by Addon and PRB Payroll

	aonDir_exists=0
	prbabsDir_exists=0
	testChan=unt
	open(testChan,err=*next)new_loc$ + "/aon/data"; aonDir_exists=1
	close(testChan,err=*next)
	testChan=unt
	open(testChan,err=*next)new_loc$ + "/prbabs/data"; prbabsDir_exists=1
	close(testChan,err=*next)
	if !aonDir_exists and !prbabsDir_exists then return

	rem --- Location is used by Addon
	msg_id$="AD_INSTALL_LOC_USED"
	gosub disp_message

	rem --- If PRB Payroll is being installed, and location is not currently used by PRB Payroll, 
	rem --- ask if they want to install PRB Payroll there too. 
	dim adm_modules$:fnget_tpl$("ADM_MODULES")
	findrecord(fnget_dev("ADM_MODULES"),key="01004419"+"PRB",dom=*next)adm_modules$
	if adm_modules.sys_install$="Y" and !prbabsDir_exists then
		msg_id$="AD_INSTALL_PR_HERE"
		gosub disp_message
		if msg_opt$="Y" then return
	endif

	callpoint!.setColumnData("ADX_INSTALLWIZ.NEW_INSTALL_LOC", new_loc$)
	callpoint!.setFocus("ADX_INSTALLWIZ.NEW_INSTALL_LOC")
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

validate_firm_id: rem -- Validate new firm ID with demo data

	abort=0

	rem --- Firm is required unless with demo data
	if firm_id$="" and install_type$<>"Q" then
		msg_id$="AD_FIRM_WO_DEMO"
		gosub disp_message
		callpoint!.setFocus(focus$)
		callpoint!.setStatus("ABORT")
		abort=1
		return
	endif

	rem --- Cannot use firm 99 or ZZ
	if pos(firm_id$="99ZZ",2) then
		msg_id$="AD_FIRM_ID_BAD"
		dim msg_tokens$[1]
		msg_tokens$[1]=firm_id$
		gosub disp_message
		callpoint!.setFocus(focus$)
		callpoint!.setStatus("ABORT")
		abort=1
		return
	endif

	return

fix_path: rem --- Flip directory path separators

	pos=pos("\"=filePath$)
	while pos
		filePath$=filePath$(1, pos-1)+"/"+filePath$(pos+1)
		pos=pos("\"=filePath$)
	wend
	return
[[ADX_INSTALLWIZ.ASVA]]
rem --- Validate directory for aon new install location

	new_loc$ = callpoint!.getColumnData("ADX_INSTALLWIZ.NEW_INSTALL_LOC")
	gosub validate_aon_dir
	callpoint!.setColumnData("ADX_INSTALLWIZ.NEW_INSTALL_LOC", new_loc$)
	if abort then break

rem -- Validate new firm ID with demo data

	rem --- Update status of checkboxes (work around for Barista bug 5616)
	help! = callpoint!.getControl("ADX_INSTALLWIZ.APP_HELP")
	callpoint!.setColumnData("ADX_INSTALLWIZ.APP_HELP",str(help!.isSelected()))

	firm_id$=callpoint!.getColumnData("ADX_INSTALLWIZ.NEW_FIRM_ID")
	install_type$=callpoint!.getColumnData("ADX_INSTALLWIZ.INSTALL_TYPE")
	focus$="ADX_INSTALLWIZ.NEW_FIRM_ID"
	gosub validate_firm_id
	if abort then break
