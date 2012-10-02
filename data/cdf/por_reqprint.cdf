[[POR_REQPRINT.ARAR]]
rem --- set defaults

callpoint!.setColumnData("POR_REQPRINT.REPORT_TYPE","N")
callpoint!.setColumnData("POR_REQPRINT.RESTART","N")
callpoint!.setColumnData("POR_REQPRINT.MESSAGE_TEXT","")
callpoint!.setColumnData("POR_REQPRINT.VENDOR_ID","")

callpoint!.setStatus("REFRESH")
[[POR_REQPRINT.VENDOR_ID.AVAL]]
if num(callpoint!.getUserInput())<>0
	callpoint!.setColumnData("POR_REQPRINT.RESTART","Y")
	else
	callpoint!.setColumnData("POR_REQPRINT.RESTART","N")
endif

callpoint!.setStatus("REFRESH")
