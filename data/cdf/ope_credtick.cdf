[[OPE_CREDTICK.AABO]]
rem --- clear variables on exit
	callpoint!.setDevObject("customer_id","")
	callpoint!.setDevObject("tick_date","")
[[OPE_CREDTICK.CUSTOMER_ID.AVAL]]
rem --- set customer for return to master
	callpoint!.setDevObject("customer_id",callpoint!.getUserInput())
[[OPE_CREDTICK.TICKLER_DATE.AVAL]]
rem --- set date for return to master
	callpoint!.setDevObject("tick_date",callpoint!.getUserInput())
