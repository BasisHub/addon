[[IVE_COUNT_ENTRY.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVE_COUNT_ENTRY.PI_CYCLECODE.BINQ]]
rem --- Restrict lookup to printed cycles

	alias_id$ = "IVC_PHYSCODE"
	inq_mode$ = "LOOKUP"
	key_pfx$  = firm_id$
	key_id$   = "PRIMARY"

	dim filter_defs$[1,1]
	filter_defs$[1,0] = "IVC_PHYSCODE.PHYS_INV_STS"
	filter_defs$[1,1] = "='2'"

	call stbl("+DIR_SYP")+"bam_inquiry.bbj",
:		gui_dev,
:		Form!,
:		alias_id$,
:		inq_mode$,
:		table_chans$[all],
:		key_pfx$,
:		key_id$,
:		selected_key$,
:		filter_defs$[all],
:		search_defs$[all]

	callpoint!.setStatus("ABORT")
[[IVE_COUNT_ENTRY.COUNT_STRING.BINP]]
rem --- Serial number's count defaults to one

	if user_tpl.this_item_lot_ser and user_tpl.lotser_flag$ = "S"
		callpoint!.setTableColumnAttribute("IVE_COUNT_ENTRY.ACT_PHYS_CNT","DFLT","1")
	endif
[[IVE_COUNT_ENTRY.AREC]]
print "AREC"; rem debug

rem --- Display next record

	gosub read_display
	user_tpl.prev_cycle$ = physical_rec.pi_cyclecode$
	print "previous cycle code set: ", user_tpl.prev_cycle$; rem debug
[[IVE_COUNT_ENTRY.LOTSER_NO.AVAL]]
print "LOTSER_NO:AVAL"; rem debug

rem --- Check for valid lot and lookup the lot location

	item$ = callpoint!.getColumnData("IVE_COUNT_ENTRY.ITEM_ID")
	lotser_no$ = callpoint!.getUserInput()

rem --- Does record exists?  Ok to add?

	gosub find_record

	if cvs(lotser_no$, 2) = "" then 
		callpoint!.setStatus("ABORT")
	else 
		if new_record then
			msg_id$ = "IV_ADD_PHYS_REC"
			gosub disp_message

			if msg_opt$ = "N" then
				callpoint!.setStatus("ABORT")
			else
				callpoint!.setColumnData("IVE_COUNT_ENTRY.FREEZE_QTY", "0")

rem			Serial number count defaults to one
				if user_tpl.lotser_flag$ = "S" then
					callpoint!.setColumnData("IVE_COUNT_ENTRY.COUNT_STRING", "1")
					callpoint!.setColumnData("IVE_COUNT_ENTRY.ACT_PHYS_CNT", "1")
				else
					callpoint!.setColumnData("IVE_COUNT_ENTRY.COUNT_STRING", "")
					callpoint!.setColumnData("IVE_COUNT_ENTRY.ACT_PHYS_CNT", "0")	
				endif

				callpoint!.setStatus("REFRESH")
			endif

		else
			gosub display_record
		endif
	endif

[[IVE_COUNT_ENTRY.ASVA]]
print "ASVA"; rem debug

rem --- Is cycle in the correct stage?

	whse$  = callpoint!.getColumnData("IVE_COUNT_ENTRY.WAREHOUSE_ID")
	cycle$ = callpoint!.getColumnData("IVE_COUNT_ENTRY.PI_CYCLECODE")
	gosub check_whse_cycle

	if failed then
		callpoint!.setStatus("ABORT")
		goto asva_end
	endif

rem --- Validate Whse/Item record

	item$ = callpoint!.getColumnData("IVE_COUNT_ENTRY.ITEM_ID")
	gosub check_item_whse

	if failed then
		callpoint!.setStatus("ABORT")
		goto asva_end
	else

rem --- Is this item is the selected cycle?

	gosub item_in_cycle

	if !found then
		callpoint!.setStatus("ABORT")
		goto asva_end			
	endif

rem --- Check for valid lot/serial

	if user_tpl.this_item_lot_ser

		lotser_no$ = callpoint!.getColumnData("IVE_COUNT_ENTRY.LOTSER_NO")
		rem gosub valid_ls

		rem if !found then
		rem 	callpoint!.setStatus("ABORT")
		rem 	goto asva_end			
		rem endif

	endif

rem --- Write existing record and display the next

	gosub write_record
	gosub read_display
	callpoint!.setColumnEnabled("IVE_COUNT_ENTRY.LOTSER_NO", 0)

asva_end:
[[IVE_COUNT_ENTRY.ITEM_ID.AVAL]]
print "ITEM_ID:AVAL"; rem debug

rem --- Get Whse/Item record

	whse$ = callpoint!.getColumnData("IVE_COUNT_ENTRY.WAREHOUSE_ID")
	item$ = callpoint!.getUserInput()

	gosub check_item_whse

	if failed then
		rem callpoint!.setStatus("ABORT")
	else

rem --- Is this item is the selected cycle?

		gosub item_in_cycle

		if !found then
			msg_id$ = "IV_ITEM_NOT_IN_CYCLE"
			gosub disp_message
			rem callpoint!.setStatus("ABORT")
		else

rem --- Get record if this isn't a lotted/serial item

			if !user_tpl.this_item_lot_ser
				callpoint!.setColumnData("IVE_COUNT_ENTRY.LOTSER_NO", "")
				lotser_no$ = ""
				gosub find_record

				if new_record then
					rem callpoint!.setStatus("ABORT")
				else
					gosub display_record
				endif

			endif
	
		endif

	endif
[[IVE_COUNT_ENTRY.PI_CYCLECODE.AVAL]]
print "PI_CYCLCODE:AVAL"; rem debug

rem --- Has cycle changed?

	whse$  = callpoint!.getColumnData("IVE_COUNT_ENTRY.WAREHOUSE_ID")
	cycle$ = callpoint!.getUserInput()

	if user_tpl.prev_cycle$ <> cycle$ then
		print "trip read for new cycle..."; rem debug
		read (fnget_dev("IVE_PHYSICAL"), key=firm_id$+whse$+cycle$, dom=*next)
		gosub read_display
		user_tpl.prev_cycle$ = cycle$
		print "previous cycle code set: ", user_tpl.prev_cycle$; rem debug
	endif

rem --- Is cycle in the correct stage?
	
	gosub check_whse_cycle
[[IVE_COUNT_ENTRY.<CUSTOM>]]
rem ==========================================================================
check_whse_cycle: rem --- Check the Physical Cycle code for the correct status
                  rem      IN: whse$
                  rem          cycle$
                  rem     OUT: physcode
                  rem          failed - true / false
rem ==========================================================================

print "in check_whse_cycle"; rem debug

	failed = 0
	file_name$ = "IVC_PHYSCODE"
	dim physcode$:fnget_tpl$(file_name$)
	find record (fnget_dev(file_name$), key=firm_id$+whse$+cycle$) physcode$

	if physcode.phys_inv_sts$ <> "2" then 
		if physcode.phys_inv_sts$ = "0" then
			msg_id$ = "IV_PHYS_NOT_FROZEN"
			gosub disp_message
			rem callpoint!.setStatus("ABORT")
			failed = 1
		else
			if physcode.phys_inv_sts$ = "1" then
				msg_id$ = "IV_PHYS_NOT_PRINTED"
				gosub disp_message
				rem callpoint!.setStatus("ABORT")
				failed = 1
			else
				if physcode.phys_inv_sts$ = "3" then	
					msg_id$ = "IV_PHYS_ALREADY_REG"
					gosub disp_message
					rem callpoint!.setStatus("ABORT")
					failed = 1
				endif
			endif
		endif
	endif

	return

rem ==========================================================================
check_item_whse: rem --- Check that a warehouse record exists for this item
                 rem      IN: whse$
                 rem          item$
                 rem     OUT: failed  (true/false)
                 rem          itemmast_rec$ (item record)
                 rem          itemwhse_rec$ (item/whse record)
                 rem          enable lot/serial$ field
rem ==========================================================================

print "in check_item_whse"; rem debug

	item_file$ = "IVM_ITEMMAST"
	dim itemmast_rec$:fnget_tpl$(item_file$)
	find record (fnget_dev(item_file$), key=firm_id$+item$) itemmast_rec$

	user_tpl.this_item_lot_ser = (user_tpl.ls$ = "Y" and itemmast_rec.lotser_item$ = "Y" and itemmast_rec.inventoried$ = "Y")
	rem callpoint!.setStatus( "ENABLE:" + str(user_tpl.this_item_lot_ser) )
	print "user_tpl.this_item_lot_ser =", user_tpl.this_item_lot_ser; rem debug

	if user_tpl.this_item_lot_ser then
		callpoint!.setColumnEnabled("IVE_COUNT_ENTRY.LOTSER_NO", 1)
	else
		callpoint!.setColumnEnabled("IVE_COUNT_ENTRY.LOTSER_NO", 0)
	endif

	whse_file$ = "IVM_ITEMWHSE"
	dim itemwhse_rec$:fnget_tpl$(whse_file$)
	itemwhse_dev = fnget_dev(whse_file$)

	failed = 1
	find record (itemwhse_dev, knum="PRIMARY", key=firm_id$+whse$+item$, dom=check_item_whse_missing) itemwhse_rec$
	failed = 0

	rem if !user_tpl.this_item_lot_ser then
		callpoint!.setColumnData("IVE_COUNT_ENTRY.LOCATION", itemwhse_rec.location$)
		print "setting location: ", itemwhse_rec.location$; rem debug
		callpoint!.setStatus("REFRESH")
	rem endif

	goto check_item_whse_done

check_item_whse_missing:

	callpoint!.setMessage("IV_ITEM_WHSE_INVALID:" + whse$ )

check_item_whse_done:

	return


rem ==========================================================================
read_display: rem --- Read record and display
              rem      IN: IVE_PHYSICAL opened
rem ==========================================================================

print "in read_display"; rem debug

	file_name$ = "IVE_PHYSICAL"
	dim physical_rec$:fnget_tpl$(file_name$)
	physical_dev = fnget_dev(file_name$)

	if func.hasRecords(physical_dev) then 
		while 1
			read record (physical_dev, end=read_display_eof) physical_rec$
			gosub display_record
			break
		
read_display_eof:
			read (physical_dev, key=firm_id$, dom=*next)
		wend
	endif

	return


rem ==========================================================================
display_record: rem --- Display a record that's been read
                rem      IN: physical_rec$
rem ==========================================================================

print "in display_record"; rem debug

	callpoint!.setColumnData("IVE_COUNT_ENTRY.WAREHOUSE_ID", physical_rec.warehouse_id$)
	callpoint!.setColumnData("IVE_COUNT_ENTRY.PI_CYCLECODE", physical_rec.pi_cyclecode$)
	callpoint!.setColumnData("IVE_COUNT_ENTRY.CUTOFF_DATE", physical_rec.cutoff_date$)
	callpoint!.setColumnData("IVE_COUNT_ENTRY.LOCATION", physical_rec.location$)
	callpoint!.setColumnData("IVE_COUNT_ENTRY.ITEM_ID", physical_rec.item_id$)
	callpoint!.setColumnData("IVE_COUNT_ENTRY.LOTSER_NO", physical_rec.lotser_no$)
	callpoint!.setColumnData("IVE_COUNT_ENTRY.FREEZE_QTY", physical_rec.freeze_qty$)
	callpoint!.setColumnData("IVE_COUNT_ENTRY.COUNT_STRING", physical_rec.count_string$)
	callpoint!.setColumnData("IVE_COUNT_ENTRY.ACT_PHYS_CNT", physical_rec.act_phys_cnt$)

	callpoint!.setStatus("REFRESH")

	user_tpl.entered_flag$ = physical_rec.entered_flag$
	user_tpl.lotser_item$  = physical_rec.lotser_item$
	user_tpl.freeze_qty$   = physical_rec.freeze_qty$

	rem count$ = physical_rec.count_string$
	rem gosub parse_count

	return


rem ==========================================================================
find_record: rem --- Find a record based on the column data
             rem      IN: the columns that make up the key, plus
             rem          item$      - for set_key_data
             rem          lotser_no$ - ditto
             rem     OUT: new_record - 1 = true, 0 = false
rem ==========================================================================

print "in find_record"; rem debug

	gosub set_key_data

	physical_key$ = physical_rec.firm_id$ + 
:                  physical_rec.warehouse_id$ +
:                  physical_rec.pi_cyclecode$ +
:                  physical_rec.location$ +
:                  physical_rec.item_id$ +
:                  physical_rec.lotser_no$

print "key : >", physical_key$, "<"; rem debug
	new_record = 1
	find record (physical_dev, key=physical_key$, dom=find_record_new) physical_rec$
	new_record = 0

find_record_new:

	if new_record then
print "record not found"; rem debug
		user_tpl.entered_flag$ = "Y"
		user_tpl.lotser_item$  = iff(user_tpl.this_item_lot_ser = 1, "Y", "N")
		user_tpl.freeze_qty$   = "1"
	endif

	return


rem ==========================================================================
item_in_cycle: rem --- Is this item in the selected cycle?
               rem      IN: itemwhse_rec$ - templated record   
               rem          itemwhse_dev  - file channel
               rem     OUT: found - true / false
rem ==========================================================================

	found = 0
	k$ = itemwhse_rec.firm_id$ +
:       callpoint!.getColumnData("IVE_COUNT_ENTRY.WAREHOUSE_ID") +
:       callpoint!.getColumnData("IVE_COUNT_ENTRY.PI_CYCLECODE") +
:       itemwhse_rec.location$ +
:       itemwhse_rec.item_id$

	find (itemwhse_dev, knum="AO_WH_CYCLE_LOC", key=k$, dom=item_in_cycle_end)
	found = 1

item_in_cycle_end:
	return


rem ==========================================================================
write_record: rem --- Write record to disk
              rem      IN: item$      - for set_key_data
              rem          lotser_no$ - ditto
rem ==========================================================================

print "in write_record"; rem debug

	gosub set_key_data

	physical_rec.cutoff_date$  = callpoint!.getColumnData("IVE_COUNT_ENTRY.CUTOFF_DATE")
	physical_rec.entered_flag$ = user_tpl.entered_flag$
	physical_rec.lotser_item$  = user_tpl.lotser_item$
	physical_rec.count_string$ = callpoint!.getColumnData("IVE_COUNT_ENTRY.COUNT_STRING")
	physical_rec.freeze_qty$   = user_tpl.freeze_qty$
	physical_rec.act_phys_cnt$ = callpoint!.getColumnData("IVE_COUNT_ENTRY.ACT_PHYS_CNT")

	physical_rec$ = field(physical_rec$)
	write record (physical_dev) physical_rec$

	dim physical_rec$:fattr(physical_rec$); rem clear the record (necessary?)

	return


rem ==========================================================================
set_key_data: rem --- Set data for the key of the table from then form
              rem      IN: item$
              rem          lotser_no$
              rem     OUT: physical_rec$
rem ==========================================================================

print "in set_key_data"; rem debug

	file_name$ = "IVE_PHYSICAL"
	dim physical_rec$:fnget_tpl$(file_name$)
	physical_dev = fnget_dev(file_name$)

	physical_rec.firm_id$      = firm_id$
	physical_rec.warehouse_id$ = callpoint!.getColumnData("IVE_COUNT_ENTRY.WAREHOUSE_ID")
	physical_rec.pi_cyclecode$ = callpoint!.getColumnData("IVE_COUNT_ENTRY.PI_CYCLECODE")
	physical_rec.location$     = callpoint!.getColumnData("IVE_COUNT_ENTRY.LOCATION")
	physical_rec.item_id$      = item$
	physical_rec.lotser_no$    = lotser_no$

	return


rem ==========================================================================
valid_ls: rem --- Get a valid lot/serial# record
          rem      IN: lotser_no$
          rem     OUT: found - true / false
rem ==========================================================================

rem --- Check for valid lot and lookup the lot location

	found = 1
	whse$ = callpoint!.getColumnData("IVE_COUNT_ENTRY.WAREHOUSE_ID")
	item$ = callpoint!.getColumnData("IVE_COUNT_ENTRY.ITEM_ID")

	file_name$ = "IVM_LSMASTER"
	dim lsmaster_rec$:fnget_tpl$(file_name$)

	find record (fnget_dev(file_name$), key=firm_id$+whse$+item$+lotser_no$, dom=valid_ls_bad) lsmaster_rec$
	goto valid_ls_end

valid_ls_bad:
	msg_id$ = "IV_LOT_MUST_EXIST"
	gosub disp_message
	found = 0

valid_ls_end:
	return


rem ==========================================================================
parse_count: rem --- Parse count string, display total
             rem      IN: count$
             rem     OUT: total, displayed
             rem          failed - true / false
rem ==========================================================================

print "in parse_count"; rem debug

	num_mask$ = "^[0-9]+(\.[0-9]+)?"
	sep_mask$ = "([^0-9.] *|$)"
	total = 0
	failed = 0
	count$ = cvs(count$, 3)
	if count$ = "" then goto count_display
	p = mask(count$, num_mask$, err=count_error)

	repeat
		if p <> 1 then exitto count_error
		amt = num( count$(1, tcb(16)) )
		total = total + amt
		count$ = cvs(count$(tcb(16) + 1), 1)
		print "count$ = ", count$; rem debug
		q = mask(count$, sep_mask$, err=count_error)
		count$ = cvs(count$(tcb(16) + 1), 1)
		print "count$ = ", count$; rem debug
		p = mask(count$, num_mask$, err=count_error)
	until count$ = ""

count_display:
	callpoint!.setColumnData("IVE_COUNT_ENTRY.ACT_PHYS_CNT", str(total:user_tpl.amt_mask$))
	callpoint!.setStatus("REFRESH")
	
	goto parse_count_end

count_error:
	msg_id$ = "IV_BAD_COUNT_STR"
	gosub disp_message
	failed = 1

parse_count_end:
	print "---failed =", failed; rem debug
	print "out"; rem debug
	return


rem ==========================================================================
#include std_missing_params.src
rem ==========================================================================
[[IVE_COUNT_ENTRY.COUNT_STRING.AVAL]]
print "COUNT_STRING:AVAL"; rem debug

rem --- Test and total count string

	count$ = callpoint!.getUserInput()
	gosub parse_count

	if failed then
		print "---Failed in parse_count"; rem debug
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

rem --- Serial number count must be one or zero

	qty$=callpoint!.getUserInput()

	if user_tpl.this_item_lot_ser and user_tpl.lotser_flag$ = "S" and qty$ <> "1" and qty$<> "0"
		msg_id$="IV_SER_ONE_ZERO"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

rem --- Flag that this record was entered

	if cvs(callpoint!.getUserInput(), 2) <> "" then 
		user_tpl.entered_flag$ = "Y"
		print "---Set entered flag"; rem debug
	endif
[[IVE_COUNT_ENTRY.BSHO]]
rem print 'show',"BSHO"; rem debug

rem --- Inits

	use ::ado_func.src::func

	dim user_tpl$:"amt_mask:c(1*), ls:c(1), lotser_flag:c(1), this_item_lot_ser:u(1)," +
:                "entered_flag:c(1), lotser_item:c(1), freeze_qty:n(1*), prev_cycle:c(2)"

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

	dim params_rec$:open_tpls$[2]

rem --- Get IV params, set mask, lot/serial

	find record (params_dev, key=firm_id$+"IV00", dom=std_missing_params) params_rec$ 
	user_tpl.amt_mask$ = params_rec.amount_mask$
	if pos(params_rec.lotser_flag$ = "LS") then ls$ = "Y" else ls$ = "N"
	user_tpl.ls$ = ls$
	user_tpl.lotser_flag$ = params_rec.lotser_flag$

	if ls$ = "N" then
		callpoint!.setColumnEnabled("IVE_COUNT_ENTRY.LOTSER_ITEM", -1)
	endif

rem --- Additional file opens

	if ls$ = "Y" then
		open_beg=1, open_end=1
		open_tables$[1]="IVM_LSMASTER", open_opts$[1]="OTA"
		gosub open_tables
	endif

rem --- Set at first record

	read (physical_dev, key=firm_id$, dom=*next)
