[[APM_VENDHIST.PAYMENT_GRP.AVAL]]
if callpoint!.getUserInput()=""
	callpoint!.setUserInput("  ")
	callpoint!.setStatus("REFRESH")
endif
[[APM_VENDHIST.ARAR]]
if user_tpl.multi_types$<>"Y"
	callpoint!.setColumnData("APM_VENDHIST.AP_TYPE","  ")
endif
[[APM_VENDHIST.BDEL]]
rem --- disallow deletion of apm-02 if any of the buckets are non-zero, or if referenced in apt-01 (open invoices)

can_delete$=""

if num(callpoint!.getColumnData("APM_VENDHIST.OPEN_INVS"))<>0 or
:	num(callpoint!.getColumnData("APM_VENDHIST.OPEN_RET"))<>0 or
:	num(callpoint!.getColumnData("APM_VENDHIST.YTD_PURCH"))<>0 or
:	num(callpoint!.getColumnData("APM_VENDHIST.PYR_PURCH"))<>0 or
:	num(callpoint!.getColumnData("APM_VENDHIST.NYR_PURCH"))<>0 or
:	num(callpoint!.getColumnData("APM_VENDHIST.YTD_DISCS"))<>0 or
:	num(callpoint!.getColumnData("APM_VENDHIST.PRI_YR_DISCS"))<>0 or
:	num(callpoint!.getColumnData("APM_VENDHIST.NYR_DISC"))<>0 or
:	num(callpoint!.getColumnData("APM_VENDHIST.YTD_PAYMENTS"))<>0 or
:	num(callpoint!.getColumnData("APM_VENDHIST.PYR_PAYMENTS"))<>0 or
:	num(callpoint!.getColumnData("APM_VENDHIST.NYR_PAYMENTS"))<>0 or
:	num(callpoint!.getColumnData("APM_VENDHIST.CUR_CAL_PMTS"))<>0 or
:	num(callpoint!.getColumnData("APM_VENDHIST.PRI_CAL_PMT"))<>0 or
:	num(callpoint!.getColumnData("APM_VENDHIST.NXT_CYR_PMTS"))<>0
 
	can_delete$="N"

endif

if can_delete$=""
	ape01_dev=fnget_dev("APE_INVOICEHDR")
	apt01_dev=fnget_dev("APT_INVOICEHDR")

	wky$=firm_id$+callpoint!.getColumnData("APM_VENDHIST.AP_TYPE")+callpoint!.getColumnData("APM_VENDHIST.VENDOR_ID")
	wk$=""
	read(ape01_dev,key=wky$,dom=*next)
	wk$=key(ape01_dev,end=*next)
	if pos(wky$=wk$)=1 can_delete$="N"
	wk$=""
	read(apt01_dev,key=wky$,dom=*next)
	wk$=key(apt01_dev,end=*next)
	if pos(wky$=wk$)=1 can_delete$="N"		
endif

if can_delete$="N"
	msg_id$="AP_VEND_ACTIVE"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
[[APM_VENDHIST.AENA]]
rem --- see if interfacing to GL
	call stbl("+DIR_PGM")+"adc_application.aon","AP",info$[all]
	gl$=info$[9];rem --- gl interface?

if gl$<>"Y"
	ctl_name$="APM_VENDHIST.GL_ACCOUNT"
	ctl_stat$="I"
	gosub disable_fields
endif

rem escape; rem  before disable reten
rem if user_tpl.ret_flag$="N" 
rem	ctl_name$="APM_VENDHIST.OPEN_RET"
rem	ctl_stat$="I"
rem	gosub disable_fields
rem endif
[[APM_VENDHIST.AP_DIST_CODE.AVAL]]
if user_tpl.multi_dist$<>"Y"

	if cvs(callpoint!.getUserInput(),3)<>"" callpoint!.setStatus("ABORT")

endif
if callpoint!.getUserInput()=""
	callpoint!.setUserInput("  ")
	callpoint!.setStatus("REFRESH")
endif
[[APM_VENDHIST.AP_DIST_CODE.BINP]]
if user_tpl$.multi_dist$<>"Y" 

	callpoint!.setColumnData("APM_VENDHIST.AP_DIST_CODE","  ")
	callpoint!.setStatus("REFRESH")

endif
[[APM_VENDHIST.AP_TYPE.AVAL]]
if user_tpl.multi_types$<>"Y"

	if cvs(callpoint!.getUserInput(),3)<>"" callpoint!.setStatus("ABORT")

endif
if callpoint!.getUserInput()=""
	callpoint!.setUserInput("  ")
	callpoint!.setStatus("REFRESH")
endif
[[APM_VENDHIST.AP_TYPE.BINP]]
if user_tpl$.multi_types$<>"Y" 

	callpoint!.setColumnData("APM_VENDHIST.AP_TYPE","  ")
	callpoint!.setStatus("REFRESH")

endif
[[APM_VENDHIST.BSHO]]
rem --- Retrieve miscellaneous templates


	files=1,begfile=1,endfile=files
	dim ids$[files],templates$[files]
	ids$[1]="aps-01A:APS_PARAMS";rem  aps-01
	
	call stbl("+DIR_PGM")+"adc_template.aon",begfile,endfile,ids$[all],templates$[all],status
        if status goto std_exit

rem --- Dimension miscellaneous string templates

	dim aps01a$:templates$[1]

rem --- Retrieve parameter data

	aps01_dev=fnget_dev("APS_PARAMS")
	aps01a_key$=firm_id$+"AP00"
	find record (aps01_dev,key=aps01a_key$,err=std_missing_params) aps01a$ 

rem -- store info needed for validation, etc., in user_tpl$
	dim user_tpl$:"multi_types:c(1),multi_dist:c(1),ret_flag:c(1)"
	user_tpl.multi_types$=aps01a.multi_types$
	user_tpl.multi_dist$=aps01a.multi_dist$
	user_tpl.ret_flag$=aps01a.ret_flag$

if user_tpl.multi_types$<>"Y"
	ctl_name$="APM_VENDHIST.AP_TYPE"
	ctl_stat$="I"
	gosub disable_fields
else
	ctl_name$="APM_VENDHIST.AP_TYPE"
	ctl_stat$=" "
	gosub disable_fields
endif
[[APM_VENDHIST.<CUSTOM>]]
disable_fields:
	rem --- used to disable/enable controls depending on parameter settings
	rem --- send in control to toggle (format "ALIAS.CONTROL_NAME"), and D or space to disable/enable

	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")

return

#include std_missing_params.src
