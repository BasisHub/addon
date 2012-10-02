[[IVR_STKREORDR.<CUSTOM>]]
#include std_missing_params.src
[[IVR_STKREORDR.ARAR]]
rem --- Are IV parameters missing?

num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"
gosub open_tables
ivs01a_chn=num(open_chans$[1])

readrecord(ivs01a_chn,key=firm_id$+"IV00",err=std_missing_params)
