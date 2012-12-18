[[SFE_WOMASTR.AOPT-LSNO]]
rem --- launch sfe_wolotser form to assign lot/serial numbers
rem --- should only be enabled if on an inventory type WO, if item is lotted/serialized, and if params have LS set.
	callpoint!.setDevObject("warehouse_id",callpoint!.getColumnData("SFE_WOMASTR.WAREHOUSE_ID"))
	callpoint!.setDevObject("item_id",callpoint!.getColumnData("SFE_WOMASTR.ITEM_ID"))
	callpoint!.setDevObject("cls_inp_qty",callpoint!.getColumnData("SFE_WOMASTR.CLS_INP_QTY"))
	callpoint!.setDevObject("qty_cls_todt",callpoint!.getColumnData("SFE_WOMASTR.QTY_CLS_TODT"))
	callpoint!.setDevObject("closed_cost",callpoint!.getColumnData("SFE_WOMASTR.CLOSED_COST"))
	callpoint!.setDevObject("wolotser_action","schedule")

	key_pfx$=firm_id$+callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")+callpoint!.getColumnData("SFE_WOMASTR.WO_NO")

	dim dflt_data$[3,1]
	dflt_data$[1,0]="SFE_WOLOTSER.FIRM_ID"
	dflt_data$[1,1]=firm_id$
	dflt_data$[2,0]="SFE_WOLOTSER.WO_LOCATION"
	dflt_data$[2,1]=callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")
	dflt_data$[3,0]="SFE_WOLOTSER.WO_NO"
	dflt_data$[3,1]=callpoint!.getColumnData("SFE_WOMASTR.WO_NO")

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"SFE_WOLOTSER",
:		stbl("+USER_ID"),
:		access$,
:		key_pfx$,
:		table_chans$[all],
:		"",
:		dflt_data$[all]
[[SFE_WOMASTR.AOPT-DRPT]]
rem --- WO Detail Report (Hard Copy)

	key_pfx$=firm_id$+callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")+callpoint!.getColumnData("SFE_WOMASTR.WO_NO")

	dim dflt_data$[3,1]
	dflt_data$[1,0]="FIRM_ID"
	dflt_data$[1,1]=firm_id$
	dflt_data$[2,0]="WO_LOCATION"
	dflt_data$[2,1]=callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")
	dflt_data$[3,0]="WO_NO"
	dflt_data$[3,1]=callpoint!.getColumnData("SFE_WOMASTR.WO_NO")

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"SFR_WOHARDCOPY",
:		stbl("+USER_ID"),
:		access$,
:		key_pfx$,
:		table_chans$[all],
:		"",
:		dflt_data$[all]
[[SFE_WOMASTR.BDEL]]
rem --- cascade delete will take care of removing:
rem ---   requirements (sfe_wooprtn/sfe-02, sfe_womatl/sfe-22, sfe_wosubcnt/sfe-32)
rem ---   comments (sfe_wocomnt/sfe-07)
rem ---   sfe_closedwo, sfe_openedwo, sfe_wocommit, sfe_wotrans (the old sfe-04 A/B/C/D recs)
rem --- otherwise, need to:
rem --- 1. remove sfe_womathdr/sfe_womatdtl (sfe-13/23) and uncommit inventory
rem --- 2. reduce on-order if it's an inventory-category work order that's in "open" status
rem --- 3. remove schedule detail (sfe_woschdl/sfm-05)

	wo_location$=callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")
	wo_no$=callpoint!.getColumnData("SFE_WOMASTR.WO_NO")

	sfe13_dev=fnget_dev("SFE_WOMATHDR")
	dim sfe_womathdr$:fnget_tpl$("SFE_WOMATHDR")
	sfe23_dev=fnget_dev("SFE_WOMATDTL")
	dim sfe_womatdtl$:fnget_tpl$("SFE_WOMATDTL")
	
	rem --- Initialize inventory item update
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

rem --- Loop thru materials detail - uncommit lot/serial only (i.e. atamo uncommits both item and lot/serial, so re-commit item and uncommit that qty later)

	read (sfe13_dev,key=firm_id$+wo_location$+wo_no$,dom=*next,dir=0)
	while 1
		sfe13_key$=key(sfe13_dev,end=*break)
		read record (sfe13_dev)sfe_womathdr$
		if pos(firm_id$+wo_location$+wo_no$=sfe13_key$)<>1 then break

		read (sfe23_dev,key=firm_id$+wo_location$+wo_no$,dom=*next)
		while 1
			sfe23_key$=key(sfe23_dev,end=*break)
			read record(sfe23_dev)sfe_womatdtl$
			if pos(firm_id$+wo_location$+wo_no$=sfe23_key$)<>1 then break
					
			rem --- Uncommit inventory
			items$[1]=sfe_womatdtl.warehouse_id$
			items$[2]=sfe_womatdtl.item_id$
			items$[3]=""
			refs[0]=max(0,sfe_womatdtl.qty_ordered-sfe_womatdtl.tot_qty_iss)
			call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
rem escape;rem have uncommitted IV, now removing sfe23 - temp; remove after testing CAH
			remove(sfe23_dev,key=sfe23_key$)
		wend
rem escape;rem have processed sfe23's and uncommitted, now removing sfe13 - temp; remove after testing CAH
		remove (sfe13_dev,key=sfe13_key$);rem bottom of 13/23 loop
		break; rem should only be one sfe-13 per work order
	wend

rem --- Remove sfm-05 (sfe_woschdl)

	sfm05_dev=fnget_dev("SFE_WOSCHDL")
	dim sfe_woschdl$:fnget_tpl$("SFE_WOSCHDL")
	
	read (sfm05_dev,key=firm_id$+wo_no$,knum=AO_WONUM,dom=*next)

	while 1
		read record(sfm05_dev,end=*break)sfe_woschdl$
		if sfe_woschdl.firm_id$+sfe_woschdl.wo_no$<>firm_id$+wo_no$ then continue
		remove (sfm05_dev,key=sfe_woschdl.firm_id$+sfe_woschdl.op_code$+sfe_woschdl.sched_date$+sfe_woschdl.wo_no$+sfe_woschdl.oper_seq_ref$,dom=*next)
	wend

	read (sfm05_dev,key="",knum=0,dom=*next);rem --- reset knum to primary

rem --- Reduce on order for scheduled prod qty

	if callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS")="O" and callpoint!.getColumnData("SFE_WOMASTR.WO_CATEGORY")="I"
rem escape;rem reduce OO - temp; remove after testing CAH 	
		items$[1]=callpoint!.getColumnData("SFE_WOMASTR.WAREHOUSE_ID")
		items$[2]=callpoint!.getColumnData("SFE_WOMASTR.ITEM_ID")
		refs[0]=-(num(callpoint!.getColumnData("SFE_WOMASTR.SCH_PROD_QTY"))-num(callpoint!.getColumnData("SFE_WOMASTR.QTY_CLS_TODT")))
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon","OO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
	endif
[[SFE_WOMASTR.BDEQ]]
rem --- cannot delete closed work order

	if callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS")="C"
		callpoint!.setMessage("SF_NO_DELETE")
		callpoint!.setStatus("ABORT")
	else

rem --- prior to deleting a work order, need to check for open transactions; if any exist, can't delete

		wo_loc$=callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")
		wo_no$=callpoint!.getColumnData("SFE_WOMASTR.WO_NO")
		can_delete$="YES"

		for files=1 to 3
			if files=1
				wotran_dev=fnget_dev("SFT_OPNOPRTR")
				dim wotran$:fnget_tpl$("SFT_OPNOPRTR")
			endif
			if files=2
				wotran_dev=fnget_dev("SFT_OPNMATTR")
				dim wotran$:fnget_tpl$("SFT_OPNMATTR")
			endif
			if files=3
				wotran_dev=fnget_dev("SFT_OPNSUBTR")
				dim wotran$:fnget_tpl$("SFT_OPNSUBTR")
			endif
			read(wotran_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)

			while 1
				wotran_key$=key(wotran_dev,end=*break)
				if pos(firm_id$+wo_loc$+wo_no$=wotran_key$)=1 then can_delete$="NO"
				break
			wend
		next files

		sfe15_dev=fnget_dev("SFE_WOMATISH")
		read (sfe15_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)
		while 1
			sfe15_key$=key(sfe15_dev,end=*break)
			if pos(firm_id$+wo_loc$+wo_no$=sfe15_key$)=1 then can_delete$="NO"
			break
		wend

		if can_delete$="NO"
			callpoint!.setMessage("SF_OPEN_TRANS")
			callpoint!.setStatus("ABORT")
		endif
	endif
	
[[SFE_WOMASTR.AFMC]]
rem --- The type of code seen below is often done in BSHO, but the code at the end that changes the prompt for the Bill/Item control
rem --- won't work there (too late).

rem --- Set new record flag

	callpoint!.setDevObject("new_rec","Y")

rem --- Open tables

	num_files=25
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="SFS_PARAMS",open_opts$[2]="OTA"
	open_tables$[3]="SFC_WOTYPECD",open_opts$[3]="OTA"
	open_tables$[4]="SFT_OPNMATTR",open_opts$[4]="OTA"
	open_tables$[5]="SFT_OPNOPRTR",open_opts$[5]="OTA"
	open_tables$[6]="SFT_OPNSUBTR",open_opts$[6]="OTA"
	
	open_tables$[8]="OPE_ORDHDR",open_opts$[8]="OTA"
	open_tables$[9]="OPE_ORDDET",open_opts$[9]="OTA"
	open_tables$[10]="IVM_ITEMMAST",open_opts$[10]="OTA"
	open_tables$[11]="OPC_LINECODE",open_opts$[11]="OTA"
	open_tables$[12]="GLS_PARAMS",open_opts$[12]="OTA"
	open_tables$[13]="SFT_CLSMATTR",open_opts$[13]="OTA"
	open_tables$[14]="SFT_CLSOPRTR",open_opts$[14]="OTA"
	open_tables$[15]="SFT_CLSSUBTR",open_opts$[15]="OTA"
	open_tables$[16]="SFT_CLSLSTRN",open_opts$[16]="OTA"
	open_tables$[17]="SFT_OPNLSTRN",open_opts$[17]="OTA"
	open_tables$[18]="IVM_ITEMWHSE",open_opts$[18]="OTA"
	open_tables$[19]="SFE_WOSCHDL",open_opts$[19]="OTA"
	open_tables$[20]="SFE_WOMATHDR",open_opts$[20]="OTA"
	open_tables$[21]="SFE_WOMATDTL",open_opts$[21]="OTA"
	open_tables$[22]="SFE_WOMATISH",open_opts$[22]="OTA"
	open_tables$[23]="SFE_WOMATISD",open_opts$[23]="OTA"
	open_tables$[24]="SFE_WOLSISSU",open_opts$[24]="OTA"
	open_tables$[25]="SFE_WOLOTSER",open_opts$[25]="OTA"

	gosub open_tables

	sfs_params=num(open_chans$[2])
	dim sfs_params$:open_tpls$[2]
	read record (sfs_params,key=firm_id$+"SF00",dom=std_missing_params) sfs_params$

	gls_params=num(open_chans$[12])
	call stbl("+DIR_PGM")+"adc_perioddates.aon",gls_params,num(sfs_params.current_per$),num(sfs_params.current_year$),beg_date$,end_date$,status
	callpoint!.setDevObject("gl_end_date",end_date$)

	ivs_params=num(open_chans$[1])
	dim ivs_params$:open_tpls$[1]
	read record (ivs_params,key=firm_id$+"IV00",dom=std_missing_params) ivs_params$
	callpoint!.setDevObject("default_wh",ivs_params.warehouse_id$)
	callpoint!.setDevObject("lotser",ivs_params.lotser_flag$)
	callpoint!.setDevObject("iv_precision",ivs_params.precision$)

	bm$=sfs_params.bm_interface$
	op$=sfs_params.ar_interface$
	po$=sfs_params.po_interface$
	pr$=sfs_params.pr_interface$

	if pos(ivs_params.lotser_flag$="LS") then
		num_files=1
		dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

		open_tables$[1]="IVM_LSMASTER",open_opts$[1]="OTA@"

		gosub open_tables
	endif

	num_files=6
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	if bm$="Y"
		call stbl("+DIR_PGM")+"adc_application.aon","BM",info$[all]
		bm$=info$[20]
	endif

	if bm$<>"Y"
		open_tables$[1]="SFC_OPRTNCOD",open_opts$[1]="OTA"
	else
		open_tables$[1]="BMC_OPCODES",open_opts$[1]="OTA"
		open_tables$[2]="BMM_BILLMAST",open_opts$[2]="OTA"
		open_tables$[3]="BMM_BILLCMTS",open_opts$[3]="OTA"
		open_tables$[4]="BMM_BILLMAT",open_opts$[4]="OTA"
		open_tables$[5]="BMM_BILLOPER",open_opts$[5]="OTA"
		open_tables$[6]="BMM_BILLSUB",open_opts$[6]="OTA"
	endif

	callpoint!.setDevObject("bm",bm$)
	x$=stbl("bm",bm$);rem for downstream rpt when callpoint! object not defined

	gosub open_tables

	callpoint!.setDevObject("opcode_chan",num(open_chans$[1]))
	callpoint!.setDevObject("opcode_tpl",open_tpls$[1])

	if op$="Y"
		call stbl("+DIR_PGM")+"adc_application.aon","AR",info$[all]
		ar$=info$[20]
		call stbl("+DIR_PGM")+"adc_application.aon","OP",info$[all]
		op$=info$[20]
	endif
	callpoint!.setDevObject("ar",ar$)
	callpoint!.setDevObject("op",op$)

	if po$="Y"
		call stbl("+DIR_PGM")+"adc_application.aon","PO",info$[all]
		po$=info$[20]

		num_files=2
		dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

		open_tables$[1]="POE_PODET",open_opts$[1]="OTA"
		open_tables$[2]="POE_REQDET",open_opts$[2]="OTA"

		gosub open_tables

	endif
	callpoint!.setDevObject("po",po$)
	x$=stbl("po",po$)

	if pr$="Y"
		call stbl("+DIR_PGM")+"adc_application.aon","PR",info$[all]
		pr$=info$[20]
	endif
	callpoint!.setDevObject("pr",pr$)
	x$=stbl("pr",pr$)

	call stbl("+DIR_PGM")+"adc_application.aon","MP",info$[all]
	callpoint!.setDevObject("mp",info$[20])
	mp$=info$[20]

rem --- alter control label and prompt for Bill No vs. Item ID depending on whether or not bm$=Y
	
	wctl!=callpoint!.getControl("ITEM_ID")
	wctl_id=wctl!.getID()-1000
	wcontext=num(callpoint!.getTableColumnAttribute("SFE_WOMASTR.ITEM_ID","CTLC"))
	lbl_ctl!=SysGUI!.getWindow(wcontext).getControl(wctl_id)
	if bm$="Y"
		lbl_ctl!.setText(Translate!.getTranslation("AON_BILL_NUMBER:","Bill Number:",1))
		callpoint!.setTableColumnAttribute("SFE_WOMASTR.ITEM_ID","PROM",Translate!.getTranslation("AON_ENTER_BILL_NUMBER","Enter a valid Bill of Materials number",1))
		callpoint!.setTableColumnAttribute("SFE_WOMASTR.ITEM_ID", "IDEF", "BOM_LOOKUP")
	else
		lbl_ctl!.setText(Translate!.getTranslation("AON_INVENTORY_ITEM_ID:","Inventory Item ID:",1))
		callpoint!.setTableColumnAttribute("SFE_WOMASTR.ITEM_ID","PROM",Translate!.getTranslation("AON_ENTER_INVENTORY_ITEM_ID","Enter a valid Inventory Item ID",1))
	endif
[[SFE_WOMASTR.WO_NO.AVAL]]
rem --- put WO number and loc in DevObject

	callpoint!.setDevObject("wo_no",callpoint!.getUserInput())
	callpoint!.setDevObject("wo_loc",callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION"))
[[SFE_WOMASTR.OPENED_DATE.AVAL]]
rem --- need to see if date has been changed; if so, prompt to change in sfe-02/22/23 as well

	prev_dt$=cvs(callpoint!.getColumnUndoData("SFE_WOMASTR.OPENED_DATE"),3)
	new_dt$=callpoint!.getUserInput()
	if prev_dt$<>"" and prev_dt$<>new_dt$
		msg_id$="SF_CHANGE_DTS"
		gosub disp_message

		if msg_opt$="Y"
			sfe02_dev=fnget_dev("SFE_WOOPRTN")
			sfe22_dev=fnget_dev("SFE_WOMATL")
			sfe23_dev=fnget_dev("SFE_WOMATDTL")

			dim sfe_wooprtn$:fnget_tpl$("SFE_WOOPRTN")
			dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")
			dim sfe_womatdtl$:fnget_tpl$("SFE_WOMATDTL")

			wo_loc$=callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")
			wo_no$=callpoint!.getColumnData("SFE_WOMASTR.WO_NO")

			rem --- operations requirements - 6500 in sfe_ab
			read (sfe02_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)
			while 1
				k$=key(sfe02_dev,end=*break)
				readrecord(sfe02_dev)sfe_wooprtn$
				if sfe_wooprtn.firm_id$+sfe_wooprtn.wo_location$+sfe_wooprtn.wo_no$<>firm_id$+wo_loc$+wo_no$ then break
				sfe_wooprtn.require_date$=new_dt$
				sfe_wooprtn$=field(sfe_wooprtn$)
				writerecord(sfe02_dev)sfe_wooprtn$
			wend
	
			rem --- materials requirements - 6600 in sfe_ab
			read (sfe22_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)
			while 1
				k$=key(sfe22_dev,end=*break)
				readrecord(sfe22_dev)sfe_womatl$
				if sfe_womatl.firm_id$+sfe_womatl.wo_location$+sfe_womatl.wo_no$<>firm_id$+wo_loc$+wo_no$ then break
				sfe_womatl.require_date$=new_dt$
				sfe_womatl$=field(sfe_womatl$)
				writerecord(sfe22_dev)sfe_womatl$
			wend

			rem --- materials commitments - 6800 in sfe_ab
			read (sfe23_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)
			while 1
				k$=key(sfe23_dev,end=*break)
				readrecord(sfe23_dev)sfe_womatdtl$
				if sfe_womatdtl.firm_id$+sfe_womatdtl.wo_location$+sfe_womatdtl.wo_no$<>firm_id$+wo_loc$+wo_no$ then break
				sfe_womatdtl.require_date$=new_dt$
				sfe_womatdtl$=field(sfe_womatdtl$)
				writerecord(sfe23_dev)sfe_womatdtl$
			wend

		endif
	endif
[[SFE_WOMASTR.ADIS]]
rem --- Set new record flag

	callpoint!.setDevObject("new_rec","N")
	callpoint!.setDevObject("wo_status",callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS"))
	callpoint!.setDevObject("wo_category",callpoint!.getColumnData("SFE_WOMASTR.WO_CATEGORY"))
	callpoint!.setDevObject("wo_no",callpoint!.getColumnData("SFE_WOMASTR.WO_NO"))
	callpoint!.setDevObject("wo_loc",callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION"))

rem --- Disable/enable based on status of closed/open

	if callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS")="C"
		callpoint!.setColumnEnabled("SFE_WOMASTR.ITEM_ID",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.BILL_REV",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.CUSTOMER_ID",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.DESCRIPTION_01",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.DESCRIPTION_02",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.DRAWING_NO",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.DRAWING_REV",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.EST_YIELD",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.FORECAST",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.ORDER_NO",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.OP_INT_SEQ_NO",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.OPENED_DATE",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.PRIORITY",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.SCH_PROD_QTY",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.UNIT_MEASURE",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.WAREHOUSE_ID",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.WO_TYPE",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.WO_STATUS",0)
	else
		callpoint!.setColumnEnabled("SFE_WOMASTR.ITEM_ID",1)
		callpoint!.setColumnEnabled("SFE_WOMASTR.BILL_REV",1)
		if callpoint!.getDevObject("ar")="Y"
			callpoint!.setColumnEnabled("SFE_WOMASTR.CUSTOMER_ID",1)
		endif
		callpoint!.setColumnEnabled("SFE_WOMASTR.DESCRIPTION_01",1)
		callpoint!.setColumnEnabled("SFE_WOMASTR.DESCRIPTION_02",1)
		callpoint!.setColumnEnabled("SFE_WOMASTR.DRAWING_NO",1)
		callpoint!.setColumnEnabled("SFE_WOMASTR.DRAWING_REV",1)
		callpoint!.setColumnEnabled("SFE_WOMASTR.EST_YIELD",1)
		if callpoint!.getDevObject("mp")="Y"
			callpoint!.setColumnEnabled("SFE_WOMASTR.FORECAST",1)
		endif
		callpoint!.setColumnEnabled("SFE_WOMASTR.OPENED_DATE",1)
		if callpoint!.getDevObject("op")="Y"			
			callpoint!.setColumnEnabled("SFE_WOMASTR.ORDER_NO",1)
			callpoint!.setColumnEnabled("SFE_WOMASTR.OP_INT_SEQ_NO",1)
		endif
		callpoint!.setColumnEnabled("SFE_WOMASTR.PRIORITY",1)
		callpoint!.setColumnEnabled("SFE_WOMASTR.SCH_PROD_QTY",1)
		callpoint!.setColumnEnabled("SFE_WOMASTR.UNIT_MEASURE",1)
		callpoint!.setColumnEnabled("SFE_WOMASTR.WAREHOUSE_ID",1)
		callpoint!.setColumnEnabled("SFE_WOMASTR.WO_TYPE",1)
		callpoint!.setColumnEnabled("SFE_WOMASTR.WO_STATUS",1)
	endif

rem --- Disable Options (buttons) for a Closed Work Order

	if callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS")="C"
		callpoint!.setOptionEnabled("SCHD",0)
		callpoint!.setOptionEnabled("RELS",0)
	else
		callpoint!.setOptionEnabled("SCHD",1)
		callpoint!.setOptionEnabled("RELS",1)
	endif

rem -- Disable Lot/Serial button if no LS

	if callpoint!.getColumnData("SFE_WOMASTR.WO_CATEGORY")="I" and callpoint!.getColumnData("SFE_WOMASTR.LOTSER_ITEM")="Y" and callpoint!.getDevObject("lotser")<>"N"
		callpoint!.setOptionEnabled("LSNO",1)
	else
		callpoint!.setOptionEnabled("LSNO",0)
	endif

rem --- Always disable these fields for an existing record

	callpoint!.setColumnEnabled("SFE_WOMASTR.ITEM_ID",0)
	callpoint!.setColumnEnabled("SFE_WOMASTR.DESCRIPTION_01",0)
	callpoint!.setColumnEnabled("SFE_WOMASTR.DESCRIPTION_02",0)

rem --- disable Copy function if closed or not an N category

	if callpoint!.getColumnData("SFE_WOMASTR.WO_CATEGORY")<>"N" or callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS")="C"
		callpoint!.setOptionEnabled("COPY",0)
	else
		callpoint!.setOptionEnabled("COPY",1)
	endif

rem --- See if any transactions exist - disable WO Type if so

	loc$=callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")
	wo_no$=callpoint!.getColumnData("SFE_WOMASTR.WO_NO")
	trans$="N"
	chan_dev=fnget_dev("SFT_OPNMATTR")
	dim chan_rec$:fnget_tpl$("SFT_OPNMATTR")
	read (chan_dev,key=firm_id$+loc$+wo_no$,dom=*next)
	while 1
		read record (chan_dev,end=*break) chan_rec$
		if chan_rec.firm_id$<>firm_id$ or
:			chan_rec.wo_location$<>loc$ or
:			chan_rec.wo_no$<>wo_no$ break
		tran$="Y"
		break
	wend

	if tran$="N"
		chan_dev=fnget_dev("SFT_OPNOPRTR")
		dim chan_rec$:fnget_tpl$("SFT_OPNOPRTR")
		read (chan_dev,key=firm_id$+loc$+wo_no$,dom=*next)
		while 1
			read record (chan_dev,end=*break) chan_rec$
			if chan_rec.firm_id$<>firm_id$ or
:				chan_rec.wo_location$<>loc$ or
:				chan_rec.wo_no$<>wo_no$ break
			tran$="Y"
			break
		wend
	endif

	if tran$="N"
		chan_dev=fnget_dev("SFT_OPNSUBTR")
		dim chan_rec$:fnget_tpl$("SFT_OPNSUBTR")
		read (chan_dev,key=firm_id$+loc$+wo_no$,dom=*next)
		while 1
			read record (chan_dev,end=*break) chan_rec$
			if chan_rec.firm_id$<>firm_id$ or
:				chan_rec.wo_location$<>loc$ or
:				chan_rec.wo_no$<>wo_no$ break
			tran$="Y"
			break
		wend
	endif

	if tran$="Y"
		callpoint!.setColumnEnabled("SFE_WOMASTR.WO_TYPE",0)
	endif

rem --- Disable WO Status if Open or Closed

	status$=callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS")
	if pos(status$="OC")=0
		callpoint!.setColumnEnabled("SFE_WOMASTR.WO_STATUS",1)
	else
		callpoint!.setColumnEnabled("SFE_WOMASTR.WO_STATUS",0)
	endif

rem --- Validate Open Sales Order

	order$=callpoint!.getColumnData("SFE_WOMASTR.ORDER_NO")
	cust$=callpoint!.getColumnData("SFE_WOMASTR.CUSTOMER_ID")
	dim ope_ordhdr$:fnget_tpl$("OPE_ORDHDR")
	gosub build_ord_line

rem --- Disable qty/yield if data exists in sfe_womatl (sfe-22)

	if callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS")<>"C" and callpoint!.getColumnData("SFE_WOMASTR.WO_CATEGORY")="I"

		sfe_womatl_dev=fnget_dev("SFE_WOMATL")
		dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")

		read (sfe_womatl_dev,key=firm_id$+loc$+wo_no$,dom=*next)
		while 1
			read record (sfe_womatl_dev,end=*break)sfe_womatl$
			if sfe_womatl$.firm_id$+sfe_womatl.wo_location$+sfe_womatl.wo_no$=firm_id$+loc$+wo_no$
				callpoint!.setColumnEnabled("SFE_WOMASTR.SCH_PROD_QTY",0)
				callpoint!.setColumnEnabled("SFE_WOMASTR.EST_YIELD",0)
				rem - this gets to be annoying - callpoint!.setMessage("SF_MATS_EXIST")
			endif
			break
		wend
	endif

rem --- set DevObjects

	callpoint!.setDevObject("prod_qty",callpoint!.getColumnData("SFE_WOMASTR.SCH_PROD_QTY"))
	callpoint!.setDevObject("wo_est_yield",callpoint!.getColumnData("SFE_WOMASTR.EST_YIELD"))
	callpoint!.setDevObject("wo_category",callpoint!.getColumnData("SFE_WOMASTR.WO_CATEGORY"))
[[SFE_WOMASTR.EST_YIELD.AVAL]]
rem --- Set DevObject

	callpoint!.setDevObject("wo_est_yield",callpoint!.getUserInput())

rem --- Informational warning for category N WO's - requirements may need to be adjusted if qty/yield is changed

	if callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS")<>"C" and callpoint!.getColumnData("SFE_WOMASTR.WO_CATEGORY")="N"
		if callpoint!.getRecordMode()="C" and callpoint!.getColumnUndoData("SFE_WOMASTR.EST_YIELD")<>callpoint!.getUserInput()
			callpoint!.setMessage("SF_ADJ_REQS")
		endif
	endif
[[SFE_WOMASTR.AOPT-COPY]]
rem --- Copy from other Work Order

rem --- Check to make sure there aren't existing requirements

	woe02_dev=fnget_dev("SFE_WOOPRTN")
	woe22_dev=fnget_dev("SFE_WOMATL")
	woe32_dev=fnget_dev("SFE_WOSUBCNT")

	wo_loc$=callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")
	wo_no$=callpoint!.getColumnData("SFE_WOMASTR.WO_NO")

	found_reqs=0

	read(woe02_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)
	while 1
		k$=key(woe02_dev,end=*break)
		if pos(firm_id$+wo_loc$+wo_no$=k$)=0 break
		found_reqs=1
		break
	wend

	read(woe22_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)
	while 1
		k$=key(woe22_dev,end=*break)
		if pos(firm_id$+wo_loc$+wo_no$=k$)=0 break
		found_reqs=1
		break
	wend

	read(woe32_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)
	while 1
		k$=key(woe32_dev,end=*break)
		if pos(firm_id$+wo_loc$+wo_no$=k$)=0 break
		found_reqs=1
		break
	wend

	if found_reqs=1
		msg_id$="REQS_EXIST"
		gosub disp_message
		break
	endif

rem --- Check for mandatory data

	if callpoint!.getDevObject("wo_category")<>"N" or
:		num(callpoint!.getColumnData("SFE_WOMASTR.EST_YIELD"))=0 or
:		cvs(callpoint!.getColumnData("SFE_WOMASTR.OPENED_DATE"),3)="" or
:		num(callpoint!.getColumnData("SFE_WOMASTR.SCH_PROD_QTY"))=0 or
:		cvs(callpoint!.getColumnData("SFE_WOMASTR.UNIT_MEASURE"),3)="" or
:		cvs(callpoint!.getColumnData("SFE_WOMASTR.WAREHOUSE_ID"),3)="" or
:		pos(callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS")="QP")=0 
		
		msg_id$="SF_MISSING_INFO"
		gosub disp_message
		break
	endif
	
rem --- Copy the Work Order

	callpoint!.setDevObject("category",callpoint!.getColumnData("SFE_WOMASTR.WO_CATEGORY"))
	callpoint!.setDevObject("wo_loc",callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION"))
	callpoint!.setDevObject("wo_no",callpoint!.getColumnData("SFE_WOMASTR.WO_NO"))

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"SFE_WOCOPY",
:		stbl("+USER_ID"),
:		"MNT",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]

	callpoint!.setStatus("SAVE")
[[SFE_WOMASTR.SCH_PROD_QTY.AVAL]]
rem --- Verify minimum quantity > 0

	if num(callpoint!.getUserInput())<=0
		msg_id$="IV_QTY_GT_ZERO"
		gosub disp_message
		callpoint!.setColumnData("SFE_WOMASTR.SCH_PROD_QTY",callpoint!.getColumnData("SFE_WOMASTR.SCH_PROD_QTY"),1)
		callpoint!.setStatus("ABORT")
	endif

rem --- Enable Copy Button

	if callpoint!.getColumnData("SFE_WOMASTR.WO_CATEGORY")="N" and num(callpoint!.getUserInput())>0
		callpoint!.setOptionEnabled("COPY",1)
	endif

	callpoint!.setDevObject("prod_qty",callpoint!.getUserInput())

rem --- Informational warning for category N WO's - requirements may need to be adjusted if qty/yield is changed

	if callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS")<>"C" and callpoint!.getColumnData("SFE_WOMASTR.WO_CATEGORY")="N"
		if callpoint!.getRecordMode()="C" and callpoint!.getColumnUndoData("SFE_WOMASTR.SCH_PROD_QTY")<>callpoint!.getUserInput()
			callpoint!.setMessage("SF_ADJ_REQS")
		endif
	endif
[[SFE_WOMASTR.AOPT-CSTS]]
rem --- Display Cost Summary

	callpoint!.setDevObject("wo_status",callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS"))
	callpoint!.setDevObject("closed_date",callpoint!.getColumnData("SFE_WOMASTR.CLOSED_DATE"))

	run stbl("+DIR_PGM")+"sfe_costsumm.aon"
[[SFE_WOMASTR.AOPT-TRNS]]
rem --- Work Order Transaction History report

	callpoint!.setDevObject("closed_date",callpoint!.getColumnData("SFE_WOMASTR.CLOSED_DATE"))

	dim dflt_data$[5,1]
	dflt_data$[1,0]="WO_NO"
	dflt_data$[1,1]=callpoint!.getColumnData("SFE_WOMASTR.WO_NO")
	dflt_data$[2,0]="WO_STATUS"
	dflt_data$[2,1]=callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS")
	dflt_data$[3,0]="CLOSED_DATE"
	dflt_data$[3,1]=callpoint!.getColumnData("SFE_WOMASTR.CLOSED_DATE")
	dflt_data$[4,0]="GL_END_DATE"
	dflt_data$[4,1]=callpoint!.getDevObject("gl_end_date")
	dflt_data$[5,0]="WO_LOCATION"
	dflt_data$[5,1]=callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"SFE_TRANSHIST",
:		stbl("+USER_ID"),
:		"MNT",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]
[[SFE_WOMASTR.AOPT-JOBS]]
rem --- Display Job Status

	callpoint!.setDevObject("wo_status",callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS"))
	callpoint!.setDevObject("closed_date",callpoint!.getColumnData("SFE_WOMASTR.CLOSED_DATE"))

	run stbl("+DIR_PGM")+"sfe_jobstat.aon"
[[SFE_WOMASTR.AOPT-RELS]]
rem --- Release/Commit the Work Order

	callpoint!.setDevObject("wo_status",callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS"))

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"SFE_RELEASEWO",
:		stbl("+USER_ID"),
:		"MNT",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]

	if callpoint!.getDevObject("wo_status")="O"
		callpoint!.setStatus("RECORD:["+firm_id$+callpoint!.getDevObject("wo_loc")+callpoint!.getDevObject("wo_no")+"]")
	endif
[[SFE_WOMASTR.AOPT-SCHD]]
rem --- Schedule the Work Order

	callpoint!.setDevObject("order_no",callpoint!.getColumnData("SFE_WOMASTR.ORDER_NO"))
	callpoint!.setDevObject("item_id",callpoint!.getColumnData("SFE_WOMASTR.ITEM_ID"))

	dim dflt_data$[3,1]
	dflt_data$[1,0]="SCHED_FLAG"
	dflt_data$[1,1]=callpoint!.getColumnData("SFE_WOMASTR.SCHED_FLAG")
	dflt_data$[2,0]="ESTSTT_DATE"
	dflt_data$[2,1]=callpoint!.getColumnData("SFE_WOMASTR.ESTSTT_DATE")
	dflt_data$[3,0]="ESTCMP_DATE"
	dflt_data$[3,1]=callpoint!.getColumnData("SFE_WOMASTR.ESTCMP_DATE")
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"SFR_SCHEDWO",
:		stbl("+USER_ID"),
:		"MNT",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]

	if callpoint!.getDevObject("sched_method")<>""
		start_date$=callpoint!.getDevObject("start_date")
		comp_date$=callpoint!.getDevObject("comp_date")
		sched_method$=callpoint!.getDevObject("sched_method")
		callpoint!.setColumnData("SFE_WOMASTR.ESTSTT_DATE",start_date$,1)
		callpoint!.setColumnData("SFE_WOMASTR.ESTCMP_DATE",comp_date$,1)
		callpoint!.setColumnData("SFE_WOMASTR.SCHED_FLAG",sched_method$,1)
		callpoint!.setStatus("MODIFIED")
	endif
[[SFE_WOMASTR.ORDER_NO.AVAL]]
rem --- Validate Open Sales Order

	if cvs(callpoint!.getUserInput(),2)<>cvs(callpoint!.getColumnData("SFE_WOMASTR.ORDER_NO"),2)
		callpoint!.setColumnData("SFE_WOMASTR.SLS_ORD_SEQ_REF","",1)
	endif

	if cvs(callpoint!.getUserInput(),2)<>""
		ope_ordhdr=fnget_dev("OPE_ORDHDR")
		dim ope_ordhdr$:fnget_tpl$("OPE_ORDHDR")
		cust$=callpoint!.getColumnData("SFE_WOMASTR.CUSTOMER_ID")
		order$=callpoint!.getUserInput()
		found_ord$="N"
		while 1
			read (ope_ordhdr,key=firm_id$+ope_ordhdr.ar_type$+cust$+order$,dom=*break)
			found_ord$="Y"
			break
		wend

		if found_ord$="N"
			msg_id$="SF_INVALID_SO_ORD"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif

		gosub build_ord_line

	endif
[[SFE_WOMASTR.CUSTOMER_ID.AVAL]]
rem --- Disable Order info if Customer not entered

	if callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS")<>"C"
		if cvs(callpoint!.getUserInput(),3)=""
			callpoint!.setColumnEnabled("SFE_WOMASTR.ORDER_NO",0)
			callpoint!.setColumnEnabled("SFE_WOMASTR.SLS_ORD_SEQ_REF",0)
			callpoint!.setColumnData("SFE_WOMASTR.ORDER_NO","",1)
			callpoint!.setColumnData("SFE_WOMASTR.SLS_ORD_SEQ_REF","",1)
		else
			callpoint!.setColumnEnabled("SFE_WOMASTR.ORDER_NO",1)
			callpoint!.setColumnEnabled("SFE_WOMASTR.SLS_ORD_SEQ_REF",1)
		endif

		if callpoint!.getUserInput()<>callpoint!.getColumnData("SFE_WOMASTR.CUSTOMER_ID")
			callpoint!.setColumnData("SFE_WOMASTR.ORDER_NO","",1)
			callpoint!.setColumnData("SFE_WOMASTR.SLS_ORD_SEQ_REF","",1)
		endif
	endif
[[SFE_WOMASTR.ITEM_ID.AVAL]]
rem --- Set default values

	ivm_itemmast=fnget_dev("IVM_ITEMMAST")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")

	read record (ivm_itemmast,key=firm_id$+callpoint!.getUserInput(),dom=*break)ivm_itemmast$
	if cvs(callpoint!.getColumnData("SFE_WOMASTR.UNIT_MEASURE"),3)=""
		callpoint!.setColumnData("SFE_WOMASTR.UNIT_MEASURE",ivm_itemmast.unit_of_sale$,1)
	endif
	if callpoint!.getDevObject("lotser")<>"N" and ivm_itemmast.lotser_item$+ivm_itemmast.inventoried$="YY"
		callpoint!.setColumnData("SFE_WOMASTR.LOTSER_ITEM","Y")
		callpoint!.setOptionEnabled("LSNO",1)
	else
		callpoint!.setColumnData("SFE_WOMASTR.LOTSER_ITEM","N")
		callpoint!.setOptionEnabled("LSNO",0)
	endif

	if callpoint!.getDevObject("bm")="Y"
		bmm_billmast=fnget_dev("BMM_BILLMAST")
		dim bmm_billmast$:fnget_tpl$("BMM_BILLMAST")
		while 1
			found_bill$="N"
			read record (bmm_billmast,key=firm_id$+callpoint!.getUserInput(),dom=*break) bmm_billmast$
			found_bill$="Y"
			break
		wend
		if found_bill$="N"
			msg_id$="SF_NO_BILL"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
		callpoint!.setColumnData("SFE_WOMASTR.DRAWING_NO",bmm_billmast.drawing_no$,1)
		callpoint!.setColumnData("SFE_WOMASTR.DRAWING_REV",bmm_billmast.drawing_rev$,1)
		callpoint!.setColumnData("SFE_WOMASTR.EST_YIELD",bmm_billmast.est_yield$,1)
		callpoint!.setColumnData("SFE_WOMASTR.SCH_PROD_QTY",bmm_billmast.std_lot_size$,1)
		callpoint!.setColumnData("SFE_WOMASTR.UNIT_MEASURE",bmm_billmast.unit_measure$,1)
		callpoint!.setColumnData("SFE_WOMASTR.BILL_REV",bmm_billmast.bill_rev$,1)
	endif

rem --- Set default Completion Date

	if cvs(callpoint!.getColumnData("SFE_WOMASTR.ESTCMP_DATE"),2)="" and
:		callpoint!.getColumnData("SFE_WOMASTR.SCHED_FLAG")="M"
		ivm_itemwhse=fnget_dev("IVM_ITEMWHSE")
		dim ivm_itemwhse$:fnget_tpl$("IVM_ITEMWHSE")
		read record (ivm_itemwhse,key=firm_id$+callpoint!.getDevObject("default_wh")+
:			callpoint!.getUserInput(),dom=*next)ivm_itemwhse$
		new_date$=""
		leadtime=ivm_itemwhse.lead_time
		call stbl("+DIR_PGM")+"adc_daydates.aon",stbl("+SYSTEM_DATE"),new_date$,leadtime
		if new_date$<>"N"
			callpoint!.setColumnData("SFE_WOMASTR.ESTCMP_DATE",new_date$,1)
		endif
	endif
[[SFE_WOMASTR.WO_STATUS.AVAL]]
rem --- Only allow changes to status if P or Q

	status$=callpoint!.getUserInput()
	old_status$=callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS")
	if pos(status$="PQ")=0
		callpoint!.setUserInput(old_status$)
	endif
[[SFE_WOMASTR.WO_TYPE.AVAL]]
rem --- Only allow change to Type if it's the same Category

	typecode_dev=fnget_dev("SFC_WOTYPECD")
	dim typecode$:fnget_tpl$("SFC_WOTYPECD")

	cat$=callpoint!.getColumnData("SFE_WOMASTR.WO_CATEGORY")
	new_type$=callpoint!.getUserInput()
	readrecord(typecode_dev,key=firm_id$+"A"+new_type$)typecode$
	if callpoint!.getDevObject("new_rec")="N"
		if cvs(cat$,3)<>"" and cat$<>typecode.wo_category$
			msg_id$="WO_NO_CAT_CHG"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

rem --- If new order, check for type of Work Order and disable Item or Descriptions

	if callpoint!.getDevObject("new_rec")="Y"
		callpoint!.setColumnData("SFE_WOMASTR.WO_CATEGORY",typecode.wo_category$,1)
		callpoint!.setDevObject("wo_category",typecode.wo_category$)
	endif

	if typecode.wo_category$<>"I"
		callpoint!.setColumnEnabled("SFE_WOMASTR.ITEM_ID",0)
	else
		callpoint!.setColumnEnabled("SFE_WOMASTR.DESCRIPTION_01",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.DESCRIPTION_02",0)
	endif

rem --- Enable Copy Button

	if typecode.wo_category$="N" and num(callpoint!.getColumnData("SFE_WOMASTR.SCH_PROD_QTY"))>0
		callpoint!.setOptionEnabled("COPY",1)
	else
		callpoint!.setOptionEnabled("COPY",0)
	endif

rem --- Disable Drawing and Revision Number if Recurring type

	if typecode.wo_category$="R"
		callpoint!.setColumnEnabled("SFE_WOMASTR.DRAWING_NO",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.DRAWING_REV",0)
	endif
[[SFE_WOMASTR.AWRI]]
rem --- create WO comments from BOM comments

	if callpoint!.getDevObject("bm")="Y" and callpoint!.getDevObject("new_rec")="Y"
	
		bmm09_dev=fnget_dev("BMM_BILLCMTS")
		dim bmm_billcmts$:fnget_tpl$("BMM_BILLCMTS")
		sfe07_dev=fnget_dev("SFE_WOCOMNT")
		dim sfe_wocomnt$:fnget_tpl$("SFE_WOCOMNT")

		sfe_wocomnt.firm_id$=firm_id$
		sfe_wocomnt.wo_location$=callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")
		sfe_wocomnt.wo_no$=callpoint!.getColumnData("SFE_WOMASTR.WO_NO")

		read (bmm09_dev,key=firm_id$+callpoint!.getColumnData("SFE_WOMASTR.ITEM_ID"),dom=*next)

		while 1
			read record (bmm09_dev,end=*break)bmm_billcmts$
			if bmm_billcmts.firm_id$+bmm_billcmts.bill_no$<>firm_id$+callpoint!.getColumnData("SFE_WOMASTR.ITEM_ID") then break
			wk$=fattr(sfe_wocomnt$,"SEQUENCE_NO")
			seq_mask$=fill(dec(wk$(10,2)),"0")
			sfe_wocomnt.sequence_no$=str(num(bmm_billcmts.sequence_num$):seq_mask$)
			sfe_wocomnt.ext_comments$=bmm_billcmts.std_comments$
			sfe_wocomnt$=field(sfe_wocomnt$)
			write record (sfe07_dev)sfe_wocomnts$
		wend

	endif

rem --- adjust OO if qty has changed on an open WO
rem --- as far as I can see, this can only happen if BOM not installed, otherwise can't change qty on an open WO

	if callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS")="O" and callpoint!.getDevObject("new_rec")="N"

		new_prod_qty=num(callpoint!.getColumnData("SFE_WOMASTR.SCH_PROD_QTY"))
		old_prod_qty=num(callpoint!.getDevObject("prod_qty"))
		wo_category$=callpoint!.getDevObject("wo_category")

		if old_prod_qty<>new_prod_qty and wo_category$="I"
rem escape;rem watch - temp; remove after testing CAH
			rem --- initialize atamo
			call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
			items$[1]=callpoint!.getColumnData("SFE_WOMASTR.WAREHOUSE_ID")
			items$[2]=callpoint!.getColumnData("SFE_WOMASTR.ITEM_ID")

			rem --- update OO w/ delta of new_prod_qty-old_prod_qty
			refs[0]=new_prod_qty-old_prod_qty
			call stbl("+DIR_PGM")+"ivc_itemupdt.aon","OO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status		
		endif
	endif

rem --- launch other form(s) based on WO category

	if callpoint!.getDevObject("new_rec")="Y"
		switch pos(callpoint!.getColumnData("SFE_WOMASTR.WO_CATEGORY")="INR")

			case 1;rem --- if on a regular stock WO, show mats grid

				key_pfx$=firm_id$+callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")+callpoint!.getColumnData("SFE_WOMASTR.WO_NO")

				dim dflt_data$[3,1]
				dflt_data$[1,0]="FIRM_ID"
				dflt_data$[1,1]=firm_id$
				dflt_data$[2,0]="WO_LOCATION"
				dflt_data$[2,1]=callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")
				dflt_data$[3,0]="WO_NO"
				dflt_data$[3,1]=callpoint!.getColumnData("SFE_WOMASTR.WO_NO")

				call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:					"SFE_WOMATL",
:					stbl("+USER_ID"),
:					"MNT",
:					key_pfx$,
:					table_chans$[all],
:					"",
:					dflt_data$[all]

				callpoint!.setStatus("ACTIVATE")

			break

			case 2;rem --- if on non-stock, launch ops, then mats, then subs grids
				   rem --- note: if user closes each form w/ mouse-click on red X, this works, but there are (it looks like) timing issues
				   rem --- if using ctl-F4 -- it will close one form, then launch and immediately close another one

				key_pfx$=firm_id$+callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")+callpoint!.getColumnData("SFE_WOMASTR.WO_NO")

				dim dflt_data$[3,1]
				dflt_data$[1,0]="FIRM_ID"
				dflt_data$[1,1]=firm_id$
				dflt_data$[2,0]="WO_LOCATION"
				dflt_data$[2,1]=callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")
				dflt_data$[3,0]="WO_NO"
				dflt_data$[3,1]=callpoint!.getColumnData("SFE_WOMASTR.WO_NO")

				call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:					"SFE_WOOPRTN",
:					stbl("+USER_ID"),
:					"MNT",
:					key_pfx$,
:					table_chans$[all],
:					"",
:					dflt_data$[all]

launch_mats:
				call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:					"SFE_WOMATL",
:					stbl("+USER_ID"),
:					"MNT",
:					key_pfx$,
:					table_chans$[all],
:					"",
:					dflt_data$[all]

				if callpoint!.getDevObject("explode_bills")="Y" then goto launch_mats

				call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:					"SFE_WOSUBCNT",
:					stbl("+USER_ID"),
:					"MNT",
:					key_pfx$,
:					table_chans$[all],
:					"",
:					dflt_data$[all]

				callpoint!.setStatus("ACTIVATE")

			break

			case 3;rem --- if recurring, launch ops grid


				key_pfx$=firm_id$+callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")+callpoint!.getColumnData("SFE_WOMASTR.WO_NO")

				dim dflt_data$[3,1]
				dflt_data$[1,0]="FIRM_ID"
				dflt_data$[1,1]=firm_id$
				dflt_data$[2,0]="WO_LOCATION"
				dflt_data$[2,1]=callpoint!.getColumnData("SFE_WOMASTR.WO_LOCATION")
				dflt_data$[3,0]="WO_NO"
				dflt_data$[3,1]=callpoint!.getColumnData("SFE_WOMASTR.WO_NO")

				call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:					"SFE_WOOPRTN",
:					stbl("+USER_ID"),
:					"MNT",
:					key_pfx$,
:					table_chans$[all],
:					"",
:					dflt_data$[all]

				callpoint!.setStatus("ACTIVATE")

			break

			case default
			break

		swend
	endif

rem --- Set new_rec to N

	callpoint!.setDevObject("new_rec","N")

rem --- disable Copy function if closed or not an N category

	if callpoint!.getColumnData("SFE_WOMASTR.WO_CATEGORY")<>"N" or callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS")="C"
		callpoint!.setOptionEnabled("COPY",0)
	else
		callpoint!.setOptionEnabled("COPY",1)
	endif

rem --- enable Release/Commit

	if pos(callpoint!.getColumnData("SFE_WOMASTR.WO_STATUS")="PQ")<>0
		callpoint!.setOptionEnabled("RELS",1)
	endif
[[SFE_WOMASTR.<CUSTOM>]]
rem =========================================================
build_ord_line:
rem 	cust$		input
rem	order_no$	input
rem	validate_ord$	input
rem =========================================================

rem --- Build Sequence list button

	wo_cat$=callpoint!.getColumnData("SFE_WOMASTR.WO_CATEGORY")

	ope11_dev=fnget_dev("OPE_ORDDET")
	dim ope11a$:fnget_tpl$("OPE_ORDDET")
	opc_linecode=fnget_dev("OPC_LINECODE")
	dim opc_linecode$:fnget_tpl$("OPC_LINECODE")
	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")

	ops_lines!=SysGUI!.makeVector()
	ops_items!=SysGUI!.makeVector()
	ops_list!=SysGUI!.makeVector()
	ops_lines!.addItem("000000000000")
	ops_items!.addItem("")
	ops_list!.addItem("")

	ctlSeqRef!=callpoint!.getControl("SFE_WOMASTR.SLS_ORD_SEQ_REF")
	ctlSeqRef!.removeAllItems()

	read(ope11_dev,key=firm_id$+ope_ordhdr.ar_type$+cust$+order$,dom=*next)
	while 1
		read record (ope11_dev,end=*break) ope11a$
		if pos(firm_id$+ope_ordhdr.ar_type$+cust$+order$=ope11a$)<>1 break
		dim opc_linecode$:fattr(opc_linecode$)
		read record (opc_linecode,key=firm_id$+ope11a.line_code$,dom=*next)opc_linecode$
		if wo_cat$="R" continue
		if wo_cat$="I" and pos(opc_linecode.line_type$="SP")=0 continue
		if wo_cat$="N" and pos(opc_linecode.line_type$="N")=0 continue
		if wo_cat$="I"
			dim ivm01a$:fattr(ivm01a$)
			read record (ivm01_dev,key=firm_id$+ope11a.item_id$,dom=*next)ivm01a$
			ops_lines!.addItem(ope11a.internal_seq_no$)
			item_list$=item_list$+$ff$+ope11a.item_id$
			work_var=pos($ff$+ope11a.item_id$=item_list$,1,0)
			if work_var>1
				work_var$=cvs(ope11a.item_id$,2)+"("+str(work_var)+")"
			else
				work_var$=cvs(ope11a.item_id$,2)
			endif
			ops_items!.addItem(work_var$)
			ops_list!.addItem(work_var$+" - "+ivm01a.item_desc$)
		endif
		if wo_cat$="N"
			ops_lines!.addItem(ope11a.internal_seq_no$)
			item_list$=item_list$+$ff$+ope11a.order_memo$
			work_var=pos($ff$+ope11a.order_memo$=item_list$,1,0)
			if work_var>1
				work_var$=cvs(ope11a.order_memo$,2)+"("+str(work_var)+")"
			else
				work_var$=cvs(ope11a.order_memo$,2)
			endif
			ops_items!.addItem(work_var$)
			ops_list!.addItem(work_var$)
		endif
	wend

	if ops_lines!.size()>0
		ldat$=""
		for x=0 to ops_lines!.size()-1
			ldat$=ldat$+ops_items!.getItem(x)+"~"+ops_lines!.getItem(x)+";"
		next x
	endif

	ctlSeqRef!.insertItems(0,ops_list!)
	callpoint!.setTableColumnAttribute("SFE_WOMASTR.SLS_ORD_SEQ_REF","LDAT",ldat$)
	callpoint!.setStatus("REFRESH")

	return

#include std_missing_params.src
[[SFE_WOMASTR.AREC]]
rem --- Set new record flag

	callpoint!.setDevObject("new_rec","Y")
	callpoint!.setDevObject("wo_status","")
	callpoint!.setDevObject("wo_no","")
	callpoint!.setDevObject("wo_loc","")

rem --- Disable Additional Options

	callpoint!.setOptionEnabled("SCHD",0)
	callpoint!.setOptionEnabled("RELS",0)
	callpoint!.setOptionEnabled("COPY",0)
	callpoint!.setOptionEnabled("LSNO",0)

rem --- set defaults

	callpoint!.setColumnData("SFE_WOMASTR.WAREHOUSE_ID",str(callpoint!.getDevObject("default_wh")))
	callpoint!.setColumnData("SFE_WOMASTR.OPENED_DATE",stbl("+SYSTEM_DATE"))
	callpoint!.setColumnData("SFE_WOMASTR.ESTSTT_DATE",stbl("+SYSTEM_DATE"))
	callpoint!.setDevObject("prod_qty","1")
	callpoint!.setDevObject("wo_est_yield","100")

rem --- enable all enterable fields

	callpoint!.setColumnEnabled("SFE_WOMASTR.ITEM_ID",1)
	callpoint!.setColumnEnabled("SFE_WOMASTR.BILL_REV",1)
	if callpoint!.getDevObject("ar")="Y"
		callpoint!.setColumnEnabled("SFE_WOMASTR.CUSTOMER_ID",1)
	else
		callpoint!.setColumnEnabled("SFE_WOMASTR.CUSTOMER_ID",0)
	endif
	callpoint!.setColumnEnabled("SFE_WOMASTR.DESCRIPTION_01",1)
	callpoint!.setColumnEnabled("SFE_WOMASTR.DESCRIPTION_02",1)
	callpoint!.setColumnEnabled("SFE_WOMASTR.DRAWING_NO",1)
	callpoint!.setColumnEnabled("SFE_WOMASTR.DRAWING_REV",1)
	callpoint!.setColumnEnabled("SFE_WOMASTR.EST_YIELD",1)
	if callpoint!.getDevObject("mp")="Y"
		callpoint!.setColumnEnabled("SFE_WOMASTR.FORECAST",1)
	else
		callpoint!.setColumnEnabled("SFE_WOMASTR.FORECAST",0)
	endif
	if callpoint!.getDevObject("op")="Y"
		callpoint!.setColumnEnabled("SFE_WOMASTR.SLS_ORD_SEQ_REF",1)
		callpoint!.setColumnEnabled("SFE_WOMASTR.ORDER_NO",1)
	else
		callpoint!.setColumnEnabled("SFE_WOMASTR.SLS_ORD_SEQ_REF",0)
		callpoint!.setColumnEnabled("SFE_WOMASTR.ORDER_NO",0)
	endif
	callpoint!.setColumnEnabled("SFE_WOMASTR.OPENED_DATE",1)
	callpoint!.setColumnEnabled("SFE_WOMASTR.PRIORITY",1)
	callpoint!.setColumnEnabled("SFE_WOMASTR.SCH_PROD_QTY",1)
	callpoint!.setColumnEnabled("SFE_WOMASTR.UNIT_MEASURE",1)
	callpoint!.setColumnEnabled("SFE_WOMASTR.WAREHOUSE_ID",1)
	callpoint!.setColumnEnabled("SFE_WOMASTR.WO_TYPE",1)
	callpoint!.setColumnEnabled("SFE_WOMASTR.WO_STATUS",1)
[[SFE_WOMASTR.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
