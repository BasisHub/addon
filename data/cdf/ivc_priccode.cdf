[[IVC_PRICCODE.BWRI]]
rem --- compress zeroes
for y=1 to 9
	for x=1 to 9
		qty_var$="BREAK_QTY_"+str(x:"00")
		qty_var1$="BREAK_QTY_"+str(x+1:"00")
		disc_var$="BREAK_DISC_"+str(x:"00")
		disc_var1$="BREAK_DISC_"+str(x+1:"00")
		if num(field(rec_data$,qty_var$))=0
			field rec_data$,qty_var$=field(rec_data$,qty_var1$)
			field rec_data$,qty_var1$="0"
			field rec_data$,disc_var$=field(rec_data$,disc_var1$)
			field rec_data$,disc_var1$="0"
		endif
	next x
next y
callpoint!.setStatus("REFRESH")

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

rem --- make sure Margin over Cost margins don't exceed 100
	if callpoint!.getColumnData("IVC_PRICCODE.IV_PRICE_MTH")="M"
		gosub validate_margin
	endif

if ok$="N"
	callpoint!.setStatus("ABORT-REFRESH")
endif
	
[[IVC_PRICCODE.<CUSTOM>]]
validate_margin:
	ok$="Y"
	if callpoint!.getColumnData("IVC_PRICCODE.IV_PRICE_MTH")="M"
		for x=1 to 10
			disc_var$="BREAK_DISC_"+str(x:"00")
			if num(field(rec_data$,disc_var$))>=100
				msg_id$="IV_BADMARGIN"
				gosub disp_message
				ok$="N"
			endif
		next x
	endif
return

remove_process_bar: rem -- remove process bar
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
return

#include std_missing_params.src
[[IVC_PRICCODE.BSHO]]
num_files=2
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ARS_PARAMS",open_opts$[1]="OTA"
open_tables$[2]="IVS_PARAMS",open_opts$[2]="OTA"
gosub open_tables
ars_params_chn=num(open_chans$[1]),ars_params_tpl$=open_tpls$[1]
ivs_params_chn=num(open_chans$[2]),ivs_params_tpl$=open_tpls$[2]

rem --- check to see if main AR param rec (firm/AR/00) exists; if not, tell user to set it up first
	dim ars01a$:ars_params_tpl$
	ars01a_key$=firm_id$+"AR00"
	find record (ars_params_chn,key=ars01a_key$,err=*next) ars01a$
	if cvs(ars01a.current_per$,2)=""
		msg_id$="AR_PARAM_ERR"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		gosub remove_process_bar
		release
	endif

rem --- check to see if main IV param rec (firm/IV/00) exists; if not, tell user to set it up first
	dim ivs01a$:ivs_params_tpl$
	ivs01a_key$=firm_id$+"IV00"
	find record (ivs_params_chn,key=ivs01a_key$,err=*next) ivs01a$
	if cvs(ivs01a.warehouse_id$,2)=""
		msg_id$="IV_PARAM_ERR"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		gosub remove_process_bar
		release
	endif
	precision num(ivs01a.precision$)
