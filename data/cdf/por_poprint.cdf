[[POR_POPRINT.<CUSTOM>]]
#include std_functions.src
[[POR_POPRINT.VENDOR_ID.AVAL]]
rem "VENDOR INACTIVE - FEATURE"
vendor_id$ = callpoint!.getUserInput()
apm01_dev=fnget_dev("APM_VENDMAST")
apm01_tpl$=fnget_tpl$("APM_VENDMAST")
dim apm01a$:apm01_tpl$
apm01a_key$=firm_id$+vendor_id$
find record (apm01_dev,key=apm01a_key$,err=*break) apm01a$
if apm01a.vend_inactive$="Y" then
   call stbl("+DIR_PGM")+"adc_getmask.aon","VENDOR_ID","","","",m0$,0,vendor_size
   msg_id$="AP_VEND_INACTIVE"
   dim msg_tokens$[2]
   msg_tokens$[1]=fnmask$(apm01a.vendor_id$(1,vendor_size),m0$)
   msg_tokens$[2]=cvs(apm01a.vendor_name$,2)
   gosub disp_message
   callpoint!.setStatus("ACTIVATE")
endif

[[POR_POPRINT.ARAR]]
rem --- set defaults

callpoint!.setColumnData("POR_POPRINT.REPORT_TYPE","N")
callpoint!.setColumnData("POR_POPRINT.RESTART","N")
callpoint!.setColumnData("POR_POPRINT.MESSAGE_TEXT","")
callpoint!.setColumnData("POR_POPRINT.VENDOR_ID","")

callpoint!.setStatus("REFRESH")
