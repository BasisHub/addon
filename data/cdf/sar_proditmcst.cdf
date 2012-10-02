[[SAR_PRODITMCST.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[SAR_PRODITMCST.ASVA]]
rem --- Check selected level against allowable level
	allow=pos(user_tpl.high_level$=user_tpl.sa_levels$)
	if pos(callpoint!.getColumnData("SAR_PRODITMCST.SA_LEVEL")=user_tpl.sa_levels$)>allow or
:	   pos(callpoint!.getColumnData("SAR_PRODITMCST.SA_LEVEL")=user_tpl.sa_levels$)=0
		msg_id$="INVALID_SA_LEVEL"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[SAR_PRODITMCST.TWLVE_PER_REPORT.AVAL]]
x$=callpoint!.getUserInput()
if x$="N" then
	callpoint!.setColumnData("SAR_PRODITMCST.MTD","Y")
	callpoint!.setColumnData("SAR_PRODITMCST.YTD","Y")
	callpoint!.setColumnData("SAR_PRODITMCST.PRIOR","Y")
	callpoint!.setColumnData("SAR_PRODITMCST.SALES_UNITS","")
else
	callpoint!.setColumnData("SAR_PRODITMCST.MTD","N")
	callpoint!.setColumnData("SAR_PRODITMCST.YTD","N")
	callpoint!.setColumnData("SAR_PRODITMCST.PRIOR","N")
	callpoint!.setColumnData("SAR_PRODITMCST.SALES_UNITS","S")
endif
callpoint!.setStatus("REFRESH")
[[SAR_PRODITMCST.ARAR]]
num_files=2
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ARS_PARAMS",open_opts$[1]="OTA"
open_tables$[2]="SAS_PARAMS",open_opts$[2]="OTA"
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
callpoint!.setColumnData("SAR_PRODITMCST.CURRENT_PER",ars_params.current_per$)
callpoint!.setColumnData("SAR_PRODITMCST.CURRENT_YEAR",ars_params.current_year$)
callpoint!.setColumnData("SAR_PRODITMCST.SA_LEVEL","C")
callpoint!.setStatus("REFRESH")
dim user_tpl$:"sa_levels:c(3),high_level:c(1)"
if sas_params.customer_lev$ = "P"
	dim user_tpl$:"sa_levels:c(2),high_level:c(1)"
	user_tpl.sa_levels$="PC"
	user_tpl.high_level$="C"
endif
if sas_params.customer_lev$ = "C"
	dim user_tpl$:"sa_levels:c(1),high_level:c(1)"
	user_tpl.sa_levels$="C"
	user_tpl.high_level$="C"
endif
if sas_params.customer_lev$ = "I"
	dim user_tpl$:"sa_levels:c(3),high_level:c(1)"
	user_tpl.sa_levels$="PIC"
	user_tpl.high_level$="C"
endif
[[SAR_PRODITMCST.BSHO]]
	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SAM_CUSTOMER",open_opts$[1]="OTA"
	open_tables$[2]="SAS_PARAMS",open_opts$[2]="OTA"
	gosub open_tables
	sas01_dev=num(open_chans$[2]),sas01a$=open_tpls$[2]
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

