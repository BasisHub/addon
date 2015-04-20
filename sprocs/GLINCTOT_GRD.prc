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

	gl_amt_mask$=fngetmask$("gl_amt_mask","$###,###,##0.00-",masks$)	
	
rem --- create the in memory recordset for return

	dataTemplate$ = "DESCRIPTION:C(30*),YEAR:C(4*),TOTAL:C(7*)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)
    
rem --- Open/Lock files

    files=3,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="glm-01",ids$[1]="GLM_ACCT"
    files$[2]="glm-02",ids$[2]="GLM_ACCTSUMMARY"
    files$[3]="gls_params",ids$[3]="GLS_PARAMS"
   
    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif

    glm01a_dev=channels[1]
    glm02a_dev=channels[2]
    gls01a_dev=channels[3]
   
rem --- Dimension string templates

    dim glm01a$:templates$[1]
    dim glm02a$:templates$[2]
    dim gls01a$:templates$[3]

rem --- get data

    readrecord(gls01a_dev,key=firm_id$+"GL00",dom=*next)gls01a$

    idsVec! = BBjAPI().makeVector()
    yearsVec! = BBjAPI().makeVector()

    rem --- Prior Year Actual / All Actual / All / Curr&Prior Actual
    if pos(include_type$="CGIJ")
        idsVec!.addItem("2")
        yearsVec!.addItem(str(num(gls01a.current_year$)-1))
    endif   

    rem --- Prior Year Budget / All Budget / All / Curr&Prior Budget
    if pos(include_type$="DHIK")
        idsVec!.addItem("3")
        yearsVec!.addItem(str(num(gls01a.current_year$)-1))
    endif   

    rem --- Current Year Actual / All Actual / All / Curr&Prior Actual
    if pos(include_type$="AGIJ")
        idsVec!.addItem("0")
        yearsVec!.addItem(gls01a.current_year$)
    endif

    rem --- Current Year Budget / All Budget / All / Curr&Prior Budget
    if pos(include_type$="BHIK")
        idsVec!.addItem("1")
        yearsVec!.addItem(gls01a.current_year$)
    endif   
    
    rem --- Next Year Actual / All Actual / All
    if pos(include_type$="EGI")
        idsVec!.addItem("4")
        yearsVec!.addItem(str(num(gls01a.current_year$)+1))
    endif

    rem --- Next Year Budget / All Budget / All
    if pos(include_type$="FHI")
        idsVec!.addItem("5")
        yearsVec!.addItem(str(num(gls01a.current_year$)+1))
    endif   

    if idsVec!.size()>0 then
        read (glm01a_dev,key=firm_id$,dom=*next)
        while 1
            readrecord(glm01a_dev,end=*break)glm01a$
            if glm01a.firm_id$<>firm_id$ then break
            if glm01a.gl_acct_type$<>acct_type$ then continue
        
            for i=0 to idsVec!.size()-1
                acct_total=0
                dim glm02a$:fattr(glm02a$)
                readrecord(glm02a_dev,key=firm_id$+glm01a.gl_account$+idsVec!.getItem(i),dom=*next)glm02a$
                acct_total=glm02a.begin_amt +glm02a.period_amt_01 +glm02a.period_amt_02 +glm02a.period_amt_03 +glm02a.period_amt_04 
:                       +glm02a.period_amt_05 +glm02a.period_amt_06+glm02a.period_amt_07 +glm02a.period_amt_08 +glm02a.period_amt_09
:                       +glm02a.period_amt_10 +glm02a.period_amt_11 +glm02a.period_amt_12 +glm02a.period_amt_13
                acct_total=round(acct_total,2)
                data! = rs!.getEmptyRecordData()
                data!.setFieldValue("DESCRIPTION",glm01a.gl_acct_desc$)
                data!.setFieldValue("YEAR",yearsVec!.getItem(i))
                data!.setFieldValue("TOTAL",str(acct_total))
                rs!.insert(data!)
            next i
        wend
    endif
    
rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit
	
rem --- Functions

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

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num
	
	std_exit:
	
	end
