[[ADS_CALENDAR.TOTAL_PERS.AVAL]]
gosub col_disable
[[ADS_CALENDAR.ADIS]]
gosub col_disable
[[ADS_CALENDAR.<CUSTOM>]]
rem --- Enable/disable column based on number of periods
col_disable:
	dim ctl_stat$[52],ctl_name$[52]
	pers=num(callpoint!.getColumnData("ADS_CALENDAR.TOTAL_PERS"))
	for x=1 to 13
		ctl_name$[x]="ADS_CALENDAR.LOCKED_FLAG_"+str(x:"00")
		ctl_name$[x+13]="ADS_CALENDAR.ABBR_NAME_"+str(x:"00")
		ctl_name$[x+26]="ADS_CALENDAR.PERIOD_NAME_"+str(x:"00")
		ctl_name$[x+39]="ADS_CALENDAR.PER_ENDING_"+str(x:"00")
		if x<=pers
			ctl_stat$[x]=" "
			ctl_stat$[x+13]=" "
			ctl_stat$[x+26]=" "
			ctl_stat$[x+39]=" "
		else
			ctl_stat$[x]="D"
			ctl_stat$[x+13]="D"
			ctl_stat$[x+26]="D"
			ctl_stat$[x+39]="D"
		endif
	next x
	gosub disable_fields
return

disable_fields:
	rem --- used to disable/enable controls
	rem --- ctl_name$ sent in with name of control to enable/disable (format "ALIAS.CONTROL_NAME")
	rem --- ctl_stat$ sent in as D or space, meaning disable/enable, respectively

	for x=1 to 52
		wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$[x],"CTLI")):"00000")
		wmap$=callpoint!.getAbleMap()
		wpos=pos(wctl$=wmap$,8)
		wmap$(wpos+6,1)=ctl_stat$[x]
		callpoint!.setAbleMap(wmap$)
	next x
	callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")

return
