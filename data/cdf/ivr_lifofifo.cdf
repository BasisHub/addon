[[IVR_LIFOFIFO.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVR_LIFOFIFO.<CUSTOM>]]
#include std_missing_params.src
[[IVR_LIFOFIFO.BSHO]]
rem --- Open files

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"

	gosub open_tables

	ivs01_dev=num(open_chans$[1])
	dim ivs01a$:open_tpls$[1]

rem --- Check params: is Lifo/Fifo set?

	find record (ivs01_dev, key=firm_id$+"IV00", err=std_missing_params) ivs01a$

	if pos(ivs01a.lifofifo$="LF") = 0 then
		msg_id$ = "IV_NO_LIFO_FIFO"
		gosub disp_message
		callpoint!.setStatus("EXIT")
	endif
