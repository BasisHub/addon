[[GLM_BUDGETMASTER.ADIS]]
rem --- Revision_src does not match ListButton codes, so must parse out record_id$ and amt_or_units$.
	revision_src$=callpoint!.getColumnData("GLM_BUDGETMASTER.REVISION_SRC")
	record_id$=revision_src$(1,len(revision_src$)-1)
	amt_or_units$=revision_src$(len(revision_src$))
	temp_id$=cvs(record_id$,2)
	if len(temp_id$)=1 and pos(temp_id$="012345") then record_id$=temp_id$

 	callpoint!.setColumnData("GLM_BUDGETMASTER.REVISION_SRC",record_id$+amt_or_units$,1)
[[GLM_BUDGETMASTER.BFMC]]
rem --- Initialize displayColumns! object
	use ::glo_DisplayColumns.aon::DisplayColumns
	displayColumns!=new DisplayColumns(firm_id$)

rem --- Initialize revision_src ListButton
	ldat_list$=displayColumns!.getStringButtonList()
	callpoint!.setTableColumnAttribute("GLM_BUDGETMASTER.REVISION_SRC","LDAT",ldat_list$)
[[GLM_BUDGETMASTER.GL_ACCOUNT.AVAL]]
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
   
[[GLM_BUDGETMASTER.GL_WILDCARD.AVAL]]
rem --- Check length of wildcard against defined mask for GL Account
	if callpoint!.getUserInput()<>""
		call "adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,m0
		if len(callpoint!.getUserInput())>len(m0$)
			msg_id$="GL_WILDCARD_LONG"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	endif
[[GLM_BUDGETMASTER.ASHO]]
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
[[GLM_BUDGETMASTER.AOPT-BREV]]
rem --- Get user approval to Create Budget Revision
if callpoint!.getRecordStatus()<>"M"
	if cvs(callpoint!.getColumnData("GLM_BUDGETMASTER.BUDGET_CODE"),3)<>"" and
:	cvs(callpoint!.getColumnData("GLM_BUDGETMASTER.AMT_OR_UNITS"),3)<>"" and
:	cvs(callpoint!.getColumnData("GLM_BUDGETMASTER.DESCRIPTION"),3)<>"" and
:	cvs(callpoint!.getColumnData("GLM_BUDGETMASTER.AMTPCT_VAL"),3)<>"" and 
:	cvs(callpoint!.getColumnData("GLM_BUDGETMASTER.REVISION_SRC"),3)<>"" and
:	cvs(callpoint!.getColumnData("GLM_BUDGETMASTER.REV_TITLE"),3)<>""
		prompt$=Translate!.getTranslation("AON_DO_YOU_WANT_TO_CREATE_A_BUDGET_REVISION?")
		call pgmdir$+"adc_yesno.aon",0,prompt$,0,answer$,fkey
		     
		if answer$="YES" 
			run stbl("+DIR_PGM")+"glu_createbudget.aon"
		else
			callpoint!.setStatus("ABORT")
		endif
	endif
endif
[[GLM_BUDGETMASTER.BWRI]]
rev_src$=callpoint!.getColumnData("GLM_BUDGETMASTER.REVISION_SRC")
gosub validate_revision_source
[[GLM_BUDGETMASTER.<CUSTOM>]]
#include std_functions.src
validate_revision_source:
	rem --- rev_src$ set prior to gosub
	amt_units$=callpoint!.getColumnData("GLM_BUDGETMASTER.AMT_OR_UNITS")
	if cvs(rev_src$,3)<>"" and cvs(amt_units$,3)<>""
		if rev_src$(len(rev_src$),1)<>amt_units$ or cvs(rev_src$(1,len(rev_src$)-1),2)<"0" or cvs(rev_src$(1,len(rev_src$)-1),2)>"5"
			msg_id$="GL_BAD_RECID"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	endif
return
#include std_missing_params.src
[[GLM_BUDGETMASTER.REVISION_SRC.AVAL]]
rev_src$=callpoint!.getUserInput()
gosub validate_revision_source
[[GLM_BUDGETMASTER.BUDGET_CODE.AVAL]]
if callpoint!.getUserInput()<="5"
	msg_id$="GL_RECID"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
