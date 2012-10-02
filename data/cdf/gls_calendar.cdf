[[GLS_CALENDAR.ADIS]]
gosub col_disable
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
