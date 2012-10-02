rem SALES_CUST_TYPE.prc
rem 
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

rem ' Return sales totals by customer type for a given month period
rem ' SETERR ERROR_ROUTINE

rem ' Declare some variables ahead of time
declare BBjStoredProcedureData sp!
declare BBjRecordSet rs!
declare BBjRecordData data!

rem ' Get the infomation object for the Stored Procedure
sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem ' Get the IN and IN/OUT parameters used by the procedure
firm_id$=sp!.getParameter("FIRM_ID")
month$ = sp!.getParameter("MONTH")
year$ = sp!.getParameter("YEAR")

rem ' set up the sql query
sql$ = "SELECT SUM(t1.TOTAL_SALES) as total_sales, t2.CUSTOMER_TYPE as CUST_TYPE, t3.CODE_DESC "
sql$ = sql$ + "FROM OPT_INVHDR t1 "
sql$ = sql$ + "INNER JOIN ARM_CUSTDET t2 ON t1.firm_id = t2.firm_id AND t1.CUSTOMER_ID = t2.CUSTOMER_ID "
sql$ = sql$ + "INNER JOIN ARC_CUSTTYPE t3 ON t2.firm_id = t3.firm_id AND t2.CUSTOMER_TYPE = t3.CUSTOMER_TYPE "
sql$ = sql$ + "WHERE t1.firm_id = '" + firm_id$ + "' AND SUBSTRING(t1.INVOICE_DATE, 5, 2) = '" + month$ + "' and SUBSTRING(t1.INVOICE_DATE, 1, 4) = '" +year$ + "' "
sql$ = sql$ + "GROUP BY t2.CUSTOMER_TYPE, t3.CODE_DESC "
sql$ = sql$ + "ORDER BY total_sales DESC "

rem ' build database url and open sql channel
dbserver$="localhost"
dbsqlport$=":2001"
dbtimeout$="&socket_timeout=5000"

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

dbname$ = stbl("+DBNAME")
dbname_api$ = stbl("+DBNAME_API")
if pos("jdbc:apache"=cvs(dbname$,8))=1 then
	url$ = dbname$
else
	if pos("jdbc:"=cvs(dbname$,8))=1 then			
		url$=dbname$+url_user$
	else
		url$ = "jdbc:basis:"+dbserver$+dbsqlport$+"?database="+dbname_api$+url_user$+dbssl$+dbtimeout$
	endif
endif
chan = sqlunt
sqlopen(chan)url$
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

rem ' Error routine
ERROR_ROUTINE:
    SETERR DONE
    msg$ = "Error #" + str(err) + " occured in " + pgm(-1) + " at line " + str(tcb(5))
    if err = 77 then msg$ = msg$ + $0d0a$ + "SQL Err: " + sqlerr(chan)
    java.lang.System.out.println(msg$)
    if tcb(13) then exit else end


