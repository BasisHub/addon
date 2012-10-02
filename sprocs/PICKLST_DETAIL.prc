rem PICKLST_DETAIL.prc
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
 
rem Create a memory record set to hold sample results.
rem Columns for the record set are defined using a string template
rs! = BBJAPI().createMemoryRecordSet("POSITION:C(7), ITEM_ID:C(40), ITEM_DESC:C(60), QTY_ORDERED:N(7), QTY_SHIPPED:C(7), UNIT_PRICE:N(7)")

dbserver$=stbl("+DBSERVER",err=*next)
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

rem url$="jdbc:basis:localhost?DATABASE=S1000&SSL=false&USER=admin&PASSWORD=admin123"

rem sql$ = "SELECT sto_orddet.item_desc_man,sto_orddet.LINE_NO,sto_orddet.ITEM_ID, ope_orddet.QTY_ORDERED, ope_orddet.LINE_CODE FROM OPE_ORDDET,STO_ORDDET WHERE FIRM_ID='" + firm_id$ + "'  AND ORDER_NO='" + order_no$ + "'"
sql$ = "SELECT SOD.ITEM_DESC_MAN, SOD.LINE_NO, SOD.ITEM_ID, OOD.QTY_ORDERED, OOD.LINE_CODE, OOD.UNIT_PRICE FROM OPE_ORDDET OOD INNER JOIN STO_ORDDET SOD ON OOD.FIRM_ID = SOD.FIRM_ID AND OOD.ORDER_NO = SOD.ORDER_NO AND OOD.LINE_NO = SOD.LINE_NO WHERE OOD.FIRM_ID='" + firm_id$ + "' AND OOD.ORDER_NO='" + order_no$ + "'"
sqlRs! = BBJAPI().createSQLRecordSet(url$,mode$,sql$)


while 1
    sqlRd! = sqlRs!.getCurrentRecordData()

    item_id$ = sqlRd!.getFieldValue("ITEM_ID")
    qty_ordered = num(sqlRd!.getFieldValue("QTY_ORDERED"))
    line_code$ = sqlRd!.getFieldValue("LINE_CODE")
    item_desc$=sqlRd!.getFieldValue("ITEM_DESC_MAN")
    line_no$=sqlRd!.getFieldValue("LINE_NO")
    unit_price=num(sqlRd!.getFieldValue("UNIT_PRICE"))

    data! = rs!.getEmptyRecordData()
    data!.setFieldValue("POSITION",line_no$)
    data!.setFieldValue("ITEM_ID",item_id$)
    data!.setFieldValue("QTY_ORDERED", str(qty_ordered))
    data!.setFieldValue("ITEM_DESC", item_desc$)
    data!.setFieldValue("UNIT_PRICE",str(unit_price))


    if line_code$="D" then
        data!.setFieldValue("QTY_SHIPPED", "Direktlieferung")
    else
        data!.setFieldValue("QTY_SHIPPED", sqlRd!.getFieldValue("QTY_ORDERED"))
    endif

    rs!.insert(data!)

    sqlRs!.next(err=*break)
wend

rem Tell the stored procedure to return the result set.
sp!.setRecordSet(rs!)