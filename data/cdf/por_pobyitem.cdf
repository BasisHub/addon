[[POR_POBYITEM.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[POR_POBYITEM.ARAR]]
callpoint!.setColumnData("POR_POBYITEM.DATE_TYPE","O")
callpoint!.setStatus("REFRESH")
