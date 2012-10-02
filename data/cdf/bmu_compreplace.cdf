[[BMU_COMPREPLACE.RPT_BILL_NO.AVAL]]
rem --- Set descriptions

	ivm_itemmast=fnget_dev("IVM_ITEMMAST")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
	item$=callpoint!.getUserInput()
	read record (ivm_itemmast,key=firm_id$+item$,dom=*next) ivm_itemmast$

	if num(callpoint!.getControlID()) = num(callpoint!.getControl("RPT_BILL_NO_1").getID()) then
		if cvs(item$,2)<>""
			callpoint!.setColumnData("<<DISPLAY>>.BEG_DESC",ivm_itemmast.item_desc$,1)
		else
			callpoint!.setColumnData("<<DISPLAY>>.BEG_DESC","First",1)
		endif
	endif
	if num(callpoint!.getControlID()) = num(callpoint!.getControl("RPT_BILL_NO_2").getID()) then
		if cvs(item$,2)<>""
			callpoint!.setColumnData("<<DISPLAY>>.END_DESC",ivm_itemmast.item_desc$,1)
		else
			callpoint!.setColumnData("<<DISPLAY>>.END_DESC","Last",1)
		endif
	endif
[[BMU_COMPREPLACE.BILL_CONV_FACT.AVAL]]
rem --- Ensure Conversion Factor is greater than zero

	if num(callpoint!.getUserInput())<=0
		msg_id$="BM_VAL_GRTR_ZERO"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[BMU_COMPREPLACE.AREC]]
rem -- Default Rounding precision from BOM params	
	
	prec$=callpoint!.getDevObject("bm_param_prec")
	callpoint!.setColumnData("BMU_COMPREPLACE.BM_ROUND_PREC",prec$,1)

rem --- Set initial values for descriptions

	callpoint!.setColumnData("<<DISPLAY>>.BEG_DESC","First",1)
	callpoint!.setColumnData("<<DISPLAY>>.END_DESC","Last",1)
[[BMU_COMPREPLACE.BSHO]]
rem --- Open needed tables

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="BMS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="IVM_ITEMMAST",open_opts$[2]="OTA"
	gosub open_tables
	
	bms01_dev=num(open_chans$[1])
	dim bms01a$:open_tpls$[1]

rem -- Get precision from BOM params for default Rounding Precision

	read record (bms01_dev,key=firm_id$+"BM00")bms01a$
	callpoint!.setDevObject("bm_param_prec",bms01a.bm_precision$)
