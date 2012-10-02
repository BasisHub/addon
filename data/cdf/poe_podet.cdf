[[POE_PODET.WAREHOUSE_ID.AVAL]]
rem --- Warehouse ID - After Validataion

	if callpoint!.getHeaderColumnData("POE_POHDR.WAREHOUSE_ID")<>pad(callpoint!.getUserInput(),2) then
		msg_id$="PO_WHSE_NOT_MATCH"
		gosub disp_message
	endif

	gosub validate_whse_item
[[POE_PODET.AGDR]]
rem --- After Grid Display Row
	po_line_code$=callpoint!.getColumnData("POE_PODET.PO_LINE_CODE")
	if cvs(po_line_code$,2)<>"" then  
    		gosub update_line_type_info
	endif
[[POE_PODET.PO_LINE_CODE.AVAL]]
	gosub update_line_type_info

	if cvs(callpoint!.getUserInput(),2)<>cvs(callpoint!.getColumnData("POE_PODET.PO_LINE_CODE"),2)  then
		callpoint!.setColumnData("POE_PODET.CONV_FACTOR","")
		callpoint!.setColumnData("POE_PODET.FORECAST","")
		callpoint!.setColumnData("POE_PODET.ITEM_ID","")
		callpoint!.setColumnData("POE_PODET.LEAD_TIM_FLG","")
		callpoint!.setColumnData("POE_PODET.LOCATION","")
		callpoint!.setColumnData("POE_PODET.NOT_B4_DATE",callpoint!.getHeaderColumnData("POE_POHDR.NOT_B4_DATE"))
		callpoint!.setColumnData("POE_PODET.NS_ITEM_ID","")
		callpoint!.setColumnData("POE_PODET.ORDER_MEMO","")
		callpoint!.setColumnData("POE_PODET.PO_MSG_CODE",callpoint!.getHeaderColumnData("POE_POHDR.PO_MSG_CODE"))
		callpoint!.setColumnData("POE_PODET.PROMISE_DATE",callpoint!.getHeaderColumnData("POE_POHDR.PROMISE_DATE"))
		callpoint!.setColumnData("POE_PODET.REQD_DATE",callpoint!.getHeaderColumnData("POE_POHDR.REQD_DATE") )
		callpoint!.setColumnData("POE_PODET.REQ_QTY","")
		callpoint!.setColumnData("POE_PODET.SEQUENCE_NO","")
		callpoint!.setColumnData("POE_PODET.SOURCE_CODE","")
		callpoint!.setColumnData("POE_PODET.UNIT_COST","")
		callpoint!.setColumnData("POE_PODET.UNIT_MEASURE","")
		callpoint!.setColumnData("POE_PODET.WAREHOUSE_ID",callpoint!.getHeaderColumnData("POE_POHDR.WAREHOUSE_ID"))
		callpoint!.setColumnData("POE_PODET.WO_NO","")
	
	endif
[[POE_PODET.ITEM_ID.AVAL]]
rem --- Item ID - After Column Validataion
	gosub validate_whse_item
[[POE_PODET.ARAR]]
	if cvs(rec_data.po_line_code$,2)="" then
		wgrid!=form!.getChildWindow(1109).getControl(5900)
		wrow=wgrid!.getSelectedRow()
		wgrid!.setSelectedCell(wrow,0)
	endif

	gosub update_line_type_info
[[POE_PODET.<CUSTOM>]]
update_line_type_info:

	poc_linecode_dev=fnget_dev("POC_LINECODE")
	dim poc_linecode$:fnget_tpl$("POC_LINECODE")
	if callpoint!.getVariableName()="POE_PODET.PO_LINE_CODE" then
		po_line_code$=callpoint!.getUserInput()
	else
		po_line_code$=callpoint!.getColumnData("POE_PODET.PO_LINE_CODE")
	endif
	read record(poc_linecode_dev,key=firm_id$+po_line_code$,dom=*next)poc_linecode$
	callpoint!.setStatus("ENABLE:"+poc_linecode.line_type$)

return

	validate_whse_item:
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
		endif
	return
		
	missing_warehouse:
		callpoint!.setStatus("ABORT")
	
	return
