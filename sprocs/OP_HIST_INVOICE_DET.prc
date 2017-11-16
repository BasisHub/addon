rem ----------------------------------------------------------------------------
rem --- OP Invoice Printing
rem --- Program: OP_HIST_INVOICE_DET.prc
rem --- Description: Stored Procedure to create detail for a jasper-based OP invoice 
 
rem --- Copyright BASIS International Ltd.  All Rights Reserved.

rem --- 12/2014-----------------------
rem --- Based on OP_INVOICE.prc, but uses "U" trans_status
rem --- used to print historical invoice from Invoice History Inquiry form

rem --- There are three sprocs and three .jaspers for this enhancement:
rem ---    - OP_HIST_INVOICE_HDR.prc / OPHistInvoiceHdr.jasper
rem ---    - OP_HIST_INVOICE_DET.prc / OPHistInvoiceDet.jasper
rem ---    - OP_HIST_INVOICE_DET_LOTSER.prc / OPHistInvoiceDet-LotSer.jasper
rem -----------------------------------

rem ----------------------------------------------------------------------------

	seterr sproc_error

rem --- Use statements and Declares

	declare BBjStoredProcedureData sp!
	declare BBjRecordSet rs!
	declare BBjRecordData data!

	use ::ado_func.src::func

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get 'IN' SPROC parameters 
	firm_id$ =     sp!.getParameter("FIRM_ID")
	ar_type$ =     sp!.getParameter("AR_TYPE")
	customer_id$ = sp!.getParameter("CUSTOMER_ID")
	order_no$ =    sp!.getParameter("ORDER_NO")
	ar_inv_no$ =   sp!.getParameter("AR_INV_NO")
	qty_mask$ =    sp!.getParameter("QTY_MASK")
	amt_mask$ =    sp!.getParameter("AMT_MASK")
	price_mask$ =  sp!.getParameter("PRICE_MASK")
	ext_mask$ =    sp!.getParameter("EXT_MASK")
	barista_wd$ =  sp!.getParameter("BARISTA_WD")

	chdir barista_wd$

rem --- create the in memory recordset for return
	dataTemplate$ = ""
	dataTemplate$ = dataTemplate$ + "order_qty_masked:c(1*), ship_qty_masked:c(1*), backord_qty_masked:c(1*), "
	dataTemplate$ = dataTemplate$ + "item_id:c(1*), item_desc:c(1*), um:c(1*), "
	dataTemplate$ = dataTemplate$ + "price_raw:c(1*), price_masked:c(1*), "
	dataTemplate$ = dataTemplate$ + "extended_raw:c(1*), extended_masked:c(1*), internal_seq_no:c(1*), "
	dataTemplate$ = dataTemplate$ + "item_is_ls:c(1), linetype_allows_ls:c(1),ship_qty:c(1*)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)
	
rem --- Initializationas
	
rem --- Open Files    
rem --- Note 'files' and 'channels[]' are used in close loop, so don't re-use

    files=3,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]    

    files$[1]="ivm-01",      ids$[1]="IVM_ITEMMAST"
    files$[2]="opt-11",      ids$[2]="OPE_INVDET"
    files$[3]="opm-02",      ids$[3]="OPC_LINECODE"

	call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status

    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif
    
	files_opened = files; rem used in loop to close files

    ivm01_dev   = channels[1]
    ope11_dev   = channels[2]
    opm02_dev   = channels[3]
    
    dim ivm01a$:templates$[1]
    dim ope11a$:templates$[2]
    dim opm02a$:templates$[3]
	
rem --- Main

    read (ope11_dev, key=firm_id$+"U"+ar_type$+customer_id$+order_no$+ar_inv_no$, knum="AO_STAT_CUST_ORD", dom=*next)
	
    rem --- Detail lines

        while 1
				
			order_qty_masked$ =   ""
			ship_qty_masked$ =    ""
			ship_qty$ =           ""
			backord_qty_masked$ = ""
			item_id$ =            ""
			item_desc$ =          ""
			lotser_no$ =          ""
			um$ =                 ""
			price_raw$ =          ""
			price_masked$ =       ""
			ext_raw$ =            ""
			ext_masked$ =         ""
			internal_seq_no$ =    ""

			linetype_allows_ls$ = "N"
			item_is_ls$ =         "N"	
			
            read record (ope11_dev, end=*break) ope11a$

            if firm_id$     <> ope11a.firm_id$     then break
			if ar_type$     <> ope11a.ar_type$     then break
            if customer_id$ <> ope11a.customer_id$ then break
            if order_no$    <> ope11a.order_no$    then break
            if ar_inv_no$    <> ope11a.ar_inv_no$    then break
			internal_seq_no$ = ope11a.internal_seq_no$

        rem --- Type
		
            dim opm02a$:fattr(opm02a$)
            dim ivm01a$:fattr(ivm01a$)
            item_description$ = "Item not found"
            start_block = 1
			
            if start_block then
                find record (opm02_dev, key=firm_id$+ope11a.line_code$, dom=*endif) opm02a$
                ivm01a.item_desc$ = ope11a.item_id$
            endif

            if pos(opm02a.line_type$=" SP") then
				linetype_allows_ls$ = "Y"
                find record (ivm01_dev, key=firm_id$+ope11a.item_id$, dom=*next) ivm01a$
                item_description$ = func.displayDesc(ivm01a.item_desc$)
				item_is_ls$ = ivm01a.lotser_item$
			endif

            if opm02a.line_type$="M" and pos(opm02a.message_type$="BI ")=0 then continue

line_detail: rem --- Item Detail

			if pos(opm02a.line_type$="MO")=0 then
				order_qty_masked$= str(ope11a.qty_ordered:qty_mask$)
				ship_qty_masked$= str(ope11a.qty_shipped:qty_mask$)
				ship_qty$= str(ope11a.qty_shipped)
				backord_qty_masked$= str(ope11a.qty_backord:qty_mask$)
			endif

			if pos(opm02a.line_type$="MNO") then
                item_desc$=cvs(ope11a.memo_1024$,3)
			endif

			if pos(opm02a.line_type$=" SP") then 
				item_desc$=cvs(ope11a.item_id$,3)
                item_id$=cvs(ope11a.item_id$,3)
			endif

			if pos(opm02a.line_type$=" SNP") then 
				price_raw$=   str(ope11a.unit_price)
				price_masked$=str(ope11a.unit_price:price_mask$)
			endif

			if opm02a.line_type$<>"M" then 
				ext_raw$=   str(ope11a.ext_price)
				ext_masked$=str(ope11a.ext_price:ext_mask$)
			endif

			if opm02a.line_type$="S" then 
				um$= ivm01a.unit_of_sale$
			endif

			if pos(opm02a.line_type$="SP") then
				item_desc$=item_desc$+" "+cvs(item_description$,3)+iff(cvs(ope11a.memo_1024$,3)="",""," - "+cvs(ope11a.memo_1024$,3))
			endif

            if item_desc$(len(item_desc$),1)=$0A$ then item_desc$=item_desc$(1,len(item_desc$)-1)

			data! = rs!.getEmptyRecordData()
			data!.setFieldValue("ORDER_QTY_MASKED", order_qty_masked$)
			data!.setFieldValue("SHIP_QTY_MASKED", ship_qty_masked$)
			data!.setFieldValue("SHIP_QTY", ship_qty$)
			data!.setFieldValue("BACKORD_QTY_MASKED", backord_qty_masked$)
			data!.setFieldValue("ITEM_ID", item_id$)
			data!.setFieldValue("ITEM_DESC", item_desc$)
			data!.setFieldValue("UM", um$)
			data!.setFieldValue("PRICE_RAW", price_raw$)
			data!.setFieldValue("PRICE_MASKED", price_masked$)
			data!.setFieldValue("EXTENDED_RAW", ext_raw$)
			data!.setFieldValue("EXTENDED_MASKED", ext_masked$)
			data!.setFieldValue("INTERNAL_SEQ_NO",internal_seq_no$)
			data!.setFieldValue("ITEM_IS_LS",item_is_ls$)
			data!.setFieldValue("LINETYPE_ALLOWS_LS",linetype_allows_ls$)

			rs!.insert(data!)		

        rem --- End of detail lines

        wend

rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)

	goto std_exit
	
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
