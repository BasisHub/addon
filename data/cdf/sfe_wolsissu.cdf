[[SFE_WOLSISSU.QTY_ISSUED.BINP]]
rem --- Disable lot/serial lookup except in lotser_no field
	callpoint!.setOptionEnabled("LLOK",0)
[[SFE_WOLSISSU.AGRE]]
rem --- Do not commit if row has been deleted
	if callpoint!.getGridRowDeleteStatus(callpoint!.getValidationRow())="Y" then
		rem --- row has been deleted, so do not commit inventory
		break
	endif

rem --- Do not commit unless lot/serial number or quantity issued has changed!
rem --- sfe_wolsissu only gets written on save (Barista bug 4419), so can exit row multiple times before sfe_wolsissu gets written.
	start_lotser_no$=callpoint!.getDevObject("start_lotser_no")
	start_qty_issued=num(callpoint!.getDevObject("start_qty_issued"))
 	lotser_no$=callpoint!.getColumnData("SFE_WOLSISSU.LOTSER_NO")
 	qty_issued=num(callpoint!.getColumnData("SFE_WOLSISSU.QTY_ISSUED"))
	if lotser_no$=start_lotser_no$ and qty_issued=start_qty_issued then
		rem --- lotser_no and qty_issued have not changed, so do not commit inventory
		break
	endif
    
rem --- Initialize inventory item update
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

rem --- Backout starting commitments unless none
	if cvs(start_lotser_no$,2)<>"" then
		rem --- Uncommit starting lot/serial
		items$[1]=callpoint!.getDevObject("warehouse_id")
		items$[2]=callpoint!.getDevObject("item_id")
		items$[3]=start_lotser_no$
		refs[0]=start_qty_issued
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

		rem --- Recommit item since got uncommitted with lot/serial
		items$[3]=" "
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
	endif

rem --- Make new commitments
	rem --- Commit lot/serial
	items$[1]=callpoint!.getDevObject("warehouse_id")
	items$[2]=callpoint!.getDevObject("item_id")
	items$[3]=lotser_no$
	refs[0]=qty_issued
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

	rem --- Uncommit item since got recommitted with lot/serial
	items$[3]=" "
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
[[SFE_WOLSISSU.<CUSTOM>]]
init_cols: rem ---  Init grid columns
	rem --- Init the Item ID
	callpoint!.setColumnData("<<DISPLAY>>.ITEM_ID",str(callpoint!.getDevObject("item_id")),1)

	rem ---  Init qty_issued
	if callpoint!.getDevObject("lotser")="S" then 
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"SFE_WOLSISSU.QTY_ISSUED",0)
	else
		callpoint!.setColumnEnabled(num(callpoint!.getValidationRow()),"SFE_WOLSISSU.QTY_ISSUED",1)
	endif
	return

get_tot_ls_qty_issued: rem --- Get total lot/serial issued quantity and total issue cost
	sfe_wolsissu_dev=fnget_dev("SFE_WOLSISSU")
	dim sfe_wolsissu$:fnget_tpl$("SFE_WOLSISSU")
	tot_ls_qty_issued=0
	tot_ls_issue_cost=0
	firm_loc_wo_isn$=callpoint!.getDevObject("firm_loc_wo_isn")
	read(sfe_wolsissu_dev,key=firm_loc_wo_isn$,dom=*next)
	while 1
		sfe_wolsissu_key$=key(sfe_wolsissu_dev,end=*break)
		if pos(firm_loc_wo_isn$=sfe_wolsissu_key$)<>1 then break
		readrecord(sfe_wolsissu_dev)sfe_wolsissu$
		tot_ls_qty_issued=tot_ls_qty_issued+sfe_wolsissu.qty_issued
		tot_ls_issue_cost=tot_ls_issue_cost+sfe_wolsissu.qty_issued*sfe_wolsissu.issue_cost
	wend
	callpoint!.setDevObject("tot_ls_qty_issued",tot_ls_qty_issued)
	callpoint!.setDevObject("tot_ls_issue_cost",tot_ls_issue_cost)
	return
[[SFE_WOLSISSU.LOTSER_NO.BINP]]
rem --- Init the Item ID
	callpoint!.setColumnData("<<DISPLAY>>.ITEM_ID",str(callpoint!.getDevObject("item_id")),1)

rem --- Enable lookup for new lot/serials
	if cvs(callpoint!.getColumnData("SFE_WOLSISSU.LOTSER_NO"),2)="" then
		callpoint!.setOptionEnabled("LLOK",1)
	else
		callpoint!.setOptionEnabled("LLOK",0)
	endif
[[SFE_WOLSISSU.AGDR]]
rem ---  Init grid columns
	gosub init_cols
[[SFE_WOLSISSU.AREC]]
rem --- Hold on to starting lotser_no and qty_issued for this line so we can determine if committments are needed.
rem --- sfe_wolsissu only gets written on save (Barista bug 4419), so can exit row multiple times before sfe_wolsissu gets written.
	start_lotser_no$=callpoint!.getColumnData("SFE_WOLSISSU.LOTSER_NO")
	start_qty_issued=num(callpoint!.getColumnData("SFE_WOLSISSU.QTY_ISSUED"))
	callpoint!.setDevObject("start_lotser_no",start_lotser_no$)
	callpoint!.setDevObject("start_qty_issued",start_qty_issued)

rem --- Init how many lot/serial items are left to issue
	tot_ls_qty_issued=num(callpoint!.getDevObject("tot_ls_qty_issued"))
	womatisd_qty_issued=num(callpoint!.getDevObject("womatisd_qty_issued"))
	callpoint!.setDevObject("left_to_issue",womatisd_qty_issued-tot_ls_qty_issued)

rem ---  Init grid columns
	gosub init_cols
[[SFE_WOLSISSU.LOTSER_NO.AVAL]]
rem --- lotser_no is disabled except for a new row, so can init entire new row here.
	lotser_no$=callpoint!.getUserInput()
	if lotser_no$=callpoint!.getColumnData("SFE_WOLSISSU.LOTSER_NO") then
		rem --- Do not re-init if user returns to lotser_no field on a new row
		break
	endif

rem --- Validate this lot/serial number and get data
	item_id$=callpoint!.getDevObject("item_id")
	warehouse_id$=callpoint!.getDevObject("warehouse_id")
	ivm_lsmaster_dev=fnget_dev("IVM_LSMASTER")
	dim ivm_lsmaster$:fnget_tpl$("IVM_LSMASTER")
	findrecord(ivm_lsmaster_dev,key=firm_id$+warehouse_id$+item_id$+lotser_no$,dom=*next)ivm_lsmaster$
	if ivm_lsmaster.lotser_no$<>lotser_no$ then
		msg_id$="IV_SERLOT_NOT_FOUND"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Reset quantity left_to_issue and tot_ls_qty_issued if lotser_no changed on new row
	qty_issued=num(callpoint!.getColumnData("SFE_WOLSISSU.QTY_ISSUED"))
	left_to_issue=num(callpoint!.getDevObject("left_to_issue"))
	tot_ls_qty_issued=num(callpoint!.getDevObject("tot_ls_qty_issued"))
	callpoint!.setDevObject("left_to_issue",left_to_issue+qty_issued)
	callpoint!.setDevObject("tot_ls_qty_issued",tot_ls_qty_issued-qty_issued)

rem --- Init issued quantity to quantity left to issue
	tot_ls_qty_issued=num(callpoint!.getDevObject("tot_ls_qty_issued"))
	womatisd_qty_issued=num(callpoint!.getDevObject("womatisd_qty_issued"))
	if callpoint!.getDevObject("lotser")="S" then
		if womatisd_qty_issued<0 then
			wolsissu_qty_issued=-1
		else
			wolsissu_qty_issued=1
		endif
	else
		wolsissu_qty_issued=womatisd_qty_issued-tot_ls_qty_issued
	endif

rem --- Can't return serialized item if it's already on hand.
	if wolsissu_qty_issued<0 and callpoint!.getDevObject("lotser")="S" and ivm_lsmaster.qty_on_hand<>0 then
		msg_id$="SF_SERIAL_ON_HAND"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Enough on hand?
	if ivm_lsmaster.qty_on_hand<ivm_lsmaster.qty_commit or ivm_lsmaster.qty_on_hand=0 then
		msg_id$="SF_QTY_NOT_AVAIL"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Don't issue more than are available
	if wolsissu_qty_issued>ivm_lsmaster.qty_on_hand-ivm_lsmaster.qty_commit then
		wolsissu_qty_issued=ivm_lsmaster.qty_on_hand-ivm_lsmaster.qty_commit
	endif

rem --- Set issue cost and quantity issued
	callpoint!.setColumnData("SFE_WOLSISSU.ISSUE_COST",str(ivm_lsmaster.unit_cost),1)
	callpoint!.setColumnData("SFE_WOLSISSU.QTY_ISSUED",str(wolsissu_qty_issued),1)

rem --- Update quantity left_to_issue and tot_ls_qty_issued
	left_to_issue=num(callpoint!.getDevObject("left_to_issue"))
	callpoint!.setDevObject("left_to_issue",left_to_issue-wolsissu_qty_issued)
	callpoint!.setDevObject("tot_ls_qty_issued",tot_ls_qty_issued+wolsissu_qty_issued)
[[SFE_WOLSISSU.AOPT-LLOK]]
rem --- Do lot/serial lookup
	warehouse_id$     = callpoint!.getDevObject("warehouse_id")
	item_id$   = callpoint!.getDevObject("item_id")
	womatisd_qty_issued=num(callpoint!.getDevObject("womatisd_qty_issued"))

	dim dflt_data$[3,1]
	dflt_data$[1,0] = "ITEM_ID"
	dflt_data$[1,1] = item_id$
	dflt_data$[2,0] = "WAREHOUSE_ID"
	dflt_data$[2,1] = warehouse_id$
	dflt_data$[3,0] = "LOTS_TO_DISP"
	if womatisd_qty_issued >= 0 then
		dflt_data$[3,1] = "O"; rem --- open lots for issues
	else
		dflt_data$[3,1] = "C"; rem --- closed lots for returns 
	endif

	rem --- Call IVC_LOTLOOKUP form
	rem ---     returns: devObject("selected_lot")         : The lot/serial# selected for this item
	rem ---                   devObject("selected_lot_avail"): The amount select for this lot, or 1 for serial#
	rem ---                   devObject("selected_lot_cost") : The cost of the selected lot
	call stbl("+DIR_SYP")+"bam_run_prog.bbj","IVC_LOTLOOKUP",stbl("+USER_ID"),"","",table_chans$[all],"",dflt_data$[all]

rem --- Verify lot/serial available qty
	if callpoint!.getDevObject("selected_lot") <> null() then 
		selected_lot$ = str(callpoint!.getDevObject("selected_lot"))
		selected_lot_avail = num(callpoint!.getDevObject("selected_lot_avail"))
		selected_lot_cost = num(callpoint!.getDevObject("selected_lot_cost"))
			
		if selected_lot_avail=0 and womatisd_qty_issued>0 then
			if callpoint!.getDevObject("lotser") = "S" then
				lot_ser$ = Translate!.getTranslation("AON_SERIAL_NUMBER")
			else
				lot_ser$ = Translate!.getTranslation("AON_LOT")
			endif
			msg_id$ = "OP_LOT_NONE_AVAIL"
			dim msg_tokens$[1]
			msg_tokens$[1] = lot_ser$
			gosub disp_message
			break; rem --- exit callpoint
		endif

		rem --- Update grid with selected lot/serial info
		tot_ls_qty_issued=num(callpoint!.getDevObject("tot_ls_qty_issued"))
		left_to_issue=num(callpoint!.getDevObject("left_to_issue"))
		qty_issued=min( abs(selected_lot_avail), abs(left_to_issue) ) * sgn(womatisd_qty_issued)
		callpoint!.setDevObject("left_to_issue",left_to_issue-qty_issued)
		callpoint!.setDevObject("tot_ls_qty_issued",tot_ls_qty_issued+qty_issued)
		callpoint!.setColumnData( "SFE_WOLSISSU.LOTSER_NO", selected_lot$,1)
		callpoint!.setColumnData("SFE_WOLSISSU.QTY_ISSUED", str(qty_issued),1)
		callpoint!.setColumnData("SFE_WOLSISSU.ISSUE_COST", str(selected_lot_cost),1)

		rem --- setFocus back on lotser_no field
		callpoint!.setFocus("SFE_WOLSISSU.LOTSER_NO")
		callpoint!.setStatus("MODIFIED")
	endif
[[SFE_WOLSISSU.QTY_ISSUED.AVAL]]
rem --- Nothing to do if qty_issued hasn't changed
	qty_issued=num(callpoint!.getUserInput())
	prev_qty_issued=num(callpoint!.getColumnData("SFE_WOLSISSU.QTY_ISSUED"))
	if qty_issued=prev_qty_issued then
		rem --- No need to validate qty_issued, nor update quantity left_to_issue and tot_ls_qty_issued
		break
	endif


rem --- Get data for this lot/serial number
	lotser_no$=callpoint!.getColumnData("SFE_WOLSISSU.LOTSER_NO")
	item_id$=callpoint!.getDevObject("item_id")
	warehouse_id$=callpoint!.getDevObject("warehouse_id")
	ivm_lsmaster_dev=fnget_dev("IVM_LSMASTER")
	dim ivm_lsmaster$:fnget_tpl$("IVM_LSMASTER")
	findrecord(ivm_lsmaster_dev,key=firm_id$+warehouse_id$+item_id$+lotser_no$)ivm_lsmaster$

rem --- Verify quantiy available
	if qty_issued>0 and qty_issued>ivm_lsmaster.qty_on_hand-ivm_lsmaster.qty_commit then
		msg_id$="SF_QTY_NOT_AVAIL"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Update quantity left_to_issue and tot_ls_qty_issued
	left_to_issue=num(callpoint!.getDevObject("left_to_issue"))
	tot_ls_qty_issued=num(callpoint!.getDevObject("tot_ls_qty_issued"))
	callpoint!.setDevObject("left_to_issue",left_to_issue+prev_qty_issued-qty_issued)
	callpoint!.setDevObject("tot_ls_qty_issued",tot_ls_qty_issued-prev_qty_issued+qty_issued)
[[SFE_WOLSISSU.AGRN]]
rem --- Hold on to starting lotser_no and qty_issued for this line so we can determine if committments are needed.
rem --- sfe_wolsissu only gets written on save (Barista bug 4419), so can exit row multiple times before sfe_wolsissu gets written.
	start_lotser_no$=callpoint!.getColumnData("SFE_WOLSISSU.LOTSER_NO")
	start_qty_issued=num(callpoint!.getColumnData("SFE_WOLSISSU.QTY_ISSUED"))
	callpoint!.setDevObject("start_lotser_no",start_lotser_no$)
	callpoint!.setDevObject("start_qty_issued",start_qty_issued)

rem --- Init how many lot/serial items are left to issue
	tot_ls_qty_issued=num(callpoint!.getDevObject("tot_ls_qty_issued"))
	womatisd_qty_issued=num(callpoint!.getDevObject("womatisd_qty_issued"))
	callpoint!.setDevObject("left_to_issue",womatisd_qty_issued-tot_ls_qty_issued)

rem --- Set focus on lotser_no unless lotted and an existing row (i.e. previously saved)
	if callpoint!.getDevObject("lotser")="L" and callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then
		rem --- Set focus on qty_issued
		callpoint!.setFocus(num(callpoint!.getValidationRow()),"SFE_WOLSISSU.QTY_ISSUED")
	else
		rem --- Set focus on lotser_no
		callpoint!.setFocus(num(callpoint!.getValidationRow()),"SFE_WOLSISSU.LOTSER_NO")
	endif
[[SFE_WOLSISSU.AUDE]]
rem --- NOTE: sfe_wolsissu row only gets written on save (Barista bug 4419), but AGRE updates inventory on row exit

rem --- Make sure undeleted row gets written to file
	callpoint!.setStatus("MODIFIED")

rem --- Commit starting lot/serial and quantity issued unless none
	start_lotser_no$=callpoint!.getDevObject("start_lotser_no")
	start_qty_issued=num(callpoint!.getDevObject("start_qty_issued"))
	if cvs(start_lotser_no$,2)<>"" then
		rem --- Initialize inventory item update
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

		rem --- Commit starting lot/serial
		items$[1]=callpoint!.getDevObject("warehouse_id")
		items$[2]=callpoint!.getDevObject("item_id")
		items$[3]=start_lotser_no$
		refs[0]=start_qty_issued
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

		rem --- Uncommit item since got recommitted with lot/serial
		items$[3]=" "
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
	endif

rem --- Update quantity left_to_issue and tot_ls_qty_issued
	left_to_issue=num(callpoint!.getDevObject("left_to_issue"))
	tot_ls_qty_issued=num(callpoint!.getDevObject("tot_ls_qty_issued"))
	callpoint!.setDevObject("left_to_issue",left_to_issue-start_qty_issued)
	callpoint!.setDevObject("tot_ls_qty_issued",tot_ls_qty_issued+start_qty_issued)
[[SFE_WOLSISSU.BEND]]
rem --- Have enough lot/serials been entered?
	tot_ls_qty_issued=num(callpoint!.getDevObject("tot_ls_qty_issued"))
	womatisd_qty_issued=num(callpoint!.getDevObject("womatisd_qty_issued"))
	if tot_ls_qty_issued<womatisd_qty_issued then
		if callpoint!.getDevObject("lotser") = "S" then
			lot_ser$ = Translate!.getTranslation("AON_SERIAL_NUMBER")
		else
			lot_ser$ = Translate!.getTranslation("AON_LOT")
		endif
		msg_id$ = "SF_TOO_FEW_LS"
		dim msg_tokens$[3]
		msg_tokens$[1] = lot_ser$
		msg_tokens$[2] = str(tot_ls_qty_issued)
		msg_tokens$[3] = str(womatisd_qty_issued)
		gosub disp_message
		if msg_opt$="C"
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

rem --- Have too many lot/serials been entered?
	if tot_ls_qty_issued>womatisd_qty_issued then
		if callpoint!.getDevObject("lotser") = "S" then
			lot_ser$ = Translate!.getTranslation("AON_SERIAL_NUMBER")
		else
			lot_ser$ = Translate!.getTranslation("AON_LOT")
		endif
		msg_id$ = "SF_TOO_MANY_LS"
		dim msg_tokens$[3]
		msg_tokens$[1] = lot_ser$
		msg_tokens$[2] = str(tot_ls_qty_issued)
		msg_tokens$[3] = str(womatisd_qty_issued)
		gosub disp_message
		if msg_opt$="C"
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

rem --- Set total lot/serial issued quantity and total issue cost
	gosub get_tot_ls_qty_issued
[[SFE_WOLSISSU.BDEL]]
rem --- NOTE: sfe_wolsissu row only gets written on save (Barista bug 4419), but AGRE updates inventory on row exit

rem --- Backout starting commitments unless none
	start_lotser_no$=callpoint!.getDevObject("start_lotser_no")
	start_qty_issued=num(callpoint!.getDevObject("start_qty_issued"))
if cvs(start_lotser_no$,2)<>"" then
		rem --- Initialize inventory item update
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

		rem --- Uncommit starting lot/serial
		items$[1]=callpoint!.getDevObject("warehouse_id")
		items$[2]=callpoint!.getDevObject("item_id")
		items$[3]=start_lotser_no$
		refs[0]=start_qty_issued
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

		rem --- Recommit item since got uncommitted with lot/serial
		items$[3]=" "
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
endif

rem --- Update quantity left_to_issue and tot_ls_qty_issued
	qty_issued=num(callpoint!.getColumnData("SFE_WOLSISSU.QTY_ISSUED"))
	left_to_issue=num(callpoint!.getDevObject("left_to_issue"))
	tot_ls_qty_issued=num(callpoint!.getDevObject("tot_ls_qty_issued"))
	callpoint!.setDevObject("left_to_issue",left_to_issue+qty_issued)
	callpoint!.setDevObject("tot_ls_qty_issued",tot_ls_qty_issued-qty_issued)
[[SFE_WOLSISSU.BSHO]]
rem --- Set STBLs needed for lot/serial file validation
	x$=stbl("+WAREHOUSE_ID",callpoint!.getDevObject("warehouse_id"))
	x$=stbl("+ITEM_ID",callpoint!.getDevObject("item_id"))

rem --- Init lot/serial button
	switch pos(callpoint!.getDevObject("lotser")="LS")
		case 1
			callpoint!.setOptionText("LLOK",Translate!.getTranslation("AON_LOT_LOOKUP"))
			break
		case 2
			callpoint!.setOptionText("LLOK",Translate!.getTranslation("AON_SERIAL_LOOKUP"))
			break
		case default
			callpoint!.setOptionEnabled("LLOK",0)
			break
	swend

rem --- Init how many lot/serial items issued already
	gosub get_tot_ls_qty_issued
