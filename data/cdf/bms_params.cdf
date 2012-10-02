[[BMS_PARAMS.ARAR]]
rem --- Update post_to_gl if GL is uninstalled
	gl_installed$=callpoint!.getDevObject("gl_installed")
	if gl_installed$<>"Y" and callpoint!.getColumnData("BMS_PARAMS.POST_TO_GL")="Y" then
		callpoint!.setColumnData("BMS_PARAMS.POST_TO_GL","N",1)
		callpoint!.setStatus("MODIFIED")
	endif
[[BMS_PARAMS.AREC]]
rem --- Init new record
	gl_installed$=callpoint!.getDevObject("gl_installed")
	if gl_installed$="Y"then callpoint!.setColumnData("BMS_PARAMS.POST_TO_GL","Y")
[[BMS_PARAMS.BSHO]]
rem --- init/parameters

	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
	gl_installed$=info$[20]
	callpoint!.setDevObject("gl_installed",gl_installed$)

	if gl_installed$<>"Y" then callpoint!.setColumnEnabled("BMS_PARAMS.POST_TO_GL",-1)
