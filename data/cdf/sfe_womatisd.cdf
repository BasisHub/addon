[[SFE_WOMATISD.AGCL]]
rem --- set preset val for batch_no
	callpoint!.setTableColumnAttribute("SFE_WOMATISD.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[SFE_WOMATISD.REQUIRE_DATE.BINP]]
rem --- Enable lot/serial button
	gosub able_lot_button
[[SFE_WOMATISD.QTY_ISSUED.BINP]]
rem --- Enable lot/serial button
	gosub able_lot_button
[[SFE_WOMATISD.ITEM_ID.AVEC]]
rem --- Enable lot/serial button
	gosub able_lot_button
[[SFE_WOMATISD.BDGX]]
rem --- Disable detail-only buttons
	callpoint!.setOptionEnabled("LENT",0)
[[SFE_WOMATISD.AGRE]]
rem --- Start lot/serial button disabled
	callpoint!.setOptionEnabled("LENT",0)

rem --- Do not commit if row has been deleted
	if callpoint!.getGridRowDeleteStatus(callpoint!.getValidationRow())="Y" then
		rem --- row has been deleted, so do not commit inventory
		break
	endif

rem --- Init things for later
	warehouse_id$=callpoint!.getColumnData("SFE_WOMATISD.WAREHOUSE_ID")
	item_id$=callpoint!.getColumnData("SFE_WOMATISD.ITEM_ID")
	qty_ordered=num(callpoint!.getColumnData("SFE_WOMATISD.QTY_ORDERED"))
	tot_qty_iss=num(callpoint!.getColumnData("SFE_WOMATISD.TOT_QTY_ISS"))
	qty_issued=num(callpoint!.getColumnData("SFE_WOMATISD.QTY_ISSUED"))

rem --- Adjust committed if issue qty exceeds ordered qty 
rem --- (For new records qty_ordered=qty_issued and tot_qty_iss=0)
	if qty_issued+tot_qty_iss>qty_ordered then

rem --- Do not commit unless quantity issued has changed, or quantity issued exeeds quantity ordered
	sfe_womatisd_dev=fnget_dev("SFE_WOMATISD")
	dim sfe_womatisd$:fnget_tpl$("SFE_WOMATISD")
	firm_loc_wo$=callpoint!.getDevObject("firm_loc_wo")
	sfe_womatisd_key$=firm_loc_wo$+callpoint!.getColumnData("SFE_WOMATISD.MATERIAL_SEQ")
	readrecord(sfe_womatisd_dev,key=sfe_womatisd_key$,knum="AO_DISP_SEQ",dom=*next)sfe_womatisd$
	start_qty_issued=sfe_womatisd.qty_issued
	if qty_issued=start_qty_issued and qty_issued+tot_qty_iss<=qty_ordered then
		rem --- qty_issued has not changed and less than qty_ordered, so do not commit inventory
		break
	endif

rem --- Inform user when item quantity is recommitted
rem --- Actually, nothing is recommitted. In the update less will be uncommitted since qty_issued has decreased.
rem --- It's this reduction in uncommitted that is being described as recommitted.
	if qty_issued<start_qty_issued then
		msg_id$="SF_ITEM_RECOMMIT"
		dim msg_tokens$[2]
		msg_tokens$[1] = str(abs(start_qty_issued-qty_issued))
		msg_tokens$[2] = cvs(item_id$, 2)
		gosub disp_message
	endif
    
rem --- Initialize inventory item update
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

rem --- Do initial commit if nothing previously ordered or issued
	if qty_ordered=0 and tot_qty_iss=0 then
		qty_ordered=qty_issued
		callpoint!.setColumnData("SFE_WOMATISD.QTY_ORDERED",str(qty_ordered),1)

		items$[1]=warehouse_id$
		items$[2]=item_id$
		refs[0]=max(0,qty_ordered-tot_qty_iss)
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
	endif

	rem --- Lot/serial entry needed?
	if pos(callpoint!.getDevObject("lotser")="LS") then

		rem --- Item lotted/serialized and inventoried?
		ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")
		dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
		warehouse_id$=callpoint!.getDevObject("warehouse_id")
		item_id$=callpoint!.getColumnData("SFE_WOMATISD.ITEM_ID")
		findrecord(ivm_itemmast_dev,key=firm_id$+item_id$,dom=*next)ivm_itemmast$
		if ivm_itemmast.lotser_item$="Y" and ivm_itemmast.inventoried$="Y" then

			rem --- All lot/serial items issued already?
			sfe_wolsissu_dev=fnget_dev("SFE_WOLSISSU")
			dim sfe_wolsissu$:fnget_tpl$("SFE_WOLSISSU")
			tot_ls_qty_issued=0
			firm_loc_wo$=callpoint!.getDevObject("firm_loc_wo")
			firm_loc_wo_isn$=firm_loc_wo$+callpoint!.getColumnData("SFE_WOMATISD.INTERNAL_SEQ_NO")
			read(sfe_wolsissu_dev,key=firm_loc_wo_isn$,dom=*next)
			while 1
				sfe_wolsissu_key$=key(sfe_wolsissu_dev,end=*break)
				if pos(firm_loc_wo_isn$=sfe_wolsissu_key$)<>1 then break
				readrecord(sfe_wolsissu_dev)sfe_wolsissu$
				tot_ls_qty_issued=tot_ls_qty_issued+sfe_wolsissu.qty_issued
			wend

			if tot_ls_qty_issued<>qty_issued+num(callpoint!.getColumnData("SFE_WOMATISD.TOT_QTY_ISS")) then
				firm_loc_wo$=callpoint!.getDevObject("firm_loc_wo")
				firm_loc_wo_isn$=firm_loc_wo$+callpoint!.getColumnData("SFE_WOMATISD.INTERNAL_SEQ_NO")
				callpoint!.setDevObject("firm_loc_wo_isn",firm_loc_wo_isn$)
				callpoint!.setDevObject("item_id",callpoint!.getColumnData("SFE_WOMATISD.ITEM_ID"))
				callpoint!.setDevObject("womatisd_qty_issued",qty_issued)

				dim dflt_data$[3,1]
				dflt_data$[1,0] = "WO_LOCATION"
				dflt_data$[1,1] = callpoint!.getDevObject("wo_location")
				dflt_data$[2,0] = "WO_NO"
				dflt_data$[2,1] = callpoint!.getDevObject("wo_no")
				dflt_data$[3,0] = "WOMATISD_SEQ_REF"
				dflt_data$[3,1] = callpoint!.getColumnData("SFE_WOMATISD.INTERNAL_SEQ_NO")

				call stbl("+DIR_SYP")+"bam_run_prog.bbj","SFE_WOLSISSU",stbl("+USER_ID"),"MNT",firm_loc_wo_isn$,table_chans$[all],"",dflt_data$[all]

				qty_issued=num(callpoint!.getDevObject("tot_ls_qty_issued"))
				callpoint!.setColumnData("SFE_WOMATISD.QTY_ISSUED",str(qty_issued),1)
				if qty_issued<>0 then
					issue_cost=num(callpoint!.getDevObject("tot_ls_issue_cost"))/qty_issued
					unit_cost=issue_cost
					callpoint!.setColumnData("SFE_WOMATISD.UNIT_COST",str(unit_cost),0)
					callpoint!.setColumnData("SFE_WOMATISD.ISSUE_COST",str(issue_cost),1)
				endif
			endif
		endif
	endif

rem --- Adjust committed if issue qty exceeds ordered qty 
rem --- (For new records qty_ordered=qty_issued and tot_qty_iss=0)
	if qty_issued+tot_qty_iss>qty_ordered then
		comit_qty=qty_issued+tot_qty_iss-qty_ordered
		items$[1]=warehouse_id$
		items$[2]=item_id$
		refs[0]=max(0,qty_issued+tot_qty_iss-qty_ordered)
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

		rem --- Update order quantity with adjusted committed quantity
		qty_ordered=qty_issued+tot_qty_iss
		callpoint!.setColumnData("SFE_WOMATISD.QTY_ORDERED",str(qty_ordered),1)
	endif

rem --- Init DISPLAY columns
	gosub init_display_cols
[[SFE_WOMATISD.AOPT-LENT]]
rem --- Lot/serial entry
	firm_loc_wo$=callpoint!.getDevObject("firm_loc_wo")
	firm_loc_wo_isn$=firm_loc_wo$+callpoint!.getColumnData("SFE_WOMATISD.INTERNAL_SEQ_NO")
	callpoint!.setDevObject("firm_loc_wo_isn",firm_loc_wo_isn$)
	callpoint!.setDevObject("item_id",callpoint!.getColumnData("SFE_WOMATISD.ITEM_ID"))
	callpoint!.setDevObject("womatisd_qty_issued",callpoint!.getColumnData("SFE_WOMATISD.QTY_ISSUED"))

	rem --- Save current context so we'll know where to return from lot lookup
	declare BBjStandardGrid grid!
	grid! = util.getGrid(Form!)
	grid_ctx=grid!.getContextID()

	dim dflt_data$[3,1]
	dflt_data$[1,0] = "WO_LOCATION"
	dflt_data$[1,1] = callpoint!.getDevObject("wo_location")
	dflt_data$[2,0] = "WO_NO"
	dflt_data$[2,1] = callpoint!.getDevObject("wo_no")
	dflt_data$[3,0] = "WOMATISD_SEQ_REF"
	dflt_data$[3,1] = callpoint!.getColumnData("SFE_WOMATISD.INTERNAL_SEQ_NO")

	call stbl("+DIR_SYP")+"bam_run_prog.bbj","SFE_WOLSISSU",stbl("+USER_ID"),"MNT",firm_loc_wo_isn$,table_chans$[all],"",dflt_data$[all]

	qty_issued=num(callpoint!.getDevObject("tot_ls_qty_issued"))
	if qty_issued<>num(callpoint!.getColumnData("SFE_WOMATISD.QTY_ISSUED")) then
		rem --- Update detail row with new values
		callpoint!.setColumnData("SFE_WOMATISD.QTY_ISSUED",str(qty_issued),1)
		if qty_issued<>0 then
			issue_cost=num(callpoint!.getDevObject("tot_ls_issue_cost"))/qty_issued
			unit_cost=issue_cost
			callpoint!.setColumnData("SFE_WOMATISD.UNIT_COST",str(unit_cost),0)
			callpoint!.setColumnData("SFE_WOMATISD.ISSUE_COST",str(issue_cost),1)
		endif

		rem --- Force writing record with new values
		callpoint!.setStatus("MODIFIED")
	endif

	rem --- Reset focus on detail row where lot/serial lookup was executed
	sysgui!.setContext(grid_ctx)
[[SFE_WOMATISD.BGDS]]
rem --- Init Java classes
	use ::sfo_SfUtils.aon::SfUtils
	use ::ado_util.src::util

rem --- Init lot/serial additional option
	switch pos(callpoint!.getDevObject("lotser")="LS")
		case 1
			callpoint!.setOptionText("LENT",Translate!.getTranslation("AON_LOT_ENTRY"))
			break
		case 2
			callpoint!.setOptionText("LENT",Translate!.getTranslation("AON_SERIAL_ENTRY"))
			break
		case default
			callpoint!.setOptionEnabled("LENT",0)
			break
	swend
[[SFE_WOMATISD.BDEL]]
rem --- Has record been written yet?
	sfe_womatisd_dev=fnget_dev("SFE_WOMATISD")
	dim sfe_womatisd$:fnget_tpl$("SFE_WOMATISD")
	firm_loc_wo$=callpoint!.getDevObject("firm_loc_wo")
	sfe_womatisd_key$=firm_loc_wo$+callpoint!.getColumnData("SFE_WOMATISD.MATERIAL_SEQ")
	found=0
	readrecord(sfe_womatisd_dev,key=sfe_womatisd_key$,knum="AO_DISP_SEQ",dom=*next)sfe_womatisd$; found=1
	if !found then
		rem --- Record not written yet, so don't uncommit inventory
		break
	endif

rem --- Retain commitment on delete?
	msg_id$="SF_DELETE_ISSUE"
	gosub disp_message
	if msg_opt$="C" then
		callpoint!.setStatus("ABORT")
		break
	endif
	del_issue_only$=msg_opt$
	callpoint!.setDevObject("del_issue_only",msg_opt$)

rem --- Initialize inventory item update
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

rem --- Delete lot/serial and inventory commitments. Must do this before sfe_womatisd records are removed.
	sfe_womatdtl_dev=fnget_dev("SFE_WOMATDTL")
	dim sfe_womatdtl$:fnget_tpl$("SFE_WOMATDTL")
	sfe_wolsissu_dev=fnget_dev("SFE_WOLSISSU")
	dim sfe_wolsissu$:fnget_tpl$("SFE_WOLSISSU")

	rem --- Delete lot/serial commitments, but keep inventory commitments (for now)
	firm_loc_wo$=callpoint!.getDevObject("firm_loc_wo")
	if pos(callpoint!.getDevObject("lotser")="LS") then
		read(sfe_wolsissu_dev,key=firm_loc_wo$+sfe_womatisd.internal_seq_no$,dom=*next)
		while 1
			sfe_wolsissu_key$=key(sfe_wolsissu_dev,end=*break)
			if pos(firm_loc_wo$+sfe_womatisd.internal_seq_no$=sfe_wolsissu_key$)<>1 then break
			readrecord(sfe_wolsissu_dev)sfe_wolsissu$

			rem --- Delete lot/serial commitments
			items$[1]=sfe_womatisd.warehouse_id$
			items$[2]=sfe_womatisd.item_id$
			items$[3]=sfe_wolsissu.lotser_no$
			refs[0]=sfe_wolsissu.qty_issued
			call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

			rem --- Keep inventory commitments (for now)
			items$[3]=" "
			call stbl("+DIR_PGM")+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

			rem --- Barista isn't currently cascading this delete, re Barista bug 5979
			remove(sfe_wolsissu_dev,key=sfe_wolsissu_key$)
		wend
	endif

	rem --- Delete inventory commitments
	items$[1]=sfe_womatisd.warehouse_id$
	items$[2]=sfe_womatisd.item_id$
	if del_issue_only$="N" then
		rem --- Not retaining committments, so delete all of them
		refs[0]=max(0,sfe_womatisd.qty_ordered-sfe_womatisd.tot_qty_iss)
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

		found=0
		sfe_womatdtl_key$=firm_loc_wo$+sfe_womatisd.womatdtl_seq_ref$
		readrecord(sfe_womatdtl_dev,key=sfe_womatdtl_key$,dom=*next)sfe_womatdtl$; found=1
		if found then
			sfe_womatdtl.qty_ordered=sfe_womatdtl.tot_qty_iss
			writerecord(sfe_womatdtl_dev,key=sfe_womatdtl_key$)sfe_womatdtl$
		endif
	else
		rem --- Retaining committments, so only delete additional committments made after WO was released
		if cvs(sfe_womatisd.womatdtl_seq_ref$,2)="" then
			rem --- Not part of released WO, so uncommit all
			refs[0]=max(0,sfe_womatisd.qty_ordered-sfe_womatisd.tot_qty_iss)
			call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
		else
			rem --- Only uncommit portion of issue's qty_issued that is greater than released WO's qty_ordered
			found=0
			sfe_womatdtl_key$=firm_loc_wo$+sfe_womatisd.womatdtl_seq_ref$
			readrecord(sfe_womatdtl_dev,key=sfe_womatdtl_key$,dom=*next)sfe_womatdtl$; found=1
			if found then
				if max(0,sfe_womatisd.qty_ordered-sfe_womatisd.tot_qty_iss)>max(0,sfe_womatdtl.qty_ordered-sfe_womatdtl.tot_qty_iss) then
					refs[0]=max(0,sfe_womatisd.qty_ordered-sfe_womatisd.tot_qty_iss)-max(0,sfe_womatdtl.qty_ordered-sfe_womatdtl.tot_qty_iss)
					call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				endif
			endif
		endif
	endif
[[SFE_WOMATISD.AUDE]]
rem --- Make sure undeleted row gets written to file
	callpoint!.setStatus("MODIFIED")

rem --- It is "safer" to use qty_issued from what was restored to disk rather than the grid row
rem --- even though they "should" be the same. 
rem --- Was record written?
	sfe_womatisd_dev=fnget_dev("SFE_WOMATISD")
	dim sfe_womatisd$:fnget_tpl$("SFE_WOMATISD")
	firm_loc_wo$=callpoint!.getDevObject("firm_loc_wo")
	sfe_womatisd_key$=firm_loc_wo$+callpoint!.getColumnData("SFE_WOMATISD.MATERIAL_SEQ")
	found=0
	readrecord(sfe_womatisd_dev,key=sfe_womatisd_key$,knum="AO_DISP_SEQ",dom=*next)sfe_womatisd$; found=1
	if !found then
		rem --- Record not written , so do not undelete (recommit)
		break
	endif

rem --- Initialize inventory item update
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

rem --- Were commitments retained during delete? No if sfe_womatdtl.qty_ordered=sfe_womatisd.tot_qty_iss
	sfe_womatdtl_dev=fnget_dev("SFE_WOMATDTL")
	dim sfe_womatdtl$:fnget_tpl$("SFE_WOMATDTL")
	firm_loc_wo$=callpoint!.getDevObject("firm_loc_wo")
	sfe_womatdtl_key$=firm_loc_wo$+sfe_womatisd.womatdtl_seq_ref$
	readrecord(sfe_womatdtl_dev,key=sfe_womatdtl_key$,dom=*next)sfe_womatdtl$
	if sfe_womatdtl.qty_ordered=sfe_womatisd.tot_qty_iss then
		rem --- Undelete inventory commitments (recommit)
		sfe_womatdtl.qty_ordered=sfe_womatisd.qty_ordered
		writerecord(sfe_womatdtl_dev,key=sfe_womatdtl_key$)sfe_womatdtl$

		items$[1]=sfe_womatisd.warehouse_id$
		items$[2]=sfe_womatisd.item_id$
		refs[0]=max(0,sfe_womatisd.qty_ordered-sfe_womatisd.tot_qty_iss)
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
	endif

rem --- Init DISPLAY columns
	gosub init_display_cols
[[SFE_WOMATISD.ITEM_ID.AVAL]]
rem --- Item ID is disabled except for a new row, so can init entire new row here.
	item_id$=callpoint!.getUserInput()
	if item_id$=callpoint!.getColumnData("SFE_WOMATISD.ITEM_ID") then
		rem --- Do not re-init if user returns to item_id field on a new row
		break
	endif

	rem --- Get Warehouse ID and Issued Date from header
	warehouse_id$=callpoint!.getDevObject("warehouse_id")
	required_date$=callpoint!.getDevObject("issued_date")

	rem -- Get Unit of Measure and Unit Cost for this item
	ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
	ivm_itemwhse_dev=fnget_dev("IVM_ITEMWHSE")
	dim ivm_itemwhse$:fnget_tpl$("IVM_ITEMWHSE")
	findrecord(ivm_itemmast_dev,key=firm_id$+item_id$,dom=*next)ivm_itemmast$
	unit_measure$=ivm_itemmast.unit_of_sale$
	findrecord(ivm_itemwhse_dev,key=firm_id$+warehouse_id$+item_id$,dom=*next)ivm_itemwhse$
	unit_cost=ivm_itemwhse.unit_cost
	issue_cost=ivm_itemwhse.unit_cost

	rem --- Check item for commitments
	sfe_womatdtl_dev=fnget_dev("SFE_WOMATDTL")
	dim sfe_womatdtl$:fnget_tpl$("SFE_WOMATDTL")
	firm_loc_wo$=callpoint!.getDevObject("firm_loc_wo")
	read(sfe_womatdtl_dev,key=firm_loc_wo$,dom=*next)
	while 1
		sfe_womatdtl_key$=key(sfe_womatdtl_dev,end=*break)
		if pos(firm_loc_wo$=sfe_womatdtl_key$)<>1 then break
		readrecord(sfe_womatdtl_dev)sfe_womatdtl$
		rem --- Looking for matching warehouse and item
		if sfe_womatdtl.warehouse_id$+sfe_womatdtl.item_id$=warehouse_id$+item_id$ then
			unit_measure$=sfe_womatdtl.unit_measure$
			womatdtl_seq_ref$=sfe_womatdtl.internal_seq_no$
			warehouse_id$=sfe_womatdtl.warehouse_id$
			item_id$=sfe_womatdtl.item_id$
			require_date$=sfe_womatdtl.require_date$
			qty_ordered=sfe_womatdtl.qty_ordered
			tot_qty_iss=sfe_womatdtl.tot_qty_iss
			unit_cost=iff(sfe_womatdtl.unit_cost=0,ivm_itemwhse.unit_cost,sfe_womatdtl.unit_cost)
			qty_issued=sfe_womatdtl.qty_issued
			issue_cost=sfe_womatdtl.issue_cost
			break; rem --- found the one we were looking for
		endif
	wend

	rem --- Set and display data for new row
	callpoint!.setColumnData("SFE_WOMATISD.UNIT_MEASURE",unit_measure$,1)
	callpoint!.setColumnData("SFE_WOMATISD.WOMATDTL_SEQ_REF",womatdtl_seq_ref$,0)
	callpoint!.setColumnData("SFE_WOMATISD.WAREHOUSE_ID",warehouse_id$,0)
	callpoint!.setColumnData("SFE_WOMATISD.ITEM_ID",item_id$,1)
	callpoint!.setColumnData("SFE_WOMATISD.REQUIRE_DATE",required_date$,1)
	callpoint!.setColumnData("SFE_WOMATISD.QTY_ORDERED",str(qty_ordered),1)
	callpoint!.setColumnData("SFE_WOMATISD.TOT_QTY_ISS",str(tot_qty_iss),0)
	callpoint!.setColumnData("SFE_WOMATISD.UNIT_COST",str(unit_cost),0)
	callpoint!.setColumnData("SFE_WOMATISD.QTY_ISSUED",str(qty_issued),1)
	callpoint!.setColumnData("SFE_WOMATISD.ISSUE_COST",str(issue_cost),1)
	gosub init_display_cols; rem --- Init DISPLAY columns
[[SFE_WOMATISD.QTY_ISSUED.AVAL]]
rem --- Can't un-issue (negative issue) more than have already been issued.
	qty_issued=num(callpoint!.getUserInput())
	if qty_issued<0 and abs(qty_issued)>num(callpoint!.getColumnData("SFE_WOMATISD.TOT_QTY_ISS")) and
:	num(callpoint!.getColumnData("SFE_WOMATISD.QTY_ORDERED"))<>0 then
		msg_id$="SF_MAX_NEG_ISSU"
		dim msg_tokens$[1]
		msg_tokens$[1] = callpoint!.getColumnData("SFE_WOMATISD.TOT_QTY_ISS")
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Init DISPLAY columns
	callpoint!.setColumnData("SFE_WOMATISD.QTY_ISSUED",callpoint!.getUserInput())
	gosub init_display_cols
[[SFE_WOMATISD.<CUSTOM>]]
init_display_cols: rem --- Init DISPLAY columns
	qty_ordered=num(callpoint!.getColumnData("SFE_WOMATISD.QTY_ORDERED"))
	tot_qty_iss=num(callpoint!.getColumnData("SFE_WOMATISD.TOT_QTY_ISS"))
	callpoint!.setColumnData("<<DISPLAY>>.QTY_REMAIN",str(qty_ordered-tot_qty_iss),1)

	qty_issued=num(callpoint!.getColumnData("SFE_WOMATISD.QTY_ISSUED"))
	issue_cost=num(callpoint!.getColumnData("SFE_WOMATISD.ISSUE_COST"))
	callpoint!.setColumnData("<<DISPLAY>>.VALUE",str(qty_issued*issue_cost),1)
	return

able_lot_button: rem --- Enable/disable Lot/Serial button
	if pos(callpoint!.getDevObject("lotser")="LS") then
		ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")
		dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
		item_id$=callpoint!.getColumnData("SFE_WOMATISD.ITEM_ID")
		findrecord(ivm_itemmast_dev,key=firm_id$+item_id$,dom=*next)ivm_itemmast$
		if ivm_itemmast.lotser_item$="Y" and ivm_itemmast.inventoried$="Y" then 
			callpoint!.setOptionEnabled("LENT",1)
		else
			callpoint!.setOptionEnabled("LENT",0)
		endif
	endif
	return
[[SFE_WOMATISD.AGDR]]
rem --- Init DISPLAY columns
	gosub init_display_cols
[[SFE_WOMATISD.BGDR]]
rem --- Init DISPLAY columns

	qty_ordered=num(callpoint!.getColumnData("SFE_WOMATISD.QTY_ORDERED"))
	tot_qty_iss=num(callpoint!.getColumnData("SFE_WOMATISD.TOT_QTY_ISS"))
	callpoint!.setColumnData("<<DISPLAY>>.QTY_REMAIN",str(qty_ordered-tot_qty_iss),1)

	qty_issued=num(callpoint!.getColumnData("SFE_WOMATISD.QTY_ISSUED"))
	issue_cost=num(callpoint!.getColumnData("SFE_WOMATISD.ISSUE_COST"))
	callpoint!.setColumnData("<<DISPLAY>>.VALUE",str(qty_issued*issue_cost),1)
[[SFE_WOMATISD.AGRN]]
rem --- Init DISPLAY columns
	gosub init_display_cols
[[SFE_WOMATISD.ADGE]]

rem --- Set precision
	precision num(callpoint!.getDevObject("precision"))

[[SFE_WOMATISD.ITEM_ID.AINV]]
rem --- Item synonym processing
	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::grid_entry"
