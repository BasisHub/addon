[[APR_VENDINV.ARAR]]
rem --- Default the AP Type if multi-type is N
if user_tpl.multi_type$="N"
	callpoint!.setColumnData("APR_VENDINV.AP_TYPE",user_tpl.ap_type$)
	callpoint!.setStatus("REFRESH")
endif
[[APR_VENDINV.<CUSTOM>]]
disable_fields:
	rem --- used to disable/enable controls depending on parameter settings
	rem --- send in control to toggle (format "ALIAS.CONTROL_NAME"), and D or space to disable/enable

	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP-REFRESH")

return
[[APR_VENDINV.BSHO]]
rem --- Open/Lock files

files=1,begfile=1,endfile=files
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="APS_PARAMS",options$[1]="OTA"

call stbl("+DIR_SYP")+"bac_open_tables.bbj",
:	begfile,
:	endfile,
:	files$[all],
:	options$[all],
:	chans$[all],
:	templates$[all],
:	table_chans$[all],
:	batch,
:	status$

if status$<>"" then
	remove_process_bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif

aps01_dev=num(chans$[1])
dim aps01a$:templates$[1]
readrecord(aps01_dev,key=firm_id$+"AP00")aps01a$
dim user_tpl$:"multi_type:c(1),ap_type:c(2)"
user_tpl.multi_type$=aps01a.multi_types$
user_tpl.ap_type$=aps01a.ap_type$

rem --- may need to disable some ctls based on params

if aps01a.multi_types$="N" 
	ctl_name$="APR_VENDINV.AP_TYPE"
	ctl_stat$="I"
	gosub disable_fields
endif
