rem ----------------------------------------------------------------------------
rem Program: SIMPLE_INVOICE_DTL.prc
rem Description: Stored Procedure to create a jasper-based simple invoice in AR
rem Invoice Detail sub-report
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

seterr sproc_error

declare BBjStoredProcedureData sp!
declare BBjRecordSet rs!
declare BBjRecordData data!

sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- get SPROC parameters

firm_id$ = sp!.getParameter("FIRM_ID")
ar_inv_no$ = sp!.getParameter("AR_INV_NO")
amt_mask$ = sp!.getParameter("AMT_MASK")
unit_mask$ = sp!.getParameter("UNIT_MASK")
barista_wd$ = sp!.getParameter("BARISTA_WD")

chdir barista_wd$

rem --- create the in memory recordset for return

dataTemplate$ = "trns_date:c(10),memo:c(1*),units:c(1*),unit_price:c(1*),ext_price:c(1*),tot_price:c(1*)"

rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

rem --- open files

files=3,begfile=1,endfile=files
dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
files$[1]="are-15",ids$[1]="ARE_INVDET"

call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
if status then
    seterr 0
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "File open error.",1001
endif

are15=channels[1]

rem --- Dimension string templates

dim are15$:templates$[1]
    
rem --- init   

read (are15,key=firm_id$+ar_inv_no$,dom=*next)

rem -- detail loop

while 1

    readrecord (are15,end=*break)are15$
    if pos(firm_id$+ar_inv_no$=are15$)<>1 then break

    tot_price=tot_price+are15.ext_price
    memo=are15.units+are15.ext_price<>0

    rem --- put data into recordset

    data! = rs!.getEmptyRecordData()
    data!.setFieldValue("TRNS_DATE", fndate$(are15.trns_date$))
    memo_1024$=are15.memo_1024$
    if len(memo_1024$) and memo_1024$(len(memo_1024$))=$0A$ then memo_1024$=memo_1024$(1,len(memo_1024$)-1); rem --- trim trailing newline
    data!.setFieldValue("MEMO",memo_1024$)
    if memo
        data!.setFieldValue("UNITS",str(are15.units:unit_mask$))
        data!.setFieldValue("UNIT_PRICE",str(are15.unit_price:amt_mask$))
        data!.setFieldValue("EXT_PRICE",str(are15.ext_price:amt_mask$))
    else
        data!.setFieldValue("UNITS","")
        data!.setFieldValue("UNIT_PRICE","")
        data!.setFieldValue("EXT_PRICE","")        
    endif
    data!.setFieldValue("TOT_PRICE",str(tot_price:amt_mask$))
    rs!.insert(data!)

wend

rem --- close files

close(are15)

sp!.setRecordSet(rs!)
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

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num

std_exit:
end


