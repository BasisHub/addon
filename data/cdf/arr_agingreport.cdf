[[ARR_AGINGREPORT.AGEDATE_FUT_FROM.AVAL]]
tmp_cur_from$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_CUR_FROM")
tmp_30_from$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_30_FROM")
tmp_60_from$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_60_FROM")
tmp_90_from$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_90_FROM")

gosub calc_dates1
[[ARR_AGINGREPORT.AGEDATE_CUR_FROM.AVAL]]
tmp_cur_from$=callpoint!.getUserInput()
tmp_30_from$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_30_FROM")
tmp_60_from$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_60_FROM")
tmp_90_from$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_90_FROM")

gosub calc_dates1
[[ARR_AGINGREPORT.AGEDATE_90_FROM.AVAL]]
tmp_cur_from$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_CUR_FROM")
tmp_30_from$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_30_FROM")
tmp_60_from$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_60_FROM")
tmp_90_from$=callpoint!.getUserInput()

gosub calc_dates4
[[ARR_AGINGREPORT.AGEDATE_60_FROM.AVAL]]
tmp_cur_from$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_CUR_FROM")
tmp_30_from$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_30_FROM")
tmp_60_from$=callpoint!.getUserInput()
tmp_90_from$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_90_FROM")

gosub calc_dates3
[[ARR_AGINGREPORT.AGEDATE_30_FROM.AVAL]]
tmp_cur_from$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_CUR_FROM")
tmp_30_from$=callpoint!.getUserInput()
tmp_60_from$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_60_FROM")
tmp_90_from$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_90_FROM")

gosub calc_dates2
[[ARR_AGINGREPORT.REPORT_SEQUENCE.AVAL]]
tmp_rpt_opt$=callpoint!.getColumnData("ARR_AGINGREPORT.REPORT_OPTION")
tmp_rpt_seq$=callpoint!.getUserInput()
gosub set_selections
[[ARR_AGINGREPORT.REPORT_OPTION.AVAL]]
tmp_rpt_opt$=callpoint!.getUserInput()
tmp_rpt_seq$=callpoint!.getColumnData("ARR_AGINGREPORT.REPORT_SEQUENCE")
gosub set_selections
[[ARR_AGINGREPORT.UPDATE_AGING.AVAL]]
if callpoint!.getColumnData("ARR_AGINGREPORT.FIXED_PERIODS")="N"
	if callpoint!.getUserInput()="Y"
		callpoint!.setMessage("FIXED_PERIODS")
		callpoint!.setUserInput("N")
		callpoint!.setStatus("REFRESH")
	endif
endif
[[ARR_AGINGREPORT.FIXED_PERIODS.AVAL]]
rem --- Recalc dates if fixed periods
if callpoint!.getUserInput()="Y"
	fixed_periods$=callpoint!.getUserInput()
	days_in_per=num(callpoint!.getColumnData("ARR_AGINGREPORT.DAYS_IN_PER"))
	start_date$=callpoint!.getColumnData("ARR_AGINGREPORT.REPORT_DATE")
	gosub calc_dates_fixed
	callpoint!.setStatus("REFRESH")
else
	if callpoint!.getColumnData("ARR_AGINGREPORT.UPDATE_AGING")="Y"
		callpoint!.setMessage("FIXED_PERIODS")
		callpoint!.setUserInput("Y")
		callpoint!.setStatus("REFRESH")
	endif
endif
[[ARR_AGINGREPORT.AREC]]
tmp_rpt_opt$=callpoint!.getColumnData("ARR_AGINGREPORT.REPORT_OPTION")
tmp_rpt_seq$=callpoint!.getColumnData("ARR_AGINGREPORT.REPORT_SEQUENCE")
gosub set_selections
fixed_periods$=callpoint!.getColumnData("ARR_AGINGREPORT.FIXED_PERIODS")
days_in_per=num(callpoint!.getColumnData("ARR_AGINGREPORT.DAYS_IN_PER"))
start_date$=callpoint!.getColumnData("ARR_AGINGREPORT.REPORT_DATE")
gosub calc_dates_fixed
[[ARR_AGINGREPORT.DAYS_IN_PER.AVAL]]
fixed_periods$=callpoint!.getColumnData("ARR_AGINGREPORT.FIXED_PERIODS")
days_in_per=num(callpoint!.getUserInput())
start_date$=callpoint!.getColumnData("ARR_AGINGREPORT.REPORT_DATE")
gosub calc_dates_fixed
callpoint!.setStatus("REFRESH")
[[ARR_AGINGREPORT.REPORT_DATE.AVAL]]
fixed_periods$=callpoint!.getColumnData("ARR_AGINGREPORT.FIXED_PERIODS")
days_in_per=num(callpoint!.getColumnData("ARR_AGINGREPORT.DAYS_IN_PER"))
start_date$=callpoint!.getUserInput()
if callpoint!.getColumnData("ARR_AGINGREPORT.FIXED_PERIODS")="Y"
	gosub calc_dates_fixed
endif
callpoint!.setStatus("REFRESH")
[[ARR_AGINGREPORT.<CUSTOM>]]
calc_dates_fixed:rem --- Calculate Aging Dates
rem --- fixed_periods$,days_in_per,start_date$ being set prior to gosub
	if days_in_per=0 days_in_per=30
	new_start$=""
	call stbl("+DIR_PGM")+"adc_daydates.aon",start_date$,new_start$,1
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_FUT_FROM",new_start$)
	prev_date$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_FUT_FROM")
	new_date$=date(jul(prev_date$,"%Yd%Mz%Dz")-1:"%Yd%Mz%Dz")
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_CUR_THRU",new_date$)
	prev_date$=new_date$
	new_date$=date(jul(prev_date$,"%Yd%Mz%Dz")-(days_in_per-1):"%Yd%Mz%Dz")
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_CUR_FROM",new_date$)
	prev_date$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_CUR_FROM")
	new_date$=date(jul(prev_date$,"%Yd%Mz%Dz")-1:"%Yd%Mz%Dz")
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_30_THRU",new_date$)
	prev_date$=new_date$
	new_date$=date(jul(prev_date$,"%Yd%Mz%Dz")-(days_in_per-1):"%Yd%Mz%Dz")
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_30_FROM",new_date$)
	prev_date$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_30_FROM")
	new_date$=date(jul(prev_date$,"%Yd%Mz%Dz")-1:"%Yd%Mz%Dz")
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_60_THRU",new_date$)
	prev_date$=new_date$
	new_date$=date(jul(prev_date$,"%Yd%Mz%Dz")-(days_in_per-1):"%Yd%Mz%Dz")
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_60_FROM",new_date$)
	prev_date$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_60_FROM")
	new_date$=date(jul(prev_date$,"%Yd%Mz%Dz")-1:"%Yd%Mz%Dz")
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_90_THRU",new_date$)
	prev_date$=new_date$
	new_date$=date(jul(prev_date$,"%Yd%Mz%Dz")-(days_in_per-1):"%Yd%Mz%Dz")
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_90_FROM",new_date$)
	prev_date$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_90_FROM")
	new_date$=date(jul(prev_date$,"%Yd%Mz%Dz")-1:"%Yd%Mz%Dz")
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_120_THRU",new_date$)
return
calc_dates1:
	rem --- tmp_cur_from$ set prior to gosub
	days_in_per=num(callpoint!.getColumnData("ARR_AGINGREPORT.DAYS_IN_PER"))
	if days_in_per=0 days_in_per=30
	err_stat$="N"
	last_date$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_CUR_THRU")
	prev_date$=tmp_cur_from$
	gosub check_dates
	if err_stat$="Y" goto date_abend
	new_date$=date(jul(prev_date$,"%Yd%Mz%Dz")-1:"%Yd%Mz%Dz")
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_30_THRU",new_date$)
	prev_date$=date(jul(new_date$,"%Yd%Mz%Dz")-days_in_per+1:"%Yd%Mz%Dz")
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_30_FROM",prev_date$)
calc_dates2:
	rem --- tmp_30_from$ set prior to gosub
	days_in_per=num(callpoint!.getColumnData("ARR_AGINGREPORT.DAYS_IN_PER"))
	if days_in_per=0 days_in_per=30
	last_date$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_30_THRU")
	prev_date$=tmp_30_from$
	gosub check_dates
	if err_stat$="Y" goto date_abend
	new_date$=date(jul(prev_date$,"%Yd%Mz%Dz")-1:"%Yd%Mz%Dz")
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_60_THRU",new_date$)
	prev_date$=date(jul(new_date$,"%Yd%Mz%Dz")-days_in_per+1:"%Yd%Mz%Dz")
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_60_FROM",prev_date$)
calc_dates3:
	rem --- tmp_60_from$ set prior to gosub
	days_in_per=num(callpoint!.getColumnData("ARR_AGINGREPORT.DAYS_IN_PER"))
	if days_in_per=0 days_in_per=30
	last_date$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_60_THRU")
	prev_date$=tmp_60_from$
	gosub check_dates
	if err_stat$="Y" goto date_abend
	new_date$=date(jul(prev_date$,"%Yd%Mz%Dz")-1:"%Yd%Mz%Dz")
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_90_THRU",new_date$)
	prev_date$=date(jul(new_date$,"%Yd%Mz%Dz")-days_in_per+1:"%Yd%Mz%Dz")
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_90_FROM",prev_date$)
calc_dates4:
	rem --- tmp_90_from$ set prior to gosub
	days_in_per=num(callpoint!.getColumnData("ARR_AGINGREPORT.DAYS_IN_PER"))
	if days_in_per=0 days_in_per=30
	last_date$=callpoint!.getColumnData("ARR_AGINGREPORT.AGEDATE_90_THRU")
	prev_date$=tmp_90_from$
	gosub check_dates
	if err_stat$="Y" goto date_abend
	new_date$=date(jul(prev_date$,"%Yd%Mz%Dz")-1:"%Yd%Mz%Dz")
	callpoint!.setColumnData("ARR_AGINGREPORT.AGEDATE_120_THRU",new_date$)
	callpoint!.setStatus("REFRESH")
date_abend:
	if err_stat$="Y"
		callpoint!.setStatus("ABORT-REFRESH")
	endif
return
check_dates: rem Check validity of entered FROM dates against THRU dates
	if prev_date$>last_date$
		err_stat$="Y"
		out1$=date(jul(prev_date$,"%Yd%Mz%Dz"):"%Mz/%Dz/%Yd")
		out2$=date(jul(last_date$,"%Yd%Mz%Dz"):"%Mz/%Dz/%Yd")
		msg_id$="ENTRY_FROM_TO"
		dim msg_tokens$[2]
		msg_tokens$[1]=out1$
		msg_tokens$[2]=out2$
		gosub disp_message
	endif
return
set_selections: rem --- Enable/Disable Selection columns based on entries
rem --- tmp_rpt_opt$,tmp_rpt_seq$ set prior to gosub
dim ctl_name$[6]
dim ctl_stat$[6]
ctl_name$[1]="ARR_AGINGREPORT.CUSTOMER_ID_1"
ctl_name$[2]="ARR_AGINGREPORT.CUSTOMER_ID_2"
ctl_name$[3]="ARR_AGINGREPORT.ALT_SEQUENCE_1"
ctl_name$[4]="ARR_AGINGREPORT.ALT_SEQUENCE_2"
ctl_name$[5]="ARR_AGINGREPORT.SALESPERSON_1"
ctl_name$[6]="ARR_AGINGREPORT.SALESPERSON_2"
if tmp_rpt_opt$<> "C"
	ctl_stat$[1]="D"
	ctl_stat$[2]="D"
	ctl_stat$[3]="D"
	ctl_stat$[4]="D"
	ctl_stat$[5]=" "
	ctl_stat$[6]=" "
	callpoint!.setColumnData("ARR_AGINGREPORT.CUSTOMER_ID_1","")
	callpoint!.setColumnData("ARR_AGINGREPORT.CUSTOMER_ID_2","")
	callpoint!.setColumnData("ARR_AGINGREPORT.ALT_SEQUENCE_1","")
	callpoint!.setColumnData("ARR_AGINGREPORT.ALT_SEQUENCE_2","")
else
	ctl_stat$[5]="D"
	ctl_stat$[6]="D"
	callpoint!.setColumnData("ARR_AGINGREPORT.SALESPERSON_1","")
	callpoint!.setColumnData("ARR_AGINGREPORT.SALESPERSON_2","")
	if tmp_rpt_seq$="A"
		ctl_stat$[1]="D"
		ctl_stat$[2]="D"
		ctl_stat$[3]=" "
		ctl_stat$[4]=" "
		callpoint!.setColumnData("ARR_AGINGREPORT.CUSTOMER_ID_1","")
		callpoint!.setColumnData("ARR_AGINGREPORT.CUSTOMER_ID_2","")
	else
		ctl_stat$[1]=" "
		ctl_stat$[2]=" "
		ctl_stat$[3]="D"
		ctl_stat$[4]="D"
		callpoint!.setColumnData("ARR_AGINGREPORT.ALT_SEQUENCE_1","")
		callpoint!.setColumnData("ARR_AGINGREPORT.ALT_SEQUENCE_2","")
	endif
endif
gosub disable_fields
return
disable_fields:
rem --- used to disable/enable controls depending on parameter settings
rem --- send in control to toggle (format "ALIAS.CONTROL_NAME"), and D or space to disable/enable
	for x=1 to 6
		wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$[x],"CTLI")):"00000")
		wmap$=callpoint!.getAbleMap()
		wpos=pos(wctl$=wmap$,8)
		wmap$(wpos+6,1)=ctl_stat$[x]
		callpoint!.setAbleMap(wmap$)
		callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")
	next x 
return
