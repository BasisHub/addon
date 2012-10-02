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

rem --- check to see if main AR param rec (firm/AR/00) exists; if not, tell user to set it up first

	ars01a_key$=firm_id$+"AR00"
	find record (ars01a_dev,key=ars01a_key$,err=*next) ars01a$
	if cvs(ars01a.current_per$,2)=""
		msg_id$="AR_PARAM_ERR"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		gosub remove_process_bar
		release
	endif

rem --- Parameters
        
	if ars01a.job_nos$<>"Y" then
		msg_id$="OP_NOJOBS"
		gosub disp_message
		callpoint!.setStatus("EXIT")
	endif
[[OPM_CUSTJOBS.<CUSTOM>]]
#include std_missing_params.src
