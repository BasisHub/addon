[[OPE_CREDMAINT.CUSTOMER_ID.AVAL]]
rem "Customer Inactive Feature"
customer_id$=callpoint!.getUserInput()
arm01_dev=fnget_dev("ARM_CUSTMAST")
arm01_tpl$=fnget_tpl$("ARM_CUSTMAST")
dim arm01a$:arm01_tpl$
arm01a_key$=firm_id$+customer_id$
find record (arm01_dev,key=arm01a_key$,err=*break) arm01a$
if arm01a.cust_inactive$="Y" then
   call stbl("+DIR_PGM")+"adc_getmask.aon","CUSTOMER_ID","","","",m0$,0,customer_size
   msg_id$="AR_CUST_INACTIVE"
   dim msg_tokens$[2]
   msg_tokens$[1]=fnmask$(arm01a.customer_id$(1,customer_size),m0$)
   msg_tokens$[2]=cvs(arm01a.customer_name$,2)
   gosub disp_message
   callpoint!.setStatus("ACTIVATE")
endif

[[OPE_CREDMAINT.ASVA]]
rem --- Update the tickler date
	gosub update_tickler

rem --- Make sure this form is closed before the Credit Review and Release grid gets focus
	callpoint!.setStatus("EXIT")
[[OPE_CREDMAINT.ARER]]
rem --- If tickler date is blank, use existing tickler date if one already exists for the customer and order.
	old_tick_date$=callpoint!.getColumnData("OPE_CREDMAINT.REV_DATE")
	if cvs(old_tick_date$,2)="" then
		ope03_dev=fnget_dev("OPE_CREDDATE")
		dim ope03a$:fnget_tpl$("OPE_CREDDATE")
		cust_no$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
		ord$=callpoint!.getColumnData("OPE_CREDMAINT.ORDER_NO")
		ope03a.firm_id$=firm_id$
		ope03a.customer_id$=pad(cust_no$,dec(fattr(ope03a$,"CUSTOMER_ID")(10,2)))
		ope03a.order_no$=pad(ord$,dec(fattr(ope03a$,"ORDER_NO")(10,2)))
		ope03_trip$=ope03a.firm_id$+ope03a.customer_id$+ope03a.order_no$
		read(ope03_dev,key=ope03_trip$,knum="BY_ORDER",dom=*next)
		ope03_key$=key(ope03_dev,end=*next)
		if pos(ope03_trip$=ope03_key$)=1 then
			readrecord(ope03_dev)ope03a$
			old_tick_date$=ope03a.rev_date$
			callpoint!.setColumnData("OPE_CREDMAINT.REV_DATE",old_tick_date$,1)
		endif

		rem --- Reset ope03_dev to its PRIMARY key
		read(ope03_dev,key="",knum="PRIMARY",dom=*next)
	endif

rem --- Hold on to old tickler date so we know if it gets changed
	callpoint!.setDevObject("old_tick_date",old_tick_date$)

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

	found_ope01_rec=0
	read(ope01_dev,key=firm_id$+ope01a.ar_type$+cust$+ord$,dom=*next)
	while 1
		ope01_key$=key(ope01_dev,end=*break)
		if pos(firm_id$+ope01a.ar_type$+cust$+ord$=ope01_key$)<>1 then break
		extractrecord(ope01_dev,dom=*next)ope01a$; rem Advisory Locking
		if pos(ope01a.trans_status$="ER")=0 then continue
		found_ope01_rec=1
		break; rem --- new order can have at most just one new invoice, if any
	wend
	if !found_ope01_rec or ope01a.invoice_type$="I" then read(ope01_dev); goto no_delete

	call "ivc_itemupdt.aon::init",channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

	read (ope11_dev,key=firm_id$+ope01a.ar_type$+cust$+ord$+ope01a.ar_inv_no$,dom=*next)
	while 1
		ope11_key$=key(ope11_dev,end=*break)
		if pos(firm_id$+ope01a.ar_type$+cust$+ord$+ope01a.ar_inv_no$=ope11_key$)<>1 then break
		readrecord(ope11_dev)ope11a$
		if pos(ope11a.trans_status$="ER")=0 then continue
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
			readrecord(ope_ordlsdet_dev,key=ope11_key$,dom=*next)
			while 1
				ope_ordlsdet_key$=key(ope_ordlsdet_dev,end=*break)
				if pos(ope11_key$=ope_ordlsdet_key$)<>1 then break
				readrecord(ope_ordlsdet_dev)ope_ordlsdet$
				if pos(ope_ordlsdet.trans_status$="ER")=0 then continue
				items$[3]=ope_ordlsdet.lotser_no$
				refs[0]=ope_ordlsdet.qty_ordered
				call "ivc_itemupdt.aon",action$,channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				remove (ope_ordlsdet_dev,key=ope_ordlsdet_key$)
				found_lot=1
			wend
			if found_lot=0
				call "ivc_itemupdt.aon",action$,channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
			endif
		endif
remove_line:
			remove (ope11_dev,key=ope11_key$,dom=*next)
		endif
	wend

rem	 --- Remove Header
	remove(ope_ordship_dev,key=firm_id$+cust$+ord$+ope01a.ar_inv_no$,dom=*next)
	remove(ope01_dev,key=ope01_key$)
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
	extractrecord(arm02_dev,key=firm_id$+callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")+"  ")arm02a$; rem Advisory Locking
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

	read(ope01_dev,key=firm_id$+"  "+cust$+ord$,dom=*next)
	while 1
		ope01_key$=key(ope01_dev,end=*break)
		if pos(firm_id$+ope01a.ar_type$+cust$+ord$=ope01_key$)<>1 then break
		extractrecord(ope01_dev,dom=*next)ope01a$; rem Advisory Locking
		if pos(ope01a.trans_status$="ER")=0 then continue

		rem --- allow change to Terms Code
		callpoint!.setDevObject("terms",ope01a.terms_code$)
		call stbl("+DIR_SYP")+"bam_run_prog.bbj","OPE_CREDTERMS",stbl("+USER_ID"),"MNT","",table_chans$[all]
		ope01a.terms_code$=callpoint!.getDevObject("terms")
		readrecord(arc_terms_dev,key=firm_id$+"A"+ope01a.terms_code$,dom=*next);goto good_code
		read(ope01_dev)
		break; rem --- new order can have at most just one new invoice, if any

good_code:
		ope01a.credit_flag$="R"
		ope01a.mod_user$=sysinfo.user_id$
		ope01a.mod_date$=date(0:"%Yd%Mz%Dz")
		ope01a.mod_time$=date(0:"%Hz%mz")
		ope01a$=field(ope01a$)
		writerecord(ope01_dev)ope01a$
		break
	wend

	gosub remove_tickler

rem --- Do NOT allow printing the Picking List if there are possible SO-WO links

	allow_print=1
	op_create_wo$=callpoint!.getDevObject("op_create_wo")
	if op_create_wo$="A" then
		gridRowVect! = BBjAPI().makeVector()
		ope11_dev=fnget_dev("OPE_ORDDET")
		dim ope11a$:fnget_tpl$("OPE_ORDDET")
		read (ope11_dev,key=firm_id$+ope01a.ar_type$+cust$+ord$+ope01a.ar_inv_no$,dom=*next)
		while 1
			ope11_key$=key(ope11_dev,end=*break)
			if pos(firm_id$+ope01a.ar_type$+cust$+ord$+ope01a.ar_inv_no$=ope11_key$)<>1 then break
			readrecord(ope11_dev)ope11a$
			if pos(ope11a.trans_status$="ER")=0 then continue
			gridRowVect!.addItem(ope11a$)
		wend
		soCreateWO!=new SalesOrderCreateWO(firm_id$,cust$,ord$)
		soCreateWO!.initIsnWOMap(gridRowVect!)
		if soCreateWO!.woCount() then
			allow_print=0
			ope_prntlist_dev=fnget_dev("OPE_PRNTLIST")
			remove(ope_prntlist_dev,key=firm_id$+"O"+ope01a.ar_type$+cust$+ord$,dom=*next)
			msg_id$="OP_USE_OE_4_PICKLIST"
			gosub disp_message
		endif
	endif

rem --- Print the order?

	if allow_print then
		msg_id$="OP_ORDREL"
		gosub disp_message
		if msg_opt$="Y"

			user_id$=stbl("+USER_ID")
	 
			dim dflt_data$[3,1]
			dflt_data$[1,0]="CUSTOMER_ID"
			dflt_data$[1,1]=cust$
			dflt_data$[2,0]="ORDER_NO"
			dflt_data$[2,1]=ord$
			dflt_data$[3,0]="INVOICE_TYPE"
			dflt_data$[3,1]=ope01a.invoice_type$
	 
			call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		                       "OPR_ODERPICKDMD",
:		                       user_id$,
:		                       "",
:		                       "",
:		                       table_chans$[all],
:		                       "",
:		                       dflt_data$[all]

		endif
	endif
	callpoint!.setStatus("EXIT")

no_rel:
	if pos("EXIT"=callpoint!.getStatus())=0
		callpoint!.setStatus("REFRESH")
	endif
[[OPE_CREDMAINT.BSHO]]
rem --- Init

	use ::opo_SalesOrderCreateWO.aon::SalesOrderCreateWO

rem --- Open tables
	num_files=13
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARM_CUSTMAST",open_opts$[1]="OTA"
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
	open_tables$[13]="OPS_PARAMS",open_opts$[13]="OTA"

	gosub open_tables

	ops_params_dev = num(open_chans$[13])
	dim ops_params$:open_tpls$[13]

 rem --- Get needed OP params

	readrecord(ops_params_dev,key=firm_id$+"AR00")ops_params$
	callpoint!.setDevObject("op_create_wo",ops_params.op_create_wo$)
[[OPE_CREDMAINT.<CUSTOM>]]
#include std_functions.src
disp_cust_comments:
	
rem --- You must pass in cust_id$ because we don't know whether it's verified or not
	arm01_dev=fnget_dev("ARM_CUSTMAST")
	dim arm01a$:fnget_tpl$("ARM_CUSTMAST")
	readrecord(arm01_dev,key=firm_id$+cust_id$,dom=*next)arm01a$
	callpoint!.setColumnData("<<DISPLAY>>.comments",arm01a.memo_1024$,1)
return

update_tickler: rem --- Modify Tickler date
	tick_date$=callpoint!.getColumnData("OPE_CREDMAINT.REV_DATE")
	if cvs(tick_date$,2)="" then
		rem --- Do not write blank tickler date
		return
	endif
	ope03_dev=fnget_dev("OPE_CREDDATE")
	dim ope03a$:fnget_tpl$("OPE_CREDDATE")
	gosub remove_tickler
	callpoint!.setDevObject("old_tick_date",tick_date$)
	ord$=callpoint!.getColumnData("OPE_CREDMAINT.ORDER_NO")
	cust_no$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
	if cvs(cust_no$,2)<>""
		ope03a.firm_id$=firm_id$
		ope03a.rev_date$=tick_date$
		ope03a.customer_id$=cust_no$
		ope03a.order_no$=pad(ord$,dec(fattr(ope03a$,"ORDER_NO")(10,2)));rem Order Number all spaces for tickler
		ope03_key$=ope03a.firm_id$+ope03a.rev_date$+ope03a.customer_id$+ope03a.order_no$
		extractrecord(ope03_dev,key=ope03_key$,dom=*next)x$; rem Advisory Locking
		ope03a$=field(ope03a$)
		writerecord(ope03_dev)ope03a$
	endif
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

	disp_text$=callpoint!.getColumnData("<<DISPLAY>>.COMMENTS")
	sv_disp_text$=disp_text$

	editable$="YES"
	force_loc$="NO"
	baseWin!=null()
	startx=0
	starty=0
	shrinkwrap$="NO"
	html$="NO"
	dialog_result$=""

	call stbl("+DIR_SYP")+ "bax_display_text.bbj",
:		"Customer Comments",
:		disp_text$, 
:		table_chans$[all], 
:		editable$, 
:		force_loc$, 
:		baseWin!, 
:		startx, 
:		starty, 
:		shrinkwrap$, 
:		html$, 
:		dialog_result$

	if disp_text$<>sv_disp_text$
		rem --- Update comments to master file
		arm01_dev=fnget_dev("ARM_CUSTMAST")
		dim arm01a$:fnget_tpl$("ARM_CUSTMAST")
		extractrecord(arm01_dev,key=firm_id$+callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID"))arm01a$; rem Advisory Locking
		arm01a.memo_1024$=disp_text$
		arm01a$=field(arm01a$)
		writerecord(arm01_dev)arm01a$
		callpoint!.setColumnData("<<DISPLAY>>.COMMENTS",disp_text$,1)
		callpoint!.setDevObject("memo_1024",disp_text$)
	endif
