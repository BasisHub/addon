rem ----------------------------------------------------------------------------
rem --- OP Pick List (or Quotation) Printing
rem --- Program: OPPICKLIST_DET.prc 

rem --- Copyright BASIS International Ltd.
rem --- All Rights Reserved

rem --- This SPROC is called from the OPPickListDet Jasper report as the detail/subreport from OPPickListHdr

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
	firm_id$ =       sp!.getParameter("FIRM_ID")
	ar_type$ =       sp!.getParameter("AR_TYPE")
	customer_id$ =   sp!.getParameter("CUSTOMER_ID")
	order_no$ =      sp!.getParameter("ORDER_NO")
    ar_inv_no$ =     sp!.getParameter("AR_INV_NO")
	qty_mask$ =      sp!.getParameter("QTY_MASK")
	price_mask$ =    sp!.getParameter("PRICE_MASK")
	selected_whse$ = sp!.getParameter("SELECTED_WHSE")
    pick_or_quote$ = sp!.getParameter("PICK_OR_QUOTE")
    print_prices$ =  sp!.getParameter("PRINT_PRICES")
    mult_wh$ =       sp!.getParameter("MULT_WH")
	barista_wd$ =    sp!.getParameter("BARISTA_WD")

	chdir barista_wd$

rem --- create the in memory recordset for return
	dataTemplate$ = ""
	dataTemplate$ = dataTemplate$ + "order_qty_masked:c(1*), ship_qty:c(1*), bo_qty:c(1*), "
	dataTemplate$ = dataTemplate$ + "item_id:c(1*), item_desc:c(1*), whse:c(2*), "
	dataTemplate$ = dataTemplate$ + "price_raw:c(1*), price_masked:c(1*), "
	dataTemplate$ = dataTemplate$ + "location:c(1*),internal_seq_no:c(1*), "
	dataTemplate$ = dataTemplate$ + "item_is_ls:c(1), linetype_allows_ls:c(1), carton:c(1*), "
    dataTemplate$ = dataTemplate$ + "whse_message:c(1*), whse_msg_sfx:c(1*)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)
	
rem --- Initializationas
	
rem --- Open Files    
rem --- Note 'files' and 'channels[]' are used in close loop, so don't re-use

    files=4,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]    

    files$[1]="ivm-01",      ids$[1]="IVM_ITEMMAST"
    files$[2]="opt-11",      ids$[2]="OPE_INVDET"
    files$[3]="opm-02",      ids$[3]="OPC_LINECODE"
    files$[4]="ivm-02",      ids$[4]="IVM_ITEMWHSE"

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
    ivm02_dev   = channels[4]
    
    dim ivm01a$:templates$[1]
    dim ope11a$:templates$[2]
    dim opm02a$:templates$[3]
    dim ivm02a$:templates$[4]

rem --- Main

    read (ope11_dev, key=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$, knum="AO_STAT_CUST_ORD", dom=*next)
	othwhse$=""
    whse_len=0

    rem --- Detail lines

        while 1
				
			order_qty_masked$ =   ""
            ship_qty$ =           ""
            bo_qty$ =             ""
			item_id$ =            ""
			item_desc$ =          ""
			whse$ =               ""
			price_raw$ =          ""
			price_masked$ =       ""
            carton$ =             ""
			location$ =           ""
			internal_seq_no$ =    ""
			linetype_allows_ls$ = "N"
			item_is_ls$ =         "N"
            whse_message$ =       ""
            whse_msg_sfx$ =       ""
			
            read record (ope11_dev, end=*break) ope11a$

            if firm_id$     <> ope11a.firm_id$     then break
			if ar_type$     <> ope11a.ar_type$     then break
            if customer_id$ <> ope11a.customer_id$ then break
            if order_no$    <> ope11a.order_no$    then break
            if ar_inv_no$   <> ope11a.ar_inv_no$   then break

			internal_seq_no$ = ope11a.internal_seq_no$
            if !whse_len then whse_len=len(ope11a.warehouse_id$);rem store len of wh field on first detail read for later use in warehouse message routine (to avoid hard-coding '2')
		
        rem --- Type
		
            dim opm02a$:fattr(opm02a$)
            dim ivm01a$:fattr(ivm01a$)
            item_description$ = "Item not found"
            start_block = 1
			
            if start_block then
                find record (opm02_dev, key=firm_id$+ope11a.line_code$, dom=*endif) opm02a$
                ivm01a.item_desc$ = ope11a.item_id$
                
                if pos(pick_or_quote$="P")<>0 or ope11a.commit_flag$<>"N" and pos(ope11a.warehouse_id$=othwhse$)=0 
                    othwhse$=othwhse$+ope11a.warehouse_id$
                endif
                
                if pos(pick_or_quote$="S") and selected_whse$<>"" and ope11a.warehouse_id$<>selected_whse$ then continue
            endif

            if pos(opm02a.line_type$=" SP") then
				if pos(pick_or_quote$="S") then linetype_allows_ls$ = "Y"
                find record (ivm01_dev, key=firm_id$+ope11a.item_id$, dom=*next) ivm01a$
                item_description$ = func.displayDesc(ivm01a.item_desc$)
				if pos(pick_or_quote$="S") then item_is_ls$ = ivm01a.lotser_item$
                find record (ivm02_dev,key=firm_id$+ope11a.warehouse_id$+ope11a.item_id$,dom=*next) ivm02a$
			endif

            if opm02a.line_type$="M" and pos(opm02a.message_type$="BO ")=0 then continue

line_detail: rem --- Item Detail

			if pos(opm02a.line_type$="MO")=0 then
				order_qty_masked$= str(ope11a.qty_ordered:qty_mask$)
				if ope11a.commit_flag$="N"
                    ship_qty$=func.formatDate(ope11a.est_shp_date$)
                else
                    ship_qty$=""
                    bo_qty$=""
                endif
                carton$=""
			endif

			if pos(opm02a.line_type$="MNO") then
				item_id$= ope11a.order_memo$
			endif

			if pos(opm02a.line_type$=" SRDP") then 
				item_id$= ope11a.item_id$
			endif

			if pos(opm02a.line_type$=" SRDNPO") and print_prices$="Y" 
				price_raw$=   str(ope11a.unit_price*ope11a.qty_ordered)
				price_masked$=str(num(price_raw$):price_mask$)
			endif

            if pick_or_quote$<>"P"
                if pos(opm02a.line_type$=" SRDNP") and mult_wh$ = "Y" then 
                    whse$ = ope11a.warehouse_id$
                else
                    whse$ = ""
                endif
			        
                if opm02a.dropship$="Y"
                    location$ = "*Dropship"				
                else   
                    if pos(opm02a.line_type$=" SRDP")<>0
                        location$ = ivm02a.location$
                    endif
                endif  
            endif

			if pos(opm02a.line_type$="SP") then
				item_desc$= item_description$
			endif

			data! = rs!.getEmptyRecordData()
			data!.setFieldValue("ORDER_QTY_MASKED", order_qty_masked$)
			data!.setFieldValue("SHIP_QTY", ship_qty$)
			data!.setFieldValue("BO_QTY", bo_qty$)
			data!.setFieldValue("ITEM_ID", item_id$)
			data!.setFieldValue("ITEM_DESC", item_desc$)
			data!.setFieldValue("WHSE", whse$)
            data!.setFieldValue("LOCATION",location$)
			data!.setFieldValue("PRICE_RAW", price_raw$)
			data!.setFieldValue("PRICE_MASKED", price_masked$)
            data!.setFieldValue("CARTON",carton$)
			data!.setFieldValue("INTERNAL_SEQ_NO",internal_seq_no$)
			data!.setFieldValue("ITEM_IS_LS",item_is_ls$)
			data!.setFieldValue("LINETYPE_ALLOWS_LS",linetype_allows_ls$)
            data!.setFieldValue("WHSE_MESSAGE",whse_message$)
            data!.setFieldValue("WHSE_MSG_SFX",whse_msg_sfx$)

			rs!.insert(data!)		

        rem --- End of detail lines

        wend

rem --- Determine the warehouse message to send back to header report

    whse_message$=iff(pick_or_quote$="P","no_message_for_quotes","")
    whse_msg_sfx$=""
    
    if mult_wh$="Y" and pick_or_quote$<>"P"
        
        sel_whse=pos(selected_whse$=othwhse$,whse_len)

        if sel_whse>0
            othwhse$=othwhse$(1,sel_whse-1)+othwhse$(sel_whse+whse_len)
        endif

        if selected_whse$="" and len(othwhse$)>whse_len
            whse_message$="AON_ALL_FROM_THESE_WHSES"
        else
            if selected_whse$="" or (selected_whse$<>"" and othwhse$="")
                whse_message$="AON_ALL_FROM_THIS_WHSE"
            else
                whse_message$="AON_PORTIONS_FROM_WHSES"
                while len(othwhse$)
                    whse_msg_sfx$=whse_msg_sfx$+othwhse$(1,whse_len)+", "
                    othwhse$=othwhse$(whse_len+1)                    
                wend
                whse_msg_sfx$=whse_msg_sfx$(1,len(whse_msg_sfx$)-2)+".";rem strip trailing comma and add period
             endif
        endif
    endif

rem --- return a final row that's empty except for the whse_message$, which will get passed back to the main report

    data! = rs!.getEmptyRecordData()
    data!.setFieldValue("ORDER_QTY_MASKED", "")
    data!.setFieldValue("SHIP_QTY", "")
    data!.setFieldValue("BO_QTY", "")
    data!.setFieldValue("ITEM_ID", "")
    data!.setFieldValue("ITEM_DESC", "")
    data!.setFieldValue("WHSE", whse$)
    data!.setFieldValue("LOCATION","")
    data!.setFieldValue("PRICE_RAW", "")
    data!.setFieldValue("PRICE_MASKED", "")
    data!.setFieldValue("CARTON","")
    data!.setFieldValue("INTERNAL_SEQ_NO","")
    data!.setFieldValue("ITEM_IS_LS","")
    data!.setFieldValue("LINETYPE_ALLOWS_LS","")
    data!.setFieldValue("WHSE_MESSAGE",whse_message$);rem whse_message$ contains key to prop file and gets translated back in main report using str() function
    data!.setFieldValue("WHSE_MSG_SFX",whse_msg_sfx$)
    
	rs!.insert(data!)    

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
