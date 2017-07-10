[[ARR_DRLLDOWN.PICK_YEAR.AVAL]]
rem --- Verify calendar exists for entered AR fiscal year
	year$=callpoint!.getUserInput()
	if cvs(year$,2)<>"" and year$<>callpoint!.getColumnData("ARR_DRLLDOWN.PICK_YEAR") then
		gls_calendar_dev=fnget_dev("GLS_CALENDAR")
		dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
		readrecord(gls_calendar_dev,key=firm_id$+year$,dom=*next)gls_calendar$
		if cvs(gls_calendar.year$,2)="" then
			msg_id$="AD_NO_FISCAL_CAL"
			dim msg_tokens$[1]
			msg_tokens$[1]=year$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
		callpoint!.setDevObject("total_pers",gls_calendar.total_pers$)
	endif
[[ARR_DRLLDOWN.PICK_GL_PER.AVAL]]
rem --- Verify haven't exceeded calendar total periods for current AR fiscal year
	period$=callpoint!.getUserInput()
	if cvs(period$,2)<>"" and period$<>callpoint!.getColumnData("ARR_DRLLDOWN.PICK_GL_PER") then
		period=num(period$)
		total_pers=num(callpoint!.getDevObject("total_pers"))
		if period<1 or period>total_pers then
			msg_id$="AD_BAD_FISCAL_PERIOD"
			dim msg_tokens$[2]
			msg_tokens$[1]=str(total_pers)
			msg_tokens$[2]=callpoint!.getColumnData("ARR_DRLLDOWN.PICK_YEAR")
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
	endif
[[ARR_DRLLDOWN.<CUSTOM>]]
#include std_missing_params.src
[[ARR_DRLLDOWN.ARAR]]
ars01_dev=fnget_dev("ARS_PARAMS")
ars01_tpl$=fnget_tpl$("ARS_PARAMS")
dim ars01a$:ars01_tpl$

read record (ars01_dev,key=firm_id$+"AR00",dom=std_missing_params)ars01a$
callpoint!.setColumnData("ARR_DRLLDOWN.PICK_GL_PER",ars01a.current_per$)
callpoint!.setColumnData("ARR_DRLLDOWN.PICK_YEAR",ars01a.current_year$)
callpoint!.setStatus("REFRESH")

rem --- Set maximum number of periods allowed for this fiscal year
	gls_calendar_dev=fnget_dev("GLS_CALENDAR")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
	current_year$=callpoint!.getColumnData("ARR_DRLLDOWN.PICK_YEAR")
	readrecord(gls_calendar_dev,key=firm_id$+current_year$,dom=*next)gls_calendar$
	callpoint!.setDevObject("total_pers",gls_calendar.total_pers$)
[[ARR_DRLLDOWN.BSHO]]
rem --- Open/Lock files

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="GLS_CALENDAR",open_opts$[2]="OTA"

	gosub open_tables
