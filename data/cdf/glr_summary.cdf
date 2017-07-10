[[GLR_SUMMARY.GL_ACCOUNT.AVAL]]
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
[[GLR_SUMMARY.GL_WILDCARD.AVAL]]
rem --- Check length of wildcard against defined mask for GL Account
	if callpoint!.getUserInput()<>""
		call "adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,m0
		if len(callpoint!.getUserInput())>len(m0$)
			msg_id$="GL_WILDCARD_LONG"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	endif
[[GLR_SUMMARY.BFMC]]
rem --- Needed classes
use ::glo_AlignFiscalCalendar.aon::AlignFiscalCalendar
use ::ado_util.src::util

rem --- creating a drop-down list of glm18 codes; not using a simple element that validates to glm18
rem ---	because glm18 contains record id/actual vs budget/amt or units, whereas param file just contains
rem ---	first and 3rd character (record id/amt or units)... this mismatch should be resolved at some point
rem ---	by either revising glm18 or the param file

num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
gosub open_tables

gls01_dev=num(open_chans$[1])

dim gls01a$:open_tpls$[1]

readrecord(gls01_dev,key=firm_id$+"GL00",dom=std_missing_params)gls01a$


rem --- Initialize displayColumns! object
use ::glo_DisplayColumns.aon::DisplayColumns
displayColumns!=new DisplayColumns(firm_id$)

rem create list for column zero of grid -- column type drop-down
none_list$=pad(Translate!.getTranslation("AON_(NONE)"),20)+"~"+"  ;"
button_list$=displayColumns!.getStringButtonList()
ldat_list$=none_list$+button_list$

for x=1 to 4
	callpoint!.setTableColumnAttribute("<<DISPLAY>>.RECORD_CD_"+str(x),"LDAT",ldat_list$)
next x
[[GLR_SUMMARY.ARER]]
rem --- now look at cols and tps in param rec
rem ---	and set <<DISPLAY>> fields accordingly

gls01_dev=fnget_dev("GLS_PARAMS")
dim gls01a$:fnget_tpl$("GLS_PARAMS")

readrecord(gls01_dev,key=firm_id$+"GL00",dom=std_missing_params)gls01a$

for x=1 to 4
	cd$=field(gls01a$,"ACCT_MN_COLS_"+str(x:"00"))
	tp$=field(gls01a$,"ACCT_MN_TYPE_"+str(x:"00"))
	callpoint!.setColumnData("<<DISPLAY>>.RECORD_CD_"+str(x),cd$+tp$)
next x

rem --- Initialize align_periods for prior and next year
pick_year$=gls01a.current_year$
gosub init_align_periods

callpoint!.setStatus("REFRESH")
[[GLR_SUMMARY.<CUSTOM>]]
#include std_missing_params.src
#include std_functions.src

rem ==========================================================================
init_align_periods: rem --- Initialize align_periods for prior and next year
rem		pick_year$: input
rem ==========================================================================
	alignCalendar! = new AlignFiscalCalendar(firm_id$)
	align_prior=alignCalendar!.canAlignCalendar(str(num(pick_year$)-1))
	align_next=alignCalendar!.canAlignCalendar(str(num(pick_year$)+1))
	if align_prior or align_next then
		rem --- can align calendar
		callpoint!.setColumnEnabled("GLR_SUMMARY.ALIGN_PERIODS",1)
	else
		rem --- canNOT align calendar
		callpoint!.setColumnEnabled("GLR_SUMMARY.ALIGN_PERIODS",0)
	endif
	callpoint!.setColumnData("GLR_SUMMARY.ALIGN_PERIODS","N",1)

	return
