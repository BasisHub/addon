[[OPE_ORDDET.QTY_ORDERED.AVEC]]
rem --- Go get Lot/Serial Numbers if needed
	gosub calc_grid_tots
	gosub disp_totals
escape
	ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm01a$:fnget_tpl$("APT_ITEMMAST")
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
		readrecord(opc_linecode_dev,key=firm$+line_code$,err=*break)opc_linecode$
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
[[OPE_ORDDET.BWAR]]
rem --- commit inventory
escape;rem bwar
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
[[OPE_ORDDET.QTY_SHIPPED.AVEC]]
rem --- update header
	gosub calc_grid_tots
	gosub disp_totals
[[OPE_ORDDET.QTY_BACKORD.AVEC]]
rem --- update header
	gosub calc_grid_tots
	gosub disp_totals
[[OPE_ORDDET.QTY_SHIPPED.AVAL]]
rem ---recalc quantities and extended price
	shipqty=num(callpoint!.getUserInput())
	ordqty=num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	if shipqty>ordqty
		callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED",str(user_tpl.line_shipqty))
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
	user_tpl.line_shipqty=num(callpoint!.getColumnData("OPE_ORDDET.QTY_SHIPPED"))
[[OPE_ORDDET.QTY_ORDERED.AVAL]]
rem ---recalc quantities and extended price
	newqty=num(callpoint!.getUserInput())
	if num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE")) = 0
		gosub pricing
	endif
	callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD","0")
	callpoint!.setColumnData("OPE_ORDDET.QTY_SHIPPED",str(newqty))

	unit_price=num(callpoint!.getColumnData("OPE_ORDDET.UNIT_PRICE"))
	new_ext_price=newqty*unit_price

	callpoint!.setColumnData("OPE_ORDDET.EXT_PRICE",str(new_ext_price))
	callpoint!.setStatus("MODIFIED-REFRESH")
[[OPE_ORDDET.QTY_BACKORD.AVAL]]
rem ---recalc quantities and extended price
	boqty=num(callpoint!.getUserInput())
	ordqty=num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	if boqty>ordqty
		callpoint!.setColumnData("OPE_ORDDET.QTY_BACKORD",str(user_tpl.line_boqty))
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
	user_tpl.line_boqty=num(callpoint!.getColumnData("OPE_ORDDET.QTY_BACKORD"))
[[OPE_ORDDET.<CUSTOM>]]
calc_grid_tots:
	recVect!=GridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs=recVect!.size()
	tamt=0
	if numrecs>0
		for reccnt=0 to numrecs-1
			gridrec$=recVect!.getItem(reccnt)
			tamt=tamt+num(gridrec.ext_price$)
		next reccnt
		user_tpl.ord_tot=tamt
	endif
return

disp_totals: rem --- get context and ID of total amount display control, and redisplay w/ amts from calc_tots
	tamt!=UserObj!.getItem(1)
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
        ope01_dev=fnget_dev("OPE_ORDHDR")
	dim ope01a$:fnget_tpl$("OPE_ORDHDR")
	ivm02_dev=fnget_dev("IVM_ITEMWHSE")
	dim ivm02a$:fnget_tpl$("IVM_ITEMWHSE")
	ivs01_dev=fnget_dev("IVS_PARAMS")
	dim ivs01a$:fnget_tpl$("IVS_PARAMS")
	ordqty=num(callpoint!.getColumnData("OPE_ORDDET.QTY_ORDERED"))
	wh$=callpoint!.getColumnData("OPE_ORDDET.WAREHOUSE_ID")
	item$=callpoint!.getColumnData("OPE_ORDDET.ITEM_ID")
	ar_type$=callpoint!.getColumnData("OPE_ORDDET.AR_TYPE")
	cust$=callpoint!.getColumnData("OPE_ORDDET.CUSTOMER_ID")
	ord$=callpoint!.getColumnData("OPE_ORDDET.ORDER_NO")
	readrecord(ope01_dev,key=firm_id$+ar_type$+cust$+ord$)ope01a$
	dim pc_files[6]
	pc_files[1]=fnget_dev("IVM_ITEMMAST")
	pc_files[2]=ivm02_dev
	pc_files[3]=fnget_dev("IVM_ITEMPRIC")
	pc_files[4]=fnget_dev("IVC_PRICCODE")
	pc_files[5]=fnget_dev("ARS_PARAMS")
	pc_files[6]=ivs01_dev
	call stbl("+DIR_PGM")+"opc_pc.aon",pc_files[all],firm_id$,wh$,item$,ope01a.price_code$,cust$,
:		ope01a.order_date$,ope01a.pricing_code$,ordqty,typeflag$,price,disc,status
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

#include std_missing_params.src
[[OPE_ORDDET.LINE_CODE.AVAL]]
rem --- set enable/disable based on line type
	line_code$=callpoint!.getColumnData("OPE_ORDDET.LINE_CODE")
	if cvs(line_code$,2)<>""
		opc_linecode_dev=fnget_dev("OPC_LINECODE")
		dim opc_linecode$:fnget_tpl$("OPC_LINECODE")
		read record (opc_linecode_dev,key=firm_id$+line_code$,dom=*next)opc_linecode$
		callpoint!.setStatus("ENABLE:"+opc_linecode.line_type$)
	endif
