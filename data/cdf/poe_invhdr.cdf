[[POE_INVHDR.BTBL]]
rem --- Open/Lock files
files=15,begfile=1,endfile=files
dim files$[files],options$[files],chans$[files],templates$[files]

files$[1]="APM_VENDCMTS";rem --- "apm-09
files$[2]="APM_VENDMAST";rem --- "apm-01"
files$[3]="APM_VENDHIST";rem --- "apm-02"
files$[4]="APS_PARAMS";rem --- "aps-01"
files$[5]="GLS_PARAMS";rem --- "gls-01"
files$[6]="POS_PARAMS";rem --- "pos-01"
files$[7]="IVS_PARAMS";rem --- "ivs-01"
files$[8]="POE_POHDR";rem --- "poe-02"
files$[9]="POE_PODET";rem --- "poe-12"
files$[10]="POT_RECHDR";rem --- "pot-04"
files$[11]="POT_RECDET";rem --- "pot-14"
files$[12]="APT_INVOICEHDR";rem --- "apt-01"
files$[13]="IVM_ITEMMAST";rem --- "ivm-01"
files$[14]="POC_LINECODE";rem --- "pom-02"
files$[15]="APC_TERMSCODE"

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

aps01_dev=num(chans$[4])
gls01_dev=num(chans$[5])
pos01_dev=num(chans$[6])
ivs01_dev=num(chans$[7])

dim aps01a$:templates$[4],gls01a$:templates$[5],pos01a$:templates$[6],ivs01a$:templates$[7]


rem --- Additional File Opens
gl$="N"
status=0
source$=pgm(-2)
call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"PO",glw11$,gl$,status
if status<>0 goto std_exit
callpoint!.setDevObject("gl_int",gl$)
callpoint!.setDevObject("glworkfile",glw11$)
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

callpoint!.setDevObject("multi_types",aps01a.multi_types$)
callpoint!.setDevObject("multi_dist",aps01a.multi_dist$)
callpoint!.setDevObject("retention",aps01a.ret_flag$)

gls01a_key$=firm_id$+"GL00"
find record (gls01_dev,key=gls01a_key$,err=std_missing_params) gls01a$
callpoint!.setDevObject("units_flag",gls01a.units_flag$)
callpoint!.setDevObject("gl_year",gls01a.current_year$)
callpoint!.setDevObject("gl_per",gls01a.current_per$)
callpoint!.setDevObject("gl_tot_pers",gls01a.total_pers$)


call stbl("+DIR_SYP")+"bac_key_template.bbj","POE_INVSEL","PRIMARY",poe_invsel_key_tpl$,table_chans$[all],status$
callpoint!.setDevObject("poe_invsel_key",poe_invsel_key_tpl$)

if aps01a.multi_types$<>"Y"
	callpoint!.setTableColumnAttribute("POE_INVHDR.AP_TYPE","PVAL",$22$+aps01a.ap_type$+$22$)
endif
[[POE_INVHDR.AABO]]
rem --- user has elected not to save record (we are NOT in immediate write, so save takes care of header and detail at once)
rem --- if rec_data$ is empty (i.e., new record never written), make sure no GL Dists are left orphaned (i.e., remove them)

if callpoint!.getRecordMode()="A"
	poe_invgl=fnget_dev("POE_INVGL")
	k$=""
	invgl_key$=callpoint!.getColumnData("POE_INVHDR.FIRM_ID")+
:		callpoint!.getColumnData("POE_INVHDR.AP_TYPE")+
:		callpoint!.getColumnData("POE_INVHDR.VENDOR_ID")+
:		callpoint!.getColumnData("POE_INVHDR.AP_INV_NO")

	read (poe_invgl,key=invgl_key$,dom=*next)
	while 1
		k$=key(poe_invgl,end=*break)
		if pos(invgl_key$=k$)<>1 then break
		remove (poe_invgl,key=k$)	
	wend	
endif
[[POE_INVHDR.BREX]]
rem --- also need final check of balance -- invoice amt - invsel amt - gl dist amt (invsel should already equal invdet)

if num(callpoint!.getColumnData("<<DISPLAY>>.DIST_BAL"))<>0
	msg_id$="PO_INV_NOT_DIST"
	gosub disp_message

endif
[[POE_INVHDR.APFE]]
rem --- when re-entering primary form, enable GL button
rem --- only enable invoice detail button if we've already written some poe_invdet records

callpoint!.setOptionEnabled("GDIS",1)

poe_invdet=fnget_dev("POE_INVDET")

k$=""
invdet_key$=callpoint!.getColumnData("POE_INVHDR.FIRM_ID")+callpoint!.getColumnData("POE_INVHDR.AP_TYPE")+
:	callpoint!.getColumnData("POE_INVHDR.VENDOR_ID")+callpoint!.getColumnData("POE_INVHDR.AP_INV_NO")


read (poe_invdet,key=invdet_key$,dom=*next)
k$=key(poe_invdet,end=*next)
if pos(invdet_key$=k$)=1
	callpoint!.setOptionEnabled("INVD",1)
else
	callpoint!.setOptionEnabled("INVD",0)
endif
[[POE_INVHDR.BPFX]]
callpoint!.setOptionEnabled("INVD",0)
callpoint!.setOptionEnabled("GDIS",0)
[[POE_INVHDR.AOPT-GDIS]]
pfx$=firm_id$+callpoint!.getColumnData("POE_INVHDR.AP_TYPE")+callpoint!.getColumnData("POE_INVHDR.VENDOR_ID")+callpoint!.getColumnData("POE_INVHDR.AP_INV_NO")
dim dflt_data$[3,1]
dflt_data$[1,0]="AP_TYPE"
dflt_data$[1,1]=callpoint!.getColumnData("POE_INVHDR.AP_TYPE")
dflt_data$[2,0]="VENDOR_ID"
dflt_data$[2,1]=callpoint!.getColumnData("POE_INVHDR.VENDOR_ID")
dflt_data$[3,0]="AP_INV_NO"
dflt_data$[3,1]=callpoint!.getColumnData("POE_INVHDR.AP_INV_NO")
call stbl("+DIR_SYP")+"bam_run_prog.bbj","POE_INVGL",stbl("+USER_ID"),"MNT",pfx$,table_chans$[all],"",dflt_data$[all]

gosub calc_gl_tots
gosub calc_grid_tots
gosub disp_dist_bal
[[POE_INVHDR.AWRI]]
rem --- look thru gridVect for any rows we've deleted from invsel... delete corres rows from invdet

if gridVect!.size()

	poe_invdet_dev=fnget_dev("POE_INVDET")
	dim poe_invdet$:fnget_tpl$("POE_INVDET")
	recs!=gridVect!.getItem(0)
	dim poe_invsel$:dtlg_param$[1,3]
	if recs!.size()
		for x=0 to recs!.size()-1
			if callpoint!.getGridRowDeleteStatus(x)="Y"
				poe_invsel$=recs!.getItem(x)
				read (poe_invdet_dev,key=poe_invsel.firm_id$+poe_invsel.ap_type$+poe_invsel.vendor_id$+poe_invsel.ap_inv_no$,dom=*next)
				while 1
					read record (poe_invdet_dev,end=*break)poe_invdet$
					if pos(poe_invsel.firm_id$+poe_invsel.ap_type$+poe_invsel.vendor_id$+poe_invsel.ap_inv_no$=poe_invdet$)<>1 then break
					if poe_invsel.po_no$<>poe_invdet.po_no$ then continue
					if cvs(poe_invsel.receiver_no$,3)<>"" and poe_invsel.receiver_no$<>poe_invdet.receiver_no$ then continue
					remove (poe_invdet_dev,key=poe_invdet.firm_id$+poe_invdet.ap_type$+poe_invdet.vendor_id$+poe_invdet.ap_inv_no$+poe_invdet.line_no$,dom=*next)
				wend
			endif
		next x
	endif
endif

callpoint!.setOptionEnabled("INVD",1)
callpoint!.setOptionEnabled("GDIS",1)

rem --- also need final check of balance -- invoice amt - invsel amt - gl dist amt (invsel should already equal invdet)

if num(callpoint!.getColumnData("<<DISPLAY>>.DIST_BAL"))<>0
	msg_id$="PO_INV_NOT_DIST"
	gosub disp_message

endif
[[POE_INVHDR.AOPT-INVD]]
pfx$=firm_id$+callpoint!.getColumnData("POE_INVHDR.AP_TYPE")+callpoint!.getColumnData("POE_INVHDR.VENDOR_ID")+callpoint!.getColumnData("POE_INVHDR.AP_INV_NO")
dim dflt_data$[3,1]
dflt_data$[1,0]="AP_TYPE"
dflt_data$[1,1]=callpoint!.getColumnData("POE_INVHDR.AP_TYPE")
dflt_data$[2,0]="VENDOR_ID"
dflt_data$[2,1]=callpoint!.getColumnData("POE_INVHDR.VENDOR_ID")
dflt_data$[3,0]="AP_INV_NO"
dflt_data$[3,1]=callpoint!.getColumnData("POE_INVHDR.AP_INV_NO")
call stbl("+DIR_SYP")+"bam_run_prog.bbj","POE_INVDET",stbl("+USER_ID"),"MNT",pfx$,table_chans$[all],"",dflt_data$[all]

rem --- re-align invsel w/ invdet based on changes user may have made in invdet
rem --- corresponds to 6000 logic from old POE.EC

poe_invsel_dev=fnget_dev("POE_INVSEL")
poe_invdet_dev=fnget_dev("POE_INVDET")

dim poe_invsel$:fnget_tpl$("POE_INVSEL")
dim poe_invdet$:fnget_tpl$("POE_INVDET")

other=0
dim x$:str(callpoint!.getDevObject("poe_invsel_key"))
last$=""

ky$=firm_id$+callpoint!.getColumnData("POE_INVHDR.AP_TYPE")+callpoint!.getColumnData("POE_INVHDR.VENDOR_ID")+callpoint!.getColumnData("POE_INVHDR.AP_INV_NO")
read (poe_invsel_dev,key=ky$,dom=*next)

while 1
	read record (poe_invsel_dev,end=*break)poe_invsel$
	if pos(ky$=poe_invsel$)<>1 then break
	if cvs(poe_invsel.po_no$,3)="" then let x$=poe_invsel.firm_id$+poe_invsel.ap_type$+poe_invsel.vendor_id$+poe_invsel.ap_inv_no$+poe_invsel.line_no$
	tot_invsel=0,last$=poe_invsel.firm_id$+poe_invsel.ap_type$+poe_invsel.vendor_id$+poe_invsel.ap_inv_no$,last_seq$=poe_invsel.line_no$
	read (poe_invdet_dev,key=ky$,dom=*next)
	while 1
		read record (poe_invdet_dev,end=*break)poe_invdet$
		if pos(ky$=poe_invdet$)<>1 then break
		if cvs(poe_invdet.po_no$,3)="" then other=1; continue
		if poe_invdet.po_no$<>poe_invsel.po_no$ then continue
		if cvs(poe_invsel.receiver_no$,3)<>"" and poe_invsel.receiver_no$<>poe_invdet.receiver_no$ then continue
		tot_invsel=tot_invsel+round(num(poe_invdet.unit_cost$)*num(poe_invdet.qty_received$),2)
	wend
	poe_invsel.total_amount$=str(tot_invsel)
	poe_invsel$=field(poe_invsel$)
	write record (poe_invsel_dev)poe_invsel$
wend

if other
	read (poe_invdet_dev,key=ky$,dom=*next)
	while 1
		read record (poe_invdet_dev,end=*break)poe_invdet$
		if pos(ky$=poe_invdet$)<>1 then break
		if cvs(poe_invdet.po_no$,3)<>"" then continue
		tot_other=tot_other+num(poe_invdet.unit_cost$)
	wend
	dim poe_invsel$:fattr(poe_invsel$)
	if cvs(x$,3)="" then x$=last$+str(num(last_seq$)+1:"000")
	poe_invsel.firm_id$=x.firm_id$
	poe_invsel.ap_type$=x.ap_type$
	poe_invsel.vendor_id$=x.vendor_id$
	poe_invsel.ap_inv_no$=x.ap_inv_no$
	poe_invsel.line_no$=x.line_no$
	find record (poe_invsel_dev,key=x$,dom=*next)poe_invsel$
	poe_invsel.total_amount$=str(tot_other)
	poe_invsel$=field(poe_invsel$)
	write record (poe_invsel_dev)poe_invsel$
endif

callpoint!.setStatus("RECORD:["+ky$+"]")
[[POE_INVHDR.ARNF]]
rem --- set defaults
		
terms_cd$=callpoint!.getDevObject("dflt_terms_cd")
invdate$=stbl("+SYSTEM_DATE")
tmp_inv_date$=callpoint!.getColumnData("POE_INVHDR.INV_DATE")
gosub calculate_due_and_discount
callpoint!.setColumnData("POE_INVHDR.AP_DIST_CODE",str(callpoint!.getDevObject("dflt_dist_cd")))
callpoint!.setColumnData("POE_INVHDR.AP_TERMS_CODE",str(callpoint!.getDevObject("dflt_terms_cd")))
callpoint!.setColumnData("POE_INVHDR.PAYMENT_GRP",str(callpoint!.getDevObject("dflt_pymt_grp")))
callpoint!.setColumnData("POE_INVHDR.INV_DATE",stbl("+SYSTEM_DATE"))

if cvs(str(callpoint!.getDevObject("dflt_acct_date")),2)<>""
	callpoint!.setColumnData("POE_INVHDR.ACCT_DATE",str(callpoint!.getDevObject("dflt_acct_date")))
else
	callpoint!.setColumnData("POE_INVHDR.ACCT_DATE",stbl("+SYSTEM_DATE"))
callpoint!.setColumnData("POE_INVHDR.HOLD_FLAG","N")

callpoint!.setStatus("REFRESH")
		
[[POE_INVHDR.AP_INV_NO.AVAL]]
rem --- see if in apt-01 (open invoices)

callpoint!.setDevObject("adjust_flag","0")
Form!.getControl(num(callpoint!.getDevObject("inv_adj_label"))).setText("(Invoice)")

apt01_dev=fnget_dev("APT_INVOICEHDR")
while 1
	find(apt01_dev,key=firm_id$+callpoint!.getColumnData("POE_INVHDR.AP_TYPE")+
:		callpoint!.getColumnData("POE_INVHDR.VENDOR_ID")+callpoint!.getUserInput(),dom=*break)
		callpoint!.setDevObject("adjust_flag","1")
		Form!.getControl(num(callpoint!.getDevObject("inv_adj_label"))).setText("(Adjustment)")
		callpoint!.setColumnEnabled("POE_INVHDR.NET_INV_AMT",0)
	break
wend
[[POE_INVHDR.BSHO]]
rem --- add static label for displaying date/amount if pulling up open invoice
inv_no!=fnget_control!("POE_INVHDR.AP_INV_NO")
inv_no_x=inv_no!.getX()
inv_no_y=inv_no!.getY()
inv_no_height=inv_no!.getHeight()
inv_no_width=inv_no!.getWidth()
nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))
x$=stbl("+CUSTOM_CTL",str(nxt_ctlID+1))
Form!.addStaticText(nxt_ctlID,inv_no_x+inv_no_width+25,inv_no_y,inv_no_width,inv_no_height,"")
callpoint!.setDevObject("inv_adj_label",str(nxt_ctlID))

rem --- add the display control holding the distribution balance to devObject
dist_bal!=fnget_control!("<<DISPLAY>>.DIST_BAL")
callpoint!.setDevObject("dist_bal_control",dist_bal!)

rem --- may need to disable some ctls based on params
if callpoint!.getDevObject("multi_types")="N" 
	apm10_dev=fnget_dev("APC_TYPECODE")
	dim apm10a$:fnget_tpl$("APC_TYPECODE")
	readrecord (apm10_dev,key=firm_id$+"  ",dom=*next)apm10a$
	callpoint!.setDevObject("dflt_dist_cd",apm10a.ap_dist_code$)
	callpoint!.setColumnEnabled("POE_INVHDR.AP_TYPE",-1)
endif
if callpoint!.getDevObject("multi_dist")="N" 
	callpoint!.setColumnEnabled("POE_INVHDR.AP_DIST_CODE",-1)
endif
if callpoint!.getDevObject("retention")="N" 
	callpoint!.setColumnEnabled("POE_INVHDR.RETENTION",-1)
endif
callpoint!.setOptionEnabled("INVD",0)
callpoint!.setOptionEnabled("GDIS",0)
[[POE_INVHDR.<CUSTOM>]]
vendor_info: rem --- get and display Vendor Information
	apm01_dev=fnget_dev("APM_VENDMAST")
	dim apm01a$:fnget_tpl$("APM_VENDMAST")
	read record(apm01_dev,key=firm_id$+vendor_id$,dom=*next)apm01a$
	callpoint!.setColumnData("<<DISPLAY>>.V_ADDR1",apm01a.addr_line_1$)
	callpoint!.setColumnData("<<DISPLAY>>.V_ADDR2",apm01a.addr_line_2$)
	callpoint!.setColumnData("<<DISPLAY>>.V_CITY",cvs(apm01a.city$,3)+", "+apm01a.state_code$+"  "+apm01a.zip_code$)
	callpoint!.setColumnData("<<DISPLAY>>.V_CONTACT",apm01a.contact_name$)
	callpoint!.setColumnData("<<DISPLAY>>.V_PHONE",apm01a.phone_no$)
	callpoint!.setColumnData("<<DISPLAY>>.V_FAX",apm01a.fax_no$)
	callpoint!.setStatus("REFRESH")
return

get_vendor_history:
rem --- set vendor_id$ and ap_type$ before coming in
	apm02_dev=fnget_dev("APM_VENDHIST")				
	dim apm02a$:fnget_tpl$("APM_VENDHIST")
	vend_hist$ = ""

	readrecord(apm02_dev,key=firm_id$+vendor_id$+ap_type$,dom=*next)apm02a$
	if cvs(apm02a.firm_id$,2) <> "" then
		callpoint!.setDevObject("dflt_dist_cd", apm02a.ap_dist_code$)
		callpoint!.setDevObject("dflt_gl_account", apm02a.gl_account$)
		callpoint!.setDevObject("dflt_terms_cd", apm02a.ap_terms_code$)
		callpoint!.setDevObject("dflt_pymt_grp", apm02a.payment_grp$)
		vend_hist$="Y"
	else
		callpoint!.setDevObject("dflt_dist_cd", "")
		callpoint!.setDevObject("dflt_gl_account", "")
		callpoint!.setDevObject("dflt_terms_cd", "")
		callpoint!.setDevObject("dflt_pymt_grp", "")
		vend_hist$=""
	endif
return

disp_vendor_comments:
	
	rem --- You must pass in vendor_id$ because we don't know whether it's verified or not
	cmt_text$=""

	apm09_dev=fnget_dev("APM_VENDCMTS")
	dim apm09a$:fnget_tpl$("APM_VENDCMTS")
	apm09_key$=firm_id$+vendor_id$
	more=1
	read(apm09_dev,key=apm09_key$,dom=*next)
	while more
		readrecord(apm09_dev,end=*break)apm09a$
		 
		if apm09a.firm_id$ = firm_id$ and apm09a.vendor_id$ = vendor_id$ then
			cmt_text$ = cmt_text$ + cvs(apm09a.std_comments$,3)+$0A$
		else
			break
		endif				
	wend
	callpoint!.setColumnData("<<DISPLAY>>.comments",cmt_text$)
	callpoint!.setStatus("REFRESH")
return

calculate_due_and_discount:

	if cvs(callpoint!.getColumnData("POE_INVHDR.ACCT_DATE"),2)=""
		callpoint!.setColumnData("POE_INVHDR.ACCT_DATE",str(callpoint!.getDevObject("dflt_acct_date")))
	endif
	if str(callpoint!.getDevObject("dflt_acct_date"))=""
		callpoint!.setColumnData("POE_INVHDR.ACCT_DATE",tmp_inv_date$)
	endif
	apm10c_dev=fnget_dev("APC_TERMSCODE")
	dim apm10c$:fnget_tpl$("APC_TERMSCODE")
	
	readrecord(apm10c_dev,key=firm_id$+"C"+terms_cd$,dom=*next)apm10c$
	prox_days$=cvs(apm10c.prox_or_days$,3); if prox_days$="" prox_days$="D"
	due_dt$=""
	call stbl("+DIR_PGM")+"adc_duedate.aon",prox_days$,invdate$,num(apm10c.due_days$),due_dt$,status
	callpoint!.setColumnData("POE_INVHDR.DUE_DATE",due_dt$)
	due_dt$=""
	call stbl("+DIR_PGM")+"adc_duedate.aon",prox_days$,invdate$,num(apm10c.disc_days$),due_dt$,status
	callpoint!.setColumnData("POE_INVHDR.PO_DISC_DATE",due_dt$)
	callpoint!.setDevObject("disc_pct",apm10c.disc_percent$)
return

calc_gl_tots:

	poe_invgl_dev=fnget_dev("POE_INVGL")
	dim poe_invgl$:fnget_tpl$("POE_INVGL")

	tot_gl=0
	ky$=firm_id$+callpoint!.getColumnData("POE_INVHDR.AP_TYPE")+callpoint!.getColumnData("POE_INVHDR.VENDOR_ID")+callpoint!.getColumnData("POE_INVHDR.AP_INV_NO")
	read (poe_invgl_dev,key=ky$,dom=*next)

	while 1
		read record (poe_invgl_dev,end=*break)poe_invgl$
		if pos(ky$=poe_invgl$)<>1 then break
		tot_gl=tot_gl+poe_invgl.gl_post_amt
	wend
	callpoint!.setDevObject("tot_gl",str(tot_gl))
return

calc_grid_tots:
	recVect!=GridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs=recVect!.size()
	tdist=0
	if numrecs>0
		for reccnt=0 to numrecs-1
			gridrec$=recVect!.getItem(reccnt)
			if cvs(gridrec$,3)<>"" and callpoint!.getGridRowDeleteStatus(reccnt)<>"Y" then tdist=tdist+num(gridrec.total_amount$)
		next reccnt
		callpoint!.setDevObject("tot_dist",str(tdist))
	endif
return

disp_dist_bal:
	dist_bal=num(callpoint!.getDevObject("inv_amt"))-num(callpoint!.getDevObject("tot_dist"))-num(callpoint!.getDevObject("tot_gl"))
	callpoint!.setColumnData("<<DISPLAY>>.DIST_BAL",str(dist_bal))
	callpoint!.setStatus("REFRESH")		 
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
[[POE_INVHDR.INVOICE_AMT.AVAL]]
callpoint!.setColumnData("POE_INVHDR.NET_INV_AMT", callpoint!.getUserInput())
callpoint!.setDevObject("inv_amt",callpoint!.getUserInput())
if callpoint!.getDevObject("gl_int")="N" then callpoint!.setDevObject("tot_dist",callpoint!.getDevObject("inv_amt"))
gosub calc_grid_tots
gosub disp_dist_bal
callpoint!.setStatus("REFRESH")
[[POE_INVHDR.AP_TERMS_CODE.AVAL]]
rem re-calc due and discount dates based on terms code

if callpoint!.getUserInput()<>callpoint!.getColumnData("POE_INVHDR.AP_TERMS_CODE")
	terms_cd$=callpoint!.getUserInput()	
	invdate$=callpoint!.getColumnData("POE_INVHDR.INV_DATE")
	tmp_inv_date$=callpoint!.getColumnData("POE_INVHDR.INV_DATE")
	gosub calculate_due_and_discount
	disc_amt=num(callpoint!.getColumnData("POE_INVHDR.NET_INV_AMT"))*(num(callpoint!.getDevObject("disc_pct"))/100)
	callpoint!.setColumnData("POE_INVHDR.DISCOUNT_AMT",str(disc_amt))
	callpoint!.setStatus("REFRESH")
endif
[[POE_INVHDR.ADIS]]
vendor_id$=callpoint!.getColumnData("POE_INVHDR.VENDOR_ID")
gosub vendor_info
gosub disp_vendor_comments

rem --- get disc % assoc w/ terms in this rec, and disp distributed bal
apm10c_dev=fnget_dev("APC_TERMSCODE")
dim apm10c$:fnget_tpl$("APC_TERMSCODE")
ap_terms_code$ = callpoint!.getColumnData("POE_INVHDR.AP_TERMS_CODE")
while 1
	readrecord(apm10c_dev,key=firm_id$+"C"+ap_terms_code$,dom=*break)apm10c$
	callpoint!.setDevObject("disc_pct",apm10c.disc_percent$)
	callpoint!.setDevObject("inv_amt",callpoint!.getColumnData("POE_INVHDR.INVOICE_AMT"))
	callpoint!.setDevObject("tot_dist","")
	callpoint!.setDevObject("tot_gl","")
	gosub calc_gl_tots	
	gosub calc_grid_tots
	gosub disp_dist_bal
	vendor_id$ = callpoint!.getColumnData("POE_INVHDR.VENDOR_ID")
	gosub disp_vendor_comments
	callpoint!.setStatus("REFRESH")
	break
wend
[[POE_INVHDR.ACCT_DATE.AVAL]]
rem make sure accting date is in an appropriate GL period
gl$=callpoint!.getDevObject("gl_int")
acctgdate$=callpoint!.getUserInput()        
if gl$="Y" 
	call stbl("+DIR_PGM")+"glc_datecheck.aon",acctgdate$,"Y",per$,yr$,status
	if status>99
		callpoint!.setStatus("ABORT")
	else
		callpoint!.setDevObject("gl_year",yr$)
		callpoint!.setDevObject("gl_per",per$)
	endif
endif
[[POE_INVHDR.VENDOR_ID.AVAL]]
vendor_id$ = callpoint!.getUserInput()
ap_type$=callpoint!.getColumnData("POE_INVHDR.AP_TYPE")

gosub vendor_info
gosub disp_vendor_comments
gosub get_vendor_history

if vend_hist$="" and callpoint!.getDevObject("multi_types")="Y"
	msg_id$="AP_NOHIST"
	gosub disp_message
	callpoint!.setStatus("CLEAR-NEWREC")
endif
[[POE_INVHDR.NET_INV_AMT.AVAL]]
rem re-calc discount amount based on net x disc %
disc_amt=num(callpoint!.getUserInput())*(num(callpoint!.getDevObject("disc_pct"))/100)
callpoint!.setColumnData("POE_INVHDR.DISCOUNT_AMT",str(disc_amt))
callpoint!.setStatus("REFRESH:POE_INVHDR.DISCOUNT_AMT")
[[POE_INVHDR.BWRI]]
rem --- re-check acct date
gl$=callpoint!.getDevObject("gl_int")
status=0
acctgdate$=callpoint!.getColumnData("POE_INVHDR.ACCT_DATE")  
if gl$="Y" 
	call stbl("+DIR_PGM")+"glc_datecheck.aon",acctgdate$,"Y",per$,yr$,status
	if status>99
		callpoint!.setStatus("ABORT")
	endif
endif

rem --- check vend hist file to be sure this vendor/ap type ok together; also make sure all key fields are entered

dont_write$=""

if cvs(callpoint!.getColumnData("POE_INVHDR.VENDOR_ID"),3)="" or
:	cvs(callpoint!.getColumnData("POE_INVHDR.AP_INV_NO"),3)="" then dont_write$="Y"

vendor_id$ = callpoint!.getColumnData("POE_INVHDR.VENDOR_ID")
ap_type$=callpoint!.getColumnData("POE_INVHDR.AP_TYPE")
gosub get_vendor_history
if vend_hist$="" and callpoint!.getDevObject("multi_types")="Y" then dont_write$="Y"

if dont_write$="Y"
	msg_id$="AP_INVOICEWRITE"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif


[[POE_INVHDR.AREC]]
callpoint!.setColumnData("<<DISPLAY>>.comments","")
callpoint!.setDevObject("inv_amt","")
callpoint!.setDevObject("tot_dist","")
callpoint!.setDevObject("tot_gl","")
callpoint!.setColumnData("<<DISPLAY>>.DIST_BAL","0")
rem --- Re-enable disabled fields
callpoint!.setColumnEnabled("POE_INVHDR.AP_DIST_CODE",1)
callpoint!.setColumnEnabled("POE_INVHDR.INV_DATE",1)
callpoint!.setColumnEnabled("POE_INVHDR.NET_INV_AMT",1)
rem --- disable opt buttons
callpoint!.setOptionEnabled("INVD",0)
callpoint!.setOptionEnabled("GDIS",0)
[[POE_INVHDR.INV_DATE.AVAL]]
invdate$=callpoint!.getUserInput()
terms_cd$=callpoint!.getColumnData("POE_INVHDR.AP_TERMS_CODE")
if cvs(terms_cd$,3)="" then terms_cd$=callpoint!.getDevObject("dflt_terms_cd")
if cvs(callpoint!.getDevObject("dflt_acct_date"),2)=""
	callpoint!.setColumnData("POE_INVHDR.ACCT_DATE",callpoint!.getUserInput())
else
	callpoint!.setColumnData("POE_INVHDR.ACCT_DATE",callpoint!.getDevObject("dflt_acct_date"))
endif
tmp_inv_date$=callpoint!.getUserInput()
gosub calculate_due_and_discount
callpoint!.setStatus("REFRESH")
[[POE_INVHDR.ASHO]]
rem --- get default date
call stbl("+DIR_SYP")+"bam_run_prog.bbj","POE_INVDATE",stbl("+USER_ID"),"MNT","",table_chans$[all]
callpoint!.setDevObject("dflt_acct_date",stbl("DEF_ACCT_DATE"))
