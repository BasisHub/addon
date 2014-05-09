rem ----------------------------------------------------------------------------
rem Program: SATOPREP_LIN.prc  
rem Description: Stored Procedure to build a resultset that aon_dashboard.bbj
rem              can use to populate the given dashboard widget
rem 
rem              Data returned is each period's SA totals by Salesrep for a
rem              given year for the top n salesreps. It's based on Sales 
rem              stored in SA and is used by the "Top Salesreps" line widget
rem              
rem
rem    ****  NOTE: Initial effort restricts the year to '2014' and the
rem    ****        number of reps to 5.
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
Debug$= "C:\Dev_aon\aon\_SPROC-Debug\SATOPREP_LIN_DebugPRC.txt"	
string Debug$
debugchan=unt
open(debugchan)Debug$	
write(debugchan)"Top of SATOPREP_LIN "
SKIP_DEBUG:

seterr sproc_error

rem --- Set of utility methods

	use ::ado_func.src::func

rem --- Declare some variables ahead of time

	declare BBjStoredProcedureData sp!

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get the IN parameters used by the procedure

	include_type$ = sp!.getParameter("INCLUDE_TYPE"); rem As listed below; only A is currently implemented
													  rem A = All products; summarize at rep level
													  rem B = Hooks for future product summaries
													  rem C = Hooks for future product summaries
													  rem D = Hooks for future product summaries
													  rem E = Hooks for future product summaries
													  rem F = Hooks for future product summaries
	if pos(include_type$="ABCDEF")=0
		include_type$="A"; rem Default All products; summarize at rep level
	endif

	year$ = sp!.getParameter("YEAR")

	max_bars=5; rem Max number of bars to show on widget

	num_to_list = num(sp!.getParameter("NUM_TO_LIST")); rem Number of salesreps to list
	if num_to_list=0 or num_to_list>max_bars
		num_to_list=max_bars; rem Default to MAX
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

rem --- Get number of periods used by fiscal calendar

	sql_prep$=""
	sql_prep$=sql_prep$+"SELECT total_pers FROM gls_params "
	sql_prep$=sql_prep$+"WHERE firm_id='"+firm_id$+"' AND gl='GL' AND sequence_00='00'"
	
	sql_chan=sqlunt
	sqlopen(sql_chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
	sqlprep(sql_chan)sql_prep$
	dim read_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)

	read_tpl$ = sqlfetch(sql_chan,end=*break)
	total_cal_periods=num(read_tpl.total_pers$)

	sqlclose(sql_chan)
	
rem --- create the in memory recordset for return

rem	dataTemplate$ = "PRODTYPE:C(25*),SALESREP:C(25*),TOTAL:N(10)"
	dataTemplate$ = "SALESREP:C(25*),PERIOD:C(6),TOTAL:N(10)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)
	
rem --- Build the SELECT statement to be returned to caller

	sql_prep$ = ""

	rem --- Build wrapper/outer query segements
	rem ---------------------------------------
	
	rem --- Values for the SPROC return assignments
	sql_prep$ = sql_prep$+"SELECT topReps.slspsn_code, LEFT(topReps.rep_name,15) AS rep_name "
	sql_prep$ = sql_prep$+" 	, perTots.period , perTots.total "
	sql_prep$ = sql_prep$+"FROM "

	
	rem --- Build query to determine TOP n reps for the year (based on total sales for the year)
	rem ---------------------------------------
	
	sql_prep$ = sql_prep$+"  (SELECT TOP "+str(num_to_list)+" rep.slspsn_code "
	sql_prep$ = sql_prep$+"              ,rep.rep_name "
	sql_prep$ = sql_prep$+"              ,ROUND(SUM(rep.total),2) AS total "
	sql_prep$ = sql_prep$+"   FROM "
	sql_prep$ = sql_prep$+"     (SELECT  "
	sql_prep$ = sql_prep$+"          r.slspsn_code "
	sql_prep$ = sql_prep$+"	   	    ,c.code_desc AS rep_name "
	sql_prep$ = sql_prep$+"	        ,(r.total_sales_01 "
	sql_prep$ = sql_prep$+"		     +r.total_sales_02 "
	sql_prep$ = sql_prep$+"		     +r.total_sales_03 "
	sql_prep$ = sql_prep$+"		     +r.total_sales_04 "
	sql_prep$ = sql_prep$+"		     +r.total_sales_05 "
	sql_prep$ = sql_prep$+"		     +r.total_sales_06 "
	sql_prep$ = sql_prep$+"		     +r.total_sales_07 "
	sql_prep$ = sql_prep$+"		     +r.total_sales_08 "
	sql_prep$ = sql_prep$+"		     +r.total_sales_09 "
	sql_prep$ = sql_prep$+"		     +r.total_sales_10 "
	sql_prep$ = sql_prep$+"		     +r.total_sales_11 "
	sql_prep$ = sql_prep$+"		     +r.total_sales_12 "
	sql_prep$ = sql_prep$+"		     +r.total_sales_13 "
	sql_prep$ = sql_prep$+"		      ) AS total "
	sql_prep$ = sql_prep$+"		 FROM sam_salespsn r "; rem r for rep
	sql_prep$ = sql_prep$+"      LEFT JOIN arc_salecode c "; rem c for code
	sql_prep$ = sql_prep$+"        ON c.firm_id=r.firm_id "
	sql_prep$ = sql_prep$+"       AND c.slspsn_code=r.slspsn_code "
	sql_prep$ = sql_prep$+"      WHERE r.firm_id='"+firm_id$+"' AND r.year='"+year$+"' "
	sql_prep$ = sql_prep$+"     ) AS rep	 "
	sql_prep$ = sql_prep$+"   GROUP BY rep.slspsn_code,rep.rep_name "
	sql_prep$ = sql_prep$+"   ORDER BY total DESC "
	sql_prep$ = sql_prep$+"  ) AS topReps "
	
	
	rem --- Join TopRep query with period totals query (not yet built)
	rem ---------------------------------------
	sql_prep$ = sql_prep$+"LEFT JOIN "
	sql_prep$ = sql_prep$+"  ("
		
	rem --- Build query to get Sales for each period for each sales rep
	rem ---------------------------------------	
	
	rem --- Loop through periods UNIONing queries for ea period
	for per=1 to total_cal_periods
		per_num$=str(per:"00")
		per_name_abbr$="p.abbr_name_"+per_num$
		period_amt$="r.total_sales_"+per_num$
		gosub add_to_sql_prep_byPeriod
	next per

	rem --- Strip trailing "UNION "
	if pos("UNION "=sql_prep$,-1)
		sql_prep$=sql_prep$(1,len(sql_prep$)-6)
	endif

	rem --- Add "ORDER BY and closing paren, name, and ON clause (for previous LEFT JOIN)"
rem	sql_prep$=sql_prep$+" ORDER BY period, r.slspsn_code"
	sql_prep$ = sql_prep$+"  ) AS perTots "
		
	sql_prep$ = sql_prep$+"ON topReps.slspsn_code=perTots.slspsn_code "	

	
	rem --- Add final ORDER BY for outer query
	rem ---------------------------------------		
	sql_prep$ = sql_prep$+"ORDER BY topReps.slspsn_code, perTots.period "	

	
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
		data!.setFieldValue("SALESREP",read_tpl.rep_name$)
		data!.setFieldValue("PERIOD",read_tpl.period$)
		data!.setFieldValue("TOTAL",str(read_tpl.total))
		rs!.insert(data!)

	wend		

rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit

rem --- Add SELECT to sql_prep$ based on include_type/gl_record_id (By Period)

add_to_sql_prep_byPeriod:	

	sql_prep$ = sql_prep$+"SELECT r.slspsn_code, LEFT(c.code_desc,15) AS rep_name  "
	sql_prep$ = sql_prep$+",'"+per_num$+"-'+"+per_name_abbr$+" AS period "; rem Prepended per num for sorting
	sql_prep$ = sql_prep$+",ROUND(sum("+period_amt$+"),2) AS Total "
	sql_prep$ = sql_prep$+"FROM sam_salespsn r "; rem r for rep
	sql_prep$ = sql_prep$+"LEFT JOIN arc_salecode c "; rem c for code
	sql_prep$ = sql_prep$+"  ON c.firm_id=r.firm_id "
	sql_prep$ = sql_prep$+" AND c.slspsn_code=r.slspsn_code "
	sql_prep$ = sql_prep$+"LEFT JOIN gls_params p ON r.firm_id=p.firm_id "
	sql_prep$ = sql_prep$+"WHERE r.firm_id='"+firm_id$+"' AND r.year='"+year$+"' "
	sql_prep$ = sql_prep$+"GROUP BY r.slspsn_code, rep_name, period "

	sql_prep$ = sql_prep$+"UNION "	

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
