[[ARC_CASHCODE.GL_DISC_ACCT.AVAL]]
gosub gl_inactive
[[ARC_CASHCODE.GL_CASH_ACCT.AVAL]]
gosub gl_inactive
[[ARC_CASHCODE.BSHO]]
pgm_dir$=stbl("+DIR_PGM")

rem --- Disable Pos Cash Type if OP not installed
call pgm_dir$+"adc_application.aon","OP",info$[all]
if info$[20] = "N"
	ctl_name$="ARC_CASHCODE.TRANS_TYPE"
	ctl_stat$="I"
	gosub disable_fields
endif

rem --- Disable G/L Accounts if G/L not installed
call pgm_dir$+"adc_application.aon","GL",info$[all]
if info$[20] = "N"
	ctl_name$="ARC_CASHCODE.GL_CASH_ACCT"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="ARC_CASHCODE.GL_DISC_ACCT"
	ctl_stat$="I"
	gosub disable_fields
endif
[[ARC_CASHCODE.<CUSTOM>]]
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
callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")

return
