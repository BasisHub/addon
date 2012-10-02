[[SFC_WOTYPECD.ARAR]]
rem --- Disable variance accounts

	stdact_flag$=callpoint!.getColumnData("SFC_WOTYPECD.STDACT_FLAG")
	gosub disable_accts
[[SFC_WOTYPECD.STDACT_FLAG.AVAL]]
rem --- Disable variance accounts

	stdact_flag$=callpoint!.getUserInput()
	gosub disable_accts
[[SFC_WOTYPECD.<CUSTOM>]]
rem =====================================================
disable_accts:
rem - std_flag$	input
rem =====================================================
rem --- Disable 4 G/L Accounts if posting at Actuals

	if stdact_flag$="A"
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_LAB_VAR",0)
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_MAT_VAR",0)
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_OVH_VAR",0)
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_SUB_VAR",0)
	else
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_LAB_VAR",1)
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_MAT_VAR",1)
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_OVH_VAR",1)
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_SUB_VAR",1)
	endif

	return
[[SFC_WOTYPECD.STDACT_FLAG.AINP]]
rem --- See if we need to set flag

	if callpoint!.getDevObject("cost_method")="S" and callpoint!.getColumnData("SFC_WOTYPECD.WO_CATEGORY")="I"
		callpoint!.setColumnData("SFC_WOTYPECD.STDACT_FLAG","S",1)
	endif
[[SFC_WOTYPECD.BSHO]]
rem --- Open files

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="IVS_PARAMS",open_opts$[2]="OTA"

	gosub open_tables
	gls01_dev=num(open_chans$[1])
	ivs01_dev=num(open_chans$[2])

rem --- Dimension string templates
	dim gls01a$:open_tpls$[1]
	dim ivs01$:open_tpls$[2]

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

	read record (ivs01_dev,key=firm_id$+"IV00")ivs01$
	callpoint!.setDevObject("cost_method",ivs01.cost_method$)

	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","BM",info$[all]
	callpoint!.setDevObject("gl",info$[20])
	if info$[20]<>"Y"
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_CLOSE_TO",-1)
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_DIR_LAB",-1)
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_LAB_VAR",-1)
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_MAT_VAR",-1)
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_OVH_LAB",-1)
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_OVH_VAR",-1)
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_PUR_ACCT",-1)
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_SUB_VAR",-1)
		callpoint!.setColumnEnabled("SFC_WOTYPECD.GL_WIP_ACCT",-1)
	endif
