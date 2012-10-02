[[GLR_ALLOCATE.ASVA]]
rem --- make sure period/year selected is in open period of prior/current/next fiscal year

date_check$=callpoint!.getColumnData("GLR_ALLOCATE.YEAR")+callpoint!.getColumnData("GLR_ALLOCATE.PERIOD")+"01"

	call stbl("+DIR_PGM")+"glc_datecheck.aon",date_check$,"Y",period$,year$,status
	if status>100 callpoint!.setStatus("ABORT")
[[GLR_ALLOCATE.<CUSTOM>]]
#include std_missing_params.src
[[GLR_ALLOCATE.ARAR]]
gls01_dev=fnget_dev("GLS_PARAMS")
gls01_tpl$=fnget_tpl$("GLS_PARAMS")
dim gls01a$:gls01_tpl$

read record (gls01_dev,key=firm_id$+"GL00",dom=std_missing_params)gls01a$
callpoint!.setColumnData("GLR_ALLOCATE.PERIOD",gls01a.current_per$)
callpoint!.setColumnData("GLR_ALLOCATE.YEAR",gls01a.current_year$)
callpoint!.setTableColumnAttribute("GLR_ALLOCATE.PERIOD","MINV","01")
callpoint!.setTableColumnAttribute("GLR_ALLOCATE.PERIOD","MAXV",str(num(gls01a.total_pers$):"00"))
callpoint!.setStatus("REFRESH")
[[GLR_ALLOCATE.BSHO]]
rem --- see if batching

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]

rem --- Open/Lock files

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"

	gosub open_tables

	gls01_dev=num(open_chans$[1]),gls01_tpl$=open_tpls$[1]

rem --- Dimension string templates

	dim gls01a$:gls01_tpl$

	gl$="N"
	status=0
	source$=pgm(-2)
	call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"GL",glw11$,gl$,status
	if status<>0 goto std_exit

