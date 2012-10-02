[[OPC_MSG_DET.MESSAGE_TEXT.BINP]]
if cvs(callpoint!.getColumnData("OPC_MSG_DET.MESSAGE_SEQ"),3)=""
	msg_id$="MISSING_SEQ"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
