[[OPC_DISCCODE.DISC_PERCENT.AVAL]]
if  num(callpoint!.getUserInput() )<0 
:	callpoint!.setUserInput("0")
	callpoint!.setStatus("REFRESH-ABORT")                           
endif
[[OPC_DISCCODE.<CUSTOM>]]
#include std_missing_params.src
[[OPC_DISCCODE.BSHO]]
rem --- Open/Lock files
	files=1,begfile=1,endfile=1
	dim files$[files],options$[files],chans$[files],templates$[files]
	files$[1]="ARS_PARAMS";rem --- "ARS_PARAMS"..."ads-01"
	
	for wkx=begfile to endfile
		options$[wkx]="OTA"
	next wkx
	call dir_pgm$+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                   chans$[all],templates$[all],table_chans$[all],batch,status$
	if status$<>"" then
		remove_process_bar:
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif
	ads01_dev=num(chans$[1])
	dim ars01a$:templates$[1]

rem --- check to see if main AR param rec (firm/AR/00) exists; if not, tell user to set it up first
	ars01a_key$=firm_id$+"AR00"
	find record (ads01_dev,key=ars01a_key$,err=*next) ars01a$
	if cvs(ars01a.current_per$,2)=""
		msg_id$="AR_PARAM_ERR"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		gosub remove_process_bar
		release
	endif
