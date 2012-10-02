[[SFR_SCHEDWO.BSHO]]
rem --- set default DevObjects

	callpoint!.setDevObject("start_date","")
	callpoint!.setDevObject("comp_date","")
	callpoint!.setDevObject("sched_method","")
[[SFR_SCHEDWO.ASVA]]
rem --- Calculate dates

	gosub calc_dates

	callpoint!.setDevObject("start_date",callpoint!.getColumnData("SFR_SCHEDWO.ESTSTT_DATE"))
	callpoint!.setDevObject("comp_date",callpoint!.getColumnData("SFR_SCHEDWO.ESTCMP_DATE"))
	callpoint!.setDevObject("sched_method",callpoint!.getColumnData("SFR_SCHEDWO.SCHED_FLAG"))
[[SFR_SCHEDWO.<CUSTOM>]]
rem --- Calculate Estimated Start/Completion Date"
rem ========================================================
calc_dates:
rem ========================================================

	status$="00"
	sched_flag$=callpoint!.getColumnData("SFR_SCHEDWO.SCHED_FLAG")
	wo_no$=callpoint!.getDevObject("wo_no")
	start_date$=callpoint!.getColumnData("SFR_SCHEDWO.ESTSTT_DATE")
	end_date$=callpoint!.getColumnData("SFR_SCHEDWO.ESTCMP_DATE")

	if sched_flag$<>"M"
		if sched_flag$="F"
			f_date$=start_date$
		else
			f_date$=end_date$
		endif
		opcode_dev=callpoint!.getDevObject("opcode_chan")
		opcode_tpl$=callpoint!.getDevObject("opcode_tpl")
		call "sfc_schdayfore.aon",wo_no$,f_date$,new_date$,sched_flag$,opcode_dev,status$,opcode_tpl$

		if status$(1,1)="1"
			msg_id$="SF_SUB_CHANGED"
			gosub disp_message
		endif
		if status$(2,1)<>"0"
			if status$(2,1)="1"
				msg_id$="SF_UNSCHED_DATE"
				gosub disp_message
			endif
			if status$(2,1)="3"
				msg_id$="SF_MISSING_FILE"
				gosub disp_message
			endif
			if status$(2,1)="5"
				msg_id$="SF_UNSCHED_DATE_SUB"
				gosub disp_message
			endif
		endif
		if sched_flag$="F"
			callpoint!.setColumnData("SFR_SCHEDWO.ESTCMP_DATE",new_date$,1)
		else
			callpoint!.setColumnData("SFR_SCHEDWO.ESTSTT_DATE",new_date$,1)
		endif
	endif

	return
[[SFR_SCHEDWO.ESTSTT_DATE.AVAL]]
rem --- Estimated Start Date

	start_date$=callpoint!.getUserInput()
	if pos(" "<>callpoint!.getDevObject("order_no"))=0
		call "adc_daydates.aon",start_date$,ret_date$,leadtime
		if ret_date$<>"N" callpoint!.setColumnData("SFR_SCHEDWO.ESTCMP_DATE",ret_date$,1)
	endif
