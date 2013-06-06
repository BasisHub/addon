[[OPE_ORDCOMMENTS.BWRI]]
rem --- Now update the 3 display fields

	if cvs(callpoint!.getColumnData("OPE_ORDCOMMENTS.REV_DATE"),3)=""
		rev_date$=callpoint!.getDevObject("rev_date")
		audit_time$=callpoint!.getDevObject("audit_time")
		callpoint!.setColumnData("OPE_ORDCOMMENTS.REV_DATE",rev_date$)
		callpoint!.setColumnData("OPE_ORDCOMMENTS.AUDIT_TIME",audit_time$)
		callpoint!.setColumnData("OPE_ORDCOMMENTS.USER_ID",stbl("+USER_ID"))
	endif
[[OPE_ORDCOMMENTS.AREC]]
rem --- Set defaults for date and time

	callpoint!.setDevObject("rev_date",date(0:"%Yd%Mz%Dz"))
	callpoint!.setDevObject("audit_time",date(0:"%Hz%mz%sz"))
