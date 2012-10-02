[[APR_RECURRING.ASVA]]
rem --- Validate Date
	call stbl("+DIR_PGM")+"glc_ctlcreate.aon",pgm(-1),"AP",glw11$,gl$,status
	call stbl("+DIR_PGM")+"glc_datecheck.aon",callpoint!.getColumnData("APR_RECURRING.YEAR")+
:		callpoint!.getColumnData("APR_RECURRING.MONTH")+"01","Y",per$,yr$,status
	if status>99
		callpoint!.setStatus("ABORT")
	endif
[[APR_RECURRING.BEND]]
release
[[APR_RECURRING.<CUSTOM>]]
#include std_missing_params.src
[[APR_RECURRING.ARAR]]
rem --- Default year and period
	gls01_dev=fnget_dev("GLS_PARAMS")
	aps01_dev=fnget_dev("APS_PARAMS")
	dim aps01a$:fnget_tpl$("APS_PARAMS")
	readrecord(aps01_dev,key=firm_id$+"AP00",dom=std_missing_params)aps01a$
	call stbl("+DIR_PGM")+"adc_perioddates.aon",gls01_dev,num(aps01a.current_per$),
:		num(aps01a.current_year$),begdate$,enddate$,status
	if status=0
		callpoint!.setColumnData("APR_RECURRING.MONTH",	enddate$(5,2))
		callpoint!.setColumnData("APR_RECURRING.YEAR",enddate$(1,4))
	endif
[[APR_RECURRING.BSHO]]
rem --- Open Parameter file
	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="GLS_PARAMS",open_opts$[2]="OTA"
	gosub open_tables
