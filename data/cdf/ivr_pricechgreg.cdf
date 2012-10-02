[[IVR_PRICECHGREG.AREC]]
rem --- Get default date from first record

	file_name$ = "IVE_PRICECHG"
	ive_pricechg_dev = fnget_dev(file_name$)
	dim ive_pricechg_rec$:fnget_tpl$(file_name$)

	read (ive_pricechg_dev, key=firm_id$, dom=*next)
	read record (ive_pricechg_dev, end=arec_end) ive_pricechg_rec$

	callpoint!.setColumnData("IVR_PRICECHGREG.NEW_PRICE_CODE", ive_pricechg_rec.price_code$)
	callpoint!.setStatus("REFRESH")

arec_end:
[[IVR_PRICECHGREG.ASVA]]
rem --- Close file (so it can be locked by the overlay)

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVE_PRICECHG", open_opts$[1]="C"

	gosub open_tables
[[IVR_PRICECHGREG.BSHO]]
rem --- Get Batch information
rem --- this will let oper set up or select a batch (if batching turned on)
rem --- stbl("+BATCH_NO) will either be zero (not batching) or contain the batch#

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]

rem --- Open file

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVE_PRICECHG", open_opts$[1]="OTA"

	gosub open_tables
