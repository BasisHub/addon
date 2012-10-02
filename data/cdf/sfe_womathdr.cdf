[[SFE_WOMATHDR.ARNF]]
rem --- Write work order commit transaction
	sfe_wocommit_dev=fnget_dev("SFE_WOCOMMIT")
	dim sfe_wocommit$:fnget_tpl$("SFE_WOCOMMIT")
	sfe_wocommit.firm_id$=firm_id$
	sfe_wocommit.wo_location$=callpoint!.getColumnData("SFE_WOMATHDR.WO_LOCATION")
	sfe_wocommit.wo_no$=callpoint!.getColumnData("SFE_WOMATHDR.WO_NO")
	writerecord(sfe_wocommit_dev)sfe_wocommit$

rem --- Initialize inventory item update
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

rem --- Initialize SFE_WOMATDTL Materials Commitment Detail from SFE_WOMATL Material Requirements
rem --- so can display new detail in grid.
	sfe_womatdtl_dev=fnget_dev("SFE_WOMATDTL")
	sfe_womatl_dev=fnget_dev("SFE_WOMATL")
	dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")

	sfe_womathdr_key$=firm_id$+callpoint!.getColumnData("SFE_WOMATHDR.WO_LOCATION")+callpoint!.getColumnData("SFE_WOMATHDR.WO_NO")
	read(sfe_womatl_dev,key=sfe_womathdr_key$,dom=*next)
	while 1
		sfe_womatl_key$=key(sfe_womatl_dev,end=*break)
		if pos(sfe_womathdr_key$=sfe_womatl_key$)<>1 then break
		readrecord(sfe_womatl_dev)sfe_womatl$
		if sfe_womatl.line_type$="M" then continue; rem --- skip message lines

		rem --- Skip if SFE_WOMATDTL record already exists
		dim sfe_womatdtl$:fnget_tpl$("SFE_WOMATDTL")
		sfe_womatdtl.firm_id$=sfe_womatl.firm_id$
		sfe_womatdtl.wo_location$=sfe_womatl.wo_location$
		sfe_womatdtl.wo_no$=sfe_womatl.wo_no$
		sfe_womatdtl.material_seq$=sfe_womatl.material_seq$
		internal_seq_no$=""
		call stbl("+DIR_SYP")+"bas_sequences.bbj","INTERNAL_SEQ_NO",internal_seq_no$,table_chans$[all],"QUIET"
		sfe_womatdtl.internal_seq_no$=internal_seq_no$
		sfe_womatdtl_key$=sfe_womatdtl.firm_id$+sfe_womatdtl.wo_location$+sfe_womatdtl.wo_no$+sfe_womatdtl.internal_seq_no$
		find(sfe_womatdtl_dev,key=sfe_womatdtl_key$,dom=*next); continue

		rem --- Initialize and write new SFE_WOMATDTL record
		sfe_womatdtl.unit_measure$=sfe_womatl.unit_measure$
		sfe_womatdtl.require_date$=sfe_womatl.require_date$
		sfe_womatdtl.warehouse_id$=callpoint!.getColumnData("SFE_WOMATHDR.WAREHOUSE_ID")
		sfe_womatdtl.item_id$=sfe_womatl.item_id$
		sfe_womatdtl.qty_ordered=sfe_womatl.total_units
		sfe_womatdtl.tot_qty_iss=0
		sfe_womatdtl.unit_cost=sfe_womatl.iv_unit_cost
		sfe_womatdtl.qty_issued=0
		sfe_womatdtl.issue_cost=sfe_womatl.iv_unit_cost
		writerecord(sfe_womatdtl_dev)sfe_womatdtl$

		rem  --- Update committed quantity
		items$[1]=sfe_womatdtl.warehouse_id$
		items$[2]=sfe_womatdtl.item_id$
		refs[0]=sfe_womatdtl.qty_ordered
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
	wend

rem --- Display grid with new detail.
	callpoint!.setStatus("REFGRID")

rem -- Build starting rowQtyMap!
	gosub build_rowQtyMap
	callpoint!.setDevObject("start_rowQtyMap",rowQtyMap!)
[[SFE_WOMATHDR.WO_NO.AVAL]]
rem --- If new record, initialize SFE_WOMATHDR and SFE_WOMATDET
	if callpoint!.getRecordMode()="A"
		rem --- When new record, initialize new SFE_WOMATHDR Materials Commitment Header record from SFE_WOMASTR Work Order Entry
		sfe_womastr_dev=fnget_dev("SFE_WOMASTR")
		dim sfe_womastr$:fnget_tpl$("SFE_WOMASTR")

		findrecord(sfe_womastr_dev,key=firm_id$+"  "+callpoint!.getUserInput())sfe_womastr$

		callpoint!.setColumnData("SFE_WOMATHDR.WO_TYPE",sfe_womastr.wo_type$,1)
		callpoint!.setColumnData("SFE_WOMATHDR.WO_CATEGORY",sfe_womastr.wo_category$,1)
		callpoint!.setColumnData("SFE_WOMATHDR.UNIT_MEASURE",sfe_womastr.unit_measure$,1)
		callpoint!.setColumnData("SFE_WOMATHDR.WAREHOUSE_ID",sfe_womastr.warehouse_id$,1)
		callpoint!.setColumnData("SFE_WOMATHDR.ITEM_ID",sfe_womastr.item_id$,1)
		callpoint!.setColumnData("SFE_WOMATHDR.ISSUED_DATE","",1)
		callpoint!.setColumnData("<<DISPLAY>>.DESCRIPTION_01",sfe_womastr.description_01$,1)
		callpoint!.setColumnData("<<DISPLAY>>.DESCRIPTION_02",sfe_womastr.description_02$,1)
		callpoint!.setColumnData("<<DISPLAY>>.WO_STATUS",sfe_womastr.wo_status$,1)

		rem -- Verify WO status
		gosub verify_wo_status
		if bad_wo then
			callpoint!.setStatus("ABORT")
			break
		endif
	endif
[[SFE_WOMATHDR.ARAR]]
rem -- Build starting rowQtyMap!
	gosub build_rowQtyMap
	callpoint!.setDevObject("start_rowQtyMap",rowQtyMap!)
[[SFE_WOMATHDR.AREC]]
rem -- Provide initial empty starting rowQtyMap!
	callpoint!.setDevObject("start_rowQtyMap", new java.util.HashMap())
[[SFE_WOMATHDR.BPFX]]
rem -- Verify WO status
	gosub verify_wo_status
	if bad_wo then
		callpoint!.setStatus("ABORT")
		break
	endif
[[SFE_WOMATHDR.BDEL]]
rem --- Initialize inventory item update
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

rem --- Delete inventory commitments. Must do this before sfe_womatisd records are removed.
	sfe_womatdtl_dev=fnget_dev("SFE_WOMATDTL")
	dim sfe_womatdtl$:fnget_tpl$("SFE_WOMATDTL")

	firm_loc_wo$=firm_id$+callpoint!.getColumnData("SFE_WOMATHDR.WO_LOCATION")+callpoint!.getColumnData("SFE_WOMATHDR.WO_NO")
	read(sfe_womatdtl_dev,key=firm_loc_wo$,dom=*next)
	while 1
		sfe_womatdtl_key$=key(sfe_womatdtl_dev,end=*break)
		if pos(firm_loc_wo$=sfe_womatdtl_key$)<>1 then break
		readrecord(sfe_womatdtl_dev)sfe_womatdtl$

		items$[1]=sfe_womatdtl.warehouse_id$
		items$[2]=sfe_womatdtl.item_id$
		refs[0]=max(0,sfe_womatdtl.qty_ordered-sfe_womatdtl.tot_qty_iss)
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
	wend

	rem --- Delete work order commit transactions
	remove(fnget_dev("SFE_WOCOMMIT"),key=firm_loc_wo$,dom=*next)

rem --- Delete inventory issues.
	sfe_womatish_dev=fnget_dev("SFE_WOMATISH")
	sfe_womatisd_dev=fnget_dev("SFE_WOMATISD")
	dim sfe_womatisd$:fnget_tpl$("SFE_WOMATISD")
	sfe_wolsissu_dev=fnget_dev("SFE_WOLSISSU")
	dim sfe_wolsissu$:fnget_tpl$("SFE_WOLSISSU")

	have_issues=0
	read(sfe_womatish_dev,key=firm_loc_wo$,dom=*next); have_issues=1
	if have_issues then
		rem --- NOTE: This code should never get executed because of check for existing materials issues in ADIS.
		remove(sfe_womatish_dev,key=firm_loc_wo$)
		read(sfe_womatisd_dev,key=firm_loc_wo$,dom=*next)
		while 1
			sfe_womatisd_key$=key(sfe_womatisd_dev,end=*break)
			if pos(firm_loc_wo$=sfe_womatisd_key$)<>1 then break
			readrecord(sfe_womatisd_dev)sfe_womatisd$
			remove(sfe_womatisd_dev,key=sfe_womatisd_key$)

			rem --- Delete lot/serial commitments if any
			if pos(callpoint!.getDevObject("lotser")="LS") then
				read(sfe_wolsissu_dev,key=firm_loc_wo$+sfe_womatisd.internal_seq_no$,dom=*next)
				while 1
					sfe_wolsissu_key$=key(sfe_wolsissu_dev,end=*break)
					if pos(firm_loc_wo$+sfe_womatisd.internal_seq_no$=sfe_wolsissu_key$)<>1 then break
					readrecord(sfe_wolsissu_dev)sfe_wolsissu$
					remove(sfe_wolsissu_dev,key=sfe_wolsissu_key$)

					rem --- Delete lot/serial commitments
					items$[1]=sfe_womatisd.warehouse_id$
					items$[2]=sfe_womatisd.item_id$
					items$[3]=sfe_wolsissu.lotser_no$
					refs[0]=sfe_wolsissu.qty_issued
					call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

					rem --- Add inventory commitments back since were deleted a second time with lot/serial commitments were deleted.
					items$[3]=" "
					call stbl("+DIR_PGM")+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				wend
			endif
		wend
	endif
[[SFE_WOMATHDR.ADIS]]
rem --- Init <<DISPLAY>> fields
	sfe_womastr_dev=fnget_dev("SFE_WOMASTR")
	dim sfe_womastr$:fnget_tpl$("SFE_WOMASTR")

	findrecord(sfe_womastr_dev,key=firm_id$+"  "+callpoint!.getColumnData("SFE_WOMATHDR.WO_NO"))sfe_womastr$

	callpoint!.setColumnData("<<DISPLAY>>.DESCRIPTION_01",sfe_womastr.description_01$,1)
	callpoint!.setColumnData("<<DISPLAY>>.DESCRIPTION_02",sfe_womastr.description_02$,1)
	callpoint!.setColumnData("<<DISPLAY>>.WO_STATUS",sfe_womastr.wo_status$,1)

rem --- Existing materials issues?
	wotrans=0
	sfe_wotrans_dev=fnget_dev("SFE_WOTRANS")
	sfe_wotrans_key$=firm_id$+callpoint!.getColumnData("SFE_WOMATHDR.WO_LOCATION")+callpoint!.getColumnData("SFE_WOMATHDR.WO_NO")
	find(sfe_wotrans_dev,key=sfe_wotrans_key$,dom=*next); wotrans=1

	if wotrans then
		rem --- Warn Materials Issues Entry is in process for this WO
		msg_id$="WO_ISSUES_IN_PROCESS"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem ... focus needs to move to the grid re Barista bug 6299
[[SFE_WOMATHDR.<CUSTOM>]]
#include std_missing_params.src

verify_wo_status: rem -- Verify WO status
	status$=callpoint!.getColumnData("<<DISPLAY>>.WO_STATUS")
	bad_wo=0

	if status$="C" then
		msg_id$="WO_CLOSED"
		gosub disp_message
		callpoint!.setStatus("NEWREC")
		bad_wo=1
	endif

	if !bad_wo and pos(status$="PQ") then
		msg_id$="WO_NOT_RELEASED"
		gosub disp_message
		callpoint!.setStatus("NEWREC")
		bad_wo=1
	endif
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

	firm_loc_wo$=firm_id$+callpoint!.getColumnData("SFE_WOMATHDR.WO_LOCATION")+callpoint!.getColumnData("SFE_WOMATHDR.WO_NO")
	read(sfe_womatdtl_dev,key=firm_loc_wo$,dom=*next)
	while 1
		sfe_womatdtl_key$=key(sfe_womatdtl_dev,end=*break)
		if pos(firm_loc_wo$=sfe_womatdtl_key$)<>1 then break
		readrecord(sfe_womatdtl_dev)sfe_womatdtl$
		rowQtyMap!.put(sfe_womatdtl.internal_seq_no$, sfe_womatdtl.qty_ordered)
	wend
	return
[[SFE_WOMATHDR.BSHO]]
rem --- Open Files
	num_files=12
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="IVS_PARAMS",open_opts$[2]="OTA"
	open_tables$[3]="SFE_WOMASTR",open_opts$[3]="OTA"
	open_tables$[4]="SFE_WOCOMMIT",open_opts$[4]="OTA"
	open_tables$[5]="SFE_WOTRANS",open_opts$[5]="OTA"
	open_tables$[6]="SFE_WOMATISH",open_opts$[6]="OTA"
	open_tables$[7]="SFE_WOMATISD ",open_opts$[7]="OTA"
	open_tables$[8]="SFE_WOMATL",open_opts$[8]="OTA"
	open_tables$[9]="SFC_WOTYPECD",open_opts$[9]="OTA"
	open_tables$[10]="IVM_ITEMMAST",open_opts$[10]="OTA"
	open_tables$[11]="IVM_ITEMWHSE",open_opts$[11]="OTA"
	open_tables$[12]="IVC_WHSECODE",open_opts$[12]="OTA"

	gosub open_tables

	sfs_params_dev=num(open_chans$[1]),sfs_params_tpl$=open_tpls$[1]
	ivs_params_dev=num(open_chans$[2]),ivs_params_tpl$=open_tpls$[2]
	sfe_womastr_dev=num(open_chans$[3]),sfe_womastr_tpl$=open_tpls$[3]

rem --- Get SF parameters
	dim sfs_params$:sfs_params_tpl$
	read record (sfs_params_dev,key=firm_id$+"SF00",dom=std_missing_params) sfs_params$

rem --- Get IV parameters
	dim ivs_params$:ivs_params_tpl$
	read record (ivs_params_dev,key=firm_id$+"IV00",dom=std_missing_params) ivs_params$
	lotser$=ivs_params.lotser_flag$
	callpoint!.setDevObject("lotser",lotser$)
	precision$=ivs_params.precision$
	callpoint!.setDevObject("precision",precision$)
	precision num(precision$)

rem --- Additional file opens
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	if pos(lotser$="LS") then
		open_tables$[1]="IVM_LSMASTER",open_opts$[1]="OTA"

		gosub open_tables

		ivm_lsmaster_dev=num(open_chans$[1]),ivm_lsmaster_tpl$=open_tpls$[1]
	endif

rem -- Provide initial empty starting rowQtyMap!
	callpoint!.setDevObject("start_rowQtyMap", new java.util.HashMap())
