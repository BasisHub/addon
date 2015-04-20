rem ----------------------------------------------------------------------------
rem Program: ARAGINGTOT_BAR.prc  
rem Description: Stored Procedure to build a resultset that adx_aondashboard.aon
rem              can use to populate the given dashboard widget
rem 
rem              Data returned is Company wide totals for last AR agings
rem              and is used by the "Company's Last AR Aging Totals" Bar widget
rem
rem AddonSoftware Version 15.00
rem Copyright BASIS International Ltd.  All Rights Reserved.
rem ----------------------------------------------------------------------------

GOTO SKIP_DEBUG
Debug$= "C:\Temp\ARAGINGTOT_BAR_DebugPRC.txt"	
string Debug$
DebugChan=unt
open(DebugChan)Debug$	
write(DebugChan)"Top of ARAGINGTOT_BAR_BAR "
SKIP_DEBUG:

seterr sproc_error

rem --- Set of utility methods

	use ::ado_func.src::func

rem --- Declare some variables ahead of time

	declare BBjStoredProcedureData sp!

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get the IN parameters used by the procedure

	firm_id$ =	sp!.getParameter("FIRM_ID")
    masks$ = sp!.getParameter("MASKS")
	barista_wd$ = sp!.getParameter("BARISTA_WD")

rem --- dirs	
	sv_wd$=dir("")
	chdir barista_wd$

rem --- Get Barista System Program directory
	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)
	pgmdir$=stbl("+DIR_PGM",err=*next)
	
rem --- create the in memory recordset for return

	dataTemplate$ = "Dummy:C(1),AGING_PERIOD:C(10*),TOTAL:C(7*)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)
	
rem --- Open/Lock files

    files=1,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="arm-02",ids$[1]="ARM_CUSTDET"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif

    arm02a_dev=channels[1]

rem --- Dimension string templates

    dim arm02a$:templates$[1]
    
rem --- Initialize agingPeriods! vector which will hold description for each aging period
    agingPeriods!=BBjAPI().makeVector()
    agingPeriods!.addItem("Future")
    agingPeriods!.addItem("Current")
    agingPeriods!.addItem("30 Days")
    agingPeriods!.addItem("60 Days")
    agingPeriods!.addItem("90 Days")
    agingPeriods!.addItem("120 Days")
    
rem --- Initialize totals for each aging period
    aging_future=0
    aging_cur=0
    aging_30=0
    aging_60=0
    aging_90=0
    aging_120=0

rem --- Get company wide last aging totals by aging period
    read(arm02a_dev,key=firm_id$,dom=*next)
    while 1
        readrecord(arm02a_dev,end=*break)arm02a$
        if arm02a.firm_id$<>firm_id$ then break

        aging_future=aging_future+arm02a.aging_future
        aging_cur=aging_cur+arm02a.aging_cur
        aging_30=aging_30+arm02a.aging_30
        aging_60=aging_60+arm02a.aging_60
        aging_90=aging_90+arm02a.aging_90
        aging_120=aging_120+arm02a.aging_120
    wend
    
rem --- Build agingTotals! vector with aging totals for each aging period
    agingTotals!=BBjAPI().makeVector()
    agingTotals!.addItem(aging_future); rem --- 0=Future
    agingTotals!.addItem(aging_cur); rem --- 1=Current
    agingTotals!.addItem(aging_30); rem --- 2=30 Days
    agingTotals!.addItem(aging_60); rem --- 3=60 Days
    agingTotals!.addItem(aging_90); rem --- 4=90 Days
    agingTotals!.addItem(aging_120); rem --- 5=120 Days

rem --- Build result set for the aging period
    for i=0 to agingPeriods!.size()-1
        data! = rs!.getEmptyRecordData()
        data!.setFieldValue("DUMMY"," ")
        data!.setFieldValue("AGING_PERIOD",agingPeriods!.getItem(i))
        data!.setFieldValue("TOTAL",str(agingTotals!.getItem(i)))
        rs!.insert(data!)
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
