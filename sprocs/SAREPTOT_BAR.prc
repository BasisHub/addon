rem ----------------------------------------------------------------------------
rem Program: SAREPTOT_BAR.prc  
rem Description: Stored Procedure to build a resultset that adx_aondashboard.aon
rem              can use to populate the given dashboard widget
rem 
rem              Data returned is current year SA totals for salesreps
rem              based on Sales stored in SA and is used by 
rem              the "Sales by Salesrep" bar widget
rem
rem    ****  NOTE: Initial effort restricts the year to '2014' and the
rem    ****        number of reps to 5.
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
Debug$= "C:\Dev_aon\aon\_SPROC-Debug\SAREPTOT_BAR_DebugPRC.txt"	
string Debug$
debugchan=unt
open(debugchan)Debug$	
write(debugchan)"Top of SAREPTOT_BAR "
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
		
	year$ = sp!.getParameter("YEAR")
	num_to_list = num(sp!.getParameter("NUM_TO_LIST")); rem Number of salesreps to list
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

	dataTemplate$ = "Dummy:C(1),SALESREP:C(20*),TOTAL:C(7*)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

rem --- Open/Lock files

    files=3,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="sam_salespsn_tot",ids$[1]="SAM_SALESPSN_TOT"
    files$[2]="arc_salecode",ids$[2]="ARC_SALECODE"
    files$[3]="ivc_prodcode",ids$[3]="IVC_PRODCODE"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif

    sam03tot_dev=channels[1]
    arm10f_dev=channels[2]
    ivm10a_dev=channels[3]

rem --- Dimension string templates

    dim sam03tot$:templates$[1]
    dim arm10f$:templates$[2]
    dim ivm10a$:templates$[3]
    
rem --- Get sales by salesperson
rem --- salesMap! key=total sales for salesperson, holds slspsnMap! (in case more than one salesperson with same total sales)
rem --- slspsnMap! key=salesperson, holds nothing (empty)
    salesMap!=new java.util.TreeMap()
    slspsn_code$=""
    read(sam03tot_dev,key=firm_id$+year$,dom=*next)
    while 1
        readrecord(sam03tot_dev,end=*break)sam03tot$
        if sam03tot.firm_id$+sam03tot.year$<>firm_id$+year$ then break
        if cvs(sam03tot.product_type$,2)<>"" then continue

        if sam03tot.slspsn_code$<>slspsn_code$ then gosub slspsn_break

        thisSales=sam03tot.total_sales_01+sam03tot.total_sales_02+sam03tot.total_sales_03+sam03tot.total_sales_04+
:                 sam03tot.total_sales_05+sam03tot.total_sales_06+sam03tot.total_sales_07+sam03tot.total_sales_08+
:                 sam03tot.total_sales_09+sam03tot.total_sales_10+sam03tot.total_sales_11+sam03tot.total_sales_12+
:                 sam03tot.total_sales_13
        thisSales=round(thisSales,2)
        slspsnSales=slspsnSales+thisSales
        
        rem --- Skip to next salesperson
        read(sam03tot_dev,key=firm_id$+year$+sam03tot.slspsn_code$+$FF$,dom=*next)
    wend
    gosub slspsn_break

rem --- Build result set for top five salespersons by sales
    if salesMap!.size()>0 then
        topSlspsns=0
        salesDeMap!=salesMap!.descendingMap()
        salesIter!=salesDeMap!.keySet().iterator()
        while salesIter!.hasNext()
            slspsnSales=salesIter!.next()
            slspsnMap!=salesDeMap!.get(slspsnSales)
            slspsnIter!=slspsnMap!.keySet().iterator()
            while slspsnIter!.hasNext()
                slspsn_code$=slspsnIter!.next()
                topSlspsns=topSlspsns+1
                if topSlspsns>num_to_list then break
                dim arm10f$:fattr(arm10f$)
                findrecord(arm10f_dev,key=firm_id$+"F"+slspsn_code$,dom=*next)arm10f$

                slspsnSales=round(slspsnSales/1000,1)
                data! = rs!.getEmptyRecordData()
                data!.setFieldValue("DUMMY"," ")
                data!.setFieldValue("SALESREP",arm10f.code_desc$)
                data!.setFieldValue("TOTAL",str(slspsnSales))
                rs!.insert(data!)
            wend
            if topSlspsns>num_to_list then break
        wend
    endif

rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit

slspsn_break: rem --- Salesperson break
    if slspsn_code$<>"" then
        if salesMap!.containsKey(slspsnSales) then
            slspsnMap!=salesMap!.get(slspsnSales)
        else
            slspsnMap!=new java.util.HashMap()
        endif
        slspsnMap!.put(slspsn_code$,"")
        salesMap!.put(slspsnSales,slspsnMap!)
    endif
    
    rem --- Initialize for next salesperson
    slspsn_code$=sam03tot.slspsn_code$
    slspsnSales=0
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
