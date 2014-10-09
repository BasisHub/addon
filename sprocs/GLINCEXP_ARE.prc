rem ----------------------------------------------------------------------------
rem Program: GLINCEXP_ARE.prc
rem Description: Stored Procedure to build a resultset that aon_dashboard.bbj
rem              can use to populate the given dashboard widget
rem 
rem              Data returned is period totals for one year of GL Income and 
rem              Expense accounts for the "Compare Income to Expense" Area Chart widget
rem
rem Author(s): C. Hawkins, C. Johnson
rem Revised: 04.03.2014
rem
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

GOTO SKIP_DEBUG
Debug$= "C:\Dev_aon\aon\_SPROC-Debug\GLIncExp_Are_DebugPRC.txt"	
string Debug$
debugchan=unt
open(debugchan)Debug$	
write(debugchan)"Top of GLINCEXP_ARE "
SKIP_DEBUG:

seterr sproc_error

rem --- Set of utility methods

	use ::ado_func.src::func

rem --- Declare some variables ahead of time

	declare BBjStoredProcedureData sp!

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get the IN parameters used by the procedure

	include_type$ = sp!.getParameter("INCLUDE_TYPE"); rem As listed below; used to access requested GL Record ID(s)
													  rem A = Current Actual)
													  rem B = Next (Actual)
													  rem C = Prior (Actual)

  if pos(include_type$="ABC")=0
		include_type$="A"; rem default to Current year
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
	
rem --- create the in memory recordset for return

	dataTemplate$ = "ACCTTYPE:C(4*),PERIOD:C(3*),TOTAL:C(7*)"

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

    rem --- Prior Year (Actual)
    if pos(include_type$="C")
        gl_record_id$="2"
        year$=str(num(gls01a.current_year$)-1)
    endif   

    rem --- Current Year (Actual)
    if pos(include_type$="A")
        gl_record_id$="0"
        year$=gls01a.current_year$
    endif

    rem --- Next Year (Actual)
    if pos(include_type$="B")
        gl_record_id$="4"
        year$=str(num(gls01a.current_year$)+1)
        endif
    endif   

    rem --- Get accounts
    eAcctsVec! = BBjAPI().makeVector()
    iAcctsVec! = BBjAPI().makeVector()
    read (glm01a_dev,key=firm_id$,dom=*next)
    while 1
        readrecord(glm01a_dev,end=*break)glm01a$
        if glm01a.firm_id$<>firm_id$ then break
        if glm01a.gl_acct_type$="E" then eAcctsVec!.addItem(glm01a.gl_account$)
        if glm01a.gl_acct_type$="I" then iAcctsVec!.addItem(glm01a.gl_account$)
    wend
    
    rem --- Add up period tatals for Expenses and Income
    for i=1 to 2
        rem --- Do Income first (since usually greater than Expenses) so Expense overlay on top of Income, re opacity issue.
        if i=1 then
            acctsVec!=iAcctsVec!
        else
            acctsVec!=eAcctsVec!
        endif
        if acctsVec!.size()>0 then
            dim totals[1+num(gls01a.total_pers$)]
            for j=0 to acctsVec!.size()-1
                dim glm02a$:fattr(glm02a$)
                readrecord(glm02a_dev,key=firm_id$+acctsVec!.getItem(j)+gl_record_id$,dom=*next)glm02a$
                    for per=1 to num(gls01a.total_pers$)
                        per_num$=str(per:"00")
                        totals[per]=totals[per]+nfield(glm02a$,"PERIOD_AMT_"+per_num$)
                    next per
            next j
            for per=1 to num(gls01a.total_pers$)
                per_num$=str(per:"00")
                data! = rs!.getEmptyRecordData()
                if i=1 then         
                    data!.setFieldValue("ACCTTYPE","Income")
                else
                    data!.setFieldValue("ACCTTYPE","Expense")
                endif
                data!.setFieldValue("PERIOD",per_num$+"-"+field(gls01a$,"ABBR_NAME_"+per_num$))
                data!.setFieldValue("TOTAL",str(abs(round(totals[per]/1000,2))))
                rs!.insert(data!)
            next per
        endif
    next i
    
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
