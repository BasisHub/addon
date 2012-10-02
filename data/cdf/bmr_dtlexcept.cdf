[[BMR_DTLEXCEPT.BILL_NO.AVAL]]
rem --- Set descriptions

	ivm_itemmast=fnget_dev("IVM_ITEMMAST")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
	item$=callpoint!.getUserInput()
	read record (ivm_itemmast,key=firm_id$+item$,dom=*next) ivm_itemmast$

	if num(callpoint!.getControlID()) = num(callpoint!.getControl("BILL_NO_1").getID()) then
		if cvs(item$,2)<>""
			callpoint!.setColumnData("<<DISPLAY>>.BEG_DESC",ivm_itemmast.item_desc$,1)
		else
			callpoint!.setColumnData("<<DISPLAY>>.BEG_DESC","First",1)
		endif
	endif
	if num(callpoint!.getControlID()) = num(callpoint!.getControl("BILL_NO_2").getID()) then
		if cvs(item$,2)<>""
			callpoint!.setColumnData("<<DISPLAY>>.END_DESC",ivm_itemmast.item_desc$,1)
		else
			callpoint!.setColumnData("<<DISPLAY>>.END_DESC","Last",1)
		endif
	endif
[[BMR_DTLEXCEPT.AREC]]
rem --- Set initial values for descriptions

	callpoint!.setColumnData("<<DISPLAY>>.BEG_DESC","First",1)
	callpoint!.setColumnData("<<DISPLAY>>.END_DESC","Last",1)
[[BMR_DTLEXCEPT.BSHO]]
rem --- Open tables

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVM_ITEMMAST",open_opts$[1]="OTA"
	gosub open_tables
