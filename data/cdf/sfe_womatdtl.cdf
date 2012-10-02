[[SFE_WOMATDTL.BDGX]]
rem -- Get starting and ending rowQtyMap!s
	start_rowQtyMap!=callpoint!.getDevObject("start_rowQtyMap")
	gosub build_rowQtyMap
	end_rowQtyMap!=rowQtyMap!

rem --- May want to reprint pick list if commitments changed
	if !start_rowQtyMap!.equals(end_rowQtyMap!) then
		rem --- Don't need to reprint pick list if have work order commit transaction
		sfe_wocommit_dev=fnget_dev("SFE_WOCOMMIT")
		dim sfe_wocommit$:fnget_tpl$("SFE_WOCOMMIT")
		sfe_wocommit.firm_id$=firm_id$
		sfe_wocommit.wo_location$=callpoint!.getHeaderColumnData("SFE_WOMATHDR.WO_LOCATION")
		sfe_wocommit.wo_no$=callpoint!.getHeaderColumnData("SFE_WOMATHDR.WO_NO")
		sfe_wocommit_key$=sfe_wocommit.firm_id$+sfe_wocommit.wo_location$+sfe_wocommit.wo_no$
		have_commit_trans=0
		find(sfe_wocommit_dev,key=sfe_wocommit_key$,dom=*next); have_commit_trans=1
		if !have_commit_trans then
			msg_id$="SF_REPRINT_PICK_LIST"
			gosub disp_message
			if msg_opt$="Y"then
				msg_id$="SF_REPRINT_NEXT_BTCH"
				gosub disp_message
				writerecord(sfe_wocommit_dev)sfe_wocommit$

				rem --- Remove any existing material issues for this WO
				have_issues=0
				sfe_womatish_dev=fnget_dev("SFE_WOMATISH")
				sfe_womatisd_dev=fnget_dev("SFE_WOMATISD")
				sfe_womatish_key$=firm_id$+callpoint!.getHeaderColumnData("SFE_WOMATHDR.WO_LOCATION")+
:					callpoint!.getHeaderColumnData("SFE_WOMATHDR.WO_NO")
				read(sfe_womatish_dev,key=sfe_womatish_key$,dom=*next); have_issues=1
				if have_issues then
					rem --- NOTE: This code should never get executed because of check for existing materials issues in ADIS of main form.
					remove(sfe_womatish_dev,key=sfe_womatish_key$)
					read(sfe_womatisd_dev,key=sfe_womatish_key$,dom=*next)
					while 1
						sfe_womatisd_key$=key(sfe_womatisd_dev,end=*break)
						if pos(sfe_womatish_key$=sfe_womatisd_key$)<>1 then break
						remove(sfe_womatisd_dev,key=sfe_womatisd_key$)
					wend
				endif
			endif
		endif
	endif
[[SFE_WOMATDTL.BGDR]]
rem --- Init DISPLAY columns
	gosub init_display_cols
[[SFE_WOMATDTL.AGRE]]
rem --- Do not commit if row has been deleted
	if callpoint!.getGridRowDeleteStatus(callpoint!.getValidationRow())="Y" then
		rem --- row has been deleted, so do not commit inventory
		break
	endif

rem --- Do not commit unless quantity ordered has changed
	sfe_womatdtl_dev=fnget_dev("SFE_WOMATDTL")
	dim sfe_womatdtl$:fnget_tpl$("SFE_WOMATDTL")
	sfe_womatdtl_key$=firm_id$+callpoint!.getColumnData("SFE_WOMATDTL.WO_LOCATION")+
:		callpoint!.getColumnData("SFE_WOMATDTL.WO_NO")+callpoint!.getColumnData("SFE_WOMATDTL.MATERIAL_SEQ")
	readrecord(sfe_womatdtl_dev,key=sfe_womatdtl_key$,knum="AO_DISP_SEQ",dom=*next)sfe_womatdtl$
	start_qty_ordered=sfe_womatdtl.qty_ordered
	qty_ordered=num(callpoint!.getColumnData("SFE_WOMATDTL.QTY_ORDERED"))
	if qty_ordered=start_qty_ordered then
		rem --- qty_ordered has not changed, so do not commit inventory
		break
	endif
    
rem --- Initialize inventory item update
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

rem  --- Update committed quantity
	items$[1]=sfe_womatdtl.warehouse_id$
	items$[2]=sfe_womatdtl.item_id$
	if qty_ordered>start_qty_ordered then
		refs[0]=qty_ordered-start_qty_ordered
		action$="CO"
	else
		refs[0]=start_qty_ordered-qty_ordered; rem --- already prevent qty_ordered from being less than tot_qty_iss
		action$="UC"
	endif
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon",action$,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
[[SFE_WOMATDTL.AGRN]]
rem --- Init DISPLAY columns
	gosub init_display_cols
[[SFE_WOMATDTL.<CUSTOM>]]
init_display_cols: rem --- Init DISPLAY columns
	qty_ordered=num(callpoint!.getColumnData("SFE_WOMATDTL.QTY_ORDERED"))
	tot_qty_iss=num(callpoint!.getColumnData("SFE_WOMATDTL.TOT_QTY_ISS"))
	callpoint!.setColumnData("<<DISPLAY>>.QTY_REMAIN",str(qty_ordered-tot_qty_iss),1)

	rem --- Get inventory quantities for item
	ivm_itemwhse_dev=fnget_dev("IVM_ITEMWHSE")
	dim ivm_itemwhse$:fnget_tpl$("IVM_ITEMWHSE")
	ivm_itemwhse_key$=firm_id$+callpoint!.getColumnData("SFE_WOMATDTL.WAREHOUSE_ID")+callpoint!.getColumnData("SFE_WOMATDTL.ITEM_ID")
	findrecord(ivm_itemwhse_dev,key=ivm_itemwhse_key$,dom=*next)ivm_itemwhse$

	callpoint!.setColumnData("<<DISPLAY>>.QTY_AVAILABLE",str(ivm_itemwhse.qty_on_hand-ivm_itemwhse.qty_commit),1)
	callpoint!.setColumnData("<<DISPLAY>>.QTY_ON_ORDER",str(ivm_itemwhse.qty_on_order),1)
	return

rem ==========================================================================
build_rowQtyMap: rem --- Build rowQtyMap!
rem --- The rowQtyMap! is keyed by sfe_womatdtl.internal_seq_no$ and holds sfe_womatdtl.qty_ordered.
rem --- It is used to determine if any qty_ordered is different than when entry started, and thus maybe requiring reprint
rem --- of the pick list. A simple flag does not work for this since the qty_ordered could be changed multiple times, and
rem --- ending up back where it originally started.
rem --- output: rowQtyMap!
rem ==========================================================================
	rowQtyMap!=new java.util.HashMap()
	sfe_womatdtl_dev=fnget_dev("SFE_WOMATDTL")
	dim sfe_womatdtl$:fnget_tpl$("SFE_WOMATDTL")

	firm_loc_wo$=firm_id$+callpoint!.getHeaderColumnData("SFE_WOMATHDR.WO_LOCATION")+callpoint!.getHeaderColumnData("SFE_WOMATHDR.WO_NO")
	read(sfe_womatdtl_dev,key=firm_loc_wo$,dom=*next)
	while 1
		sfe_womatdtl_key$=key(sfe_womatdtl_dev,end=*break)
		if pos(firm_loc_wo$=sfe_womatdtl_key$)<>1 then break
		readrecord(sfe_womatdtl_dev)sfe_womatdtl$
		rowQtyMap!.put(sfe_womatdtl.internal_seq_no$, sfe_womatdtl.qty_ordered)
	wend
	return
[[SFE_WOMATDTL.AGDR]]
rem --- Init DISPLAY columns
	gosub init_display_cols
[[SFE_WOMATDTL.ADGE]]
rem --- Set precision
	precision num(callpoint!.getDevObject("precision"))
[[SFE_WOMATDTL.AUDE]]
rem --- Make sure undeleted row gets written to file
	callpoint!.setStatus("MODIFIED")

rem --- It is "safer" to use qty_ordered from what was restored to disk rather than the grid row
rem --- even though they "should" be the same. 
rem --- Was record written?
	sfe_womatdtl_dev=fnget_dev("SFE_WOMATDTL")
	dim sfe_womatdtl$:fnget_tpl$("SFE_WOMATDTL")
	sfe_womatdtl_key$=firm_id$+callpoint!.getColumnData("SFE_WOMATDTL.WO_LOCATION")+
:		callpoint!.getColumnData("SFE_WOMATDTL.WO_NO")+callpoint!.getColumnData("SFE_WOMATDTL.MATERIAL_SEQ")
	found=0
	readrecord(sfe_womatdtl_dev,key=sfe_womatdtl_key$,knum="AO_DISP_SEQ",dom=*next)sfe_womatdtl$; found=1
	if !found then
		rem --- Record not written yet, so don't uncommit inventory
		break
	endif

rem --- Initialize inventory item update
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

rem  --- Update committed quantity
	items$[1]=sfe_womatdtl.warehouse_id$
	items$[2]=sfe_womatdtl.item_id$
	refs[0]=sfe_womatdtl.qty_ordered-sfe_womatdtl.tot_qty_iss
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

rem --- Init DISPLAY columns
	gosub init_display_cols
[[SFE_WOMATDTL.BDEL]]
rem --- Has record been written yet?
	sfe_womatdtl_dev=fnget_dev("SFE_WOMATDTL")
	dim sfe_womatdtl$:fnget_tpl$("SFE_WOMATDTL")
	sfe_womatdtl_key$=firm_id$+callpoint!.getColumnData("SFE_WOMATDTL.WO_LOCATION")+
:		callpoint!.getColumnData("SFE_WOMATDTL.WO_NO")+callpoint!.getColumnData("SFE_WOMATDTL.MATERIAL_SEQ")
	found=0
	readrecord(sfe_womatdtl_dev,key=sfe_womatdtl_key$,knum="AO_DISP_SEQ",dom=*next)sfe_womatdtl$; found=1
	if !found then
		rem --- Record not written yet, so don't uncommit inventory
		break
	endif
    
rem --- Initialize inventory item update
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

rem  --- Update committed quantity
	items$[1]=sfe_womatdtl.warehouse_id$
	items$[2]=sfe_womatdtl.item_id$
	refs[0]=sfe_womatdtl.qty_ordered-sfe_womatdtl.tot_qty_iss
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
[[SFE_WOMATDTL.QTY_ORDERED.AVAL]]
rem --- qty_ordered cannot be less than tot_qty_iss
	qty_ordered=num(callpoint!.getUserInput())
	tot_qty_iss=num(callpoint!.getColumnData("SFE_WOMATDTL.TOT_QTY_ISS"))
	if qty_ordered<tot_qty_iss then
		msg_id$="SF_ISS_EXCEEDS_ORD"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Update balance (qty_remain)
	qty_ordered=num(callpoint!.getUserInput())
	tot_qty_iss=num(callpoint!.getColumnData("SFE_WOMATDTL.TOT_QTY_ISS"))
	callpoint!.setColumnData("<<DISPLAY>>.QTY_REMAIN",str(qty_ordered-tot_qty_iss),1)
[[SFE_WOMATDTL.ITEM_ID.AVAL]]
rem --- Item ID is disabled except for a new row, so can init entire new row here.
	item_id$=callpoint!.getUserInput()
	if item_id$=callpoint!.getColumnData("SFE_WOMATDTL.ITEM_ID") then
		rem --- Do not re-init if user returns to item_id field on a new row
		break
	endif

	rem --- Get Warehouse ID from header
	warehouse_id$=callpoint!.getHeaderColumnData("SFE_WOMATHDR.WAREHOUSE_ID")

	rem --- Default require_date to today
	dim sysinfo$:stbl("+SYSINFO_TPL")
	sysinfo$=stbl("+SYSINFO")

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

	rem --- Set and display data for new row
	callpoint!.setColumnData("SFE_WOMATDTL.ITEM_ID",item_id$,0); rem --- needed in init_display_cols routine
	callpoint!.setColumnData("SFE_WOMATDTL.WAREHOUSE_ID",warehouse_id$,0)
	callpoint!.setColumnData("SFE_WOMATDTL.REQUIRE_DATE",sysinfo.system_date$,1)
	callpoint!.setColumnData("SFE_WOMATDTL.UNIT_MEASURE",unit_measure$,1)
	callpoint!.setColumnData("SFE_WOMATDTL.QTY_ORDERED",str(0),1)
	callpoint!.setColumnData("SFE_WOMATDTL.TOT_QTY_ISS",str(0),0)
	callpoint!.setColumnData("SFE_WOMATDTL.UNIT_COST",str(unit_cost),0)
	callpoint!.setColumnData("SFE_WOMATDTL.QTY_ISSUED",str(0),1)
	callpoint!.setColumnData("SFE_WOMATDTL.ISSUE_COST",str(issue_cost),0)
	gosub init_display_cols; rem --- Init DISPLAY columns
[[SFE_WOMATDTL.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::grid_entry"
