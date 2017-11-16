[[ADM_RPT_RCP_LOAD.BSHO]]
rem --- Use customer lookup for customer recipient type 
	if callpoint!.getDevObject("recipient_tp")="C" then
		callpoint!.setTableColumnAttribute("ADM_RPT_RCP_LOAD.RECIPIENT_1","IDEF","AR_CUST_LK")
		callpoint!.setTableColumnAttribute("ADM_RPT_RCP_LOAD.RECIPIENT_2","IDEF","AR_CUST_LK")
	endif

rem --- Use vendor lookup for vendor recipient type 
	if callpoint!.getDevObject("recipient_tp")="V" then
		callpoint!.setTableColumnAttribute("ADM_RPT_RCP_LOAD.RECIPIENT_1","IDEF","AP_VEND_LK")
		callpoint!.setTableColumnAttribute("ADM_RPT_RCP_LOAD.RECIPIENT_2","IDEF","AP_VEND_LK")
	endif
