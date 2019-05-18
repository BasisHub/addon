[[APM_VENDMAST.ADIS]]
rem --- Enable/disable and Payment Information fields
	if callpoint!.getColumnData("APM_VENDMAST.PAYMENT_TYPE")="A" then
		callpoint!.setColumnEnabled("APM_VENDMAST.BANK_NAME",1)
		callpoint!.setColumnEnabled("APM_VENDMAST.ABA_NO",1)
		callpoint!.setColumnEnabled("APM_VENDMAST.BNK_ACCT_NO",1)
		callpoint!.setColumnEnabled("APM_VENDMAST.BNK_ACCT_TYPE",1)

		rem --- Initialize email address and fax number from ADM_RPTCTL_RCP
		reportControl!=new ReportControl()
		rpt_ctl$=reportControl!.getReportControl("APR_CHECKS")
		rpt_ctl$=iff(rpt_ctl$="","NO","YES")
		vendor_id$=callpoint!.getColumnData("APM_VENDMAST.VENDOR_ID")
		if rpt_ctl$="YES" and reportControl!.getRecipientInfo(reportControl!.getReportID(),"",vendor_id$) then
			AdmRptctlRcp!=reportControl!.getAdmRptctlRcp()
			if reportControl!.getEmailYN()="Y"  then
				callpoint!.setColumnData("<<DISPLAY>>.CHKSTUB_EMAIL",AdmRptctlRcp!.getFieldAsString("EMAIL_TO"),1)
			else
				callpoint!.setColumnData("<<DISPLAY>>.CHKSTUB_EMAIL","",1)
			endif
			if reportControl!.getFaxYN()="Y" then
				callpoint!.setColumnData("<<DISPLAY>>.CHKSTUB_FAX",AdmRptctlRcp!.getFieldAsString("FAX_TO"),1)
			else
				callpoint!.setColumnData("<<DISPLAY>>.CHKSTUB_FAX","",1)
			endif
		endif
	else
		callpoint!.setColumnEnabled("APM_VENDMAST.BANK_NAME",0)
		callpoint!.setColumnEnabled("APM_VENDMAST.ABA_NO",0)
		callpoint!.setColumnEnabled("APM_VENDMAST.BNK_ACCT_NO",0)
		callpoint!.setColumnEnabled("APM_VENDMAST.BNK_ACCT_TYPE",0)

		callpoint!.setColumnData("<<DISPLAY>>.CHKSTUB_EMAIL","",1)
		callpoint!.setColumnData("<<DISPLAY>>.CHKSTUB_FAX","",1)
	endif
[[APM_VENDMAST.PAYMENT_TYPE.AVAL]]
rem --- Enable Payment Information fields when paying via ACH
	payment_type$=callpoint!.getUserInput()
	if payment_type$<>callpoint!.getColumnData("APM_VENDMAST.PAYMENT_TYPE") then
		if payment_type$="A" then
			callpoint!.setColumnEnabled("APM_VENDMAST.BANK_NAME",1)
			callpoint!.setColumnEnabled("APM_VENDMAST.ABA_NO",1)
			callpoint!.setColumnEnabled("APM_VENDMAST.BNK_ACCT_NO",1)
			callpoint!.setColumnEnabled("APM_VENDMAST.BNK_ACCT_TYPE",1)

			callpoint!.setColumnData("APM_VENDMAST.BNK_ACCT_TYPE","C",1)

			rem --- Initialize email address and fax number from ADM_RPTCTL_RCP
			reportControl!=new ReportControl()
			rpt_ctl$=reportControl!.getReportControl("APR_CHECKS")
			rpt_ctl$=iff(rpt_ctl$="","NO","YES")
			vendor_id$=callpoint!.getColumnData("APM_VENDMAST.VENDOR_ID")
			if rpt_ctl$="YES" and reportControl!.getRecipientInfo(reportControl!.getReportID(),"",vendor_id$) then
				AdmRptctlRcp!=reportControl!.getAdmRptctlRcp()
				if reportControl!.getEmailYN()="Y"  then
					callpoint!.setColumnData("<<DISPLAY>>.CHKSTUB_EMAIL",AdmRptctlRcp!.getFieldAsString("EMAIL_TO"),1)
				endif
				if reportControl!.getFaxYN()="Y" then
					callpoint!.setColumnData("<<DISPLAY>>.CHKSTUB_FAX",AdmRptctlRcp!.getFieldAsString("FAX_TO"),1)
				endif
			endif
		else
			rem --- Don�t allow changing PAYMENT_TYPE from A to P if there are any ACH payments for the vendor.
			achPayment=0
			vendor_id$=callpoint!.getColumnData("APM_VENDMAST.VENDOR_ID")
			apw01_dev=fnget_dev("APW_CHECKINVOICE")
			dim apw01a$:fnget_tpl$("APW_CHECKINVOICE")
			read(apw01_dev,key=firm_id$,dom=*next)
			while 1
				readrecord(apw01_dev,end=*break)apw01a$
				if apw01a.firm_id$<>firm_id$ then break
				if apw01a.vendor_id$<>vendor_id$ or apw01a.comp_or_void$<>"A" then continue
				achPayment=1
				break
			wend
			if achPayment then
				msg_id$="AP_CHANGE_ACH"
				gosub disp_message

				rem --- Reset radio buttons and start over
				checkPaymentType!=callpoint!.getControl("APM_VENDMAST.PAYMENT_TYPE")
				checkPaymentType!.setSelected(SysGUI!.FALSE)
				achPaymentType!=util.findControl(Form!,Translate!.getTranslation("DDM_ELEMENT_LDAT-PAYMENT_TYPE-A-DD_ATTR_LDAT_DS"))
				if achPaymentType!<>null() then achPaymentType!.setSelected(SysGUI!.TRUE)
				callpoint!.setStatus("ABORT")
				break
			endif

			callpoint!.setColumnEnabled("APM_VENDMAST.BANK_NAME",0)
			callpoint!.setColumnEnabled("APM_VENDMAST.ABA_NO",0)
			callpoint!.setColumnEnabled("APM_VENDMAST.BNK_ACCT_NO",0)
			callpoint!.setColumnEnabled("APM_VENDMAST.BNK_ACCT_TYPE",0)

			callpoint!.setColumnData("APM_VENDMAST.BANK_NAME","",1)
			callpoint!.setColumnData("APM_VENDMAST.ABA_NO","",1)
			callpoint!.setColumnData("APM_VENDMAST.BNK_ACCT_NO","",1)
			callpoint!.setColumnData("APM_VENDMAST.BNK_ACCT_TYPE","",1)
			callpoint!.setColumnData("<<DISPLAY>>.CHKSTUB_EMAIL","",1)
			callpoint!.setColumnData("<<DISPLAY>>.CHKSTUB_FAX","",1)
		endif
	endif
[[APM_VENDMAST.AREC]]
rem --- Disable and initialize Payment Information fields
	callpoint!.setColumnEnabled("APM_VENDMAST.BANK_NAME",0)
	callpoint!.setColumnEnabled("APM_VENDMAST.ABA_NO",0)
	callpoint!.setColumnEnabled("APM_VENDMAST.BNK_ACCT_NO",0)
	callpoint!.setColumnEnabled("APM_VENDMAST.BNK_ACCT_TYPE",0)

	callpoint!.setColumnData("APM_VENDMAST.PAYMENT_TYPE","P",1)
[[APM_VENDMAST.AOPT-IHST]]
rem --- Show invoices from this vendor

	vendor_id$=callpoint!.getColumnData("APM_VENDMAST.VENDOR_ID")

	selected_key$ = ""
	dim filter_defs$[1,2]
	filter_defs$[0,0]="APT_INVOICEHDR.FIRM_ID"
	filter_defs$[0,1]="='"+firm_id$+"'"
	filter_defs$[0,2]="LOCK"
	filter_defs$[1,0]="APT_INVOICEHDR.VENDOR_ID"
	filter_defs$[1,1]="='"+vendor_id$+"'"
	filter_defs$[1,2]="LOCK"

	dim search_defs$[3]

	call stbl("+DIR_SYP")+"bax_query.bbj",
:		gui_dev,
:		Form!,
:		"AP_INVBYVEND",
:		"",
:		table_chans$[all],
:		selected_key$,
:		filter_defs$[all],
:		search_defs$[all],
:		"",
:		""

rem --- Show history for selected invoice
	if selected_key$<>""
		call stbl("+DIR_SYP")+"bac_key_template.bbj",
:			"APT_INVOICEHDR",
:			"PRIMARY",
:			primary_key$,
:			table_chans$[all],
:			status$
		dim apt_invoicehdr_key$:primary_key$
		apt_invoicehdr_key$=selected_key$

		rem --- Launch Invoice History Inquiry form
		user_id$=stbl("+USER_ID")
		key_pfx$=apt_invoicehdr_key$
		call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:			"APT_INVOICEHDR",
:			user_id$,
:			"",
:			key_pfx$,
:			table_chans$[all]
	endif
[[APM_VENDMAST.AOPT-HCPY]]
rem --- Go run the Hard Copy form

	vend$=callpoint!.getColumnData("APM_VENDMAST.VENDOR_ID")
	temp$=callpoint!.getColumnData("APM_VENDMAST.TEMP_VEND")
	if temp$="Y"
		type$="T"
	else
		type$="P"
	endif

	dim dflt_data$[3,1]
	dflt_data$[1,0]="VENDOR_ID_1"
	dflt_data$[1,1]=vend$
	dflt_data$[2,0]="VENDOR_ID_2"
	dflt_data$[2,1]=vend$
	dflt_data$[3,0]="VENDOR_TYPE"
	dflt_data$[3,1]=type$

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"APR_DETAIL",
:		stbl("+USER_ID"),
:		"MNT",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]
[[APM_VENDMAST.VENDOR_ID.AVAL]]
if num(callpoint!.getUserInput(),err=*endif)=0
	callpoint!.setMessage("INPUT_ERR_MAIN")
	callpoint!.setStatus("ABORT")
endif
[[APM_VENDMAST.BWRI]]
if num(callpoint!.getColumnData("APM_VENDMAST.VENDOR_ID"),err=*endif)=0 
	callpoint!.setMessage("INPUT_ERR_MAIN")
	callpoint!.setStatus("ABORT")
endif
[[APM_VENDMAST.AWRI]]
rem --- Code input if new customer
	cp_vendor_id$=callpoint!.getColumnData("APM_VENDMAST.VENDOR_ID")
	apm02_dev=fnget_dev("APM_VENDHIST")
	apm02_key$=""

rem --- if accessing vendor maint via Invoice/Manual Check Entry, get default apm_vendhist (apm-02) values
rem --- from AP Types file (apc_typecode)

	if callpoint!.getDevObject("passed_in_AP_type")<>null()
	
		apc_typecode_dev=fnget_dev("APC_TYPECODE")
		dim apc_typecode$:fnget_tpl$("APC_TYPECODE")

		read record (apc_typecode_dev,key=firm_id$+"A"+callpoint!.getDevObject("passed_in_AP_type"),err=*next)apc_typecode$

		dflt_ap_type$=callpoint!.getDevObject("passed_in_AP_type")
		dflt_ap_dist_code$=apc_typecode.ap_dist_code$
		dflt_payment_grp$=apc_typecode.payment_grp$
		dflt_ap_terms_code$=apc_typecode.ap_terms_code$

	endif

	read(apm02_dev,key=firm_id$+cp_vendor_id$,dom=*next)
	apm02_key$=key(apm02_dev,end=*next)
	if pos(firm_id$+cp_vendor_id$=apm02_key$)=0
		if callpoint!.getColumnData("APM_VENDMAST.TEMP_VEND")<>"Y" or (dflt_ap_type$="" or dflt_ap_dist_code$="" 
:			or dflt_payment_grp$="" or dflt_ap_terms_code$="") then

			user_id$=stbl("+USER_ID")
			dim dflt_data$[2,1]
			dflt_data$[1,0]="VENDOR_ID"
			dflt_data$[1,1]=cp_vendor_id$
			call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:				"APM_VENDHIST",
:				user_id$,
:				"",
:				firm_id$+cp_vendor_id$,
:				table_chans$[all],
:				"",
:				dflt_data$[all]
		else

			dim apm02a$:fnget_tpl$("APM_VENDHIST")
			apm02a.firm_id$=firm_id$
			apm02a.vendor_id$=cp_vendor_id$
			apm02a.ap_type$=dflt_ap_type$
			apm02a.ap_dist_code$=dflt_ap_dist_code$
			apm02a.payment_grp$=dflt_payment_grp$
			apm02a.ap_terms_code$=dflt_ap_terms_code$
			apm02a$=field(apm02a$)
			extract record (apm02_dev,key=apm02a.firm_id$+apm02a.vendor_id$+apm02a.ap_type$,dom=*next)dummy$;rem Advisory Locking
			write record (apm02_dev)apm02a$
		endif

	endif
	
[[APM_VENDMAST.ARNF]]
rem --- Set Date Opened
	callpoint!.setColumnData("APM_VENDMAST.OPENED_DATE",sysinfo.system_date$)
[[APM_VENDMAST.BDEL]]
rem --- can delete vendor and assoc recs (apm01/02/05/06/08/09/14/15) unless
rem --- vendor referenced in inventory, or
rem --- open invoice or open retention amts in apm-02 <>  0, or 
rem --- vendor present in ape-01 or apt-01
can_delete$=""
vendor_id$=callpoint!.getColumnData("APM_VENDMAST.VENDOR_ID")
if cvs(vendor_id$,3)<>""
	if user_tpl.iv_installed$="Y"
		num_files=1
		dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
		open_tables$[1]="IVM_ITEMMAST",open_opts$[1]="OTA"
		gosub open_tables
		ivm01_dev=num(open_chans$[1])
		
		iv_key$=""
		read(ivm01_dev,key=firm_id$+vendor_id$,knum="AO_VEND_ITEM",dom=*next)
		iv_key$=key(ivm01_dev,end=*next)
		if pos(firm_id$+vendor_id$=iv_key$)=1 can_delete$="N"
	endif
	if can_delete$=""
		apm02_dev=fnget_dev("APM_VENDHIST")
		ape01_dev=fnget_dev("APE_INVOICEHDR")
		apt01_dev=fnget_dev("APT_INVOICEHDR")
		morehist=1
		dim apm02a$:fnget_tpl$("APM_VENDHIST")
		read(apm02_dev,key=firm_id$+vendor_id$,dom=*next)
		while morehist
			readrecord(apm02_dev,end=*break)apm02a$
			if apm02a.firm_id$+apm02a.vendor_id$=firm_id$+vendor_id$
				if num(apm02a.open_invs$)<>0 or num(apm02a.open_ret$)<>0 can_delete$="N"
				wk$=""
				read(ape01_dev,key=firm_id$+apm02a.ap_type$+vendor_id$,dom=*next)
				wk$=key(ape01_dev,end=*next)
				if pos(firm_id$+apm02a.ap_type$+vendor_id$=wk$)=1 can_delete$="N"
				wk$=""
				read(apt01_dev,key=firm_id$+apm02a.ap_type$+vendor_id$,dom=*next)
				wk$=key(apt01_dev,end=*next)
				if pos(firm_id$+apm02a.ap_type$+vendor_id$=wk$)=1 can_delete$="N"
			else
				morehist=0
			endif
		wend
	endif
	if can_delete$="N"
		msg_id$="AP_VEND_ACTIVE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
endif
[[APM_VENDMAST.<CUSTOM>]]
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
#include std_missing_params.src
[[APM_VENDMAST.VENDOR_NAME.AVAL]]
rem --- if no alt sequence is set, default it to vendor name
if cvs(callpoint!.getColumnData("APM_VENDMAST.ALT_SEQUENCE"),3)=""
	alt_seq$=callpoint!.getUserInput()
	alt_seq_len=num(callpoint!.getTableColumnAttribute("APM_VENDMAST.ALT_SEQUENCE","MAXL"))
	if len(alt_seq$)>alt_seq_len
		alt_seq$=alt_seq$(1,alt_seq_len)
	endif
	callpoint!.setColumnData("APM_VENDMAST.ALT_SEQUENCE",alt_seq$)
	callpoint!.setStatus("REFRESH")
endif
[[APM_VENDMAST.BSHO]]
rem --- Open/Lock files

	use ::ado_rptControl.src::ReportControl
	use ::ado_util.src::util

	files=11,begfile=1,endfile=files
	dim files$[files],options$[files],chans$[files],templates$[files]
	files$[1]="APE_INVOICEHDR";rem --- ape-01
	files$[2]="APT_INVOICEHDR";rem --- apt-01
	files$[3]="APT_INVOICEDET";rem --- apt-11
	files$[4]="APS_PARAMS";rem --- aps-01
	files$[5]="GLS_PARAMS";rem --- gls-01
	files$[6]="IVS_PARAMS";rem --- ivs-01
	files$[7]="APC_TYPECODE"
	files$[8]="APE_INVOICEDET"
	files$[9]="GLS_CALENDAR"
	files$[10]="ADM_RPTCTL_RCP"
	files$[11]="APW_CHECKINVOICE"; rem --- apw-01

	for wkx=begfile to endfile
		options$[wkx]="OTA"
	next wkx
	call stbl("+DIR_SYP")+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                   chans$[all],templates$[all],table_chans$[all],batch,status$

	if status$<>"" then
		remove_process_bar:
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif

	aps01_dev=num(chans$[4])	
	gls01_dev=num(chans$[5])
	ivs01_dev=num(chans$[6])
	gls_calendar_dev=num(chans$[9])

rem --- Dimension miscellaneous string templates
	dim aps01a$:templates$[4],gls01a$:templates$[5],ivs01c$:templates$[6]
	dim ape11a$:templates$[8],gls_calendar$:templates$[9]

rem --- Retrieve parameter data
	dim info$[20]
	aps01a_key$=firm_id$+"AP00"
	find record (aps01_dev,key=aps01a_key$,err=std_missing_params) aps01a$ 
	gls01a_key$=firm_id$+"GL00"
	find record (gls01_dev,key=gls01a_key$,err=std_missing_params) gls01a$ 
	find record (gls_calendar_dev,key=firm_id$+gls01a.current_year$,err=*next) gls_calendar$ 
	if cvs(gls_calendar.firm_id$,2)="" then
		msg_id$="AD_NO_FISCAL_CAL"
		dim msg_tokens$[1]
		msg_tokens$[1]=gls01a.current_year$
		gosub disp_message
		callpoint!.setStatus("EXIT")
		break
	endif
	call stbl("+DIR_PGM")+"adc_application.aon","IV",info$[all]
	iv$=info$[20]
	if iv$<>"Y" aps01a.use_replen$="N"
	
	call stbl("+DIR_PGM")+"adc_application.aon","AP",info$[all]
	gl$=info$[9];rem --- gl interface?
	
	call stbl("+DIR_PGM")+"adc_application.aon","PO",info$[all]
	po$=info$[20];rem --- po installed?
	if po$="N" aps01a.use_replen$="N"

	dim user_tpl$:"app:c(2),gl_interface:c(1),po_installed:c(1),iv_installed:c(1),"+
:		"multi_types:c(1),multi_dist:c(1),ret_flag:c(1),use_replen:c(1),"+
:		"gl_total_pers:c(2),gl_current_per:c(2),gl_current_year:c(4),gl_acct_len:c(2),gl_max_len:c(2)"

	user_tpl.app$="AP"
	user_tpl.gl_interface$=gl$
	user_tpl.po_installed$=po$
	user_tpl.iv_installed$=iv$
	user_tpl.multi_types$=aps01a.multi_types$
	user_tpl.multi_dist$=aps01a.multi_dist$
	user_tpl.ret_flag$=aps01a.ret_flag$
	user_tpl.use_replen$=aps01a.use_replen$
	user_tpl.gl_total_pers$=gls_calendar.total_pers$
	user_tpl.gl_current_per$=gls01a.current_per$
	user_tpl.gl_current_year$=gls01a.current_year$
	user_tpl.gl_max_len$=str(max(10,len(ape11a.gl_account$)):"00")
	
	callpoint!.setDevObject("aps_single_dist_code",aps01a.ap_dist_code$)

rem --- used to also open ivm-03 if iv$="Y", but using alt keys on ivm-01 instead
rem --- knum=3 is firm/vendor/item, knum=9 is firm/buyer/vendor/item
	if po$="Y"
		files=5,begfile=1,endfile=files
		dim files$[files],options$[files],chans$[files],templates$[files]
		files$[1]="POC_LINECODE";rem --- pom-02
		files$[2]="POT_RECHDR";rem --- pot-04
		files$[3]="POT_INVHDR";rem --- pot-05
		files$[4]="POT_RECDET";rem --- pot-14
		files$[5]="POT_INVDET";rem --- pot-25
		for wkx=begfile to endfile
			options$[wkx]="OTA"
		next wkx
		call stbl("+DIR_SYP")+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:	                                   chans$[all],templates$[all],table_chans$[all],batch,status$
		if status$<>"" then
			bbjAPI!=bbjAPI()
			rdFuncSpace!=bbjAPI!.getGroupNamespace()
			rdFuncSpace!.setValue("+build_task","OFF")
			release
		endif
	endif

rem --- disable access to vendor replenishment form if param is set for no replen. processing

	if user_tpl.use_replen$<>"Y"
		callpoint!.setOptionEnabled("APM_VENDREPL",0)
	endif

rem --- if vendor maint has been launched from Invoice/Manual Check Entry, default the temp vendor flag to "Y"

	if str(callpoint!.getDevObject("passed_in_temp_vend"))="Y"
		callpoint!.setTableColumnAttribute("APM_VENDMAST.TEMP_VEND","DFLT","Y")
	endif
[[APM_VENDMAST.AOPT-RHST]]
rem Receipt History Inquiry
if user_tpl.po_installed$="Y"
	cp_vendor_id$=callpoint!.getColumnData("APM_VENDMAST.VENDOR_ID")
	user_id$=stbl("+USER_ID")
	dim dflt_data$[2,1]
	dflt_data$[1,0]="VENDOR_ID"
	dflt_data$[1,1]=cp_vendor_id$
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	                       "APR_RECEIPTS",
:	                       user_id$,
:	                   	  "",
:	                       "",
:	                       table_chans$[all],
:	                       "",
:	                       dflt_data$[all]
else
	msg_id$="AP_NOPO"
	gosub disp_message
endif
[[APM_VENDMAST.AOPT-OINV]]
rem Open Invoice Inquiry
cp_vendor_id$=callpoint!.getColumnData("APM_VENDMAST.VENDOR_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[2,1]
dflt_data$[1,0]="VENDOR_ID"
dflt_data$[1,1]=cp_vendor_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:                       "APR_VENDINV",
:                       user_id$,
:                   	  "",
:                       "",
:                       table_chans$[all],
:                       "",
:                       dflt_data$[all]
