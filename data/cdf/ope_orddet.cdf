[[OPE_ORDDET.UNIT_COST.AVAL]]
rem --- Disable Cost field if there is a value in it
g!=form!.getChildWindow(1109).getControl(5900)
enable_color!=g!.getCellBackColor(0,0)
disable_color!=g!.getLineColor()

r=g!.getSelectedRow()
if num(callpoint!.getUserInput())=0
 	g!.setCellEditable(r,5,1)
 	g!.setCellBackColor(r,5,enable_color!)
else
	g!.setCellEditable(r,5,0)
	g!.setCellBackColor(r,5,disable_color!)
endif
[[OPE_ORDDET.EXT_PRICE.AVEC]]
rem --- update header
	gosub calc_grid_tots
	gosub disp_totals
[[OPE_ORDDET.UNIT_PRICE.AVAL]]
rem --- See if this should be repriced
rem 	if num(callpoint!.getUserInput())<0
rem 		dim op_chans[6]
rem 		op_chans[1]=fnget_dev("IVM_ITEMMAST")
rem 		op_chans[2]=fnget_dev("IVM_ITEMWHSE")
rem 		op_chans[4]=fnget_dev("IVM_ITEMPRIC")
rem 		op_chans[5]=fnget_dev("ARS_PARAMS")
rem 		op_chans[6]=fnget_dev("IVS_PARAMS")
rem 		whs$=callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
rem 		item$=callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
rem 		listcd$=""
rem 		cust$=callpoint!.getColumnData("OPE_ORDDET.CUSTOMER_ID")
rem 		date$=user_tpl.order_date$
rem 		priccd$=user_tpl.price_code$
rem 		ordqty=num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
rem 		type_price$=""
rem 		call stbl("+DIR_PGM")+"opc_pc.aon",op_chans[all],firm_id$,whs$,item$,listcd$,cust$,date$,priccd$,ordqty,type_price$,price,disc,status
rem 		callpoint!.setUserInput(str(price))
rem 	endif

rem --- Calc Extension
	newqty=num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	unit_price=num(callpoint!.getUserInput())
	new_ext_price=newqty*unit_price
	callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE",str(new_ext_price))
	callpoint!.setStatus("MODIFIED-REFRESH")
rem --- update header
	gosub calc_grid_tots
	gosub disp_totals
[[OPE_ORDDET.AUDE]]
rem --- redisplay totals
	gosub calc_grid_tots
	gosub disp_totals
[[OPE_ORDDET.ADEL]]
rem --- redisplay totals
	gosub calc_grid_tots
	gosub disp_totals
[[OPE_ORDDET.WAREHOUSE_ID.AVAL]]
item$=callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
wh$=callpoint!.getUserInput()
gosub set_avail
[[OPE_ORDDET.QTY_BACKORD.BINP]]
item$=callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
wh$=callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
gosub check_new_row
[[OPE_ORDDET.LINE_CODE.BINP]]
item$=callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
wh$=callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
gosub check_new_row
[[OPE_ORDDET.WAREHOUSE_ID.BINP]]
item$=callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
wh$=callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
gosub check_new_row
[[OPE_ORDDET.ORDER_MEMO.BINP]]
item$=callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
wh$=callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
gosub check_new_row
[[OPE_ORDDET.UNIT_COST.BINP]]
item$=callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
wh$=callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
gosub check_new_row
[[OPE_ORDDET.UNIT_PRICE.BINP]]
item$=callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
wh$=callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
gosub check_new_row
[[OPE_ORDDET.QTY_ORDERED.BINP]]
item$=callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
wh$=callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
gosub check_new_row
[[OPE_ORDDET.QTY_SHIPPED.BINP]]
item$=callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
wh$=callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
gosub check_new_row
[[OPE_ORDDET.EXT_PRICE.BINP]]
item$=callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
wh$=callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
gosub check_new_row
[[OPE_ORDDET.ITEM_ID.BINP]]
item$=callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
wh$=callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
gosub check_new_row
[[OPE_ORDDET.ITEM_ID.AVAL]]
item$=callpoint!.getUserInput()
wh$=callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
gosub set_avail

rem --- Get unit cost
ivm02_dev=fnget_dev("IVM_ITEMWHSE")
dim ivm02a$:fnget_tpl$("IVM_ITEMWHSE")
while 1
	readrecord(ivm02_dev,key=firm_id$+callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")+callpoint!.getUserInput(),dom=*break)ivm02a$
	callpoint!.setColumnData("OPE_ORDDET.UNIT_COST",str(ivm02a.unit_cost))
	break
wend
callpoint!.setStatus("REFRESH")
[[OPE_ORDDET.QTY_ORDERED.AVEC]]
rem --- Go get Lot/Serial Numbers if needed
	gosub calc_grid_tots
	gosub disp_totals
	ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")
	opc_linecode_dev=fnget_dev("OPC_LINECODE")
	dim opc_linecode$:fnget_tpl$("OPC_LINECODE")
	ivs01_dev=fnget_dev("IVS_PARAMS")
	dim ivs01a$:fnget_tpl$("IVS_PARAMS")
	readrecord(ivs01_dev,key=firm_id$+"IV00")ivs0a$
	ar_type$=callpoint!.getColumnData("OPE_ORDDET.AR_TYPE")
	cust$=callpoint!.getColumnData("OPE_ORDDET.CUSTOMER_ID")
	ord$=callpoint!.getColumnData("OPE_ORDDET.ORDER_NO")
	seq$=callpoint!.getColumnData("OPE_ORDDET.LINE_NO")
	line_code$=callpoint!.getColumnData("OPE_ORDDET.LINE_CODE")
	while 1
		readrecord(opc_linecode_dev,key=firm_id$+line_code$,err=*break)opc_linecode$
		if pos(opc_linecode.line_type$="SP")
			readrecord(ivm_itemmast_dev,key=firm_id$+item$,err=*break)ivm01a$
			if pos(ivm01a.lotser_item$="Y") and
:					callpoint!.getColumnData("OPE_ORDDET.COMMIT_FLAG")="Y" and
:					ivm01a.inventoried$="Y"  and
:					pos(ivs01a.lotser_flag$="LS")
				user_id$=stbl("+USER_ID")
				dim dflt_data$[1,1]
				key_pfx$=firm_id$+ar_type$+cust$+ord$+seq$
				call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:					"OPE_ORDLSDET",
:					user_id$,
:					"MNT",
:					key_pfx$,
:					table_chans$[all],
:					"",
:					dflt_data$[all]
			endif
		endif
		break
	wend
rem	glns!=bbjapi().getNamespace("GLNS","GL Dist",1)
rem	amt_dist=num(glns!.getValue("dist_amt"))
rem	if amt_dist<>num(callpoint!.getColumnData("APE_MANCHECKDET.INVOICE_AMT"))
rem		msg_id$="AP_NOBAL"
rem		gosub disp_message
rem	endif
rem	wk =Form!.getChildWindow(1109).getControl(5900).getSelectedRow()
rem	Form!.getChildWindow(1109).getControl(5900).focus()
rem --- Form!.getChildWindow(1109).getControl(5900).startEdit(wk,5)
rem --- Form!.focus()
	
rem	endif
[[OPE_ORDDET.BWRI]]
rem --- commit inventory
escape;rem bwri
	qty=rec_data.qty_ordered
	qty1=callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED")
escape
[[OPE_ORDDET.ADIS]]
rem ---display extended price
	ordqty=num(rec_data.qty_ordered)
	unit_price=num(rec_data.unit_price)
	new_ext_price=ordqty*unit_price
	callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE",str(new_ext_price))
	callpoint!.setStatus("MODIFIED-REFRESH")
[[OPE_ORDDET.AGDR]]
rem --- set enable/disable based on line type
	line_code$=rec_data.line_code$
	if cvs(line_code$,2)<>""
rem		callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE",rec_data.str(ext_price))
		opc_linecode_dev=fnget_dev("OPC_LINECODE")
		dim opc_linecode$:fnget_tpl$("OPC_LINECODE")
		read record (opc_linecode_dev,key=firm_id$+line_code$,dom=*next)opc_linecode$
		callpoint!.setStatus("ENABLE:"+opc_linecode.line_type$)
	endif
[[OPE_ORDDET.QTY_SHIPPED.AVAL]]
rem ---recalc quantities and extended price
	shipqty=num(callpoint!.getUserInput())
	ordqty=num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	if shipqty>ordqty
		callpoint!.setUserInput(str(user_tpl.line_shipqty))
		msg_id$="SHIP_EXCEEDS_ORD"
		gosub disp_message
		callpoint!.setStatus("ABORT-REFRESH")
	else
		callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD",str(ordqty-shipqty))
		unit_price=num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
		new_ext_price=ordqty*unit_price
		callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE",str(new_ext_price))
		callpoint!.setStatus("MODIFIED-REFRESH")
	endif
	user_tpl.line_shipqty=num(callpoint!.getUserInput())
rem --- update header
	gosub calc_grid_tots
	gosub disp_totals
[[OPE_ORDDET.QTY_ORDERED.AVAL]]
rem ---recalc quantities and extended price
	newqty=num(callpoint!.getUserInput())
	if num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE")) = 0
		qty_ord=num(callpoint!.getUserInput())
		gosub pricing
	endif
	callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD","0")
	callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED",str(newqty))
	unit_price=num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
	new_ext_price=newqty*unit_price
	callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE",str(new_ext_price))
	callpoint!.setStatus("MODIFIED-REFRESH")
rem --- update header
	gosub calc_grid_tots
	gosub disp_totals
[[OPE_ORDDET.QTY_BACKORD.AVAL]]
rem ---recalc quantities and extended price
	boqty=num(callpoint!.getUserInput())
	ordqty=num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	if boqty>ordqty
		callpoint!.setUserInput(str(user_tpl.line_boqty))
		msg_id$="BO_EXCEEDS_ORD"
		gosub disp_message
		callpoint!.setStatus("ABORT-REFRESH")
	else
		shipqty=ordqty-boqty
		callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED",str(shipqty))
		unit_price=num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
		new_ext_price=ordqty*unit_price
		callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE",str(new_ext_price))
		callpoint!.setStatus("MODIFIED-REFRESH")
	endif
	user_tpl.line_boqty=num(callpoint!.getUserInput())
rem --- update header
	gosub calc_grid_tots
	gosub disp_totals
[[OPE_ORDDET.<CUSTOM>]]
calc_grid_tots:
	recVect!=GridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs=recVect!.size()
	tamt=0
	if numrecs>0
		for reccnt=0 to numrecs-1
			gridrec$=recVect!.getItem(reccnt)
			if cvs(gridrec$,3)<>""
				if callpoint!.getGridRowDeleteStatus(reccnt)<>"Y"
					opc_linecode_dev=fnget_dev("OPC_LINECODE")
					dim opc_linecode$:fnget_tpl$("OPC_LINECODE")
					read record (opc_linecode_dev,key=firm_id$+gridrec.line_code$,dom=*next)opc_linecode$
					if pos(opc_linecode$="SPN")
						tamt=tamt+(gridrec.unit_price*gridrec.qty_ordered)
					else
						tamt=tamt+gridrec.ext_price
					endif
				endif
			endif
		next reccnt
		user_tpl.ord_tot=tamt
	endif
return

disp_totals: rem --- get context and ID of total amount display control, and redisplay w/ amts from calc_tots
	tamt!=UserObj!.getItem(num(user_tpl.ord_tot_1$))
	tamt!.setValue(user_tpl.ord_tot)
return

update_totals: rem --- Update Order/Invoice Totals & Commit Inventory
rem --- need to send in wh_id$, item_id$, ls_id$, and qty
	dim iv_files[44],iv_info$[3],iv_params$[4],iv_refs$[11],iv_refs[5]
	iv_files[0]=fnget_dev("GLS_PARAMS")
	iv_files[1]=fnget_dev("IVM_ITEMMAST")
	iv_files[2]=fnget_dev("IVM_ITEMWHSE")
	iv_files[4]=fnget_dev("IVM_ITEMTIER")
	iv_files[5]=fnget_dev("IVM_ITEMVEND")
	iv_files[7]=fnget_dev("IVM_LSMASTER")
	iv_files[12]=fnget_dev("IVM_ITEMACCT")
	iv_files[17]=fnget_dev("IVM_LSACT")
	iv_files[41]=fnget_dev("IVT_LSTRANS")
	iv_files[42]=fnget_dev("IVX_LSCUST")
	iv_files[43]=fnget_dev("IVX_LSVEND")
	iv_files[44]=fnget_dev("IVT_ITEMTRAN")
	ivs01_dev=fnget_dev("IVS_PARAMS")
	dim ivs01a$:fnget_tpl$("IVS_PARAMS")
	readrecord(ivs01_dev,key=firm_id$+"IV00")ivs01a$
	iv_info$[1]=wh_id$
	iv_info$[2]=item_id$
	iv_info$[3]=ls_id$
	iv_refs[0]=qty
escape; rem decisions have to be made about ivc_ua (ivc_itemupt.aon)
	U[0]=U[0]+S8*line_sign
	U[1]=U[1]+S9*line_sign
	U[2]=U[2]+S0*line_sign
	while 1
		if pos(S8$(2,1)="SP")=0 break
		if s8$(3,1)="Y" or a0$(21,1)="P" break; REM "Drop ship or quote
		if line_sign>0 iv_action$="OE" else iv_action$="UC"
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon",iv_action$,iv_files[all],ivs01a$,
:			iv_info$[all],iv_refs$[all],iv_refs[all],iv_status
		break
	wend
return

pricing: rem "Call Pricing routine
	ivm02_dev=fnget_dev("IVM_ITEMWHSE")
	dim ivm02a$:fnget_tpl$("IVM_ITEMWHSE")
	ivs01_dev=fnget_dev("IVS_PARAMS")
	dim ivs01a$:fnget_tpl$("IVS_PARAMS")
	ordqty=qty_ord
	wh$=callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
	item$=callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	ar_type$=callpoint!.getColumnData("OPE_ORDDET.AR_TYPE")
	cust$=callpoint!.getColumnData("OPE_ORDDET.CUSTOMER_ID")
	ord$=callpoint!.getColumnData("OPE_ORDDET.ORDER_NO")
	dim pc_files[6]
	pc_files[1]=fnget_dev("IVM_ITEMMAST")
	pc_files[2]=fnget_dev("IVM_ITEMWHSE")
	pc_files[3]=fnget_dev("IVM_ITEMPRIC")
	pc_files[4]=fnget_dev("IVC_PRICCODE")
	pc_files[5]=fnget_dev("ARS_PARAMS")
	pc_files[6]=ivs01_dev
	call stbl("+DIR_PGM")+"opc_pc.aon",pc_files[all],firm_id$,wh$,item$,user_tpl.price_code$,cust$,
:		user_tpl.order_date$,user_tpl.pricing_code$,ordqty,typeflag$,price,disc,status
	if price=0
		msg_id$="ENTER_PRICE"
		gosub disp_message
	else
		callpoint!.setColumnData("OPE_ORDDET.UNIT_PRICE",str(price))
		callpoint!.setColumnData("OPE_ORDDET.DISC_PERCENT",str(disc))
	endif
	if disc=100
		readrecord(ivm02_dev,key=firm_id$+wh$+item$)ivm02a$
		callpoint!.setColumnData("OPE_ORDDET.STD_LIST_PRC",str(ivm02a.cur_price))
	else
		readrecord(ivs01_dev,key=firm_id$+"IV00")ivs01a$
		precision  num(ivs01a.precision$)+3
		factor=100/(100-disc)
		precision num(ivs01a.precision$)
		callpoint!.setColumnData("OPE_ORDDET.STD_LIST_PRC",str(price*factor))
return

rem --- set data in Availability window
set_avail:
	dim avail$[6]
	good_item$="N"
	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")
	ivm02_dev=fnget_dev("IVM_ITEMWHSE")
	dim ivm02a$:fnget_tpl$("IVM_ITEMWHSE")
	ivc_whcode_dev=fnget_dev("IVC_WHSECODE")
	dim ivm10c$:fnget_tpl$("IVC_WHSECODE")
	while 1
		readrecord(ivm01_dev,key=firm_id$+item$,dom=*break)ivm01a$
		readrecord(ivm02_dev,key=firm_id$+wh$+item$,dom=*break)ivm02a$
		readrecord(ivc_whcode_dev,key=firm_id$+"C"+wh$,dom=*break)ivm10c$
		good_item$="Y"
		break
	wend
	if good_item$="Y"
		avail$[1]=str(ivm02a.qty_on_hand)
		avail$[2]=str(ivm02a.qty_commit)
		avail$[3]=str(ivm02a.qty_on_hand-ivm02a.qty_commit)
		avail$[4]=str(ivm02a.qty_on_order)
		avail$[5]=ivm10c.short_name$
		avail$[6]=ivm01a.item_type$
		userObj!.getItem(num(user_tpl.avail_oh$)).setText(avail$[1])
		userObj!.getItem(num(user_tpl.avail_comm$)).setText(avail$[2])
		userObj!.getItem(num(user_tpl.avail_avail$)).setText(avail$[3])
		userObj!.getItem(num(user_tpl.avail_oo$)).setText(avail$[4])
		userObj!.getItem(num(user_tpl.avail_wh$)).setText(avail$[5])
		userObj!.getItem(num(user_tpl.avail_type$)).setText(avail$[6])
		opc_linecode_dev=fnget_dev("OPC_LINECODE")
		dim opc_linecode$:fnget_tpl$("OPC_LINECODE")
		while 1
			userObj!.getItem(num(user_tpl.dropship_flag$)).setText("")
			readrecord(opc_linecode_dev,key=firm_id$+callpoint!.getColumnData("OPE_ORDDET.LINE_CODE"),dom=*break)opc_linecode$
			if opc_linecode.dropship$="Y"
				userObj!.getItem(num(user_tpl.dropship_flag$)).setText("**Drop Ship**")
			endif
			break
		wend
	endif
return

rem --- Clear Availability Window
clear_avail:
	userObj!.getItem(num(user_tpl.avail_oh$)).setText("")
	userObj!.getItem(num(user_tpl.avail_comm$)).setText("")
	userObj!.getItem(num(user_tpl.avail_avail$)).setText("")
	userObj!.getItem(num(user_tpl.avail_oo$)).setText("")
	userObj!.getItem(num(user_tpl.avail_wh$)).setText("")
	userObj!.getItem(num(user_tpl.avail_type$)).setText("")
	userObj!.getItem(num(user_tpl.dropship_flag$)).setText("")
return

rem --- Check to see if we're on a new row
check_new_row:
	MyGrid!=userObj!.getItem(0)
	CurrRow=MyGrid!.getSelectedRow()
	if CurrRow<>user_tpl.cur_row
		gosub clear_avail
		user_tpl.cur_row=CurrRow
		gosub set_avail
	endif
return

disable_ctl:rem --- disable selected controls
	wctl$=str(num(callpoint!.getTableColumnAttribute(dctl$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=dmap$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP")
return

#include std_missing_params.src
[[OPE_ORDDET.LINE_CODE.AVAL]]
rem --- set enable/disable based on line type
	line_code$=callpoint!.getUserInput()
	if cvs(line_code$,2)<>""
		opc_linecode_dev=fnget_dev("OPC_LINECODE")
		dim opc_linecode$:fnget_tpl$("OPC_LINECODE")
		read record (opc_linecode_dev,key=firm_id$+line_code$,dom=*next)opc_linecode$
		callpoint!.setStatus("ENABLE:"+opc_linecode.line_type$)
	endif

