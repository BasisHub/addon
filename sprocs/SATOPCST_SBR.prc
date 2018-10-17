rem ----------------------------------------------------------------------------
rem Program: SATOPCST_SBR.prc  
rem Description: Stored Procedure to build a resultset that adx_aondashboard.bbj
rem              can use to populate the given dashboard widget
rem 
rem              Data returned is multiple year SA totals for customers
rem              for TOP x customers based on Sales stored in SA and is used by 
rem              the "Top Customers Over Multiple Years" stacked bar widget
rem
rem    ****  NOTE: Initial effort restricts the number of customers to 5.
rem    ****        But code is written with conditionals for possible 
rem    ****        future enhancements
rem
rem AddonSoftware Version 15.00 - Apr2015
rem Copyright BASIS International Ltd.  All Rights Reserved.
rem ----------------------------------------------------------------------------

GOTO SKIP_DEBUG
Debug$= "C:\Temp\SATOPCST_SBR_DebugPRC.txt"	
string Debug$
debugchan=unt
open(debugchan)Debug$	
write(debugchan)"Top of SATOPCST_SBR "
SKIP_DEBUG:

seterr sproc_error

rem --- Declare some variables ahead of time

	declare BBjStoredProcedureData sp!

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get the IN parameters used by the procedure

	max_bars=5; rem Max number of bars to show on widget
		
    years_to_include=num(sp!.getParameter("INCLUDE_TYPE"))
	current_year$ = sp!.getParameter("YEAR")
	num_to_list = num(sp!.getParameter("NUM_TO_LIST")); rem Number of customers to list
	if num_to_list=0 or num_to_list>max_bars
		num_to_list=max_bars; rem default to Current Year Actual
	endif
	
	firm_id$ =	sp!.getParameter("FIRM_ID")
	barista_wd$ = sp!.getParameter("BARISTA_WD")

rem --- dirs	
	sv_wd$=dir("")
	chdir barista_wd$

rem --- Get Barista System Program directory
	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)
	pgmdir$=stbl("+DIR_PGM",err=*next)
	
rem --- create the in memory recordset for return

	dataTemplate$ = "YEAR:C(4*),CUSTOMER:C(25*),TOTAL:N(7*)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

rem --- Open/Lock files

    files=2,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="sam_customer_tot",ids$[1]="SAM_CUSTOMER_TOT"
    files$[2]="arm-01",ids$[2]="ARM_CUSTMAST"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif

    sam01tot_dev=channels[1]
    arm01a_dev=channels[2]

rem --- Dimension string templates

    dim sam01tot$:templates$[1]
    dim arm01a$:templates$[2]
    
rem --- Get sales by customer and customer + year
rem --- salesMap! key=total sales for custom, holds custMap! (in case more than one customer with same total sales)
rem --- customerMap! key=customer, holds yearMap!
rem --- yearMap! key=year, holds customer sales for year
    salesMap!=new java.util.TreeMap()
    read(arm01a_dev,key=firm_id$,dom=*next)
    while 1
        readrecord(arm01a_dev,end=*break)arm01a$
        if arm01a.firm_id$<>firm_id$ then break
        customer_id$=arm01a.customer_id$
        year$=str(num(current_year$)-years_to_include)
        this_year$=""
        gosub year_break
        trip_key$=firm_id$+year$+customer_id$
        read(sam01tot_dev,key=trip_key$,dom=*next)
        while 1
            readrecord(sam01tot_dev,end=*break)sam01tot$
            if pos(trip_key$=sam01tot.firm_id$+sam01tot.year$+sam01tot.customer_id$)<>1 then
                if year$=current_year$ then break
                rem --- Do next year now
                year$=str(num(year$)+1)
                gosub year_break
                trip_key$=firm_id$+year$+customer_id$
                read(sam01tot_dev,key=trip_key$,dom=*continue)
            endif
            if cvs(sam01tot$.product_type$,2)<>"" then continue
    
            thisSales=sam01tot.total_sales_01+sam01tot.total_sales_02+sam01tot.total_sales_03+sam01tot.total_sales_04+
:               sam01tot.total_sales_05+sam01tot.total_sales_06+sam01tot.total_sales_07+sam01tot.total_sales_08+
:               sam01tot.total_sales_09+sam01tot.total_sales_10+sam01tot.total_sales_11+sam01tot.total_sales_12+
:               sam01tot.total_sales_13
            thisSales=round(thisSales,2)
            custSales=custSales+thisSales
            yearSales=yearSales+thisSales
        
            rem --- Skip to next customer
            read(sam01tot_dev,key=firm_id$+year$+customer_id$+$FF$,dom=*next)
        wend
        gosub customer_break
    wend

rem --- Build result set for top five customers by sales
    if salesMap!.size()>0 then
        topCustomers=0
        salesDeMap!=salesMap!.descendingMap()
        salesIter!=salesDeMap!.keySet().iterator()
        while salesIter!.hasNext()
            custSales=salesIter!.next()
            customerMap!=salesDeMap!.get(custSales)
            custIter!=customerMap!.keySet().iterator()
            while custIter!.hasNext()
                customer_id$=custIter!.next()
                topCustomers=topCustomers+1
                if topCustomers>num_to_list then break
                dim arm01a$:fattr(arm01a$)
                findrecord(arm01a_dev,key=firm_id$+customer_id$,dom=*next)arm01a$
                
                yearMap!=customerMap!.get(customer_id$)
                yearIter!=yearMap!.keySet().iterator()
                while yearIter!.hasNext()
                    this_year$=yearIter!.next()
                    yearSales=yearMap!.get(this_year$)
                
                    yearSales=round(yearSales/1000,0)
                    data! = rs!.getEmptyRecordData()
                    data!.setFieldValue("YEAR",this_year$)
                    data!.setFieldValue("CUSTOMER",arm01a.customer_name$)
                    data!.setFieldValue("TOTAL",str(yearSales))
                    rs!.insert(data!)
                wend
            wend
            if topCustomers>num_to_list then break
        wend
    endif

rem --- Tell the stored procedure to return the result set.

    sp!.setRecordSet(rs!)
    goto std_exit

customer_break: rem --- Customer break
    gosub year_break
    if customer_id$<>"" then
        if salesMap!.containsKey(custSales) then
            customerMap!=salesMap!.get(custSales)
        else
            customerMap!=new java.util.HashMap()
        endif
        customerMap!.put(customer_id$,yearMap!)
        salesMap!.put(custSales,customerMap!)
    endif
    
    rem --- Initialize for next customer
    customer_id$=sam01tot.customer_id$
    custSales=0
    yearMap!=new java.util.TreeMap()
    this_year$=sam01tot.year$
    yearSales=0
    return
    
year_break: rem --- Year break
    if this_year$<>"" then
        yearMap!.put(this_year$,yearSales)
    else
        yearMap!=new java.util.TreeMap()
    endif

    rem --- Initialize first year
    this_year$=year$
    yearSales=0
    return
    
rem --- Functions

    def fndate$(q$)
        q1$=""
        q1$=date(jul(num(q$(1,4)),num(q$(5,2)),num(q$(7,2)),err=*next),err=*next)
        if q1$="" q1$=q$
        return q1$
    fnend

rem --- fnmask$: Alphanumeric Masking Function (formerly fnf$)

    def fnmask$(q1$,q2$)
        if cvs(q1$,2)="" return ""
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
					q1$=q$(2,len(q$)-1)+";"+q$; rem Has negatives with minus at the front =>> ##0.00;-##0.00
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

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num
	
	std_exit:
	
	end
