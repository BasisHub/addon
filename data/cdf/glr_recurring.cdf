[[GLR_RECURRING.ARAR]]
gls01_dev=fnget_dev("GLS_PARAMS")
gls01_tpl$=fnget_tpl$("GLS_PARAMS")
dim gls01a$:gls01_tpl$

read record (gls01_dev,key=firm_id$+"GL00",dom=std_missing_params)gls01a$
callpoint!.setColumnData("GLR_RECURRING.POSTING_YEAR",gls01a.current_year$)
callpoint!.setTableColumnAttribute("GLR_RECURRING.POSTING_PER","MINV","01")
callpoint!.setTableColumnAttribute("GLR_RECURRING.POSTING_PER","MAXV",str(num(gls01a.total_pers$):"00"))
callpoint!.setStatus("REFRESH")
[[GLR_RECURRING.BSHO]]
rem --- Open/Lock files

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"

	gosub open_tables

	gls01_dev=num(open_chans$[1]),gls01_tpl$=open_tpls$[1]

rem --- Dimension string templates

	dim gls01a$:gls01_tpl$
[[GLR_RECURRING.<CUSTOM>]]
#include std_missing_params.src
