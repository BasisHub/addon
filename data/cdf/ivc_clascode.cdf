[[IVC_CLASCODE.BDEL]]
rem --- Make sure item class being deleted isn't used in ivm-01

ivm01_dev=fnget_dev("IVM_ITEMMAST")
ivs_defaults=fnget_dev("IVS_DEFAULTS")
dim ivs_defaults$:fnget_tpl$("IVS_DEFAULTS")
item_class$ = callpoint!.getColumnData("IVC_CLASCODE.ITEM_CLASS")

read (ivm01_dev,key=firm_id$+item_class$,knum=6,dom=*next)
k$="", k$=key(ivm01_dev,err=*next)
if pos(firm_id$+item_class$=k$)=1
	msg_id$="IV_CLASS_IN_USE"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif

rem --- Make sure this item class isn't a default

readrecord (ivs_defaults,key=firm_id$+"D",dom=*next)ivs_defaults$

if ivs_defaults.item_class$=item_class$ then
	msg_id$="IV_CLASS_DEFAULT"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
[[IVC_CLASCODE.BSHO]]
files=3,begfile=1,endfile=files
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="IVS_PARAMS",options$[1]="OTA"
files$[2]="IVM_ITEMMAST",options$[2]="OTA"
files$[3]="IVS_DEFAULTS",options$[3]="OTA"
call dir_pgm$+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                 chans$[all],templates$[all],table_chans$[all],batch,status$
if status$<>"" then
	remove_process_bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif
ivs01_dev=num(chans$[1])

rem --- Dimension miscellaneous string templates

	dim ivs01a$:templates$[1]

	ivs01a_key$=firm_id$+"IV00"
	find record (ivs01_dev,key=ivs01a_key$,err=std_missing_params) ivs01a$
[[IVC_CLASCODE.<CUSTOM>]]
#include std_missing_params.src
