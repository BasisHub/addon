[[OPR_ODERPICKDMD.AREC]]
rem --- default print prices to true if this is a quote

	if callpoint!.getColumnData("OPR_ODERPICKDMD.INVOICE_TYPE")="P"
		callpoint!.setColumnData("OPR_ODERPICKDMD.PRINT_PRICES","Y",1)
	endif
