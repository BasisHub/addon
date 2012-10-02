rem --- Vendor Maintenance (Open Invoice Inquiry, Lightbar)
rem --- Program apr_vendinv v8.0.0 23May2007 (apm_mf)
rem --- Created by adx_codeport.bbx v1.1.5 (05/23/2007 10:46:54)

rem --- AddonSoftware Version 8.0.0 - 01Jan2007
rem --- Copyright (c) 1981-2007 AddonSoftware
rem --- All Rights Reserved

        setesc std_error
        seterr std_error

rem --- Retrieve the program path

        dir_pgm$=stbl("+DIR_PGM",err=*next)

rem --- Retrieve sysinfo data

        sysinfo_template$=stbl("+SYSINFO_TPL",err=*next)
        dim sysinfo$:sysinfo_template$
        sysinfo$=stbl("+SYSINFO",err=*next)
        milestone=num(stbl("+MILESTONE",err=*next),err=*next)
        firm_id$=sysinfo.firm_id$
        task_desc$=sysinfo.task_desc$

rem --- Open/Lock files

        files=3,begfile=1,endfile=files
        dim files$[files],options$[files],chans$[files],templates$[files]
        files$[1]="aps_params";rem " --- aps-01"
        files$[2]="apt_invoicehdr";rem " --- apt-01
        files$[3]="apt_invoicedet";rem " --- apt-11
        for wkx=begfile to endfile
            options$[wkx]="OTA"
        next wkx

    call stbl("+DIR_SYP")+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:       chans$[all],templates$[all],rd_table_chans$[all],batch,status$

        if status$<>"" goto std_exit
        aps01_dev=num(chans$[1])
        apt01_dev=num(chans$[2])
        apt11_dev=num(chans$[3])

rem --- Dimension string templates

        dim aps01a$:templates$[1]
        dim apt01a$:templates$[2],apt11a$:templates$[3]

rem --- retrieve key template

        call stbl("+DIR_SYP")+"bac_key_template.bbj","APT_INVOICEHDR","PRIMARY",apt01a_key0$,rd_table_chans$[all],status$

rem --- Assign form input values to local variables

        vendor_id$=Option!.getOptionData("VENDOR_ID")
        ap_type$=Option!.getOptionData("AP_TYPE")
        beg_inv_no$=Option!.getOptionData("AP_INV_NO")
        pd_unpd_both$=Option!.getOptionData("PD_UNPD_BOTH")

rem --- Retrieve parameter records

        aps01a_key$=firm_id$+"AP00"
        find record (aps01_dev,key=aps01a_key$,err=std_missing_params) aps01a$

rem --- Initializations

        recs=0
        width=80
        height=18
        win_x=0
        win_y=5
        title$="Open Invoices, Vendor: "
        maxrow=height-5

        dim inv_types$[3]
        inv_types$[1]="Paid"
        inv_types$[2]="Unpaid"
        inv_types$[3]="Both"

        dim x0$(73),x[2],w0$(22),w1$(11),w[2]
        dim heading$(width-2),footing$(width-2),msg$[0]

        call stbl("+DIR_PGM")+"adc_getmask.aon","","AP","A","",mask$,0,0

        call dir_pgm$+"adc_progress.aon","N","","","","",0,apt01_dev,1,meter_num,status

rem --- Init Headings

rem --- date/time 

        OutVect!=bbjAPI().getSysGui().makeVector()
        rep_date$=date(0:"%Mz/%Dz/%Yd")
        rep_date_stamp$=date(0:"%Yd%Mz%Dz")
        rep_time$=date(0:"%hz:%mz %p")
        rep_time_stamp$=date(0:"%Hz%mz%sz")
        rep_prog$=pgm(-2)

rem --- column headings

        dim columns$[8,10]
        if aps01a.ret_flag$<>"Y" dim columns$[7,10]
        columns$[0,0]="Invoice No",columns$[0,1]="C",columns$[0,2]="15"
        columns$[1,0]="Transaction",columns$[1,1]="C",columns$[1,2]="20"
        columns$[2,0]="Date",columns$[2,1]="C",columns$[2,2]="15"
        columns$[3,0]="Due",columns$[3,1]="C",columns$[3,2]="15"
        columns$[4,0]="PG",columns$[4,1]="C",columns$[4,2]="5"
        columns$[5,0]="H",columns$[5,1]="C",columns$[5,2]="5"
        columns$[6,0]="Amount",columns$[6,1]="N",columns$[6,2]="15",columns$[6,3]=mask$
        columns$[7,0]="Discount",columns$[7,1]="N",columns$[7,2]="15",columns$[7,3]=mask$
        if aps01a.ret_flag$="Y"
            columns$[8,0]="Retention",columns$[8,1]="N",columns$[8,2]="15",columns$[8,3]=mask$
        endif

rem --- miscellaneous headings

        dim headings$[5]
        headings$[0]=firm_name$
        headings$[1]=task_desc$
        headings$[2]=title$+vendor_id$
        headings$[3]="AP Type: "+ap_type$
        if beg_inv_no$="" then let x$="First Invoice" else let x$="invoice no: "+beg_inv_no$
        headings$[4]="Beginning with "+x$
        headings$[5]="Invoice type: "+inv_types$[pos(pd_unpd_both$="PUB")]

rem --- Print positions

        dim o[2]
        o[2]=width-2-mask
        o[1]=o[2]-mask  
        o[0]=o[1]-mask


position_apt01: rem --- Position apt-01

        l=1
        inv_found=0
        row=1
        page=1
        t0$=""
        invtotal=0
        baltotal=0
        dim apt01ak0$:apt01a_key0$
        dim k$:apt01a_key0$
        apt01ak0.firm_id$=firm_id$
        if aps01a.multi_types$="Y" and cvs(ap_type$,2)<>""
        	apt01ak0.ap_type$=ap_type$
        	apt01ak0.vendor_id$=vendor_id$
        	apt01ak0.ap_inv_no$=beg_inv_no$
		endif
        read record (apt01_dev,key=apt01ak0$,dir=0,dom=*next) apt01a$

next_apt01: rem --- Read next invoice

        k$=key(apt01_dev,end=no_more_invoices)
        if pos(firm_id$=k$)<>1 goto no_more_invoices
        if aps01a.multi_types$="Y" and cvs(ap_type$,2)<>""
	        if k.ap_type$<>ap_type$ goto no_more_invoices
	    endif
	    if aps01a.multi_types$="Y" and cvs(ap_type$,2)<>""
        	if cvs(vendor_id$,2)<>""
        		if k.vendor_id$<>vendor_id$ goto no_more_invoices
        	endif	
        endif
        if (aps01a.multi_types$="Y" and cvs(ap_type$,2)="") or aps01a.multi_types$="N"
        	if cvs(vendor_id$,2)<>"" 
        		if k.vendor_id$<>vendor_id$
        			read(apt01_dev)
        			goto next_apt01
        		endif	
        	endif	
        endif
        
rem --- Invoice header

        read record (apt01_dev,key=k$) apt01a$
        gosub calc_balance
        if pd_unpd_both$="P" and balance<>0  goto apt11_loop
        if pd_unpd_both$="U" and balance=0  goto apt11_loop

rem --- Display invoice totals

        if t0$=k.ap_inv_no$ goto reposition_invhdr
        gosub inv_total

reposition_invhdr: rem --- Reposition to invoice header if OK to display

        if found read (apt01_dev,key=apt01a$(1,len(apt01ak0$)))
        recs=recs+1
rem --- Header window record

        OutVect!.addItem(apt01a.ap_inv_no$)
        wk$="Invoice";if apt01a.mc_inv_flag$="M" then wk$(1,2)="MI Invoice"
        OutVect!.addItem(wk$)
        OutVect!.addItem(fndate$(apt01a.invoice_date$))
        OutVect!.addItem(fndate$(apt01a.inv_due_date$))
        OutVect!.addItem(apt01a.payment_grp$)
        OutVect!.addItem(apt01a.hold_flag$)
        OutVect!.addItem(apt01a.invoice_amt$)
        OutVect!.addItem(apt01a.discount_amt$)

        if aps01a.ret_flag$="Y" 
            OutVect!.addItem(apt01a.retention$)
        endif

        inv_found=1
        invtotal=invtotal+invoice
        baltotal=baltotal+balance
        detail$="N"
        read record (apt11_dev,key=apt01a.firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$,dom=*next) apt11a$

next_apt11: rem --- Detail window record

        read record (apt11_dev,end=next_apt01) apt11a$
    if apt01a.firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$ <>
:       apt11a.firm_id$+apt11a.ap_type$+apt11a.vendor_id$+apt11a.ap_inv_no$ goto next_apt01
        detail$="Y"

        switch asc(apt11a.trans_type$)
        case asc("A"); let trans$="    Adjust"; break
        case asc("C"); let trans$="CC "+apt11a.trans_ref$; break
        case asc("M"); let trans$="MC "+apt11a.trans_ref$; break
        case asc("R"); let trans$="RC "+apt11a.trans_ref$; break
        case asc("S"); let trans$="MI "+apt11a.trans_ref$; break
        case default; let trans$=""; break
        swend

        OutVect!.addItem("")
        OutVect!.addItem(trans$)
        OutVect!.addItem(fndate$(apt11a.trans_date$))
        xwk=fnblank(3)
        OutVect!.addItem(apt11a.trans_amt$)
        OutVect!.addItem(apt11a.trans_disc$)
        if aps01a.ret_flag$="Y"
            OutVect!.addItem(apt11a.trans_ret$)
        endif

        inv_found=1


apt11_loop: rem --- Loop back for next invoice

        goto next_apt11

no_more_invoices: rem --- No more invoices

        if recs=0
            msg_id$="DOC_OUTPUT_NODATA"
            gosub disp_message
            goto std_exit_no_report
        endif

        if inv_found
            gosub inv_total
            gosub vendor_total
        else
            OutVect!.addItem("No invoices")
            xwk=fnblank(7+(aps01a.ret_flag$="Y"))
        endif

finished: rem --- All done

        goto std_exit

vendor_total: rem --- Vendor Total

        OutVect!.addItem("")
        OutVect!.addItem("Vendor Total")
        xwk=fnblank(4)
        OutVect!.addItem(str(baltotal))
        xwk=fnblank(1+(aps01a.ret_flag$="Y"))
        inv_found=1
        return

inv_total: rem --- Invoice Total

        if t0$="" goto first_inv_total
        if detail$="N" goto first_inv_total
        OutVect!.addItem("")
        OutVect!.addItem("Invoice Total")
        xwk=fnblank(4)
        OutVect!.addItem(str(lastbalance))
        xwk=fnblank(1+(aps01a.ret_flag$="Y"))  
        inv_found=1

first_inv_total:

        let t0$=k.ap_inv_no$,lastbalance=balance
        return

calc_balance: rem --- Retrieve payment and adjustments

        let invoice=num(apt01a.invoice_amt$),applied=0,found=0
        read (apt11_dev,key=apt01a.firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$,dom=*next)
next_calc_balance:
        read record (apt11_dev,end=end_calc_balance) apt11a$
    if apt01a.firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$ <>
:       apt11a.firm_id$+apt11a.ap_type$+apt11a.vendor_id$+apt11a.ap_inv_no$ goto end_calc_balance
        let found=1
        if apt11a.trans_type$="A" invoice=invoice+num(apt11a.trans_amt$) else applied=applied+num(apt11a.trans_amt$)
        goto next_calc_balance
end_calc_balance:
        let balance=invoice+applied
        return

rem #include std_functions.src
rem --- Standard AddonSoftware functions (01Mar2006)
rem --- Functions used to retrieve form values

    def fnstr_pos(q0$,q1$,q1)=int((pos(q0$=q1$,q1)+q1-1)/q1)
    def fnget_rec_date$(q0$)=rd_rec_data$[fnstr_pos(cvs(q0$,1+2+4)+"."+
:                            cvs(q0$,1+2+4),rd_rec_data$[0,0],40),0]
    def fnget_fld_data$(q0$,q1$)=cvs(rd_rec_data$[fnstr_pos(cvs(q0$,1+2+4)+"."+
:                                cvs(q1$,1+2+4),rd_rec_data$[0,0],40),0],2)
    def fnget_table$(q0$)=rd_alias_id$

rem --- Miscellaneous functions

    def fncenter(q$,q)=int((q-len(q$))/2)

rem --- Format inventory item description

    def fnitem$(q$,q1,q2,q3)=cvs(q$(1,q1)+" "+q$(q1+1,q2)+" "+q$(q1+q2+1,q3),32)

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

rem --- fnbasename$: Strip path and optionally the suffix from a file name

    def fnbasename$(q$,q0$)
        q=max(pos("/"=q$,-1),pos(":"=q$,-1),pos(">"=q$,-1),pos("\"=q$,-1))
        if q then q$=q$(q+1)
        if q0$<>"" then q=mask(q$,q0$); if q q$=q$(1,q-1)
    return q$

rem --- fnglobal: Return numeric value of passed stbl variable

    def fnglobal(q$,q1)
        q1$=stbl(q$,err=*next),q1=num(q1$,err=*next)
        return q1
    fnend

rem --- fnglobal$: Return string value of passed STBL variable

    def fnglobal$(q$,q1$)
        q1$=stbl(q$,err=*next)
        return q1$
    fnend

rem --- Create blank line in OutVect! (no return value wanted or needed)
    def fnblank(q0)
        for q1=1 to q0
            OutVect!.addItem("")
        next q1
        return q1
    fnend

rem #endinclude std_functions.src

rem #include disp_message.src

disp_message:rem --- Display Message Dialog

    call stbl("+DIR_SYP")+"bac_message.bbj",msg_id$,msg_tokens$[all],msg_opt$,table_chans$[all]
    return

rem #include std_error.src

std_error: rem --- Standard error handler (01Apr2006)

    rd_err_text$=""
    if tcb(5)<>0 and pgm(-1)=pgm(-2) rd_err_text$=pgm(tcb(5))
    dir_pgm$=stbl("+DIR_PGM",err=std_error_exit)
    call stbl("+DIR_SYP")+"bac_error.bbj",err=std_error_exit,pgm(-2),str(tcb(5)),
:                                str(err),rd_err_text$,rd_err_act$
    if pos("EXIT"=rd_err_act$) goto std_error_exit
    if pos("ESCAPE"=rd_err_act$) seterr 0;setesc 0
    if pos("RETRY"=rd_err_act$) retry
std_error_exit:
    master_user$=cvs(stbl("+MASTER_USER",err=std_error_release),2)
    sysinfo_template$=stbl("+SYSINFO_TPL",err=std_error_release)
    dim sysinfo$:sysinfo_template$
    sysinfo$=stbl("+SYSINFO",err=std_error_release)
    if cvs(sysinfo.user_id$,2)=master_user$ escape
std_error_release:
    status=999
    if pgm(-1)<>pgm(-2) exit
    release

rem #endinclude std_error.src

rem #include std_missing_params.src

std_missing_params: rem --- Standard missing parameter handler (15Apr2006)

    rd_err_text$=""
    if tcb(5)<>0 and pgm(-1)=pgm(-2) rd_err_text$=pgm(tcb(5))
    dir_pgm$=stbl("+DIR_PGM",err=std_missing_params_exit)
    call dir_pgm$+"adc_noparams.aon",err=std_missing_params_exit,pgm(-2),str(tcb(5)),
:                                   str(err),rd_err_text$,rd_err_act$
std_missing_params_exit:
    master_user$=cvs(stbl("+MASTER_USER",err=std_missing_params_release),2)
    sysinfo_template$=stbl("+SYSINFO_TPL",err=std_missing_params_release)
    dim sysinfo$:sysinfo_template$
    sysinfo$=stbl("+SYSINFO",err=std_missing_params_release)
    if cvs(sysinfo.user_id$,2)=master_user$ escape
std_missing_params_release:
    status=999
    if pgm(-1)<>pgm(-2) exit
    release

rem #endinclude std_missing_params.src

rem #include std_end.src

std_exit: rem --- Standard program end (01Mar2006)

    call pgmdir$+"adc_progress.aon","D","","","","",0,0,0,meter_num,status
    run stbl("+DIR_SYP")+"bas_process_end.bbj",err=*next
    release
rem #endinclude std_end.src

std_exit_no_report:

    OutVect!=null()
    goto std_exit
    
    end
