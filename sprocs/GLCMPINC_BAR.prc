rem ----------------------------------------------------------------------------
rem Program: GLCMPINC_BAR.prc     (orig: DASHBD_GLCOMPAREINC_BAR.prc)
rem Description: Stored Procedure to build a resultset that aon_dashboard.bbj
rem              can use to populate the given dashboard widget
rem 
rem              Data returned is for GL Income accounts comparing Period or
rem              Year Totals across years for the "Income Comparison" BarChart widget
rem
rem Author(s): C. Hawkins, C. Johnson
rem Revised: 04.03.2014
rem
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

GOTO SKIP_DEBUG
Debug$= "C:\Dev_aon\aon\_SPROC-Debug\GLCMPINC_BAR_DebugPRC.txt"	
string Debug$
debugchan=unt
open(debugchan)Debug$	
write(debugchan)"Top of GLCMPINC_BAR "
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
													  rem A = Current/Prior by Period (Actual)
													  rem B = Current/Prior by Year Period (Actual)
													  rem C = Current/Next by Period (Actual)
													  rem D = Current/Next by Year (Actual)
													  rem E = Current/Prior/Next by Period (Actual)
													  rem F = Current/Prior/Next by Year (Actual)
	if pos(include_type$="ABCDEF")=0
		include_type$="A"; rem default to Current vs Prior by period
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

	dataTemplate$ = "YEAR:C(4*),PERIOD:C(3*),TOTAL:C(7*)"

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

    rem --- Prior Year (Actual)
    if pos(include_type$="ABEF")
        idsVec!.addItem("2")
        yearsVec!.addItem(str(num(gls01a.current_year$)-1))
    endif   

    rem --- Current Year (Actual)
    if pos(include_type$="ABCDEF")
        idsVec!.addItem("0")
        yearsVec!.addItem(gls01a.current_year$)
    endif

    rem --- Next Year (Actual)
    if pos(include_type$="CDEF")
        idsVec!.addItem("4")
        yearsVec!.addItem(str(num(gls01a.current_year$)+1))
        endif
    endif   

    if idsVec!.size()>0 then
        rem --- Get accounts
        acctsVec! = BBjAPI().makeVector()
        read (glm01a_dev,key=firm_id$,dom=*next)
        while 1
            readrecord(glm01a_dev,end=*break)glm01a$
            if glm01a.firm_id$<>firm_id$ then break
            if glm01a.gl_acct_type$<>acct_type$ then continue
            acctsVec!.addItem(glm01a.gl_account$)
        wend
        
        if acctsVec!.size()>0 then
            rem --- Add up tatal for each GL record ID
            for i=0 to idsVec!.size()-1
                rem --- Add up total for all GL accounts of specified account type
                dim totals[1+num(gls01a.total_pers$)]
                for j=0 to acctsVec!.size()-1
                    dim glm02a$:fattr(glm02a$)
                    readrecord(glm02a_dev,key=firm_id$+acctsVec!.getItem(j)+idsVec!.getItem(i),dom=*next)glm02a$
                    if pos(include_type$="BDF")
                        totals[0]=totals[0]+glm02a.begin_amt +glm02a.period_amt_01 +glm02a.period_amt_02 +glm02a.period_amt_03 +glm02a.period_amt_04 
:                       +glm02a.period_amt_05 +glm02a.period_amt_06+glm02a.period_amt_07 +glm02a.period_amt_08 +glm02a.period_amt_09
:                       +glm02a.period_amt_10 +glm02a.period_amt_11 +glm02a.period_amt_12 +glm02a.period_amt_13
                    else
                        for per=1 to num(gls01a.total_pers$)
                            per_num$=str(per:"00")
                            totals[per]=totals[per]+nfield(glm02a$,"PERIOD_AMT_"+per_num$)
                        next per
                    endif
                next j
                if pos(include_type$="BDF")
                    data! = rs!.getEmptyRecordData()
                    data!.setFieldValue("YEAR",yearsVec!.getItem(i))
                    data!.setFieldValue("PERIOD"," ")
                    data!.setFieldValue("TOTAL",str(abs(round(totals[0]/1000,2))))
                    rs!.insert(data!)
                else
                    for per=1 to num(gls01a.total_pers$)
                        per_num$=str(per:"00")
                        data! = rs!.getEmptyRecordData()
                        data!.setFieldValue("YEAR",yearsVec!.getItem(i))
                        data!.setFieldValue("PERIOD",per_num$+"-"+field(gls01a$,"ABBR_NAME_"+per_num$))
                        data!.setFieldValue("TOTAL",str(abs(round(totals[per]/1000,2))))
                        rs!.insert(data!)
                    next per
                endif
            next i
        endif
    endif
    
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
