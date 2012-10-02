[[IVE_COSTCHG.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVE_COSTCHG.BTBL]]
rem --- Get Batch information

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]
callpoint!.setTableColumnAttribute("IVE_COSTCHG.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[IVE_COSTCHG.BEND]]
rem --- remove software lock on batch, if batching

	batch$=stbl("+BATCH_NO",err=*next)
	if num(batch$)<>0
		lock_table$="ADM_PROCBATCHES"
		lock_record$=firm_id$+stbl("+PROCESS_ID")+batch$
		lock_type$="X"
		lock_status$=""
		lock_disp$=""
		call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$
	endif
[[IVE_COSTCHG.ARAR]]
rem --- Set default warehouse if necessary

	if user_tpl.default_whse$ <> "" then 
		callpoint!.setColumnData("IVE_COSTCHG.WAREHOUSE_ID", user_tpl.default_whse$)
		callpoint!.setStatus("REFRESH")
		util.disableField(callpoint!, "WAREHOUSE_ID")
	endif
[[IVE_COSTCHG.AWRI]]
rem --- Set last date as a default for the next record

	user_tpl.last_date$ = callpoint!.getColumnData("IVE_COSTCHG.EFFECT_DATE")
[[IVE_COSTCHG.ADIS]]
rem --- Display std cost

	whse$ = callpoint!.getColumnData("IVE_COSTCHG.WAREHOUSE_ID")
	item$ = callpoint!.getColumnData("IVE_COSTCHG.ITEM_ID")

	gosub check_item_whse

	if !failed then gosub set_display_cost
[[IVE_COSTCHG.AREC]]
rem --- Set defaults

	needs_refresh = 0

	if user_tpl.last_date$ <> "" then
		callpoint!.setColumnData("IVE_COSTCHG.EFFECT_DATE",user_tpl.last_date$)
		needs_refresh = 1
	endif

	if user_tpl$.default_whse$ <> "" then
		callpoint!.setColumnData("IVE_COSTCHG.WAREHOUSE_ID", user_tpl$.default_whse$)
		needs_refresh = 1
	endif

	if needs_refresh then callpoint!.setStatus("REFRESH")
[[IVE_COSTCHG.ITEM_ID.AVAL]]
rem --- Is the warehouse / item combination valid?

	whse$ = callpoint!.getColumnData("IVE_COSTCHG.WAREHOUSE_ID")
	item$ = callpoint!.getUserInput()

	if whse$ <> "" then 
		gosub check_item_whse
		if !failed then gosub set_display_cost
	endif
[[IVE_COSTCHG.BWRI]]
rem --- Check that all data is valid

rem --- Is the warehouse / item combination valid?

	whse$ = callpoint!.getColumnData("IVE_COSTCHG.WAREHOUSE_ID")
	item$ = callpoint!.getColumnData("IVE_COSTCHG.ITEM_ID")

	gosub check_item_whse

	if failed then
		callpoint!.setStatus("ABORT")
		goto bwri_end
	endif

bwri_end:
[[IVE_COSTCHG.<CUSTOM>]]
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
set_display_cost: rem --- Display Std Cost; set default cost
                  rem      IN: itemwhse_rec$
                  rem     OUT: new_cost, if zero
rem ===========================================================================

	if num( callpoint!.getColumnData("IVE_COSTCHG.NEW_COST") ) = 0 then
		callpoint!.setColumnData("IVE_COSTCHG.NEW_COST", itemwhse_rec.unit_cost$)
		callpoint!.setStatus("MODIFIED")
	endif

	callpoint!.setColumnData("<<DISPLAY>>.STD_COST", itemwhse_rec.unit_cost$)
	callpoint!.setStatus("REFRESH")

return

rem ===========================================================================
#include std_missing_params.src
rem ===========================================================================
[[IVE_COSTCHG.WAREHOUSE_ID.AVAL]]
rem --- Is the warehouse / item combination valid?

	whse$ = callpoint!.getUserInput()
	item$ = callpoint!.getColumnData("IVE_COSTCHG.ITEM_ID")

	if item$ <> "" then 
		gosub check_item_whse
		if !failed then gosub set_display_cost
	endif
[[IVE_COSTCHG.BSHO]]
rem --- Inits

	use ::ado_util.src::util

rem --- Open files

	num_files=3
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVM_ITEMMAST", open_opts$[1]="OTA"
	open_tables$[2]="IVM_ITEMWHSE", open_opts$[2]="OTA"
	open_tables$[3]="IVS_PARAMS",   open_opts$[3]="OTA"

	gosub open_tables

	ivs_params_dev = num(open_chans$[3])
	dim ivs_params_rec$:open_tpls$[3]

rem --- Globals

	dim user_tpl$:"default_whse:c(1*), last_date:c(1*)"

rem --- Get parameter records

	find record(ivs_params_dev, key=firm_id$+"IV00", dom=std_missing_params) ivs_params_rec$

	if ivs_params_rec.cost_method$ <> "S" then
		callpoint!.setMessage("IV_NO_STD_COST")
		callpoint!.setStatus("EXIT")
		goto bsho_end
	endif

	if ivs_params_rec.multi_whse$ <> "Y" then 
		user_tpl.default_whse$ = ivs_params_rec.warehouse_id$
	endif

bsho_end:
