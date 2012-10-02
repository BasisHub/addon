[[IVR_LOTVENDHIST.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVR_LOTVENDHIST.ARAR]]
callpoint!.setColumnData("OP_CL_BOTH","B")

callpoint!.setStatus("REFRESH")
