[[ADX_CLEARFILE.<CUSTOM>]]
rem ==========================================================================
fix_path: rem --- Flip directory path separators
rem IN: filePath$
rem OUT: filePath$
rem ==========================================================================

	pos=pos("\"=filePath$)
	while pos
		filePath$=filePath$(1, pos-1)+"/"+filePath$(pos+1)
	pos=pos("\"=filePath$)
	wend

	return

[[ADX_CLEARFILE.DD_TABLE_ALIAS.AVAL]]
rem --- Restrict to Addon data tables
	dd_table_alias$=callpoint!.getUserInput()
	ddm_tables_dev=fnget_dev("DDM_TABLES")
	dim ddm_tables$:fnget_tpl$("DDM_TABLES")
	readrecord(ddm_tables_dev,key=dd_table_alias$)ddm_tables$
	if ddm_tables.asc_comp_id$<>"01007514" or
:	pos(ddm_tables.asc_prod_id$+";"="ADB;DDB;SQB;") or
:	pos(ddm_tables.dd_alias_type$+";"="P;R") then
		dim msg_tokens$[1]
		msg_tokens$[0]=cvs(dd_table_alias$,2)
		msg_id$="AD_FILE_NOT_ADDON"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif
[[ADX_CLEARFILE.ASVA]]
rem --- Confirm ready to clear data
	table_alias$=cvs(callpoint!.getColumnData("ADX_CLEARFILE.DD_TABLE_ALIAS"),2)
	dim msg_tokens$[2]
	msg_tokens$[0]=table_alias$
	if callpoint!.getColumnData("ADX_CLEARFILE.ACTIVE") = "Y"
		msg_tokens$[1]=Translate!.getTranslation("AON_FIRM")+" "+firm_id$
	else
		msg_tokens$[1]=Translate!.getTranslation("AON_ALL_FIRMS")
	endif
	msg_id$="AD_CLEAR_FIRM_CONF"
	gosub disp_message
	if msg_opt$<>"Y"then
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- This utility is restricted to Addon data files, so no need to update admin_backup for Barista admin data files.

rem --- Clear selected data
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]=table_alias$,open_opts$[1]="OTA"

	gosub open_tables

	table_dev=num(open_chans$[1])

	prompt$=""
	if callpoint!.getColumnData("ADX_CLEARFILE.ACTIVE") = "Y"
		call "adc_clearpartial.aon","",table_dev,firm_id$,status
		if status = 0
			prompt$=table_alias$+" "+Translate!.getTranslation("AON_CLEARED_FOR")+" "+Translate!.getTranslation("AON_FIRM")+" "+firm_id$+"."
			x=msgbox(prompt$,64,Form!.getTitle())
		endif
	else
		call "adc_clearfile.aon",table_dev
		if table_dev<>0
			prompt$=table_alias$+" "+Translate!.getTranslation("AON_CLEARED_FOR")+" "+Translate!.getTranslation("AON_ALL_FIRMS")+"."
			x=msgbox(prompt$,64,Form!.getTitle())
		endif
	endif

rem --- Log file cleared
	if prompt$<>"" then
		use ::ado_file.src::FileObject
		use java.io.File

		rem --- Flip directory path separators
		filePath$=stbl("+DIR_DAT")
		gosub fix_path
		dataDir$=filePath$

		rem --- Get aon directory location from aon/data path
		aonDir$=dataDir$(1, pos("/data"=dataDir$,-1)-1)

		rem --- Create logs directory under aon directory
		logpath$=aonDir$+"/logs"
		FileObject.makeDirs(new File(logpath$))

		rem --- create and open log file
		log$ = logpath$+"/clearfile_"+DATE(0:"%Yd%Mz%Dz")+"_"+DATE(0:"%Hz%mz")+".txt"
		erase log$,err=*next
		string log$
		log_dev=unt
		open (log_dev)log$
            
		rem --- write log header info
		print (log_dev)"Clearfile log created: " + date(0:"%Yd-%Mz-%Dz@%Hz:%mz:%sz")
		print (log_dev)"Executed by: "+stbl("+USER_ID")
		print (log_dev)prompt$
		print (log_dev)
	endif
[[ADX_CLEARFILE.ARAR]]
rem --- Set Current Firm to true
	callpoint!.setColumnData("ADX_CLEARFILE.ACTIVE","Y")
	callpoint!.setStatus("REFRESH")
