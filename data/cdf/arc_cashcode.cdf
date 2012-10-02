[[ARC_CASHCODE.BSHO]]
pgm_dir$=stbl("+DIR_PGM")

rem --- Disable Pos Cash Type if OP not installed
call pgm_dir$+"adc_application.aon","OP",info$[all]
if info$[20] = "N"
	ctl_name$="ARC_CASHCODE.TRANS_TYPE"
	ctl_stat$="I"
	gosub disable_fields
endif

rem --- Disable G/L Accounts if G/L not installed
call pgm_dir$+"adc_application.aon","GL",info$[all]
if info$[20] = "N"
	ctl_name$="ARC_CASHCODE.GL_CASH_ACCT"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="ARC_CASHCODE.GL_DISC_ACCT"
	ctl_stat$="I"
	gosub disable_fields
endif
[[ARC_CASHCODE.<CUSTOM>]]
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
