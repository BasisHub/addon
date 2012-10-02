[[POE_RECHDR.RECPT_DATE.AVAL]]
rem --- check receipt date
if callpoint!.getDevObject("gl_installed")="Y"
	call stbl("+DIR_PGM")+"glc_datecheck.aon",callpoint!.getUserInput(),"Y",period$,year$,status
	if status>99 then callpoint!.setStatus("ABORT")
endif
[[POE_RECHDR.RECEIVER_NO.AVAL]]
rem --- don't allow user to assign new receiver# -- use Barista seq#
rem --- if user made null entry (to assign next seq automatically) then getRawUserInput() will be empty
rem --- if not empty, then the user typed a number -- if an existing receiver, fine; if not, abort

if cvs(callpoint!.getRawUserInput(),3)<>""
	msk$=callpoint!.getTableColumnAttribute("POE_RECHDR.PO_NO","MSKI")
	find_receiver$=str(num(callpoint!.getRawUserInput()):msk$)
	poe_rechdr_dev=fnget_dev("POE_RECHDR")
	dim poe_rechdr$:fnget_tpl$("POE_RECHDR")
	read record (poe_rechdr_dev,key=firm_id$+find_receiver$,dom=*next)poe_rechdr$
	if poe_rechdr.firm_id$<>firm_id$ or  poe_rechdr.receiver_no$<>find_receiver$
		msg_id$="PO_INVAL_RECVR"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
endif
[[POE_RECHDR.PO_NO.AVAL]]
rem --- Create Receipt from PO

if cvs(callpoint!.getUserInput(),3)<>""


	rem --- check receiver history file for this receiver#/po#; since using auto-number receiver #'s, this shouldn't happen unless auto# gets reset
	pot_rechdr_dev=fnget_dev("POT_RECHDR")
	dim pot_rechdr$:fnget_tpl$("POT_RECHDR")
	readrecord (pot_rechdr_dev,key=firm_id$+callpoint!.getUserInput()+callpoint!.getColumnData("POE_RECHDR.RECEIVER_NO"),dom=*next)pot_rechdr$
	if pot_rechdr$.firm_id$<>firm_id$ or pot_rechdr.po_no$<>callpoint!.getUserInput() or pot_rechdr.receiver_no$<>callpoint!.getColumnData("POE_RECHDR.RECEIVER_NO")

		msg_id$="PO_CREATE_REC"
		gosub disp_message

		if msg_opt$="Y"

			rem --- launch form to ask receive complete/default receipt qty

			call stbl("+DIR_SYP")+"bam_run_prog.bbj", "POE_RECDFLTS", stbl("+USER_ID"), "MNT", "", table_chans$[all]
			callpoint!.setStatus("ACTIVATE")

			rem --- write the poe_rechdr and det recs

			poe_rechdr_dev=fnget_dev("POE_RECHDR")
			dim poe_rechdr$:fnget_tpl$("POE_RECHDR")
			poe_pohdr_dev=fnget_dev("POE_POHDR")
			dim poe_pohdr$:fnget_tpl$("POE_POHDR")
			poe_recdet_dev=fnget_dev("POE_RECDET")
			dim poe_recdet$:fnget_tpl$("POE_RECDET")
			poe_podet_dev=fnget_dev("POE_PODET")
			dim poe_podet$:fnget_tpl$("POE_PODET")
			ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")

			receiver_no$=callpoint!.getColumnData("POE_RECHDR.RECEIVER_NO")
			po_no$=callpoint!.getUserInput()
			
			read record (poe_pohdr_dev,key=firm_id$+po_no$,dom=*break) poe_pohdr$
			call stbl("+DIR_PGM")+"adc_copyfile.aon",poe_pohdr$,poe_rechdr$,status	
			poe_rechdr.receiver_no$=receiver_no$
			poe_rechdr.recpt_date$=sysinfo.system_date$
			poe_rechdr.rec_complete$=callpoint!.getDevObject("rec_complete")
			write record (poe_rechdr_dev) poe_rechdr$

			read record(poe_podet_dev,key=firm_id$+po_no$,dom=*next)
			msg_printed=0
			while 1
				read record(poe_podet_dev,end=*break) poe_podet$
				if poe_podet.po_no$<>po_no$ or poe_podet.firm_id$<>firm_id$ then break
				dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
				ivm_itemmast.firm_id$=firm_id$	
				ivm_itemmast.item_id$=poe_podet.item_id$
				while 1
					read record (ivm_itemmast_dev,key=firm_id$+poe_podet.item_id$,dom=*break)ivm_itemmast$
					if pos(str(callpoint!.getDevObject("lot_or_serial"))="LS")<>0 and msg_printed=0 and ivm_itemmast.lotser_item$="Y" and ivm_itemmast.inventoried$="Y"
						msg_id$="PO_NEED_LOTS"
						msg_printed=1
						gosub disp_message
					endif
					break
				wend
				dim poe_recdet$:fnget_tpl$("POE_RECDET")
				call stbl("+DIR_PGM")+"adc_copyfile.aon",poe_podet$,poe_recdet$,status
				poe_recdet.receiver_no$=receiver_no$
				poe_recdet.qty_prev_rec$=poe_podet.qty_received$
				if callpoint!.getDevObject("dflt_rec_qty")="Y"
					poe_recdet.qty_received=poe_recdet.qty_ordered-poe_recdet.qty_prev_rec
				endif
				write record (poe_recdet_dev) poe_recdet$

			wend

			callpoint!.setStatus("RECORD:["+firm_id$+receiver_no$+"]")

		else

			callpoint!.setStatus("ABORT")

		endif
	else
		msg_id$="PO_REC_HIST"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
endif
[[POE_RECHDR.VENDOR_ID.AVAL]]
vendor_id$=callpoint!.getUserInput()
gosub vendor_info
gosub disp_vendor_comments

[[POE_RECHDR.DROPSHIP.AVAL]]
rem --- if turning off dropship flag, clear devObject items

if callpoint!.getUserInput()="N"
	callpoint!.setDevObject("ds_orders","N")
	callpoint!.setDevObject("so_ldat","")
	callpoint!.setDevObject("so_lines_list","")
	callpoint!.setTableColumnAttribute("POE_RECHDR.CUSTOMER_ID","MINL","0")	
	callpoint!.setTableColumnAttribute("POE_RECHDR.ORDER_NO","MINL","0")
else
	callpoint!.setTableColumnAttribute("POE_RECHDR.CUSTOMER_ID","MINL","1")
	if callpoint!.getDevObject("OP_installed")="Y"
		callpoint!.setTableColumnAttribute("POE_RECHDR.ORDER_NO","MINL","1")
	endif
endif
[[POE_RECHDR.CUSTOMER_ID.AVAL]]
rem --- if dropshipping, retrieve/display specified shipto address

	callpoint!.setColumnData("POE_RECHDR.ORDER_NO","")
	callpoint!.setColumnData("POE_RECHDR.SHIPTO_NO","")
	callpoint!.setColumnData("POE_RECHDR.DS_ADDR_LINE_1","")
	callpoint!.setColumnData("POE_RECHDR.DS_ADDR_LINE_2","")
	callpoint!.setColumnData("POE_RECHDR.DS_ADDR_LINE_3","")
	callpoint!.setColumnData("POE_RECHDR.DS_ADDR_LINE_4","")
	callpoint!.setColumnData("POE_RECHDR.DS_CITY","")
	callpoint!.setColumnData("POE_RECHDR.DS_NAME","")
	callpoint!.setColumnData("POE_RECHDR.DS_STATE_CD","")
	callpoint!.setColumnData("POE_RECHDR.DS_ZIP_CODE","")

	tmp_customer_id$=callpoint!.getUserInput()
	gosub shipto_cust;rem will refresh address w/ that from order once order# is entered
	
	callpoint!.setStatus("REFRESH")
[[POE_RECHDR.ORDER_NO.AVAL]]
rem --- if dropshipping, retrieve specified sales order and display shipto address

if cvs(callpoint!.getColumnData("POE_RECHDR.CUSTOMER_ID"),3)<>""

	tmp_customer_id$=callpoint!.getColumnData("POE_RECHDR.CUSTOMER_ID")
	tmp_order_no$=callpoint!.getUserInput()

	gosub dropship_shipto
	gosub get_dropship_order_lines

	if callpoint!.getDevObject("ds_orders")<>"Y" and cvs(callpoint!.getUserInput(),3)<>""
		msg_id$="PO_NO_SO_LINES"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif			
endif
[[POE_RECHDR.ADIS]]
vendor_id$=callpoint!.getColumnData("POE_RECHDR.VENDOR_ID")
purch_addr$=callpoint!.getColumnData("POE_RECHDR.PURCH_ADDR")
gosub vendor_info
gosub disp_vendor_comments
gosub purch_addr_info
gosub whse_addr_info

rem --- depending on whether or not drop-ship flag is selected and OE is installed, set min lengths for cust# and order#

callpoint!.setTableColumnAttribute("POE_RECHDR.CUSTOMER_ID","MINL","1")
if callpoint!.getDevObject("OP_installed")="Y"
	callpoint!.setTableColumnAttribute("POE_RECHDR.ORDER_NO","MINL","1")
endif

rem --- disable drop-ship checkbox, customer, order until/unless no detail exists

dtl!=gridvect!.getItem(0)		
if dtl!.size()
	callpoint!.setDevObject("dtl_posted","Y")
else
	callpoint!.setDevObject("dtl_posted","")
endif
gosub enable_dropship_fields 
[[POE_RECHDR.AREC]]
gosub  form_inits
[[POE_RECHDR.APFE]]
rem --- set total order amt

total_amt=num(callpoint!.getDevObject("total_amt"))
callpoint!.setColumnData("<<DISPLAY>>.ORDER_TOTAL",str(total_amt))
tamt!=callpoint!.getDevObject("tamt")
tamt!.setValue(total_amt)

rem --- check dtl_posted flag to see if dropship fields should be disabled

gosub enable_dropship_fields 
[[POE_RECHDR.ADEL]]

rem ---  loop thru gridVect! -- for each row that isn't marked deleted:
rem --- 1. call atamo to reverse OO qty for each dtl row that isn't from the original PO and isn't a dropship
rem --- 2. get rid of poe_linked (poe-08) records, if applicable (will only exist on a dropship)
rem --- 3. remove lot/serial records [removal of work order stuff not yet implemented (need)]

	poe_reclsdet_dev=fnget_dev("POE_RECLSDET")
	poe_linked_dev=fnget_dev("POE_LINKED")

	dim poe_reclsdet$:fnget_tpl$("POE_RECLSDET")

	g!=gridVect!.getItem(0)
	dim poe_recdet$:dtlg_param$[1,3]

	if g!.size()	
		for x=0 to g!.size()-1
			if callpoint!.getGridRowDeleteStatus(x)<>"Y"
				poe_recdet$=g!.getItem(x)				
		
				rem --- reverse OO qty 
				if cvs(poe_recdet.po_no$,3)="" and callpoint!.getColumnData("POE_RECHDR.DROPSHIP")<>"Y" 

					status = 999
					call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs_params$,items$[all],refs$[all],refs[all],table_chans$[all],status
					if status then goto std_exit
		 
					items$[0]=firm_id$
		 			items$[1]=poe_recdet.warehouse_id$
					items$[2]=poe_recdet.item_id$
					refs[0]=-(poe_recdet.qty_ordered - poe_recdet.qty_prev_rec)*poe_recdet.conv_factor
					action$="OO"

					if refs[0]<>0 then call stbl("+DIR_PGM")+"ivc_itemupdt.aon",action$,chan[all],ivs_params$,items$[all],refs$[all],refs[all],table_chans$[all],status
				endif

				rem --- remove poe_linked
				if cvs(poe_recdet.po_no$,3)=""
					remove (poe_linked_dev,key=firm_id$+poe_recdet.po_no$+poe_recdet.internal_seq_no$,dom=*next)
				endif

				rem --- remove lot/ser records				
				read (poe_reclsdet_dev,key=firm_id$+poe_recdet.receiver_no$+poe_recdet.internal_seq_no$,dom=*next)
	
				while 1
					read record (poe_reclsdet_dev,end=*break)poe_reclsdet$
					if pos(firm_id$+poe_recdet.receiver_no$+poe_recdet.internal_seq_no$=poe_reclsdet$)<>1 then break
					remove (poe_reclsdet_dev,key=poe_reclsdet.firm_id$+poe_reclsdet.receiver_no$+poe_reclsdet.po_int_seq_ref$+poe_reclsdet.sequence_no$)
				wend
				
			endif
		next x
	endif
[[POE_RECHDR.ARNF]]
rem -- set default values
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
	callpoint!.setColumnData("POE_RECHDR.WAREHOUSE_ID",ivs_params.warehouse_id$)
	gosub whse_addr_info

	callpoint!.setColumnData("POE_RECHDR.ORD_DATE",sysinfo.system_date$)
	callpoint!.setColumnData("POE_RECHDR.AP_TERMS_CODE",apm02a.ap_terms_code$)
	callpoint!.setColumnData("POE_RECHDR.PO_FRT_TERMS",pos_params.po_frt_terms$)
	callpoint!.setColumnData("POE_RECHDR.AP_SHIP_VIA",pos_params.ap_ship_via$)
	callpoint!.setColumnData("POE_RECHDR.FOB",pos_params.fob$)
	callpoint!.setColumnData("POE_RECHDR.HOLD_FLAG",pos_params.hold_flag$)
	callpoint!.setColumnData("POE_RECHDR.PO_MSG_CODE",pos_params.po_msg_code$)
[[POE_RECHDR.WAREHOUSE_ID.AVAL]]
gosub whse_addr_info
[[POE_RECHDR.REQD_DATE.AVAL]]
tmp$=callpoint!.getUserInput()
if tmp$<>"" and tmp$<callpoint!.getColumnData("POE_RECHDR.ORD_DATE") then callpoint!.setStatus("ABORT")
[[POE_RECHDR.NOT_B4_DATE.AVAL]]
not_b4_date$=cvs(callpoint!.getUserInput(),2)
if not_b4_date$<>"" then
	if not_b4_date$<callpoint!.getColumnData("POE_RECHDR.ORD_DATE") then callpoint!.setStatus("ABORT")
	if not_b4_date$>callpoint!.getColumnData("POE_RECHDR.REQD_DATE") then callpoint!.setStatus("ABORT")
	promise_date$=cvs(callpoint!.getColumnData("POE_RECHDR.PROMISE_DATE"),2)
	if promise_date$<>"" and not_b4_date$>promise_date$ then callpoint!.setStatus("ABORT")
endif
[[POE_RECHDR.PROMISE_DATE.AVAL]]
tmp$=cvs(callpoint!.getUserInput(),2)
if tmp$<>"" and tmp$<callpoint!.getColumnData("POE_RECHDR.ORD_DATE") then callpoint!.setStatus("ABORT")
[[POE_RECHDR.BSHO]]
rem print 'show';rem debug
rem --- inits

	use ::ado_util.src::util

rem --- Open Files
	num_files=16
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="IVS_PARAMS",open_opts$[2]="OTA"
	open_tables$[3]="POS_PARAMS",open_opts$[3]="OTA"
	open_tables$[4]="APM_VENDHIST",open_opts$[4]="OTA"
	open_tables$[5]="IVM_ITEMWHSE",open_opts$[5]="OTA"
	open_tables$[6]="IVM_ITEMVEND",open_opts$[6]="OTA"
	open_tables$[7]="POE_POHDR",open_opts$[7]="OTA"
	open_tables$[8]="POE_PODET",open_opts$[8]="OTA"
	open_tables$[9]="POT_RECHDR",open_opts$[9]="OTA"
	open_tables$[10]="IVM_ITEMMAST",open_opts$[10]="OTA"
	open_tables$[11]="POE_LINKED",open_opts$[11]="OTA"
	open_tables$[12]="IVM_ITEMSYN",open_opts$[12]="OTA"
	open_tables$[13]="APM_VENDCMTS",open_opts$[13]="OTA"
	open_tables$[14]="POE_RECLSDET",open_opts$[14]="OTA"
	open_tables$[15]="IVS_PARAMS",open_opts$[15]="OTA"
	open_tables$[16]="IVM_LSMASTER",open_opts$[16]="OTA"

	gosub open_tables

	aps_params_dev=num(open_chans$[1]),aps_params_tpl$=open_tpls$[1]
	ivs_params_dev=num(open_chans$[2]),ivs_params_tpl$=open_tpls$[2]
	pos_params_dev=num(open_chans$[3]),pos_params_tpl$=open_tpls$[3]
	apm_vendhist_dev=num(open_chans$[4]),apm_vendhist_tpl$=open_tpls$[4]
	ivm_itemwhse_dev=num(open_chans$[5]),ivm_itemwhse_tpl$=open_tpls$[5]
	ivm_itemvend_dev=num(open_chans$[6]),ivm_itemvend_tpl$=open_tpls$[6]
	poe_pohdr_dev=num(open_chans$[7]),poe_pohdr_tpl$=open_tpls$[7]
	poe_podet_dev=num(open_chans$[8]),poe_podet_tpl$=open_tpls$[8]
	pot_rechdr_dev=num(open_chans$[9]),pot_rechdr_tpl$=open_tpls$[9]
	ivs01_dev=num(open_chans$[15]),ivs01a_tpl$=open_tpls$[15]

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

rem --- call adc_application to see if SF is installed

	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","SF",info$[all]
	callpoint!.setDevObject("SF_installed",info$[20])
	if info$[20]="Y"
		num_files=2
		dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
		open_tables$[1]="SFE_WOMATL",open_opts$[1]="OTA"
		open_tables$[2]="SFE_WOSUBCNT",open_opts$[2]="OTA"

		gosub open_tables
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
	
rem --- get IV param info

	dim ivs_params$:fnget_tpl$("IVS_PARAMS")
	read record (ivs_params_dev,key=firm_id$+"IV00")ivs_params$
	callpoint!.setDevObject("iv_prec",ivs_params.precision$)
	callpoint!.setDevObject("ivs_params_rec",ivs_params$)	
	callpoint!.setDevObject("lot_or_serial",ivs_params.lotser_flag$)

rem --- store dtlGrid! and column for sales order line# reference listbutton (within grid) in devObject

	dtlWin!=Form!.getChildWindow(1109)
	dtlGrid!=dtlWin!.getControl(5900)
	callpoint!.setDevObject("dtl_grid",dtlGrid!)
	callpoint!.setDevObject("so_seq_ref_col",15)

rem --- call glc_ctlcreate

gl$="N"
status=0
source$=""
glw11$=""
call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"PO",glw11$,gl$,status
if status<>0 then release

callpoint!.setDevObject("gl_installed",gl$)

rem --- Set up Lot/Serial button properly

	dim ivs01a$:ivs01a_tpl$
	readrecord(ivs01_dev,key=firm_id$+"IV00")ivs01a$
	switch pos(ivs01a.lotser_flag$="LS")
		case 1; callpoint!.setOptionText("LENT",Translate!.getTranslation("AON_LOT_ENTRY")); break
		case 2; callpoint!.setOptionText("LENT",Translate!.getTranslation("AON_SERIAL_ENTRY")); break
		case default; break
	swend

	callpoint!.setOptionEnabled("LENT",0)
[[POE_RECHDR.PURCH_ADDR.AVAL]]
vendor_id$=callpoint!.getColumnData("POE_RECHDR.VENDOR_ID")
purch_addr$=callpoint!.getUserInput()
gosub purch_addr_info
[[POE_RECHDR.ARAR]]
vendor_id$=callpoint!.getColumnData("POE_RECHDR.VENDOR_ID")
purch_addr$=callpoint!.getColumnData("POE_RECHDR.PURCH_ADDR")
gosub vendor_info
gosub purch_addr_info
gosub whse_addr_info
gosub form_inits

rem ---	depending on whether or not drop-ship flag is selected and OE is installed...
rem ---	if drop-ship is selected, load up sales order line#'s for the detail grid's so reference listbutton

if callpoint!.getColumnData("POE_RECHDR.DROPSHIP")="Y"

	if callpoint!.getDevObject("OP_installed")="Y"
		tmp_customer_id$=callpoint!.getColumnData("POE_RECHDR.CUSTOMER_ID")
		tmp_order_no$=callpoint!.getColumnData("POE_RECHDR.ORDER_NO")
		gosub get_dropship_order_lines

	endif
endif
[[POE_RECHDR.<CUSTOM>]]
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
	callpoint!.setColumnData("<<DISPLAY>>.PA_ZIP",apm05a.zip_code$)
	callpoint!.setStatus("REFRESH")
return

whse_addr_info: rem --- get and display Warehouse Address Info
	ivc_whsecode_dev=fnget_dev("IVC_WHSECODE")
	dim ivc_whsecode$:fnget_tpl$("IVC_WHSECODE")
	if pos("WAREHOUSE_ID.AVAL"=callpoint!.getCallpointEvent())<>0
		warehouse_id$=callpoint!.getUserInput()
	else
		warehouse_id$=callpoint!.getColumnData("POE_RECHDR.WAREHOUSE_ID")
	endif
	read record(ivc_whsecode_dev,key=firm_id$+"C"+warehouse_id$,dom=*next)ivc_whsecode$
	callpoint!.setColumnData("<<DISPLAY>>.W_ADDR1",ivc_whsecode$.addr_line_1$)
	callpoint!.setColumnData("<<DISPLAY>>.W_ADDR2",ivc_whsecode$.addr_line_2$)
	callpoint!.setColumnData("<<DISPLAY>>.W_CITY",ivc_whsecode$.city$)
	callpoint!.setColumnData("<<DISPLAY>>.W_STATE",ivc_whsecode$.state_code$)
	callpoint!.setColumnData("<<DISPLAY>>.W_ZIP",ivc_whsecode$.zip_code$)
	callpoint!.setStatus("REFRESH")
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
	callpoint!.setColumnData("POE_RECHDR.SHIPTO_NO",shipto_no$)
	if cvs(shipto_no$,3)=""
		gosub shipto_cust
	endif
	if num(shipto_no$,err=*endif)=99
		read record (ope_ordship_dev,key=firm_id$+tmp_customer_id$+tmp_order_no$,dom=*next)ope_ordship$
		dim rec$:fattr(ope_ordship$)
		rec$=ope_ordship$
		gosub fill_dropship_address
		callpoint!.setColumnData("POE_RECHDR.DS_NAME",rec.name$)
	endif
	if num(shipto_no$,err=*endif)>0 and num(shipto_no$,err=*endif)<99
		read record (arm_custship_dev,key=firm_id$+tmp_customer_id$+shipto_no$,dom=*next)arm_custship$
		dim rec$:fattr(arm_custship$)
		rec$=arm_custship$
		gosub fill_dropship_address
		callpoint!.setColumnData("POE_RECHDR.DS_NAME",rec.name$)
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
	callpoint!.setColumnData("POE_RECHDR.DS_NAME",rec.customer_name$)

return

fill_dropship_address:
	callpoint!.setColumnData("POE_RECHDR.DS_ADDR_LINE_1",rec.addr_line_1$)
	callpoint!.setColumnData("POE_RECHDR.DS_ADDR_LINE_2",rec.addr_line_2$)
	callpoint!.setColumnData("POE_RECHDR.DS_ADDR_LINE_3",rec.addr_line_3$)
	callpoint!.setColumnData("POE_RECHDR.DS_ADDR_LINE_4",rec.addr_line_4$)
	callpoint!.setColumnData("POE_RECHDR.DS_CITY",rec.city$)
	callpoint!.setColumnData("POE_RECHDR.DS_STATE_CD",rec.state_code$)
	callpoint!.setColumnData("POE_RECHDR.DS_ZIP_CODE",rec.zip_code$)
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
callpoint!.setDevObject("qty_received","")

callpoint!.setDevObject("total_amt","0")
callpoint!.setDevObject("dtl_posted","")

callpoint!.setTableColumnAttribute("POE_RECHDR.CUSTOMER_ID","MINL","0")	
callpoint!.setTableColumnAttribute("POE_RECHDR.ORDER_NO","MINL","0")

callpoint!.setColumnData("<<DISPLAY>>.COMMENTS","")

return

enable_dropship_fields:
rem disables/enables dropship fields if detail has (or hasn't) been created for this requisition
rem since warehouse in hdr can't be changed once detail is posted, handling that control here, too.

if callpoint!.getDevObject("dtl_posted")="Y"
	callpoint!.setColumnEnabled("POE_RECHDR.WAREHOUSE_ID",0)
	if callpoint!.getDevObject("OP_installed")="Y"
		callpoint!.setColumnEnabled("POE_RECHDR.DROPSHIP",0)
		callpoint!.setColumnEnabled("POE_RECHDR.CUSTOMER_ID",0)
		callpoint!.setColumnEnabled("POE_RECHDR.ORDER_NO",0)			
	else
		callpoint!.setColumnEnabled("POE_RECHDR.DROPSHIP",1)
		callpoint!.setColumnEnabled("POE_RECHDR.CUSTOMER_ID",1)
		callpoint!.setColumnEnabled("POE_RECHDR.ORDER_NO",0)		
	endif
else
	callpoint!.setColumnEnabled("POE_RECHDR.WAREHOUSE_ID",1)
	if callpoint!.getColumnData("POE_RECHDR.DROPSHIP")="Y"
		callpoint!.setColumnEnabled("POE_RECHDR.DROPSHIP",1)
		callpoint!.setColumnEnabled("POE_RECHDR.CUSTOMER_ID",1)
		callpoint!.setColumnEnabled("POE_RECHDR.ORDER_NO",1)
	else
		callpoint!.setColumnEnabled("POE_RECHDR.DROPSHIP",1)
		callpoint!.setColumnEnabled("POE_RECHDR.CUSTOMER_ID",0)
		callpoint!.setColumnEnabled("POE_RECHDR.ORDER_NO",0)
	endif
endif


callpoint!.setStatus("REFRESH")

return
