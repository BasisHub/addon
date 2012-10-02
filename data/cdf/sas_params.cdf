[[SAS_PARAMS.BWRI]]
rem --- Check for valid data

	bad_data$="N"

rem --- check for option without detail level

	if callpoint!.getColumnData("SAS_PARAMS.BY_CUSTOMER") <> "N"
		if callpoint!.getColumnData("SAS_PARAMS.CUSTOMER_LEV") = " "
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.BY_TERRITORY") <> "N"
		if callpoint!.getColumnData("SAS_PARAMS.TERRCODE_LEV") = " "
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.BY_SALESPSN") <> "N"
		if callpoint!.getColumnData("SAS_PARAMS.SALESPSN_LEV") = " "
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.BY_CUSTOMER_TYPE") <> "N"
		if callpoint!.getColumnData("SAS_PARAMS.CUSTTYPE_LEV") = " "
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.BY_SHIPTO") <> "N"
		if callpoint!.getColumnData("SAS_PARAMS.SHIPTO_LEV") = " "
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.BY_SIC_CODE") <> "N"
		if callpoint!.getColumnData("SAS_PARAMS.SIC_CODE_LEV") = " "
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.BY_PRODUCT") <> "N"
		if callpoint!.getColumnData("SAS_PARAMS.PRODUCT_LEV") = " "
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.BY_WHSE") <> "N"
		if callpoint!.getColumnData("SAS_PARAMS.WHSE_LEV") = " "
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.BY_VENDOR") <> "N"
		if callpoint!.getColumnData("SAS_PARAMS.VENDOR_LEV") = " "
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.BY_DIST_CODE") <> "N"
		if callpoint!.getColumnData("SAS_PARAMS.DISTCODE_LEV") = " "
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.BY_NONSTOCK") <> "N"
		if callpoint!.getColumnData("SAS_PARAMS.NONSTOCK_LEV") = " "
			bad_data$="Y"
		endif
	endif

rem --- now check for detail level without option

	if callpoint!.getColumnData("SAS_PARAMS.CUSTOMER_LEV") <> ""
		if callpoint!.getColumnData("SAS_PARAMS.BY_CUSTOMER") = "N"
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.TERRCODE_LEV") <> ""
		if callpoint!.getColumnData("SAS_PARAMS.BY_TERRITORY") = "N"
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.SALESPSN_LEV") <> ""
		if callpoint!.getColumnData("SAS_PARAMS.BY_SALESPSN") = "N"
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.CUSTTYPE_LEV") <> ""
		if callpoint!.getColumnData("SAS_PARAMS.BY_CUSTOMER_TYPE") = "N"
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.SHIPTO_LEV") <> ""
		if callpoint!.getColumnData("SAS_PARAMS.BY_SHIPTO") = "N"
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.SIC_CODE_LEV") <> ""
		if callpoint!.getColumnData("SAS_PARAMS.BY_SIC_CODE") = "N"
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.PRODUCT_LEV") <> ""
		if callpoint!.getColumnData("SAS_PARAMS.BY_PRODUCT") = "N"
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.WHSE_LEV") <> ""
		if callpoint!.getColumnData("SAS_PARAMS.BY_WHSE") = "N"
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.VENDOR_LEV") <> ""
		if callpoint!.getColumnData("SAS_PARAMS.BY_VENDOR") = "N"
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.DISTCODE_LEV") <> ""
		if callpoint!.getColumnData("SAS_PARAMS.BY_DIST_CODE") = "N"
			bad_data$="Y"
		endif
	endif
	if callpoint!.getColumnData("SAS_PARAMS.NONSTOCK_LEV") <> ""
		if callpoint!.getColumnData("SAS_PARAMS.BY_NONSTOCK") = "N"
			bad_data$="Y"
		endif
	endif

rem - now display message if needed

	if bad_data$="Y"
		msg_id$="SA_PARAM_ERR"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
