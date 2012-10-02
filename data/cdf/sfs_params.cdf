[[SFS_PARAMS.ADIS]]
rem --- Save changes made based on Applications installed

	callpoint!.setStatus("SAVE")
[[SFS_PARAMS.ARAR]]
rem --- Set defaults

	gosub set_defaults
[[SFS_PARAMS.ARER]]
rem --- Set defaults

	gosub set_defaults
[[SFS_PARAMS.<CUSTOM>]]
rem ==========================================================
set_defaults:
rem ==========================================================

	if callpoint!.getDevObject("bm")<>"Y"
		callpoint!.setColumnData("SFS_PARAMS.BM_INTERFACE","N",1)
		callpoint!.setColumnEnabled("SFS_PARAMS.BM_INTERFACE",0)
	endif
	if callpoint!.getDevObject("ap")<>"Y"
		callpoint!.setColumnData("SFS_PARAMS.AR_INTERFACE","N",1)
		callpoint!.setColumnEnabled("SFS_PARAMS.AR_INTERFACE",0)
	endif
	if callpoint!.getDevObject("po")<>"Y"
		callpoint!.setColumnData("SFS_PARAMS.PO_INTERFACE","N",1)
		callpoint!.setColumnEnabled("SFS_PARAMS.PO_INTERFACE",0)
	endif

rem Force Payroll to not be installed until Basis generates a Payroll Application
	callpoint!.setDevObject("pr","N")
	if callpoint!.getDevObject("pr")<>"Y"
		callpoint!.setColumnData("SFS_PARAMS.PR_INTERFACE","N",1)
		callpoint!.setColumnEnabled("SFS_PARAMS.PR_INTERFACE",0)
		callpoint!.setColumnData("SFS_PARAMS.PAY_ACTSTD","S",1)
		callpoint!.setColumnEnabled("SFS_PARAMS.PAY_ACTSTD",0)
		callpoint!.setColumnData("SFS_PARAMS.OVERHD_TYPE","",1)
		callpoint!.setColumnEnabled("SFS_PARAMS.OVERHD_TYPE",0)
	endif

	callpoint!.setColumnData("SFS_PARAMS.MAX_EMPL_NO","9")

	return
[[SFS_PARAMS.TIME_ENTRY_S.AVAL]]
rem --- Validate Time Entry table is empty if value changes

	old_setting$=callpoint!.getColumnUndoData("SFS_PARAMS.TIME_ENTRY_S")
	if old_setting$="D"
		old_chan=fnget_dev("SFE_TIMEDATE")
	endif
	if old_setting$="E"
		old_chan=fnget_dev("SFE_TIMEEMPL")
	endif
	if old_setting$="W"
		old_chan=fnget_dev("SFE_TIMEWO")
	endif

	read(old_chan,key=firm_id$,dom=*next)
	while 1
		k$=key(old_chan,end=*break)
		if pos(firm_id$=k$)<>1 break
		msg_id$="SF_BATCH_CHANGE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	wend
[[SFS_PARAMS.TIME_CLK_FLG.BINP]]
rem --- Set default if Time Sheet Entry set to 

	if pos(callpoint!.getColumnData("SFS_PARAMS.TIME_ENTRY_S")="DE") = 0
		callpoint!.setColumnData("SFS_PARAMS.TIME_CLK_FLG","N",1)
	endif
[[SFS_PARAMS.CURRENT_PER.AVAL]]
rem --- Validate Period is valid

	gl_pers=num(callpoint!.getDevObject("gl_pers"))
	if num(callpoint!.getUserInput())<1 or num(callpoint!.getUserInput())>gl_pers
		msg_id$="AR_INVALID_PER"
		dim msg_tokens$[1]
		msg_tokens$[1]=str(gl_pers)
		msg_opt$=""
		gosub disp_message
		callpoint!.setUserInput(callpoint!.getColumnUndoData("SFS_PARAMS.CURRENT_PER"))
		callpoint!.setStatus("REFRESH-ABORT")
	endif
[[SFS_PARAMS.BSHO]]
rem --- Open files

	num_files=4
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="SFE_TIMEDATE",open_opts$[2]="OTA"
	open_tables$[3]="SFE_TIMEEMPL",open_opts$[3]="OTA"
	open_tables$[4]="SFE_TIMEWO",open_opts$[4]="OTA"
	gosub open_tables
	gls01_dev=num(open_chans$[1])

rem --- Dimension string templates
	dim gls01a$:open_tpls$[1]

rem --- check to see if main GL param rec (firm/GL/00) exists; if not, tell user to set it up first
	gls01a_key$=firm_id$+"GL00"
	find record (gls01_dev,key=gls01a_key$,err=*next) gls01a$  
	if cvs(gls01a.current_per$,2)=""
		msg_id$="GL_PARAM_ERR"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		rem - remove process bar
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif

rem --- Retrieve parameter data

	callpoint!.setDevObject("gl_pers",gls01a.total_pers$)
	callpoint!.setDevObject("gl_curr_per",gls01a.current_per$)
	callpoint!.setDevObject("gl_curr_year",gls01a.current_year$)

	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","BM",info$[all]
	callpoint!.setDevObject("bm",info$[20])
	call stbl("+DIR_PGM")+"adc_application.aon","AP",info$[all]
	callpoint!.setDevObject("ap",info$[20])
	callpoint!.setDevObject("br",info$[9])
	call stbl("+DIR_PGM")+"adc_application.aon","PO",info$[all]
	callpoint!.setDevObject("po",info$[20])
	call stbl("+DIR_PGM")+"adc_application.aon","PR",info$[all]
	callpoint!.setDevObject("pr",info$[20])
