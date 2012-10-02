[[OPE_ORDLSDET.AGRN]]
rem --- keep track of starting qty for this line, so we can accurately check avail qty minus what's already been committed

	user_tpl.prev_ord = num(callpoint!.getColumnData("OPE_ORDLSDET.QTY_ORDERED"))
[[OPE_ORDLSDET.AUDE]]
print "AUDE"; rem debug

rem --- Re-commit lot/serial if undeleting an existing (not new) row

	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then

	rem --- Initialize inventory item update

		status=999
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
		if status then exitto std_exit

		commit_lot$ = callpoint!.getColumnUndoData("OPE_ORDLSDET.LOTSER_NO")
		commit_qty  = num(callpoint!.getColumnUndoData("OPE_ORDLSDET.QTY_ORDERED"))
		increasing  = 1

		gosub commit_lots

	rem --- Take out left to order

		user_tpl.left_to_ord = user_tpl.left_to_ord - commit_qty

	endif
[[OPE_ORDLSDET.BDEL]]
print "BDEL"; rem debug

rem --- If not a new row, uncommit the lot/serial

	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then

	rem --- Initialize inventory item update

		status=999
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
		if status then exitto std_exit

		commit_lot$ = callpoint!.getColumnUndoData("OPE_ORDLSDET.LOTSER_NO")
		commit_qty  = num(callpoint!.getColumnUndoData("OPE_ORDLSDET.QTY_ORDERED"))
		increasing  = 0
		gosub commit_lots

	rem --- Put back left to order

		user_tpl.left_to_ord = user_tpl.left_to_ord + commit_qty

	endif
[[OPE_ORDLSDET.QTY_ORDERED.AVAL]]
print "QTY_ORDERED.AVAL"; rem debug

rem ---- If serial (as opposed to lots), qty must be 1 ot -1

	qty_ordered = num(callpoint!.getUserInput())
	gosub there_can_be_only_one

	if aborted then 
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

	print "---Not aborted"; rem debug

rem --- Update qty left to order

	print "---Left to Ord:", user_tpl.left_to_ord; rem debug
	print "---Qty Ordered:", qty_ordered; rem debug
	print "---Prev Qty   :", user_tpl.prev_ord; rem debug
	print "---left + prev - ordered "; rem debug
	user_tpl.left_to_ord = user_tpl.left_to_ord + user_tpl.prev_ord - qty_ordered 
	print "---Qty left to ord:", user_tpl.left_to_ord; rem debug

rem --- Set shipped default

	callpoint!.setTableColumnAttribute("OPE_ORDLSDET.QTY_SHIPPED","DFLT", str(qty_ordered))
	callpoint!.setColumnData("OPE_ORDLSDET.QTY_ORDERED", str(qty_ordered))
	print "---Setting both default and qty shipped:", qty_ordered; rem debug
	callpoint!.setStatus("REFRESH")
	print "---REFRESH"; rem debug
[[OPE_ORDLSDET.AGRE]]
print "AGRE"; rem debug

rem --- Check quantities, do commits if this row isn't deleted

	if callpoint!.getGridRowDeleteStatus( callpoint!.getValidationRow() ) <> "Y" and
:		cvs( callpoint!.getColumnData("OPE_ORDLSDET.LOTSER_NO"), 3)        <> "" 
:	then

	rem --- Check if Serial and validate quantity

		qty_shipped = num(callpoint!.getColumnData("OPE_ORDLSDET.QTY_SHIPPED"))
		qty_ordered = num(callpoint!.getColumnData("OPE_ORDLSDET.QTY_ORDERED"))

		gosub valid_quantities
		if aborted then break; rem --- exit callpoint

	rem --- Now check for Sales Line quantity

		if callpoint!.getGridRowNewStatus( callpoint!.getValidationRow() )    = "Y" or
:		   callpoint!.getGridRowModifyStatus( callpoint!.getValidationRow() ) = "Y" 
:		then
			line_qty = num(callpoint!.getDevObject("ord_qty"))
			lot_qty  = qty_ordered

			gosub check_avail
			if aborted then break; rem --- exit callpoint
		endif

	rem --- Commit lots if inventoried and not a dropship or quote
	rem --- Set 'increasing' to 0 if uncommitting prev lot/committing new one, or 1 if just doing new one

		if callpoint!.getDevObject("invoice_type")  <> "P" and 
:			callpoint!.getDevObject("dropship_line") <> "Y" and 
:			callpoint!.getDevObject("inventoried")   =  "Y"
:		then

		rem --- Get current and prior values

			curr_lot$ = callpoint!.getColumnData("OPE_ORDLSDET.LOTSER_NO")
			curr_qty  = num(callpoint!.getColumnData("OPE_ORDLSDET.QTY_ORDERED"))

			prior_lot$ = callpoint!.getColumnUndoData("OPE_ORDLSDET.LOTSER_NO")
			prior_qty  = num(callpoint!.getColumnUndoData("OPE_ORDLSDET.QTY_ORDERED"))

		rem --- Has there been any change?

			if curr_lot$ <> prior_lot$ or curr_qty <> prior_qty then

			rem --- Initialize inventory item update

				status=999
				call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				if status then exitto std_exit

			rem --- Uncommit prior amount

				if cvs(prior_lot$,3)<>"" and prior_qty then
					commit_lot$ = prior_lot$
					commit_qty  = prior_qty
					increasing=0
					gosub commit_lots
				endif

			rem --- Commit current amount

				commit_lot$ = curr_lot$
				commit_qty  = curr_qty 
				increasing=1
				gosub commit_lots

				committedNow!.put(commit_lot$, commit_qty)
				callpoint!.setDevObject("committed_now", CommittedNow!)
			endif
		endif
	endif
 
[[OPE_ORDLSDET.BEND]]
print "BEND"; rem debug

rem --- Check total quantity from all lines against ordered quantity and shipped

	declare BBjVector GridVect!

	lot_qty  = 0
	lot_ship = 0
	line_qty = num(callpoint!.getDevObject("ord_qty"))
	aborted  = 0

	dim gridrec$:fattr(rec_data$)
	numrecs = GridVect!.size()

	if numrecs>0 then 
		for reccnt=0 to numrecs-1
			gridrec$ = str(GridVect!.getItem(reccnt))

			if cvs(gridrec$,3) <> "" and callpoint!.getGridRowDeleteStatus(reccnt) <> "Y" then 

			rem --- Check if Serial and validate quantity

				qty_shipped = gridrec.qty_shipped
				qty_ordered = gridrec.qty_ordered
				gosub valid_quantities
				if aborted then break

			rem --- Check available

				if callpoint!.getGridRowNewStatus(reccnt)    = "Y" or
:				   callpoint!.getGridRowModifyStatus(reccnt) = "Y" 
:				then
					lot_qty  = qty_ordered
					gosub check_avail
					if aborted then break
				endif

			rem --- Total lines

				lot_qty  = lot_qty  + gridrec.qty_ordered
				lot_ship = lot_ship + gridrec.qty_shipped
			endif
		next reccnt

		if aborted then break; rem --- exit callpoint
	endif

rem --- Warn that selected lot/serial#'s does not match order qty

	if lot_qty <> num(callpoint!.getDevObject("ord_qty")) then 
		msg_id$ = "OP_LOT_QTY_UNEQUAL"
		dim msg_tokens$[3]
		msg_tokens$[1] = str(lot_qty)

		if callpoint!.getDevObject("lotser_flag") = "L" then 
			msg_tokens$[2] = Translate!.getTranslation("AON_LOT_NUMBERS")
		else
			msg_tokens$[2] = Translate!.getTranslation("AON_SERIAL_NUMBERS")
		endif

		msg_tokens$[3] = str(callpoint!.getDevObject("ord_qty"))
		gosub disp_message
		callpoint!.setDevObject("total_shipped","0")
		break
	endif

rem --- Send back qty shipped

	print "---Setting DevObject total_shipped:", lot_ship; rem debug
	callpoint!.setDevObject("total_shipped", str(lot_ship))
[[OPE_ORDLSDET.<CUSTOM>]]
rem ==========================================================================
check_avail: rem --- Check for available quantity
             rem      IN: line_qty 
	          rem          lot_qty 
	          rem    OUT:  aborted - true/false
             rem          committedNow!
rem ==========================================================================

	aborted = 0
	wh$     = callpoint!.getDevObject("wh")
	item$   = callpoint!.getDevObject("item")
	ls_no$  = callpoint!.getColumnData("OPE_ORDLSDET.LOTSER_NO")

	file_name$ = "IVM_LSMASTER"
	lsmast_dev = fnget_dev(file_name$)
	dim lsmast_tpl$:fnget_tpl$(file_name$)
	start_block = 1

	if start_block then
		read record (lsmast_dev, key=firm_id$+wh$+item$+ls_no$, dom=*endif) lsmast_tpl$
		committedNow! = cast(HashMap, callpoint!.getDevObject("committed_now"))

		if committedNow!.containsKey(ls_no$) then
			commtd_now = num(committedNow!.get(ls_no$))
		else
			commtd_now = 0
		endif

		if lot_qty >= 0 and lot_qty > lsmast_tpl.qty_on_hand - lsmast_tpl.qty_commit + commtd_now then
			dim msg_tokens$[1]
			msg_tokens$[1] = str(lsmast_tpl.qty_on_hand - lsmast_tpl.qty_commit + commtd_now)
			msg_id$ = "IV_QTY_OVER_AVAIL"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			aborted=1
		endif
	endif

	return

rem ==========================================================================
there_can_be_only_one: rem --- Serial#'s can only have a quantity of 1 or -1
                       rem      IN: qty_ordered
rem ==========================================================================

	print "in there_can_be_only_one..."; rem debug
	aborted = 0

	if callpoint!.getDevObject("lotser_flag") = "S" and abs(qty_ordered) <> 1 then 
		msg_id$ = "IV_SERIAL_ONE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		aborted = 1
		print "---Aborted:", aborted; rem debug
	endif

	print "back"; rem debug

	return

rem ==========================================================================
valid_quantities: rem --- Validate Quantities
                  rem       IN: qty_shipped
                  rem           qty_ordered
                  rem      OUT: aborted - true/false
rem ==========================================================================

	gosub there_can_be_only_one

	if !aborted then

	rem --- Ship Qty must be <= Order Qty

		if abs(qty_ordered) < abs(qty_shipped) then 
			msg_id$ = "SHIP_EXCEEDS_ORD"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			aborted = 1
		endif
	endif

	return

rem ==========================================================================
commit_lots: rem --- Commit lots
             rem      IN: commit_lot$
             rem          commit_qty
             rem          increasing - 0/1 to back out old/commit new
             rem     OUT: committedNow!
rem ==========================================================================

rem --- This routine uncommits warehouse (since already committed when entering detail line)
rem --- then re-commits warehouse and commits lot/serial master

	print "in commit_lots..."; rem debug
	wh$   = callpoint!.getDevObject("wh")
	item$ = callpoint!.getDevObject("item")

	items$[1] = wh$
	items$[2] = item$
	items$[3] = ""
	refs[0]   = commit_qty

	if increasing then action$="UC" else action$="OE" 
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon",action$,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
	if status then exitto std_exit

	items$[3]=commit_lot$

	if increasing then action$="OE" else action$="UC" 
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon",action$,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
	if status then exitto std_exit

rem --- Keep track of what's been committed this session

	committedNow! = cast(HashMap, callpoint!.getDevObject("committed_now"))

	if committedNow!.containsKey(commit_lot$) then	
		commtd_now = num(committedNow!.get(commit_lot$))
	else
		commtd_now = 0
	endif

	if increasing then
		commtd_now = commtd_now + commit_qty
	else
		commtd_now = commtd_now - commit_qty
	endif

	committedNow!.put(commit_lot$, commtd_now)
	print "back"; rem debug

	return
[[OPE_ORDLSDET.BSHO]]
print "BSHO"; rem debug

rem --- Inits

	use java.util.HashMap

	declare HashMap committedNow!

	dim user_tpl$:"invoice_noninventory:u(1), left_to_ord:n(1*), prev_ord:n(1*)"
	user_tpl.invoice_noninventory = 0
	user_tpl.left_to_ord = num(callpoint!.getDevObject("ord_qty"))
	user_tpl.prev_ord = 0

rem --- Set Lot/Serial button up properly

	switch pos(callpoint!.getDevObject("lotser_flag")="LS")
		case 1; callpoint!.setOptionText("LLOK",Translate!.getTranslation("AON_LOT_LOOKUP")); break
		case 2; callpoint!.setOptionText("LLOK",Translate!.getTranslation("AON_SERIAL_LOOKUP")); break
		case default; callpoint!.setOptionEnabled("LLOK",0); break
	swend

rem --- Set a flag for non-inventoried items when in Invoice Entry
	
	item$ = callpoint!.getDevObject("item")

	if callpoint!.getDevObject("from") = "invoice_entry" 
		file_name$="IVM_ITEMMAST"
		dim itemmast_rec$:fnget_tpl$(file_name$)
		find record (fnget_dev(file_name$), key=firm_id$+item$, dom=*endif) itemmast_rec$
		if itemmast_rec.inventoried$ = "N" then user_tpl.invoice_noninventory = 1
	endif

rem --- No Serial/lot lookup for non-invent items
	
	if user_tpl.invoice_noninventory then callpoint!.setOptionEnabled("LLOK", 0)

rem --- Create a HashMap so that we know what's been committed during this session

	declare HashMap committedNow!
	committedNow! = new HashMap()
	callpoint!.setDevObject("committed_now", committedNow!)
[[OPE_ORDLSDET.AOPT-LLOK]]
print "AOPT.LLOK"; rem debug

rem --- Non-inventoried items from Invoice Entry do not have to exist

	if user_tpl.invoice_noninventory then
		break; rem --- exit callpoint
	endif

rem --- Set data for the lookup form

	wh$     = callpoint!.getDevObject("wh")
	item$   = callpoint!.getDevObject("item")
	ord_qty = num( callpoint!.getDevObject("ord_qty") )
	lsmast_dev = fnget_dev("IVM_LSMASTER")

rem --- See if there are any open lots

	read (lsmast_dev, key=firm_id$+wh$+item$+" ", knum="AO_WH_ITM_FLAG", dom=*next)
	lsmast_key$=key(lsmast_dev, end=*next)

	if pos(firm_id$+wh$+item$+" " = lsmast_key$) = 1 then
		dim dflt_data$[3,1]
		dflt_data$[1,0] = "ITEM_ID"
		dflt_data$[1,1] = item$
		dflt_data$[2,0] = "WAREHOUSE_ID"
		dflt_data$[2,1] = wh$
		dflt_data$[3,0] = "LOTS_TO_DISP"

		if ord_qty > 0 then
			dflt_data$[3,1] = "O"; rem --- default to open lots
		else
			dflt_data$[3,1] = "C"; rem --- closed lots for returns 
		endif

	rem --- Call the lookup form
	rem      IN: call/enter list
	rem     OUT: DevObject("selected_lot")      : The lot/serial# selected for this item
	rem          DevObject("selected_lot_avail"): The amount select for this lot, or 1 for serial#
	rem          DevObject("selected_lot_cost") : The cost of the selected lot

		print "---call IVC_LOTLOOKUP..."; rem debug
		call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:			"IVC_LOTLOOKUP",
:			stbl("+USER_ID"),
:			"",
:			"",
:			table_chans$[all],
:			"",
:			dflt_data$[all]
		print "---back from IVC_LOTLOOKUP..."; rem debug

	rem --- Test lot and available qty

		if callpoint!.getDevObject("selected_lot") <> null() then 
			ls_no$ = str(callpoint!.getDevObject("selected_lot"))
			committedNow! = cast(HashMap, callpoint!.getDevObject("committed_now"))

			if callpoint!.getDevObject("lotser_flag") = "S" then
				lot_ser$ = Translate!.getTranslation("AON_SERIAL_NUMBER")
			else
				lot_ser$ = Translate!.getTranslation("AON_LOT")
			endif

			if committedNow!.containsKey(ls_no$) then
				msg_id$ = "OP_LOT_SELECTED"
				dim msg_tokens$[1]
				msg_tokens$[1] = lot_ser$
				gosub disp_message
				break; rem --- exit callpoint
			endif
			
			print "---lot selected..."; rem debug
			lot_avail = num(callpoint!.getDevObject("selected_lot_avail"))

			if !lot_avail and ord_qty > 0 then
				msg_id$ = "OP_LOT_NONE_AVAIL"
				dim msg_tokens$[1]
				msg_tokens$[1] = lot_ser$
				gosub disp_message
				break; rem --- exit callpoint
			endif

		rem --- Set the detail grid to the data selected in the lookup

			print "---lot qty available:", lot_avail; rem debug
			lot_cost = num(callpoint!.getDevObject("selected_lot_cost"))
			qty_ord  = min( abs(lot_avail), abs(user_tpl.left_to_ord) ) * sgn(ord_qty)

			callpoint!.setColumnData( "OPE_ORDLSDET.LOTSER_NO", ls_no$ )
			callpoint!.setColumnData( "OPE_ORDLSDET.QTY_ORDERED", str(qty_ord) )
			rem callpoint!.setTableColumnAttribute("OPE_ORDLSDET.QTY_SHIPPED","DFLT", str(qty_ord))
			print "---Set qty ord:", qty_ord; rem debug

			user_tpl.left_to_ord = ( abs(user_tpl.left_to_ord) - abs(qty_ord) ) * sgn(ord_qty)
			print "---Left to Ord:", user_tpl.left_to_ord; rem debug

			callpoint!.setColumnData("OPE_ORDLSDET.QTY_SHIPPED", str(qty_ord))
			print "---Set shipped:", qty_ord; rem debug

			callpoint!.setColumnData("OPE_ORDLSDET.UNIT_COST", str(lot_cost))
			callpoint!.setStatus("MODIFIED;REFRESH")
		endif

	else
		msg_id$="IV_NO_OPENLOTS"
		gosub disp_message
	endif
[[OPE_ORDLSDET.LOTSER_NO.AVAL]]
print "LOTSER_NO.AVAL"; rem debug

rem --- Get lot/serial record fields

	wh$     = callpoint!.getDevObject("wh")
	item$   = callpoint!.getDevObject("item")
 	ls_no$  = callpoint!.getUserInput()
	ord_qty = num( callpoint!.getDevObject("ord_qty") )


rem --- Non-inventoried items from Invoice Entry do not have to exist (but can't be blank)

	if user_tpl.invoice_noninventory then
		if cvs( callpoint!.getUserInput(), 2 ) = "" then
			msg_id$ = "IV_SERLOT_BLANK"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			valid_rec$ = "N"
			print "valid_rec$=",valid_rec$; rem debug
		endif

		unit_cost = num( callpoint!.getDevObject("unit_cost") )
		callpoint!.setColumnData("OPE_ORDLSDET.UNIT_COST", str(unit_cost))
		callpoint!.setStatus("MODIFIED;REFRESH")
		print "unit_cost=",unit_cost; rem debug
	endif

	if valid_rec$="N" then 
		break
	endif

	if user_tpl.invoice_noninventory then
		goto set_qty_defaults
	endif

rem --- Validate open lot number

	file_name$ = "IVM_LSMASTER"
	lsmast_dev = fnget_dev(file_name$)
	dim lsmast_tpl$:fnget_tpl$(file_name$)

	got_rec$ = "N"
	start_block = 1

	if start_block then
		read record (lsmast_dev, key=firm_id$+wh$+item$+ls_no$, dom=*endif) lsmast_tpl$
		got_rec$ = "Y"
	endif

	if got_rec$ = "N" then
		msg_id$ = "IV_LOT_MUST_EXIST"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

	if lsmast_tpl.closed_flag$ = "C" and ord_qty > 0 then
		msg_id$ = "IV_SERLOT_CLOSED"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

set_qty_defaults: rem --- Set defaults

	if num(callpoint!.getColumnData("OPE_ORDLSDET.QTY_ORDERED")) = 0 then
		if callpoint!.getDevObject("lotser_flag")="S" then 
			callpoint!.setColumnData("OPE_ORDLSDET.QTY_ORDERED","1")
			user_tpl.left_to_ord = user_tpl.left_to_ord - 1
		else
			ord_qty = min(lsmast_tpl.qty_on_hand, user_tpl.left_to_ord)
			callpoint!.setColumnData("OPE_ORDLSDET.QTY_ORDERED", str(ord_qty))
			user_tpl.left_to_ord = user_tpl.left_to_ord - ord_qty
		endif
	endif

	print "---Left to ord:", user_tpl.left_to_ord; rem debug

	if num(callpoint!.getColumnData("OPE_ORDLSDET.QTY_SHIPPED")) = 0 then
		if callpoint!.getDevObject("lotser_flag")="S" then
			callpoint!.setColumnData("OPE_ORDLSDET.QTY_SHIPPED","1")
		else
			callpoint!.setColumnData("OPE_ORDLSDET.QTY_SHIPPED", str(ord_qty))
		endif
	endif

	if user_tpl.invoice_noninventory or cvs( callpoint!.getUserInput(), 2 ) = "" then
		goto refresh_screen
	endif

	if num(callpoint!.getColumnData("OPE_ORDLSDET.UNIT_COST")) = 0 then
		callpoint!.setColumnData("OPE_ORDLSDET.UNIT_COST", lsmast_tpl.unit_cost$)
	endif
	
refresh_screen:
	callpoint!.setStatus("MODIFIED;REFRESH")
[[OPE_ORDLSDET.LOTSER_NO.AINQ]]
escape; rem ainq
