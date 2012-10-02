[[IVE_PHYSICAL.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVE_PHYSICAL.ITEM_ID.AVAL]]
print "ITEM_ID:AVAL"; rem debug

rem --- Get Whse/Item record

	whse$ = callpoint!.getColumnData("IVE_PHYSICAL.WAREHOUSE_ID")
	item$ = callpoint!.getUserInput()

	gosub check_item_whse
[[IVE_PHYSICAL.ADIS]]
print "ADIS"; rem debug

rem --- Is cycle in the correct stage?

	whse$  = callpoint!.getColumnData("IVE_PHYSICAL.WAREHOUSE_ID")
	cycle$ = callpoint!.getColumnData("IVE_PHYSICAL.PI_CYCLECODE")

	gosub check_whse_cycle

rem --- Check item/warehouse
	
	item$ = callpoint!.getColumnData("IVE_PHYSICAL.ITEM_ID")

	gosub check_item_whse
[[IVE_PHYSICAL.PI_CYCLECODE.AVAL]]
print "PI_CYCLECODE:AVAL"; rem debug

rem --- Is cycle in the correct stage?

	whse$  = callpoint!.getColumnData("IVE_PHYSICAL.WAREHOUSE_ID")
	cycle$ = callpoint!.getUserInput()

	gosub check_whse_cycle
[[IVE_PHYSICAL.LOTSER_ITEM.BINP]]
print "LOTSER_NO:BINP"; rem debug

rem --- Is there a lot/serial#?

	item$ = callpoint!.getColumnData("IVE_PHYSICAL.ITEM_ID")
	whse$ = callpoint!.getColumnData("IVE_PHYSICAL.WAREHOUSE_ID")

	gosub check_item_whse

	if failed then 
		callpoint!.setStatus("ABORT")
		goto lotser_item_end
	endif

	if !user_tpl.this_item_lot_ser then 
		util.disableField(callpoint!, "IVE_PHYSICAL.LOTSER_ITEM")
	endif

lotser_item_end:
[[IVE_PHYSICAL.ARAR]]
print "ARAR"; rem debug

rem --- Set default values

	if user_tpl.default_whse$ <> "" then
		callpoint!.setColumnData("IVE_PHYSICAL.WAREHOUSE_ID", user_tpl.default_whse$)
	endif

	if user_tpl.default_cycle$ <> "" then
		callpoint!.setColumnData("IVE_PHYSICAL.PI_CYCLECODE", user_tpl.default_cycle$)
	endif
[[IVE_PHYSICAL.<CUSTOM>]]
rem ===========================================================================
check_whse_cycle: rem --- Check the Physical Cycle code for the correct status
                  rem      IN: whse$
                  rem          cycle$
rem ===========================================================================

print "in check_whse_cycle"; rem debug

	file_name$ = "IVC_PHYSCODE"
	dim physcode$:fnget_tpl$(file_name$)
	find record (fnget_dev(file_name$), key=firm_id$+whse$+cycle$) physcode$

	if physcode.phys_inv_sts$ <> "2" then 
		if physcode.phys_inv_sts$ = "0" then
			msg_id$ = "IV_PHYS_NOT_FROZEN"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		else
			if physcode.phys_inv_sts$ = "1" then
				msg_id$ = "IV_PHYS_NOT_PRINTED"
				gosub disp_message
				callpoint!.setStatus("ABORT")
			else
				if physcode.phys_inv_sts$ = "3" then	
					msg_id$ = "IV_PHYS_ALREADY_REG"
					gosub disp_message
					callpoint!.setStatus("ABORT")
				endif
			endif
		endif
	endif

	return

rem ===========================================================================
check_item_whse: rem --- Check that a warehouse record exists for this item
                 rem      IN: whse$
                 rem          item$
                 rem     OUT: failed  (true/false)
                 rem          itemmast_rec$ (item record)
                 rem          itemwhse_rec$ (item/whse record)
rem ===========================================================================

print "in check_item_whse"; rem debug

	item_file$ = "IVM_ITEMMAST"
	dim itemmast_rec$:fnget_tpl$(item_file$)
	find record (fnget_dev(item_file$), key=firm_id$+item$) itemmast_rec$

	this_item_lot_ser = (user_tpl.ls$ = "Y" and itemmast_rec.lotser_item$ = "Y" and itemmast_rec.inventoried$ = "Y")
	callpoint!.setStatus( "ENABLE:" + str(this_item_lot_ser) )

	if !this_item_lot_ser then
		rem callpoint!.setColumnEnabled("IVE_PHYSICAL.LOTSER_ITEM", 0)
		rem util.disableField(callpoint!, "IVE_PHYSICAL.LOTSER_ITEM")
	endif

	whse_file$ = "IVM_ITEMWHSE"
	dim itemwhse_rec$:fnget_tpl$(whse_file$)

	failed = 1
	find record (fnget_dev(whse_file$),key=firm_id$+whse$+item$,dom=check_item_whse_missing) itemwhse_rec$
	failed = 0

	callpoint!.setColumnData("IVE_PHYSICAL.LOCATION", itemwhse_rec.location$)

	goto check_item_whse_done

check_item_whse_missing:

	callpoint!.setMessage("IV_ITEM_WHSE_INVALID:" + whse$ )

check_item_whse_done:

return


rem ===========================================================================
#include std_missing_params.src
rem ===========================================================================
[[IVE_PHYSICAL.COUNT_STRING.AVAL]]
print "COUNT_STRING:AVAL"; rem debug

rem --- Parse count string, display total

	count$ = cvs( callpoint!.getColumnData("IVE_PHYSICAL.COUNT_STRING"), 1)
	p = mask(count$, "^[0-9]+(\.[0-9]+)?")
	total = 0

	while p
		if p <> 1 then goto count_error
		amt = num( count$(1, tcb(16)) )
		total = total + amt
		count$ = cvs( count$(tcb(16)), 1)
		p = mask(count$)
	wend

	callpoint!.setColumnData("IVE_PHYSICAL.ACT_PHYS_CNT", str(total:user_tpl.amt_mask$))
	
	goto count_string_end

count_error:
	msg_id$ = "IV_BAD_COUNT_STR"
	gosub disp_message
	callpoint!.setStatus("ABORT")

count_string_end:
[[IVE_PHYSICAL.BSHO]]
print 'show',"BSHO"; rem debug

rem --- Inits

	use ::ado_util.src::util

	dim user_tpl$:"default_whse:c(2), default_cycle:c(2), amt_mask:c(1*), ls:c(1)"

rem --- Open files

	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVE_PHYSICAL", open_opts$[1]="OTA"
	open_tables$[2]="IVS_PARAMS",   open_opts$[2]="OTA"
	open_tables$[3]="IVM_ITEMMAST", open_opts$[3]="OTA"
	open_tables$[4]="IVM_ITEMWHSE", open_opts$[4]="OTA"
	open_tables$[5]="IVC_PHYSCODE", open_opts$[5]="OTA"

	gosub open_tables

	physical_dev = num(open_chans$[1])
	params_dev   = num(open_chans$[2])

	dim physical_rec$:open_tpls$[1]
	dim params_rec$:open_tpls$[2]


rem --- Get IV params, set mask, lot/serial

	find record (params_dev, key=firm_id$+"IV00", dom=std_missing_params) params_rec$ 
	user_tpl.amt_mask$ = params_rec.amount_mask$
	if pos(params_rec.lotser_flag$ = "LS") then ls$="Y" else ls$ = "N"
	user_tpl.ls$ = ls$

	if ls$ = "N" then
		callpoint!.setColumnEnabled("IVE_PHYSICAL.LOTSER_ITEM", -1)
	endif

rem --- Additional file opens

	if ls$ = "Y" then
		open_beg=1, open_end=1
		open_tables$[1]="IVM_LSMASTER", open_opts$[1]="OTA"
		gosub open_tables
		lsmaster_dev = num(open_chans$[1])
		dim lsmaster_rec$:open_tpls$[1]
	endif

rem --- Get the first record

	read (physical_dev, key=firm_id$, dom=*next)
	read record (physical_dev, end=*next) physical_rec$

	user_tpl.default_whse$   = physical_rec.warehouse_id$
	user_tpl.default_cycle$  = physical_rec.pi_cyclecode$
