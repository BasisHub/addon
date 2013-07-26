[[POE_INVDET.BEND]]
rem --- Reset Header Balance

	recVect!=GridVect!.getItem(0)
	gridrec=fnget_dev("POE_INVDET")
	dim gridrec$:fnget_tpl$("POE_INVDET")
	tdist=0
	ap_type$=callpoint!.getColumnData("POE_INVDET.AP_TYPE")
	vendor_id$=callpoint!.getColumnData("POE_INVDET.VENDOR_ID")
	ap_inv_no$=callpoint!.getColumnData("POE_INVDET.AP_INV_NO")

	read (gridrec,key=firm_id$+ap_type$+vendor_id$+ap_inv_no$,dom=*next)
	while 1
		read record (gridrec,end=*break) gridrec$
		if pos(firm_id$+ap_type$+vendor_id$+ap_inv_no$=gridrec$)<>1 break
		tdist=tdist+round((gridrec.qty_received)*(gridrec.unit_cost),2)
	wend

	dist_bal=num(callpoint!.getDevObject("invdet_bal"))-tdist
	dist_bal!=callpoint!.getDevObject("dist_bal_control")
	dist_bal!.setValue(dist_bal)
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
