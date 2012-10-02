[[IVM_DESCRIP1.<CUSTOM>]]
#include std_missing_params.src
[[IVM_DESCRIP1.BSHO]]
rem --- Open/Lock files

files=1,begfile=1,endfile=files
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="IVS_PARAMS",options$[1]="OTA"
call dir_pgm$+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                 chans$[all],templates$[all],table_chans$[all],batch,status$
if status$<>""  goto std_exit
ivs01_dev=num(chans$[1])

rem --- Dimension miscellaneous string templates

dim ivs01a$:templates$[1]

rem --- init/parameters

ivs01a_key$=firm_id$+"IV00"
find record (ivs01_dev,key=ivs01a_key$,err=std_missing_params) ivs01a$
if ivs01a.master_flag_01$<>"Y"
	msg_id$="IV_NO_DESC"
	dim msg_tokens$[1]
	msg_tokens$[1]="1"
	gosub disp_message
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif
