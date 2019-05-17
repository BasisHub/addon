[[BME_ORDER.ARNF]]
if num(stbl("+BATCH_NO"),err=*next)<>0
	rem --- Check if this record exists in a different batch
	tableAlias$=callpoint!.getAlias()
	primaryKey$=callpoint!.getColumnData("BME_ORDER.FIRM_ID")+
:		callpoint!.getColumnData("BME_ORDER.PROD_DATE")+
:		callpoint!.getColumnData("BME_ORDER.CUSTOMER_ID")+
:		callpoint!.getColumnData("BME_ORDER.ORDER_NO")
	call stbl("+DIR_PGM")+"adc_findbatch.aon",tableAlias$,primaryKey$,Translate!,table_chans$[all],existingBatchNo$,status
	if status or existingBatchNo$<>"" then callpoint!.setStatus("NEWREC")
endif
[[BME_ORDER.<CUSTOM>]]
#include std_functions.src
[[BME_ORDER.CUSTOMER_ID.AVAL]]
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
   callpoint!.setStatus("ACTIVATE-ABORT")
   goto std_exit
endif

[[BME_ORDER.BEND]]
rem --- remove software lock on batch, if batching

	batch$=stbl("+BATCH_NO",err=*next)
	if num(batch$)<>0
		lock_table$="ADM_PROCBATCHES"
		lock_record$=firm_id$+stbl("+PROCESS_ID")+batch$
		lock_type$="X"
		lock_status$=""
		lock_disp$=""
		call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$
	endif
[[BME_ORDER.BTBL]]
rem --- Get Batch information

	call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]
	callpoint!.setTableColumnAttribute("BME_ORDER.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[BME_ORDER.AREC]]
rem --- Clear Order Date

	callpoint!.setColumnData("<<DISPLAY>>.ORDER_DATE","",1)
[[BME_ORDER.ARAR]]
	ope01_dev=fnget_dev("OPE_ORDHDR")
	dim ope01a$:fnget_tpl$("OPE_ORDHDR")

	cust$=callpoint!.getColumnData("BME_ORDER.CUSTOMER_ID")
	order$=callpoint!.getColumnData("BME_ORDER.ORDER_NO")
	read(ope01_dev,key=firm_id$+"  "+cust$+order$,knum="PRIMARY",dom=*next)
	while 1
		dim ope01a$:fattr(ope01a$)
		ope01_key$=key(ope01_dev,end=*break)
		if pos(firm_id$+"  "+cust$+order$=ope01_key$)<>1 then break
		read record(ope01_dev)ope01a$
		if pos(ope01a.trans_status$="ER") then break; rem --- new order can have at most just one new invoice, if any
	wend

	callpoint!.setColumnData("<<DISPLAY>>.ORDER_DATE",fndate$(ope01a.order_date$),1)
[[BME_ORDER.ORDER_NO.AVAL]]
rem --- Check to make sure the order selected is an Order

	ope01_dev=fnget_dev("OPE_ORDHDR")
	dim ope01a$:fnget_tpl$("OPE_ORDHDR")

	cust$=callpoint!.getColumnData("BME_ORDER.CUSTOMER_ID")
	order$=callpoint!.getUserInput()
	read(ope01_dev,key=firm_id$+"  "+cust$+order$,knum="PRIMARY",dom=*next)
	while 1
		dim ope01a$:fattr(ope01a$)
		ope01_key$=key(ope01_dev,end=*break)
		if pos(firm_id$+"  "+cust$+order$=ope01_key$)<>1 then break
		read record(ope01_dev)ope01a$
		if pos(ope01a.trans_status$="ER") then break; rem --- new order can have at most just one new invoice, if any
	wend

	if ope01a.ordinv_flag$<>"O"
		msg_id$="OP_ORDER_TYPE"
		gosub disp_message
		callpoint!.setColumnData("BME_ORDER.ORDER_NO","",1)
		callpoint!.setStatus("ABORT")
	endif

	callpoint!.setColumnData("<<DISPLAY>>.ORDER_DATE",fndate$(ope01a.order_date$),1)
[[BME_ORDER.PROD_DATE.AVAL]]
rem --- make sure production date is in an appropriate GL period

	gl$=callpoint!.getDevObject("glint")
	prod_date$=callpoint!.getUserInput()        
	if gl$="Y" 
		call stbl("+DIR_PGM")+"glc_datecheck.aon",prod_date$,"Y",per$,yr$,status
		if status>99
			callpoint!.setStatus("ABORT")
		endif
	endif
[[BME_ORDER.BSHO]]
rem --- Check to see if OP is installed

	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","OP",info$[all]
	callpoint!.setDevObject("OP_installed",info$[20])
	if info$[20]<>"Y"
		msg_id$="AD_NO_OP"
		gosub disp_message
		release
	endif

rem --- Open Files

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="OPE_ORDHDR",open_opts$[1]="OTA"
	gosub open_tables

rem --- Additional Init
	gl$="N"
	status=0
	source$=pgm(-2)
	call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"IV",glw11$,gl$,status
	if status<>0 goto std_exit
	callpoint!.setDevObject("glint",gl$)
