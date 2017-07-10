[[GLR_ALLOCATE.ASVA]]
rem --- Verify haven't exceeded calendar total periods for current GL fiscal year
	period$=callpoint!.getColumnData("GLR_ALLOCATE.PERIOD")
	if cvs(period$,2)<>"" then
		period=num(period$)
		total_pers=num(callpoint!.getDevObject("total_pers"))
		if period<1 or period>total_pers then
			msg_id$="AD_BAD_FISCAL_PERIOD"
			dim msg_tokens$[2]
			msg_tokens$[1]=str(total_pers)
			msg_tokens$[2]=callpoint!.getColumnData("GLR_ALLOCATE.YEAR")
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

rem --- Restrict to only unlocked periods in the current fiscal year
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
callpoint!.setStatus("REFRESH")

rem --- Set maximum number of periods allowed for this fiscal year
	gls_calendar_dev=fnget_dev("GLS_CALENDAR")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
	current_year$=callpoint!.getColumnData("GLR_ALLOCATE.YEAR")
	readrecord(gls_calendar_dev,key=firm_id$+current_year$,dom=*next)gls_calendar$
	callpoint!.setDevObject("total_pers",gls_calendar.total_pers$)
[[GLR_ALLOCATE.BSHO]]
rem --- see if batching

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]

rem --- Open/Lock files

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="GLS_CALENDAR",open_opts$[2]="OTA"

	gosub open_tables

	gls01_dev=num(open_chans$[1]),gls01_tpl$=open_tpls$[1]

rem --- Dimension string templates

	dim gls01a$:gls01_tpl$

	gl$="N"
	status=0
	source$=pgm(-2)
	call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"GL",glw11$,gl$,status
	if status<>0 goto std_exit
