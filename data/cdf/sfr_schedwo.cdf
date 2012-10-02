[[SFR_SCHEDWO.SCHED_FLAG.AVAL]]
rem --- Set default Start and Completion Date for Manual

	if cvs(callpoint!.getColumnData("SFR_SCHEDWO.SCHED_FLAG"),2)<>"M" and
:		callpoint!.getUserInput()="M"
		ivm_itemwhse=fnget_dev("IVM_ITEMWHSE")
		dim ivm_itemwhse$:fnget_tpl$("IVM_ITEMWHSE")
		read record (ivm_itemwhse,key=firm_id$+callpoint!.getDevObject("default_wh")+
:			callpoint!.getDevObject("item_id"),dom=*next)ivm_itemwhse$
		new_date$=""
		leadtime=ivm_itemwhse.lead_time
		call stbl("+DIR_PGM")+"adc_daydates.aon",stbl("+SYSTEM_DATE"),new_date$,leadtime
		if new_date$<>"N"
			callpoint!.setColumnData("SFR_SCHEDWO.ESTSTT_DATE",stbl("+SYSTEM_DATE"),1)
			callpoint!.setColumnData("SFR_SCHEDWO.ESTCMP_DATE",new_date$,1)
		endif
	endif
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
