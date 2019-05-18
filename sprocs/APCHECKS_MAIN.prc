rem ----------------------------------------------------------------------------
rem --- Program: APChecks_Main.prc
rem --- 
rem --- Description: APChecks_MAIN.prc is a stored Procedure to create jasper-based,
rem ---              3-part AP Checks with user-selectable part-order from these options:
rem ---                - A => Accounting Stub          ==> APChecks_Stub.prc
rem ---                - V => Vendor Stub              ==> APChecks_Stub.prc
rem ---                - C => Check (the check itself) ==> APChecks_Check.prc
rem ---            - apr_apchecks.aon does the bulk of the processing logic including
rem ---              writing to a jasper print work file: APW_CHKJASPERPRN. This work file
rem ---              is used for SQL queries for jasper.
rem ---            - APChecks_MAIN.prc does the first query, to get the 'driver' info
rem ---              for the -main.jrxml.
rem ---            - The subreport, APChecks_Stub.prc/-stub.jrxml, prints vendor and 
rem ---              accounting stubs by querying the work file based on -main's calling params.
rem ---            - The subreport, APChecks_Check.prc/-check.jrxml, prints each check 
rem ---              itself by querying the work file based on -main's calling params. Stub overflow
rem ---              is indicated in the workfile as a VOID check record.

rem --- See apr_apchecks.aon for more info.

rem --- AddonSoftware
rem --- Copyright BASIS International Ltd.  All Rights Reserved.
rem --- All Rights Reserved
rem ----------------------------------------------------------------------------

	seterr sproc_error
		
	declare BBjStoredProcedureData sp!
	declare BBjRecordSet rs!
	declare BBjRecordData data!

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get 'IN' SPROC parameters 

	firm_id$ = sp!.getParameter("FIRM_ID")
	barista_wd$ = sp!.getParameter("BARISTA_WD")
	ap_type$ = sp!.getParameter("AP_TYPE")
    ach_payment$ = sp!.getParameter("ACH_PAYMENT")

	chdir barista_wd$
	
rem --- Create the memory recordset for return to jasper

	dataTemplate$ = ""
	dataTemplate$ = dataTemplate$ + "firm_id:C(2), ap_type:C(1*), check_num:C(1*), check_date:C(10), "
	dataTemplate$ = dataTemplate$ + "aptype_vend_pagenum:C(3), vendor_id:C(1*), vend_name:C(30), "
	dataTemplate$ = dataTemplate$ + "vend_addr1:C(35), vend_addr2:C(35), vend_addr3:C(35), vend_addr4:C(35)  "

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

rem --- Get Barista System Program directory
	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)
	pgmdir$=stbl("+DIR_PGM",err=*next)
	
rem --- Open/Lock files

    files=2,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="apm-01",ids$[1]="APM_VENDMAST"
    files$[2]="apm_payaddr",ids$[2]="APM_PAYADDR"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif

    apm01_dev=channels[1]
    apm08_dev=channels[2]

rem --- Dimension string templates

	dim apm01a$:templates$[1]
	dim apm08a$:templates$[2]
    
initializations: rem --- Initializations

    more=1

rem --- Get 'driver' info from work file that was pre-filled w/needed data in the .aon o'lay
rem ---     Note: The work file includes all records that should be processed

rem ---     Note: I include vendor and addr here so Stub and Check don't have to both
rem ---           format the address.


	sql_prep$=""
	sql_prep$=sql_prep$+"SELECT DISTINCT wk.firm_id "
	sql_prep$=sql_prep$+"      ,wk.ap_type "
	sql_prep$=sql_prep$+"      ,wk.check_no "
	sql_prep$=sql_prep$+"      ,wk.check_date "
	sql_prep$=sql_prep$+"      ,wk.chk_pagenum "
	sql_prep$=sql_prep$+"      ,wk.vendor_id "
	sql_prep$=sql_prep$+"FROM APW_CHKJASPERPRN wk "
	sql_prep$=sql_prep$+"WHERE firm_id='"+firm_id$+"' "

	if cvs(ach_payment$,2)<>"" then
	    sql_prep$=sql_prep$+"AND ach_payment='"+ach_payment$+"' "
	endif
	
	sql_chan=sqlunt
	sqlopen(sql_chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
	sqlprep(sql_chan)sql_prep$
	dim read_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)

rem --- Process SQL results

	while 1
		read_tpl$ = sqlfetch(sql_chan,end=*break)
		
		firm_id$=   read_tpl.firm_id$
		ap_type$=   read_tpl.ap_type$
		vendor_id$= read_tpl.vendor_id$
		check_no$=  read_tpl.check_no$
		aptype_vend_pagenum$=  read_tpl.chk_pagenum$
		
		rem --- Vendor Address
			dim address$(4*35)
		   
			find record (apm01_dev,key=firm_id$+vendor_id$,dom=*next) apm01a$
			address$(1)=apm01a.addr_line_1$+apm01a.addr_line_2$+apm01a.city$+apm01a.state_code$+apm01a.zip_code$+apm01a.cntry_id$
			vend_name$= apm01a.vendor_name$
			start_block = 1

			if start_block
				find record (apm08_dev,key=firm_id$+vendor_id$,dom=*endif) apm08a$
				address$(1)= apm08a.addr_line_1$+apm08a.addr_line2$+apm08a.city$+apm08a.state_code$+apm08a.zip_code$+apm08a.cntry_id$
				vend_name$=  apm08a.vendor_name$
			endif
			
			call pgmdir$+"adc_address.aon",address$,24,3,9,35
			 
		rem --- Send data to out result set
			data! = rs!.getEmptyRecordData()
			
			data!.setFieldValue("FIRM_ID", firm_id$)
			data!.setFieldValue("AP_TYPE", ap_type$)
			data!.setFieldValue("CHECK_NUM", check_no$)
			data!.setFieldValue("APTYPE_VEND_PAGENUM", aptype_vend_pagenum$)
			data!.setFieldValue("CHECK_DATE", fndate$(check_date$))
			data!.setFieldValue("VENDOR_ID", vendor_id$)
			data!.setFieldValue("VEND_NAME", vend_name$)
			data!.setFieldValue("VEND_ADDR1", address$(1,35))
			data!.setFieldValue("VEND_ADDR2", address$(36,35))
            data!.setFieldValue("VEND_ADDR3", address$(71,35))
            data!.setFieldValue("VEND_ADDR4", address$(106))
			
			rs!.insert(data!)
	wend

sp!.setRecordSet(rs!)
		
rem --- close files

close(apm01_dev)
close(apm08_dev)

end


rem --- Date/time handling functions

    def fndate$(q$)
        q1$=""
        q1$=date(jul(num(q$(1,4)),num(q$(5,2)),num(q$(7,2)),err=*next),err=*next)
        if q1$="" q1$=q$
        return q1$
    fnend

    def fnyy$(q$)=q$(3,2)
    def fnclock$(q$)=date(0:"%hz:%mz %p")
    def fntime$(q$)=date(0:"%Hz%mz")

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

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num
    
std_exit:
    end