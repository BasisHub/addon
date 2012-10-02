[[IVR_COSTCHGREG.ASVA]]
rem --- Close file so it can be locked in the register

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVE_COSTCHG",open_opts$[1]="C"
	gosub open_tables
[[IVR_COSTCHGREG.AREC]]
rem --- Get default date from first record

	file_name$ = "IVE_COSTCHG"
	ive_costchg_dev = fnget_dev(file_name$)
	dim ive_costchg_rec$:fnget_tpl$(file_name$)

	read (ive_costchg_dev, key=firm_id$, dom=*next)
	read record (ive_costchg_dev, end=arec_end) ive_costchg_rec$

	callpoint!.setColumnData("IVR_COSTCHGREG.EFFECT_DATE", ive_costchg_rec.effect_date$)
	callpoint!.setStatus("REFRESH")

arec_end:
[[IVR_COSTCHGREG.BSHO]]
rem --- Get Batch information
rem --- this will let oper set up or select a batch (if batching turned on)
rem --- stbl("+BATCH_NO) will either be zero (not batching) or contain the batch#

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]

rem --- Open file

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVE_COSTCHG", open_opts$[1]="OTA"

	gosub open_tables
