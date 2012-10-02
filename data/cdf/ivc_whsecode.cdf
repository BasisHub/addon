[[IVC_WHSECODE.BDEL]]
rem -- Don't allow delete of WH code if it's in use 

ivm02_dev = fnget_dev("IVM_ITEMWHSE")
wh$ = callpoint!.getColumnData("IVC_WHSECODE.WAREHOUSE_ID")

read (ivm02_dev,key=firm_id$+wh$,dom=*next)
k$="", k$=key(ivm02_dev,end=*next)

if pos(firm_id$+wh$=k$)=1
	msg_id$="IV_WHSE_USED"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
[[IVC_WHSECODE.<CUSTOM>]]
#include std_missing_params.src
[[IVC_WHSECODE.BSHO]]
rem --- Open/Lock files

files=2,begfile=1,endfile=files
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="IVS_PARAMS",options$[1]="OTA"
files$[2]="IVM_ITEMWHSE",options$[2]="OTA"
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
