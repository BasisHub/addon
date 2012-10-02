[[APS_PARAMS.END_CMT_LINE.AVAL]]
rem --- make sure ending cmt line > beg cmt line
if cvs(callpoint!.getColumnData("APS_PARAMS.BEG_CMT_LINE"),3)<>""
	if num(callpoint!.getColumnData("APS_PARAMS.BEG_CMT_LINE") )> 
:		num(callpoint!.getUserInput()) then callpoint!.setStatus("ABORT")
endif
[[APS_PARAMS.<CUSTOM>]]
#include std_missing_params.src
[[APS_PARAMS.ARAR]]
	pgmdir$=stbl("+DIR_PGM")
rem --- Open/Lock files
	files=2,begfile=1,endfile=files
	dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
	files$[1]="aps_params",ids$[1]="APS_PARAMS"
	files$[2]="gls_params",ids$[2]="GLS_PARAMS"
	call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
	if status then
		remove_process_bar:
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
	 	release
	endif

	aps01_dev=channels[1]
	gls01_dev=channels[2]
rem --- Dimension string templates
	dim aps01a$:templates$[1],gls01a$:templates$[2]

rem --- check to see if main GL param rec (firm/GL/00) exists; if not, tell user to set it up first
	gls01a_key$=firm_id$+"GL00"
	find record (gls01_dev,key=gls01a_key$,err=*next) gls01a$  
	if cvs(gls01a.current_per$,2)=""
		msg_id$="GL_PARAM_ERR"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		gosub remove_process_bar
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
	dim user_tpl$:"app:c(2),gl_pers:c(2),gl_installed:c(1),"+
:                  "ap_installed:c(1),iv_installed:c(1),bank_rec:c(1)"
	user_tpl.app$="AP"
	user_tpl.gl_pers$=gls01a.total_pers$
	user_tpl.gl_installed$=gl$
	user_tpl.ap_installed$=ap$
	user_tpl.iv_installed$=iv$
	user_tpl.bank_rec$=br$
	rem --- set some defaults (that I can't do via arde) if param doesn't yet exist
	aps01a_key$=firm_id$+"AP00"
	find record (aps01_dev,key=aps01a_key$,err=*next) aps01a$
	if cvs(aps01a.current_per$,2)=""
		callpoint!.setColumnData("APS_PARAMS.CURRENT_PER",gls01a.current_per$)
		callpoint!.setColumnUndoData("APS_PARAMS.CURRENT_PER",gls01a.current_per$)
		callpoint!.setColumnData("APS_PARAMS.CURRENT_YEAR",gls01a.current_year$)
		callpoint!.setColumnUndoData("APS_PARAMS.CURRENT_YEAR",gls01a.current_year$)
		callpoint!.setColumnData("APS_PARAMS.VENDOR_SIZE",
:			callpoint!.getColumnData("APS_PARAMS.MAX_VENDOR_LEN"))
		callpoint!.setColumnUndoData("APS_PARAMS.VENDOR_SIZE",
:                     	callpoint!.getColumnData("APS_PARAMS.MAX_VENDOR_LEN"))
		if ap$="Y" and gl$="Y" and br$="Y" 
			callpoint!.setColumnData("APS_PARAMS.BR_INTERFACE","Y")
			callpoint!.setColumnUndoData("APS_PARAMS.BR_INTERFACE","Y")
		endif
   callpoint!.setStatus("MODIFIED-REFRESH")
	endif
