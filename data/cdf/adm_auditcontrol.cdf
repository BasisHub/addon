[[ADM_AUDITCONTROL.ARNF]]
rem --- no GL Post rec exists for this process (but the process, in adm-19, does exist)
rem --- forward process alias and process program (one or the other will be blank) from adm-19 to glm-06

adm19_dev=fnget_dev("ADM_PROCDETAIL")
dim adm19a$:fnget_tpl$("ADM_PROCDETAIL")

read record (adm19_dev,key=callpoint!.getColumnData("ADM_AUDITCONTROL.PROCESS_ID")+
:	callpoint!.getColumnData("ADM_AUDITCONTROL.SEQUENCE_NO"),dom=*next)adm19a$
callpoint!.setColumnData("ADM_AUDITCONTROL.PROCESS_ALIAS",adm19a.dd_table_alias$)
callpoint!.setColumnData("ADM_AUDITCONTROL.PROCESS_PROGRAM",adm19a.program_name$)

callpoint!.setStatus("REFRESH")
