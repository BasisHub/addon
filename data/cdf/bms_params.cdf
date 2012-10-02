[[BMS_PARAMS.BSHO]]
rem --- init/parameters

	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
	gl_installed$=info$[20]

	if gl_installed$="Y"
		call stbl("+DIR_PGM")+"adc_application.aon","IV",info$[all]
		gl_installed$=info$[9]
	endif

	if gl_installed$<>"Y"
		callpoint!.setColumnEnabled("BMS_PARAMS.GL_PRD_VAR",-1)
		callpoint!.setColumnEnabled("BMS_PARAMS.GL_PUR_ACCT",-1)
		callpoint!.setColumnEnabled("BMS_PARAMS.GL_WIP_ACCT",-1)
	endif

	callpoint!.setDevObject("gl_installed",gl_installed$)
