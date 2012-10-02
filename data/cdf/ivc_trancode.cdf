[[IVC_TRANCODE.BREC]]
rem --- Enable Post to G/L flag
	ctl_name$="IVC_TRANCODE.POST_GL"
	ctl_stat$=""
	gosub disable_fields
[[IVC_TRANCODE.BREA]]
rem --- Enable Post to G/L flag
	ctl_name$="IVC_TRANCODE.POST_GL"
	ctl_stat$=""
	gosub disable_fields
[[IVC_TRANCODE.TRANS_TYPE.AVAL]]
rem --- Check for Commitment type
	if callpoint!.getColumnData("IVC_TRANCODE.TRANS_TYPE") = "C"
		callpoint!.setColumnData("IVC_TRANCODE.POST_GL","N")
		callpoint!.setColumnData("IVC_TRANCODE.GL_ADJ_ACCT","")
		ctl_name$="IVC_TRANCODE.POST_GL"
		ctl_stat$="D"
		gosub disable_fields
		ctl_name$="IVC_TRANCODE.GL_ADJ_ACCT"
		gosub disable_fields
	endif
[[IVC_TRANCODE.BWRI]]
rem --- Check for blank Trans Type
	if cvs(callpoint!.getColumnData("IVC_TRANCODE.TRANS_TYPE"),2) = ""
		msg_id$="INVALID_TRANS_TYPE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[IVC_TRANCODE.<CUSTOM>]]
rem #include std_missing_params.src

disable_fields:
rem --- used to disable/enable controls depending on parameter settings
rem --- send in control to toggle (format "ALIAS.CONTROL_NAME"), and D or space to disable/enable

	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP-REFRESH")

return
[[IVC_TRANCODE.BSHO]]
rem --- Open/Lock Files
	files=1,begfile=1,endfile=files
	dim files$[files],options$[files],chans$[files],templates$[files]
	files$[1]="IVS_PARAMS",options$[1]="OTA"
	call dir_pgm$+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                 chans$[all],templates$[all],table_chans$[all],batch,status$
	if status$<>""  goto std_exit
	ivs01_dev=num(chans$[1])
			
	rem --- Dimension miscellaneous string templates
			
	dim ivs01a$:templates$[1]
			
rem --- init/parameters
			
	ivs01a_key$=firm_id$+"IV00"
	find record (ivs01_dev,key=ivs01a_key$,err=std_missing_params) ivs01a$
