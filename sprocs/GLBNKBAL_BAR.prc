rem ----------------------------------------------------------------------------
rem Program: GLBNKBAL_BAR.prc     (orig: DASHBD_GLBANKBALS.prc)
rem Description: Stored Procedure to build a resultset that aon_dashboard.bbj
rem              can use to populate the given dashboard widget
rem 
rem              Data returned is for current year totals for GL accounts
rem              that are specified as Bank accounts and is used by 
rem              the "Bank Account Balances" BARCHART widget
rem
rem    ****  NOTE: Design is for only current balances, so include_type$ is 
rem    ****        always "A"/"0", and data is totaled for all periods 
rem    ****        regardless of date. No filtering is available.
rem    ****        But code is written with conditionals for possible 
rem    ****        future enhancements
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
													  rem A = Current Year Actual full totals (no period/date consideration)
	if pos(include_type$="A")=0
		include_type$="A"; rem default to Current Year Actual
	endif
	
	firm_id$ = sp!.getParameter("FIRM_ID")
	barista_wd$ = sp!.getParameter("BARISTA_WD")
    masks$ = sp!.getParameter("MASKS")
    
    rem --- Current Year Actual 
    
    if pos(include_type$="A")
        gl_record_id$="0"
    endif
    
    rem --- Prior Year Actual 
    if pos(include_type$="C")
        gl_record_id$="2"
    endif   
        
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

    gl_acct_mask$=fngetmask$("gl_acct_mask","000-000",masks$)       
    
rem --- create the in memory recordset for return

    dataTemplate$ = "Dummy:C(1),ACCOUNT:C(1*),TOTAL:C(7*)"

    rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)
    
rem --- Open/Lock files

    files=2,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="glm-05",ids$[1]="GLM_BANKMASTER"
    files$[2]="glm-02",ids$[2]="GLM_ACCTSUMMARY"
   
    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif

    glm05a_dev=channels[1]
    glm02a_dev=channels[2]
   
rem --- Dimension string templates

    dim glm05a$:templates$[1]
    dim glm02a$:templates$[2]

rem --- get data
 
   read (glm05a_dev,key=firm_id$,dom=*next)
    while 1
        readrecord(glm05a_dev,end=*break)glm05a$
        if glm05a.firm_id$<>firm_id$ then break
    
        acct_total=0
        readrecord(glm02a_dev,key=firm_id$+glm05a.gl_account$+gl_record_id$,dom=*continue)glm02a$
        acct_total=glm02a.begin_amt +glm02a.period_amt_01 +glm02a.period_amt_02 +glm02a.period_amt_03 +glm02a.period_amt_04 
:                       +glm02a.period_amt_05 +glm02a.period_amt_06+glm02a.period_amt_07 +glm02a.period_amt_08 +glm02a.period_amt_09
:                       +glm02a.period_amt_10 +glm02a.period_amt_11 +glm02a.period_amt_12 +glm02a.period_amt_13
        acct_total=round(acct_total,2)
        data! = rs!.getEmptyRecordData()
        data!.setFieldValue("DUMMY"," ")
        data!.setFieldValue("ACCOUNT",fnmask$(glm02a.gl_account$,gl_acct_mask$))
        data!.setFieldValue("TOTAL",str(acct_total))
                
        rs!.insert(data!)
        
    wend
    
rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit
	
rem --- Functions

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

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num
	
	std_exit:
	
	end
