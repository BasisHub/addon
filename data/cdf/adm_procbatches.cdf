[[ADM_PROCBATCHES.BEND]]
release
[[ADM_PROCBATCHES.AOPT-SELB]]
rem --- see if process ID of this record is same as set in +PROCESS_ID by adc_getbatch...don't permit user to select batch from a different process
rem --- hopefully at some point we'll be able to run this form w/ an automatic filter on process ID

if cvs(callpoint!.getColumnData("ADM_PROCBATCHES.PROCESS_ID"),3)<>stbl("+PROCESS_ID")

	callpoint!.setMessage("PROC_INVALID")
	callpoint!.setStatus("ABORT")

else

	if cvs(callpoint!.getColumnData("ADM_PROCBATCHES.BATCH_NO"),3)=""
	callpoint!.setStatus("ABORT")

else

	rem --- set exit stbl to be this batch number

	x$=stbl("+BATCH_NO",callpoint!.getColumnData("ADM_PROCBATCHES.BATCH_NO"))
	callpoint!.setStatus("EXIT")

endif
[[ADM_PROCBATCHES.ARNF]]
rem --- Setup defaults
	callpoint!.setColumnData("ADM_PROCBATCHES.DATE_OPENED",date(0:"%Yd%Mz%Dz"))
	callpoint!.setColumnData("ADM_PROCBATCHES.LSTUSE_DATE",date(0:"%Yd%Mz%Dz"))
	callpoint!.setColumnData("ADM_PROCBATCHES.LSTUSE_TIME",date(0:"%hz%mz"))
	callpoint!.setColumnData("ADM_PROCBATCHES.PROCESS_ID",stbl("+PROCESS_ID"))
	callpoint!.setColumnData("ADM_PROCBATCHES.TIME_OPENED",date(0:"%hz%mz"))
	callpoint!.setColumnData("ADM_PROCBATCHES.USER_ID",sysinfo.user_id$)
	callpoint!.setColumnData("ADM_PROCBATCHES.DESCRIPTION",stbl("+BATCH_DESC"))
	callpoint!.setStatus("MODIFIED-REFRESH")
[[ADM_PROCBATCHES.BWRI]]
rem --- see if process ID of this record is same as set in +PROCESS_ID by adc_getbatch...don't permit user to select batch from a different process
rem --- hopefully at some point we'll be able to run this form w/ an automatic filter on process ID

if cvs(callpoint!.getColumnData("ADM_PROCBATCHES.PROCESS_ID"),3)<>stbl("+PROCESS_ID")

	callpoint!.setMessage("PROC_INVALID")
	callpoint!.setStatus("ABORT")

endif

if cvs(callpoint!.getColumnData("ADM_PROCBATCHES.BATCH_NO"),3)=""
	callpoint!.setStatus("ABORT")
endif
[[ADM_PROCBATCHES.BSHO]]
rem --- disable key field if no new recs allowed

	if stbl("+ALLOW_NEW_BATCH",err=*next)<>"Y"
		ctl_name$="ADM_PROCBATCHES.BATCH_NO"
		ctl_stat$="I"
		gosub disable_fields
	endif
[[ADM_PROCBATCHES.<CUSTOM>]]
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
