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
    ivIMask$ =       sp!.getParameter("ITEM_MASK")
	selected_whse$ = sp!.getParameter("SELECTED_WHSE")
    pick_or_quote$ = sp!.getParameter("PICK_OR_QUOTE")
    reprint$ =       sp!.getParameter("REPRINT")
    print_prices$ =  sp!.getParameter("PRINT_PRICES")
    mult_wh$ =       sp!.getParameter("MULT_WH")
	barista_wd$ =    sp!.getParameter("BARISTA_WD")
    woInfo_1abels$ = sp!.getParameter("WO_INFO_LABELS")

	chdir barista_wd$

rem --- create the in memory recordset for return
	dataTemplate$ = ""
	dataTemplate$ = dataTemplate$ + "order_qty_masked:c(1*), ship_qty:c(1*), bo_qty:c(1*), "
	dataTemplate$ = dataTemplate$ + "item_id:c(1*), item_desc:c(1*), whse:c(2*), "
	dataTemplate$ = dataTemplate$ + "price_raw:c(1*), price_masked:c(1*), "
	dataTemplate$ = dataTemplate$ + "location:c(1*), internal_seq_no:c(1*), um_sold:c(2*), "
	dataTemplate$ = dataTemplate$ + "item_is_ls:c(1), linetype_allows_ls:c(1), carton:c(1*), "
    dataTemplate$ = dataTemplate$ + "whse_message:c(1*), whse_msg_sfx:c(1*), ship_qty_raw:c(1*), "
    dataTemplate$ = dataTemplate$ + "wo_info1:c(1*), wo_info2:c(1*)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)
	
rem --- Initializations
    sf$="N"
    if cvs(woInfo_1abels$,3)<>"" then sf$="Y"

    dim woInfoLabel$[5]
    index=1
    xpos=pos(";"=woInfo_1abels$)
    while xpos
        woInfoLabel$[index]=woInfo_1abels$(1,xpos-1)
        index=index+1
        woInfo_1abels$=woInfo_1abels$(xpos+1)
        xpos=pos(";"=woInfo_1abels$)
    wend
	
rem --- Open Files    
rem --- Note 'files' and 'channels[]' are used in close loop, so don't re-use

    files=iff(sf$="Y",6,5),begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]    

    files$[1]="ivm-01",      ids$[1]="IVM_ITEMMAST"
    files$[2]="opt-11",      ids$[2]="OPE_INVDET"
    files$[3]="opm-02",      ids$[3]="OPC_LINECODE"
    files$[4]="ivm-02",      ids$[4]="IVM_ITEMWHSE"
    files$[5]="ivs_params",  ids$[5]="IVS_PARAMS"
    if sf$="Y" then files$[6]="sfe-01",ids$[6]="SFE_WOMASTR"

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
    ivsParams_dev=channels[5]
    
    dim ivm01a$:templates$[1]
    dim ope11a$:templates$[2]
    dim opm02a$:templates$[3]
    dim ivm02a$:templates$[4]
    dim ivsParams$:templates$[5]
    
    if sf$="Y" then
        sfe01_dev=channels[6]
        dim sfe01a$:templates$[6]
    endif

rem --- Get IV parameters

    findrecord(ivsParams_dev,key=firm_id$+"IV00",dom=*next)ivsParams$
    
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
            ship_qty_raw$ =       ""
            wo_info1$ =           ""
            wo_info2$ =           ""
            um_sold$ =            ""
            qtyOrdered_purchaseUM = 0
            qtyOrdered_salesUM    = 0
            			
            read record (ope11_dev, end=*break) ope11a$

            if firm_id$     <> ope11a.firm_id$     then break
			if ar_type$     <> ope11a.ar_type$     then break
            if customer_id$ <> ope11a.customer_id$ then break
            if order_no$    <> ope11a.order_no$    then break
            if ar_inv_no$   <> ope11a.ar_inv_no$   then break

			internal_seq_no$ = ope11a.internal_seq_no$
            if !whse_len then whse_len=len(ope11a.warehouse_id$);rem store len of wh field on first detail read for later use in warehouse message routine (to avoid hard-coding '2')

            if reprint$<>"Y" and ope11a.pick_flag$="Y" then continue; rem --- Not a reprint and already printed
            if reprint$="Y" and ope11a.pick_flag$<>"Y" then continue; rem --- A reprint and not printed yet
		
        rem --- Type
		
            dim opm02a$:fattr(opm02a$)
            dim ivm01a$:fattr(ivm01a$)
            item_description$ = "Item not found"
            start_block = 1
			
            if start_block then
                find record (opm02_dev, key=firm_id$+ope11a.line_code$, dom=*endif) opm02a$
                ivm01a.item_desc$ = fnmask$(ope11a.item_id$,ivIMask$)
                
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
                qtyOrdered_salesUM=ope11a.qty_ordered
				order_qty_masked$= str(ope11a.qty_ordered:qty_mask$)
                ship_qty_raw$= str(ope11a.qty_ordered)
				if ope11a.commit_flag$="N"
                    ship_qty$=func.formatDate(ope11a.est_shp_date$)
                else
                    ship_qty$=""
                    bo_qty$=""
                endif
                carton$=""
                if ivsParams.sell_purch_um$="Y" and ivm01a.sell_purch_um$="Y" then
                    rem --- Use Unit of Purchase, and as necessary also use Unit of Sale
                    qtyOrdered_purchaseUM=int(ope11a.qty_ordered/ivm01a.conv_factor)
                    qtyOrdered_salesUM=ope11a.qty_ordered-(qtyOrdered_purchaseUM*ivm01a.conv_factor)
                    if qtyOrdered_purchaseUM then
                        rem --- Use Unit of Purchase
                        order_qty_masked$= str(qtyOrdered_purchaseUM:qty_mask$)
                        ship_qty_raw$= str(qtyOrdered_purchaseUM)
                    endif
                endif
			endif

			if pos(opm02a.line_type$="MNO") then
				item_desc$=cvs(ope11a.memo_1024$,3)
			endif

			if pos(opm02a.line_type$=" SP") then 
				item_desc$=cvs(fnmask$(ope11a.item_id$,ivIMask$),3)
                item_id$=cvs(fnmask$(ope11a.item_id$,ivIMask$),3)
			endif

			if pos(opm02a.line_type$=" SNPO") and print_prices$="Y" 
				price_raw$=   str(ope11a.unit_price*ope11a.qty_ordered)
				price_masked$=str(ope11a.unit_price:price_mask$)
			endif
			if pos(opm02a.line_type$=" SNPO") and print_prices$="Y" then
			    if qtyOrdered_purchaseUM then
                    rem --- Use Unit of Purchase
                    price_raw$=   str(ope11a.unit_price*ivm01a.conv_factor*qtyOrdered_purchaseUM)
                    price_masked$=str(ope11a.unit_price*ivm01a.conv_factor:price_mask$)
			    else
                    rem --- Use Unit of Sale
    				price_raw$=   str(ope11a.unit_price*qtyOrdered_salesUM)
    				price_masked$=str(ope11a.unit_price:price_mask$)
				endif
			endif

            if pick_or_quote$<>"P"
                if pos(opm02a.line_type$=" SNP") and mult_wh$ = "Y" then 
                    whse$ = ope11a.warehouse_id$
                else
                    whse$ = ""
                endif
			        
                if opm02a.dropship$="Y"
                    location$ = "AON_DROPSHIP"				
                else   
                    if pos(opm02a.line_type$=" SP")<>0
                        location$ = ivm02a.location$
                    endif
                endif  
            endif

			if pos(opm02a.line_type$="SP") then
				item_desc$=item_desc$+" "+cvs(item_description$,3)+iff(cvs(ope11a.memo_1024$,3)="",""," - "+cvs(ope11a.memo_1024$,3))
			endif

            if len(item_desc$) then if item_desc$(len(item_desc$),1)=$0A$ then item_desc$=item_desc$(1,len(item_desc$)-1)

            if sf$="Y" then
                redim sfe01a$
                read(sfe01_dev,key=firm_id$+customer_id$+order_no$+ope11a.internal_seq_no$,knum="AO_CST_ORD_LINE",dom=*next)
                readrecord(sfe01_dev,end=*endif)sfe01a$
                if sfe01a.firm_id$+sfe01a.customer_id$+sfe01a.order_no$+sfe01a.sls_ord_seq_ref$=firm_id$+customer_id$+order_no$+ope11a.internal_seq_no$ then
                    wo_info1$ = woInfoLabel$[1]+": "+sfe01a.wo_no$+"   "+woInfoLabel$[2]+": "+sfe01a.wo_status$+"   "+woInfoLabel$[3]+": "+cvs(str(sfe01a.sch_prod_qty:qty_mask$),3)
                    wo_info2$ = woInfoLabel$[4]+": "+fndate$(sfe01a.eststt_date$)+"   "+woInfoLabel$[5]+": "+fndate$(sfe01a.estcmp_date$)
                endif
            endif

            rem --- How many pick list lines are needed for this order detail line?
            linesNeeded=1
            if qtyOrdered_purchaseUM and qtyOrdered_salesUM then linesNeeded=2

            for line=1 to linesNeeded
                rem --- Unit of Purchase can only be used on the first line, but the first line can use either Unit of Purchase or Unit of Sale.
                if line=1 and qtyOrdered_purchaseUM then
                    rem --- Use Unit of Purchase
                    um_sold$=ivm01a.purchase_um$
                else
                    rem --- Use Unit of Sale
                    if pos(opm02a.line_type$="MO")=0 then
                        um_sold$=ivm01a.unit_of_sale$
                        order_qty_masked$= str(qtyOrdered_salesUM:qty_mask$)
                        ship_qty_raw$= str(qtyOrdered_salesUM)
                    endif
                    if pos(opm02a.line_type$=" SNPO") and print_prices$="Y" then
                        price_raw$=   str(ope11a.unit_price*qtyOrdered_salesUM)
                        price_masked$=str(ope11a.unit_price:price_mask$)
                    endif
                endif
                
                rem --- Cannot use internal_seq_no for the second line because the Jasper LINE_ITEM Group Header is grouped by internal_seq_no.
                rem --- Use line_no instead of internal_seq_no for the second line to avoid that grouping, which causes second line to not print.
                if line=2 then internal_seq_no$=ope11a.line_no$
                
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
                if pos(opm02a.line_type$="MO")=0 then data!.setFieldValue("UM_SOLD",um_sold$)			
    			data!.setFieldValue("ITEM_IS_LS",item_is_ls$)
    			data!.setFieldValue("LINETYPE_ALLOWS_LS",linetype_allows_ls$)
                data!.setFieldValue("WHSE_MESSAGE",whse_message$)
                data!.setFieldValue("WHSE_MSG_SFX",whse_msg_sfx$)
                data!.setFieldValue("SHIP_QTY_RAW", ship_qty_raw$)
                data!.setFieldValue("WO_INFO1", wo_info1$)
                data!.setFieldValue("WO_INFO2", wo_info2$)
    
    			rs!.insert(data!)
			next line		

        rem --- End of detail lines
        wend

rem --- Determine the warehouse message to send back to header report

    whse_message$="AON_ALL_FROM_THIS_WHSE"
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
    data!.setFieldValue("SHIP_QTY_RAW", "")
    data!.setFieldValue("WO_INFO1", "")
    data!.setFieldValue("WO_INFO2", "")
    
	rs!.insert(data!)    

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

rem --- fnmask$: Alphanumeric Masking Function (formerly fnf$)

    def fnmask$(q1$,q2$)
        if cvs(q1$,2)="" return ""
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
