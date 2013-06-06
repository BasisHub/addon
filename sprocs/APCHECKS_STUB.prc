rem ----------------------------------------------------------------------------
rem --- Program: APChecks_Stub.prc (Vendor and Accounting Stubs)
rem
rem --- Description: APChecks_MAIN.prc is a stored Procedure to create jasper-based,
rem ---              3-part AP Checks with user-selectable part-order from these options:
rem ---                - A => Accounting Stub          ==> APChecks_Stub.prc
rem ---                - V => Vendor Stub              ==> APChecks_Stub.prc
rem ---                - C => Check (the check itself) ==> APChecks_Check.prc
rem ---            - apr_apchecks.aon does the bulk of the processing logic including
rem ---              writing to a jasper print work file: APW_CHKJASPERPRN. This work file
rem ---              is used for SQL queries for jasper.
rem ---            - APChecks_MAIN.prc does the first query, to get the 'driver' info
rem ---              for the -main.jrxml.
rem ---            - The subreport, APChecks_Stub.prc/-stub.jrxml, prints vendor and 
rem ---              accounting stubs by querying the work file based on -main's calling params.
rem ---            - The subreport, APChecks_Check.prc/-check.jrxml, prints each check 
rem ---              itself by querying the work file based on -main's calling params. Stub overflow
rem ---              is indicated in the workfile as a VOID check record.

rem --- See apr_apchecks.aon for more info.

rem --- AddonSoftware
rem --- Copyright BASIS International Ltd.  All Rights Reserved.
rem --- All Rights Reserved
rem ----------------------------------------------------------------------------

	seterr sproc_error

	declare BBjStoredProcedureData sp!
	declare BBjRecordSet rs!
	declare BBjRecordData data!

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get 'IN' SPROC parameters 

	firm_id$ =       sp!.getParameter("FIRM_ID")
	barista_wd$ =    sp!.getParameter("BARISTA_WD")
	check_no$ =      sp!.getParameter("CHECK_NUM")
	ap_type$ =       sp!.getParameter("AP_TYPE")
	vendor_id$ =     sp!.getParameter("VENDOR_ID")
	stub_type$ =     sp!.getParameter("STUB_TYPE"); rem (V)endStub/(A)cctingStub...Which stub are we printing?
	curr_page$=      sp!.getParameter("CURR_PAGE")
	
	ap_address1_name$ = sp!.getParameter("AP_ADDRESS1_NAME")
	ap_address2$ =      sp!.getParameter("AP_ADDRESS2")
	ap_address3$ =      sp!.getParameter("AP_ADDRESS3")
	ap_address4$ =      sp!.getParameter("AP_ADDRESS4")
	ap_addr3_stub$ =    sp!.getParameter("AP_ADDR3_STUB")

	logo_file$ =        sp!.getParameter("LOGO_FILE")

	vend_name$ =        sp!.getParameter("VEND_NAME")
	vend_addr1$ =       sp!.getParameter("VEND_ADDR1")
	vend_addr2$ =       sp!.getParameter("VEND_ADDR2")
	vend_addr3$ =       sp!.getParameter("VEND_ADDR3")

	vend_mask$ =     sp!.getParameter("VEND_MASK")
	gl_acct_mask$ =  sp!.getParameter("GL_ACCT_MASK")
	stub_amt_mask$ = sp!.getParameter("STUB_AMT_MASK")

	max_stub_rows=  num(sp!.getParameter("MAX_STUB_ROWS"))

	chdir barista_wd$

rem --- Create the memory recordset for return to jasper

	dataTemplate$ = ""
	dataTemplate$ = dataTemplate$ + "check_date:C(10), invoice_number:C(7), invoice_date:C(10), "
	dataTemplate$ = dataTemplate$ + "invoice_amt:C(1*), discount_amt:C(1*), amount_paid:C(1*), "
	dataTemplate$ = dataTemplate$ + "invoice_amt_tot:C(1*), discount_amt_tot:C(1*), amount_paid_tot:C(1*), "
	dataTemplate$ = dataTemplate$ + "memo_gldist:C(30*)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

initializations: rem --- Initializations
	
	FALSE=0
	TRUE=1
	rows_inserted=0
	
rem --- Get data from work file

	sql_prep$=""
	sql_prep$=sql_prep$+"SELECT check_date "
	sql_prep$=sql_prep$+"      ,vendor_id "
	sql_prep$=sql_prep$+"      ,stub_inv_no "
	sql_prep$=sql_prep$+"      ,stub_inv_date "
	sql_prep$=sql_prep$+"      ,stub_memo_dist "
	sql_prep$=sql_prep$+"      ,stub_is_total "
	sql_prep$=sql_prep$+"      ,stub_inv_amt "
	sql_prep$=sql_prep$+"      ,stub_inv_discamt "
	sql_prep$=sql_prep$+"      ,stub_inv_amt_pd "
	sql_prep$=sql_prep$+"FROM APW_CHKJASPERPRN "
	sql_prep$=sql_prep$+"WHERE firm_id='"+firm_id$+"' "
	sql_prep$=sql_prep$+"  AND ap_type='"+ap_type$+"' "
	sql_prep$=sql_prep$+"  AND check_no='"+check_no$+"' "
	sql_prep$=sql_prep$+"  AND chk_pagenum='"+curr_page$+"' "; rem Though a APType-Vendor may have multi checks (overflow), process only one pg at a time
	sql_prep$=sql_prep$+"  AND section_type='"+stub_type$+"' "
	
	sql_chan=sqlunt
	sqlopen(sql_chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
	sqlprep(sql_chan)sql_prep$
	dim read_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)

rem --- Loop through result set from work file query
	prev_inv_no$=""
	
	while TRUE
		
		read_tpl$ = sqlfetch(sql_chan,end=*break)
		
		if prev_inv_no$="" or prev_inv_no$<>read_tpl.stub_inv_no$
			inv_no$=          read_tpl.stub_inv_no$
			inv_date$=fndate$(read_tpl.stub_inv_date$)
			inv_amt$=     str(read_tpl.stub_inv_amt:stub_amt_mask$)
			inv_discamt$= str(read_tpl.stub_inv_discamt:stub_amt_mask$)
			inv_amt_pd$=  str(read_tpl.stub_inv_amt_pd:stub_amt_mask$)	
			
			prev_inv_no$=read_tpl.stub_inv_no$
		else
			rem --- don't repeat fields when printing multiple memo/GL Dist
			inv_no$=  ""
			inv_date$=""
			inv_amt$= ""
			inv_discamt$= ""
			inv_amt_pd$=  ""
		endif
		
		if read_tpl.stub_is_total$<>"Y" then 				
			data! = rs!.getEmptyRecordData()
			data!.setFieldValue("CHECK_DATE", fndate$(read_tpl.check_date$))
			data!.setFieldValue("INVOICE_NUMBER", inv_no$)
			data!.setFieldValue("INVOICE_DATE", inv_date$)
			data!.setFieldValue("INVOICE_AMT", inv_amt$)
			data!.setFieldValue("DISCOUNT_AMT", inv_discamt$)
			data!.setFieldValue("AMOUNT_PAID", inv_amt_pd$)
			data!.setFieldValue("MEMO_GLDIST", read_tpl.stub_memo_dist$)
						
			rs!.insert(data!)
			rows_inserted=rows_inserted+1
		else
			rem --- Add rows to fill so totals line is always at same place and stub is same height
			while rows_inserted < max_stub_rows-1
				data! = rs!.getEmptyRecordData()
				rs!.insert(data!)
				rows_inserted=rows_inserted+1
			wend
			
			rem --- Send totals or Continued
			data! = rs!.getEmptyRecordData()
			if pos("Continued"=read_tpl.stub_memo_dist$)
				data!.setFieldValue("INVOICE_AMT_TOT", "")
				data!.setFieldValue("DISCOUNT_AMT_TOT", "")
				data!.setFieldValue("AMOUNT_PAID_TOT", "")
				data!.setFieldValue("MEMO_GLDIST", read_tpl.stub_memo_dist$); rem will be "** Continued **" when overflow
			else
				data!.setFieldValue("INVOICE_AMT_TOT", str(read_tpl.stub_inv_amt:stub_amt_mask$))
				data!.setFieldValue("DISCOUNT_AMT_TOT", str(read_tpl.stub_inv_discamt:stub_amt_mask$))
				data!.setFieldValue("AMOUNT_PAID_TOT", str(read_tpl.stub_inv_amt_pd:stub_amt_mask$))
				data!.setFieldValue("MEMO_GLDIST", "")			
			endif
			
			rs!.insert(data!)

		endif
				
	wend
		
	sp!.setRecordSet(rs!)
	
	goto std_exit


disp_message: rem --- Display Message Dialog

    call stbl("+DIR_SYP")+"bac_message.bbj",msg_id$,msg_tokens$[all],msg_opt$,table_chans$[all]
    return

rem #include std_functions.src
rem --- Standard AddonSoftware functions (01Mar2006)
rem --- Functions used to retrieve form values

    def fnstr_pos(q0$,q1$,q1)=int((pos(q0$=q1$,q1)+q1-1)/q1)
    def fnget_rec_date$(q0$)=rd_rec_data$[fnstr_pos(cvs(q0$,1+2+4)+"."+
:                            cvs(q0$,1+2+4),rd_rec_data$[0,0],40),0]
    def fnget_fld_data$(q0$,q1$)=cvs(rd_rec_data$[fnstr_pos(cvs(q0$,1+2+4)+"."+
:                                cvs(q1$,1+2+4),rd_rec_data$[0,0],40),0],2)
    def fnget_table$(q0$)=rd_alias_id$


rem --- Miscellaneous functions

    def fncenter(q$,q)=int((q-len(q$))/2)

rem --- Format inventory item description

	def fnitem$(q$,q1,q2,q3)
		q$=pad(q$,q1+q2+q3)
		return cvs(q$(1,q1)+" "+q$(q1+1,q2)+" "+q$(q1+q2+1,q3),32)
	fnend

rem --- Date/time handling functions

    def fndate$(q$)
    q1$=""
    q1$=date(jul(num(q$(1,4)),num(q$(5,2)),num(q$(7,2)),err=*next),err=*next)
    if q1$="" q1$=q$
    return q1$
    fnend

    def fnyy$(q$)=q$(3,2)
    def fnclock$(q$)=date(0:"%hz:%mz %p")
    def fntime$(q$)=date(0:"%Hz%mz")

rem --- fnmask$: Alphanumeric Masking Function (formerly fnf$)

    def fnmask$(q1$,q2$)
    if q2$="" q2$=fill(len(q1$),"0")
    return str(-num(q1$,err=*next):q2$,err=*next)
    q=1
    q0=0
    while len(q2$(q))
        if pos(q2$(q,1)="-()") q0=q0+1 else q2$(q,1)="X"
        q=q+1
    wend
    if len(q1$)>len(q2$)-q0 q1$=q1$(1,len(q2$)-q0)
    return str(q1$:q2$)
    fnend

rem --- fnbasename$: Strip path and optionally the suffix from a file name

    def fnbasename$(q$,q0$)
    q=max(pos("/"=q$,-1),pos(":"=q$,-1),pos(">"=q$,-1),pos("\"=q$,-1))
    if q then q$=q$(q+1)
    if q0$<>"" then q=mask(q$,q0$); if q q$=q$(1,q-1)
    return q$
	fnend

rem --- fnglobal: Return numeric value of passed stbl variable

    def fnglobal(q$,q1)
    q1$=stbl(q$,err=*next),q1=num(q1$,err=*next)
    return q1
    fnend

rem --- fnglobal$: Return string value of passed STBL variable

    def fnglobal$(q$,q1$)
    q1$=stbl(q$,err=*next)
    return q1$
    fnend

rem #endinclude std_functions.src   

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num
    
std_exit:
    end