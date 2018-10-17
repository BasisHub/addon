[[APR_AGINGREPORT.AREC]]
rem --- Initialize and disable ap_type when not using multiple AP types
	if callpoint!.getDevObject("multi_types")="N" then
		callpoint!.setColumnData("APR_AGINGREPORT.AP_TYPE",str(callpoint!.getDevObject("ap_type")))
		callpoint!.setColumnEnabled("APR_AGINGREPORT.AP_TYPE",0)
	endif
[[APR_AGINGREPORT.<CUSTOM>]]
#include std_missing_params.src
[[APR_AGINGREPORT.BSHO]]
rem --- Open/Lock files
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APS_PARAMS",open_opts$[1]="OTA"

	gosub open_tables

	aps01_dev=num(open_chans$[1])
	dim aps01a$:open_tpls$[1]

rem --- Retrieve parameter data
	aps01a_key$=firm_id$+"AP00"
	find record (aps01_dev,key=aps01a_key$,err=std_missing_params) aps01a$
	callpoint!.setDevObject("multi_types",aps01a.multi_types$)
	callpoint!.setDevObject("ap_type",aps01a.ap_type$)
[[APR_AGINGREPORT.AGING_DATE.AVAL]]
rem --- Verify calendar exists for fiscal year of aging_date
	aging_date$=callpoint!.getUserInput()
	call pgmdir$+"adc_fiscalperyr.aon",firm_id$,aging_date$,period$,year$,table_chans$[all],status
	if status then
		callpoint!.setStatus("ABORT")
		break
	endif
