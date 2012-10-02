[[ARE_CNVINV.BEND]]
rem --- remove software lock on batch, if batching

	batch$=stbl("+BATCH_NO",err=*next)
	if num(batch$)<>0
		lock_table$="ADM_PROCBATCHES"
		lock_record$=firm_id$+stbl("+PROCESS_ID")+batch$
		lock_type$="U"
		lock_status$=""
		lock_disp$=""
		call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$
	endif
[[ARE_CNVINV.BTBL]]
rem --- Get Batch information

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]
callpoint!.setTableColumnAttribute("ARE_CNVINV.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)


[[ARE_CNVINV.BSHO]]
rem --- Open/Lock files
	files=7,begfile=1,endfile=7
	dim files$[files],options$[files],chans$[files],templates$[files]
	files$[1]="ARS_PARAMS";rem --- "ARS_PARAMS"..."ads-01"
	files$[2]="ARM_CUSTMAST";rem --- "arm-01"
	files$[3]="ARM_CUSTDET";rem --- "arm-02"
	files$[4]="ARC_TERMCODE";rem --- "arm-10" (A)
	files$[5]="ARC_DISTCODE";rem --- "arm-10 (D)
	files$[6]="ART_INVHDR";rem --- "art-01"
	files$[7]="GLS_PARAMS"
	for wkx=begfile to endfile
		options$[wkx]="OTA"
	next wkx
	call stbl("+DIR_SYP")+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                   chans$[all],templates$[all],table_chans$[all],batch,status$
	if status$<>"" then
		remove_process_bar:
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif
	ars01_dev=num(chans$[1])
	gls01_dev=num(chans$[7])
rem --- Dimension templates
	dim ars01a$:templates$[1],gls01a$:templates$[7]
	dim user_tpl$:"firm_id:c(2),op_installed:C(1),glyr:C(4),glper:C(2),no_glpers:C(2),"+
:	    "disc_pct:C(7),inv_days_due:C(7),disc_days:C(7),prox_days:C(1)"
	user_tpl.firm_id$=firm_id$
rem --- Retrieve parameter data/see if OP is installed
	call stbl("+DIR_PGM")+"adc_application.aon","OP",info$[all]
	op$=info$[20]
	user_tpl.op_installed$=op$
	ars01a_key$=firm_id$+"AR00"
	find record (ars01_dev,key=ars01a_key$,err=std_missing_params) ars01a$
	gls01a_key$=firm_id$+"GL00"
	find record (gls01_dev,key=gls01a_key$,err=std_missing_params) gls01a$ 
	user_tpl.glyr$=gls01a.current_year$
	user_tpl.glper$=gls01a.current_per$
	user_tpl.no_glpers$=gls01a.total_pers$     
[[ARE_CNVINV.AR_INV_NO.AVAL]]
rem --- check art-01 and be sure invoice# they've entered isn't in use for this cust.
rem --- otherwise, display the selected invoice...
rem --- note: this means it's possible to have same inv# assigned to diff customers
art_invhdr_dev=fnget_dev("ART_INVHDR")
dim art01a$:fnget_tpl$("ART_INVHDR")
invhdr_key$=firm_id$+"  "+callpoint!.getColumnData("ARE_CNVINV.CUSTOMER_ID")+callpoint!.getUserInput()
read(art_invhdr_dev,key=invhdr_key$,dom=*next)
readrecord(art_invhdr_dev,end=*next)art01a$
if art01a.firm_id$=firm_id$ and art01a.customer_id$=callpoint!.getColumnData("ARE_CNVINV.CUSTOMER_ID") and
:                       art01a.ar_inv_no$=callpoint!.getUserInput()
		msg_id$="AR_INV_USED"
		dim msg_tokens$[1]
		gosub disp_message
		callpoint!.setUserInput("")
		callpoint!.setStatus("REFRESH-ABORT")                           
endif
[[ARE_CNVINV.AR_TERMS_CODE.AVAL]]
arc_termcode_dev=fnget_dev("ARC_TERMCODE")
dim arm10a$:fnget_tpl$("ARC_TERMCODE")
read record(arc_termcode_dev,key=firm_id$+"A"+callpoint!.getUserInput(),dom=*next)arm10a$
user_tpl.disc_pct$=str(arm10a.disc_percent$)
user_tpl.inv_days_due$=str(arm10a.inv_days_due$)
user_tpl.disc_days$=str(arm10a.disc_days$)
user_tpl.prox_days$=arm10a.prox_or_days$
if num(callpoint!.getColumnData("ARE_CNVINV.INVOICE_AMT"))<>0
	wk_amt=num(callpoint!.getColumnData("ARE_CNVINV.INVOICE_AMT"))*num(user_tpl.disc_pct$)/100
	callpoint!.setColumnData("ARE_CNVINV.DISCOUNT_AMT",str(wk_amt))
	callpoint!.setColumnUndoData("ARE_CNVINV.DISCOUNT_AMT",str(wk_amt))
	callpoint!.setStatus("REFRESH")
endif
if cvs(callpoint!.getColumnData("ARE_CNVINV.INVOICE_DATE"),2)<>""
	call stbl("+DIR_PGM")+"adc_duedate.aon",user_tpl.prox_days$,callpoint!.getColumnData("ARE_CNVINV.INVOICE_DATE"),
:                              num(user_tpl.inv_days_due$),wk_date_out$,status
	if status then callpoint!.setStatus("ABORT")
	callpoint!.setColumnData("ARE_CNVINV.INV_DUE_DATE",wk_date_out$)
	callpoint!.setColumnUndoData("ARE_CNVINV.INV_DUE_DATE",wk_date_out$)
	call stbl("+DIR_PGM")+"adc_duedate.aon",user_tpl.prox_days$,callpoint!.getColumnData("ARE_CNVINV.INVOICE_DATE"),
:                               num(user_tpl.disc_days$),wk_date_out$,status
	if status then callpoint!.setStatus("ABORT")
	callpoint!.setColumnData("ARE_CNVINV.DISC_DATE",wk_date_out$)
	callpoint!.setColumnUndoData("ARE_CNVINV.DISC_DATE",wk_date_out$)
	callpoint!.setStatus("REFRESH")
endif
[[ARE_CNVINV.CUSTOMER_ID.AVAL]]
rem --- if on new rec, check are-02 and set default inv# to first one for this customer, if there is one.
if cvs(callpoint!.getColumnData("ARE_CNVINV.AR_INV_NO"),2)=""
	arm_custdet_dev=fnget_dev("ARM_CUSTDET")
	dim arm02a$:fnget_tpl$("ARM_CUSTDET")
	readrecord(arm_custdet_dev,key=firm_id$+callpoint!.getUserInput()+"  ",dom=*next)arm02a$
	if arm02a.firm_id$=firm_id$ and arm02a.customer_id$=callpoint!.getUserInput()
		callpoint!.setColumnData("ARE_CNVINV.AR_DIST_CODE",arm02a.ar_dist_code$)
		callpoint!.setColumnUndoData("ARE_CNVINV.AR_DIST_CODE",arm02a.ar_dist_code$)
		callpoint!.setColumnData("ARE_CNVINV.AR_TERMS_CODE",arm02a.ar_terms_code$)
		callpoint!.setColumnUndoData("ARE_CNVINV.AR_TERMS_CODE",arm02a.ar_terms_code$)
		callpoint!.setStatus("REFRESH")
	endif
endif
[[ARE_CNVINV.INVOICE_AMT.AVAL]]
wk_amt=num(callpoint!.getUserInput())*num(user_tpl.disc_pct$)/100
callpoint!.setColumnData("ARE_CNVINV.DISCOUNT_AMT",str(wk_amt))
callpoint!.setColumnUndoData("ARE_CNVINV.DISCOUNT_AMT",str(wk_amt))
callpoint!.setStatus("REFRESH")
[[ARE_CNVINV.INVOICE_DATE.AVAL]]
call stbl("+DIR_PGM")+"adc_duedate.aon",user_tpl.prox_days$,callpoint!.getUserInput(),num(user_tpl.inv_days_due$),
:	wk_date_out$,status
if status then callpoint!.setStatus("ABORT")
callpoint!.setColumnData("ARE_CNVINV.INV_DUE_DATE",wk_date_out$)
callpoint!.setColumnUndoData("ARE_CNVINV.INV_DUE_DATE",wk_date_out$)
call stbl("+DIR_PGM")+"adc_duedate.aon",user_tpl.prox_days$,callpoint!.getUserInput(),num(user_tpl.disc_days$),
:	wk_date_out$,status
if status then callpoint!.setStatus("ABORT")
callpoint!.setColumnData("ARE_CNVINV.DISC_DATE",wk_date_out$)
callpoint!.setColumnUndoData("ARE_CNVINV.DISC_DATE",wk_date_out$)
callpoint!.setStatus("REFRESH")
[[ARE_CNVINV.<CUSTOM>]]
#include std_missing_params.src

