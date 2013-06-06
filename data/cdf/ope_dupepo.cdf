[[OPE_DUPEPO.AREC]]
rem --- Display counter

	counter$=callpoint!.getDevObject("found_dupe")
	counter=len(counter$)/8
	callpoint!.setColumnData("<<DISPLAY>>.NO_LINES",str(counter),1)
[[OPE_DUPEPO.AWIN]]
rem --- Build and show form

	use ::ado_util.src::util

	UserObj! = BBjAPI().makeVector()
	vectOrders! = BBjAPI().makeVector()
	nxt_ctlID = util.getNextControlID()

	gridOrders! = Form!.addGrid(nxt_ctlID,5,140,800,300); rem --- ID, x, y, width, height

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0] = callpoint!.getColumnAttributeTypes()
	def_inv_cols = 7
	num_rpts_rows = 6
	dim attr_inv_col$[def_inv_cols,len(attr_def_col_str$[0,0])/5]
	column_no = 1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="TYPE"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_TYPE")
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="STATUS"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_STATUS")
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ORDER_NO"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ORDER")
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="INVOICE_NO"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_INVOICE")
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ORD_DATE"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ORDER")+" "+Translate!.getTranslation("AON_DATE")
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SHIP_DATE"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_SHIP_DATE")
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="INVOICE_DATE"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_INVOICE_DATE")
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	column_no = column_no +1

	for curr_attr=1 to def_inv_cols
		attr_inv_col$[0,1] = attr_inv_col$[0,1] + 
:			pad("APT_PAY." + attr_inv_col$[curr_attr, fnstr_pos("DVAR", attr_def_col_str$[0,0], 5)], 40)
	next curr_attr

	attr_disp_col$=attr_inv_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridOrders!,"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC-CHECKS-DATES",num_rpts_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_inv_col$[all]

	opt_hdr=num(callpoint!.getDevObject("opt_invlookup"))
	dim opt_hdr$:callpoint!.getDevObject("opt_invlookup_tpl")
	ope_hdr=num(callpoint!.getDevObject("ope_polookup"))
	dim ope_hdr$:callpoint!.getDevObject("ope_polookup_tpl")
	cust$=callpoint!.getDevObject("customer")
	ar_type$=ope_hdr.ar_type$

	counter$=callpoint!.getDevObject("found_dupe")
	counter=len(counter$)/8

	for x=1 to len(counter$) step 8
		type$=counter$(x,1)
		order$=counter$(x+1,7)
		if type$="O"
			read record (ope_hdr,key=firm_id$+ar_type$+cust$+order$,knum="PRIMARY") ope_hdr$
			vectOrders!.addItem("Order")
			status$=ope_hdr.invoice_type$
			if status$="P"
				status$="Quote"
			else
				if status$="S"
					status$="Sale"
				else
					if status$="V"
						status$="Void"
					endif
				endif
			endif
			if ope_hdr.ordinv_flag$="I" status$="Invoice"
			vectOrders!.addItem(status$)
			vectOrders!.addItem(ope_hdr.order_no$)
			vectOrders!.addItem(ope_hdr.ar_inv_no$)
			vectOrders!.addItem(fndate$(ope_hdr.order_date$))
			vectOrders!.addItem(fndate$(ope_hdr.shipmnt_date$))
			vectOrders!.addItem(fndate$(ope_hdr.invoice_date$))
		else
			read record (opt_hdr,key=firm_id$+ar_type$+cust$+order$,knum="PRIMARY") opt_hdr$
			vectOrders!.addItem("Historical")
			vectOrders!.addItem("Invoice")
			vectOrders!.addItem(opt_hdr.order_no$)
			vectOrders!.addItem(opt_hdr.ar_inv_no$)
			vectOrders!.addItem(fndate$(opt_hdr.order_date$))
			vectOrders!.addItem(fndate$(opt_hdr.shipmnt_date$))
			vectOrders!.addItem(fndate$(opt_hdr.invoice_date$))
		endif
	next x

rem --- Fill grid

	SysGUI!.setRepaintEnabled(0)

	numrow = vectOrders!.size() / gridOrders!.getNumColumns()
	gridOrders!.clearMainGrid()
	gridOrders!.setNumRows(numrow)
	gridOrders!.setCellText(0,0,vectOrders!)

	gridOrders!.resort()

	SysGUI!.setRepaintEnabled(1)
