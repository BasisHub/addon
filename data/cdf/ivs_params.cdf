[[IVS_PARAMS.ASVA]]
rem --- Validate Description Lengths

	desc1=num(callpoint!.getColumnData("IVS_PARAMS.DESC_LEN_01"))
	desc2=num(callpoint!.getColumnData("IVS_PARAMS.DESC_LEN_02"))
	desc3=num(callpoint!.getColumnData("IVS_PARAMS.DESC_LEN_03"))
	tot_len$=callpoint!.getTableColumnAttribute("IVS_PARAMS.DESC_LEN_01","MAXV")

	if desc1+desc2+desc3>num(tot_len$)
		msg_id$="IV_DESC_TOO_LONG"
		dim msg_tokens$[1]
		msg_tokens$[0]=tot_len$
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif

	if desc3<>0 and desc2=0
		msg_id$="IV_DESC3_NODESC2"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif

	if desc1=0
		msg_id$="INPUT_ERR_VALUE"
		dim msg_tokens$[1]
		msg_tokens$[0]=callpoint!.getTableColumnAttribute("IVS_PARAMS.DESC_LEN_01","DESC")
		msg_tokens$[1]="1-"+tot_len$
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[IVS_PARAMS.AREC]]
rem --- Init new record
	gl_installed$=callpoint!.getDevObject("gl_installed")
	if gl_installed$="Y" then callpoint!.setColumnData("IVS_PARAMS.POST_TO_GL","Y")
[[IVS_PARAMS.CURRENT_PER.AVAL]]
rem --- Validate period is valid
	cur_per=num(callpoint!.getUserInput())
	dim gls01a$:user_tpl.gls01_tpl$
	readrecord(user_tpl.gls01_dev,key=firm_id$+"GL00")gls01a$
	if cur_per>num(gls01a.total_pers$)
		msg_id$="INVALID_PERIOD"
		dim msg_tokens$[1]
		gosub disp_message
		callpoint!.setStatus("ABORT-REFRESH")
	endif
[[IVS_PARAMS.COST_METHOD.AVAL]]
rem --- Display message if costing method has changed

	if user_tpl.old_cost_method$<>""
		if user_tpl.old_cost_method$<>callpoint!.getUserInput()
			msg_id$="REBUILD_COSTS"	
			dim msg_tokens$[1]
			gosub disp_message
			user_tpl.old_cost_method$=callpoint!.getUserInput(); rem display message only once
		endif
	endif
[[IVS_PARAMS.BSHO]]
rem --- Open/Lock files
			
	num_files=1
	dim files$[num_files],options$[num_files],ids$[num_files],templates$[num_files],channels[num_files]
	files$[1]="gls_params",ids$[1]="GLS_PARAMS",options$[1]="OTA"
	call stbl("+DIR_PGM")+"adc_fileopen.aon",action,1,num_files,files$[all],options$[all],
:                              ids$[all],templates$[all],channels[all],batch,status
	if status then
		remove_process_bar:
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
	 	release
	endif

	gls01_dev=channels[1]

rem --- Setup user template

	dim user_tpl$:"old_cost_method:c(1),gls01_dev:n(4),gls01_tpl:c(2048)"
	user_tpl.gls01_dev=gls01_dev
	user_tpl.gls01_tpl$=templates$[1]

rem --- init/parameters

	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
	gl_installed$=info$[20]
	callpoint!.setDevObject("gl_installed",gl_installed$)

	if gl_installed$<>"Y" then callpoint!.setColumnEnabled("IVS_PARAMS.POST_TO_GL",-1)
[[IVS_PARAMS.ARAR]]
rem --- Set old costing method

	if user_tpl.old_cost_method$<>""
		user_tpl.old_cost_method$=callpoint!.getColumnData("IVS_PARAMS.COST_METHOD")
	endif

rem --- Update post_to_gl if GL is uninstalled
	gl_installed$=callpoint!.getDevObject("gl_installed")
	if gl_installed$<>"Y" and callpoint!.getColumnData("IVS_PARAMS.POST_TO_GL")="Y" then
		callpoint!.setColumnData("IVS_PARAMS.POST_TO_GL","N",1)
		callpoint!.setStatus("MODIFIED")
	endif
