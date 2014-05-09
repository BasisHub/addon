rem ----------------------------------------------------------------------------
rem Program: SATOPCST_BAR.prc  
rem Description: Stored Procedure to build a resultset that aon_dashboard.bbj
rem              can use to populate the given dashboard widget
rem 
rem              Data returned is current year SA totals for top 5 customers
rem              based on Sales stored in SA and is used by 
rem              the "Top 5 Customers" Bar widget
rem
rem    ****  NOTE: Initial effort restricts the year to '2014' and the
rem    ****        number of customers to 5.
rem    ****        But code is written with conditionals for possible 
rem    ****        future enhancements
rem
rem Author(s): C. Hawkins, C. Johnson
rem Revised: 04.03.2014
rem
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

GOTO SKIP_DEBUG
Debug$= "C:\Dev_aon\aon\_SPROC-Debug\SATOPCST_BAR_DebugPRC.txt"	
string Debug$
DebugChan=unt
open(DebugChan)Debug$	
write(DebugChan)"Top of SATOPCST_BAR "
SKIP_DEBUG:

seterr sproc_error

rem --- Set of utility methods

	use ::ado_func.src::func

rem --- Declare some variables ahead of time

	declare BBjStoredProcedureData sp!

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get the IN parameters used by the procedure

	max_bars=5; rem Max number of bars to show on widget
		
	year$ = sp!.getParameter("YEAR")
	num_to_list = num(sp!.getParameter("NUM_TO_LIST")); rem Number of customers to list
	if num_to_list=0 or num_to_list>max_bars
		num_to_list=max_bars; rem default to Current Year Actual
	endif
	
	firm_id$ =	sp!.getParameter("FIRM_ID")
	barista_wd$ = sp!.getParameter("BARISTA_WD")
	masks$ = sp!.getParameter("MASKS")

rem --- dirs	
	sv_wd$=dir("")
	chdir barista_wd$

rem --- Get Barista System Program directory
	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)
	pgmdir$=stbl("+DIR_PGM",err=*next)
	
rem --- masks$ will contain pairs of fields in a single string mask_name^mask|

	if len(masks$)>0
		if masks$(len(masks$),1)<>"|"
			masks$=masks$+"|"
		endif
	endif

	
rem --- Get masks

	ar_amt_mask$=fngetmask$("ar_amt_mask","$###,###,##0.00-",masks$)	
	ar_cust_mask$=fngetmask$("cust_mask","UU-UUUU",masks$)		
	
rem --- create the in memory recordset for return

	dataTemplate$ = "Dummy:C(1),CUSTOMER:C(25*),TOTAL:N(10)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)
	
rem --- Build the SELECT statement to be returned to caller

	sql_prep$ = ""
	
rem	sql_prep$ = sql_prep$+"SELECT TOP "+str(num_to_list)+" STR(cust.customer_id,'"+cust_mask$+"')+'  '+LEFT(cust.customer_name,15) AS customer"
	sql_prep$ = sql_prep$+"SELECT TOP "+str(num_to_list)+" cust.customer_id, LEFT(cust.customer_name,15) AS customer_name"
	sql_prep$ = sql_prep$+"        ,ROUND(SUM(cust.total),2) AS total "
	sql_prep$ = sql_prep$+"FROM (SELECT  "
	sql_prep$ = sql_prep$+"		 c.customer_id "
	sql_prep$ = sql_prep$+"		,m.customer_name "
	sql_prep$ = sql_prep$+"		,(c.total_sales_01 "
	sql_prep$ = sql_prep$+"		 +c.total_sales_02 "
	sql_prep$ = sql_prep$+"		 +c.total_sales_03 "
	sql_prep$ = sql_prep$+"		 +c.total_sales_04 "
	sql_prep$ = sql_prep$+"		 +c.total_sales_05 "
	sql_prep$ = sql_prep$+"		 +c.total_sales_06 "
	sql_prep$ = sql_prep$+"		 +c.total_sales_07 "
	sql_prep$ = sql_prep$+"		 +c.total_sales_08 "
	sql_prep$ = sql_prep$+"		 +c.total_sales_09 "
	sql_prep$ = sql_prep$+"		 +c.total_sales_10 "
	sql_prep$ = sql_prep$+"		 +c.total_sales_11 "
	sql_prep$ = sql_prep$+"		 +c.total_sales_12 "
	sql_prep$ = sql_prep$+"		 +c.total_sales_13 "
	sql_prep$ = sql_prep$+"		  ) AS total "
	sql_prep$ = sql_prep$+"      FROM sam_customer c "
	sql_prep$ = sql_prep$+"      LEFT JOIN arm_custmast m "
	sql_prep$ = sql_prep$+"      ON m.firm_id=c.firm_id "
	sql_prep$ = sql_prep$+"	  AND m.customer_id=c.customer_id "
	sql_prep$ = sql_prep$+"      WHERE c.firm_id='"+firm_id$+"' "
	sql_prep$ = sql_prep$+"      AND c.year='"+year$+"' "
	sql_prep$ = sql_prep$+"     ) cust	 "
	sql_prep$ = sql_prep$+"GROUP BY cust.customer_id,cust.customer_name "
	sql_prep$ = sql_prep$+"ORDER BY total DESC "
	
rem --- Execute the query

	sql_chan=sqlunt
	sqlopen(sql_chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
	sqlprep(sql_chan)sql_prep$
	dim read_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)

rem --- Assign the SELECT results to rs!

	while 1
		read_tpl$ = sqlfetch(sql_chan,end=*break)
		data! = rs!.getEmptyRecordData()
		data!.setFieldValue("DUMMY"," ")
rem		data!.setFieldValue("CUSTOMER",read_tpl.customer_id$) 
		data!.setFieldValue("CUSTOMER",read_tpl.customer_name$)
rem		str(num_to_list)+" STR(cust.customer_id,'"+cust_mask$+"')+'  '+LEFT(cust.customer_name,15) AS customer"
		data!.setFieldValue("TOTAL",str(read_tpl.total))
		rs!.insert(data!)
	
	wend		

rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit

rem --- Add SELECT to sql_prep$ based on include_type/gl_record_id

add_to_sql_prep:	
		
	sql_prep$ = sql_prep$+"SELECT '', b.gl_account as 'Account', "
	sql_prep$ = sql_prep$+"ROUND(s.begin_amt +s.period_amt_01 +s.period_amt_02 +s.period_amt_03 +s.period_amt_04 +s.period_amt_05 +s.period_amt_06 "
	sql_prep$ = sql_prep$+"+s.period_amt_07 +s.period_amt_08 +s.period_amt_09 +s.period_amt_10 +s.period_amt_11 +s.period_amt_12 +s.period_amt_13 ,2) as 'Total' "; rem  For Each Account' "
	sql_prep$ = sql_prep$+"FROM glm_bankmaster b "
	sql_prep$ = sql_prep$+"LEFT JOIN glm_acctsummary s "
	sql_prep$ = sql_prep$+"ON b.firm_id=s.firm_id AND b.gl_account=s.gl_account "
	sql_prep$ = sql_prep$+"WHERE b.firm_id='"+firm_id$+"' AND s.firm_id='"+firm_id$+"' AND s.record_id='"+gl_record_id$+"' "	
	
	return
	
rem --- Functions

    def fndate$(q$)
        q1$=""
        q1$=date(jul(num(q$(1,4)),num(q$(5,2)),num(q$(7,2)),err=*next),err=*next)
        if q1$="" q1$=q$
        return q1$
    fnend

rem --- fnmask$: Alphanumeric Masking Function (formerly fnf$)

    def fnmask$(q1$,q2$)
        if q2$="" q2$=fill(len(q1$),"0")
        return str(-num(q1$,err=*next):q2$,err=*next)
        q=1
        q0=0
        while len(q2$(q))
              if pos(q2$(q,1)="-()") q0=q0+1 else q2$(q,1)="X"
              q=q+1
        wend
        if len(q1$)>len(q2$)-q0 q1$=q1$(1,len(q2$)-q0)
        return str(q1$:q2$)
    fnend

	def fngetmask$(q1$,q2$,q3$)
		rem --- q1$=mask name, q2$=default mask if not found in mask string, q3$=mask string from parameters
		q$=q2$
		if len(q1$)=0 return q$
		if q1$(len(q1$),1)<>"^" q1$=q1$+"^"
		q=pos(q1$=q3$)
		if q=0 return q$
		q$=q3$(q)
		q=pos("^"=q$)
		q$=q$(q+1)
		q=pos("|"=q$)
		q$=q$(1,q-1)
		return q$
	fnend

rem --- fngetPattern$: Build iReports 'Pattern' from Addon Mask
	def fngetPattern$(q$)
		q1$=q$
		if len(q$)>0
			if pos("-"=q$)
				q1=pos("-"=q$)
				if q1=len(q$)
					q1$=q$(1,len(q$)-1)+";"+q$; rem Has negatives with minus at the end =>> ##0.00;##0.00-
				else
					q1$=q$(2,len(q$))+";"+q$; rem Has negatives with minus at the front =>> ##0.00;-##0.00
				endif
			endif
			if pos("CR"=q$)=len(q$)-1
				q1$=q$(1,pos("CR"=q$)-1)+";"+q$
			endif
			if q$(1,1)="(" and q$(len(q$),1)=")"
				q1$=q$(2,len(q$)-2)+";"+q$
			endif
		endif
		return q1$
	fnend	

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num
	
	std_exit:
	
	end
