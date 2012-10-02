[[OPE_INVSTATION.BSHO]]
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
			callpoint!.setTableColumnAttribute("OPE_INVSTATION.DEF_STATION", "DFLT", userdefault_rec.default_station$)
			no_user = 0
		endif
	endif

	if start_block then
		find record (params_dev, key=firm_id$+"AR00", dom=*endif) params_rec$

		if cvs(params_rec.default_station$, 2) <> "" then
			callpoint!.setTableColumnAttribute("OPE_INVSTATION.DEF_STATION", "DFLT", params_rec.default_station$)
		endif
	endif
[[OPE_INVSTATION.BEND]]
rem --- Set value into an STBL so calling program can access it

	ignore$ = stbl("OPE_DEF_STATION", callpoint!.getColumnData("OPE_INVSTATION.DEF_STATION"))
	release
