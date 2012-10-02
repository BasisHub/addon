[[ARM_CUSTDET.AR_TERMS_CODE.AVAL]]
rem --- look up terms code, arm10A...if cred_hold is Y for this terms code,
rem --- and cm$ is Y, set arm_custdet.cred_hold to Y as well
if user_tpl.cm_installed$="Y"
	tablepos=pos("ARC_TERMCODE"=table_chans$[0,0],20)
	arc_termcode_dev=num(table_chans$[0,0](tablepos+17,3))
	dim arc_termcode$:table_chans$[int(tablepos/20)+1,0]
	read record (arc_termcode_dev,key=firm_id$+"A"+callpoint_data$,dom=*break)arc_termcode$
	if arc_termcode.cred_hold$="Y"
		rec_data$[fnstr_pos("ARM_CUSTDET.CRED_HOLD",rec_data$[0,0],40),0]="Y"
		callpoint.callpoint_stat$="REFRESH"
	endif
endif
