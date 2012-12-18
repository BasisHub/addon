[[SFE_AUTOGENLS.ASVA]]
rem --- Generate new lot/serial numbers
	lsmaster_dev=fnget_dev("@IVM_LSMASTER")
	dim lsmaster$:fnget_tpl$("@IVM_LSMASTER")
	wolotser_dev=fnget_dev("@SFE_WOLOTSER")
	dim wolotser$:fnget_tpl$("@SFE_WOLOTSER")
	wolotser1_dev=fnget_dev("1SFE_WOLOTSER")
	dim wolotser1$:fnget_tpl$("1SFE_WOLOTSER")
	womastr_dev=fnget_dev("@SFE_WOMASTR")
	dim womastr$:fnget_tpl$("@SFE_WOMASTR")
	wo_location$=callpoint!.getColumnData("SFE_AUTOGENLS.WO_LOCATION")
	wo_no$=callpoint!.getColumnData("SFE_AUTOGENLS.WO_NO")
	warehouse_id$=callpoint!.getColumnData("SFE_AUTOGENLS.WAREHOUSE_ID")
	item_id$=callpoint!.getColumnData("SFE_AUTOGENLS.ITEM_ID")

	rem --- Get starting value, mask and maximum value for sfe_wolotser.sequence_no$
	sequence_no$=callpoint!.getDevObject("sequence_no")
	seq_mask$=pad("",len(sequence_no$),"0")
	seq_max=num(pad("",len(sequence_no$),"9"))
	next_seq_no=num(sequence_no$)

	rem --- Get lot/serial base characters and trailing numeric
	next_lotser$=callpoint!.getColumnData("SFE_AUTOGENLS.LOTSER_NO")
	lotser$=cvs(next_lotser$,3)
	base_len=len(lotser$)
	while base_len>0
		x=num(lotser$(base_len,1),err=*break)
		base_len=base_len-1
	wend
	lotser_base$=lotser$(1,base_len)
	lotser_numeric$=lotser$(base_len+1)
	num_mask$=pad(num_mask$,len(lotser_numeric$),"0")

	rem --- Create new lot/serial numbers
	ls_created=0
	lotser_numeric$=str(num(lotser_numeric$)-1); rem --- starting lotser must be given first
	gen_qty=num(callpoint!.getColumnData("SFE_AUTOGENLS.GEN_QTY"))
	for i=1 to gen_qty
		write_wolotser=1
		while write_wolotser
			lotser_numeric$=str(1+num(lotser_numeric$):num_mask$)
			next_lotser$(1)=lotser_base$+lotser_numeric$

			rem --- Verify lot/serial not currently in inventory
			lsmaster_found=0
			lsmaster_key$=firm_id$+warehouse_id$+item_id$+next_lotser$
			findrecord(lsmaster_dev,key=lsmaster_key$,dom=*next)lsmaster$; lsmaster_found=1
			if lsmaster_found and lsmaster.qty_on_hand-lsmaster.qty_commit>0 then continue

			rem --- Verify lot/serial can be used
			wolotser_found=0
			findrecord(wolotser_dev,key=firm_id$+next_lotser$,knum="AO_LOTSER",dom=*next)wolotser$; wolotser_found=1
			if wolotser_found then
				rem --- This next_lotser already entered for a work order being closed.
				if wolotser.wo_location$=wo_location$ and wolotser.wo_no$=wo_no$ then
					rem --- This next_lotser already entered for this work order being closed.
					continue
				else
					rem --- This next_lotser already entered for a different work order being closed.
					rem --- Is that other work order for the same item (finished good)?
					womastr_found=0
					findrecord(womastr_dev,key=firm_id$+wolotser.wo_location$+wolotser.wo_no$,dom=*next)womastr$; womastr_found=1
					if womastr_found and womastr.warehouse_id$=warehouse_id$ and womastr.item_id$=item_id$ then
						continue
					endif
				endif
			endif

			rem --- Write new sfe_wolotser record
			dim wolotser1$:fattr(wolotser1$)
			wolotser1.firm_id$=firm_id$
			wolotser1.wo_location$=wo_location$
			wolotser1.wo_no$=wo_no$
			wolotser1.closed_flag$=""
			wolotser1.closed_date$=""
			wolotser1.complete_flg$="N"
			wolotser1.lotser_no$=next_lotser$
			wolotser1.sch_prod_qty=1
			wolotser1.qty_cls_todt=0
			wolotser1.cls_cst_todt=0
			wolotser1.cls_inp_qty=0
			wolotser1.closed_cost=0
			while write_wolotser
				next_seq_no=next_seq_no+1
				if next_seq_no>seq_max then break
				wolotser1.sequence_no$=str(next_seq_no:seq_mask$)
				writerecord(wolotser1_dev,dom=*continue)wolotser1$
				ls_created=ls_created+1
				write_wolotser=0
			wend
		wend
		if next_seq_no>seq_max then break
	next i

rem --- Return actually number of new lot/serial numbers created
	callpoint!.setDevObject("ls_created",ls_created)

rem --- Warn if fewer new lot/serial numbers were created than requested
	if ls_created<gen_qty then
			msg_id$="SF_LS_NOT_CREATED"
			dim msg_tokens$[2]
			msg_tokens$[1]=str(ls_created)
			msg_tokens$[2]=str(gen_qty)
			gosub disp_message
	endif
[[SFE_AUTOGENLS.BSHO]]
rem --- Open Files
	num_files=4
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFE_WOMASTR",open_opts$[1]="OTA@"
	open_tables$[2]="SFE_WOLOTSER",open_opts$[2]="OTA@"
	open_tables$[3]="SFE_WOLOTSER",open_opts$[3]="OTA[1]"
	open_tables$[4]="IVM_LSMASTER",open_opts$[4]="OTA@"

	gosub open_tables

rem --- Set gen_qty maximum value to max_qty when given
	seterr skip_max_qty
	max_qty=int(callpoint!.getDevObject("max_qty"))
	seterr std_error
	callpoint!.setTableColumnAttribute("SFE_AUTOGENLS.GEN_QTY","MAXV",str(max_qty))

skip_max_qty:
	seterr std_error
