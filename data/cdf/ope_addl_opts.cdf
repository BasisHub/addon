[[OPE_ADDL_OPTS.ASVA]]
rem --- Save UserObj! for caller

	callpoint!.setDevObject("additional_options", UserObj!)
[[OPE_ADDL_OPTS.<CUSTOM>]]
rem ==========================================================================
recalc: rem --- Recalculate price
rem ==========================================================================

	unit_price = round(list_price * (100 - disc_perc) / 100, 2)
	
	if unit_price <> user_tpl.orig_price then
		callpoint!.setColumnData("OPE_ADDL_OPTS.MAN_PRICE", "Y")
		UserObj!.setFieldValue("MAN_PRICE", "Y")
		callpoint!.setColumnData("OPE_ADDL_OPTS.NET_PRICE", str(unit_price))
		UserObj!.setFieldValue("UNIT_PRICE", unit_price)
		callpoint!.setStatus("REFRESH")
	endif

	return
[[OPE_ADDL_OPTS.BSHO]]
rem --- Disable fields, set globals

	declare BBjTemplatedString UserObj!

	UserObj! = cast(BBjTemplatedString, callpoint!.getDevObject("additional_options"))
	dim user_tpl$:"orig_price:n(7*), orig_list:n(7*)"

	user_tpl.orig_price = UserObj!.getFieldAsNumber("UNIT_PRICE")
	user_tpl.orig_list  = UserObj!.getFieldAsNumber("STD_LIST_PRC")
	line_type$          = UserObj!.getFieldAsString("LINE_TYPE")
	invoice_type$       = UserObj!.getFieldAsString("INVOICE_TYPE")

	if pos(line_type$ = "SPN") = 0 then 
		callpoint!.setColumnEnabled("OPE_ADDL_OPTS.STD_LIST_PRC", 0)
		callpoint!.setColumnEnabled("OPE_ADDL_OPTS.DISC_PERCENT", 0)
	endif
		
	if invoice_type$ = "P" then
		callpoint!.setColumnEnabled("OPE_ADDL_OPTS.COMMIT_FLAG", 0)
	endif
[[OPE_ADDL_OPTS.STD_LIST_PRC.AVAL]]
rem --- Send back to caller

	list_price = round(num(callpoint!.getUserInput()), 2)
	UserObj!.setFieldValue("STD_LIST_PRC", list_price)

	if num(callpoint!.getUserInput()) <> user_tpl.orig_list then
		disc_perc  = num(callpoint!.getColumnData("OPE_ADDL_OPTS.DISC_PERCENT"))
		gosub recalc
	endif
[[OPE_ADDL_OPTS.EST_SHP_DATE.AVAL]]
rem --- Send back to caller

	UserObj!.setFieldValue("EST_SHP_DATE", callpoint!.getUserInput())
[[OPE_ADDL_OPTS.DISC_PERCENT.AVAL]]
rem --- Send back to caller

	UserObj!.setFieldValue("DISC_PERCENT", callpoint!.getUserInput())

	list_price = num(callpoint!.getColumnData("OPE_ADDL_OPTS.STD_LIST_PRC"))
	disc_perc  = num(callpoint!.getUserInput())
	gosub recalc
[[OPE_ADDL_OPTS.COMMIT_FLAG.AVAL]]
rem --- Send back to caller

	UserObj!.setFieldValue("COMMIT_FLAG", callpoint!.getUserInput())

	if callpoint!.getUserInput() = "N" then
		UserObj!.setFieldValue("PRINT_FLAG", "N")
		callpoint!.setStatus("REFRESH")
	endif
