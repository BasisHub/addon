rem ----------------------------------------------------------------------------
rem Program: VENDORDETAIL_HIST.prc
rem Description: Stored Procedure to get the G/L and number Masks shown correctly into iReports
rem
rem Author(s): J. Brewer
rem Revised: 08.31.2012
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

	firm_id$ = sp!.getParameter("FIRM_ID")
	vendor_id$  = sp!.getParameter("VENDOR_ID")
	barista_wd$ = sp!.getParameter("BARISTA_WD")
	masks$ = sp!.getParameter("MASKS")
	
rem --- masks$ will contain pairs of fields in a single string mask_name^mask|

	if len(masks$)>0
		if masks$(len(masks$),1)<>"|"
			masks$=masks$+"|"
		endif
	endif
	
	sv_wd$=dir("")
	chdir barista_wd$

rem --- Create a memory record set to hold results.
rem --- Columns for the record set are defined using a string template
	temp$="FIRM_ID:C(2), AP_TYPE:C(2*), AP_TYPE_DESC:C(30*), PAYMENT_GRP:C(1),PAYMENT_GRP_DESC:C(1*), AP_DIST_CODE:C(1*), "
	temp$=temp$+"AP_DIST_CODE_DESC:C(1*), AP_TERMS_CODE:C(1*), TERMS_CODE_DESC:C(1*), GL_ACCOUNT:C(1*), "
	temp$=temp$+"GL_ACCT_DESC:C(1*), OPEN_INVS:C(1*), LSTINV_DATE:C(1*), OPEN_RET:C(1*), LSTPAY_DATE:C(1*), "
	temp$=temp$+"YTD_PURCH:C(1*), YTD_DISCS:C(1*), YTD_PAYMENTS:C(1*), CUR_CAL_PMTS:C(1*), "
	temp$=temp$+"PYR_PURCH:C(1*), PRI_YR_DISCS:C(1*), PYR_PAYMENTS:C(1*), PRI_CAL_PMT:C(1*), "
	temp$=temp$+"NYR_PURCH:C(1*), NYR_DISC:C(1*), NYR_PAYMENTS:C(1*), NXT_CYR_PMTS:C(1*)"
	rs! = BBJAPI().createMemoryRecordSet(temp$)

rem --- Get Barista System Program directory
	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)
	pgmdir$=stbl("+DIR_PGM",err=*next)
	
rem --- Get masks

rem --- Make the 'Patterns' used to mask in iReports from Addon masks
rem       examples:
rem          ##0.00;##0.00-   Includes negatives with minus at the end
rem          ##0.00;-##0.00   Includes negatives with minus at the front
rem          ##0.00;##0.00-   Positives only

	ap_units_mask$=fngetmask$("ad_units_mask","#,###.00",masks$)
	ap_amt_mask$=fngetmask$("sf_amt_mask","##,##0.00-",masks$)	
	
rem --- Build SQL statement
    sql_prep$=""
	where_clause$=""
	order_clause$=""
	
	sql_prep$="select apm_vendhist.firm_id, apm_vendhist.ap_type, apm_vendhist.vendor_id, "
	sql_prep$=sql_prep$+"apm_vendhist.ap_dist_code, apm_vendhist.payment_grp, apm_vendhist.ap_terms_code, "
	sql_prep$=sql_prep$+"apm_vendhist.lstinv_date, apm_vendhist.lstpay_date, apm_vendhist.gl_account, "
	sql_prep$=sql_prep$+"apm_vendhist.open_invs, apm_vendhist.open_ret, apm_vendhist.ytd_purch, "
	sql_prep$=sql_prep$+"apm_vendhist.pyr_purch, apm_vendhist.nyr_purch, apm_vendhist.ytd_discs, "
	sql_prep$=sql_prep$+"apm_vendhist.pri_yr_discs, apm_vendhist.nyr_disc, apm_vendhist.ytd_payments, "
	sql_prep$=sql_prep$+"apm_vendhist.pyr_payments, apm_vendhist.nyr_payments, apm_vendhist.cur_cal_pmts, "
	sql_prep$=sql_prep$+"apm_vendhist.pri_cal_pmt, apm_vendhist.nxt_cyr_pmts, "
	sql_prep$=sql_prep$+"apc_typecode.code_desc AS ap_type_desc, "
	sql_prep$=sql_prep$+"apc_distribution.code_desc AS ap_dist_code_desc, "
	sql_prep$=sql_prep$+"apc_paymentgroup.code_desc AS payment_grp_desc, "
	sql_prep$=sql_prep$+"apc_termscode.code_desc AS terms_code_desc, "
	sql_prep$=sql_prep$+"glm_acct.gl_acct_desc FROM apm_vendhist "
	sql_prep$=sql_prep$+"left join apc_typecode on apm_vendhist.firm_id = apc_typecode.firm_id and apm_vendhist.ap_type = apc_typecode.ap_type "
	sql_prep$=sql_prep$+"left join apc_distribution on apm_vendhist.firm_id=apc_distribution.firm_id and apm_vendhist.ap_dist_code=apc_distribution.ap_dist_code "
	sql_prep$=sql_prep$+"left join apc_paymentgroup on apm_vendhist.firm_id=apc_paymentgroup.firm_id and apm_vendhist.payment_grp=apc_paymentgroup.payment_grp "
	sql_prep$=sql_prep$+"left join apc_termscode on apm_vendhist.firm_id=apc_termscode.firm_id and apm_vendhist.ap_terms_code=apc_termscode.terms_codeap "
	sql_prep$=sql_prep$+"left join glm_acct on apm_vendhist.firm_id=glm_acct.firm_id and apm_vendhist.gl_account=glm_acct.gl_account "
	sql_prep$=sql_prep$+"where apm_vendhist.firm_id='"+firm_id$+"' and apm_vendhist.vendor_id='"+vendor_id$+"' "

	sql_chan=sqlunt
	sqlopen(sql_chan,err=*next)stbl("+DBNAME")
	sqlprep(sql_chan)sql_prep$
	dim read_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)

rem --- Trip Read

	while 1
		read_tpl$ = sqlfetch(sql_chan,end=*break)

		data! = rs!.getEmptyRecordData()
		data!.setFieldValue("FIRM_ID",read_tpl.firm_id$)
		data!.setFieldValue("AP_TYPE",read_tpl.ap_type$)
		data!.setFieldValue("AP_TYPE_DESC",read_tpl.ap_type_desc$)
		data!.setFieldValue("PAYMENT_GRP",read_tpl.payment_grp$)
		data!.setFieldValue("PAYMENT_GRP_DESC",read_tpl.payment_grp_desc$)
		data!.setFieldValue("AP_DIST_CODE",read_tpl.ap_dist_code$)
		data!.setFieldValue("AP_DIST_CODE_DESC",read_tpl.ap_dist_code_desc$)
		data!.setFieldValue("AP_TERMS_CODE",read_tpl.ap_terms_code$)
		data!.setFieldValue("TERMS_CODE_DESC",read_tpl.terms_code_desc$)
		data!.setFieldValue("GL_ACCOUNT",read_tpl.gl_account$)
		data!.setFieldValue("GL_ACCT_DESC",read_tpl.gl_acct_desc$)
		data!.setFieldValue("OPEN_INVS",str(read_tpl.open_invs:ap_amt_mask$))
		data!.setFieldValue("LSTINV_DATE",fndate$(read_tpl.lstinv_date$))
		data!.setFieldValue("OPEN_RET",str(read_tpl.open_ret:ap_units_mask$))
		data!.setFieldValue("LSTPAY_DATE",fndate$(read_tpl.lstpay_date$))
		data!.setFieldValue("YTD_PURCH",str(read_tpl.ytd_purch:ap_amt_mask$))
		data!.setFieldValue("YTD_DISCS",str(read_tpl.ytd_discs:ap_amt_mask$))
		data!.setFieldValue("YTD_PAYMENTS",str(read_tpl.ytd_payments:ap_amt_mask$))
		data!.setFieldValue("CUR_CAL_PMTS",str(read_tpl.cur_cal_pmts:ap_amt_mask$))
		data!.setFieldValue("PYR_PURCH",str(read_tpl.pyr_purch:ap_amt_mask$))
		data!.setFieldValue("PRI_YR_DISCS",str(read_tpl.pri_yr_discs:ap_amt_mask$))
		data!.setFieldValue("PYR_PAYMENTS",str(read_tpl.pyr_payments:ap_amt_mask$))
		data!.setFieldValue("PRI_CAL_PMT",str(read_tpl.pri_cal_pmt:ap_amt_mask$))
		data!.setFieldValue("NYR_PURCH",str(read_tpl.nyr_purch:ap_amt_mask$))
		data!.setFieldValue("NYR_DISC",str(read_tpl.nyr_disc:ap_amt_mask$))
		data!.setFieldValue("NYR_PAYMENTS",str(read_tpl.nyr_payments:ap_amt_mask$))
		data!.setFieldValue("NXT_CYR_PMTS",str(read_tpl.nxt_cyr_pmts:ap_amt_mask$))

		rs!.insert(data!)
	wend
	
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
	
	std_exit:
	
	end
