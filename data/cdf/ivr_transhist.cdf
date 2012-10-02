[[IVR_TRANSHIST.TRAN_HST_PO.AVAL]]
if callpoint!.getUserInput()="N"
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_ALL","N")
	user_tpl.all_on$="N"
	callpoint!.setStatus("REFRESH")
else
	gosub check_all
endif
[[IVR_TRANSHIST.TRAN_HST_TI.AVAL]]
if callpoint!.getUserInput()="N"
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_ALL","N")
	user_tpl.all_on$="N"
	callpoint!.setStatus("REFRESH")
else
	gosub check_all
endif
[[IVR_TRANSHIST.TRAN_HST_TO.AVAL]]
if callpoint!.getUserInput()="N"
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_ALL","N")
	user_tpl.all_on$="N"
	callpoint!.setStatus("REFRESH")
else
	gosub check_all
endif
[[IVR_TRANSHIST.TRAN_HST_WI.AVAL]]
if callpoint!.getUserInput()="N"
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_ALL","N")
	user_tpl.all_on$="N"
	callpoint!.setStatus("REFRESH")
else
	gosub check_all
endif
[[IVR_TRANSHIST.TRAN_HST_WO.AVAL]]
if callpoint!.getUserInput()="N"
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_ALL","N")
	user_tpl.all_on$="N"
	callpoint!.setStatus("REFRESH")
else
	gosub check_all
endif
[[IVR_TRANSHIST.TRAN_HST_PH.AVAL]]
if callpoint!.getUserInput()="N"
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_ALL","N")
	user_tpl.all_on$="N"
	callpoint!.setStatus("REFRESH")
else
	gosub check_all
endif
[[IVR_TRANSHIST.TRAN_HST_OP.AVAL]]
if callpoint!.getUserInput()="N"
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_ALL","N")
	user_tpl.all_on$="N"
	callpoint!.setStatus("REFRESH")
else
	gosub check_all
endif
[[IVR_TRANSHIST.TRAN_HST_IT.AVAL]]
if callpoint!.getUserInput()="N"
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_ALL","N")
	user_tpl.all_on$="N"
	callpoint!.setStatus("REFRESH")
else
	gosub check_all
endif
[[IVR_TRANSHIST.TRAN_HST_BM.AVAL]]
if callpoint!.getUserInput()="N"
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_ALL","N")
	user_tpl.all_on$="N"
	callpoint!.setStatus("REFRESH")
else
	gosub check_all
endif
[[IVR_TRANSHIST.BSHO]]
rem --- Setup user_tpl$
	dim user_tpl$:"all_on:c(1)"
	user_tpl.all_on$="Y"
[[IVR_TRANSHIST.TRAN_HST_ALL.AVAL]]
if callpoint!.getUserInput()="Y" and user_tpl.all_on$="N"
	gosub turn_on_all
	user_tpl.all_on$="Y"
endif
if callpoint!.getUserInput()="N" and user_tpl.all_on$="Y"
	gosub turn_off_all
	user_tpl.all_on$="N"
endif
[[IVR_TRANSHIST.<CUSTOM>]]
rem --- Turn all checkboxes on
turn_on_all:
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_BM","Y")
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_IT","Y")
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_OP","Y")
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_PH","Y")
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_PO","Y")
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_TI","Y")
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_TO","Y")
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_WI","Y")
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_WO","Y")
	callpoint!.setStatus("REFRESH")
return
rem --- Turn all checkboxes off
turn_off_all:
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_BM","N")
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_IT","N")
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_OP","N")
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_PH","N")
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_PO","N")
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_TI","N")
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_TO","N")
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_WI","N")
	callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_WO","N")
	callpoint!.setStatus("REFRESH")
return
rem --- turn ALL checbox on if all checkboxes on
check_all:
	if callpoint!.getColumnData("IVR_TRANSHIST.TRAN_HST_BM")="Y" and
:	callpoint!.getColumnData("IVR_TRANSHIST.TRAN_HST_IT")="Y" and
:	callpoint!.getColumnData("IVR_TRANSHIST.TRAN_HST_OP")="Y" and
:	callpoint!.getColumnData("IVR_TRANSHIST.TRAN_HST_PH")="Y" and
:	callpoint!.getColumnData("IVR_TRANSHIST.TRAN_HST_PO")="Y" and
:	callpoint!.getColumnData("IVR_TRANSHIST.TRAN_HST_TI")="Y" and
:	callpoint!.getColumnData("IVR_TRANSHIST.TRAN_HST_TO")="Y" and
:	callpoint!.getColumnData("IVR_TRANSHIST.TRAN_HST_WI")="Y" and
:	callpoint!.getColumnData("IVR_TRANSHIST.TRAN_HST_WO")="Y"
		callpoint!.setColumnData("IVR_TRANSHIST.TRAN_HST_ALL","Y")
		user_tpl.all_on$="Y"
		callpoint!.setStatus("REFRESH")
	endif
	return

