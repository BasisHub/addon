[[GLS_PARAMS.BSHO]]
rem -- Open/lock files
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_CALENDAR",open_opts$[1]="OTA"
	gosub open_tables
[[GLS_PARAMS.CURRENT_PER.AVAL]]
rem --- CURRENT_PER cannot be greater than TOTAL_PERS for the current fiscal year
	current_per$=callpoint!.getUserInput()
	year$=cvs(callpoint!.getColumnData("GLS_PARAMS.CURRENT_YEAR"),2)
	if year$<>"" then
		gls_calendar_dev=fnget_dev("GLS_CALENDAR")
		dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
		find record(gls_calendar_dev,key=firm_id$+year$,err=*next)gls_calendar$

		if cvs(gls_calendar.total_pers$,2)<>"" and num(current_per$)>num(gls_calendar.total_pers$) then
			msg_id$="AD_BAD_FISCAL_PERIOD"
			dim msg_tokens$[2]
			msg_tokens$[1]=gls_calendar.total_pers$
			msg_tokens$[2]=callpoint!.getColumnData("GLS_PARAMS.CURRENT_YEAR")
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
	endif
[[GLS_PARAMS.ASVA]]
rem --- Check For Required Fiscal Calendars
	theFirm$=firm_id$
	call stbl("+DIR_PGM")+"glc_checkfiscalcalendars.aon",theFirm$,Translate!,status
[[GLS_PARAMS.AREC]]
rem --- Init new record

	callpoint!.setColumnData("GLS_PARAMS.POST_TO_GL","Y")
	curr_date$=stbl("+SYSTEM_DATE")
	callpoint!.setColumnData("GLS_PARAMS.CURRENT_YEAR",curr_date$(1,4))
	callpoint!.setColumnData("GLS_PARAMS.CURRENT_PER",curr_date$(5,2))
