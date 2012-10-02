[[SAM_DISTCODE.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[SAM_DISTCODE.PRODUCT_TYPE.AVAL]]
rem --- Enable/Disable Summary button
	dist_code$=callpoint!.getColumnData("SAM_DISTCODE.AR_DIST_CODE")
	prod_type$=callpoint!.getUserInput()
	item_no$=callpoint!.getColumnData("SAM_DISTCODE.ITEM_ID")
	gosub summ_button
[[SAM_DISTCODE.ITEM_ID.AVAL]]
rem --- Enable/Disable Summary button
	dist_code$=callpoint!.getColumnData("SAM_DISTCODE.AR_DIST_CODE")
	prod_type$=callpoint!.getColumnData("SAM_DISTCODE.PRODUCT_TYPE")
	item_no$=callpoint!.getUserInput()
	gosub summ_button
[[SAM_DISTCODE.AR_DIST_CODE.AVAL]]
rem --- Enable/Disable Summary button
	dist_code$=callpoint!.getUserInput()
	prod_type$=callpoint!.getColumnData("SAM_DISTCODE.PRODUCT_TYPE")
	item_no$=callpoint!.getColumnData("SAM_DISTCODE.ITEM_ID")
	gosub summ_button
[[SAM_DISTCODE.AOPT-SUMM]]
rem --- Calculate and display summary info
	tcst=0
	tqty=0
	tsls=0
	trip_key$=firm_id$+callpoint!.getColumnData("SAM_DISTCODE.YEAR")+callpoint!.getColumnData("SAM_DISTCODE.AR_DIST_CODE")
	prod_type$=callpoint!.getColumnData("SAM_DISTCODE.PRODUCT_TYPE")
	item_no$=callpoint!.getColumnData("SAM_DISTCODE.ITEM_ID")
	if cvs(prod_type$,2)<>"" 
		trip_key$=trip_key$+prod_type$
	else
		callpoint!.setColumnData("SAM_DISTCODE.PRODUCT_TYPE","")
	endif
	callpoint!.setColumnData("SAM_DISTCODE.ITEM_ID","")

rem --- Start progress meter
	task_id$=info(3,0)
	Window_Name$=Translate!.getTranslation("AON_SUMMARIZING")
	Progress! = bbjapi().getGroupNamespace()
	Progress!.setValue("+process_task",task_id$+"^C^"+Window_Name$+"^CNC-IND^"+str(n)+"^")

	sam_dev=	fnget_dev("SAM_DISTCODE")
	dim sam_tpl$:fnget_tpl$("SAM_DISTCODE")
	dim qty[13],cost[13],sales[13]
	read(sam_dev,key=trip_key$,dom=*next)
	while 1
		read record(sam_dev,end=*break)sam_tpl$

		Progress!.getValue("+process_task_"+task_id$,err=*next);break

		if pos(trip_key$=sam_tpl$)<>1 break
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
		callpoint!.setColumnData("SAM_DISTCODE.TOTAL_SALES_"+str(x:"00"),str(sales[x]))
		callpoint!.setColumnData("SAM_DISTCODE.TOTAL_COST_"+str(x:"00"),str(cost[x]))
		callpoint!.setColumnData("SAM_DISTCODE.QTY_SHIPPED_"+str(x:"00"),str(qty[x]))
	next x
	callpoint!.setColumnData("<<DISPLAY>>.TCST",str(tcst))
	callpoint!.setColumnData("<<DISPLAY>>.TQTY",str(tqty))
	callpoint!.setColumnData("<<DISPLAY>>.TSLS",str(tsls))

	callpoint!.setColumnEnabled("SAM_DISTCODE.YEAR",0)
	callpoint!.setColumnEnabled("SAM_DISTCODE.AR_DIST_CODE",0)
	callpoint!.setColumnEnabled("SAM_DISTCODE.PRODUCT_TYPE",0)
	callpoint!.setColumnEnabled("SAM_DISTCODE.ITEM_ID",0)
	callpoint!.setOptionEnabled("SUMM",0)
	callpoint!.setStatus("REFRESH-CLEAR")
[[SAM_DISTCODE.ARAR]]
rem --- Create totals

	gosub calc_totals
[[SAM_DISTCODE.AREC]]
rem --- Enable key fields
	ctl_name$="SAM_DISTCODE.YEAR"
	ctl_stat$=""
	gosub disable_fields
	ctl_name$="SAM_DISTCODE.AR_DIST_CODE"
	ctl_stat$=""
	gosub disable_fields
	ctl_name$="SAM_DISTCODE.PRODUCT_TYPE"
	ctl_stat$=""
	gosub disable_fields
	ctl_name$="SAM_DISTCODE.ITEM_ID"
	ctl_stat$=""
	gosub disable_fields
	callpoint!.setColumnData("<<DISPLAY>>.TCST","0")
	callpoint!.setColumnData("<<DISPLAY>>.TQTY","0")
	callpoint!.setColumnData("<<DISPLAY>>.TSLS","0")
	callpoint!.setStatus("REFRESH")
[[SAM_DISTCODE.BSHO]]
rem --- Check for parameter record
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SAS_PARAMS",open_opts$[1]="OTA"
	gosub open_tables
	sas01_dev=num(open_chans$[1]),sas01a$=open_tpls$[1]

	dim sas01a$:sas01a$
	read record (sas01_dev,key=firm_id$+"SA00")sas01a$
	if sas01a.by_dist_code$<>"Y"
		msg_id$="INVALID_SA"
		dim msg_tokens$[1]
		msg_tokens$[1]=Translate!.getTranslation("AON_DIST_CODE")
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
[[SAM_DISTCODE.<CUSTOM>]]
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
	
	tcst=0
	tqty=0
	tsls=0
	For x=1 to 13
		tcst=tcst+num(callpoint!.getColumnData("SAM_DISTCODE.TOTAL_COST_"+str(x:"00")))
		tqty=tqty+num(callpoint!.getColumnData("SAM_DISTCODE.QTY_SHIPPED_"+str(x:"00")))
		tsls=tsls+num(callpoint!.getColumnData("SAM_DISTCODE.TOTAL_SALES_"+str(x:"00")))
	next x
	callpoint!.setColumnData("<<DISPLAY>>.TCST",str(tcst))
	callpoint!.setColumnData("<<DISPLAY>>.TQTY",str(tqty))
	callpoint!.setColumnData("<<DISPLAY>>.TSLS",str(tsls))
	callpoint!.setStatus("REFRESH")

	return

rem --- Enable/Disable Summary Button
summ_button:
	callpoint!.setOptionEnabled("SUMM",1)
	if cvs(dist_code$,2)=""
		callpoint!.setOptionEnabled("SUMM",0)
	else
		if cvs(prod_type$,2)=""
			if cvs(item_no$,2)<>""
				callpoint!.setOptionEnabled("SUMM",0)
			endif
		else
			if cvs(item_no$,2)<>""
				callpoint!.setOptionEnabled("SUMM",0)
			endif
		endif
	endif
	return
