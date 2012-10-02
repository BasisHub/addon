[[SFE_WOOPRTN.BDEL]]
rem --- v6 didn't do this, but before deleting, check to make sure the op isn't used in a material or subcontract line
[[SFE_WOOPRTN.REQUIRE_DATE.AVAL]]
rem --- Deal with Schedule Records

	if callpoint!.getUserInput()<>callpoint!.getColumnData("SFE_WOOPRTN.REQUIRE_DATE")
		gosub remove_sched
		setup_time=num(callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME"))
		hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
		pcs_per_hr=num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))
		yield=num(callpoint!.getDevObject("wo_est_yield"))
		run_time=SfUtils.opUnits(hrs_per_pc,pcs_per_hr,yield)
		move_time=num(callpoint!.getColumnData("SFE_WOOPRTN.MOVE_TIME"))
		add_date$=callpoint!.getUserInput()
		gosub add_sched
	endif
[[SFE_WOOPRTN.MOVE_TIME.AVAL]]
rem --- Deal with Schedule Records

	setup_time=num(callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME"))
	hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
	pcs_per_hr=num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))
	yield=num(callpoint!.getDevObject("wo_est_yield"))
	run_time=SfUtils.opUnits(hrs_per_pc,pcs_per_hr,yield)
	move_time=num(callpoint!.getUserInput())
	add_date$=callpoint!.getColumnData("SFE_WOOPRTN.REQUIRE_DATE")
	if callpoint!.getUserInput()<>callpoint!.getColumnData("SFE_WOOPRTN.MOVE_TIME")
		gosub remove_sched
		gosub add_sched
	endif

rem --- Calculate totals

	hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
	pcs_per_hr=num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))
	dir_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.DIRECT_RATE"))
	ovhd_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.OVHD_RATE"))
	setup=num(callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME"))
	gosub calc_totals
[[SFE_WOOPRTN.SETUP_TIME.AVAL]]
rem --- Deal with Schedule Records

	setup_time=num(callpoint!.getUserInput())
	hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
	pcs_per_hr=num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))
	yield=num(callpoint!.getDevObject("wo_est_yield"))
	run_time=SfUtils.opUnits(hrs_per_pc,pcs_per_hr,yield)
	move_time=num(callpoint!.getColumnData("SFE_WOOPRTN.MOVE_TIME"))
	add_date$=callpoint!.getColumnData("SFE_WOOPRTN.REQUIRE_DATE")
	if callpoint!.getUserInput()<>callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME")
		gosub remove_sched
		gosub add_sched
	endif

rem --- Calculate totals

	hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
	pcs_per_hr=num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))
	dir_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.DIRECT_RATE"))
	ovhd_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.OVHD_RATE"))
	setup=num(callpoint!.getUserInput())
	gosub calc_totals
[[SFE_WOOPRTN.PCS_PER_HOUR.AVAL]]
rem --- Check for valid quantity

	if num(callpoint!.getUserInput())=0
		msg_id$="VALUE_GT_ZERO"
		gosub disp_message
		callpoint!.setColumnData("SFE_WOOPRTN.PCS_PER_HOUR","1",1)
		callpoint!.setFocus(callpoint!.getValidationRow(),"SFE_WOOPRTN.PCS_PER_HOUR")
	endif

rem --- Calculate totals

	hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
	pcs_per_hr=num(callpoint!.getUserInput())
	dir_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.DIRECT_RATE"))
	ovhd_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.OVHD_RATE"))
	setup=num(callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME"))
	gosub calc_totals
[[SFE_WOOPRTN.HRS_PER_PCE.AVAL]]
rem --- Calculate totals

	hrs_per_pc=num(callpoint!.getUserInput())
	pcs_per_hr=num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))
	dir_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.DIRECT_RATE"))
	ovhd_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.OVHD_RATE"))
	setup=num(callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME"))
	gosub calc_totals
[[SFE_WOOPRTN.OP_CODE.AVAL]]
rem --- Display Queue time

	op_code$=callpoint!.getUserInput()
	gosub disp_queue

	hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
	pcs_per_hr=num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))
	dir_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.DIRECT_RATE"))
	ovhd_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.OVHD_RATE"))
	setup=num(callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME"))
	gosub calc_totals
[[SFE_WOOPRTN.<CUSTOM>]]
rem ===============================================================
disp_queue:
rem	op_code$:	input
rem ===============================================================

	opcode_dev=num(callpoint!.getDevObject("opcode_chan"))
	dim opcode$:callpoint!.getDevObject("opcode_tpl")
	callpoint!.setColumnData("SFE_WOOPRTN.CODE_DESC","",0)

	while 1
		read record (opcode_dev,key=firm_id$+op_code$,dom=*break)opcode$
		callpoint!.setColumnData("<<DISPLAY>>.QUEUE_TIME",opcode.queue_time$,1)
		callpoint!.setColumnData("SFE_WOOPRTN.CODE_DESC",opcode.code_desc$,0)
		break
	wend

	if opcode.pcs_per_hour=0 opcode.pcs_per_hour=1
	if num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))=0
		callpoint!.setColumnData("SFE_WOOPRTN.PCS_PER_HOUR",opcode.pcs_per_hour$,1)
	endif
	if num(callpoint!.getColumnData("SFE_WOOPRTN.DIRECT_RATE"))=0
		callpoint!.setColumnData("SFE_WOOPRTN.DIRECT_RATE",opcode.direct_rate$)
	endif
	if num(callpoint!.getColumnData("SFE_WOOPRTN.OVHD_RATE"))=0
		dir_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.DIRECT_RATE"))
		callpoint!.setColumnData("SFE_WOOPRTN.OVHD_RATE",str(dir_rate*opcode.ovhd_factor))
	endif
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y"
		callpoint!.setColumnData("SFE_WOOPRTN.SETUP_TIME",opcode.setup_time$,1)
		callpoint!.setColumnData("SFE_WOOPRTN.MOVE_TIME",opcode.move_time$,1)
	endif

	hrs_per_pc=num(callpoint!.getColumnData("SFE_WOOPRTN.HRS_PER_PCE"))
	pcs_per_hr=num(callpoint!.getColumnData("SFE_WOOPRTN.PCS_PER_HOUR"))
	dir_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.DIRECT_RATE"))
	ovhd_rate=num(callpoint!.getColumnData("SFE_WOOPRTN.OVHD_RATE"))
	setup=num(callpoint!.getColumnData("SFE_WOOPRTN.SETUP_TIME"))
	gosub calc_totals

	return

rem ===============================================================
calc_totals:
rem	hrs_per_pc:	input
rem	pcs_per_hr:	input
rem dir_rate:		input
rem ovhd_rate:	input
rem setup:		input
rem ===============================================================

	yield=num(callpoint!.getDevObject("wo_est_yield"))
	sched_qty=num(callpoint!.getDevObject("prod_qty"))

	run_time=SfUtils.opUnits(hrs_per_pc,pcs_per_hr,yield)
	unit_cost=SfUtils.opUnitsDollars(hrs_per_pc,dir_rate,ovhd_rate,pcs_per_hr,yield)
	callpoint!.setColumnData("SFE_WOOPRTN.RUNTIME_HRS",str(run_time))
	callpoint!.setColumnData("SFE_WOOPRTN.UNIT_COST",str(unit_cost),1)

	old_tot_time=num(callpoint!.getColumnData("SFE_WOOPRTN.TOTAL_TIME"))
	new_tot_time=SfUtils.opTime(run_time,sched_qty,hrs_per_pc,pcs_per_hr,yield,setup)
	new_tot_dols=SfUtils.opTotStdCost(sched_qty,hrs_per_pc,dir_rate,ovhd_rate,pcs_per_hr,yield,setup)
	callpoint!.setColumnData("SFE_WOOPRTN.TOTAL_TIME",str(new_tot_time))
	callpoint!.setColumnData("SFE_WOOPRTN.TOT_STD_COST",str(new_tot_dols))
	if old_tot_time<>new_tot_time
		gosub remove_sched
rem jpb need to add the correct records back in - not happening right now.
rem jpb None of the input variables are being sent in
		gosub add_sched
	endif

	return

rem ===============================================================
remove_sched:
rem ===============================================================

	sfm05_dev=fnget_dev("SFE_WOSCHDL")
	dim sfm05a$:fnget_tpl$("SFE_WOSCHDL")
	wo_no$=callpoint!.getColumnData("SFE_WOOPRTN.WO_NO")
	isn$=callpoint!.getColumnData("SFE_WOOPRTN.INTERNAL_SEQ_NO")

	while 1
		read (sfm05_dev,key=firm_id$+wo_no$+isn$,knum="AON_WONUM",dom=*next)
		read record (sfm05_dev,end=*break) sfm05a$
		if pos(firm_id$+wo_no$+isn$=sfm05a.firm_id$+sfm05a.wo_no$+sfm05a.oper_seq_ref$)<>1 break
		remove (sfm05_dev,key=firm_id$+sfm05a.op_code$+sfm05a.sched_date$+sfm05a.wo_no$+sfm05a.oper_seq_ref$)
	wend

	return

rem ===============================================================
add_sched:
rem setup_time:	input
rem run_time:		input
rem move_time:	input
rem add_date$:	input
rem ===============================================================

	sfm05_dev=fnget_dev("SFE_WOSCHDL")
	dim sfm05a$:fnget_tpl$("SFE_WOSCHDL")
	queue_time=num(callpoint!.getColumnData("<<DISPLAY>>.QUEUE_TIME"))

	sfm05a.firm_id$=firm_id$
	sfm05a.op_code$=callpoint!.getColumnData("SFE_WOOPRTN.OP_CODE")
	sfm05a.sched_date$=add_date$
	sfm05a.wo_no$=callpoint!.getColumnData("SFE_WOOPRTN.WO_NO")
	sfm05a.oper_seq_ref$=callpoint!.getColumnData("SFE_WOOPRTN.INTERNAL_SEQ_NO")
	sfm05a.queue_time=queue_time
	sfm05a.setup_time=setup_time
	sfm05a.runtime_hrs=run_time
	sfm05a.move_time=move_time
	sfm05a$=field(sfm05a$)
	write record (sfm05_dev) sfm05a$

	return
[[SFE_WOOPRTN.AGDR]]
rem --- Display Queue time

	op_code$=callpoint!.getColumnData("SFE_WOOPRTN.OP_CODE")
	gosub disp_queue

[[SFE_WOOPRTN.BSHO]]
use ::sfo_SfUtils.aon::SfUtils
declare SfUtils sfUtils!

rem --- set validation table for op codes to use sf codes if no bom interface (or bom not installed)

	if callpoint!.getDevObject("bm")<>"Y"
		callpoint!.setTableColumnAttribute("SFE_WOOPRTN.OP_CODE","DTAB","SFC_OPRTNCOD")
	endif

rem --- Disable grid if Closed Work Order

	if callpoint!.getDevObject("wo_status")="C"
		opts$=callpoint!.getTableAttribute("OPTS")
		callpoint!.setTableAttribute("OPTS",opts$+"BID")

		x$=callpoint!.getTableColumns()
		for x=1 to len(x$) step 40
			opts$=callpoint!.getTableColumnAttribute(cvs(x$(x,40),2),"OPTS")
			callpoint!.setTableColumnAttribute(cvs(x$(x,40),2),"OPTS",o$+"C"); rem - makes cells read only
		next x
	endif
