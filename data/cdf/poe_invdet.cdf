[[POE_INVDET.MEMO_1024.BINQ]]
rem --- Launch Comments dialog
	gosub comment_entry
	callpoint!.setStatus("ABORT")
[[POE_INVDET.AOPT-COMM]]
rem --- invoke the comments dialog

	gosub comment_entry
[[POE_INVDET.AGDS]]
use ::ado_util.src::util

rem --- Set column size for memo_1024 field very small so it doesn't take up room, but still available for hover-over of memo contents

	grid! = form!.getControl(5000);rem - fixed control ID for stand-alone grid
	col_hdr$=callpoint!.getTableColumnAttribute("POE_INVDET.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(grid!, col_hdr$)
	grid!.setColumnWidth(memo_1024_col,15)
[[POE_INVDET.<CUSTOM>]]
rem ==========================================================================
comment_entry:
rem --- on a line where you can access the memo/non-stock (order_memo) field, pop the new memo_1024 editor instead
rem --- the editor can be popped on demand for any line using the Comments button (alt-C),
rem --- but will automatically pop for lines where the order_memo field is enabled.
rem ==========================================================================

	disp_text$=callpoint!.getColumnData("POE_INVDET.MEMO_1024")
	sv_disp_text$=disp_text$

	rem --- Allow editing comments only for line codes of type "O"
	poc_linecode_dev=fnget_dev("POC_LINECODE")
	dim poc_linecode$:fnget_tpl$("POC_LINECODE")
	po_line_code$=callpoint!.getColumnData("POE_INVDET.PO_LINE_CODE")
	read record (poc_linecode_dev,key=firm_id$+po_line_code$,dom=*next)poc_linecode$
	if poc_linecode.line_type$="O"
		editable$="YES"
	else
		editable$="NO"
	endif

	force_loc$="NO"
	baseWin!=null()
	startx=0
	starty=0
	shrinkwrap$="NO"
	html$="NO"
	dialog_result$=""

	call stbl("+DIR_SYP")+ "bax_display_text.bbj",
:		"Requisition/PO Comments",
:		disp_text$, 
:		table_chans$[all], 
:		editable$, 
:		force_loc$, 
:		baseWin!, 
:		startx, 
:		starty, 
:		shrinkwrap$, 
:		html$, 
:		dialog_result$

	if disp_text$<>sv_disp_text$
		memo_len=len(callpoint!.getColumnData("POE_INVDET.ORDER_MEMO"))
		order_memo$=disp_text$
		order_memo$=order_memo$(1,min(memo_len,(pos($0A$=order_memo$+$0A$)-1)))

		callpoint!.setColumnData("POE_INVDET.MEMO_1024",disp_text$,1)
		callpoint!.setColumnData("POE_INVDET.ORDER_MEMO",order_memo$,1)

		callpoint!.setStatus("MODIFIED")
	endif

	callpoint!.setStatus("ACTIVATE")

	return
[[POE_INVDET.ORDER_MEMO.BINP]]
rem --- invoke the comments dialog

	gosub comment_entry
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
	callpoint!.setColumnData("POE_INVDET.QTY_RECEIVED","1",1)
endif
