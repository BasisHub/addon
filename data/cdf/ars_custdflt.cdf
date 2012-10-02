[[ARS_CUSTDFLT.AWIN]]
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ARS_PARAMS",open_opts$[1]="OTA"
gosub open_tables
ars01_dev=num(open_chans$[1]),ars01_tpl$=open_tpls$[1]

dim ars01a$:ars01_tpl$

rem --- check to see if main AR param rec (firm/AR/00) exists; if not, tell user to set it up first

	ars01a_key$=firm_id$+"AR00"
	find record (ars01_dev,key=ars01a_key$,err=*next) ars01a$
	if cvs(ars01a.current_per$,2)=""
		msg_id$="AR_PARAM_ERR"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		gosub remove_process_bar
		release
	endif
[[ARS_CUSTDFLT.<CUSTOM>]]
remove_process_bar:

bbjAPI!=bbjAPI()
rdFuncSpace!=bbjAPI!.getGroupNamespace()
rdFuncSpace!.setValue("+build_task","OFF")

return
