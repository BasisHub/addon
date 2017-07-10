[[GLR_BUDGETUPDATE.GL_ACCOUNT.AVAL]]
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
      callpoint!.setStatus("ACTIVATE")
   endif
[[GLR_BUDGETUPDATE.GL_WILDCARD.AVAL]]
rem --- Check length of wildcard against defined mask for GL Account
	if callpoint!.getUserInput()<>""
		call "adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,m0
		if len(callpoint!.getUserInput())>len(m0$)
			msg_id$="GL_WILDCARD_LONG"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	endif
[[GLR_BUDGETUPDATE.<CUSTOM>]]
#include std_functions.src
ctl_toggle:
	for x=0 to ctls_to_toggle!.size()-1
		ctl_name$=ctls_to_toggle!.getItem(x)
		gosub disable_fields
	next x
return
disable_fields:
	rem --- used to disable/enable controls
	rem --- ctl_name$ sent in with name of control to enable/disable (format "ALIAS.CONTROL_NAME")
	rem --- ctl_stat$ sent in as D or space, meaning disable/enable, respectively
	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")
return

#include std_missing_params.src
[[GLR_BUDGETUPDATE.BUDGET_REVS.AVAL]]
glm08_dev=fnget_dev("GLM_BUDGETMASTER")
dim glm08a$:fnget_tpl$("GLM_BUDGETMASTER")
glm08a.firm_id$=firm_id$
budget_revs$=callpoint!.getUserInput()
glm08a.budget_code$=budget_revs$(1,len(budget_revs$)-1)
glm08a.amt_or_units$=budget_revs$(len(budget_revs$))
read record (glm08_dev,key=glm08a.firm_id$+glm08a.budget_code$+glm08a.amt_or_units$,dom=*next)glm08a$
callpoint!.setColumnData("GLR_BUDGETUPDATE.GL_ACCOUNT_1",glm08a.gl_account_01$)
callpoint!.setColumnData("GLR_BUDGETUPDATE.GL_ACCOUNT_2",glm08a.gl_account_02$)
callpoint!.setColumnData("GLR_BUDGETUPDATE.GL_WILDCARD",glm08a.gl_wildcard$)
callpoint!.setColumnData("GLR_BUDGETUPDATE.ROUNDING",glm08a.rounding$)
callpoint!.setColumnData("GLR_BUDGETUPDATE.UPDATE_TYPE","C")
ctl_stat$=" "
ctls_to_toggle!=userObj!.getItem(num(user_tpl.ctls_to_toggle_ofst$))
gosub ctl_toggle
[[GLR_BUDGETUPDATE.BSHO]]
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"

gosub open_tables
gls01_dev=num(open_chans$[1])
dim gls01a$:open_tpls$[1]
readrecord(gls01_dev,key=firm_id$+"GL00",err=std_missing_params)gls01a$
if gls01a.budget_flag$<>"Y"
	msg_id$="GL_NO_BUDG"
	gosub disp_message
	rem --- remove process bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif



rem --- store some ctls we'll be disabling/enabling
ctls_to_toggle!=SysGUI!.makeVector()
ctls_to_toggle!.addItem("GL_ACCOUNT_1")
ctls_to_toggle!.addItem("GL_ACCOUNT_2")
ctls_to_toggle!.addItem("GL_WILDCARD")
ctls_to_toggle!.addItem("ROUNDING")
ctls_to_toggle!.addItem("UPDATE_TYPE")
user_tpl_str$="ctls_to_toggle_ofst:c(5)"
dim user_tpl$:user_tpl_str$
userObj!=SysGUI!.makeVector()
userObj!.addItem(ctls_to_toggle!)
ctl_stat$="I"
gosub ctl_toggle
