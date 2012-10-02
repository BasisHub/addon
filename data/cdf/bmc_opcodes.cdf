[[BMC_OPCODES.PCS_PER_HOUR.AVAL]]
rem --- Make sure value is greater than 0

	if num(callpoint!.getUserInput())<=0
		msg_id$="PCS_PER_HR_NOT_ZERO"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[BMC_OPCODES.BSHO]]
rem --- Open needed files

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="BMM_BILLOPER",open_opts$[1]="OTA"
	gosub open_tables
[[BMC_OPCODES.BDEL]]
rem --- Check for usage in Bills

	bmm_billoper_dev=fnget_dev("BMM_BILLOPER")
	op_code$=callpoint!.getColumnData("BMC_OPCODES.OP_CODE")
	while 1
		read(bmm_billoper_dev,key=firm_id$+op_code$,knum="AO_OPCODE_BILL",dom=*next)
		k$=key(bmm_billoper_dev,end=*break)
		if pos(firm_id$+op_code$=k$)=1
			callpoint!.setMessage("BM_OPCODE_USED")
			callpoint!.setStatus("ABORT")
		endif
		break
	wend
