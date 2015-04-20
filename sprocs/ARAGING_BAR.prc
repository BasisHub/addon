rem ----------------------------------------------------------------------------
rem Program: ARAGING_BAR.prc  
rem Description: Stored Procedure to build a resultset that adx_aondashboard.aon
rem              can use to populate the given dashboard widget
rem 
rem              Data returned is for the 5 customers with largest aging for selected aging period
rem              and is used by the "Customer's With Largest Last Aging In Period" Bar widget
rem
rem AddonSoftware Version 15.00
rem Copyright BASIS International Ltd.  All Rights Reserved.
rem ----------------------------------------------------------------------------

GOTO SKIP_DEBUG
Debug$= "C:\Temp\ARAGING_BAR_DebugPRC.txt"	
string Debug$
DebugChan=unt
open(DebugChan)Debug$	
write(DebugChan)"Top of ARAGING_BAR_BAR "
SKIP_DEBUG:

seterr sproc_error

rem --- Set of utility methods

	use ::ado_func.src::func

rem --- Declare some variables ahead of time

	declare BBjStoredProcedureData sp!

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get the IN parameters used by the procedure

    max_bars=5; rem Max number of bars to show on widget
    num_to_list = num(sp!.getParameter("NUM_TO_LIST")); rem Number of customers to list
    if num_to_list=0 or num_to_list>max_bars
        num_to_list=max_bars
    endif

	firm_id$ =	sp!.getParameter("FIRM_ID")
    aging_period$ =  cvs(sp!.getParameter("AGING_PERIOD"),2)
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

	dataTemplate$ = "AGING_PERIOD:C(10*),CUSTOMER:C(30*),TOTAL:C(7*)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)
	
rem --- Open/Lock files

    files=2,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="arm-01",ids$[1]="ARM_CUSTMAST"
    files$[2]="arm-02",ids$[2]="ARM_CUSTDET"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif

    arm01a_dev=channels[1]
    arm02a_dev=channels[2]

rem --- Dimension string templates

    dim arm01a$:templates$[1]
    dim arm02a$:templates$[2]
    
rem --- Identify aging period selected
    agingPeriods!=BBjAPI().makeVector()
    agingPeriods!.addItem("Future")
    agingPeriods!.addItem("Current")
    agingPeriods!.addItem("30 Days")
    agingPeriods!.addItem("60 Days")
    agingPeriods!.addItem("90 Days")
    agingPeriods!.addItem("120 Days")
    period=-1
    for i=0 to agingPeriods!.size()-1
        if aging_period$<>agingPeriods!.getItem(i) then continue
        period=i
        break
    next i
    if period<0 then goto done
    
rem --- Get last aging for selected period by customer
rem --- agingMap! key=period aging for customer, holds custmerMap! (in case more than one customer with same period aging)
rem --- customerMap! key=customer, holds agingVec!
rem --- agingVec! holds customer agings for each period
    agingMap!=new java.util.TreeMap()
    read(arm02a_dev,key=firm_id$,dom=*next)
    while 1
        readrecord(arm02a_dev,end=*break)arm02a$
        if arm02a.firm_id$<>firm_id$ then break
    
        agingVec!=BBjAPI().makeVector()
        agingVec!.addItem(arm02a.aging_future); rem --- 0=Future
        agingVec!.addItem(arm02a.aging_cur); rem --- 1=Current
        agingVec!.addItem(arm02a.aging_30); rem --- 2=30 Days
        agingVec!.addItem(arm02a.aging_60); rem --- 3=60 Days
        agingVec!.addItem(arm02a.aging_90); rem --- 4=90 Days
        agingVec!.addItem(arm02a.aging_120); rem --- 5=120 Days
        
        if agingMap!.containsKey(agingVec!.getItem(period)) then
            customerMap!=agingMap!.get(agingVec!.getItem(period))
        else
            customerMap!=new java.util.HashMap()
        endif
        customerMap!.put(arm02a.customer_id$,agingVec!)
        agingMap!.put(agingVec!.getItem(period),customerMap!)
    wend

rem --- Build result set for top five salespersons by sales
    if agingMap!.size()>0 then
        topCustomers=0
        agingDeMap!=agingMap!.descendingMap()
        agingIter!=agingDeMap!.keySet().iterator()
        while agingIter!.hasNext()
            customerAging=agingIter!.next()
            customerMap!=agingMap!.get(customerAging)
            customerIter!=customerMap!.keySet().iterator()
            while customerIter!.hasNext()
                customer_id$=customerIter!.next()
                topCustomers=topCustomers+1
                if topCustomers>num_to_list then break
                dim arm01a$:fattr(arm01a$)
                findrecord(arm01a_dev,key=firm_id$+customer_id$,dom=*next)arm01a$
                
                agingVec!=customerMap!.get(customer_id$)
                for i=0 to agingVec!.size()-1
                    data! = rs!.getEmptyRecordData()
                    data!.setFieldValue("AGING_PERIOD",agingPeriods!.getItem(i))
                    data!.setFieldValue("CUSTOMER",arm01a.customer_name$)
                    data!.setFieldValue("TOTAL",str(agingVec!.getItem(i)))
                    rs!.insert(data!)
                next i
            wend
            if topCustomers>num_to_list then break
        wend
    endif
    
rem --- Tell the stored procedure to return the result set.
done:
	sp!.setRecordSet(rs!)
	goto std_exit

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num
	
	std_exit:
	
	end
