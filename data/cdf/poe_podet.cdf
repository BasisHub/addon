[[POE_PODET.CONV_FACTOR.AVAL]]
rem --- Recalc Unit Cost

	prev_fact=num(callpoint!.getColumnData("POE_PODET.CONV_FACTOR"))
	new_fact=num(callpoint!.getUserInput())
	unit_cost=num(callpoint!.getColumnData("POE_PODET.UNIT_COST"))
	if num(callpoint!.getUserInput())<>prev_fact and prev_fact<>0
		unit_cost=unit_cost/prev_fact
		unit_cost=unit_cost*new_fact
		callpoint!.setColumnData("POE_PODET.UNIT_COST",str(unit_cost),1)
		gosub update_header_tots
		callpoint!.setDevObject("cost_this_row",unit_cost)
	endif
[[POE_PODET.WO_NO.BINQ]]
rem --- call custom inquiry
rem --- Query displays WO's for given firm/vendor, only showing those not already linked to a PO, and only non-stocks (per v6 validation code)

	poc_linecode_dev=fnget_dev("POC_LINECODE")
	dim poc_linecode$:fnget_tpl$("POC_LINECODE")
	po_line_code$=callpoint!.getColumnData("POE_PODET.PO_LINE_CODE")
	read record(poc_linecode_dev,key=firm_id$+po_line_code$,dom=*next)poc_linecode$
	line_type$=poc_linecode.line_type$

	switch pos(line_type$="NS")
		case 1;rem Non-Stock
			call stbl("+DIR_SYP")+"bac_key_template.bbj","SFE_WOSUBCNT","AO_SUBCONT_SEQ",key_tpl$,rd_table_chans$[all],status$
			dim sf_sub_key$:key_tpl$
			wo_loc$=sf_sub_key.wo_location$

			saved_wo$=callpoint!.getColumnData("POE_PODET.WO_NO")
			saved_seq$=callpoint!.getColumnData("POE_PODET.WK_ORD_SEQ_REF")
			sub_dev=fnget_dev("SFE_WOSUBCNT")
			dim subs$:fnget_tpl$("SFE_WOSUBCNT")
			read record (sub_dev,key=firm_id$+sf_sub_key.wo_location$+saved_wo$+saved_seq$,knum="AO_SUBCONT_SEQ",dom=*next)subs$
			if cvs(subs.wo_no$,3)=""
				saved_wo$=""
				saved_seq$=""
			else
				saved_seq$=subs.subcont_seq$
			endif

			dim filter_defs$[7,2]
			filter_defs$[1,0]="SFE_WOSUBCNT.FIRM_ID"
			filter_defs$[1,1]="='"+firm_id$ +"'"
			filter_defs$[1,2]="LOCK"
			rem --- Allow different vendor than what is on WO subcontract line
			rem filter_defs$[2,0]="SFE_WOSUBCNT.VENDOR_ID"
			rem filter_defs$[2,1]="='"+callpoint!.getHeaderColumnData("POE_POHDR.VENDOR_ID")+"'"
			rem filter_defs$[2,2]="LOCK"
			rem --- Previous PO may not have been for full quantity on WO subcontract line
			rem filter_defs$[3,0]="SFE_WOSUBCNT.PO_NO"
			rem filter_defs$[3,1]="=''"
			rem filter_defs$[3,2]="LOCK"
			filter_defs$[4,0]="SFE_WOSUBCNT.LINE_TYPE"
			filter_defs$[4,1]="='S' "
			filter_defs$[4,2]="LOCK"
			filter_defs$[5,0]="SFE_WOSUBCNT.WO_LOCATION"
			filter_defs$[5,1]="='"+sf_sub_key.wo_location$+"' "
			filter_defs$[5,2]="LOCK"
			filter_defs$[6,0]="SFE_WOMASTR.WO_STATUS"
			filter_defs$[6,1]="not in ('Q','C') "
			filter_defs$[6,2]="LOCK"
			filter_defs$[7,0]="SFE_WOSUBCNT.WO_NO"
			filter_defs$[7,1]=" LIKE '"+callpoint!.getDevObject("lookup_wo_no")+"%'"
			filter_defs$[7,2]="LOCK"

			call stbl("+DIR_SYP")+"bax_query.bbj",gui_dev,form!,"SF_SUBDETAIL","",table_chans$[all],sf_sub_key$,filter_defs$[all]
			wo_type$="N"
			wo_key$=sf_sub_key$
			if wo_key$="" wo_key$=firm_id$+wo_loc$+saved_wo$+saved_seq$
			callpoint!.setDevObject("lookup_wo_no","")
			break
		case 2;rem Special Order Item
			whse$=callpoint!.getColumnData("POE_PODET.WAREHOUSE_ID")
			item$=callpoint!.getColumnData("POE_PODET.ITEM_ID")
			ivm_itemwhse=fnget_dev("IVM_ITEMWHSE")
			dim ivm_itemwhse$:fnget_tpl$("IVM_ITEMWHSE")
			read record (ivm_itemwhse,key=firm_id$+whse$+item$,dom=*break) ivm_itemwhse$
			if ivm_itemwhse.special_ord$<>"Y" break
			call stbl("+DIR_SYP")+"bac_key_template.bbj","SFE_WOMATL","AO_MAT_SEQ",key_tpl$,rd_table_chans$[all],status$
			dim sf_mat_key$:key_tpl$
			wo_loc$=sf_mat_key.wo_location$

			saved_wo$=callpoint!.getColumnData("POE_PODET.WO_NO")
			saved_seq$=callpoint!.getColumnData("POE_PODET.WK_ORD_SEQ_REF")
			mat_dev=fnget_dev("SFE_WOMATL")
			dim mats$:fnget_tpl$("SFE_WOMATL")
			read record (mat_dev,key=firm_id$+sf_mat_key.wo_location$+saved_wo$+saved_seq$,knum="AO_MAT_SEQ",dom=*next)mats$
			if cvs(mats.wo_no$,3)=""
				saved_wo$=""
				saved_seq$=""
			else
				saved_seq$=mats.material_seq$
			endif

			dim filter_defs$[5,2]
			filter_defs$[1,0]="SFE_WOMATL.FIRM_ID"
			filter_defs$[1,1]="='"+firm_id$ +"'"
			filter_defs$[1,2]="LOCK"
			filter_defs$[2,0]="SFE_WOMATL.ITEM_ID"
			filter_defs$[2,1]="='"+callpoint!.getColumnData("POE_PODET.ITEM_ID")+"'"
			filter_defs$[2,2]="LOCK"
			filter_defs$[3,0]="SFE_WOMATL.WO_LOCATION"
			filter_defs$[3,1]="='"+sf_mat_key.wo_location$+"' "
			filter_defs$[3,2]="LOCK"
			filter_defs$[4,0]="SFE_WOMATL.LINE_TYPE"
			filter_defs$[4,1]="='S' "
			filter_defs$[4,2]="LOCK"
			filter_defs$[5,0]="SFE_WOMASTR.WO_STATUS"
			filter_defs$[5,1]="not in ('C','Q') "
			filter_defs$[5,2]="LOCK"
	
			call stbl("+DIR_SYP")+"bax_query.bbj",gui_dev,form!,"SF_MATDETAIL","",table_chans$[all],sf_mat_key$,filter_defs$[all]
			wo_type$="S"
			wo_key$=sf_mat_key$
			if wo_key$="" wo_key$=firm_id$+wo_loc$+saved_wo$+saved_seq$
		break
		case default
		break
	swend

	if cvs(wo_key$,3)=firm_id$ wo_key$=""

	gosub get_wo_info

	if cvs(wo_key$,3)<>""
		callpoint!.setColumnData("POE_PODET.WO_NO",wo_no$,1)
		callpoint!.setColumnData("POE_PODET.WK_ORD_SEQ_REF",wo_line$,1)
		callpoint!.setDevObject("wo_looked_up","Y")
	else
		callpoint!.setColumnData("POE_PODET.WO_NO","",1)
		callpoint!.setColumnData("POE_PODET.WK_ORD_SEQ_REF","",1)
		callpoint!.setDevObject("wo_looked_up","N")
	endif

	callpoint!.setStatus("MODIFIED-ACTIVATE-ABORT")
[[POE_PODET.WO_NO.AVAL]]
rem --- need to use custom query so we get back both po# and line#
rem --- throw message to user and abort manual entry

	callpoint!.setDevObject("lookup_wo_no",callpoint!.getUserInput())
	if cvs(callpoint!.getUserInput(),3)<>""
		if callpoint!.getUserInput()<>callpoint!.getColumnData("POE_PODET.WO_NO")
			if callpoint!.getDevObject("wo_looked_up")<>"Y"
				callpoint!.setMessage("PO_USE_QUERY")
				callpoint!.setStatus("ABORT")
			endif
		endif
	else
		callpoint!.setColumnData("POE_PODET.WK_ORD_SEQ_REF","",1)
	endif

	callpoint!.setDevObject("wo_looked_up","N")
[[POE_PODET.REQD_DATE.AVAL]]
ord_date$=cvs(callpoint!.getHeaderColumnData("POE_POHDR.ORD_DATE"),2)
req_date$=cvs(callpoint!.getUserInput(),2)
promise_date$=cvs(callpoint!.getColumnData("POE_PODET.PROMISE_DATE"),2)
not_b4_date$=cvs(callpoint!.getColumnData("POE_PODET.NOT_B4_DATE"),2)

gosub validate_dates

if bad_date$="" then gosub warn_dates
[[POE_PODET.PROMISE_DATE.AVAL]]
ord_date$=cvs(callpoint!.getHeaderColumnData("POE_POHDR.ORD_DATE"),2)
req_date$=cvs(callpoint!.getColumnData("POE_PODET.REQD_DATE"),2)
promise_date$=cvs(callpoint!.getUserInput(),2)
not_b4_date$=cvs(callpoint!.getColumnData("POE_PODET.NOT_B4_DATE"),2)

gosub validate_dates

if bad_date$="" then gosub warn_dates
[[POE_PODET.NOT_B4_DATE.AVAL]]
ord_date$=cvs(callpoint!.getHeaderColumnData("POE_POHDR.ORD_DATE"),2)
req_date$=cvs(callpoint!.getColumnData("POE_PODET.REQD_DATE"),2)
promise_date$=cvs(callpoint!.getColumnData("POE_PODET.PROMISE_DATE"),2)
not_b4_date$=cvs(callpoint!.getUserInput(),2)

gosub validate_dates
[[POE_PODET.BDEL]]
rem --- before delete; check to see if this row is on a receiver...if so don't allow delete
rem --- otherwise, reverse the OO quantity in ivm-02

	on_rcvr$="N"
	item$=callpoint!.getColumnData("POE_PODET.ITEM_ID")
	po_no$=callpoint!.getColumnData("POE_PODET.PO_NO")
	poe_recdet=fnget_dev("POE_RECDET")
	read(poe_recdet,key=firm_id$+item$+po_no$,knum="ITEM_PO",dom=*next)
	while 1
		k$=key(poe_recdet,end=*break)
		if pos(firm_id$+item$+po_no$=k$)<>1 break
		on_rcvr$="Y"
		break
	wend

	if on_rcvr$="Y"
		msg_id$="POLINE_NO_DELETE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	else
		curr_qty = -num(callpoint!.getColumnUndoData("POE_PODET.QTY_ORDERED")) * num(callpoint!.getColumnUndoData("POE_PODET.CONV_FACTOR"))
		if curr_qty<>0 and callpoint!.getHeaderColumnData("POE_POHDR.DROPSHIP")<>"Y"then gosub update_iv_oo
	endif
[[POE_PODET.AWRI]]
rem --- if new row, updt ivm-05 (old poc.ua, now poc_itemvend) 

if callpoint!.getGridRowNewStatus(num(callpoint!.getValidationRow()))="Y"

	vendor_id$=callpoint!.getHeaderColumnData("POE_POHDR.VENDOR_ID")
	ord_date$=callpoint!.getHeaderColumnData("POE_POHDR.ORD_DATE")
	item_id$=callpoint!.getColumnData("POE_PODET.ITEM_ID")
	conv_factor=num(callpoint!.getColumnData("POE_PODET.CONV_FACTOR"))
	unit_cost=num(callpoint!.getColumnData("POE_PODET.UNIT_COST"))
	qty_ordered=num(callpoint!.getColumnData("POE_PODET.QTY_ORDERED"))
	status=0

	call stbl("+DIR_PGM")+"poc_itemvend.aon","W","P",vendor_id$,ord_date$,item_id$,conv_factor,unit_cost,qty_ordered,callpoint!.getDevObject("iv_prec"),status
	
endif

rem --- also need to update POE_LINKED if this is a dropship

cust_id$=callpoint!.getHeaderColumnData("POE_POHDR.CUSTOMER_ID")
order_no$=callpoint!.getHeaderColumnData("POE_POHDR.ORDER_NO")
so_line_no$=callpoint!.getColumnData("POE_PODET.SO_INT_SEQ_REF")

if num(so_line_no$)<>0

	poe_linked_dev=fnget_dev("POE_LINKED")
	dim poe_linked$:fnget_tpl$("POE_LINKED")

	poe_linked.firm_id$=firm_id$
	poe_linked.po_no$=callpoint!.getColumnData("POE_PODET.PO_NO")
	poe_linked.poedet_seq_ref$=callpoint!.getColumnData("POE_PODET.INTERNAL_SEQ_NO")
	poe_linked.customer_id$=cust_id$
	poe_linked.order_no$=order_no$
	poe_linked.opedet_seq_ref$=so_line_no$

	write record (poe_linked_dev)poe_linked$

endif

rem --- Update inventory OO if not a dropship PO

if callpoint!.getHeaderColumnData("POE_POHDR.DROPSHIP")<>"Y"

	rem --- Get current and prior values

	curr_whse$ = callpoint!.getColumnData("POE_PODET.WAREHOUSE_ID")
	curr_item$ = callpoint!.getColumnData("POE_PODET.ITEM_ID")
	curr_qty   = num(callpoint!.getColumnData("POE_PODET.QTY_ORDERED")) * num(callpoint!.getColumnData("POE_PODET.CONV_FACTOR"))
	curr_qty$   = callpoint!.getColumnData("POE_PODET.QTY_ORDERED")
	curr_conv$ = callpoint!.getColumnData("POE_PODET.CONV_FACTOR")

	prior_whse$ = callpoint!.getDevObject("prior_wh")
	prior_item$ = callpoint!.getDevObject("prior_item")
	prior_qty   = num(callpoint!.getDevObject("prior_qty")) * num(callpoint!.getDevObject("prior_conv"))


	rem --- Initialize inventory item update

	status=999
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
	if status then exitto std_exit

	rem --- reverse OO prior item and warehouse

	if prior_whse$<>"" and prior_item$<>"" and prior_qty<>0 then
		items$[1] = prior_whse$
		items$[2] = prior_item$
		refs[0]   = -prior_qty

		print "---reverse OO: item = ", cvs(items$[2], 2), ", WH: ", items$[1], ", qty =", refs[0]; rem debug
				
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon","OO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
		if status then exitto std_exit
	endif

	rem --- Update OO quantity for current item and warehouse

	if curr_whse$<>"" and curr_item$<>"" and curr_qty<>0 then
		items$[1] = curr_whse$
		items$[2] = curr_item$
		refs[0]   = curr_qty 

		print "-----Update OO: item = ", cvs(items$[2], 2), ", WH: ", items$[1], ", qty =", refs[0]; rem debug

		call stbl("+DIR_PGM")+"ivc_itemupdt.aon","OO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
		if status then exitto std_exit
	endif

	callpoint!.setDevObject("prior_wh",curr_whse$)
	callpoint!.setDevObject("prior_item",curr_item$)
	callpoint!.setDevObject("prior_qty",curr_qty$)
	callpoint!.setDevObject("prior_conv",curr_conv$)

endif
[[POE_PODET.QTY_ORDERED.AVAL]]
rem --- call poc_itemvend.aon (poc.ua) to retrieve unit cost from ivm-05
rem --- send in: R/W for retrieve or write
rem                   R for req, P for PO, Q for QA recpt, C for PO recpt
rem                   vendor_id and ord_date from header rec
rem                   item_id,conv factor, unit cost, req qty or ordered qty from detail record
rem                   IV precision from iv params rec
rem 			status

rem don't allow ordered qty < qty rec'd -- need that logic still...

vendor_id$=callpoint!.getHeaderColumnData("POE_POHDR.VENDOR_ID")
ord_date$=callpoint!.getHeaderColumnData("POE_POHDR.ORD_DATE")
item_id$=callpoint!.getColumnData("POE_PODET.ITEM_ID")
conv_factor=num(callpoint!.getColumnData("POE_PODET.CONV_FACTOR"))
unit_cost=num(callpoint!.getColumnData("POE_PODET.UNIT_COST"))
qty_ordered=num(callpoint!.getUserInput())
status=0

call stbl("+DIR_PGM")+"poc_itemvend.aon","R","P",vendor_id$,ord_date$,item_id$,conv_factor,unit_cost,qty_ordered,callpoint!.getDevObject("iv_prec"),status

callpoint!.setColumnData("POE_PODET.UNIT_COST",str(unit_cost),1)

gosub update_header_tots
callpoint!.setDevObject("qty_this_row",num(callpoint!.getUserInput()))
callpoint!.setDevObject("cost_this_row",unit_cost);rem setting both qty and cost because cost may have changed based on qty break
[[POE_PODET.AGCL]]
rem print 'show';rem debug

use ::ado_util.src::util

rem --- set default line code based on param file
if cvs(callpoint!.getDevObject("dflt_po_line_code"),2)<>"" then
	callpoint!.setTableColumnAttribute("POE_PODET.PO_LINE_CODE","DFLT",str(callpoint!.getDevObject("dflt_po_line_code")))
endif
[[POE_PODET.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::grid_entry"
[[POE_PODET.AGRE]]
rem --- check data to see if o.k. to leave row (only if the row isn't marked as deleted)

poc_linecode_dev=fnget_dev("POC_LINECODE")
dim poc_linecode$:fnget_tpl$("POC_LINECODE")
po_line_code$=callpoint!.getColumnData("POE_PODET.PO_LINE_CODE")
read record(poc_linecode_dev,key=firm_id$+po_line_code$,dom=*next)poc_linecode$
line_type$=poc_linecode.line_type$

if callpoint!.getGridRowDeleteStatus(num(callpoint!.getValidationRow()))<>"Y"

	ok_to_write$="Y"

	if ok_to_write$="Y" and cvs(po_line_code$,3)=""
		ok_to_write$="N"
		focus_column$="POE_PODET.PO_LINE_CODE"
		translate$="AON_LINE_CODE"
	endif

	if ok_to_write$="Y" and cvs(callpoint!.getColumnData("POE_PODET.WAREHOUSE_ID"),3)="" 
		ok_to_write$="N"
		focus_column$="POE_PODET.WAREHOUSE_ID"
		translate$="AON_WAREHOUSE"
	endif

	qty_ordered=num(callpoint!.getColumnData("POE_PODET.QTY_ORDERED"))
	if ok_to_write$="Y" and pos(line_type$="SD")<>0 
		if ok_to_write$="Y" and cvs(callpoint!.getColumnData("POE_PODET.ITEM_ID"),3)=""
			ok_to_write$="N"
			focus_column$="POE_PODET.ITEM_ID"
			translate$="AON_ITEM"
		endif
		if ok_to_write$="Y" and num(callpoint!.getColumnData("POE_PODET.CONV_FACTOR"))<=0
			ok_to_write$="N"
			focus_column$="POE_PODET.CONV_FACTOR"
			translate$="AON_CONVERSION_FACTOR"
		endif
		if ok_to_write$="Y" and num(callpoint!.getColumnData("POE_PODET.UNIT_COST"))<0
			ok_to_write$="N"
			focus_column$="POE_PODET.UNIT_COST"
			translate$="AON_UNIT_COST"
		endif
		if ok_to_write$="Y" and (qty_ordered=0 or (qty_ordered>0 and qty_ordered<num(callpoint!.getColumnData("POE_PODET.QTY_RECEIVED"))))
			ok_to_write$="N"
			focus_column$="POE_PODET.QTY_ORDERED"
			translate$="AON_QUANTITY_ORDERED"
		endif
	endif

	if ok_to_write$="Y" and line_type$="N" 
		if ok_to_write$="Y" and num(callpoint!.getColumnData("POE_PODET.UNIT_COST"))<0
			ok_to_write$="N"
			focus_column$="POE_PODET.UNIT_COST"
			translate$="AON_UNIT_COST"
		endif
		if ok_to_write$="Y" and (qty_ordered=0 or (qty_ordered>0 and qty_ordered<num(callpoint!.getColumnData("POE_PODET.QTY_RECEIVED"))))
			ok_to_write$="N"
			focus_column$="POE_PODET.QTY_ORDERED"
			translate$="AON_QUANTITY_ORDERED"
		endif
	endif

	if ok_to_write$="Y" and line_type$="O" 
		if ok_to_write$="Y" and num(callpoint!.getColumnData("POE_PODET.UNIT_COST"))<0
			ok_to_write$="N"
			focus_column$="POE_PODET.UNIT_COST"
			translate$="AON_UNIT_COST"
		endif
	endif

	if ok_to_write$="Y" and pos(line_type$="NOV")<>0 
		if ok_to_write$="Y" and cvs(callpoint!.getColumnData("POE_PODET.ORDER_MEMO"),3)="" 
			ok_to_write$="N"
			focus_column$="POE_PODET.ORDER_MEMO"
			translate$="AON_MEMO"
		endif
	endif

	if ok_to_write$="Y" and callpoint!.getHeaderColumnData("POE_POHDR.DROPSHIP")="Y" and callpoint!.getDevObject("OP_installed")="Y"
		if ok_to_write$="Y" and pos(line_type$="DSNO")<>0
			if ok_to_write$="Y" and cvs(callpoint!.getColumnData("POE_PODET.SO_INT_SEQ_REF"),3)="" 
				ok_to_write$="N"
				focus_column$="POE_PODET.SO_INT_SEQ_REF"
				translate$="AON_SO_SEQ_NO"
			endif
		endif
	endif

	if ok_to_write$<>"Y"
		msg_id$="PO_REQD_DET"
		dim msg_tokens$[1]
		msg_tokens$[1]=""
		if translate$<>""
			msg_tokens$[1]=Translate!.getTranslation(translate$)
		endif
		gosub disp_message
		callpoint!.setFocus(num(callpoint!.getValidationRow()),focus_column$,1)
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif
	
	rem -- now loop thru entire gridVect to make sure SO line reference, if used, isn't used >1 time

	dtl!=gridVect!.getItem(0)
	so_lines_referenced$=""
	dup_so_lines$=""

	if dtl!.size()
		dim rec$:dtlg_param$[1,3]
		for x=0 to dtl!.size()-1
			if callpoint!.getGridRowDeleteStatus(x)<>"Y"
				rec$=dtl!.getItem(x)
				if cvs(rec.so_int_seq_ref$,3)<>""
					if pos(rec.so_int_seq_ref$+"^"=so_lines_referenced$)<>0 
						msg_id$="PO_DUP_SO_LINE"
						gosub disp_message
						callpoint!.setFocus(num(callpoint!.getValidationRow()),"POE_PODET.SO_INT_SEQ_REF",1)
						break
					else
						so_lines_referenced$=so_lines_referenced$+rec.so_int_seq_ref$+"^"
					endif
				endif
			endif
		next x
	endif

endif

rem --- look at wo number; if different than it was when we entered the row, update and/or remove link in corresponding wo detail line

	wo_no_was$=callpoint!.getDevObject("start_wo_no")
	wo_seq_ref_was$=callpoint!.getDevObject("start_wo_seq_ref")

	wo_no_now$=callpoint!.getColumnData("POE_PODET.WO_NO")
	wo_seq_ref_now$=callpoint!.getColumnData("POE_PODET.WK_ORD_SEQ_REF")

	if wo_no_was$+wo_seq_ref_was$<>wo_no_now$+wo_seq_ref_now$
		sfe_womatl=fnget_dev("SFE_WOMATL")
		sfe_wosub=fnget_dev("SFE_WOSUBCNT")
		dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")
		dim sfe_wosub$:fnget_tpl$("SFE_WOSUBCNT")

		rem --- used to reference different wo# (i.e., changed from one wo# to another, or have now removed the wo# from this PO line)
		if cvs(wo_no_was$,3)<>""
			if line_type$="S"
				find record (sfe_womatl,key=firm_id$+sfe_womatl.wo_location$+wo_no_was$+wo_seq_ref_was$,knum="AO_MAT_SEQ",dom=*endif)sfe_womatl$
				sfe_womatl.po_no$=""
				sfe_womatl.pur_ord_seq_ref$=""
				sfe_womatl.po_status$=""
				sfe_womatl$=field(sfe_womatl$)
				write record (sfe_womatl)sfe_womatl$
			endif
			if line_type$="N"
				find record (sfe_wosub,key=firm_id$+sfe_wosub.wo_location$+wo_no_was$+wo_seq_ref_was$,knum="AO_SUBCONT_SEQ",dom=*endif)sfe_wosub$
				sfe_wosub.po_no$=""
				sfe_wosub.pur_ord_seq_ref$=""
				sfe_wosub.po_status$=""
				sfe_wosub$=field(sfe_wosub$)
				write record (sfe_wosub)sfe_wosub$
			endif
		endif		
		rem --- now references different wo# (i.e., changed from one wo# to another, or have now set a wo# on this PO line)
		if cvs(wo_no_now$,3)<>""
			if line_type$="S"
				find record (sfe_womatl,key=firm_id$+sfe_womatl.wo_location$+wo_no_now$+wo_seq_ref_now$,knum="AO_MAT_SEQ",dom=*endif)sfe_womatl$
				sfe_womatl.po_no$=callpoint!.getColumnData("POE_PODET.PO_NO")
				sfe_womatl.pur_ord_seq_ref$=callpoint!.getColumnData("POE_PODET.INTERNAL_SEQ_NO")
				sfe_womatl$.po_status$="P"
				sfe_womatl$=field(sfe_womatl$)
				write record (sfe_womatl)sfe_womatl$
			endif
			if line_type$="N"
				find record (sfe_wosub,key=firm_id$+sfe_wosub.wo_location$+wo_no_now$+wo_seq_ref_now$,knum="AO_SUBCONT_SEQ",dom=*endif)sfe_wosub$
				sfe_wosub.po_no$=callpoint!.getColumnData("POE_PODET.PO_NO")
				sfe_wosub.pur_ord_seq_ref$=callpoint!.getColumnData("POE_PODET.INTERNAL_SEQ_NO")
				sfe_wosub.po_status$="P"
				sfe_wosub$=field(sfe_wosub$)
				write record (sfe_wosub)sfe_wosub$
			endif
		endif
	endif
[[POE_PODET.AGRN]]
rem --- save current qty/price this row

callpoint!.setDevObject("qty_this_row",callpoint!.getColumnData("POE_PODET.QTY_ORDERED"))
callpoint!.setDevObject("cost_this_row",callpoint!.getColumnData("POE_PODET.UNIT_COST"))

callpoint!.setDevObject("bdel_flag","")

rem print "AGRN "
rem print "qty this row: ",callpoint!.getDevObject("qty_this_row")
rem print "cost this row: ",callpoint!.getDevObject("cost_this_row")

	poc_linecode_dev=fnget_dev("POC_LINECODE")
	dim poc_linecode$:fnget_tpl$("POC_LINECODE")
	po_line_code$=callpoint!.getColumnData("POE_PODET.PO_LINE_CODE")
	read record(poc_linecode_dev,key=firm_id$+po_line_code$,dom=*next)poc_linecode$
	line_type$=poc_linecode.line_type$
	gosub enable_by_line_type

rem --- save current po status flag, po/req# and line#

	callpoint!.setDevObject("start_wo_no",callpoint!.getColumnData("POE_PODET.WO_NO"))
	callpoint!.setDevObject("start_wo_seq_ref",callpoint!.getColumnData("POE_PODET.WK_ORD_SEQ_REF"))
	callpoint!.setDevObject("wo_looked_up","N")
	callpoint!.setDevObject("lookup_wo_no","")

	wh$=callpoint!.getColumnData("POE_PODET.WAREHOUSE_ID")
	item$=callpoint!.getColumnData("POE_PODET.ITEM_ID")
	qty$=callpoint!.getColumnData("POE_PODET.QTY_ORDERED")
	conv$=callpoint!.getColumnData("POE_PODET.CONV_FACTOR")
	callpoint!.setDevObject("prior_wh",wh$)
	callpoint!.setDevObject("prior_item",item$)
	callpoint!.setDevObject("prior_qty",qty$)
	callpoint!.setDevObject("prior_conv",conv$)
[[POE_PODET.UNIT_COST.AVAL]]
gosub update_header_tots
callpoint!.setDevObject("cost_this_row",num(callpoint!.getUserInput()))
[[POE_PODET.AUDE]]
gosub update_header_tots
po_line_code$=callpoint!.getColumnData("POE_PODET.PO_LINE_CODE")
if cvs(po_line_code$,2)<>"" then  gosub update_line_type_info

curr_qty = num(callpoint!.getColumnData("POE_PODET.QTY_ORDERED")) * num(callpoint!.getColumnData("POE_PODET.CONV_FACTOR"))
if curr_qty<>0 and callpoint!.getHeaderColumnData("POE_POHDR.DROPSHIP")<>"Y" then gosub update_iv_oo
[[POE_PODET.ADEL]]
gosub update_header_tots
[[POE_PODET.ADGE]]
rem --- if there are order lines to display/access in the sales order line item listbutton, set the LDAT and list display
rem --- get the detail grid, then get the listbutton within the grid; set the list on the listbutton, and put the listbutton back in the grid

order_list!=callpoint!.getDevObject("so_lines_list")
ldat$=callpoint!.getDevObject("so_ldat")

if ldat$<>""
	callpoint!.setColumnEnabled(-1,"POE_PODET.SO_INT_SEQ_REF",1)
	callpoint!.setTableColumnAttribute("POE_PODET.SO_INT_SEQ_REF","LDAT",ldat$)
	g!=callpoint!.getDevObject("dtl_grid")
	col_hdr$=callpoint!.getTableColumnAttribute("POE_PODET.SO_INT_SEQ_REF","LABS")
	col_ref=util.getGridColumnNumber(g!, col_hdr$)
	c!=g!.getColumnListControl(col_ref)
	c!.removeAllItems()
	c!.insertItems(0,order_list!)
	g!.setColumnListControl(col_ref,c!)
else
	callpoint!.setColumnEnabled(-1,"POE_PODET.SO_INT_SEQ_REF",0)
endif 

callpoint!.setOptionEnabled("DPRT",0)
callpoint!.setOptionEnabled("QPRT",0)
[[POE_PODET.BDGX]]
rem -- loop thru gridVect; if there are any lines not marked deleted, set the callpoint!.setDevObject("dtl_posted") to Y

dtl!=gridVect!.getItem(0)
callpoint!.setDevObject("dtl_posted","")
if dtl!.size()
	for x=0 to dtl!.size()-1
		if callpoint!.getGridRowDeleteStatus(x)<>"Y" then callpoint!.setDevObject("dtl_posted","Y")
	next x
endif
[[POE_PODET.AREC]]
callpoint!.setDevObject("qty_this_row",0)
callpoint!.setDevObject("cost_this_row",0)

rem --- set dates from Header

callpoint!.setColumnData("POE_PODET.NOT_B4_DATE",callpoint!.getHeaderColumnData("POE_POHDR.NOT_B4_DATE"))
callpoint!.setColumnData("POE_PODET.REQD_DATE",callpoint!.getHeaderColumnData("POE_POHDR.REQD_DATE"))
callpoint!.setColumnData("POE_PODET.PROMISE_DATE",callpoint!.getHeaderColumnData("POE_POHDR.PROMISE_DATE"))

rem --- REFRESH is needed in order to get the default PO_LINE_CODE set in AGCL
callpoint!.setStatus("REFRESH")
[[POE_PODET.WAREHOUSE_ID.AVAL]]
rem --- Warehouse ID - After Validataion

if callpoint!.getHeaderColumnData("POE_POHDR.WAREHOUSE_ID")<>pad(callpoint!.getUserInput(),2)
	msg_id$="PO_WHSE_NOT_MATCH"
	gosub disp_message
endif

gosub validate_whse_item
[[POE_PODET.AGDR]]
rem --- After Grid Display Row

if num(callpoint!.getColumnData("POE_PODET.QTY_RECEIVED"))<>0
	util.disableGridRow(Form!,num(callpoint!.getValidationRow()))
	callpoint!.setDevObject("qty_received","Y")
	rem print "receipt amt found - disabled row ",callpoint!.getValidationRow();rem debug
else
	po_line_code$=callpoint!.getColumnData("POE_PODET.PO_LINE_CODE")
	if cvs(po_line_code$,2)<>"" then  gosub update_line_type_info
endif


total_amt=num(callpoint!.getDevObject("total_amt"))
total_amt=total_amt+round(num(callpoint!.getColumnData("POE_PODET.QTY_ORDERED"))*num(callpoint!.getColumnData("POE_PODET.UNIT_COST")),2)
callpoint!.setDevObject("total_amt",str(total_amt))

	poc_linecode_dev=fnget_dev("POC_LINECODE")
	dim poc_linecode$:fnget_tpl$("POC_LINECODE")
	po_line_code$=callpoint!.getColumnData("POE_PODET.PO_LINE_CODE")
	read record(poc_linecode_dev,key=firm_id$+po_line_code$,dom=*next)poc_linecode$
	line_type$=poc_linecode.line_type$
	gosub enable_by_line_type
[[POE_PODET.PO_LINE_CODE.AVAL]]
rem --- Line Code - After Validataion
rem print 'show',;rem debug
rem print callpoint!.getUserInput();rem debug
rem print callpoint!.getColumnData("POE_PODET.PO_LINE_CODE");rem debug
rem print callpoint!.getColumnUndoData("POE_PODET.PO_LINE_CODE");rem debug
rem print "validation row:", callpoint!.getValidationRow()
rem print "new status:",callpoint!.getGridRowNewStatus(num(callpoint!.getValidationRow()))
rem print "modify status:",callpoint!.getGridRowModifyStatus(num(callpoint!.getValidationRow()))

rem I think if line type changes on existing row, need to uncommit whatever's on this line (assuming old line code was a stock type)

gosub update_line_type_info

if callpoint!.getGridRowNewStatus(num(callpoint!.getValidationRow()))="Y" or cvs(callpoint!.getUserInput(),2)<>cvs(callpoint!.getColumnData("POE_PODET.PO_LINE_CODE"),2) then
		callpoint!.setColumnData("POE_PODET.PO_LINE_CODE",callpoint!.getUserInput())
		callpoint!.setColumnData("POE_PODET.CONV_FACTOR","")
		callpoint!.setColumnData("POE_PODET.FORECAST","")
		callpoint!.setColumnData("POE_PODET.ITEM_ID","")
		callpoint!.setColumnData("POE_PODET.LEAD_TIM_FLG","")
		callpoint!.setColumnData("POE_PODET.LOCATION","")
		callpoint!.setColumnData("POE_PODET.NOT_B4_DATE",callpoint!.getHeaderColumnData("POE_POHDR.NOT_B4_DATE"))
		callpoint!.setColumnData("POE_PODET.NS_ITEM_ID","")
		callpoint!.setColumnData("POE_PODET.ORDER_MEMO","")
		callpoint!.setColumnData("POE_PODET.PO_MSG_CODE","")
		callpoint!.setColumnData("POE_PODET.PROMISE_DATE",callpoint!.getHeaderColumnData("POE_POHDR.PROMISE_DATE"))
		callpoint!.setColumnData("POE_PODET.REQD_DATE",callpoint!.getHeaderColumnData("POE_POHDR.REQD_DATE"))
		callpoint!.setColumnData("POE_PODET.REQ_QTY","")
		callpoint!.setColumnData("POE_PODET.SO_INT_SEQ_REF","")
		callpoint!.setColumnData("POE_PODET.SOURCE_CODE","")
		callpoint!.setColumnData("POE_PODET.UNIT_COST","")
		callpoint!.setColumnData("POE_PODET.UNIT_MEASURE","")
		callpoint!.setColumnData("POE_PODET.WAREHOUSE_ID",callpoint!.getHeaderColumnData("POE_POHDR.WAREHOUSE_ID"))
		callpoint!.setColumnData("POE_PODET.WO_NO","")
		callpoint!.setColumnData("POE_PODET.WK_ORD_SEQ_REF","")
		callpoint!.setStatus("REFRESH")

	rem --- If a V line type immediately follows an S line type containing an item with this vendor's part number,
	rem --- that number is automatically displayed.
	if line_type$="V" and callpoint!.getValidationRow()>0  then
		rem --- Get line code for previous row
		dtl!=gridVect!.getItem(0)
		dim rec$:dtlg_param$[1,3]
		rec$=dtl!.getItem(callpoint!.getValidationRow()-1)
		prev_row_line_code$=rec.po_line_code$
		prev_row_item_id$=rec.item_id$

		rem --- Get line type for previous row's line code
		poc_linecode_dev=fnget_dev("POC_LINECODE")
		dim poc_linecode$:fnget_tpl$("POC_LINECODE")
		read record(poc_linecode_dev,key=firm_id$+prev_row_line_code$,dom=*next)poc_linecode$
		prev_row_line_type$=poc_linecode.line_type$

		rem --- Get this vendor's part number for item
		if prev_row_line_type$="S" then
			ivm_itemvend_dev=fnget_dev("IVM_ITEMVEND")
			dim ivm_itemvend$:fnget_tpl$("IVM_ITEMVEND")
			vendor_id$=callpoint!.getHeaderColumnData("POE_POHDR.VENDOR_ID")
			read record(ivm_itemvend_dev,key=firm_id$+vendor_id$+prev_row_item_id$,dom=*next)ivm_itemvend$
			callpoint!.setColumnData("POE_PODET.ORDER_MEMO",ivm_itemvend.vendor_item$)
		endif
	endif
endif

gosub enable_by_line_type

if line_type$="M" and cvs(callpoint!.getColumnData("POE_PODET.ORDER_MEMO"),2)=""
	callpoint!.setColumnData("POE_PODET.ORDER_MEMO"," ")
	callpoint!.setStatus("MODIFIED")
endif
[[POE_PODET.ITEM_ID.AVAL]]
rem --- Item ID - After Column Validataion

gosub validate_whse_item
if pos("ABORT"=callpoint!.getStatus())<>0
	callpoint!.setUserInput("")
endif

	poc_linecode_dev=fnget_dev("POC_LINECODE")
	dim poc_linecode$:fnget_tpl$("POC_LINECODE")
	po_line_code$=callpoint!.getColumnData("POE_PODET.PO_LINE_CODE")
	read record(poc_linecode_dev,key=firm_id$+po_line_code$,dom=*next)poc_linecode$
	line_type$=poc_linecode.line_type$
	gosub enable_by_line_type
[[POE_PODET.<CUSTOM>]]
rem ==========================================================================
update_line_type_info:
rem ==========================================================================

	poc_linecode_dev=fnget_dev("POC_LINECODE")
	dim poc_linecode$:fnget_tpl$("POC_LINECODE")
	if callpoint!.getVariableName()="POE_PODET.PO_LINE_CODE" then
		po_line_code$=callpoint!.getUserInput()
	else
		po_line_code$=callpoint!.getColumnData("POE_PODET.PO_LINE_CODE")
	endif
	read record(poc_linecode_dev,key=firm_id$+po_line_code$,dom=*next)poc_linecode$
	line_type$=poc_linecode.line_type$

rem --- Manually enable/disable fields based on Line Type

rem	callpoint!.setStatus("ENABLE:"+poc_linecode.line_type$)
	switch pos(poc_linecode.line_type$="SNOMV")
		case 1; rem Standard
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.NS_ITEM_ID",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.ITEM_ID",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.ORDER_MEMO",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.UNIT_MEASURE",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.CONV_FACTOR",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.QTY_ORDERED",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.UNIT_COST",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.LOCATION",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.REQD_DATE",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.PROMISE_DATE",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.NOT_B4_DATE",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.PO_MSG_CODE",1)
			break
		case 2; rem Non-stock
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.NS_ITEM_ID",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.ITEM_ID",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.ORDER_MEMO",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.UNIT_MEASURE",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.CONV_FACTOR",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.QTY_ORDERED",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.UNIT_COST",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.LOCATION",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.REQD_DATE",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.PROMISE_DATE",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.NOT_B4_DATE",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.PO_MSG_CODE",1)
			break
		case 3; rem Other
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.NS_ITEM_ID",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.ITEM_ID",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.ORDER_MEMO",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.UNIT_MEASURE",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.CONV_FACTOR",0)
			callpoint!.setColumnData("POE_PODET.QTY_ORDERED","1")
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.QTY_ORDERED",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.UNIT_COST",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.LOCATION",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.REQD_DATE",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.PROMISE_DATE",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.NOT_B4_DATE",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.PO_MSG_CODE",1)
			break
		case 4; rem Memo
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.NS_ITEM_ID",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.ITEM_ID",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.ORDER_MEMO",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.UNIT_MEASURE",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.CONV_FACTOR",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.QTY_ORDERED",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.UNIT_COST",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.LOCATION",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.REQD_DATE",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.PROMISE_DATE",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.NOT_B4_DATE",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.PO_MSG_CODE",0)
			break
		case 5; rem Vendor Part Number
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.NS_ITEM_ID",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.ITEM_ID",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.ORDER_MEMO",1)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.UNIT_MEASURE",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.CONV_FACTOR",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.QTY_ORDERED",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.UNIT_COST",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.LOCATION",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.REQD_DATE",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.PROMISE_DATE",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.NOT_B4_DATE",0)
			callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_PODET.PO_MSG_CODE",0)
			break
		case default; rem everything else
			break
	swend
	callpoint!.setStatus("REFRESH")
	callpoint!.setDevObject("line_type",poc_linecode.line_type$)

return

rem ==========================================================================
validate_whse_item:
rem ==========================================================================
	ivm_itemwhse_dev=fnget_dev("IVM_ITEMWHSE")
	dim ivm_itemwhse$:fnget_tpl$("IVM_ITEMWHSE")
	change_flag=0
	if callpoint!.getVariableName()="POE_PODET.ITEM_ID" then
		item_id$=callpoint!.getUserInput()
		if item_id$<>callpoint!.getColumnData("POE_PODET.ITEM_ID") then 
			change_flag=1
		 endif
	else
		item_id$=callpoint!.getColumnData("POE_PODET.ITEM_ID")
	endif
	if callpoint!.getVariableName()="POE_PODET.WAREHOUSE_ID" then
		whse$=callpoint!.getUserInput()
		if whse$<>callpoint!.getColumnData("POE_PODET.WAREHOUSE_ID") then
			change_flag=1
		endif
	else
		whse$=callpoint!.getColumnData("POE_PODET.WAREHOUSE_ID")
	endif
		
	if change_flag and cvs(item_id$,2)<>"" then
		read record (ivm_itemwhse_dev,key=firm_id$+whse$+item_id$,dom=missing_warehouse) ivm_itemwhse$
		ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")
		dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
		read record(ivm_itemmast_dev,key=firm_id$+item_id$)ivm_itemmast$
		callpoint!.setColumnData("POE_PODET.UNIT_MEASURE",ivm_itemmast.purchase_um$)
		callpoint!.setColumnData("POE_PODET.CONV_FACTOR",str(ivm_itemmast.conv_factor))
		if num(callpoint!.getColumnData("POE_PODET.CONV_FACTOR"))=0 then callpoint!.setColumnData("POE_PODET.CONV_FACTOR",str(1))
		if cvs(callpoint!.getColumnData("POE_PODET.LOCATION"),2)="" then callpoint!.setColumnData("POE_PODET.LOCATION","STOCK")
		callpoint!.setColumnData("POE_PODET.UNIT_COST",str(num(callpoint!.getColumnData("POE_PODET.CONV_FACTOR"))*ivm_itemwhse.unit_cost))
		callpoint!.setStatus("REFRESH")
	endif
return

rem ==========================================================================	
missing_warehouse:
rem ==========================================================================

	msg_id$="IV_ITEM_WHSE_INVALID"
	dim msg_tokens$[1]
	msg_tokens$[1]=whse$
	gosub disp_message
	callpoint!.setStatus("ABORT")

return

rem ==========================================================================
update_header_tots:
rem ==========================================================================

if pos(".AVAL"=callpoint!.getCallpointEvent())
	if callpoint!.getVariableName()="POE_PODET.QTY_ORDERED"
		new_qty=num(callpoint!.getUserInput())
		new_cost=num(callpoint!.getColumnData("POE_PODET.UNIT_COST"))
	endif
	if callpoint!.getVariableName()="POE_PODET.UNIT_COST"
		new_qty=num(callpoint!.getColumnData("POE_PODET.QTY_ORDERED"))
		new_cost=num(callpoint!.getUserInput())
	endif
	if callpoint!.getVariableName()="POE_PODET.CONV_FACTOR"
		new_qty=num(callpoint!.getColumnData("POE_PODET.QTY_ORDERED"))
		new_cost=unit_cost
	endif
	gosub calculate_header_tots
endif

if pos(".ADEL"=callpoint!.getCallpointEvent())
	new_qty=0
	new_cost=0
	gosub calculate_header_tots
	callpoint!.setDevObject("qty_this_row",0)
	callpoint!.setDevObject("cost_this_row",0)
endif

if pos(".AUDE"=callpoint!.getCallpointEvent())
	new_cost=num(callpoint!.getColumnData("POE_PODET.UNIT_COST"))
	new_qty=num(callpoint!.getColumnData("POE_PODET.QTY_ORDERED"))
	callpoint!.setDevObject("qty_this_row",0)
	callpoint!.setDevObject("cost_this_row",0)
	gosub calculate_header_tots
	callpoint!.setDevObject("qty_this_row",new_cost)
	callpoint!.setDevObject("cost_this_row",new_qty)
endif

return

rem ==========================================================================
calculate_header_tots:
rem ==========================================================================

total_amt=num(callpoint!.getDevObject("total_amt"))
old_price=round(num(callpoint!.getDevObject("qty_this_row"))*num(callpoint!.getDevObject("cost_this_row")),2) 
new_price=round(new_qty*new_cost,2)
new_total=total_amt-old_price+new_price
callpoint!.setDevObject("total_amt",new_total)
tamt!=callpoint!.getDevObject("tamt")
tamt!.setValue(new_total)
callpoint!.setHeaderColumnData("<<DISPLAY>>.ORDER_TOTAL",str(new_total))

rem print "amts:"
rem print "total_amt: ",total_amt
rem print "old_price: ",old_price
rem print "new_price: ",new_price
rem print "new_total: ",new_total

return

rem ==========================================================================
update_iv_oo:
rem ==========================================================================

rem --- used for un/delete rows; make sure curr_qty is set (+/-) before entry

curr_whse$ = callpoint!.getColumnData("POE_PODET.WAREHOUSE_ID")
curr_item$ = callpoint!.getColumnData("POE_PODET.ITEM_ID")

rem --- Initialize inventory item update

status=999
call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
if status then exitto std_exit

items$[1] = curr_whse$
items$[2] = curr_item$
refs[0]   = curr_qty

print "---Update OO: item = ", cvs(items$[2], 2), ", WH: ", items$[1], ", qty =", refs[0]; rem debug
				
call stbl("+DIR_PGM")+"ivc_itemupdt.aon","OO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
if status then exitto std_exit

return

rem ==========================================================================
validate_dates: rem --- validate dates
rem ==========================================================================

	bad_date$=""
	order_date$=Translate!.getTranslation("AON_ORDER_DATE")
	reqd_date$=Translate!.getTranslation("AON_REQUIRED")+" "+Translate!.getTranslation("AON_DATE")
	prom_date$=Translate!.getTranslation("AON_PROMISED")+" "+Translate!.getTranslation("AON_DATE")
	nb4_date$=Translate!.getTranslation("AON_NOT_BEFORE")+" "+Translate!.getTranslation("AON_DATE")
	after$=Translate!.getTranslation("AON_IS_AFTER")
	before$=Translate!.getTranslation("AON_IS_BEFORE")

	if ord_date$<>"" and req_date$<>"" and ord_date$>req_date$ then
		bad_date$ = order_date$+" "+after$+" "+reqd_date$
	endif

	if ord_date$<>"" and promise_date$<>"" and ord_date$>promise_date$ then
		bad_date$ = order_date$+" "+after$+" "+prom_date$
	endif

	if ord_date$<>"" and not_b4_date$<>"" and ord_date$>not_b4_date$ then
		bad_date$ = order_date$+" "+after$+" "+nb4_date$
	endif

	if req_date$<>"" and not_b4_date$<>"" and req_date$<not_b4_date$ then
		bad_date$ = reqd_date$+" "+before$+" "+nb4_date$
	endif

	if promise_date$<>"" and not_b4_date$<>"" and promise_date$<not_b4_date$ then
		bad_date$ = prom_date$+" "+before$+" "+nb4_date$
	endif

	if bad_date$ <> ""
		msg_id$="INVALID_PO_DATE"
		dim msg_tokens$[1]
		msg_tokens$[1]=bad_date$
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif

return

rem ==========================================================================
warn_dates: rem --- warn about possible bad dates
rem ==========================================================================

	warn_date$=""
	reqd_date$=Translate!.getTranslation("AON_REQUIRED")+" "+Translate!.getTranslation("AON_DATE")
	prom_date$=Translate!.getTranslation("AON_PROMISED")+" "+Translate!.getTranslation("AON_DATE")

	if req_date$<>"" and promise_date$<>"" and req_date$<promise_date$ then
		warn_date$ = reqd_date$+" "+before$+" "+prom_date$
	endif

	if warn_date$ <> ""
		msg_id$="WARN_PO_DATE"
		dim msg_tokens$[1]
		msg_tokens$[1]=warn_date$
		gosub disp_message
	endif

return

rem ==========================================================================
enable_by_line_type:
rem line_type$ : input
rem ==========================================================================

	this_row=callpoint!.getValidationRow()
	if callpoint!.getDevObject("SF_installed")="Y"
		if line_type$="N"
			callpoint!.setColumnEnabled(this_row,"POE_PODET.WO_NO",1)
			callpoint!.setColumnEnabled(this_row,"POE_PODET.WK_ORD_SEQ_REF",0)
		else
			whse$=callpoint!.getColumnData("POE_PODET.WAREHOUSE_ID")
			if callpoint!.getCallpointEvent()="POE_PODET.ITEM_ID.AVAL"
				item$=callpoint!.getUserInput()
			else
				item$=callpoint!.getColumnData("POE_PODET.ITEM_ID")
			endif
			ivm_itemwhse=fnget_dev("IVM_ITEMWHSE")
			dim ivm_itemwhse$:fnget_tpl$("IVM_ITEMWHSE")
			spec_ord$="N"
			while 1
				read record (ivm_itemwhse,key=firm_id$+whse$+item$,dom=*break) ivm_itemwhse$
				if ivm_itemwhse.special_ord$="Y" spec_ord$="Y"
				break
			wend
			if spec_ord$="Y"
				callpoint!.setColumnEnabled(this_row,"POE_PODET.WO_NO",1)
				callpoint!.setColumnEnabled(this_row,"POE_PODET.WK_ORD_SEQ_REF",0)
			else
				callpoint!.setColumnEnabled(this_row,"POE_PODET.WO_NO",0)
				callpoint!.setColumnEnabled(this_row,"POE_PODET.WK_ORD_SEQ_REF",0)
			endif
		endif
	else
		callpoint!.setColumnEnabled(this_row,"POE_PODET.WO_NO",0)
		callpoint!.setColumnEnabled(this_row,"POE_PODET.WK_ORD_SEQ_REF",0)
	endif

return

rem ========================================================
get_wo_info:
rem wo_key$:		input
rem wo_no$:		output
rem wo_line$:		output
rem wo_type$:	input
rem ========================================================

	sfe_wosub=fnget_dev("SFE_WOSUBCNT")
	dim sfe_wosub$:fnget_tpl$("SFE_WOSUBCNT")

	sfe_womatl=fnget_dev("SFE_WOMATL")
	dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")

	rem --- wo_key$ will be firm/wo_loc/wo_no/seq - need to read the correct table to get ISN
	if wo_key$<>""
		if wo_key$(len(wo_key$),1)="^" then wo_key$=wo_key$(1,len(wo_key$)-1)
		switch pos(wo_type$="NS")
			case 1; rem Non-stock Subcontract line
				read record (sfe_wosub,key=wo_key$,knum="PRIMARY") sfe_wosub$
				wo_no$=sfe_wosub.wo_no$
				wo_line$=sfe_wosub.internal_seq_no$
			break
			case 2;rem Special Order Item
				read record (sfe_womatl,key=wo_key$,knum="PRIMARY") sfe_womatl$
				wo_no$=sfe_womatl.wo_no$
				wo_line$=sfe_womatl.internal_seq_no$
			break
			case default
			break	
		swend
			
	endif

	return
