[[APC_DISTRIBUTION.GL_RET_ACCT.AVAL]]
gosub gl_active
[[APC_DISTRIBUTION.GL_PURC_ACCT.AVAL]]
gosub gl_active
[[APC_DISTRIBUTION.GL_DISC_ACCT.AVAL]]
gosub gl_active
[[APC_DISTRIBUTION.GL_CASH_ACCT.AVAL]]
gosub gl_active
[[APC_DISTRIBUTION.GL_AP_ACCT.AVAL]]
gosub gl_active
[[APC_DISTRIBUTION.<CUSTOM>]]
#include std_functions.src
#include std_missing_params.src

gl_active:
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
[[APC_DISTRIBUTION.BSHO]]
rem --- Open/Lock files


files=1,begfile=1,endfile=files
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="APS_PARAMS";rem --- aps-01

for wkx=begfile to endfile
	options$[wkx]="OTA"
next wkx

call stbl("+DIR_SYP")+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                 chans$[all],templates$[all],table_chans$[all],batch,status$

if status$<>"" then
	remove_process_bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif

aps01_dev=num(chans$[1])

rem --- Retrieve miscellaneous templates

files=1,begfile=1,endfile=files
dim ids$[files],templates$[files]
ids$[1]="aps-01A:APS_PARAMS"

call stbl("+DIR_PGM")+"adc_template.aon",begfile,endfile,ids$[all],templates$[all],status
if status goto std_exit

rem --- Dimension miscellaneous string templates

dim aps01a$:templates$[1]

rem --- init/parameters

aps01a_key$=firm_id$+"AP00"
find record (aps01_dev,key=aps01a_key$,err=std_missing_params) aps01a$

if aps01a.ret_flag$<>"Y" 
    ctl_name$="APC_DISTRIBUTION.GL_RET_ACCT"
    ctl_stat$="I"
    gosub disable_fields
endif

dim info$[20]
call stbl("+DIR_PGM")+"adc_application.aon","AP",info$[all]
gl$=info$[9]
if gl$<>"Y" then
	callpoint!.setColumnEnabled("APC_DISTRIBUTION.GL_AP_ACCT",-1)
	callpoint!.setColumnEnabled("APC_DISTRIBUTION.GL_CASH_ACCT",-1)
	callpoint!.setColumnEnabled("APC_DISTRIBUTION.GL_DISC_ACCT",-1)
endif
