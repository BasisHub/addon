[[ADS_CALENDAR.PER_ENDING_13.AVAL]]
gosub validate_mo_day
[[ADS_CALENDAR.PER_ENDING_12.AVAL]]
gosub validate_mo_day
[[ADS_CALENDAR.PER_ENDING_11.AVAL]]
gosub validate_mo_day
[[ADS_CALENDAR.PER_ENDING_10.AVAL]]
gosub validate_mo_day
[[ADS_CALENDAR.PER_ENDING_09.AVAL]]
gosub validate_mo_day
[[ADS_CALENDAR.PER_ENDING_08.AVAL]]
gosub validate_mo_day
[[ADS_CALENDAR.PER_ENDING_07.AVAL]]
gosub validate_mo_day
[[ADS_CALENDAR.PER_ENDING_06.AVAL]]
gosub validate_mo_day
[[ADS_CALENDAR.PER_ENDING_05.AVAL]]
gosub validate_mo_day
[[ADS_CALENDAR.PER_ENDING_04.AVAL]]
gosub validate_mo_day
[[ADS_CALENDAR.PER_ENDING_03.AVAL]]
gosub validate_mo_day
[[ADS_CALENDAR.PER_ENDING_02.AVAL]]
gosub validate_mo_day
[[ADS_CALENDAR.PER_ENDING_01.AVAL]]
gosub validate_mo_day
[[ADS_CALENDAR.TOTAL_PERS.AVAL]]
pers=num(callpoint!.getUserInput())
gosub col_disable
[[ADS_CALENDAR.ADIS]]
pers=num(callpoint!.getColumnData("ADS_CALENDAR.TOTAL_PERS"))
gosub col_disable
[[ADS_CALENDAR.<CUSTOM>]]
rem --- validate period ending date (month/day - doesn't check for Feb 28 vs 29)
validate_mo_day:

	ok$="N"
	mo_day$=str(num(callpoint!.getUserInput(),err=validate_mo_day_err):"0000")
	month=num(mo_day$(1,2))

	switch month
		case 1
		case 3
		case 5
		case 7
		case 8
		case 10
		case 12
			if num(mo_day$(3,2))>=1 and num(mo_day$(3,2))<=31 ok$="Y"	
		break
		case 2
			if num(mo_day$(3,2))>=1 and num(mo_day$(3,2))<=29 ok$="Y"
		break
		case 4
		case 6
		case 9
		case 11
			if num(mo_day$(3,2))>=1 and num(mo_day$(3,2))<=30 ok$="Y"
		break
	swend

	if ok$<>"Y"

validate_mo_day_err:
	msg_id$="GL_INVAL_PER"
	gosub disp_message
	callpoint!.setStatus("ABORT")

	endif

return


rem --- Enable/disable column based on number of periods
rem --- pers being set prior to gosub
col_disable:
	dim ctl_stat$[52],ctl_name$[52]
	
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
