[[OPR_SALESTAX.BSHO]]
rem --- Is General Ledger installed?
	gl$="N"
	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
	gl$=info$[20]
	callpoint!.setDevObject("gl",gl$)

rem --- Open files
	num_files=1
	if gl$="Y" then num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARS_PARAMS",open_opts$[1]="OTA"
	if gl$="Y" then
		open_tables$[2]="GLS_CALENDAR",open_opts$[2]="OTA"
	endif

	gosub open_tables

	arsParams_dev=num(open_chans$[1])
	dim arsParams$:open_tpls$[1]

rem --- AR params rec must exist for the firm
	findrecord (arsParams_dev,key=firm_id$+"AR00",dom=*next)arsParams$
	if arsParams.firm_id$<>firm_id$ then
		msg_id$="AR_PARAM_ERR"
		gosub disp_message
		release
	endif
	callpoint!.setDevObject("ar_period",arsParams.current_per$)
	callpoint!.setDevObject("ar_year",arsParams.current_year$)
[[OPR_SALESTAX.AREC]]
rem --- Set default Beginning and Ending Dates
	if callpoint!.getDevObject("gl")="Y" then
		rem --- GL is installed, so use the prior AR fiscal period end date month/year
		ar_period$=callpoint!.getDevObject("ar_period")
		ar_year$=callpoint!.getDevObject("ar_year")

		rem --- Get fiscal calendar for prior AR fiscal period
		fiscalYear$=ar_year$
		if num(ar_period$)=1 then fiscalYear$=str(num(ar_year$)-1)
		glsCalendar_dev=fnget_dev("GLS_CALENDAR")
		dim glsCalendar$:fnget_tpl$("GLS_CALENDAR")
		findrecord(glsCalendar_dev,key=firm_id$+fiscalYear$,dom=*next)glsCalendar$
		if glsCalendar.firm_id$<>firm_id$ then
			msg_id$="GL_FIRM_MISSING_CAL"
			dim msg_tokens$[2]
			msg_tokens$[1]=firm_id$
			msg_tokens$[2]=ar_year$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif

		rem --- Get end date for prior AR fiscal period
		priorPeriod=num(ar_period$)-1
		if priorPeriod<1 then priorPeriod=num(glsCalendar.total_pers$)
		prior_per_ending$=field(glsCalendar$,"PER_ENDING_"+str(priorPeriod:"00"))
		callpoint!.setColumnData("OPR_SALESTAX.PICK_DATE_YYYYMM_1",fiscalYear$+prior_per_ending$(1,2),1)
		callpoint!.setColumnData("OPR_SALESTAX.PICK_DATE_YYYYMM_2",fiscalYear$+prior_per_ending$(1,2),1)
	else
		rem --- GL not installed, so use the current system month/year
		callpoint!.setColumnData("OPR_SALESTAX.PICK_DATE_YYYYMM_1",stbl("+SYSTEM_DATE")(1,6),1)
		callpoint!.setColumnData("OPR_SALESTAX.PICK_DATE_YYYYMM_2",stbl("+SYSTEM_DATE")(1,6),1)
	endif
