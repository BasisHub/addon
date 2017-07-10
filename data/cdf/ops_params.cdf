[[OPS_PARAMS.OP_CREATE_WO_TYP.AVAL]]
rem --- Verify WO Category of entered WO Type is Inventory Item

	wo_type$=callpoint!.getUserInput()
	wotypecd_dev=fnget_dev("SFC_WOTYPECD")
	dim wotypecd$:fnget_tpl$("SFC_WOTYPECD")
	findrecord(wotypecd_dev,key=firm_id$+"A"+wo_type$,dom=*next)wotypecd$
	if wotypecd.wo_category$<>"I" then
		msg_id$="AD_BAD_WO_CATEGORY"
		dim msg_tokens$[1]
		msg_tokens$[1]="Inventory Item"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[OPS_PARAMS.OP_CREATE_WO.AVAL]]
rem --- Disable and clear OP_CREATE_WO_TYP if not creating Work Orders

	op_create_wo$=callpoint!.getUserInput()
	if cvs(op_create_wo$,2)<>cvs(callpoint!.getColumnData("OPS_PARAMS.OP_CREATE_WO"),2) then
		if cvs(op_create_wo$,2)="" then
			callpoint!.setColumnData("OPS_PARAMS.OP_CREATE_WO_TYP","",1)
			callpoint!.setColumnEnabled("OPS_PARAMS.OP_CREATE_WO_TYP",0)
		else
			callpoint!.setColumnEnabled("OPS_PARAMS.OP_CREATE_WO_TYP",1)
		endif
	endif
[[OPS_PARAMS.ARAR]]
rem --- Update post_to_gl if GL is uninstalled
	if user_tpl.gl_installed$<>"Y" and callpoint!.getColumnData("OPS_PARAMS.POST_TO_GL")="Y" then
		callpoint!.setColumnData("OPS_PARAMS.POST_TO_GL","N",1)
		callpoint!.setStatus("MODIFIED")
	endif
[[OPS_PARAMS.ADIS]]

rem --- Default Line Code is required when Line Code Entry is skipped

if callpoint!.getColumnData("OPS_PARAMS.SKIP_LN_CODE")="Y"
	callpoint!.setTableColumnAttribute("OPS_PARAMS.LINE_CODE","MINL","1")
else
	callpoint!.setTableColumnAttribute("OPS_PARAMS.LINE_CODE","MINL","0")
endif

rem --- Reset OP_CREATE_WO and OP_CREATE_WO_TYP if no longer able to create WOs

	if user_tpl.sf_interface$<>"Y" and callpoint!.getColumnData("OPS_PARAMS.OP_CREATE_WO")<>"" then
		callpoint!.setColumnData("OPS_PARAMS.OP_CREATE_WO","",1)
		callpoint!.setColumnData("OPS_PARAMS.OP_CREATE_WO_TYP","",1)
		callpoint!.setStatus("SAVE")
	endif

rem --- Disable OP_CREATE_WO_TYP if not creating Work Orders

	if cvs(callpoint!.getColumnData("OPS_PARAMS.OP_CREATE_WO"),2)="" then
		callpoint!.setColumnEnabled("OPS_PARAMS.OP_CREATE_WO_TYP",0)
	endif
[[OPS_PARAMS.SKIP_LN_CODE.AVAL]]
rem --- Default Line Code is required when Line Code Entry is skipped

if callpoint!.getUserInput()="Y"
	callpoint!.setTableColumnAttribute("OPS_PARAMS.LINE_CODE","MINL","1")
else
	callpoint!.setTableColumnAttribute("OPS_PARAMS.LINE_CODE","MINL","0")
endif
[[OPS_PARAMS.AREC]]
rem --- Init new record
	callpoint!.setColumnData("OPS_PARAMS.INV_HIST_FLG","Y")
	if user_tpl.gl_installed$="Y" then callpoint!.setColumnData("OPS_PARAMS.POST_TO_GL","Y")
[[OPS_PARAMS.END_CMT_LINE.AVAL]]
beg_cmt$=callpoint!.getColumnData("OPS_PARAMS.BEG_CMT_LINE")
end_cmt$=callpoint!.getUserInput()
gosub validate_cmt_lines
[[OPS_PARAMS.BEG_CMT_LINE.AVAL]]
beg_cmt$=callpoint!.getUserInput()
end_cmt$=callpoint!.getColumnData("OPS_PARAMS.END_CMT_LINE")
gosub validate_cmt_lines
[[OPS_PARAMS.AREA]]
rem --- if not posting to GL, set 'print sales GL detail' flag to N as well

if user_tpl.gl_post$="N" then 
	callpoint!.setColumnData("OPS_PARAMS.PRT_GL_DET","N")
	ctl_name$="PRT_GL_DET"
	ctl_stat$="D"
	gosub disable_fields
endif
[[OPS_PARAMS.BSHO]]
rem --- Inits

	use ::ado_util.src::util

rem --- Are Bill Of Materials and Shop Floor installed?

	bm_sf$="N"
	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","BM",info$[all]
	bm$=info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","SF",info$[all]
	sf$=info$[20]
	if bm$="Y" and sf$="Y" then bm_sf$="Y"

rem --- Open files

	num_files=2
	if bm_sf$="Y" then num_files=4
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="ARS_PARAMS",open_opts$[2]="OTA"
	if bm_sf$="Y" then
		open_tables$[3]="SFS_PARAMS",open_opts$[3]="OTA"
		open_tables$[4]="SFC_WOTYPECD",open_opts$[4]="OTA"
	endif

	gosub open_tables

	gls01_dev=num(open_chans$[1])
	ars01_dev=num(open_chans$[2])

rem --- Dimension string templates

	dim gls01a$:open_tpls$[1]
	dim ars01a$:open_tpls$[2]

rem --- Check to see if main AR param rec (firm/AR/00) exists; if not, tell user to set it up first

	ars01a_key$=firm_id$+"AR00"
	find record (ars01_dev,key=ars01a_key$,err=*next) ars01a$
	if cvs(ars01a.current_per$,2)=""
		msg_id$="AR_PARAM_ERR"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		gosub remove_process_bar
		release
	endif

rem --- Check to see if main GL param rec (firm/GL/00) exists; if not, tell user to set it up first

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

rem --- Check if SF is interfacing with OP

rem wgh ... 9036 ... Temporarily disable ER 9036 changes until code complete.
bm_sf$="N"
	sf_interface$="N"
	if bm_sf$="Y" then
		sfs01_dev=num(open_chans$[3])
		dim sfs01a$:open_tpls$[3]
		findrecord(sfs01_dev,key=firm_id$+"SF00",dom=*endif)sfs01a$
		sf_interface$=sfs01a.ar_interface$
	endif

rem --- Retrieve parameter/application data

	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
	gl$=info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","AP",info$[all]
	ap$=info$[20],br$=info$[9]
	call stbl("+DIR_PGM")+"adc_application.aon","IV",info$[all]
	iv$=info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","OP",info$[all]
	gl_post$=info$[9]
	if gl$<>"Y" gl_post$="N"

	dim user_tpl$:"app:c(2),gl_installed:c(1),gl_post:c(1),"+
:                  "ap_installed:c(1),iv_installed:c(1),bank_rec:c(1),sf_interface:c(1)"

	user_tpl.app$="AR"
	user_tpl.gl_installed$=gl$
	user_tpl.ap_installed$=ap$
	user_tpl.iv_installed$=iv$
	user_tpl.bank_rec$=br$
	user_tpl.gl_post$=gl_post$
	user_tpl.sf_interface$=sf_interface$

	if user_tpl.gl_installed$<>"Y" then callpoint!.setColumnEnabled("OPS_PARAMS.POST_TO_GL",-1)
	if user_tpl.sf_interface$<>"Y" then
		callpoint!.setColumnEnabled("OPS_PARAMS.OP_CREATE_WO",-1)
		callpoint!.setColumnEnabled("OPS_PARAMS.OP_CREATE_WO_TYP",-1)
	endif

rem --- Resize window

	util.resizeWindow(Form!, SysGui!)
[[OPS_PARAMS.<CUSTOM>]]
validate_cmt_lines:
rem make sure beg/end cmt lines are blank or >0, <99, and that beg < end

beg_cmt=0
end_cmt=0
beg_cmt=num(beg_cmt$,err=*next)
end_cmt=num(end_cmt$,err=*next)
passed$=""

if cvs(beg_cmt$,3)<>"" and cvs(end_cmt$,3)<>""
	if beg_cmt<=0 or beg_cmt>99 or beg_cmt>end_cmt or
:	   end_cmt<=0 or end_cmt>99 or end_cmt<beg_cmt
		passed$="N"
	endif
else
	if cvs(beg_cmt$,3)<>""
		if beg_cmt<=0 or beg_cmt>99
			passed$="N"
		endif
	endif
else
	if cvs(end_cmt$,3)<>""
		if end_cmt<=0 or end_cmt>99
			passed$="N"
		endif
	endif
endif

if passed$="N"
	msg_id$="OP_INVAL_CMT"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif

return

remove_process_bar:

bbjAPI!=bbjAPI()
rdFuncSpace!=bbjAPI!.getGroupNamespace()
rdFuncSpace!.setValue("+build_task","OFF")

return

disable_fields:
	rem --- used to disable/enable controls
	rem --- ctl_name$ sent in with name of control to enable/disable (format "ALIAS.CONTROL_NAME")
	rem --- ctl_stat$ sent in as D or space, meaning disable/enable, respectively

	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")

return

#include std_missing_params.src
