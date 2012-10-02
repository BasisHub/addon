[[GLS_CALENDAR.LOCKED_FLAG_01.BINP]]
callpoint!.setStatus("REFRESH")
[[GLS_CALENDAR.ADIS]]
gosub col_disable
if num(callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS"))=0
	gosub set_defaults
endif
[[GLS_CALENDAR.<CUSTOM>]]
rem --- Enable/disable column based on number of periods
col_disable:
	dim ctl_stat$[13],ctl_name$[13]
	pers=num(callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS"))
	for x=1 to 13
		ctl_name$[x]="GLS_CALENDAR.LOCKED_FLAG_"+str(x:"00")
		if x<=pers
			ctl_stat$[x]=" "
		else
			ctl_stat$[x]="D"
		endif
	next x
	gosub disable_fields
return

disable_fields:
	rem --- used to disable/enable controls
	rem --- ctl_name$ sent in with name of control to enable/disable (format "ALIAS.CONTROL_NAME")
	rem --- ctl_stat$ sent in as D or space, meaning disable/enable, respectively

	for x=1 to 13
		wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$[x],"CTLI")):"00000")
		wmap$=callpoint!.getAbleMap()
		wpos=pos(wctl$=wmap$,8)
		wmap$(wpos+6,1)=ctl_stat$[x]
		callpoint!.setAbleMap(wmap$)
	next x
	callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")

return

set_defaults:

	callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_01","January")
	callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_02","February")
	callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_03","March")
	callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_04","April")
	callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_05","May")
	callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_06","June")
	callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_07","July")
	callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_08","August")
	callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_09","September")
	callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_10","October")
	callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_11","November")
	callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_12","December")
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
	callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_01","0131")
	callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_02","0228")
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
	curr_date$=date(0:"%Mz%Dz%Yl")
	callpoint!.setColumnData("GLS_CALENDAR.CURRENT_YEAR",curr_date$(5,4))
	callpoint!.setColumnData("GLS_CALENDAR.TOTAL_PERS","12")
	callpoint!.setColumnData("GLS_CALENDAR.CURRENT_PER",curr_date$(1,2))
	if jul(num(curr_date$(5,4)),2,29,err=*endif)>0
		callpoint!.setColumnData("GLS_CALENDAR.PER_ENDING_02","0229")
	endif
	callpoint!.setStatus("SAVE")
return
