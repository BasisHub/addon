[[GLR_BUDGETREPORT.ARER]]
rem look at cols and tps in param rec; translate those to matching entry in the <<DISPLAY>> lists and set selected index

codeList!=UserObj!.getItem(num(user_tpl.codeList_ofst$))

gls01_dev=fnget_dev("GLS_PARAMS")
dim gls01a$:fnget_tpl$("GLS_PARAMS")

readrecord(gls01_dev,key=firm_id$+"GL00",dom=std_missing_params)gls01a$

for x=1 to 4
	cd$=field(gls01a$,"BUD_MN_COLS_"+str(x:"00"))
	tp$=field(gls01a$,"BUD_MN_TYPE_"+str(x:"00"))
	cd_tp$="("+cd$+tp$+")"
	wk_id$=callpoint!.getTableColumnAttribute("<<DISPLAY>>.BUD_CD_"+str(x),"CTLI")
	wk_ctl!=Form!.getControl(num(wk_id$))
	gosub find_code
	if list_row>=0 wk_ctl!.selectIndex(list_row)
next x
[[GLR_BUDGETREPORT.<CUSTOM>]]
find_code:
	list_size=codeList!.size()
	list_row=-1
	if list_size<>0
		for wk=0 to list_size-1
			if pos(cd_tp$=codeList!.getItem(wk))<>0 list_row=wk
		next wk
		if list_row=-1 list_row=0
	endif
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
[[GLR_BUDGETREPORT.BSHO]]
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

rem create list for column zero of grid -- column type drop-down
more=1
codeList!=SysGUI!.makeVector()
codes!=SysGUI!.makeVector()
read(glm18_dev,key="",dom=*next)
while more
	readrecord(glm18_dev,end=*break)glm18a$
	codeList!.addItem(glm18a.rev_title$+"("+glm18a.record_id$+glm18a.amt_or_units$+")")
	codes!.addItem(glm18a.record_id$+glm18a.amt_or_units$)
wend

codeList!.insertItem(0,"(none)")

for x=1 to 4
	wk_id$=callpoint!.getTableColumnAttribute("<<DISPLAY>>.BUD_CD_"+str(x),"CTLI")
	wk_ctl!=Form!.getControl(num(wk_id$))
	wk_ctl!.insertItems(0,codeList!)
next x

rem store desired data in user_tpl
tpl_str$="codes_ofst:c(5),codeList_ofst:c(5)"

dim user_tpl$:tpl_str$

user_tpl.codes_ofst$="0"
user_tpl.codeList_ofst$="1"

rem store desired vectors/objects in UserObj!
UserObj!=SysGUI!.makeVector()

UserObj!.addItem(codes!)
UserObj!.addItem(codeList!)

ctl_stat$=" "
ctl_name$="<<DISPLAY>>.BUD_CD_1"
gosub disable_fields
ctl_name$="<<DISPLAY>>.BUD_CD_2"
gosub disable_fields
ctl_name$="<<DISPLAY>>.BUD_CD_3"
gosub disable_fields
ctl_name$="<<DISPLAY>>.BUD_CD_4"
gosub disable_fields
