[[OPE_CREDTICK.ASVA]]
rem --- set data for return to master

	callpoint!.setDevObject("tick_date",callpoint!.getColumnData("OPE_CREDTICK.TICKLER_DATE"))
	callpoint!.setDevObject("customer_id",callpoint!.getColumnData("OPE_CREDTICK.CUSTOMER_ID"))
[[OPE_CREDTICK.AABO]]
rem --- clear variables on exit
	callpoint!.setDevObject("customer_id","")
	callpoint!.setDevObject("tick_date","")
