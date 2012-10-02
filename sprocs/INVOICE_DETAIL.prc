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
invoice_no$ = sp!.getParameter("INVOICE_NO")

rem Create a memory record set to hold sample results.
rem Columns for the record set are defined using a string template
rs! = BBJAPI().createMemoryRecordSet("POSITION:C(7), ITEM_ID:C(40), ITEM_DESC:C(60), AMOUNT:N(7), VAT:N(7), SINGLE_PRICE:N(7), SUB_TOTAL:N(7)")

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


sql$ = "SELECT OOD.ITEM_ID, SOD.ITEM_DESC_MAN, SOD.QTY_CHARGED, OOD.LINE_CODE, OOD.UNIT_PRICE, SOD.VAT_PERCENT, ROUND(OOD.UNIT_PRICE * (1 + SOD.VAT_PERCENT/100),2) AS BRUTO_PRICE, ROUND(ROUND(OOD.UNIT_PRICE * (1 + SOD.VAT_PERCENT/100),2) * SOD.QTY_CHARGED,2) AS ROW_PRICE FROM OPT_INVDET OOD INNER JOIN STO_INVDET SOD ON OOD.FIRM_ID = SOD.FIRM_ID AND OOD.AR_INV_NO = SOD.AR_INV_NO AND OOD.ORDDET_SEQ_REF = SOD.LINE_NO WHERE OOD.FIRM_ID='"+firm_id$+"' AND OOD.AR_INV_NO='"+invoice_no$+"'"
sqlRs! = BBjAPI().createSQLRecordSet(url$,mode$,sql$)

if sqlRs!.isEmpty() then
    goto sp_end
endif

i=1
while 1
    data! = rs!.getEmptyRecordData()
    sqlRd! = sqlRs!.getCurrentRecordData()

    item_id$ = sqlRd!.getFieldValue("ITEM_ID")
    qty_charged = num(sqlRd!.getFieldValue("QTY_CHARGED"))
    vat = num(sqlRd!.getFieldValue("VAT_PERCENT"))
    line_code$ = sqlRd!.getFieldValue("LINE_CODE")
    price_net = num(sqlRd!.getFieldValue("UNIT_PRICE"))
    price_brut = num(sqlRd!.getFieldValue("BRUTO_PRICE"))
    row_price = num(sqlRd!.getFieldValue("ROW_PRICE"))

    data!.setFieldValue("POSITION",str(i:"000"))
    data!.setFieldValue("AMOUNT", str(qty_charged))
    data!.setFieldValue("ITEM_ID", sqlRd!.getFieldValue("ITEM_ID"))
    data!.setFieldValue("ITEM_DESC", sqlRd!.getFieldValue("ITEM_DESC_MAN"))
    data!.setFieldValue("SINGLE_PRICE", str(price_brut))
    data!.setFieldValue("SUB_TOTAL", str(row_price))
    data!.setFieldValue("VAT", str(vat))

    rs!.insert(data!)

    sqlRs!.next(err=*break)

    i=i+1
wend

sp_end:
rem Tell the stored procedure to return the result set.
sp!.setRecordSet(rs!)
