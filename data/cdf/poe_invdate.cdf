[[POE_INVDATE.BEND]]
release
[[POE_INVDATE.ASVA]]
rem --- validate Accounting Date
	if callpoint!.getColumnData("POE_INVDATE.DEF_ACCT_DATE")<>"" 
		call stbl("+DIR_PGM")+"glc_datecheck.aon",
:			callpoint!.getColumnData("POE_INVDATE.DEF_ACCT_DATE"),
:			"Y",per$,yr$,status
		if status>100
			callpoint!.setStatus("ABORT")
		else
			temp_stbl$=stbl("DEF_ACCT_DATE",callpoint!.getColumnData("POE_INVDATE.DEF_ACCT_DATE"))
		endif
	endif
[[POE_INVDATE.<CUSTOM>]]
disable_fields:
	rem --- used to disable/enable controls
	rem --- ctl_name$ sent in with name of control to enable/disable (format "ALIAS.CONTROL_NAME")
	rem --- ctl_stat$ sent in as D or space, meaning disable/enable, respectively
	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")
return
[[POE_INVDATE.USE_INV_DATE.AVAL]]
rem --- Enable/Disable Date field
	ctl_name$="POE_INVDATE.DEF_ACCT_DATE"
	if callpoint!.getUserInput()="N"
		ctl_stat$=""
		if callpoint!.getColumnData("POE_INVDATE.DEF_ACCT_DATE")=""
			acctdate$=date(0:"%Y%Mz%Dz")
			acctdate$=stbl("+SYSTEM_DATE",err=*next)
		else
			acctdate$=callpoint!.getColumnData("POE_INVDATE.DEF_ACCT_DATE")
		endif
	else
		ctl_stat$="D"
		acctdate$=""
	endif
	callpoint!.setColumnData("POE_INVDATE.DEF_ACCT_DATE",acctdate$)
	temp_stbl$=stbl("DEF_ACCT_DATE",acctdate$)
	gosub disable_fields
[[POE_INVDATE.ARAR]]
rem --- Disable date for initial sreen show
	ctl_name$="POE_INVDATE.DEF_ACCT_DATE"
	ctl_stat$="D"
	acctdate$="",acctdate$=stbl("+SYSTEM_DATE",err=*next)
	callpoint!.setColumnData("POE_INVDATE.DEF_ACCT_DATE",acctdate$)
	callpoint!.setColumnData("POE_INVDATE.USE_INV_DATE","Y")
	temp_stbl$=stbl("DEF_ACCT_DATE",acctdate$)
	gosub disable_fields

