rem ----------------------------------------------------------------------------
rem Program: SFHARDCOPYFGLS.prc
rem Description: Stored Procedure to get the Shop Floor Hard Copy Finished Good Lot/Serial info into iReports
rem Used for Hard Copy, Traveler, Work Order Closed Detail and Work Order Detail
rem
rem Author(s): J. Brewer/ C. Johnson
rem Revised: 05.01.2012
rem
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

rem --- Set of utility methods

	use ::ado_func.src::func

rem --- Declare some variables ahead of time

	declare BBjStoredProcedureData sp!
	declare BBjRecordSet rs!
	declare BBjRecordData data!

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get the IN parameters used by the procedure

	firm_id$            = sp!.getParameter("FIRM_ID")
	wo_loc$             = sp!.getParameter("WO_LOCATION")
	wo_no$              = sp!.getParameter("WO_NO")
	barista_wd$         = sp!.getParameter("BARISTA_WD")
	masks$              = sp!.getParameter("MASKS")
	master_cls_inp_qty$ = sp!.getParameter("MAST_CLS_INP_QTY_STR")
	master_cls_inp_qty = num(master_cls_inp_qty$)

rem --- masks$ will contain pairs of fields in a single string mask_name^mask|

	if len(masks$)>0
		if masks$(len(masks$),1)<>"|"
			masks$=masks$+"|"
		endif
	endif

rem ---
	
	sv_wd$=dir("")
	chdir barista_wd$

rem --- Create a memory record set to hold results.
rem --- Columns for the record set are defined using a string template
	temp$="LOTSERIAL:C(1*), COMMENT:C(1*), CLOSED_YN:C(1*), CLOSED_DATE:C(1*), "
	temp$=temp$+"SCHED_PROD_QTY:C(1*), CLOSED_QTY:C(1*), CURR_CLSD_QTY:C(1*), UNIT_COST:C(1*) "
	
	rs! = BBJAPI().createMemoryRecordSet(temp$)

rem --- Get Barista System Program directory

	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)

rem --- Get masks

	pgmdir$=stbl("+DIR_PGM",err=*next)

	sf_cost_mask$=fngetmask$("sf_cost_mask","##,##0.0000-",masks$)
	sf_units_mask$=fngetmask$("sf_units_mask","#,###.0000-",masks$)
	sf_rate_mask$=fngetmask$("sf_rate_mask","#,##0.000-",masks$)
	sf_hours_mask$=fngetmask$("sf_hours_mask","#,##0.00",masks$)
	sf_amt_mask$=fngetmask$("sf_amt_mask","###,##0.00-",masks$)	
	vendor_mask$=fngetmask$("vendor_mask","000000",masks$)
	employee_mask$=fngetmask$("employee_mask","000000",masks$)

rem --- Build SQL statement

    sql_prep$=""
	where_clause$=""
	order_clause$=""
	
    sql_prep$=sql_prep$+"SELECT * "
    sql_prep$=sql_prep$+"FROM SFE_WOLOTSER as lots "
	
	rem Modify the query of that view per passed-in parameters	

		where_clause$="WHERE lots.firm_id+lots.wo_location = '"+firm_id$+wo_loc$+"' AND "

	rem Limit recordset to WO being reported on
		where_clause$=where_clause$+"lots.wo_no = '"+wo_no$+"' AND "
	
    rem Complete the WHERE clause
		where_clause$=cvs(where_clause$,2)
		if where_clause$(len(where_clause$)-2,3)="AND" where_clause$=where_clause$(1,len(where_clause$)-3)

	rem Complete the ORDER BY clause	
		order_clause$=order_clause$+" ORDER BY lots.sequence_no "
    
	rem Complete sql_prep$
		sql_prep$=sql_prep$+where_clause$+order_clause$	

	rem Exec the completed query
	sql_chan=sqlunt
	sqlopen(sql_chan,err=*next)stbl("+DBNAME")
	sqlprep(sql_chan)sql_prep$
	dim read_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan,err=std_exit)

rem --- Init Totals 

	sched_qty_tot=0
	closed_qty_tot=0
	curr_closed_qty_tot=0
	
rem --- Trip Read

	tot_recs=0
	while 1
		read_tpl$ = sqlfetch(sql_chan,end=*break)

		data! = rs!.getEmptyRecordData()
		
		data!.setFieldValue("LOTSERIAL",read_tpl.lotser_no$)
		data!.setFieldValue("COMMENT",read_tpl.wo_ls_cmt$) 		
		data!.setFieldValue("SCHED_PROD_QTY",str(read_tpl.sch_prod_qty:sf_units_mask$))
		data!.setFieldValue("CLOSED_YN",read_tpl.closed_flag$)		
		
		if read_tpl.closed_flag$="Y"
			data!.setFieldValue("CLOSED_DATE",fndate$(read_tpl.closed_date$))
		endif 
		
		if read_tpl.qty_cls_todt 
			data!.setFieldValue("CLOSED_QTY",str(read_tpl.qty_cls_todt:sf_units_mask$))	
			data!.setFieldValue("UNIT_COST",str(read_tpl.cls_cst_todt:sf_cost_mask$))
		endif
	
		if master_cls_inp_qty 
			data!.setFieldValue("CURR_CLSD_QTY",str(read_tpl.cls_inp_qty:sf_units_mask$))
		endif
		tot_recs=tot_recs+1
		rs!.insert(data!)
		
		rem --- Accum tots
		sched_qty_tot=sched_qty_tot + read_tpl.sch_prod_qty
		closed_qty_tot=closed_qty_tot + read_tpl.qty_cls_todt
		curr_closed_qty_tot=curr_closed_qty_tot + read_tpl.cls_inp_qty
	
	wend
	
	rem --- Print totals
	
	if tot_recs>0
		data! = rs!.getEmptyRecordData(); rem Add totals' underscores
		data!.setFieldValue("SCHED_PROD_QTY",fill(20,"_"))
		data!.setFieldValue("CLOSED_QTY",fill(20,"_"))
		data!.setFieldValue("CURR_CLSD_QTY",fill(20,"_"))
		rs!.insert(data!)
	
		data! = rs!.getEmptyRecordData()
		data!.setFieldValue("SCHED_PROD_QTY",str(sched_qty_tot:sf_units_mask$)) 		
		data!.setFieldValue("CLOSED_QTY",str(closed_qty_tot:sf_units_mask$)) 			
		data!.setFieldValue("CURR_CLSD_QTY",str(curr_closed_qty_tot:sf_units_mask$))

		rs!.insert(data!)
	endif
	
rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit

rem --- Subroutines

	
rem --- Functions

rem --- Format inventory item description

	def fnitem$(q$,q1,q2,q3)
		q$=pad(q$,q1+q2+q3)
		return cvs(q$(1,q1)+" "+q$(q1+1,q2)+" "+q$(q1+q2+1,q3),32)
	fnend

rem --- Date/time handling functions

    def fndate$(q$)
        q1$=""
        q1$=date(jul(num(q$(1,4)),num(q$(5,2)),num(q$(7,2)),err=*next),err=*next)
        if q1$="" q1$=q$
        return q1$
    fnend
    
    def fnyy$(q$)=q$(3,2)
    def fnclock$(q$)=date(0:"%hz:%mz %p")
    def fntime$(q$)=date(0:"%Hz%mz")
    def fnh$(q1$)=q1$(5,2)+"/"+q1$(1,4)

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



	std_exit:
	
	end
