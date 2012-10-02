[[IVE_PRICECHG.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVE_PRICECHG.BEND]]
rem --- remove software lock on batch, if batching

	batch$=stbl("+BATCH_NO",err=*next)
	if num(batch$)<>0
		lock_table$="ADM_PROCBATCHES"
		lock_record$=firm_id$+stbl("+PROCESS_ID")+batch$
		lock_type$="U"
		lock_status$=""
		lock_disp$=""
		call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,table_chans$[all],lock_status$
	endif
[[IVE_PRICECHG.BTBL]]
rem --- Get Batch information

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]
callpoint!.setTableColumnAttribute("IVE_PRICECHG.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[IVE_PRICECHG.PRICE_CODE.AVAL]]
rem --- Set last price code

	user_tpl.last_price_cd$ = callpoint!.getColumnData("IVE_PRICECHG.PRICE_CODE")
[[IVE_PRICECHG.UNIT_PRICE.BINP]]
print "in UNIT_PRICE.BINP"; rem debug

rem --- Display current price

	whse$ = callpoint!.getColumnData("IVE_PRICECHG.WAREHOUSE_ID")
	item$ = callpoint!.getColumnData("IVE_PRICECHG.ITEM_ID")
	new_price = num( callpoint!.getColumnData("IVE_PRICECHG.UNIT_PRICE") )
	print "Price from getColumnData():", new_price

	gosub check_item_whse

	if failed then 
		callpoint!.setStatus("ABORT")
	else
		gosub set_display_price
	endif
[[IVE_PRICECHG.ADIS]]
print "in ADIS"; rem debug

rem --- Display current price

	whse$ = callpoint!.getColumnData("IVE_PRICECHG.WAREHOUSE_ID")
	item$ = callpoint!.getColumnData("IVE_PRICECHG.ITEM_ID")
	new_price = num( callpoint!.getColumnData("IVE_PRICECHG.UNIT_PRICE") )

	gosub check_item_whse

	if !failed then gosub set_display_price
[[IVE_PRICECHG.BWRI]]
print "in BWRI"; rem debug

rem --- Is the warehouse / item combination valid?

	whse$ = callpoint!.getColumnData("IVE_PRICECHG.WAREHOUSE_ID")
	item$ = callpoint!.getColumnData("IVE_PRICECHG.ITEM_ID")

	gosub check_item_whse

	if failed then
		callpoint!.setStatus("ABORT")
	endif
[[IVE_PRICECHG.ARAR]]
rem --- Set default warehouse if necessary

	if user_tpl.default_whse$ <> "" then 
		callpoint!.setColumnData("IVE_PRICECHG.WAREHOUSE_ID", user_tpl.default_whse$)
		callpoint!.setStatus("REFRESH")
		callpoint!.setColumnEnabled("IVE_PRICECHG.WAREHOUSE_ID",-1); rem permanent disable
	endif

rem --- Set price code to the last one used

	if cvs(user_tpl.last_price_cd$, 2) <> "" then
		callpoint!.setColumnData("IVE_PRICECHG.PRICE_CODE", user_tpl.last_price_cd$)
		callpoint!.setStatus("REFRESH")
	endif
[[IVE_PRICECHG.<CUSTOM>]]
rem ===========================================================================
check_item_whse: rem --- Check that a warehouse record exists for this item
                 rem      IN: whse$
                 rem          item$
                 rem     OUT: failed  (true/false)
                 rem          itemwhse_rec$ (item/whse record)
rem ===========================================================================

	whse_file$ = "IVM_ITEMWHSE"
	dim itemwhse_rec$:fnget_tpl$(whse_file$)

	failed = 1
	find record (fnget_dev(whse_file$), key=firm_id$+whse$+item$, dom=check_item_whse_missing) itemwhse_rec$
	failed = 0

	goto check_item_whse_done

check_item_whse_missing:

	callpoint!.setMessage("IV_NO_ITEM_WH")

check_item_whse_done:

return

rem ===========================================================================
set_display_price: rem --- Display current price; set default price
                   rem      IN: itemwhse_rec$
                   rem          new_price
                   rem     OUT: new price set, if it was zero
rem ===========================================================================

	if new_price = 0 then
		print "Setting price to: ", itemwhse_rec.cur_price$
		callpoint!.setColumnData("IVE_PRICECHG.UNIT_PRICE", itemwhse_rec.cur_price$)
		callpoint!.setStatus("MODIFIED")
	endif

	callpoint!.setColumnData("<<DISPLAY>>.CUR_PRICE", itemwhse_rec.cur_price$)
	callpoint!.setStatus("REFRESH")

return

rem ===========================================================================
#include std_missing_params.src
rem ===========================================================================
[[IVE_PRICECHG.BSHO]]
rem print 'show',"in BSHO"; rem debug

rem --- Open files

	num_files=3
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVM_ITEMMAST", open_opts$[1]="OTA"
	open_tables$[2]="IVM_ITEMWHSE", open_opts$[2]="OTA"
	open_tables$[3]="IVS_PARAMS",   open_opts$[3]="OTA"

	gosub open_tables

	ivs_params_dev = num(open_chans$[3])
	dim ivs_params_rec$:open_tpls$[3]

rem --- Get params

	find record (ivs_params_dev, key=firm_id$+"IV00", dom=std_missing_params) ivs_params_rec$

rem --- Globals

	dim user_tpl$:"default_whse:c(1*), last_price_cd:c(1*)"

rem --- If this company is not multi-warehouse, set default warehouse

	if ivs_params_rec.multi_whse$ <> "Y" then 
		user_tpl.default_whse$ = ivs_params_rec.warehouse_id$
	endif
