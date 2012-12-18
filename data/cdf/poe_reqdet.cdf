[[POE_REQDET.WO_NO.AVAL]]
rem --- need to use custom query so we get back both po# and line#
rem --- throw message to user and abort manual entry

	if cvs(callpoint!.getUserInput(),3)<>""
		if callpoint!.getUserInput()<>callpoint!.getColumnData("POE_REQDET.WO_NO")
			if callpoint!.getDevObject("wo_looked_up")<>"Y"
				callpoint!.setMessage("PO_USE_QUERY")
				callpoint!.setStatus("ABORT")
			endif
		endif
	else
		callpoint!.setColumnData("POE_REQDET.WK_ORD_SEQ_REF","",1)
	endif

	callpoint!.setDevObject("wo_looked_up","N")
[[POE_REQDET.WO_NO.BINQ]]
rem --- call custom inquiry
rem --- Query displays WO's for given firm/vendor, only showing those not already linked to a PO, and only non-stocks (per v6 validation code)

	poc_linecode_dev=fnget_dev("POC_LINECODE")
	dim poc_linecode$:fnget_tpl$("POC_LINECODE")
	po_line_code$=callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE")
	read record(poc_linecode_dev,key=firm_id$+po_line_code$,dom=*next)poc_linecode$
	line_type$=poc_linecode.line_type$

	switch pos(line_type$="NS")
		case 1;rem Non-Stock
			call stbl("+DIR_SYP")+"bac_key_template.bbj","SFE_WOSUBCNT","AO_SUBCONT_SEQ",key_tpl$,rd_table_chans$[all],status$
			dim sf_sub_key$:key_tpl$
			wo_loc$=sf_sub_key.wo_location$

			saved_wo$=callpoint!.getColumnData("POE_REQDET.WO_NO")
			saved_seq$=callpoint!.getColumnData("POE_REQDET.WK_ORD_SEQ_REF")
			sub_dev=fnget_dev("SFE_WOSUBCNT")
			dim subs$:fnget_tpl$("SFE_WOSUBCNT")
			read record (sub_dev,key=firm_id$+sf_sub_key.wo_location$+saved_wo$+saved_seq$,knum="AO_SUBCONT_SEQ",dom=*next)subs$
			if cvs(subs.wo_no$,3)=""
				saved_wo$=""
				saved_seq$=""
			else
				saved_seq$=subs.subcont_seq$
			endif

			dim filter_defs$[6,2]
			filter_defs$[1,0]="SFE_WOSUBCNT.FIRM_ID"
			filter_defs$[1,1]="='"+firm_id$ +"'"
			filter_defs$[1,2]="LOCK"
			filter_defs$[2,0]="SFE_WOSUBCNT.VENDOR_ID"
			filter_defs$[2,1]="='"+callpoint!.getHeaderColumnData("POE_REQHDR.VENDOR_ID")+"'"
			filter_defs$[2,2]="LOCK"
			filter_defs$[3,0]="SFE_WOSUBCNT.PO_NO"
			filter_defs$[3,1]="=''"
			filter_defs$[3,2]="LOCK"
			filter_defs$[4,0]="SFE_WOSUBCNT.LINE_TYPE"
			filter_defs$[4,1]="='S' "
			filter_defs$[4,2]="LOCK"
			filter_defs$[5,0]="SFE_WOSUBCNT.WO_LOCATION"
			filter_defs$[5,1]="='"+sf_sub_key.wo_location$+"' "
			filter_defs$[5,2]="LOCK"
			filter_defs$[6,0]="SFE_WOMASTR.WO_STATUS"
			filter_defs$[6,1]="not in ('Q','C') "
			filter_defs$[6,2]="LOCK"

			call stbl("+DIR_SYP")+"bax_query.bbj",gui_dev,form!,"SF_SUBDETAIL","",table_chans$[all],sf_sub_key$,filter_defs$[all]
			wo_type$="N"
			wo_key$=sf_sub_key$
			if wo_key$="" wo_key$=firm_id$+wo_loc$+saved_wo$+saved_seq$
			break
		case 2;rem Special Order Item
			whse$=callpoint!.getColumnData("POE_REQDET.WAREHOUSE_ID")
			item$=callpoint!.getColumnData("POE_REQDET.ITEM_ID")
			ivm_itemwhse=fnget_dev("IVM_ITEMWHSE")
			dim ivm_itemwhse$:fnget_tpl$("IVM_ITEMWHSE")
			read record (ivm_itemwhse,key=firm_id$+whse$+item$,dom=*break) ivm_itemwhse$
			if ivm_itemwhse.special_ord$<>"Y" break
			call stbl("+DIR_SYP")+"bac_key_template.bbj","SFE_WOMATL","AO_MAT_SEQ",key_tpl$,rd_table_chans$[all],status$
			dim sf_mat_key$:key_tpl$
			wo_loc$=sf_mat_key.wo_location$

			saved_wo$=callpoint!.getColumnData("POE_REQDET.WO_NO")
			saved_seq$=callpoint!.getColumnData("POE_REQDET.WK_ORD_SEQ_REF")
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
			filter_defs$[2,1]="='"+callpoint!.getColumnData("POE_REQDET.ITEM_ID")+"'"
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
		callpoint!.setColumnData("POE_REQDET.WO_NO",wo_no$,1)
		callpoint!.setColumnData("POE_REQDET.WK_ORD_SEQ_REF",wo_line$,1)
		callpoint!.setDevObject("wo_looked_up","Y")
	else
		callpoint!.setColumnData("POE_REQDET.WO_NO","",1)
		callpoint!.setColumnData("POE_REQDET.WK_ORD_SEQ_REF","",1)
		callpoint!.setDevObject("wo_looked_up","N")
	endif

	callpoint!.setStatus("MODIFIED-ACTIVATE-ABORT")
[[POE_REQDET.REQ_QTY.BINP]]
if callpoint!.getDevObject("line_type")="O"  
	callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"POE_REQDET.REQ_QTY",0)
	callpoint!.setFocus("POE_REQDET.UNIT_COST")
endif
[[POE_REQDET.BDGX]]
rem -- loop thru gridVect; if there are any lines not marked deleted, set the callpoint!.setDevObject("dtl_posted") to Y

dtl!=gridVect!.getItem(0)
callpoint!.setDevObject("dtl_posted","")

if dtl!.size()
	for x=0 to dtl!.size()-1
		if callpoint!.getGridRowDeleteStatus(x)<>"Y" then callpoint!.setDevObject("dtl_posted","Y")
	next x
endif

[[POE_REQDET.ADGE]]
rem --- if there are order lines to display/access in the sales order line item listbutton, set the LDAT and list display
rem --- get the detail grid, then get the listbutton within the grid; set the list on the listbutton, and put the listbutton back in the grid

order_list!=callpoint!.getDevObject("so_lines_list")
ldat$=callpoint!.getDevObject("so_ldat")

if ldat$<>""
	callpoint!.setColumnEnabled(-1,"POE_REQDET.SO_INT_SEQ_REF",1)
	callpoint!.setTableColumnAttribute("POE_REQDET.SO_INT_SEQ_REF","LDAT",ldat$)
	g!=callpoint!.getDevObject("dtl_grid")
	c!=g!.getColumnListControl(num(callpoint!.getDevObject("so_seq_ref_col")))
	c!.removeAllItems()
	c!.insertItems(0,order_list!)
	g!.setColumnListControl(num(callpoint!.getDevObject("so_seq_ref_col")),c!)	
else
	callpoint!.setColumnEnabled(-1,"POE_REQDET.SO_INT_SEQ_REF",0)
endif 
[[POE_REQDET.AUDE]]
gosub update_header_tots
[[POE_REQDET.ADEL]]
gosub update_header_tots
[[POE_REQDET.AREC]]
callpoint!.setDevObject("qty_this_row",0)
callpoint!.setDevObject("cost_this_row",0)

rem callpoint!.setFocus(num(callpoint!.getValidationRow()),"POE_REQDET.PO_LINE_CODE"); rem no longer needed since Barista bug 3999 fixed
[[POE_REQDET.UNIT_COST.AVAL]]
gosub update_header_tots
callpoint!.setDevObject("cost_this_row",num(callpoint!.getUserInput()))
[[POE_REQDET.AGRN]]
rem --- save current qty/price this row

callpoint!.setDevObject("qty_this_row",callpoint!.getColumnData("POE_REQDET.REQ_QTY"))
callpoint!.setDevObject("cost_this_row",callpoint!.getColumnData("POE_REQDET.UNIT_COST"))

rem print "AGRN "
rem print "qty this row: ",callpoint!.getDevObject("qty_this_row")
rem print "cost this row: ",callpoint!.getDevObject("cost_this_row")

rem print "AGRN line_no: ",callpoint!.getColumnData("POE_REQDET.PO_LINE_NO")


	poc_linecode_dev=fnget_dev("POC_LINECODE")
	dim poc_linecode$:fnget_tpl$("POC_LINECODE")
	po_line_code$=callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE")
	read record(poc_linecode_dev,key=firm_id$+po_line_code$,dom=*next)poc_linecode$
	line_type$=poc_linecode.line_type$
	gosub enable_by_line_type

rem --- save current po status flag, po/req# and line#

	callpoint!.setDevObject("start_wo_no",callpoint!.getColumnData("POE_REQDET.WO_NO"))
	callpoint!.setDevObject("start_wo_seq_ref",callpoint!.getColumnData("POE_REQDET.WK_ORD_SEQ_REF"))
	callpoint!.setDevObject("wo_looked_up","N")
[[POE_REQDET.AGRE]]
rem --- check data to see if o.k. to leave row (only if the row isn't marked as deleted)

rem print "col data: ",callpoint!.getColumnData("POE_REQDET.REQ_QTY")
rem print "undo data: ",callpoint!.getColumnUndoData("POE_REQDET.REQ_QTY")
rem print "disk data: ",callpoint!.getColumnDiskData("POE_REQDET.REQ_QTY")

if callpoint!.getGridRowDeleteStatus(num(callpoint!.getValidationRow()))<>"Y"

	ok_to_write$="Y"

	if ok_to_write$="Y" and  cvs(callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE"),3)=""
		ok_to_write$="N"
		focus_column$="POE_REQDET.PO_LINE_CODE"
		translate$="AON_LINE_CODE"
	endif

	if ok_to_write$="Y" and  cvs(callpoint!.getColumnData("POE_REQDET.WAREHOUSE_ID"),3)="" 
		ok_to_write$="N"
		focus_column$="POE_REQDET.WAREHOUSE_ID"
		translate$="AON_WAREHOUSE"
	endif

	if ok_to_write$="Y" and pos(cvs(callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE"),3)="SD")<>0 
		if ok_to_write$="Y" and cvs(callpoint!.getColumnData("POE_REQDET.ITEM_ID"),3)=""
			ok_to_write$="N"
			focus_column$="POE_REQDET.ITEM_ID"
			translate$="AON_ITEM"
		endif
		if ok_to_write$="Y" and num(callpoint!.getColumnData("POE_REQDET.CONV_FACTOR"))<=0
			ok_to_write$="N"
			focus_column$="POE_REQDET.CONV_FACTOR"
			translate$="AON_CONVERSION_FACTOR"
		endif
		if ok_to_write$="Y" and num(callpoint!.getColumnData("POE_REQDET.UNIT_COST"))<0
			ok_to_write$="N"
			focus_column$="POE_REQDET.UNIT_COST"
			translate$="AON_UNIT_COST"
		endif
		if ok_to_write$="Y" and num(callpoint!.getColumnData("POE_REQDET.REQ_QTY"))<=0
			ok_to_write$="N"
			focus_column$="POE_REQDET.REQ_QTY"
			translate$="AON_QUANTITY_REQUIRED"
		endif
	endif

	if ok_to_write$="Y" and  cvs(callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE"),3)="N" 
		if ok_to_write$="Y" and  num(callpoint!.getColumnData("POE_REQDET.UNIT_COST"))<0
			ok_to_write$="N"
			focus_column$="POE_REQDET.UNIT_COST"
			translate$="AON_UNIT_COST"
		endif
		if ok_to_write$="Y" and  num(callpoint!.getColumnData("POE_REQDET.REQ_QTY"))<=0
			ok_to_write$="N"
			focus_column$="POE_REQDET.REQ_QTY"
			translate$="AON_QUANTITY_REQUIRED"
		endif
	endif

	if ok_to_write$="Y" and cvs(callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE"),3)="O" 
		if ok_to_write$="Y" and num(callpoint!.getColumnData("POE_REQDET.UNIT_COST"))<0
			ok_to_write$="N"
			focus_column$="POE_REQDET.UNIT_COST"
			translate$="AON_UNIT_COST"
		endif
	endif

	if ok_to_write$="Y" and pos(cvs(callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE"),3)="MNOV")<>0 
		if ok_to_write$="Y" and cvs(callpoint!.getColumnData("POE_REQDET.ORDER_MEMO"),3)="" 
			ok_to_write$="N"
			focus_column$="POE_REQDET.ORDER_MEMO"
			translate$="AON_MEMO"
		endif
	endif

	if ok_to_write$="Y" and callpoint!.getHeaderColumnData("POE_REQHDR.DROPSHIP")="Y" and callpoint!.getDevObject("OP_installed")="Y"
		if ok_to_write$="Y" and pos(cvs(callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE"),3)="DSNO")<>0
			if ok_to_write$="Y" and cvs(callpoint!.getColumnData("POE_REQDET.SO_INT_SEQ_REF"),3)="" 
				ok_to_write$="N"
				focus_column$="POE_REQDET.SO_INT_SEQ_REF"
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
		callpoint!.setFocus(num(callpoint!.getValidationRow()),focus_column$)
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
						callpoint!.setFocus(num(callpoint!.getValidationRow()),"POE_REQDET.SO_INT_SEQ_REF")
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

	poc_linecode_dev=fnget_dev("POC_LINECODE")
	dim poc_linecode$:fnget_tpl$("POC_LINECODE")
	po_line_code$=callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE")
	read record(poc_linecode_dev,key=firm_id$+po_line_code$,dom=*next)poc_linecode$
	line_type$=poc_linecode.line_type$

	wo_no_was$=callpoint!.getDevObject("start_wo_no")
	wo_seq_ref_was$=callpoint!.getDevObject("start_wo_seq_ref")

	wo_no_now$=callpoint!.getColumnData("POE_REQDET.WO_NO")
	wo_seq_ref_now$=callpoint!.getColumnData("POE_REQDET.WK_ORD_SEQ_REF")

	sfe_womatl=fnget_dev("SFE_WOMATL")
	sfe_wosub=fnget_dev("SFE_WOSUBCNT")

	dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")
	dim sfe_wosub$:fnget_tpl$("SFE_WOSUBCNT")

	if wo_no_was$+wo_seq_ref_was$<>wo_no_now$+wo_seq_ref_now$
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
				sfe_womatl.po_no$=callpoint!.getColumnData("POE_REQDET.REQ_NO")
				sfe_womatl.pur_ord_seq_ref$=callpoint!.getColumnData("POE_REQDET.INTERNAL_SEQ_NO")
				sfe_womatl$.po_status$="R"
				sfe_womatl$=field(sfe_womatl$)
				write record (sfe_womatl)sfe_womatl$
			endif
			if line_type$="N"
				find record (sfe_wosub,key=firm_id$+sfe_wosub.wo_location$+wo_no_now$+wo_seq_ref_now$,knum="AO_SUBCONT_SEQ",dom=*endif)sfe_wosub$
				sfe_wosub.po_no$=callpoint!.getColumnData("POE_REQDET.REQ_NO")
				sfe_wosub.pur_ord_seq_ref$=callpoint!.getColumnData("POE_REQDET.INTERNAL_SEQ_NO")
				sfe_wosub.po_status$="R"
				sfe_wosub$=field(sfe_wosub$)
				write record (sfe_wosub)sfe_wosub$
			endif
		endif
	endif
[[POE_REQDET.ITEM_ID.AINV]]
rem --- Item synonym processing
 
	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::grid_entry"
     
[[POE_REQDET.AGCL]]
rem print 'show';rem debug

use ::ado_util.src::util

rem --- set default line code based on param file
callpoint!.setTableColumnAttribute("POE_REQDET.PO_LINE_CODE","DFLT",str(callpoint!.getDevObject("dflt_po_line_code")))
[[POE_REQDET.PO_LINE_CODE.AVAL]]
rem --- Line Code - After Validataion

rem  print "userInput: ",callpoint!.getUserInput();rem debug
rem  print "columnData: ",callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE");rem debug
rem  print "undoData: ",callpoint!.getColumnUndoData("POE_REQDET.PO_LINE_CODE");rem debug
rem print "validation row:", callpoint!.getValidationRow()
rem print "new status:",callpoint!.getGridRowNewStatus(num(callpoint!.getValidationRow()))
rem print "modify status:",callpoint!.getGridRowModifyStatus(num(callpoint!.getValidationRow()))

gosub update_line_type_info

if callpoint!.getGridRowNewStatus(num(callpoint!.getValidationRow()))="Y" or cvs(callpoint!.getUserInput(),2)<>cvs(callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE"),2) 

		callpoint!.setColumnData("POE_REQDET.CONV_FACTOR","")
		callpoint!.setColumnData("POE_REQDET.FORECAST","")
		callpoint!.setColumnData("POE_REQDET.ITEM_ID","")
		callpoint!.setColumnData("POE_REQDET.LEAD_TIM_FLG","")
		callpoint!.setColumnData("POE_REQDET.LOCATION","")
		callpoint!.setColumnData("POE_REQDET.NOT_B4_DATE",callpoint!.getHeaderColumnData("POE_REQHDR.NOT_B4_DATE"))
		callpoint!.setColumnData("POE_REQDET.NS_ITEM_ID","")
		callpoint!.setColumnData("POE_REQDET.ORDER_MEMO","")
		callpoint!.setColumnData("POE_REQDET.PO_MSG_CODE","")
		callpoint!.setColumnData("POE_REQDET.PROMISE_DATE",callpoint!.getHeaderColumnData("POE_REQHDR.PROMISE_DATE"))
		callpoint!.setColumnData("POE_REQDET.REQD_DATE",callpoint!.getHeaderColumnData("POE_REQHDR.REQD_DATE"))
		callpoint!.setColumnData("POE_REQDET.REQ_QTY","")
		callpoint!.setColumnData("POE_REQDET.SO_INT_SEQ_REF","")
		callpoint!.setColumnData("POE_REQDET.SOURCE_CODE","")
		callpoint!.setColumnData("POE_REQDET.UNIT_COST","")
		callpoint!.setColumnData("POE_REQDET.UNIT_MEASURE","")
		callpoint!.setColumnData("POE_REQDET.WAREHOUSE_ID",callpoint!.getHeaderColumnData("POE_REQHDR.WAREHOUSE_ID"))
		callpoint!.setColumnData("POE_REQDET.WO_NO","")
		callpoint!.setColumnData("POE_REQDET.WK_ORD_SEQ_REF","")


endif

if callpoint!.getDevObject("line_type")="O" 
	callpoint!.setColumnData("POE_REQDET.REQ_QTY","1")
else
	callpoint!.setColumnData("POE_REQDET.REQ_QTY","")
endif

gosub enable_by_line_type
[[POE_REQDET.REQ_QTY.AVAL]]
rem --- call poc.ua to retrieve unit cost from ivm-05, at least that's what v6 did here
rem --- send in: R/W for retrieve or write
rem                   R for req, P for PO, Q for QA recpt, C for PO recpt
rem                   vendor_id and ord_date from header rec
rem                   item_id,conv factor, unit cost, req qty or ordered qty from detail record
rem                   IV precision from iv params rec
rem 			status

vendor_id$=callpoint!.getHeaderColumnData("POE_REQHDR.VENDOR_ID")
ord_date$=callpoint!.getHeaderColumnData("POE_REQHDR.ORD_DATE")
item_id$=callpoint!.getColumnData("POE_REQDET.ITEM_ID")
conv_factor=num(callpoint!.getColumnData("POE_REQDET.CONV_FACTOR"))
unit_cost=num(callpoint!.getColumnData("POE_REQDET.UNIT_COST"))
req_qty=num(callpoint!.getUserInput())
status=0

call stbl("+DIR_PGM")+"poc_itemvend.aon","R","R",vendor_id$,ord_date$,item_id$,conv_factor,unit_cost,req_qty,callpoint!.getDevObject("iv_prec"),status

callpoint!.setColumnData("POE_REQDET.UNIT_COST",str(unit_cost))

gosub update_header_tots
callpoint!.setDevObject("qty_this_row",num(callpoint!.getUserInput()))
callpoint!.setDevObject("cost_this_row",unit_cost);rem setting both qty and cost because cost may have changed based on qty break
[[POE_REQDET.WAREHOUSE_ID.AVAL]]
rem --- Warehouse ID - After Validataion
	gosub validate_whse_item
[[POE_REQDET.AGDR]]
rem --- After Grid Display Row

po_line_code$=callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE")
if cvs(po_line_code$,2)<>"" then  
    gosub update_line_type_info
endif


total_amt=num(callpoint!.getDevObject("total_amt"))
total_amt=total_amt+round(num(callpoint!.getColumnData("POE_REQDET.REQ_QTY"))*num(callpoint!.getColumnData("POE_REQDET.UNIT_COST")),2)
callpoint!.setDevObject("total_amt",str(total_amt))

	poc_linecode_dev=fnget_dev("POC_LINECODE")
	dim poc_linecode$:fnget_tpl$("POC_LINECODE")
	po_line_code$=callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE")
	read record(poc_linecode_dev,key=firm_id$+po_line_code$,dom=*next)poc_linecode$
	line_type$=poc_linecode.line_type$
	gosub enable_by_line_type
[[POE_REQDET.ITEM_ID.AVAL]]
	
gosub validate_whse_item
if pos("ABORT"=callpoint!.getStatus())<>0
	callpoint!.setUserInput("")
endif

	poc_linecode_dev=fnget_dev("POC_LINECODE")
	dim poc_linecode$:fnget_tpl$("POC_LINECODE")
	po_line_code$=callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE")
	read record(poc_linecode_dev,key=firm_id$+po_line_code$,dom=*next)poc_linecode$
	line_type$=poc_linecode.line_type$
	gosub enable_by_line_type
[[POE_REQDET.<CUSTOM>]]
update_line_type_info:
	poc_linecode_dev=fnget_dev("POC_LINECODE")
	dim poc_linecode$:fnget_tpl$("POC_LINECODE")

	if callpoint!.getVariableName()="POE_REQDET.PO_LINE_CODE" then
		po_line_code$=callpoint!.getUserInput()
	else
		po_line_code$=callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE")
	endif
	read record(poc_linecode_dev,key=firm_id$+po_line_code$,dom=*next)poc_linecode$
	line_type$=poc_linecode.line_type$
	callpoint!.setStatus("ENABLE:"+poc_linecode.line_type$)
	callpoint!.setDevObject("line_type",poc_linecode.line_type$)

return

validate_whse_item:
	ivm_itemwhse_dev=fnget_dev("IVM_ITEMWHSE")
	dim ivm_itemwhse$:fnget_tpl$("IVM_ITEMWHSE")
	change_flag=0

	if callpoint!.getVariableName()="POE_REQDET.ITEM_ID" then
		item_id$=callpoint!.getUserInput()
		if item_id$<>callpoint!.getColumnData("POE_REQDET.ITEM_ID") then 
			change_flag=1
		 endif
	else
		item_id$=callpoint!.getColumnData("POE_REQDET.ITEM_ID")
	endif
	if callpoint!.getVariableName()="POE_REQDET.WAREHOUSE_ID" then
		whse$=callpoint!.getUserInput()
		if whse$<>callpoint!.getColumnData("POE_REQDET.WAREHOUSE_ID") then
			change_flag=1
		endif
	else
		whse$=callpoint!.getColumnData("POE_REQDET.WAREHOUSE_ID")
	endif
	
	if change_flag and cvs(item_id$,2)<>"" then
		read record (ivm_itemwhse_dev,key=firm_id$+whse$+item_id$,knum="PRIMARY",dom=missing_warehouse) ivm_itemwhse$
		ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")
		dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
		read record(ivm_itemmast_dev,key=firm_id$+item_id$)ivm_itemmast$
		callpoint!.setColumnData("POE_REQDET.UNIT_MEASURE",ivm_itemmast.purchase_um$)
		callpoint!.setColumnData("POE_REQDET.CONV_FACTOR",str(ivm_itemmast.conv_factor))
		if num(callpoint!.getColumnData("POE_REQDET.CONV_FACTOR"))=0 then callpoint!.setColumnData("POE_REQDET.CONV_FACTOR",str(1))
		if cvs(callpoint!.getColumnData("POE_REQDET.LOCATION"),2)="" then callpoint!.setColumnData("POE_REQDET.LOCATION","STOCK")
		callpoint!.setColumnData("POE_REQDET.UNIT_COST",str(num(callpoint!.getColumnData("POE_REQDET.CONV_FACTOR"))*ivm_itemwhse.unit_cost))
		callpoint!.setStatus("REFRESH")
	endif
return
		
missing_warehouse:
	msg_id$="IV_ITEM_WHSE_INVALID"
	dim msg_tokens$[1]
	msg_tokens$[1]=whse$
	gosub disp_message
	callpoint!.setStatus("ABORT")

return

update_header_tots:

if pos(".AVAL"=callpoint!.getCallpointEvent())
	if callpoint!.getVariableName()="POE_REQDET.REQ_QTY"
		new_qty=num(callpoint!.getUserInput())
		new_cost=num(callpoint!.getColumnData("POE_REQDET.UNIT_COST"))
	else
		new_qty=num(callpoint!.getColumnData("POE_REQDET.REQ_QTY"))
		new_cost=num(callpoint!.getUserInput())
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
	new_cost=num(callpoint!.getColumnData("POE_REQDET.UNIT_COST"))
	new_qty=num(callpoint!.getColumnData("POE_REQDET.REQ_QTY"))
	callpoint!.setDevObject("qty_this_row",0)
	callpoint!.setDevObject("cost_this_row",0)
	gosub calculate_header_tots
	callpoint!.setDevObject("qty_this_row",new_cost)
	callpoint!.setDevObject("cost_this_row",new_qty)
endif

return

calculate_header_tots:

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
enable_by_line_type:
rem line_type$ : input
rem ==========================================================================

	this_row=callpoint!.getValidationRow()
	if callpoint!.getDevObject("SF_installed")="Y"
		if line_type$="N"
			callpoint!.setColumnEnabled(this_row,"POE_REQDET.WO_NO",1)
			callpoint!.setColumnEnabled(this_row,"POE_REQDET.WK_ORD_SEQ_REF",0)
		else
			whse$=callpoint!.getColumnData("POE_REQDET.WAREHOUSE_ID")
			if callpoint!.getCallpointEvent()="POE_REQDET.ITEM_ID.AVAL"
				item$=callpoint!.getUserInput()
			else
				item$=callpoint!.getColumnData("POE_REQDET.ITEM_ID")
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
				callpoint!.setColumnEnabled(this_row,"POE_REQDET.WO_NO",1)
				callpoint!.setColumnEnabled(this_row,"POE_REQDET.WK_ORD_SEQ_REF",0)
			else
				callpoint!.setColumnEnabled(this_row,"POE_REQDET.WO_NO",0)
				callpoint!.setColumnEnabled(this_row,"POE_REQDET.WK_ORD_SEQ_REF",0)
			endif
		endif
	else
		callpoint!.setColumnEnabled(this_row,"POE_REQDET.WO_NO",0)
		callpoint!.setColumnEnabled(this_row,"POE_REQDET.WK_ORD_SEQ_REF",0)
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
