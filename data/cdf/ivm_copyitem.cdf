[[IVM_COPYITEM.OLD_ITEM.AVAL]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVM_COPYITEM.NEW_ITEM_ID.AVAL]]
rem --- Make sure new Item doesn't exist

	ivm01_dev = fnget_dev("IVM_ITEMMAST")
	new_item$ = callpoint!.getUserInput()
	start_block = 1

	if start_block then 
		find (ivm01_dev,key=firm_id$+new_item$, dom=*endif)
		msg_id$="IV_ITEM_EXISTS"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif
	
	callpoint!.setDevObject("new_item_id", new_item$)
[[IVM_COPYITEM.BSHO]]
rem --- Open file

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	
	open_tables$[1]="IVM_ITEMMAST", open_opts$[1]="OTA"
	
	gosub open_tables
	
	ivm01_dev=num(open_chans$[1])
	ivm01a$=open_tpls$[1]
