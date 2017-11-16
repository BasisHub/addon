[[ADM_RPTCTL_RCP.AOPT-IMPT]]
rem --- Launch Import Recipients form
	callpoint!.setDevObject("dd_table_alias",callpoint!.getColumnData("ADM_RPTCTL_RCP.DD_TABLE_ALIAS"))
	callpoint!.setDevObject("recipient_tp",callpoint!.getColumnData("ADM_RPTCTL_RCP.RECIPIENT_TP"))

	call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:		"ADM_RPT_RCP_LOAD", 
:		stbl("+USER_ID"), 
:		"MNT", 
:		"", 
:		table_chans$[all], 
:		"",
:		""
[[ADM_RPTCTL_RCP.FAX_YN.AVAL]]
rem --- if selecting fax checkbox, set 'to' defaults from customer or vendor

	if callpoint!.getUserInput()="Y"
		gosub set_defaults
	endif
[[ADM_RPTCTL_RCP.ARER]]
rem --- if launching as Dtl Window Table from ADM_RPTCTL, need to set recipient type here since you won't be entering the DD_TABLE_ALIAS

	dd_table_alias$=callpoint!.getColumnData("ADM_RPTCTL_RCP.DD_TABLE_ALIAS")
	if cvs(dd_table_alias$,3)<>""
		gosub set_recip_tp
	endif
[[ADM_RPTCTL_RCP.EMAIL_YN.AVAL]]
rem --- if selecting email checkbox, get 'from' defaults from email account and 'to' defaults from customer or vendor

	if callpoint!.getUserInput()="Y"
		gosub set_defaults
	endif
[[ADM_RPTCTL_RCP.<CUSTOM>]]
rem ==================================================
set_defaults:
rem ==================================================

	adm_email_acct=fnget_dev("@ADM_EMAIL_ACCT")
	dim adm_email_acct$:fnget_tpl$("@ADM_EMAIL_ACCT")

	adm_rptctl=fnget_dev("@ADM_RPTCTL")
	dim adm_rptctl$:fnget_tpl$("@ADM_RPTCTL")

	apm_emailfax=fnget_dev("@APM_EMAILFAX")
	dim apm_emailfax$:fnget_tpl$("@APM_EMAILFAX")

	arm_emailfax=fnget_dev("@ARM_EMAILFAX")
	dim arm_emailfax$:fnget_tpl$("@ARM_EMAILFAX")

rem --- get ADM_RPTCTL record and Email Account record

	readrecord (adm_rptctl,key=firm_id$+callpoint!.getColumnData("ADM_RPTCTL_RCP.DD_TABLE_ALIAS"))adm_rptctl$

	readrecord(adm_email_acct,key=firm_id$+adm_rptctl.email_account$,dom=*next)adm_email_acct$


rem --- get default to, cc, bcc from cust or vend email/fax tables
rem --- note: if cust is specified, vendor will be blank and vice versa

	cust_id$=callpoint!.getColumnData("ADM_RPTCTL_RCP.CUSTOMER_ID")
	vendor_id$=callpoint!.getColumnData("ADM_RPTCTL_RCP.VENDOR_ID")

	if cvs(cust_id$,3)<>""

		readrecord (arm_emailfax,key=firm_id$+cust_id$,dom=*next)arm_emailfax$

	endif

	if cvs(vendor_id$,3)<>""

		readrecord (apm_emailfax,key=firm_id$+vendor_id$,dom=*next)apm_emailfax$

	endif

rem --- set email or fax defaults depending on which box was checked

	if pos("EMAIL_YN"=callpoint!.getCallpointEvent())

		callpoint!.setColumnData("ADM_RPTCTL_RCP.EMAIL_SUBJECT",adm_rptctl.dflt_subject$,1)
		callpoint!.setColumnData("ADM_RPTCTL_RCP.EMAIL_MESSAGE",adm_rptctl.dflt_message$,1)

		if cvs(adm_rptctl.email_account$,3)<>""
			callpoint!.setColumnData("ADM_RPTCTL_RCP.EMAIL_FROM",adm_email_acct.email_from$,1)
			callpoint!.setColumnData("ADM_RPTCTL_RCP.EMAIL_REPLYTO",adm_email_acct.email_replyto$,1)
		endif

		if cvs(cust_id$,3)<>""
			callpoint!.setColumnData("ADM_RPTCTL_RCP.EMAIL_TO",arm_emailfax.email_to$,1)
			callpoint!.setColumnData("ADM_RPTCTL_RCP.EMAIL_CC",arm_emailfax.email_cc$,1)
			callpoint!.setColumnData("ADM_RPTCTL_RCP.EMAIL_BCC",arm_emailfax.email_bcc$,1)
		endif

		if cvs(vend_id$,3)<>""
			callpoint!.setColumnData("ADM_RPTCTL_RCP.EMAIL_TO",apm_emailfax.email_to$)
			callpoint!.setColumnData("ADM_RPTCTL_RCP.EMAIL_CC",apm_emailfax.email_cc$)
			callpoint!.setColumnData("ADM_RPTCTL_RCP.EMAIL_BCC",apm_emailfax.email_bcc$)
		endif
	endif

	if pos("FAX_YN"=callpoint!.getCallpointEvent())

		callpoint!.setColumnData("ADM_RPTCTL_RCP.FAX_SUBJECT",adm_rptctl.dflt_subject$,1)
		callpoint!.setColumnData("ADM_RPTCTL_RCP.FAX_MESSAGE",adm_rptctl.dflt_message$,1)

		if cvs(cust_id$,3)<>""
			callpoint!.setColumnData("ADM_RPTCTL_RCP.FAX_TO",arm_emailfax.fax_to$,1)
			callpoint!.setColumnData("ADM_RPTCTL_RCP.FAX_NOS",arm_emailfax.fax_nos$,1)

		endif

		if cvs(vend_id$,3)<>""
			callpoint!.setColumnData("ADM_RPTCTL_RCP.FAX_TO",apm_emailfax.fax_to$)
			callpoint!.setColumnData("ADM_RPTCTL_RCP.FAX_NOS",apm_emailfax.fax_nos$)
		endif
	endif

	return

rem ==================================================
set_recip_tp:
rem ==================================================
rem --- set recipient type based on ADM_RPTCTL rec
rem --- enable/disable 'print copy' checkbox depending on recipient type (disabled if 'other')
rem --- incoming: dd_table_alias$


	adm_rptctl=fnget_dev("@ADM_RPTCTL")
	dim adm_rptctl$:fnget_tpl$("@ADM_RPTCTL")

	readrecord (adm_rptctl,key=firm_id$+dd_table_alias$)adm_rptctl$

	if cvs(adm_rptctl.recipient_tp$,3)<>""

		callpoint!.setColumnData("ADM_RPTCTL_RCP.RECIPIENT_TP",adm_rptctl.recipient_tp$)

		switch pos(adm_rptctl.recipient_tp$="CVO")
			case 1;rem customer
			case 2;rem vendor
				callpoint!.setColumnEnabled("ADM_RPTCTL_RCP.PRINT_YN",1)
				rem --- Enable AOPT-IMPT for Customer and Vendor recipient types
				callpoint!.setOptionEnabled("IMPT",1)
			break
			case 3;rem other
			case default
				callpoint!.setColumnEnabled("ADM_RPTCTL_RCP.PRINT_YN",0)
				rem --- Disable AOPT-IMPT for Other recipient type
				callpoint!.setOptionEnabled("IMPT",0)
			break
		swend
	else
		msg_id$="AD_NORECIP"
		gosub disp_message
		callpoint!.setStatus("EXIT")
	endif
	return
[[ADM_RPTCTL_RCP.BSHO]]
rem --- table opens

	num_files=4
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ADM_EMAIL_ACCT",open_opts$[1]="OTA@"
	open_tables$[2]="ADM_RPTCTL",open_opts$[2]="OTA@"
	open_tables$[3]="ARM_EMAILFAX",open_opts$[3]="OTA@"
	open_tables$[4]="APM_EMAILFAX",open_opts$[4]="OTA@"
	gosub open_tables
[[ADM_RPTCTL_RCP.VENDOR_ID.AVAL]]
rem --- if not on a Vendor recipient type, pad w/ spaces

	if callpoint!.getColumnData("ADM_RPTCTL_RCP.RECIPIENT_TP")<>"V"
		vend_len=len(callpoint!.getColumnData("ADM_RPTCTL_RCP.VENDOR_ID"))
		callpoint!.setUserInput(fill(vend_len," "))
	else
		if cvs(callpoint!.getUserInput(),2)<>"" then
			rem --- Disable AOPT-IMPT after a vendor_id has been entered
			callpoint!.setOptionEnabled("IMPT",0)
		endif
	endif
[[ADM_RPTCTL_RCP.VENDOR_ID.AINV]]
rem --- if not on a Vendor recipient type, pad w/ spaces

	if callpoint!.getColumnData("ADM_RPTCTL_RCP.RECIPIENT_TP")<>"V"
		vend_len=len(callpoint!.getColumnData("ADM_RPTCTL_RCP.VENDOR_ID"))
		callpoint!.setUserInput(fill(vend_len," "))
	endif
[[ADM_RPTCTL_RCP.DD_TABLE_ALIAS.AVAL]]
rem --- set recipient type based on ADM_RPTCTL rec

	dd_table_alias$=callpoint!.getUserInput()
	gosub set_recip_tp
[[ADM_RPTCTL_RCP.CUSTOMER_ID.AVAL]]
rem --- if not on a Customer recipient type, pad w/ spaces

	if callpoint!.getColumnData("ADM_RPTCTL_RCP.RECIPIENT_TP")<>"C"
		cust_len=len(callpoint!.getColumnData("ADM_RPTCTL_RCP.CUSTOMER_ID"))
		callpoint!.setUserInput(fill(cust_len," "))
	else
		if cvs(callpoint!.getUserInput(),2)<>"" then
			rem --- Disable AOPT-IMPT after a customer_id has been entered
			callpoint!.setOptionEnabled("IMPT",0)
		endif
	endif
[[ADM_RPTCTL_RCP.CUSTOMER_ID.AINV]]
rem --- if not on a Customer recipient type, pad w/ spaces

	if callpoint!.getColumnData("ADM_RPTCTL_RCP.RECIPIENT_TP")<>"C"
		cust_len=len(callpoint!.getColumnData("ADM_RPTCTL_RCP.CUSTOMER_ID"))
		callpoint!.setUserInput(fill(cust_len," "))
	endif
