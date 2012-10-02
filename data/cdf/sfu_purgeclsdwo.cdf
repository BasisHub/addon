[[SFU_PURGECLSDWO.PURGE_DATE.AVAL]]
rem --- Purge date cannot be in current or previous period

rem --- Default year and period
	gls01_dev=fnget_dev("GLS_PARAMS")
	sfs01_dev=fnget_dev("SFS_PARAMS")
	
rem --- check to see if SF param rec exists; if not, tell user to set it up first
	dim sfs01a$:fnget_tpl$("SFS_PARAMS")
	read record(sfs01_dev,key=firm_id$+"SF00",err=*next) sfs01a$
	if cvs(sfs01a.current_per$,2)=""
		msg_id$="SF_PARAM_ERR"
		gosub disp_message
		
		rem - remove process bar
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif

rem --- check to see if GL param rec exists; if not, tell user to set it up first
	dim gls01a$:fnget_tpl$("GLS_PARAMS")
	read record(gls01_dev,key=firm_id$+"GL00",err=*next) gls01a$
	if cvs(gls01a.current_per$,2)=""
		msg_id$="GL_PARAM_ERR"
		gosub disp_message
		
		rem - remove process bar
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif

rem --- check that purge date is before prev SF period

	sf_year=num(sfs01a.current_year$)
	prev_sf_per=num(sfs01a.current_per$)-1
	if prev_sf_per=0 then 
		prev_sf_per=num(gls01a.total_pers$)
		sf_year=sf_year-1
	endif

	call stbl("+DIR_PGM")+"adc_perioddates.aon", gls01_dev,
:						                                    prev_sf_per, 
:						                                    sf_year, 
:						                                    begdate$, 
:						                                    enddate$, 
:						                                    status
	
	if status=0 
		if callpoint!.getUserInput()>=begdate$
			msg_id$="SF_CANT_PURGE"
			dim msg_tokens$[1]
			msg_opt$=""
			msg_tokens$[1]=fndate$(begdate$)
			gosub disp_message
			callpoint!.setFocus("SFU_PURGECLSDWO.PURGE_DATE")
		endif
	endif
[[SFU_PURGECLSDWO.BSHO]]
rem --- Open Parameter file

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="GLS_PARAMS",open_opts$[2]="OTA"
	gosub open_tables
