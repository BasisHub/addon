rem -------------------------------------------------------------------------
rem --- Program: APACH_PAYMENT_HDR.prc
rem --- Description: Stored Procedure to create a jasper-based ACH Payment report
rem
rem --- AddonSoftware
rem --- Copyright BASIS International Ltd.  All Rights Reserved.
rem -------------------------------------------------------------------------

    seterr sproc_error
    
    declare BBjStoredProcedureData sp!
    declare BBjRecordSet rs!
    declare BBjRecordData data!

rem --- Get the infomation object for the Stored Procedure
    sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get 'IN' SPROC parameters 
    firm_id$ = sp!.getParameter("FIRM_ID")
    ap_type$ = sp!.getParameter("AP_TYPE")
    check_no$ = sp!.getParameter("CHECK_NO")
    vendor_id$=sp!.getParameter("VENDOR_ID")
    vend_mask$ = sp!.getParameter("VEND_MASK")
    amt_mask$ = sp!.getParameter("AMT_MASK")
    barista_wd$ = sp!.getParameter("BARISTA_WD")

    chdir barista_wd$

rem --- Create the memory record set for return to jasper
    dataTemplate$ = "vendor_id:C(1*),vendor_name:C(30),address1:C(30),address2:C(30),address3:C(30),"
    dataTemplate$ = dataTemplate$ + "check_no:C(1*),check_date:C(1*),check_amt:C(1*),"
    dataTemplate$ = dataTemplate$ + "sent_to1:C(1*),sent_to2:C(1*)"
    rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

rem --- open files
    files=2,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="apm-01",ids$[1]="APM_VENDMAST"
    files$[2]="apm_payaddr",ids$[2]="APM_PAYADDR"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")
        throw "File open error.",1001
    endif

    apm01_dev=channels[1]
    apmPayAddr_dev=channels[2]
    dim apm01a$:templates$[1]
    dim apmPayAddr$:templates$[2]

rem --- Format Vendor Address
    dim address$(3*30)
    find record (apm01_dev,key=firm_id$+vendor_id$,dom=*next) apm01a$
    address$(1)=apm01a.addr_line_1$+apm01a.addr_line_2$+apm01a.city$+apm01a.state_code$+apm01a.zip_code$+apm01a.cntry_id$
    vend_name$= apm01a.vendor_name$
    start_block = 1

    if start_block
        find record (apmPayAddr_dev,key=firm_id$+vendor_id$,dom=*endif) apmPayAddr$
        address$(1)= apmPayAddr.addr_line_1$+apmPayAddr.addr_line2$+apmPayAddr.city$+apmPayAddr.state_code$+apmPayAddr.zip_code$+apmPayAddr.cntry_id$
        vend_name$=  apmPayAddr.vendor_name$
    endif
    
    call pgmdir$+"adc_address.aon",address$,24,3,9,30

rem --- Get check date and amount
    sql_prep$=""
    sql_prep$=sql_prep$+"SELECT check_date "
    sql_prep$=sql_prep$+"      ,chk_amt "
    sql_prep$=sql_prep$+"FROM APW_CHKJASPERPRN "
    sql_prep$=sql_prep$+"WHERE firm_id='"+firm_id$+"' "
    sql_prep$=sql_prep$+"  AND ap_type='"+ap_type$+"' "
    sql_prep$=sql_prep$+"  AND check_no='"+check_no$+"' "
    sql_prep$=sql_prep$+"  AND section_type='C' "
    
    sql_chan=sqlunt
    sqlopen(sql_chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
    sqlprep(sql_chan)sql_prep$
    dim read_tpl$:sqltmpl(sql_chan)
    sqlexec(sql_chan)
    read_tpl$ = sqlfetch(sql_chan)

rem --- put data into recordset
    data! = rs!.getEmptyRecordData()
    data!.setFieldValue("VENDOR_ID",fnmask$(vendor_id$,vend_mask$))
    data!.setFieldValue("VENDOR_NAME",vend_name$)
    data!.setFieldValue("ADDRESS1", address$(1,30))
    data!.setFieldValue("ADDRESS2", address$(31,30))
    data!.setFieldValue("ADDRESS3", address$(61,30))
    data!.setFieldValue("CHECK_NO", check_no$)
    data!.setFieldValue("CHECK_DATE", fndate$(read_tpl.check_date$))
    data!.setFieldValue("CHECK_AMT", str(read_tpl.chk_amt:amt_mask$))
    data!.setFieldValue("SENT_TO1", apm01a.bank_name$)
    bnkAcctNo$=cvs(apm01a.bnk_acct_no$,2)
    if len(bnkAcctNo$)>4 then
        bnkAcctNo$=pad(bnkAcctNo$(len(bnkAcctNo$)-3),len(bnkAcctNo$),"R","x")
    else
        bnkAcctNo$=pad(bnkAcctNo$,6,"R","x")
    endif
    data!.setFieldValue("SENT_TO2", bnkAcctNo$)
    rs!.insert(data!)

rem --- close files
    close(apm01_dev,err=*next)
    close(apmPayAddr_dev,err=*next)

    sp!.setRecordSet(rs!)
    goto std_exit

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
        if cvs(q1$,2)="" return ""
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

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num

std_exit:
    end