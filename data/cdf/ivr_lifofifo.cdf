[[IVR_LIFOFIFO.<CUSTOM>]]
#include std_missing_params.src
[[IVR_LIFOFIFO.BSHO]]
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"
gosub open_tables
ivs01_dev=num(open_chans$[1]),ivs01_tpl$=open_tpls$[1]

dim ivs01a$:ivs01_tpl$
ivs01a_key$=firm_id$+"IV00"
find record (ivs01_dev,key=ivs01a_key$,err=std_missing_params) ivs01a$

if pos(ivs01a.lifofifo$="LF") = 0 then
	call stbl("+DIR_SYP")+"bac_message.bbj","IV_NO_LIFO_FIFO",msg_tokens$[all],msg_opt$,table_chans$[all]
	callpoint!.setStatus("EXIT")
endif
