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
	period$ = cvs(period$,3)
	
	account$ = sp!.getParameter("ACCOUNT_ID")
	if len(cvs(account$,3))<>10 then 
		account$ = account$ + fill(10,"0")
		account$ = account$(1,10)
	endif	
	
	barista_wd$ = sp!.getParameter("BARISTA_WD")
	masks$ = sp!.getParameter("MASKS")
	gl_acct_mask$=fngetmask$("gl_acct_mask","000-000",masks$)
	gl_amt_mask$=fngetmask$("gl_amt_mask","$###,###,##0.00-",masks$)

		
rem --- dirs	
	sv_wd$=dir("")
	chdir barista_wd$
	
rem --- Get Barista System Program directory
	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)
	pgmdir$=stbl("+DIR_PGM",err=*next)
	
rem --- create the in memory recordset for return

	rem ' dataTemplate$ = "TRANSDATE:C(10*),DESCRIPTION:C(30*),REFERENCE_01:C(10*),REFERENCE_02:C(10*),REFERENCE_03:C(10*),TRANSAMT:C(22*)"
	dataTemplate$ = "DATE:C(10*),DESCRIPTION:C(30*),REFERENCE:C(10*),AMOUNT:C(22*)"
	
	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)
	
rem --- Open/Lock files

    files=2,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="glm-01",ids$[1]="GLM_ACCT"
    files$[2]="glt-06",ids$[2]="GLT_TRANSDETAIL"
    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif

    glm01a_dev=channels[1]
    glt06a_dev=channels[2]
    
rem --- Dimension string templates

    dim glm01a$:templates$[1]
    dim glt06a$:templates$[2]
    
rem --- get data

    readrecord(glm01a_dev,key=firm_id$+account$,dom=*next)glm01a$

    read record(glt06a_dev,key=firm_id$ + account$ + year$ + period$, dom=*next)glt06a$
    more = 1
    while more
	read record(glt06a_dev, end = *break)glt06a$

	if glt06a.firm_id$ <> firm_id$ then break
	if glt06a.gl_account$ <> account$ then break
	if glt06a.posting_year$ <> year$ then break
	
	rem ' check period if doing a period return vs an annual
	if period$ <> "" then
		if glt06a.posting_per$ <> period$ then break
	endif
	
	data! = rs!.getEmptyRecordData()
	data!.setFieldValue("DATE",fndate$(glt06a.trns_date$))
	data!.setFieldValue("DESCRIPTION",glt06a.description$)
	data!.setFieldValue("REFERENCE",glt06a.reference_01$)
	data!.setFieldValue("AMOUNT",str(glt06a.trans_amt:gl_amt_mask$))
	rs!.insert(data!)

    wend

    
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
	
    def fndate$(q$)
        q1$="20141201"
        q1$=date(jul(num(q$(1,4)),num(q$(5,2)),num(q$(7,2)),err=*next),err=*next)
        if q1$="" q1$=q$
        return q1$
    fnend	

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num
	
	std_exit:
	
	end
