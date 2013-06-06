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

sv_wd$=dir("")
chdir barista_wd$

rem ' set up the sql query
sql$ = "SELECT SUBSTRING(t1.ORDDET_SEQ_REF, 10, 3) as line_number, t1.line_code, t1.item_id as item_number, t1.order_memo, t1.qty_shipped, t1.unit_price, t1.ext_price "
sql$ = sql$ + "FROM OPT_INVDET t1 " 
sql$ = sql$ + "WHERE firm_id = '" + firm_id$ + "' AND CUSTOMER_ID = '" + customer_nbr$ + "' AND AR_INV_NO = '" + inv_nbr$ + "' "
sql$ = sql$ + "ORDER BY t1.ORDDET_SEQ_REF"

rem ' build the database url
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
mode$="mode=PROCEDURE"

rs! = BBJAPI().createSQLRecordSet(url$,mode$,sql$)

sp!.setRecordSet(rs!)

end

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num
