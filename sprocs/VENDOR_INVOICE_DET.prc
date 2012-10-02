rem --- VENDOR_INVOICE_DET.prc
rem --- detail for Vendor Open Invoice rpt (hyperlinked)
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
ap_type$=sp!.getParameter("AP_TYPE")
vendor_id$=sp!.getParameter("VENDOR_ID")
ap_inv_no$=sp!.getParameter("AP_INV_NO")
barista_wd$=sp!.getParameter("BARISTA_WD")

sv_wd$=dir("")
chdir barista_wd$

rem --- Open/Lock files

    files=1,begfile=1,endfile=files
    dim files$[files],options$[files],chans$[files],templates$[files]
    files$[1]="APT_INVOICEDET"
    for wkx=begfile to endfile
        options$[wkx]="OTA"
    next wkx

    call stbl("+DIR_SYP")+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:       chans$[all],templates$[all],table_chans$[all],batch,status$

        if status$<>"" goto done

    apt_invoicedet=num(chans$[1])

rem --- Dimension string templates

    dim apt_invoicedet$:templates$[1]

    rs! = BBJAPI().createMemoryRecordSet(templates$[1]+",TRANS_TYPE_DESC:C(20)")

rem --- init, and position for read

    read (apt_invoicedet,key=firm_id$+ap_type$+vendor_id$+ap_inv_no$,dom=*next)

rem --- read/load open invoice detail info into recordset.

    while 1
        read record(apt_invoicedet,end=*break)apt_invoicedet$
        if apt_invoicedet.firm_id$<>firm_id$ then break
        if apt_invoicedet.ap_type$<>ap_type$ then break
        if apt_invoicedet.vendor_id$<>vendor_id$ then break
        if cvs(apt_invoicedet.ap_inv_no$,3)<>cvs(ap_inv_no$,3) then break

        switch pos(apt_invoicedet.trans_type$="ACMRV")
            case 1
                trans_tp$="Adjustment"
            break
            case 2
                trans_tp$="Computer"
            break
            case 3
                trans_tp$="Manual"
            break
            case 4
                trans_tp$="Reversal"
            break
            case 5
                trans_tp$="Void"
            break
            case default
                trans_tp$="not defined"
            break
        swend

        data! = rs!.getEmptyRecordData()
        data!.setFieldValue("TRANS_TYPE", trans_type$)
        data!.setFieldValue("TRANS_DATE", fndate$(apt_invoicedet.trans_date$))
        data!.setFieldValue("TRANS_REF", apt_invoicedet.trans_ref$)
        data!.setFieldValue("TRANS_AMT", apt_invoicedet.trans_amt$)
        data!.setFieldValue("TRANS_DISC", apt_invoicedet.trans_disc$)
        data!.setFieldValue("TRANS_RET", apt_invoicedet.trans_ret$)
        data!.setFieldValue("TRANS_TYPE_DESC", trans_tp$)
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
