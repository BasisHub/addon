[[BMS_PARAMS.ADIS]]
rem - don't use gl accounts if GL not installed

			
			if callpoint!.getDevObject("gl_installed")<>"Y"  then
				callpoint!.setColumnData("BMS_PARAMS.GL_WIP_ACCT","")
				callpoint!.setColumnData("BMS_PARAMS.GL_PUR_ACCT","")
				callpoint!.setColumnData("BMS_PARAMS.GL_PRD_VAR","")
				
				ctl_stat$="D"

				ctl_name$="BMS_PARAMS.GL_WIP_ACCT"
				gosub disable_fields

				ctl_name$="BMS_PARAMS.GL_PUR_ACCT"
				gosub disable_fields

				ctl_name$="GL_PRD_VAR"
				gosub disable_fields
			else

				ctl_stat$=""

				ctl_name$="BMS_PARAMS.GL_WIP_ACCT"
				gosub disable_fields

				ctl_name$="BMS_PARAMS.GL_PUR_ACCT"
				gosub disable_fields

				ctl_name$="GL_PRD_VAR"
				gosub disable_fields

			endif
[[BMS_PARAMS.BSHO]]
rem --- init/parameters

			dim info$[20]
			
			call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
			gl$=info$[20]
			callpoint!.setDevObject("gl_installed",gl$)
[[BMS_PARAMS.<CUSTOM>]]
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
