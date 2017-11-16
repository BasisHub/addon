[[APT_INVOICEHDR.ARAR]]
rem --- Initialize MAN_CK_* check boxes
	if callpoint!.getColumnData("APT_INVOICEHDR.MC_INV_FLAG")="M" then
		callpoint!.setColumnData("<<DISPLAY>>.MAN_CK_INV","Y",1)
	endif
	if callpoint!.getColumnData("APT_INVOICEHDR.MC_INV_ADJ")="A" then
		callpoint!.setColumnData("<<DISPLAY>>.MAN_CK_ADJ","Y",1)
	endif
	if callpoint!.getColumnData("APT_INVOICEHDR.MC_INV_REV")="R" then
		callpoint!.setColumnData("<<DISPLAY>>.MAN_CK_REV","Y",1)
	endif
