[[GLS_COLUMNS.BFMC]]
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
ldat_list$=pad("(none)",20)+"~"+"  ;"
read(glm18_dev,key="",dom=*next)
while more
	readrecord(glm18_dev,end=*break)glm18a$
	ldat_list$=ldat_list$+pad(glm18a.rev_title$,20)+"~"+glm18a.record_id$+glm18a.amt_or_units$+";"
wend

for x=1 to 4
	callpoint!.setTableColumnAttribute("<<DISPLAY>>.RECORD_CD_"+str(x),"LDAT",ldat_list$)
next x

for x=1 to 4
	callpoint!.setTableColumnAttribute("<<DISPLAY>>.BUD_CD_"+str(x),"LDAT",ldat_list$)
next x
[[GLS_COLUMNS.<CUSTOM>]]
#include std_missing_params.src
[[GLS_COLUMNS.ADIS]]
rem look at cols and tps in param rec; translate those to matching entry in the <<DISPLAY>> lists and set selected index

for x=1 to 4
	cd$=callpoint!.getColumnData("GLS_COLUMNS.ACCT_MN_COLS_"+str(x:"00"))
	tp$=callpoint!.getColumnData("GLS_COLUMNS.ACCT_MN_TYPE_"+str(x:"00"))
 	callpoint!.setColumnData("<<DISPLAY>>.RECORD_CD_"+str(x),cd$+tp$)
next x

for x=1 to 4
	cd$=callpoint!.getColumnData("GLS_COLUMNS.BUD_MN_COLS_"+str(x:"00"))
	tp$=callpoint!.getColumnData("GLS_COLUMNS.BUD_MN_TYPE_"+str(x:"00"))
	callpoint!.setColumnData("<<DISPLAY>>.BUD_CD_"+str(x),cd$+tp$)
next x

callpoint!.setStatus("REFRESH")
[[GLS_COLUMNS.BWAR]]
rem "set column and type in gl param rec based on items selected from pulldowns

for x=1 to 4
	cd_tp$=pad(callpoint!.getColumnData("<<DISPLAY>>.RECORD_CD_"+str(x)),2)
	callpoint!.setColumnData("GLS_COLUMNS.ACCT_MN_COLS_"+str(x:"00"),cd_tp$(1,1))
	callpoint!.setColumnData("GLS_COLUMNS.ACCT_MN_TYPE_"+str(x:"00"),cd_tp$(2,1))
next x

for x=1 to 4
	cd_tp$=pad(callpoint!.getColumnData("<<DISPLAY>>.BUD_CD_"+str(x)),2)
	callpoint!.setColumnData("GLS_COLUMNS.BUD_MN_COLS_"+str(x:"00"),cd_tp$(1,1))
	callpoint!.setColumnData("GLS_COLUMNS.BUD_MN_TYPE_"+str(x:"00"),cd_tp$(2,1))
next x
