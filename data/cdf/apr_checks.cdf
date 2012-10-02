[[APR_CHECKS.PICK_CHECK.AVAL]]
if callpoint!.getUserInput()="Y"
	if callpoint!.getDevObject("multi_types")<>"Y"
		ctl_name$="APR_CHECKS.AP_TYPE"
		ctl_stat$="D"
		gosub disable_fields
	else
		ctl_name$="APR_CHECKS.AP_TYPE"
		ctl_stat$=" "
		gosub disable_fields
endif
[[APR_CHECKS.BSHO]]
rem --- See if we need to disable AP Type
	files=1,begfile=1,endfile=files
	dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
	files$[1]="aps_params",ids$[1]="APS_PARAMS"; rem  aps-01
	call stbl("+DIR_PGM")+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                         ids$[all],templates$[all],channels[all],batch,status
	if status then
		remove_process_bar:
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
	 	release
	endif


	aps01_dev=channels[1]
rem --- Dimension string templates
	dim aps01a$:templates$[1]
rem --- Get parameters
	aps01_key$=firm_id$+"AP00"
	readrecord(aps01_dev,key=aps01_key$,dom=std_missing_params)aps01a$
	callpoint!.setDevObject("multi_types",aps01a.multi_types$)
	if aps01a.multi_types$ <> "Y" then
		ctl_name$="APR_CHECKS.AP_TYPE"
		ctl_stat$="I"
		gosub disable_fields
	endif
[[APR_CHECKS.<CUSTOM>]]
disable_fields:
rem --- used to disable/enable controls depending on parameter settings
rem --- send in control to toggle (format "ALIAS.CONTROL_NAME"), and D or space to disable/enable
	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP-REFRESH")
return
#include std_missing_params.src
[[APR_CHECKS.ASVA]]
rem --- Validate Check Number
if num(callpoint!.getColumnData("APR_CHECKS.CHECK_NO")) = 0 then
	msg_id$="ENTRY_INVALID"
	dim msg_tokens$[1]
	msg_tokens$[1]="Check Number"
	msg_opt$=""
	gosub disp_message
	callpoint!.setStatus("ABORT")
rem --- Set focus on the Check Number field
	ctlContext=num(callpoint!.getTableColumnAttribute("APR_CHECKS.CHECK_NO","CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute("APR_CHECKS.CHECK_NO","CTLI"))
	chk_no!=SysGUI!.getWindow(ctlContext).getControl(ctlID)
	chk_no!.focus()
endif
rem --- Validate Check Date
check_date$=callpoint!.getColumnData("APR_CHECKS.CHECK_DATE")
check_date=1
			
if cvs(check_date$,2)<>""
	check_date=0
	check_date=jul(num(check_date$(1,4)),num(check_date$(5,2)),num(check_date$(7,2)),err=*next)
endif
			
if len(cvs(check_date$,2))<>8 or check_date=0
	msg_id$="INVALID_DATE"
	dim msg_tokens$[1]
	msg_opt$=""
	gosub disp_message
	callpoint!.setStatus("ABORT")
rem --- Set focus on the Check Date field
	ctlContext=num(callpoint!.getTableColumnAttribute("APR_CHECKS.CHECK_DATE","CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute("APR_CHECKS.CHECK_DATE","CTLI"))
	chk_date!=SysGUI!.getWindow(ctlContext).getControl(ctlID)
	chk_date!.focus()
endif
rem --- validate Check Date
gl$="N"
status=0
source$=pgm(-2)
call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"AP",glw11$,gl$,status
call stbl("+DIR_PGM")+"glc_datecheck.aon",check_date$,"Y",per$,yr$,status
if status>100
	callpoint!.setStatus("ABORT")
rem --- Set focus on the Check Date field
	ctlContext=num(callpoint!.getTableColumnAttribute("APR_CHECKS.CHECK_DATE","CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute("APR_CHECKS.CHECK_DATE","CTLI"))
	chk_date!=SysGUI!.getWindow(ctlContext).getControl(ctlID)
	chk_date!.focus()
endif
