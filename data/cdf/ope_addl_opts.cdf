[[OPE_ADDL_OPTS.ASVA]]
rem --- Confirm it's okay to exit

	if callpoint!.getDevObject("exit_ok")<>"Y" then
		callpoint!.setDevObject("exit_ok","Y")
		callpoint!.setStatus("ABORT")
		break
	endif

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

	isEditMode = UserObj!.getFieldAsNumber("isEditMode")
	user_tpl.orig_price = UserObj!.getFieldAsNumber("UNIT_PRICE")
	user_tpl.orig_list  = UserObj!.getFieldAsNumber("STD_LIST_PRC")
	line_type$          = UserObj!.getFieldAsString("LINE_TYPE")
	invoice_type$       = UserObj!.getFieldAsString("INVOICE_TYPE")

	if isEditMode then
		if pos(line_type$ = "SPN") = 0 then 
			callpoint!.setColumnEnabled("OPE_ADDL_OPTS.STD_LIST_PRC", -1)
			callpoint!.setColumnEnabled("OPE_ADDL_OPTS.DISC_PERCENT",  -1)
		endif

		if invoice_type$ = "P" then
			callpoint!.setColumnEnabled("OPE_ADDL_OPTS.COMMIT_FLAG",  -1)
		endif
	else
			callpoint!.setColumnEnabled("OPE_ADDL_OPTS.COMMIT_FLAG",  -1)
			callpoint!.setColumnEnabled("OPE_ADDL_OPTS.DISC_PERCENT",  -1)
			callpoint!.setColumnEnabled("OPE_ADDL_OPTS.EST_SHP_DATE", -1)
			callpoint!.setColumnEnabled("OPE_ADDL_OPTS.MAN_PRICE", -1)
			callpoint!.setColumnEnabled("OPE_ADDL_OPTS.NET_PRICE", -1)
			callpoint!.setColumnEnabled("OPE_ADDL_OPTS.PRINTED", -1)
			callpoint!.setColumnEnabled("OPE_ADDL_OPTS.STD_LIST_PRC", -1)
	endif

rem --- Initialize exit abort flag

	callpoint!.setDevObject("exit_ok","Y")
[[OPE_ADDL_OPTS.STD_LIST_PRC.AVAL]]
rem --- Send back to caller

	list_price = round(num(callpoint!.getUserInput()), 2)
	UserObj!.setFieldValue("STD_LIST_PRC", list_price)

	if num(callpoint!.getUserInput()) <> user_tpl.orig_list then
		disc_perc  = num(callpoint!.getColumnData("OPE_ADDL_OPTS.DISC_PERCENT"))
		gosub recalc
	endif
[[OPE_ADDL_OPTS.EST_SHP_DATE.AVAL]]
rem --- Is OP parameter set for asking about creating Work Order?

	if callpoint!.getDevObject("op_create_wo")<>null() and callpoint!.getDevObject("op_create_wo")="A" then
		newEstShpDate$ = callpoint!.getUserInput()
		oldEstShpDate$ = callpoint!.getColumnUndoData("OPE_ADDL_OPTS.EST_SHP_DATE")
		if callpoint!.getColumnData("OPE_ADDL_OPTS.COMMIT_FLAG")="Y" and newEstShpDate$ <> oldEstShpDate$ and
:		callpoint!.getGridRowNewStatus(num(callpoint!.getValidationRow())) <> "Y" then
			rem --- Estimated Ship Date changed for a committed detail line
			isn$ = UserObj!.getFieldAsString("INTERNAL_SEQ_NO")
			soCreateWO! = callpoint!.getDevObject("soCreateWO")
			if !soCreateWO!.adjustEstShpDate(isn$, newEstShpDate$) then
				callpoint!.setColumnData("OPE_ADDL_OPTS.EST_SHP_DATE",oldEstShpDate$,1)
				callpoint!.setStatus("ACTIVATE-ABORT")
				callpoint!.setDevObject("exit_ok","N")
				break
			endif
			callpoint!.setStatus("ACTIVATE")
		endif
	endif

rem --- Send back to caller

	UserObj!.setFieldValue("EST_SHP_DATE", callpoint!.getUserInput())
[[OPE_ADDL_OPTS.DISC_PERCENT.AVAL]]
rem --- Send back to caller

	UserObj!.setFieldValue("DISC_PERCENT", callpoint!.getUserInput())

	list_price = num(callpoint!.getColumnData("OPE_ADDL_OPTS.STD_LIST_PRC"))
	disc_perc  = num(callpoint!.getUserInput())
	gosub recalc
[[OPE_ADDL_OPTS.COMMIT_FLAG.AVAL]]
rem --- Is OP parameter set for asking about creating Work Order?

	if callpoint!.getDevObject("op_create_wo")<>null() and callpoint!.getDevObject("op_create_wo")="A" then
		if callpoint!.getUserInput()="N" and callpoint!.getColumnUndoData("OPE_ADDL_OPTS.COMMIT_FLAG")="Y" then
			rem --- Treat un-committing the same as deleting the line as far as linked WOs are concerned
			isn$ = UserObj!.getFieldAsString("INTERNAL_SEQ_NO")
			soCreateWO! = callpoint!.getDevObject("soCreateWO")
			if !soCreateWO!.unlinkWO(isn$) then
				callpoint!.setColumnData("OPE_ADDL_OPTS.COMMIT_FLAG","Y",1)
				callpoint!.setStatus("ACTIVATE-ABORT")
				callpoint!.setDevObject("exit_ok","N")
				break
			endif
			callpoint!.setStatus("ACTIVATE")
		endif
	endif

rem --- Send back to caller

	UserObj!.setFieldValue("COMMIT_FLAG", callpoint!.getUserInput())

	if callpoint!.getUserInput() = "N" then
		UserObj!.setFieldValue("PRINT_FLAG", "N")
		callpoint!.setStatus("REFRESH")
	endif
