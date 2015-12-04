[[ARS_CUSTDFLT.AREC]]
rem --- Initialize new record

	if callpoint!.getDevObject("cm_installed")="Y" then
		hold_new$=callpoint!.getDevObject("hold_new")
		callpoint!.setColumnData("ARS_CUSTDFLT.CRED_HOLD",hold_new$)
	else
		callpoint!.setColumnData("ARS_CUSTDFLT.CRED_HOLD","N")
	endif

	callpoint!.setColumnData("ARS_CUSTDFLT.INV_HIST_FLG","Y")
[[ARS_CUSTDFLT.BSHO]]
rem --- Determine if optional modules are installed

	call stbl("+DIR_PGM")+"adc_application.aon","OP",info$[all]
	op$=info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","SA",info$[all]
	sa$=info$[20]

rem --- Disable fields that require OP

	if op$<>"Y" then
		callpoint!.setColumnEnabled("ARS_CUSTDFLT.FRT_TERMS",-1)
		callpoint!.setColumnEnabled("ARS_CUSTDFLT.MESSAGE_CODE",-1)
		callpoint!.setColumnEnabled("ARS_CUSTDFLT.PRICING_CODE",-1)
		callpoint!.setColumnEnabled("ARS_CUSTDFLT.SA_FLAG",-1)
	endif

	rem --- Detail invoice history is always retained now, so disable that check box.
	callpoint!.setColumnEnabled("ARS_CUSTDFLT.INV_HIST_FLG",-1)

rem --- Disable fields that require SA

	if sa$<>"Y" then
		callpoint!.setColumnEnabled("ARS_CUSTDFLT.SA_FLAG",-1)
	endif

rem --- Check Credit Management parameters

	if callpoint!.getDevObject("cm_installed")="Y" then
		callpoint!.setColumnEnabled("ARS_CUSTDFLT.CREDIT_LIMIT",-1)
	else
		callpoint!.setColumnEnabled("ARS_CUSTDFLT.CRED_HOLD",-1)
	endif
[[ARS_CUSTDFLT.AWIN]]
rem --- Get AR parameters

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="ARS_CREDIT",open_opts$[2]="OTA"

	gosub open_tables

	ars01a_dev=num(open_chans$[1]);dim ars01a$:open_tpls$[1]
	ars01c_dev=num(open_chans$[2]);dim ars01c$:open_tpls$[2]

rem --- Check to see if main AR param rec (firm/AR/00) exists; if not, tell user to set it up first

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

rem --- Get Credit Management parameters

	ars01c_key$=firm_id$+"AR01"
	find record (ars01c_dev,key=ars01c_key$,err=*next) ars01c$
	callpoint!.setDevObject("cm_installed",ars01c.sys_install$)
	callpoint!.setDevObject("hold_new",ars01c.hold_new$)
[[ARS_CUSTDFLT.<CUSTOM>]]
remove_process_bar:

bbjAPI!=bbjAPI()
rdFuncSpace!=bbjAPI!.getGroupNamespace()
rdFuncSpace!.setValue("+build_task","OFF")

return
