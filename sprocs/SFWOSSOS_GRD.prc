rem ----------------------------------------------------------------------------
rem Program: SFWOSSOS_GRD.prc     
rem Description: Stored Procedure to build a resultset that aon_dashboard.bbj
rem              can use to populate the given dashboard widget
rem 
rem              Data returned is for non-closed WOs that have links to SOs
rem              for the "WOs linked to SOs" grid widget
rem
rem Author(s): C. Hawkins, C. Johnson
rem Revised: 04.03.2014
rem
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

rem GOTO SKIP_DEBUG
Debug$= "C:\Dev_aon\aon\_SPROC-Debug\SFWOSSOS_GRD_DebugPRC.txt"	
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

	wo_include_type$ = sp!.getParameter("WO_INCLUDE_TYPE"); rem As listed below; used to filter WOs reported
													  rem A = Open WOs only
													  rem B = Planned WOs only
													  rem C = Quoted WOs only
													  rem D = Open and Planned WOs
													  rem E = Planned and Quoted WOs
													  rem F = Open and Quoted WOs
													  rem G = All (Open/Planned/Quoted)
	so_include_type$ = sp!.getParameter("SO_INCLUDE_TYPE"); rem As listed below; used to filter SOs reported
													  rem A = Sales (Open) SOs only
													  rem B = Backorders only
													  rem C = Quoted SOs only
													  rem D = Sales and Backorders SOs
													  rem E = Backorders and Quotes SOs
													  rem F = Sales and Quotes (no B/Os)
													  rem G = All uninvoiced (sales, B/Os and quotes)
													  
	if pos(wo_include_type$="ABCDEFG")=0
		wo_include_type$="A"; rem default to Open WOs only
	endif
	
	if pos(so_include_type$="ABCDE")=0
		so_include_type$="A"; rem default to Open SOs only
	endif
	
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

	
rem --- Get masks (not used in this particular SPROC)


	
rem --- create the in memory recordset for return

rem	dataTemplate$ = "WO:C(7*),WO_ESTCOMPDT:C(8*),SO:C(7*),SO_REQSHIPDT:C(8*)"
	dataTemplate$ = "WO:C(7*),Est_Cmplt:C(8*),SO:C(7*),Est_SHIP:C(8*)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

	
rem --- Build the SELECT statement to be returned to caller

	sql_prep$ = ""
	sql_where$ = ""
	wo_where$ = ""
	so_where$ = ""
	
	sql_prep$ = sql_prep$+"SELECT w.wo_no "
	sql_prep$ = sql_prep$+"      ,w.estcmp_date "
	sql_prep$ = sql_prep$+"      ,d.order_no "
	sql_prep$ = sql_prep$+"      ,CASE WHEN d.est_shp_date<>'' THEN d.est_shp_date "
	sql_prep$ = sql_prep$+"            ELSE h.shipmnt_date "
	sql_prep$ = sql_prep$+"       END AS 'ShipDate' "
	sql_prep$ = sql_prep$+"FROM sfe_womastr w "
	sql_prep$ = sql_prep$+"LEFT JOIN ope_invdet d "
	sql_prep$ = sql_prep$+"       ON w.firm_id=d.firm_id AND w.customer_id=d.customer_id  "
	sql_prep$ = sql_prep$+"      AND w.order_no=d.order_no AND w.sls_ord_seq_ref=d.internal_seq_no "
	sql_prep$ = sql_prep$+"LEFT JOIN ope_invhdr h "
	sql_prep$ = sql_prep$+"       ON h.firm_id=d.firm_id AND h.customer_id=d.customer_id "
	sql_prep$ = sql_prep$+"      AND h.order_no=d.order_no "
	
	sql_where$ = sql_where$+"WHERE w.firm_id='"+firm_id$+"' AND "
	
	rem ===========================
	rem --- WHERE logic for WOs ---
	rem ===========================
	
	rem --- Main WO where clause: Ignore if no SO linkage
	wo_where$=wo_where$+"(w.customer_id<>'' AND w.order_no<>'' AND w.sls_ord_seq_ref<>'') AND "
	
		rem --- ANDed with a grouped set of WO status clauses which are ORed
		wo_where$=wo_where$+"("
		
		rem --- All non-closed WOs
		if pos(wo_include_type$="G")
			wo_where$=wo_where$+"w.wo_status<>'C' OR "
		endif	
		
		rem --- Open / Open and Planned / Open and Quotes
		if pos(wo_include_type$="ADF")
			wo_where$=wo_where$+"w.wo_status='O' OR "
		endif

		rem --- Planned / Open and Planned / Planned and Quotes
		if pos(wo_include_type$="BDE")
			wo_where$=wo_where$+"w.wo_status='P' OR "
		endif

		rem --- Quotes / Open and Quotes / Planned and Quotes
		if pos(wo_include_type$="CEF")
			wo_where$=wo_where$+"w.wo_status='Q' OR "
		endif
		
		rem ===========================
		rem --- Strip trailing "AND " from wo_where$
		rem --- Add closing paren to wo_where$
		rem ===========================
		if pos("AND "=wo_where$,-1)
			wo_where$=wo_where$(1,len(wo_where$)-4)
		endif
		wo_where$=wo_where$+") AND "
		
		rem --- Close WO's and prep for SO's clauses
		wo_where$=wo_where$+") AND "
	

	rem ===========================
	rem --- WHERE logic for SOs ---
	rem ===========================

	so_where$=so_where$+"(h.ordinv_flag='O' AND ( "; rem Exclude invoices

	rem --- All non-invoiced SOs is the baseline, so no logic to append

	
	rem --- Sales / Sales and Backorders / Sales and Quotes
	if pos(so_include_type$="ADF")
		so_where$=so_where$+"h.invoice_type='S' AND "
	endif

	rem --- Backorders / Sales and Backorders / Backorders and Quotes
	if pos(so_include_type$="BDE")
		so_where$=so_where$+"h.backord_flag='B' AND "
	endif

	rem --- Quotes / Sales and Quotes / Backorders and Quotes
	if pos(so_include_type$="CEF")
		so_where$=so_where$+"h.invoice_type='P' AND "
	endif

	rem ===========================
	rem --- Strip trailing "AND " from so_where$
	rem --- Add closing paren to so_where$
	rem ===========================
	if pos("AND "=so_where$,-1)
		so_where$=so_where$(1,len(so_where$)-4)+")"
	endif
	so_where$=so_where$+") "

			
	rem ===========================
	rem --- Append the where clauses
	rem ===========================
	sql_prep$ = sql_prep$+sql_where$+wo_where$+so_where$
	

rem --- Execute the query
write(debugchan)"sql_prep$="+sql_prep$

	sql_chan=sqlunt
	sqlopen(sql_chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
	sqlprep(sql_chan)sql_prep$
	dim read_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)

rem --- Assign the SELECT results to rs!
got_at_least_one=0
	while 1
		read_tpl$ = sqlfetch(sql_chan,end=*break)

		data! = rs!.getEmptyRecordData()
		data!.setFieldValue("WO",read_tpl.wo_no$)
		data!.setFieldValue("Est_Cmplt",fndate$(read_tpl.estcmp_date$))
		data!.setFieldValue("SO",read_tpl.order_no$)
		data!.setFieldValue("Est_SHIP",fndate$(read_tpl.ShipDate$))

		rs!.insert(data!)
got_at_least_one=1	
	wend		
write(debugchan)"got_at_least_one="+str(got_at_least_one)
if got_at_least_one=0
		data! = rs!.getEmptyRecordData()
		data!.setFieldValue("WO","-None-")
		data!.setFieldValue("Est_Cmplt","-None-")
		data!.setFieldValue("SO","-None-")
		data!.setFieldValue("Est_SHIP","-None-")

		rs!.insert(data!)		
endif	
	
rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit


	
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
