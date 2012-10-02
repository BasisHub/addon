[[IVR_ITMREQUIREMT.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVR_ITMREQUIREMT.ARAR]]
callpoint!.setColumnData("IVR_ITMREQUIREMT.REPORT_SEQUENCE","V")
callpoint!.setStatus("REFRESH")
