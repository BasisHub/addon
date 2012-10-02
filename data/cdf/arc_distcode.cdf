[[ARC_DISTCODE.AENA]]
pgm_dir$=stbl("+DIR_PGM")

rem --- Disable columns if PO system not installed
call pgm_dir$+"adc_application.aon","PO",info$[all]

if info$[20] = "N"
	ctl_name$="ARC_DISTCODE.GL_INV_ADJ"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="ARC_DISTCODE.GL_COGS_ADJ"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="ARC_DISTCODE.GL_PURC_ACCT"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="ARC_DISTCODE.GL_PPV_ACCT"
	ctl_stat$="I"
	gosub disable_fields
endif
[[ARC_DISTCODE.<CUSTOM>]]
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
