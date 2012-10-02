[[APM_VENDMAST.AWRI]]
rem --- Code input if new customer
	cp_vendor_id$=callpoint!.getColumnData("APM_VENDMAST.VENDOR_ID")
	apm02_dev=fnget_dev("APM_VENDHIST")
	apm02_key$=""
	while apm02_key$=""
		read(apm02_dev,key=firm_id$+cp_vendor_id$,dom=*next)
		apm02_key$=key(apm02_dev,end=*next)
		if apm02_key$<>""
			if pos(firm_id$+cp_vendor_id$=apm02_key$)<>1
				apm02_key$=""
			else
				break
			endif
		endif
		user_id$=stbl("+USER_ID")
		dim dflt_data$[2,1]
		dflt_data$[1,0]="VENDOR_ID"
		dflt_data$[1,1]=cp_vendor_id$
		call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:			"APM_VENDHIST",
:			user_id$,
:			"",
:			"",
:			table_chans$[all],
:			"",
:			dflt_data$[all]
	wend
[[APM_VENDMAST.ARNF]]
rem --- Set Date Opened
	callpoint!.setColumnData("APM_VENDMAST.OPENED_DATE",sysinfo.system_date$)
[[APM_VENDMAST.VENDOR_ID.AINP]]
if num(callpoint!.getUserInput(),err=*next)=0 callpoint!.setStatus("ABORT")
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
		read(ivm01_dev,key=firm_id$+vendor_id$,knum=3,dom=*next)
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
	alt_seq$=callpoint!.getColumnData("APM_VENDMAST.VENDOR_NAME")
	alt_seq_len=num(callpoint!.getTableColumnAttribute("APM_VENDMAST.ALT_SEQUENCE","MAXL"))
	if len(alt_seq$)>alt_seq_len
		alt_seq$=alt_seq$(1,alt_seq_len)
	endif
	callpoint!.setColumnData("APM_VENDMAST.ALT_SEQUENCE",alt_seq$)
	callpoint!.setStatus("REFRESH")
endif
[[APM_VENDMAST.BSHO]]
rem --- Open/Lock files
 
	files=6,begfile=1,endfile=files
	dim files$[files],options$[files],chans$[files],templates$[files]
	files$[1]="APE_INVOICEHDR";rem --- ape-01
	files$[2]="APT_INVOICEHDR";rem --- apt-01
	files$[3]="APT_INVOICEDET";rem --- apt-11
	files$[4]="APS_PARAMS";rem --- aps-01
	files$[5]="GLS_PARAMS";rem --- gls-01
	files$[6]="IVS_PARAMS";rem --- ivs-01

	for wkx=begfile to endfile
		options$[wkx]="OTA"
	next wkx

	call stbl("+DIR_SYP")+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                   chans$[all],templates$[all],table_chans$[all],batch,status$

	if status$<>"" goto std_exit

	aps01_dev=num(chans$[4])	
	gls01_dev=num(chans$[5])
	ivs01_dev=num(chans$[6])


rem --- Dimension miscellaneous string templates

	dim aps01a$:templates$[4],gls01a$:templates$[5],ivs01c$:templates$[6]

rem --- Retrieve parameter data

	dim info$[20]

	aps01a_key$=firm_id$+"AP00"
	find record (aps01_dev,key=aps01a_key$,err=std_missing_params) aps01a$ 

	gls01a_key$=firm_id$+"GL00"
	find record (gls01_dev,key=gls01a_key$,err=std_missing_params) gls01a$ 

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

	user_tpl.app$="AP",user_tpl.gl_interface$=gl$,user_tpl.po_installed$=po$,user_tpl.iv_installed$=iv$,
:		user_tpl.multi_types$=aps01a.multi_types$,user_tpl.multi_dist$=aps01a.multi_dist$,
:		user_tpl.ret_flag$=aps01a.ret_flag$,user_tpl.use_replen$=aps01a.use_replen$,
:		user_tpl.gl_total_pers$=gls01a.total_pers$,user_tpl.gl_current_per$=gls01a.current_per$,
:		user_tpl.gl_current_year$=gls01a.current_year$,user_tpl.gl_max_len$=gls01a.max_acct_len$

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

		if status$<>"" goto std_exit

	endif
rem --- set enable_str$ to list of aliases in popup to enable -- enabled by default, so only include specific enable request
rem --- set disable_str$ to list of all aliases in popup to disable (format alias_name;alias_name;alias_name)
if user_tpl.use_replen$<>"Y"
	enable_str$=""
	disable_str$="APM_VENDREPL"
	call stbl("+DIR_SYP")+"bam_enable_pop.bbj",Form!,enable_str$,disable_str$
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
