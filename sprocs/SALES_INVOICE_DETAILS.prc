rem SALES_INVOICE_DETAIL.prc
rem 
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------
rem ' Return invoice detail by invoice number

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
inv_nbr$ = sp!.getParameter("AR_INV_NBR")
barista_wd$=sp!.getParameter("BARISTA_WD")

rem ' set up the sql query
sql$ = "SELECT SUBSTRING(t1.INTERNAL_SEQ_NO, 10, 3) as line_number, t1.line_code, t1.item_id as item_number, t1.order_memo, t1.qty_shipped, t1.unit_price, t1.ext_price "
sql$ = sql$ + "FROM OPT_INVDET t1 " 
sql$ = sql$ + "WHERE firm_id = '" + firm_id$ + "' AND ar_type = '  ' AND CUSTOMER_ID = '" + customer_nbr$ + "' AND AR_INV_NO = '" + inv_nbr$ + "' "
sql$ = sql$ + "ORDER BY t1.INTERNAL_SEQ_NO"

chan = sqlunt
sqlopen(chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
sqlprep(chan)sql$
dim irec$:sqltmpl(chan)
sqlexec(chan)

rs! = BBJAPI().createMemoryRecordSet("LINE_NUMBER:C(3),LINE_CODE:C(1),ITEM_NUMBER:C(20),ORDER_MEMO:C(40),QTY_SHIPPED:N(1*),UNIT_PRICE:N(1*),EXT_PRICE:N(1*)")

while 1
    irec$ = sqlfetch(chan,err=*break)
    data! = rs!.getEmptyRecordData()    
    data!.setFieldValue("LINE_NUMBER",irec.line_number$)
    data!.setFieldValue("LINE_CODE",irec.line_code$)
    data!.setFieldValue("ITEM_NUMBER",irec.item_number$)
    data!.setFieldValue("ORDER_MEMO",irec.order_memo$)
    data!.setFieldValue("QTY_SHIPPED",str(irec.qty_shipped))
    data!.setFieldValue("UNIT_PRICE",str(irec.unit_price))
    data!.setFieldValue("EXT_PRICE",str(irec.ext_price))
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
