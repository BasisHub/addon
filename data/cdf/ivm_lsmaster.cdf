[[IVM_LSMASTER.VENDOR_ID.AVAL]]
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

[[IVM_LSMASTER.<CUSTOM>]]
#include std_functions.src
[[IVM_LSMASTER.AOPT-LLKP]]
key_pfx$=callpoint!.getColumnData("IVM_LSMASTER.FIRM_ID")+callpoint!.getColumnData("IVM_LSMASTER.ITEM_ID")+
:	callpoint!.getColumnData("IVM_LSMASTER.WAREHOUSE_ID")
selected_key$=""
call stbl("+DIR_SYP")+"bam_inquiry.bbj",
:	gui_dev,
:	Form!,
:	"IVM_LSMASTER",
:	"",
:	table_chans$[all],
:	key_pfx$,
:	"ALT_KEY_03",
:	selected_key$

escape
if selected_key$<>""
	callpoint!.setColumnData("IVM_LSMASTER.LOTSER_NO",selected_key$(25,20))
	callpoint!.setStatus("REFRESH")
endif
[[IVM_LSMASTER.AOPT-LHST]]
iv_item_id$=callpoint!.getColumnData("IVM_LSMASTER.ITEM_ID")
iv_whse_id$=callpoint!.getColumnData("IVM_LSMASTER.WAREHOUSE_ID")
iv_lot_id$=callpoint!.getColumnData("IVM_LSMASTER.LOTSER_NO")

call stbl("+DIR_PGM")+"ivr_itmWhseLotAct.aon",iv_item_id$,iv_whse_id$,iv_lot_id$,table_chans$[all]
[[IVM_LSMASTER.AOPT-LTRN]]
iv_item_id$=callpoint!.getColumnData("IVM_LSMASTER.ITEM_ID")
iv_whse_id$=callpoint!.getColumnData("IVM_LSMASTER.WAREHOUSE_ID")
iv_lot_id$=callpoint!.getColumnData("IVM_LSMASTER.LOTSER_NO")
user_id$=stbl("+USER_ID")
dim dflt_data$[5,1]
dflt_data$[1,0]="ITEM_ID_1"
dflt_data$[1,1]=iv_item_id$
dflt_data$[2,0]="ITEM_ID_2"
dflt_data$[2,1]=iv_item_id$
dflt_data$[3,0]="WAREHOUSE_ID_1"
dflt_data$[3,1]=iv_whse_id$
dflt_data$[4,0]="WAREHOUSE_ID_2"
dflt_data$[4,1]=iv_whse_id$ 
dflt_data$[5,0]="LOTSER_NO"
dflt_data$[5,1]=iv_lot_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"IVR_LSTRANHIST",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]
