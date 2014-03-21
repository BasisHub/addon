[[POE_RECLSDET.LOTSER_NO.AVAL]]
rem --- Initialize qty_received for new rows
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" then
		if callpoint!.getDevObject("lot_or_serial")="S" then 
			callpoint!.setColumnData("POE_RECLSDET.QTY_RECEIVED","1",1)
		else
			gosub get_lotser_tot
			callpoint!.setColumnData("POE_RECLSDET.QTY_RECEIVED",str(num(callpoint!.getDevObject("ls_qty_received"))-total_lotser),1)
		endif
	endif

rem --- Enable/disable additional options
	gosub enable_options
[[POE_RECLSDET.AOPT-AUTO]]
rem --- Generate new serial numbers
	gosub get_lotser_tot
	max_qty=num(callpoint!.getDevObject("ls_qty_received"))-total_lotser
	rows_used=GridVect!.size()
	if cvs(callpoint!.getColumnData("POE_RECLSDET.LOTSER_NO"),2)="" then
		rows_used=rows_used-1
	endif

	dim dflt_data$[7,1]
	dflt_data$[1,0]="RECEIVER_NO"
	dflt_data$[1,1]=callpoint!.getColumnData("POE_RECLSDET.RECEIVER_NO")
	dflt_data$[2,0]="PO_INT_SEQ_REF"
	dflt_data$[2,1]=callpoint!.getColumnData("POE_RECLSDET.PO_INT_SEQ_REF")
	dflt_data$[3,0]="PO_NO"
	dflt_data$[3,1]=callpoint!.getColumnData("POE_RECLSDET.PO_NO")
	dflt_data$[4,0]="LOTSER_NO"
	dflt_data$[4,1]=callpoint!.getColumnData("POE_RECLSDET.LOTSER_NO")
	dflt_data$[5,0]="UNIT_COST"
	dflt_data$[5,1]=callpoint!.getColumnData("POE_RECLSDET.UNIT_COST")
	dflt_data$[6,0]="GEN_QTY"
	dflt_data$[6,1]=str(max_qty)
	dflt_data$[7,0]="ROWS_USED"
	dflt_data$[7,1]=str(rows_used)

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"POE_AUTOGENLS",
:		stbl("+USER_ID"),
:		"",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]

rem --- Update grid with changes
	callpoint!.setStatus("CLEAR-REFGRID")

rem --- Enable/disable additional options
	gosub enable_options
[[POE_RECLSDET.AGRN]]
rem --- Enable/disable additional options
	gosub enable_options
[[POE_RECLSDET.AUDE]]
rem --- Enable/disable additional options
	gosub enable_options
[[POE_RECLSDET.AREC]]
rem --- Enable/disable additional options
	gosub enable_options
[[POE_RECLSDET.AWRI]]
rem --- Enable/disable additional options
	gosub enable_options
[[POE_RECLSDET.ADEL]]
rem --- Enable/disable additional options
	gosub enable_options
[[POE_RECLSDET.BEND]]
gosub check_lotser_tot
[[POE_RECLSDET.<CUSTOM>]]
rem ==========================================================================
get_lotser_tot: rem --- Sum up number of lotted/serialized items already entered
rem --- total_lotser: output
rem ==========================================================================
	total_lotser=0
	if gridVect!.size()<>0
		dim rec$:fattr(rec_data$)
		for x=0 to gridVect!.size()-1
			if callpoint!.getGridRowDeleteStatus(x)<>"Y"
				rec$=gridVect!.getItem(x)
				if len(rec$)>0 then total_lotser=total_lotser+rec.qty_received
			endif
		next x	
	endif
	return

rem ==========================================================================
check_lotser_tot:
rem --- warn if total lotted/serialized <> receipt qty --- allow to proceed, as register won't update under these circumstances
rem ==========================================================================
	gosub get_lotser_tot
	if total_lotser<>num(callpoint!.getDevObject("ls_qty_received"))
		msg_id$="PO_REC_LOTS"
		dim msg_tokens$[2]
		msg_tokens$[1]=str(callpoint!.getDevObject("ls_qty_received"))
		msg_tokens$[2]=str(total_lotser)
		gosub disp_message
	endif
	return

rem ==========================================================================
enable_options: rem --- Enable/disable additional options
rem ==========================================================================
	rem --- Disable auto-assign option when grid has been modified.
	rem --- Need to force write of current grid rows to file so they can be updated in the additional option.
	grid_modified=0
	for row=0 to GridVect!.size()-1
		if callpoint!.getGridRowModifyStatus(row)="Y" or callpoint!.getGridRowDeleteStatus(row)="Y" then
			grid_modified=1
			break
		endif
	next row

	if callpoint!.getDevObject("lot_or_serial")<>"S" or grid_modified then
		rem --- Disable auto-assign option when not serialized, or grid is in modified state
		callpoint!.setOptionEnabled("AUTO",0)
	else
		rem --- Disable auto-assign option when don't need more than one
		gosub get_lotser_tot
		if num(callpoint!.getDevObject("ls_qty_received"))-total_lotser<=1 then
			callpoint!.setOptionEnabled("AUTO",0)
		else
			callpoint!.setOptionEnabled("AUTO",1)
		endif
	endif
	return
[[POE_RECLSDET.QTY_RECEIVED.AVAL]]
rem --- Serialized QTY_RECEIVED must be an integer not more than 1 or less than -1
	if callpoint!.getDevObject("lot_or_serial")="S" then
		serialQty=int(num(callpoint!.getUserInput()))
		if serialQty>1 then serialQty=1
		if serialQty<-1 then serialQty=-1
		callpoint!.setUserInput(str(serialQty))
	endif

rem --- Enable/disable additional options
	gosub enable_options
[[POE_RECLSDET.BSHO]]
rem --- Initialize PO_NO and UNIT_COST
	callpoint!.setTableColumnAttribute("POE_RECLSDET.PO_NO","DFLT",str(callpoint!.getDevObject("ls_po_no")))
	callpoint!.setTableColumnAttribute("POE_RECLSDET.UNIT_COST","DFLT",str(callpoint!.getDevObject("ls_unit_cost")))
