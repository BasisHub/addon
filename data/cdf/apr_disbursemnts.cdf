[[APR_DISBURSEMNTS.PERIOD.AVAL]]
rem --- Validate period
	period=num(callpoint!.getUserInput())
	if period<1 or period>num(callpoint!.getDevObject("tot_per")) then
		msg_id$ = "INVALID_PERIOD"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif
[[APR_DISBURSEMNTS.ARAR]]
use ::ado_func.src::func

	pgmdir$=stbl("+DIR_PGM")

rem --- Open/Lock files

	files=1,begfile=1,endfile=files
	dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
	files$[1]="aps_params",ids$[1]="APS_PARAMS"
	call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
	if status then
		remove_process_bar:
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
	 	release
	endif
	
	aps01_dev=channels[1]

rem --- Dimension string templates

	dim aps01a$:templates$[1]

rem --- Retrieve parameter data

	aps01a_key$=firm_id$+"AP00"
	find record (aps01_dev,key=aps01a_key$,err=*next) aps01a$
	callpoint!.setColumnData("APR_DISBURSEMNTS.PERIOD",aps01a.current_per$,1)
	callpoint!.setColumnData("APR_DISBURSEMNTS.YEAR",aps01a.current_year$,1)
	callpoint!.setDevObject("tot_per",func.getNumPeriods())

rem --- Initialize TYPE_BREAKS
	if aps01a.multi_types$<>"Y" then
		callpoint!.setColumnEnabled("APR_DISBURSEMNTS.TYPE_BREAKS",0)
	else
		callpoint!.setColumnData("APR_DISBURSEMNTS.TYPE_BREAKS","1",0)
	endif
