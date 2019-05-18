[[APR_CHECKREPORT.ARAR]]

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
	period=num(aps01a.current_per$)
	year=num(aps01a.current_year$)

	call stbl("+DIR_PGM")+"adc_perioddates.aon",period,year,begdate$,enddate$,table_chans$[all],status
	if status=0 then
		callpoint!.setColumnData("APR_CHECKREPORT.CHECK_DATE_1",begdate$,1)
		callpoint!.setColumnData("APR_CHECKREPORT.CHECK_DATE_2",enddate$,1)
	endif

rem --- Initialize TYPE_BREAKS
	if aps01a.multi_types$<>"Y" then
		callpoint!.setColumnEnabled("APR_CHECKREPORT.TYPE_BREAKS",0)
	else
		callpoint!.setColumnData("APR_CHECKREPORT.TYPE_BREAKS","1",0)
	endif

rem --- Initialize ACH_PAYMENTS
	callpoint!.setColumnData("APR_CHECKREPORT.ACH_PAYMENTS","I",0)
