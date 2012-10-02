[[IVC_TYPECODE.BDEL]]
rem --- Make sure item type being deleted isn't used in ivm-01

ivm01_dev=fnget_dev("IVM_ITEMMAST")
ivs_defaults=fnget_dev("IVS_DEFAULTS")
dim ivs_defaults$:fnget_tpl$("IVS_DEFAULTS")
item_type$ = callpoint!.getColumnData("IVC_TYPECODE.ITEM_TYPE")

read (ivm01_dev,key=firm_id$+item_type$,knum=7,dom=*next)
k$="", k$=key(ivm01_dev,err=*next)
if pos(firm_id$+item_type$=k$)=1
	msg_id$="IV_TYPE_IN_USE"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif

rem --- Make sure this item type isn't a default

readrecord (ivs_defaults,key=firm_id$+"D",dom=*next)ivs_defaults$

if ivs_defaults.item_type$=item_type$ then
	msg_id$="IV_TYPE_DEFAULT"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
[[IVC_TYPECODE.<CUSTOM>]]
#include std_missing_params.src
[[IVC_TYPECODE.BSHO]]
rem --- Open/Lock files

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

rem --- init/parameters

ivs01a_key$=firm_id$+"IV00"
find record (ivs01_dev,key=ivs01a_key$,err=std_missing_params) ivs01a$
