[[BMR_DETAILLIST.BILL_NO.AVAL]]
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
[[BMR_DETAILLIST.BFMC]]
rem --- Set Custom Query for BOM Item Number

	callpoint!.setTableColumnAttribute("BMR_DETAILLIST.BILL_NO_1", "IDEF", "BOM_LOOKUP")
	callpoint!.setTableColumnAttribute("BMR_DETAILLIST.BILL_NO_2", "IDEF", "BOM_LOOKUP")
[[BMR_DETAILLIST.BSHO]]
rem --- Open tables

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="BMM_BILLMAST",open_opts$[1]="OTA"
	gosub open_tables
[[BMR_DETAILLIST.ASVA]]
rem --- set DevObjects for the Jasper Report

	callpoint!.setDevObject("bill_from",callpoint!.getColumnData("BMR_DETAILLIST.BILL_NO_1"))
	callpoint!.setDevObject("bill_thru",callpoint!.getColumnData("BMR_DETAILLIST.BILL_NO_2"))
