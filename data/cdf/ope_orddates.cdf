[[OPE_ORDDATES.BSHO]]
rem --- Open File(s)
	
	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ADM_USERDEFAULTS", open_opts$[1]="OTA"
	open_tables$[2]="ARS_PARAMS",       open_opts$[2]="OTA"

	gosub open_tables

	userdefault_dev = num(open_chans$[1])
	params_dev      = num(open_chans$[2])

	dim userdefault_rec$:open_tpls$[1]
	dim params_rec$:open_tpls$[2]
    
rem --- Set this user's or param's default POS station

	start_block = 1
	no_user     = 1
	
	if start_block then
		user$ = stbl("+USER_ID",err=*endif)
		find record (userdefault_dev, key=firm_id$+pad(user$, 16), dom=*endif) userdefault_rec$

		if cvs(userdefault_rec.default_station$, 2) <> "" then 
			callpoint!.setTableColumnAttribute("OPE_ORDDATES.DEF_STATION", "DFLT", userdefault_rec.default_station$)
			no_user = 0
		endif
	endif

	if start_block then
		find record (params_dev, key=firm_id$+"AR00", dom=*endif) params_rec$

		if cvs(params_rec.default_station$, 2) <> "" then
			callpoint!.setTableColumnAttribute("OPE_ORDDATES.DEF_STATION", "DFLT", params_rec.default_station$)
		endif
	endif
[[OPE_ORDDATES.BEND]]
rem --- Set values into STBLs

	ignore$ = stbl("OPE_DEF_SHIP",    callpoint!.getColumnData("OPE_ORDDATES.DEF_SHIP") )
	ignore$ = stbl("OPE_DEF_COMMIT",  callpoint!.getColumnData("OPE_ORDDATES.DEF_COMMIT") )
	ignore$ = stbl("OPE_DEF_STATION", callpoint!.getColumnData("OPE_ORDDATES.DEF_STATION") )

	release
[[OPE_ORDDATES.ARAR]]
rem --- Setup default dates

	ars01_dev = fnget_dev("ARS_PARAMS")
	dim ars01a$:fnget_tpl$("ARS_PARAMS")
	read record (ars01_dev,key=firm_id$+"AR00") ars01a$

	dim sysinfo$:stbl("+SYSINFO_TPL")
	sysinfo$=stbl("+SYSINFO")

	pgmdir$ = ""
	pgmdir$ = stbl("+DIR_PGM", err=*next)

	orddate$ = sysinfo.system_date$
	comdate$ = orddate$
	shpdate$ = orddate$

	comdays = num(ars01a.commit_days$)
	shpdays = num(ars01a.def_shp_days$)

	if comdays then call pgmdir$+"adc_daydates.aon", orddate$, comdate$, comdays
	if shpdays then call pgmdir$+"adc_daydates.aon", orddate$, shpdate$, shpdays

	callpoint!.setColumnData("OPE_ORDDATES.DEF_COMMIT", comdate$)
	callpoint!.setColumnData("OPE_ORDDATES.DEF_SHIP", shpdate$)
	callpoint!.setStatus("REFRESH")

	temp_stbl$ = stbl("OPE_DEF_SHIP", shpdate$)
	temp_stbl$ = stbl("OPE_DEF_COMMIT", comdate$)
