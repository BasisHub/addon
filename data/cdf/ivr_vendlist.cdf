[[IVR_VENDLIST.BSHO]]
num_files=3
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"
open_tables$[2]="APS_PARAMS",open_opts$[2]="OTA"
open_tables$[3]="GLS_PARAMS",open_opts$[3]="OTA"
gosub open_tables
ivs01_dev=num(open_chans$[1])
aps01_dev=num(open_chans$[2])
gls01_dev=num(open_chans$[3])


rem "see if app param recs are present

    aps01a_key$=firm_id$+"AP00"
    find record (aps01_dev,key=aps01a_key$,err=std_missing_params) aps01a$
    gls01a_key$=firm_id$+"GL00"
    find record (gls01_dev,key=gls01a_key$,err=std_missing_params) gls01a$
    ivs01a_key$=firm_id$+"IV00"
    find record (ivs01_dev,key=ivs01a_key$,err=std_missing_params) ivs01a$
[[IVR_VENDLIST.<CUSTOM>]]
#include std_missing_params.src
