[[IVM_COPYITEM.NEW_ITEM_ID.AVAL]]
rem " --- Make sure new Item doesn't exist
	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	while 1
		find (ivm01_dev,key=firm_id$+callpoint!.getUserInput(),dom=*break)
		msg_id$="IV_ITEM_EXISTS"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	wend
[[IVM_COPYITEM.BSHO]]
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="IVM_ITEMMAST",open_opts$[1]="OTA"
gosub open_tables
ivm01_dev=num(open_chans$[1]),ivm01a$=open_tpls$[1]

