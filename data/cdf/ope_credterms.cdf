[[OPE_CREDTERMS.ARER]]
rem Default the Terms Code
	terms$=callpoint!.getDevObject("terms")
	callpoint!.setColumnData("OPE_CREDTERMS.TERMS_CODE",terms$)
	callpoint!.setStatus("REFRESH")
[[OPE_CREDTERMS.ASVA]]
callpoint!.setDevObject("terms",callpoint!.getColumnData("OPE_CREDTERMS.TERMS_CODE"))
