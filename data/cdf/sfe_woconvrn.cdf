[[SFE_WOCONVRN.BEND]]
rem --- Remove software lock on batch when batching
	batch$=stbl("+BATCH_NO",err=*next)
	if num(batch$)<>0
		lock_table$="ADM_PROCBATCHES"
		lock_record$=firm_id$+stbl("+PROCESS_ID")+batch$
		lock_type$="X"
		lock_status$=""
		lock_disp$=""
		call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$
	endif
[[SFE_WOCONVRN.BTBL]]
rem --- Get Batch information
	call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]
	callpoint!.setTableColumnAttribute("SFE_WOCONVRN.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[SFE_WOCONVRN.ADIS]]
rem --- Get and display work order data
	wo_no$=callpoint!.getColumnData("SFE_WOCONVRN.WO_NO")
	womastr_dev=fnget_dev("@SFE_WOMASTR")
	dim womastr$:fnget_tpl$("@SFE_WOMASTR")
	womastr_key$=firm_id$+callpoint!.getColumnData("SFE_WOCONVRN.WO_LOCATION")+wo_no$
	readrecord(womastr_dev,key=womastr_key$)womastr$
	callpoint!.setColumnData("<<DISPLAY>>.BILL_REV",womastr.bill_rev$,1)
	callpoint!.setColumnData("<<DISPLAY>>.CLOSED_DATE",womastr.closed_date$,1)
	callpoint!.setColumnData("<<DISPLAY>>.CLS_CST_TODT",str(womastr.cls_cst_todt),1)
	callpoint!.setColumnData("<<DISPLAY>>.DESCRIPTION_01",womastr.description_01$,1)
	callpoint!.setColumnData("<<DISPLAY>>.DESCRIPTION_02",womastr.description_02$,1)
	callpoint!.setColumnData("<<DISPLAY>>.DRAWING_NO",womastr.drawing_no$,1)
	callpoint!.setColumnData("<<DISPLAY>>.DRAWING_REV",womastr.drawing_rev$,1)
	callpoint!.setColumnData("<<DISPLAY>>.ITEM_ID",womastr.item_id$,1)
	callpoint!.setColumnData("<<DISPLAY>>.OPENED_DATE",womastr.opened_date$,1)
	callpoint!.setColumnData("<<DISPLAY>>.QTY_CLS_TODT",str(womastr.qty_cls_todt),1)
	callpoint!.setColumnData("<<DISPLAY>>.SCH_PROD_QTY",str(womastr.sch_prod_qty),1)
	callpoint!.setColumnData("<<DISPLAY>>.UNIT_MEASURE",womastr.unit_measure$,1)
	callpoint!.setColumnData("<<DISPLAY>>.WO_CATEGORY",womastr.wo_category$,1)
	callpoint!.setColumnData("<<DISPLAY>>.WO_STATUS",womastr.wo_status$,1)
	callpoint!.setColumnData("<<DISPLAY>>.WO_TYPE",womastr.wo_type$,1)

rem --- Update totals
	gosub update_totals
[[SFE_WOCONVRN.OVHD_RATE.AVAL]]
rem --- Update totals
	ovhd_rate=num(callpoint!.getUserInput())
	callpoint!.setColumnData("SFE_WOCONVRN.OVHD_RATE",str(ovhd_rate))
	gosub update_totals
[[SFE_WOCONVRN.HRS.AVAL]]
rem --- Update totals
	hrs=num(callpoint!.getUserInput())
	callpoint!.setColumnData("SFE_WOCONVRN.HRS",str(hrs))
	gosub update_totals
[[SFE_WOCONVRN.DIRECT_RATE.AVAL]]
rem --- Update totals
	direct_rate=num(callpoint!.getUserInput())
	callpoint!.setColumnData("SFE_WOCONVRN.DIRECT_RATE",str(direct_rate))
	gosub update_totals
[[SFE_WOCONVRN.ACT_SUB_TOT.AVAL]]
rem --- Update totals
	act_sub_tot=num(callpoint!.getUserInput())
	callpoint!.setColumnData("SFE_WOCONVRN.ACT_SUB_TOT",str(act_sub_tot))
	gosub update_totals
[[SFE_WOCONVRN.ACT_MAT_TOT.AVAL]]
rem --- Update totals
	act_mat_tot=num(callpoint!.getUserInput())
	callpoint!.setColumnData("SFE_WOCONVRN.ACT_MAT_TOT",str(act_mat_tot))
	gosub update_totals
[[SFE_WOCONVRN.WO_NO.AVAL]]
rem --- Get work order data
	wo_no$=callpoint!.getUserInput()
	womastr_dev=fnget_dev("@SFE_WOMASTR")
	dim womastr$:fnget_tpl$("@SFE_WOMASTR")
	womastr_key$=firm_id$+callpoint!.getColumnData("SFE_WOCONVRN.WO_LOCATION")+wo_no$
	readrecord(womastr_dev,key=womastr_key$)womastr$

rem --- Work order cannot be closed
	if womastr.wo_status$="C"
		msg_id$="WO_NOT_OPEN"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Operations must be set up for work order
	wooprtn_dev=fnget_dev("@SFE_WOOPRTN")
	read(wooprtn_dev,key=womastr_key$,dom=*next)
	wooprtn_key$=""
	wooprtn_key$=key(wooprtn_dev,end=*next)
	if pos(womastr_key$=wooprtn_key$)<>1 then
		msg_id$="SF_WO_OPS_MISSING"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Display work order data
	callpoint!.setColumnData("<<DISPLAY>>.BILL_REV",womastr.bill_rev$,1)
	callpoint!.setColumnData("<<DISPLAY>>.CLOSED_DATE",womastr.closed_date$,1)
	callpoint!.setColumnData("<<DISPLAY>>.CLS_CST_TODT",str(womastr.cls_cst_todt),1)
	callpoint!.setColumnData("<<DISPLAY>>.DESCRIPTION_01",womastr.description_01$,1)
	callpoint!.setColumnData("<<DISPLAY>>.DESCRIPTION_02",womastr.description_02$,1)
	callpoint!.setColumnData("<<DISPLAY>>.DRAWING_NO",womastr.drawing_no$,1)
	callpoint!.setColumnData("<<DISPLAY>>.DRAWING_REV",womastr.drawing_rev$,1)
	callpoint!.setColumnData("<<DISPLAY>>.ITEM_ID",womastr.item_id$,1)
	callpoint!.setColumnData("<<DISPLAY>>.OPENED_DATE",womastr.opened_date$,1)
	callpoint!.setColumnData("<<DISPLAY>>.QTY_CLS_TODT",str(womastr.qty_cls_todt),1)
	callpoint!.setColumnData("<<DISPLAY>>.SCH_PROD_QTY",str(womastr.sch_prod_qty),1)
	callpoint!.setColumnData("<<DISPLAY>>.UNIT_MEASURE",womastr.unit_measure$,1)
	callpoint!.setColumnData("<<DISPLAY>>.WO_CATEGORY",womastr.wo_category$,1)
	callpoint!.setColumnData("<<DISPLAY>>.WO_STATUS",womastr.wo_status$,1)
	callpoint!.setColumnData("<<DISPLAY>>.WO_TYPE",womastr.wo_type$,1)
[[SFE_WOCONVRN.<CUSTOM>]]
#include std_missing_params.src

rem ==========================================================================
update_totals: rem --- Update totals
rem ==========================================================================
	hrs=num(callpoint!.getColumnData("SFE_WOCONVRN.HRS"))
	direct_rate=num(callpoint!.getColumnData("SFE_WOCONVRN.DIRECT_RATE"))
	ovhd_rate=num(callpoint!.getColumnData("SFE_WOCONVRN.OVHD_RATE"))
	act_ops_tot=round(hrs*direct_rate*(1+ovhd_rate),2)
	callpoint!.setColumnData("SFE_WOCONVRN.ACT_OPS_TOT",str(act_ops_tot),1)

	act_mat_tot=num(callpoint!.getColumnData("SFE_WOCONVRN.ACT_MAT_TOT"))
	act_sub_tot=num(callpoint!.getColumnData("SFE_WOCONVRN.ACT_SUB_TOT"))
	wip_tot=act_ops_tot+act_mat_tot+act_sub_tot
	callpoint!.setColumnData("<<DISPLAY>>.WIP_TOTAL",str(wip_tot),1)
	return	
[[SFE_WOCONVRN.BSHO]]
rem --- Open Files
	num_files=6
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFS_PARAMS",open_opts$[1]="OTA@"
	open_tables$[2]="IVS_PARAMS",open_opts$[2]="OTA@"
	open_tables$[3]="SFE_WOMASTR",open_opts$[3]="OTA@"
	open_tables$[4]="SFE_WOOPRTN",open_opts$[4]="OTA@"
	open_tables$[5]="SFC_WOTYPECD",open_opts$[5]="OTA@"
	open_tables$[6]="IVM_ITEMMAST",open_opts$[6]="OTA@"

	gosub open_tables

	sfs_params_dev=num(open_chans$[1]),sfs_params_tpl$=open_tpls$[1]
	ivs_params_dev=num(open_chans$[2]),ivs_params_tpl$=open_tpls$[2]

rem --- Get SF parameters
	dim sfs_params$:sfs_params_tpl$
	read record (sfs_params_dev,key=firm_id$+"SF00",dom=std_missing_params) sfs_params$
	gl$="N"; rem --- Conversion Work Order tasks do not hit GL

	if gl$="Y"
		gl$="N"
		status=0
		source$=pgm(-2)
		call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"SF",glw11$,gl$,status
		if status<>0 goto std_exit
	endif
	callpoint!.setDevObject("gl",gl$)

rem --- Get IV parameters
	dim ivs_params$:ivs_params_tpl$
	read record (ivs_params_dev,key=firm_id$+"IV00",dom=std_missing_params) ivs_params$
	precision$=ivs_params.precision$
	callpoint!.setDevObject("precision",precision$)
	precision num(precision$)
