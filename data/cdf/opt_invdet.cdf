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
			callpoint!.setDevObject("inventoried",ivm01a.inventoried$)

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
	qty_ord = num(callpoint!.getColumnData("OPT_INVDET.QTY_ORDERED"))
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
rem --- Save current row/column so we'll know where to set focus when we return from lot lookup

	declare BBjStandardGrid grid!
	grid! = util.getGrid(Form!)
	return_to_row = grid!.getSelectedRow()
	return_to_col = grid!.getSelectedColumn()

rem --- Go get Lot Numbers

	item_id$ = callpoint!.getColumnData("OPT_INVDET.ITEM_ID")
	gosub lot_ser_check

rem --- Is this item lot/serial?

	if lotted$ = "Y" then
		ar_type$ = callpoint!.getColumnData("OPT_INVDET.AR_TYPE")
		cust$    = callpoint!.getColumnData("OPT_INVDET.CUSTOMER_ID")
		invoice$   = callpoint!.getColumnData("OPT_INVDET.AR_INV_NO")
		int_seq$ = callpoint!.getColumnData("OPT_INVDET.ORDDET_SEQ_REF")

		if cvs(cust$,2) <> ""

		rem --- Run the Lot/Serial# detail entry form
		rem      IN: call/enter list
		rem          the DevObjects set below
		rem          DevObject("lotser_flag"): set in OPT_INVHDR

			callpoint!.setDevObject("from",          "invoice_entry")
			callpoint!.setDevObject("wh",            callpoint!.getColumnData("OPT_INVDET.WAREHOUSE_ID"))
			callpoint!.setDevObject("item",          callpoint!.getColumnData("OPT_INVDET.ITEM_ID"))
			callpoint!.setDevObject("ord_qty",       callpoint!.getColumnData("OPT_INVDET.QTY_ORDERED"))
			callpoint!.setDevObject("dropship_line", user_tpl.line_dropship$)
			callpoint!.setDevObject("invoice_type",  callpoint!.getHeaderColumnData("OPT_INVHDR.INVOICE_TYPE"))

			grid!.focus()

			dim dflt_data$[4,1]
			dflt_data$[1,0] = "AR_TYPE"
			dflt_data$[1,1] = ar_type$
			dflt_data$[2,0] = "CUSTOMER_ID"
			dflt_data$[2,1] = cust$
			dflt_data$[3,0] = "AR_INV_NO"
			dflt_data$[3,1] = invoice$
			dflt_data$[4,0]="ORDDET_SEQ_REF"
			dflt_data$[4,1]=int_seq$
			lot_pfx$ = firm_id$+ar_type$+cust$+invoice$+int_seq$

			call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:				"OPT_INVLSDET", 
:				stbl("+USER_ID"), 
:				"MNT", 
:				lot_pfx$, 
:				table_chans$[all], 
:				dflt_data$[all]

		rem --- Updated qty shipped, backordered, extension
rem			callpoint!.setStatus("REFRESH")

		rem --- Return focus to where we were (Detail line grid)

rem --- per bug 5587 disable forceEdit until Barista bug 5586 is fixed
rem --- then replace forceEdit with setFocus in AGRN
rem			util.forceEdit(Form!, return_to_row, return_to_col)
		endif
	endif
