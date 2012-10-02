rem Declare some variables ahead of time
declare BBjStoredProcedureData sp!
declare BBjRecordSet rs!
declare BBjRecordData data!

rem Get the infomation object for the Stored Procedure
sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem Get the IN and IN/OUT parameters used by the procedure
firm_id$ = sp!.getParameter("FIRM_ID")
customer_id$ = sp!.getParameter("CUSTOMER_ID")
order_no$ = sp!.getParameter("ORDER_NO")

sypdir$=""
sypdir$=stbl("+DIR_SYP",err=*next)

rem Create a memory record set to hold sample results.
rem Columns for the record set are defined using a string template
rs! = BBJAPI().createMemoryRecordSet("ORDER:C(7), SHIP:C(7), BACKORD:C(7), ITEM_ID:C(40), ITEM_DESC:C(60), LOTSER_NO:C(57*), WH:C(2), LOCATION:C(10), PRICE:N(7), CARTON:C(7)")

rem Open Files    
num_files = 7
dim open_tables$[1:num_files], open_opts$[1:num_files], open_chans$[1:num_files], open_tpls$[1:num_files]

open_tables$[1] = "OPE_ORDDET", open_opts$[1] = "OTA"
open_tables$[2] = "OPC_LINECODE", open_opts$[2] = "OTA"
open_tables$[3] = "IVM_ITEMWHSE", open_opts$[3] = "OTA"
open_tables$[4] = "OPE_ORDLSDET", open_opts$[4] = "OTA"
open_tables$[5] = "IVS_PARAMS", open_opts$[5] = "OTA"
open_tables$[6] = "OPE_ORDHDR", open_opts$[6] = "OTA"
open_tables$[7] = "IVM_ITEMMAST", open_opts$[7] = "OTA"

call sypdir$+"bac_open_tables.bbj",
:       open_beg,
:		open_end,
:		open_tables$[all],
:		open_opts$[all],
:		open_chans$[all],
:		open_tpls$[all],
:		table_chans$[all],
:		open_batch,
:		open_status$

ope_orddet_chan = num(open_chans$[1])
opc_linecode_chan = num(open_chans$[2])
ivm_itemwhse_chan = num(open_chans$[3])
ope_ordlsdet_chan = num(open_chans$[4])
ivs_params_chan = num(open_chans$[5])
ope_ordhdr_chan = num(open_chans$[6])
ivm_itemmast_chan = num(open_chans$[7])

dim ope_orddet$:open_tpls$[1]
dim opc_linecode$:open_tpls$[2]
dim ivm_itemwhse$:open_tpls$[3]
dim ope_ordlsdet$:open_tpls$[4]
dim ivs_params$:open_tpls$[5]
dim ope_ordhdr$:open_tpls$[6]
dim ivm_itemmast$:open_tpls$[7]

total = 0

data! = rs!.getEmptyRecordData()

find record (ope_ordhdr_chan, key=firm_id$+"  "+customer_id$+order_no$, dom=*continue) ope_ordhdr$

find record (ivs_params_chan, key=firm_id$+"IV00") ivs_params$
read (ope_orddet_chan, key=firm_id$+"  "+customer_id$+order_no$, knum="AO_CUST_ORD_LINE", dom=*next)

while BBjAPI().TRUE
    read record (ope_orddet_chan, end=*break)ope_orddet$
    if ope_orddet.firm_id$<>firm_id$ then break
    if ope_orddet.customer_id$<>customer_id$ then break
    if ope_orddet.order_no$<>order_no$ then break

    find record (opc_linecode_chan, key=firm_id$+ope_orddet.line_code$, dom=*endif)opc_linecode$

    if pos(opc_linecode.line_type$="MO")=0 then
        data!.setFieldValue("ORDER", str(ope_orddet.qty_ordered))
        if ope_orddet.commit_flag$="N" then
            data!.setFieldValue("SHIP", func.formatDate(ope_orddet.est_shp_date$))
        else
            data!.setFieldValue("SHIP", "_______")
        endif
        data!.setFieldValue("BACKORD", "_______")
    endif

    if pos(opc_linecode.line_type$="MO")<>0
        data!.setFieldValue("ITEM_ID", ope_orddet.order_memo$)
    endif  

    if opc_linecode.line_type$="N"
        data!.setFieldValue("ITEM_ID", "Non-Stock")
    endif

    if pos(opc_linecode.line_type$=" SRDP")<>0
        data!.setFieldValue("ITEM_ID", ope_orddet.item_id$)
    endif

    if pos(opc_linecode.line_type$=" SRDP")<>0
        find record (ivm_itemmast_chan, key=firm_id$+ope_orddet.item_id$, dom=*next)ivm_itemmast$
        data!.setFieldValue("ITEM_DESC", ivm_itemmast.item_desc$)
    endif

    if opc_linecode.line_type$="N"
        data!.setFieldValue("ITEM_DESC", ope_orddet.order_memo$)
    endif

    total_ls = 0
    read (ope_ordlsdet_chan, key=firm_id$+"  "+customer_id$+order_no$+ope_orddet.internal_seq_no$, dom=*next)

    tmp$=""
    while BBjAPI().TRUE
        read record (ope_ordlsdet_chan, end=*break) ope_ordlsdet$
        if ope_ordlsdet.firm_id$ <> firm_id$        then break
        if ope_ordlsdet.customer_id$ <> customer_id$    then break
        if ope_ordlsdet.order_no$ <> order_no$       then break
        if ope_ordlsdet.internal_seq_no$ <> ope_orddet.orddet_seq_ref$ then break

        if ope_ordlsdet.qty_ordered then
            if ivs_params.lotser_flag$<>"L" then
                tmp$ = tmp$+"S/N: "+ope_ordlsdet.lotser_no$+fill(32," ")
            else
                if ope_ordlsdet.qty_shipped then 
                    amount$ = str(ope_ordlsdet.qty_shipped:"                    ")
                else 
                    amount$ = fill(20,"_")
                endif
                tmp$ = tmp$+"Lot: "+ope_ordlsdet.lotser_no$+"   Shipped: "+amount$
            endif
            total_ls=total_ls+ope_ordlsdet.qty_shipped
        endif
    wend

tmp$=""
    if total_ls < ope_orddet.qty_ordered then
       ope_ordlsdet.lotser_no$ = fill(20, "_")
       ope_ordlsdet.qty_ordered = 0
       ope_ordlsdet.qty_shipped = 0
       ope_ordlsdet.unit_cost   = 0

        if ivs_params.lotser_flag$="L" then 
            y9=3
        else
            y9=ope_orddet.qty_ordered-total_ls
        endif
        rem for y=1 to ope_orddet.qty_shipped - total_ls
        for y=1 to y9
            if ivs_params.lotser_flag$<>"L" then
                tmp$ = tmp$+"S/N: "+ope_ordlsdet.lotser_no$+fill(32," ")
            else
                if ope_ordlsdet.qty_shipped then 
                    amount$ = str(ope_ordlsdet.qty_shipped:"                    ")
                else 
                    amount$ = fill(20,"_")
                endif
                tmp$ = tmp$+"Lot: "+ope_ordlsdet.lotser_no$+"   Shipped: "+amount$
            endif
            if ivs_params.lotser_flag$="L" then break
        next y
    endif

    data!.setFieldValue("LOTSER_NO", tmp$)

    if ope_ordhdr.invoice_type$<>"P"
        if pos(opc_linecode.line_type$=" SRDPN")<>0 then
            data!.setFieldValue("WH", ope_orddet.warehouse_id$)
        endif

        if opc_linecode.dropship$="Y"
            data!.setFieldValue("LOCATION", "*Dropship")
        else   
            if pos(opc_linecode.line_type$=" SRDP")<>0
                find record (ivm_itemwhse_chan, key=firm_id$+ope_orddet.warehouse_id$+ope_orddet.item_id$, dom=*next)ivm_itemwhse$
                data!.setFieldValue("LOCATION", ivm_itemwhse.location$)
            endif
        endif  
    endif

    if pos(opc_linecode.line_type$=" SRDPN")<>0
        data!.setFieldValue("PRICE", str(ope_orddet.qty_ordered*ope_orddet.unit_price))
        total=total+(ope_orddet.qty_ordered*ope_orddet.unit_price)
    endif 

    if pos(opc_linecode.line_type$="O")<>0
        data!.setFieldValue("PRICE", str(ope_orddet.qty_ordered*ope_orddet.ext_price))
        total=total+(ope_orddet.qty_ordered*ope_orddet.ext_price)
    endif

    data!.setFieldValue("CARTON", "_______")

    rs!.insert(data!)
wend

data! = rs!.getEmptyRecordData()

data!.setFieldValue("LOCATION", fill(10," ")+"Total:")
data!.setFieldValue("PRICE", str(total))

rs!.insert(data!)

rem Tell the stored procedure to return the result set.
sp!.setRecordSet(rs!)