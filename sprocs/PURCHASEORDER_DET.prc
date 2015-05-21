rem ----------------------------------------------------------------------------
rem --- Purchase Order
rem --- Program: PURCHASEORDER_DET.prc 

rem --- Copyright BASIS International Ltd.  All Rights Reserved.

rem --- 4/2015 ------------------------
rem --- Replaced BBjForm-based PO Print with Jasper-based

rem --- por_poprint.aon is used to drive both on-demand and batch PO print

rem --- There are two sprocs/.jaspers for this document:
rem ---    - PURCHASEORDER_HDR.prc / PurchaseOrderHdr.jasper
rem ---    - PURCHASEORDER_DET.prc / PurchaseOrderDet.jasper

rem ----------------------------------------------------------------------------

	seterr sproc_error

rem --- Use statements and Declares

	use ::ado_func.src::func

	declare BBjStoredProcedureData sp!
	declare BBjRecordSet rs!
	declare BBjRecordData data!    

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get 'IN' SPROC parameters 
	firm_id$=sp!.getParameter("FIRM_ID")
	po_no$=sp!.getParameter("PO_NO")
    vendor_id$=sp!.getParameter("VENDOR_ID")
	qty_mask$=sp!.getParameter("QTY_MASK")
	cost_mask$=sp!.getParameter("COST_MASK")
	ext_mask$=sp!.getParameter("EXT_MASK")
    iv_precision$=sp!.getParameter("IV_PRECISION")
    prt_vdr_item$=sp!.getParameter("PRT_VDR_ITEM")
    hdr_msg_code$=sp!.getParameter("HDR_MSG_CODE")
    hdr_ship_from$=sp!.getParameter("HDR_SHIP_FROM")
    nof_prompt$=sp!.getParameter("NOF_PROMPT")
    vend_item_prompt$=sp!.getParameter("VEND_ITEM_PROMPT")
    promise_prompt$=sp!.getParameter("PROMISE_PROMPT")
    not_b4_prompt$=sp!.getParameter("NOT_B4_PROMPT")
    shipfrom_prompt$=sp!.getParameter("SHIPFROM_PROMPT")
	barista_wd$=sp!.getParameter("BARISTA_WD")

	chdir barista_wd$

rem --- create the in-memory recordset for return

	dataTemplate$ = ""
	dataTemplate$ = dataTemplate$ + "QTY_ORDERED:c(1*), ITEM_ID_DESC_MSG:c(1*), REQD_DATE:c(1*), "
	dataTemplate$ = dataTemplate$ + "UNIT_COST:c(1*), UNIT_MEASURE:c(1*), EXTENSION:c(1*), "
	dataTemplate$ = dataTemplate$ + "TOTAL:c(1*)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)
	
rem --- Initializationas
	
rem --- Open Files    
rem --- Note 'files' and 'channels[]' are used in close loop, so don't re-use

    files=7,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]    

    files$[1]="poe-12",ids$[1]="POE_PODET"
    files$[2]="pom-04",ids$[2]="POC_MSGCODE"
    files$[3]="pom-14",ids$[3]="POC_MSGLINE"
    files$[4]="pom-02",ids$[4]="POC_LINECODE"
    files$[5]="ivm-01",ids$[5]="IVM_ITEMMAST"
    files$[6]="ivm-05",ids$[6]="IVM_ITEMVEND"
    files$[7]="apm-05",ids$[7]="APM_VENDADDR"

	call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status

    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif
    
	files_opened = files; rem used in loop to close files

    poe_podet=channels[1]
    poc_msgcode=channels[2]
    poc_msgline=channels[3]
    poc_linecode=channels[4]
    ivm_itemmast=channels[5]
    ivm_itemvend=channels[6]
    apm_vendaddr=channels[7]
    
    dim poe_podet$:templates$[1]
    dim poc_msgcode$:templates$[2]
    dim poc_msgline$:templates$[3]
    dim poc_linecode$:templates$[4]
    dim ivm_itemmast$:templates$[5]
    dim ivm_itemvend$:templates$[6]
    dim apm_vendaddr$:templates$[7]
	
rem --- Main

    read (poe_podet,key=firm_id$+po_no$,dom=*next)
    precision num(iv_precision$)
    total=0
    
    while 1
    
        readrecord (poe_podet,end=*break) poe_podet$
        if pos(firm_id$+po_no$=poe_podet$)<>1 then break
        
        qty=poe_podet.qty_ordered-poe_podet.qty_received
        
        find record (poc_linecode,key=firm_id$+poe_podet.po_line_code$,dom=*next) poc_linecode$
        if poc_linecode.line_type$="O" then qty=1

        precision 2
        let extension=poe_podet.unit_cost*qty
        precision num(iv_precision$)
        total=total+extension

        action=pos(poc_linecode.line_type$="SNVMO")
        std_line=1
        nonstock_line=2
        vend_part_num=3
        message_line=4
        other_line=5

        switch action
        case std_line;   rem --- Standard Line

            dim ivm_itemmast$:fattr(ivm_itemmast$)
            ivm_itemmast.item_desc$=nof_prompt$
            find record (ivm_itemmast,key=firm_id$+poe_podet.item_id$,dom=*next) ivm_itemmast$
                        
			qty_ordered$=str(qty:qty_mask$)
			item_id_desc_msg$=ivm_itemmast.item_id$;rem --- this field will contain the item id OR the description OR vendor part/address/message text, depending on the line
			reqd_date$=func.formatDate(poe_podet.reqd_date$)
			unit_cost$=str(poe_podet.unit_cost:cost_mask$)
			unit_measure$=poe_podet.unit_measure$
			extension$=str(extension:ext_mask$)
            gosub add_to_recordset
            
            item_id_desc_msg$=func.displayDesc(ivm_itemmast.item_desc$)
            gosub add_to_recordset

            if prt_vdr_item$="Y"
                dim ivm_itemvend$:fattr(ivm_itemvend$)
                find record (ivm_itemvend,key=firm_id$+vendor_id$+ivm_itemmast.item_id$,dom=*next) ivm_itemvend$
                if cvs(ivm_itemvend.vendor_item$,3)<>""
                    item_id_desc_msg$=vend_item_prompt$+ivm_itemvend.vendor_item$
                    gosub add_to_recordset
                endif
            endif

            break

        case nonstock_line; rem --- Non-Stock Line

            qty_ordered$=str(qty:qty_mask$)
            item_id_desc_msg$=poe_podet.ns_item_id$
            reqd_date$=func.formatDate(poe_podet.reqd_date$)
			unit_cost$=str(poe_podet.unit_cost:cost_mask$)
			unit_measure$=poe_podet.unit_measure$
			extension$=str(extension:ext_mask$)
            gosub add_to_recordset

            item_id_desc_msg$=poe_podet.order_memo$
            gosub add_to_recordset
            
            break

        case vend_part_num; rem --- Vendor Part Number
        
            item_id_desc_msg$=vend_item_prompt$+poe_podet.order_memo$)
            gosub add_to_recordset
                
            break

        case message_line; rem --- Message Line

            item_id_desc_msg$=poe_podet.order_memo$)
            gosub add_to_recordset
                                
            break

        case other_line; rem --- Other Line
        
            item_id_desc_msg$=poe_podet.order_memo$)
            reqd_date$=func.formatDate(poe_podet.reqd_date$)            
            unit_cost$=str(poe_podet.unit_cost:cost_mask$)
            extension$=str(extension:ext_mask$)
            gosub add_to_recordset
            
            break

        case default
            return
            break

    swend

rem --- Date Promised or Not Before Date?

    if pos(poc_linecode.line_type$="VM")=0
        tmp1$=""
        tmp2$=""
        if cvs(poe_podet.promise_date$,2)<>""
            tmp1$=promise_prompt$+func.formatDate(poe_podet.promise_date$)
        endif
        if cvs(poe_podet.not_b4_date$,2)<>""
            tmp2$=not_b4_prompt$+func.formatDate(poe_podet.not_b4_date$)
        endif
        item_id_desc_msg$=tmp1$+" "+tmp2$
        if cvs(item_id_desc_msg$,2)<>"" then gosub add_to_recordset
    endif

rem --- Detail line message code

    if cvs(poe_podet.po_msg_code$,2)<>""

        msg_cd$ = poe_podet.po_msg_code$
        gosub process_messages

    endif

    wend

rem --- Done with line item or line messages, wrap up with header level message and/or ship from

    if cvs(hdr_msg_code$,2)<>""
    
        item_id_desc_msg$=""
        gosub add_to_recordset;rem add blank line before header message
    
        msg_cd$=hdr_msg_code$
        gosub process_messages
    
    endif

    if cvs(hdr_ship_from$,2)<>""

        item_id_desc_msg$=""
        gosub add_to_recordset;rem add blank line before shipfrom
    
        shipfrom_addrLines=4
        shipfrom_addrLine_len=30
        dim shipfrom$(shipfrom_addrLines*shipfrom_addrLine_len)
        
        find record (apm_vendaddr,key=firm_id$+vendor_id$+hdr_ship_from$,dom=*next) apm_vendaddr$

        temp_addr$= apm_vendaddr.addr_line_1$ + apm_vendaddr.addr_line_2$ + apm_vendaddr.city$ + apm_vendaddr.state_code$ + apm_vendaddr.zip_code$
        call pgmdir$+"adc_address.aon",temp_addr$,24,3,9,shipfrom_addrLine_len
        shipfrom$(1,shipfrom_addrLine_len)=shipfrom_prompt$+apm_vendaddr.name$
        shipfrom$(shipfrom_addrLine_len+1)=temp_addr$
        
        for x=0 to shipfrom_addrLines-1
            item_id_desc_msg$=shipfrom$(x*shipfrom_addrLine_len+1,shipfrom_addrLine_len)
            gosub add_to_recordset
        next x
    
    endif

rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)

	goto std_exit

add_to_recordset:

    total$=str(total:ext_mask$)

    data! = rs!.getEmptyRecordData()
    data!.setFieldValue("QTY_ORDERED",qty_ordered$)
    data!.setFieldValue("ITEM_ID_DESC_MSG",item_id_desc_msg$)
    data!.setFieldValue("REQD_DATE",reqd_date$)
    data!.setFieldValue("UNIT_COST",unit_cost$)
    data!.setFieldValue("UNIT_MEASURE",unit_measure$)
    data!.setFieldValue("EXTENSION",extension$)
    data!.setFieldValue("TOTAL",total$)

    rs!.insert(data!)

    qty_ordered$=""
    item_id_desc_msg$=""
    reqd_date$=""
    unit_cost$=""
    unit_measure$=""
    extension$=""

    return

process_messages:rem --- Header or Detail level message codes

    find record (poc_msgcode,key=firm_id$+msg_cd$,dom=*return) poc_msgcode$
    rem --- if type isn't Both or POs, skip it (other types R=requisition, N=none)
    if pos(poc_msgcode.message_type$ = "BP")<>0
        read (poc_msgline,key=poc_msgcode.firm_id$+poc_msgcode.po_msg_code$,dom=*next)

        while 1
            read record (poc_msgline,end=*break) poc_msgline$         
            if pos(poc_msgcode.firm_id$+poc_msgcode.po_msg_code$=poc_msgline$)<>1 then break
            item_id_desc_msg$ = poc_msgline.message_text$
            gosub add_to_recordset
        wend

    endif
    
    return
	
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
