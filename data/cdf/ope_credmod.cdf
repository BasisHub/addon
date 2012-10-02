[[OPE_CREDMOD.ARER]]
rem --- Display default information
	tick_date$=callpoint!.getDevObject("tick_date")
rem	tick_date$=tick_date$(5,4)+tick_date$(1,4)
	cred_hold$=callpoint!.getDevObject("cred_hold")
	cred_limit$=callpoint!.getDevObject("cred_limit")
	callpoint!.setColumnData("OPE_CREDMOD.TICKLER_DATE",tick_date$)
	callpoint!.setColumnData("OPE_CREDMOD.CRED_HOLD",cred_hold$)
	callpoint!.setColumnData("OPE_CREDMOD.CREDIT_LIMIT",cred_limit$)
	callpoint!.setStatus("REFRESH")
[[OPE_CREDMOD.ASVA]]
rem --- Set data for return
	callpoint!.setDevObject("tick_date",callpoint!.getColumnData("OPE_CREDMOD.TICKLER_DATE"))
	callpoint!.setDevObject("cred_hold",callpoint!.getColumnData("OPE_CREDMOD.CRED_HOLD"))
	callpoint!.setDevObject("cred_limit",callpoint!.getColumnData("OPE_CREDMOD.CREDIT_LIMIT"))
