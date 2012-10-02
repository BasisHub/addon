[[BMM_BILLOPER.OP_CODE.AVAL]]
rem --- Setup default data for new S type line

	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y"
		bmm08=fnget_dev("BMC_OPCODES")
		dim bmm08$:fnget_tpl$("BMC_OPCODES")
		op_code$=callpoint!.getUserInput()
		read record (bmm08,key=firm_id$+op_code$,dom=*next)bmm08$
		callpoint!.setColumnData("BMM_BILLOPER.MOVE_TIME",bmm08.move_time$)
		callpoint!.setColumnData("BMM_BILLOPER.PCS_PER_HOUR",bmm08.pcs_per_hour$)
		callpoint!.setColumnData("BMM_BILLOPER.SETUP_TIME",bmm08.setup_time$)
		callpoint!.setColumnData("BMM_BILLOPER.HRS_PER_PCE","1")
		hrs_pc=1
		pc_hr=bmm08.pcs_per_hour
		setup=bmm08.setup_time
		gosub calc_hours
	endif
[[BMM_BILLOPER.AGRN]]
rem --- Display Total Hours

	hrs_pc=num(callpoint!.getColumnData("BMM_BILLOPER.HRS_PER_PCE"))
	pc_hr=num(callpoint!.getColumnData("BMM_BILLOPER.PCS_PER_HOUR"))
	setup=num(callpoint!.getColumnData("BMM_BILLOPER.SETUP_TIME"))
	op_code$=callpoint!.getColumnData("BMM_BILLOPER.OP_CODE")
	gosub calc_hours
[[BMM_BILLOPER.SETUP_TIME.AVAL]]
rem --- Display Total Hours

	hrs_pc=num(callpoint!.getColumnData("BMM_BILLOPER.HRS_PER_PCE"))
	pc_hr=num(callpoint!.getColumnData("BMM_BILLOPER.PCS_PER_HOUR"))
	setup=num(callpoint!.getUserInput())
	op_code$=callpoint!.getColumnData("BMM_BILLOPER.OP_CODE")
	gosub calc_hours
[[BMM_BILLOPER.PCS_PER_HOUR.AVAL]]
rem --- Display Total Hours

	hrs_pc=num(callpoint!.getColumnData("BMM_BILLOPER.HRS_PER_PCE"))
	pc_hr=num(callpoint!.getUserInput())
	setup=num(callpoint!.getColumnData("BMM_BILLOPER.SETUP_TIME"))
	op_code$=callpoint!.getColumnData("BMM_BILLOPER.OP_CODE")
	gosub calc_hours
[[BMM_BILLOPER.HRS_PER_PCE.AVAL]]
rem --- Display Total Hours

	hrs_pc=num(callpoint!.getUserInput())
	pc_hr=num(callpoint!.getColumnData("BMM_BILLOPER.PCS_PER_HOUR"))
	setup=num(callpoint!.getColumnData("BMM_BILLOPER.SETUP_TIME"))
	op_code$=callpoint!.getColumnData("BMM_BILLOPER.OP_CODE")
	gosub calc_hours
[[BMM_BILLOPER.<CUSTOM>]]
rem ===================================================================
calc_hours:
rem --- hrs_pc:			input
rem --- pc_hr:			input
rem --- setup:			input
rem --- op_code:		input
rem ===================================================================

	bmm08=fnget_dev("BMC_OPCODES")
	dim bmm08$:fnget_tpl$("BMC_OPCODES")
	read record (bmm08,key=firm_id$+op_code$,dom=*next)bmm08$
	direct_rate=bmm08.direct_rate*1.0
	oh_rate=bmm08.ovhd_factor

	yield_pct=callpoint!.getDevObject("yield")
	lot_size=callpoint!.getDevObject("lotsize")
	direct_cost=BmUtils.directCost(hrs_pc,direct_rate,pc_hr,yield_pct,setup,lot_size)
	oh_cost=direct_cost*oh_rate
	callpoint!.setColumnData("BMM_BILLOPER.DIRECT_RATE",str(direct_rate:mask$))
	callpoint!.setColumnData("BMM_BILLOPER.DIRECT_COST",str(direct_cost:mask$))
	callpoint!.setColumnData("BMM_BILLOPER.OVHD_COST",str(oh_cost:mask$))
	callpoint!.setColumnData("BMM_BILLOPER.TOT_COST",str(direct_cost+oh_cost:mask$))
	callpoint!.setColumnData("BMM_BILLOPER.QUEUE_TIME",bmm08.queue_time$)
	callpoint!.setStatus("REFRESH")

	return
[[BMM_BILLOPER.BSHO]]
rem --- Setup java class for Derived Data Element

	use ::bmo_BmUtils.aon::BmUtils
	declare BmUtils bmUtils!

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="BMC_OPCODES",open_opts$[1]="OTA"
	gosub open_tables
