[[POE_RECLSDET.BEND]]
gosub check_lotser_tot

[[POE_RECLSDET.<CUSTOM>]]
check_lotser_tot:
rem --- warn if total lotted/serialized <> receipt qty --- allow to proceed, as register won't update under these circumstances

total_lotser=0

if gridVect!.size()<>0
dim rec$:fattr(rec_data$)
	for x=0 to gridVect!.size()-1
		if callpoint!.getGridRowDeleteStatus(x)<>"Y"
			rec$=gridVect!.getItem(x)
			total_lotser=total_lotser+num(rec.qty_received$)
		endif
	next x	
endif

if total_lotser<>num(callpoint!.getDevObject("ls_qty_received"))
	msg_id$="PO_REC_LOTS"
	dim msg_tokens$[2]
	msg_tokens$[1]=str(callpoint!.getDevObject("ls_qty_received"))
	msg_tokens$[2]=str(total_lotser)
	gosub disp_message
endif
return
[[POE_RECLSDET.QTY_RECEIVED.AVAL]]
rem ---- don't allow more lot/serial allocation than we have in the received qty in main form (need)
rem ---- if serial (as opposed to lots), qty must be one.

if callpoint!.getDevObject("lot_or_serial")="S"
	callpoint!.setUserInput("1")
endif
[[POE_RECLSDET.BSHO]]
callpoint!.setTableColumnAttribute("POE_RECLSDET.PO_NO","DFLT",str(callpoint!.getDevObject("ls_po_no")))
callpoint!.setTableColumnAttribute("POE_RECLSDET.QTY_RECEIVED","DFLT",str(callpoint!.getDevObject("ls_qty_received")))
if callpoint!.getDevObject("lot_or_serial")="S" then callpoint!.setTableColumnAttribute("POE_RECLSDET.QTY_RECEIVED","DFLT","1")
callpoint!.setTableColumnAttribute("POE_RECLSDET.UNIT_COST","DFLT",str(callpoint!.getDevObject("ls_unit_cost")))
