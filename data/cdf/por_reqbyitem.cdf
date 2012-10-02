[[POR_REQBYITEM.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[POR_REQBYITEM.ARAR]]
callpoint!.setColumnData("POR_REQBYITEM.DATE_TYPE","O")
callpoint!.setStatus("REFRESH")

