rem SALES_CUSTOMER.prc
rem 
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------
rem ' Return invoices by customer for a given month period

seterr sproc_error

rem ' Declare some variables ahead of time
declare BBjStoredProcedureData sp!
declare BBjRecordSet rs!
declare BBjRecordData data!

rem ' Get the infomation object for the Stored Procedure
sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem ' Get the IN and IN/OUT parameters used by the procedure
firm_id$=sp!.getParameter("FIRM_ID")
customer_nbr$=sp!.getParameter("CUSTOMER_NBR")
month$ = sp!.getParameter("MONTH")
year$ = sp!.getParameter("YEAR")
barista_wd$=sp!.getParameter("BARISTA_WD")

beg_dt$ = year$+month$+"01"
end_dt$ = year$+month$+"31"

sv_wd$=dir("")
chdir barista_wd$

rem ' set up the sql query
sql$ = "SELECT t1.ar_inv_no as ar_inv_nbr, "
sql$ = sql$ + "t1.invoice_date AS invoice_date, "
sql$ = sql$ + "t1.total_sales as invoice_amt FROM OPT_INVHDR t1 "
sql$ = sql$ + "WHERE t1.trans_status='U' AND firm_id = '" + firm_id$ + "' AND t1.ar_type = '  ' AND CUSTOMER_ID = '" + customer_nbr$ + "' AND t1.INVOICE_DATE >= '" + beg_dt$ + "' and t1.INVOICE_DATE <= '" +end_dt$ + "' "
sql$ = sql$ + "ORDER BY t1.ar_inv_no"

chan = sqlunt
sqlopen(chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
sqlprep(chan)sql$
dim irec$:sqltmpl(chan)
sqlexec(chan)

rs! = BBJAPI().createMemoryRecordSet("AR_INV_NBR:C(7),INVOICE_DATE:C(10),INVOICE_AMT:N(7*)")

while 1
    irec$ = sqlfetch(chan,err=*break)
    data! = rs!.getEmptyRecordData()    
    data!.setFieldValue("AR_INV_NBR",irec.ar_inv_nbr$)
    data!.setFieldValue("INVOICE_DATE",irec.invoice_date$(5,2)+"/"+irec.invoice_date$(7,2)+"/"+irec.invoice_date$(1,4))
    data!.setFieldValue("INVOICE_AMT",irec.invoice_amt$)
    rs!.insert(data!)
wend

rem ' Close the sql channel and set the stored procedure's result set to the record set that 
rem ' was created and populated in the code above
done:
sqlclose (chan)
sp!.setRecordSet(rs!)
end

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num


