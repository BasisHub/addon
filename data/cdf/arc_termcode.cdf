[[ARC_TERMCODE.BSHO]]
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ARS_CREDIT",open_opts$[1]="OTA"
gosub open_tables
ars_credit=num(open_chans$[1])
dim ars_credit$:open_tpls$[1]

read record (ars_credit,key=firm_id$+"AR01",dom=*next)ars_credit$
if ars_credit.sys_install$ <> "Y"
 	ctl_name$="ARC_TERMCODE.CRED_HOLD"
 	ctl_stat$="I"
 	gosub disable_fields
endif
[[ARC_TERMCODE.<CUSTOM>]]
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
