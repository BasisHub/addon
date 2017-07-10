rem SALES_CUST_TYPE_CUST.prc
rem 
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------
rem ' Return sales totals by customer by customer type for a given month period

seterr sproc_error

rem ' Declare some variables ahead of time
declare BBjStoredProcedureData sp!
declare BBjRecordSet rs!
declare BBjRecordData data!

rem ' Get the infomation object for the Stored Procedure
sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem ' Get the IN and IN/OUT parameters used by the procedure
firm_id$=sp!.getParameter("FIRM_ID")
cust_type$=sp!.getParameter("CUST_TYPE")
beg_dt$ = sp!.getParameter("BEGDATE")
end_dt$ = sp!.getParameter("ENDDATE")
custIdMask$=sp!.getParameter("CUST_ID_MASK")
custIdLen=num(sp!.getParameter("CUST_ID_LEN"))
barista_wd$=sp!.getParameter("BARISTA_WD")

sv_wd$=dir("")
chdir barista_wd$

rem ' USE statements
use ::ado_func.src::func

rem ' set up the sql query
sql$ = "SELECT SUM(t1.total_sales) AS total_sales, t1.customer_id, t3.customer_name, t3.contact_name FROM OPT_INVHDR t1 "
sql$ = sql$ + "INNER JOIN ARM_CUSTDET t2 ON t1.firm_id = t2.firm_id AND t1.customer_id = t2.customer_id "
sql$ = sql$ + "INNER JOIN ARM_CUSTMAST t3 on t2.firm_id = t3.firm_id AND t2.customer_id = t3.customer_id "
sql$ = sql$ + "WHERE t1.trans_status='U' AND t1.firm_id = '" + firm_id$ + "' AND t1.ar_type = '  ' AND t2.customer_type = '" + cust_type$ + "' AND t1.INVOICE_DATE >= '" + beg_dt$ + "' and t1.INVOICE_DATE <= '" +end_dt$ + "' "
sql$ = sql$ + "GROUP BY t1.customer_id, t3.customer_name, t3.contact_name "
sql$ = sql$ + "ORDER BY total_sales DESC "

chan = sqlunt
sqlopen(chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
sqlprep(chan)sql$
dim irec$:sqltmpl(chan)
sqlexec(chan)

rs! = BBJAPI().createMemoryRecordSet("FIRM_ID:C(2),CUSTOMER_NBR:C(10),CUSTOMER_ID:C(6),CUST_NAME:C(30),CONTACT_NAME:C(20),TOTAL_SALES:N(15)")

while 1
    irec$ = sqlfetch(chan,err=*break)
    data! = rs!.getEmptyRecordData()    
    data!.setFieldValue("FIRM_ID",firm_id$)

    customer_id$ = irec.customer_id$
    data!.setFieldValue("CUSTOMER_NBR",func.alphaMask(customer_id$(1,custIdLen),custIdMask$))
    data!.setFieldValue("CUSTOMER_ID",customer_id$)

    data!.setFieldValue("TOTAL_SALES",str(irec.total_sales))
    data!.setFieldValue("CUST_NAME",irec.customer_name$)
    data!.setFieldValue("CONTACT_NAME",irec.contact_name$)
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


