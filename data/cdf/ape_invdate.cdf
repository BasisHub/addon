[[APE_INVDATE.BEND]]
rem --- remove software lock on batch, if batching

	batch$=stbl("+BATCH_NO",err=*next)
	if num(batch$)<>0
		lock_table$="ADM_PROCBATCHES"
		lock_record$=firm_id$+stbl("+PROCESS_ID")+batch$
		lock_type$="U"
		lock_status$=""
		lock_disp$=""
		call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,table_chans$[all],lock_status$
	endif

release
[[APE_INVDATE.ASVA]]
rem --- validate Accounting Date
	if callpoint!.getColumnData("APE_INVDATE.DEF_ACCT_DATE")<>"" 
		call stbl("+DIR_PGM")+"glc_datecheck.aon",
:			callpoint!.getColumnData("APE_INVDATE.DEF_ACCT_DATE"),
:			"Y",per$,yr$,status
		if status>100
			callpoint!.setStatus("ABORT")
		else
			temp_stbl$=stbl("DEF_ACCT_DATE",callpoint!.getColumnData("APE_INVDATE.DEF_ACCT_DATE"))
		endif
	endif
[[APE_INVDATE.<CUSTOM>]]
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
[[APE_INVDATE.USE_INV_DATE.AVAL]]
rem --- Enable/Disable Date field
	ctl_name$="APE_INVDATE.DEF_ACCT_DATE"
	if callpoint!.getUserInput()="N"
		ctl_stat$=""
		if callpoint!.getColumnData("APE_INVDATE.DEF_ACCT_DATE")=""
			acctdate$=date(0:"%Y%Mz%Dz")
			acctdate$=stbl("+SYSTEM_DATE",err=*next)
		else
			acctdate$=callpoint!.getColumnData("APE_INVDATE.DEF_ACCT_DATE")
		endif
	else
		ctl_stat$="D"
		acctdate$=""
	endif
	callpoint!.setColumnData("APE_INVDATE.DEF_ACCT_DATE",acctdate$)
	temp_stbl$=stbl("DEF_ACCT_DATE",acctdate$)
	gosub disable_fields
[[APE_INVDATE.ARAR]]
rem --- Disable date for initial sreen show
	ctl_name$="APE_INVDATE.DEF_ACCT_DATE"
	ctl_stat$="D"
	acctdate$="",acctdate$=stbl("+SYSTEM_DATE",err=*next)
	callpoint!.setColumnData("APE_INVDATE.DEF_ACCT_DATE",acctdate$)
	callpoint!.setColumnData("APE_INVDATE.USE_INV_DATE","Y")
	temp_stbl$=stbl("DEF_ACCT_DATE",acctdate$)
	gosub disable_fields

