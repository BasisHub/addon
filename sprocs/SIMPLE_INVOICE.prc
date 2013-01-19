rem ----------------------------------------------------------------------------
rem Program: SIMPLE_INVOICE.prc
rem Description: Stored Procedure to create a jasper-based simple invoice in AR
rem 
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

declare BBjStoredProcedureData sp!
declare BBjRecordSet rs!
declare BBjRecordData data!

sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- get SPROC parameters

firm_id$ = sp!.getParameter("FIRM_ID")
ar_inv_no$ = sp!.getParameter("AR_INV_NO")
customer$ = sp!.getParameter("CUSTOMER_ID")
amt_mask$ = sp!.getParameter("AMT_MASK")
cust_mask$ = sp!.getParameter("CUST_MASK")
customer_size = num(sp!.getParameter("CUST_SIZE"))
unit_mask$ = sp!.getParameter("UNIT_MASK")
barista_wd$ = sp!.getParameter("BARISTA_WD")
terms_cd$ = sp!.getParameter("TERMS_CD")

chdir barista_wd$

rem --- create the in memory recordset for return

dataTemplate$ = "firm_id:c(2),customer_id:C(1*),cust_name:C(30),address1:C(30),address2:C(30),"
dataTemplate$ = dataTemplate$ + "address3:C(30),address4:C(30),address5:C(30),address6:C(30),"
dataTemplate$ = dataTemplate$ + "remit1:C(30),remit2:C(30),remit3:C(30), remit4:C(30),"
dataTemplate$ = dataTemplate$ + "ar_address1:C(30),ar_address2:C(30),ar_address3:C(30),ar_address4:C(30),ar_phone_no:C(1*),terms_desc:C(1*)"

rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

rem --- open files

files=3,begfile=1,endfile=files
dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
files$[1]="arm-01",ids$[1]="ARM_CUSTMAST"
files$[2]="ars_report",ids$[2]="ARS_REPORT"
files$[3]="arc_termcode",ids$[3]="ARC_TERMCODE"

call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
if status goto std_exit

arm01=channels[1]
ars_report=channels[2]
arc_termcode=channels[3]

rem --- Dimension string templates

dim arm01$:templates$[1]
dim ars_report$:templates$[2]
dim arc_termcode$:templates$[3]
    
rem --- init   

gosub format_return_remit_addresses
gosub format_address_block
gosub format_terms_code

rem --- put data into recordset

data! = rs!.getEmptyRecordData()
data!.setFieldValue("FIRM_ID",firm_id$)
data!.setFieldValue("CUSTOMER_ID",fnmask$(customer$(1,customer_size),cust_mask$))
data!.setFieldValue("CUST_NAME",arm01.customer_name$)
data!.setFieldValue("ADDRESS1", address$(1,30))
data!.setFieldValue("ADDRESS2", address$(31,30))
data!.setFieldValue("ADDRESS3", address$(61,30))
data!.setFieldValue("ADDRESS4", address$(91,30))
data!.setFieldValue("ADDRESS5", address$(121,30))
data!.setFieldValue("REMIT1", remit$(1,30))
data!.setFieldValue("REMIT2", remit$(31,30))
data!.setFieldValue("REMIT3", remit$(61,30))
data!.setFieldValue("REMIT4", remit$(91,30))
data!.setFieldValue("AR_ADDRESS1", ar_address$(1,30))
data!.setFieldValue("AR_ADDRESS2", ar_address$(31,30))
data!.setFieldValue("AR_ADDRESS3", ar_address$(61,30))
data!.setFieldValue("AR_ADDRESS4", ar_address$(91,30))
data!.setFieldValue("AR_PHONE_NO", ar_phone_no$)
data!.setFieldValue("TERMS_DESC", terms_desc$)
rs!.insert(data!)

rem --- close files

close(arm01)
close(ars_report)
close(arc_termcode)

sp!.setRecordSet(rs!)
end

rem --- format address block for customer
format_address_block:

    address$=""
	read record(arm01,key=firm_id$ + customer$)arm01$
    address$=arm01.addr_line_1$+arm01.addr_line_2$+arm01.addr_line_3$+arm01.addr_line_4$+arm01.city$+arm01.state_code$+arm01.zip_code$
    call pgmdir$+"adc_address.aon",address$,24,5,9,30
    
return

rem --- format company and remit-to addresses
format_return_remit_addresses:

    find record (ars_report,key=firm_id$+"AR02",err=*next) ars_report$

    remit$=ars_report.remit_addr_1$+ars_report.remit_addr_2$+ars_report.remit_city$+ars_report.remit_state$+ars_report.remit_zip$
    call pgmdir$+"adc_address.aon",remit$,24,3,9,30
    remit$=ars_report.remit_name$+remit$

    ar_address$=ars_report.addr_line_1$+ars_report.addr_line_2$+ars_report.city$+ars_report.state_code$+ars_report.zip_code$
    call pgmdir$+"adc_address.aon",ar_address$,24,3,9,30
    ar_address$=ars_report.name$+ar_address$

    call stbl("+DIR_SYP")+"bac_getmask.bbj","T",cvs(ars_report.phone_no$,2),"",phone_mask$
    ar_phone_no$=str(cvs(ars_report.phone_no$,2):phone_mask$)
    
return

rem --- format terms code
format_terms_code:

    arc_termcode.firm_id$=firm_id$
    arc_termcode.record_id_a$="A"
    arc_termcode.code_desc$="Undefined"
    
    find record (arc_termcode,key=arc_termcode.firm_id$+arc_termcode.record_id_a$+terms_cd$,dom=*next)arc_termcode$
    terms_desc$=cvs(arc_termcode.code_desc$,3)
    
return

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

std_exit:
end


