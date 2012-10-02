[[IVM_COPYITEM.NEW_ITEM_ID.AVAL]]
rem " --- Make sure new Item doesn't exist

	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	find (ivm01_dev,key=firm_id$+callpoint!.getColumnData("IVM_COPYITEM.NEW_ITEM_ID"),dom=okay)
	msg_id$="IV_ITEM_EXISTS"
	gosub disp_message
	callpoint!.setStatus("ABORT")
okay:
[[IVM_COPYITEM.NEW_ITEM.AVAL]]
rem --- See if item already exists

	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	find (ivm01_dev,key=firm_id$+callpoint!.getColumnData("IVM_COPYITEM.NEW_ITEM"),dom=okay)
	msg_id$="IV_ITEM_EXISTS"
	gosub disp_message
	callpoint!.setStatus("ABORT")
okay:
[[IVM_COPYITEM.BSHO]]
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="IVM_ITEMMAST",open_opts$[1]="OTA"
gosub open_tables
ivm01_dev=num(open_chans$[1]),ivm01a$=open_tpls$[1]
