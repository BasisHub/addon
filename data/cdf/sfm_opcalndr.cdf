[[SFM_OPCALNDR.BFMC]]
rem --- See if BOM is being used

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFS_PARAMS",open_opts$[1]="OTA"
	gosub open_tables

	sfs_params=num(open_chans$[1])
	dim sfs_params$:open_tpls$[1]

	read record(sfs_params,key=firm_id$+"SF00",dom=std_missing_params) sfs_params$

	if sfs_params.bm_interface$<>"Y"
		callpoint!.setTableColumnAttribute("SFM_OPCALNDR.OP_CODE","DTAB","SFC_OPRTNCOD")
	endif
[[SFM_OPCALNDR.<CUSTOM>]]
rem ==========================================================================
#include std_missing_params.src
rem ==========================================================================
