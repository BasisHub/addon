[[IVR_COSTCHGVALUE.<CUSTOM>]]
#include std_missing_params.src
[[IVR_COSTCHGVALUE.ASVA]]
rem --- Close file so it can be locked in the register

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVE_COSTCHG",open_opts$[1]="C"
	gosub open_tables
[[IVR_COSTCHGVALUE.BSHO]]
rem --- Get Batch information
rem --- this will let oper set up or select a batch (if batching turned on)
rem --- stbl("+BATCH_NO) will either be zero (not batching) or contain the batch#

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]

rem --- Open file

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVE_COSTCHG", open_opts$[1]="OTA"
	open_tables$[2]="IVS_PARAMS",   open_opts$[2]="OTA"

	gosub open_tables

	ivs_params_dev = num(open_chans$[2])
	dim ivs_params_rec$:open_tpls$[2]

rem --- Get parameter records

	find record(ivs_params_dev, key=firm_id$+"IV00", dom=std_missing_params) ivs_params_rec$

	if ivs_params_rec.cost_method$ <> "S" then
		callpoint!.setMessage("IV_NO_STD_COST")
		callpoint!.setStatus("EXIT")
		break
	endif
[[IVR_COSTCHGVALUE.AREC]]
rem --- Get default date from first record

	file_name$ = "IVE_COSTCHG"
	ive_costchg_dev = fnget_dev(file_name$)
	dim ive_costchg_rec$:fnget_tpl$(file_name$)

	read (ive_costchg_dev, key=firm_id$, dom=*next)
	read record (ive_costchg_dev, end=arec_end) ive_costchg_rec$

	callpoint!.setColumnData("IVR_COSTCHGVALUE.EFFECT_DATE", ive_costchg_rec.effect_date$)
	callpoint!.setStatus("REFRESH")

arec_end:
