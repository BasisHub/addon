[[IVR_ZEROBAL.ZERO_INCLUDED.AVAL]]
rem -- set report date based on selection (all, since last run, since process dt, since system dt)

switch pos(callpoint!.getUserInput()="ARPS")
	case 1
		callpoint!.setColumnData("IVR_ZEROBAL.REPORT_DATE","")
	break
	case 2
		callpoint!.setColumnData("IVR_ZEROBAL.REPORT_DATE",callpoint!.getColumnData("IVR_ZEROBAL.RUN_DATE"))
	break
	case 3
		callpoint!.setColumnData("IVR_ZEROBAL.REPORT_DATE",stbl("+SYSTEM_DATE"))
	break
	case 4
		callpoint!.setColumnData("IVR_ZEROBAL.REPORT_DATE",date(0:"%Yd%Mz%Dz"))
	break
	case default
	break
swend

callpoint!.setStatus("REFRESH")
[[IVR_ZEROBAL.ARAR]]
rem --- Open files

num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="IVS_ZEROBAL",open_opts$[1]="OTA"
gosub open_tables
ivs10a_chn=num(open_chans$[1])
ivs10a_tpl$=open_tpls$[1]

rem --- Get Last Run date

dim ivs10a$:ivs10a_tpl$
readrecord(ivs10a_chn,key=firm_id$+"A",dom=*next)ivs10a$

rem --- Get system date

sysinfo_template$=stbl("+SYSINFO_TPL")
dim sysinfo$:sysinfo_template$
sysinfo$=stbl("+SYSINFO")

rem --- Set Report Date

if num(ivs10a.run_date$) then
	report_date$=ivs10a.run_date$
	never = 0
else
	report_date$=sysinfo.system_date$
	never = 1
endif

rem --- Display defaults

callpoint!.setColumnData("IVR_ZEROBAL.RUN_DATE",report_date$)
callpoint!.setColumnData("IVR_ZEROBAL.REPORT_DATE",report_date$)

if never then
	callpoint!.setColumnData("IVR_ZEROBAL.ZERO_INCLUDED","A")
	callpoint!.setColumnData("IVR_ZEROBAL.REPORT_DATE","")
	ctl_name$ = "IVR_ZEROBAL.ZERO_INCLUDED"
	ctl_stat$ = "D"
	gosub disable_fields
	ctl_name$ = "IVR_ZEROBAL.REPORT_DATE"
	gosub disable_fields
else
	callpoint!.setColumnData("IVR_ZEROBAL.ZERO_INCLUDED","R")
endif

callpoint!.setStatus("ABLEMAP-REFRESH")
[[IVR_ZEROBAL.<CUSTOM>]]
rem #include disable_fields.src

disable_fields:
	rem --- used to disable/enable controls
	rem --- ctl_name$ sent in with name of control to enable/disable (format "ALIAS.CONTROL_NAME")
	rem --- ctl_stat$ sent in as D or space, meaning disable/enable, respectively

	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	rem callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")

return

rem #endinclude disable_fields.src
