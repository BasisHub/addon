[[GLX_COPYCHART.ASVA]]
if callpoint!.getColumnData("GLX_COPYCHART.COMPANY_ID_FROM")=callpoint!.getColumnData("GLX_COPYCHART.COMPANY_ID_TO") then 
	msg_id$="GL_FIRMS"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
