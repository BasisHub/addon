[[SFE_TIMEEMPL.BSHO]]
rem --- Hold on to the control for entered_hrs so it can be updated in detail grid
	callpoint!.setDevObject("control_entered_hrs",callpoint!.getControl("<<DISPLAY>>.ENTERED_HRS"))
[[SFE_TIMEEMPL.BWAR]]
rem --- Check entered hrs
	total_hrs=num(callpoint!.getColumnData("SFE_TIMEEMPL.TOTAL_HRS"))
	entered_hrs=num(callpoint!.getColumnData("<<DISPLAY>>.ENTERED_HRS"))
	if entered_hrs<>total_hrs then
		msg_id$ = "SF_HOURS_OOB"
		dim msg_tokens$[1]
		msg_tokens$[1]=str(total_hrs-entered_hrs:callpoint!.getDevObject("unit_mask"))
		gosub disp_message
		if msg_opt$="O" then
			rem --- Ok oob
			callpoint!.setColumnData("SFE_TIMEEMPL.TOTAL_HRS",str(entered_hrs),1)
			callpoint!.setStatus("MODIFIED")
		else
			rem --- Cancel exit
			callpoint!.setStatus("ABORT")
			break
		endif
	endif
[[SFE_TIMEEMPL.ADIS]]
rem --- Init entered hrs
	entered_hrs=0
	timedet_dev=fnget_dev("SFE_TIMEEMPLDET")
	dim timedet$:fnget_tpl$("SFE_TIMEEMPLDET")
	trip_key$=firm_id$+callpoint!.getColumnData("SFE_TIMEEMPL.EMPLOYEE_NO")+callpoint!.getColumnData("SFE_TIMEEMPL.TRANS_DATE")
	read(timedet_dev,key=trip_key$,dom=*next)
	while 1
		timedet_key$=key(timedet_dev,end=*break)
		if pos(trip_key$=timedet_key$)<>1 then break
		readrecord(timedet_dev)timedet$
		entered_hrs=entered_hrs+timedet.hrs+timedet.setup_time
	wend
	callpoint!.setColumnData("<<DISPLAY>>.ENTERED_HRS",str(entered_hrs),1)
[[SFE_TIMEEMPL.AREC]]
rem --- Init new record
	entered_hrs=0
	callpoint!.setColumnData("<<DISPLAY>>.ENTERED_HRS",str(entered_hrs),1)
	callpoint!.setDevObject("entered_hrs",entered_hrs)
	callpoint!.setDevObject("normal_title","")
	callpoint!.setDevObject("hrlysalary","")
[[SFE_TIMEEMPL.EMPLOYEE_NO.AVAL]]
rem --- Init for this employee
	if callpoint!.getDevObject("pr")="Y" then
		empcode_dev=callpoint!.getDevObject("empcode_dev")
		dim empcode$:callpoint!.getDevObject("empcode_tpl")
		findrecord(empcode_dev,key=firm_id$+callpoint!.getUserInput(),dom=*next)empcode$
		callpoint!.setDevObject("normal_title",empcode.normal_title$)
		callpoint!.setDevObject("hrlysalary",empcode.hrlysalary$)
	endif
[[SFE_TIMEEMPL.AREA]]
rem --- Init for this employee
	if callpoint!.getDevObject("pr")="Y" then
		empcode_dev=callpoint!.getDevObject("empcode_dev")
		dim empcode$:callpoint!.getDevObject("empcode_tpl")
		findrecord(empcode_dev,key=firm_id$+callpoint!.getColumnData("SFE_TIMEEMPL.EMPLOYEE_NO"),dom=*next)empcode$
		callpoint!.setDevObject("normal_title",empcode.normal_title$)
		callpoint!.setDevObject("hrlysalary",empcode.hrlysalary$)
	endif
[[SFE_TIMEEMPL.TRANS_DATE.BINP]]
rem --- Initialize trans_date
	if cvs(callpoint!.getColumnData("SFE_TIMEEMPL.TRANS_DATE"),2)="" then 
		callpoint!.setColumnData("SFE_TIMEEMPL.TRANS_DATE",stbl("+SYSTEM_DATE"),1)
	endif
[[SFE_TIMEEMPL.TRANS_DATE.AVAL]]
rem --- Validate trans_date
	if cvs(callpoint!.getUserInput(),2)="" then callpoint!.setUserInput(stbl("+SYSTEM_DATE"))
	trans_date$=callpoint!.getUserInput()        
	if callpoint!.getDevObject("gl")="Y"
		call stbl("+DIR_PGM")+"glc_datecheck.aon",trans_date$,"Y",per$,yr$,status
		if status>99 then callpoint!.setStatus("ABORT")
	endif
[[SFE_TIMEEMPL.BEND]]
rem --- Remove software lock on batch when batching
	batch$=stbl("+BATCH_NO",err=*next)
	if num(batch$)<>0
		lock_table$="ADM_PROCBATCHES"
		lock_record$=firm_id$+stbl("+PROCESS_ID")+batch$
		lock_type$="X"
		lock_status$=""
		lock_disp$=""
		call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$
	endif
[[SFE_TIMEEMPL.<CUSTOM>]]
#include std_missing_params.src



[[SFE_TIMEEMPL.BTBL]]
rem --- Get Batch information
	call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]
	callpoint!.setTableColumnAttribute("SFE_TIMEEMPL.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)

rem --- Open Files
	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="IVS_PARAMS",open_opts$[2]="OTA"
	open_tables$[3]="SFE_WOMASTR",open_opts$[3]="OTA"
	open_tables$[4]="SFE_WOOPRTN",open_opts$[4]="OTA"
	open_tables$[5]="IVM_ITEMMAST",open_opts$[5]="OTA"

	gosub open_tables

	sfs_params_dev=num(open_chans$[1]),sfs_params_tpl$=open_tpls$[1]
	ivs_params_dev=num(open_chans$[2]),ivs_params_tpl$=open_tpls$[2]
	callpoint!.setDevObject("sfe_womastr_dev",num(open_chans$[3]))
	callpoint!.setDevObject("sfe_womastr_tpl",open_tpls$[3])
	callpoint!.setDevObject("sfe_wooprtn_dev",num(open_chans$[4]))
	callpoint!.setDevObject("sfe_wooprtn_tpl",open_tpls$[4])
	callpoint!.setDevObject("ivm_itemmast_dev",num(open_chans$[5]))
	callpoint!.setDevObject("ivm_itemmast_tpl",open_tpls$[5])

rem --- Get SF parameters
	dim sfs_params$:sfs_params_tpl$
	read record (sfs_params_dev,key=firm_id$+"SF00",dom=std_missing_params) sfs_params$
	bm$=sfs_params.bm_interface$
	pr$=sfs_params.pr_interface$
	gl$=sfs_params.post_to_gl$
	pay_actstd$=sfs_params.pay_actstd$
	callpoint!.setDevObject("pay_actstd",pay_actstd$)
	time_clk_flg$=sfs_params.time_clk_flg$
	callpoint!.setDevObject("time_clk_flg",time_clk_flg$)

	call stbl("+DIR_PGM")+"adc_getmask.aon","","SF","U","",unit_mask$,0,0
	callpoint!.setDevObject("unit_mask",unit_mask$)

	if bm$="Y"
		call stbl("+DIR_PGM")+"adc_application.aon","BM",info$[all]
		bm$=info$[20]
	endif
	callpoint!.setDevObject("bm",bm$)

	if gl$="Y"
		gl$="N"
		status=0
		source$=pgm(-2)
		call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"SF",glw11$,gl$,status
		if status<>0 goto std_exit
	endif
	callpoint!.setDevObject("gl",gl$)

	if pr$="Y"
		call stbl("+DIR_PGM")+"adc_application.aon","PR",info$[all]
		pr$=info$[20]
	endif
	callpoint!.setDevObject("pr",pr$)

rem --- Get IV parameters
	dim ivs_params$:ivs_params_tpl$
	read record (ivs_params_dev,key=firm_id$+"IV00",dom=std_missing_params) ivs_params$
	callpoint!.setDevObject("item_desc_len_01",num(ivs_params.desc_len_01$))
	precision$=ivs_params.precision$
	callpoint!.setDevObject("precision",precision$)
	precision num(precision$)

rem --- Additional file opens
	num_files=9
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	if gl$="Y" then
		open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
	endif
	if pr$="Y" then
		open_tables$[2]="PRS_PARAMS",open_opts$[2]="OTA"
		open_tables$[3]="PRM_EMPLMAST",open_opts$[3]="OTA"
		open_tables$[5]="PRC_PAYCODE",open_opts$[5]="OTA"
		open_tables$[6]="PRC_TITLCODE",open_opts$[6]="OTA"
		open_tables$[7]="PRT_EMPLEARN",open_opts$[7]="OTA"
		if pay_actstd$="A" then open_tables$[8]="PRM_EMPLPAY",open_opts$[8]="OTA"
	else
		open_tables$[3]="SFM_EMPLMAST",open_opts$[3]="OTA"
		open_tables$[4]="SFX_EMPLXREF",open_opts$[4]="OTA"
	endif
	if bm$="Y" then
		open_tables$[9]="BMC_OPCODES",open_opts$[9]="OTA"
	else
		open_tables$[9]="SFC_OPRTNCOD",open_opts$[9]="OTA"
	endif

	gosub open_tables

	current_year$=""
	if gl$="Y" then
		gls_params_dev=num(open_chans$[1])
		dim gls_params$:open_tpls$[1]
		find record (gls_params_dev,key=firm_id$+"GL00",dom=std_missing_params) gls_params$
		current_year$=gls_params.current_year$
	endif
	callpoint!.setDevObject("current_year",current_year$)

	if pr$="Y" then
		prs_params_dev=num(open_chans$[2])
		dim prs_params$:open_tpls$[2]
		find record (prs_params_dev,key=firm_id$+"PR00",dom=std_missing_params) prs_params$
		callpoint!.setDevObject("reg_pay_code",prs_params.reg_pay_code$)
		precision$=prs_params.precision$
		callpoint!.setDevObject("precision",precision$)
		precision num(precision$)
	endif

	callpoint!.setDevObject("empcode_dev",num(open_chans$[3]))
	callpoint!.setDevObject("empcode_tpl",open_tpls$[3])
	callpoint!.setDevObject("empxref_dev",num(open_chans$[4]))
	callpoint!.setDevObject("empxref_tpl",open_tpls$[4])
	callpoint!.setDevObject("paycode_dev",num(open_chans$[5]))
	callpoint!.setDevObject("paycode_tpl",open_tpls$[5])
	callpoint!.setDevObject("titlcode_dev",num(open_chans$[6]))
	callpoint!.setDevObject("titlcode_tpl",open_tpls$[6])
	callpoint!.setDevObject("emplearn_dev",num(open_chans$[7]))
	callpoint!.setDevObject("emplearn_tpl",open_tpls$[7])
	if pay_actstd$="A" then 
		callpoint!.setDevObject("emplpay_dev",num(open_chans$[8]))
		callpoint!.setDevObject("emplpay_tpl",open_tpls$[8])
	endif
	callpoint!.setDevObject("opcode_dev",num(open_chans$[9]))
	callpoint!.setDevObject("opcode_tpl",open_tpls$[9])

rem --- Validate employee_no with SFM_EMPLMAST instead of PRM_EMPLMAST when PR not installed
	if pr$="Y" then callpoint!.setTableColumnAttribute("SFE_TIMEEMPL.EMPLOYEE_NO","DTAB","PRM_EMPLMAST")
