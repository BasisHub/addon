[[SFE_WOCLOSE.AOPT-LSNO]]
rem --- Launch sfe_wolotser form to assign lot/serial numbers
	gosub do_wolotser
[[SFE_WOCLOSE.ASVA]]
rem --- Don't do close stuff when SAVE comes from callpoint!.setStatus("SAVE")
	if callpoint!.getDevObject("set_status_save") then 
		callpoint!.setDevObject("set_status_save",0)
		break
	endif

rem --- Write sfe_closedwo record
	closedwo_dev=fnget_dev("1SFE_CLOSEDWO")
	dim closedwo$:fnget_tpl$("1SFE_CLOSEDWO")
	closedwo.firm_id$=firm_id$
	closedwo.wo_location$=callpoint!.getColumnData("SFE_WOCLOSE.WO_LOCATION")
	closedwo.wo_no$=callpoint!.getColumnData("SFE_WOCLOSE.WO_NO")
	writerecord(closedwo_dev,dom=*next)closedwo$

rem --- Recalculate standards
 	if callpoint!.getColumnData("SFE_WOCLOSE.RECALC_FLAG")="Y" then
		qty_cls_todt=num(callpoint!.getColumnData("SFE_WOCLOSE.QTY_CLS_TODT"))
		cls_inp_qty=num(callpoint!.getColumnData("SFE_WOCLOSE.CLS_INP_QTY"))
		msg_id$="SF_RECALC_STDS"
		dim msg_tokens$[1]
		msg_tokens$[1]=str(qty_cls_todt+cls_inp_qty)
		gosub disp_message
		if msg_opt$="N" then
			callpoint!.setStatus("ABORT")
			break
		endif

		rem --- Adjust inventory on order quantity if necessary
		sch_prod_qty=num(callpoint!.getColumnData("SFE_WOCLOSE.SCH_PROD_QTY"))
		if callpoint!.getColumnData("SFE_WOCLOSE.WO_CATEGORY")="I" and sch_prod_qty-(qty_cls_todt+cls_inp_qty)<>0 then

			rem --- Initialize inventory item update
			call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

			rem --- Reduce inventory on order for close incomplete work order
			items$[1]=callpoint!.getColumnData("SFE_WOCLOSE.WAREHOUSE_ID")
			items$[2]=callpoint!.getColumnData("SFE_WOCLOSE.ITEM_ID")
			refs[0]=-(sch_prod_qty-(qty_cls_todt+cls_inp_qty))
			call stbl("+DIR_PGM")+"ivc_itemupdt.aon","OO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
		endif

		rem --- Adjust standards for closed incomplete work order
		precision$=callpoint!.getDevObject("precision")
		sch_prod_qty=qty_cls_todt+cls_inp_qty
		callpoint!.setColumnData("SFE_WOCLOSE.SCH_PROD_QTY",str(sch_prod_qty),1)
		est_yield=num(callpoint!.getColumnData("SFE_WOCLOSE.EST_YIELD"))
		for req=1 to 3
			switch req
				case 1
					woreq_dev=fnget_dev("1SFE_WOOPRTN")
					dim woreq$:fnget_tpl$("1SFE_WOOPRTN")
					break
				case 2
					woreq_dev=fnget_dev("1SFE_WOMATL")
					dim woreq$:fnget_tpl$("1SFE_WOMATL")
					break
				case 3
					woreq_dev=fnget_dev("1SFE_WOSUBCNT")
					dim woreq$:fnget_tpl$("1SFE_WOSUBCNT")
					break
			swend
			read(woreq_dev,key=closedwo.firm_id$+closedwo.wo_location$+closedwo.wo_no$,dom=*next)
			while 1
				woreq_key$=key(woreq_dev,end=*break)
				if pos(closedwo.firm_id$+closedwo.wo_location$+closedwo.wo_no$=woreq_key$)<>1 then break
				extractrecord(woreq_dev)woreq$; rem Advisory locking
				switch req
					case 1; rem sfe_wooprtn (sfe-02)
						if woreq.pcs_per_hour=0 then woreq.pcs_per_hour=1
						woreq.total_time=SfUtils.opTime(1,
:										  		sch_prod_qty,
:										  		woreq.hrs_per_pce,
:										  		woreq.pcs_per_hour,
:										  		100,
:										  		woreq.setup_time)
						precision 2
						woreq.tot_std_cost= SfUtils.opTotStdCost(sch_prod_qty,
:												woreq.hrs_per_pce,
:												woreq.direct_rate,
:												woreq.ovhd_rate,
:												woreq.pcs_per_hour,
:												est_yield,
:												woreq.setup_time)
						break
					case 2; rem sfe_womatl (sfe-22)
						if woreq.divisor=0 then woreq.divisor=1
						woreq.units= SfUtils.matQtyWorkOrd(woreq.qty_required,
:												 woreq.alt_factor,
:												 woreq.divisor,
:												 woreq.scrap_factor,
:												 est_yield)
						woreq.unit_cost=woreq.units*woreq.iv_unit_cost
						woreq.total_units=woreq.units*sch_prod_qty
						precision 2
						woreq.total_cost=woreq.total_units*woreq.iv_unit_cost
						break
					case 3; rem sfe_wosubcnt (sfe-32)
						woreq.unit_cost=woreq.units*woreq.rate
						woreq.total_units=woreq.units*sch_prod_qty
						precision 2
						woreq.total_cost=woreq.unit_cost*sch_prod_qty
						break
					case default
						break
				swend
				precision num(precision$)
				writerecord(woreq_dev)woreq$
			wend
		next req

		rem --- Clear recalculate flang
		callpoint!.setColumnData("SFE_WOCLOSE.RECALC_FLAG","",1)
	endif

rem --- Lot/serial processing if needed
	if callpoint!.getColumnData("SFE_WOCLOSE.WO_CATEGORY")="I" and 
:	callpoint!.getColumnData("SFE_WOCLOSE.LOTSER_ITEM")="Y" and 
:	pos(callpoint!.getDevObject("lotser")="LS") then
		gosub do_wolotser
	endif
[[SFE_WOCLOSE.CLOSED_COST.BINP]]
rem --- As needed, initialize actual closed cost and closed value
	closed_cost=num(callpoint!.getUserInput())
	if num(callpoint!.getColumnData("SFE_WOCLOSE.CLOSED_COST"))=0 then
		stdact_flag$=callpoint!.getDevObject("stdact_flag")
		complete_flg$=callpoint!.getColumnData("SFE_WOCLOSE.COMPLETE_FLG")
		cls_inp_qty=num(callpoint!.getColumnData("SFE_WOCLOSE.CLS_INP_QTY"))
		gosub update_act_closed_cost
	endif
[[SFE_WOCLOSE.CLOSED_COST.AVAL]]
rem --- Update closed value
	closed_cost=num(callpoint!.getUserInput())
	cls_inp_qty=num(callpoint!.getColumnData("SFE_WOCLOSE.CLS_INP_QTY"))
	callpoint!.setColumnData("<<DISPLAY>>.CLOSED_VALUE",str(cls_inp_qty*closed_cost),1)
[[SFE_WOCLOSE.COMPLETE_FLG.AVAL]]
rem --- Enable/disable closed cost
	complete_flg$=callpoint!.getUserInput()
	stdact_flag$=callpoint!.getDevObject("stdact_flag")
	gosub enable_closed_cost

rem --- Update actual closed cost and closed value
	closed_cost=num(callpoint!.getColumnData("SFE_WOCLOSE.CLOSED_COST"))
	cls_inp_qty=num(callpoint!.getColumnData("SFE_WOCLOSE.CLS_INP_QTY"))
	gosub update_act_closed_cost

rem --- Enable/disable recalculate flag
	gosub enable_recalc_flg

rem --- Check for open POs for subcontracts for this work order
	if cvs(callpoint!.getUserInput(),2)="Y" and callpoint!.getDevObject("po")="Y" then
		open$=""
		wosubcnt_dev=fnget_dev("1SFE_WOSUBCNT")
		dim wosubcnt$:fnget_tpl$("1SFE_WOSUBCNT")
		podet_dev=fnget_dev("@POE_PODET")
		reqdet_dev=fnget_dev("@POE_REQDET")

		wo_location$=callpoint!.getColumnData("SFE_WOCLOSE.WO_LOCATION")
		wo_no$=callpoint!.getColumnData("SFE_WOCLOSE.WO_NO")
		wosubcnt_trip$=firm_id$+wo_location$+wo_no$
		read(wosubcnt_dev,key=wosubcnt_trip$,dom=*next)
		while 1
			wosubcnt_key$=key(wosubcnt_dev,end=*break)
			if pos(wosubcnt_trip$=wosubcnt_key$)<>1 then break
			readrecord(wosubcnt_dev)wosubcnt$
			if num(wosubcnt.po_no$)=0 then continue

			rem --- Check purchase order detail
			dim podet$:fnget_tpl$("@POE_PODET")
			readrecord(podet_dev,key=firm_id$+wosubcnt.po_no$+wosubcnt.pur_ord_seq_ref$,dom=*next)podet$
			if podet.wo_no$+podet.wk_ord_seq_ref$=wosubcnt.wo_no$+wosubcnt.internal_seq_no$ then
				open$=cvs(Translate!.getTranslation("AON_ORDERS"),8)
				break
			endif

			rem --- Check PO requisition detail
			dim reqdet$:fnget_tpl$("@POE_REQDET")
			readrecord(reqdet_dev,key=firm_id$+wosubcnt.po_no$+wosubcnt.pur_ord_seq_ref$,dom=*next)reqdet$
			if reqdet.wo_no$+reqdet.wk_ord_seq_ref$=wosubcnt.wo_no$+wosubcnt.internal_seq_no$ then
				open$=cvs(Translate!.getTranslation("AON_REQUISITIONS"),8)
				break
			endif
		wend

		if open$<>"" then
			callpoint!.setUserInput("N")
			msg_id$="SF_OPEN_SUBCONTRACTS"
			dim msg_tokens$[1]
			msg_tokens$[1]=open$
			gosub disp_message
		endif
	endif
[[SFE_WOCLOSE.CLS_INP_QTY.AVAL]]
rem --- Can't unclose more than previously closed
	cls_inp_qty=num(callpoint!.getUserInput())
	qty_cls_todt=num(callpoint!.getColumnData("SFE_WOCLOSE.QTY_CLS_TODT"))
	if cls_inp_qty<>0 and qty_cls_todt<>0 and sgn(cls_inp_qty)<>sgn(qty_cls_todt) and abs(cls_inp_qty)>abs(qty_cls_todt) then
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Work order complete?
	complete_flg$=callpoint!.getColumnData("SFE_WOCLOSE.COMPLETE_FLG")
	if cls_inp_qty+qty_cls_todt>=num(callpoint!.getColumnData("SFE_WOCLOSE.SCH_PROD_QTY")) then
		complete_flg$="Y"
		callpoint!.setColumnData("SFE_WOCLOSE.COMPLETE_FLG",complete_flg$,1)
		callpoint!.setStatus("MODIFIED")
		stdact_flag$=callpoint!.getDevObject("stdact_flag")
		gosub enable_closed_cost
	endif

rem --- Update actual closed cost and closed value
	closed_cost=num(callpoint!.getColumnData("SFE_WOCLOSE.CLOSED_COST"))
	stdact_flag$=callpoint!.getDevObject("stdact_flag")
	gosub update_act_closed_cost

rem --- Enable/disable recalculate flag
	gosub enable_recalc_flg
[[SFE_WOCLOSE.ASHO]]
rem --- Get system info
	dim sysinfo$:stbl("+SYSINFO_TPL")
	sysinfo$=stbl("+SYSINFO")
[[SFE_WOCLOSE.CLS_INP_DATE.AVAL]]
rem --- Verify date when GL installed
	cls_inp_date$=callpoint!.getUserInput()
	if callpoint!.getDevObject("gl")="Y" then
		rem --- Verify date is in an open period
		call stbl("+DIR_PGM")+"glc_datecheck.aon",cls_inp_date$,"Y",per$,yr$,status
		if status>99 then 
			callpoint!.setStatus("ABORT")
			break
		endif

		rem --- Verify date is not in prior period
		if cls_inp_date$<callpoint!.getDevObject("gl_beg_date") then
			msg_id$="SF_CLOSE_PRIOR"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
	endif
[[SFE_WOCLOSE.CLS_INP_DATE.BINP]]
rem --- Close this work order?
	ask_close_question=num(callpoint!.getDevObject("ask_close_question"))
	if ask_close_question and callpoint!.getColumnData("SFE_WOCLOSE.COMPLETE_FLG")<>"Y" then
		rem --- Work order scheduled to be closed?
		closedwo_dev=fnget_dev("1SFE_CLOSEDWO")
		wo_location$=callpoint!.getColumnData("SFE_WOCLOSE.WO_LOCATION")
		wo_no$=callpoint!.getColumnData("SFE_WOCLOSE.WO_NO")
		closedwo_found=0
		findrecord(closedwo_dev,key=firm_id$+wo_location$+wo_no$,dom=*next);closedwo_found=1
		if !closedwo_found then
			callpoint!.setDevObject("ask_close_question","0")
			msg_id$="SF_CLOSE_WO"
			gosub disp_message
			if msg_opt$="N" then
				rem --- Done with this work order
				callpoint!.setStatus("NEWREC")
				break
			endif
		endif
	endif

rem --- Initialize input close date
	if cvs(callpoint!.getColumnData("SFE_WOCLOSE.CLS_INP_DATE"),2)="" then
		callpoint!.setColumnData("SFE_WOCLOSE.CLS_INP_DATE",sysinfo.system_date$,1)
		callpoint!.setStatus("MODIFIED")
	endif

rem --- Display isn't being refreshed after wo reopened in ADIS , so must do it here
	callpoint!.setStatus("REFRESH")
[[SFE_WOCLOSE.ADIS]]
rem --- Need to ask about closing this work order
	callpoint!.setDevObject("ask_close_question","1")

rem --- Initialize complete flag as necessary
	complete_flg$=callpoint!.getColumnData("SFE_WOCLOSE.COMPLETE_FLG")
	if pos(complete_flg$="YN")=0 then
		complete_flg$="N"
		callpoint!.setColumnData("SFE_WOCLOSE.COMPLETE_FLG",complete_flg$,1)
	endif

rem --- Close at standard or actual?
	wotypecd_dev=fnget_dev("@SFC_WOTYPECD")
	dim wotypecd$:fnget_tpl$("@SFC_WOTYPECD")
	wo_type$=callpoint!.getColumnData("SFE_WOCLOSE.WO_TYPE")
	findrecord(wotypecd_dev,key=firm_id$+"A"+wo_type$,dom=*next)wotypecd$
	stdact_flag$=wotypecd.stdact_flag$
	callpoint!.setDevObject("stdact_flag",stdact_flag$)
	gosub enable_closed_cost

rem --- Work order scheduled to be closed?
	closedwo_dev=fnget_dev("1SFE_CLOSEDWO")
	dim closedwo$:fnget_tpl$("1SFE_CLOSEDWO")
	wo_location$=callpoint!.getColumnData("SFE_WOCLOSE.WO_LOCATION")
	wo_no$=callpoint!.getColumnData("SFE_WOCLOSE.WO_NO")
	findrecord(closedwo_dev,key=firm_id$+wo_location$+wo_no$,dom=*next)closedwo$
	callpoint!.setDevObject("set_status_save",0)
	if closedwo.wo_no$=wo_no$ then
		rem --- Reopen closed work order?
		msg_id$="SF_REOPEN_WO"
		gosub disp_message
		if msg_opt$="Y" then
			rem --- Reopen work order
			remove(closedwo_dev,key=firm_id$+wo_location$+wo_no$,dom=*next)
			callpoint!.setColumnData("SFE_WOCLOSE.CLS_INP_DATE","",1)
			callpoint!.setColumnData("SFE_WOCLOSE.COMPLETE_FLG","N",1)
			callpoint!.setColumnData("SFE_WOCLOSE.CLS_INP_QTY","0",1)
			callpoint!.setColumnData("SFE_WOCLOSE.CLOSED_COST","0",1)
			callpoint!.setStatus("REFRESH-SAVE")
			callpoint!.setDevObject("set_status_save",1)

			rem --- Clear close entries for serial/lot numbers for this work order
			lotser$=callpoint!.getDevObject("lotser")
			if pos(lotser$="LS")=0 then
				wolotser_dev=fnget_dev("1SFE_WOLOTSER")
				dim wolotser$:fnget_tpl$("1SFE_WOLOTSER")
				read(wolotser_dev,key=firm_id$+wo_location$+wo_no$,dom=*next)closedwo$
				while 1
					wolotser_key$=key(wolotser_dev,end=*break)
					if pos(firm_id$+wo_location$+wo_no$=wolotser_key$)<>1 then break
					extractrecord(wolotser_dev,key=wolotser_key$)wolotser$; rem Advisory locking
					wolotser.complete_flg$="N"
					wolotser.cls_inp_qty=0
					wolotser.closed_cost=0
					writerecord(wolotser_dev)wolotser$
				wend
			endif
		endif
	endif

rem --- Check work order status
	wo_status$=callpoint!.getColumnData("SFE_WOCLOSE.WO_STATUS")
	if wo_status$<>"O" then
		switch (BBjAPI().TRUE)
			case wo_status$="P"
				msg_id$="SF_CANNOT_CLOSE_P"
				break
			case wo_status$="Q"
				msg_id$="SF_CANNOT_CLOSE_Q"
				break
			case wo_status$="C"
				msg_id$="SF_WO_CLS_UPDAT"
				break
			case default
				break
		swend
		gosub disp_message

		rem --- Done with this work order
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Calculate standard cost, actual cost and last op code seq number
	std_cost=0
	act_cost=0
	last_op_cd_seq_no$=""
	sch_prod_qty=num(callpoint!.getColumnData("SFE_WOCLOSE.SCH_PROD_QTY"))
	wo_category$=callpoint!.getColumnData("SFE_WOCLOSE.WO_CATEGORY")
	if wo_category$="I" then
		itemwhse_dev=fnget_dev("@IVM_ITEMWHSE")
		dim itemwhse$:fnget_tpl$("@IVM_ITEMWHSE")
		whse$=callpoint!.getColumnData("SFE_WOCLOSE.WAREHOUSE_ID")
		item$=callpoint!.getColumnData("SFE_WOCLOSE.ITEM_ID")
		findrecord(itemwhse_dev,key=firm_id$+whse$+item$,dom=*endif)itemwhse$
		std_cost=sch_prod_qty*itemwhse.std_cost
	endif

	rem --- Check requirements files
	cost_method$=callpoint!.getDevObject("cost_method")
	if cost_method$<>"S" and stdact_flag$="S" then std_cost=0
	for req=1 to 3
		switch req
			case 1
				woreq_dev=fnget_dev("1SFE_WOOPRTN")
				dim woreq$:fnget_tpl$("1SFE_WOOPRTN")
				cost_field$="TOT_STD_COST"
				break
			case 2
				woreq_dev=fnget_dev("1SFE_WOMATL")
				dim woreq$:fnget_tpl$("1SFE_WOMATL")
				cost_field$="TOTAL_COST"
				break
			case 3
				woreq_dev=fnget_dev("1SFE_WOSUBCNT")
				dim woreq$:fnget_tpl$("1SFE_WOSUBCNT")
				cost_field$="TOTAL_COST"
				break
		swend
		read(woreq_dev,key=firm_id$+wo_location$+wo_no$,dom=*next)
		while 1
			woreq_key$=key(woreq_dev,end=*break)
			if pos(firm_id$+wo_location$+wo_no$=woreq_key$)<>1 then break
			readrecord(woreq_dev)woreq$
			if wo_category$<>"I" or (cost_method$<>"S" and stdact_flag$="S") then std_cost=std_cost+nfield(woreq$,cost_field$)
			if req=1 then last_op_cd_seq_no$=woreq.internal_seq_no$
		wend
	next req

	rem --- Check transactions files
	if cost_method$<>"S" and stdact_flag$="S" then itemwhse.std_cost=0
	for tran=1 to 3
		switch tran
			case 1
				wotran_dev=fnget_dev("@SFT_OPNOPRTR")
				dim wotran$:fnget_tpl$("@SFT_OPNOPRTR")
				break
			case 2
				wotran_dev=fnget_dev("@SFT_OPNMATTR")
				dim wotran$:fnget_tpl$("@SFT_OPNMATTR")
				break
			case 3
				wotran_dev=fnget_dev("@SFT_OPNSUBTR")
				dim wotran$:fnget_tpl$("@SFT_OPNSUBTR")
				break
		swend
		read(wotran_dev,key=firm_id$+wo_location$+wo_no$,dom=*next)
		while 1
			wotran_key$=key(wotran_dev,end=*break)
			if pos(firm_id$+wo_location$+wo_no$=wotran_key$)<>1 then break
			readrecord(wotran_dev)wotran$
			act_cost=act_cost+wotran.ext_cost
		wend
	next tran

rem --- Calculate and display new amounts
	if wo_category$<>"I" or (cost_method$<>"S" and stdact_flag$="S") then
		if sch_prod_qty<>0 then
			itemwhse.std_cost=std_cost/sch_prod_qty
		else
			itemwhse.std_cost=0
		endif
	endif
	if sch_prod_qty<>0 then
		act_unit_cost=act_cost/sch_prod_qty
	else
		act_unit_cost=0
	endif
	closed_cost=num(callpoint!.getColumnData("SFE_WOCLOSE.CLOSED_COST"))
	if closed_cost=0 and stdact_flag$<>"A" then closed_cost=itemwhse.std_cost
	qty_cls_todt=num(callpoint!.getColumnData("SFE_WOCLOSE.QTY_CLS_TODT"))
	if num(callpoint!.getColumnData("SFE_WOCLOSE.CLS_INP_QTY"))=0 then
		cls_inp_qty=max(0,sch_prod_qty-qty_cls_todt)
		callpoint!.setColumnData("SFE_WOCLOSE.CLS_INP_QTY",str(cls_inp_qty),1)
		callpoint!.setStatus("MODIFIED")
	endif
	if num(callpoint!.getColumnData("SFE_WOCLOSE.CLOSED_COST"))<>closed_cost then
		callpoint!.setColumnData("SFE_WOCLOSE.CLOSED_COST",str(closed_cost),1)
		callpoint!.setStatus("MODIFIED")
	endif
	callpoint!.setColumnData("<<DISPLAY>>.CLOSED_VALUE",str(cls_inp_qty*closed_cost),1)
	callpoint!.setColumnData("<<DISPLAY>>.SCH_PROD_QTY_2",str(sch_prod_qty),1)
	callpoint!.setColumnData("<<DISPLAY>>.CLOSED_TO_DATE",str(qty_cls_todt),1)
	callpoint!.setColumnData("<<DISPLAY>>.STD_UNIT_COST",str(itemwhse.std_cost),1)
	callpoint!.setColumnData("<<DISPLAY>>.VALUE_AT_STD",str(std_cost),1)
	callpoint!.setColumnData("<<DISPLAY>>.ACT_UNIT_COST",str(act_unit_cost),1)
	callpoint!.setColumnData("<<DISPLAY>>.VALUE_AT_ACT",str(act_cost),1)

rem -- Disable lot/serial option if not lotted/serialized, and scheduled for close
	if callpoint!.getColumnData("SFE_WOCLOSE.WO_CATEGORY")="I" and 
:	callpoint!.getColumnData("SFE_WOCLOSE.LOTSER_ITEM")="Y" and 
:	pos(callpoint!.getDevObject("lotser")="LS") then
		rem --- Work order scheduled for close?
		closedwo_dev=fnget_dev("1SFE_CLOSEDWO")
		wo_location$=callpoint!.getColumnData("SFE_WOCLOSE.WO_LOCATION")
		wo_no$=callpoint!.getColumnData("SFE_WOCLOSE.WO_NO")
		closedwo_found=0
		findrecord(closedwo_dev,key=firm_id$+wo_location$+wo_no$,dom=*next);closedwo_found=1
		if closedwo_found then
			callpoint!.setOptionEnabled("LSNO",1)
		else
			callpoint!.setOptionEnabled("LSNO",0)
		endif
	else
		callpoint!.setOptionEnabled("LSNO",0)
	endif
[[SFE_WOCLOSE.<CUSTOM>]]
#include std_missing_params.src

rem ==========================================================================
enable_closed_cost: rem --- Enable/disable closed cost
rem --- stdact_flag$: input
rem --- complete_flg$: input
rem ==========================================================================
	if stdact_flag$<>"A" or complete_flg$="Y" then
		callpoint!.setColumnEnabled("SFE_WOCLOSE.CLOSED_COST",0)
	else
		callpoint!.setColumnEnabled("SFE_WOCLOSE.CLOSED_COST",1)
	endif
	return

rem ==========================================================================
update_act_closed_cost: rem --- Update actual closed cost and closed value
rem --- stdact_flag$: input
rem --- complete_flg$: input
rem --- cls_inp_qty: input
rem --- closed_cost: input
rem ==========================================================================

	if stdact_flag$="A" and complete_flg$="Y" then
		act_cost=num(callpoint!.getColumnData("<<DISPLAY>>.VALUE_AT_ACT"))
		cls_cst_todt=num(callpoint!.getColumnData("SFE_WOCLOSE.CLS_CST_TODT"))
		if cls_inp_qty=0
			closed_cost=0
		else
			closed_cost=(act_cost-cls_cst_todt)/cls_inp_qty
		endif
	endif
	callpoint!.setColumnData("SFE_WOCLOSE.CLOSED_COST",str(closed_cost),1)
	callpoint!.setColumnData("<<DISPLAY>>.CLOSED_VALUE",str(cls_inp_qty*closed_cost),1)
	callpoint!.setStatus("MODIFIED")

	return

rem ==========================================================================
enable_recalc_flg: rem --- Enable/disable recalculate flag
rem --- complete_flg$: input
rem --- cls_inp_qty: input
rem ==========================================================================
	sch_prod_qty=num(callpoint!.getColumnData("SFE_WOCLOSE.SCH_PROD_QTY"))
	qty_cls_todt=num(callpoint!.getColumnData("SFE_WOCLOSE.QTY_CLS_TODT"))
	if complete_flg$<>"Y" or sch_prod_qty=qty_cls_todt+cls_inp_qty then
		callpoint!.setColumnData("SFE_WOCLOSE.RECALC_FLAG","",1)
		callpoint!.setColumnEnabled("SFE_WOCLOSE.RECALC_FLAG",0)
	else
		callpoint!.setColumnEnabled("SFE_WOCLOSE.RECALC_FLAG",1)
	endif
	return

rem ==========================================================================
do_wolotser: rem --- Launch sfe_wolotser form to assign lot/serial numbers
rem ==========================================================================
	callpoint!.setDevObject("wo_loc",callpoint!.getColumnData("SFE_WOCLOSE.WO_LOCATION"))
	callpoint!.setDevObject("wo_no",callpoint!.getColumnData("SFE_WOCLOSE.WO_NO"))
	callpoint!.setDevObject("wo_status",callpoint!.getColumnData("SFE_WOCLOSE.WO_STATUS"))
	callpoint!.setDevObject("warehouse_id",callpoint!.getColumnData("SFE_WOCLOSE.WAREHOUSE_ID"))
	callpoint!.setDevObject("item_id",callpoint!.getColumnData("SFE_WOCLOSE.ITEM_ID"))
	callpoint!.setDevObject("prod_qty",callpoint!.getColumnData("SFE_WOCLOSE.SCH_PROD_QTY"))
	callpoint!.setDevObject("cls_inp_qty",callpoint!.getColumnData("SFE_WOCLOSE.CLS_INP_QTY"))
	callpoint!.setDevObject("qty_cls_todt",callpoint!.getColumnData("SFE_WOCLOSE.QTY_CLS_TODT"))
	callpoint!.setDevObject("closed_cost",callpoint!.getColumnData("SFE_WOCLOSE.CLOSED_COST"))
	callpoint!.setDevObject("wolotser_action","close")

	key_pfx$=firm_id$+callpoint!.getColumnData("SFE_WOCLOSE.WO_LOCATION")+callpoint!.getColumnData("SFE_WOCLOSE.WO_NO")

	dim dflt_data$[3,1]
	dflt_data$[1,0]="SFE_WOLOTSER.FIRM_ID"
	dflt_data$[1,1]=firm_id$
	dflt_data$[2,0]="SFE_WOLOTSER.WO_LOCATION"
	dflt_data$[2,1]=callpoint!.getColumnData("SFE_WOCLOSE.WO_LOCATION")
	dflt_data$[3,0]="SFE_WOLOTSER.WO_NO"
	dflt_data$[3,1]=callpoint!.getColumnData("SFE_WOCLOSE.WO_NO")

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"SFE_WOLOTSER",
:		stbl("+USER_ID"),
:		access$,
:		key_pfx$,
:		table_chans$[all],
:		"",
:		dflt_data$[all]

	return
[[SFE_WOCLOSE.BSHO]]
use ::sfo_SfUtils.aon::SfUtils

rem --- Open Files
	num_files=13
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFS_PARAMS",open_opts$[1]="OTA@"
	open_tables$[2]="IVS_PARAMS",open_opts$[2]="OTA@"
	open_tables$[3]="SFE_WOOPRTN",open_opts$[3]="OTA[1]"
	open_tables$[4]="SFE_CLOSEDWO",open_opts$[4]="OTA[1]"
	open_tables$[5]="SFE_WOMATL",open_opts$[5]="OTA[1]"
	open_tables$[6]="SFE_WOSUBCNT",open_opts$[6]="OTA[1]"
	open_tables$[7]="SFC_WOTYPECD",open_opts$[7]="OTA@"
	open_tables$[8]="SFT_OPNOPRTR",open_opts$[8]="OTA@"
	open_tables$[9]="SFT_OPNMATTR",open_opts$[9]="OTA@"
	open_tables$[10]="SFT_OPNSUBTR",open_opts$[10]="OTA@"
	open_tables$[11]="IVM_ITEMMAST",open_opts$[11]="OTA@"
	open_tables$[12]="IVM_ITEMWHSE",open_opts$[12]="OTA@"
	open_tables$[13]="IVC_WHSECODE",open_opts$[13]="OTA@"

	gosub open_tables

	sfs_params_dev=num(open_chans$[1]),sfs_params_tpl$=open_tpls$[1]
	ivs_params_dev=num(open_chans$[2]),ivs_params_tpl$=open_tpls$[2]

rem --- Get SF parameters
	dim sfs_params$:sfs_params_tpl$
	read record (sfs_params_dev,key=firm_id$+"SF00",dom=std_missing_params) sfs_params$
	po$=sfs_params.po_interface$
	gl$=sfs_params.post_to_gl$

	if po$="Y" then
		call stbl("+DIR_PGM")+"adc_application.aon","PO",info$[all]
		po$=info$[20]
	endif
	callpoint!.setDevObject("po",po$)

	if gl$="Y" then
		gl$="N"
		status=0
		source$=pgm(-2)
		call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"SF",glw11$,gl$,status
		if status<>0 goto std_exit
	endif
	callpoint!.setDevObject("gl",gl$)

rem --- Get IV parameters
	dim ivs_params$:ivs_params_tpl$
	read record (ivs_params_dev,key=firm_id$+"IV00",dom=std_missing_params) ivs_params$
	lotser$=ivs_params.lotser_flag$
	callpoint!.setDevObject("lotser",lotser$)
	precision$=ivs_params.precision$
	callpoint!.setDevObject("precision",precision$)
	precision num(precision$)
	cost_method$=ivs_params.cost_method$
	callpoint!.setDevObject("cost_method",cost_method$)

rem --- Additional file opens
	num_files=4
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	if po$="Y" then
		open_tables$[1]="POE_REQDET",open_opts$[1]="OTA@"
		open_tables$[2]="POE_PODET",open_opts$[2]="OTA@"
	endif
	if pos(lotser$="LS") then
		open_tables$[3]="IVM_LSMASTER",open_opts$[3]="OTA@"
	endif
	if gl$="Y" then
		open_tables$[4]="GLS_PARAMS",open_opts$[4]="OTA@"
	endif

	gosub open_tables

	if gl$="Y" then
		rem --- Get GL period start date for current SF period
		gls_params_dev=num(open_chans$[4])
		call stbl("+DIR_PGM")+"adc_perioddates.aon",gls_params_dev,num(sfs_params.current_per$),num(sfs_params.current_year$),beg_date$,end_date$,status
		callpoint!.setDevObject("gl_beg_date",beg_date$)
	endif
