[[IVR_PRICECHGPCT.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVR_PRICECHGPCT.ASVA]]
rem --- Percent change can't be zero

	if num( callpoint!.getColumnData("IVR_PRICECHGPCT.PERCENT_CHANGE") ) = 0 then
		callpoint!.setMessage("IV_PCT_CHG_INVALID")
		callpoint!.setStatus("ABORT")
	endif


[[IVR_PRICECHGPCT.PERCENT_CHANGE.AVAL]]
rem --- Percent can't be zero

	if num( callpoint!.getUserInput() ) = 0 then
		callpoint!.setStatus("ABORT")
	endif
[[IVR_PRICECHGPCT.BSHO]]
rem --- Get Batch information
rem --- this will let oper set up or select a batch (if batching turned on)
rem --- stbl("+BATCH_NO) will either be zero (not batching) or contain the batch#

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]

rem --- Inits

	pgmdir$=""
	pgmdir$=stbl("+DIR_PGM")

rem --- is AP installed?  If not, disable vendor fields

	call pgmdir$ + "adc_application.aon", "AP", info$[all]
	ap_installed = (info$[20] = "Y")

	if !ap_installed then
		callpoint!.setColumnEnabled("IVR_PRICECHGPCT.VENDOR_ID_1", -1)
		callpoint!.setColumnEnabled("IVR_PRICECHGPCT.VENDOR_ID_2", -1)
	endif
