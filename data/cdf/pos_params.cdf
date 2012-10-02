[[POS_PARAMS.ARAR]]
rem --- Update post_to_gl if GL is uninstalled
	gl_installed$=callpoint!.getDevObject("gl_installed")
	if gl_installed$<>"Y" and callpoint!.getColumnData("POS_PARAMS.POST_TO_GL")="Y" then
		callpoint!.setColumnData("POS_PARAMS.POST_TO_GL","N",1)
		callpoint!.setStatus("MODIFIED")
	endif
[[POS_PARAMS.AREC]]
rem --- Init new record
	gl_installed$=callpoint!.getDevObject("gl_installed")
	if gl_installed$="Y" then callpoint!.setColumnData("POS_PARAMS.POST_TO_GL","Y")
[[POS_PARAMS.BSHO]]
rem --- Disable update planned Work Orders if Shop Floor not installed
pgm_dir$=stbl("+DIR_PGM")
call pgm_dir$+"adc_application.aon","SF",info$[all]
if info$[20]<>"Y"
	ctl_name$="POS_PARAMS.UPDT_PLAN_WO"
	ctl_stat$="D"
	gosub disable_fields
endif

rem --- Disable post_to_gl if GL not installed
call pgm_dir$+"adc_application.aon","GL",info$[all]
gl_installed$=info$[20]
callpoint!.setDevObject("gl_installed",gl_installed$)
if gl_installed$<>"Y" then callpoint!.setColumnEnabled("POS_PARAMS.POST_TO_GL",-1)
[[POS_PARAMS.PO_INV_CODE.AVAL]]
tmp_po_line_code$=callpoint!.getUserInput()
gosub validate_po_line_type
if pom02a.line_type$<>"O" then callpoint!.setStatus("ABORT")
[[POS_PARAMS.REQ_M_LINECD.AVAL]]
tmp_po_line_code$=callpoint!.getUserInput()
gosub validate_po_line_type
if pom02a.line_type$<>"M" then callpoint!.setStatus("ABORT")
[[POS_PARAMS.REQ_N_LINECD.AVAL]]
tmp_po_line_code$=callpoint!.getUserInput()
gosub validate_po_line_type
if pom02a.line_type$<>"N" then callpoint!.setStatus("ABORT")
[[POS_PARAMS.REQ_S_LINECD.AVAL]]
tmp_po_line_code$=callpoint!.getUserInput()
gosub validate_po_line_type
if pom02a.line_type$<>"S" then callpoint!.setStatus("ABORT")
[[POS_PARAMS.LAND_METHOD.AVAL]]
dummy$=callpoint!.getUserInput()
if pos(dummy$="CQN")=0 then callpoint!.setStatus("ABORT-REFRESH")
[[POS_PARAMS.<CUSTOM>]]
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

validate_po_line_type:
	pom02_dev=fnget_dev("POC_LINECODE")
	dim pom02a$:fnget_tpl$("POC_LINECODE")
	pom02a.firm_id$=callpoint!.getColumnData("POS_PARAMS.FIRM_ID")
	pom02a.po_line_code$=tmp_po_line_code$
	read record (pom02_dev,key=pom02a.firm_id$+pom02a.po_line_code$,dom=*next)pom02a$
return
