[[BMU_IVCOSTING.ASVA]]
rem --- Warning to run IV Valuation Report and the IV Costing Report

	msg_id$="BM_RUN_VALUATION"
	dim msg_tokens$[1]
	msg_opt$=""
	gosub disp_message
	if msg_opt$<>"Y"
		callpoint!.setStatus("EXIT")
	endif
[[BMU_IVCOSTING.BSHO]]
rem --- Open needed tables
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"
	gosub open_tables
			
	ivs01_dev=num(open_chans$[1])
	dim ivs01a$:open_tpls$[1]
		
	read record (ivs01_dev,key=firm_id$+"IV00")ivs01a$
	callpoint!.setDevObject("dflt_whse",ivs01a.warehouse_id$)
[[BMU_IVCOSTING.AREC]]
rem --- Set default Warehouse
			
	whse$=callpoint!.getDevObject("dflt_whse")
	callpoint!.setColumnData("BMU_IVCOSTING.WAREHOUSE_ID",whse$,1)
[[BMR_COSTING.AREC]]
rem --- Set default Warehouse

	whse$=callpoint!.getDevObject("dflt_whse")
	callpoint!.setColumnData("BMR_COSTING.WAREHOUSE_ID",whse$,1)
[[BMR_COSTING.BSHO]]
rem --- Open needed tables
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"
	gosub open_tables

	ivs01_dev=num(open_chans$[1])
	dim ivs01a$:open_tpls$[1]

	read record (ivs01_dev,key=firm_id$+"IV00")ivs01a$
	callpoint!.setDevObject("dflt_whse",ivs01a.warehouse_id$)
