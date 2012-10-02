[[IVR_LOTSTATUS.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVR_LOTSTATUS.ARAR]]
callpoint!.setColumnData("PICK_LISTBUTTON","I")
callpoint!.setColumnData("OP_CL_BOTH","B")

callpoint!.setStatus("REFRESH")
