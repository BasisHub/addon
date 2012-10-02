[[IVX_LFTIER_UTIL.<CUSTOM>]]
#include std_missing_params.src
[[IVX_LFTIER_UTIL.BSHO]]
rem --- Open Files

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVS_PARAMS", open_opts$[1]="OTA"

	gosub open_tables

	params_dev = num(open_chans$[1])
	dim params_rec$:open_tpls$[1]

rem --- Get IV params and check LIFO/FIFO flag

	find record(params_dev, key=firm_id$+"IV00", dom=std_missing_params) params_rec$

	if pos(params_rec.lifofifo$ = "LF") = 0 then 
		msg_id$ = "IV_NOT_LF"
		gosub disp_message
		callpoint!.setStatus("EXIT")
	endif
