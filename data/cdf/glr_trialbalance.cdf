[[GLR_TRIALBALANCE.PICK_GL_PER.AVAL]]
rem --- Verify haven't exceeded calendar total periods for current GL fiscal year
	period$=callpoint!.getUserInput()
	if cvs(period$,2)<>"" and period$<>callpoint!.getColumnData("GLR_TRIALBALANCE.PICK_GL_PER") then
		period=num(period$)
		total_pers=num(callpoint!.getDevObject("total_pers"))
		if period<1 or period>total_pers then
			msg_id$="AD_BAD_FISCAL_PERIOD"
			dim msg_tokens$[2]
			msg_tokens$[1]=str(total_pers)
			msg_tokens$[2]=callpoint!.getColumnData("GLR_TRIALBALANCE.PICK_YEAR")
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
	endif
[[GLR_TRIALBALANCE.PICK_YEAR.AVAL]]
rem --- Verify calendar exists for entered GL fiscal year
	year$=callpoint!.getUserInput()
	if cvs(year$,2)<>"" and year$<>callpoint!.getColumnData("GLR_TRIALBALANCE.PICK_YEAR") then
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

		rem --- Verify haven't exceeded calendar total periods for current GL fiscal year
		period$=callpoint!.getColumnData("GLR_TRIALBALANCE.PICK_GL_PER")
		if cvs(period$,2)<>"" then
			period=num(period$)
			total_pers=num(callpoint!.getDevObject("total_pers"))
			if period<1 or period>total_pers then
				msg_id$="AD_BAD_FISCAL_PERIOD"
				dim msg_tokens$[2]
				msg_tokens$[1]=str(total_pers)
				msg_tokens$[2]=year$
				gosub disp_message
				callpoint!.setStatus("ABORT")
				break
			endif
		endif
	endif
[[GLR_TRIALBALANCE.<CUSTOM>]]
#include std_missing_params.src
[[GLR_TRIALBALANCE.ARAR]]
gls01_dev=fnget_dev("GLS_PARAMS")
gls01_tpl$=fnget_tpl$("GLS_PARAMS")
dim gls01a$:gls01_tpl$

read record (gls01_dev,key=firm_id$+"GL00",dom=std_missing_params)gls01a$
callpoint!.setColumnData("GLR_TRIALBALANCE.PICK_GL_PER",gls01a.current_per$)
callpoint!.setColumnData("GLR_TRIALBALANCE.PICK_YEAR",gls01a.current_year$)
callpoint!.setStatus("REFRESH")

rem --- Set maximum number of periods allowed for this fiscal year
	gls_calendar_dev=fnget_dev("GLS_CALENDAR")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
	current_year$=callpoint!.getColumnData("GLR_TRIALBALANCE.PICK_YEAR")
	readrecord(gls_calendar_dev,key=firm_id$+current_year$,dom=*next)gls_calendar$
	callpoint!.setDevObject("total_pers",gls_calendar.total_pers$)
[[GLR_TRIALBALANCE.BSHO]]
rem --- Open/Lock files

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="GLS_CALENDAR",open_opts$[2]="OTA"

	gosub open_tables
