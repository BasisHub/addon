[[POE_INVDET.PO_LINE_CODE.AVAL]]
rem --- line code must be of type 'O'

poc_linecode_dev=fnget_dev("POC_LINECODE")
dim poc_linecode$:fnget_tpl$("POC_LINECODE")

read record (poc_linecode_dev,key=firm_id$+callpoint!.getUserInput(),dom=*next)poc_linecode$

if poc_linecode.line_type$<>"O"
	msg_id$="PO_LINE_CD"
	gosub disp_message
	callpoint!.setStatus("ABORT")
else
	callpoint!.setColumnData("POE_INVDET.QTY_RECEIVED","1")
	callpoint!.setStatus("REFRESH")
endif
