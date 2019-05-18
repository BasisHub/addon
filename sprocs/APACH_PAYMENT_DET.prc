rem ------------------------------------------------------------------------------------
rem --- Program: APACH_PAYMENT_DET.prc
rem --- Description: Stored Procedure to create a jasper-based ACH Payment detail sub-report
rem
rem --- AddonSoftware
rem --- Copyright BASIS International Ltd.  All Rights Reserved.
rem ------------------------------------------------------------------------------------

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
    amt_mask$ = sp!.getParameter("AMT_MASK")
    barista_wd$ = sp!.getParameter("BARISTA_WD")

    chdir barista_wd$

rem --- Create the memory recordset for return to jasper
    dataTemplate$ = "invoice_date:c(10),invoice:c(1*),invoice_amt:c(1*),discount:c(1*),amount_paid:c(1*),total_amt_paid:c(1*)"
    rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

rem --- Get data from work file
    sql_prep$=""
    sql_prep$=sql_prep$+"SELECT stub_inv_date "
    sql_prep$=sql_prep$+"      ,stub_inv_no "
    sql_prep$=sql_prep$+"      ,section_type "
    sql_prep$=sql_prep$+"      ,stub_inv_amt "
    sql_prep$=sql_prep$+"      ,stub_inv_discamt "
    sql_prep$=sql_prep$+"      ,stub_inv_amt_pd "
    sql_prep$=sql_prep$+"      ,stub_is_total "
    sql_prep$=sql_prep$+"FROM APW_CHKJASPERPRN "
    sql_prep$=sql_prep$+"WHERE firm_id='"+firm_id$+"' "
    sql_prep$=sql_prep$+"  AND ap_type='"+ap_type$+"' "
    sql_prep$=sql_prep$+"  AND check_no='"+check_no$+"' "
    
    sql_chan=sqlunt
    sqlopen(sql_chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
    sqlprep(sql_chan)sql_prep$
    dim read_tpl$:sqltmpl(sql_chan)
    sqlexec(sql_chan)

rem --- Loop through result set from work file query
    total_amt=0
    while 1
        read_tpl$ = sqlfetch(sql_chan,end=*break)
        if read_tpl.section_type$="V" and read_tpl.stub_is_total$<>"Y" then                
            total_amt=total_amt+num(read_tpl.stub_inv_amt_pd)

            data! = rs!.getEmptyRecordData()
            data!.setFieldValue("INVOICE_DATE", fndate$(read_tpl.stub_inv_date$))
            data!.setFieldValue("INVOICE", read_tpl.stub_inv_no$)
            data!.setFieldValue("INVOICE_AMT", str(read_tpl.stub_inv_amt:amt_mask$))
            data!.setFieldValue("DISCOUNT", str(read_tpl.stub_inv_discamt:amt_mask$))
            data!.setFieldValue("AMOUNT_PAID", str(read_tpl.stub_inv_amt_pd:amt_mask$))
            data!.setFieldValue("TOTAL_AMT_PAID",str(total_amt:amt_mask$))
                        
            rs!.insert(data!)
        endif
    wend
    
rem --- Tell the stored procedure to return the result set.
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

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num

std_exit:
    end


