[[APE_MANCHECKDET.AUDE]]
rem --- Recalc totals for header
	gosub calc_tots
	gosub disp_tots
[[APE_MANCHECKDET.BDEL]]
rem --- need to delete the GL dist recs here (but don't try if nothing in grid row/rec_data$)
if cvs(rec_data$,3)<>"" gosub delete_gldist
	
	
[[APE_MANCHECKDET.INVOICE_AMT.AVEC]]
gosub calc_tots
gosub disp_tots
[[APE_MANCHECKDET.ADEL]]
rem --- Recalc totals for header
	gosub calc_tots
	gosub disp_tots
[[APE_MANCHECKDET.DISCOUNT_AMT.AVEC]]
gosub calc_tots
gosub disp_tots
[[APE_MANCHECKDET.DISCOUNT_AMT.AVAL]]
net_paid=num(callpoint!.getColumnData("APE_MANCHECKDET.INVOICE_AMT"))-num(callpoint!.getUserInput())
callpoint!.setColumnData("APE_MANCHECKDET.NET_PAID_AMT",str(net_paid))
glns!=bbjapi().getNamespace("GLNS","GL Dist",1)
glns!.setValue("dist_amt",callpoint!.getColumnData("APE_MANCHECKDET.INVOICE_AMT"))
glns!.setValue("dflt_dist",user_tpl.dflt_dist_cd$)
glns!.setValue("dflt_gl",user_tpl.dflt_gl_account$)
glns!.setValue("tot_inv",callpoint!.getColumnData("APE_MANCHECKDET.INVOICE_AMT"))
callpoint!.setStatus("MODIFIED-REFRESH")
[[APE_MANCHECKDET.INVOICE_AMT.AVAL]]
rem --- if invoice # isn't in open invoice file, invoke GL Dist grid

net_paid=num(callpoint!.getUserInput())-num(callpoint!.getColumnData("APE_MANCHECKDET.DISCOUNT_AMT"))
callpoint!.setColumnData("APE_MANCHECKDET.NET_PAID_AMT",str(net_paid))

glns!=bbjapi().getNamespace("GLNS","GL Dist",1)
glns!.setValue("dist_amt",callpoint!.getUserInput())
glns!.setValue("dflt_dist",user_tpl.dflt_dist_cd$)
glns!.setValue("dflt_gl",user_tpl.dflt_gl_account$)
glns!.setValue("tot_inv",callpoint!.getUserInput())

apt_invoicehdr_dev=fnget_dev("APT_INVOICEHDR")			
dim apt01a$:fnget_tpl$("APT_INVOICEHDR")
ap_type$=field(apt01a$,"AP_TYPE")
vendor_id$=field(apt01a$,"VENDOR_ID")
ap_type$(1)=UserObj!.getItem(num(user_tpl.ap_type_vpos$)).getText()
vendor_id$(1)=UserObj!.getItem(num(user_tpl.vendor_id_vpos$)).getText()

apt01ak1$=firm_id$+ap_type$+vendor_id$+callpoint!.getColumnData("APE_MANCHECKDET.AP_INV_NO")

readrecord(apt_invoicehdr_dev,key=apt01ak1$,dom=*next)apt01a$
if apt01a$(1,len(apt01ak1$))<>apt01ak1$ and num(callpoint!.getUserInput())<>0

	rem --- make sure fields (ap type, vendor ID, check#) needed to build GL Dist recs are present, and that AP type/Vendor go together
	dont_allow$=""	
	gosub validate_mandatory_data

	if dont_allow$="Y"
		msg_id$="AP_MANCHKWRITE"
		gosub disp_message
	else	
		rem --- save row/column so we'll know where to set focus when we return from GL Dist, and run GL Dist form	
		w!=Form!.getChildWindow(1109)
		c!=w!.getControl(5900)
		return_to_row=c!.getSelectedRow()
		return_to_col=c!.getSelectedColumn()
		rem --- invoke GL Dist form
		gosub get_gl_tots
		user_id$=stbl("+USER_ID")
		dim dflt_data$[1,1]
		dflt_data$[1,0]="GL_ACCOUNT"
		dflt_data$[1,1]=user_tpl.dflt_gl_account$
		key_pfx$=callpoint!.getColumnData("APE_MANCHECKDET.FIRM_ID")+callpoint!.getColumnData("APE_MANCHECKDET.AP_TYPE")+
:			callpoint!.getColumnData("APE_MANCHECKDET.CHECK_NO")+callpoint!.getColumnData("APE_MANCHECKDET.VENDOR_ID")+
:			callpoint!.getColumnData("APE_MANCHECKDET.AP_INV_NO")
		call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"APE_MANCHECKDIST",
:		user_id$,
:		"MNT",
:		key_pfx$,
:		table_chans$[all],
:		"",
:		dflt_data$[all]
		rem --- return focus to where we were (should be discount amt on same row)
		c!.focus()
		c!.accept(1,err=*next)
		c!.startEdit(return_to_row,return_to_col+1)
	endif	
endif
callpoint!.setStatus("MODIFIED-REFRESH")
[[APE_MANCHECKDET.AP_INV_NO.AVAL]]
apt_invoicehdr_dev=fnget_dev("APT_INVOICEHDR")
apt_invoicedet_dev=fnget_dev("APT_INVOICEDET")
dim apt01a$:fnget_tpl$("APT_INVOICEHDR")
dim apt11a$:fnget_tpl$("APT_INVOICEDET")
inv_amt=0,disc_amt=0,ret_amt=0
ap_type$=field(apt01a$,"AP_TYPE")
vendor_id$=field(apt01a$,"VENDOR_ID")
ap_type$(1)=UserObj!.getItem(num(user_tpl.ap_type_vpos$)).getText()
vendor_id$(1)=UserObj!.getItem(num(user_tpl.vendor_id_vpos$)).getText()
apt01ak1$=firm_id$+ap_type$+vendor_id$+callpoint!.getUserInput()
apt11ak1$=apt01ak1$(1,len(apt01ak1$)-2)
ape22_dev1=user_tpl.ape22_dev1
call stbl("+DIR_SYP")+"bac_key_template.bbj","APE_MANCHECKDET","ALT_KEY_01",ape22_key1$,rd_table_chans$[all],status$
readrecord(apt_invoicehdr_dev,key=apt01ak1$,dom=*next)apt01a$
if apt01a$(1,len(apt01ak1$))=apt01ak1$
	if apt01a.selected_for_pay$="Y"
		callpoint!.setMessage("AP_INV_IN_USE:Check")
		ape02_key$=firm_id$+callpoint!.getColumnData("APE_MANCHECKDET.AP_TYPE")+
:						callpoint!.getColumnData("APE_MANCHECKDET.CHECK_NO")+
:						callpoint!.getColumnData("APE_MANCHECKDET.VENDOR_ID")
		callpoint!.setStatus("ABORT-RECORD:"+ape02_key$)
		goto end_of_inv_aval
	endif
	if apt01a.hold_flag$="Y"
		callpoint!.setMessage("AP_INV_HOLD")
		ape02_key$=firm_id$+callpoint!.getColumnData("APE_MANCHECKDET.AP_TYPE")+
:						callpoint!.getColumnData("APE_MANCHECKDET.CHECK_NO")+
:						callpoint!.getColumnData("APE_MANCHECKDET.VENDOR_ID")
		callpoint!.setStatus("ABORT-RECORD:"+ape02_key$)
		goto end_of_inv_aval		
	endif
	dim ape22_key$:ape22_key1$
	read(ape22_dev1,key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$,knum=1,dom=*next)
		ape22_key$=key(ape22_dev1,end=*next)
	if pos(firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$=ape22_key$)=1 and
:		ape22_key.check_no$<>callpoint!.getColumnData("APE_MANCHECKDET.CHECK_NO")
		callpoint!.setMessage("AP_INV_IN_USE:Manual Check")
		ape02_key$=firm_id$+callpoint!.getColumnData("APE_MANCHECKDET.AP_TYPE")+
:						callpoint!.getColumnData("APE_MANCHECKDET.CHECK_NO")+
:						callpoint!.getColumnData("APE_MANCHECKDET.VENDOR_ID")
		callpoint!.setStatus("ABORT-RECORD:"+ape02_key$)
		goto end_of_inv_aval
	endif
	inv_amt=num(apt01a.invoice_amt$)
	disc_amt=num(apt01a.discount_amt$)
	ret_amt=num(apt01a.retention$)
	more_dtl=1
	read(apt_invoicedet_dev,key=apt11ak1$,dom=*next)							
	while more_dtl
		readrecord(apt_invoicedet_dev,end=*next)apt11a$
		if apt11a$(1,len(apt11ak1$))=apt11ak1$
			inv_amt=inv_amt+num(apt11a.trans_amt$)
			disc_amt=disc_amt+num(apt11a.trans_disc$)
			ret_amt=ret_amt+num(apt11a.trans_ret$)			
		else
			more_dtl=0
		endif
	wend
	callpoint!.setColumnData("APE_MANCHECKDET.INVOICE_DATE",apt01a.invoice_date$)
	callpoint!.setColumnData("APE_MANCHECKDET.AP_DIST_CODE",apt01a.ap_dist_code$)
	rem --- disable inv date/dist code, leaving only inv amt/disc amt enabled for open invoice
	w!=Form!.getChildWindow(1109)
	c!=w!.getControl(5900)
	c!.setColumnEditable(1,0)
	c!.setColumnEditable(2,0)
	c!.startEdit(c!.getSelectedRow(),4)
else
	rem --- enable inv date/dist code if on invoice not in open invoice file
	rem --- also have user confirm that the invoice wasn't found in Open Invoice file
	msg_id$="AP_EXT_INV"
	gosub disp_message
	w!=Form!.getChildWindow(1109)
	c!=w!.getControl(5900)
	c!.setColumnEditable(1,1)
	c!.setColumnEditable(2,1)
	c!.startEdit(c!.getSelectedRow(),1)
	callpoint!.setColumnData("APE_MANCHECKDET.AP_DIST_CODE",user_tpl.dflt_dist_cd$)
	callpoint!.setColumnData("APE_MANCHECKDET.INVOICE_DATE",callpoint!.getHeaderColumnData("APE_MANCHECKHDR.CHECK_DATE"))
endif
callpoint!.setColumnData("APE_MANCHECKDET.INVOICE_AMT",str(inv_amt))
callpoint!.setColumnData("APE_MANCHECKDET.DISCOUNT_AMT",str(disc_amt))
callpoint!.setColumnData("APE_MANCHECKDET.RETENTION",str(ret_amt))
callpoint!.setColumnData("APE_MANCHECKDET.NET_PAID_AMT",str(inv_amt-disc_amt-ret_amt))
callpoint!.setStatus("MODIFIED-REFRESH")
end_of_inv_aval:
[[APE_MANCHECKDET.<CUSTOM>]]
calc_tots:
	recVect!=GridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs=recVect!.size()
	tinv=0,tdisc=0,tret=0
	if numrecs>0
		for reccnt=0 to numrecs-1			
				gridrec$=recVect!.getItem(reccnt)
				if cvs(gridrec$,3)<> "" and callpoint!.getGridRowDeleteStatus(reccnt)<>"Y" 
					tinv=tinv+num(gridrec.invoice_amt$)
					tdisc=tdisc+num(gridrec.discount_amt$)
					tret=tret+num(gridrec.retention$)
				endif
		next reccnt
	endif
return
disp_tots:
    rem --- get context and ID of display controls for totals, and redisplay w/ amts from calc_tots
    rem --- also setHeaderColumnData so Barista's values for these display controls will stay in sync
    
    tinv!=UserObj!.getItem(num(user_tpl.tinv_vpos$))
    tinv!.setValue(tinv)
    callpoint!.setHeaderColumnData("<<DISPLAY>>.DISP_TOT_INV",str(tinv))
    tdisc!=UserObj!.getItem(num(user_tpl.tdisc_vpos$))
    tdisc!.setValue(tdisc)
    callpoint!.setHeaderColumnData("<<DISPLAY>>.DISP_TOT_DISC",str(tdisc))
    tret!=UserObj!.getItem(num(user_tpl.tret_vpos$))
    tret!.setValue(tret)
    callpoint!.setHeaderColumnData("<<DISPLAY>>.DISP_TOT_RETEN",str(tret))
    tchk!=UserObj!.getItem(num(user_tpl.tchk_vpos$))
    tchk!.setValue(tinv-tdisc-tret)
    callpoint!.setHeaderColumnData("<<DISPLAY>>.DISP_TOT_CHECK",str(tinv-tdisc-tret))
return
get_gl_tots:
	ape12_dev=fnget_dev("APE_MANCHECKDIST")				
	dim ape12a$:fnget_tpl$("APE_MANCHECKDIST")
	amt_dist=0
	ape12ak1$=firm_id$+callpoint!.getColumnData("APE_MANCHECKDET.AP_TYPE")+
:	callpoint!.getColumnData("APE_MANCHECKDET.CHECK_NO")+callpoint!.getColumnData("APE_MANCHECKDET.VENDOR_ID")+
:	callpoint!.getColumnData("APE_MANCHECKDET.AP_INV_NO")
	read(ape12_dev,key=ape12ak1$,dom=*next)
	more_dtl=1
	while more_dtl
		read record(ape12_dev,end=*break)ape12a$
		if ape12a$(1,len(ape12ak1$))=ape12ak1$
			amt_dist=amt_dist+num(ape12a.gl_post_amt$)
		else
			more_dtl=0
		endif
	wend
		pfx$="GLNS",nm$="GL Dist"
		GLNS!=BBjAPI().getNamespace(pfx$,nm$,1)
		GLNS!.setValue("dist_amt",str(amt_dist))
return
delete_gldist:
	ape12_dev=fnget_dev("APE_MANCHECKDIST")
	dim ape12a$:fnget_tpl$("APE_MANCHECKDIST")
	remove_ky$=firm_id$+callpoint!.getColumnData("APE_MANCHECKDET.AP_TYPE") +
:		callpoint!.getColumnData("APE_MANCHECKDET.CHECK_NO") +
:		callpoint!.getColumnData("APE_MANCHECKDET.VENDOR_ID") +
:		callpoint!.getColumnData("APE_MANCHECKDET.AP_INV_NO")
	read (ape12_dev,key=remove_ky$,dom=*next)
	while 1
		k$=key(ape12_dev,end=*break)
		if pos(remove_ky$=k$)<>1 then break
		remove(ape12_dev,key=k$)
	wend
return

validate_mandatory_data:

	dont_allow$=""

	if cvs(callpoint!.getHeaderColumnData("APE_MANCHECKHDR.CHECK_DATE"),3)="" or
:		cvs(callpoint!.getHeaderColumnData("APE_MANCHECKHDR.CHECK_NO"),3)="" or
:		cvs(callpoint!.getHeaderColumnData("APE_MANCHECKHDR.VENDOR_ID"),3)="" then dont_allow$="Y"

	vend_hist$=""
	tmp_vendor_id$=callpoint!.getHeaderColumnData("APE_MANCHECKHDR.VENDOR_ID")
	gosub get_vendor_history
	if vend_hist$<>"Y" then dont_allow$="Y"

return

get_vendor_history:
	apm02_dev=fnget_dev("APM_VENDHIST")				
	dim apm02a$:fnget_tpl$("APM_VENDHIST")
	vend_hist$=""
	readrecord(apm02_dev,key=firm_id$+tmp_vendor_id$+
:		callpoint!.getHeaderColumnData("APE_MANCHECKHDR.AP_TYPE"),dom=*next)apm02a$
	if apm02a.firm_id$+apm02a.vendor_id$+apm02a.ap_type$=firm_id$+tmp_vendor_id$+
:		callpoint!.getHeaderColumnData("APE_MANCHECKHDR.AP_TYPE")
			vend_hist$="Y"
	endif
return
