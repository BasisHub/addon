[[SFE_TIMEWODET.BGDC]]
rem --- set preset val for batch_no
	callpoint!.setTableColumnAttribute("SFE_TIMEWODET.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)

rem --- When PR is installed
	if callpoint!.getDevObject("pr")="Y"
		rem --- Validate employee_no with PRM_EMPLMAST instead of SFM_EMPLMAST
		callpoint!.setTableColumnAttribute("SFE_TIMEWODET.EMPLOYEE_NO","DTAB","PRM_EMPLMAST")
		callpoint!.setTableColumnAttribute("SFE_TIMEWODET.EMPLOYEE_NO","DCOL","EMPL_DISPNAME")
		callpoint!.setTableColumnAttribute("SFE_TIMEWODET.EMPLOYEE_NO","IDEF","PR_EMPLOYEES")

		rem --- Validate pay_code with PRC_PAYCODE
		callpoint!.setTableColumnAttribute("SFE_TIMEWODET.PAY_CODE","DTAB","PRC_PAYCODE")
		callpoint!.setTableColumnAttribute("SFE_TIMEWODET.PAY_CODE","DCOL","PR_CODE_DESC")
		callpoint!.setTableColumnAttribute("SFE_TIMEWODET.PAY_CODE","DKEY","[+FIRM_ID]+""A""+@")

		rem --- Validate title_code with PRC_TITLCODE
		callpoint!.setTableColumnAttribute("SFE_TIMEWODET.TITLE_CODE","DTAB","PRC_TITLCODE")
		callpoint!.setTableColumnAttribute("SFE_TIMEWODET.TITLE_CODE","DCOL","CODE_DESC")
		callpoint!.setTableColumnAttribute("SFE_TIMEWODET.TITLE_CODE","DKEY","[+FIRM_ID]+""F""+@")
	endif
[[<<DISPLAY>>.OP_REF.AVAL]]
rem --- Use this op_ref to initialize op_code and oper_seq_ref
	op_ref$=callpoint!.getUserInput()
	wo_location$="  "
	wo_no$=callpoint!.getColumnData("SFE_TIMEWODET.WO_NO")
	wooprtn_dev=callpoint!.getDevObject("sfe_wooprtn_dev")
	dim wooprtn$:callpoint!.getDevObject("sfe_wooprtn_tpl")
	key$=firm_id$+wo_location$+wo_no$+op_ref$
	findrecord(wooprtn_dev,key=key$,knum="AO_OP_REF",dom=*next)wooprtn$
	rem --- Must be a Standard line type operation, not a Message
	if wooprtn.line_type$<>"S" then
		msg_id$ = "WO_STD_OP_LINE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif
	rem --- Op_code initializations
	if wooprtn.internal_seq_no$<>callpoint!.getColumnData("SFE_TIMEWODET.OPER_SEQ_REF") then
		callpoint!.setColumnData("SFE_TIMEWODET.OPER_SEQ_REF",wooprtn.internal_seq_no$)
		op_code$=wooprtn.op_code$
		gosub op_code_init
	endif
[[SFE_TIMEWODET.AWRI]]

	gosub calc_header_hrs
[[SFE_TIMEWODET.BDGX]]

	gosub calc_header_hrs
[[SFE_TIMEWODET.BDEL]]

	gosub calc_header_hrs
[[SFE_TIMEWODET.AUDE]]

	gosub calc_header_hrs
[[SFE_TIMEWODET.AGRE]]
rem --- Display operation ref
	oper_seq_no$=callpoint!.getColumnData("SFE_TIMEWODET.OPER_SEQ_REF")
	gosub set_op_ref

	gosub calc_header_hrs
[[SFE_TIMEWODET.BGDR]]
rem --- Display operation ref
	oper_seq_no$=callpoint!.getColumnData("SFE_TIMEWODET.OPER_SEQ_REF")
	gosub set_op_ref
[[SFE_TIMEWODET.AGRN]]
rem --- Display operation ref
	oper_seq_no$=callpoint!.getColumnData("SFE_TIMEWODET.OPER_SEQ_REF")
	gosub set_op_ref

rem --- Require op_ref entry
	callpoint!.setTableColumnAttribute("<<DISPLAY>>.OP_REF","MINL","1")

rem --- Set op_ref lookup
	callpoint!.setTableColumnAttribute("<<DISPLAY>>.OP_REF","IDEF","AO_WO_OP_REF_LK")

rem --- Op_code initializations
	op_code$=callpoint!.getColumnData("SFE_TIMEWODET.OP_CODE")
	gosub op_code_init

rem --- Hold on to starting values for hrs and setup_time
	callpoint!.setDevObject("previous_hrs",callpoint!.getColumnData("SFE_TIMEWODET.HRS"))
	callpoint!.setDevObject("previous_setup_time",callpoint!.getColumnData("SFE_TIMEWODET.SETUP_TIME"))
[[SFE_TIMEWODET.HRS.AVAL]]
rem --- Update extension
	hrs=num(callpoint!.getUserInput())
	setup_time=num(callpoint!.getColumnData("SFE_TIMEWODET.SETUP_TIME"))
	gosub calculate_extension
[[SFE_TIMEWODET.SETUP_TIME.AVAL]]
rem --- Adjust hrs as needed
	setup_time=num(callpoint!.getUserInput())
	hrs=num(callpoint!.getColumnData("SFE_TIMEWODET.HRS"))
	if callpoint!.getDevObject("time_clk_flg")="Y" then
		if hrs<>0 and setup_time>hrs then
			callpoint!.setStatus("ABORT")
			break
		else
			hrs=hrs-setup_time
			callpoint!.setColumnData("SFE_TIMEWODET.HRS",str(hrs),1)
		endif
	endif

rem --- Update extension
	gosub calculate_extension
[[SFE_TIMEWODET.TITLE_CODE.AVAL]]
rem --- Get pay rate
	title_code$=callpoint!.getUserInput()
	pay_code$=callpoint!.getColumnData("SFE_TIMEWODET.PAY_CODE")
	gosub get_pay_rate
	if bad_code$="TC" then
		callpoint!.setStatus("ABORT")
		break
	endif
[[SFE_TIMEWODET.START_TIME.AVAL]]
rem --- Calculate hours
	start_time$=callpoint!.getUserInput()
	stop_time$=callpoint!.getColumnData("SFE_TIMEWODET.STOP_TIME")
	gosub calculate_hours

	rem --- Calculate hrs and extension
	if hours<>0 then
		setup_time=num(callpoint!.getColumnData("SFE_TIMEWODET.SETUP_TIME"))
		hrs=hours-setup_time
		callpoint!.setColumnData("SFE_TIMEWODET.HRS",str(hrs),1)
		gosub calculate_extension
	endif
[[SFE_TIMEWODET.PAY_CODE.AVAL]]
rem --- Get pay rate
	pay_code$=callpoint!.getUserInput()
	title_code$=callpoint!.getColumnData("SFE_TIMEWODET.TITLE_CODE")
	gosub get_pay_rate
	if bad_code$="PC" then
		callpoint!.setStatus("ABORT")
		break
	endif
[[SFE_TIMEWODET.<CUSTOM>]]
rem ==========================================================================
calculate_hours: rem --- Calculate hours
rem --- start_time$: input
rem --- stop_time$: input
rem --- hours: output
rem ==========================================================================
	hours=0
	if cvs(start_time$,2)<>"" and cvs(stop_time$,2)<>"" then
		start=num(start_time$)
		stop=num(stop_time$)
		if stop<start then stop=stop+2400
		if mod(stop,100)<mod(start,100) then stop=stop-40
		hours=(int((stop-start)*.01)+mod(stop-start,100)/60)*1
	endif
	return

rem ==========================================================================
calculate_extension: rem --- Calculate extension
rem --- hrs: input
rem --- setup_time: input
rem ==========================================================================
	hrs=num(callpoint!.getColumnData("SFE_TIMEWODET.HRS"))
	setup_time=num(callpoint!.getColumnData("SFE_TIMEWODET.SETUP_TIME"))
	direct_rate=num(callpoint!.getColumnData("SFE_TIMEWODET.DIRECT_RATE"))
	opcode_ovhd_factor=callpoint!.getDevObject("opcode_ovhd_factor")
	ovhd_rate=direct_rate*opcode_ovhd_factor
	extended_amt=round((hrs+setup_time)*direct_rate,2)+round((hrs+setup_time)*ovhd_rate,2)
	callpoint!.setColumnData("SFE_TIMEWODET.OVHD_RATE",str(ovhd_rate))
	callpoint!.setColumnData("SFE_TIMEWODET.EXTENDED_AMT",str(extended_amt))
	return

rem ==========================================================================
get_pay_rate: rem --- Determine pay rate if actual
rem --- pay_code$: input
rem --- title_code$: input
rem --- bad_code$: output
rem ==========================================================================
	bad_code$=""
	if callpoint!.getDevObject("pr")<>"Y" then
		rem --- No payroll interface, use opcode direct rate
		if num(callpoint!.getColumnData("SFE_TIMEWODET.DIRECT_RATE"))=0 then
			callpoint!.setColumnData("SFE_TIMEWODET.DIRECT_RATE",str(callpoint!.getDevObject("opcode_direct_rate")))
		endif
		hrs=num(callpoint!.getColumnData("SFE_TIMEWODET.HRS"))
		setup_time=num(callpoint!.getColumnData("SFE_TIMEWODET.SETUP_TIME"))
		gosub calculate_extension
	else
		rem --- Payroll Interface,  use employee's pay and title codes
		employee_no$=callpoint!.getColumnData("SFE_TIMEWODET.EMPLOYEE_NO")

		rem --- Use employee's pay code
		bad_code$="PC"
		trans_date$=callpoint!.getHeaderColumnData("SFE_TIMEWO.TRANS_DATE")
		emplearn_dev=callpoint!.getDevObject("emplearn_dev")
		find(emplearn_dev,key=firm_id$+employee_no$+trans_date$(1,4)+"A"+pay_code$,dom=*endif)
		paycode_dev=callpoint!.getDevObject("paycode_dev")
		dim paycode$:callpoint!.getDevObject("paycode_tpl")
		findrecord(paycode_dev,key=firm_id$+"A"+pay_code$,dom=*endif)paycode$
		bad_code$=""
		paycode_rate=paycode.calc_rtamt
		premium_rate=paycode.prem_factor

		rem --- Use employee's title code
		if callpoint!.getDevObject("pay_actstd")="A" then 
			bad_code$="TC"
			emplpay_dev=callpoint!.getDevObject("emplpay_dev")
			dim emplpay$:callpoint!.getDevObject("emplpay_tpl")
			findrecord(emplpay_dev,key=firm_id$+employee_no$+title_code$,dom=*endif)emplpay$
			titlcode_dev=callpoint!.getDevObject("titlcode_dev")
			dim titlcode$:callpoint!.getDevObject("titlcode_tpl")
			findrecord(titlcode_dev,key=firm_id$+"F"+title_code$,dom=*endif)titlcode$
			bad_code$=""

			rem --- Calculate actual pay rate
			rate=0
			std_rate=emplpay.std_rate
			std_hrs=emplpay.std_hrs
			if callpoint!.getDevObject("hrlysalary")<>"S" then
				rate=std_rate
			else
				if std_hrs<>0 then rate=std_rate/std_hrs
			endif
			if paycode_rate<>0 then rate=paycode_rate; rem --- override by pay code
			if rate=0 then rate=titlcode.std_rate; rem --- use title code rate if needed
			if premium_rate<>0 then rate=rate*premium_rate; rem --- premium factor
    
			if rate<>0 then
				callpoint!.setColumnData("SFE_TIMEWODET.DIRECT_RATE",str(rate))
				hrs=num(callpoint!.getColumnData("SFE_TIMEWODET.HRS"))
				setup_time=num(callpoint!.getColumnData("SFE_TIMEWODET.SETUP_TIME"))
				gosub calculate_extension
			else
				bad_code$="TC"
			endif
		endif
	endif

	rem --- Bad pay code
	if bad_code$="PC" and cvs(pay_code$,2)<>"" then
		msg_id$ = "PR_BAD_PAY_CODE"
		dim msg_tokens$[1]
		msg_tokens$[1]=pay_code$
		gosub disp_message
	endif

	rem --- Bad title code
	if bad_code$="TC" and cvs(title_code$,2)<>"" then
		msg_id$ = "PR_BAD_TITLE_CODE"
		dim msg_tokens$[1]
		msg_tokens$[1]=title_code$
		gosub disp_message
	endif

	return

rem ==========================================================================
op_code_init: rem --- Op_code initializations
rem --- op_code$: input
rem ==========================================================================
rem --- Get op_code direct rate and overhead factor
	opcode_dev=callpoint!.getDevObject("opcode_dev")
	dim opcode$:callpoint!.getDevObject("opcode_tpl")
	findrecord(opcode_dev,key=firm_id$+op_code$,dom=*next)opcode$
	callpoint!.setDevObject("opcode_direct_rate",opcode.direct_rate)
	callpoint!.setDevObject("opcode_ovhd_factor",opcode.ovhd_factor)

	rem --- Set direct rate and calculate extionsion
	if num(callpoint!.getColumnData("SFE_TIMEWODET.DIRECT_RATE"))=0 or 
:	op_code$<>callpoint!.getColumnData("SFE_TIMEWODET.OP_CODE") then
		callpoint!.setColumnData("SFE_TIMEWODET.DIRECT_RATE",str(callpoint!.getDevObject("opcode_direct_rate")))
		callpoint!.setColumnData("SFE_TIMEWODET.OP_CODE",op_code$,1)
	endif
	hrs=num(callpoint!.getColumnData("SFE_TIMEWODET.HRS"))
	setup_time=num(callpoint!.getColumnData("SFE_TIMEWODET.SETUP_TIME"))
	gosub calculate_extension

	return

rem ==========================================================================
set_op_ref: rem --- Display operation reference
rem --- oper_seq_no$: input
rem ==========================================================================
	wo_location$="  "
	wo_no$=callpoint!.getColumnData("SFE_TIMEWODET.WO_NO")
	wooprtn_dev=callpoint!.getDevObject("sfe_wooprtn_dev")
	dim wooprtn$:callpoint!.getDevObject("sfe_wooprtn_tpl")
	findrecord(wooprtn_dev,key=firm_id$+wo_location$+wo_no$+oper_seq_no$,knum="AO_OP_SEQ",dom=*next)wooprtn$
	callpoint!.setColumnData("<<DISPLAY>>.OP_REF",wooprtn.wo_op_ref$,1)
	return

rem ==========================================================================
calc_header_hrs:
rem ==========================================================================

	entered_hrs=0
	dim dtl_rec$:fnget_tpl$("SFE_TIMEWODET")
	dtl_vect!=GridVect!.getItem(0)
	if dtl_vect!<>null() and dtl_vect!.size()
	for i=0 to dtl_vect!.size()-1
		dtl_rec$=dtl_vect!.getItem(i)
		if cvs(dtl_rec$, 2) <> "" and callpoint!.getGridRowDeleteStatus(i) <> "Y"
			entered_hrs=entered_hrs+dtl_rec.hrs+dtl_rec.setup_time
		endif
	next i
	callpoint!.setHeaderColumnData("<<DISPLAY>>.ENTERED_HRS",str(entered_hrs))
	control_entered_hrs!=callpoint!.getDevObject("control_entered_hrs")
	control_entered_hrs!.setText(str(entered_hrs))
	callpoint!.setStatus("REFRESH")

	return
[[SFE_TIMEWODET.STOP_TIME.AVAL]]
rem --- Capture entry so can be used for next new start time
	stop_time$=callpoint!.getUserInput()
	callpoint!.setDevObject("prev_stoptime",callpoint!.getUserInput())

rem --- Calculate hours
	start_time$=callpoint!.getColumnData("SFE_TIMEWODET.START_TIME")
	gosub calculate_hours

	rem --- Calculate hrs and extension
	if hours<>0 then
		setup_time=num(callpoint!.getColumnData("SFE_TIMEWODET.SETUP_TIME"))
		hrs=hours-setup_time
		callpoint!.setColumnData("SFE_TIMEWODET.HRS",str(hrs),1)
		gosub calculate_extension
	endif
[[SFE_TIMEWODET.AREC]]
rem --- Initialize dev objects
	callpoint!.setDevObject("opcode_direct_rate",0)
	callpoint!.setDevObject("opcode_ovhd_factor",0)
	callpoint!.setDevObject("normal_title","")
	callpoint!.setDevObject("hrlysalary","")
	callpoint!.setDevObject("previous_hrs",0)
	callpoint!.setDevObject("previous_setup_time",0)

rem --- Initialize column data
	callpoint!.setColumnData("SFE_TIMEWODET.START_TIME",str(callpoint!.getDevObject("prev_stoptime")),1)
	callpoint!.setStatus("REFRESH")
[[SFE_TIMEWODET.START_TIME.BINP]]
rem --- Initialize new start_time
	if cvs(callpoint!.getColumnData("SFE_TIMEWODET.START_TIME"),2)="" then
		callpoint!.setColumnData("SFE_TIMEWODET.START_TIME",str(callpoint!.getDevObject("prev_stoptime")),1)
	endif
[[SFE_TIMEWODET.EMPLOYEE_NO.AVAL]]
rem --- Init for this employee

	if callpoint!.getDevObject("pr")="Y" then
		empcode_dev=callpoint!.getDevObject("empcode_dev")
		dim empcode$:callpoint!.getDevObject("empcode_tpl")
		findrecord(empcode_dev,key=firm_id$+callpoint!.getUserInput(),dom=*next)empcode$
		callpoint!.setDevObject("normal_title",empcode.normal_title$)
		callpoint!.setDevObject("hrlysalary",empcode.hrlysalary$)
		if cvs(callpoint!.getColumnData("SFE_TIMEWODET.TITLE_CODE"),2)="" then
			callpoint!.setColumnData("SFE_TIMEWODET.TITLE_CODE",empcode.normal_title$,1)
		endif
		if cvs(callpoint!.getColumnData("SFE_TIMEWODET.PAY_CODE"),2)="" then
			callpoint!.setColumnData("SFE_TIMEWODET.PAY_CODE",str(callpoint!.getDevObject("reg_pay_code")),1)
		endif
	endif
[[SFE_TIMEWODET.ADGE]]
rem --- Disable fields
	if callpoint!.getDevObject("time_clk_flg")<>"Y" then
		callpoint!.setColumnEnabled(-1,"SFE_TIMEWODET.START_TIME",0)
		callpoint!.setColumnEnabled(-1,"SFE_TIMEWODET.STOP_TIME",0)
	endif
	if callpoint!.getDevObject("pr")<>"Y" then
		callpoint!.setColumnEnabled(-1,"SFE_TIMEWODET.PAY_CODE",0)
		callpoint!.setColumnEnabled(-1,"SFE_TIMEWODET.TITLE_CODE",0)
	endif

rem --- Initializations
	callpoint!.setDevObject("prev_stoptime","")
[[SFE_TIMEWODET.BGDS]]
rem --- Set precision
	precision num(callpoint!.getDevObject("precision"))
