[[APM_APPROVERS.PRELIM_APPROVAL.AVAL]]
rem --- Currently same individual cannot be both check_signer and prelim_approval
	if num(callpoint!.getUserInput()) then
		callpoint!.setColumnData("APM_APPROVERS.CHECK_SIGNER","0",1)
		callpoint!.setColumnEnabled("APM_APPROVERS.CHECK_SIGNER",0)
	else
		callpoint!.setColumnEnabled("APM_APPROVERS.CHECK_SIGNER",1)
	endif
[[APM_APPROVERS.CHECK_SIGNER.AVAL]]
rem --- Currently same individual cannot be both check_signer and prelim_approval
	if num(callpoint!.getUserInput()) then
		callpoint!.setColumnData("APM_APPROVERS.PRELIM_APPROVAL","0",1)
		callpoint!.setColumnEnabled("APM_APPROVERS.PRELIM_APPROVAL",0)
	else
		callpoint!.setColumnEnabled("APM_APPROVERS.PRELIM_APPROVAL",1)
	endif
[[APM_APPROVERS.ADIS]]
rem --- Currently same individual cannot be both check_signer and prelim_approval
	if num(callpoint!.getColumnData("APM_APPROVERS.PRELIM_APPROVAL")) then
		callpoint!.setColumnData("APM_APPROVERS.CHECK_SIGNER","0",1)
		callpoint!.setColumnEnabled("APM_APPROVERS.CHECK_SIGNER",0)
	else
		callpoint!.setColumnEnabled("APM_APPROVERS.CHECK_SIGNER",1)
	endif
	if num(callpoint!.getColumnData("APM_APPROVERS.CHECK_SIGNER")) then
		callpoint!.setColumnData("APM_APPROVERS.PRELIM_APPROVAL","0",1)
		callpoint!.setColumnEnabled("APM_APPROVERS.PRELIM_APPROVAL",0)
	else
		callpoint!.setColumnEnabled("APM_APPROVERS.PRELIM_APPROVAL",1)
	endif
[[APM_APPROVERS.BSHO]]
rem --- Open/Lock files

	num_files=6
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APS_PARAMS",open_opts$[1]="OTA@"
	open_tables$[2]="APS_PAYAUTH",open_opts$[2]="OTA@"

	gosub open_tables

	aps01_dev=num(open_chans$[1])
	payauth_dev=num(open_chans$[2])

	dim aps01a$:open_tpls$[1]
	dim payauth$:open_tpls$[2]

rem --- Retrieve parameter data
	aps01a_key$=firm_id$+"AP00"
	find record (aps01_dev,key=aps01a_key$,err=std_missing_params) aps01a$

rem --- Verify using Payment Authorization
	payauth_key$=aps01a_key$
	dim payauth$:fattr(payauth$)
	find record(payauth_dev,key=payauth_key$,dom=*next)payauth$
	if !payauth.use_pay_auth then
		callpoint!.setMessage("PAYAUTH_PARAM_ERR")
		callpoint!.setStatus("EXIT")
		break
	endif
[[APM_APPROVERS.<CUSTOM>]]
#include std_missing_params.src
