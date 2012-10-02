[[BMR_INDENTEDBILL.BILL_NO.AVAL]]
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
[[BMR_INDENTEDBILL.BFMC]]
rem --- Set Custom Query for BOM Item Number

	callpoint!.setTableColumnAttribute("BMR_INDENTEDBILL.BILL_NO_1", "IDEF", "BOM_LOOKUP")
	callpoint!.setTableColumnAttribute("BMR_INDENTEDBILL.BILL_NO_2", "IDEF", "BOM_LOOKUP")
[[BMR_INDENTEDBILL.AREC]]
rem --- Set default Warehouse

	whse$=callpoint!.getDevObject("dflt_whse")
	callpoint!.setColumnData("BMR_INDENTEDBILL.WAREHOUSE_ID",whse$,1)

[[BMR_INDENTEDBILL.BSHO]]
rem --- Open needed tables
	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="BMM_BILLMAST",open_opts$[2]="OTA"
	gosub open_tables

	ivs01_dev=num(open_chans$[1])
	dim ivs01a$:open_tpls$[1]

	read record (ivs01_dev,key=firm_id$+"IV00")ivs01a$
	callpoint!.setDevObject("dflt_whse",ivs01a.warehouse_id$)
