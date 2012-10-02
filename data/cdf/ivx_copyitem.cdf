[[IVX_COPYITEM.ASVA]]
rem --- make sure warehouses aren't same

whse1$=callpoint!.getColumnData("IVX_COPYITEM.WAREHOUSE_FROM")
whse2$=callpoint!.getColumnData("IVX_COPYITEM.WAREHOUSE_TO")

if cvs(whse1$,3)="" or cvs(whse2$,3)="" 
	callpoint!.setStatus("ABORT")
else
	if whse1$=whse2$ 
		callpoint!.setStatus("ABORT")
	endif
endif


[[IVX_COPYITEM.ASHO]]
msg_id$="IV_COPYITEM"
msg_opt$=""

gosub disp_message
if msg_opt$<>"Y" then release
