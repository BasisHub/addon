[[ARC_TERMCODE.BDEL]]
rem --- Inits

	num_files = 2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARM_CUSTDET",  open_opts$[1]="OTA"
	open_tables$[2]="ARS_CUSTDFLT", open_opts$[2]="OTA"

	gosub open_tables

	arm_custdet_dev = num(open_chans$[1])
	terms_code_knum$ = "AO_TERMS_CUST"
	terms_code$ = callpoint!.getColumnData("ARC_TERMCODE.AR_TERMS_CODE")

rem --- Check if code is used by a customer

	read(arm_custdet_dev,key=firm_id$+terms_code$,knum=terms_code_knum$,dom=*next)
	k$ = key(arm_custdet_dev,end=bdel_check_default)

	if k$(1,2) = firm_id$ and k$(3,2) = terms_code$ then 
		callpoint!.setMessage("AR_TERM_IN_USE")
		callpoint!.setStatus("ABORT")
	endif

bdel_check_default: rem --- Check if code is a default

	ars_custdflt_dev = num(open_chans$[2])
	dim ars_rec$:open_tpls$[2]

	find record(ars_custdflt_dev,key=firm_id$+"D",dom=bdel_end)ars_rec$

	if ars_rec.ar_terms_code$ = terms_code$ then
		callpoint!.setMessage("AR_TERM_IN_DFLT")
		callpoint!.setStatus("ABORT")
	endif

bdel_end:
[[ARC_TERMCODE.BSHO]]
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ARS_CREDIT",open_opts$[1]="OTA"
gosub open_tables
ars_credit=num(open_chans$[1])
dim ars_credit$:open_tpls$[1]

read record (ars_credit,key=firm_id$+"AR01",dom=*next)ars_credit$
if ars_credit.sys_install$ <> "Y"
 	ctl_name$="ARC_TERMCODE.CRED_HOLD"
 	ctl_stat$="I"
 	gosub disable_fields
endif
[[ARC_TERMCODE.<CUSTOM>]]
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
