[[ARR_INVOICES.PICK_CHECK.AVAL]]
if callpoint!.getColumnData("ARR_INVOICES.PICK_CHECK")<>"Y"
	callpoint!.setColumnData("ARR_INVOICES.PICK_AR_INV_NO","")
	callpoint!.setStatus("REFRESH")
endif
