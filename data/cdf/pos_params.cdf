[[POS_PARAMS.BSHO]]
rem --- Disable update planned Work Orders if Shop Floor not installed
pgm_dir$=stbl("+DIR_PGM")
call pgm_dir$+"adc_application.aon","SF",info$[all]
if info$[20]<>"Y"
	ctl_name$="POS_PARAMS.UPDT_PLAN_WO"
	ctl_stat$="D"
	gosub disable_fields
endif
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
[[POS_PARAMS.END_CMT_LINE.AVAL]]
dummy$=callpoint!.getColumnData("POS_PARAMS.DISPLAY_CMTS")
if dummy$="Y" then
	beg_cmt_line=num(callpoint!.getColumnData("POS_PARAMS.BEG_CMT_LINE"))
	dummy_end_line=num(callpoint!.getUserInput())
	if dummy_end_line<beg_cmt_line then callpoint!.setStatus("ABORT")
endif
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
[[POS_PARAMS.DISPLAY_CMTS.AVAL]]
rem "aval on cmt checks 
if callpoint!.getUserInput()="N"
	callpoint!.setColumnData("POS_PARAMS.BEG_CMT_LINE","0")
	callpoint!.setColumnData("POS_PARAMS.END_CMT_LINE","0")
	ctl_name$="POS_PARAMS.BEG_CMT_LINE"
	ctl_stat$="D"
	gosub disable_fields
	ctl_name$="POS_PARAMS.END_CMT_LINE"
	ctl_stat$="D"
	gosub disable_fields
else
	ctl_name$="POS_PARAMS.BEG_CMT_LINE"
	ctl_stat$=""
	gosub disable_fields
	ctl_name$="POS_PARAMS.END_CMT_LINE"
	ctl_stat$=""
	gosub disable_fields
endif
