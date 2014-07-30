rem ----------------------------------------------------------------------------
rem Program: GLINCTOT_GRD.prc     (orig: DASHBD_GLINC_YRTOTS.prc)
rem Description: Stored Procedure to build a resultset that aon_dashboard.bbj
rem              can use to populate the given dashboard widget
rem 
rem              Data returned is for GL Income account totals by year
rem              for the "GL Income Acct. Totals" grid widget
rem
rem Author(s): C. Hawkins, C. Johnson
rem Revised: 04.03.2014
rem
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

seterr sproc_error

rem --- Set of utility methods

	use ::ado_func.src::func

rem --- Declare some variables ahead of time

	declare BBjStoredProcedureData sp!

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get the IN parameters used by the procedure

	include_type$ = sp!.getParameter("INCLUDE_TYPE"); rem As listed below; used to access requested GL Record ID(s)
													  rem A = Current Year Actual
													  rem B = Current Year Budget
													  rem C = Prior Year Actual
													  rem D = Prior Year Budget
													  rem E = Next Year Actual
													  rem F = Next Year Budget
													  rem G = All Actual
													  rem H = All Budget
													  rem I = All 
													  rem J = Current & Prior Year Actual
													  rem K = Current & Prior Year Budget
	if pos(include_type$="ABCDEFGHIJK")=0
		include_type$="A"; rem default to Current Year Actual
	endif
	
	acct_type$  = sp!.getParameter("ACCT_TYPE"); rem A/L/C/I/E or any combo
												 rem A = Asset 
												 rem L = Liability 
												 rem C = Capital
												 rem I = Income
												 rem E = Expense
	do_coa_join$  = sp!.getParameter("DO_COA_JOIN"); rem Use a Chart of Accounts table JOIN to get Category?
													 rem Y/N  ===== > NOT IMPLEMENTED 
	
	firm_id$ = sp!.getParameter("FIRM_ID")
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

	ad_units_mask$=fngetmask$("ad_units_mask","#,###.00",masks$)
	gl_amt_mask$=fngetmask$("gl_amt_mask","$###,###,##0.00-",masks$)	
	gl_acct_mask$=fngetmask$("gl_acct_mask","000-000",masks$)		
	
rem --- create the in memory recordset for return

	dataTemplate$ = "DESCRIPTION:C(30*),YEAR:C(4*),TOTAL:C(1*)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

	
rem --- Build the SELECT statement to be returned to caller

rem sql_prep$ = "SELECT DISTINCT m.gl_acct_desc as Description, p.current_year AS Year, STR(ROUND(ABS(s.begin_amt +s.period_amt_01 +s.period_amt_02 +s.period_amt_03 +s.period_amt_04 +s.period_amt_05 +s.period_amt_06 +s.period_amt_07 +s.period_amt_08 +s.period_amt_09 +s.period_amt_10 +s.period_amt_11 +s.period_amt_12 +s.period_amt_13 ),2),'$###,###,##0.00') AS Total FROM glm_acct m LEFT JOIN glm_acctsummary s ON m.firm_id=s.firm_id AND m.gl_account=s.gl_account LEFT JOIN gls_params p ON m.firm_id=p.firm_id WHERE m.firm_id='01' AND s.firm_id='01' AND m.gl_acct_type='I' AND s.record_id='0' UNION SELECT m.gl_acct_desc as Description ,STR(NUM(p.current_year)-1) AS Year ,STR(ROUND(ABS(s.begin_amt +s.period_amt_01 +s.period_amt_02 +s.period_amt_03 +s.period_amt_04 +s.period_amt_05 +s.period_amt_06 +s.period_amt_07 +s.period_amt_08 +s.period_amt_09 +s.period_amt_10 +s.period_amt_11 +s.period_amt_12 +s.period_amt_13 ),2),'$###,###,##0.00') AS Total FROM glm_acct m LEFT JOIN glm_acctsummary s ON m.firm_id=s.firm_id AND m.gl_account=s.gl_account LEFT JOIN gls_params p ON m.firm_id=p.firm_id WHERE m.firm_id='01' AND s.firm_id='01' AND m.gl_acct_type='I' AND s.record_id='2'"	

	sql_prep$ = ""
	
	rem --- Current Year Actual / All Actual / All / Curr&Prior Actual
	if pos(include_type$="AGIJ")
		gl_record_id$="0"
		year_calc$="p.current_year"
		gosub add_to_sql_prep
	endif

	rem --- Current Year Budget / All Budget / All / Curr&Prior Budget
	if pos(include_type$="BHIK")
		gl_record_id$="1"
		year_calc$="p.current_year"
		gosub add_to_sql_prep
	endif	

	rem --- Prior Year Actual / All Actual / All / Curr&Prior Actual
	if pos(include_type$="CGIJ")
		gl_record_id$="2"
		year_calc$="STR(NUM(p.current_year)-1)"
		gosub add_to_sql_prep
	endif	

	rem --- Prior Year Budget / All Budget / All / Curr&Prior Budget
	if pos(include_type$="DHIK")
		gl_record_id$="3"
		year_calc$="STR(NUM(p.current_year)-1)"
		gosub add_to_sql_prep
	endif	
	
	rem --- Next Year Actual / All Actual / All
	if pos(include_type$="EGI")
		gl_record_id$="4"
		year_calc$="STR(NUM(p.current_year)+1)"
		gosub add_to_sql_prep
	endif

	rem --- Next Year Budget / All Budget / All
	if pos(include_type$="FHI")
		gl_record_id$="5"
		year_calc$="STR(NUM(p.current_year)+1)"
		gosub add_to_sql_prep
	endif	

	rem --- Strip trailing "UNION "
	if pos("UNION "=sql_prep$,-1)
		sql_prep$=sql_prep$(1,len(sql_prep$)-6)
	endif


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
		data!.setFieldValue("DESCRIPTION",read_tpl.Description$)
		data!.setFieldValue("YEAR",read_tpl.Year$)
		data!.setFieldValue("TOTAL",read_tpl.Total$)

		rs!.insert(data!)
	
	wend		

rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit

rem --- Add SELECT to sql_prep$ based on include_type/gl_record_id

add_to_sql_prep:	
	sql_prep$ = sql_prep$+"SELECT DISTINCT m.gl_acct_desc as Description, "
	sql_prep$ = sql_prep$+year_calc$+" AS Year, "
	sql_prep$ = sql_prep$+"STR(ROUND(ABS(s.begin_amt +s.period_amt_01 +s.period_amt_02 +s.period_amt_03 +s.period_amt_04 +s.period_amt_05 +s.period_amt_06 "
	sql_prep$ = sql_prep$+"+s.period_amt_07 +s.period_amt_08 +s.period_amt_09 +s.period_amt_10 +s.period_amt_11 +s.period_amt_12 +s.period_amt_13 ),2),'"+gl_amt_mask$+"') AS Total "
	sql_prep$ = sql_prep$+"FROM glm_acct m "
	sql_prep$ = sql_prep$+"LEFT JOIN glm_acctsummary s ON m.firm_id=s.firm_id AND m.gl_account=s.gl_account "
	sql_prep$ = sql_prep$+"LEFT JOIN gls_params p ON m.firm_id=p.firm_id "
	sql_prep$ = sql_prep$+"WHERE m.firm_id='"+firm_id$+"' AND s.firm_id='"+firm_id$+"' AND m.gl_acct_type='"+acct_type$+"' AND s.record_id='"+gl_record_id$+"' "

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