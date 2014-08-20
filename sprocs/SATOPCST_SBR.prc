rem ----------------------------------------------------------------------------
rem Program: SATOPCST_SBR.prc  
rem Description: Stored Procedure to build a resultset that aon_dashboard.bbj
rem              can use to populate the given dashboard widget
rem 
rem              Data returned is current year SA totals for top 5 customers
rem              based on Sales stored in SA and is used by 
rem              the "Top 5 Customers" Stacked Bar widget
rem
rem    ****  NOTE: Initial effort restricts the year to '2014' and the
rem    ****        number of customers to 5.
rem    ****        But code is written with conditionals for possible 
rem    ****        future enhancements
rem
rem Author(s): C. Hawkins, C. Johnson
rem Revised: 04.03.2014
rem
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

GOTO SKIP_DEBUG
Debug$= "C:\Dev_aon\aon\_SPROC-Debug\SATOPCST_SBR_DebugPRC.txt"	
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
		
	year$ = sp!.getParameter("YEAR")
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

	dataTemplate$ = "PRODTYPE:C(25*),CUSTOMER:C(25*),TOTAL:N(7*)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

rem --- Open/Lock files

    files=3,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="sam-01",ids$[1]="SAM_CUSTOMER"
    files$[2]="arm-01",ids$[2]="ARM_CUSTMAST"
    files$[3]="ivc_prodcode",ids$[3]="IVC_PRODCODE"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif

    sam01a_dev=channels[1]
    arm01a_dev=channels[2]
    ivm10a_dev=channels[3]

rem --- Dimension string templates

    dim sam01a$:templates$[1]
    dim arm01a$:templates$[2]
    dim ivm10a$:templates$[3]
    
rem --- Get sales by customer and customer + product type
rem --- salesMap! key=total sales for custom, holds custMap! (in case more than one customer with same total sales)
rem --- customerMap! key=customer, holds prodTypeMap!
rem --- prodTypeMap! key=product type, holds customer sales for product type
    salesMap!=new java.util.TreeMap()
    customer_id$=""
    product_type$=""
    read(sam01a_dev,key=firm_id$+year$,dom=*next)
    while 1
        readrecord(sam01a_dev,end=*break)sam01a$
        if sam01a.firm_id$+sam01a.year$<>firm_id$+year$ then break

        if sam01a.customer_id$<>customer_id$ then gosub customer_break
        if sam01a.product_type$<>product_type$ then gosub prodType_break

        thisSales=sam01a.total_sales_01+sam01a.total_sales_02+sam01a.total_sales_03+sam01a.total_sales_04+
:                 sam01a.total_sales_05+sam01a.total_sales_06+sam01a.total_sales_07+sam01a.total_sales_08+
:                 sam01a.total_sales_09+sam01a.total_sales_10+sam01a.total_sales_11+sam01a.total_sales_12+
:                 sam01a.total_sales_13
        thisSales=round(thisSales,2)
        custSales=custSales+thisSales
        prodTypeSales=prodTypeSales+thisSales
    wend
    gosub customer_break

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
                
                prodTypeMap!=customerMap!.get(customer_id$)
                prodIter!=prodTypeMap!.keySet().iterator()
                while prodIter!.hasNext()
                    product_type$=prodIter!.next()
                    prodTypeSales=prodTypeMap!.get(product_type$)
                    dim ivm10a$:fattr(ivm10a$)
                    if product_type$=fill(len(ivm10a.product_type$)," ") then
                        rem --- Sales might be summarized by customer with no product type
                        ivm10a.code_desc$(1)=Translate!.getTranslation("AON_ALL")+" "+Translate!.getTranslation("AON_PRODUCT_TYPE")
                    else
                        findrecord(ivm10a_dev,key=firm_id$+"A"+product_type$,dom=*next)ivm10a$
                    endif
                
                    data! = rs!.getEmptyRecordData()
                    data!.setFieldValue("CUSTOMER",arm01a.customer_name$)
                    data!.setFieldValue("PRODTYPE",ivm10a.code_desc$)
                    data!.setFieldValue("TOTAL",str(prodTypeSales))
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
    gosub prodType_break
    if customer_id$<>"" then
        if salesMap!.containsKey(custSales) then
            customerMap!=salesMap!.get(custSales)
        else
            customerMap!=new java.util.HashMap()
        endif
        customerMap!.put(customer_id$,prodTypeMap!)
        salesMap!.put(custSales,customerMap!)
    endif
    
    rem --- Initialize for next customer
    customer_id$=sam01a.customer_id$
    custSales=0
    prodTypeMap!=new java.util.TreeMap()
    product_type$=sam01a.product_type$
    prodTypeSales=0
    return
    
prodType_break: rem --- Product type break
    if product_type$<>"" then
        prodTypeMap!.put(product_type$,prodTypeSales)
    endif

    rem --- Initialize for next product type
    product_type$=sam01a.product_type$
    prodTypeSales=0
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
