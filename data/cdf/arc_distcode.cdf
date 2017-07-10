[[ARC_DISTCODE.GL_SLS_ACCT.AVAL]]
gosub gl_inactive
[[ARC_DISTCODE.GL_PURC_ACCT.AVAL]]
gosub gl_inactive
[[ARC_DISTCODE.GL_PPV_ACCT.AVAL]]
gosub gl_inactive
[[ARC_DISTCODE.GL_INV_ADJ.AVAL]]
gosub gl_inactive
[[ARC_DISTCODE.GL_INV_ACCT.AVAL]]
gosub gl_inactive
[[ARC_DISTCODE.GL_FRGT_ACCT.AVAL]]
gosub gl_inactive
[[ARC_DISTCODE.GL_DISC_ACCT.AVAL]]
gosub gl_inactive
[[ARC_DISTCODE.GL_COGS_ADJ.AVAL]]
gosub gl_inactive
[[ARC_DISTCODE.GL_COGS_ACCT.AVAL]]
gosub gl_inactive
[[ARC_DISTCODE.GL_CASH_ACCT.AVAL]]
gosub gl_inactive
[[ARC_DISTCODE.GL_AR_ACCT.AVAL]]
gosub gl_inactive
[[ARC_DISTCODE.BDEL]]
rem --- Check if code is used as a default code

	num_files = 1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARS_CUSTDFLT", open_opts$[1]="OTA"
	gosub open_tables
	ars_custdflt_dev = num(open_chans$[1])
	dim ars_rec$:open_tpls$[1]

	find record(ars_custdflt_dev,key=firm_id$+"D",dom=*next)ars_rec$
	if ars_rec.ar_dist_code$ = callpoint!.getColumnData("ARC_DISTCODE.AR_DIST_CODE") then
		callpoint!.setMessage("AR_DIST_CODE_IN_DFLT")
		callpoint!.setStatus("ABORT")
	endif
[[ARC_DISTCODE.AENA]]
pgm_dir$=stbl("+DIR_PGM")

rem --- Disable columns if PO system not installed
call pgm_dir$+"adc_application.aon","PO",info$[all]

if info$[20] = "N"
	ctl_name$="ARC_DISTCODE.GL_INV_ADJ"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="ARC_DISTCODE.GL_COGS_ADJ"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="ARC_DISTCODE.GL_PURC_ACCT"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="ARC_DISTCODE.GL_PPV_ACCT"
	ctl_stat$="I"
	gosub disable_fields
endif
[[ARC_DISTCODE.<CUSTOM>]]
#include std_functions.src

gl_inactive:
rem "GL INACTIVE FEATURE"
   glm01_dev=fnget_dev("GLM_ACCT")
   glm01_tpl$=fnget_tpl$("GLM_ACCT")
   dim glm01a$:glm01_tpl$
   glacctinput$=callpoint!.getUserInput()
   glm01a_key$=firm_id$+glacctinput$
   find record (glm01_dev,key=glm01a_key$,err=*return) glm01a$
   if glm01a.acct_inactive$="Y" then
      call stbl("+DIR_PGM")+"adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,gl_size
      msg_id$="GL_ACCT_INACTIVE"
      dim msg_tokens$[2]
      msg_tokens$[1]=fnmask$(glm01a.gl_account$(1,gl_size),m0$)
      msg_tokens$[2]=cvs(glm01a.gl_acct_desc$,2)
      gosub disp_message
      callpoint!.setStatus("ACTIVATE-ABORT")
   endif
return

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
