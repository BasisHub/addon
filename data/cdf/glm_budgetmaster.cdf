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
[[GLM_BUDGETMASTER.ADEL]]
glm18_dev=fnget_dev("GLM_RECORDTYPE")
glm18_tpl$=fnget_tpl$("GLM_RECORDTYPE")
dim glm18a$:glm18_tpl$
glm18a.record_id$=callpoint!.getColumnData("GLM_BUDGETMASTER.BUDGET_CODE")
glm18a.actbud$="B"
glm18a.amt_or_units$=callpoint!.getColumnData("GLM_BUDGETMASTER.AMT_OR_UNITS")
remove(glm18_dev,key=glm18a.record_id$+glm18a.actbud$+glm18a.amt_or_units$,dom=*next)
[[GLM_BUDGETMASTER.AWRI]]
glm18_dev=fnget_dev("GLM_RECORDTYPE")
glm18_tpl$=fnget_tpl$("GLM_RECORDTYPE")
dim glm18a$:glm18_tpl$
glm18a.record_id$=callpoint!.getColumnData("GLM_BUDGETMASTER.BUDGET_CODE")
glm18a.actbud$="B"
glm18a.amt_or_units$=callpoint!.getColumnData("GLM_BUDGETMASTER.AMT_OR_UNITS")
glm18a.description$=callpoint!.getColumnData("GLM_BUDGETMASTER.DESCRIPTION")
glm18a.rev_title$=callpoint!.getColumnData("GLM_BUDGETMASTER.REV_TITLE")
glm18a$=field(glm18a$)
writerecord(glm18_dev)glm18a$
[[GLM_BUDGETMASTER.BWRI]]
rev_src$=callpoint!.getColumnData("GLM_BUDGETMASTER.REVISION_SRC")
gosub validate_revision_source
[[GLM_BUDGETMASTER.<CUSTOM>]]
validate_revision_source:
	rem --- rev_src$ set prior to gosub
	amt_units$=callpoint!.getColumnData("GLM_BUDGETMASTER.AMT_OR_UNITS")
	if cvs(rev_src$,3)<>"" and cvs(amt_units$,3)<>""
		if rev_src$(len(rev_src$),1)<>amt_units$ or rev_src$(1,1)<"0" or rev_src$(1,1)>"5"
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

