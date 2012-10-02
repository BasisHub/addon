[[APE_RECURRINGHDR.BTBL]]
rem --- Open/Lock files
files=7,begfile=1,endfile=7
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="APT_INVOICEDIST";rem --- "apt-02"
files$[2]="APM_VENDCMTS";rem --- "apm-09
files$[3]="APM_VENDMAST";rem --- "apm-01"
files$[4]="APM_VENDHIST";rem --- "apm-02"
files$[5]="APS_PARAMS";rem --- "ads-01"
files$[6]="GLS_PARAMS";rem --- "gls-01"
files$[7]="APC_TYPECODE";rem --- "apm-10A"
for wkx=begfile to endfile
	options$[wkx]="OTA"
next wkx
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
aps01_dev=num(chans$[5])
gls01_dev=num(chans$[6])
dim aps01a$:templates$[5],gls01a$:templates$[6]
user_tpl_str$="glint:c(1),glyr:c(4),glper:c(2),gl_tot_pers:c(2),glworkfile:c(16),"
user_tpl_str$=user_tpl_str$+"amt_msk:c(15),multi_types:c(1),multi_dist:c(1),ret_flag:c(1),units_flag:c(1),"
user_tpl_str$=user_tpl_str$+"misc_entry:c(1),inv_in_ape03:c(1),inv_in_apt02:c(1),"
user_tpl_str$=user_tpl_str$+"dflt_ap_type:c(2),dflt_dist_cd:c(2),dflt_gl_account:c(10),dflt_terms_cd:c(2),dflt_pymt_grp:c(2),"
user_tpl_str$=user_tpl_str$+"disc_pct:c(5),dist_bal_ofst:c(1),inv_amt:c(10),tot_dist:c(10),open_inv_textID:c(5)"
dim user_tpl$:user_tpl_str$
rem --- set up UserObj! as vector to store dist bal display control
UserObj!=SysGUI!.makeVector()

rem --- Additional File Opens
gl$="N"
status=0
source$=pgm(-2)
call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"AP",glw11$,gl$,status
if status<>0 goto std_exit
user_tpl.glint$=gl$
user_tpl.glworkfile$=glw11$
if gl$="Y"
   files=2,begfile=1,endfile=2
   dim files$[files],options$[files],chans$[files],templates$[files]
   files$[1]="GLM_ACCT",options$[1]="OTA";rem --- "glm-01"
   files$[2]=glw11$,options$[2]="OTAS";rem --- s means no err if tmplt not found
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
gls01a_key$=firm_id$+"GL00"
find record (gls01_dev,key=gls01a_key$,err=std_missing_params) gls01a$
user_tpl.units_flag$=gls01a.units_flag$
user_tpl.glyr$=gls01a.current_year$
user_tpl.glper$=gls01a.current_per$
user_tpl.gl_tot_pers$=gls01a.total_pers$

rem --- if not using multi AP types, disable access to AP Type and get default distribution code

if user_tpl.multi_types$<>"Y"
	callpoint!.setTableColumnAttribute("APE_RECURRINGHDR.AP_TYPE","PVAL",$22$+aps01a.ap_type$+$22$)

	rem --- get default distribution code	
	apm10_dev=fnget_dev("APC_TYPECODE")
	dim apm10a$:fnget_tpl$("APC_TYPECODE")
	readrecord (apm10_dev,key=firm_id$+"A"+user_tpl.dflt_ap_type$,dom=*next)apm10a$
	if cvs(apm10a$,2)<>""
		user_tpl.dflt_dist_cd$=apm10a.ap_dist_code$
	endif

	rem --- if not using multi distribution codes, initialize and disable Distribution Code
	if user_tpl.multi_dist$<>"Y"
		callpoint!.setTableColumnAttribute("APE_RECURRINGHDR.AP_DIST_CODE","PVAL",$22$+user_tpl.dflt_dist_cd$+$22$)
	endif
endif
[[APE_RECURRINGHDR.AP_INV_NO.AVAL]]
ctl_name$="APE_RECURRINGHDR.AP_DIST_CODE"
if user_tpl.multi_dist$="Y" 
	ctl_stat$=""
else
	ctl_stat$="D"
endif
gosub disable_fields
ctl_name$="APE_RECURRINGHDR.INVOICE_DATE"
ctl_stat$=""
gosub disable_fields
ctl_name$="APE_RECURRINGHDR.NET_INV_AMT"
ctl_stat$=""
gosub disable_fields
[[APE_RECURRINGHDR.AREC]]
Form!.getControl(num(user_tpl.open_inv_textID$)).setText("")
callpoint!.setColumnData("<<DISPLAY>>.comments","")
user_tpl.inv_amt$=""
user_tpl.tot_dist$=""
callpoint!.setColumnData("<<DISPLAY>>.DIST_BAL","0")

rem --- Re-enable disabled fields
ctl_name$="APE_RECURRINGHDR.AP_DIST_CODE"
if user_tpl.multi_dist$="Y" 
	ctl_stat$=""
else
	ctl_stat$="D"
endif
gosub disable_fields
ctl_name$="APE_RECURRINGHDR.INVOICE_DATE"
ctl_stat$=""
gosub disable_fields
ctl_name$="APE_RECURRINGHDR.NET_INV_AMT"
ctl_stat$=""
gosub disable_fields
[[APE_RECURRINGHDR.BWRI]]
rem --- fully distributed?
gl$=user_tpl.glint$
status=0
acctgdate$=callpoint!.getColumnData("APE_RECURRINGHDR.ACCTING_DATE")  
if gl$="Y" 
	call stbl("+DIR_PGM")+"glc_datecheck.aon",acctgdate$,"Y",per$,yr$,status
	if status>99
		callpoint!.setStatus("ABORT")
		ctlContext=num(callpoint!.getTableColumnAttribute("APE_RECURRINGHDR.ACCTING_DATE","CTLC"))
		ctlID=num(callpoint!.getTableColumnAttribute("APE_RECURRINGHDR.ACCTING_DATE","CTLI"))
		acct_dt!=SysGUI!.getWindow(ctlContext).getControl(ctlID)
		acct_dt!.focus()
	endif
endif
if status<=99
	bal_amt=num(callpoint!.getColumnData("APE_RECURRINGHDR.INVOICE_AMT"))-num(user_tpl.tot_dist$)
	if bal_amt<>0
		msg_id$="AP_NOT_DIST"
		gosub disp_message
		if msg_opt$="N"
			gosub calc_grid_tots
			gosub disp_dist_bal
			callpoint!.setStatus("REFRESH-ABORT")
		endif
	endif
endif
	
[[APE_RECURRINGHDR.NET_INV_AMT.AVAL]]
rem re-calc discount amount based on net x disc %
disc_amt=num(callpoint!.getUserInput())*(num(user_tpl.disc_pct$)/100)
callpoint!.setColumnData("APE_RECURRINGHDR.DISCOUNT_AMT",str(disc_amt))
callpoint!.setStatus("REFRESH:APE_RECURRINGHDR.DISCOUNT_AMT")
[[APE_RECURRINGHDR.PAYMENT_GRP.AVAL]]
if cvs(callpoint!.getUserInput(),3)=""
	callpoint!.setUserInput("  ")
	callpoint!.setStatus("REFRESH")
endif
[[APE_RECURRINGHDR.AP_DIST_CODE.AVAL]]
if cvs(callpoint!.getUserInput(),3)=""
	callpoint!.setUserInput("  ")
	callpoint!.setStatus("REFRESH")
endif
[[APE_RECURRINGHDR.AP_TYPE.AVAL]]
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
[[APE_RECURRINGHDR.ARNF]]
rem not in ape-03; set up defaults

apm10c_dev=fnget_dev("APC_TERMSCODE")
dim apm10c$:fnget_tpl$("APC_TERMSCODE")

terms_cd$=user_tpl.dflt_terms_cd$
invdate$=stbl("+SYSTEM_DATE")
gosub calculate_due_and_discount
callpoint!.setColumnData("APE_RECURRINGHDR.AP_DIST_CODE",user_tpl.dflt_dist_cd$)
callpoint!.setColumnData("APE_RECURRINGHDR.AP_TERMS_CODE",user_tpl.dflt_terms_cd$)
callpoint!.setColumnData("APE_RECURRINGHDR.PAYMENT_GRP",user_tpl.dflt_pymt_grp$)
callpoint!.setColumnData("APE_RECURRINGHDR.INVOICE_DATE",stbl("+SYSTEM_DATE"))
callpoint!.setColumnData("APE_RECURRINGHDR.HOLD_FLAG","N")
user_tpl.inv_in_ape03$="N"
user_tpl.inv_in_apt02$="N"

callpoint!.setStatus("REFRESH")
[[APE_RECURRINGHDR.VENDOR_ID.AVAL]]
rem "check vend hist file to be sure this vendor/ap type ok and to set some defaults;  display vend cmts
tmp_vendor_id$=callpoint!.getUserInput()
gosub disp_vendor_comments
gosub get_vendor_history
if vend_hist$=""
	if user_tpl.multi_types$="Y"
		msg_id$="AP_VEND_BAD_APTYPE"
		gosub disp_message
		callpoint!.setStatus("CLEAR-NEWREC")
	endif
endif
[[APE_RECURRINGHDR.ACCTING_DATE.AVAL]]
gl$=user_tpl.glint$
acctgdate$=callpoint!.getUserInput()      
if gl$="Y" 
	call stbl("+DIR_PGM")+"glc_datecheck.aon",acctgdate$,"Y",per$,yr$,status
	if status>99
		callpoint!.setStatus("ABORT")
	else
		user_tpl.glyr$=yr$
		user_tpl.glper$=per$
	endif
endif
[[APE_RECURRINGHDR.ADIS]]
rem --- get disc % assoc w/ terms in this rec, and disp distributed bal
apm10c_dev=fnget_dev("APC_TERMSCODE")
dim apm10c$:fnget_tpl$("APC_TERMSCODE")
readrecord(apm10c_dev,key=firm_id$+"C"+callpoint!.getColumnData("APE_RECURRINGHDR.AP_TERMS_CODE"),dom=*next)apm10c$
user_tpl.disc_pct$=apm10c.disc_percent$
user_tpl.inv_amt$=callpoint!.getColumnData("APE_RECURRINGHDR.INVOICE_AMT")
if user_tpl.glint$="N" user_tpl.tot_dist$=user_tpl.inv_amt$
gosub calc_grid_tots
gosub disp_dist_bal
user_tpl.inv_in_ape03$="Y"
user_tpl.inv_in_apt02$="N"
Form!.getControl(num(user_tpl.open_inv_textID$)).setText("")
tmp_vendor_id$=callpoint!.getColumnData("APE_RECURRINGHDR.VENDOR_ID")
gosub disp_vendor_comments
callpoint!.setStatus("REFRESH")
[[APE_RECURRINGHDR.AP_TERMS_CODE.AVAL]]
rem re-calc due and discount dates based on terms code
	terms_cd$=callpoint!.getUserInput()
	if terms_cd$="" callpoint!.setUserInput("  ")		
	invdate$=callpoint!.getColumnData("APE_RECURRINGHDR.INVOICE_DATE")
	gosub calculate_due_and_discount
	disc_amt=num(callpoint!.getColumnData("APE_RECURRINGHDR.NET_INV_AMT"))*(num(user_tpl.disc_pct$)/100)
	callpoint!.setColumnData("APE_RECURRINGHDR.DISCOUNT_AMT",str(disc_amt))
	callpoint!.setStatus("REFRESH")
endif
[[APE_RECURRINGHDR.INVOICE_AMT.AVAL]]
callpoint!.setColumnData("APE_RECURRINGHDR.NET_INV_AMT",
:	callpoint!.getUserInput())
user_tpl.inv_amt$=callpoint!.getUserInput()
if user_tpl.glint$="N" user_tpl.tot_dist$=user_tpl.inv_amt$
gosub calc_grid_tots
gosub disp_dist_bal
callpoint!.setStatus("REFRESH")
[[APE_RECURRINGHDR.<CUSTOM>]]
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
get_vendor_history:
	apm02_dev=fnget_dev("APM_VENDHIST")				
	dim apm02a$:fnget_tpl$("APM_VENDHIST")
	vend_hist$=""
	readrecord(apm02_dev,key=firm_id$+tmp_vendor_id$+
:		callpoint!.getColumnData("APE_RECURRINGHDR.AP_TYPE"),dom=*next)apm02a$
	if apm02a.firm_id$+apm02a.vendor_id$+apm02a.ap_type$=firm_id$+tmp_vendor_id$+
:		callpoint!.getColumnData("APE_RECURRINGHDR.AP_TYPE")
			user_tpl.dflt_dist_cd$=apm02a.ap_dist_code$
			user_tpl.dflt_gl_account$=apm02a.gl_account$
			user_tpl.dflt_terms_cd$=apm02a.ap_terms_code$
			user_tpl.dflt_pymt_grp$=apm02a.payment_grp$
			vend_hist$="Y"
	endif
return

disp_vendor_comments:
	
	cmt_text$=""
	apm09_dev=fnget_dev("APM_VENDCMTS")
	dim apm09a$:fnget_tpl$("APM_VENDCMTS")
	apm09_key$=firm_id$+tmp_vendor_id$
	more=1
	read(apm09_dev,key=apm09_key$,dom=*next)
	while more
		readrecord(apm09_dev,end=*break)apm09a$
		if apm09a.firm_id$+apm09a.vendor_id$<>firm_id$+tmp_vendor_id$  break
			cmt_text$=cmt_text$+cvs(apm09a.std_comments$,3)+$0A$
		endif				
	wend
	callpoint!.setColumnData("<<DISPLAY>>.comments",cmt_text$)
	callpoint!.setStatus("REFRESH")
calculate_due_and_discount:
	apm10c_dev=fnget_dev("APC_TERMSCODE")
	dim apm10c$:fnget_tpl$("APC_TERMSCODE")
	
	readrecord(apm10c_dev,key=firm_id$+"C"+terms_cd$,dom=*next)apm10c$
	prox_days$=cvs(apm10c.prox_or_days$,3); if prox_days$="" prox_days$="D"
	due_dt$=""
	call stbl("+DIR_PGM")+"adc_duedate.aon",prox_days$,invdate$,num(apm10c.due_days$),due_dt$,status
	callpoint!.setColumnData("APE_RECURRINGHDR.INV_DUE_DATE",due_dt$)
	due_dt$=""
	call stbl("+DIR_PGM")+"adc_duedate.aon",prox_days$,invdate$,num(apm10c.disc_days$),due_dt$,status
	callpoint!.setColumnData("APE_RECURRINGHDR.DISC_DATE",due_dt$)
	user_tpl.disc_pct$=apm10c.disc_percent$
return
calc_grid_tots:
	recVect!=GridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs=recVect!.size()
	tdist=0
	if numrecs>0
		for reccnt=0 to numrecs-1
			gridrec$=recVect!.getItem(reccnt)
			if cvs(gridrec$,3)<>"" then tdist=tdist+num(gridrec.gl_post_amt$)
		next reccnt
		user_tpl.tot_dist$=str(tdist)
	endif
return
disp_dist_bal:
	dist_bal=num(user_tpl.inv_amt$)-num(user_tpl.tot_dist$)
	callpoint!.setColumnData("<<DISPLAY>>.DIST_BAL",str(dist_bal))
	 
return
rem #include fnget_control.src
def fnget_control!(ctl_name$)
ctlContext=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLC"))
ctlID=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI"))
get_control!=SysGUI!.getWindow(ctlContext).getControl(ctlID)
return get_control!
fnend
rem #endinclude fnget_control.src
#include std_missing_params.src
[[APE_RECURRINGHDR.BSHO]]
rem --- add static label for displaying date/amount if pulling up open invoice
inv_no!=fnget_control!("APE_RECURRINGHDR.AP_INV_NO")
cmts!=fnget_control!("<<DISPLAY>>.COMMENTS")
inv_no_x=inv_no!.getX()
inv_no_y=inv_no!.getY()
inv_no_height=inv_no!.getHeight()
inv_no_width=inv_no!.getWidth()
cmts_x=cmts!.getX()
nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))
Form!.addStaticText(nxt_ctlID,inv_no_x+inv_no_width+5,inv_no_y,cmts_x-(inv_no_x+inv_no_width+5),inv_no_height*2,"")
user_tpl.open_inv_textID$=str(nxt_ctlID)
rem --- add the display control holding the distribution balance to userObj!
dist_bal!=fnget_control!("<<DISPLAY>>.DIST_BAL")
user_tpl.dist_bal_ofst$="0"
userObj!.addItem(dist_bal!)

rem --- may need to disable some ctls based on params
if user_tpl.multi_types$="N" 
	ctl_name$="APE_RECURRINGHDR.AP_TYPE"
	ctl_stat$="I"
	gosub disable_fields
endif
if user_tpl.multi_dist$="N" 
	ctl_name$="APE_RECURRINGHDR.AP_DIST_CODE"
	ctl_stat$="I"
	gosub disable_fields
endif
if user_tpl.ret_flag$="N" 
	ctl_name$="APE_RECURRINGHDR.RETENTION"
	ctl_stat$="I"
	gosub disable_fields
endif
	ctl_name$="<<DISPLAY>>.DIST_BAL"
	ctl_stat$="I"
	gosub disable_fields
rem --- disable some grid columns depending on params
w!=Form!.getChildWindow(1109)
c!=w!.getControl(5900)
if gl$="N" 
	numcols=c!.getNumColumns()
	for x=0 to numcols-1
		c!.setColumnEditable(x,0)
	next x
endif
if user_tpl.units_flag$="N" c!.setColumnEditable(3,0)
