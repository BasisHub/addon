rem ----------------------------------------------------------------------------
rem Program: INVOICE_HEADER.prc
rem Description: Stored Procedure to get the header and footer informations to print on the invoices
rem
rem Author(s): S. Birster
rem Revised: 02.23.2011
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

rem Get the IN parameters used by the procedure
firm_id$ = sp!.getParameter("FIRM_ID")
customer_id$ = sp!.getParameter("CUSTOMER_ID")
invoice_no$ = sp!.getParameter("INVOICE_NO")
store_master_id$ = sp!.getParameter("STORE_MASTER_ID")
html_path$ = sp!.getParameter("HTML_PATH")

rem Create a memory record set to hold results.
rem Columns for the record set are defined using a string template
rs! = BBjAPI().createMemoryRecordSet("LOGO:C(128), COMP_LINE_01:C(30), COMP_LINE_02:C(30), COMP_LINE_03:C(30), COMP_LINE_04:C(30), COMP_LINE_05:C(30),
:                                     COMP_LINE_06:C(30), COMP_LINE_07:C(30), COMP_LINE_08:C(30), COMP_LINE_09:C(30), COMP_LINE_10:C(30),
:                                     BILL_ADDR_LINE_1:C(30), BILL_ADDR_LINE_2:C(30), BILL_ADDR_LINE_3:C(30), BILL_ADDR_LINE_4:C(30), BILL_ADDR_LINE_5:C(30),
:                                     SHIP_ADDR_LINE_1:C(30), SHIP_ADDR_LINE_2:C(30), SHIP_ADDR_LINE_3:C(30), SHIP_ADDR_LINE_4:C(30), SHIP_ADDR_LINE_5:C(30),
:                                     INVOICE_NO:C(7), INVOICE_DATE:C(10), ORDER_NO:C(7), SUB_TOTAL:N(7), FREIGHT_TYPE:C(39), FREIGHT_AMT:N(7), PAYM_FEE:N(7),
:                                     TOTAL:N(7), SUB_TOTAL2:N(7), MESSAGE:C(40*), SHOW_VAT_TABLE:N(1)")


dbserver$=stbl("+DBSERVER",err=*next)
dbsqlport$=":"+stbl("+DBSQLPORT",err=*next)
dbssl=num(stbl("+DBSSL",err=*next))
dbtimeout$="&socket_timeout="+stbl("+DBTIMEOUT",err=*next)

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
    url_storeadmin$ = "storeadmin"
else
	if pos("jdbc:"=cvs(dbname$,8))=1 then			
		url$ = dbname$+url_user$
        url_storeadmin$ = "storeadmin"+url_user$
	else
		url$ = "jdbc:basis:"+dbserver$+dbsqlport$+"?database="+dbname_api$+url_user$+dbssl$+dbtimeout$
        url_storeadmin$ = "jdbc:basis:"+dbserver$+dbsqlport$+"?database=storeadmin"+url_user$+dbssl$+dbtimeout$
	endif
endif
mode$="mode=PROCEDURE"



data! = rs!.getEmptyRecordData()
data!.setFieldValue("LOGO",html_path$ + "own/gfx/header.png")
data!.setFieldValue("INVOICE_NO", invoice_no$)
data!.setFieldValue("SHOW_VAT_TABLE","0")


rem ### Calculate total sum's ###
sub_total=0
sum_net=0
sum_vat=0

sql$ = "SELECT ROUND(SUM(OOD.UNIT_PRICE*SOD.QTY_CHARGED),2) AS SUM_NET, ROUND(SUM(ROUND((OOD.UNIT_PRICE+SOD.VAT_AMOUNT)*SOD.QTY_CHARGED,2)),2) AS SUM_BRUT, ROUND(SOD.VAT_PERCENT,2) AS VAT_PERCENT, ROUND(SUM(ROUND(SOD.VAT_AMOUNT*SOD.QTY_CHARGED,2)),2) AS SUM_VAT FROM OPT_INVDET OOD INNER JOIN STO_INVDET SOD ON OOD.FIRM_ID = SOD.FIRM_ID AND OOD.ORDDET_SEQ_REF = SOD.LINE_NO AND OOD.AR_INV_NO = SOD.AR_INV_NO WHERE OOD.FIRM_ID='"+firm_id$+"' AND OOD.AR_INV_NO='"+invoice_no$+"' GROUP BY SOD.VAT_PERCENT"
sqlRs! = BBjAPI().createSQLRecordSet(url$,mode$,sql$)

rem if no positions, then nothing to print
if sqlRs!.isEmpty() then
    goto sp_end
endif

i=0
while 1
    i=i+1
    sqlRd! = sqlRs!.getCurrentRecordData()
    sub_total=sub_total+ROUND(num(sqlRd!.getFieldValue("SUM_BRUT")),2)
    sum_vat=sum_vat+num(sqlRd!.getFieldValue("SUM_VAT"))
    sqlRs!.next(err=*break)
wend

if i > 1 then
    data!.setFieldValue("SHOW_VAT_TABLE","1")
endif

data!.setFieldValue("SUB_TOTAL",str(sub_total))


paym_fee=0
sql$ = "SELECT OH.PAYM_TERMS_TXT, OH.PAYM_AMOUNT FROM STO_INVHDR OH WHERE OH.FIRM_ID='" + firm_id$ + "' AND OH.AR_INV_NO='" + invoice_no$ + "'"
sqlRs! = BBjAPI().createSQLRecordSet(url$,mode$,sql$)
if !sqlRs!.isEmpty() then
    sqlRd! = sqlRs!.getCurrentRecordData()
    paym_fee=num(sqlRd!.getFieldValue("PAYM_AMOUNT"))
    data!.setFieldValue("PAYM_FEE",str(paym_fee))
    data!.setFieldValue("FREIGHT_TYPE",cvs(sqlRd!.getFieldValue("PAYM_TERMS_TXT"),3))
endif

sql$="SELECT INVOICE_DATE, FREIGHT_AMT, SHIPTO_TYPE, SHIPTO_NO FROM OPT_INVHDR WHERE FIRM_ID='" + firm_id$ + "' AND AR_INV_NO='" + invoice_no$ + "'"
sqlRs! = BBjAPI().createSQLRecordSet(url$,mode$,sql$)
if !sqlRs!.isEmpty() then
    sqlRd! = sqlRs!.getCurrentRecordData()
    shipto_type$=sqlRd!.getFieldValue("SHIPTO_TYPE")
    shipto_no$=sqlRd!.getFieldValue("SHIPTO_NO")
    data!.setFieldValue("FREIGHT_AMT",sqlRd!.getFieldValue("FREIGHT_AMT"))
    data!.setFieldValue("INVOICE_DATE", date(jul(sqlRd!.getFieldValue("INVOICE_DATE"),"%Yl%Mz%Dz"):"%Dz.%Mz.%Yl"))
endif


url_storeadmin$="jdbc:basis:localhost?DATABASE=storeadmin&SSL=false&USER=admin&PASSWORD=admin123"
sql$="SELECT NAME, ADDR_LINE_1, ADDR_LINE_2, ZIP_CODE, CITY, PHONE, FAX, EMAIL, WEBSITE, CNTRY_ID FROM STA_STOREMASTER WHERE MASTER_ID='"+store_master_id$+"'"
sqlRs! = BBjAPI().createSQLRecordSet(url_storeadmin$,mode$,sql$)

if !(sqlRs!.isEmpty()) then
    sqlRd! = sqlRs!.getCurrentRecordData()

    i=1
    data!.setFieldValue("COMP_LINE_"+str(i:"00"), cvs(sqlRd!.getFieldValue("NAME"),3))
    i=i+1
    if cvs(sqlRd!.getFieldValue("ADDR_LINE_1"),3)<>"" then
        data!.setFieldValue("COMP_LINE_"+str(i:"00"), cvs(sqlRd!.getFieldValue("ADDR_LINE_1"),3))
        i=i+1
    endif
    if cvs(sqlRd!.getFieldValue("ADDR_LINE_2"),3)<>"" then
        data!.setFieldValue("COMP_LINE_"+str(i:"00"), cvs(sqlRd!.getFieldValue("ADDR_LINE_2"),3))
        i=i+1
    endif
    data!.setFieldValue("COMP_LINE_"+str(i:"00"), cvs(sqlRd!.getFieldValue("ZIP_CODE"),3)+" "+cvs(sqlRd!.getFieldValue("CITY"),3))
    i=i+2

    if cvs(sqlRd!.getFieldValue("PHONE"),3)<>"" then
        data!.setFieldValue("COMP_LINE_"+str(i:"00"), "Tel.: "+cvs(sqlRd!.getFieldValue("PHONE"),3))
        i=i+1
    endif
    if cvs(sqlRd!.getFieldValue("FAX"),3)<>"" then
        data!.setFieldValue("COMP_LINE_"+str(i:"00"), "Fax: "+cvs(sqlRd!.getFieldValue("FAX"),3))
        i=i+1
    endif
    if cvs(sqlRd!.getFieldValue("WEBSITE"),3)<>"" then
        data!.setFieldValue("COMP_LINE_"+str(i:"00"), "http://"+cvs(sqlRd!.getFieldValue("WEBSITE"),3))
        i=i+1
    endif
    if cvs(sqlRd!.getFieldValue("EMAIL"),3)<>"" then
        data!.setFieldValue("COMP_LINE_"+str(i:"00"), "email: "+cvs(sqlRd!.getFieldValue("EMAIL"),3))
        i=i+1
    endif
    storeCountryId$=cvs(sqlRd!.getFieldValue("CNTRY_ID"),3)
endif

sql$="SELECT CUSTOMER_ID, CUSTOMER_NAME, ADDR_LINE_1, ADDR_LINE_2, ADDR_LINE_3, ADDR_LINE_4, CITY, ZIP_CODE, COUNTRY FROM ARM_CUSTMAST WHERE FIRM_ID='" + firm_id$ + "' AND CUSTOMER_ID='" + customer_id$ + "'"
sqlRs! = BBjAPI().createSQLRecordSet(url$,mode$,sql$)
sqlRd! = sqlRs!.getCurrentRecordData()

salutation$ = cvs(sqlRd!.getFieldValue("ADDR_LINE_4"),3)
addr_line1$ = cvs(sqlRd!.getFieldValue("CUSTOMER_NAME"),3)
if salutation$ = "HERR" OR salutation$ = "FRAU" then
    addr_line1$ = addr_line1$ + " " + cvs(sqlRd!.getFieldValue("ADDR_LINE_1"),3)
else
    addr_line2$ = cvs(sqlRd!.getFieldValue("ADDR_LINE_1"),3)
endif
addr_line3$ = cvs(sqlRd!.getFieldValue("ADDR_LINE_2"),3)
addr_line4$ = cvs(sqlRd!.getFieldValue("ADDR_LINE_3"),3)
addr_line5$ = cvs(sqlRd!.getFieldValue("ZIP_CODE"),3)+" "+cvs(sqlRd!.getFieldValue("CITY"),3)

i=1
if addr_line1$ > "" then
    data!.setFieldValue("BILL_ADDR_LINE_"+str(i), addr_line1$)
    i=i+1
endif
if addr_line2$ > "" then
    data!.setFieldValue("BILL_ADDR_LINE_"+str(i), addr_line2$)
    i=i+1
endif
if addr_line3$ > "" then
    data!.setFieldValue("BILL_ADDR_LINE_"+str(i), addr_line3$)
    i=i+1
endif
if addr_line4$ > "" then
    data!.setFieldValue("BILL_ADDR_LINE_"+str(i), addr_line4$)
    i=i+1
endif
data!.setFieldValue("BILL_ADDR_LINE_"+str(i), addr_line5$)

i=1
if addr_line1$ > "" then
    data!.setFieldValue("SHIP_ADDR_LINE_"+str(i), addr_line1$)
    i=i+1
endif
if addr_line2$ > "" then
    data!.setFieldValue("SHIP_ADDR_LINE_"+str(i), addr_line2$)
    i=i+1
endif
if addr_line3$ > "" then
    data!.setFieldValue("SHIP_ADDR_LINE_"+str(i), addr_line3$)
    i=i+1
endif
if addr_line4$ > "" then
    data!.setFieldValue("SHIP_ADDR_LINE_"+str(i), addr_line4$)
    i=i+1
endif
data!.setFieldValue("SHIP_ADDR_LINE_"+str(i), addr_line5$)

countryId$ = cvs(sqlRd!.getFieldValue("COUNTRY"),3)

rem Get Ship To address from Manual Ship To table
if shipto_type$="M" then
rem     if bill_exists then
        sql$="SELECT CUSTOMER_ID, NAME AS CUSTOMER_NAME, ADDR_LINE_1, ADDR_LINE_2, ADDR_LINE_3, ADDR_LINE_4, CITY, ZIP_CODE --, CNTRY_ID FROM OPT_INVSHIP WHERE FIRM_ID='" + firm_id$ + "' AND AR_INV_NO='"+ invoice_no$ +"'"
rem     else
rem         sql$="SELECT CUSTOMER_ID, NAME AS CUSTOMER_NAME, ADDR_LINE_1, ADDR_LINE_2, ADDR_LINE_3, ADDR_LINE_4, CITY, ZIP_CODE, CNTRY_ID FROM OPE_ORDSHIP WHERE FIRM_ID='" + firm_id$ + "' AND CUSTOMER_ID='" + customer_id$ + "' AND ORDER_NO='"+ order_no$ +"'"
rem     endif
    sqlRs! = BBjAPI().createSQLRecordSet(url$,mode$,sql$)
    sqlRd! = sqlRs!.getCurrentRecordData()

    salutation$ = cvs(sqlRd!.getFieldValue("ADDR_LINE_4"),3)
    addr_line1$ = cvs(sqlRd!.getFieldValue("CUSTOMER_NAME"),3)
    if salutation$ = "HERR" OR salutation$ = "FRAU" then
        addr_line1$ = addr_line1$ + " " + cvs(sqlRd!.getFieldValue("ADDR_LINE_1"),3)
    else
        addr_line2$ = cvs(sqlRd!.getFieldValue("ADDR_LINE_1"),3)
    endif
    addr_line3$ = cvs(sqlRd!.getFieldValue("ADDR_LINE_2"),3)
    addr_line4$ = cvs(sqlRd!.getFieldValue("ADDR_LINE_3"),3)
    addr_line5$ = cvs(sqlRd!.getFieldValue("ZIP_CODE"),3)+" "+cvs(sqlRd!.getFieldValue("CITY"),3)

    i=1
    if addr_line1$ > "" then
        data!.setFieldValue("SHIP_ADDR_LINE_"+str(i), addr_line1$)
        i=i+1
    endif
    if addr_line2$ > "" then
        data!.setFieldValue("SHIP_ADDR_LINE_"+str(i), addr_line2$)
        i=i+1
    endif
    if addr_line3$ > "" then
        data!.setFieldValue("SHIP_ADDR_LINE_"+str(i), addr_line3$)
        i=i+1
    endif
    if addr_line4$ > "" then
        data!.setFieldValue("SHIP_ADDR_LINE_"+str(i), addr_line4$)
        i=i+1
    endif
    data!.setFieldValue("SHIP_ADDR_LINE_"+str(i), addr_line5$)

    countryId$ = cvs(sqlRd!.getFieldValue("CNTRY_ID"),3)
endif

rem Get Ship To address from Customer Ship To table
if shipto_type$="S" then
    sql$="SELECT CUSTOMER_ID, NAME AS CUSTOMER_NAME, ADDR_LINE_1, ADDR_LINE_2, ADDR_LINE_3, ADDR_LINE_4, CITY, STATE_CODE, ZIP_CODE, CNTRY_ID FROM ARM_CUSTSHIP WHERE FIRM_ID='" + firm_id$ + "' AND CUSTOMER_ID='" + customer_id$ + "' AND SHIPTO_NO='"+ shipto_no$ +"'"
    sqlRs! = BBjAPI().createSQLRecordSet(url$,mode$,sql$)
    sqlRd! = sqlRs!.getCurrentRecordData()

    salutation$ = cvs(sqlRd!.getFieldValue("ADDR_LINE_4"),3)
    addr_line1$ = cvs(sqlRd!.getFieldValue("CUSTOMER_NAME"),3)
    if salutation$ = "HERR" OR salutation$ = "FRAU" then
        addr_line1$ = addr_line1$ + " " + cvs(sqlRd!.getFieldValue("ADDR_LINE_1"),3)
    else
        addr_line2$ = cvs(sqlRd!.getFieldValue("ADDR_LINE_1"),3)
    endif
    addr_line3$ = cvs(sqlRd!.getFieldValue("ADDR_LINE_2"),3)
    addr_line4$ = cvs(sqlRd!.getFieldValue("ADDR_LINE_3"),3)
    addr_line5$ = cvs(sqlRd!.getFieldValue("ZIP_CODE"),3)+" "+cvs(sqlRd!.getFieldValue("CITY"),3)

    i=1
    if addr_line1$ > "" then
        data!.setFieldValue("SHIP_ADDR_LINE_"+str(i), addr_line1$)
        i=i+1
    endif
    if addr_line2$ > "" then
        data!.setFieldValue("SHIP_ADDR_LINE_"+str(i), addr_line2$)
        i=i+1
    endif
    if addr_line3$ > "" then
        data!.setFieldValue("SHIP_ADDR_LINE_"+str(i), addr_line3$)
        i=i+1
    endif
    if addr_line4$ > "" then
        data!.setFieldValue("SHIP_ADDR_LINE_"+str(i), addr_line4$)
        i=i+1
    endif
    data!.setFieldValue("SHIP_ADDR_LINE_"+str(i), addr_line5$)

    countryId$ = cvs(sqlRd!.getFieldValue("CNTRY_ID"),3)
endif



rem Calculates Total Due
total = sub_total + num(data!.getFieldValue("FREIGHT_AMT")) + paym_fee

data!.setFieldValue("TOTAL", str(total))


rs!.insert(data!)


sp_end:
rem Tell the stored procedure to return the result set.
sp!.setRecordSet(rs!)
