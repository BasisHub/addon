[[BMM_DETAILLIST.ASVA]]
rem --- set DevObjects for the Jasper Report

	callpoint!.setDevObject("bill_from",callpoint!.getDevObject("master_bill"))
	callpoint!.setDevObject("bill_thru",callpoint!.getDevObject("master_bill"))
