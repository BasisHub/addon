[[OPM_CUSTJOBS.BSHO]]
rem --- Open/Lock files

	files=5,begfile=1,endfile=files
	dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
	files$[1]="ars_params",ids$[1]="ARS_PARAMS"
	call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:		ids$[all],templates$[all],channels[all],batch,status

	if status then
		remove_process_bar:
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
	 	release
	endif
	
	ars01a_dev=channels[1]

rem --- Dimension string templates

	dim ars01a$:templates$[1]

rem --- Retrieve parameter records

        ars01a_key$=firm_id$+"AR00"
        find record (ars01a_dev,key=ars01a_key$,err=std_missing_params) ars01a$

rem --- Parameters
        
	if ars01a.job_nos$<>"Y" then
		msg_id$="OP_NOJOBS"
		gosub disp_message
		callpoint!.setStatus("EXIT")
	endif
[[OPM_CUSTJOBS.<CUSTOM>]]
#include std_missing_params.src
