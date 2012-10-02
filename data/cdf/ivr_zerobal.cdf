[[IVR_ZEROBAL.ARAR]]
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="IVS_ZEROBAL",open_opts$[1]="OTA"
gosub open_tables
ivs10a_chn=num(open_chans$[1])
ivs10a_tpl$=open_tpls$[1]

dim ivs10a$:ivs10a_tpl$
readrecord(ivs10a_chn,key=firm_id$+"A",dom=*next)ivs10a$

sysinfo_template$=stbl("+SYSINFO_TPL",err=*next)
dim sysinfo$:sysinfo_template$
sysinfo$=stbl("+SYSINFO",err=*next)
when$=sysinfo.system_date$

p9=num(ivs10a.run_date$)
if p9<>0 then report_date$=ivs10a.run_date$ else report_date$=when$

callpoint!.setColumnData("RUN_DATE",ivs10a.run_date$)
callpoint!.setColumnData("REPORT_DATE",report_date$)
callpoint!.setColumnData("REPORT_SEQ","P")
callpoint!.setStatus("REFRESH")
