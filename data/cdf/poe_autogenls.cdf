[[POE_AUTOGENLS.BSHO]]
rem --- Open Files
	num_files=4
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="POE_RECDET",open_opts$[1]="OTA@"
	open_tables$[2]="POE_RECLSDET",open_opts$[2]="OTA@"
	open_tables$[3]="POE_RECLSDET",open_opts$[3]="OTA[1]"
	open_tables$[4]="IVM_LSMASTER",open_opts$[4]="OTA@"

	gosub open_tables
[[POE_AUTOGENLS.AREC]]
rem --- Get warehouse_id and item_id
	porecdet_dev=fnget_dev("@POE_RECDET")
	dim porecdet$:fnget_tpl$("@POE_RECDET")
	porecdet_key$=firm_id$+callpoint!.getColumnData("POE_AUTOGENLS.RECEIVER_NO")+callpoint!.getColumnData("POE_AUTOGENLS.PO_INT_SEQ_REF")
	readrecord(porecdet_dev,key=porecdet_key$)porecdet$
	callpoint!.setDevObject("warehouse_id",porecdet.warehouse_id$)
	callpoint!.setDevObject("item_id",porecdet.item_id$)
[[POE_AUTOGENLS.<CUSTOM>]]
rem =========================================================
checkSerialNoSize: rem --- Will new serial numbers be too large?
rem --- data out: lotser_base$
rem --- data out: lotser_numeric$
rem --- data out: lotser_mask$
rem --- data out: seq_mask$
rem --- data out: seq_max
rem --- data out: abort
rem =========================================================
	abort=0

	rem --- Get serial number base characters and trailing numeric
	first_lotser$=callpoint!.getColumnData("POE_AUTOGENLS.LOTSER_NO")
	lotser$=cvs(first_lotser$,3)
	base_len=len(lotser$)
	while base_len>0
		x=num(lotser$(base_len,1),err=*break)
		base_len=base_len-1
	wend
	lotser_base$=lotser$(1,base_len)
	lotser_numeric$=lotser$(base_len+1)
	lotser_mask$=pad("",len(cvs(lotser_numeric$,2)),"0")

	rem --- Calculate numeric for last lotser
	gen_qty=num(callpoint!.getColumnData("POE_AUTOGENLS.GEN_QTY"))
	last_num=gen_qty+num(lotser_numeric$)

	rem --- There must be enough remaining space in the starting serial number to hold all of the new ones
	dim poe_reclsdet$:fnget_tpl$("POE_RECLSDET")
	wk$=fattr(poe_reclsdet$,"lotser_no")
	max_digits=num(pad("",dec(wk$(10,2))-len(lotser_base$),"9"))
	if last_num>max_digits then
		msg_id$="PO_MAX_SERIAL_NO"
		dim msg_tokens$[2]
		msg_tokens$[1]=lotser_base$+str(last_num)
		msg_tokens$[2]=str(dec(wk$(10,2)))
		gosub disp_message
		abort=1
		return
	endif

	rem --- There must be enough remaining empty rows in the grid to hold all of the new ones
	dim poe_reclsdet$:fnget_tpl$("POE_RECLSDET")
	wk$=fattr(poe_reclsdet$,"sequence_no")
	seq_digits=dec(wk$(10,2))
	seq_mask$=pad("",seq_digits,"0")
	seq_max=num(pad("",seq_digits,"9"))
	max_rows=seq_max-num(callpoint!.getColumnData("POE_AUTOGENLS.ROWS_USED"))
	if gen_qty>max_rows then
		msg_id$="PO_SERIAL_ROWS"
		dim msg_tokens$[2]
		msg_tokens$[1]=str(max_rows)
		msg_tokens$[2]=str(gen_qty)
		gosub disp_message
		abort=1
		return
	endif

	return
[[POE_AUTOGENLS.ASVA]]
rem --- Will new serial numbers be too large?
	gosub checkSerialNoSize
	if abort then
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Build list of serial numbers not already entered
	poreclsdet_dev=fnget_dev("@POE_RECLSDET")
	dim poreclsdet$:fnget_tpl$("@POE_RECLSDET")
	receiver_no$=callpoint!.getColumnData("POE_AUTOGENLS.RECEIVER_NO")
	po_int_seq_ref$=callpoint!.getColumnData("POE_AUTOGENLS.PO_INT_SEQ_REF")
	entered_lotser$=""
	read(poreclsdet_dev,key=firm_id$+receiver_no$+po_int_seq_ref$,dom=*next)
	while 1
		poreclsdet_key$=key(poreclsdet_dev,end=*break)
		if pos(firm_id$+receiver_no$+po_int_seq_ref$=poreclsdet_key$)<>1 then break
		readrecord(poreclsdet_dev)poreclsdet$
		if cvs(poreclsdet.lotser_no$,2)<>"" then entered_lotser$=entered_lotser$+";"+poreclsdet.lotser_no$
	wend

rem --- Generate serial numbers
	lsmaster_dev=fnget_dev("@IVM_LSMASTER")
	dim lsmaster$:fnget_tpl$("@IVM_LSMASTER")
	poreclsdet1_dev=fnget_dev("1POE_RECLSDET")
	dim poreclsdet1$:fnget_tpl$("1POE_RECLSDET")
	po_no$=callpoint!.getColumnData("POE_AUTOGENLS.PO_NO")
	unit_cost=num(callpoint!.getColumnData("POE_AUTOGENLS.UNIT_COST"))
	warehouse_id$=callpoint!.getDevObject("warehouse_id")
	item_id$=callpoint!.getDevObject("item_id")
	next_lotser$=callpoint!.getColumnData("POE_AUTOGENLS.LOTSER_NO")

	rem --- Update poe_reclsdet (poe_24) with new serial numbers
	rem --- (lotser_base$, lotser_numeric$, lotser_mask$, seq_mask$ and seq_max come from checkSerialNoSize routine)
	rem --- Create new lot/serial numbers
	next_seq_no=0
	lotser_numeric$=str(num(lotser_numeric$)-1); rem --- starting lotser must be given first
	gen_qty=num(callpoint!.getColumnData("POE_AUTOGENLS.GEN_QTY"))
	for i=1 to gen_qty
		write_poreclsdet=1
		while write_poreclsdet
			lotser_numeric$=str(1+num(lotser_numeric$):lotser_mask$)
			next_lotser$(1)=lotser_base$+lotser_numeric$

			rem --- Verify serial number not currently in inventory
			lsmaster_found=0
			lsmaster_key$=firm_id$+warehouse_id$+item_id$+next_lotser$
			findrecord(lsmaster_dev,key=lsmaster_key$,dom=*next)lsmaster$; lsmaster_found=1
			if lsmaster_found and lsmaster.qty_on_hand-lsmaster.qty_commit>0 then continue

			rem --- Skip if serial number already used
			if pos(next_lotser$=entered_lotser$) then break

			rem --- Write new poe_reclsdet record
			dim poreclsdet1$:fattr(poreclsdet1$)
			poreclsdet1.firm_id$=firm_id$
			poreclsdet1.receiver_no$=receiver_no$
			poreclsdet1.po_int_seq_ref$=po_int_seq_ref$
			poreclsdet1.po_no$=po_no$
			poreclsdet1.lotser_no$=next_lotser$
			poreclsdet1.qty_received=1
			poreclsdet1.unit_cost=unit_cost
			while write_poreclsdet
				next_seq_no=next_seq_no+1
				if next_seq_no>seq_max then break
				poreclsdet1.sequence_no$=str(next_seq_no:seq_mask$)
				writerecord(poreclsdet1_dev,dom=*continue)poreclsdet1$
				write_poreclsdet=0
			wend
		wend
		if next_seq_no>seq_max then break
	next i
[[POE_AUTOGENLS.GEN_QTY.AVAL]]
rem ---GEN_QTY must be a positive integer
	serialQty=int(num(callpoint!.getUserInput()))
	callpoint!.setUserInput(str(serialQty))
