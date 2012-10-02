[[POS_PARAMS.HOLD_FLAG.AVAL]]
escape;rem "will this fire twice, too?
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
[[POS_PARAMS.AP_SHIP_VIA.AVAL]]
escape;rem "aval on ship via
if cvs(callpoint!.getUserInput(),3)="B"
	callpoint!.setColumnData("POS_PARAMS.BEG_CMT_LINE","0")
	callpoint!.setColumnData("POS_PARAMS.END_CMT_LINE","0")
	ctl_name$="POS_PARAMS.BEG_CMT_LINE"
	ctl_stat$="D"
	gosub disable_fields
	ctl_name$="POS_PARAMS.END_CMT_LINE"
	gosub disable_fields

endif
[[POS_PARAMS.DISPLAY_CMTS.AVAL]]
rem "escape;rem "aval on cmt checks -- why does this fire twice?
if callpoint!.getUserInput()="N"
	callpoint!.setColumnData("POS_PARAMS.BEG_CMT_LINE","0")
	callpoint!.setColumnData("POS_PARAMS.END_CMT_LINE","0")
	ctl_name$="POS_PARAMS.BEG_CMT_LINE"
	ctl_stat$="D"
	gosub disable_fields
	ctl_name$="POS_PARAMS.END_CMT_LINE"
	ctl_stat$="D"
	gosub disable_fields

endif
