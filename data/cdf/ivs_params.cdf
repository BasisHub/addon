[[IVS_PARAMS.CURRENT_YEAR.AVAL]]
rem --- Verify calendar exists for entered IV fiscal year
	year$=callpoint!.getUserInput()
	if cvs(year$,2)<>"" and year$<>callpoint!.getColumnData("IVS_PARAMS.CURRENT_YEAR") then
		gls_calendar_dev=fnget_dev("GLS_CALENDAR")
		dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
		readrecord(gls_calendar_dev,key=firm_id$+year$,dom=*next)gls_calendar$
		if cvs(gls_calendar.year$,2)="" then
			msg_id$="AD_NO_FISCAL_CAL"
			dim msg_tokens$[1]
			msg_tokens$[1]=year$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
		callpoint!.setDevObject("total_pers",gls_calendar.total_pers$)
	endif
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
rem --- Verify haven't exceeded calendar total periods for current IV fiscal year
	period$=callpoint!.getUserInput()
	if cvs(period$,2)<>"" and period$<>callpoint!.getColumnData("IVS_PARAMS.CURRENT_PER") then
		period=num(period$)
		total_pers=num(callpoint!.getDevObject("total_pers"))
		if period<1 or period>total_pers then
			msg_id$="AD_BAD_FISCAL_PERIOD"
			dim msg_tokens$[2]
			msg_tokens$[1]=str(total_pers)
			msg_tokens$[2]=callpoint!.getColumnData("IVS_PARAMS.CURRENT_YEAR")
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
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

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="GLS_CALENDAR",open_opts$[2]="OTA"

	gosub open_tables

rem --- Setup user template

	dim user_tpl$:"old_cost_method:c(1)"

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

rem --- Retrieve parameter data
	gl_installed$=callpoint!.getDevObject("gl_installed")
	ivs01_dev=fnget_dev("IVS_PARAMS")
	dim ivs01a$:fnget_tpl$("IVS_PARAMS")
	ivs01a_key$=firm_id$+"IV00"
	find record (ivs01_dev,key=ivs01a_key$,err=*next) ivs01a$
	if cvs(ivs01a.current_per$,2)=""
		gls01_dev=fnget_dev("GLS_PARAMS")
		dim gls01a$:fnget_tpl$("GLS_PARAMS")
		gls01a_key$=firm_id$+"GL00"
		find record (gls01_dev,key=gls01a_key$,err=*next) gls01a$
		callpoint!.setColumnData("IVS_PARAMS.CURRENT_PER",gls01a.current_per$)
		callpoint!.setColumnUndoData("IVS_PARAMS.CURRENT_PER",gls01a.current_per$)
		callpoint!.setColumnData("IVS_PARAMS.CURRENT_YEAR",gls01a.current_year$)
		callpoint!.setColumnUndoData("IVS_PARAMS.CURRENT_YEAR",gls01a.current_year$)
		if gl_installed$="Y" then
			callpoint!.setColumnData("IVS_PARAMS.POST_TO_GL","Y")
		endif
   		callpoint!.setStatus("MODIFIED-REFRESH")
	else
		rem --- Update post_to_gl if GL is uninstalled
		if gl_installed$<>"Y" and callpoint!.getColumnData("IVS_PARAMS.POST_TO_GL")="Y" then 
			callpoint!.setColumnData("IVS_PARAMS.POST_TO_GL","N",1)
   			callpoint!.setStatus("MODIFIED")
		endif
	endif

rem --- Set maximum number of periods allowed for this fiscal year
	gls_calendar_dev=fnget_dev("GLS_CALENDAR")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
	current_year$=callpoint!.getColumnData("IVS_PARAMS.CURRENT_YEAR")
	readrecord(gls_calendar_dev,key=firm_id$+current_year$,dom=*next)gls_calendar$
	callpoint!.setDevObject("total_pers",gls_calendar.total_pers$)
