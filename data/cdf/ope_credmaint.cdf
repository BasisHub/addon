[[OPE_CREDMAINT.ARER]]
rem --- Set dates to CCYYMMDD
	tick_date$=callpoint!.getColumnData("OPE_CREDMAINT.REV_DATE")
	tick_date$=tick_date$(5,4)+tick_date$(1,4)
	callpoint!.setColumnData("OPE_CREDMAINT.REV_DATE",tick_date$)
	callpoint!.setDevObject("old_tick_date",tick_date$)
	ord_date$=callpoint!.getColumnData("OPE_CREDMAINT.ORDER_DATE")
	if len(ord_date$)>0
		ord_date$=ord_date$(5,4)+ord_date$(1,4)
		callpoint!.setColumnData("OPE_CREDMAINT.ORDER_DATE",ord_date$)
	endif
	ship_date$=callpoint!.getColumnData("OPE_CREDMAINT.SHIPMNT_DATE")
	if len(ship_date$)>0
		ship_date$=ship_date$(5,4)+ship_date$(1,4)
		callpoint!.setColumnData("OPE_CREDMAINT.SHIPMNT_DATE",ship_date$)
	endif

rem --- Display Comments
	cust_id$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
	gosub disp_cust_comments
[[OPE_CREDMAINT.AOPT-DELO]]
rem --- Delete the Order or the Followup date for the Customer

	cust$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
	ord$=callpoint!.getColumnData("OPE_CREDMAINT.ORDER_NO")
	if cvs(ord$,2)=""
		msg_id$="OP_REM_FOLLOWUP"
	else
		msg_id$="OP_ORD_FOLLOWUP"
	endif
	gosub disp_message
	if msg_opt$="N" goto no_delete

	if cvs(ord$,2)="" goto del_followup

rem --- Delete the order
	ope01_dev=fnget_dev("OPE_ORDHDR")
	dim ope01a$:fnget_tpl$("OPE_ORDHDR")
	ope11_dev=fnget_dev("OPE_ORDDET")
	dim ope11a$:fnget_tpl$("OPE_ORDDET")
	opc_linecode_dev=fnget_dev("OPC_LINECODE")
	dim opc_linecode$:fnget_tpl$("OPC_LINECODE")
	ivs_params_dev=fnget_dev("IVS_PARAMS")
	dim ivs_params$:fnget_tpl$("IVS_PARAMS")
	ope_ordlsdet_dev=fnget_dev("OPE_ORDLSDET")
	dim ope_ordlsdet$:fnget_tpl$("OPE_ORDLSDET")
	ope_ordship_dev=fnget_dev("OPE_ORDSHIP")
	dim ope_ordship$:fnget_tpl$("OPE_ORDSHIP")
	ope_prntlist_dev=fnget_dev("OPE_PRNTLIST")
	ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")

	readrecord(ivs_params_dev,key=firm_id$+"IV00")ivs01a$
	readrecord(ope01_dev,key=firm_id$+ope01a.ar_type$+cust$+ord$,dom=no_delete)ope01a$
	if ope01a.invoice_type$="I" goto no_delete

	call "ivc_itemupdt.aon::init",channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

	read (ope11_dev,key=firm_id$+ope01a.ar_type$+cust$+ord$,dom=*next)
	while 1
		readrecord(ope11_dev,end=*break)ope11a$
		if pos(firm_id$+ope01a.ar_type$+cust$+ord$=ope11a$)<>1 break
		readrecord(opc_linecode_dev,key=firm_id$+ope11a.line_code$,dom=remove_line)opc_linecode$
		if pos(opc_linecode.line_type$="SP")=0 goto remove_line
		if ope01a.invoice_type$="P" goto remove_line
		if opc_linecode.dropship$="Y" or ope11a.commit_flag$="N" or ope11a.dropship$="Y" goto remove_line
		if ope11a.commit_flag$<>"Y" goto remove_line

rem --- Uncommit Inventory

		dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
		readrecord(ivm_itemmast_dev,key=firm_id$+ope11a.item_id$,dom=*next)ivm_itemmast$
		items$[1]=ope11a.warehouse_id$
		items$[2]=ope11a.item_id$
		action$="UC"
		refs[0]=ope11a.qty_ordered
		if ivm_itemmast.lotser_item$<>"Y" or ivm_itemmast.inventoried$<>"Y"
			call "ivc_itemupdt.aon",action$,channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
			goto remove_line
		else
			found_lot=0
			readrecord(ope_ordlsdet_dev,key=firm_id$+ope11a.ar_type$+cust$+
:					ord$+ope11a.internal_seq_no$,dom=*next)
			while 1
				readrecord(ope_ordlsdet_dev,end=*break)ope_ordlsdet$
				if pos(firm_id$+ope11a.ar_type$+cust$+ord$+ope11a.internal_seq_no$=ope_ordlsdet$)<>1 break
				items$[3]=ope_ordlsdet.lotser_no$
				refs[0]=ope_ordlsdet.qty_ordered
				call "ivc_itemupdt.aon",action$,channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				remove (ope_ordlsdet_dev,key=ope_ordlsdet.firm_id$+ope_ordlsdet.ar_type$+cust$+
:					ord$+ope_ordlsdet.internal_seq_no$+ope_ordlsdet.sequence_no$)
				found_lot=1
			wend
			if found_lot=0
				call "ivc_itemupdt.aon",action$,channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
			endif
		endif
remove_line:
			remove (ope11_dev,key=firm_id$+ope01a.ar_type$+cust$+ord$+ope11a.internal_seq_no$,dom=*next)
		endif
	wend

rem	 --- Remove Header
	remove(ope_ordship_dev,key=firm_id$+cust$+ord$,dom=*next)
	remove(ope01_dev,key=firm_id$+ope01a.ar_type$+cust$+ord$)
	remove(ope_prntlist_dev,key=firm_id$+"O"+ope01a.ar_type$+cust$+ord$,dom=*next)

del_followup:
	gosub remove_tickler
	callpoint!.setStatus("EXIT")

no_delete:
[[OPE_CREDMAINT.AOPT-ORIV]]
rem Order/Invoice History Inq
	gosub update_tickler
	cp_cust_id$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
	user_id$=stbl("+USER_ID")
	dim dflt_data$[2,1]
	dflt_data$[1,0]="CUSTOMER_ID"
	dflt_data$[1,1]=cp_cust_id$
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"ARR_ORDINVHIST",
:		user_id$,
:		"",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]
[[OPE_CREDMAINT.AOPT-IDTL]]
rem Invoice Dtl Inquiry
	gosub update_tickler
	cp_cust_id$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
	user_id$=stbl("+USER_ID")
	dim dflt_data$[2,1]
	dflt_data$[1,0]="CUSTOMER_ID"
	dflt_data$[1,1]=cp_cust_id$
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:                       "ARR_INVDETAIL",
:                       user_id$,
:                   	"",
:                       "",
:                       table_chans$[all],
:                       "",
:                       dflt_data$[all]
[[OPE_CREDMAINT.AOPT-MDAT]]
rem --- Modify Information

	callpoint!.setDevObject("tick_date",callpoint!.getColumnData("OPE_CREDMAINT.REV_DATE"))
	callpoint!.setDevObject("cred_hold",callpoint!.getColumnData("OPE_CREDMAINT.CRED_HOLD"))
	callpoint!.setDevObject("cred_limit",callpoint!.getColumnData("OPE_CREDMAINT.CREDIT_LIMIT"))
	call stbl("+DIR_SYP")+"bam_run_prog.bbj","OPE_CREDMOD",stbl("+USER_ID"),"MNT","",table_chans$[all]
	tick_date$=callpoint!.getDevObject("tick_date")
	cred_hold$=callpoint!.getDevObject("cred_hold")
	cred_limit$=callpoint!.getDevObject("cred_limit")
	callpoint!.setColumnData("OPE_CREDMAINT.REV_DATE",tick_date$)
	callpoint!.setColumnData("OPE_CREDMAINT.CRED_HOLD",cred_hold$)
	callpoint!.setColumnData("OPE_CREDMAINT.CREDIT_LIMIT",cred_limit$)
	callpoint!.setStatus("REFRESH")

rem --- Update Credit changes to master file
	arm02_dev=fnget_dev("ARM_CUSTDET")
	dim arm02a$:fnget_tpl$("ARM_CUSTDET")
	readrecord(arm02_dev,key=firm_id$+callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")+"  ")arm02a$
	arm02a.cred_hold$=cred_hold$
	arm02a.credit_limit=num(cred_limit$)
	arm02a$=field(arm02a$)
	writerecord(arm02_dev)arm02a$
[[OPE_CREDMAINT.BEND]]
rem --- One last chance to update the tickler date
	gosub update_tickler
[[OPE_CREDMAINT.AOPT-RELO]]
rem --- Release an Order from Credit Hold
	gosub update_tickler
	cust$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
	ord$=callpoint!.getColumnData("OPE_CREDMAINT.ORDER_NO")
	if cvs(ord$,2)="" goto no_rel

	dim msg_tokens$[1]
	msg_tokens$[1]=ord$
	msg_id$="OP_CONFIRM_REL"
	gosub disp_message
	if msg_opt$="N" goto no_rel

	ope01_dev=fnget_dev("OPE_ORDHDR")
	dim ope01a$:fnget_tpl$("OPE_ORDHDR")
	arc_terms_dev=fnget_dev("ARC_TERMCODE")
	while 1
		readrecord(ope01_dev,key=firm_id$+"  "+cust$+ord$,dom=*break)ope01a$
		rem --- allow change to Terms Code
		callpoint!.setDevObject("terms",ope01a.terms_code$)
		call stbl("+DIR_SYP")+"bam_run_prog.bbj","OPE_CREDTERMS",stbl("+USER_ID"),"MNT","",table_chans$[all]
		ope01a.terms_code$=callpoint!.getDevObject("terms")
		readrecord(arc_terms_dev,key=firm_id$+"A"+ope01a.terms_code$,dom=*next);goto good_code
		continue
good_code:
		ope01a.credit_flag$="R"
		ope01a$=field(ope01a$)
		writerecord(ope01_dev)ope01a$
		break
	wend

	gosub remove_tickler

rem --- Print the order?

	msg_id$="OP_ORDREL"
	gosub disp_message
	if msg_opt$="Y"
		call stbl("+DIR_PGM")+"opc_picklist.aon", cust$, ord$, callpoint!, table_chans$[all], status
	endif
	callpoint!.setStatus("EXIT")

no_rel:
	if pos("EXIT"=callpoint!.getStatus())=0
		callpoint!.setStatus("REFRESH")
	endif
[[OPE_CREDMAINT.BSHO]]
rem --- Open tables
	num_files=12
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARM_CUSTCMTS",open_opts$[1]="OTA"
	open_tables$[2]="OPE_ORDHDR",open_opts$[2]="OTA"
	open_tables$[3]="ARC_TERMCODE",open_opts$[3]="OTA"
	open_tables$[4]="OPE_CREDDATE",open_opts$[4]="OTA"
	open_tables$[5]="ARM_CUSTDET",open_opts$[5]="OTA"
	open_tables$[6]="OPE_ORDDET",open_opts$[6]="OTA"
	open_tables$[7]="OPC_LINECODE",open_opts$[7]="OTA"
	open_tables$[8]="IVS_PARAMS",open_opts$[8]="OTA"
	open_tables$[9]="OPE_ORDLSDET",open_opts$[9]="OTA"
	open_tables$[10]="OPE_ORDSHIP",open_opts$[10]="OTA"
	open_tables$[11]="OPE_PRNTLIST",open_opts$[11]="OTA"
	open_tables$[12]="IVM_ITEMMAST",open_opts$[12]="OTA"
	gosub open_tables
[[OPE_CREDMAINT.<CUSTOM>]]
disp_cust_comments:
	
rem --- You must pass in cust_id$ because we don't know whether it's verified or not
	cmt_text$=""
	arm05_dev=fnget_dev("ARM_CUSTCMTS")
	dim arm05a$:fnget_tpl$("ARM_CUSTCMTS")
	arm05_key$=firm_id$+cust_id$
	more=1
	read(arm05_dev,key=arm05_key$,dom=*next)
	while more
		readrecord(arm05_dev,end=*break)arm05a$
		 
		if arm05a.firm_id$ = firm_id$ and arm05a.customer_id$ = cust_id$ then
			cmt_text$ = cmt_text$ + cvs(arm05a.std_comments$,3)+$0A$
		endif				
	wend
	callpoint!.setColumnData("<<DISPLAY>>.comments",cmt_text$)
	callpoint!.setStatus("REFRESH")
return

update_tickler: rem --- Modify Tickler date
	ope03_dev=fnget_dev("OPE_CREDDATE")
	dim ope03a$:fnget_tpl$("OPE_CREDDATE")
	gosub remove_tickler
	tick_date$=callpoint!.getColumnData("OPE_CREDMAINT.REV_DATE")
	callpoint!.setDevObject("old_tick_date",tick_date$)
	ord$=callpoint!.getColumnData("OPE_CREDMAINT.ORDER_NO")
	cust_no$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
	ope03a.firm_id$=firm_id$
	ope03a.rev_date$=tick_date$
	ope03a.customer_id$=cust_no$
	ope03a.order_no$=ord$
	ope03a$=field(ope03a$)
	writerecord(ope03_dev)ope03a$
	callpoint!.setDevObject("tick_date",tick_date$)
return

remove_tickler:
	ope03_dev=fnget_dev("OPE_CREDDATE")
	dim ope03a$:fnget_tpl$("OPE_CREDDATE")
	old_tick_date$=callpoint!.getDevObject("old_tick_date")
	ord$=callpoint!.getColumnData("OPE_CREDMAINT.ORDER_NO")
	cust_no$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
	remove(ope03_dev,key=firm_id$+old_tick_date$+cust_no$+ord$,dom=*next)
	if len(ord$)=0
		ord$=fill(num(callpoint!.getTableColumnAttribute("OPE_CREDMAINT.ORDER_NO","MAXL")))
		remove(ope03_dev,key=firm_id$+old_tick_date$+cust_no$+ord$,dom=*next)
	endif
return
[[OPE_CREDMAINT.AOPT-COMM]]
rem --- Comment Maintenance

	gosub update_tickler
	cust_id$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
	user_id$=stbl("+USER_ID")

	dim dflt_data$[2,1]
	dflt_data$[1,0]="CUSTOMER_ID"
	dflt_data$[1,1]=cust_id$

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"ARM_CUSTCMTS",
:		user_id$,
:		"MNT",
:		firm_id$+cust_id$,
:		table_chans$[all],
:		"",
:		dflt_data$[all]

	gosub disp_cust_comments
