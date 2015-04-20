[[OPE_DUPEPO.AREC]]
rem --- Display counter

	found_dupes!=callpoint!.getDevObject("found_dupe")
	callpoint!.setColumnData("<<DISPLAY>>.NO_LINES",str(found_dupes!.size()),1)
[[OPE_DUPEPO.AWIN]]
rem --- Build and show form

	use ::ado_util.src::util

	UserObj! = BBjAPI().makeVector()
	vectOrders! = BBjAPI().makeVector()
	nxt_ctlID = util.getNextControlID()

	gridOrders! = Form!.addGrid(nxt_ctlID,5,40,800,300); rem --- ID, x, y, width, height

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
	cust$=callpoint!.getDevObject("customer")
	ar_type$=opt_hdr.ar_type$

	found_dupes!=callpoint!.getDevObject("found_dupe")

	if found_dupes!.size()>0 then
		for i=0 to found_dupes!.size()-1
			dupeOP!=found_dupes!.getItem(i)
			type$=dupeOP!.getItem(0)
			order$=dupeOP!.getItem(1)
			invoice$=dupeOP!.getItem(2)
			read record (opt_hdr,key=firm_id$+ar_type$+cust$+order$+invoice$,knum="PRIMARY",dom=*continue) opt_hdr$
			if type$="O"
				vectOrders!.addItem("Order")
				status$=opt_hdr.invoice_type$
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
				if opt_hdr.ordinv_flag$="I" status$="Invoice"
				vectOrders!.addItem(status$)
			else
				vectOrders!.addItem("Historical")
				vectOrders!.addItem("Invoice")
			endif
			vectOrders!.addItem(opt_hdr.order_no$)
			vectOrders!.addItem(opt_hdr.ar_inv_no$)
			vectOrders!.addItem(fndate$(opt_hdr.order_date$))
			vectOrders!.addItem(fndate$(opt_hdr.shipmnt_date$))
			vectOrders!.addItem(fndate$(opt_hdr.invoice_date$))
		next i
	endif

rem --- Fill grid

	numrow = vectOrders!.size() / gridOrders!.getNumColumns()
	gridOrders!.clearMainGrid()
	gridOrders!.setNumRows(numrow)
	gridOrders!.setCellText(0,0,vectOrders!)

	gridOrders!.resort()
