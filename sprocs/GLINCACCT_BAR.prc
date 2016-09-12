rem ----------------------------------------------------------------------------
rem Program: GLINCACCT_BAR.prc     
rem Description: Stored Procedure to build a resultset that aon_dashboard.bbj
rem              can use to populate the given dashboard widget
rem 
rem              Data returned is for GL Income accounts for a given monthly period
rem              uses as a drilldown from the "Income Comparison" BarChart widget
rem
rem Author(s): C. Hawkins, C. Johnson, K. Williams
rem Revised: 12.09.2014
rem
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

GOTO SKIP_DEBUG
Debug$= "C:\temp\GLCMPINC_BAR_DebugPRC.txt"	
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

	firm_id$ = sp!.getParameter("FIRM_ID")
	year$ = sp!.getParameter("YEAR")
	period$ = sp!.getParameter("PERIOD")
	period$=cvs(period$,3)
	barista_wd$ = sp!.getParameter("BARISTA_WD")
	masks$ = sp!.getParameter("MASKS")
	gl_acct_mask$=fngetmask$("gl_acct_mask","000-000",masks$)
		
	rem ' we are working with Income accounts
	acct_type$ = "I"

rem --- dirs	
	sv_wd$=dir("")
	chdir barista_wd$
	
rem --- Get Barista System Program directory
	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)
	pgmdir$=stbl("+DIR_PGM",err=*next)
	
rem --- create the in memory recordset for return

	dataTemplate$ = "YRPERIOD:C(6*),ACCOUNT:C(10*),TOTAL:C(7*)"

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
    idsVec!.addItem("2")
    yearsVec!.addItem(str(num(gls01a.current_year$)-1))

    rem --- Current Year (Actual)
    idsVec!.addItem("0")
    yearsVec!.addItem(gls01a.current_year$)

    rem --- Next Year (Actual)
    idsVec!.addItem("4")
    yearsVec!.addItem(str(num(gls01a.current_year$)+1))

    rem --- what year are we working with
    for i = 0 to yearsVec!.size()-1
    	if yearsVec!.getItem(i) = year$ then
    		record_id$ = idsVec!.getItem(i)
    		break
    	endif
    next i

    if record_id$ <> "" then
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
	            rem --- get each accounts dollar amount
	            for j=0 to acctsVec!.size()-1
	                    dim glm02a$:fattr(glm02a$)
	                    readrecord(glm02a_dev,key=firm_id$+acctsVec!.getItem(j)+record_id$,dom=*next)glm02a$
	                    
	                    rem ' either have a full year or a period
	                    if period$ = "" then
				amount = glm02a.period_amt_01 + glm02a.period_amt_02 + glm02a.period_amt_03
				amount = amount + glm02a.period_amt_04 + glm02a.period_amt_05 + glm02a.period_amt_06
				amount = amount + glm02a.period_amt_07 + glm02a.period_amt_08 + glm02a.period_amt_09
				amount = amount + glm02a.period_amt_10 + glm02a.period_amt_11 + glm02a.period_amt_12
				amount = amount + glm02a.period_amt_13
			    else
				    switch num(period$)
					case 1; amount = glm02a.period_amt_01; break
					case 2; amount = glm02a.period_amt_02; break
					case 3; amount = glm02a.period_amt_03; break
					case 4; amount = glm02a.period_amt_04; break
					case 5; amount = glm02a.period_amt_05; break
					case 6; amount = glm02a.period_amt_06; break
					case 7; amount = glm02a.period_amt_07; break
					case 8; amount = glm02a.period_amt_08; break
					case 9; amount = glm02a.period_amt_09; break
					case 10; amount = glm02a.period_amt_10; break
					case 11; amount = glm02a.period_amt_11; break
					case 12; amount = glm02a.period_amt_12; break
					case 13; amount = glm02a.period_amt_13; break
					case default; amount = 0; break
				    swend
			    endif
			    
  			    if round((amount * -1)/1000,0) <> 0 then
				data! = rs!.getEmptyRecordData()
				if period$ = "" then 
					data!.setFieldValue("YRPERIOD",year$)
				else
					data!.setFieldValue("YRPERIOD",year$ + "-" + period$)
				endif
				data!.setFieldValue("ACCOUNT",fnmask$(acctsVec!.getItem(j),gl_acct_mask$))
				data!.setFieldValue("TOTAL",str(round((amount * -1)/1000,0)))
				rs!.insert(data!)
			    endif
 	                next j
		endif
	endif	
    
rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)

	goto std_exit

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
