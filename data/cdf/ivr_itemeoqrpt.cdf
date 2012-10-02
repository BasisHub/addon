[[IVR_ITEMEOQRPT.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVR_ITEMEOQRPT.ARAR]]
callpoint!.setColumnData("RPT_LEVEL","B")
callpoint!.setStatus("REFRESH")
