[[SFE_WOMATL.ITEM_ID.AINV]]
rem --- To avoid endless loop, need second ABORT in AINV when ABORT executed in AVAL.
	if callpoint!.getDevObject("item_wh_failed") then
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[SFE_WOMATL.AGRN]]
rem --- Enable/disable explode field
	gosub enable_explode
[[SFE_WOMATL.AOPT-AUTO]]
rem --- Update displayed row nums for inserted and deleted rows, or
	if callpoint!.getDevObject("insertedRows")+callpoint!.getDevObject("deletedRows") then
		msg_id$="SF_UPDATE_ROW_NO"
		gosub disp_message

		callpoint!.setDevObject("insertedRows",0)
		callpoint!.setDevObject("deletedRows",0)
		callpoint!.setStatus("REFGRID")
		break
	endif

rem --- Keep track of lines to explode so they can be checked again when grid is refreshed
	dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")
	grid! = Form!.getControl(num(stbl("+GRID_CTL")))
	col_hdr$=callpoint!.getTableColumnAttribute("<<DISPLAY>>.EXPLODE_BILL","LABS")
	explode_bill_column=util.getGridColumnNumber(grid!, col_hdr$)
	col_hdr$=callpoint!.getTableColumnAttribute("SFE_WOMATL.INTERNAL_SEQ_NO","LABS")
	isn_column=util.getGridColumnNumber(grid!, col_hdr$)
	mark_to_explode$=""
	if grid!.getNumRows()>0 then
		for row=0 to grid!.getNumRows()-1
			if grid!.getCellState(row,explode_bill_column) then
				sfe_womatl$=GridVect!.get(row)
				mark_to_explode$=mark_to_explode$+sfe_womatl.internal_seq_no$+";"
			endif
		next row
	endif
	callpoint!.setDevObject("mark_to_explode",mark_to_explode$)

rem --- Auto create Reference Numbers
	callpoint!.setDevObject("MatlTable","SFE_WOMATL")
	callpoint!.setDevObject("GridVect",GridVect!)
	callpoint!.setDevObject("worefnum_status","")

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"SFE_WOREFNUM",
:		stbl("+USER_ID"),
:		"MNT",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]

rem --- Update grid with changes
	if callpoint!.getDevObject("worefnum_status")<>"CANCEL" then callpoint!.setStatus("REFGRID")
[[SFE_WOMATL.BUDE]]
rem --- verify wo_ref_num is unique
	refnumMap!=callpoint!.getDevObject("refnumMap")
	wo_ref_num$=callpoint!.getColumnData("SFE_WOMATL.WO_REF_NUM")
	if cvs(wo_ref_num$,2)<>"" then
		if refnumMap!.containsKey(wo_ref_num$) then
			msg_id$="SF_DUP_REF_NUM"
			dim msg_tokens$[1]
			msg_tokens$[1]=wo_ref_num$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		else
			refnumMap!.put(wo_ref_num$,"")
		endif
	endif

rem --- Maintain count of deleted rows
	deletedRows=callpoint!.getDevObject("deletedRows")
	deletedRows=deletedRows-1
	callpoint!.setDevObject("deletedRows",deletedRows)
[[SFE_WOMATL.WO_REF_NUM.BINP]]
rem --- Capture starting wo_ref_num
	prev_wo_ref_num$=callpoint!.getColumnData("SFE_WOMATL.WO_REF_NUM")
	callpoint!.setDevObject("prev_wo_ref_num",prev_wo_ref_num$)
[[SFE_WOMATL.BDEL]]
rem --- Update refnumMap!
	refnumMap!=callpoint!.getDevObject("refnumMap")
	wo_ref_num$=callpoint!.getColumnData("SFE_WOMATL.WO_REF_NUM")
	if cvs(wo_ref_num$,2)<>"" then
		refnumMap!.remove(wo_ref_num$)
	endif

rem --- Maintain count of deleted rows
	deletedRows=callpoint!.getDevObject("deletedRows")
	deletedRows=deletedRows+1
	callpoint!.setDevObject("deletedRows",deletedRows)
[[SFE_WOMATL.WO_REF_NUM.AVAL]]
rem --- Verify wo_ref_num is unique
	wo_ref_num$=callpoint!.getUserInput()
	prev_wo_ref_num$=callpoint!.getDevObject("prev_wo_ref_num")
	refnumMap!=callpoint!.getDevObject("refnumMap")
	if wo_ref_num$<>prev_wo_ref_num$ then
		if refnumMap!.containsKey(wo_ref_num$) then
			msg_id$="SF_DUP_REF_NUM"
			dim msg_tokens$[1]
			msg_tokens$[1]=wo_ref_num$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		else
			if cvs(wo_ref_num$,2)<>"" then refnumMap!.put(wo_ref_num$,"")
			if cvs(prev_wo_ref_num$,2)<>"" then refnumMap!.remove(prev_wo_ref_num$)
		endif
	endif
[[<<DISPLAY>>.EXPLODE_BILL.AVAL]]
rem --- Enable/disable explode field
	callpoint!.setColumnData("<<DISPLAY>>.EXPLODE_BILL",callpoint!.getUserInput())
	gosub enable_explode
[[SFE_WOMATL.ITEM_ID.BINP]]
rem --- Capture current item_id so will know later if it was changed
	callpoint!.setDevObject("prev_item_id",callpoint!.getColumnData("SFE_WOMATL.ITEM_ID"))
	callpoint!.setDevObject("item_wh_failed",0)
[[SFE_WOMATL.LINE_TYPE.BINP]]
rem --- Capture current line_type so will know later if it was changed
	callpoint!.setDevObject("prev_line_type",callpoint!.getColumnData("SFE_WOMATL.LINE_TYPE"))
[[SFE_WOMATL.LINE_TYPE.AVAL]]
rem --- Skip if line_type didn't changed
	line_type$=callpoint!.getUserInput()
	if line_type$=callpoint!.getDevObject("prev_line_type") then break

rem --- Enable/disable explode field
	callpoint!.setColumnData("SFE_WOMATL.LINE_TYPE",line_type$)
	gosub enable_explode
[[SFE_WOMATL.AGDR]]
rem --- Enable/disable explode field
	gosub enable_explode

rem --- Set ROW_NUM (material_seq may not be numbered sequentially from one when DataPorted)
	dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")
	wk$=fattr(sfe_womatl$,"material_seq")
	new_row_num=1+callpoint!.getValidationRow()
	callpoint!.setColumnData("<<DISPLAY>>.ROW_NUM",pad(str(new_row_num),dec(wk$(10,2)),"R","0"),1)

rem --- Track wo_ref_num in Map to insure they are unique
	refnumMap!=callpoint!.getDevObject("refnumMap")
	wo_ref_num$=callpoint!.getColumnData("SFE_WOMATL.WO_REF_NUM")
	if cvs(wo_ref_num$,2)<>"" then
		refnumMap!.put(wo_ref_num$,"")
	endif
[[SFE_WOMATL.BWRI]]
rem --- Add/remove to string of bills being exploded
	checked$=""
	gosub bills_to_explode
[[SFE_WOMATL.BEND]]
rem --- if materials lines were entered manually, and any of them are bills, 
rem --- prompt user to explode them; if yes, explode, then re-launch form so user can view/edit

	if callpoint!.getDevObject("explode_bills")<>""

		msg_id$="SF_EXPLODE"
		msg_opt$=""
		gosub disp_message
		if msg_opt$="Y"

			rem --- Build HashMap of deleted items so they don't get exploded
			deleteItemMap!=new java.util.HashMap()
			dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")
			grid! = Form!.getControl(num(stbl("+GRID_CTL")))
			col_hdr$=callpoint!.getTableColumnAttribute("<<DISPLAY>>.EXPLODE_BILL","LABS")
			explode_bill_column=util.getGridColumnNumber(grid!, col_hdr$)
			col_hdr$=callpoint!.getTableColumnAttribute("SFE_WOMATL.INTERNAL_SEQ_NO","LABS")
			isn_column=util.getGridColumnNumber(grid!, col_hdr$)
			if grid!.getNumRows()>0 then
				for row=0 to grid!.getNumRows()-1
					if callpoint!.getGridRowDeleteStatus(row)<>"Y" then continue
					if grid!.getCellState(row,explode_bill_column) then
						sfe_womatl$=GridVect!.get(row)
						deleteItemMap!.put(sfe_womatl.internal_seq_no$,"Y")
					endif
				next row
			endif

			bmm01_dev=fnget_dev("BMM_BILLMAST")
			sfe01_dev=fnget_dev("SFE_WOMASTR")
			sfe22_dev=fnget_dev("SFE_WOMATL")

			call stbl("+DIR_SYP")+"bac_key_template.bbj","SFE_WOMATL","PRIMARY",sfe22_key_tpl$,rd_table_chans$[all],status$
			call stbl("+DIR_SYP")+"bac_key_template.bbj","SFE_WOOPRTN","PRIMARY",sfe02_key_tpl$,rd_table_chans$[all],status$
			call stbl("+DIR_SYP")+"bac_key_template.bbj","SFE_WOSUBCNT","PRIMARY",sfe32_key_tpl$,rd_table_chans$[all],status$

			wo_no$=callpoint!.getDevObject("wo_no")
			wo_loc$=callpoint!.getDevObject("wo_loc")
			explode_bills$=callpoint!.getDevObject("explode_bills")
			explode_bill$=""

			while explode_bills$<>""

				tmp=pos("^^"=explode_bills$+"^^")
				explode_bill$=explode_bills$(1,tmp-1)
				explode_bills$=explode_bills$(tmp+2)	
				mat_isn$=explode_bill$(1,pos("^"=explode_bill$)-1)
				explode_bill$=explode_bill$(pos("^"=explode_bill$)+1)	

				rem --- Don't explode items that are being deleted
				if deleteItemMap!.containsKey(mat_isn$) then continue

				dim bmm_billmast$:fnget_tpl$("BMM_BILLMAST")
				read record (bmm01_dev,key=firm_id$+explode_bill$,dom=*continue)bmm_billmast$
				new_bill$=bmm_billmast.bill_no$
					
				dim sfe_womastr$:fnget_tpl$("SFE_WOMASTR")		
				read record (sfe01_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)sfe_womastr$
			
				all_bills$=""
				x=0
				t=1
				dim allbills[10,1]
				allbills[x,0]=1
				allbills[x,1]=1

				rem --- Get units for item being exploded
				dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")
				read record (sfe22_dev,key=firm_id$+wo_loc$+wo_no$+mat_isn$,knum="AO_MAT_SEQ",dom=*next)sfe_womatl$
				t=sfe_womatl.units
				allbills[x,0]=t

				gosub explode_bills

				rem --- Signal sfe_womastr to re-launch sfe_womatl form after a bill is exploded
				callpoint!.setDevObject("explode_bills","Y")
			wend
		else
			rem --- Don't exit, they want to edit bills selected for explosion
			callpoint!.setStatus("ABORT")
			break
		endif
	endif
[[SFE_WOMATL.AGRE]]
rem --- check to see if item is marked special order in IV warehouse rec; if so, mark PO Status flag
	
	if cvs(callpoint!.getColumnData("SFE_WOMATL.PO_STATUS"),3)=""
		if callpoint!.getDevObject("special_order")="Y" then callpoint!.setColumnData("SFE_WOMATL.PO_STATUS","S")
	endif
[[SFE_WOMATL.AREC]]
rem --- Initializations
	callpoint!.setDevObject("special_order","N")

rem --- Maintain count of inserted rows (don't count if last row)
	if GridVect!.size()>1+callpoint!.getValidationRow() then
		insertedRows=callpoint!.getDevObject("insertedRows")
		insertedRows=insertedRows+1
		callpoint!.setDevObject("insertedRows",insertedRows)
	endif
[[SFE_WOMATL.SCRAP_FACTOR.AVAL]]
rem --- Calc Totals

	qty_required=num(callpoint!.getColumnData("SFE_WOMATL.QTY_REQUIRED"))
	alt_factor=num(callpoint!.getColumnData("SFE_WOMATL.ALT_FACTOR"))
	divisor=num(callpoint!.getColumnData("SFE_WOMATL.DIVISOR"))
	scrap_factor=num(callpoint!.getUserInput())
	gosub calculate_totals
[[SFE_WOMATL.ALT_FACTOR.AVAL]]
rem --- Calc Totals

	qty_required=num(callpoint!.getColumnData("SFE_WOMATL.QTY_REQUIRED"))
	alt_factor=num(callpoint!.getUserInput())
	divisor=num(callpoint!.getColumnData("SFE_WOMATL.DIVISOR"))
	scrap_factor=num(callpoint!.getColumnData("SFE_WOMATL.SCRAP_FACTOR"))
	gosub calculate_totals
[[SFE_WOMATL.QTY_REQUIRED.AVAL]]
rem --- Verify minimum quantity > 0

	if num(callpoint!.getUserInput())<=0
		msg_id$="IV_QTY_GT_ZERO"
		gosub disp_message
		callpoint!.setColumnData("SFE_WOMATL.QTY_REQUIRED",callpoint!.getColumnData("SFE_WOMATL.QTY_REQUIRED"),1)
		callpoint!.setStatus("ABORT")
	endif

rem --- Calc Totals

	qty_required=num(callpoint!.getUserInput())
	alt_factor=num(callpoint!.getColumnData("SFE_WOMATL.ALT_FACTOR"))
	divisor=num(callpoint!.getColumnData("SFE_WOMATL.DIVISOR"))
	scrap_factor=num(callpoint!.getColumnData("SFE_WOMATL.SCRAP_FACTOR"))
	gosub calculate_totals
[[SFE_WOMATL.DIVISOR.AVAL]]
rem --- Calc Totals

	qty_required=num(callpoint!.getColumnData("SFE_WOMATL.QTY_REQUIRED"))
	alt_factor=num(callpoint!.getColumnData("SFE_WOMATL.ALT_FACTOR"))
	divisor=num(callpoint!.getUserInput())
	scrap_factor=num(callpoint!.getColumnData("SFE_WOMATL.SCRAP_FACTOR"))
	gosub calculate_totals
[[SFE_WOMATL.<CUSTOM>]]
rem =========================================================

init_wo_sfe22_recs: rem ---Initialize vector with current sfe-22 (sfe_womatl) records for given work order

rem --- incoming data:
rem --- wo_no$
rem --- wo_loc$
rem --- sfe_womatl$

rem =========================================================

	wo_sfe22_recs!=BBjAPI().makeVector()
	dim sfe_womatl$:fattr(sfe_womatl$)
	read(sfe22_dev,key=firm_id$+wo_loc$+wo_no$,knum="PRIMARY",dom=*next)
	while 1
		sfe22_key$=key(sfe22_dev,end=*break)
		if pos(firm_id$+wo_loc$+wo_no$=sfe22_key$)<>1 then break
		readrecord(sfe22_dev)sfe_womatl$
		wo_sfe22_recs!.addItem(sfe_womatl$)
	wend
	return

rem ==========================================================================
enable_explode: rem --- Enable/disable explode field (and initialize)
rem ==========================================================================
	rem --- Enable explode when item is a Bill on non-stock planned or quote WO, else disable.
	row=callpoint!.getValidationRow()
	callpoint!.setColumnEnabled(row,"<<DISPLAY>>.EXPLODE_BILL",0)
	if callpoint!.getDevObject("bm")="Y" and callpoint!.getColumnData("SFE_WOMATL.LINE_TYPE")="S"
		bmm01_dev=fnget_dev("BMM_BILLMAST")
		dim bmm_billmast$:fnget_tpl$("BMM_BILLMAST")
		item_id$=callpoint!.getColumnData("SFE_WOMATL.ITEM_ID")

		bmm01_found=0
		read record (bmm01_dev,key=firm_id$+item_id$,dom=*next)bmm_billmast$; bmm01_found=1
		if bmm01_found then
			if bmm_billmast.phantom_bill$="Y" then
				rem --- Always explode phantom bills
				rem --- Disable so explode can't be cancelled
				callpoint!.setColumnData("<<DISPLAY>>.EXPLODE_BILL","Y",1)
				rem --- Add/remove to string of bills being exploded
				checked$="Y"
				gosub bills_to_explode
			else
				if callpoint!.getDevObject("wo_category")="N" and pos(callpoint!.getDevObject("wo_status")="PQ") then
					rem --- Enable so explode can be changed for non-stock planned or quote work orders
					callpoint!.setColumnEnabled(row,"<<DISPLAY>>.EXPLODE_BILL",1)
					mark_pos=pos(callpoint!.getColumnData("SFE_WOMATL.INTERNAL_SEQ_NO")=callpoint!.getDevObject("mark_to_explode"))
					if callpoint!.getDevObject("new_item") or mark_pos then
						rem --- For new bill, check explode
						callpoint!.setColumnData("<<DISPLAY>>.EXPLODE_BILL","Y",1)
						rem --- Add/remove to string of bills being exploded
						checked$="Y"
						gosub bills_to_explode
						if mark_pos then
							rem --- Remove from mark_to_explode
							mark_len=len(callpoint!.getColumnData("SFE_WOMATL.INTERNAL_SEQ_NO"))
							mark_to_explode$=callpoint!.getDevObject("mark_to_explode")
							mark_to_explode$=mark_to_explode$(1,mark_pos-1)+mark_to_explode$(mark_pos+mark_len+1)
							callpoint!.setDevObject("mark_to_explode",mark_to_explode$)
						endif
					endif
				else
					callpoint!.setColumnData("<<DISPLAY>>.EXPLODE_BILL","N",1)
				endif
			endif
		else
			callpoint!.setColumnData("<<DISPLAY>>.EXPLODE_BILL","N",1)
		endif
	else
		callpoint!.setColumnData("<<DISPLAY>>.EXPLODE_BILL","N",1)
	endif
	return

rem ========================================================
calculate_totals:
rem ========================================================

	wo_est_yield=num(callpoint!.getDevObject("wo_est_yield"))	
	prod_qty=num(callpoint!.getDevObject("prod_qty"))

	unit_cost=num(callpoint!.getColumnData("SFE_WOMATL.IV_UNIT_COST"))

	units=SfUtils.matQtyWorkOrd(qty_required,alt_factor,divisor,scrap_factor,wo_est_yield)

	callpoint!.setColumnData("SFE_WOMATL.UNITS",str(units),1)
	callpoint!.setColumnData("SFE_WOMATL.UNIT_COST",str(units*unit_cost),1)
	callpoint!.setColumnData("SFE_WOMATL.TOTAL_UNITS",str(prod_qty*units),1)
	callpoint!.setColumnData("SFE_WOMATL.TOTAL_COST",str(prod_qty*units*unit_cost),1)
	precision 2
	callpoint!.setColumnData("SFE_WOMATL.TOTAL_COST",str(num(callpoint!.getColumnData("SFE_WOMATL.TOTAL_COST"))*1)); rem jpb callpoint!.setColumnData("SFE_WOMATL.TOTAL_COST" is w(3)
	precision num(callpoint!.getDevObject("iv_precision"))

	return

rem =========================================================
explode_bills:

rem --- incoming data:
rem --- wo_no$
rem --- wo_loc$
rem --- new_bill$
rem --- mat_isn$
rem --- sfe_womastr$

rem =========================================================

	bmm01_dev=fnget_dev("BMM_BILLMAST")
	bmm02_dev=fnget_dev("BMM_BILLMAT")
	bmm03_dev=fnget_dev("BMM_BILLOPER")
	bmm05_dev=fnget_dev("BMM_BILLSUB")
	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	ivm02_dev=fnget_dev("IVM_ITEMWHSE")
	sfe02_dev=fnget_dev("SFE_WOOPRTN")
	sfe22_dev=fnget_dev("SFE_WOMATL")
	sfe32_dev=fnget_dev("SFE_WOSUBCNT")
	op_code_dev=callpoint!.getDevObject("opcode_chan")

	dim bmm_billmast$:fnget_tpl$("BMM_BILLMAST")
	dim bmm_billmat$:fnget_tpl$("BMM_BILLMAT")
	dim bmm_billoper$:fnget_tpl$("BMM_BILLOPER")
	dim bmm_billsub$:fnget_tpl$("BMM_BILLSUB")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
	dim ivm_itemwhse$:fnget_tpl$("IVM_ITEMWHSE")
	dim sfe_wooprtn$:fnget_tpl$("SFE_WOOPRTN")
	dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")
	dim sfe_wosubcnt$:fnget_tpl$("SFE_WOSUBCNT")

	call stbl("+DIR_SYP")+"bac_key_template.bbj","SFE_WOMATL","PRIMARY",sfe22_key_tpl$,rd_table_chans$[all],status$
	dim sfe22_prev_key$:sfe22_key_tpl$

	all_bills$=new_bill$
	curr_bill$=new_bill$
	no_more_seq=0
	subs$=""
	mats$=""
	mats_offset=0
	dim yld[99]
	yld[0]=num(sfe_womastr.est_yield$)
	yld=yld[0]

	wfattr$=fattr(sfe_womatl$,"INTERNAL_SEQ_NO")
	mat_isn_len=dec(wfattr$(10,2))

	wfattr$=fattr(sfe_womatl$,"MATERIAL_SEQ")
	material_seq_len=dec(wfattr$(10,2))
	mat_seq_mask$=fill(material_seq_len,"0")

	wfattr$=fattr(sfe_wooprtn$,"OP_SEQ")
	op_seq_len=dec(wfattr$(10,2))
	op_seq_mask$=fill(op_seq_len,"0")

	wfattr$=fattr(sfe_wooprtn$,"INTERNAL_SEQ_NO")
	op_isn_len=dec(wfattr$(10,2))

	wfattr$=fattr(sfe_wosubcnt$,"SUBCONT_SEQ")
	sub_seq_len=dec(wfattr$(10,2))
	sub_seq_mask$=fill(sub_seq_len,"0")

	wfattr$=fattr(bmm_billmat$,"ITEM_ID")
	item_len=dec(wfattr$(10,2))

	rem --- Get vector of wo's current sfe_womatl records
	gosub init_wo_sfe22_recs
	rem --- Initialize vector index for inserting next sfe_womatl record
	if num(mat_isn$)>0 then
		dim sfe_womatl$:fattr(sfe_womatl$)
		sfe22_key$=firm_id$+wo_loc$+wo_no$+mat_isn$
		read record (sfe22_dev,key=sfe22_key$,knum="AO_MAT_SEQ",dom=*next)sfe_womatl$
		next_mat_seq=max(1,num(sfe_womatl.material_seq$))
	else
		next_mat_seq=1
		endif
	rem --- Remove from vector the bill being exploded
	if num(mat_isn$)>0 and wo_sfe22_recs!.size()>0 then wo_sfe22_recs!.removeItem(next_mat_seq-1)

mats_next_bill:
	read (bmm02_dev,key=firm_id$+curr_bill$,dom=*next)

mats_loop:
	while 1

		dim sfe_womatl$:fattr(sfe_womatl$)
		sfe_womatl.firm_id$=firm_id$
		sfe_womatl.wo_location$=wo_loc$
		sfe_womatl.wo_no$=wo_no$

		bmm02_key$=key(bmm02_dev,end=*break)
		read record (bmm02_dev)bmm_billmat$
		if pos(firm_id$+curr_bill$=bmm02_key$)<>1 then break

		w_cost=0
		dim ivm_itemmast$:fattr(ivm_itemmast$)
		dim ivm_itemwhse$:fattr(ivm_itemwhse$)
		read record (ivm01_dev,key=firm_id$+bmm_billmat.item_id$,dom=*next)ivm_itemmast$
		w_cost=num(ivm_itemmast.maximum_qty$)

		read record(ivm02_dev,key=firm_id$+sfe_womastr.warehouse_id$+bmm_billmat.item_id$,dom=*next)ivm_itemwhse$
		w_cost=num(ivm_itemwhse.unit_cost$)		

		read record (bmm01_dev,key=firm_id$+new_bill$,dom=*next)bmm_billmast$; rem - don't know why this is needed
	
		eff_date$=bmm_billmat.effect_date$
		obs_date$=bmm_billmat.obsolt_date$
		gosub verify_dates
		if ok$="N" then continue

		if bmm_billmat.line_type$="M"
			sfe_womatl.line_type$="M"
			sfe_womatl.ext_comments$=bmm_billmat.ext_comments$
			phantom_bill$="N"
		else
			sfe_womatl.unit_measure$=ivm_itemmast.unit_of_sale$
			sfe_womatl.require_date$=sfe_womastr.eststt_date$
			sfe_womatl.warehouse_id$=sfe_womastr.warehouse_id$
			sfe_womatl.item_id$=bmm_billmat.item_id$
			sfe_womatl.line_type$="S"

			allbills[x,1]=num(bmm_billmat.material_seq$)
			bmm_billmat.qty_required=iff(bmm_billmat.qty_required=0,1,bmm_billmat.qty_required)
			bmm_billmat.alt_factor=iff(bmm_billmat.alt_factor=0,1,bmm_billmat.alt_factor)
			bmm_billmat.divisor=iff(bmm_billmat.divisor=0,1,bmm_billmat.divisor)
			
			sfe_womatl.divisor=bmm_billmat.divisor
			sfe_womatl.qty_required=bmm_billmat.qty_required*t
			sfe_womatl.alt_factor=bmm_billmat.alt_factor
			sfe_womatl.iv_unit_cost=w_cost
			sfe_womatl.scrap_factor=bmm_billmat.scrap_factor

			yld=iff(yld[x]=0,100,yld[x])
			material_units=SfUtils.matQty(bmm_billmat.qty_required,bmm_billmat.alt_factor,bmm_billmat.divisor,yld,bmm_billmat.scrap_factor)
			sfe_womatl.units=material_units*t
			sfe_womatl.unit_cost=material_units*w_cost*t
			sfe_womatl.total_units=	material_units*t*sfe_womastr.sch_prod_qty
			sfe_womatl.total_cost=material_units*w_cost*t*sfe_womastr.sch_prod_qty
		
			precision 2
			sfe_womatl.total_cost=sfe_womatl.total_cost*1
			precision num(callpoint!.getDevObject("iv_precision"))

			rem --- is this material line a phantom bill? (6200)
			dim bmm_billmast$:fattr(bmm_billmast$)
			dim sfe22_prev_key$:sfe22_key_tpl$
			read record(bmm01_dev,key=firm_id$+bmm_billmat.item_id$,dom=*next)bmm_billmast$
			phantom_bill$=bmm_billmast.phantom_bill$
		endif

		if phantom_bill$<>"Y"
			rem --- now write materials rec
			rem --- not phantom, or not a bill, or just a message line (6400)
			sfe_womatl.material_seq$=str(next_mat_seq:mat_seq_mask$)
			if pos("9"<>sfe_womatl.material_seq$)=0 
				msg_id$="SF_NO_MORE_SEQ"
				gosub disp_message
				explode_bills$=""
				exitto end_explode_bills
			endif
			internal_seq_no$=""
			call stbl("+DIR_SYP")+"bas_sequences.bbj","INTERNAL_SEQ_NO",internal_seq_no$,table_chans$[all],"QUIET"
			sfe_womatl.internal_seq_no$=internal_seq_no$

			if ivm_itemwhse.special_ord$="Y" then sfe_womatl.po_status$="S"

			rem --- Insert exploded bill records into vector
			sfe_womatl$=field(sfe_womatl$)
			wo_sfe22_recs!.insertItem(next_mat_seq-1,sfe_womatl$)
			next_mat_seq=next_mat_seq+1

			rem --- Keep track if this is a bill so can mark to explode on initial redisplay
			if sfe_womatl.item_id$=bmm_billmast.bill_no$ then
				mark_to_explode$=mark_to_explode$+sfe_womatl.internal_seq_no$+";"
			endif

			rem --- Link material requirement to operation
			if cvs(bmm_billmat.op_int_seq_ref$,3)<>""			
				if mats$="" mats_offset=len(bmm_billmat.bill_no$+bmm_billmat.op_int_seq_ref$)
				mats$=mats$+bmm_billmat.bill_no$+bmm_billmat.op_int_seq_ref$+sfe_womatl.internal_seq_no$
			endif

		else
			rem --- down one level; then exitto mats_next_bill
			all_bills$=all_bills$+bmm_billmat.item_id$
			curr_bill$=bmm_billmat.item_id$
			bmm$=bmm_billmat.item_id$
			x=len(all_bills$)/item_len-1
			allbills[x,0]=sfe_womatl.units
			allbills[x,1]=num(bmm_billmat.material_seq$)
			t=allbills[x,0]
			yld[x]=bmm_billmast.est_yield
			dim bmm_billmast$:fattr(bmm_billmast$)
			found=0

			extractrecord (bmm01_dev,key=firm_id$+bmm$,dom=*next)bmm_billmast$;found=1
			if found and sfe_womastr.opened_date$>=bmm_billmast.lstact_date$
				bmm_billmast.lstact_date$=sfe_womastr.opened_date$
				bmm_billmast.source_code$="W"
				bmm_billmast$=field(bmm_billmast$)
				writerecord(bmm01_dev)bmm_billmast$
			endif
			exitto mats_next_bill
		endif

	wend

	rem --- Overwrite wo's existing sfe_womatl records with records in vector
	mat_seq=1
	while mat_seq<=wo_sfe22_recs!.size()
		sfe_womatl$=wo_sfe22_recs!.getItem(mat_seq-1)
		sfe_womatl.material_seq$=str(mat_seq:mat_seq_mask$)
		if pos("9"<>sfe_womatl.material_seq$)=0 
			msg_id$="SF_NO_MORE_SEQ"
			gosub disp_message
			explode_bills$=""
			exitto end_explode_bills
		endif
		sfe22_key$=sfe_womatl.firm_id$+sfe_womatl.wo_location$+sfe_womatl.wo_no$+sfe_womatl.material_seq$
		extractrecord(sfe22_dev,key=sfe22_key$,knum="PRIMARY",dom=*next)x$; rem --- Advisory locking
		sfe_womatl$=field(sfe_womatl$)
		writerecord(sfe22_dev)sfe_womatl$
		mat_seq=mat_seq+1
	wend

back_up_levels: rem --- this is the 6900 part - move on to ops and subs for phantoms, or do final ops/subs

	if all_bills$<>new_bill$
		gosub do_operations
		if no_more_seq then
			explode_bills$=""
			goto end_explode_bills
		endif
		if callpoint!.getDevObject("po")="Y" then
			gosub do_subcontracts
			if no_more_seq then
				explode_bills$=""
				goto end_explode_bills
			endif
		endif
		allbills[x,0]=0
		allbills[x,1]=0
next_bill_level:
		all_bills$=all_bills$(1,x*item_len)
		x=x-1
		curr_bill$=all_bills$(x*item_len+1,item_len)
		t=allbills[x,0]
		rem --- now re-position back to the bmm_billmat line we were on before doing phantom explode
		read (bmm02_dev,key=firm_id$+curr_bill$+str(allbills[x,1]:mat_seq_mask$),dom=next_bill_level)
		goto mats_loop
	else
		curr_bill$=all_bills$
		gosub do_operations
		if no_more_seq then
			explode_bills$=""
			goto end_explode_bills
		endif
		if callpoint!.getDevObject("po")="Y" then
			gosub do_subcontracts
			if no_more_seq then
				explode_bills$=""
				goto end_explode_bills
			endif
		endif
		rem all done... should now be ready to display what's just been added to mats grid
	endif

end_explode_bills:
	callpoint!.setDevObject("mark_to_explode",mark_to_explode$)
	return

rem =========================================================
do_operations:

	dim sfe_wooprtn$:fattr(sfe_wooprtn$)
	wk$=fattr(sfe_wooprtn$,"WO_OP_REF")
	opRef_mask$=fill(dec(wk$(10,2)),"0")
	if opRefMap!=null() then
		opRefMap!=new java.util.HashMap()
		read (sfe02_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)
		while 1
			sfe02_key$=key(sfe02_dev,end=*break)
			if pos(firm_id$+wo_loc$+wo_no$=sfe02_key$)<>1 then break
			readrecord(sfe02_dev)sfe_wooprtn$
			opRefMap!.put(sfe_wooprtn.wo_op_ref$,"")
		wend
	endif

	yld=num(sfe_womastr.est_yield$)
	dim bmm_billoper$:fattr(bmm_billoper$)
	dim sfe02_prev_key$:sfe02_key_tpl$

	read (bmm03_dev,key=firm_id$+curr_bill$,dom=*next)

	while 1
		bmm03_key$=key(bmm03_dev,end=*break)
		read record (bmm03_dev)bmm_billoper$
		if pos(firm_id$+curr_bill$=bmm03_key$)<>1 then break

		read record (bmm01_dev,key=firm_id$+new_bill$,dom=*next)bmm_billmast$;rem - don't know why this is needed

		eff_date$=bmm_billoper.effect_date$
		obs_date$=bmm_billoper.obsolt_date$
		gosub verify_dates
		if ok$="N" then continue

		dim op_code$:callpoint!.getDevObject("opcode_tpl")
		dim sfe_wooprtn$:fattr(sfe_wooprtn$)
		sfe_wooprtn.firm_id$=firm_id$
		sfe_wooprtn.wo_location$=wo_loc$
		sfe_wooprtn.wo_no$=wo_no$
		sfe_wooprtn.op_code$=bmm_billoper.op_code$
		sfe_wooprtn.require_date$=sfe_womastr.opened_date$
		sfe_wooprtn.line_type$=bmm_billoper.line_type$

		if sfe_wooprtn.line_type$="M"
			sfe_wooprtn.ext_comments$=bmm_billoper.ext_comments$
		else
			read record (op_code_dev,key=firm_id$+bmm_billoper.op_code$,dom=*next)op_code$
			sfe_wooprtn.code_desc$=op_code.code_desc$
			if bmm_billoper.pcs_per_hour=0
				bmm_billoper.pcs_per_hour=iff(op_code.pcs_per_hour=0,1,op_code.pcs_per_hour)
			endif
			sfe_wooprtn.hrs_per_pce=bmm_billoper.hrs_per_pce*t/yld*100
			sfe_wooprtn.pcs_per_hour=bmm_billoper.pcs_per_hour
			sfe_wooprtn.direct_rate=op_code.direct_rate
			sfe_wooprtn.ovhd_rate=sfe_wooprtn.direct_rate*op_code.ovhd_factor
			sfe_wooprtn.setup_time=bmm_billoper.setup_time
			sfe_wooprtn.move_time=bmm_billoper.move_time

			sfe_wooprtn.runtime_hrs=SfUtils.opUnits(bmm_billoper.hrs_per_pce,bmm_billoper.pcs_per_hour,yld)*t
			sfe_wooprtn.unit_cost=SfUtils.opUnitsDollars(bmm_billoper.hrs_per_pce,sfe_wooprtn.direct_rate,sfe_wooprtn.ovhd_rate,bmm_billoper.pcs_per_hour,yld)*t
			sfe_wooprtn.total_time=SfUtils.opTime(t,sfe_womastr.sch_prod_qty,bmm_billoper.hrs_per_pce,bmm_billoper.pcs_per_hour,yld,bmm_billoper.setup_time)
			
			tot_units=SfUtils.opTime(t,sfe_womastr.sch_prod_qty,bmm_billoper.hrs_per_pce,bmm_billoper.pcs_per_hour,yld,bmm_billoper.setup_time)
			tot_cost=sfe_wooprtn.direct_rate+sfe_wooprtn.ovhd_rate
			sfe_wooprtn.tot_std_cost=tot_units*tot_cost
			precision 2
			sfe_wooprtn.tot_std_cost=sfe_wooprtn.tot_std_cost*1
			precision num(callpoint!.getDevObject("iv_precision"))
		endif

		rem --- now write ops rec

		read (sfe02_dev,key=firm_id$+wo_loc$+wo_no$+$FF$,dom=*next)
		sfe_wooprtn.op_seq$=fill(op_seq_len,"0")
		occ=1
	
		dim sfe02_prev_key$:fattr(sfe02_prev_key$)
		sfe02_prev_key$=keyp(sfe02_dev,end=no_prev_ops_key)
		if pos(firm_id$+wo_loc$+wo_no$=sfe02_prev_key$)=1 then sfe_wooprtn.op_seq$=sfe02_prev_key.op_seq$
		if pos("9"<>sfe02_prev_key.op_seq$)=0 
			msg_id$="SF_NO_MORE_SEQ"
			gosub disp_message
			no_more_seq=1
			exitto end_do_operations
		endif

no_prev_ops_key:
		sfe_wooprtn.op_seq$=str(num(sfe_wooprtn.op_seq$)+1:op_seq_mask$)

		sfe_wooprtn.wo_op_ref$=""
		nextOpRef=num(sfe_wooprtn.op_seq$)
		while cvs(sfe_wooprtn.wo_op_ref$,2)=""
			rem --- With 6 digit wo_op_ref, would need 1,000,000 operations to create an endless loop
			if !opRefMap!.containsKey(str(nextOpRef,opRef_mask$)) then
				sfe_wooprtn.wo_op_ref$=str(nextOpRef,opRef_mask$)
				opRefMap!.put(sfe_wooprtn.wo_op_ref$,"")
			endif
			nextOpRef=nextOpRef+1
		wend

		internal_seq_no$=""
		call stbl("+DIR_SYP")+"bas_sequences.bbj","INTERNAL_SEQ_NO",internal_seq_no$,table_chans$[all],"QUIET"
		sfe_wooprtn.internal_seq_no$=internal_seq_no$

		sfe_wooprtn$=field(sfe_wooprtn$)
		writerecord (sfe02_dev)sfe_wooprtn$

		if subs$="" subs_offset=len(curr_bill$+bmm_billoper.internal_seq_no$)
		subs$=subs$+curr_bill$+bmm_billoper.internal_seq_no$+sfe_wooprtn.internal_seq_no$

		rem --- Link material requirement to operation
		while 1
			mats_pos=pos(bmm_billoper.bill_no$+bmm_billoper.internal_seq_no$=mats$,mats_offset+mat_isn_len,occ)
			if mats_pos=0 then break
			dim sfe_womatl2$:fattr(sfe_womatl$)
			sfe22_key$=firm_id$+wo_loc$+wo_no$+mats$(mats_pos+mats_offset,mat_isn_len)
			extract record (sfe22_dev,key=sfe22_key$,knum="AO_MAT_SEQ",dom=*break)sfe_womatl2$
			sfe_womatl2.oper_seq_ref$=sfe_wooprtn.internal_seq_no$
			sfe_womatl2$=field(sfe_womatl2$)
			write record (sfe22_dev)sfe_womatl2$
			occ=occ+1
		wend
	
	wend

end_do_operations:
	return

rem =========================================================
do_subcontracts:

	dim bmm_billsub$:fattr(bmm_billsub$)
	dim sfe_wosubcnt$:fattr(sfe_wosubcnt$)
	dim sfe32_prev_key$:sfe32_key_tpl$

	sfe_wosubcnt.firm_id$=firm_id$
	sfe_wosubcnt.wo_location$=wo_loc$
	sfe_wosubcnt.wo_no$=wo_no$

	read (bmm05_dev,key=firm_id$+curr_bill$,dom=*next)

	while 1
		bmm05_key$=key(bmm05_dev,end=*break)
		read record (bmm05_dev)bmm_billsub$
		if pos(firm_id$+curr_bill$=bmm05_key$)<>1 then break

		eff_date$=bmm_billsub.effect_date$
		obs_date$=bmm_billsub.obsolt_date$
		gosub verify_dates
		if ok$="N" then continue

		sfe_wosubcnt.require_date$=sfe_womastr.opened_date$
		sfe_wosubcnt.vendor_id$=bmm_billsub.vendor_id$
		sfe_wosubcnt.line_type$=bmm_billsub.line_type$

		if sfe_wosubcnt.line_type$="S"
			sfe_wosubcnt.unit_measure$=bmm_billsub.unit_measure$	
			sfe_wosubcnt.description$=bmm_billsub.ext_comments$(1,len(sfe_wosubcnt.description$))
			sfe_wosubcnt.oper_seq_ref$=""
			sfe_wosubcnt.units=SfUtils.netSubQuantityRequired(bmm_billsub.qty_required,bmm_billsub.alt_factor,bmm_billsub.divisor)
			sfe_wosubcnt.unit_cost=sfe_wosubcnt.units*bmm_billsub.unit_cost
			sfe_wosubcnt.total_units=sfe_wosubcnt.units*sfe_womastr.sch_prod_qty
			sfe_wosubcnt.total_cost=sfe_wosubcnt.unit_cost*sfe_womastr.sch_prod_qty
			sfe_wosubcnt.rate=bmm_billsub.unit_cost
			sfe_wosubcnt.lead_time=bmm_billsub.lead_time
		else
			sfe_wosubcnt.unit_measure$=""
			sfe_wosubcnt.description$=""
			sfe_wosubcnt.ext_comments$=bmm_billsub.ext_comments$
		endif

		subs_pos=pos(bmm_billsub.bill_no$+bmm_billsub.op_int_seq_ref$=subs$,subs_offset+op_isn_len)
		if subs_pos>0 then sfe_wosubcnt.oper_seq_ref$=subs$(subs_pos+subs_offset,op_isn_len)

		rem --- now write subcontract rec

		read (sfe32_dev,key=firm_id$+wo_loc$+wo_no$+$FF$,dom=*next)
		sfe_wosubcnt.subcont_seq$=fill(sub_seq_len,"0")
		dim sfe32_prev_key$:fattr(sfe32_prev_key$)
		sfe32_prev_key$=keyp(sfe32_dev,end=no_prev_subs_key)
		if pos(firm_id$+wo_loc$+wo_no$=sfe32_prev_key$)=1 then sfe_wosubcnt.subcont_seq$=sfe32_prev_key.subcont_seq$
		if pos("9"<>sfe32_prev_key.subcont_seq$)=0 
			msg_id$="SF_NO_MORE_SEQ"
			gosub disp_message
			no_more_seq=1
			exitto end_do_subcontracts
		endif
no_prev_subs_key:
		sfe_wosubcnt.subcont_seq$=str(num(sfe_wosubcnt.subcont_seq$)+1:sub_seq_mask$)
		internal_seq_no$=""
		call stbl("+DIR_SYP")+"bas_sequences.bbj","INTERNAL_SEQ_NO",internal_seq_no$,table_chans$[all],"QUIET"
		sfe_wosubcnt.internal_seq_no$=internal_seq_no$

		sfe_wosubcnt$=field(sfe_wosubcnt$)
		writerecord (sfe32_dev)sfe_wosubcnt$
		
	wend

end_do_subcontracts:
	return

rem =========================================================
verify_dates:

rem --- verify date on WO is within effective and obsolete dates
rem --- incoming data:
rem --- eff_date$ from bmm_billmat rec
rem --- obs_date$ from bmm_billmat rec
rem --- sfe_womastr$ rec

rem --- returned:  ok$ (Y/N)
rem =========================================================

	ok$="Y"
	if cvs(eff_date$,3)<>"" 
		if sfe_womastr.opened_date$<eff_date$
			ok$="N"
		endif
	endif
	if cvs(obs_date$,3)<>""
		if sfe_womastr.opened_date$>=obs_date$
			ok$="N"
		endif
	endif
	return

rem ==========================================================================
bills_to_explode: rem --- Add/remove to string of bills being exploded

rem --- incoming data:
rem --- checked$
rem ==========================================================================
	rem --- Maintain a string of item/seq# for any bill being exploded (explosion done on exit)
	explode_bills$=callpoint!.getDevObject("explode_bills")
	item_id$=callpoint!.getColumnData("SFE_WOMATL.ITEM_ID")
	mat_isn$=callpoint!.getColumnData("SFE_WOMATL.INTERNAL_SEQ_NO")
	tmp$=mat_isn$+"^"+item_id$+"^^"

	rem --- Bug 6493: On grids callpoint!.getColumnData("<<DISPLAY>>.field") does NOT return data for the current validation row
	rem --- So must test check box directly instead of <<DISPLAY>>.EXPLODE_BILL
	grid! = Form!.getControl(num(stbl("+GRID_CTL")))
	row=callpoint!.getValidationRow()
	col_hdr$=callpoint!.getTableColumnAttribute("<<DISPLAY>>.EXPLODE_BILL","LABS")
	column=util.getGridColumnNumber(grid!, col_hdr$)
	if checked$="" then checked$=iff(grid!.getCellState(row,column),"Y","N")
	if checked$="Y" then
		rem --- Add to string of bills being exploded
		if pos(tmp$=explode_bills$)=0
			explode_bills$=explode_bills$+tmp$
			callpoint!.setDevObject("explode_bills",explode_bills$)
		endif
	else
		rem --- Remove from string of bills being exploded
		start=pos(tmp$=explode_bills$)
		if start then
			explode_bills$=explode_bills$(1,start-1)+explode_bills$(start+len(tmp$))
			callpoint!.setDevObject("explode_bills",explode_bills$)
		endif
	endif
	checked$=""
	return
[[SFE_WOMATL.ITEM_ID.AVAL]]
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

rem --- Skip if item_id didn't change
	item_id$=callpoint!.getUserInput()
	if item_id$=callpoint!.getDevObject("prev_item_id") then break

rem --- Verify item is in the production warehouse
	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	ivm02_dev=fnget_dev("IVM_ITEMWHSE")
	dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")
	dim ivm02a$:fnget_tpl$("IVM_ITEMWHSE")
	whse_id$=callpoint!.getDevObject("warehouse_id")

	read record(ivm01_dev,key=firm_id$+item_id$)ivm01a$
	ivm02_found=0
	read record (ivm02_dev,key=firm_id$+whse_id$+item_id$,dom=*next) ivm02a$; ivm02_found=1
	if !ivm02_found then
		msg_id$="SF_ITEM_NOT_IN_WH"
		dim msg_tokens$[2]
		msg_tokens$[1]=cvs(item_id$,2)
		msg_tokens$[2]=whse_id$
		gosub disp_message
		callpoint!.setStatus("ABORT")
		callpoint!.setDevObject("item_wh_failed",1)
		break
	endif

rem --- Enable/disable explode field for new/changed item
	callpoint!.setColumnData("SFE_WOMATL.ITEM_ID",item_id$)
	callpoint!.setDevObject("new_item",1)
	gosub enable_explode
	callpoint!.setDevObject("new_item",0)

rem --- Set default Unit Cost

	callpoint!.setColumnData("SFE_WOMATL.IV_UNIT_COST",str(ivm02a.unit_cost))
	callpoint!.setColumnData("SFE_WOMATL.UNIT_MEASURE",ivm01a.unit_of_sale$,1)
	callpoint!.setColumnData("SFE_WOMATL.WAREHOUSE_ID",whse_id$)

	callpoint!.setDevObject("special_order",ivm02a.special_ord$)

	qty_required=num(callpoint!.getColumnData("SFE_WOMATL.QTY_REQUIRED"))
	alt_factor=num(callpoint!.getColumnData("SFE_WOMATL.ALT_FACTOR"))
	divisor=num(callpoint!.getColumnData("SFE_WOMATL.DIVISOR"))
	scrap_factor=num(callpoint!.getColumnData("SFE_WOMATL.SCRAP_FACTOR"))
	gosub calculate_totals
[[SFE_WOMATL.BSHO]]
use ::ado_util.src::util
use ::sfo_SfUtils.aon::SfUtils
declare SfUtils sfUtils!

rem --- init data

	mark_to_explode$=""
	refnumMap!=new java.util.HashMap()
	callpoint!.setDevObject("refnumMap",refnumMap!)
	callpoint!.setDevObject("insertedRows",0)
	callpoint!.setDevObject("deletedRows",0)

	all_bills$=""
	x=0
	t=1
	dim allbills[10,1]
	allbills[x,0]=1
	allbills[x,1]=1

	call stbl("+DIR_SYP")+"bac_key_template.bbj","SFE_WOMATL","PRIMARY",sfe22_key_tpl$,rd_table_chans$[all],status$
	call stbl("+DIR_SYP")+"bac_key_template.bbj","SFE_WOOPRTN","PRIMARY",sfe02_key_tpl$,rd_table_chans$[all],status$
	call stbl("+DIR_SYP")+"bac_key_template.bbj","SFE_WOSUBCNT","PRIMARY",sfe32_key_tpl$,rd_table_chans$[all],status$

	callpoint!.setDevObject("new_item",0)
	callpoint!.setDevObject("explode_bills","")
	callpoint!.setDevObject("special_order","")

rem --- if coming in from the AWRI of the header form (vs. launching manually from the Addt'l Opts)
rem --- see if we're on a new WO that's for an I-category bill, and if so explode mats/ops/subs before displaying mats

	if callpoint!.getDevObject("new_rec")="Y" and callpoint!.getDevObject("wo_category")="I" and callpoint!.getDevObject("bm")="Y"

		bmm02_dev=fnget_dev("BMM_BILLMAT")
		sfe01_dev=fnget_dev("SFE_WOMASTR")

		dim bmm_billmat$:fnget_tpl$("BMM_BILLMAT")
		dim sfe_womastr$:fnget_tpl$("SFE_WOMASTR")
		dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")

		wo_no$=callpoint!.getDevObject("wo_no")
		wo_loc$=callpoint!.getDevObject("wo_loc")
		read record (sfe01_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)sfe_womastr$
		new_bill$=sfe_womastr.item_id$
		mat_isn$=pad("",len(sfe_womatl.internal_seq_no$),"0")

		if cvs(new_bill$,3)<>""
			read(bmm02_dev,key=firm_id$+new_bill$,dom=*next)
			bmm02_key$=key(bmm02_dev,end=*endif)
			if pos(firm_id$+new_bill$=bmm02_key$)=1 then gosub explode_bills
		endif
	endif

rem --- Disable grid if Closed Work Order or Recurring

	if callpoint!.getDevObject("wo_status")="C" or 
:		callpoint!.getDevObject("wo_category")="R" or
:		(callpoint!.getDevObject("wo_category")="I" and callpoint!.getDevObject("bm")="Y")
		opts$=callpoint!.getTableAttribute("OPTS")
		callpoint!.setTableAttribute("OPTS",opts$+"BID")

		x$=callpoint!.getTableColumns()
		worefnumPos=pos("SFE_WOMATL.WO_REF_NUM"=x$)
		for x=1 to len(x$) step 40
			rem --- Don't disable wo_ref_num for Bills Of Materials unless WO is closed
			if x<>worefnumPos or
:			(x=worefnumPos and 
:			(callpoint!.getDevObject("wo_status")="C" or (callpoint!.getDevObject("wo_category")<>"I" and callpoint!.getDevObject("bm")<>"Y")))
:			then
				opts$=callpoint!.getTableColumnAttribute(cvs(x$(x,40),2),"OPTS")
				callpoint!.setTableColumnAttribute(cvs(x$(x,40),2),"OPTS",opts$+"C"); rem - makes cells read only
			endif
		next x
	endif

rem --- fill listbox for use with Op Sequence

	sfe02_dev=fnget_dev("SFE_WOOPRTN")
	dim sfe02a$:fnget_tpl$("SFE_WOOPRTN")
	op_code=callpoint!.getDevObject("opcode_chan")
	dim op_code$:callpoint!.getDevObject("opcode_tpl")
	wo_no$=callpoint!.getDevObject("wo_no")
	wo_loc$=callpoint!.getDevObject("wo_loc")

	ops_lines!=SysGUI!.makeVector()
	ops_items!=SysGUI!.makeVector()
	ops_list!=SysGUI!.makeVector()
	ops_lines!.addItem("000000000000")
	ops_items!.addItem("")
	ops_list!.addItem("")

	read(sfe02_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)
	while 1
		read record (sfe02_dev,end=*break) sfe02a$
		if pos(firm_id$+wo_loc$+wo_no$=sfe02a$)<>1 break
		if sfe02a.line_type$<>"S" continue
		dim op_code$:fattr(op_code$)
		read record (op_code,key=firm_id$+sfe02a.op_code$,dom=*next)op_code$
		ops_lines!.addItem(sfe02a.internal_seq_no$)
		ops_items!.addItem(sfe02a.wo_op_ref$)
		ops_list!.addItem(sfe02a.wo_op_ref$+" - "+sfe02a.op_code$+" - "+op_code.code_desc$)
	wend

	if ops_lines!.size()>0
		ldat$=""
		for x=0 to ops_lines!.size()-1
			ldat$=ldat$+ops_items!.getItem(x)+"~"+ops_lines!.getItem(x)+";"
		next x
	endif

	callpoint!.setTableColumnAttribute("SFE_WOMATL.OPER_SEQ_REF","LDAT",ldat$)
	col_hdr$=callpoint!.getTableColumnAttribute("SFE_WOMATL.OPER_SEQ_REF","LABS")
	my_grid!=Form!.getControl(5000)
	ListColumn=util.getGridColumnNumber(my_grid!, col_hdr$)
	my_control!=my_grid!.getColumnListControl(ListColumn)
	my_control!.removeAllItems()
	my_control!.insertItems(0,ops_list!)
	my_grid!.setColumnListControl(ListColumn,my_control!)
	my_grid!.setColumnHeaderCellText(ListColumn,"Op Ref")

rem --- Disable WO_REF_NUM when locked or WO closed
	if callpoint!.getDevObject("lock_ref_num")="Y" or callpoint!.getDevObject("wo_status")="C" or !callpoint!.isEditMode() then
		opts$=callpoint!.getTableColumnAttribute("SFE_WOMATL.WO_REF_NUM","OPTS")
		callpoint!.setTableColumnAttribute("SFE_WOMATL.WO_REF_NUM","OPTS",opts$+"C"); rem --- makes read only
		callpoint!.setOptionEnabled("AUTO",0)
	endif
