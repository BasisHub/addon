[[POE_REQHDR.REQ_NO.AVAL]]
rem --- don't allow user to assign new req# -- use Barista seq#
rem --- if user made null entry (to assign next seq automatically) then getRawUserInput() will be empty
rem --- if not empty, then the user typed a number -- if an existing requisition, fine; if not, abort

if cvs(callpoint!.getRawUserInput(),3)<>""
	msk$=callpoint!.getTableColumnAttribute("POE_REQHDR.REQ_NO","MSKI")
	find_requisition$=str(num(callpoint!.getRawUserInput()):msk$)
	poe_reqhdr_dev=fnget_dev("POE_REQHDR")
	dim poe_reqhdr$:fnget_tpl$("POE_REQHDR")
	read record (poe_reqhdr_dev,key=firm_id$+find_requisition$,dom=*next)poe_reqhdr$
	if poe_reqhdr.firm_id$<>firm_id$ or  poe_reqhdr.req_no$<>find_requisition$
		msg_id$="PO_INVAL_REQ"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
endif
[[POE_REQHDR.AOPT-DPRT]]
rem --- on-demand requisition print

vendor_id$=callpoint!.getColumnData("POE_REQHDR.VENDOR_ID")
req_no$=callpoint!.getColumnData("POE_REQHDR.REQ_NO")

gosub queue_for_printing

if cvs(vendor_id$,3)<>"" and cvs(req_no$,3)<>""

	gosub queue_for_printing
	call "por_reqprint.aon",vendor_id$,req_no$	

endif
[[POE_REQHDR.AOPT-QPRT]]
gosub queue_for_printing
msg_id$="PO_REQ_QPRT"
gosub disp_message
[[POE_REQHDR.ADEL]]
rem --- also delete requisition print record

poe_reqprint_dev=fnget_dev("POE_REQPRINT")
remove (poe_reqprint_dev,key=firm_id$+callpoint!.getColumnData("POE_REQHDR.VENDOR_ID")+callpoint!.getColumnData("POE_REQHDR.REQ_NO"),dom=*next)

[[POE_REQHDR.AWRI]]
rem --- need to put out poe_reqprint record

gosub queue_for_printing
[[POE_REQHDR.APFE]]
rem --- set total order amt

total_amt=num(callpoint!.getDevObject("total_amt"))
callpoint!.setColumnData("<<DISPLAY>>.ORDER_TOTAL",str(total_amt))
tamt!=callpoint!.getDevObject("tamt")
tamt!.setValue(total_amt)

rem --- check dtl_posted flag to see if dropship fields should be disabled

gosub enable_dropship_fields 
[[POE_REQHDR.AREC]]
gosub  form_inits
[[POE_REQHDR.ADIS]]
vendor_id$=callpoint!.getColumnData("POE_REQHDR.VENDOR_ID")
purch_addr$=callpoint!.getColumnData("POE_REQHDR.PURCH_ADDR")
gosub vendor_info
gosub disp_vendor_comments
gosub purch_addr_info
gosub whse_addr_info

rem --- depending on whether or not drop-ship flag is selected and OE is installed, set min lengths for cust# and order#

callpoint!.setTableColumnAttribute("POE_REQHDR.CUSTOMER_ID","MINL","1")
if callpoint!.getDevObject("OP_installed")="Y"
	callpoint!.setTableColumnAttribute("POE_REQHDR.ORDER_NO","MINL","1")
endif

rem --- disable drop-ship checkbox, customer, order until/unless no detail exists

dtl!=gridvect!.getItem(0)		
if dtl!.size()
	callpoint!.setDevObject("dtl_posted","Y")
else
	callpoint!.setDevObject("dtl_posted","")
endif
gosub enable_dropship_fields 
[[POE_REQHDR.ORDER_NO.AVAL]]
rem --- if dropshipping, retrieve specified sales order and display shipto address

if cvs(callpoint!.getColumnData("POE_REQHDR.CUSTOMER_ID"),3)<>""

	tmp_customer_id$=callpoint!.getColumnData("POE_REQHDR.CUSTOMER_ID")
	tmp_order_no$=callpoint!.getUserInput()

	gosub dropship_shipto
	gosub get_dropship_order_lines

	if callpoint!.getDevObject("ds_orders")<>"Y" and cvs(callpoint!.getUserInput(),3)<>""
		msg_id$="PO_NO_SO_LINES"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif			
endif
[[POE_REQHDR.CUSTOMER_ID.AVAL]]
rem --- if dropshipping, retrieve specified sales order and display shipto address

	callpoint!.setColumnData("POE_REQHDR.ORDER_NO","")
	callpoint!.setColumnData("POE_REQHDR.SHIPTO_NO","")
	callpoint!.setColumnData("POE_REQHDR.DS_ADDR_LINE_1","")
	callpoint!.setColumnData("POE_REQHDR.DS_ADDR_LINE_2","")
	callpoint!.setColumnData("POE_REQHDR.DS_ADDR_LINE_3","")
	callpoint!.setColumnData("POE_REQHDR.DS_ADDR_LINE_4","")
	callpoint!.setColumnData("POE_REQHDR.DS_CITY","")
	callpoint!.setColumnData("POE_REQHDR.DS_NAME","")
	callpoint!.setColumnData("POE_REQHDR.DS_STATE_CD","")
	callpoint!.setColumnData("POE_REQHDR.DS_ZIP_CODE","")

	tmp_customer_id$=callpoint!.getUserInput()
	gosub shipto_cust;rem will refresh address w/ that from order once order# is entered
	
	callpoint!.setStatus("REFRESH")
	
[[POE_REQHDR.DROPSHIP.AVAL]]
rem --- if turning off dropship flag, clear devObject items

if callpoint!.getUserInput()="N"
	callpoint!.setDevObject("ds_orders","N")
	callpoint!.setDevObject("so_ldat","")
	callpoint!.setDevObject("so_lines_list","")
	callpoint!.setTableColumnAttribute("POE_REQHDR.CUSTOMER_ID","MINL","0")	
	callpoint!.setTableColumnAttribute("POE_REQHDR.ORDER_NO","MINL","0")
else
	callpoint!.setTableColumnAttribute("POE_REQHDR.CUSTOMER_ID","MINL","1")
	if callpoint!.getDevObject("OP_installed")="Y"
		callpoint!.setTableColumnAttribute("POE_REQHDR.ORDER_NO","MINL","1")
	endif
endif

		

			
[[POE_REQHDR.ARNF]]
rem --- IV Params
	ivs_params_chn=fnget_dev("IVS_PARAMS")
	dim ivs_params$:fnget_tpl$("IVS_PARAMS")
	read record(ivs_params_chn,key=firm_id$+"IV00")ivs_params$
rem --- PO Params
	pos_params_chn=fnget_dev("POS_PARAMS")
	dim pos_params$:fnget_tpl$("POS_PARAMS")
	read record(pos_params_chn,key=firm_id$+"PO00")pos_params$
rem --- Set Defaults
	apm02_dev=fnget_dev("APM_VENDHIST")
	dim apm02a$:fnget_tpl$("APM_VENDHIST")
	read record(apm02_dev,key=firm_id$+vendor_id$,dom=*next)
	tmp$=key(apm02_dev,end=done_apm_vendhist)
		if pos(firm_id$+vendor_id$=tmp$)<>1 then goto done_apm_vendhist
		read record(apm02_dev,key=tmp$)apm02a$
	done_apm_vendhist:
	callpoint!.setColumnData("<<DISPLAY>>.ORDER_TOTAL","")
	callpoint!.setColumnData("POE_REQHDR.WAREHOUSE_ID",ivs_params.warehouse_id$)
	gosub whse_addr_info
	callpoint!.setColumnData("POE_REQHDR.ORD_DATE",sysinfo.system_date$)
	callpoint!.setColumnData("POE_REQHDR.AP_TERMS_CODE",apm02a.ap_terms_code$)
	callpoint!.setColumnData("POE_REQHDR.PO_FRT_TERMS",pos_params.po_frt_terms$)
	callpoint!.setColumnData("POE_REQHDR.AP_SHIP_VIA",pos_params.ap_ship_via$)
	callpoint!.setColumnData("POE_REQHDR.FOB",pos_params.fob$)
	callpoint!.setColumnData("POE_REQHDR.HOLD_FLAG",pos_params.hold_flag$)
	callpoint!.setColumnData("POE_REQHDR.PO_MSG_CODE",pos_params.po_req_msg_code$)
[[POE_REQHDR.PROMISE_DATE.AVAL]]
tmp$=cvs(callpoint!.getUserInput(),2)
if tmp$<>"" and tmp$<callpoint!.getColumnData("POE_REQHDR.ORD_DATE") then callpoint!.setStatus("ABORT")
[[POE_REQHDR.NOT_B4_DATE.AVAL]]
not_b4_date$=cvs(callpoint!.getUserInput(),2)
if not_b4_date$<>"" then
	if not_b4_date$<callpoint!.getColumnData("POE_REQHDR.ORD_DATE") then callpoint!.setStatus("ABORT")
	if not_b4_date$>callpoint!.getColumnData("POE_REQHDR.REQD_DATE") then callpoint!.setStatus("ABORT")
	promise_date$=cvs(callpoint!.getColumnData("POE_REQHDR.PROMISE_DATE"),2)
	if promise_date$<>"" and not_b4_date$>promise_date$ then callpoint!.setStatus("ABORT")
endif
[[POE_REQHDR.REQD_DATE.AVAL]]
tmp$=callpoint!.getUserInput()
if tmp$<>"" and tmp$<callpoint!.getColumnData("POE_REQHDR.ORD_DATE") then callpoint!.setStatus("ABORT")
[[POE_REQHDR.WAREHOUSE_ID.AVAL]]
gosub whse_addr_info
[[POE_REQHDR.ARAR]]
vendor_id$=callpoint!.getColumnData("POE_REQHDR.VENDOR_ID")
purch_addr$=callpoint!.getColumnData("POE_REQHDR.PURCH_ADDR")
gosub vendor_info
gosub purch_addr_info
gosub whse_addr_info
gosub form_inits

rem ---	depending on whether or not drop-ship flag is selected and OE is installed...
rem ---	if drop-ship is selected, load up sales order line#'s for the detail grid's so reference listbutton

if callpoint!.getColumnData("POE_REQHDR.DROPSHIP")="Y"

	if callpoint!.getDevObject("OP_installed")="Y"
		tmp_customer_id$=callpoint!.getColumnData("POE_REQHDR.CUSTOMER_ID")
		tmp_order_no$=callpoint!.getColumnData("POE_REQHDR.ORDER_NO")
		gosub get_dropship_order_lines

	endif
endif
[[POE_REQHDR.PURCH_ADDR.AVAL]]
vendor_id$=callpoint!.getColumnData("POE_REQHDR.VENDOR_ID")
purch_addr$=callpoint!.getUserInput()
gosub purch_addr_info

[[POE_REQHDR.VENDOR_ID.AVAL]]
vendor_id$=callpoint!.getUserInput()
gosub vendor_info
gosub disp_vendor_comments

[[POE_REQHDR.<CUSTOM>]]
vendor_info: rem --- get and display Vendor Information
	apm01_dev=fnget_dev("APM_VENDMAST")
	dim apm01a$:fnget_tpl$("APM_VENDMAST")
	read record(apm01_dev,key=firm_id$+vendor_id$,dom=*next)apm01a$
	callpoint!.setColumnData("<<DISPLAY>>.V_ADDR1",apm01a.addr_line_1$)
	callpoint!.setColumnData("<<DISPLAY>>.V_ADDR2",apm01a.addr_line_2$)
	if cvs(apm01a.city$+apm01a.state_code$+apm01a.zip_code$,3)<>""
		callpoint!.setColumnData("<<DISPLAY>>.V_CITY",cvs(apm01a.city$,3)+", "+apm01a.state_code$+"  "+apm01a.zip_code$)
	else
		callpoint!.setColumnData("<<DISPLAY>>.V_CITY","")
	endif
	callpoint!.setColumnData("<<DISPLAY>>.V_CONTACT",apm01a.contact_name$)
	callpoint!.setColumnData("<<DISPLAY>>.V_PHONE",apm01a.phone_no$)
	callpoint!.setColumnData("<<DISPLAY>>.V_FAX",apm01a.fax_no$)
	callpoint!.setStatus("REFRESH")
return

disp_vendor_comments:	
	rem --- You must pass in vendor_id$ because we don't know whether it's verified or not
	cmt_text$=""
	apm_vendcmts_dev=fnget_dev("APM_VENDCMTS")
	dim apm_vendcmts$:fnget_tpl$("APM_VENDCMTS")
	apm_vendcmts_key$=firm_id$+vendor_id$
	more=1
	read(apm_vendcmts_dev,key=apm_vendcmts_key$,dom=*next)
	while more
		readrecord(apm_vendcmts_dev,end=*break)apm_vendcmts$		 
		if apm_vendcmts.firm_id$ = firm_id$ and apm_vendcmts.vendor_id$ = vendor_id$ then
			cmt_text$ = cmt_text$ + cvs(apm_vendcmts.std_comments$,3)+$0A$
		endif				
	wend
	callpoint!.setColumnData("<<DISPLAY>>.comments",cmt_text$)
	callpoint!.setStatus("REFRESH")
return

purch_addr_info: rem --- get and display Purchase Address Info
	apm05_dev=fnget_dev("APM_VENDADDR")
	dim apm05a$:fnget_tpl$("APM_VENDADDR")
	read record(apm05_dev,key=firm_id$+vendor_id$+purch_addr$,dom=*next)apm05a$
	callpoint!.setColumnData("<<DISPLAY>>.PA_ADDR1",apm05a.addr_line_1$)
	callpoint!.setColumnData("<<DISPLAY>>.PA_ADDR2",apm05a.addr_line_2$)
	callpoint!.setColumnData("<<DISPLAY>>.PA_CITY",apm05a.city$)
	callpoint!.setColumnData("<<DISPLAY>>.PA_STATE",apm05a.state_code$)
	callpoint!.setColumnData("<<DISPLAY>>.PA_ZIP_CODE",apm05a.zip_code$)
	callpoint!.setStatus("REFRESH-WAIT:.75")
return

whse_addr_info: rem --- get and display Warehouse Address Info
	ivc_whsecode_dev=fnget_dev("IVC_WHSECODE")
	dim ivc_whsecode$:fnget_tpl$("IVC_WHSECODE")
	if pos("WAREHOUSE_ID.AVAL"=callpoint!.getCallpointEvent())<>0
		warehouse_id$=callpoint!.getUserInput()
	else
		warehouse_id$=callpoint!.getColumnData("POE_REQHDR.WAREHOUSE_ID")
	endif
	read record(ivc_whsecode_dev,key=firm_id$+"C"+warehouse_id$,dom=*next)ivc_whsecode$
	callpoint!.setColumnData("<<DISPLAY>>.W_ADDR1",ivc_whsecode.addr_line_1$)
	callpoint!.setColumnData("<<DISPLAY>>.W_ADDR2",ivc_whsecode.addr_line_2$)
	callpoint!.setColumnData("<<DISPLAY>>.W_CITY",ivc_whsecode.city$)
	callpoint!.setColumnData("<<DISPLAY>>.W_STATE",ivc_whsecode.state_code$)
	callpoint!.setColumnData("<<DISPLAY>>.W_ZIP_CODE",ivc_whsecode.zip_code$)
	callpoint!.setStatus("REFRESH-WAIT:.5")

return

dropship_shipto: rem --- get and display shipto from Sales Order if dropship indicated, and OE installed

	ope_ordhdr_dev=fnget_dev("OPE_ORDHDR")
	arm_custship_dev=fnget_dev("ARM_CUSTSHIP")
	ope_ordship_dev=fnget_dev("OPE_ORDSHIP")

	dim ope_ordhdr$:fnget_tpl$("OPE_ORDHDR")
	dim arm_custship$:fnget_tpl$("ARM_CUSTSHIP")
	dim ope_ordship$:fnget_tpl$("OPE_ORDSHIP")

	read record (ope_ordhdr_dev,key=firm_id$+ope_ordhdr.ar_type$+tmp_customer_id$+tmp_order_no$,dom=*next)ope_ordhdr$
	shipto_no$=ope_ordhdr.shipto_no$
	callpoint!.setColumnData("POE_REQHDR.SHIPTO_NO",shipto_no$)
	if cvs(shipto_no$,3)=""
		gosub shipto_cust
	endif
	if num(shipto_no$,err=*endif)=99
		read record (ope_ordship_dev,key=firm_id$+tmp_customer_id$+tmp_order_no$,dom=*next)ope_ordship$
		dim rec$:fattr(ope_ordship$)
		rec$=ope_ordship$
		gosub fill_dropship_address
		callpoint!.setColumnData("POE_REQHDR.DS_NAME",rec.name$)
	endif
	if num(shipto_no$,err=*endif)>0 and num(shipto_no$,err=*endif)<99
		read record (arm_custship_dev,key=firm_id$+tmp_customer_id$+shipto_no$,dom=*next)arm_custship$
		dim rec$:fattr(arm_custship$)
		rec$=arm_custship$
		gosub fill_dropship_address
		callpoint!.setColumnData("POE_REQHDR.DS_NAME",rec.name$)
	endif

	callpoint!.setStatus("REFRESH")
return

shipto_cust:

	arm_custmast_dev=fnget_dev("ARM_CUSTMAST")
	dim arm_custmast$:fnget_tpl$("ARM_CUSTMAST")

	read record (arm_custmast_dev,key=firm_id$+tmp_customer_id$,dom=*next)arm_custmast$
	dim rec$:fattr(arm_custmast$)
	rec$=arm_custmast$
	gosub fill_dropship_address
	callpoint!.setColumnData("POE_REQHDR.DS_NAME",rec.customer_name$)

return

fill_dropship_address:
	callpoint!.setColumnData("POE_REQHDR.DS_ADDR_LINE_1",rec.addr_line_1$)
	callpoint!.setColumnData("POE_REQHDR.DS_ADDR_LINE_2",rec.addr_line_2$)
	callpoint!.setColumnData("POE_REQHDR.DS_ADDR_LINE_3",rec.addr_line_3$)
	callpoint!.setColumnData("POE_REQHDR.DS_ADDR_LINE_4",rec.addr_line_4$)
	callpoint!.setColumnData("POE_REQHDR.DS_CITY",rec.city$)
	callpoint!.setColumnData("POE_REQHDR.DS_STATE_CD",rec.state_code$)
	callpoint!.setColumnData("POE_REQHDR.DS_ZIP_CODE",rec.zip_code$)
return

get_dropship_order_lines:
rem --- read thru selected sales order and build list of lines for which line code is marked as drop-ship
	ope_ordhdr_dev=fnget_dev("OPE_ORDHDR")
	ope_orddet_dev=fnget_dev("OPE_ORDDET")
	ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")

	dim ope_ordhdr$:fnget_tpl$("OPE_ORDHDR")
	dim ope_orddet$:fnget_tpl$("OPE_ORDDET")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")

	order_lines!=SysGUI!.makeVector()
	order_items!=SysGUI!.makeVector()
	order_list!=SysGUI!.makeVector()
	callpoint!.setDevObject("ds_orders","N")

	read record (ope_ordhdr_dev,key=firm_id$+ope_ordhdr.ar_type$+tmp_customer_id$+tmp_order_no$,dom=*return)ope_ordhdr$

	read (ope_orddet_dev,key=firm_id$+ope_ordhdr.ar_type$+ope_ordhdr.customer_id$+ope_ordhdr.order_no$,knum="PRIMARY",dom=*next)

	while 1
		read record (ope_orddet_dev,end=*break)ope_orddet$
		if ope_orddet.firm_id$+ope_orddet.ar_type$+ope_orddet.customer_id$+ope_orddet.order_no$<>
:			ope_ordhdr.firm_id$+ope_ordhdr.ar_type$+ope_ordhdr.customer_id$+ope_ordhdr.order_no$ then break
		if pos(ope_orddet.line_code$=callpoint!.getDevObject("oe_ds_line_codes"))<>0
			read record (ivm_itemmast_dev,key=firm_id$+ope_orddet.item_id$,dom=*next)ivm_itemmast$
			order_lines!.addItem(ope_orddet.internal_seq_no$)
			order_items!.addItem(ope_orddet.item_id$)
			order_list!.addItem(Translate!.getTranslation("AON_ITEM:_")+cvs(ope_orddet.item_id$,3)+" "+cvs(ivm_itemmast.display_desc$,3))
		endif
	wend

	if order_lines!.size()=0 
		callpoint!.setDevObject("ds_orders","N")
		callpoint!.setDevObject("so_ldat","")
		callpoint!.setDevObject("so_lines_list","")
	else 
		ldat$=""
		for x=0 to order_lines!.size()-1
			ldat$=ldat$+order_items!.getItem(x)+"~"+order_lines!.getItem(x)+";"
		next x

		callpoint!.setDevObject("ds_orders","Y")		
		callpoint!.setDevObject("so_ldat",ldat$)
		callpoint!.setDevObject("so_lines_list",order_list!)
	endif	
return

form_inits:

rem --- setting up for new rec or nav to diff rec

callpoint!.setDevObject("ds_orders","")
callpoint!.setDevObject("so_ldat","")
callpoint!.setDevObject("so_lines_list","")

callpoint!.setDevObject("total_amt","0")
callpoint!.setDevObject("dtl_posted","")

callpoint!.setTableColumnAttribute("POE_REQHDR.CUSTOMER_ID","MINL","0")	
callpoint!.setTableColumnAttribute("POE_REQHDR.ORDER_NO","MINL","0")

return

enable_dropship_fields:
rem disables/enables dropship fields if detail has (or hasn't) been created for this requisition
rem since warehouse in hdr can't be changed once detail is posted, handling that control here, too.

if callpoint!.getDevObject("dtl_posted")="Y"
	callpoint!.setColumnEnabled("POE_REQHDR.WAREHOUSE_ID",0)
	if callpoint!.getDevObject("OP_installed")="Y"
		callpoint!.setColumnEnabled("POE_REQHDR.DROPSHIP",0)
		callpoint!.setColumnEnabled("POE_REQHDR.CUSTOMER_ID",0)
		callpoint!.setColumnEnabled("POE_REQHDR.ORDER_NO",0)			
	else
		callpoint!.setColumnEnabled("POE_REQHDR.DROPSHIP",1)
		callpoint!.setColumnEnabled("POE_REQHDR.CUSTOMER_ID",1)
		callpoint!.setColumnEnabled("POE_REQHDR.ORDER_NO",0)		
	endif
else
	callpoint!.setColumnEnabled("POE_REQHDR.WAREHOUSE_ID",1)
	if callpoint!.getColumnData("POE_REQHDR.DROPSHIP")="Y"
		callpoint!.setColumnEnabled("POE_REQHDR.DROPSHIP",1)
		callpoint!.setColumnEnabled("POE_REQHDR.CUSTOMER_ID",1)
		callpoint!.setColumnEnabled("POE_REQHDR.ORDER_NO",1)
	else
		callpoint!.setColumnEnabled("POE_REQHDR.DROPSHIP",1)
		callpoint!.setColumnEnabled("POE_REQHDR.CUSTOMER_ID",0)
		callpoint!.setColumnEnabled("POE_REQHDR.ORDER_NO",0)
	endif
endif

callpoint!.setStatus("REFRESH")

return

queue_for_printing:

poe_reqprint_dev=fnget_dev("POE_REQPRINT")
dim poe_reqprint$:fnget_tpl$("POE_REQPRINT")

poe_reqprint.firm_id$=firm_id$
poe_reqprint.vendor_id$=callpoint!.getColumnData("POE_REQHDR.VENDOR_ID")
poe_reqprint.req_no$=callpoint!.getColumnData("POE_REQHDR.REQ_NO")

writerecord (poe_reqprint_dev)poe_reqprint$

return
[[POE_REQHDR.BSHO]]
rem print 'show';rem debug
rem --- inits

	use ::ado_util.src::util

rem --- Open Files
	num_files=10
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="IVS_PARAMS",open_opts$[2]="OTA"
	open_tables$[3]="POS_PARAMS",open_opts$[3]="OTA"
	open_tables$[4]="APM_VENDHIST",open_opts$[4]="OTA"
	open_tables$[5]="IVM_ITEMWHSE",open_opts$[5]="OTA"
	open_tables$[6]="IVM_ITEMVEND",open_opts$[6]="OTA"
	open_tables$[7]="IVM_ITEMMAST",open_opts$[7]="OTA"
	open_tables$[8]="IVM_ITEMSYN",open_opts$[8]="OTA"
	open_tables$[9]="POE_REQPRINT",open_opts$[9]="OTA"
	open_tables$[10]="APM_VENDCMTS",open_opts$[10]="OTA"

	gosub open_tables
	aps_params_dev=num(open_chans$[1]),aps_params_tpl$=open_tpls$[1]
	ivs_params_dev=num(open_chans$[2]),ivs_params_tpl$=open_tpls$[2]
	pos_params_dev=num(open_chans$[3]),pos_params_tpl$=open_tpls$[3]
	apm_vendhist_dev=num(open_chans$[4]),apm_vendhist_tpl$=open_tpls$[4]
	ivm_itemwhse_dev=num(open_chans$[5]),ivm_itemwhse_tpl$=open_tpls$[5]
	ivm_itemvend_dev=num(open_chans$[6]),ivm_itemvend_tpl$=open_tpls$[6]

rem --- Verify that there are line codes - abort if not.

	poc_linecode_dev=fnget_dev("POC_LINECODE")
	readrecord(poc_linecode_dev,key=firm_id$,dom=*next)
	found_one$="N"
	while 1
		poc_linecode_key$=key(poc_linecode_dev,end=*break)
		if pos(firm_id$=poc_linecode_key$)=1 found_one$="Y"
		break
	wend
	if found_one$="N"
		msg_id$="MISSING_LINECODE"
		gosub disp_message
		release
	endif

rem --- call adc_application to see if OE is installed; if so, open a couple tables for potential use if linking PO to SO for dropship

	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","OP",info$[all]
	callpoint!.setDevObject("OP_installed",info$[20])
	if info$[20]="Y"
		num_files=6
		dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
		open_tables$[1]="ARM_CUSTMAST",open_opts$[1]="OTA"
		open_tables$[2]="ARM_CUSTSHIP",open_opts$[2]="OTA"
		open_tables$[3]="OPE_ORDSHIP",open_opts$[3]="OTA"
		open_tables$[4]="OPE_ORDHDR",open_opts$[4]="OTA"
		open_tables$[5]="OPE_ORDDET",open_opts$[5]="OTA"
		open_tables$[6]="OPC_LINECODE",open_opts$[6]="OTA"
		gosub open_tables
	
		opc_linecode_dev=num(open_chans$[6])
		dim opc_linecode$:open_tpls$[6]
		
		let oe_dropship$=""
		read record (opc_linecode_dev,key=firm_id$,dom=*next)
		
		while 1
			read record (opc_linecode_dev,end=*break)opc_linecode$
			if opc_linecode.firm_id$<>firm_id$ then break
			if opc_linecode.dropship$="Y" then oe_dropship$=oe_dropship$+opc_linecode.line_code$
		wend
		
		callpoint!.setDevObject("oe_ds_line_codes",oe_dropship$)
	endif

rem --- AP Params
	dim aps_params$:aps_params_tpl$
	read record(aps_params_dev,key=firm_id$+"AP00")aps_params$

rem --- store total amount control in devObject

	tamt!=util.getControl(callpoint!,"<<DISPLAY>>.ORDER_TOTAL")
	callpoint!.setDevObject("tamt",tamt!)

rem --- store default PO Line Code from POS_PARAMS
	
	dim pos_params$:fnget_tpl$("POS_PARAMS")
	read record (pos_params_dev,key=firm_id$+"PO00")pos_params$
	callpoint!.setDevObject("dflt_po_line_code",pos_params.po_line_code$)
	
rem --- get IV precision

	dim ivs_params$:fnget_tpl$("IVS_PARAMS")
	read record (ivs_params_dev,key=firm_id$+"IV00")ivs_params$
	callpoint!.setDevObject("iv_prec",ivs_params.precision$)	


rem --- store dtlGrid! and column for sales order line# reference listbutton (within grid) in devObject

	dtlWin!=Form!.getChildWindow(1109)
	dtlGrid!=dtlWin!.getControl(5900)
	callpoint!.setDevObject("dtl_grid",dtlGrid!)
	callpoint!.setDevObject("so_seq_ref_col",13)


rem --- store dropship control so it can be retrieved and enabled/disabled from detail grid

	c!=util.getControl(callpoint!,"POE_REQHDR.DROPSHIP")
	callpoint!.setDevObject("dropship_ctl",c!)
