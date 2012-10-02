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
rem --- Retrieve parameter data/see if IV is installed
	ars01a_key$=firm_id$+"AR00"
 	find record (ads01_dev,key=ars01a_key$,ERR=std_missing_params) ars01a$
