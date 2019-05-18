rem ----------------------------------------------------------------------------
rem --- Purchase Requisition Header
rem --- Program: PURCHASEREQUISITION_HDR.prc 

rem --- Copyright BASIS International Ltd.  All Rights Reserved.

rem --- 2/2016 ------------------------
rem --- Replaced BBjForm-based Req Print with Jasper-based

rem --- por_reqprint.aon is used to drive both on-demand and batch Req print

rem --- There are two sprocs/.jaspers for this document:
rem ---    - PURCHASEREQUISITION_HDR.prc / PurchaseRequisitionHdr.jasper
rem ---    - PURCHASEREQUISITION_DET.prc / PurchaseRequisitionDet.jasper

rem ----------------------------------------------------------------------------

    seterr sproc_error

    declare BBjStoredProcedureData sp!
    declare BBjRecordSet rs!
    declare BBjRecordData data!

rem --- Get the infomation object for the Stored Procedure
    sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- get SPROC parameters

    firm_id$=sp!.getParameter("FIRM_ID")
    req_no$=sp!.getParameter("REQ_NO")
    vend_mask$=sp!.getParameter("VEND_MASK")
    dflt_msg$=sp!.getParameter("DFLT_MSG")
    barista_wd$=sp!.getParameter("BARISTA_WD")

    chdir barista_wd$

rem --- create the in memory recordset for return
rem --- formatted date, vendor address, ship-to (warehouse) address, terms code desc, ship via, FOB, ack by, freight terms

    dataTemplate$ = ""
    dataTemplate$ = dataTemplate$ + "vendor_id:C(6),ord_date:C(10),"
    datatemplate$ = datatemplate$ + "vend_addr_line1:C(30),vend_addr_line2:C(30),vend_addr_line3:C(30),"
    datatemplate$ = datatemplate$ + "vend_addr_line4:C(30),vend_addr_line5:C(30),vend_addr_line6:C(30),"
    datatemplate$ = datatemplate$ + "vend_addr_line7:C(30),"
    datatemplate$ = datatemplate$ + "ship_addr_line1:C(30),ship_addr_line2:C(30),ship_addr_line3:C(30),"
    datatemplate$ = datatemplate$ + "ship_addr_line4:C(30),ship_addr_line5:C(30),ship_addr_line6:C(30),"
    datatemplate$ = datatemplate$ + "ship_addr_line7:C(30),"
    dataTemplate$ = dataTemplate$ + "drop_ship:C(1*),terms_desc:C(1*),ship_via:C(1*),fob:C(1*),"
    dataTemplate$ = dataTemplate$ + "ack_by:C(1*),freight_terms:C(1*),hdr_msg_code:C(1*),hdr_ship_from:C(1*)"

    rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)
   
rem --- Use statements and Declares
	
    use ::ado_func.src::func

rem --- Retrieve the program path

    pgmdir$=""
    pgmdir$=stbl("+DIR_PGM",err=*next)
    sypdir$=""
    sypdir$=stbl("+DIR_SYP",err=*next)

rem --- Open Files    
rem --- Note 'files' and 'channels[]' are used in close loop, so don't re-use

    files=4,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]    

    files$[1]="poe-01",ids$[1]="POE_REQHDR"
    files$[2]="apm-01",ids$[2]="APM_VENDMAST"
    files$[3]="ivc_whsecode",ids$[3]="IVC_WHSECODE"
    files$[4]="apc_termscode",ids$[4]="APC_TERMSCODE"

	call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status

    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif
    
	files_opened = files; rem used in loop to close files
	
    poe_reqhdr = channels[1] 
    apm_vendmast = channels[2]    
    ivc_whsecode = channels[3]
    apc_termscode = channels[4]
	
    dim poe_reqhdr$:templates$[1]
    dim apm_vendmast$:templates$[2]
    dim ivc_whsecode$:templates$[3]
    dim apc_termscode$:templates$[4]
	
rem --- Initialize Data

	max_vendAddr_lines = 7
	vend_addrLine_len = 30
	dim vend_addr$(max_vendAddr_lines * vend_addrLine_len)
	
	max_shipAddr_lines = 7
	ship_addrLine_len = 30	
	dim ship_addr$(max_shipAddr_lines * ship_addrLine_len)
	
rem --- Main Read

    find record (poe_reqhdr,key=firm_id$+req_no$,dom=all_done)poe_reqhdr$
    vendor_id$=poe_reqhdr.vendor_id$

rem --- get Vendor address
        
    find record (apm_vendmast,key=firm_id$+vendor_id$,dom=*next)apm_vendmast$
    
    temp_addr$ = apm_vendmast.addr_line_1$ + apm_vendmast.addr_line_2$ + apm_vendmast.city$ + apm_vendmast.state_code$ + apm_vendmast.zip_code$ + apm_vendmast.cntry_id$
    call "adc_address.aon",temp_addr$,24,3,9,vend_addrLine_len
    vend_addr$(1)=apm_vendmast.vendor_name$+temp_addr$

    if cvs(apm_vendmast$,3)="" then
        vend_addr$(1) = pad("Vendor not found", vend_addrLine_len*max_vendAddr_lines)
    endif
        
rem --- get Ship-To address

    if poe_reqhdr.dropship$="Y"
        drop_ship$="Y"
        ship_to$=poe_reqhdr.ds_name$
        temp_addr$=poe_reqhdr.ds_addr_line_1$+poe_reqhdr.ds_addr_line_2$+poe_reqhdr.ds_addr_line_3$+poe_reqhdr.ds_city$+poe_reqhdr.ds_state_cd$+poe_reqhdr.ds_zip_code$
    else
        drop_ship$=""
        find record (ivc_whsecode,key=firm_id$+"C"+poe_reqhdr.warehouse_id$,dom=*next)ivc_whsecode$
        ship_to$=ivc_whsecode.short_name$
        temp_addr$= ivc_whsecode.addr_line_1$ + ivc_whsecode.addr_line_2$ + ivc_whsecode.addr_line_3$ + ivc_whsecode.city$ + ivc_whsecode.state_code$ + ivc_whsecode.zip_code$
    endif
    
    call "adc_address.aon",temp_addr$,24,4,9,ship_addrLine_len
    ship_addr$(1,ship_addrLine_len)=ship_to$
    ship_addr$(ship_addrLine_len+1)=temp_addr$

rem --- get Terms description and message code

    find record (apc_termscode,key=firm_id$+"C"+poe_reqhdr.ap_terms_code$,dom=*next)apc_termscode$
    terms_desc$=apc_termscode.code_desc$
    
    hdr_msg_code$=dflt_msg$
    if cvs(poe_reqhdr.po_msg_code$,2)<>"" then hdr_msg_code$=poe_reqhdr.po_msg_code$

    hdr_ship_from$=poe_reqhdr.purch_addr$
        
all_done:

    ord_date$=func.formatDate(poe_reqhdr.ord_date$)
    vend_id$=func.alphaMask(vendor_id$,vend_mask$)

    data! = rs!.getEmptyRecordData()
    data!.setFieldValue("vendor_id",vend_id$)
    data!.setFieldValue("ord_date",ord_date$)
    data!.setFieldValue("ship_via",poe_reqhdr.ap_ship_via$)
    data!.setFieldValue("fob",poe_reqhdr.fob$)
    data!.setFieldValue("terms_desc",terms_desc$)
    data!.setFieldValue("drop_ship",drop_ship$)
    data!.setFieldValue("ack_by",poe_reqhdr.acknowledge$)
    data!.setFieldValue("freight_terms",poe_reqhdr.po_frt_terms$)
    data!.setFieldValue("hdr_msg_code",hdr_msg_code$)
    data!.setFieldValue("hdr_ship_from",hdr_ship_from$)

    data!.setFieldValue("vend_addr_line1", vend_addr$((vend_addrLine_len*0)+1,vend_addrLine_len))
    data!.setFieldValue("vend_addr_line2", vend_addr$((vend_addrLine_len*1)+1,vend_addrLine_len))
    data!.setFieldValue("vend_addr_line3", vend_addr$((vend_addrLine_len*2)+1,vend_addrLine_len))
    data!.setFieldValue("vend_addr_line4", vend_addr$((vend_addrLine_len*3)+1,vend_addrLine_len))
    data!.setFieldValue("vend_addr_line5", vend_addr$((vend_addrLine_len*4)+1,vend_addrLine_len))
    data!.setFieldValue("vend_addr_line6", vend_addr$((vend_addrLine_len*5)+1,vend_addrLine_len))
    data!.setFieldValue("vend_addr_line7", vend_addr$((vend_addrLine_len*6)+1,vend_addrLine_len))

    data!.setFieldValue("ship_addr_line1", ship_addr$((ship_addrLine_len*0)+1,ship_addrLine_len))
    data!.setFieldValue("ship_addr_line2", ship_addr$((ship_addrLine_len*1)+1,ship_addrLine_len))
    data!.setFieldValue("ship_addr_line3", ship_addr$((ship_addrLine_len*2)+1,ship_addrLine_len))
    data!.setFieldValue("ship_addr_line4", ship_addr$((ship_addrLine_len*3)+1,ship_addrLine_len))
    data!.setFieldValue("ship_addr_line5", ship_addr$((ship_addrLine_len*4)+1,ship_addrLine_len))
    data!.setFieldValue("ship_addr_line6", ship_addr$((ship_addrLine_len*5)+1,ship_addrLine_len))
    data!.setFieldValue("ship_addr_line7", ship_addr$((ship_addrLine_len*6)+1,ship_addrLine_len))

	rs!.insert(data!)

rem Tell the stored procedure to return the result set.
	sp!.setRecordSet(rs!)
    
	goto std_exit

format_address: rem --- Reformat address to bottom justify

	dim tmp_address$(7*line_len)
	y=6*line_len+1
	for x=y to 1 step -line_len
		if cvs(address$(x,line_len),2)<>""
			tmp_address$(y,line_len)=address$(x,line_len)
			y=y-line_len
		endif
	next x
	address$=tmp_address$
	return

rem --- Functions

    def fnline2y%(tmp0)=(tmp0*12)+12+top_of_detail+2


rem #include std_end.src

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num
	
std_exit:

	rem --- Close files
		x = files_opened
		while x>=1
			close (channels[x],err=*next)
			x=x-1
		wend

    end
