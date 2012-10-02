[[POE_REQDET.BGDR]]
	find_item$=callpoint!.getColumnData("POE_REQDET.ITEM_ID")
	gosub get_item_desc
[[POE_REQDET.WAREHOUSE_ID.BINP]]
rem --- old version defaulted whse to the ship-to one

if cvs(callpoint!.getColumnData("POE_REQDET.WAREHOUSE_ID"),3)=""
	callpoint!.setColumnData("POE_REQDET.WAREHOUSE_ID",callpoint!.getHeaderColumnData("POE_REQHDR.WAREHOUSE_ID"))
	callpoint!.setStatus("REFRESH:POE_REQDET.WAREHOUSE_ID")
endif
[[POE_REQDET.AGRN]]
rem -- set default line code 

callpoint!.setColumnData("POE_REQDET.PO_LINE_CODE",str(callpoint!.getDevObject("dflt_po_line_code")))
gosub update_line_type_info

x$=stbl("+POE_REQDET_ITEM_DESC","")

callpoint!.setStatus("MODIFIED-REFRESH")
[[POE_REQDET.PO_LINE_CODE.AVAL]]
rem --- Line Code - After Validataion

	gosub update_line_type_info

        if cvs(callpoint!.getUserInput(),2)<>cvs(callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE"),2) then

		callpoint!.setColumnData("POE_REQDET.CONV_FACTOR","")
		callpoint!.setColumnData("POE_REQDET.FORECAST","")
		callpoint!.setColumnData("POE_REQDET.ITEM_ID","")
		callpoint!.setColumnData("POE_REQDET.LEAD_TIM_FLG","")
		callpoint!.setColumnData("POE_REQDET.LOCATION","")
		callpoint!.setColumnData("POE_REQDET.NOT_B4_DATE",callpoint!.getHeaderColumnData("POE_REQHDR.NOT_B4_DATE"))
		callpoint!.setColumnData("POE_REQDET.NS_ITEM_ID","")
		callpoint!.setColumnData("POE_REQDET.ORDER_MEMO","")
		callpoint!.setColumnData("POE_REQDET.PO_MSG_CODE",callpoint!.getHeaderColumnData("POE_REQHDR.PO_MSG_CODE"))
		callpoint!.setColumnData("POE_REQDET.PROMISE_DATE",callpoint!.getHeaderColumnData("POE_REQHDR.PROMISE_DATE"))
		callpoint!.setColumnData("POE_REQDET.REQD_DATE",callpoint!.getHeaderColumnData("POE_REQHDR.REQD_DATE") )
		callpoint!.setColumnData("POE_REQDET.REQ_QTY","")
		callpoint!.setColumnData("POE_REQDET.SO_INT_SEQ_REF","")
		callpoint!.setColumnData("POE_REQDET.SOURCE_CODE","")
		callpoint!.setColumnData("POE_REQDET.UNIT_COST","")
		callpoint!.setColumnData("POE_REQDET.UNIT_MEASURE","")
		callpoint!.setColumnData("POE_REQDET.WAREHOUSE_ID",callpoint!.getHeaderColumnData("POE_REQHDR.WAREHOUSE_ID"))
		callpoint!.setColumnData("POE_REQDET.WO_NO","")
		callpoint!.setColumnData("POE_REQDET.WO_SEQ_REF","")

		
	endif
	
[[POE_REQDET.REQ_QTY.AVAL]]
rem --- assume we need to call poc.ua to retrieve unit cost from ivm-05, at least that's what v6 did here
[[POE_REQDET.AREC]]
rem --- After Array Transfer
	if cvs(rec_data.po_line_code$,2)="" then
		wgrid!=form!.getChildWindow(1109).getControl(5900)
		wrow=wgrid!.getSelectedRow()
		wgrid!.setSelectedCell(wrow,0)
	endif
	gosub update_line_type_info
[[POE_REQDET.WAREHOUSE_ID.AVAL]]
rem --- Warehouse ID - After Validataion
	gosub validate_whse_item
[[POE_REQDET.AGDR]]
rem --- After Grid Display Row
	po_line_code$=callpoint!.getColumnData("POE_REQDET.PO_LINE_CODE")
	if cvs(po_line_code$,2)<>"" then  
	    gosub update_line_type_info
	endif

[[POE_REQDET.ITEM_ID.AVAL]]
rem --- did user enter item#, or are we trying to do synonym lookup, or ? for custom lookup

find_item$=callpoint!.getUserInput()
found_item=0
ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")
dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")

rem --- if userInput() is a "?", call custom inquiry

	if cvs(callpoint!.getUserInput(),3)="?"
		call stbl("+DIR_SYP")+"bam_run_prog.bbj","IVC_ITEMLOOKUP",stbl("+USER_ID"),"MNT","",table_chans$[all]
		find_item$=callpoint!.getDevObject("find_item")
		read record (ivm_itemmast_dev,key=firm_id$+find_item$,dom=*endif)ivm_itemmast$
		callpoint!.setUserInput(find_item$)
		x$=stbl("+POE_REQDET_ITEM_DESC",cvs(ivm_itemmast.item_desc$,3))
		gosub validate_whse_item
	else
		read record (ivm_itemmast_dev,key=firm_id$+find_item$,dom=*next)ivm_itemmast$;found_item=1
			if found_item=1
				x$=stbl("+POE_REQDET_ITEM_DESC",cvs(ivm_itemmast.item_desc$,3))
				gosub validate_whse_item
			else
				rem --- otherwise, try synonym lookup
				call stbl("+DIR_SYP")+"bac_key_template.bbj","IVM_ITEMSYN","PRIMARY",key_tpl$,table_chans$[all],rd_stat$
				dim return_key$:key_tpl$

				call stbl("+DIR_SYP")+"bam_inquiry.bbj",gui_dev,Form!,"IVM_ITEMSYN","LOOKUP",
:					table_chans$[all],firm_id$,"PRIMARY",return_key$
				if cvs(return_key$,3)<>""
					find_item$=return_key.item_id$
					read record (ivm_itemmast_dev,key=firm_id$+find_item$,dom=*next)ivm_itemmast$
					x$=stbl("+POE_REQDET_ITEM_DESC",cvs(ivm_itemmast.item_desc$,3))
					callpoint!.setUserInput(ivm_itemmast.item_id$)
					gosub validate_whse_item
				endif
			endif
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
	
rem	if change_flag and cvs(item_id$,2)<>"" then
	if cvs(item_id$,2)<>"" then
		read record (ivm_itemwhse_dev,key=firm_id$+whse$+item_id$,dom=missing_warehouse) ivm_itemwhse$
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

get_item_desc:

	ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")

	read record (ivm_itemmast_dev,key=firm_id$+find_item$,dom=*next)ivm_itemmast$
	x$=stbl("+POE_REQDET_ITEM_DESC",cvs(ivm_itemmast.item_desc$,3))

return
		
