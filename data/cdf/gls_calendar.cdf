[[GLS_CALENDAR.AWRI]]
rem --- When fiscal calendar for the initial fiscal year is saved, create duplicate fiscal calendars for the prior and next fiscal years.
	year$=callpoint!.getDevObject("copy_calendar")
	if year$<>"" then
		dim gls_params$:fnget_tpl$("GLS_PARAMS")
		gls_params$=callpoint!.getDevObject("gls_params")
		gls_calendar_dev=fnget_dev("GLS_CALENDAR")
		dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
		readrecord(gls_calendar_dev,key=firm_id$+year$,dom=*endif)gls_calendar$

		rem --- Create prior fiscal year's calendar
		dim prior_cal$:fnget_tpl$("GLS_CALENDAR")
		prior_cal$=gls_calendar$
		prior_cal.year$=str(num(gls_calendar.year$)-1)
		for per=1 to num(prior_cal.total_pers$)
			field prior_cal$,"LOCKED_FLAG_"+str(per:"00")="Y"
			field prior_cal$,"LOCKED_DATE_"+str(per:"00")=date(0:"%Yd%Mz%Dz")
			per_ending$=field(prior_cal$,"PER_ENDING_"+str(per:"00"))
			if (gls_params.adjust_february and per_ending$="0228") or per_ending$="0229" then
				rem --- Adjust last day of February for leap year
				calendar_year=num(prior_cal.year$)
				if per_ending$<prior_cal.cal_start_date$ then calendar_year=calendar_year+1
				Calendar! = new java.util.GregorianCalendar()
				if per_ending$="0229" and !Calendar!.isLeapYear(calendar_year) then field prior_cal$,"PER_ENDING_"+str(per:"00")="0228"
				if per_ending$="0228" and Calendar!.isLeapYear(calendar_year) then field prior_cal$,"PER_ENDING_"+str(per:"00")="0229"
			endif
		next per

		prior_cal$=field(prior_cal$)
		writerecord(gls_calendar_dev)prior_cal$

		rem --- Create next fiscal year's calendar only if GL parameter create_next_cal is checked/true
		dim gls_params$:fnget_tpl$("GLS_PARAMS")
		gls_params$=callpoint!.getDevObject("gls_params")
		if gls_params.create_next_cal then
			rem --- Next fiscal year
			dim next_cal$:fnget_tpl$("GLS_CALENDAR")
			next_cal$=gls_calendar$
			next_cal.year$=str(num(gls_calendar.year$)+1)
			for per=1 to num(next_cal.total_pers$)
				field next_cal$,"LOCKED_FLAG_"+str(per:"00")="N"
				field next_cal$,"LOCKED_DATE_"+str(per:"00")=""
				per_ending$=field(next_cal$,"PER_ENDING_"+str(per:"00"))
				if (gls_params.adjust_february and per_ending$="0228") or per_ending$="0229" then
					rem --- Adjust last day of February for leap year
					calendar_year=num(next_cal.year$)
					if per_ending$<next_cal.cal_start_date$ then calendar_year=calendar_year+1
					Calendar! = new java.util.GregorianCalendar()
					if per_ending$="0229" and !Calendar!.isLeapYear(calendar_year) then field next_cal$,"PER_ENDING_"+str(per:"00")="0228"
					if per_ending$="0228" and Calendar!.isLeapYear(calendar_year) then field next_cal$,"PER_ENDING_"+str(per:"00")="0229"
				endif
			next per

			next_cal$=field(next_cal$)
			writerecord(gls_calendar_dev)next_cal$
		endif

		rem --- Reset file pointer for saved record
		read(gls_calendar_dev,key=firm_id$+year$,dom=*next)
	endif

rem --- Remove glw_acctsummary records if the fiscal calendar was changed.
	if callpoint!.getDevObject("calendar_changed") then
		dim gls_params$:fnget_tpl$("GLS_PARAMS")
		gls_params$=callpoint!.getDevObject("gls_params")
		if callpoint!.getColumnData("GLS_CALENDAR.YEAR")=gls_params.current_year$ then
			rem --- Remove all glw_acctsummary records for the FIRM if the fiscal calendar (total_pers, cal_start_date, or per_ending_nn)
			rem --- for the CURRENT FISCAL YEAR changes.
			call stbl("+DIR_PGM")+"adc_clearpartial.aon","",fnget_dev("GLW_ACCTSUMMARY"),firm_id$,status
		else
			rem --- Remove all glw_acctsummary records for a YEAR if the fiscal calendar (total_pers, cal_start_date, or per_ending_nn)
			rem --- changes for THAT FISCAL YEAR.
			call stbl("+DIR_PGM")+"adc_clearpartial.aon","",fnget_dev("GLW_ACCTSUMMARY"),firm_id$+callpoint!.getColumnData("GLS_CALENDAR.YEAR"),status
		endif
		if status then
			callpoint!.setStatus("ABORT")
			break
		endif
	endif
[[GLS_CALENDAR.PER_ENDING_03.AVAL]]
rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="03" then
		per_ending$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PER_ENDING_03"),2)="" then
		per_ending$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if mmdd$<>per_ending$ then callpoint!.setUserInput(mmdd$)
	endif

rem --- Check PER_ENDING date against GLT_TRANSDETAIL (glt-06) period dates
	period$="03"
	per_ending$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- Validate period ending date
	per_ending$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break
[[GLS_CALENDAR.PER_ENDING_04.AVAL]]
rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="04" then
		per_ending$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PER_ENDING_04"),2)="" then
		per_ending$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if mmdd$<>per_ending$ then callpoint!.setUserInput(mmdd$)
	endif

rem --- Check PER_ENDING date against GLT_TRANSDETAIL (glt-06) period dates
	period$="04"
	per_ending$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- Validate period ending date
	per_ending$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break
[[GLS_CALENDAR.PER_ENDING_05.AVAL]]
rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="05" then
		per_ending$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PER_ENDING_05"),2)="" then
		per_ending$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if mmdd$<>per_ending$ then callpoint!.setUserInput(mmdd$)
	endif

rem --- Check PER_ENDING date against GLT_TRANSDETAIL (glt-06) period dates
	period$="05"
	per_ending$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- Validate period ending date
	per_ending$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break
[[GLS_CALENDAR.PER_ENDING_06.AVAL]]
rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="06" then
		per_ending$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PER_ENDING_06"),2)="" then
		per_ending$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if mmdd$<>per_ending$ then callpoint!.setUserInput(mmdd$)
	endif

rem --- Check PER_ENDING date against GLT_TRANSDETAIL (glt-06) period dates
	period$="06"
	per_ending$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- Validate period ending date
	per_ending$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break
[[GLS_CALENDAR.PER_ENDING_07.AVAL]]
rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="07" then
		per_ending$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PER_ENDING_07"),2)="" then
		per_ending$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if mmdd$<>per_ending$ then callpoint!.setUserInput(mmdd$)
	endif

rem --- Check PER_ENDING date against GLT_TRANSDETAIL (glt-06) period dates
	period$="07"
	per_ending$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- Validate period ending date
	per_ending$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break
[[GLS_CALENDAR.PER_ENDING_08.AVAL]]
rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="08" then
		per_ending$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PER_ENDING_08"),2)="" then
		per_ending$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if mmdd$<>per_ending$ then callpoint!.setUserInput(mmdd$)
	endif

rem --- Check PER_ENDING date against GLT_TRANSDETAIL (glt-06) period dates
	period$="08"
	per_ending$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- Validate period ending date
	per_ending$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break
[[GLS_CALENDAR.PER_ENDING_09.AVAL]]
rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="09" then
		per_ending$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PER_ENDING_09"),2)="" then
		per_ending$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if mmdd$<>per_ending$ then callpoint!.setUserInput(mmdd$)
	endif

rem --- Check PER_ENDING date against GLT_TRANSDETAIL (glt-06) period dates
	period$="09"
	per_ending$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- Validate period ending date
	per_ending$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break
[[GLS_CALENDAR.PER_ENDING_10.AVAL]]
rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="10" then
		per_ending$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PER_ENDING_10"),2)="" then
		per_ending$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if mmdd$<>per_ending$ then callpoint!.setUserInput(mmdd$)
	endif

rem --- Check PER_ENDING date against GLT_TRANSDETAIL (glt-06) period dates
	period$="10"
	per_ending$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- Validate period ending date
	per_ending$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break
[[GLS_CALENDAR.PER_ENDING_11.AVAL]]
rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="11" then
		per_ending$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PER_ENDING_11"),2)="" then
		per_ending$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if mmdd$<>per_ending$ then callpoint!.setUserInput(mmdd$)
	endif

rem --- Check PER_ENDING date against GLT_TRANSDETAIL (glt-06) period dates
	period$="11"
	per_ending$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- Validate period ending date
	per_ending$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break
[[GLS_CALENDAR.PER_ENDING_12.AVAL]]
rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="12" then
		per_ending$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PER_ENDING_12"),2)="" then
		per_ending$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if mmdd$<>per_ending$ then callpoint!.setUserInput(mmdd$)
	endif

rem --- Check PER_ENDING date against GLT_TRANSDETAIL (glt-06) period dates
	period$="12"
	per_ending$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- Validate period ending date
	per_ending$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break
[[GLS_CALENDAR.BSHO]]
rem -- Get GL parameters
	num_files=6
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="GLT_TRANSDETAIL",open_opts$[2]="OTA"
	open_tables$[3]="GLM_ACCTSUMMARY",open_opts$[3]="OTA"
	open_tables$[4]="ADS_COMPINFO",open_opts$[4]="OTA"
	open_tables$[5]="GLW_ACCTSUMMARY",open_opts$[5]="OTA"
	open_tables$[6]="GLM_ACCTBUDGET",open_opts$[6]="OTA"
	gosub open_tables
	gls_params_dev=num(open_chans$[1])
	dim gls_params$:open_tpls$[1]

	find record(gls_params_dev,key=firm_id$+"GL00",err=std_missing_params)gls_params$
	callpoint!.setDevObject("gls_params",gls_params$)

rem --- Need to know later if form was just launched
	callpoint!.setDevObject("justLaunched","1")
[[GLS_CALENDAR.BWRI]]
rem --- TOTAL_PERS must be >= last period in glt_transdetail (glt-06) for this fiscal year
	total_pers=num(callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS"))
	gosub check_total_pers
	if abort then break

rem --- CAL_START_DATE must be <= first trns_date in glt_transdetail (glt-06) for this fiscal year
	cal_start_date$=callpoint!.getColumnData("GLS_CALENDAR.CAL_START_DATE")
	gosub check_cal_start_date
	if abort then break

rem --- Check PER_ENDING date against GLT_TRANSDETAIL (glt-06) period dates
	for per=1 to 13
		period$=str(per:"00")
		per_ending$=callpoint!.getColumnData("GLS_CALENDAR.PER_ENDING_"+period$)
		gosub check_transdetail_period_dates
		if abort then break
	next per
	if abort then break

rem --- Check United States (US) specific requirements for fiscal calendars
	ads_compinfo_dev=fnget_dev("ADS_COMPINFO")
	dim ads_compinfo$:fnget_tpl$("ADS_COMPINFO")
	readrecord(ads_compinfo_dev,key=firm_id$,dom=*next)ads_compinfo$
	if ads_compinfo.country_id$="US" then gosub validate_us_requirements

rem --- When fiscal calendar for the initial fiscal year is saved, create duplicate fiscal calendars for the prior and next fiscal years.
	gls_calendar_dev=fnget_dev("GLS_CALENDAR")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")

	read(gls_calendar_dev,key=firm_id$,dom=*next)
	gls_calendar_key$=key(gls_calendar_dev,end=*next)
	if pos(firm_id$=gls_calendar_key$)<>1 then
		callpoint!.setDevObject("copy_calendar",callpoint!.getColumnData("GLS_CALENDAR.YEAR"))
	else
		callpoint!.setDevObject("copy_calendar","")
	endif

rem --- Was this fiscal calendar changed (total_pers, cal_start_date, or per_ending_nn)?
	callpoint!.setDevObject("calendar_changed",0)
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")<>callpoint!.getColumnUndoData("GLS_CALENDAR.TOTAL_PERS") then
		callpoint!.setDevObject("calendar_changed",1)
	else
		if callpoint!.getColumnData("GLS_CALENDAR.CAL_START_DATE")<>callpoint!.getColumnUndoData("GLS_CALENDAR.CAL_START_DATE") then
			callpoint!.setDevObject("calendar_changed",1)
		else
			for per=1 to num(callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS"))
				if callpoint!.getColumnData("GLS_CALENDAR.PER_ENDING_"+str(per:"00"))<>callpoint!.getColumnUndoData("GLS_CALENDAR.PER_ENDING_"+str(per:"00")) then
					callpoint!.setDevObject("calendar_changed",1)
                            		break
				endif
			next per
		endif
	endif
[[GLS_CALENDAR.BDEL]]
rem --- Never allow deleting the calendar for the prior/current/next fiscal year.
	dim gls_params$:fnget_tpl$("GLS_PARAMS")
	gls_params$=callpoint!.getDevObject("gls_params")
	current_year=num(gls_params.current_year$)
	year=num(callpoint!.getColumnData("GLS_CALENDAR.YEAR"))
	if year=current_year-1 or year=current_year or year=current_year+1 then
		msg_id$="GL_NOT_DEL_PCN_CAL"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Can only delete fiscal calendars where there is no corresponding data in 
rem --- GLM_ACCTSUMMARY (glm-02) or GLM_ACCTBUDGET.
	cal_in_use=0
	year$=callpoint!.getColumnData("GLS_CALENDAR.YEAR")

	glm_acctsummary_dev=fnget_dev("GLM_ACCTSUMMARY")
	dim glm_acctsummary$:fnget_tpl$("GLM_ACCTSUMMARY")
	read(glm_acctsummary_dev,key=firm_id$+year$,knum="BY_YEAR_ACCT",dom=*next)
	readrecord(glm_acctsummary_dev,end=*next)glm_acctsummary$
	if glm_acctsummary.year$=year$ then cal_in_use=1

	if !cal_in_use then
		glm_acctbudget_dev=fnget_dev("GLM_ACCTBUDGET")
		dim glm_acctbudget$:fnget_tpl$("GLM_ACCTBUDGET")
		read(glm_acctbudget_dev,key=firm_id$+year$,knum="BY_YEAR_ACCT",dom=*next)
		readrecord(glm_acctbudget_dev,end=*next)glm_acctbudget$
		if glm_acctbudget.year$=year$ then cal_in_use=1
	endif

	if cal_in_use then
		msg_id$="GL_CANNOT_DEL_CAL"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif
[[GLS_CALENDAR.PER_ENDING_01.AVAL]]
rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="01" then
		per_ending$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PER_ENDING_01"),2)="" then
		per_ending$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if mmdd$<>per_ending$ then callpoint!.setUserInput(mmdd$)
	endif

rem --- Check PER_ENDING date against GLT_TRANSDETAIL (glt-06) period dates
	period$="01"
	per_ending$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- Validate period ending date
	per_ending$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break
[[GLS_CALENDAR.PER_ENDING_02.AVAL]]
rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="02" then
		per_ending$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PER_ENDING_02"),2)="" then
		per_ending$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if mmdd$<>per_ending$ then callpoint!.setUserInput(mmdd$)
	endif

rem --- Check PER_ENDING date against GLT_TRANSDETAIL (glt-06) period dates
	period$="02"
	per_ending$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- Validate period ending date
	per_ending$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break
[[GLS_CALENDAR.PER_ENDING_13.AVAL]]
rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="13" then
		per_ending$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PER_ENDING_13"),2)="" then
		per_ending$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if mmdd$<>per_ending$ then callpoint!.setUserInput(mmdd$)
	endif

rem --- Check PER_ENDING date against GLT_TRANSDETAIL (glt-06) period dates
	period$="13"
	per_ending$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- Validate period ending date
	per_ending$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break
[[GLS_CALENDAR.CAL_START_DATE.AVAL]]
rem --- Must be a valid date
	cal_start_date$=callpoint!.getUserInput()
	year=num(callpoint!.getColumnData("GLS_CALENDAR.YEAR"))
	julian=-1
	julian=jul(year,num(cal_start_date$(1,2)),num(cal_start_date$(3,2)),err=*next)
	if julian<0 then
		msg_id$="INVALID_DATE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Must be the day after the ending period of the prior year when there is a calendar for the prior year.
	gls_calendar_dev=fnget_dev("GLS_CALENDAR")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
	prior_year$=str(num(callpoint!.getColumnData("GLS_CALENDAR.YEAR"))-1)
	readrecord(gls_calendar_dev,key=firm_id$+prior_year$,dom=*next)gls_calendar$
	if cvs(gls_calendar.year$,2)<>"" then
		enddate$=date(julian-1:"%Yl%Mz%Dz")
		if enddate$(5)<>field(gls_calendar$,"PER_ENDING_"+gls_calendar.total_pers$) then
			msg_id$="GL_BAD_START_DATE"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

rem --- CAL_START_DATE must be <= first trns_date in glt_transdetail (glt-06) for this fiscal year
	cal_start_date$=callpoint!.getUserInput()
	gosub check_cal_start_date
	if abort then break
[[GLS_CALENDAR.YEAR.AVAL]]
rem --- Unless it's the current fiscal year, a new year must have an existing prior year, or next year.
	gls_calendar_dev=fnget_dev("GLS_CALENDAR")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
	dim gls_params$:fnget_tpl$("GLS_PARAMS")
	gls_params$=callpoint!.getDevObject("gls_params")

	year$=callpoint!.getUserInput()
	if year$<>gls_params.current_year$ then
		prior_year$=str(num(year$)-1)
		readrecord(gls_calendar_dev,key=firm_id$+prior_year$,dom=*next)gls_calendar$
		if cvs(gls_calendar.year$,2)="" then
			next_year$=str(num(year$)+1)
			readrecord(gls_calendar_dev,key=firm_id$+next_year$,dom=*next)gls_calendar$
			if cvs(gls_calendar.year$,2)="" then
				msg_id$="GL_CALENDAR_MISSING"
				gosub disp_message
				callpoint!.setStatus("ABORT")
				break
			endif

			rem --- Is this a new record?
			newRecord=1
			readrecord(gls_calendar_dev,key=firm_id$+year$,dom=*next); newRecord=0
			if newRecord then
				msg_id$="GL_COPY_CALENDAR"
				gosub disp_message
				if msg_opt$="Y" then
					rem --- Copy calendar from current fiscal year.
					gosub copy_fiscal_calendar
				else
					rem --- Do NOT copy calendar from current fiscal year.
					callpoint!.setColumnData("GLS_CALENDAR.CAL_START_DATE","",1)
					callpoint!.setColumnEnabled("GLS_CALENDAR.CAL_START_DATE",1)
				endif
			endif
		else
			rem --- Is this a new record?
			newRecord=1
			readrecord(gls_calendar_dev,key=firm_id$+year$,dom=*next); newRecord=0
			if newRecord then
				msg_id$="GL_COPY_CALENDAR"
				gosub disp_message
				if msg_opt$="Y" then
					rem --- Copy calendar from current fiscal year.
					gosub copy_fiscal_calendar
				else
					rem --- Do NOT copy calendar from current fiscal year.
					rem --- Initialize CAL_START_DATE to the day after the ending period of the prior year.
					calendar_year=num(year$)-1
					begdate$=field(gls_calendar$,"PER_ENDING_"+gls_calendar.total_pers$)
					if begdate$<gls_calendar.per_ending_01$ then calendar_year=calendar_year+1
					rem --- Adjust last day of February for leap year
					if begdate$(1,2)="02" then
						Calendar! = new java.util.GregorianCalendar()
						if begdate$(3,2)="29" and !Calendar!.isLeapYear(calendar_year) then begdate$(3,2)="28"
						if begdate$(3,2)="28" and Calendar!.isLeapYear(calendar_year) then begdate$(3,2)="29"
					endif
					julian=jul(calendar_year,num(begdate$(1,2)),num(begdate$(3,2)))+1
					begdate$=date(julian:"%Yl%Mz%Dz")
					callpoint!.setColumnData("GLS_CALENDAR.CAL_START_DATE",begdate$(5),1)
					callpoint!.setColumnEnabled("GLS_CALENDAR.CAL_START_DATE",0)
				endif
			endif
		endif
	endif

rem --- Get the earliest and latest trns_date in GLT_TRANSDETAIL (glt-06) for each period in "this" fiscal year.
	year$=callpoint!.getUserInput()
	gosub get_transdetail_period_dates
[[GLS_CALENDAR.TOTAL_PERS.AVAL]]
rem --- Disable and clear un-used periods
	total_pers=num(callpoint!.getUserInput())
	gosub disable_periods

rem --- TOTAL_PERS must be >= last period in glt_transdetail (glt-06) for this fiscal year
	total_pers=num(callpoint!.getUserInput())
	gosub check_total_pers
	if abort then break
[[GLS_CALENDAR.ADIS]]
rem --- Show current fiscal year and period
	gosub show_current_fiscal_yr

rem --- Disable and clear un-used periods
	total_pers=num(callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS"))
	gosub disable_periods

rem --- Get the earliest and latest trns_date in GLT_TRANSDETAIL (glt-06) for each period in "this" fiscal year.
	year$=callpoint!.getColumnData("GLS_CALENDAR.YEAR")
	gosub get_transdetail_period_dates
[[GLS_CALENDAR.AREC]]
rem --- Show current fiscal year and period
	gosub show_current_fiscal_yr

rem --- Disable and clear un-used periods
	total_pers=num(callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS"))
	gosub disable_periods

rem --- On launch initialize form with calendar for current fiscal year
	if num(callpoint!.getDevObject("justLaunched")) then
		callpoint!.setDevObject("justLaunched","0")
		gls_calendar_dev=fnget_dev("GLS_CALENDAR")
		dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")

		dim gls_params$:fnget_tpl$("GLS_PARAMS")
		gls_params$=callpoint!.getDevObject("gls_params")
		readrecord(gls_calendar_dev,key=firm_id$+gls_params.current_year$,dom=*next)gls_calendar$
		if cvs(gls_calendar.year$,2)<>"" then
			callpoint!.setStatus("NEWRECORD:["+firm_id$+gls_calendar.year$+"]")
		else
			rem --- Default to a calendar year for the very first calendar entered, which is for the current fiscal year.
			callpoint!.setColumnData("GLS_CALENDAR.YEAR",gls_params.current_year$)
			callpoint!.setColumnData("GLS_CALENDAR.CAL_START_DATE","0101")
			callpoint!.setColumnData("GLS_CALENDAR.TOTAL_PERS","12")
			callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_01","0131")
			Calendar! = new java.util.GregorianCalendar()
			if Calendar!.isLeapYear(num(gls_params.current_year$)) then
				callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_02","0229")
			else
				callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_02","0228")
			endif
			callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_03","0331")
			callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_04","0430")
			callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_05","0531")
			callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_06","0630")
			callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_07","0731")
			callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_08","0831")
			callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_09","0930")
			callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_10","1031")
			callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_11","1130")
			callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_12","1231")
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_01",Translate!.getTranslation("AON_JANUARY"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_02",Translate!.getTranslation("AON_FEBRUARY"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_03",Translate!.getTranslation("AON_MARCH"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_04",Translate!.getTranslation("AON_APRIL"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_05",Translate!.getTranslation("AON_MAY"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_06",Translate!.getTranslation("AON_JUNE"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_07",Translate!.getTranslation("AON_JULY"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_08",Translate!.getTranslation("AON_AUGUST"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_09",Translate!.getTranslation("AON_SEPTEMBER"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_10",Translate!.getTranslation("AON_OCTOBER"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_11",Translate!.getTranslation("AON_NOVEMBER"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_12",Translate!.getTranslation("AON_DECEMBER"))
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_01","Jan")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_02","Feb")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_03","Mar")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_04","Apr")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_05","May")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_06","Jun")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_07","Jul")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_08","Aug")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_09","Sep")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_10","Oct")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_11","Nov")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_12","Dec")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_01","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_02","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_03","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_04","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_05","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_06","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_07","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_08","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_09","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_10","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_11","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_12","N")

			total_pers=12
			gosub disable_periods
			callpoint!.setStatus("REFRESH-MODIFIED")
		endif
	endif
[[GLS_CALENDAR.<CUSTOM>]]
#include std_missing_params.src

show_current_fiscal_yr: rem --- Show current fiscal year and period
	dim gls_params$:fnget_tpl$("GLS_PARAMS")
	gls_params$=callpoint!.getDevObject("gls_params")
	callpoint!.setColumnData("<<DISPLAY>>.CURRENT_YEAR",gls_params.current_year$,1)
	callpoint!.setColumnData("<<DISPLAY>>.CURRENT_PER",gls_params.current_per$,1)
	callpoint!.setColumnData("<<DISPLAY>>.GL_YR_CLOSED",gls_params.gl_yr_closed$,1)
	callpoint!.setColumnData("<<DISPLAY>>.ADJUST_FEBRUARY",str(gls_params.adjust_february),1)
	callpoint!.setColumnData("<<DISPLAY>>.CREATE_NEXT_CAL",str(gls_params.create_next_cal),1)
return

disable_periods: rem --- Disable and clear periods based on total number of fiscal periods
                            rem --- Input: total_pers = total number of periods in this fiscal year
	for per=1 to 13
		able=iff(per<=total_pers,1,0)
		callpoint!.setColumnEnabled("GLS_CALENDAR.PER_ENDING_"+str(per:"00"),able)
		callpoint!.setColumnEnabled("GLS_CALENDAR.PERIOD_NAME_"+str(per:"00"),able)
		callpoint!.setColumnEnabled("GLS_CALENDAR.ABBR_NAME_"+str(per:"00"),able)
		callpoint!.setColumnEnabled("GLS_CALENDAR.LOCKED_FLAG_"+str(per:"00"),able)
		callpoint!.setColumnEnabled("GLS_CALENDAR.LOCKED_DATE_"+str(per:"00"),able)
		if !able then
			callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_"+str(per:"00"),"")
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_"+str(per:"00"),"")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_"+str(per:"00"),"")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_"+str(per:"00"),"")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_DATE_"+str(per:"00"),"")
		endif
	next per
	callpoint!.setStatus("REFRESH")
return

validate_cal_end: rem --- The ending day of the last period must be the day before the start of
                              rem --- the next year when a fiscal calendar exists for the next year.
                              rem --- Input: per_ending$ = mmdd period ending date
                              rem --- Output: abort = 1 (true) or 0 (false) for callpoint!.setStatus("ABORT")
	gls_calendar_dev=fnget_dev("GLS_CALENDAR")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
	abort=0

	next_year$=str(num(callpoint!.getColumnData("GLS_CALENDAR.YEAR"))+1)
	readrecord(gls_calendar_dev,key=firm_id$+next_year$,dom=*next)gls_calendar$
	if cvs(gls_calendar.year$,2)<>"" then
		start_date$=callpoint!.getColumnData("GLS_CALENDAR.CAL_START_DATE")
		julian=jul(num(next_year$),num(start_date$(1,2)),num(start_date$(3,2)))
		enddate$=date(julian-1:"%Yl%Mz%Dz")
		if per_ending$<>enddate$(5) then
			msg_id$="GL_BAD_END_DATE"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			abort=1
		endif
	endif
return

leap_year_adjustment: rem --- Adjust last day of February for leap year
                              rem --- Input: per_ending$ = mmdd period ending date
                              rem --- Output: mmdd$ = adjusted date
	mmdd$=per_ending$
	dim gls_params$:fnget_tpl$("GLS_PARAMS")
	gls_params$=callpoint!.getDevObject("gls_params")
	if (gls_params.adjust_february and per_ending$="0228") or per_ending$="0229" then
		calendar_year=num(callpoint!.getColumnData("GLS_CALENDAR.YEAR"))
		if per_ending$<callpoint!.getColumnData("GLS_CALENDAR.CAL_START_DATE") then calendar_year=calendar_year+1
		Calendar! = new java.util.GregorianCalendar()
		if per_ending$="0229" and !Calendar!.isLeapYear(calendar_year) then mmdd$="0228"
		if per_ending$="0228" and Calendar!.isLeapYear(calendar_year) then mmdd$="0229"
	endif
return

copy_fiscal_calendar: rem --- Copy calendar from current fiscal year
	current_fiscal_yr$=gls_params.current_year$
	readrecord(gls_calendar_dev,key=firm_id$+current_fiscal_yr$,dom=*endif)gls_calendar$
	cal_start_date$=gls_calendar.cal_start_date$
	callpoint!.setColumnData("GLS_CALENDAR.CAL_START_DATE",cal_start_date$)
	total_pers$=gls_calendar.total_pers$
	callpoint!.setColumnData("GLS_CALENDAR.TOTAL_PERS",total_pers$)
	for per=1 to num(total_pers$)
		per_ending$=field(gls_calendar$,"PER_ENDING_"+str(per:"00"))
		if (gls_params.adjust_february and per_ending$="0228") or per_ending$="0229" then
			rem --- Adjust last day of February for leap year
			calendar_year=num(year$)
			if per_ending$<cal_start_date$ then calendar_year=calendar_year+1
			Calendar! = new java.util.GregorianCalendar()
			if per_ending$="0229" and !Calendar!.isLeapYear(calendar_year) then per_ending$="0228"
			if per_ending$="0228" and Calendar!.isLeapYear(calendar_year) then per_ending$="0229"
		endif
		callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_"+str(per:"00"),per_ending$)
		period_name$=field(gls_calendar$,"PERIOD_NAME_"+str(per:"00"))
		callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_"+str(per:"00"),period_name$)
		abbr_name$=field(gls_calendar$,"ABBR_NAME_"+str(per:"00"))
		callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_"+str(per:"00"),abbr_name$)
		if year$<current_fiscal_yr$ then
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_"+str(per:"00"),"Y")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_DATE_"+str(per:"00"),date(0:"%Yd%Mz%Dz"))
		else
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_"+str(per:"00"),"N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_DATE_"+str(per:"00"),"")
		endif
	next per

	total_pers=num(total_pers$)
	gosub disable_periods
	callpoint!.setStatus("REFRESH-MODIFIED")
return

get_transdetail_period_dates: rem --- Get the earliest and latest trns_date in GLT_TRANSDETAIL (glt-06) for each period in given fiscal year.
                                                   rem --- Input: year$ = fiscal year of interest
	glt_transdetail_dev=fnget_dev("GLT_TRANSDETAIL")
	dim glt_transdetail$:fnget_tpl$("GLT_TRANSDETAIL")

	rem --- Get the earliest trns_date for each period
	earliestTransDate!=new java.util.HashMap()
	for per=1 to 13
		period$=str(per:"00")
		read(glt_transdetail_dev,key=firm_id$+year$+period$,knum="BY_YEAR_PERIOD",dom=*next)
		redim glt_transdetail$
		readrecord(glt_transdetail_dev,end=*next)glt_transdetail$
		if firm_id$+year$+period$=glt_transdetail.firm_id$+glt_transdetail.posting_year$+glt_transdetail.posting_per$ then
			earliestTransDate!.put(period$,glt_transdetail.trns_date$)
		else
			earliestTransDate!.put(period$,"")
		endif
	next per

	rem --- Get the latest trns_date for each period
	latestTransDate!=new java.util.HashMap()
	for per=1 to 13
		period$=str(per:"00")
		read(glt_transdetail_dev,key=firm_id$+year$+period$+$FF$,knum="BY_YEAR_PERIOD",dom=*next)
		readrecord(glt_transdetail_dev,dir=-1,end=*next)
		redim glt_transdetail$
		readrecord(glt_transdetail_dev,end=*next)glt_transdetail$
		if firm_id$+year$+period$=glt_transdetail.firm_id$+glt_transdetail.posting_year$+glt_transdetail.posting_per$ then
			latestTransDate!.put(period$,glt_transdetail.trns_date$)
		else
			latestTransDate!.put(period$,"")
		endif
	next per

	callpoint!.setDevObject("earliestTransDate",earliestTransDate!)
	callpoint!.setDevObject("latestTransDate",latestTransDate!)
return

check_total_pers: rem --- TOTAL_PERS must be >= last period in glt_transdetail (glt-06) for this fiscal year
                                                       rem --- Input: total_per = total number of periods in the fiscal year
                                                       rem --- Output: abort = 1 (true) or 0 (false) for callpoint!.setStatus("ABORT")
	latestTransDate!=callpoint!.getDevObject("latestTransDate")
	last_period=-1
	for per=13 to 1 step -1
		if latestTransDate!.get(str(per:"00"))<>"" then
			last_period=per
			break
		endif
	next per
	if total_pers<last_period then
		msg_id$="GL_BAD_TOTAL_PERS"
		dim msg_tokens$[2]
		msg_tokens$[1]=str(last_period)
		msg_tokens$[2]=str(last_period)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif
return


check_cal_start_date: rem --- CAL_START_DATE must be <= first trns_date in glt_transdetail (glt-06) for this fiscal year
                                                       rem --- Input: cal_start_date$ = the calendar start date to be checked
                                                       rem --- Output: abort = 1 (true) or 0 (false) for callpoint!.setStatus("ABORT")
	earliestTransDate!=callpoint!.getDevObject("earliestTransDate")
	first_mmdd$="9999"
	for per=1 to 13
		trans_date$=earliestTransDate!.get(str(per:"00"))
		if trans_date$<>"" then
			first_mmdd$=trans_date$(5)
			break
		endif
	next per
	if cal_start_date$>first_mmdd$ then
		msg_id$="GL_BAD_CAL_START"
		dim msg_tokens$[2]
		msg_tokens$[1]=first_mmdd$(1,2)+"/"+first_mmdd$(3)
		msg_tokens$[2]=first_mmdd$(1,2)+"/"+first_mmdd$(3)
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
return

check_transdetail_period_dates: rem --- Check PER_ENDING date against GLT_TRANSDETAIL (glt-06) period dates
                                                       rem --- Input: period$ = period the per_ending$ date is for
                                                       rem --- Input: per_ending$ = mmdd period ending date
                                                       rem --- Output: abort = 1 (true) or 0 (false) for callpoint!.setStatus("ABORT")

	rem --- Period cannot end before this date
	abort=0
	latestTransDate!=callpoint!.getDevObject("latestTransDate")
	before_date$=latestTransDate!.get(period$)
	if before_date$<>"" and per_ending$<before_date$(5) then
		msg_id$="GL_PER_END_BEFORE"
		dim msg_tokens$[4]
		msg_tokens$[1]=before_date$(5,2)+"/"+before_date$(7)
		msg_tokens$[2]=period$
		msg_tokens$[3]=period$
		msg_tokens$[4]=before_date$(5,2)+"/"+before_date$(7)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		abort=1
	endif

	rem --- Period cannot end on or after this date
	next_period$=str(num(period$)+1:"00")
	if !abort and next_period$<="13" then
		earliestTransDate!=callpoint!.getDevObject("earliestTransDate")
		after_date$=earliestTransDate!.get(next_period$)
		if after_date$<>"" and per_ending$>=after_date$(5) then
			msg_id$="GL_PER_END_AFTER"
			dim msg_tokens$[4]
			msg_tokens$[1]=after_date$(5,2)+"/"+after_date$(7)
			msg_tokens$[2]=next_period$
			msg_tokens$[3]=period$
			msg_tokens$[4]=after_date$(5,2)+"/"+after_date$(7)
			gosub disp_message
			callpoint!.setStatus("ABORT")
			abort=1
		endif
	endif
return

rem --- validate period ending date
validate_mo_day: rem --- validate period ending date (month/day - doesn't check for Feb 28 vs 29)
                              rem --- Input: per_ending$ = mmdd period ending date
                              rem --- Output: abort = 1 (true) or 0 (false) for callpoint!.setStatus("ABORT")
	abort=1
	switch num(per_ending$(1,2))
		case 1
		case 3
		case 5
		case 7
		case 8
		case 10
		case 12
			if num(per_ending$(3,2))>=1 and num(per_ending$(3,2))<=31 then abort=0	
			break
		case 2
			if num(per_ending$(3,2))>=1 and num(per_ending$(3,2))<=29 then abort=0
			break
		case 4
		case 6
		case 9
		case 11
			if num(per_ending$(3,2))>=1 and num(per_ending$(3,2))<=30 then abort=0
			break
		case default
			break
	swend

	if abort then
		msg_id$="GL_INVAL_PER"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
return

validate_us_requirements: rem --- Check United States (US) specific requirements for fiscal calendars

	rem --- Per US Tax Code, fiscal calendar must include at least a minimum of 359 days ( 13 periods * 4 weeks – less 5 days),
        rem --- but not more than a maximum of 371 days (53 weeks * 7 days).
	fiscal_year=num(callpoint!.getColumnData("GLS_CALENDAR.YEAR"))
	cal_start_date$=callpoint!.getColumnData("GLS_CALENDAR.CAL_START_DATE")
	start_julian=jul(fiscal_year,num(cal_start_date$(1,2)),num(cal_start_date$(3,2)))
	minimum_julian=start_julian+359
	maximum_julian=start_julian+371
	total_pers$=callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")
	ending_mmdd$=callpoint!.getColumnData("GLS_CALENDAR.PER_ENDING_"+total_pers$)

	rem --- 359 days may span zero or one year end. 371 days may span one or two year ends.
	bad_calendar=1
	for span=0 to 2
		end_julian=jul(fiscal_year+span,num(ending_mmdd$(1,2)),num(ending_mmdd$(3,2)))
		if end_julian>=minimum_julian and end_julian<=maximum_julian then
			bad_calendar=0
			break
		endif
	next span

	if bad_calendar then
		msg_id$="GL_US_CAL_REQ_1"
		gosub disp_message
	endif
return
