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
num_files=2
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
open_tables$[2]="GLM_RECORDTYPES",open_opts$[2]="OTA"
gosub open_tables

gls01_dev=num(open_chans$[1])
glm18_dev=num(open_chans$[2])

dim gls01a$:open_tpls$[1]
dim glm18a$:open_tpls$[2]

readrecord(gls01_dev,key=firm_id$+"GL00",dom=std_missing_params)gls01a$

if gls01a.budget_flag$<>"Y"
	msg_id$="GL_NO_BUDG"
	gosub disp_message
	rem --- remove process bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif

rem create list for column zero of grid -- column type drop-down

more=1
codes!=SysGUI!.makeVector()
ldat_list$=pad(Translate!.getTranslation("AON_(NONE)"),20)+"~"+"  ;"

read(glm18_dev,key="",dom=*next)
while more
	readrecord(glm18_dev,end=*break)glm18a$
	codes!.addItem(glm18a.record_id$+glm18a.amt_or_units$)
	ldat_list$=ldat_list$+pad(glm18a.rev_title$,20)+"~"+glm18a.record_id$+glm18a.amt_or_units$+";"
wend

for x=1 to 4
	callpoint!.setTableColumnAttribute("<<DISPLAY>>.BUD_CD_"+str(x),"LDAT",ldat_list$)
next x

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
