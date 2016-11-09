[[BMU_COMPREPLACE.<CUSTOM>]]
#include std_missing_params.src
[[BMU_COMPREPLACE.BILL_NO.AVAL]]
rem --- Validate against BOM_BILLMAST

	bmm_billmast=fnget_dev("BMM_BILLMAST")
	found=0
	bill$=callpoint!.getUserInput()
	while 1
		find (bmm_billmast,key=firm_id$+bill$,dom=*break)
		found=1
		break
	wend

	if found=0 and cvs(bill$,3)<>""
		msg_id$="INPUT_ERR_DATA"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[BMU_COMPREPLACE.BFMC]]
rem --- Set Custom Query for BOM Item Number

	callpoint!.setTableColumnAttribute("BMU_COMPREPLACE.BILL_NO_1","IDEF","BOM_LOOKUP")
	callpoint!.setTableColumnAttribute("BMU_COMPREPLACE.BILL_NO_2","IDEF","BOM_LOOKUP")
[[BMU_COMPREPLACE.BILL_CONV_FACT.AVAL]]
rem --- Ensure Conversion Factor is greater than zero

	if num(callpoint!.getUserInput())<=0
		msg_id$="BM_VAL_GRTR_ZERO"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[BMU_COMPREPLACE.AREC]]
rem -- Default Rounding precision from BOM params	
	
	prec$=str(callpoint!.getDevObject("this_precision"))
	callpoint!.setColumnData("BMU_COMPREPLACE.BM_ROUND_PREC",prec$,1)
[[BMU_COMPREPLACE.BSHO]]
rem --- Open needed tables

	num_files=3
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="BMS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="BMM_BILLMAST",open_opts$[2]="OTA"
	open_tables$[3]="IVS_PARAMS",open_opts$[3]="OTA"

	gosub open_tables
	
	bms01_dev=num(open_chans$[1])
	dim bms01a$:open_tpls$[1]
	ivs01_dev=num(open_chans$[3])
	dim ivs01a$:open_tpls$[3]

rem -- Get precision from BOM params for default Rounding Precision

	read record (bms01_dev,key=firm_id$+"BM00",dom=std_missing_params)bms01a$
	callpoint!.setDevObject("bm_param_prec",str(bms01a.bm_precision))

	read record (ivs01_dev,key=firm_id$+"IV00",dom=std_missing_params)ivs01a$
	if num(ivs01a.precision$)>bms01a.bm_precision then
		callpoint!.setDevObject("this_precision",num(ivs01a.precision$))
	else
		callpoint!.setDevObject("this_precision",bms01a.bm_precision)
	endif
