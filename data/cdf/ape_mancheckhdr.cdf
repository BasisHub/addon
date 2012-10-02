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
		lock_type$="U"
		lock_status$=""
		lock_disp$=""
		call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$
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
:	cvs(callpoint!.getColumnData("APE_MANCHECKHDR.VENDOR_ID"),3)="" then dont_write$="Y"

vend_hist$=""
tmp_vendor_id$=callpoint!.getColumnData("APE_MANCHECKHDR.VENDOR_ID")
gosub get_vendor_history
if vend_hist$<>"Y" then dont_write$="Y"

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
	ape22_dev=fnget_dev("APE_MANCHECKDET")
	
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
[[APE_MANCHECKHDR.AOPT-OCHK]]
rem -- call inquiry program to view open check file; plug check#/vendor id if those fields are still blank on form
key_pfx$=callpoint!.getColumnData("APE_MANCHECKHDR.FIRM_ID")+callpoint!.getColumnData("APE_MANCHECKHDR.AP_TYPE")
selected_key$=""
call stbl("+DIR_SYP")+"bam_inquiry.bbj",
:	gui_dev,
:	Form!,
:	"APT_CHECKHISTORY",
:	"",
:	table_chans$[all],
:	key_pfx$,
:	"PRIMARY",
:	selected_key$
if selected_key$<>""
	if cvs(callpoint!.getColumnData("APE_MANCHECKHDR.CHECK_NO"),3)="" and cvs(callpoint!.getColumnData("APE_MANCHECKHDR.CHECK_DATE"),3)="" and
:		cvs(callpoint!.getColumnData("APE_MANCHECKHDR.VENDOR_ID"),3)=""
		callpoint!.setColumnData("APE_MANCHECKHDR.CHECK_NO",selected_key$(len(key_pfx$)+1,7))
		callpoint!.setColumnData("APE_MANCHECKHDR.VENDOR_ID",selected_key$(len(key_pfx$)+8,6))
		callpoint!.setStatus("REFRESH")
	endif
endif
[[APE_MANCHECKHDR.<CUSTOM>]]
disp_vendor_comments:
	
	cmt_text$=""
	apm09_dev=fnget_dev("APM_VENDCMTS")
	dim apm09a$:fnget_tpl$("APM_VENDCMTS")
	apm09_key$=firm_id$+tmp_vendor_id$
	more=1
	read(apm09_dev,key=apm09_key$,dom=*next)

	while more
		readrecord(apm09_dev,end=*break)apm09a$

		if apm09a.firm_id$ <> firm_id$ or apm09a.vendor_id$<>tmp_vendor_id$ then 
			break
		endif

		cmt_text$=cmt_text$+cvs(apm09a.std_comments$,3)+$0A$
	wend

	callpoint!.setColumnData("<<DISPLAY>>.comments",cmt_text$)
	callpoint!.setStatus("REFRESH")

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
			pfx$="GLNS",nm$="GL Dist"
			GLNS!=BBjAPI().getNamespace(pfx$,nm$,1)
			GLNS!.setValue("dflt_gl",apm02a.gl_account$)
			GLNS!.setValue("dflt_dist",apm02a.ap_dist_code$)
			vend_hist$="Y"
	endif
return

#include std_missing_params.src
[[APE_MANCHECKHDR.VENDOR_ID.AVAL]]
	print "Head: VENDOR_ID.AVAL (After Column Validation)"; rem debug

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
[[APE_MANCHECKHDR.AOPT-VCMT]]
key_pfx$=callpoint!.getColumnData("APE_MANCHECKHDR.FIRM_ID")+callpoint!.getColumnData("APE_MANCHECKHDR.VENDOR_ID")
call stbl("+DIR_SYP")+"bam_inquiry.bbj",
:	gui_dev,
:	Form!,
:	"APM_VENDCMTS",
:	"VIEW",
:	table_chans$[all],
:	key_pfx$,
:	"PRIMARY"
[[APE_MANCHECKHDR.AOPT-AVEN]]
user_id$=stbl("+USER_ID")
dim dflt_data$[1,1]
key_pfx$=callpoint!.getColumnData("APE_MANCHECKHDR.FIRM_ID")+callpoint!.getColumnData("APE_MANCHECKHDR.VENDOR_ID")
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"APM_VENDMAST",
:	user_id$,
:	"MNT",
:	key_pfx$,
:	table_chans$[all],
:	"",
:	dflt_data$[all]
[[APE_MANCHECKHDR.BSHO]]
rem --- Disable ap type control if param for multi-types is N

	if user_tpl.multi_types$="N" 
		ctl_name$="APE_MANCHECKHDR.AP_TYPE"
		ctl_stat$="I"
		gosub disable_fields
	endif
			
rem --- Disable some grid columns

	w!=Form!.getChildWindow(1109)
	c!=w!.getControl(5900)
	c!.setColumnEditable(6,0)
	c!.setColumnEditable(7,0)
	if user_tpl.multi_types$="N" c!.setColumnEditable(2,0)

rem --- Disable button

	callpoint!.setOptionEnabled("OINV",0)
[[APE_MANCHECKHDR.AWIN]]
rem print 'show',; rem debug

rem --- Open/Lock files
files=30,begfile=1,endfile=12
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="APE_MANCHECKHDR";rem --- "ape-02"
files$[2]="APE_MANCHECKDIST";rem --- "ape-12"
files$[3]="APE_MANCHECKDET";rem --- "ape-22"
files$[4]="APM_VENDMAST";rem --- "apm-01"
files$[5]="APM_VENDHIST";rem --- "apm-02"
files$[6]="APT_INVOICEHDR";rem --- "apt-01"
files$[7]="APT_INVOICEDET";rem --- "apt-11"
files$[8]="APT_CHECKHISTORY";rem --- "apt-05
files$[9]="APC_TYPECODE";rem --- "apm-10A"
files$[10]="APM_VENDCMTS";rem --- "apm-09
files$[11]="APS_PARAMS";rem --- "ads-01"
files$[12]="GLS_PARAMS"
for wkx=begfile to endfile
	options$[wkx]="OTA"
next wkx
options$[3]=options$[3]+"N"
call stbl("+DIR_SYP")+"bac_open_tables.bbj",
:	begfile,
:	endfile,
:	files$[all],
:	options$[all],
:	chans$[all],
:	templates$[all],
:	table_chans$[all],
:	batch,
:	status$
if status$<>"" then
	remove_process_bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif
aps01_dev=num(chans$[11])
gls01_dev=num(chans$[12])
dim aps01a$:templates$[11],gls01a$:templates$[12]
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
:	begfile,
:	endfile,
:	files$[all],
:	options$[all],
:	chans$[all],
:	templates$[all],
:	table_chans$[all],
:	batch,
:	status$
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
pfx$="GLNS",nm$="GL Dist"
GLNS!=BBjAPI().getNamespace(pfx$,nm$,1)
GLNS!.setValue("GLMisc",user_tpl.misc_entry$)
GLNS!.setValue("GLUnits",user_tpl.units_flag$)
GLNS!.setValue("gl_int",user_tpl.glint$)
GLNS!.setValue("dist_amt","")
GLNS!.setValue("dflt_gl","")
GLNS!.setValue("dflt_dist","")
GLNS!.setValue("tot_inv","")
[[APE_MANCHECKHDR.ARNF]]
rem --- Look in check history for this check number

	trans_type$ = callpoint!.getColumnData("APE_MANCHECKHDR.TRANS_TYPE")
	check_no$   = callpoint!.getColumnData("APE_MANCHECKHDR.CHECK_NO")
	ap_type$    = callpoint!.getColumnData("APE_MANCHECKHDR.AP_TYPE")
	vendor_id$  = callpoint!.getColumnData("APE_MANCHECKHDR.VENDOR_ID")

	if user_tpl.open_check$<>"Y" and trans_type$<>"R" and cvs(check_no$,3)<>"" then
		apt05_dev = fnget_dev("APT_CHECKHISTORY")
		dim apt05a$:fnget_tpl$("APT_CHECKHISTORY")

		read (apt05_dev,key=firm_id$+ap_type$+check_no$+vendor_id$,dom=*next)
		readrecord (apt05_dev,end=*next)apt05a$

		if	apt05a.firm_id$   = firm_id$  and
:			apt05a.ap_type$   = ap_type$  and
:			apt05a.check_no$  = check_no$ and
:			apt05a.vendor_id$ = vendor_id$
:		then
			user_tpl.open_check$="Y"; rem don't check again

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
					ape_mancheckhdr=fnget_dev("APE_MANCHECKHDR")
					dim ape_checktpl$:fnget_tpl$("APE_MANCHECKHDR")
					ape_checktpl.firm_id$=firm_id$
					ape_checktpl.ap_type$=ap_type$
					ape_checktpl.check_no$=check_no$
					ape_checktpl.vendor_id$=vendor_id$
					ape_checktpl.trans_type$="R"
					ape_checktpl.check_date$=apt05a.check_date$
					ape_checktpl.vendor_name$=apt05a.vendor_name$
					ape_checktpl.batch_no$=callpoint!.getColumnData("APE_MANCHECKHDR.BATCH_NO")
					ape_checktpl$=field(ape_checktpl$)
					write record(ape_mancheckhdr) ape_checktpl$
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
[[APE_MANCHECKHDR.AREC]]
print "Head: AREC (After New Record)"; rem debug
print "open_check$ reset"; rem debug

user_tpl.reuse_chk$=""
user_tpl.open_check$=""
user_tpl.dflt_gl_account$=""
callpoint!.setColumnData("<<DISPLAY>>.comments","")
rem --- enable/disable grid cells
w!=Form!.getChildWindow(1109)
c!=w!.getControl(5900)
c!.setColumnEditable(0,1)
c!.setColumnEditable(1,1)
c!.setColumnEditable(6,0)
c!.setColumnEditable(7,0)
if user_tpl.multi_dist$="N" c!.setColumnEditable(2,0)

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
