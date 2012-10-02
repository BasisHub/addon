[[IVC_TRANCODE.POST_GL.AVAL]]
rem --- if setting post to gl flag to Y, set min length on GL acct field to 1

if callpoint!.getUserInput()<>"Y"
	callpoint!.setTableColumnAttribute("IVC_TRANCODE.GL_ADJ_ACCT","MINL","0")
else
	callpoint!.setTableColumnAttribute("IVC_TRANCODE.GL_ADJ_ACCT","MINL","1")
endif
[[IVC_TRANCODE.BDEL]]
rem -- don't allow delete of trans code if it's in use in ive_transhdr
ive01_dev=fnget_dev("IVE_TRANSHDR")
k$=""
read (ive01_dev,key=firm_id$+callpoint!.getColumnData("IVC_TRANCODE.TRANS_CODE"),knum=1,dom=*next)
k$=key(ive01_dev,end=*next)
if pos(firm_id$+callpoint!.getColumnData("IVC_TRANCODE.TRANS_CODE")=k$)=1
	dim msg_tokens$[1]
	msg_tokens$[1]="This Transaction Code is referenced by one or more open Transaction Entries."
	msg_id$="IV_NO_DELETE"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
[[IVC_TRANCODE.BREC]]
rem --- re-enable Post to G/L flag (unless GL not installed)
	if user_tpl.gl_installed$="Y"
		ctl_name$="IVC_TRANCODE.POST_GL"
		ctl_stat$=""
		gosub disable_fields
	endif
[[IVC_TRANCODE.TRANS_TYPE.AVAL]]
rem --- Check for Commitment type
	if callpoint!.getUserInput() = "C"
		callpoint!.setColumnData("IVC_TRANCODE.POST_GL","N")
		callpoint!.setColumnData("IVC_TRANCODE.GL_ADJ_ACCT","")
		ctl_name$="IVC_TRANCODE.POST_GL"
		ctl_stat$="D"
		gosub disable_fields
		ctl_name$="IVC_TRANCODE.GL_ADJ_ACCT"
		gosub disable_fields
	else
		if user_tpl.gl_installed$="Y"
			ctl_name$="IVC_TRANCODE.POST_GL"
			ctl_stat$=""
			gosub disable_fields
		endif
	endif
[[IVC_TRANCODE.BWRI]]
rem --- Check for blank Trans Type
	if cvs(callpoint!.getColumnData("IVC_TRANCODE.TRANS_TYPE"),2) = "" then
		msg_id$="INVALID_TRANS_TYPE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
rem --- Check for G/L Number if Post to G/L is up
	if callpoint!.getColumnData("IVC_TRANCODE.POST_GL") = "Y" then
		if cvs(callpoint!.getColumnData("IVC_TRANCODE.GL_ADJ_ACCT"),2) = "" then
			msg_id$ = "IV_NEED_GL_ACCT"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	endif
[[IVC_TRANCODE.<CUSTOM>]]
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

#include std_missing_params.src
[[IVC_TRANCODE.BSHO]]
rem --- Open/Lock Files
	files=2,begfile=1,endfile=files
	dim files$[files],options$[files],chans$[files],templates$[files]
	files$[1]="IVS_PARAMS",options$[1]="OTA"
	files$[2]="IVE_TRANSHDR",options$[2]="OTA"
	call dir_pgm$+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                 chans$[all],templates$[all],table_chans$[all],batch,status$
	if status$<>"" then
		remove_process_bar:
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif
	ivs01_dev=num(chans$[1])
			
	rem --- Dimension miscellaneous string templates
			
	dim ivs01a$:templates$[1]
			
rem --- init/parameters
			
	ivs01a_key$=firm_id$+"IV00"
	find record (ivs01_dev,key=ivs01a_key$,err=std_missing_params) ivs01a$
rem --- check if GL is installed
	call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
	gl$=info$[20];rem --- gl installed?
	dim user_tpl$:"gl_installed:c(1)"
	user_tpl.gl_installed$=gl$
	if gl$<>"Y"
		ctl_stat$="I"
		ctl_name$="IVC_TRANCODE.POST_GL"
		gosub disable_fields
		ctl_name$="IVC_TRANCODE.GL_ADJ_ACCT"
		gosub disable_fields	
	endif
