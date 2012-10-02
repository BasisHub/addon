[[APU_PERIODEND.AWIN]]
rem --- Open/Lock files

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APS_PARAMS",open_opts$[1]="OTA"

	gosub open_tables

	aps01_dev=num(open_chans$[1]),aps01_tpl$=open_tpls$[1]

rem --- Dimension string templates

	dim aps01a$:aps01_tpl$
[[APU_PERIODEND.ARAR]]
aps01_dev=fnget_dev("APS_PARAMS")
aps01_tpl$=fnget_tpl$("APS_PARAMS")
dim aps01a$:aps01_tpl$

read record (aps01_dev,key=firm_id$+"AP00",dom=std_missing_params)aps01a$
callpoint!.setColumnData("APU_PERIODEND.PERIOD_YEAR",aps01a.current_per$+aps01a.current_year$)
callpoint!.setStatus("REFRESH")
[[APU_PERIODEND.<CUSTOM>]]
#include std_missing_params.src
