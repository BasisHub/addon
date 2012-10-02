[[POC_MSGCODE.<CUSTOM>]]
#include std_missing_params.src
[[POC_MSGCODE.BSHO]]
rem --- Open/Lock files

num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="POS_PARAMS",open_opts$[1]="OTA"
gosub open_tables
pos_params=num(open_chans$[1])
dim pos01a$:open_tpls$[1]

rem --- init/parameters

pos01a_key$=firm_id$+"PO00"
find record (pos_params,key=pos01a_key$,err=std_missing_params) pos01a$
