[[IVR_PRICEREVERSE.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVR_PRICEREVERSE.BSHO]]
rem --- Inits

	pgmdir$=""
	pgmdir$=stbl("+DIR_PGM")

rem --- is AP installed?  If not, disable vendor fields

	call pgmdir$ + "adc_application.aon", "AP", info$[all]
	ap_installed = (info$[20] = "Y")

	if !ap_installed then
		callpoint!.setColumnEnabled("IVR_PRICEREVERSE.VENDOR_ID_1", -1)
		callpoint!.setColumnEnabled("IVR_PRICEREVERSE.VENDOR_ID_2", -1)
	endif
