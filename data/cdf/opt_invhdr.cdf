[[OPT_INVHDR.AFMC]]
rem --- Inits

	use ::ado_util.src::util
	use ::ado_order.src::OrderHelper
	use ::adc_array.aon::ArrayObject
[[OPT_INVHDR.BSHO]]
rem --- Open needed files

	num_files=39
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="ARM_CUSTMAST",  open_opts$[1]="OTA"
	open_tables$[2]="ARM_CUSTSHIP",  open_opts$[2]="OTA"
rem	open_tables$[3]="OPE_ORDSHIP",   open_opts$[3]="OTA"
	open_tables$[4]="ARS_PARAMS",    open_opts$[4]="OTA"
	open_tables$[5]="ARM_CUSTDET",   open_opts$[5]="OTA"
rem	open_tables$[6]="OPE_INVCASH",   open_opts$[6]="OTA"
	open_tables$[7]="ARS_CREDIT",    open_opts$[7]="OTA"
	open_tables$[8]="OPC_LINECODE",  open_opts$[8]="OTA"
	open_tables$[9]="GLS_PARAMS",    open_opts$[9]="OTA"
	open_tables$[10]="GLS_PARAMS",   open_opts$[10]="OTA"
	open_tables$[11]="IVM_LSMASTER", open_opts$[11]="OTA"
	open_tables$[12]="IVX_LSCUST",   open_opts$[12]="OTA"
	open_tables$[13]="IVM_ITEMMAST", open_opts$[13]="OTA"
	open_tables$[15]="IVX_LSVEND",   open_opts$[15]="OTA"
	open_tables$[16]="IVM_ITEMWHSE", open_opts$[16]="OTA"
	open_tables$[17]="IVM_ITEMACT",  open_opts$[17]="OTA"
	open_tables$[18]="IVT_ITEMTRAN", open_opts$[18]="OTA"
	open_tables$[19]="IVM_ITEMTIER", open_opts$[19]="OTA"
	open_tables$[20]="IVM_ITEMACT",  open_opts$[20]="OTA"
	open_tables$[21]="IVM_ITEMVEND", open_opts$[21]="OTA"
	open_tables$[22]="IVT_LSTRANS",  open_opts$[22]="OTA"
	open_tables$[23]="OPT_INVHDR",   open_opts$[23]="OTA"
	open_tables$[24]="OPT_INVDET",   open_opts$[24]="OTA"
rem	open_tables$[25]="OPE_ORDDET",   open_opts$[25]="OTA"
	open_tables$[26]="OPT_INVSHIP",  open_opts$[26]="OTA"
	open_tables$[27]="OPE_CREDDATE", open_opts$[27]="OTA"
	open_tables$[28]="IVC_WHSECODE", open_opts$[28]="OTA"
	open_tables$[29]="IVS_PARAMS",   open_opts$[29]="OTA"
	open_tables$[30]="OPE_ORDLSDET", open_opts$[30]="OTA"
	open_tables$[31]="IVM_ITEMPRIC", open_opts$[31]="OTA"
	open_tables$[32]="IVC_PRICCODE", open_opts$[32]="OTA"
	open_tables$[33]="ARM_CUSTCMTS", open_opts$[33]="OTA"
	open_tables$[34]="OPE_PRNTLIST", open_opts$[34]="OTA"
	open_tables$[35]="OPM_POINTOFSALE", open_opts$[35]="OTA"
	open_tables$[36]="ARC_SALECODE", open_opts$[36]="OTA"
	open_tables$[37]="OPC_DISCCODE", open_opts$[37]="OTA"
	open_tables$[38]="OPC_TAXCODE",  open_opts$[38]="OTA"
rem	open_tables$[39]="OPE_ORDHDR",   open_opts$[39]="OTA"
	
gosub open_tables

rem --- Set table_chans$[all] into util object for getDev() and getTmpl()

	declare ArrayObject tableChans!

	call stbl("+DIR_PGM")+"adc_array.aon::str_array2object", table_chans$[all], tableChans!, status
	if status = 999 then goto std_exit
	util.setTableChans(tableChans!)

rem --- get AR Params

	dim ars01a$:open_tpls$[4]
	read record (num(open_chans$[4]), key=firm_id$+"AR00") ars01a$

	dim ars_credit$:open_tpls$[7]
	read record (num(open_chans$[7]), key=firm_id$+"AR01") ars_credit$

rem --- get IV Params

	dim ivs01a$:open_tpls$[29]
	read record (num(open_chans$[29]), key=firm_id$+"IV00") ivs01a$

rem --- See if blank warehouse exists

	blank_whse$ = "N"
	dim ivm10c$:open_tpls$[28]
	start_block = 1
	
	if start_block then
		read record (num(open_chans$[28]), key=firm_id$+"C"+ivm10c.warehouse_id$, dom=*endif) ivm10c$
		blank_whse$ = "Y"
	endif

rem --- Disable display fields

	declare BBjVector column!
	column! = BBjAPI().makeVector()

	column!.addItem("<<DISPLAY>>.BADD1")
	column!.addItem("<<DISPLAY>>.BADD2")
	column!.addItem("<<DISPLAY>>.BADD3")
	column!.addItem("<<DISPLAY>>.BADD4")
	column!.addItem("<<DISPLAY>>.BCITY")
	column!.addItem("<<DISPLAY>>.BSTATE")
	column!.addItem("<<DISPLAY>>.BZIP")
	column!.addItem("<<DISPLAY>>.ORDER_TOT")

	if ars01a.job_nos$<>"Y" then 
		column!.addItem("OPT_INVHDR.JOB_NO")
	endif

	callpoint!.setColumnEnabled(column!, -1)

	column!.clear()
	column!.addItem("<<DISPLAY>>.SNAME")
	column!.addItem("<<DISPLAY>>.SADD1")
	column!.addItem("<<DISPLAY>>.SADD2")
	column!.addItem("<<DISPLAY>>.SADD3")
	column!.addItem("<<DISPLAY>>.SADD4")
	column!.addItem("<<DISPLAY>>.SCITY")
	column!.addItem("<<DISPLAY>>.SSTATE")
	column!.addItem("<<DISPLAY>>.SZIP")
	callpoint!.setColumnEnabled(column!, -1)

	callpoint!.setColumnEnabled(column!, -1)

rem --- Save display control objects

rem	UserObj!.addItem( util.getControl(callpoint!, "<<DISPLAY>>.ORDER_TOT") )

rem --- Setup user_tpl$
    
	tpl$ = 
:		"credit_installed:c(1), " +
:		"balance:n(15), " +
:		"credit_limit:n(15), " +
:		"display_bal:c(1), " +
:		"ord_tot:n(15), " +
:		"def_ship:c(8), " + 
:		"def_commit:c(8), " +
:		"blank_whse:c(1), " +
:		"line_code:c(1), " +
:		"line_type:c(1), " +
:		"dropship_whse:c(1), " +
:		"def_whse:c(10), " +
:     "avail_oh:u(1), " +
:     "avail_comm:u(1), " +
:     "avail_avail:u(1), " +
:     "avail_oo:u(1), " +
:     "avail_wh:u(1), " +
:     "avail_type:u(1), " +
:     "dropship_flag:u(1), " +
:		"manual_price:u(1), " +
:     "ord_tot_obj:u(1), " +
:		"price_code:c(2), " +
:		"pricing_code:c(4), " +
:		"order_date:c(8), " +
:		"pick_hold:c(1), " +
:		"pgmdir:c(1*), " +
:		"skip_whse:c(1), " +
:		"warehouse_id:c(2), " +
:		"user_entry:c(1), " +
:		"cur_row:n(5), " +
:		"skip_ln_code:c(1), " +
:		"hist_ord:c(1), " +
:		"cash_sale:c(1), " +
:		"cash_cust:c(6), " +
:		"bo_col:u(1), " +
:		"prod_type_col:u(1), " +
:		"allow_bo:c(1), " +
:		"amount_mask:c(1*)," +
:		"line_taxable:c(1), " +
:		"item_taxable:c(1), " +
:		"min_line_amt:n(5), " +
:		"min_ord_amt:n(5), " +
:		"item_price:n(15), " +
:		"line_dropship:c(1), " +
:		"dropship_cost:c(1), " +
:		"lotser_flag:c(1), " +
:		"new_detail:u(1), " +
:		"prev_line_code:c(1*), " +
:		"prev_item:c(1*), " +
:		"prev_qty_ord:n(15), " +
:		"prev_boqty:n(15), " +
:		"prev_shipqty:n(15), " +
:		"prev_ext_price:n(15), " +
:		"prev_taxable:n(15), " +
:		"prev_ext_cost:n(15), " +
:     "prev_disc_code:c(1*), "+
:     "prev_ship_to:c(1*), " +
:		"prev_sales_total:n(15), " +
:		"prev_unitprice:n(15), " +
:		"detail_modified:u(1), " +
:		"record_deleted:u(1), " +
:		"item_wh_failed:u(1), " +
:		"do_end_of_form:u(1), " +
:		"picklist_warned:u(1)"

	dim user_tpl$:tpl$

	user_tpl.credit_installed$ = ars_credit.sys_install$
	user_tpl.pick_hold$        = ars_credit.pick_hold$
	user_tpl.display_bal$      = ars_credit.display_bal$
	user_tpl.blank_whse$       = blank_whse$
	user_tpl.dropship_whse$    = ars01a.dropshp_whse$
	call stbl("+DIR_PGM")+"adc_getmask.aon","","AR","A","",amt_mask$,0,0
	user_tpl.amount_mask$      = amt_mask$
	user_tpl.line_code$        = ars01a.line_code$
	user_tpl.skip_ln_code$     = ars01a.skip_ln_code$
	user_tpl.cash_sale$        = ars01a.cash_sale$
	user_tpl.cash_cust$        = ars01a.customer_id$
   user_tpl.allow_bo$         = ars01a.backorders$
	user_tpl.dropship_cost$    = ars01a.dropshp_cost$
	user_tpl.min_ord_amt       = num(ars01a.min_ord_amt$)
	user_tpl.min_line_amt      = num(ars01a.min_line_amt$)
	user_tpl.def_whse$         = ivs01a.warehouse_id$
	user_tpl.lotser_flag$      = ivs01a.lotser_flag$
	user_tpl.pgmdir$           = stbl("+DIR_PGM",err=*next)
	user_tpl.cur_row           = -1
	user_tpl.detail_modified   = 0
	user_tpl.record_deleted    = 0
	user_tpl.item_wh_failed    = 1
	user_tpl.do_end_of_form    = 1
	user_tpl.picklist_warned   = 0

rem --- Columns for the util disableCell() method

	user_tpl.bo_col            = 9
	user_tpl.prod_type_col     = 1

	user_tpl.prev_line_code$   = ""
	user_tpl.prev_item$        = ""
	user_tpl.prev_qty_ord      = 0
	user_tpl.prev_boqty        = 0
	user_tpl.prev_shipqty      = 0
	user_tpl.prev_ext_price    = 0; rem used in detail section to hold the line extension 
	user_tpl.prev_taxable      = 0
	user_tpl.prev_ext_cost     = 0
	user_tpl.prev_disc_code$   = ""
	user_tpl.prev_ship_to$     = ""
	user_tpl.prev_sales_total  = 0; rem used in totals section to hold the order sale total
	user_tpl.prev_unitprice    = 0

rem --- Ship and Commit dates

	dim sysinfo$:stbl("+SYSINFO_TPL")
	sysinfo$=stbl("+SYSINFO")

	pgmdir$ = ""
	pgmdir$ = stbl("+DIR_PGM")

	orddate$ = sysinfo.system_date$
	comdate$ = orddate$
	shpdate$ = orddate$

	comdays = num(ars01a.commit_days$)
	shpdays = num(ars01a.def_shp_days$)

	if comdays then call pgmdir$+"adc_daydates.aon", orddate$, comdate$, comdays
	if shpdays then call pgmdir$+"adc_daydates.aon", orddate$, shpdate$, shpdays

	user_tpl.def_ship$   = shpdate$
	user_tpl.def_commit$ = comdate$

rem --- Save the indices of the controls for the Avail Window, setup in AFMC

	user_tpl.avail_oh      = 2
	user_tpl.avail_comm    = 3
	user_tpl.avail_avail   = 4
	user_tpl.avail_oo      = 5
	user_tpl.avail_wh      = 6
	user_tpl.avail_type    = 7
	user_tpl.dropship_flag = 8
	user_tpl.manual_price  = 9
	user_tpl.ord_tot_obj   = 10; rem set here in BSHO

rem --- Set variables for called forms (OPE_ORDLSDET)

	callpoint!.setDevObject("lotser_flag",ivs01a.lotser_flag$)

rem --- Set up Lot/Serial button (and others) properly

	switch pos(ivs01a.lotser_flag$="LS")
		case 1; callpoint!.setOptionText("LENT",Translate!.getTranslation("AON_LOT_ENTRY")); break
		case 2; callpoint!.setOptionText("LENT",Translate!.getTranslation("AON_SERIAL_ENTRY")); break
		case default; break
	swend

rem --- Parse table_chans$[all] into an object

	declare ArrayObject tableChans!

	call pgmdir$+"adc_array.aon::str_array2object", table_chans$[all], tableChans!, status
	util.setTableChans(tableChans!)

rem --- get mask for display sequence number used in detail lines (needed when creating duplicate/credit)

	call stbl("+DIR_PGM")+"adc_getmask.aon","LINE_NO","","","",line_no_mask$,0,0
	callpoint!.setDevObject("line_no_mask",line_no_mask$)
[[OPT_INVHDR.<CUSTOM>]]
rem ==========================================================================
display_customer: rem --- Get and display Bill To Information
                  rem      IN: cust_id$
rem ==========================================================================

	custmast_dev = fnget_dev("ARM_CUSTMAST")
	dim custmast_tpl$:fnget_tpl$("ARM_CUSTMAST")
	find record (custmast_dev, key=firm_id$+cust_id$) custmast_tpl$

	callpoint!.setColumnData("<<DISPLAY>>.BADD1",  custmast_tpl.addr_line_1$)
	callpoint!.setColumnData("<<DISPLAY>>.BADD2",  custmast_tpl.addr_line_2$)
	callpoint!.setColumnData("<<DISPLAY>>.BADD3",  custmast_tpl.addr_line_3$)
	callpoint!.setColumnData("<<DISPLAY>>.BADD4",  custmast_tpl.addr_line_4$)
	callpoint!.setColumnData("<<DISPLAY>>.BCITY",  custmast_tpl.city$)
	callpoint!.setColumnData("<<DISPLAY>>.BSTATE", custmast_tpl.state_code$)
	callpoint!.setColumnData("<<DISPLAY>>.BZIP",   custmast_tpl.zip_code$)

	return

rem ==========================================================================
ship_to_info: rem --- Get and display Bill To Information
              rem      IN: cust_id$
              rem          ship_to_type$
              rem          ship_to_no$
              rem          invoice_no$
rem ==========================================================================

	if ship_to_type$<>"M" then

		if ship_to_type$="S" then
			custship_dev = fnget_dev("ARM_CUSTSHIP")
			dim custship_tpl$:fnget_tpl$("ARM_CUSTSHIP")
			read record (custship_dev, key=firm_id$+cust_id$+ship_to_no$, dom=*next) custship_tpl$

			callpoint!.setColumnData("<<DISPLAY>>.SNAME",custship_tpl.name$)
			callpoint!.setColumnData("<<DISPLAY>>.SADD1",custship_tpl.addr_line_1$)
			callpoint!.setColumnData("<<DISPLAY>>.SADD2",custship_tpl.addr_line_2$)
			callpoint!.setColumnData("<<DISPLAY>>.SADD3",custship_tpl.addr_line_3$)
			callpoint!.setColumnData("<<DISPLAY>>.SADD4",custship_tpl.addr_line_4$)
			callpoint!.setColumnData("<<DISPLAY>>.SCITY",custship_tpl.city$)
			callpoint!.setColumnData("<<DISPLAY>>.SSTATE",custship_tpl.state_code$)
			callpoint!.setColumnData("<<DISPLAY>>.SZIP",custship_tpl.zip_code$)
		else
			callpoint!.setColumnData("<<DISPLAY>>.SNAME",Translate!.getTranslation("AON_SAME"))
			callpoint!.setColumnData("<<DISPLAY>>.SADD1","")
			callpoint!.setColumnData("<<DISPLAY>>.SADD2","")
			callpoint!.setColumnData("<<DISPLAY>>.SADD3","")
			callpoint!.setColumnData("<<DISPLAY>>.SADD4","")
			callpoint!.setColumnData("<<DISPLAY>>.SCITY","")
			callpoint!.setColumnData("<<DISPLAY>>.SSTATE","")
			callpoint!.setColumnData("<<DISPLAY>>.SZIP","")
		endif

	else

		invship_dev = fnget_dev("OPT_INVSHIP")
		dim invship_tpl$:fnget_tpl$("OPT_INVSHIP")
		read record (invship_dev, key=firm_id$+cust_id$+invoice_no$, dom=*endif) invship_tpl$

		callpoint!.setColumnData("<<DISPLAY>>.SNAME",invship_tpl.name$)
		callpoint!.setColumnData("<<DISPLAY>>.SADD1",invship_tpl.addr_line_1$)
		callpoint!.setColumnData("<<DISPLAY>>.SADD2",invship_tpl.addr_line_2$)
		callpoint!.setColumnData("<<DISPLAY>>.SADD3",invship_tpl.addr_line_3$)
		callpoint!.setColumnData("<<DISPLAY>>.SADD4",invship_tpl.addr_line_4$)
		callpoint!.setColumnData("<<DISPLAY>>.SCITY",invship_tpl.city$)
		callpoint!.setColumnData("<<DISPLAY>>.SSTATE",invship_tpl.state_code$)
		callpoint!.setColumnData("<<DISPLAY>>.SZIP",invship_tpl.zip_code$)
	endif

	callpoint!.setStatus("REFRESH")

	return
[[OPT_INVHDR.ADIS]]
rem --- Display Ship to information

	cust_id$ = callpoint!.getColumnData("OPT_INVHDR.CUSTOMER_ID")
	gosub display_customer

	ship_to_type$ = callpoint!.getColumnData("OPT_INVHDR.SHIPTO_TYPE")
	ship_to_no$   = callpoint!.getColumnData("OPT_INVHDR.SHIPTO_NO")
	invoice_no$     = callpoint!.getColumnData("OPT_INVHDR.AR_INV_NO")
	gosub ship_to_info

rem --- Display invoice total

	callpoint!.setColumnData("<<DISPLAY>>.ORDER_TOT", callpoint!.getColumnData("OPT_INVHDR.TOTAL_SALES"))
[[OPT_INVHDR.AOPT-PRNT]]
rem --- Print a counter Invoice

	cust_id$  = callpoint!.getColumnData("OPT_INVHDR.CUSTOMER_ID")
	order_no$ = callpoint!.getColumnData("OPT_INVHDR.AR_INV_NO")

	call pgmdir$+"opc_invoicehist.aon", cust_id$, order_no$, callpoint!, table_chans$[all], status
	if status = 999 then goto std_exit
