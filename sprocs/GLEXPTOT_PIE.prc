rem ----------------------------------------------------------------------------
rem Program: GLEXPTOT_PIE.prc     (orig: DASHBD_GLIEXP_YRTOTS_PIE.prc)
rem Description: Stored Procedure to build a resultset that aon_dashboard.bbj
rem              can use to populate the given dashboard widget
rem 
rem              Data returned is for GL Expense account totals by year
rem              for the "YTD Expense Breakdow" pie widget
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
	
rem --- create the in memory recordset for return

	dataTemplate$ = "CATEGORY:C(1*),TOTAL:C(7*)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)
	
rem --- Open/Lock files

    files=3,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="glm-01",ids$[1]="GLM_ACCT"
    files$[2]="glm-02",ids$[2]="GLM_ACCTSUMMARY"
    files$[3]="glm-10",ids$[3]="GLM_ACCTBREAKS"
   
    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif

    glm01a_dev=channels[1]
    glm02a_dev=channels[2]
    glm10a_dev=channels[3]
   
rem --- Dimension string templates

    dim glm01a$:templates$[1]
    dim glm02a$:templates$[2]
    dim glm10a$:templates$[3]

rem --- get data

    rem --- Current Year Actual only
    gl_record_id$="0"

    rem --- Get accounts breaks
    start_brk_no$=""
    end_brk_no$=""
    read (glm10a_dev,key=firm_id$+start_brk_no$,dom=*next)
    while 1
        dim gm10a$:fattr(glm10a$)
        readrecord(glm10a_dev,end=*next)glm10a$
        if glm10a.firm_id$<>firm_id$ then dim gm10a$:fattr(glm10a$)
        start_brk_no$=end_brk_no$
        start_brk_desc$=end_brk_desc$
        end_brk_no$=glm10a.acct_no_brk$
        end_brk_desc$=glm10a.acct_bk_desc$
        if start_brk_no$="" then continue
    
        acct_total=0
        read (glm01a_dev,key=firm_id$+start_brk_no$,dir=0,dom=*next)
        while 1
            readrecord(glm01a_dev,end=*break)glm01a$
            if glm01a.firm_id$<>firm_id$ then break
            if glm01a.gl_account$>=end_brk_no$ and cvs(end_brk_no$,2)<>"" then break
            if glm01a.gl_acct_type$<>acct_type$ then continue
        
            dim glm02a$:fattr(glm02a$)
            readrecord(glm02a_dev,key=firm_id$+glm01a.gl_account$+gl_record_id$,dom=*next)glm02a$
            acct_total=acct_total+glm02a.begin_amt +glm02a.period_amt_01 +glm02a.period_amt_02 +glm02a.period_amt_03 +glm02a.period_amt_04 
:                       +glm02a.period_amt_05 +glm02a.period_amt_06+glm02a.period_amt_07 +glm02a.period_amt_08 +glm02a.period_amt_09
:                       +glm02a.period_amt_10 +glm02a.period_amt_11 +glm02a.period_amt_12 +glm02a.period_amt_13
        wend
        data! = rs!.getEmptyRecordData()
        data!.setFieldValue("CATEGORY",start_brk_desc$)
        data!.setFieldValue("TOTAL",cvs(str(abs(acct_total):"#########.00"),3))
        rs!.insert(data!)
        if cvs(end_brk_no$,2)="" then break
    wend
    
rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num
	
	std_exit:
	
	end
