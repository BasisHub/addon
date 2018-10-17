[[SFR_CLSDRECWODET.AREC]]
rem --- Restrict report to Recurring/Permanent work orders
	callpoint!.setColumnData("<<DISPLAY>>.WO_CATEGORY","'R'")
