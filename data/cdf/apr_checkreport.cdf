[[APR_CHECKREPORT.ARAR]]

use ::ado_func.src::func

pgmdir$=stbl("+DIR_PGM")

rem --- Open/Lock files

	files=2,begfile=1,endfile=files
	dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
	files$[1]="aps_params",ids$[1]="APS_PARAMS"
	files$[2]="gls_params",ids$[2]="GLS_PARAMS"
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
	gls01_dev=channels[2]

rem --- Dimension string templates

	dim aps01a$:templates$[1]

rem --- Retrieve parameter data

	aps01a_key$=firm_id$+"AP00"
	find record (aps01_dev,key=aps01a_key$,err=*next) aps01a$
	period=num(aps01a.current_per$)
	year=num(aps01a.current_year$)

	call stbl("+DIR_PGM")+"adc_perioddates.aon",gls01_dev,period,year,begdate$,enddate$,status
	callpoint!.setColumnData("APR_CHECKREPORT.CHECK_DATE_1",begdate$,1)
	callpoint!.setColumnData("APR_CHECKREPORT.CHECK_DATE_2",enddate$,1)

rem	tot_per$=func.getNumPeriods()
rem	callpoint!.setTableColumnAttribute("APR_CHECKREPORT.PERIOD","MINV","01")
rem	callpoint!.setTableColumnAttribute("APR_CHECKREPORT.PERIOD","MAXV",tot_per$)

rem	callpoint!.setStatus("REFRESH")
