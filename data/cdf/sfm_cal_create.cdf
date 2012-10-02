[[SFM_CAL_CREATE.BFMC]]
rem --- See if BOM is being used

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFS_PARAMS",open_opts$[1]="OTA"
	gosub open_tables

	sfs_params=num(open_chans$[1])
	dim sfs_params$:open_tpls$[1]

	read record(sfs_params,key=firm_id$+"SF00",dom=std_missing_params) sfs_params$

	if sfs_params.bm_interface$<>"Y"
		callpoint!.setTableColumnAttribute("SFM_CAL_CREATE.OP_CODE","DTAB","SFC_OPRTNCOD")
	endif
[[SFM_CAL_CREATE.<CUSTOM>]]
rem ===============================================
write_rec:
rem ===============================================

	wom04a.firm_id$=firm_id$	
	wom04a.op_code$=callpoint!.getColumnData("SFM_CAL_CREATE.OP_CODE")
	wom04a.year$=old_date$(1,4)
	wom04a.month$=old_date$(5,2)
	wom04a.days_in_mth=32
	while 1
		wom04a.days_in_mth=wom04a.days_in_mth-1
		X=jul(num(x9$(1,4)),num(x9$(5,2)),wom04a.days_in_mth,err=*continue)
		break
	wend
	write record (wom04_dev) wom04a$
	for x9=1 to 31
		field wom04a$,"hrs_per_day_"+str(x9:"00")=-1
	next x9
	old_date$=first_date$
	gosub get_rec

	return

rem ===============================================
get_rec:
rem ===============================================

	dim wom04a$:fattr(wom04a$)
	wom04a.firm_id$=firm_id$	
	wom04a.op_code$=callpoint!.getColumnData("SFM_CAL_CREATE.OP_CODE")
	wom04a.year$=first_date$(1,4)
	wom04a.month$=first_date$(5,2)
	for x9=1 to 31
		field wom04a$,"hrs_per_day_"+str(x9:"00")=-1
	next x9
	read record (wom04_dev,key=firm_id$+wom04a.op_code$+wom04a.year$+wom04a.month$,dom=*next) wom04a$

	return

#include std_missing_params.src
[[SFM_CAL_CREATE.ASVA]]
rem  --- Write records

	exclude$=""
	if callpoint!.getColumnData("SFM_CAL_CREATE.SUNDAY")="Y"
		exclude$=exclude$+"Sun"
	endif
	if callpoint!.getColumnData("SFM_CAL_CREATE.MONDAY")="Y"
		exclude$=exclude$+"Mon"
	endif
	if callpoint!.getColumnData("SFM_CAL_CREATE.TUESDAY")="Y"
		exclude$=exclude$+"Tue"
	endif
	if callpoint!.getColumnData("SFM_CAL_CREATE.WEDNESDAY")="Y"
		exclude$=exclude$+"Wed"
	endif
	if callpoint!.getColumnData("SFM_CAL_CREATE.THURSDAY")="Y"
		exclude$=exclude$+"Thu"
	endif
	if callpoint!.getColumnData("SFM_CAL_CREATE.FRIDAY")="Y"
		exclude$=exclude$+"Fri"
	endif
	if callpoint!.getColumnData("SFM_CAL_CREATE.SATURDAY")="Y"
		exclude$=exclude$+"Sat"
	endif

	wom04_dev=fnget_dev("SFM_OPCALNDR")
	dim wom04a$:fnget_tpl$("SFM_OPCALNDR")
	first_date$=callpoint!.getColumnData("SFM_CAL_CREATE.FIRST_SCHED_DT")
	hrs_per_day=num(callpoint!.getColumnData("SFM_CAL_CREATE.HRS"))
	old_date$=first_date$
	gosub get_rec
	num_weeks=num(callpoint!.getColumnData("SFM_CAL_CREATE.NUM_WEEKS"))
	for week_count=1 to num_weeks
		for day_count=1 to 7
			call "adc_dayweek.aon",first_date$,dow$,dow
			if first_date$(1,6)<>old_date$(1,6) gosub write_rec
			if pos(dow$=exclude$,3)>0 
				field wom04a$,"hrs_per_day_"+str(num(first_date$(7,2)):"00")=0
			else
				field wom04a$,"hrs_per_day_"+str(num(first_date$(7,2)):"00")=hrs_per_day
			endif
			x9$=first_date$
			dow$=""
			call "adc_daydates.aon",first_date$,dow$,1
			first_date$=dow$
		next day_count
	next week_count

	gosub write_rec

	msg_id$="UPDATE_COMPLETE"
	gosub disp_message
[[SFM_CAL_CREATE.OP_CODE.AVAL]]
rem --- Calc Last Date Defined for this Op Code

	op_code$=callpoint!.getUserInput()
	last_date$="        "
	sfm_cal=fnget_dev("SFM_OPCALNDR")
	dim sfm_cal$:fnget_tpl$("SFM_OPCALNDR")

	read (sfm_cal,key=firm_id$+op_code$,dom=*next)
	while 1
		read record (sfm_cal,end=*break) sfm_cal$
		if pos(firm_id$+op_code$=sfm_cal$)<>1 break
		for x=sfm_cal.days_in_mth to 1 step -1
			if nfield(sfm_cal$,"hrs_per_day_"+str(x:"00"))>=0 
				x$=str(x:"00")
				break
			endif
		next x
		last_date$=sfm_cal.year$+sfm_cal.month$+x$
	wend

	callpoint!.setColumnData("<<DISPLAY>>.LAST_SCHED_DT",last_date$,1)
[[SFM_CAL_CREATE.BSHO]]
rem --- Open files

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFM_OPCALNDR",open_opts$[1]="OTA"
	gosub open_tables
