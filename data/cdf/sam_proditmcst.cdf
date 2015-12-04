[[SAM_PRODITMCST.BPRK]]
rem --- Use current selections for initiating previous record
	year$=callpoint!.getColumnData("SAM_PRODITMCST.YEAR")
	product_type$=callpoint!.getColumnData("SAM_PRODITMCST.PRODUCT_TYPE")
	item_id$=callpoint!.getColumnData("SAM_PRODITMCST.ITEM_ID")
	sam_dev=fnget_dev("SAM_PRODITMCST")
	customer_id$=callpoint!.getColumnData("SAM_PRODITMCST.CUSTOMER_ID")
	read(sam_dev,key=firm_id$+year$+product_type$+item_id$+customer_id$,dir=0,dom=*next)
[[SAM_PRODITMCST.BNEK]]
rem --- Use current selections for initiating next record
	year$=callpoint!.getColumnData("SAM_PRODITMCST.YEAR")
	product_type$=callpoint!.getColumnData("SAM_PRODITMCST.PRODUCT_TYPE")
	item_id$=callpoint!.getColumnData("SAM_PRODITMCST.ITEM_ID")
	sam_dev=fnget_dev("SAM_PRODITMCST")
	customer_id$=callpoint!.getColumnData("SAM_PRODITMCST.CUSTOMER_ID")
	read(sam_dev,key=firm_id$+year$+product_type$+item_id$+customer_id$,dom=*next)
[[SAM_PRODITMCST.BOVE]]
rem --- Restrict lookup to orders
			
	alias_id$ = "SAM_CUSTOMER"
	inq_mode$ = ""
	key_pfx$  = firm_id$
	key_id$   = "AO_PRD_ITM_CST"
			
	dim filter_defs$[1,1]
			
	call stbl("+DIR_SYP")+"bam_inquiry.bbj",
:		gui_dev,
:		Form!,
:		alias_id$,
:		inq_mode$,
:		table_chans$[all],
:		key_pfx$,
:		key_id$,
:		selected_key$,
:		filter_defs$[all],
:		search_defs$[all]
			
	if selected_key$<>"" then 
		callpoint!.setStatus("RECORD:[" + selected_key$ +"]")
	else
		callpoint!.setStatus("ABORT")
	endif
	callpoint!.setStatus("ACTIVATE")
[[SAM_PRODITMCST.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[SAM_PRODITMCST.CUSTOMER_ID.AVAL]]
rem --- Enable/Disable Summary button
	prod_type$=callpoint!.getColumnData("SAM_PRODITMCST.PRODUCT_TYPE")
	item_no$=callpoint!.getColumnData("SAM_PRODITMCST.ITEM_ID")
	cust_no$=callpoint!.getUserInput()
	gosub summ_button
[[SAM_PRODITMCST.ITEM_ID.AVAL]]
rem --- Enable/Disable Summary button
	prod_type$=callpoint!.getColumnData("SAM_PRODITMCST.PRODUCT_TYPE")
	item_no$=callpoint!.getUserInput()
	cust_no$=callpoint!.getColumnData("SAM_PRODITMCST.CUSTOMER_ID")
	gosub summ_button
[[SAM_PRODITMCST.PRODUCT_TYPE.AVAL]]
rem --- Enable/Disable Summary button
	prod_type$=callpoint!.getUserInput()
	item_no$=callpoint!.getColumnData("SAM_PRODITMCST.ITEM_ID")
	cust_no$=callpoint!.getColumnData("SAM_PRODITMCST.CUSTOMER_ID")
	gosub summ_button
[[SAM_PRODITMCST.AOPT-SUMM]]
rem --- Calculate and display summary info
	tcst=0
	tqty=0
	tsls=0
	year$=callpoint!.getColumnData("SAM_PRODITMCST.YEAR")
	lyear$=str(num(year$)-1:"0000")
	trip_key$=firm_id$+year$+callpoint!.getColumnData("SAM_PRODITMCST.PRODUCT_TYPE")
	ltrip_key$=firm_id$+lyear$+callpoint!.getColumnData("SAM_PRODITMCST.PRODUCT_TYPE")
	item_no$=callpoint!.getColumnData("SAM_PRODITMCST.ITEM_ID")
	cust_no$=callpoint!.getColumnData("SAM_PRODITMCST.CUSTOMER_ID")
	if cvs(item_no$,2)<>"" 
		trip_key$=trip_key$+item_no$
		ltrip_key$=ltrip_key$+item_no$
	else
		callpoint!.setColumnData("SAM_PRODITMCST.ITEM_ID","")
	endif
	callpoint!.setColumnData("SAM_PRODITMCST.CUSTOMER_ID","")

rem --- Start progress meter
	task_id$=info(3,0)
	Window_Name$=Translate!.getTranslation("AON_SUMMARIZING")
	Progress! = bbjapi().getGroupNamespace()
	Progress!.setValue("+process_task",task_id$+"^C^"+Window_Name$+"^CNC-IND^"+str(n)+"^")

	sam_dev=	fnget_dev("SAM_PRODITMCST")
	dim sam_tpl$:fnget_tpl$("SAM_PRODITMCST")
	dim qty[13],cost[13],sales[13]

rem --- Calculate Last Year

	read(sam_dev,key=ltrip_key$,knum="AO_PRD_ITM_CST",dom=*next)
	while 1
		read record(sam_dev,end=*break)sam_tpl$

		Progress!.getValue("+process_task_"+task_id$,err=*next);break
	
		if pos(ltrip_key$=sam_tpl$)<>1 break
		for x=1 to 13
			qty[x]=qty[x]+nfield(sam_tpl$,"qty_shipped_"+str(x:"00"))
			cost[x]=cost[x]+nfield(sam_tpl$,"total_cost_"+str(x:"00"))
			sales[x]=sales[x]+nfield(sam_tpl$,"total_sales_"+str(x:"00"))
		next x
	wend
	For x=1 to 13
		tcst=tcst+cost[x]
		tqty=tqty+qty[x]
		tsls=tsls+sales[x]
	next x

	for x=1 to 13
		callpoint!.setColumnData("<<DISPLAY>>.LY_SHIP_"+str(x:"00"),str(qty[x]))
		callpoint!.setColumnData("<<DISPLAY>>.LY_SALES_"+str(x:"00"),str(sales[x]))
		callpoint!.setColumnData("<<DISPLAY>>.LY_COST_"+str(x:"00"),str(cost[x]))
	next x

	callpoint!.setColumnData("<<DISPLAY>>.LY_COST_TOT",str(tcst))
	callpoint!.setColumnData("<<DISPLAY>>.LY_SALES_TOT",str(tsls))
	callpoint!.setColumnData("<<DISPLAY>>.LY_SHIP_TOT",str(tqty))

	tcst=0
	tsls=0
	tqty=0
	dim cost[13],qty[13],sales[13]

rem --- Calculate This Year

	read(sam_dev,key=trip_key$,knum="AO_PRD_ITM_CST",dom=*next)
	while 1
		sam_key$=key(sam_dev,end=*break)
		if pos(trip_key$=sam_key$)<>1 break
		read record(sam_dev,knum="AO_PRD_ITM_CST",key=sam_key$)sam_tpl$

		Progress!.getValue("+process_task_"+task_id$,err=*next);break

		for x=1 to 13
			qty[x]=qty[x]+nfield(sam_tpl$,"qty_shipped_"+str(x:"00"))
			cost[x]=cost[x]+nfield(sam_tpl$,"total_cost_"+str(x:"00"))
			sales[x]=sales[x]+nfield(sam_tpl$,"total_sales_"+str(x:"00"))
		next x
	wend
	For x=1 to 13
		tcst=tcst+cost[x]
		tqty=tqty+qty[x]
		tsls=tsls+sales[x]
	next x

Progress!.setValue("+process_task",task_id$+"^D^")

rem --- Now display all of these things and disable key fields
	for x=1 to 13
		callpoint!.setColumnData("SAM_PRODITMCST.TOTAL_SALES_"+str(x:"00"),str(sales[x]))
		callpoint!.setColumnData("SAM_PRODITMCST.TOTAL_COST_"+str(x:"00"),str(cost[x]))
		callpoint!.setColumnData("SAM_PRODITMCST.QTY_SHIPPED_"+str(x:"00"),str(qty[x]))
	next x
	callpoint!.setColumnData("<<DISPLAY>>.TCST",str(tcst))
	callpoint!.setColumnData("<<DISPLAY>>.TQTY",str(tqty))
	callpoint!.setColumnData("<<DISPLAY>>.TSLS",str(tsls))

	callpoint!.setColumnEnabled("SAM_PRODITMCST.YEAR",0)
	callpoint!.setColumnEnabled("SAM_PRODITMCST.PRODUCT_TYPE",0)
	callpoint!.setColumnEnabled("SAM_PRODITMCST.ITEM_ID",0)
	callpoint!.setColumnEnabled("SAM_PRODITMCST.CUSTOMER_ID",0)
	callpoint!.setOptionEnabled("SUMM",0)
	callpoint!.setStatus("REFRESH-CLEAR")
[[SAM_PRODITMCST.ARAR]]
rem --- Create totals

	gosub calc_totals
[[SAM_PRODITMCST.AREC]]
rem --- Enable key fields
	ctl_name$="SAM_PRODITMCST.YEAR"
	ctl_stat$=""
	gosub disable_fields
	ctl_name$="SAM_PRODITMCST.PRODUCT_TYPE"
	ctl_stat$=""
	gosub disable_fields
	ctl_name$="SAM_PRODITMCST.ITEM_ID"
	ctl_stat$=""
	gosub disable_fields
	ctl_name$="SAM_PRODITMCST.CUSTOMER_ID"
	ctl_stat$=""
	gosub disable_fields
	callpoint!.setColumnData("<<DISPLAY>>.TCST","0")
	callpoint!.setColumnData("<<DISPLAY>>.TQTY","0")
	callpoint!.setColumnData("<<DISPLAY>>.TSLS","0")

	for x=1 to 13
		callpoint!.setColumnData("<<DISPLAY>>.LY_SHIP_"+str(x:"00"),"0")
		callpoint!.setColumnData("<<DISPLAY>>.LY_SALES_"+str(x:"00"),"0")
		callpoint!.setColumnData("<<DISPLAY>>.LY_COST_"+str(x:"00"),"0")
	next x

	callpoint!.setColumnData("<<DISPLAY>>.LY_COST_TOT","0")
	callpoint!.setColumnData("<<DISPLAY>>.LY_SALES_TOT","0")
	callpoint!.setColumnData("<<DISPLAY>>.LY_SHIP_TOT","0")

	callpoint!.setStatus("REFRESH")
[[SAM_PRODITMCST.BSHO]]
rem --- Check for parameter record
	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SAS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="SAM_PRODITMCST",open_opts$[2]="OTA@"
	gosub open_tables
	sas01_dev=num(open_chans$[1]),sas01a$=open_tpls$[1]

	dim sas01a$:sas01a$
	read record (sas01_dev,key=firm_id$+"SA00")sas01a$
	if sas01a.by_customer$<>"Y"
		msg_id$="INVALID_SA"
		dim msg_tokens$[1]
		msg_tokens$[1]=Translate!.getTranslation("AON_CUSTOMER")
		gosub disp_message
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif

rem --- disable total elements
	ctl_name$="<<DISPLAY>>.TQTY"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="<<DISPLAY>>.TCST"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="<<DISPLAY>>.TSLS"
	ctl_stat$="I"
	gosub disable_fields
	callpoint!.setStatus("ABLEMAP-ACTIVATE-REFRESH")

rem --- Disable Summary Button
	callpoint!.setOptionEnabled("SUMM",0)
[[SAM_PRODITMCST.<CUSTOM>]]
disable_fields:
rem --- used to disable/enable controls depending on parameter settings
rem --- send in control to toggle (format "ALIAS.CONTROL_NAME"), and D or space to disable/enable

	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)

	return

calc_totals:

rem --- Calculate Last Year

	year$=callpoint!.getColumnData("SAM_PRODITMCST.YEAR")
	lyear$=str(num(year$)-1:"0000")
	cust_no$=callpoint!.getColumnData("SAM_PRODITMCST.CUSTOMER_ID")
	prod$=callpoint!.getColumnData("SAM_PRODITMCST.PRODUCT_TYPE")
	item$=callpoint!.getColumnData("SAM_PRODITMCST.ITEM_ID")
	ltrip_key$=firm_id$+lyear$+prod$+item$+cust_no$
	sam_dev=fnget_dev("@SAM_PRODITMCST")
	dim sam_tpl$:fnget_tpl$("@SAM_PRODITMCST")
	dim qty[13],cost[13],sales[13]

	while 1
		read record(sam_dev,key=ltrip_key$,knum="AO_PRD_ITM_CST",dom=*break)sam_tpl$

		Progress!.getValue("+process_task_"+task_id$,err=*next);break
	
		if pos(ltrip_key$=sam_tpl.firm_id$+sam_tpl.year$+sam_tpl.product_type$+sam_tpl.item_id$+sam_tpl.customer_id$)<>1 break
		for x=1 to 13
			qty[x]=qty[x]+nfield(sam_tpl$,"qty_shipped_"+str(x:"00"))
			cost[x]=cost[x]+nfield(sam_tpl$,"total_cost_"+str(x:"00"))
			sales[x]=sales[x]+nfield(sam_tpl$,"total_sales_"+str(x:"00"))
		next x
		break
	wend
	For x=1 to 13
		tcst=tcst+cost[x]
		tqty=tqty+qty[x]
		tsls=tsls+sales[x]
	next x

	for x=1 to 13
		callpoint!.setColumnData("<<DISPLAY>>.LY_SHIP_"+str(x:"00"),str(qty[x]))
		callpoint!.setColumnData("<<DISPLAY>>.LY_SALES_"+str(x:"00"),str(sales[x]))
		callpoint!.setColumnData("<<DISPLAY>>.LY_COST_"+str(x:"00"),str(cost[x]))
	next x

	callpoint!.setColumnData("<<DISPLAY>>.LY_COST_TOT",str(tcst))
	callpoint!.setColumnData("<<DISPLAY>>.LY_SALES_TOT",str(tsls))
	callpoint!.setColumnData("<<DISPLAY>>.LY_SHIP_TOT",str(tqty))

	tcst=0
	tqty=0
	tsls=0
	For x=1 to 13
		tcst=tcst+num(callpoint!.getColumnData("SAM_PRODITMCST.TOTAL_COST_"+str(x:"00")))
		tqty=tqty+num(callpoint!.getColumnData("SAM_PRODITMCST.QTY_SHIPPED_"+str(x:"00")))
		tsls=tsls+num(callpoint!.getColumnData("SAM_PRODITMCST.TOTAL_SALES_"+str(x:"00")))
	next x
	callpoint!.setColumnData("<<DISPLAY>>.TCST",str(tcst))
	callpoint!.setColumnData("<<DISPLAY>>.TQTY",str(tqty))
	callpoint!.setColumnData("<<DISPLAY>>.TSLS",str(tsls))
	callpoint!.setStatus("REFRESH")

	return

rem --- Enable/Disable Summary Button
summ_button:
	if callpoint!.isEditMode() then callpoint!.setOptionEnabled("SUMM",1)
	if cvs(prod_type$,2)=""
		callpoint!.setOptionEnabled("SUMM",0)
	else
		if cvs(item_no$,2)=""
			if cvs(cust_no$,2)<>""
				callpoint!.setOptionEnabled("SUMM",0)
			endif
		else
			if cvs(cust_no$,2)<>""
				callpoint!.setOptionEnabled("SUMM",0)
			endif
		endif
	endif
	return
