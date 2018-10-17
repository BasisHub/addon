[[OPR_ODERPICKDMD.BSHO]]
rem --- Open/Lock files
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"

	gosub open_tables

	ivs01_dev=num(open_chans$[1])
	dim ivs01a$:open_tpls$[1]

rem --- Retrieve parameter data
	ivs01a_key$=firm_id$+"IV00"
	find record (ivs01_dev,key=ivs01a_key$,err=std_missing_params) ivs01a$
	callpoint!.setDevObject("multi_whse",ivs01a.multi_whse$)
	callpoint!.setDevObject("warehouse_id",ivs01a.warehouse_id$)
[[OPR_ODERPICKDMD.<CUSTOM>]]
#include std_missing_params.src
[[OPR_ODERPICKDMD.AREC]]
rem --- default print prices to true if this is a quote

	if callpoint!.getColumnData("OPR_ODERPICKDMD.INVOICE_TYPE")="P"
		callpoint!.setColumnData("OPR_ODERPICKDMD.PRINT_PRICES","Y",1)
	endif

rem --- Initialize and disable warehouse_id when not using multiple warehouses
	if callpoint!.getDevObject("multi_whse")="N" then
		callpoint!.setColumnData("OPR_ODERPICKDMD.WAREHOUSE_ID",str(callpoint!.getDevObject("warehouse_id")))
		callpoint!.setColumnEnabled("OPR_ODERPICKDMD.WAREHOUSE_ID",0)
	endif
