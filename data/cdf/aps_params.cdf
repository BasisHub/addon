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
	if pos(scan_docs_to$="NOTGD ",3)=0 then
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

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APE_INVOICEHDR",open_opts$[1]="OTA"
	open_tables$[2]="APt_INVOICEHDR",open_opts$[2]="OTA"

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
	call stbl("+DIR_PGM")+"adc_application.aon","IV",info$[all]
	iv$=info$[20]
	dim user_tpl$:"app:c(2),gl_pers:c(2),gl_installed:c(1),iv_installed:c(1)"
	user_tpl.app$="AP"
	user_tpl.gl_pers$=gls01a.total_pers$
	user_tpl.gl_installed$=gl_installed$
	user_tpl.iv_installed$=iv$
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
