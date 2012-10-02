[[APM_VENDHIST.ARAR]]
rem --- Get correct Open Invoice amount

	apt_invhdr=fnget_dev("APT_INVOICEHDR")
	dim apt_invhdr$:fnget_tpl$("APT_INVOICEHDR")
	apt_invdet=fnget_dev("APT_INVOICEDET")
	dim apt_invdet$:fnget_tpl$("APT_INVOICEDET")
	vendor_id$=callpoint!.getColumnData("APM_VENDHIST.VENDOR_ID")
	ap_type$=callpoint!.getColumnData("APM_VENDHIST.AP_TYPE")
	open_invs=0

rem --- Main process

	read(apt_invhdr,key=firm_id$+ap_type$+vendor_id$,dom=*next)
	while 1
		read record (apt_invhdr,end=*break) apt_invhdr$
		if pos(firm_id$+ap_type$+vendor_id$=apt_invhdr$)<>1 break
		open_invs=open_invs+apt_invhdr.invoice_amt
		hdr_key$=firm_id$+ap_type$+vendor_id$+apt_invhdr.ap_inv_no$
		read(apt_invdet,key=hdr_key$,dom=*next)
		while 1
			read record(apt_invdet,end=*break) apt_invdet$
			if apt_invdet.firm_id$+apt_invdet.ap_type$+apt_invdet.vendor_id$+apt_invdet.ap_inv_no$<>hdr_key$ break
			open_invs=open_invs+(apt_invdet.trans_amt+apt_invdet.trans_disc)
		wend
	wend

	callpoint!.setColumnData("APM_VENDHIST.OPEN_INVS",str(open_invs),1)
[[APM_VENDHIST.ARNF]]
rem --- initialize new record
	if user_tpl.multi_dist$<>"Y"
		callpoint!.setColumnData("APM_VENDHIST.AP_DIST_CODE",user_tpl.dflt_dist_code$)
		callpoint!.setStatus("REFRESH")
	endif
[[APM_VENDHIST.AREC]]
if user_tpl.multi_types$<>"Y" 
	callpoint!.setColumnData("APM_VENDHIST.AP_TYPE",user_tpl.dflt_ap_type$)
	callpoint!.setStatus("REFRESH")
endif
[[APM_VENDHIST.BSHO]]
if user_tpl.multi_dist$="N"
	callpoint!.setColumnEnabled("APM_VENDHIST.AP_DIST_CODE",-1)
endif
[[APM_VENDHIST.BTBL]]
rem --- Retrieve parameter data

	aps01_dev=fnget_dev("APS_PARAMS")
	dim aps01a$:fnget_tpl$("APS_PARAMS")
	aps01a_key$=firm_id$+"AP00"
	find record (aps01_dev,key=aps01a_key$,err=std_missing_params) aps01a$ 

rem -- store info needed for validation, etc., in user_tpl$
	dim user_tpl$:"multi_types:c(1),multi_dist:c(1),ret_flag:c(1),dflt_ap_type:c(2),dflt_dist_code:c(2)"
	user_tpl.multi_types$=aps01a.multi_types$
	user_tpl.multi_dist$=aps01a.multi_dist$
	user_tpl.ret_flag$=aps01a.ret_flag$
 	user_tpl.dflt_ap_type$=aps01a.ap_type$
	user_tpl.dflt_dist_code$=aps01a.ap_dist_code$

rem --- if not using multi AP types, disable access to AP Type and get default distribution code

	if user_tpl.multi_types$<>"Y"
		callpoint!.setTableColumnAttribute("APM_VENDHIST.AP_TYPE","PVAL",$22$+user_tpl.dflt_ap_type$+$22$)

		rem --- get default distribution code	
		apc_typecode_dev=fnget_dev("APC_TYPECODE")
		dim apc_typecode$:fnget_tpl$("APC_TYPECODE")
		find record (apc_typecode_dev,key=firm_id$+"A"+user_tpl.dflt_ap_type$,err=*next)apc_typecode$
		if cvs(apc_typecode$,2)<>""
			user_tpl.dflt_dist_code$=apc_typecode.ap_dist_code$
		endif

		rem --- if not using multi distribution codes, initialize and disable Distribution Code
		if user_tpl.multi_dist$<>"Y"
			callpoint!.setTableColumnAttribute("APM_VENDHIST.AP_DIST_CODE","PVAL",$22$+user_tpl.dflt_dist_code$+$22$)
		endif
	endif
[[APM_VENDHIST.PAYMENT_GRP.AVAL]]
if callpoint!.getUserInput()=""
	callpoint!.setUserInput("  ")
	callpoint!.setStatus("REFRESH")
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
[[APM_VENDHIST.AP_DIST_CODE.AVAL]]
if user_tpl.multi_dist$="Y" and callpoint!.getUserInput()=""
	callpoint!.setUserInput("  ")
	callpoint!.setStatus("REFRESH")
endif
[[APM_VENDHIST.AP_TYPE.AVAL]]
if callpoint!.getUserInput()=""
	callpoint!.setUserInput("  ")
	callpoint!.setStatus("REFRESH")
endif

rem --- get default distribution code	
	apc_typecode_dev=fnget_dev("APC_TYPECODE")
	dim apc_typecode$:fnget_tpl$("APC_TYPECODE")
	find record (apc_typecode_dev,key=firm_id$+"A"+callpoint!.getUserInput(),err=*next)apc_typecode$
	if cvs(apc_typecode$,2)<>""
		user_tpl.dflt_dist_code$=apc_typecode.ap_dist_code$
	endif

if user_tpl.multi_dist$<>"Y"
	callpoint!.setColumnData("APM_VENDHIST.AP_DIST_CODE",user_tpl.dflt_dist_code$)
	callpoint!.setStatus("REFRESH")
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

display_default_rec:

	apm_vendhist_dev=fnget_dev("APM_VENDHIST")
	dim apm_vendhist_tpl$:fnget_tpl$("APM_VENDHIST")
	while 1
		readrecord(apm_vendhist_dev,key=firm_id$+
:			callpoint!.getColumnData("APM_VENDHIST.VENDOR_ID")+
:			user_tpl.dflt_ap_type$,dom=*break)apm_vendhist_tpl$
		callpoint!.setStatus("RECORD:["+firm_id$+
:			callpoint!.getColumnData("APM_VENDHIST.VENDOR_ID")+
:			user_tpl.dflt_ap_type$+"]")
		break
	wend
return

#include std_missing_params.src
