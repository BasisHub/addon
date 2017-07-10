[[IVM_ITEMPRIC.<CUSTOM>]]
#include std_functions.src
[[IVM_ITEMPRIC.CUSTOMER_ID.AVAL]]
rem "Customer Inactive Feature"
customer_id$=callpoint!.getUserInput()
arm01_dev=fnget_dev("ARM_CUSTMAST")
arm01_tpl$=fnget_tpl$("ARM_CUSTMAST")
dim arm01a$:arm01_tpl$
arm01a_key$=firm_id$+customer_id$
find record (arm01_dev,key=arm01a_key$,err=*break) arm01a$
if arm01a.cust_inactive$="Y" then
   call stbl("+DIR_PGM")+"adc_getmask.aon","CUSTOMER_ID","","","",m0$,0,customer_size
   msg_id$="AR_CUST_INACTIVE"
   dim msg_tokens$[2]
   msg_tokens$[1]=fnmask$(arm01a.customer_id$(1,customer_size),m0$)
   msg_tokens$[2]=cvs(arm01a.customer_name$,2)
   gosub disp_message
   callpoint!.setStatus("ACTIVATE")
endif


[[IVM_ITEMPRIC.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
	callpoint!.setStatus("ACTIVATE")
[[IVM_ITEMPRIC.BWRI]]
rem --- make sure each qty > previous one
ok$="Y"
for x=2 to 10
	wkvar$="BREAK_QTY_"+str(x:"00")
	wkvar1$="BREAK_QTY_"+str(x-1:"00")

	if num(field(rec_data$,wkvar$))<=num(field(rec_data$,wkvar1$)) and
:		num(field(rec_data$,wkvar$))<>0 and
:		num(field(rec_data$,wkvar1$))<>0
		ok$="N"
	endif
next x

if ok$="N"
	msg_id$="IV_QTYERR"
	gosub disp_message
	callpoint!.setStatus("ABORT-REFRESH")
endif
