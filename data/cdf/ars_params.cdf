[[ARS_PARAMS.CURRENT_YEAR.AVAL]]
rem --- Verify calendar exists for entered AR fiscal year
	year$=callpoint!.getUserInput()
	if cvs(year$,2)<>"" and year$<>callpoint!.getColumnData("ARS_PARAMS.CURRENT_YEAR") then
		gls_calendar_dev=fnget_dev("GLS_CALENDAR")
		dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
		readrecord(gls_calendar_dev,key=firm_id$+year$,dom=*next)gls_calendar$
		if cvs(gls_calendar.year$,2)="" then
			msg_id$="AD_NO_FISCAL_CAL"
			dim msg_tokens$[1]
			msg_tokens$[1]=year$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
		callpoint!.setDevObject("total_pers",gls_calendar.total_pers$)
	endif
[[ARS_PARAMS.ARAR]]
rem --- Update post_to_gl if GL is uninstalled
	if user_tpl.gl_installed$<>"Y" and callpoint!.getColumnData("ARS_PARAMS.POST_TO_GL")="Y" then
		callpoint!.setColumnData("ARS_PARAMS.POST_TO_GL","N",1)
		callpoint!.setStatus("MODIFIED")
	endif

rem --- Set maximum number of periods allowed for this fiscal year
	gls_calendar_dev=fnget_dev("GLS_CALENDAR")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
	current_year$=callpoint!.getColumnData("ARS_PARAMS.CURRENT_YEAR")
	readrecord(gls_calendar_dev,key=firm_id$+current_year$,dom=*next)gls_calendar$
	callpoint!.setDevObject("total_pers",gls_calendar.total_pers$)
[[ARS_PARAMS.AREC]]
rem --- Init new record
	callpoint!.setColumnData("ARS_PARAMS.INV_HIST_FLG","Y")
	if user_tpl.gl_installed$="Y" then
		callpoint!.setColumnData("ARS_PARAMS.POST_TO_GL","Y")
		callpoint!.setColumnData("ARS_PARAMS.BR_INTERFACE","Y")
	else
		callpoint!.setColumnData("ARS_PARAMS.POST_TO_GL","N")
		callpoint!.setColumnData("ARS_PARAMS.BR_INTERFACE","N")

		callpoint!.setColumnEnabled("ARS_PARAMS.POST_TO_GL",0)
		callpoint!.setColumnEnabled("ARS_PARAMS.BR_INTERFACE",0)
	endif
[[ARS_PARAMS.BSHO]]
num_files=2
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
open_tables$[2]="GLS_CALENDAR",open_opts$[2]="OTA"
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
	call stbl("+DIR_PGM")+"adc_application.aon","IV",info$[all]
	iv$=info$[20]
	dim user_tpl$:"app:c(2),gl_curr_per:c(2),gl_curr_year:c(4),gl_installed:c(1),"+
:                  "iv_installed:c(1)"
	user_tpl.app$="AR"
	user_tpl.gl_installed$=gl$
	user_tpl.iv_installed$=iv$
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
callpoint!.setStatus("MODIFIED-REFRESH")

rem --- Set maximum number of periods allowed for this fiscal year
	gls_calendar_dev=fnget_dev("GLS_CALENDAR")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
	current_year$=callpoint!.getColumnData("ARS_PARAMS.CURRENT_YEAR")
	readrecord(gls_calendar_dev,key=firm_id$+current_year$,dom=*next)gls_calendar$
	callpoint!.setDevObject("total_pers",gls_calendar.total_pers$)
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
[[ARS_PARAMS.CURRENT_PER.AVAL]]
rem --- Verify haven't exceeded calendar total periods for current AR fiscal year
	period$=callpoint!.getUserInput()
	if cvs(period$,2)<>"" and period$<>callpoint!.getColumnData("ARS_PARAMS.CURRENT_PER") then
		period=num(period$)
		total_pers=num(callpoint!.getDevObject("total_pers"))
		if period<1 or period>total_pers then
			msg_id$="AD_BAD_FISCAL_PERIOD"
			dim msg_tokens$[2]
			msg_tokens$[1]=str(total_pers)
			msg_tokens$[2]=callpoint!.getColumnData("ARS_PARAMS.CURRENT_YEAR")
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
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

