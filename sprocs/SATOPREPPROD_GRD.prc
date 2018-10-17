rem ----------------------------------------------------------------------------
rem Program: SATOPREPPROD_GRD.prc     
rem Description: Stored Procedure to build a resultset that adx_aondashboard.bbj
rem              can use to populate the given dashboard widget
rem 
rem              Data returned is a salesperson's sales by product type and is
rem              used by a drilldown grid widget.
rem
rem AddonSoftware Version 15.00 - Apr2015
rem Copyright BASIS International Ltd.  All Rights Reserved.
rem ----------------------------------------------------------------------------

GOTO SKIP_DEBUG
Debug$= "C:\temp\SATOPREPPROD_GRD_DebugPRC.txt"	
string Debug$
debugchan=unt
open(debugchan)Debug$	
write(debugchan)"Top of SATOPREPPROD_GRD"
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
    slspsn_desc$ = sp!.getParameter("SLSPSN_DESC")
	barista_wd$ = sp!.getParameter("BARISTA_WD")
	unspecified_prod_type$ = sp!.getParameter("UNSPECIFIED_PROD_TYPE")
	masks$ = sp!.getParameter("MASKS")
	gl_amt_mask$=fngetmask$("gl_amt_mask","$###,###,##0.00-",masks$)

		
rem --- dirs	

	sv_wd$=dir("")
	chdir barista_wd$
	
rem --- Get Barista System Program directory

	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)
	pgmdir$=stbl("+DIR_PGM",err=*next)
	
rem --- create the in memory recordset for return

	dataTemplate$ = "PRODUCT_TYPE:C(26*),YTD_AMT:C(7*),PRIOR_AMT:C(7*)"
	
	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)
	
rem --- Open/Lock files

    files=3,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="sam-03",ids$[1]="SAM_SALESPSN"
    files$[2]="arc_salecode",ids$[2]="ARC_SALECODE"
    files$[3]="ivc_prodcode",ids$[3]="IVC_PRODCODE"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif

    sam03a_dev=channels[1]
    arm10f_dev=channels[2]
    ivm10a_dev=channels[3]

rem --- Dimension string templates

    dim sam03a$:templates$[1]
    dim arm10f$:templates$[2]
    dim ivm10a$:templates$[3]

rem --- Get salesperson code from salesperson's name
    slspsn_desc$=pad(slspsn_desc$,len(arm10f.code_desc$)," ")
    slspsn_code$=""
    trip_key$=firm_id$+"F"
    read(arm10f_dev,key=trip_key$,dom=*next)
    while 1
        arm10f_key$=key(arm10f_dev,end=*break)
        if pos(trip_key$=arm10f_key$)<>1 then break
        readrecord(arm10f_dev)arm10f$
        if arm10f.code_desc$=slspsn_desc$ then
            slspsn_code$=arm10f.slspsn_code$
            break
        endif
    wend
    
rem --- Get salesperson's sales by product type for this year and prior year
rem --- producTypeMap! key=product type, holds salesVec!
rem --- salesVec! (0)=prior year sales, (1)=current YTD sales

    productTypeMap!=new java.util.TreeMap()
    productType$=""
    prior_year$=str(num(year$)-1)
    trip_key$=firm_id$+prior_year$+slspsn_code$
    read(sam03a_dev,key=trip_key$,dom=*next)
    while 1
        sam03a_key$=key(sam03a_dev,end=*break)
        if pos(trip_key$=sam03a_key$)<>1 then
            if prior_year$="" then break
            rem --- Do current year now
            gosub productType_break
            prior_year$=""
            trip_key$=firm_id$+year$+slspsn_code$
            read(sam03a_dev,key=trip_key$,dom=*continue)
        endif
        readrecord(sam03a_dev)sam03a$

        if sam03a.product_type$<>productType$ then gosub productType_break

        thisSales=sam03a.total_sales_01+sam03a.total_sales_02+sam03a.total_sales_03+sam03a.total_sales_04+
:                 sam03a.total_sales_05+sam03a.total_sales_06+sam03a.total_sales_07+sam03a.total_sales_08+
:                 sam03a.total_sales_09+sam03a.total_sales_10+sam03a.total_sales_11+sam03a.total_sales_12+
:                 sam03a.total_sales_13
        thisSales=round(thisSales,2)
        productTypeSales=productTypeSales+thisSales
    wend
    gosub productType_break

rem --- Build result set for this salesperson's sales by product type

    if productTypeMap!.size()>0 then
        ytd_total=0
        prior_total=0
        productTypeIter!=productTypeMap!.keySet().iterator()
        while productTypeIter!.hasNext()
            productType$=productTypeIter!.next()
            salesVec!=productTypeMap!.get(productType$)

            rem ... Get product type description
            dim ivm10a$:fattr(ivm10a$)
            ivm10a.code_desc$=unspecified_prod_type$; rem --- Sales might be summarized by salesrep with no product type
            readrecord(ivm10a_dev,key=firm_id$+"A"+productType$,dom=*next)ivm10a$
                
            data! = rs!.getEmptyRecordData()
            data!.setFieldValue("PRODUCT_TYPE",productType$+" - "+ivm10a.code_desc$)
            data!.setFieldValue("YTD_AMT",str(salesVec!.getItem(1):gl_amt_mask$))
            data!.setFieldValue("PRIOR_AMT",str(salesVec!.getItem(0):gl_amt_mask$))
            rs!.insert(data!)
            
            ytd_total=ytd_total+salesVec!.getItem(1)
            prior_total=prior_total+salesVec!.getItem(0)
        wend
        
        rem --- Add salesperson's total sales to record set
        dashes$=fill(len(gl_amt_mask$),"=")
        data! = rs!.getEmptyRecordData()
        data!.setFieldValue("PRODUCT_TYPE","")
        data!.setFieldValue("YTD_AMT",dashes$)
        data!.setFieldValue("PRIOR_AMT",dashes$)
        rs!.insert(data!)
            
        data! = rs!.getEmptyRecordData()
        data!.setFieldValue("PRODUCT_TYPE","")
        data!.setFieldValue("YTD_AMT",str(ytd_total:gl_amt_mask$))
        data!.setFieldValue("PRIOR_AMT",str(prior_total:gl_amt_mask$))
        rs!.insert(data!)
    endif

rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)

	goto std_exit

productType_break: rem --- Product type break
    if productType$<>"" then
        if productTypeMap!.containsKey(productType$) then
            salesVec!=productTypeMap!.get(productType$)
        else
            salesVec!=BBjAPI().makeVector()
        endif
        if prior_year$<>"" then
            rem --- Prior year sales
            salesVec!.addItem(productTypeSales)
            salesVec!.addItem(0)
        else
            rem --- Current YTD sales
            if salesVec!.size()=0 then
                salesVec!.addItem(0)
                salesVec!.addItem(productTypeSales)
            else
                salesVec!.insertItem(1,productTypeSales)
            endif
        endif
        productTypeMap!.put(productType$,salesVec!)
    endif
    
    rem --- Initialize for next product type
    productType$=sam03a.product_type$
    productTypeSales=0
    return

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
