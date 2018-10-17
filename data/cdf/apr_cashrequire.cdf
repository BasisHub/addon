[[APR_CASHREQUIRE.AREC]]
rem --- Initialize and disable ap_type when not using multiple AP types
	if callpoint!.getDevObject("multi_types")="N" then
		callpoint!.setColumnData("APR_CASHREQUIRE.AP_TYPE",str(callpoint!.getDevObject("ap_type")))
		callpoint!.setColumnEnabled("APR_CASHREQUIRE.AP_TYPE",0)
	endif
[[APR_CASHREQUIRE.BSHO]]
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
[[APR_CASHREQUIRE.<CUSTOM>]]
#include std_missing_params.src
[[APR_CASHREQUIRE.AGING_DATE.AVAL]]
rem --- Verify calendar exists for fiscal year of aging_date
	aging_date$=callpoint!.getUserInput()
	call pgmdir$+"adc_fiscalperyr.aon",firm_id$,aging_date$,period$,year$,table_chans$[all],status
	if status then
		callpoint!.setStatus("ABORT")
		break
	endif
[[APR_CASHREQUIRE.ASVA]]
rem --- Check if a valid date was entered

	aging_date$=callpoint!.getColumnData("APR_CASHREQUIRE.AGING_DATE")
	aging_date=1
				
	if cvs(aging_date$,2)<>""
		aging_date=0
		aging_date=jul(num(aging_date$(1,4)),num(aging_date$(5,2)),num(aging_date$(7,2)),err=*next)
	endif
				
	if len(cvs(aging_date$,2))<>8 or aging_date=0
		msg_id$="INVALID_DATE"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		callpoint!.setStatus("EXIT")
	endif
