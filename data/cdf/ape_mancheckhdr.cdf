[[APE_MANCHECKHDR.VENDOR_ID.BINQ]]
rem --- Set filter_defs$[] to only show vendors of given AP Type

ap_type$=callpoint!.getColumnData("APE_MANCHECKHDR.AP_TYPE")

dim filter_defs$[2,2]
filter_defs$[0,0]="APM_VENDMAST.FIRM_ID"
filter_defs$[0,1]="='"+firm_id$+"'"
filter_defs$[0,2]="LOCK"

filter_defs$[1,0]="APM_VENDHIST.AP_TYPE"
filter_defs$[1,1]="='"+ap_type$+"'"
filter_defs$[1,2]="LOCK"


call STBL("+DIR_SYP")+"bax_query.bbj",
:		gui_dev, 
:		form!,
:		"AP_VEND_LK",
:		"DEFAULT",
:		table_chans$[all],
:		sel_key$,
:		filter_defs$[all]

if sel_key$<>""
	call stbl("+DIR_SYP")+"bac_key_template.bbj",
:		"APM_VENDMAST",
:		"PRIMARY",
:		apm_vend_key$,
:		table_chans$[all],
:		status$
	dim apm_vend_key$:apm_vend_key$
	apm_vend_key$=sel_key$
	callpoint!.setColumnData("APE_MANCHECKHDR.VENDOR_ID",apm_vend_key.vendor_id$,1)
endif	
callpoint!.setStatus("ACTIVATE-ABORT")
[[APE_MANCHECKHDR.CHECK_NO.AVAL]]
rem --- Look in entry file for this check number.
rem --- If found, use setStatus("RECORD") to call it up. (bug 8510)
rem --- If not found, then look in check history.
rem --- If found there, then offer to do reversal or re-use check number, depending on check type.
rem --- (if open Computer or Manual check, can reverse; if already a Void or Reversal, offer to reuse check#)

	batch_no$=callpoint!.getColumnData("APE_MANCHECKHDR.BATCH_NO")
	ap_type$=callpoint!.getColumnData("APE_MANCHECKHDR.AP_TYPE")
	check_no$=callpoint!.getUserInput()
	tmpky$=""

	ape_mancheckhdr=fnget_dev("APE_MANCHECKHDR")

	read (ape_mancheckhdr,key=firm_id$+batch_no$+ap_type$+check_no$,dom=*next)
	tmpky$=key(ape_mancheckhdr,end=*next)
	if pos(firm_id$+batch_no$+ap_type$+check_no$=tmpky$)=1
		callpoint!.setStatus("RECORD:["+tmpky$+"]")
		break
	endif

rem --- not found in entry file, so see if in open checks

	if cvs(check_no$,3)<>""
	rem --- above used to be if user_tpl.open_check$<>"Y" and cvs(check_no$,3)<>"" - disable the flag check so it always asks
		apt05_dev = fnget_dev("APT_CHECKHISTORY")
		dim apt05a$:fnget_tpl$("APT_CHECKHISTORY")

		read (apt05_dev,key=firm_id$+ap_type$+check_no$+vendor_id$,dom=*next)
		readrecord (apt05_dev,end=*next)apt05a$

		if apt05a.firm_id$=firm_id$  and apt05a.ap_type$=ap_type$  and apt05a.check_no$=check_no$

			user_tpl.open_check$="Y"; rem don't check again - disabled for bug 8510
			vendor_id$=apt05a.vendor_id$

			rem --- Reverse? (Check is Manual or Computer generated)

			if pos(apt05a.trans_type$="CM") then
				msg_id$="AP_REVERSE"
				msg_opt$=""
				gosub disp_message

				if msg_opt$="Y"
					callpoint!.setColumnData("APE_MANCHECKHDR.TRANS_TYPE","R")
					callpoint!.setColumnUndoData("APE_MANCHECKHDR.TRANS_TYPE","R")
					ctl_name$="APE_MANCHECKHDR.AP_TYPE"
					ctl_stat$="D"
					gosub disable_fields
					ctl_name$="APE_MANCHECKHDR.CHECK_NO"
					ctl_stat$="D"
					gosub disable_fields
					ctl_name$="APE_MANCHECKHDR.TRANS_TYPE"
					ctl_stat$="D"
					gosub disable_fields
					ctl_name$="APE_MANCHECKHDR.VENDOR_ID"
					gosub disable_fields
					callpoint!.setColumnData("APE_MANCHECKHDR.CHECK_DATE",apt05a.check_date$)
					callpoint!.setColumnData("APE_MANCHECKHDR.VENDOR_ID",vendor_id$)
					tmp_vendor_id$=vendor_id$
					gosub disp_vendor_comments
					gosub disable_grid
					callpoint!.setStatus("MODIFIED")
				else
					callpoint!.setStatus("ABORT")
				endif
			else
				rem --- Recycle? (check is Void or Reversed)
				
				if pos(apt05a.trans_type$="VR") then

					msg_id$="AP_OPEN_CHK"
					msg_opt$=""
					gosub disp_message

					if msg_opt$="Y"
						user_tpl.reuse_chk$="Y"
						callpoint!.setColumnData("APE_MANCHECKHDR.TRANS_TYPE","M")
						callpoint!.setStatus("REFRESH")
					else
						callpoint!.setStatus("ABORT")
					endif
				endif
			endif
		endif
	endif
[[APE_MANCHECKHDR.ADEL]]
rem --- Verify all G/L Distribution records get deleted

	ape12_dev=fnget_dev("APE_MANCHECKDIST")
	ap_type$=callpoint!.getColumnData("APE_MANCHECKHDR.AP_TYPE")
	check_no$=callpoint!.getColumnData("APE_MANCHECKHDR.CHECK_NO")
	vend$=callpoint!.getColumnData("APE_MANCHECKHDR.VENDOR_ID")

	read(ape12_dev,key=firm_id$+ap_type$+check_no$+vend$,dom=*next)
	while 1
		ape12_key$=key(ape12_dev,end=*break)
		read(ape12_dev)
		if pos(firm_id$+ap_type$+check_no$+vend$=ape12_key$)<>1 break
		remove (ape12_dev,key=ape12_key$)
	wend
[[APE_MANCHECKHDR.AP_TYPE.AVAL]]
user_tpl.dflt_ap_type$=callpoint!.getUserInput()
if user_tpl.dflt_ap_type$=""
	user_tpl.dflt_ap_type$="  "
	callpoint!.setUserInput(user_tpl.dflt_ap_type$)
	callpoint!.setStatus("REFRESH")
endif

apm10_dev=fnget_dev("APC_TYPECODE")
dim apm10a$:fnget_tpl$("APC_TYPECODE")
readrecord (apm10_dev,key=firm_id$+"A"+user_tpl.dflt_ap_type$,dom=*next)apm10a$
if cvs(apm10a$,2)<>""
	user_tpl.dflt_dist_cd$=apm10a.ap_dist_code$
endif
[[APE_MANCHECKHDR.BPFX]]
rem --- don't allow access to the grid if doing a void or reversal
rem --- there is a disable_grid routine which works, but F7 still tries to jump there and causes Barista error

if pos(callpoint!.getColumnData("APE_MANCHECKHDR.TRANS_TYPE")="RV")<>0
	callpoint!.setStatus("ABORT")
endif
[[APE_MANCHECKHDR.VENDOR_ID.BINP]]
rem --- set devObject with AP Type and a temp vend indicator, so if we decide to set up a temporary vendor from here,
rem --- we'll know which AP type to use, and we can automatically set the temp vendor flag in the vendor master

callpoint!.setDevObject("passed_in_temp_vend","Y")
callpoint!.setDevObject("passed_in_AP_type",callpoint!.getColumnData("APE_MANCHECKHDR.AP_TYPE"))
[[APE_MANCHECKHDR.BEND]]
rem --- remove software lock on batch, if batching

	batch$=stbl("+BATCH_NO",err=*next)
	if num(batch$)<>0
		lock_table$="ADM_PROCBATCHES"
		lock_record$=firm_id$+stbl("+PROCESS_ID")+batch$
		lock_type$="X"
		lock_status$=""
		lock_disp$=""
		call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$
	endif

rem --- remove images copied temporarily to web servier for viewing

	urlVect!=callpoint!.getDevObject("urlVect")
	if urlVect!.size()
		for wk=0 to urlVect!.size()-1
			BBUtils.deleteFromWebServer(urlVect!.get(wk))
		next wk
	endif
[[APE_MANCHECKHDR.BTBL]]
rem --- Get Batch information

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]
callpoint!.setTableColumnAttribute("APE_MANCHECKHDR.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[APE_MANCHECKHDR.BWRI]]
rem --- make sure we have entered mandatory elements of header, and that ap_type/vendor are valid together

dont_write$=""

if cvs(callpoint!.getColumnData("APE_MANCHECKHDR.CHECK_DATE"),3)="" or
:	cvs(callpoint!.getColumnData("APE_MANCHECKHDR.CHECK_NO"),3)="" or
:	(cvs(callpoint!.getColumnData("APE_MANCHECKHDR.VENDOR_ID"),3)="" and callpoint!.getColumnData("APE_MANCHECKHDR.TRANS_TYPE")<>"V") then
	dont_write$="Y"
endif

if cvs(callpoint!.getColumnData("APE_MANCHECKHDR.VENDOR_ID"),3)<>"" then
	vend_hist$=""
	tmp_vendor_id$=callpoint!.getColumnData("APE_MANCHECKHDR.VENDOR_ID")
	gosub get_vendor_history
	if vend_hist$<>"Y" then dont_write$="Y"
endif

if dont_write$="Y"
	msg_id$="AP_MANCHKWRITE"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
[[APE_MANCHECKHDR.AABO]]
rem --- need to go thru gridVect!; any record NOT already in ape-22 (detail) should be removed from ape-12 (gl dist)
rem --- this can happen in this program, since dist grid is launched/handled from dtl grid -- we might write out
rem --- one or more ape-12 recs, then come back to main form and abort, which won't save the ape-22 recs...
	recVect!=gridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs=recVect!.size()
	ape12_dev=fnget_dev("APE_MANCHECKDIST")
	ape22_dev=fnget_dev("@APE_MANCHECKDET")

	if numrecs>0
		for reccnt=0 to numrecs-1
			gridrec$=recVect!.getItem(reccnt)
			if cvs(gridrec$,3)<>""
				remove_ky$=firm_id$+gridrec.ap_type$+gridrec.check_no$+gridrec.vendor_id$+gridrec.ap_inv_no$
				ape22_ky$=remove_ky$+"00"
				read(ape22_dev,key=ape22_ky$,dom=*next);continue
				read (ape12_dev,key=remove_ky$,dom=*next)
				while 1
					k$=key(ape12_dev,end=*break)
					if pos(remove_ky$=k$)<>1 then break
					remove(ape12_dev,key=k$)
				wend
			endif
		next reccnt		
	endif
[[APE_MANCHECKHDR.<CUSTOM>]]
disp_vendor_comments:
	apm01_dev=fnget_dev("APM_VENDMAST")
	dim apm01a$:fnget_tpl$("APM_VENDMAST")
	readrecord(apm01_dev,key=firm_id$+tmp_vendor_id$,dom=*next)apm01a$
	callpoint!.setColumnData("<<DISPLAY>>.comments",apm01a.memo_1024$,1)
return

disable_grid:
	w!=Form!.getChildWindow(1109)
	c!=w!.getControl(5900)
	c!.setEnabled(0)
return

enable_grid:
	w!=Form!.getChildWindow(1109)
	c!=w!.getControl(5900)
	c!.setEnabled(1)
return

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

calc_tots:
	recVect!=GridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs=recVect!.size()
	tinv=0,tdisc=0,tret=0
	if numrecs>0
		for reccnt=0 to numrecs-1
			gridrec$=recVect!.getItem(reccnt)
			tinv=tinv+gridrec.invoice_amt
			tdisc=tdisc+gridrec.discount_amt
			tret=tret+gridrec.retention
		next reccnt
	endif
return

disp_tots:
    rem --- get context and ID of display controls for totals, and redisplay w/ amts from calc_tots
    
    tinv!=UserObj!.getItem(num(user_tpl.tinv_vpos$))
    tinv!.setValue(tinv)
    tdisc!=UserObj!.getItem(num(user_tpl.tdisc_vpos$))
    tdisc!.setValue(tdisc)
    tret!=UserObj!.getItem(num(user_tpl.tret_vpos$))
    tret!.setValue(tret)
    tchk!=UserObj!.getItem(num(user_tpl.tchk_vpos$))
    tchk!.setValue(tinv-tdisc-tret)
    return

get_vendor_history:
	apm02_dev=fnget_dev("APM_VENDHIST")				
	dim apm02a$:fnget_tpl$("APM_VENDHIST")
	vend_hist$=""
	readrecord(apm02_dev,key=firm_id$+tmp_vendor_id$+
:		callpoint!.getColumnData("APE_MANCHECKHDR.AP_TYPE"),dom=*next)apm02a$
	if apm02a.firm_id$+apm02a.vendor_id$+apm02a.ap_type$=firm_id$+tmp_vendor_id$+
:		callpoint!.getColumnData("APE_MANCHECKHDR.AP_TYPE")
			user_tpl.dflt_dist_cd$=apm02a.ap_dist_code$
			user_tpl.dflt_gl_account$=apm02a.gl_account$
			callpoint!.setDevObject("dflt_gl",apm02a.gl_account$)
			callpoint!.setDevObject("dflt_dist",apm02a.ap_dist_code$)
			vend_hist$="Y"
	endif
return

#include std_missing_params.src
#include std_functions.src
[[APE_MANCHECKHDR.VENDOR_ID.AVAL]]
	print "Head: VENDOR_ID.AVAL (After Column Validation)"; rem debug
	rem "VENDOR INACTIVE - FEATURE"
	vendor_id$ = callpoint!.getUserInput()
	apm01_dev=fnget_dev("APM_VENDMAST")
	apm01_tpl$=fnget_tpl$("APM_VENDMAST")
	dim apm01a$:apm01_tpl$
	apm01a_key$=firm_id$+vendor_id$
	find record (apm01_dev,key=apm01a_key$,err=*break) apm01a$
	if apm01a.vend_inactive$="Y" then
	   call stbl("+DIR_PGM")+"adc_getmask.aon","VENDOR_ID","","","",m0$,0,vendor_size
	   msg_id$="AP_VEND_INACTIVE"
	   dim msg_tokens$[2]
	   msg_tokens$[1]=fnmask$(apm01a.vendor_id$(1,vendor_size),m0$)
	   msg_tokens$[2]=cvs(apm01a.vendor_name$,2)
	   gosub disp_message
	   callpoint!.setStatus("ACTIVATE")
	endif
	tmp_vendor_id$=callpoint!.getUserInput()			
	gosub disp_vendor_comments
	gosub get_vendor_history
	if vend_hist$=""
		if user_tpl.multi_types$="Y"
			msg_id$="AP_VEND_BAD_APTYPE"
			gosub disp_message
			callpoint!.setStatus("CLEAR;NEWREC")
		endif
	endif
[[APE_MANCHECKHDR.TRANS_TYPE.AVAL]]
print "in trans type aval"
if callpoint!.getUserInput()="R"
	msg_id$="AP_REUSE_ERR"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
if callpoint!.getUserInput()="V"
	ctl_name$="APE_MANCHECKHDR.VENDOR_ID"
	ctl_stat$="D"
	gosub disable_fields
	gosub disable_grid							
endif
						
if callpoint!.getUserInput()="M"
	ctl_name$="APE_MANCHECKHDR.VENDOR_ID"
	ctl_stat$=" "
	gosub disable_fields
	gosub enable_grid							
endif
[[APE_MANCHECKHDR.CHECK_DATE.AVAL]]
print "in check date aval"

gl$=user_tpl.glint$
ckdate$=callpoint!.getUserInput()

if gl$="Y"
	if user_tpl.glyr$<>""
		call stbl("+DIR_PGM")+"glc_datecheck.aon",ckdate$,"N",per$,yr$,status
		if user_tpl.glyr$<>yr$ or user_tpl.glper$<>per$
			call stbl("+DIR_PGM")+"glc_datecheck.aon",ckdate$,"Y",per$,yr$,status
			if status>99
				callpoint!.setStatus("ABORT")
			else
				user_tpl.glyr$=yr$
				user_tpl.glper$=per$
			endif
		endif
	endif
endif
[[APE_MANCHECKHDR.BSHO]]
rem --- Disable ap type control if param for multi-types is N

	if user_tpl.multi_types$="N" 
		ctl_name$="APE_MANCHECKHDR.AP_TYPE"
		ctl_stat$="I"
		gosub disable_fields
	endif

rem --- Disable button

	callpoint!.setOptionEnabled("OINV",0)
[[APE_MANCHECKHDR.AWIN]]
rem print 'show',; rem debug

	use ::BBUtils.bbj::BBUtils

rem --- Open/Lock files
	files=30,begfile=1,endfile=15
	dim files$[files],options$[files],chans$[files],templates$[files]
	files$[1]="APE_MANCHECKHDR",options$[1]="OTA"
	files$[2]="APE_MANCHECKDIST",options$[2]="OTA"
	files$[3]="APE_MANCHECKDET",options$[3]="OTAN";rem --- "ape-22, channel stored in user_tpl$ and used in detail grid callpoints when reading by AO_VEND_INV key
	files$[4]="APM_VENDMAST",options$[4]="OTA"
	files$[5]="APM_VENDHIST",options$[5]="OTA"
	files$[6]="APT_INVOICEHDR",options$[6]="OTA"
	files$[7]="APT_INVOICEDET",options$[7]="OTA"
	files$[8]="APT_CHECKHISTORY",options$[8]="OTA"
	files$[9]="APC_TYPECODE",options$[9]="OTA"
	rem files$[10]="",options$[10]=""
	files$[11]="APS_PARAMS",options$[11]="OTA"
	files$[12]="GLS_PARAMS",options$[12]="OTA"
	files$[13]="APS_PAYAUTH",options$[13]="OTA@"
	files$[14]="APT_INVIMAGE",options$[14]="OTA[1]"
	files$[15]="APE_MANCHECKDET",options$[15]="OTA@";rem --- "ape-22, used in AABO to compare grid against what's on disk

	call stbl("+DIR_SYP")+"bac_open_tables.bbj",
:		begfile,
:		endfile,
:		files$[all],
:		options$[all],
:		chans$[all],
:		templates$[all],
:		table_chans$[all],
:		batch,
:		status$
	if status$<>"" then
		remove_process_bar:
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif

	aps01_dev=num(chans$[11])
	gls01_dev=num(chans$[12])
	aps_payauth=num(chans$[13])
	dim aps01a$:templates$[11],gls01a$:templates$[12],aps_payauth$:templates$[13]

	user_tpl_str$="firm_id:c(2),glint:c(1),glyr:c(4),glper:c(2),glworkfile:c(16),"
	user_tpl_str$=user_tpl_str$+"amt_msk:c(15),multi_types:c(1),multi_dist:c(1),ret_flag:c(1),"
	user_tpl_str$=user_tpl_str$+"misc_entry:c(1),post_closed:c(1),units_flag:c(1),"
	user_tpl_str$=user_tpl_str$+"existing_tran:c(1),open_check:c(1),existing_invoice:c(1),reuse_chk:c(1),"
	user_tpl_str$=user_tpl_str$+"dflt_ap_type:c(2),dflt_dist_cd:c(2),dflt_gl_account:c(10),"
	user_tpl_str$=user_tpl_str$+"tinv_vpos:c(1),tdisc_vpos:c(1),tret_vpos:c(1),tchk_vpos:c(1),"
	user_tpl_str$=user_tpl_str$+"ap_type_vpos:c(1),vendor_id_vpos:c(1),ape22_dev1:n(5)"

	dim user_tpl$:user_tpl_str$
	user_tpl.firm_id$=firm_id$
	user_tpl.ape22_dev1=num(chans$[3])

rem --- set up UserObj! as vector

	UserObj!=SysGUI!.makeVector()
	
	ctlContext=num(callpoint!.getTableColumnAttribute("<<DISPLAY>>.DISP_TOT_INV","CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute("<<DISPLAY>>.DISP_TOT_INV","CTLI"))
	tinv!=SysGUI!.getWindow(ctlContext).getControl(ctlID)

	ctlContext=num(callpoint!.getTableColumnAttribute("<<DISPLAY>>.DISP_TOT_DISC","CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute("<<DISPLAY>>.DISP_TOT_DISC","CTLI"))
	tdisc!=SysGUI!.getWindow(ctlContext).getControl(ctlID)

	ctlContext=num(callpoint!.getTableColumnAttribute("<<DISPLAY>>.DISP_TOT_RETEN","CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute("<<DISPLAY>>.DISP_TOT_RETEN","CTLI"))
	tret!=SysGUI!.getWindow(ctlContext).getControl(ctlID)

	ctlContext=num(callpoint!.getTableColumnAttribute("<<DISPLAY>>.DISP_TOT_CHECK","CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute("<<DISPLAY>>.DISP_TOT_CHECK","CTLI"))
	tchk!=SysGUI!.getWindow(ctlContext).getControl(ctlID)

	ctlContext=num(callpoint!.getTableColumnAttribute("APE_MANCHECKHDR.AP_TYPE","CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute("APE_MANCHECKHDR.AP_TYPE","CTLI"))
	ap_type!=SysGUI!.getWindow(ctlContext).getControl(ctlID)

	ctlContext=num(callpoint!.getTableColumnAttribute("APE_MANCHECKHDR.VENDOR_ID","CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute("APE_MANCHECKHDR.VENDOR_ID","CTLI"))
	vendor_id!=SysGUI!.getWindow(ctlContext).getControl(ctlID)

	UserObj!.addItem(tinv!)
	user_tpl.tinv_vpos$="0"
	UserObj!.addItem(tdisc!)
	user_tpl.tdisc_vpos$="1"
	UserObj!.addItem(tret!)
	user_tpl.tret_vpos$="2"
	UserObj!.addItem(tchk!)
	user_tpl.tchk_vpos$="3"
	UserObj!.addItem(ap_type!)
	user_tpl.ap_type_vpos$="4"
	UserObj!.addItem(vendor_id!)
	user_tpl.vendor_id_vpos$="5"

rem --- Additional File Opens

	gl$="N"
	status=0
	source$=pgm(-2)
	call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"AP",glw11$,gl$,status
	if status<>0 goto std_exit
	user_tpl.glint$=gl$
	user_tpl.glworkfile$=glw11$

	if gl$="Y"
		files=21,begfile=20,endfile=21
		dim files$[files],options$[files],chans$[files],templates$[files]
		files$[20]="GLM_ACCT",options$[20]="OTA";rem --- "glm-01"
		files$[21]=glw11$,options$[21]="OTAS";rem --- s means no err if tmplt not found

		call stbl("+DIR_SYP")+"bac_open_tables.bbj",
:			begfile,
:			endfile,
:			files$[all],
:			options$[all],
:			chans$[all],
:			templates$[all],
:			table_chans$[all],
:			batch,
:			status$
		if status$<>"" then
			bbjAPI!=bbjAPI()
			rdFuncSpace!=bbjAPI!.getGroupNamespace()
			rdFuncSpace!.setValue("+build_task","OFF")
			release
		endif
	endif

rem --- Retrieve parameter data
               
	aps01a_key$=firm_id$+"AP00"
	find record (aps01_dev,key=aps01a_key$,err=std_missing_params) aps01a$
	callpoint!.setDevObject("multi_types",aps01a.multi_types$)

	call stbl("+DIR_PGM")+"adc_getmask.aon","","AP","A","",amt_mask$,0,0

	user_tpl.amt_msk$=amt_mask$
	user_tpl.multi_types$=aps01a.multi_types$
	user_tpl.dflt_ap_type$=aps01a.ap_type$
	user_tpl.multi_dist$=aps01a.multi_dist$
	user_tpl.dflt_dist_cd$=aps01a.ap_dist_code$
	user_tpl.ret_flag$=aps01a.ret_flag$
	user_tpl.misc_entry$=aps01a.misc_entry$
	user_tpl.post_closed$=aps01a.post_closed$

	if user_tpl.multi_types$<>"Y"
		apm10_dev=fnget_dev("APC_TYPECODE")
		dim apm10a$:fnget_tpl$("APC_TYPECODE")
		readrecord (apm10_dev,key=firm_id$+"A"+user_tpl.dflt_ap_type$,dom=*next)apm10a$
		if cvs(apm10a$,2)<>""
			user_tpl.dflt_dist_cd$=apm10a.ap_dist_code$
		endif
	endif

	gls01a_key$=firm_id$+"GL00"
	find record (gls01_dev,key=gls01a_key$,err=std_missing_params) gls01a$
	user_tpl.units_flag$=gls01a.units_flag$
	callpoint!.setDevObject("GLMisc",user_tpl.misc_entry$)
	callpoint!.setDevObject("GLUnits",user_tpl.units_flag$)
	callpoint!.setDevObject("gl_int",user_tpl.glint$)
	callpoint!.setDevObject("dist_amt","")
	callpoint!.setDevObject("dflt_gl","")
	callpoint!.setDevObject("dflt_dist","")
	callpoint!.setDevObject("tot_inv","")

rem --- Get Payment Authorization parameter record

	readrecord(aps_payauth,key=firm_id$+"AP00",dom=*next)aps_payauth$
	callpoint!.setDevObject("use_pay_auth",aps_payauth.use_pay_auth)
	callpoint!.setDevObject("scan_docs_to",aps_payauth.scan_docs_to$)

rem --- Create vector of urls for viewed invoice images

	urlVect!=BBjAPI().makeVector()
	callpoint!.setDevObject("urlVect",urlVect!)
[[APE_MANCHECKHDR.AREC]]
user_tpl.reuse_chk$=""
user_tpl.open_check$=""
user_tpl.dflt_gl_account$=""
callpoint!.setColumnData("<<DISPLAY>>.comments","")

rem --- if not multi-type then set the defalut AP Type
if user_tpl.multi_types$="N" then
	callpoint!.setColumnData("APE_MANCHECKHDR.AP_TYPE",user_tpl.dflt_ap_type$)
endif
[[APE_MANCHECKHDR.AREA]]
print "Head: AREA (After Record Read)"; rem debug
print "open_check$ is reset"; rem debug

user_tpl.existing_tran$="Y"
user_tpl.open_check$=""
user_tpl.reuse_chk$=""
[[APE_MANCHECKHDR.ADIS]]
print "Head: ADIS (After Record Displays)"; rem debug
print "open_check$ is reset"; rem debug

user_tpl.existing_tran$="Y"
user_tpl.open_check$=""
user_tpl.reuse_chk$=""
tmp_vendor_id$=callpoint!.getColumnData("APE_MANCHECKHDR.VENDOR_ID")
gosub disp_vendor_comments
ctl_name$="APE_MANCHECKHDR.TRANS_TYPE"
ctl_stat$="D"
gosub disable_fields
ctl_name$="APE_MANCHECKHDR.VENDOR_ID"
gosub disable_fields
if callpoint!.getColumnData("APE_MANCHECKHDR.TRANS_TYPE")="M"
	gosub calc_tots
	callpoint!.setColumnData("<<DISPLAY>>.DISP_TOT_INV",str(tinv))
   	callpoint!.setColumnData("<<DISPLAY>>.DISP_TOT_DISC",str(tdisc))
	callpoint!.setColumnData("<<DISPLAY>>.DISP_TOT_RETEN",str(tret))
	callpoint!.setColumnData("<<DISPLAY>>.DISP_TOT_CHECK",str(tinv-tdisc-tret))
else
	ctl_name$="APE_MANCHECKHDR.CHECK_DATE"
	ctl_stat$="D"
	gosub disable_fields
	gosub disable_grid
endif
rem --- disable inv#/date/dist code cells corres to existing data -- only allow change on inv/disc cols
curr_rows!=GridVect!.getItem(0)
curr_rows=curr_rows!.size()
if curr_rows
gosub enable_grid
dtlGrid!=Form!.getChildWindow(1109).getControl(5900)
	for wk=0 to curr_rows-1
		dtlGrid!.setCellEditable(wk,0,0)
		dtlGrid!.setCellEditable(wk,1,0)
		dtlGrid!.setCellEditable(wk,2,0)
	next wk
endif
