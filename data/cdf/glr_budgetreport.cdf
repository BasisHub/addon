[[GLR_BUDGETREPORT.AWIN]]
rem --- Needed classes
use ::glo_AlignFiscalCalendar.aon::AlignFiscalCalendar

rem --- Initialize align_periods
callpoint!.setDevObject("align_fiscal_periods","N")
callpoint!.setDevObject("alignCalendar",new AlignFiscalCalendar(firm_id$))
pick_year$=callpoint!.getDevObject("current_fiscal_year")
gosub init_align_periods
[[GLR_BUDGETREPORT.GL_ACCOUNT.AVAL]]
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
[[GLR_BUDGETREPORT.GL_WILDCARD.AVAL]]
rem --- Check length of wildcard against defined mask for GL Account
	if callpoint!.getUserInput()<>""
		call "adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,m0
		if len(callpoint!.getUserInput())>len(m0$)
			msg_id$="GL_WILDCARD_LONG"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	endif
[[GLR_BUDGETREPORT.BFMC]]
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
gosub open_tables

gls01_dev=num(open_chans$[1])

dim gls01a$:open_tpls$[1]

readrecord(gls01_dev,key=firm_id$+"GL00",dom=std_missing_params)gls01a$
callpoint!.setDevObject("current_fiscal_year",gls01a.current_year$)

if gls01a.budget_flag$<>"Y"
	msg_id$="GL_NO_BUDG"
	gosub disp_message
	rem --- remove process bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif

rem --- Initialize displayColumns! object
	use ::glo_DisplayColumns.aon::DisplayColumns
	displayColumns!=new DisplayColumns(firm_id$)

rem create list for column zero of grid -- column type drop-down

codes!=SysGUI!.makeVector()
	none_list$=pad(Translate!.getTranslation("AON_(NONE)"),20)+"~"+"  ;"
	button_list$=displayColumns!.getStringButtonList()
	ldat_list$=none_list$+button_list$

for x=1 to 4
	callpoint!.setTableColumnAttribute("<<DISPLAY>>.BUD_CD_"+str(x),"LDAT",ldat_list$)
next x

	while len(button_list$)>0
		xpos=pos(";"=button_list$)
		this_button$=button_list$(1,xpos)
		button_list$=button_list$(xpos+1)

		record_id$=this_button$(pos("~"=this_button$)+1)
		record_id$=record_id$(1,len(record_id$)-2)
		amt_or_units$=this_button$(len(this_button$)-1,1)
		codes!.addItem(record_id$+amt_or_units$)
	wend

rem store desired data in user_tpl
tpl_str$="codes_ofst:c(5)"

dim user_tpl$:tpl_str$

user_tpl.codes_ofst$="0"

rem store desired vectors/objects in UserObj!
UserObj!=SysGUI!.makeVector()

UserObj!.addItem(codes!)
[[GLR_BUDGETREPORT.ASVA]]
rem --- set up selections from display fields

codes!=UserObj!.getItem(0)

for x=1 to 4
	wk_id$=callpoint!.getTableColumnAttribute("<<DISPLAY>>.BUD_CD_"+str(x),"CTLI")
	wk_ctl!=Form!.getControl(num(wk_id$))
	list_row=wk_ctl!.getSelectedIndex() - 1
	if list_row>=0
		callpoint!.setDevObject("id"+str(x),codes!.getItem(list_row))
	else
		callpoint!.setDevObject("id"+str(x),"  ")
	endif
next x
[[GLR_BUDGETREPORT.ARER]]
rem look at cols and tps in param rec; translate those to matching entry in the <<DISPLAY>> lists and set selected index

gls01_dev=fnget_dev("GLS_PARAMS")
dim gls01a$:fnget_tpl$("GLS_PARAMS")

readrecord(gls01_dev,key=firm_id$+"GL00",dom=std_missing_params)gls01a$

for x=1 to 4
	cd$=field(gls01a$,"BUD_MN_COLS_"+str(x:"00"))
	tp$=field(gls01a$,"BUD_MN_TYPE_"+str(x:"00"))
	cd_tp$="("+cd$+tp$+")"
	callpoint!.setColumnData("<<DISPLAY>>.BUD_CD_"+str(x),cd$+tp$)
next x

callpoint!.setStatus("REFRESH")
[[GLR_BUDGETREPORT.<CUSTOM>]]
#include std_functions.src
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

rem ==========================================================================
init_align_periods: rem --- Initialize align_periods for prior and next year
rem		pick_year$: input
rem ==========================================================================

	alignCalendar! = callpoint!.getDevObject("alignCalendar")
	align_prior=alignCalendar!.canAlignCalendar(str(num(pick_year$)-1))
	align_next=alignCalendar!.canAlignCalendar(str(num(pick_year$)+1))
	if align_prior or align_next then
		rem --- can align calendar
		callpoint!.setColumnEnabled("GLR_BUDGETREPORT.ALIGN_PERIODS",1)
	else
		rem --- canNOT align calendar
		callpoint!.setColumnEnabled("GLR_BUDGETREPORT.ALIGN_PERIODS",0)
		callpoint!.setDevObject("align_fiscal_periods","N")
	endif
	align_fiscal_periods$=callpoint!.getDevObject("align_fiscal_periods")
	callpoint!.setColumnData("GLR_BUDGETREPORT.ALIGN_PERIODS",align_fiscal_periods$,1)

	return

#include std_missing_params.src
