[[IVR_COSTCHGBYPCT.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVR_COSTCHGBYPCT.ASVA]]
rem --- Percent change can't be zero

	if num( callpoint!.getColumnData("IVR_COSTCHGBYPCT.PERCENT_CHANGE") ) = 0 then
		callpoint!.setMessage("IV_PCT_CHG_INVALID")
		callpoint!.setStatus("ABORT")
	endif

[[IVR_COSTCHGBYPCT.PERCENT_CHANGE.AVAL]]
rem --- Percent can't be zero

	if num( callpoint!.getUserInput() ) = 0 then
		callpoint!.setStatus("ABORT")
	endif
[[IVR_COSTCHGBYPCT.<CUSTOM>]]
#include std_missing_params.src
[[IVR_COSTCHGBYPCT.BSHO]]
rem --- Inits

	pgmdir$=""
	pgmdir$=stbl("+DIR_PGM")

rem --- Open files

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVS_PARAMS", open_opts$[1]="OTA"

	gosub open_tables

	ivs_params_dev = num(open_chans$[1])
	dim ivs_params_rec$:open_tpls$[1]

rem --- Get parameter record

	find record(ivs_params_dev, key=firm_id$+"IV00", dom=std_missing_params) ivs_params_rec$

rem --- Must be standard costing

	if ivs_params_rec.cost_method$ <> "S" then
		callpoint!.setMessage("IV_NO_STD_COST")
		callpoint!.setStatus("EXIT")
		goto bsho_end
	endif

rem --- is AP installed?  If not, disable vendor fields

	call pgmdir$ + "adc_application.aon", "AP", info$[all]
	ap_installed = (info$[20] = "Y")

	if !ap_installed then
		callpoint!.setColumnEnabled("IVR_COSTCHGBYPCT.VENDOR_ID_1", -1)
		callpoint!.setColumnEnabled("IVR_COSTCHGBYPCT.VENDOR_ID_2", -1)
	endif

rem --- Get Batch information
rem --- this will let oper set up or select a batch (if batching turned on)
rem --- stbl("+BATCH_NO) will either be zero (not batching) or contain the batch#

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]

bsho_end:
