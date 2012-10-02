[[IVC_BUYCODE.BDEL]]
rem --- make sure the buyer code that's being deleted isn't the default, or isn't used in ivm-02

ivm02_dev=fnget_dev("IVM_ITEMWHSE")
ivs_defaults=fnget_dev("IVS_DEFAULTS")

dim ivs_defaults$:fnget_tpl$("IVS_DEFAULTS")

can_delete$=""
ivm02_key$=""

read (ivm02_dev,key=firm_id$+callpoint!.getColumnData("IVC_BUYCODE.BUYER_CODE"),knum=3,dom=*next)
ivm02_key$=key(ivm02_dev,end=*next)
if pos(firm_id$+callpoint!.getColumnData("IVC_BUYCODE.BUYER_CODE")=ivm02_key$)=1
	can_delete$="N"
endif
readrecord (ivs_defaults,key=firm_id$+"D",dom=*next)ivs_defaults$
if ivs_defaults.buyer_code$=callpoint!.getColumnData("IVC_BUYCODE.BUYER_CODE")
	can_delete$="N"
endif

if can_delete$="N"
	msg_id$="IV_NO_DELETE"
	dim msg_tokens$[1]
	msg_tokens$[1]="This Buyer Code is either the default, or is used on one or more Inventory items."
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
[[IVC_BUYCODE.<CUSTOM>]]
#include std_missing_params.src
[[IVC_BUYCODE.BSHO]]
rem --- Open/Lock files

files=3,begfile=1,endfile=files
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="IVS_PARAMS",options$[1]="OTA"
files$[2]="IVM_ITEMWHSE",options$[2]="OTA"
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

disable_str$=""
enable_str$=""
dim info$[20]

ivs01a_key$=firm_id$+"IV00"
find record (ivs01_dev,key=ivs01a_key$,err=std_missing_params) ivs01a$

call stbl("+DIR_PGM")+"adc_application.aon","PO",info$[all]
po$=info$[20]

if po$<>"Y"
	MSG_ID$="PO_NOT_INST"
	gosub disp_message
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif
