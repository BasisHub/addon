[[GLM_AUDITCONTROL.<CUSTOM>]]
rem #include disable_fields.src

disable_fields:
	rem --- used to disable/enable controls
	rem --- ctl_name$ sent in with name of control to enable/disable (format "ALIAS.CONTROL_NAME")
	rem --- ctl_stat$ sent in as D or space, meaning disable/enable, respectively

	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")

return

rem #endinclude disable_fields.src
[[GLM_AUDITCONTROL.ARAR]]
ctl_name$="GLM_AUDITCONTROL.GL_POST_MEMO"
ctl_stat$=" "

gosub disable_fields

rem --- for reasons I don't understand, this field, tho' not marked display only, would not wake up;
rem --- so am doing it forcibly here.

callpoint!.setColumnData("<<DISPLAY>>.DISP_AUDIT_NUM",callpoint!.getColumnData("GLM_AUDITCONTROL.AUDIT_NUMBER"))
