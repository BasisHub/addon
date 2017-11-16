[[POT_RECDET.BGDS]]
rem --- initialize storage for header total

	callpoint!.setDevObject("header_tot","0")
[[POT_RECDET.AGDS]]
rem --- update header tot

	tot_received=0
	tot_received=num(callpoint!.getDevObject("header_tot"),err=*next)
	totReceived!=callpoint!.getDevObject("totReceived")
	totReceived!.setText(str(tot_received))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.ORDER_TOTAL",str(tot_received))
[[POT_RECDET.AGDR]]
rem --- store extended amount for display in header

	ext_amt=round(num(callpoint!.getColumnData("POT_RECDET.UNIT_COST"))*num(callpoint!.getColumnData("POT_RECDET.QTY_RECEIVED")),2)
	callpoint!.setDevObject("header_tot",str(num(callpoint!.getDevObject("header_tot"))+ext_amt))

[[POT_RECDET.<CUSTOM>]]
rem ==========================================================================
#include std_missing_params.src
rem ==========================================================================

rem ==========================================================================
rem 	Use util object
rem ==========================================================================

	use ::ado_util.src::util
[[POT_RECDET.AGCL]]
rem --- Set column size for memo_1024 field very small so it doesn't take up room, but still available for hover-over of memo contents

	grid! = util.getGrid(Form!)
	col_hdr$=callpoint!.getTableColumnAttribute("POT_RECDET.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(grid!, col_hdr$)
	grid!.setColumnWidth(memo_1024_col,15)
[[POT_RECDET.ITEM_ID.AVAL]]
rem "Inventory Inactive Feature"
item_id$=callpoint!.getUserInput()
ivm01_dev=fnget_dev("IVM_ITEMMAST")
ivm01_tpl$=fnget_tpl$("IVM_ITEMMAST")
dim ivm01a$:ivm01_tpl$
ivm01a_key$=firm_id$+item_id$
find record (ivm01_dev,key=ivm01a_key$,err=*break)ivm01a$
if ivm01a.item_inactive$="Y" then
   msg_id$="IV_ITEM_INACTIVE"
   dim msg_tokens$[2]
   msg_tokens$[1]=cvs(ivm01a.item_id$,2)
   msg_tokens$[2]=cvs(ivm01a.display_desc$,2)
   gosub disp_message
   callpoint!.setStatus("ACTIVATE")
endif

