[[SFE_WOMATL.BWRI]]
rem --- If BOM is installed, build a string of item/seq# for any item that's a bill; used for explosion when exiting

	if callpoint!.getDevObject("bm")="Y" and callpoint!.getColumnData("SFE_WOMATL.LINE_TYPE")="S"

		bmm01_dev=fnget_dev("BMM_BILLMAST")
		dim bmm_billmast$:fnget_tpl$("BMM_BILLMAST")

		item_id$=callpoint!.getColumnData("SFE_WOMATL.ITEM_ID")
		material_seq$=callpoint!.getColumnData("SFE_WOMATL.MATERIAL_SEQ")

		read record (bmm01_dev,key=firm_id$+item_id$,dom=*next)bmm_billmast$

		if pos(firm_id$+item_id$=bmm_billmast$)=1
			explode_bills$=callpoint!.getDevObject("explode_bills")
			tmp$=material_seq$+"^"+item_id$+"^^"
			if pos(tmp$=explode_bills$)=0
				explode_bills$=explode_bills$+tmp$
				callpoint!.setDevObject("explode_bills",explode_bills$)
			endif
		endif
	endif
[[SFE_WOMATL.BEND]]
rem --- if materials lines were entered manually, and any of them are bills, 
rem --- prompt user to explode them; if yes, explode, then re-launch form so user can view/edit

	if callpoint!.getDevObject("explode_bills")<>""

		msg_id$="SF_EXPLODE"
		msg_opt$=""
		gosub disp_message
		if msg_opt$="Y"

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
				material_seq$=explode_bill$(1,pos("^"=explode_bill$)-1)
				explode_bill$=explode_bill$(pos("^"=explode_bill$)+1)	

				dim bmm_billmast$:fnget_tpl$("BMM_BILLMAST")
				read record (bmm01_dev,key=firm_id$+explode_bill$,dom=*continue)bmm_billmast$

				rem 0590 DIM T0$(0),T[10,1]
				rem 0600 LET X=0,T[X,0]=1,T[X,1]=1,T=1
			
				all_bills$=""
				x=0
				t=1
				dim allbills[10,1]
				allbills[x,0]=1
				allbills[x,1]=1
					
				dim sfe_womastr$:fnget_tpl$("SFE_WOMASTR")		
				read record (sfe01_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)sfe_womastr$

				new_bill$=bmm_billmast.bill_no$
				t=num(callpoint!.getColumnData("SFE_WOMATL.UNITS"))
				allbills[x,0]=t

				gosub explode_bills
				rem --- now remove the original bill record
				remove(sfe22_dev,key=firm_id$+wo_loc$+wo_no$+material_seq$,dom=*next)
		
				callpoint!.setDevObject("explode_bills","Y")
			wend
		else
			callpoint!.setDevObject("explode_bills","N")
		endif
	endif
[[SFE_WOMATL.AGRE]]
rem --- check to see if item is marked special order in IV warehouse rec; if so, mark PO Status flag
	
	if cvs(callpoint!.getColumnData("SFE_WOMATL.PO_STATUS"),3)=""
		if callpoint!.getDevObject("special_order")="Y" then callpoint!.setColumnData("SFE_WOMATL.PO_STATUS","S")
	endif
[[SFE_WOMATL.AREC]]
rem --- initializations

	callpoint!.setDevObject("special_order","N")
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

	all_bills$=new_bill$
	curr_bill$=new_bill$
	subs$=""
	mats$=""
	mats_offset=0
	dim yld[99]
	yld[0]=num(sfe_womastr.est_yield$)
	yld=yld[0]

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
			read (sfe22_dev,key=firm_id$+wo_loc$+wo_no$+$FF$,dom=*next)
			sfe_womatl.material_seq$=fill(material_seq_len,"0")
			dim sfe22_prev_key$:fattr(sfe22_prev_key$)
			sfe22_prev_key$=keyp(sfe22_dev,end=no_prev_mats_key)
			if pos(firm_id$+wo_loc$+wo_no$=sfe22_prev_key$)=1 then sfe_womatl.material_seq$=sfe22_prev_key.material_seq$
			if pos("9"<>sfe22_prev_key.material_seq$)=0 
				msg_id$="SF_NO_MORE_SEQ"
				gosub disp_message
				exitto back_up_levels
			endif
no_prev_mats_key:
			sfe_womatl.material_seq$=str(num(sfe_womatl.material_seq$)+1:mat_seq_mask$)
			internal_seq_no$=""
			call stbl("+DIR_SYP")+"bas_sequences.bbj","INTERNAL_SEQ_NO",internal_seq_no$,table_chans$[all],"QUIET"
			sfe_womatl.internal_seq_no$=internal_seq_no$

			if ivm_itemwhse.special_ord$="Y" then sfe_womatl.po_status$="S"

			sfe_womatl$=field(sfe_womatl$)
			writerecord (sfe22_dev)sfe_womatl$

			if cvs(bmm_billmat.op_int_seq_ref$,3)<>""			
				if mats$="" mats_offset=len(bmm_billmat.bill_no$+bmm_billmat.op_int_seq_ref$)
				mats$=mats$+bmm_billmat.bill_no$+bmm_billmat.op_int_seq_ref$+sfe_womatl.material_seq$
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

back_up_levels: rem --- this is the 6900 part - move on to ops and subs for phantoms, or do final ops/subs

	if all_bills$<>new_bill$
		gosub do_operations
		if callpoint!.getDevObject("po")="Y" then gosub do_subcontracts
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
		if callpoint!.getDevObject("po")="Y" then gosub do_subcontracts
		rem all done... should now be ready to display what's just been added to mats grid
	endif
	return

rem =========================================================
do_operations:

	yld=num(sfe_womastr.est_yield$)
	dim bmm_billoper$:fattr(bmm_billoper$)
	dim sfe_wooprtn$:fattr(sfe_wooprtn$)
	dim sfe02_prev_key$:sfe02_key_tpl$

	sfe_wooprtn.firm_id$=firm_id$
	sfe_wooprtn.wo_location$=wo_loc$
	sfe_wooprtn.wo_no$=wo_no$

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
			exitto back_up_levels
		endif
no_prev_ops_key:
		sfe_wooprtn.op_seq$=str(num(sfe_wooprtn.op_seq$)+1:op_seq_mask$)
		internal_seq_no$=""
		call stbl("+DIR_SYP")+"bas_sequences.bbj","INTERNAL_SEQ_NO",internal_seq_no$,table_chans$[all],"QUIET"
		sfe_wooprtn.internal_seq_no$=internal_seq_no$

		sfe_wooprtn$=field(sfe_wooprtn$)
		writerecord (sfe02_dev)sfe_wooprtn$

		if subs$="" subs_offset=len(curr_bill$+bmm_billoper.internal_seq_no$)
		subs$=subs$+curr_bill$+bmm_billoper.internal_seq_no$+sfe_wooprtn.internal_seq_no$
	
		while 1
			mats_pos=pos(bmm_billoper.bill_no$+bmm_billoper.internal_seq_no$=mats$,mats_offset+material_seq_len,occ)
			if mats_pos=0 then break
			dim sfe_womatl2$:fattr(sfe_womatl$)
			extract record (sfe22_dev,key=firm_id$+wo_loc$+wo_no$+mats$(mats_pos+mats_offset,material_seq_len),dom=*break)sfe_womatl2$
			sfe_womatl2.oper_seq_ref$=sfe_wooprtn.internal_seq_no$
			sfe_womatl2$=field(sfe_womatl2$)
			write record (sfe22_dev)sfe_womatl2$
			occ=occ+1
		wend
	
	wend

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
			sfe_wosubcnt.description$=bmm_billsub.ext_comments$(10,len(sfe_wosubcnt.description$))
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
			sfe_wosubcnt.ext_comments$=bill_billsub.ext_comments$
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
			exitto back_up_levels
		endif
no_prev_subs_key:
		sfe_wosubcnt.subcont_seq$=str(num(sfe_wosubcnt.subcont_seq$)+1:sub_seq_mask$)
		internal_seq_no$=""
		call stbl("+DIR_SYP")+"bas_sequences.bbj","INTERNAL_SEQ_NO",internal_seq_no$,table_chans$[all],"QUIET"
		sfe_wosubcnt.internal_seq_no$=internal_seq_no$

		sfe_wosubcnt$=field(sfe_wosubcnt$)
		writerecord (sfe32_dev)sfe_wosubcnt$
		
	wend

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
[[SFE_WOMATL.ITEM_ID.AVAL]]
rem --- Set default Unit Cost

	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	ivm02_dev=fnget_dev("IVM_ITEMWHSE")
	dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")
	dim ivm02a$:fnget_tpl$("IVM_ITEMWHSE")
	whse_id$=callpoint!.getDevObject("default_wh")

	read record(ivm01_dev,key=firm_id$+callpoint!.getUserInput())ivm01a$
	read record (ivm02_dev,key=firm_id$+whse_id$+callpoint!.getUserInput()) ivm02a$

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
use ::sfo_SfUtils.aon::SfUtils
declare SfUtils sfUtils!

rem --- init data

rem 0590 DIM T0$(0),T[10,1]
rem 0600 LET X=0,T[X,0]=1,T[X,1]=1,T=1

	all_bills$=""
	x=0
	t=1
	dim allbills[10,1]
	allbills[x,0]=1
	allbills[x,1]=1

	call stbl("+DIR_SYP")+"bac_key_template.bbj","SFE_WOMATL","PRIMARY",sfe22_key_tpl$,rd_table_chans$[all],status$
	call stbl("+DIR_SYP")+"bac_key_template.bbj","SFE_WOOPRTN","PRIMARY",sfe02_key_tpl$,rd_table_chans$[all],status$
	call stbl("+DIR_SYP")+"bac_key_template.bbj","SFE_WOSUBCNT","PRIMARY",sfe32_key_tpl$,rd_table_chans$[all],status$

	callpoint!.setDevObject("explode_bills","")
	callpoint!.setDevObject("special_order","")

rem --- if coming in from the AWRI of the header form (vs. launching manually from the Addt'l Opts)
rem --- see if we're on a new WO that's for an I-category bill, and if so explode mats/ops/subs before displaying mats

	if callpoint!.getDevObject("new_rec")="Y" and callpoint!.getDevObject("wo_category")="I" and callpoint!.getDevObject("bm")="Y"

		bmm02_dev=fnget_dev("BMM_BILLMAT")
		sfe01_dev=fnget_dev("SFE_WOMASTR")

		dim bmm_billmat$:fnget_tpl$("BMM_BILLMAT")
		dim sfe_womastr$:fnget_tpl$("SFE_WOMASTR")

		wo_no$=callpoint!.getDevObject("wo_no")
		wo_loc$=callpoint!.getDevObject("wo_loc")
		read record (sfe01_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)sfe_womastr$
		new_bill$=sfe_womastr.item_id$

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
		for x=1 to len(x$) step 40
			opts$=callpoint!.getTableColumnAttribute(cvs(x$(x,40),2),"OPTS")
			callpoint!.setTableColumnAttribute(cvs(x$(x,40),2),"OPTS",o$+"C"); rem - makes cells read only
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
		ops_items!.addItem(sfe02a.op_code$)
		ops_list!.addItem(sfe02a.op_code$+" - "+op_code.code_desc$)
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
	num_grid_cols=my_grid!.getNumColumns()
	ListColumn=-1
	for xwk=0 to num_grid_cols-1
		if my_grid!.getColumnHeaderCellText(xwk)=col_hdr$ then ListColumn=xwk
	next xwk
	if ListColumn>=0
		my_control!=my_grid!.getColumnListControl(ListColumn)
		my_control!.removeAllItems()
		my_control!.insertItems(0,ops_list!)
		my_grid!.setColumnListControl(ListColumn,my_control!)
	endif
[[SFE_WOMATL.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::grid_entry"
