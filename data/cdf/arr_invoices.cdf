[[ARR_INVOICES.PICK_CHECK.AVAL]]
if callpoint!.getUserInput()<>"Y"
	callpoint!.setColumnData("ARR_INVOICES.PICK_AR_INV_NO","")
	callpoint!.setStatus("REFRESH")
endif

