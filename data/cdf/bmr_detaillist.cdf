[[BMR_DETAILLIST.ASVA]]
rem --- set DevObjects for the Jasper Report

	callpoint!.setDevObject("bill_from",callpoint!.getColumnData("BMR_DETAILLIST.BILL_NO_1"))
	callpoint!.setDevObject("bill_thru",callpoint!.getColumnData("BMR_DETAILLIST.BILL_NO_2"))
