[[ARR_STMT_DEMAND.AREC]]
rem --- open report control

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARM_CUSTRPT_CTL",open_opts$[1]="OTA"
	gosub open_tables
	arm_custrpt_ctl=num(open_chans$[1])
	dim arm_custrpt_ctl$:open_tpls$[1]

	find record (arm_custrpt_ctl,key=firm_id$+callpoint!.getColumnData("CUSTOMER_ID")+pad("ARR_STATEMENTS",16),err=*next)arm_custrpt_ctl$
	if arm_custrpt_ctl.email_yn$="Y" or arm_custrpt_ctl.fax_yn$="Y"
		callpoint!.setColumnEnabled("ARR_STMT_DEMAND.PICK_CHECK",1)
	else
		callpoint!.setColumnEnabled("ARR_STMT_DEMAND.PICK_CHECK",0)
	endif
