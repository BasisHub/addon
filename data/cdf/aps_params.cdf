[[APS_ACH.ACH_CHECK_DIR.AVAL]]
rem --- Verify export directory exists
	temp_dir$=callpoint!.getUserInput()

	rem --- Flip directory path separators
	filePath$=temp_dir$
	gosub fix_path
	temp_dir$=filePath$
	rem --- Add trailing path separator
	if pos(temp_dir$(len(temp_dir$),1)="\/")=0 then
		temp_dir$=temp_dir$+"/"
	endif

	temp_chan=unt
	success=0
	open(temp_chan,err=*next)temp_dir$; success=1
	if !success then
		close(temp_chan)
		msg_id$="AD_DATAPORT_DIR"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
	callpoint!.setUserInput(temp_dir$)
[[APS_ACH.ACH_EXPORT_DIR.AVAL]]
rem --- Verify export directory exists
	temp_dir$=callpoint!.getUserInput()

	rem --- Flip directory path separators
	filePath$=temp_dir$
	gosub fix_path
	temp_dir$=filePath$
	rem --- Add trailing path separator
	if pos(temp_dir$(len(temp_dir$),1)="\/")=0 then
		temp_dir$=temp_dir$+"/"
	endif

	temp_chan=unt
	success=0
	open(temp_chan,err=*next)temp_dir$; success=1
	if !success then
		close(temp_chan)
		msg_id$="AD_DATAPORT_DIR"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
	callpoint!.setUserInput(temp_dir$)
[[APS_PARAMS.BEND]]
rem --- Check fields required for ACH Payments
	if cvs(callpoint!.getColumnData("APS_ACH.BNK_ACCT_CD"),2)<>"" then
		required_field$=""
		if cvs(callpoint!.getColumnData("<<DISPLAY>>.ABA_NO"),2)="" then
			rem --- May be blank when upgrading from pre-v19
			required_field$="Bank Routing Number"
		endif
		if cvs(callpoint!.getColumnData("APS_ACH.TOTAL_REQUIRED"),2)="" then
			required_field$="Total Record Required"
		endif
		if cvs(callpoint!.getColumnData("APS_ACH.FIRM_NAME"),2)="" then
			required_field$="Federal ID"
		endif
		if cvs(callpoint!.getColumnData("<<DISPLAY>>.FEDERAL_ID"),2)="" then
			required_field$="Firm Name"
		endif
		if cvs(callpoint!.getColumnData("APS_ACH.ACH_EXPORT_DIR"),2)="" then
			required_field$="ACH File Export Directory"
		endif
		if cvs(callpoint!.getColumnData("APS_ACH.ACH_CHECK_DIR"),2)="" then
			required_field$="ACH Check Image Directory"
		endif
		if cvs(required_field$,2)<>"" then
			msg_id$="AP_REQUIRED_FOR_ACH"
			dim msg_tokens$[1]
			msg_tokens$[1]=required_field$
			gosub disp_message
		endif
	endif
[[APS_ACH.BNK_ACCT_CD.AVAL]]
rem --- Initialize ACH Payment fields
	bnk_acct_cd$=callpoint!.getUserInput()
	if cvs(bnk_acct_cd$,2)="" then
		rem --- Don’t allow eliminating the BNK_ACCT_CD (changing is okay) if there are any ACH payments in APW_CHECKINVOICE (apw-01)
		if cvs(callpoint!.getColumnData("APS_ACH.BNK_ACCT_CD"),2)<>"" then
			achPayments=0
			apwCheckInvoice_dev=fnget_dev("APW_CHECKINVOICE")
			dim apwCheckInvoice$:fnget_tpl$("APW_CHECKINVOICE")
			read(apwCheckInvoice_dev,key=firm_id$,dom=*next)
			while 1
				readrecord(apwCheckInvoice_dev,end=*break)apwCheckInvoice$
				if apwCheckInvoice.firm_id$<>firm_id$ then break
				if apwCheckInvoice.comp_or_void$<>"A" then continue
				achPayments=1
				break
			wend
			if achPayments then
				rem --- Cannot delete Bank Account Code. There are ACH Payments in Check Register that have not been updated.
				msg_id$="AP_ACHCHK_NOT_UPDTED"
				gosub disp_message
				callpoint!.setColumnData("APS_ACH.BNK_ACCT_CD",callpoint!.getColumnData("APS_ACH.BNK_ACCT_CD"),1)
				callpoint!.setStatus("ABORT")
				break
			endif
		endif

		rem --- Clear ACH Payment fields
		callpoint!.setColumnData("<<DISPLAY>>.BANK_NAME","",1)
		callpoint!.setColumnData("<<DISPLAY>>.ADDRESS_LINE_1","",1)
		callpoint!.setColumnData("<<DISPLAY>>.ADDRESS_LINE_2","",1)
		callpoint!.setColumnData("<<DISPLAY>>.ADDRESS_LINE_3","",1)
		callpoint!.setColumnData("<<DISPLAY>>.ACCT_DEST","",1)
		callpoint!.setColumnData("<<DISPLAY>>.ABA_NO","",1)
		callpoint!.setColumnData("<<DISPLAY>>.BNK_ACCT_NO","",1)
		callpoint!.setColumnData("<<DISPLAY>>.BNK_ACCT_TYPE","",1)
		callpoint!.setColumnData("APS_ACH.TOTAL_REQUIRED","",1)
		callpoint!.setColumnData("APS_ACH.FIRM_NAME","",1)
		callpoint!.setColumnData("<<DISPLAY>>.FEDERAL_ID","",1)
		callpoint!.setColumnData("APS_ACH.ACH_EXPORT_DIR","",1)
		callpoint!.setColumnData("APS_ACH.ACH_CHECK_DIR","",1)

		rem --- Disable non-bank account code fields
		callpoint!.setColumnEnabled("APS_ACH.TOTAL_REQUIRED",0)
		callpoint!.setColumnEnabled("APS_ACH.FIRM_NAME",0)
		callpoint!.setColumnEnabled("APS_ACH.ACH_EXPORT_DIR",0)
		callpoint!.setColumnEnabled("APS_ACH.ACH_CHECK_DIR",0)
	else
		rem --- Enable non-bank account code fields
		callpoint!.setColumnEnabled("APS_ACH.TOTAL_REQUIRED",1)
		callpoint!.setColumnEnabled("APS_ACH.FIRM_NAME",1)
		callpoint!.setColumnEnabled("APS_ACH.ACH_EXPORT_DIR",1)
		callpoint!.setColumnEnabled("APS_ACH.ACH_CHECK_DIR",1)

		rem --- Non-bank account code fields are required
		callpoint!.setTableColumnAttribute("APS_ACH.TOTAL_REQUIRED","MINL","1")
		callpoint!.setTableColumnAttribute("APS_ACH.FIRM_NAME","MINL","1")
		callpoint!.setTableColumnAttribute("APS_ACH.ACH_EXPORT_DIR","MINL","1")
		callpoint!.setTableColumnAttribute("APS_ACH.ACH_CHECK_DIR","MINL","1")

		if bnk_acct_cd$<>callpoint!.getColumnData("APS_ACH.BNK_ACCT_CD")
			rem --- Initialize bank account code fields
			adcBankAcctCode_dev=fnget_dev("ADC_BANKACCTCODE")
			dim adcBankAcctCode$:fnget_tpl$("ADC_BANKACCTCODE")
			readrecord(adcBankAcctCode_dev,key=firm_id$+bnk_acct_cd$,dom=*next)adcBankAcctCode$
			callpoint!.setColumnData("<<DISPLAY>>.BANK_NAME",adcBankAcctCode.bank_name$,1)
			callpoint!.setColumnData("<<DISPLAY>>.ADDRESS_LINE_1",adcBankAcctCode.address_line_1$,1)
			callpoint!.setColumnData("<<DISPLAY>>.ADDRESS_LINE_2",adcBankAcctCode.address_line_2$,1)
			callpoint!.setColumnData("<<DISPLAY>>.ADDRESS_LINE_3",adcBankAcctCode.address_line_3$,1)
			callpoint!.setColumnData("<<DISPLAY>>.ACCT_DEST",adcBankAcctCode.acct_desc$,1)
			callpoint!.setColumnData("<<DISPLAY>>.ABA_NO",adcBankAcctCode.aba_no$,1)
			callpoint!.setColumnData("<<DISPLAY>>.BNK_ACCT_NO",adcBankAcctCode.bnk_acct_no$,1)
			callpoint!.setColumnData("<<DISPLAY>>.BNK_ACCT_TYPE",adcBankAcctCode.bnk_acct_type$,1)
			callpoint!.setColumnData("APS_ACH.TOTAL_REQUIRED","Y",1)

			rem --- Initialize Firm Name field
			admFirms_dev=fnget_dev("ADM_FIRMS")
			dim admFirms$:fnget_tpl$("ADM_FIRMS")
			readrecord(admFirms_dev,key=firm_id$,dom=*next)admFirms$
			callpoint!.setColumnData("APS_ACH.FIRM_NAME",admFirms.firm_name$,1)

			rem --- Initialize Federal ID field
			apsReport_dev=fnget_dev("APS_REPORT")
			dim apsReport$:fnget_tpl$("APS_REPORT")
			readrecord(apsReport_dev,key=firm_id$+"AP02",dom=*next)apsReport$
			callpoint!.setColumnData("<<DISPLAY>>.FEDERAL_ID",apsReport.federal_id$,1)

			rem --- Enable non-bank account code fields
			callpoint!.setColumnEnabled("APS_ACH.TOTAL_REQUIRED",1)
			callpoint!.setColumnEnabled("APS_ACH.FIRM_NAME",1)
			callpoint!.setColumnEnabled("APS_ACH.ACH_EXPORT_DIR",1)
			callpoint!.setColumnEnabled("APS_ACH.ACH_CHECK_DIR",1)
		endif
	endif
[[APS_PARAMS.CURRENT_YEAR.AVAL]]
rem --- Verify calendar exists for entered AP fiscal year
	year$=callpoint!.getUserInput()
	if cvs(year$,2)<>"" and year$<>callpoint!.getColumnData("APS_PARAMS.CURRENT_YEAR") then
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
[[APS_PARAMS.CURRENT_PER.AVAL]]
rem --- Verify haven't exceeded calendar total periods for current AP fiscal year
	period$=callpoint!.getUserInput()
	if cvs(period$,2)<>"" and period$<>callpoint!.getColumnData("APS_PARAMS.CURRENT_PER") then
		period=num(period$)
		total_pers=num(callpoint!.getDevObject("total_pers"))
		if period<1 or period>total_pers then
			msg_id$="AD_BAD_FISCAL_PERIOD"
			dim msg_tokens$[2]
			msg_tokens$[1]=str(total_pers)
			msg_tokens$[2]=callpoint!.getColumnData("APS_PARAMS.CURRENT_YEAR")
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
	endif
[[APS_PARAMS.MULTI_TYPES.AVAL]]
rem --- Warn if Multiple AP Types is un-checked and there are already AP invoices in the system.
	multiTypes$=callpoint!.getUserInput()
	if multiTypes$="N" and callpoint!.getColumnData("APS_PARAMS.MULTI_TYPES")="Y" then
		rem --- Check APE_INVOICEHDR and APT_INVOICEHDR for invoices for this firm
		ape01_dev=fnget_dev("APE_INVOICEHDR")
		apt01_dev=fnget_dev("APT_INVOICEHDR")
		read(ape01_dev,key=firm_id$,dom=*next)
		ape01_key$=key(ape01_dev,end=*next)
		read(apt01_dev,key=firm_id$,dom=*next)
		apt01_key$=key(apt01_dev,end=*next)
		if pos(firm_id$=ape01_key$)=1 or pos(firm_id$=apt01_key$)=1 then
			msg_id$="AP_CHG_MTYPE_PARAM"
			gosub disp_message
			if msg_opt$<>"O" then
				callpoint!.setColumnData("APS_PARAMS.MULTI_TYPES","Y",1)
				callpoint!.setColumnEnabled("APS_PARAMS.AP_TYPE", 0)
				callpoint!.setStatus("ABORT")
				break
			endif
		endif
	endif

rem --- Disable ap_type when using multiple AP types
	if multiTypes$="Y" then
		callpoint!.setColumnEnabled("APS_PARAMS.AP_TYPE", 0)
	else
		callpoint!.setColumnEnabled("APS_PARAMS.AP_TYPE",1)
	endif
[[APS_PARAMS.AREC]]
rem --- Initialize new record
	callpoint!.setColumnData("APS_PARAMS.CUR_1099_YR",callpoint!.getColumnData("APS_PARAMS.CURRENT_YEAR"),1)
	callpoint!.setColumnData("APS_PARAMS.MULTI_TYPES","Y",1)
	callpoint!.setColumnData("APS_PARAMS.MULTI_DIST","Y",1)

	rem --- Disable non-bank account code fields on ACH Payments tab
	callpoint!.setColumnEnabled("APS_ACH.TOTAL_REQUIRED",0)
	callpoint!.setColumnEnabled("APS_ACH.FIRM_NAME",0)
	callpoint!.setColumnEnabled("APS_ACH.ACH_EXPORT_DIR",0)
	callpoint!.setColumnEnabled("APS_ACH.ACH_CHECK_DIR",0)
[[APS_PAYAUTH.WARN_IN_REGISTER.AVAL]]
rem --- Disable ok_to_update if not warning in register
	warn_in_register=num(callpoint!.getUserInput())
	gosub able_ok_to_update
[[APS_PARAMS.ADIS]]
rem --- Display selected colors
	RGB$=callpoint!.getColumnData("APS_PAYAUTH.ONE_AUTH_COLOR")
	gosub get_RGB
	valRGB!=SysGUI!.makeColor(R,G,B)
	one_color_ctl!=callpoint!.getDevObject("one_color_ctl")
	one_color_ctl!.setBackColor(valRGB!)

	RGB$=callpoint!.getColumnData("APS_PAYAUTH.TWO_AUTH_COLOR")
	gosub get_RGB
	valRGB!=SysGUI!.makeColor(R,G,B)
	two_color_ctl!=callpoint!.getDevObject("two_color_ctl")
	two_color_ctl!.setBackColor(valRGB!)

	RGB$=callpoint!.getColumnData("APS_PAYAUTH.ALL_AUTH_COLOR")
	gosub get_RGB
	valRGB!=SysGUI!.makeColor(R,G,B)
	all_color_ctl!=callpoint!.getDevObject("all_color_ctl")
	all_color_ctl!.setBackColor(valRGB!)

	rem --- Initialize bank account code fields
	bnk_acct_cd$=callpoint!.getColumnData("APS_ACH.BNK_ACCT_CD")
	if cvs(bnk_acct_cd$,2)<>"" then
		adcBankAcctCode_dev=fnget_dev("ADC_BANKACCTCODE")
		dim adcBankAcctCode$:fnget_tpl$("ADC_BANKACCTCODE")
		readrecord(adcBankAcctCode_dev,key=firm_id$+bnk_acct_cd$,dom=*next)adcBankAcctCode$
		callpoint!.setColumnData("<<DISPLAY>>.BANK_NAME",adcBankAcctCode.bank_name$,1)
		callpoint!.setColumnData("<<DISPLAY>>.ADDRESS_LINE_1",adcBankAcctCode.address_line_1$,1)
		callpoint!.setColumnData("<<DISPLAY>>.ADDRESS_LINE_2",adcBankAcctCode.address_line_2$,1)
		callpoint!.setColumnData("<<DISPLAY>>.ADDRESS_LINE_3",adcBankAcctCode.address_line_3$,1)
		callpoint!.setColumnData("<<DISPLAY>>.ACCT_DEST",adcBankAcctCode.acct_desc$,1)
		callpoint!.setColumnData("<<DISPLAY>>.ABA_NO",adcBankAcctCode.aba_no$,1)
		callpoint!.setColumnData("<<DISPLAY>>.BNK_ACCT_NO",adcBankAcctCode.bnk_acct_no$,1)
		callpoint!.setColumnData("<<DISPLAY>>.BNK_ACCT_TYPE",adcBankAcctCode.bnk_acct_type$,1)

		rem --- Initialize Federal ID field
		apsReport_dev=fnget_dev("APS_REPORT")
		dim apsReport$:fnget_tpl$("APS_REPORT")
		readrecord(apsReport_dev,key=firm_id$+"AP02",dom=*next)apsReport$
		callpoint!.setColumnData("<<DISPLAY>>.FEDERAL_ID",apsReport.federal_id$,1)
	endif
[[APS_PAYAUTH.ONE_AUTH_COLOR.AMOD]]
rem --- Display selected color
	RGB$=callpoint!.getColumnData("APS_PAYAUTH.ONE_AUTH_COLOR")
	gosub get_RGB
	valRGB!=SysGUI!.makeColor(R,G,B)
	one_color_ctl!=callpoint!.getDevObject("one_color_ctl")
	one_color_ctl!.setBackColor(valRGB!)
[[APS_PAYAUTH.SCAN_DOCS_TO.AVAL]]
rem --- Restrict selection to currently available options
	scan_docs_to$=callpoint!.getUserInput()
	if pos(scan_docs_to$="NOTGD BDA",3)=0 then
		callpoint!.setMessage("AD_OPTION_NOT")
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Enable/Disable WARN_IN_REGISTER and OK_TO_UPDATE
	gosub able_scan_docs
[[APS_PAYAUTH.ALL_AUTH_COLOR.AMOD]]
rem --- Display selected color
	RGB$=callpoint!.getColumnData("APS_PAYAUTH.ALL_AUTH_COLOR")
	gosub get_RGB
	valRGB!=SysGUI!.makeColor(R,G,B)
	all_color_ctl!=callpoint!.getDevObject("all_color_ctl")
	all_color_ctl!.setBackColor(valRGB!)
[[APS_PAYAUTH.TWO_AUTH_COLOR.AMOD]]
rem --- Display selected color
	RGB$=callpoint!.getColumnData("APS_PAYAUTH.TWO_AUTH_COLOR")
	gosub get_RGB
	valRGB!=SysGUI!.makeColor(R,G,B)
	two_color_ctl!=callpoint!.getDevObject("two_color_ctl")
	two_color_ctl!.setBackColor(valRGB!)
[[APS_PARAMS.AWIN]]
	use ::ado_util.src::util
[[APS_PARAMS.BFMC]]
rem --- Initialize COLOR lists
	ldat$=""
	ldat$=ldat$+"Gray"+"~"+"128,128,128"+";"
	ldat$=ldat$+"Green-Yellow"+"~"+"173,255,047"+";"
	ldat$=ldat$+"Light Blue"+"~"+"173,216,230"+";"
	ldat$=ldat$+"Light Gray"+"~"+"211,211,211"+";"
	ldat$=ldat$+"Light Green"+"~"+"144,238,144"+";"
	ldat$=ldat$+"Light Lavender"+"~"+"200,173,232"+";"
	ldat$=ldat$+"Light Pink"+"~"+"255,182,193"+";"
	ldat$=ldat$+"Orange"+"~"+"255,165,000"+";"
	ldat$=ldat$+"Red"+"~"+"255,000,000"+";"
	ldat$=ldat$+"White"+"~"+"255,255,255"+";"
	ldat$=ldat$+"Yellow"+"~"+"255,255,000"+";"
	callpoint!.setTableColumnAttribute("APS_PAYAUTH.ALL_AUTH_COLOR","LDAT",ldat$)
	callpoint!.setTableColumnAttribute("APS_PAYAUTH.ONE_AUTH_COLOR","LDAT",ldat$)
	callpoint!.setTableColumnAttribute("APS_PAYAUTH.TWO_AUTH_COLOR","LDAT",ldat$)
[[APS_PAYAUTH.TWO_SIG_REQ.AVAL]]
rem --- Enable/Disable TWO_SIG_AMT and TWO_AUTH_COLOR (and initialize TWO_AUTH_COLOR)
	two_sig_req=num(callpoint!.getUserInput())
	gosub able_two_sig
[[APS_PAYAUTH.USE_PAY_AUTH.AVAL]]
rem --- Enable/Disable Payment Authorization
	use_pay_auth=num(callpoint!.getUserInput())
	gosub able_payauth
[[APS_PARAMS.BSHO]]
rem --- Open files

	num_files=7
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APE_INVOICEHDR",open_opts$[1]="OTA"
	open_tables$[2]="APT_INVOICEHDR",open_opts$[2]="OTA"
	open_tables$[3]="GLS_CALENDAR",open_opts$[3]="OTA"
	open_tables$[4]="ADC_BANKACCTCODE",open_opts$[4]="OTA"
	open_tables$[5]="APS_REPORT",open_opts$[5]="OTA"
	open_tables$[6]="ADM_FIRMS",open_opts$[6]="OTA"
	open_tables$[7]="APW_CHECKINVOICE",open_opts$[7]="OTA"

	gosub open_tables

rem --- Disable fields based on params

	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
	gl_installed$=info$[20]
	callpoint!.setDevObject("gl_installed",gl_installed$)
	if gl_installed$<>"Y" then callpoint!.setColumnEnabled("APS_PARAMS.POST_TO_GL",-1)

	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","PO",info$[all]
	po_installed$=info$[20]
	callpoint!.setDevObject("po_installed",po_installed$)
	if po_installed$<>"Y" then callpoint!.setColumnEnabled("APS_PARAMS.USE_REPLEN",-1)

rem --- ALL_AUTH_COLOR background color displays
	ctl_name$="APS_PAYAUTH.ALL_AUTH_COLOR"
	gosub make_color_display
	callpoint!.setDevObject("all_color_ctl",color_display_ctl!)

rem --- ONE_AUTH_COLOR background color displays
	ctl_name$="APS_PAYAUTH.ONE_AUTH_COLOR"
	gosub make_color_display
	callpoint!.setDevObject("one_color_ctl",color_display_ctl!)

rem --- TWO_AUTH_COLOR background color displays
	ctl_name$="APS_PAYAUTH.TWO_AUTH_COLOR"
	gosub make_color_display
	callpoint!.setDevObject("two_color_ctl",color_display_ctl!)
[[APS_PARAMS.<CUSTOM>]]
#include std_missing_params.src

rem =========================================================
able_payauth: rem --- Enable/Disable Payment Authorization
	rem --- input: use_pay_auth
rem =========================================================
	callpoint!.setColumnEnabled("APS_PAYAUTH.SEND_EMAIL",use_pay_auth)
	callpoint!.setColumnEnabled("APS_PAYAUTH.SCAN_DOCS_TO",use_pay_auth)
	callpoint!.setColumnEnabled("APS_PAYAUTH.ALL_AUTH_COLOR",use_pay_auth)
	callpoint!.setColumnEnabled("APS_PAYAUTH.ONE_AUTH_COLOR",use_pay_auth)
	callpoint!.setColumnEnabled("APS_PAYAUTH.TWO_AUTH_COLOR",use_pay_auth)
	callpoint!.setColumnEnabled("APS_PAYAUTH.WARN_IN_REGISTER",use_pay_auth)
	callpoint!.setColumnEnabled("APS_PAYAUTH.OK_TO_UPDATE",use_pay_auth)
	callpoint!.setColumnEnabled("APS_PAYAUTH.TWO_SIG_REQ",use_pay_auth)
	callpoint!.setColumnEnabled("APS_PAYAUTH.TWO_SIG_AMT",use_pay_auth)

	if use_pay_auth then
		rem --- Initialize SCAN_DOCS_TO
		if cvs(callpoint!.getColumnData("APS_PAYAUTH.SCAN_DOCS_TO"),2)="" then
			callpoint!.setColumnData("APS_PAYAUTH.SCAN_DOCS_TO","NOT",1); rem --- Not scanned
		endif

		rem --- Enable/Disable WARN_IN_REGISTER and OK_TO_UPDATE
		scan_docs_to$=callpoint!.getColumnData("APS_PAYAUTH.SCAN_DOCS_TO")
		gosub able_scan_docs

		rem --- Initialize ALL_AUTH_COLOR
		if cvs(callpoint!.getColumnData("APS_PAYAUTH.ALL_AUTH_COLOR"),2)="" then
			callpoint!.setColumnData("APS_PAYAUTH.ALL_AUTH_COLOR","255,255,255",1); rem --- White
			valRGB!=SysGUI!.makeColor(255,255,255)
			all_color_ctl!=callpoint!.getDevObject("all_color_ctl")
			all_color_ctl!.setBackColor(valRGB!)
		endif

		rem --- Initialize ONE_AUTH_COLOR
		if cvs(callpoint!.getColumnData("APS_PAYAUTH.ONE_AUTH_COLOR"),2)="" then
			callpoint!.setColumnData("APS_PAYAUTH.ONE_AUTH_COLOR","211,211,211",1); rem --- Light Gray
			valRGB!=SysGUI!.makeColor(211,211,211)
			one_color_ctl!=callpoint!.getDevObject("one_color_ctl")
			one_color_ctl!.setBackColor(valRGB!)
		endif

		rem --- Enable/Disable TWO_SIG_AMT and TWO_AUTH_COLOR (and initialize TWO_AUTH_COLOR)
		two_sig_req=num(callpoint!.getColumnData("APS_PAYAUTH.TWO_SIG_REQ"))
		gosub able_two_sig

	endif
	return

rem =========================================================
able_ok_to_update: rem --- Enable/Disable OK_TO_UPDATE
	rem --- input: warn_in_register
rem =========================================================
	if warn_in_register then
		callpoint!.setColumnEnabled("APS_PAYAUTH.OK_TO_UPDATE",1)
	else
		callpoint!.setColumnData("APS_PAYAUTH.OK_TO_UPDATE","0",1)
		callpoint!.setColumnEnabled("APS_PAYAUTH.OK_TO_UPDATE",0)
	endif
	return

rem =========================================================
able_two_sig: rem --- Enable/Disable TWO_SIG_AMT and TWO_AUTH_COLOR (and initialize TWO_AUTH_COLOR)
	rem --- input: two_sig_req
rem =========================================================
	callpoint!.setColumnEnabled("APS_PAYAUTH.TWO_SIG_AMT",two_sig_req)
	callpoint!.setColumnEnabled("APS_PAYAUTH.TWO_AUTH_COLOR",two_sig_req)

	rem --- Initialize TWO_AUTH_COLOR
	if two_sig_req and cvs(callpoint!.getColumnData("APS_PAYAUTH.TWO_AUTH_COLOR"),2)="" then
		callpoint!.setColumnData("APS_PAYAUTH.TWO_AUTH_COLOR","200,173,232",1); rem --- Light Lavender
			valRGB!=SysGUI!.makeColor(200,173,232)
			two_color_ctl!=callpoint!.getDevObject("two_color_ctl")
			two_color_ctl!.setBackColor(valRGB!)
	endif
	return

rem =========================================================
able_scan_docs: rem --- Enable/Disable WARN_IN_REGISTER and OK_TO_UPDATE
	rem --- input: scan_docs_to$
rem =========================================================
	if scan_docs_to$="NOT" then
		rem --- Disable if not scanning invoices
		callpoint!.setColumnData("APS_PAYAUTH.WARN_IN_REGISTER","0",1)
		callpoint!.setColumnEnabled("APS_PAYAUTH.WARN_IN_REGISTER",0)
		callpoint!.setColumnData("APS_PAYAUTH.OK_TO_UPDATE","0",1)
		callpoint!.setColumnEnabled("APS_PAYAUTH.OK_TO_UPDATE",0)
	else
		rem --- Enable if scanning invoices
		callpoint!.setColumnEnabled("APS_PAYAUTH.WARN_IN_REGISTER",1)
		rem --- Disable ok_to_update if not warning in register
		warn_in_register=num(callpoint!.getColumnData("APS_PAYAUTH.WARN_IN_REGISTER"))
		gosub able_ok_to_update
	endif
	return

rem =========================================================
make_color_display: rem --- Make control for displaying color next to given control
	rem --- input: ctl_name$
	rem --- output: color_display_ctl!
rem =========================================================
	ctlContext=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI"))
	control!=SysGUI!.getWindow(ctlContext).getControl(ctlID)
	childWin!=SysGUI!.getWindow(ctlContext).getControl(0)
	save_ctx=SysGUI!.getContext()
	SysGUI!.setContext(ctlContext)
	nxt_ctlID=util.getNextControlID()
	color_display_ctl!=childWin!.addEditBox(nxt_ctlID,control!.getX()+control!.getWidth()+10,control!.getY(),4*20,20,"",$$)
	color_display_ctl!.setEnabled(0)
	SysGUI!.setContext(save_ctx)
	return

rem =========================================================
get_RGB: rem --- Parse Red, Green and Blue segments from RGB$ string
	rem --- input: RGB$
	rem --- output: R
	rem --- output: G
	rem --- output: B
rem =========================================================
	comma1=pos(","=RGB$,1,1)
	comma2=pos(","=RGB$,1,2)
	R=num(RGB$(1,comma1-1))
	G=num(RGB$(comma1+1,comma2-comma1-1))
	B=num(RGB$(comma2+1))
	return

rem =========================================================
fix_path: rem --- Flip directory path separators
	rem --- input: filePath$
rem =========================================================

	pos=pos("\"=filePath$)
	while pos
		filePath$=filePath$(1, pos-1)+"/"+filePath$(pos+1)
		pos=pos("\"=filePath$)
	wend
	return
[[APS_PARAMS.ARAR]]
rem --- Open/Lock files
	pgmdir$=stbl("+DIR_PGM")
	files=2,begfile=1,endfile=files
	dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
	files$[1]="aps_params",ids$[1]="APS_PARAMS"
	files$[2]="gls_params",ids$[2]="GLS_PARAMS"
	call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
	if status then
		remove_process_bar:
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
	 	release
	endif

	aps01_dev=channels[1]
	gls01_dev=channels[2]
rem --- Dimension string templates
	dim aps01a$:templates$[1],gls01a$:templates$[2]

rem --- check to see if main GL param rec (firm/GL/00) exists; if not, tell user to set it up first
	gls01a_key$=firm_id$+"GL00"
	find record (gls01_dev,key=gls01a_key$,err=*next) gls01a$  
	if cvs(gls01a.current_per$,2)=""
		msg_id$="GL_PARAM_ERR"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		gosub remove_process_bar
		release
	endif

rem --- Retrieve parameter data
	gl_installed$=callpoint!.getDevObject("gl_installed")
	po_installed$=callpoint!.getDevObject("po_installed")
	rem --- set some defaults (that I can't do via arde) if param doesn't yet exist
	aps01a_key$=firm_id$+"AP00"
	find record (aps01_dev,key=aps01a_key$,err=*next) aps01a$
	if cvs(aps01a.current_per$,2)=""
		callpoint!.setColumnData("APS_PARAMS.CURRENT_PER",gls01a.current_per$)
		callpoint!.setColumnUndoData("APS_PARAMS.CURRENT_PER",gls01a.current_per$)
		callpoint!.setColumnData("APS_PARAMS.CURRENT_YEAR",gls01a.current_year$)
		callpoint!.setColumnUndoData("APS_PARAMS.CURRENT_YEAR",gls01a.current_year$)
		callpoint!.setColumnData("APS_PARAMS.VENDOR_SIZE",
:			callpoint!.getColumnData("APS_PARAMS.MAX_VENDOR_LEN"))
		callpoint!.setColumnUndoData("APS_PARAMS.VENDOR_SIZE",
:                     	callpoint!.getColumnData("APS_PARAMS.MAX_VENDOR_LEN"))
		if gl_installed$="Y" then
			callpoint!.setColumnData("APS_PARAMS.POST_TO_GL","Y")
			callpoint!.setColumnData("APS_PARAMS.BR_INTERFACE","Y")
		endif
   		callpoint!.setStatus("MODIFIED-REFRESH")
	else
		rem --- Update post_to_gl if GL is uninstalled
		if gl_installed$<>"Y" and callpoint!.getColumnData("APS_PARAMS.POST_TO_GL")="Y" then 
			callpoint!.setColumnData("APS_PARAMS.POST_TO_GL","N",1)
   			callpoint!.setStatus("MODIFIED")
		endif

		rem --- Update use_replen if PO is uninstalled
		if po_installed$<>"Y" and callpoint!.getColumnData("APS_PARAMS.USE_REPLEN")="Y" then 
			callpoint!.setColumnData("APS_PARAMS.USE_REPLEN","N",1)
   			callpoint!.setStatus("MODIFIED")
		endif
	endif

rem --- Enable/Disable Payment Authorization
	use_pay_auth=num(callpoint!.getColumnData("APS_PAYAUTH.USE_PAY_AUTH"))
	gosub able_payauth

rem --- Set maximum number of periods allowed for this fiscal year
	gls_calendar_dev=fnget_dev("GLS_CALENDAR")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
	current_year$=callpoint!.getColumnData("APS_PARAMS.CURRENT_YEAR")
	readrecord(gls_calendar_dev,key=firm_id$+current_year$,dom=*next)gls_calendar$
	callpoint!.setDevObject("total_pers",gls_calendar.total_pers$)
