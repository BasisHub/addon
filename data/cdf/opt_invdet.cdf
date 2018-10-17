[[OPT_INVDET.BGDR]]
rem --- Initialize UM_SOLD related <DISPLAY> fields
	conv_factor=num(callpoint!.getColumnData("OPT_INVDET.CONV_FACTOR"))
	if conv_factor=0 then conv_factor=1
	qty_ordered=num(callpoint!.getColumnData("OPT_INVDET.QTY_ORDERED"))/conv_factor
	callpoint!.setColumnData("<<DISPLAY>>.QTY_ORDERED_DSP",str(qty_ordered))
	unit_price=num(callpoint!.getColumnData("OPT_INVDET.UNIT_PRICE"))*conv_factor
	callpoint!.setColumnData("<<DISPLAY>>.UNIT_PRICE_DSP",str(unit_price))
	qty_backord=num(callpoint!.getColumnData("OPT_INVDET.QTY_BACKORD"))/conv_factor
	callpoint!.setColumnData("<<DISPLAY>>.QTY_BACKORD_DSP",str(qty_backord))
	qty_shipped=num(callpoint!.getColumnData("OPT_INVDET.QTY_SHIPPED"))/conv_factor
	callpoint!.setColumnData("<<DISPLAY>>.QTY_SHIPPED_DSP",str(qty_shipped))
	std_list_prc=num(callpoint!.getColumnData("OPT_INVDET.STD_LIST_PRC"))*conv_factor
	callpoint!.setColumnData("OPT_INVDET.STD_LIST_PRC",str(std_list_prc))
[[OPT_INVDET.AGCL]]
rem --- Set column size for memo_1024 field very small so it doesn't take up room, but still available for hover-over of memo contents

	grid! = util.getGrid(Form!)
	col_hdr$=callpoint!.getTableColumnAttribute("OPT_INVDET.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(grid!, col_hdr$)
	grid!.setColumnWidth(memo_1024_col,15)
[[OPT_INVDET.AGRN]]
rem --- Set buttons

	gosub able_lot_button
[[OPT_INVDET.BDGX]]
rem --- Disable detail-only buttons

	callpoint!.setOptionEnabled("LENT",0)
[[OPT_INVDET.<CUSTOM>]]
rem ==========================================================================
lot_ser_check: rem --- Check for lotted item
               rem      IN: item_id$
               rem     OUT: lotted$ - Y/N
rem ==========================================================================

	lotted$="N"

	if cvs(item_id$, 2)<>"" and pos(user_tpl.lotser_flag$ = "LS") then 
		ivm01_dev=fnget_dev("IVM_ITEMMAST")
		dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")
		start_block = 1

		if start_block then
			read record (ivm01_dev, key=firm_id$+item_id$, dom=*endif) ivm01a$

		rem --- In Invoice Entry, non-inventoried lotted/serial can enter lots

			if ivm01a.lotser_item$="Y" then lotted$="Y"
		endif
	endif

	return

rem ==========================================================================
able_lot_button: rem --- Enable/disable Lot/Serial button
                 rem      IN: item_id$ (for lot_ser_check)
rem ==========================================================================

	item_id$   = callpoint!.getColumnData("OPT_INVDET.ITEM_ID")
	qty_ord = num(callpoint!.getColumnData("<<DISPLAY>>.QTY_ORDERED_DSP"))
	gosub lot_ser_check

	if lotted$ = "Y" and qty_ord <> 0 then
		callpoint!.setOptionEnabled("LENT",1)
	else
		callpoint!.setOptionEnabled("LENT",0)
	endif

	return

rem ==========================================================================
rem 	Use util object
rem ==========================================================================

	use ::ado_util.src::util
[[OPT_INVDET.AOPT-LENT]]
rem --- Save current context so we'll know where to return from lot lookup

	declare BBjStandardGrid grid!
	grid! = util.getGrid(Form!)
	grid_ctx=grid!.getContextID()

rem --- Go get Lot Numbers

	item_id$ = callpoint!.getColumnData("OPT_INVDET.ITEM_ID")
	gosub lot_ser_check

rem --- Is this item lot/serial?

	if lotted$ = "Y" then
		ar_type$ = callpoint!.getColumnData("OPT_INVDET.AR_TYPE")
		cust$    = callpoint!.getColumnData("OPT_INVDET.CUSTOMER_ID")
		order$=callpoint!.getColumnData("OPT_INVDET.ORDER_NO")
		invoice$   = callpoint!.getColumnData("OPT_INVDET.AR_INV_NO")
		int_seq$ = callpoint!.getColumnData("OPT_INVDET.INTERNAL_SEQ_NO")

		if cvs(cust$,2) <> ""

		rem --- Run the Lot/Serial# detail entry form
			grid!.focus()

			dim dflt_data$[6,1]
			dflt_data$[1,0] = "AR_TYPE"
			dflt_data$[1,1] = ar_type$
			dflt_data$[2,0] = "TRANS_STATUS"
			dflt_data$[2,1] = "U"
			dflt_data$[3,0] = "CUSTOMER_ID"
			dflt_data$[3,1] = cust$
			dflt_data$[4,0] = "ORDER_NO"
			dflt_data$[4,1] = order$
			dflt_data$[5,0] = "AR_INV_NO"
			dflt_data$[5,1] = invoice$
			dflt_data$[6,0]="ORDDET_SEQ_REF"
			dflt_data$[6,1]=int_seq$
			lot_pfx$ = firm_id$+"U"+ar_type$+cust$+invoice$+int_seq$

			call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:				"OPT_INVLSDET", 
:				stbl("+USER_ID"), 
:				"INQ", 
:				lot_pfx$, 
:				table_chans$[all], 
:				dflt_data$[all]

		rem --- Updated qty shipped, backordered, extension
rem			callpoint!.setStatus("REFRESH")

		rem --- Return focus to where we were (Detail line grid)

			sysgui!.setContext(grid_ctx)
		endif
	endif
