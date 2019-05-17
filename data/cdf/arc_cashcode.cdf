[[ARC_CASHCODE.AREC]]
rem --- disable gateway config option
	callpoint!.setOptionEnabled("GTWY",0)
[[ARC_CASHCODE.AOPT-GTWY]]
rem --- launch config form for selected gateway

	gateway$=callpoint!.getColumnData("ARS_CC_CUSTSVC.GATEWAY_ID")

	dim dflt_data$[1,1]
	dflt_data$[0,0]="FIRM_ID"
	dflt_data$[0,1]=firm_id$
	dflt_data$[1,0]="GATEWAY_ID"
	dflt_data$[1,1]=gateway$

	key_pfx$=firm_id$+gateway$

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"ARS_GATEWAYHDR",
:		stbl("+USER_ID"),
:		"",
:		key_pfx$,
:		table_chans$[all],
:		"",
:		dflt_data$[all]
[[ARS_CC_CUSTSVC.INTERFACE_TP.AVAL]]
rem --- populate list of supported gateways based on the interface type

	interface_tp$=callpoint!.getUserInput()
	column$="ARS_CC_CUSTSVC.GATEWAY_ID"
	gosub get_gateways
[[ARC_CASHCODE.ADIS]]
rem --- if accepting credit card payments for this rec code, populate list of supported gateways based on the interface type

	if callpoint!.getColumnData("ARS_CC_CUSTSVC.USE_CUSTSVC_CC")="Y"
		interface_tp$=callpoint!.getColumnData("ARS_CC_CUSTSVC.INTERFACE_TP")
		column$="ARS_CC_CUSTSVC.GATEWAY_ID"
		gosub get_gateways
		callpoint!.setOptionEnabled("GTWY",1)
		callpoint!.setStatus("REFRESH")
	else
		callpoint!.setOptionEnabled("GTWY",0)
	endif
[[ARC_CASHCODE.GL_DISC_ACCT.AVAL]]
gosub gl_inactive
[[ARC_CASHCODE.GL_CASH_ACCT.AVAL]]
gosub gl_inactive
[[ARC_CASHCODE.BSHO]]
rem --- use

	use ::ado_func.src::func

rem --- open tables

	num_files=4
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARS_GATEWAYHDR",open_opts$[1]="OTA"
	open_tables$[2]="ARS_PARAMS",open_opts$[2]="OTA"
	open_tables$[3]="ADM_PROCMASTER",open_opts$[3]="OTA"
	open_tables$[4]="ADM_PROCDETAIL",open_opts$[4]="OTA"
	gosub open_tables

	ars_params=num(open_chans$[2])
	adm_procmaster=num(open_chans$[3])
	adm_procdetail=num(open_chans$[4])

	dim ars_params$:open_tpls$[2]
	dim adm_procmaster$:open_tpls$[3]
	dim adm_procdetail$:open_tpls$[4]

rem --- enable/disable deposit description based on whether using bank rec or not
	read record(ars_params,key=firm_id$+"AR00",err=std_missing_params)ars_params$
	callpoint!.setColumnEnabled("ARS_CC_CUSTSVC.DEPOSIT_DESC",iff(ars_params.br_interface$="Y",1,-1))

rem --- get process_id for Cash Receipts to see if batching is turned on; enable/disable batch description accordingly
	proc_key_val$=firm_id$+pad("ARE_CASHHDR",len(adm_procdetail.dd_table_alias$))
	read record (adm_procdetail,key=proc_key_val$,knum="AO_TABLE_PROCESS",dom=*next)
	while 1
		k$=key(adm_procdetail,end=*break)
		if pos(proc_key_val$=k$)<>1 break
		readrecord(adm_procdetail,end=*break)adm_procdetail$
		proc_id$=adm_procdetail.process_id$
		break
	wend
	read record (adm_procmaster,key=firm_id$+proc_id$,dom=*next)adm_procmaster$
	callpoint!.setColumnEnabled("ARS_CC_CUSTSVC.BATCH_DESC",iff(adm_procmaster.batch_entry$="Y",1,-1))

rem --- Disable Pos Cash Type if OP not installed
	call stbl("+DIR_PGM")+"adc_application.aon","OP",info$[all]
	if info$[20] = "N"
		ctl_name$="ARC_CASHCODE.TRANS_TYPE"
		ctl_stat$="I"
		gosub disable_fields
	endif

rem --- Disable G/L Accounts if G/L not installed
	call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
	if info$[20] = "N"
		ctl_name$="ARC_CASHCODE.GL_CASH_ACCT"
		ctl_stat$="I"
		gosub disable_fields
		ctl_name$="ARC_CASHCODE.GL_DISC_ACCT"
		ctl_stat$="I"
		gosub disable_fields
	endif
[[ARC_CASHCODE.<CUSTOM>]]
#include std_functions.src
#include std_missing_params.src

rem ============================================================
get_gateways:rem --- load up listbutton with supported gateways for given or selected interface type
rem --- in: interface_tp$, column$ in ars_cc_custsvc to set list for
rem ============================================================

	ars_gatewayhdr=fnget_dev("ARS_GATEWAYHDR")
	dim ars_gatewayhdr$:fnget_tpl$("ARS_GATEWAYHDR")

	ldat$=""

	codeVect!=BBjAPI().makeVector()
	descVect!=BBjAPI().makeVector()

	read(ars_gatewayhdr,key=firm_id$,dom=*next)
	while 1
		readrecord(ars_gatewayhdr,end=*break)ars_gatewayhdr$
		if pos(firm_id$=ars_gatewayhdr$)<>1 then break
		if pos(ars_gatewayhdr.interface_tp$=interface_tp$+"B")
			codeVect!.add(ars_gatewayhdr.gateway_id$)
			descVect!.add(ars_gatewayhdr.description$)
		endif
	wend

	ldat$=func.buildListButtonList(descVect!,codeVect!)
	callpoint!.setTableColumnAttribute(column$,"LDAT",ldat$)
	c!=callpoint!.getControl(column$)
	c!.removeAllItems()
	c!.insertItems(0,descVect!)

	return

gl_inactive:
rem "GL INACTIVE FEATURE"
   glm01_dev=fnget_dev("GLM_ACCT")
   glm01_tpl$=fnget_tpl$("GLM_ACCT")
   dim glm01a$:glm01_tpl$
   glacctinput$=callpoint!.getUserInput()
   glm01a_key$=firm_id$+glacctinput$
   find record (glm01_dev,key=glm01a_key$,err=*return) glm01a$
   if glm01a.acct_inactive$="Y" then
      call stbl("+DIR_PGM")+"adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,gl_size
      msg_id$="GL_ACCT_INACTIVE"
      dim msg_tokens$[2]
      msg_tokens$[1]=fnmask$(glm01a.gl_account$(1,gl_size),m0$)
      msg_tokens$[2]=cvs(glm01a.gl_acct_desc$,2)
      gosub disp_message
      callpoint!.setStatus("ACTIVATE-ABORT")
   endif
return

disable_fields:
rem --- used to disable/enable controls depending on parameter settings
rem --- send in control to toggle (format "ALIAS.CONTROL_NAME"), and D or space to disable/enable
 
wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
wmap$=callpoint!.getAbleMap()
wpos=pos(wctl$=wmap$,8)
wmap$(wpos+6,1)=ctl_stat$
callpoint!.setAbleMap(wmap$)
callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")

return
