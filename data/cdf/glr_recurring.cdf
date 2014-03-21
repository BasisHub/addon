[[GLR_RECURRING.ARAR]]
rem --- Initialize Posting Month and Posting Year with system date
	dim sysinfo$:stbl("+SYSINFO_TPL")
	sysinfo$=stbl("+SYSINFO")
	callpoint!.setColumnData("GLR_RECURRING.POSTING_MONTH",sysinfo.system_date$(5,2),1)
	callpoint!.setColumnData("GLR_RECURRING.POSTING_YEAR",sysinfo.system_date$(1,4),1)
