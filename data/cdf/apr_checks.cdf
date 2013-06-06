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
rem --- and see if a print run in currently running
	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="ADX_LOCKS",   open_opts$[2]="OTA"
	gosub open_tables

	aps01_dev=fnget_dev("APS_PARAMS")
	adxlocks_dev=fnget_dev("ADX_LOCKS")

	dim aps01a$:fnget_tpl$("APS_PARAMS")
	dim adxlocks$:fnget_tpl$("ADX_LOCKS")

rem --- Get parameters
	aps01_key$=firm_id$+"AP00"
	readrecord(aps01_dev,key=aps01_key$,dom=std_missing_params)aps01a$
	callpoint!.setDevObject("multi_types",aps01a.multi_types$)
	if aps01a.multi_types$ <> "Y" then
		ctl_name$="APR_CHECKS.AP_TYPE"
		ctl_stat$="I"
		gosub disable_fields
	endif

rem --- Abort if a check run is actively running
	pgm_name_fattr$=fattr(adxlocks$,"MENU_OPTION_ID")
	len_pgm_name_fattr=dec(pgm_name_fattr$(10,2))
	
	dim taskname$(len_pgm_name_fattr)
	taskname$(1)=callpoint!.getTableAttribute("ALID")

	while 1
		extract record(adxlocks_dev, key=firm_id$+taskname$, dom=*break)
		
		msg_id$="AP_CHKS_PRINTING"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		if pos("PASSVALID"=msg_opt$)=0
			callpoint!.setStatus("EXIT")		
		endif

		break
	wend
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
	msg_tokens$[1]=Translate!.getTranslation("AON_CHECK_NUMBER")
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

rem --- If all is well, write the softlock so only one jasper printing per firm can be run at a time
	currstatus$=callpoint!.getStatus()

	if len(cvs(currstatus$,2))=0
		menu_option_id$=callpoint!.getTableAttribute("ALID")

		adxlocks_dev=fnget_dev("ADX_LOCKS")
		dim adxlocks$:fnget_tpl$("ADX_LOCKS")

		adxlocks.firm_id$=firm_id$
		adxlocks.menu_option_id$=menu_option_id$

		extract record(adxlocks_dev,key=firm_id$+menu_option_id$,dom=*next)dummy$; rem Advisory Locking
		write record(adxlocks_dev)adxlocks$
	endif
