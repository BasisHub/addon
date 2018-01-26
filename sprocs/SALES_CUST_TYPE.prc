rem SALES_CUST_TYPE.prc
rem 
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

rem ' Return sales totals by customer type for a given month period

seterr sproc_error

rem ' Declare some variables ahead of time
declare BBjStoredProcedureData sp!
declare BBjRecordSet rs!
declare BBjRecordData data!

rem ' Get the infomation object for the Stored Procedure
sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem ' Get the IN and IN/OUT parameters used by the procedure
firm_id$=sp!.getParameter("FIRM_ID")
beg_dt$ = sp!.getParameter("BEGDATE")
end_dt$ = sp!.getParameter("ENDDATE")
barista_wd$=sp!.getParameter("BARISTA_WD")

sv_wd$=dir("")
chdir barista_wd$

rem ' set up the sql query
sql$ = "SELECT SUM(t1.TOTAL_SALES) as total_sales, t2.CUSTOMER_TYPE as CUST_TYPE, t3.CODE_DESC "
sql$ = sql$ + "FROM OPT_INVHDR t1 "
sql$ = sql$ + "INNER JOIN ARM_CUSTDET t2 ON t1.firm_id = t2.firm_id AND t1.CUSTOMER_ID = t2.CUSTOMER_ID AND t2.AR_TYPE = '  ' "
sql$ = sql$ + "INNER JOIN ARC_CUSTTYPE t3 ON t2.firm_id = t3.firm_id AND t3.RECORD_ID_L='L' AND t2.CUSTOMER_TYPE = t3.CUSTOMER_TYPE "
sql$ = sql$ + "WHERE t1.trans_status='U' AND t1.firm_id = '" + firm_id$ + "' AND t1.ar_type = '  ' AND t1.INVOICE_DATE >= '" + beg_dt$ + "' and t1.INVOICE_DATE <= '" +end_dt$ + "' "
sql$ = sql$ + "GROUP BY t2.CUSTOMER_TYPE, t3.CODE_DESC "
sql$ = sql$ + "ORDER BY total_sales DESC "

chan = sqlunt
sqlopen(chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
sqlprep(chan)sql$
dim irec$:sqltmpl(chan)
sqlexec(chan)

rs! = BBJAPI().createMemoryRecordSet("FIRM_ID:C(2),CUST_TYPE:C(3),CODE_DESC:C(20),TOTAL_SALES:N(15)")

while 1
    irec$ = sqlfetch(chan,err=*break)
    data! = rs!.getEmptyRecordData()    
    data!.setFieldValue("FIRM_ID",firm_id$)
    data!.setFieldValue("CUST_TYPE",irec.cust_type$)
    data!.setFieldValue("CODE_DESC",irec.code_desc$)
    data!.setFieldValue("TOTAL_SALES",str(irec.total_sales))
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


