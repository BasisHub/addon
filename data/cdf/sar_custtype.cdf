[[SAR_CUSTTYPE.ASVA]]
rem --- Check selected level against allowable level
	allow=pos(user_tpl.high_level$=user_tpl.sa_levels$)
	if pos(callpoint!.getColumnData("SAR_CUSTTYPE.SA_LEVEL")=user_tpl.sa_levels$)>allow or
:	   pos(callpoint!.getColumnData("SAR_CUSTTYPE.SA_LEVEL")=user_tpl.sa_levels$)=0
		msg_id$="INVALID_SA_LEVEL"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[SAR_CUSTTYPE.BSHO]]
	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SAM_CUSTTYPE",open_opts$[1]="OTA"
	open_tables$[2]="SAS_PARAMS",open_opts$[2]="OTA"
	gosub open_tables
	sas01_dev=num(open_chans$[2]),sas01a$=open_tpls$[2]
	dim sas01a$:sas01a$
	read record (sas01_dev,key=firm_id$+"SA00")sas01a$
	if sas01a.by_customer_type$<>"Y"
		msg_id$="INVALID_SA"
		dim msg_tokens$[1]
		msg_tokens$[1]="Cust Type"
		gosub disp_message
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif
[[SAR_CUSTTYPE.TWLVE_PER_REPORT.AVAL]]
x$=callpoint!.getUserInput()
if x$="N" then
	callpoint!.setColumnData("SAR_CUSTTYPE.MTD","Y")
	callpoint!.setColumnData("SAR_CUSTTYPE.YTD","Y")
	callpoint!.setColumnData("SAR_CUSTTYPE.PRIOR","Y")
	callpoint!.setColumnData("SAR_CUSTTYPE.SALES_UNITS","")
else
	callpoint!.setColumnData("SAR_CUSTTYPE.MTD","N")
	callpoint!.setColumnData("SAR_CUSTTYPE.YTD","N")
	callpoint!.setColumnData("SAR_CUSTTYPE.PRIOR","N")
	callpoint!.setColumnData("SAR_CUSTTYPE.SALES_UNITS","S")
endif
callpoint!.setStatus("REFRESH")
[[SAR_CUSTTYPE.ARAR]]
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
if sas_params.by_customer_type$<>"Y"
	msg_id$="INVALID_SA"
	dim msg_tokens$[1]
	msg_tokens$[1]="Cust Type"
	gosub disp_message
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif
callpoint!.setColumnData("SAR_CUSTTYPE.CURRENT_PER",ars_params.current_per$)
callpoint!.setColumnData("SAR_CUSTTYPE.CURRENT_YEAR",ars_params.current_year$)
callpoint!.setColumnData("SAR_CUSTTYPE.SA_LEVEL",sas_params.custtype_lev$)
callpoint!.setStatus("REFRESH")
dim user_tpl$:"sa_levels:c(3),high_level:c(1)"
user_tpl.sa_levels$="CPI"
user_tpl.high_level$=sas_params.custtype_lev$
