rem INVOICE_DETAIL.prc
rem 
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

rem Declare some variables ahead of time

declare BBjStoredProcedureData sp!
declare BBjRecordSet rs!
declare BBjRecordData data!

rem Get the infomation object for the Stored Procedure
sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem Get the IN and IN/OUT parameters used by the procedure
firm_id$ = sp!.getParameter("FIRM_ID")
customer_id$ = sp!.getParameter("CUSTOMER_ID")
order_no$ = sp!.getParameter("ORDER_NO")
store_master_id$ = sp!.getParameter("STORE_MASTER_ID")
vat_01 = num(sp!.getParameter("VAT_01"))
vat_02 = num(sp!.getParameter("VAT_02"))

rem Create a memory record set to hold sample results.
rem Columns for the record set are defined using a string template
rs! = BBJAPI().createMemoryRecordSet("POSITION:C(7), ITEM_ID:C(40), ITEM_DESC:C(60), AMOUNT:C(7), VAT:C(7), SINGLE_PRICE:N(7), SUB_TOTAL:N(7)")

erver$=stbl("+DBSERVER",err=*next)
dbsqlport$=":"+stbl("+DBSQLPORT",err=*next)
dbssl=num(stbl("+DBSSL",err=*next))
dbtimeout$="&socket_timeout="+stbl("+DBTIMEOUT")

if dbssl
	dbssl$="&ssl=true"
else
	dbssl$="&ssl=false"
endif

url_user$="&user=guest"
if stbl("!DSUDDB",err=*endif)<>"" then
	url_user$=""
endif

dbname$ = stbl("+DBNAME",err=*next)
dbname_api$ = stbl("+DBNAME_API",err=*next)
if pos("jdbc:apache"=cvs(dbname$,8))=1 then
	url$ = dbname$
else
	if pos("jdbc:"=cvs(dbname$,8))=1 then			
		url$=dbname$+url_user$
	else
		url$ = "jdbc:basis:"+dbserver$+dbsqlport$+"?database="+dbname_api$+url_user$+dbssl$+dbtimeout$
	endif
endif
mode$="mode=PROCEDURE"

url$="jdbc:basis:localhost?DATABASE=ADDON_STORE&SSL=false&USER=admin&PASSWORD=admin123"

data! = rs!.getEmptyRecordData()

sql$ = "SELECT ITEM_ID, QTY_ORDERED, QTY_SHIPPED, QTY_BACKORD, LINE_CODE, ORDER_MEMO, INTERNAL_SEQ_NO, UNIT_PRICE, EXT_PRICE FROM OPE_ORDDET WHERE FIRM_ID='" + firm_id$ + "' AND CUSTOMER_ID='" + customer_id$ + "' AND ORDER_NO='" + order_no$ + "'"
sqlRs! = BBJAPI().createSQLRecordSet(url$,mode$,sql$)

num_item = sqlRs!.getRecordCount()

for i=1 to num_item
    sqlRd! = sqlRs!.getCurrentRecordData()

    item_id$ = sqlRd!.getFieldValue("ITEM_ID")
    qty_ordered = num(sqlRd!.getFieldValue("QTY_ORDERED"))
    qty_shipped = num(sqlRd!.getFieldValue("QTY_SHIPPED"))
    qty_backord = num(sqlRd!.getFieldValue("QTY_BACKORD"))
    line_code$ = sqlRd!.getFieldValue("LINE_CODE")
    order_memo$ = sqlRd!.getFieldValue("ORDER_MEMO")
    internal_seq_no$ = sqlRd!.getFieldValue("INTERNAL_SEQ_NO")
    unit_price = num(sqlRd!.getFieldValue("UNIT_PRICE"))
    ext_price = num(sqlRd!.getFieldValue("EXT_PRICE"))

    data!.setFieldValue("POSITION",str(i:"00"))
    data!.setFieldValue("AMOUNT", str(qty_ordered))

    sql$="SELECT LINE_TYPE FROM OPC_LINECODE WHERE FIRM_ID='" + firm_id$ + "' AND LINE_CODE='" + line_code$ + "'"
    sqlRs2! = BBJAPI().createSQLRecordSet(url$,mode$,sql$)
    sqlRd2! = sqlRs2!.getCurrentRecordData()

    if pos(sqlRd2!.getFieldValue("LINE_TYPE")=" SP") then
        sql$="SELECT item_desc FROM IVM_ITEMMAST WHERE FIRM_ID='" + firm_id$ + "' AND ITEM_ID='" + item_id$ + "'"
        sqlRs3! = BBJAPI().createSQLRecordSet(url$,mode$,sql$)
        sqlRd3! = sqlRs3!.getCurrentRecordData()
        item_desc$ = sqlRd3!.getFieldValue("ITEM_DESC")
    endif

    if pos(sqlRd2!.getFieldValue("LINE_TYPE")="MNO") then
        data!.setFieldValue("ITEM_ID", order_memo$)
    endif

    if pos(sqlRd2!.getFieldValue("LINE_TYPE")=" SRDP") then
        data!.setFieldValue("ITEM_ID", item_id$)
    endif

    if pos(sqlRd2!.getFieldValue("LINE_TYPE")="SP") then
        data!.setFieldValue("ITEM_DESC", item_desc$)
    endif

    sql$="SELECT VAT_ID FROM STO_ITEMDETAIL WHERE ITEM_ID='" + item_id$ + "' AND FIRM_ID='" + firm_id$ + "'"
    sqlRs4! = BBJAPI().createSQLRecordSet(url$,mode$,sql$)
    if !(sqlRs4!.isEmpty()) then
        sqlRd4! = sqlRs4!.getCurrentRecordData()

        vat$=sqlRd4!.getFieldValue("VAT_ID")
        if vat$="01" then
            data!.setFieldValue("VAT",str(vat_01))
        else
            data!.setFieldValue("VAT",str(vat_02))
        endif
    endif

    if pos(sqlRd2!.getFieldValue("LINE_TYPE")=" SRDNP") then
        data!.setFieldValue("SINGLE_PRICE", str(unit_price))
    endif

    data!.setFieldValue("SUB_TOTAL", str(unit_price*qty_ordered))

    if i<num_item then
        sqlRs!.next()
    endif

    rs!.insert(data!)
next i

rem Tell the stored procedure to return the result set.
sp!.setRecordSet(rs!)