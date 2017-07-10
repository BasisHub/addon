[[POE_INVGL.<CUSTOM>]]
#include std_functions.src
[[POE_INVGL.GL_ACCOUNT.AVAL]]
rem "GL INACTIVE FEATURE"
   glm01_dev=fnget_dev("GLM_ACCT")
   glm01_tpl$=fnget_tpl$("GLM_ACCT")
   dim glm01a$:glm01_tpl$
   glacctinput$=callpoint!.getUserInput()
   glm01a_key$=firm_id$+glacctinput$
   find record (glm01_dev,key=glm01a_key$,err=*break) glm01a$
   if glm01a.acct_inactive$="Y" then
      call stbl("+DIR_PGM")+"adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,gl_size
      msg_id$="GL_ACCT_INACTIVE"
      dim msg_tokens$[2]
      msg_tokens$[1]=fnmask$(glm01a.gl_account$(1,gl_size),m0$)
      msg_tokens$[2]=cvs(glm01a.gl_acct_desc$,2)
      gosub disp_message
      callpoint!.setStatus("ACTIVATE-ABORT")
   endif
[[POE_INVGL.AGRN]]
if callpoint!.getDevObject("units_flag")<>"Y"
	callpoint!.setColumnEnabled("POE_INVGL.UNITS",-1)
	callpoint!.setStatus("REFRESH")
endif

rem - To avoid problems with GL lookup (bug 4923), force GL_ACCOUNT into edit mode
rem - if not previously entered.
if cvs(callpoint!.getColumnData("POE_INVGL.GL_ACCOUNT"),3)=""
	callpoint!.setFocus("POE_INVGL.GL_ACCOUNT")
endif
[[POE_INVGL.AREC]]
if callpoint!.getDevObject("units_flag")<>"Y"
	callpoint!.setColumnEnabled("POE_INVGL.UNITS",-1)
	callpoint!.setStatus("REFRESH")
endif
