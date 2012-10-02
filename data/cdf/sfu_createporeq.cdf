[[SFU_CREATEPOREQ.<CUSTOM>]]
#include std_missing_params.src
[[SFU_CREATEPOREQ.BSHO]]
rem --- Exit if PO is not installed
	call stbl("+DIR_PGM")+"adc_application.aon","PO",info$[all]
	po$=info$[20];rem --- po installed?

	if po$<>"Y" then 
		msg_id$="PO_NOT_INST"
		gosub disp_message
		callpoint!.setStatus("EXIT")
		break
	endif

rem --- Exit if SF is not interfaced with PO 
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="sfs_params",open_opts$[1]="OTA"
	gosub open_tables
	sfs01_dev=num(open_chans$[1]),sfs_params_tpl$=open_tpls$[1]

	dim sfs01a$:sfs_params_tpl$

	readrecord(sfs01_dev,key=firm_id$+"SF00",dom=std_missing_params)sfs01a$

	if sfs01a.po_interface$<>"Y"
		msg_id$="SF_NO_PO_INTERFACE"
		gosub disp_message
		callpoint!.setStatus("EXIT")
		break
	endif
[[SFU_CREATEPOREQ.ASVA]]
rem --- Ensure that at least one status option (Open/Closed) is checked

if callpoint!.getColumnData("SFU_CREATEPOREQ.OPEN")="N" AND callpoint!.getColumnData("SFU_CREATEPOREQ.CLOSED")="N"
	msg_id$="SF_STATUS_REQUIRED"
	gosub disp_message
	callpoint!.setStatus("ABORT")
	callpoint!.setFocus("SFU_CREATEPOREQ.OPEN")
endif
