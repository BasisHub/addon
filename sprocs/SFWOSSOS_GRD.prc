rem ----------------------------------------------------------------------------
rem Program: SFWOSSOS_GRD.prc     
rem Description: Stored Procedure to build a resultset that adx_aondashboard.bbj
rem              can use to populate the given dashboard widget
rem 
rem              Data returned is for WOs that have links to SOs
rem              for the "WOs linked to SOs" grid widget
rem
rem Author(s): C. Hawkins, C. Johnson
rem Revised: 04.03.2014
rem
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

GOTO SKIP_DEBUG
Debug$= "C:\Temp\SFWOSSOS_GRD_DebugPRC.txt"	
string Debug$
debugchan=unt
open(debugchan)Debug$	
write(debugchan)"Top of SATOPREP_LIN "
SKIP_DEBUG:

seterr sproc_error

rem --- Set of utility methods

	use ::ado_func.src::func

rem --- Declare some variables ahead of time

	declare BBjStoredProcedureData sp!

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get the IN parameters used by the procedure

	wo_include_type$ = sp!.getParameter("WO_INCLUDE_TYPE"); rem As listed below; used to filter WOs reported
													  rem A = Open WOs only
													  rem B = Planned WOs only
													  rem C = Quoted WOs only
													  rem D = Open and Planned WOs
													  rem E = Planned and Quoted WOs
													  rem F = Open and Quoted WOs
                                                      rem G = All except Closed WOs
                                                      rem H = Closed WOs only
                                                      rem I = Open and Closed WOs
                                                      rem J = All (Open/Planned/Quoted/Closed)
	so_include_type$ = sp!.getParameter("SO_INCLUDE_TYPE"); rem As listed below; used to filter SOs reported
													  rem A = Sales (Open) SOs only
													  rem B = Backorders only
													  rem C = Quoted SOs only
													  rem D = Sales and Backorders SOs
													  rem E = Backorders and Quotes SOs
													  rem F = Sales and Quotes (no B/Os)
													  rem G = All uninvoiced (sales, B/Os and quotes)
													  
	if pos(wo_include_type$="ABCDEFGHIJ")=0
		wo_include_type$="A"; rem default to Open WOs only
	endif
	
	if pos(so_include_type$="ABCDEFG")=0
		so_include_type$="A"; rem default to Open SOs only
	endif
	
	firm_id$ = sp!.getParameter("FIRM_ID")
	barista_wd$ = sp!.getParameter("BARISTA_WD")
	masks$ = sp!.getParameter("MASKS")

rem --- dirs	
	sv_wd$=dir("")
	chdir barista_wd$

rem --- Get Barista System Program directory
	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)
	pgmdir$=stbl("+DIR_PGM",err=*next)
	
rem --- masks$ will contain pairs of fields in a single string mask_name^mask|

	if len(masks$)>0
		if masks$(len(masks$),1)<>"|"
			masks$=masks$+"|"
		endif
	endif
	
rem --- create the in memory recordset for return

    dataTemplate$ = "WO:C(7*), WO_Stat:C(1), Est_Cmplt:C(8*), Item:C(20*), Quantity:C(7*), SO:C(7*), SO_Stat:C(1), Est_Ship:C(8*)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

rem --- Open/Lock files

    files=3,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="sfe-01",ids$[1]="SFE_WOMASTR"
    files$[2]="opt-01",ids$[2]="OPE_ORDHDR"
    files$[3]="opt-11",ids$[3]="OPE_ORDDET"
   
    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif

    sfe01a_dev=channels[1]
    ope01a_dev=channels[2]
    ope11a_dev=channels[3]
   
rem --- Dimension string templates

    dim sfe01a$:templates$[1]
    dim ope01a$:templates$[2]
    dim ope11a$:templates$[3]

rem --- get data

    ar_type$=ope01a.ar_type$
    
    rem --- All non-closed WOs
    wo_status$=""
    if pos(wo_include_type$="G") then wo_status$=wo_status$+"OPQ"
        
    rem --- Open / Open and Planned / Open and Quotes / Open and Closed
    if pos(wo_include_type$="ADFI") then wo_status$=wo_status$+"O"

    rem --- Planned / Open and Planned / Planned and Quotes
    if pos(wo_include_type$="BDE") then wo_status$=wo_status$+"P"

    rem --- Quotes / Open and Quotes / Planned and Quotes
    if pos(wo_include_type$="CEF") then wo_status$=wo_status$+"Q"
    
    rem --- Closed / Open and Closed
    wo_status$=""
    if pos(wo_include_type$="HI") then wo_status$=wo_status$+"C"
    
    rem --- All WOs
    if pos(wo_include_type$="J") then wo_status$=wo_status$+"COPQ"

    rem --- Get WOs linked to SOs
    got_at_least_one=0  
    read (sfe01a_dev,key=firm_id$,dom=*next)
    while 1
        readrecord(sfe01a_dev,end=*break)sfe01a$
        if sfe01a.firm_id$<>firm_id$ then break
        if sfe01a.customer_id$="" or sfe01a.order_no$="" or sfe01a.sls_ord_seq_ref$="" then continue
        if pos(sfe01a.wo_status$=wo_status$)=0 then continue

        rem --- Get SO linked to this WO
        found_ope01a_rec=0
        read(ope01a_dev,key=firm_id$+ar_type$+sfe01a.customer_id$+sfe01a.order_no$,dom=*next)
        while 1
            ope01a_key$=key(ope01a_dev,end=*break)
            if pos(firm_id$+ar_type$+sfe01a.customer_id$+sfe01a.order_no$=ope01a_key$)<>1 then break
            readrecord(ope01a_dev)ope01a$
            if pos(ope01a.trans_status$="ER")=0 then continue
            if ope01a.ordinv_flag$<>"O" then continue; rem --- Exclude invoices
            found_ope01a_rec=1
            break; rem --- new order can have at most just one new invoice, if any
        wend
        if !found_ope01a_rec then continue

        switch pos(so_include_type$="ABCDEFG")
            case 1; rem --- A = Sales (Open) SOs only
                if ope01a.invoice_type$<>"S" then continue
                break
            case 2; rem --- B = Backorders only
                if ope01a.backord_flag$<>"B" then continue
                break
            case 3; rem --- C = Quoted SOs only
                if ope01a.invoice_type$<>"P" then continue
                break
            case 4; rem --- D = Sales and Backorders SOs
                if ope01a.invoice_type$<>"S" and ope01a.backord_flag$<>"B" then continue
                break
            case 5; rem --- E = Backorders and Quotes SOs
                if ope01a.invoice_type$<>"P" and ope01a.backord_flag$<>"B" then continue
                break
            case 6; rem --- F = Sales and Quotes (no B/Os)
                if ope01a.backord_flag$="B" then continue
                break
            case 7; rem --- G = All uninvoiced (sales, B/Os and quotes)
                break
            case default
                continue
        swend

        readrecord(ope11a_dev,key=ope01a_key$+sfe01a.sls_ord_seq_ref$,dom=*continue)ope11a$
        if pos(ope11a.trans_status$="ER")=0 then continue

        data! = rs!.getEmptyRecordData()
        data!.setFieldValue("WO",sfe01a.wo_no$)
        data!.setFieldValue("WO_Stat",sfe01a.wo_status$)
        if cvs(sfe01a.estcmp_date$,2)=""
            data!.setFieldValue("Est_Cmplt","-None-")       
        else
            data!.setFieldValue("Est_Cmplt",fndate$(sfe01a.estcmp_date$))     
        endif
        data!.setFieldValue("Item",sfe01a.item_id$)
        data!.setFieldValue("Quantity",str(sfe01a.sch_prod_qty))
        data!.setFieldValue("SO",ope01a.order_no$)
        if ope01a.backord_flag$="B" then
            so_status$=ope01a.backord_flag$
        else
            so_status$=ope01a.invoice_type$
        endif
        if so_status$="P"
            data!.setFieldValue("SO_Stat","Q"); rem For clarity/consistency in grid change P (proforma) to Q (quote)
        else
            data!.setFieldValue("SO_Stat",so_status$)
        endif
        if cvs(ope11a.est_shp_date$,2)<>"" then
            shipdate$=ope11a.est_shp_date$
        else
            shipdate$=ope01a.shipmnt_date$
        endif
        if cvs(shipdate$,2)=""
            data!.setFieldValue("Est_Ship","-None-")
        else
            data!.setFieldValue("Est_Ship",fndate$(shipdate$))     
        endif
        rs!.insert(data!)
        got_at_least_one=1  
    wend

    if !got_at_least_one
        data! = rs!.getEmptyRecordData()
        data!.setFieldValue("WO","-None-")
        data!.setFieldValue("Est_Cmplt","-None-")
        data!.setFieldValue("SO","-None-")
        data!.setFieldValue("Est_SHIP","-None-")
        rs!.insert(data!)       
    endif   
    
rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit

rem --- Functions

    def fndate$(q$)
        q1$=""
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
