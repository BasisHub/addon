[[IVM_ITEMPRIC.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVM_ITEMPRIC.BWRI]]
rem --- make sure each qty > previous one
ok$="Y"
for x=2 to 10
	wkvar$="BREAK_QTY_"+str(x:"00")
	wkvar1$="BREAK_QTY_"+str(x-1:"00")

	if num(field(rec_data$,wkvar$))<=num(field(rec_data$,wkvar1$)) and
:		num(field(rec_data$,wkvar$))<>0 and
:		num(field(rec_data$,wkvar1$))<>0
		ok$="N"
	endif
next x

if ok$="N"
	msg_id$="IV_QTYERR"
	gosub disp_message
	callpoint!.setStatus("ABORT-REFRESH")
endif
