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

rem print "AREC line_no: ",callpoint!.getColumnData("POE_REQDET.PO_LINE_NO")
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
[[POE_REQDET.AGRE]]
rem --- check data to see if o.k. to leave row (only if the row isn't marked as deleted)

rem print "col data: ",callpoint!.getColumnData("POE_REQDET.REQ_QTY")
rem print "undo data: ",callpoint!.getColumnUndoData("POE_REQDET.REQ_QTY")
rem print "disk data: ",callpoint!.getColumnDiskData("POE_REQDET.REQ_QTY")

if callpoint!.getGridRowDeleteStatus(num(callpoint!.getValidationRow()))<>"Y"

	ok_to_write$="Y"

	if cvs(callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE"),3)="" or 
:		cvs(callpoint!.getColumnData("POE_REQDET.WAREHOUSE_ID"),3)="" 
		ok_to_write$="N"
		focus_column$="POE_REQDET.PO_LINE_CODE"
	endif

	if pos(cvs(callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE"),3)="SD")<>0 
		if cvs(callpoint!.getColumnData("POE_REQDET.ITEM_ID"),3)="" or
:		num(callpoint!.getColumnData("POE_REQDET.CONV_FACTOR"))<=0 or
:		num(callpoint!.getColumnData("POE_REQDET.UNIT_COST"))<0 or
:		num(callpoint!.getColumnData("POE_REQDET.REQ_QTY"))<=0 or
:		cvs(callpoint!.getColumnData("POE_REQDET.REQD_DATE"),3)="" 
			ok_to_write$="N"
			focus_column$="POE_REQDET.ITEM_ID"
		endif
	endif

	if cvs(callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE"),3)="N" 
		if num(callpoint!.getColumnData("POE_REQDET.UNIT_COST"))<0 or
:		num(callpoint!.getColumnData("POE_REQDET.REQ_QTY"))<=0 or
:		cvs(callpoint!.getColumnData("POE_REQDET.REQD_DATE"),3)="" 	
			ok_to_write$="N"
			focus_column$="POE_REQDET.ORDER_MEMO"
		endif
	endif

	if cvs(callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE"),3)="O" 
		if num(callpoint!.getColumnData("POE_REQDET.UNIT_COST"))<0 or
:		cvs(callpoint!.getColumnData("POE_REQDET.REQD_DATE"),3)="" 	
			ok_to_write$="N"
			focus_column$="POE_REQDET.ORDER_MEMO"
		endif
	endif

	if pos(cvs(callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE"),3)="MNOV")<>0 
		if cvs(callpoint!.getColumnData("POE_REQDET.ORDER_MEMO"),3)="" 
			ok_to_write$="N"
			focus_column$="POE_REQDET.ORDER_MEMO"
		endif
	endif

	if callpoint!.getHeaderColumnData("POE_REQHDR.DROPSHIP")="Y" and callpoint!.getDevObject("OP_installed")="Y"
		if pos(cvs(callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE"),3)="DSNO")<>0
			if cvs(callpoint!.getColumnData("POE_REQDET.SO_INT_SEQ_REF"),3)="" 
				ok_to_write$="N"
				focus_column$="POE_REQDET.SO_INT_SEQ_REF"
			endif
		endif
	endif

	if ok_to_write$<>"Y"
		msg_id$="PO_REQD_DET"
		gosub disp_message
		callpoint!.setFocus(num(callpoint!.getValidationRow()),focus_column$)
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
[[POE_REQDET.ITEM_ID.AINV]]
rem --- remember row/column we're on so we can force focus when we return from synonym lookup

if cvs(callpoint!.getUserInput(),3)<>""

	declare BBjStandardGrid grid!
	grid! = util.getGrid(Form!)
	return_to_row = grid!.getSelectedRow()
	return_to_col = grid!.getSelectedColumn()

	rem --- see if they entered a synonym, if so, display (if only one of them), if no match, or more than one match, launch bam_inquiry on synonym file

	ivm_itemsyn_dev=fnget_dev("IVM_ITEMSYN")
	dim ivm_itemsyn$:fnget_tpl$("IVM_ITEMSYN")

	read (ivm_itemsyn_dev,key=firm_id$+callpoint!.getUserInput(),dom=*next)
	read_count=0
	found_count=0
	found_item$=""

	while read_count<2
		read record (ivm_itemsyn_dev,end=*break)ivm_itemsyn$
		if ivm_itemsyn.firm_id$=firm_id$ and ivm_itemsyn.item_synonym$=callpoint!.getUserInput()
			found_count=found_count+1
			found_item$=ivm_itemsyn.item_id$
		endif
		read_count=read_count+1
	wend

	if found_count=1
		callpoint!.setUserInput(found_item$)
		callpoint!.setStatus("")
	else
		call stbl("+DIR_SYP")+"bac_key_template.bbj","IVM_ITEMSYN","PRIMARY",key_tpl$,table_chans$[all],rd_stat$
		dim return_key$:key_tpl$

		dim search_defs$[2]
		search_defs$[0]="IVM_ITEMSYN.ITEM_SYNONYM"
		search_defs$[1]=callpoint!.getRawUserInput()
		search_defs$[2]="A"

		call stbl("+DIR_SYP")+"bam_inquiry.bbj",gui_dev,Form!,"IVM_ITEMSYN","LOOKUP",
:			table_chans$[all],firm_id$,"PRIMARY",return_key$,filter_defs$[all],search_defs$[all]
		if cvs(return_key$,3)<>""
			callpoint!.setUserInput(return_key.item_id$)	
			callpoint!.setStatus("ACTIVATE")
		else
			callpoint!.setStatus("ABORT")
		endif
		util.forceEdit(Form!, return_to_row, return_to_col)
	endif
else
	callpoint!.setStatus("ABORT")
endif
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
		callpoint!.setColumnData("POE_REQDET.WO_SEQ_REF","")


endif

if callpoint!.getDevObject("line_type")="O" 
	callpoint!.setColumnData("POE_REQDET.REQ_QTY","1")
else
	callpoint!.setColumnData("POE_REQDET.REQ_QTY","")
endif

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
[[POE_REQDET.ITEM_ID.AVAL]]
	
gosub validate_whse_item
if pos("ABORT"=callpoint!.getStatus())<>0
	callpoint!.setUserInput("")
endif







	
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
rem	if cvs(item_id$,2)<>"" then
		read record (ivm_itemwhse_dev,key=firm_id$+whse$+item_id$,knum=0,dom=missing_warehouse) ivm_itemwhse$
		ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")
		dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
		read record(ivm_itemmast_dev,key=firm_id$+item_id$)ivm_itemmast$
		callpoint!.setColumnData("POE_REQDET.UNIT_MEASURE",ivm_itemmast.purchase_um$)
		callpoint!.setColumnData("POE_REQDET.CONV_FACTOR",str(ivm_itemmast.conv_factor))
		if num(callpoint!.getColumnData("POE_REQDET.CONV_FACTOR"))=0 then callpoint!.setColumnData("POE_REQDET.CONV_FACTOR",str(1))
		if cvs(callpoint!.getColumnData("POE_REQDET.LOCATION"),2)="" then callpoint!.setColumnData("POE_REQDET.LOCATION","STOCK")
		callpoint!.setColumnData("POE_REQDET.UNIT_COST",str(num(callpoint!.getColumnData("POE_REQDET.CONV_FACTOR"))*ivm_itemwhse.unit_cost))
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
