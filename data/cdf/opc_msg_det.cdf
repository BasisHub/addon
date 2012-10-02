[[OPC_MSG_DET.MESSAGE_TEXT.BINP]]
rem --- since sequence number is controlled by Barista, the logic below shouldn't be needed
rem --- rem'd rather than ripping it out


rem if cvs(callpoint!.getColumnData("OPC_MSG_DET.MESSAGE_SEQ"),3)=""
rem 	msg_id$="MISSING_SEQ"
rem 	gosub disp_message
rem 	callpoint!.setStatus("ABORT")
rem endif
