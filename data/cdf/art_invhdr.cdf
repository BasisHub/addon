[[ART_INVHDR.BSHO]]
rem --- Use statements
	use ::ado_func.src::func

rem --- Open/Lock files
	sys_pgm$=stbl("+DIR_SYP",err=*next)
	files=1,begfile=1,endfile=1
	dim files$[files],options$[files],chans$[files],templates$[files]
	files$[1]="ARM_CUSTMAST"; options$[1]="OTA"
	call sys_pgm$+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                   chans$[all],templates$[all],table_chans$[all],batch,status$
	if status$ <> ""  then goto std_exit
[[ART_INVHDR.ADIS]]
rem --- Display customer address
	gosub disp_cust_addr
[[ART_INVHDR.<CUSTOM>]]
disp_cust_addr: rem --- Display customer address
	declare BBjTemplatedString addr!

	arm_custmast_dev = fnget_dev("ARM_CUSTMAST")
	dim arm01a$:fnget_tpl$("ARM_CUSTMAST")
	read record (arm_custmast_dev, key=firm_id$+callpoint!.getColumnData("ART_INVHDR.CUSTOMER_ID"), dom=*next) arm01a$
	addr! = BBjAPI().makeTemplatedString( fnget_tpl$("ARM_CUSTMAST") )
	addr!.setString(arm01a$)
	addr$ = func.formatAddress(table_chans$[all], addr!, 30, 7)

	callpoint!.setColumnData("<<DISPLAY>>.CUST_ADDR1",addr$(31,30),1)
	callpoint!.setColumnData("<<DISPLAY>>.CUST_ADDR2",addr$(61,30),1)
	callpoint!.setColumnData("<<DISPLAY>>.CUST_ADDR3",addr$(91,30),1)
	callpoint!.setColumnData("<<DISPLAY>>.CUST_ADDR4",addr$(121,30),1)
	callpoint!.setColumnData("<<DISPLAY>>.CUST_CTST",addr$(151,30),1)
	callpoint!.setColumnData("<<DISPLAY>>.CUST_ZIP",addr$(181,30),1)

	return
