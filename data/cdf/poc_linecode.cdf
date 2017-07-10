[[POC_LINECODE.GL_PPV_ACCT.AVAL]]
gosub gl_active
[[POC_LINECODE.GL_EXP_ACCT.AVAL]]
gosub gl_active
[[POC_LINECODE.LINE_TYPE.AVAL]]
rem - don't use gl accounts if GL not installed

if callpoint!.getDevObject("gl_installed")<>"Y"  then
	callpoint!.setColumnData("POC_LINECODE.GL_EXP_ACCT","")
	callpoint!.setColumnData("POC_LINECODE.GL_PPV_ACCT","")
	ctl_name$="POC_LINECODE.GL_EXP_ACCT"
	ctl_stat$="D"
	gosub disable_fields
	ctl_name$="POC_LINECODE.GL_PPV_ACCT"
	gosub disable_fields
endif

rem --- Unset Lead Time Flag if not S type

if callpoint!.getUserInput() <> "S"
	callpoint!.setColumnData("POC_LINECODE.LEAD_TIM_FLG","N")
	callpoint!.setStatus("MODIFIED-REFRESH")
else
	if callpoint!.getRecordMode() = "A"
		callpoint!.setColumnData("POC_LINECODE.LEAD_TIM_FLG","Y")
		callpoint!.setStatus("REFRESH")
	endif
endif
[[POC_LINECODE.<CUSTOM>]]
#include std_missing_params.src
#include std_functions.src

gl_active:
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
[[POC_LINECODE.BSHO]]
rem --- Open/Lock files

files=1,begfile=1,endfile=files
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="POS_PARAMS";rem --- ads-01

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

ads01_dev=num(chans$[1])

rem --- Retrieve miscellaneous templates

files=1,begfile=1,endfile=files
dim ids$[files],templates$[files]
ids$[1]="pos-01A:POS_PARAMS"

call stbl("+DIR_PGM")+"adc_template.aon",begfile,endfile,ids$[all],templates$[all],status
if status goto std_exit

rem --- Dimension miscellaneous string templates

dim pos01a$:templates$[1]

rem --- init/parameters

pos01a_key$=firm_id$+"PO00"
find record (ads01_dev,key=pos01a_key$,err=std_missing_params) pos01a$

dim info$[20]

call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
gl$=info$[20]
callpoint!.setDevObject("gl_installed",gl$)
