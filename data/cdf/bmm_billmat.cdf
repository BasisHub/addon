[[BMM_BILLMAT.AGDR]]
rem --- Display Net Quantity

	qty_req=num(callpoint!.getColumnData("BMM_BILLMAT.QTY_REQUIRED"))
	alt_fact=num(callpoint!.getColumnData("BMM_BILLMAT.ALT_FACTOR"))
	divisor=num(callpoint!.getColumnData("BMM_BILLMAT.DIVISOR"))
	scrap_fact=num(callpoint!.getColumnData("BMM_BILLMAT.SCRAP_FACTOR"))
	gosub calc_net
	item$=callpoint!.getColumnData("BMM_BILLMAT.ITEM_ID")
	gosub check_sub
[[BMM_BILLMAT.AREC]]
rem --- Default Line Number to something

rem escape
[[BMM_BILLMAT.ITEM_ID.AVAL]]
rem --- Component must not be the same as the Master Bill

	item$=callpoint!.getUserInput()
	if item$ = callpoint!.getColumnData("BMM_BILLMAT.BILL_NO")
		msg_id$="BM_BAD_COMP_ITEM"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Check to see if item is a Sub Bill

	gosub check_sub

rem --- Set defaults for new record

	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y"
		callpoint!.setColumnData("BMM_BILLMAT.ALT_FACTOR","1")
		callpoint!.setColumnData("BMM_BILLMAT.DIVISOR","1")
		item_dev=fnget_dev("IVM_ITEMMAST")
		dim item_tpl$:fnget_tpl$("IVM_ITEMMAST")
		readrecord(item_dev,key=firm_id$+item$)item_tpl$
		callpoint!.setColumnData("BMM_BILLMAT.UNIT_MEASURE",item_tpl.unit_of_sale$)
		callpoint!.setStatus("REFRESH")
	endif
[[BMM_BILLMAT.SCRAP_FACTOR.AVAL]]
rem --- Display Net Quantity

	qty_req=num(callpoint!.getColumnData("BMM_BILLMAT.QTY_REQUIRED"))
	alt_fact=num(callpoint!.getColumnData("BMM_BILLMAT.ALT_FACTOR"))
	divisor=num(callpoint!.getColumnData("BMM_BILLMAT.DIVISOR"))
	scrap_fact=num(callpoint!.getUserInput())
	gosub calc_net
[[BMM_BILLMAT.DIVISOR.AVAL]]
rem --- Display Net Quantity

	qty_req=num(callpoint!.getColumnData("BMM_BILLMAT.QTY_REQUIRED"))
	alt_fact=num(callpoint!.getColumnData("BMM_BILLMAT.ALT_FACTOR"))
	divisor=num(callpoint!.getUserInput())
	scrap_fact=num(callpoint!.getColumnData("BMM_BILLMAT.SCRAP_FACTOR"))
	gosub calc_net
[[BMM_BILLMAT.ALT_FACTOR.AVAL]]
rem --- Display Net Quantity

	qty_req=num(callpoint!.getColumnData("BMM_BILLMAT.QTY_REQUIRED"))
	alt_fact=num(callpoint!.getUserInput())
	divisor=num(callpoint!.getColumnData("BMM_BILLMAT.DIVISOR"))
	scrap_fact=num(callpoint!.getColumnData("BMM_BILLMAT.SCRAP_FACTOR"))
	gosub calc_net
[[BMM_BILLMAT.QTY_REQUIRED.AVAL]]
rem --- Display Net Quantity

	qty_req=num(callpoint!.getUserInput())
	alt_fact=num(callpoint!.getColumnData("BMM_BILLMAT.ALT_FACTOR"))
	divisor=num(callpoint!.getColumnData("BMM_BILLMAT.DIVISOR"))
	scrap_fact=num(callpoint!.getColumnData("BMM_BILLMAT.SCRAP_FACTOR"))
	gosub calc_net
[[BMM_BILLMAT.<CUSTOM>]]
rem ===================================================================
calc_net:
rem --- qty_req:		input
rem --- alt_fact:			input
rem --- divisor:			input
rem --- scrap_fact:		input
rem ===================================================================

	mask$=callpoint!.getDevObject("unit_mask")
	yield_pct=callpoint!.getDevObject("yield")
	net_qty=BmUtils.netQuantityRequired(qty_req,alt_fact,divisor,yield_pct,scrap_fact)
	callpoint!.setColumnData("BMM_BILLMAT.NET_REQUIRED",str(net_qty:mask$))
rem	callpoint!.setStatus("SAVE")

	return

rem ===================================================================
check_sub:
rem --- item$:			input
rem ===================================================================

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="BMM_BILLMAST",open_opts$[1]="OTAN[2_]"
	gosub open_tables
	sub_bill$=""
	while 1
		find (num(open_chans$[1]),key=firm_id$+item$,dom=*break)
		sub_bill$="*"
		break
	wend
	open_opts$[1]="CX[2_]"
	gosub open_tables
	callpoint!.setColumnData("BMM_BILLMAT.SUB_BILL",sub_bill$)
rem	callpoint!.setStatus("REFRESH")

	return
[[BMM_BILLMAT.BSHO]]
rem --- Setup java class for Derived Data Element

	use ::bmo_BmUtils.aon::BmUtils
	declare BmUtils bmUtils!

rem --- Set DevObject for Net Quantity mask

	pgmdir$=stbl("+DIR_PGM",err=*next)
	call pgmdir$+"adc_getmask.aon","","IV","U","",m2$,0,m2
	callpoint!.setDevObject("unit_mask",m2$)

rem --- Open files for later use

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVM_ITEMMAST",open_opts$[1]="OTAN[2_]"
	gosub open_tables
[[BMM_BILLMAT.ITEM_ID.AINV]]
rem --- Check for item synonyms

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
