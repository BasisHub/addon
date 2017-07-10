[[SAR_CUSTTERR.CURRENT_YEAR.AVAL]]
rem --- Verify calendar exists for entered SA fiscal year
	year$=callpoint!.getUserInput()
	if cvs(year$,2)<>"" and year$<>callpoint!.getColumnData("SAR_CUSTTERR.CURRENT_YEAR") then
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
[[SAR_CUSTTERR.CURRENT_PER.AVAL]]
rem --- Verify haven't exceeded calendar total periods for entered SA fiscal year
	period$=callpoint!.getUserInput()
	if cvs(period$,2)<>"" and period$<>callpoint!.getColumnData("SAR_CUSTTERR.CURRENT_PER") then
		period=num(period$)
		total_pers=num(callpoint!.getDevObject("total_pers"))
		if period<1 or period>total_pers then
			msg_id$="AD_BAD_FISCAL_PERIOD"
			dim msg_tokens$[2]
			msg_tokens$[1]=str(total_pers)
			msg_tokens$[2]=callpoint!.getColumnData("SAR_CUSTTERR.CURRENT_YEAR")
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
	endif
[[SAR_CUSTTERR.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[SAR_CUSTTERR.BFMC]]
rem --- open files
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SAS_PARAMS",open_opts$[1]="OTA"
	gosub open_tables
	sas01_dev=num(open_chans$[1]),sas01a$=open_tpls$[1]
	dim sas01a$:sas01a$
	read record (sas01_dev,key=firm_id$+"SA00")sas01a$

rem --- create list for available levels

	ldat_list$=pad(Translate!.getTranslation("AON_TERRITORY"),20)+"~"+"T ;"
	if pos(sas01a.terrcode_lev$="CPI") ldat_list$=ldat_list$+pad(Translate!.getTranslation("AON_CUSTOMER"),20)+"~"+"C;"
	if pos(sas01a.terrcode_lev$="PI") ldat_list$=ldat_list$+pad(Translate!.getTranslation("AON_PRODUCT"),20)+"~"+"P ;"
	if pos(sas01a.terrcode_lev$="I") ldat_list$=ldat_list$+pad(Translate!.getTranslation("AON_ITEM"),20)+"~"+"I ;"

	callpoint!.setTableColumnAttribute("SAR_CUSTTERR.SA_LEVEL","LDAT",ldat_list$)
[[SAR_CUSTTERR.ASVA]]
rem --- Check selected level against allowable level
	allow=pos(user_tpl.high_level$=user_tpl.sa_levels$)
	if pos(callpoint!.getColumnData("SAR_CUSTTERR.SA_LEVEL")=user_tpl.sa_levels$)>allow or
:	   pos(callpoint!.getColumnData("SAR_CUSTTERR.SA_LEVEL")=user_tpl.sa_levels$)=0
		msg_id$="INVALID_SA_LEVEL"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[SAR_CUSTTERR.BSHO]]
	sas01_dev=fnget_dev("SAS_PARAMS")
	sas01a$=fnget_tpl$("SAS_PARAMS")
	dim sas01a$:sas01a$
	read record (sas01_dev,key=firm_id$+"SA00")sas01a$
	if sas01a.by_customer$<>"Y"
		msg_id$="INVALID_SA"
		dim msg_tokens$[1]
		msg_tokens$[1]=Translate!.getTranslation("AON_CUSTOMER")
		gosub disp_message
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif
[[SAR_CUSTTERR.ARAR]]
num_files=3
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ARS_PARAMS",open_opts$[1]="OTA"
open_tables$[2]="SAS_PARAMS",open_opts$[2]="OTA"
open_tables$[3]="GLS_CALENDAR",open_opts$[3]="OTA"
gosub open_tables
ars_params_chn=num(open_chans$[1]),ars_params_tpl$=open_tpls$[1]
sas_params_chn=num(open_chans$[2]),sas_params_tpl$=open_tpls$[2]
dim ars_params$:ars_params_tpl$
readrecord(ars_params_chn,key=firm_id$+"AR00")ars_params$
dim sas_params$:sas_params_tpl$
readrecord(sas_params_chn,key=firm_id$+"SA00")sas_params$
if sas_params.by_customer$<>"Y"
	msg_id$="INVALID_SA"
	dim msg_tokens$[1]
	msg_tokens$[1]=Translate!.getTranslation("AON_CUSTOMER")
	gosub disp_message
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif
callpoint!.setColumnData("SAR_CUSTTERR.CURRENT_PER",ars_params.current_per$)
callpoint!.setColumnData("SAR_CUSTTERR.CURRENT_YEAR",ars_params.current_year$)
callpoint!.setColumnData("SAR_CUSTTERR.SA_LEVEL",sas_params.customer_lev$)
callpoint!.setStatus("REFRESH")
dim user_tpl$:"sa_levels:c(4),high_level:c(1)"
user_tpl.sa_levels$="TCPI"
user_tpl.high_level$=sas_params.customer_lev$

rem --- Set maximum number of periods allowed for this fiscal year
	gls_calendar_dev=fnget_dev("GLS_CALENDAR")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
	current_year$=callpoint!.getColumnData("SAR_CUSTTERR.CURRENT_YEAR")
	readrecord(gls_calendar_dev,key=firm_id$+current_year$,dom=*next)gls_calendar$
	callpoint!.setDevObject("total_pers",gls_calendar.total_pers$)
[[SAR_CUSTTERR.TWLVE_PER_REPORT.AVAL]]
x$=callpoint!.getUserInput()
if x$="N" then
	callpoint!.setColumnData("SAR_CUSTTERR.MTD","Y")
	callpoint!.setColumnData("SAR_CUSTTERR.YTD","Y")
	callpoint!.setColumnData("SAR_CUSTTERR.PRIOR","Y")
	callpoint!.setColumnData("SAR_CUSTTERR.SALES_UNITS","")
else
	callpoint!.setColumnData("SAR_CUSTTERR.MTD","N")
	callpoint!.setColumnData("SAR_CUSTTERR.YTD","N")
	callpoint!.setColumnData("SAR_CUSTTERR.PRIOR","N")
	callpoint!.setColumnData("SAR_CUSTTERR.SALES_UNITS","S")
endif
callpoint!.setStatus("REFRESH")

