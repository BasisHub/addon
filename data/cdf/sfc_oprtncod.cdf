[[SFC_OPRTNCOD.PCS_PER_HOUR.AVAL]]
rem --- Make sure value is greater than 0

	if num(callpoint!.getUserInput())<=0
		msg_id$="PCS_PER_HR_NOT_ZERO"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[SFC_OPRTNCOD.BSHO]]
rem --- Check to make sure BOM isn't being used

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFS_PARAMS",open_opts$[1]="OTA"
	gosub open_tables

	sfs_params=num(open_chans$[1])
	dim sfs_params$:open_tpls$[1]

	read record(sfs_params,key=firm_id$+"SF00",dom=std_missing_params) sfs_params$

	if sfs_params.bm_interface$="Y"
		msg_id$="SF_BOM_INST"
		gosub disp_message
		rem - remove process bar
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif
[[SFC_OPRTNCOD.<CUSTOM>]]
#include std_missing_params.src
