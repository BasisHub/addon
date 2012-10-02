[[APR_CHECKREPORT.ARAR]]
	pgmdir$=stbl("+DIR_PGM")

rem --- Open/Lock files

	files=1,begfile=1,endfile=files
	dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
	files$[1]="aps_params",ids$[1]="APS_PARAMS"
	call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
	if status goto std_exit
	aps01_dev=channels[1]

rem --- Dimension string templates

	dim aps01a$:templates$[1]

rem --- Retrieve parameter data

	aps01a_key$=firm_id$+"AP00"
	find record (aps01_dev,key=aps01a_key$,err=*next) aps01a$
	callpoint!.setColumnData("APR_CHECKREPORT.PERIOD",aps01a.current_per$)
	callpoint!.setColumnData("APR_CHECKREPORT.YEAR",aps01a.current_year$)

	callpoint!.setStatus("MODIFIED-REFRESH")
