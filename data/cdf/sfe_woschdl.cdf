[[SFE_WOSCHDL.<CUSTOM>]]
rem ==========================================================================
#include std_missing_params.src
rem ==========================================================================
[[SFE_WOSCHDL.BFMC]]
rem --- open files/init

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFS_PARAMS",open_opts$[1]="OTA"

	gosub open_tables

	sfs_params=num(open_chans$[1])

	dim sfs_params$:open_tpls$[1]

	read record (sfs_params,key=firm_id$+"SF00",dom=std_missing_params)sfs_params$
	bm$=sfs_params.bm_interface$

	if bm$="Y"
		call stbl("+DIR_PGM")+"adc_application.aon","BM",info$[all]
		bm$=info$[20]
	endif

	if bm$<>"Y"
		callpoint!.setTableColumnAttribute("SFE_WOSCHDL.OP_CODE","DTAB","SFC_OPRTNCOD")
	endif
