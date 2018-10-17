[[APR_CHECKS.CHECK_NO.AVAL]]
rem --- Warn if this check number has been previously used
	check_no$=callpoint!.getUserInput()
	aptCheckHistory_dev=fnget_dev("APT_CHECKHISTORY")
	dim aptCheckHistory$:fnget_tpl$("APT_CHECKHISTORY")
	ap_type$=pad(callpoint!.getColumnData("APR_CHECKS.AP_TYPE"),len(aptCheckHistory.ap_type$))

	next_ap_type$=ap_type$
	read(aptCheckHistory_dev,key=firm_id$+next_ap_type$+check_no$,dom=*next)
	while 1
		readrecord(aptCheckHistory_dev,end=*break)aptCheckHistory$
		if aptCheckHistory.firm_id$<>firm_id$ then break
		callpoint!.setDevObject("reuse_check_num","")		
		if aptCheckHistory.ap_type$+aptCheckHistory.check_no$=next_ap_type$+check_no$ then
			rem --- This check number was previously used
			msg_id$="AP_CHECK_NUM_USED"
			dim msg_tokens$[1]
			msg_tokens$[1]=check_no$
			gosub disp_message
			if msg_opt$="C" then
				callpoint!.setStatus("ABORT")
				callpoint!.setDevObject("reuse_check_num","N")
			else
				callpoint!.setDevObject("reuse_check_num","Y")		
			endif
		else
			rem --- Must check all AP Types when ap_type is blank/empty
			if cvs(ap_type$,2)="" then
				aptCheckHistory_key$=key(aptCheckHistory_dev,end=*break)
				if pos(firm_id$+next_ap_type$=aptCheckHistory_key$)=1 then
					rem --- Skip ahead to next ap_type
					read(aptCheckHistory_dev,key=firm_id$+aptCheckHistory.ap_type$+$FF$,dom=*next)
				endif
				readrecord(aptCheckHistory_dev,end=*break)aptCheckHistory$
				next_ap_type$=aptCheckHistory.ap_type$
				read(aptCheckHistory_dev,key=firm_id$+next_ap_type$+check_no$,dom=*continue)
			endif
		endif
		break
	wend
[[APR_CHECKS.ARER]]
rem --- Use default check form order if available
	default_form_order$=callpoint!.getDevObject("default_form_order")
	if cvs(default_form_order$,2)<>"" then
		formorderListButton!=callpoint!.getControl("APR_CHECKS.FORM_ORDER")
		formorderVector!=formorderListButton!.getAllItems()
		for i=0 to formorderVector!.size()-1
			if pos(default_form_order$=formorderVector!.getItem(i)) then
				formorderListButton!.selectIndex(i)
				break
			endif
		next i
	endif
[[APR_CHECKS.AREC]]

[[APR_CHECKS.VENDOR_ID.AVAL]]
rem "VENDOR INACTIVE - FEATURE"
vendor_id$ = callpoint!.getUserInput()
apm01_dev=fnget_dev("APM_VENDMAST")
apm01_tpl$=fnget_tpl$("APM_VENDMAST")
dim apm01a$:apm01_tpl$
apm01a_key$=firm_id$+vendor_id$
find record (apm01_dev,key=apm01a_key$,err=*break) apm01a$
if apm01a.vend_inactive$="Y" then
   call stbl("+DIR_PGM")+"adc_getmask.aon","VENDOR_ID","","","",m0$,0,vendor_size
   msg_id$="AP_VEND_INACTIVE"
   dim msg_tokens$[2]
   msg_tokens$[1]=fnmask$(apm01a.vendor_id$(1,vendor_size),m0$)
   msg_tokens$[2]=cvs(apm01a.vendor_name$,2)
   gosub disp_message
   callpoint!.setStatus("ACTIVATE")
endif

[[APR_CHECKS.VENDOR_ID.BINQ]]
rem --- Set filter_defs$[] to only show vendors of given AP Type

ap_type$=callpoint!.getColumnData("APR_CHECKS.AP_TYPE")

dim filter_defs$[2,2]
filter_defs$[0,0]="APM_VENDMAST.FIRM_ID"
filter_defs$[0,1]="='"+firm_id$+"'"
filter_defs$[0,2]="LOCK"

filter_defs$[1,0]="APM_VENDHIST.AP_TYPE"
filter_defs$[1,1]="='"+ap_type$+"'"
filter_defs$[1,2]="LOCK"


call STBL("+DIR_SYP")+"bax_query.bbj",
:		gui_dev, 
:		form!,
:		"AP_VEND_LK",
:		"DEFAULT",
:		table_chans$[all],
:		sel_key$,
:		filter_defs$[all]

if sel_key$<>""
	call stbl("+DIR_SYP")+"bac_key_template.bbj",
:		"APM_VENDMAST",
:		"PRIMARY",
:		apm_vend_key$,
:		table_chans$[all],
:		status$
	dim apm_vend_key$:apm_vend_key$
	apm_vend_key$=sel_key$
	callpoint!.setColumnData("APR_CHECKS.VENDOR_ID",apm_vend_key.vendor_id$,1)
endif	
callpoint!.setStatus("ACTIVATE-ABORT")
[[APR_CHECKS.ADIS]]
rem --- Clear Check Number when using previously saved selections.
	callpoint!.setColumnData("APR_CHECKS.CHECK_NO","",1)
[[APR_CHECKS.BEND]]
rem --- Make sure softlock is cleared when exiting/aborting
	adxlocks_dev=fnget_dev("ADX_LOCKS")
	dim adxlocks$:fnget_tpl$("ADX_LOCKS")
	menu_option_id$=pad(callpoint!.getTableAttribute("ALID"),len(adxlocks.menu_option_id$))

	remove (adxlocks_dev,key=firm_id$+menu_option_id$,dom=*next)
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
	num_files=3
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="ADX_LOCKS",   open_opts$[2]="OTA"
	open_tables$[3]="APT_CHECKHISTORY",open_opts$[3]="OTA"
	gosub open_tables

	aps01_dev=fnget_dev("APS_PARAMS")
	adxlocks_dev=fnget_dev("ADX_LOCKS")

	dim aps01a$:fnget_tpl$("APS_PARAMS")
	dim adxlocks$:fnget_tpl$("ADX_LOCKS")

rem --- Get parameters
	aps01_key$=firm_id$+"AP00"
	readrecord(aps01_dev,key=aps01_key$,dom=std_missing_params)aps01a$
	callpoint!.setDevObject("multi_types",aps01a.multi_types$)
	callpoint!.setDevObject("default_form_order",aps01a.form_order$)
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

rem --- Initializations
	callpoint!.setDevObject("reuse_check_num","")		
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
#include std_functions.src
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

rem --- Don't allow re-using an unwanted check number
if callpoint!.getDevObject("reuse_check_num")="N" then
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
