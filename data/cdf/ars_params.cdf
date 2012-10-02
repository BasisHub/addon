[[ARS_PARAMS.ARAR]]
rem --- Update post_to_gl if GL is uninstalled
	if user_tpl.gl_installed$<>"Y" and callpoint!.getColumnData("ARS_PARAMS.POST_TO_GL")="Y" then
		callpoint!.setColumnData("ARS_PARAMS.POST_TO_GL","N",1)
		callpoint!.setStatus("MODIFIED")
	endif
[[ARS_PARAMS.AREC]]
rem --- Init new record
	callpoint!.setColumnData("ARS_PARAMS.INV_HIST_FLG","Y")
	if user_tpl.gl_installed$="Y" then callpoint!.setColumnData("ARS_PARAMS.POST_TO_GL","Y")
[[ARS_PARAMS.BSHO]]
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
gosub open_tables
gls01_dev=num(open_chans$[1])
rem --- Dimension string templates
	dim gls01a$:open_tpls$[1]

rem --- check to see if main GL param rec (firm/GL/00) exists; if not, tell user to set it up first
	gls01a_key$=firm_id$+"GL00"
	find record (gls01_dev,key=gls01a_key$,err=*next) gls01a$  
	if cvs(gls01a.current_per$,2)=""
		msg_id$="GL_PARAM_ERR"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		rem - remove process bar
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif

rem --- Retrieve parameter data
	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
	gl$=info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","AP",info$[all]
	ap$=info$[20],br$=info$[9]
	call stbl("+DIR_PGM")+"adc_application.aon","IV",info$[all]
	iv$=info$[20]
	dim user_tpl$:"app:c(2),gl_pers:c(2),gl_curr_per:c(2),gl_curr_year:c(4),gl_installed:c(1),"+
:                  "ap_installed:c(1),iv_installed:c(1),bank_rec:c(1)"
	user_tpl.app$="AR"
	user_tpl.gl_pers$=gls01a.total_pers$
	user_tpl.gl_installed$=gl$
	user_tpl.ap_installed$=ap$
	user_tpl.iv_installed$=iv$
	user_tpl.bank_rec$=br$
	user_tpl.gl_curr_per$=gls01a.current_per$
	user_tpl.gl_curr_year$=gls01a.current_year$

	if user_tpl.gl_installed$<>"Y" then callpoint!.setColumnEnabled("ARS_PARAMS.POST_TO_GL",-1)
[[ARS_PARAMS.ARNF]]
rem --- param rec (firm+AR00) doesn't yet exist; set some defaults
callpoint!.setColumnData("ARS_PARAMS.CURRENT_PER",user_tpl.gl_curr_per$)
callpoint!.setColumnUndoData("ARS_PARAMS.CURRENT_PER",user_tpl.gl_curr_per$)
callpoint!.setColumnData("ARS_PARAMS.CURRENT_YEAR",user_tpl.gl_curr_year$)
callpoint!.setColumnUndoData("ARS_PARAMS.CURRENT_YEAR",user_tpl.gl_curr_year$)
callpoint!.setColumnData("ARS_PARAMS.CUSTOMER_SIZE",
:	callpoint!.getColumnData("ARS_PARAMS.MAX_CUSTOMER_LEN"))
callpoint!.setColumnUndoData("ARS_PARAMS.CUSTOMER_SIZE",
:                     callpoint!.getColumnData("ARS_PARAMS.MAX_CUSTOMER_LEN"))
if ap$="Y" and gl$="Y" and br$="Y" 
	callpoint!.setColumnData("ARS_PARAMS.BR_INTERFACE","Y")
	callpoint!.setColumnUndoData("ARS_PARAMS.BR_INTERFACE","Y")
endif
callpoint!.setStatus("MODIFIED-REFRESH")
[[ARS_PARAMS.AUTO_NO.AVAL]]
rem --- check here and be sure seq #'s rec exists, if auto-number got checked
if callpoint!.getUserInput()="Y"
	dim open_tables$[1],open_chans$[1],open_opts$[1],open_tpls$[1]
	open_beg=1,open_end=1,open_status$=""
	open_tables$[1]="ADS_SEQUENCES"
	open_opts$[1]="OTA"
	gosub open_tables
	dim ads_sequences$:open_tpls$[1]
	ads_sequences.firm_id$=firm_id$,ads_sequences.seq_id$="CUSTOMER_ID"
	read record (num(open_chans$[1]),key=ads_sequences.firm_id$+
:                               ads_sequences_seq_id$,dom=*next)ads_sequences$;break
	if ads_sequences.firm_id$<>firm_id$ or cvs(ads_sequences.seq_id$,2)<>"CUSTOMER_ID"
		msg_id$="AR_CUST_SEQ"
		dim msg_tokens$[1]
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
endif
[[ARS_PARAMS.BR_INTERFACE.AVAL]]
if user_tpl.ap_installed$<>"Y" or user_tpl.gl_installed$<>"Y" or user_tpl.bank_rec$<>"Y"
	if callpoint!.getUserInput()<>"N"
		msg_id$="AR_BANKREC_ERR"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		callpoint!.setUserInput("N")
		callpoint!.setStatus("REFRESH")
	endif
endif
[[ARS_PARAMS.CURRENT_PER.AVAL]]
if num(callpoint!.getUserInput())<1 or num(callpoint!.getUserInput())>num(user_tpl.gl_pers$)
	msg_id$="AR_INVALID_PER"
	dim msg_tokens$[1];msg_tokens$[1]=user_tpl.gl_pers$
	msg_opt$=""
	gosub disp_message
	callpoint!.setUserInput(
:                           callpoint!.getColumnUndoData("ARS_PARAMS.CURRENT_PER"))
	callpoint!.setStatus("REFRESH-ABORT")
endif
[[ARS_PARAMS.CUSTOMER_INPUT.AVAL]]
wkdata$=callpoint!.getUserInput()
gosub format_cust_outmask
if cust_sz > maxsz
	msg_id$="AR_CUSTNO_MAX"
	dim msg_tokens$[1];msg_tokens$[1]=str(maxsz)
	msg_opt$=""
	gosub disp_message
	callpoint!.setUserInput(
:                           callpoint!.getColumnUndoData("ARS_PARAMS.CUSTOMER_INPUT"))
	callpoint!.setStatus("REFRESH")
else
	rem --- set customer_size and customer_output based on input mask entered
	rem --- i.e., same as 6200 logic in ARP.AB
	callpoint!.setColumnData("ARS_PARAMS.CUSTOMER_SIZE",str(cust_sz:"00"))
	callpoint!.setColumnData("ARS_PARAMS.CUSTOMER_OUTPUT",cust_out$)
endif
[[ARS_PARAMS.DIST_BY_ITEM.AVAL]]
if user_tpl.iv_installed$<>"Y"
	if callpoint!.getUserInput()<>"N"
		msg_id$="AR_DISTITEM_ERR"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		callpoint!.setUserInput("N")
		callpoint!.setStatus("REFRESH")
	endif
endif
[[ARS_PARAMS.<CUSTOM>]]
format_cust_outmask:
	maxsz=num(callpoint!.getColumnData("ARS_PARAMS.MAX_CUSTOMER_LEN")),cust_sz=0,cust_out$=""
	for wk=1 to len(wkdata$)
		if pos("#"=wkdata$(wk,1))<>0 then let cust_sz=cust_sz+1,cust_out$=cust_out$+"0"
		if pos("#"=wkdata$(wk,1))=0 then let cust_out$=cust_out$+wkdata$(wk,1)
	next wk
return
#include std_missing_params.src

