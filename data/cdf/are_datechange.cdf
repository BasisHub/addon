[[ARE_DATECHANGE.BWRI]]
rem --- Abort if record not a valid invoice
	art_invhdr_dev=fnget_dev("ART_INVHDR")
	find record (art_invhdr_dev,key=firm_id$+
:		callpoint!.getColumnData("ARE_DATECHANGE.AR_TYPE")+
:		callpoint!.getColumnData("ARE_DATECHANGE.CUSTOMER_ID")+
:		callpoint!.getColumnData("ARE_DATECHANGE.AR_INV_NO_VER")+"00",dom=*next);goto valid_inv
	callpoint!.setMessage("AR_INV_NO")
	callpoint!.setStatus("ABORT")
valid_inv:
	arc_temcode_dev=fnget_dev("ARC_TERMCODE")
	find record (arc_temcode_dev,key=firm_id$+"A"+
:		pad(callpoint!.getColumnData("ARE_DATECHANGE.AR_TERMS_CODE"),2),dom=*next);goto valid_terms
	callpoint!.setMessage("INVALID_TERMS")
	callpoint!.setStatus("ABORT")
valid_terms:	
[[ARE_DATECHANGE.INVOICE_DATE.AVAL]]
rem --- recalculate due and discount dates
	tmp_inv_date$=callpoint!.getUserInput()
	tmp_term_code$=callpoint!.getColumnData("ARE_DATECHANGE.AR_TERMS_CODE")
	gosub recalc_dates
[[ARE_DATECHANGE.<CUSTOM>]]
recalc_dates:
	rem --- tmp_term_code$ and tmp_inv_date$ set prior to gosub
	arc_termcode_dev=fnget_dev("ARC_TERMCODE")
	dim arc_termcode$:fnget_tpl$("ARC_TERMCODE")
	while 1
		readrecord (arc_termcode_dev,key=firm_id$+"A"+tmp_term_code$,dom=*break)arc_termcode$
		call stbl("+DIR_PGM")+"adc_duedate.aon",arc_termcode.prox_or_days$,tmp_inv_date$,
:			arc_termcode.inv_days_due,due$,status
		callpoint!.setColumnData("ARE_DATECHANGE.INV_DUE_DATE",due$)
		readrecord (arc_termcode_dev,key=firm_id$+"A"+tmp_term_code$,dom=*break)arc_termcode$
		call stbl("+DIR_PGM")+"adc_duedate.aon",arc_termcode.prox_or_days$,tmp_inv_date$,
:			arc_termcode.disc_days,due$,status
		callpoint!.setColumnData("ARE_DATECHANGE.DISC_DATE",due$)
		callpoint!.setStatus("REFRESH")
		break
	wend
	return
[[ARE_DATECHANGE.AR_TERMS_CODE.AVAL]]
rem --- recalculate due and discount dates
	tmp_inv_date$=callpoint!.getColumnData("ARE_DATECHANGE.INVOICE_DATE")
	tmp_term_code$=callpoint!.getUserInput()
	gosub recalc_dates
[[ARE_DATECHANGE.AWIN]]
rem --- Open/Lock files
files=1,begfile=1,endfile=1
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="ARE_DATECHANGE";rem --- "are-06"
for wkx=begfile to endfile
	options$[wkx]="OTA"
next wkx
call dir_pgm$+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                   chans$[all],templates$[all],table_chans$[all],batch,status$
if status$<>"" then
	remove_process_bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif
are_datechange_dev=num(chans$[1])
[[ARE_DATECHANGE.BSHO]]
num_files=2
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ART_INVHDR",open_opts$[1]="OTA"
open_tables$[2]="ARC_TERMCODE",open_opts$[2]="OTA"
gosub open_tables
dim user_tpl$:"art_invhdr_tpl:c("+str(len(open_tpls$[1]))+"*),art_invhdr_chn:n(3*)"
user_tpl.art_invhdr_chn=num(open_chans$[1])
user_tpl.art_invhdr_tpl$=open_tpls$[1]
[[ARE_DATECHANGE.AR_INV_NO_VER.AVAL]]
	msg_id$="AR_INV_NO"
	dim msg_tokens$[1]
	msg_opt$=""
	dim art_invhdr$:user_tpl.art_invhdr_tpl$
	firm_id$=callpoint!.getColumnData("ARE_DATECHANGE.FIRM_ID")
	ar_type$=callpoint!.getColumnData("ARE_DATECHANGE.AR_TYPE")
	cust_id$=callpoint!.getColumnData("ARE_DATECHANGE.CUSTOMER_ID")
	inv_no$=callpoint!.getUserInput()
	readrecord(user_tpl.art_invhdr_chn,key=firm_id$+ar_type$+cust_id$+inv_no$+"00",dom=invalid_inv)art_invhdr$
	msg_id$=""
	callpoint!.setColumnData("ARE_DATECHANGE.AR_TERMS_CODE",art_invhdr.ar_terms_code$)
	callpoint!.setColumnData("ARE_DATECHANGE.DISCOUNT_AMT",str(art_invhdr.disc_allowed))
	callpoint!.setColumnData("ARE_DATECHANGE.DISC_DATE",art_invhdr.disc_date$)
	callpoint!.setColumnData("ARE_DATECHANGE.INVOICE_AMT",str(art_invhdr.invoice_amt))
	callpoint!.setColumnData("ARE_DATECHANGE.INVOICE_DATE",art_invhdr.invoice_date$)
	callpoint!.setColumnData("ARE_DATECHANGE.INVOICE_TYPE",art_invhdr.invoice_type$)
	callpoint!.setColumnData("ARE_DATECHANGE.INV_DUE_DATE",art_invhdr.inv_due_date$)
	callpoint!.setStatus("ABLEMAP-REFRESH")

invalid_inv:
	if msg_id$<>"" then
		gosub disp_message
		escape
	endif
