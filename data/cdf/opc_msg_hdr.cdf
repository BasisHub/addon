[[OPC_MSG_HDR.BDEL]]
rem --- Check if code is used as a default code

	num_files = 1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARS_CUSTDFLT", open_opts$[1]="OTA"
	gosub open_tables
	ars_custdflt_dev = num(open_chans$[1])
	dim ars_rec$:open_tpls$[1]

	find record(ars_custdflt_dev,key=firm_id$+"D",dom=*next)ars_rec$
	if ars_rec.message_code$ = callpoint!.getColumnData("OPC_MSG_HDR.MESSAGE_CODE") then
		callpoint!.setMessage("OP_MSG_CODE_IN_DFLT")
		callpoint!.setStatus("ABORT")
	endif
[[OPC_MSG_HDR.AOPT-LSTG]]
rem --- run the Std Message Listing program
rem --- since this is a header/detail file structure, the built-in 'print all records' option won't work

run stbl("+DIR_PGM")+"opr_stdmessage.aon",err=*next
