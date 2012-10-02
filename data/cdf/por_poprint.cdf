[[POR_POPRINT.VENDOR_ID.AVAL]]
if num(callpoint!.getUserInput())<>0
	callpoint!.setColumnData("POR_POPRINT.RESTART","Y")
	else
	callpoint!.setColumnData("POR_POPRINT.RESTART","N")
endif

callpoint!.setStatus("REFRESH")
[[POR_POPRINT.REPORT_TYPE.AVAL]]
if callpoint!.getUserInput()="V"
	ctl_name$="POR_POPRINT.VENDOR_ID"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="POR_POPRINT.RESTART"
	gosub disable_fields
else
	ctl_name$="POR_POPRINT.VENDOR_ID"
	ctl_stat$="D"
	gosub disable_fields
	ctl_name$="POR_POPRINT.RESTART"
	gosub disable_fields
endif
[[POR_POPRINT.BSHO]]
if callpoint!.getColumnData("POR_POPRINT.RESTART")<>"Y"
	ctl_name$="POR_POPRINT.RESTART"
	ctl_stat$="D"	
	gosub disable_fields
	ctl_name$="POR_POPRINT.VENDOR_ID"
	gosub disable_fields
endif

callpoint!.setStatus("REFRESH")
[[POR_POPRINT.ARAR]]
rem --- set defaults

callpoint!.setColumnData("POR_POPRINT.REPORT_TYPE","N")
callpoint!.setColumnData("POR_POPRINT.RESTART","N")
callpoint!.setColumnData("POR_POPRINT.MESSAGE_TEXT","")
callpoint!.setColumnData("POR_POPRINT.VENDOR_ID","")

callpoint!.setStatus("REFRESH")
[[POR_POPRINT.RESTART.AVAL]]
if callpoint!.getUserInput()="Y"
	ctl_name$="POR_POPRINT.VENDOR_ID"
	ctl_stat$="I"
	gosub disable_fields
else
	ctl_name$="POR_POPRINT.VENDOR_ID"
	ctl_stat$="D"
	gosub disable_fields
endif
[[POR_POPRINT.<CUSTOM>]]
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
