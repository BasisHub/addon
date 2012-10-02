[[OPU_COMMREL.AREC]]
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ars_params",open_opts$[1]="OTA"
gosub open_tables
ars01_dev=num(open_chans$[1]),ars01a_tpl$=open_tpls$[1]

dim ars01a$:ars01a_tpl$
readrecord(ars01_dev,key=firm_id$+"AR00",dom=std_missing_params)ars01a$
call stbl("+DIR_PGM")+"adc_daydates.aon",sysinfo.system_date$,next$,num(ars01a.commit_days$)
callpoint!.setColumnData("OPU_COMMREL.LAST_COMMIT",ars01a.lstcom_date$)
callpoint!.setColumnData("OPU_COMMREL.COMMIT_THRU",next$)
callpoint!.setStatus("REFRESH")
[[OPU_COMMREL.<CUSTOM>]]
#include std_missing_params.src
