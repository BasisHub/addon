[[ARC_DISTCODE.BDEL]]
rem --- Check if code is used as a default code

	num_files = 1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARS_CUSTDFLT", open_opts$[1]="OTA"
	gosub open_tables
	ars_custdflt_dev = num(open_chans$[1])
	dim ars_rec$:open_tpls$[1]

	find record(ars_custdflt_dev,key=firm_id$+"D",dom=*next)ars_rec$
	if ars_rec.ar_dist_code$ = callpoint!.getColumnData("ARC_DISTCODE.AR_DIST_CODE") then
		callpoint!.setMessage("AR_DIST_CODE_IN_DFLT")
		callpoint!.setStatus("ABORT")
	endif
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
