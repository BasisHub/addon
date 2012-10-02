[[IVR_ITEMLABELS.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVR_ITEMLABELS.ARAR]]
callpoint!.setColumnData("PICk_COUNT","1")
callpoint!.setStatus("REFRESH")
