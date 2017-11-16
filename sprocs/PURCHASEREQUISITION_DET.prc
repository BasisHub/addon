rem ----------------------------------------------------------------------------
rem --- Purchase Requitision Detail
rem --- Program: PURCHASEREQUISITION_DET.prc 

rem --- Copyright BASIS International Ltd.  All Rights Reserved.

rem --- 2/2016 ------------------------
rem --- Replaced BBjForm-based Req Print with Jasper-based

rem --- por_reqprint.aon is used to drive both on-demand and batch Req print

rem --- There are two sprocs/.jaspers for this document:
rem ---    - PURCHASEREQUISITION_HDR.prc / PurchaseRequisitionHdr.jasper
rem ---    - PURCHASEREQUISITION_DET.prc / PurchaseRequisitionDet.jasper

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
	req_no$=sp!.getParameter("REQ_NO")
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

    files=6,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]    

    files$[1]="poe-11",ids$[1]="POE_REQDET"
    files$[2]="poc_message",ids$[2]="POC_MESSAGE"
    files$[3]="pom-02",ids$[3]="POC_LINECODE"
    files$[4]="ivm-01",ids$[4]="IVM_ITEMMAST"
    files$[5]="ivm-05",ids$[5]="IVM_ITEMVEND"
    files$[6]="apm-05",ids$[6]="APM_VENDADDR"

	call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status

    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif
    
	files_opened = files; rem used in loop to close files

    poe_reqdet=channels[1]
    poc_message=channels[2]
    poc_linecode=channels[3]
    ivm_itemmast=channels[4]
    ivm_itemvend=channels[5]
    apm_vendaddr=channels[6]
    
    dim poe_reqdet$:templates$[1]
    dim poc_message$:templates$[2]
    dim poc_linecode$:templates$[3]
    dim ivm_itemmast$:templates$[4]
    dim ivm_itemvend$:templates$[5]
    dim apm_vendaddr$:templates$[6]
	
rem --- Main

    read (poe_reqdet,key=firm_id$+req_no$,knum="AO_REQ_LINE",dom=*next)
    precision num(iv_precision$)
    total=0
    
    while 1
    
        readrecord (poe_reqdet,end=*break) poe_reqdet$
        if pos(firm_id$+req_no$=poe_reqdet$)<>1 then break
        
        qty=poe_reqdet.req_qty
        
        find record (poc_linecode,key=firm_id$+poe_reqdet.po_line_code$,dom=*next) poc_linecode$
        if poc_linecode.line_type$="O" then qty=1

        precision 2
        let extension=poe_reqdet.unit_cost*qty
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
            find record (ivm_itemmast,key=firm_id$+poe_reqdet.item_id$,dom=*next) ivm_itemmast$
                        
			qty_ordered$=str(qty:qty_mask$)
			item_id_desc_msg$=ivm_itemmast.item_id$;rem --- this field will contain the item id OR the description OR vendor part/address/message text, depending on the line
			reqd_date$=func.formatDate(poe_reqdet.reqd_date$)
			unit_cost$=str(poe_reqdet.unit_cost:cost_mask$)
			unit_measure$=poe_reqdet.unit_measure$
			extension$=str(extension:ext_mask$)
            
            item_id_desc_msg$=cvs(ivm_itemmast.item_id$,3)+" "+func.displayDesc(ivm_itemmast.item_desc$)

            if prt_vdr_item$="Y"
                dim ivm_itemvend$:fattr(ivm_itemvend$)
                find record (ivm_itemvend,key=firm_id$+vendor_id$+ivm_itemmast.item_id$,dom=*next) ivm_itemvend$
                if cvs(ivm_itemvend.vendor_item$,3)<>""
                    item_id_desc_msg$=item_id_desc_msg$+$0A$+vend_item_prompt$+ivm_itemvend.vendor_item$
                endif
            endif
            
            if cvs(poe_reqdet.memo_1024$,3)<>""
                item_id_desc_msg$=item_id_desc_msg$+$0A$+poe_reqdet.memo_1024$
            endif
            gosub add_to_recordset

            break

        case nonstock_line; rem --- Non-Stock Line

            qty_ordered$=str(qty:qty_mask$)
            item_id_desc_msg$=poe_reqdet.ns_item_id$
            reqd_date$=func.formatDate(poe_reqdet.reqd_date$)
			unit_cost$=str(poe_reqdet.unit_cost:cost_mask$)
			unit_measure$=poe_reqdet.unit_measure$
			extension$=str(extension:ext_mask$)

            item_id_desc_msg$=poe_reqdet.memo_1024$
            gosub add_to_recordset
            
            break

        case vend_part_num; rem --- Vendor Part Number
        
            item_id_desc_msg$=vend_item_prompt$+poe_reqdet.memo_1024$
            gosub add_to_recordset
                
            break

        case message_line; rem --- Message Line

            item_id_desc_msg$=poe_reqdet.memo_1024$
            gosub add_to_recordset
                                
            break

        case other_line; rem --- Other Line
        
            item_id_desc_msg$=poe_reqdet.memo_1024$
            reqd_date$=func.formatDate(poe_reqdet.reqd_date$)            
            unit_cost$=str(poe_reqdet.unit_cost:cost_mask$)
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
        if cvs(poe_reqdet.promise_date$,2)<>""
            tmp1$=promise_prompt$+func.formatDate(poe_reqdet.promise_date$)
        endif
        if cvs(poe_reqdet.not_b4_date$,2)<>""
            tmp2$=not_b4_prompt$+func.formatDate(poe_reqdet.not_b4_date$)
        endif
        item_id_desc_msg$=tmp1$+" "+tmp2$
        if cvs(item_id_desc_msg$,2)<>"" then gosub add_to_recordset
    endif

rem --- Detail line message code

    if cvs(poe_reqdet.po_msg_code$,2)<>""
        msg_cd$ = poe_reqdet.po_msg_code$
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
    
    if len(item_id_desc_msg$)
        if item_id_desc_msg$(len(item_id_desc_msg$),1)=$0A$ then item_id_desc_msg$=item_id_desc_msg$(1,len(item_id_desc_msg$)-1)
    endif

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

    find record (poc_message,key=firm_id$+msg_cd$,dom=*return) poc_message$
    rem --- if type isn't Both or Requisitions, skip it (other types P=POs, N=neither)
    if pos(poc_message.message_type$ = "BR")<>0 then item_id_desc_msg$=poc_message.memo_1024$
    gosub add_to_recordset
    
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
