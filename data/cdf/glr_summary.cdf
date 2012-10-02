[[GLR_SUMMARY.BFMC]]
use ::ado_util.src::util

rem --- creating a drop-down list of glm18 codes; not using a simple element that validates to glm18
rem ---	because glm18 contains record id/actual vs budget/amt or units, whereas param file just contains
rem ---	first and 3rd character (record id/amt or units)... this mismatch should be resolved at some point
rem ---	by either revising glm18 or the param file

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
ldat_list$=pad(Translate!.getTranslation("AON_(NONE)"),20)+"~"+"  ;"
read(glm18_dev,key="",dom=*next)
while more
	readrecord(glm18_dev,end=*break)glm18a$
	ldat_list$=ldat_list$+pad(glm18a.rev_title$,20)+"~"+glm18a.record_id$+glm18a.amt_or_units$+";"
wend

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

callpoint!.setStatus("REFRESH")
[[GLR_SUMMARY.<CUSTOM>]]
#include std_missing_params.src
