[[POR_POPRINT.VENDOR_ID.AVAL]]
if num(callpoint!.getUserInput())<>0
	callpoint!.setColumnData("POR_POPRINT.RESTART","Y")
	else
	callpoint!.setColumnData("POR_POPRINT.RESTART","N")
endif

callpoint!.setStatus("REFRESH")
[[POR_POPRINT.ARAR]]
rem --- set defaults

callpoint!.setColumnData("POR_POPRINT.REPORT_TYPE","N")
callpoint!.setColumnData("POR_POPRINT.RESTART","N")
callpoint!.setColumnData("POR_POPRINT.MESSAGE_TEXT","")
callpoint!.setColumnData("POR_POPRINT.VENDOR_ID","")

callpoint!.setStatus("REFRESH")
