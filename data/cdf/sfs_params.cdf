[[SFS_PARAMS.CURRENT_YEAR.AVAL]]
rem --- Verify calendar exists for entered SF fiscal year
	year$=callpoint!.getUserInput()
	if cvs(year$,2)<>"" and year$<>callpoint!.getColumnData("SFS_PARAMS.CURRENT_YEAR") then
		gls_calendar_dev=fnget_dev("GLS_CALENDAR")
		dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
		readrecord(gls_calendar_dev,key=firm_id$+year$,dom=*next)gls_calendar$
		if cvs(gls_calendar.year$,2)="" then
			msg_id$="AD_NO_FISCAL_CAL"
			dim msg_tokens$[1]
			msg_tokens$[1]=year$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
		callpoint!.setDevObject("total_pers",gls_calendar.total_pers$)
	endif
[[SFS_PARAMS.PR_INTERFACE.AVAL]]
rem --- If Interface is turned on, enable Std/Act flag

	pr_inter$=callpoint!.getUserInput()
	if pr_inter$<>"Y"
		callpoint!.setColumnData("SFS_PARAMS.PAY_ACTSTD","S",1)
		callpoint!.setColumnEnabled("SFS_PARAMS.PAY_ACTSTD",0)
	else
		callpoint!.setColumnEnabled("SFS_PARAMS.PAY_ACTSTD",1)
	endif
[[SFS_PARAMS.AREC]]
rem --- Init new record
	gl_installed$=callpoint!.getDevObject("gl_installed")
	if gl_installed$="Y" then callpoint!.setColumnData("SFS_PARAMS.POST_TO_GL","Y")
[[SFS_PARAMS.ADIS]]
rem --- Save changes made based on Applications installed

	callpoint!.setStatus("SAVE")

rem --- Enable/disable fields

	gosub able_fields
[[SFS_PARAMS.ARAR]]
rem --- Retrieve parameter data
	gl_installed$=callpoint!.getDevObject("gl_installed")
	sfs01_dev=fnget_dev("SFS_PARAMS")
	dim sfs01a$:fnget_tpl$("SFS_PARAMS")
	sfs01a_key$=firm_id$+"SF00"
	find record (sfs01_dev,key=sfs01a_key$,err=*next) sfs01a$
	if cvs(sfs01a.current_per$,2)=""
		gls01_dev=fnget_dev("GLS_PARAMS")
		dim gls01a$:fnget_tpl$("GLS_PARAMS")
		gls01a_key$=firm_id$+"GL00"
		find record (gls01_dev,key=gls01a_key$,err=*next) gls01a$

		callpoint!.setColumnData("SFS_PARAMS.CURRENT_PER",gls01a.current_per$)
		callpoint!.setColumnUndoData("SFS_PARAMS.CURRENT_PER",gls01a.current_per$)
		callpoint!.setColumnData("SFS_PARAMS.CURRENT_YEAR",gls01a.current_year$)
		callpoint!.setColumnUndoData("SFS_PARAMS.CURRENT_YEAR",gls01a.current_year$)
		if gl_installed$="Y" then
			callpoint!.setColumnData("SFS_PARAMS.POST_TO_GL","Y")
		endif
   		callpoint!.setStatus("MODIFIED-REFRESH")
	else
		rem --- Update post_to_gl if GL is uninstalled
		if gl_installed$<>"Y" and callpoint!.getColumnData("SFS_PARAMS.POST_TO_GL")="Y" then 
			callpoint!.setColumnData("SFS_PARAMS.POST_TO_GL","N",1)
   			callpoint!.setStatus("MODIFIED")
		endif
	endif

rem --- Set maximum number of periods allowed for this fiscal year
	gls_calendar_dev=fnget_dev("GLS_CALENDAR")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
	current_year$=callpoint!.getColumnData("SFS_PARAMS.CURRENT_YEAR")
	readrecord(gls_calendar_dev,key=firm_id$+current_year$,dom=*next)gls_calendar$
	callpoint!.setDevObject("total_pers",gls_calendar.total_pers$)
[[SFS_PARAMS.ARER]]
rem --- Set defaults

	gosub set_defaults
[[SFS_PARAMS.<CUSTOM>]]
rem ==========================================================
able_fields:
rem ==========================================================

	if callpoint!.getDevObject("bm")<>"Y"
		callpoint!.setColumnData("SFS_PARAMS.BM_INTERFACE","N",1)
		callpoint!.setColumnEnabled("SFS_PARAMS.BM_INTERFACE",0)
	endif
	if callpoint!.getDevObject("ar")<>"Y"
		callpoint!.setColumnData("SFS_PARAMS.AR_INTERFACE","N",1)
		callpoint!.setColumnEnabled("SFS_PARAMS.AR_INTERFACE",0)
	endif
	if callpoint!.getDevObject("po")<>"Y"
		callpoint!.setColumnData("SFS_PARAMS.PO_INTERFACE","N",1)
		callpoint!.setColumnEnabled("SFS_PARAMS.PO_INTERFACE",0)
	endif

	if callpoint!.getDevObject("pr")<>"Y"
		callpoint!.setColumnData("SFS_PARAMS.PR_INTERFACE","N",1)
		callpoint!.setColumnEnabled("SFS_PARAMS.PR_INTERFACE",0)
		callpoint!.setColumnData("SFS_PARAMS.PAY_ACTSTD","S",1)
		callpoint!.setColumnEnabled("SFS_PARAMS.PAY_ACTSTD",0)
		callpoint!.setColumnData("SFS_PARAMS.OVERHD_TYPE","",1)
		callpoint!.setColumnEnabled("SFS_PARAMS.OVERHD_TYPE",0)
	endif

	return

rem ==========================================================
set_defaults:
rem ==========================================================

	gosub able_fields

	callpoint!.setColumnData("SFS_PARAMS.TIME_ENTRY_S","E",1)
	callpoint!.setColumnData("SFS_PARAMS.MAX_EMPL_NO","9")

	return
[[SFS_PARAMS.TIME_ENTRY_S.AVAL]]
rem --- Validate Time Entry table is empty if value changes

	old_setting$=callpoint!.getColumnUndoData("SFS_PARAMS.TIME_ENTRY_S")
	if old_setting$="D"
		old_chan=fnget_dev("SFE_TIMEDATE")
	endif
	if old_setting$="E"
		old_chan=fnget_dev("SFE_TIMEEMPL")
	endif
	if old_setting$="W"
		old_chan=fnget_dev("SFE_TIMEWO")
	endif

	if old_chan then
		read(old_chan,key=firm_id$,dom=*next)
		while 1
			k$=key(old_chan,end=*break)
			if pos(firm_id$=k$)<>1 break
			msg_id$="SF_BATCH_CHANGE"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		wend
	endif
[[SFS_PARAMS.TIME_CLK_FLG.BINP]]
rem --- Set default if Time Sheet Entry set to 

	if pos(callpoint!.getColumnData("SFS_PARAMS.TIME_ENTRY_S")="DE") = 0
		callpoint!.setColumnData("SFS_PARAMS.TIME_CLK_FLG","N",1)
	endif
[[SFS_PARAMS.CURRENT_PER.AVAL]]
rem --- Verify haven't exceeded calendar total periods for current AP fiscal year
	period$=callpoint!.getUserInput()
	if cvs(period$,2)<>"" and period$<>callpoint!.getColumnData("SFS_PARAMS.CURRENT_PER") then
		period=num(period$)
		total_pers=num(callpoint!.getDevObject("total_pers"))
		if period<1 or period>total_pers then
			msg_id$="AD_BAD_FISCAL_PERIOD"
			dim msg_tokens$[2]
			msg_tokens$[1]=str(total_pers)
			msg_tokens$[2]=callpoint!.getColumnData("SFS_PARAMS.CURRENT_YEAR")
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
	endif
[[SFS_PARAMS.BSHO]]
rem --- Open files

	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="SFE_TIMEDATE",open_opts$[2]="OTA"
	open_tables$[3]="SFE_TIMEEMPL",open_opts$[3]="OTA"
	open_tables$[4]="SFE_TIMEWO",open_opts$[4]="OTA"
	open_tables$[5]="GLS_CALENDAR",open_opts$[5]="OTA"

	gosub open_tables

rem --- Retrieve parameter data

	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","BM",info$[all]
	callpoint!.setDevObject("bm",info$[20])
	call stbl("+DIR_PGM")+"adc_application.aon","AR",info$[all]
	callpoint!.setDevObject("ar",info$[20])
	call stbl("+DIR_PGM")+"adc_application.aon","AP",info$[all]
	callpoint!.setDevObject("br",info$[9])
	call stbl("+DIR_PGM")+"adc_application.aon","PO",info$[all]
	callpoint!.setDevObject("po",info$[20])
	call stbl("+DIR_PGM")+"adc_application.aon","PR",info$[all]
	callpoint!.setDevObject("pr",info$[20])

	call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
	gl_installed$=info$[20]
	callpoint!.setDevObject("gl_installed",gl_installed$)

	if gl_installed$<>"Y" then callpoint!.setColumnEnabled("SFS_PARAMS.POST_TO_GL",-1)
