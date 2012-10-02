[[BMR_BILLMATAVAIL.BILL_NO.AVAL]]
rem --- Set description

	ivm_itemmast=fnget_dev("IVM_ITEMMAST")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
	item$=callpoint!.getUserInput()
	read record (ivm_itemmast,key=firm_id$+item$,dom=*next) ivm_itemmast$

	if cvs(item$,2)<>""
		callpoint!.setColumnData("<<DISPLAY>>.BILL_DESC",ivm_itemmast.item_desc$,1)
	else
		callpoint!.setColumnData("<<DISPLAY>>.BILL_DESC","",1)
	endif
[[BMR_BILLMATAVAIL.AREC]]
rem --- Set initial values for descriptions

	callpoint!.setColumnData("<<DISPLAY>>.BILL_DESC","",1)
[[BMR_BILLMATAVAIL.BSHO]]
rem --- Open tables

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVM_ITEMMAST",open_opts$[1]="OTA"
	gosub open_tables
