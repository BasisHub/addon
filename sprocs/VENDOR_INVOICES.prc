rem --- VENDOR_INVOICES
rem --- used to create Vendor Open Invoice rpt via iReport
rem --- Dec 08.CAH
rem
rem --- AddonSoftware
rem --- Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------
seterr error_routine

rem --- Declare some variables ahead of time
declare BBjStoredProcedureData sp!
declare BBjRecordSet rs!
declare BBjRecordData data!

rem --- Get the infomation object for the Stored Procedure
sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get the IN and IN/OUT parameters used by the procedure
firm_id$ = sp!.getParameter("FIRM_ID")
vendor_id$=sp!.getParameter("VENDOR_ID")
ap_type$=sp!.getParameter("AP_TYPE")
beg_inv_no$=sp!.getParameter("BEG_INV_NO")
pd_unpd_both$=sp!.getParameter("PD_UNPD_BOTH")
barista_wd$=sp!.getParameter("BARISTA_WD")

sv_wd$=dir("")
chdir barista_wd$

rem --- Open/Lock files

    files=4,begfile=1,endfile=files
    dim files$[files],options$[files],chans$[files],templates$[files]
    files$[1]="APT_INVOICEHDR"
    files$[2]="APC_PAYMENTGROUP"
    files$[3]="APC_TYPECODE"
    files$[4]="APM_VENDMAST"
    for wkx=begfile to endfile
        options$[wkx]="OTA"
    next wkx

    call stbl("+DIR_SYP")+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:       chans$[all],templates$[all],table_chans$[all],batch,status$

        if status$<>"" goto done

    apt_invoicehdr=num(chans$[1])
    apc_paymentgroup=num(chans$[2])
    apc_typecode=num(chans$[3])
    apm_vendmast=num(chans$[4])

rem --- Dimension string templates

    dim apt_invoicehdr$:templates$[1]
    dim apc_paymentgroup$:templates$[2]
    dim apc_typecode$:templates$[3]
    dim apm_vendmast$:templates$[4]


    rs! = BBJAPI().createMemoryRecordSet(templates$[1]+",PYMTGRP_DESC:C(20),VENDOR_NAME:C(30),AP_TYPE_CODE_DESC:C(20)")

rem --- init, and position for read

    read record(apm_vendmast,key=firm_id$+vendor_id$,dom=*next)apm_vendmast$
    read record(apc_typecode,key=firm_id$+"A"+ap_type$,dom=*next)apc_typecode$
    rem --- ********************************
    rem --- need to figure out how to return vend name and ap type desc as outbound params
    rem --- thought this would do it -- so they'd show on report, but doesn't work, so
    rem --- adding these fields (redundantly) to each row in rs!
    rem sp!.setParameter("VENDOR_NAME",apm_vendmast.vendor_name$)
    rem sp!.setParameter("AP_TYPE_CODE_DESC",apc_typecode.code_desc$)

    read record (apt_invoicehdr,key=firm_id$+ap_type$+vendor_id$+beg_inv_no$,dir=0,dom=*next)apt_invoicehdr$

    while 1
        read record(apt_invoicehdr,end=*break)apt_invoicehdr$
        if apt_invoicehdr.firm_id$<>firm_id$ then break
        if apt_invoicehdr.ap_type$<>ap_type$ then break
        if apt_invoicehdr.vendor_id$<>vendor_id$ then break
        read record (apc_paymentgroup,key=apt_invoicehdr.firm_id$+"D"+apt_invoicehdr.payment_grp$,dom=*next)apc_paymentgroup$

        data! = rs!.getEmptyRecordData()
        data!.setFieldValue("AP_INV_NO", apt_invoicehdr.ap_inv_no$)
        data!.setFieldValue("MC_INV_FLAG", apt_invoicehdr.mc_inv_flag$)
        data!.setFieldValue("INVOICE_DATE", fndate$(apt_invoicehdr.invoice_date$))
        data!.setFieldValue("INV_DUE_DATE", fndate$(apt_invoicehdr.inv_due_date$))
        data!.setFieldValue("PAYMENT_GRP", apt_invoicehdr.payment_grp$)
        data!.setFieldValue("HOLD_FLAG", apt_invoicehdr.hold_flag$)
        data!.setFieldValue("INVOICE_AMT", apt_invoicehdr.invoice_amt$)
        data!.setFieldValue("DISCOUNT_AMT", apt_invoicehdr.discount_amt$)
        data!.setFieldValue("RETENTION", apt_invoicehdr.retention$)
        data!.setFieldValue("PYMTGRP_DESC", apc_paymentgroup.code_desc$)
        data!.setFieldValue("AP_TYPE_CODE_DESC", apc_typecode.code_desc$ )
        data!.setFieldValue("VENDOR_NAME", apm_vendmast.vendor_name$)
        rs!.insert(data!)

    wend

done:
sp!.setRecordSet(rs!)
end

rem --- Date/time handling functions

    def fndate$(q$)
        q1$=""
        q1$=date(jul(num(q$(1,4)),num(q$(5,2)),num(q$(7,2)),err=*next),err=*next)
        if q1$="" q1$=q$
        return q1$
    fnend

rem --- Error routine
error_routine:
    seterr done
    msg$ = "Error #" + str(err) + " occured in " + pgm(-1) + " at line " + str(tcb(5))
    if err = 77 then msg$ = msg$ + $0d0a$ + "SQL Err: " + sqlerr(chan)
    java.lang.System.out.println(msg$)
    if tcb(13) then exit else end
