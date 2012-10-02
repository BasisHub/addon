[[IVC_PRODCODE.BDEL]]
rem --- Make sure prod type being deleted isn't used in ivm-01

ivm01_dev=fnget_dev("IVM_ITEMMAST")
ivs_defaults=fnget_dev("IVS_DEFAULTS")
dim ivs_defaults$:fnget_tpl$("IVS_DEFAULTS")
prod_type$ = callpoint!.getColumnData("IVC_PRODCODE.PRODUCT_TYPE")

read (ivm01_dev,key=firm_id$+prod_type$,knum=2,dom=*next)
k$="", k$=key(ivm01_dev,err=*next)
if pos(firm_id$+prod_type$=k$)=1
	dim msg_tokens$[1]
	msg_tokens$[1]="This Product Type is assigned to one or more Inventory items."
	msg_id$="IV_NO_DELETE"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif

rem --- Make sure this prod type isn't a default

readrecord (ivs_defaults,key=firm_id$+"D",dom=*next)ivs_defaults$

if ivs_defaults.product_type$=prod_type$ then
	msg_id$="IV_PROD_DEFAULT"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
[[IVC_PRODCODE.<CUSTOM>]]
rem #include disable_fields.src

disable_fields:
	rem --- used to disable/enable controls
	rem --- ctl_name$ sent in with name of control to enable/disable (format "ALIAS.CONTROL_NAME")
	rem --- ctl_stat$ sent in as D or space, meaning disable/enable, respectively

	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")

return

rem #endinclude disable_fields.src

#include std_missing_params.src
[[IVC_PRODCODE.BSHO]]
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
rem Needed? ivm01_dev=num(chans$[2])

rem --- Dimension miscellaneous string templates

dim ivs01a$:templates$[1]

rem --- init/parameters

ivs01a_key$=firm_id$+"IV00"
find record (ivs01_dev,key=ivs01a_key$,err=std_missing_params) ivs01a$

call stbl("+DIR_PGM")+"adc_application.aon","SA",info$[all]
sa$=info$[20]
if sa$<>"Y"
	ctl_name$="IVC_PRODCODE.SA_LEVEL"
	ctl_stat$="I"
	gosub disable_fields
	callpoint!.setTableColumnAttribute("IVC_PRODCODE.SA_LEVEL","DFLT","N")
endif
