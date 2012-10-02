[[POE_POHDR.PO_NO.AVAL]]
rem --- don't allow user to assign new PO# -- use Barista seq#
rem --- if user made null entry (to assign next seq automatically) then getRawUserInput() will be empty
rem --- if not empty, then the user typed a number -- if an existing po, fine; if not, abort

if cvs(callpoint!.getRawUserInput(),3)<>""
	msk$=callpoint!.getTableColumnAttribute("POE_POHDR.PO_NO","MSKI")
	find_po$=str(num(callpoint!.getRawUserInput()):msk$)
	poe_pohdr_dev=fnget_dev("POE_POHDR")
	dim poe_pohdr$:fnget_tpl$("POE_POHDR")
	read record (poe_pohdr_dev,key=firm_id$+find_po$,dom=*next)poe_pohdr$
	if poe_pohdr.firm_id$<>firm_id$ or  poe_pohdr.po_no$<>find_po$
		msg_id$="PO_INVAL_PO"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
endif
[[POE_POHDR.AOPT-DPRT]]
rem --- on-demand PO print

vendor_id$=callpoint!.getColumnData("POE_POHDR.VENDOR_ID")
po_no$=callpoint!.getColumnData("POE_POHDR.PO_NO")

gosub queue_for_printing

if cvs(vendor_id$,3)<>"" and cvs(po_no$,3)<>""

	gosub queue_for_printing
	call "por_poprint.aon",vendor_id$,po_no$	

endif
[[POE_POHDR.AOPT-QPRT]]
gosub queue_for_printing

msg_id$="PO_QPRT"
gosub disp_message
[[POE_POHDR.BDEL]]
rem --- don't allow deletion if any detail line on the PO has a non-zero qty received
rem --- otherwise, give option to retain requisition (if applicable), reverse OO quantity, delete print and link records

if callpoint!.getDevObject("qty_received")="Y" 

	msg_id$="PO_NO_DELETE"
	gosub disp_message
	callpoint!.setStatus("ABORT")

else

	rem --- ask if user wants to retain the requisition (if this PO came from one); if so, re-create it

	if cvs(callpoint!.getColumnData("POE_POHDR.REQ_NO"),3)<>""

		msg_id$="PO_RETAIN_REQ"
		msg_opt$=""
		gosub disp_message
		if msg_opt$="Y"

			poe_reqhdr_dev=fnget_dev("POE_REQHDR")
			poe_reqdet_dev=fnget_dev("POE_REQDET")
			poe_pohdr_dev=fnget_dev("POE_POHDR")
			poe_podet_dev=fnget_dev("POE_PODET")

			dim poe_reqhdr$:fnget_tpl$("POE_REQHDR")
			dim poe_reqdet$:fnget_tpl$("POE_REQDET")
			dim poe_pohdr$:fnget_tpl$("POE_POHDR")
			dim poe_podet$:fnget_tpl$("POE_PODET")

			po_no$=callpoint!.getColumnData("POE_POHDR.PO_NO")
			
			read record (poe_pohdr_dev,key=firm_id$+po_no$,dom=*break) poe_pohdr$
			call stbl("+DIR_PGM")+"adc_copyfile.aon",poe_pohdr$,poe_reqhdr$,status	
			poe_reqhdr$=field(poe_reqhdr$)
			write record (poe_reqhdr_dev) poe_reqhdr$

			read (poe_podet_dev,key=poe_pohdr.firm_id$+poe_pohdr.po_no$,dom=*next)

			while 1
				read record (poe_podet_dev,end=*break)poe_podet$
				if pos(firm_id$+poe_pohdr.po_no$=poe_podet$)<>1 then break
				if num(poe_podet.req_qty$)=0 then continue
				call stbl("+DIR_PGM")+"adc_copyfile.aon",poe_podet$,poe_reqdet$,status
				poe_reqdet.req_no$=poe_reqhdr.req_no$;rem dataport util doesn't yet fill req_no in det recs, so get from hdr
				poe_reqdet$=field(poe_reqdet$)
				write record (poe_reqdet_dev)poe_reqdet$
			wend
			rem --- old version called poc_wa if shop floor was installed and requisition was retained --- that logic not enabled/tested here
			rem --- from v7 poe_bb.bbx:
			rem  IF SF$="N" OR RETAIN_REQ$="N" THEN GOTO RESET_PO_NO
			rem  READ (POE11_DEV,KEY=B0$,DOM=4630)
			rem  READ (POE11_DEV,END=RESET_PO_NO)IOL=POE11A
			rem  IF W0$(1,15)<>B0$ THEN GOTO RESET_PO_NO
			rem  IF CVS(W2$(1,7),2)="" THEN GOTO 4690
			rem  FIND (POM02_DEV,KEY=N0$+W1$(1,2),DOM=4690)IOL=POM02A
			rem  IF POS(Y1$(21,1)="NS")=0 THEN GOTO 4690
			rem  CALL "poc_wa.bbx",SFE22_DEV,SFE32_DEV,N0$,W0$(9),"R",Y1$,W2$(1,10),W2$(1,10),I[1],STATUS
			rem  GOTO 4630
		endif
	endif

	rem ---  loop thru gridVect! and call atamo to reverse OO qty for each dtl row that isn't already marked deleted (skip dropship orders)

	if callpoint!.getColumnData("POE_POHDR.DROPSHIP")<>"Y"
		g!=gridVect!.getItem(0)
		dim poe_podet$:dtlg_param$[1,3]

		if g!.size()	
			for x=0 to g!.size()-1
				if callpoint!.getGridRowDeleteStatus(x)<>"Y"
					poe_podet$=g!.getItem(x)

					status = 999
					call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs_params$,items$[all],refs$[all],refs[all],table_chans$[all],status
					if status then goto std_exit
		 
					items$[0]=firm_id$
		 			items$[1]=poe_podet.warehouse_id$
					items$[2]=poe_podet.item_id$
					refs[0]=-(poe_podet.qty_ordered - poe_podet.qty_received)*poe_podet.conv_factor
					action$="OO"

					if refs[0]<>0 then call stbl("+DIR_PGM")+"ivc_itemupdt.aon",action$,chan[all],ivs_params$,items$[all],refs$[all],refs[all],table_chans$[all],status
				endif
			next x
		endif
	endif

	rem ---  delete PO print records, and poe_linked records for dropships

	poe_poprint_dev=fnget_dev("POE_POPRINT")
	remove (poe_poprint_dev,key=firm_id$+callpoint!.getColumnData("POE_POHDR.VENDOR_ID")+callpoint!.getColumnData("POE_POHDR.PO_NO"),dom=*next)

	if callpoint!.getColumnData("POE_POHDR.DROPSHIP")="Y"

		poe_linked_dev=fnget_dev("POE_LINKED")
		dim poe_linked$:fnget_tpl$("POE_LINKED")
		read (poe_linked_dev,key=firm_id$+callpoint!.getColumnData("POE_POHDR.PO_NO"),dom=*next)

		while 1
			k$=key(poe_linked_dev,end=*break)
			read record (poe_linked_dev)poe_linked$
			if pos(firm_id$+callpoint!.getColumnData("POE_POHDR.PO_NO")=poe_linked$)<>1 then break
			remove (poe_linked_dev,key=k$)
		wend

	endif

endif
[[POE_POHDR.VENDOR_ID.AVAL]]
vendor_id$=callpoint!.getUserInput()
gosub vendor_info
gosub disp_vendor_comments

[[POE_POHDR.DROPSHIP.AVAL]]
rem --- if turning off dropship flag, clear devObject items

if callpoint!.getUserInput()="N"
	callpoint!.setDevObject("ds_orders","N")
	callpoint!.setDevObject("so_ldat","")
	callpoint!.setDevObject("so_lines_list","")
	callpoint!.setTableColumnAttribute("POE_POHDR.CUSTOMER_ID","MINL","0")	
	callpoint!.setTableColumnAttribute("POE_POHDR.ORDER_NO","MINL","0")
else
	callpoint!.setTableColumnAttribute("POE_POHDR.CUSTOMER_ID","MINL","1")
	if callpoint!.getDevObject("OP_installed")="Y"
		callpoint!.setTableColumnAttribute("POE_POHDR.ORDER_NO","MINL","1")
	endif
endif
[[POE_POHDR.CUSTOMER_ID.AVAL]]
rem --- if dropshipping, retrieve/display specified shipto address

	callpoint!.setColumnData("POE_POHDR.ORDER_NO","")
	callpoint!.setColumnData("POE_POHDR.SHIPTO_NO","")
	callpoint!.setColumnData("POE_POHDR.DS_ADDR_LINE_1","")
	callpoint!.setColumnData("POE_POHDR.DS_ADDR_LINE_2","")
	callpoint!.setColumnData("POE_POHDR.DS_ADDR_LINE_3","")
	callpoint!.setColumnData("POE_POHDR.DS_ADDR_LINE_4","")
	callpoint!.setColumnData("POE_POHDR.DS_CITY","")
	callpoint!.setColumnData("POE_POHDR.DS_NAME","")
	callpoint!.setColumnData("POE_POHDR.DS_STATE_CD","")
	callpoint!.setColumnData("POE_POHDR.DS_ZIP_CODE","")

	tmp_customer_id$=callpoint!.getUserInput()
	gosub shipto_cust;rem will refresh address w/ that from order once order# is entered
	
	callpoint!.setStatus("REFRESH")
[[POE_POHDR.ORDER_NO.AVAL]]
rem --- if dropshipping, retrieve specified sales order and display shipto address

if cvs(callpoint!.getColumnData("POE_POHDR.CUSTOMER_ID"),3)<>""

	tmp_customer_id$=callpoint!.getColumnData("POE_POHDR.CUSTOMER_ID")
	tmp_order_no$=callpoint!.getUserInput()

	gosub dropship_shipto
	gosub get_dropship_order_lines

	if callpoint!.getDevObject("ds_orders")<>"Y" and cvs(callpoint!.getUserInput(),3)<>""
		msg_id$="PO_NO_SO_LINES"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif			
endif
[[POE_POHDR.ADIS]]
vendor_id$=callpoint!.getColumnData("POE_POHDR.VENDOR_ID")
purch_addr$=callpoint!.getColumnData("POE_POHDR.PURCH_ADDR")
gosub vendor_info
gosub disp_vendor_comments
gosub purch_addr_info
gosub whse_addr_info

rem --- depending on whether or not drop-ship flag is selected and OE is installed, set min lengths for cust# and order#

callpoint!.setTableColumnAttribute("POE_POHDR.CUSTOMER_ID","MINL","1")
if callpoint!.getDevObject("OP_installed")="Y"
	callpoint!.setTableColumnAttribute("POE_POHDR.ORDER_NO","MINL","1")
endif

rem --- disable drop-ship checkbox, customer, order until/unless no detail exists

dtl!=gridvect!.getItem(0)		
if dtl!.size()
	callpoint!.setDevObject("dtl_posted","Y")
else
	callpoint!.setDevObject("dtl_posted","")
endif
gosub enable_dropship_fields 

rem --- check if receiver, QA receiver, or invoice exists for this PO.  If so, give warning and don't allow edits
rem --- old code checked poe-33 (QA), 34(receiver) and 35 (invoice GL dist); we'll use alt_key_01 on the 33 and 34 files, and we still have 35.
rem --- v6 code that accessed poe-35 looks like it could never have worked?

poe_qahdr_dev=fnget_dev("POE_QAHDR")
dim poe_qahdr$:fnget_tpl$("POE_QAHDR")

poe_rechdr_dev=fnget_dev("POE_RECHDR")
dim poe_rechdr$:fnget_tpl$("POE_RECHDR")

poe_invdet_dev=fnget_dev("POE_INVDET")
dim poe_invdet$:fnget_tpl$("POE_INVDET")

vendor_id$=callpoint!.getColumnData("POE_POHDR.VENDOR_ID")
po_no$=callpoint!.getColumnData("POE_POHDR.PO_NO")

read (poe_rechdr_dev,key=firm_id$+po_no$+vendor_id$,knum="AO_VEND_RCVR_PO",dom=*next)
read record (poe_rechdr_dev,err=*next)poe_rechdr$
if poe_rechdr.firm_id$=firm_id$ and poe_rechdr.vendor_id$=vendor_id$ and poe_rechdr.po_no$=po_no$
	msg_id$="PO_REC_EXISTS"
	gosub disp_message
	callpoint!.setStatus("NEWREC")
endif

read (poe_qahdr_dev,key=firm_id$+po_no$+vendor_id$,knum="AO_PO_VEND_RCVR",dom=*next)
read record (poe_qahdr_dev,err=*next)poe_qahdr$
if poe_qahdr.firm_id$=firm_id$ and poe_qahdr.vendor_id$=vendor_id$ and poe_qahdr.po_no$=po_no$
	msg_id$="PO_QA_EXISTS"
	gosub disp_message
	callpoint!.setStatus("NEWREC")
endif

read (poe_invdet_dev,key=firm_id$+po_no$+vendor_id$,knum="AO_PO_VEND",dom=*next)
read record (poe_invdet_dev,err=*next)poe_invdet$
if poe_invdet.firm_id$=firm_id$ and poe_invdet.vendor_id$=vendor_id$ and poe_invdet.po_no$=po_no$
	msg_id$="PO_INV_EXISTS"
	gosub disp_message
	callpoint!.setStatus("NEWREC")
endif
[[POE_POHDR.AREC]]
gosub  form_inits
[[POE_POHDR.APFE]]
rem --- set total order amt

total_amt=num(callpoint!.getDevObject("total_amt"))
callpoint!.setColumnData("<<DISPLAY>>.ORDER_TOTAL",str(total_amt))
tamt!=callpoint!.getDevObject("tamt")
tamt!.setValue(total_amt)

rem --- check dtl_posted flag to see if dropship fields should be disabled

gosub enable_dropship_fields 
[[POE_POHDR.AWRI]]
rem --- need to put out poe_poprint record

gosub queue_for_printing


[[POE_POHDR.REQ_NO.AVAL]]
rem --- Load PO from requisition

if cvs(callpoint!.getUserInput(),3)<>""

	msg_id$="PO_CREATE_REQ"
	gosub disp_message

	if msg_opt$="Y"

		rem --- write the po and podet recs, plus the print rec and poe_linked rec (if dropship)
		rem --- also call atamo to adjust on order qty for S line types
		rem --- also calls poc_wa (not yet implemented).

		status = 999
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs_params$,items$[all],refs$[all],refs[all],table_chans$[all],status
		if status then goto std_exit

		poe_reqhdr_dev=fnget_dev("POE_REQHDR")
		dim poe_reqhdr$:fnget_tpl$("POE_REQHDR")
		poe_pohdr_dev=fnget_dev("POE_POHDR")
		dim poe_pohdr$:fnget_tpl$("POE_POHDR")
		poe_reqdet_dev=fnget_dev("POE_REQDET")
		dim poe_reqdet$:fnget_tpl$("POE_REQDET")
		poe_podet_dev=fnget_dev("POE_PODET")
		poe_reqprint_dev=fnget_dev("POE_REQPRINT")

		poe_linked_dev=fnget_dev("POE_LINKED")
		dim poe_linked$:fnget_tpl$("POE_LINKED")
		poe_poprint_dev=fnget_dev("POE_POPRINT")
		dim poe_poprint$:fnget_tpl$("POE_POPRINT")
		poc_linecode_dev=fnget_dev("POC_LINECODE")
		dim poc_linecode$:fnget_tpl$("POC_LINECODE")

		po_no$=callpoint!.getColumnData("POE_POHDR.PO_NO")
		req_no$=callpoint!.getUserInput()
		
		read record (poe_reqhdr_dev,key=firm_id$+req_no$,dom=*break) poe_reqhdr$
		call stbl("+DIR_PGM")+"adc_copyfile.aon",poe_reqhdr$,poe_pohdr$,status	
		poe_pohdr.po_no$=po_no$
		write record (poe_pohdr_dev) poe_pohdr$

		poe_poprint.firm_id$=firm_id$
		poe_poprint.vendor_id$=poe_pohdr.vendor_id$
		poe_poprint.po_no$=poe_pohdr.po_no$
		write record (poe_poprint_dev)poe_poprint$

		read record(poe_reqdet_dev,key=firm_id$+req_no$,dom=*next)
		while 1
			read record(poe_reqdet_dev) poe_reqdet$
			if poe_reqdet.req_no$<>req_no$ or poe_reqdet.firm_id$<>firm_id$ then break
			dim poe_podet$:fnget_tpl$("POE_PODET")
			call stbl("+DIR_PGM")+"adc_copyfile.aon",poe_reqdet$,poe_podet$,status
			poe_podet.po_no$=po_no$
			poe_podet.qty_ordered=poe_reqdet.req_qty
			write record (poe_podet_dev) poe_podet$

			find record (poc_linecode_dev,key=firm_id$+poe_podet.po_line_code$,dom=*next)poc_linecode$
			if poc_linecode.line_type$="S"
				items$[0]=firm_id$
				items$[1]=poe_podet.warehouse_id$
				items$[2]=poe_podet.item_id$
				refs[0]=poe_podet.qty_ordered*poe_podet.conv_factor
				action$="OO"
		                call stbl("+DIR_PGM")+"ivc_itemupdt.aon",action$,chan[all],ivs_params$,items$[all],refs$[all],refs[all],table_chans$[all],status
			endif

			rem --- Update work order?

			if callpoint!.getDevObject("SF_installed")<>"N" and pos(poc_linecode.line_type$="NS")<>0 and cvs(poe_podet.wo_no$,2)<>""
	escape;rem logic not yet exercised - poc_wa not yet debugged
				sfe_womatl_dev=fnget_dev("SFE_WOMATL")
				sfe_wosubcnt_dev=fnget_dev("SFE_WOSUBCNT")
				oldwo$=poe_podet.wo_no$+poe_podet.wo_seq_ref$
				newwo$=oldwo$,po$=poe_podet.po_no$+poe_podet.internal_seq_no$
				call stbl("+DIR_PGM")+"poc_wa.bbx",sfe_womatl_dev,sfe_wosubcnt_dev,firm_id$,po$,"P",poc_linecode.code_desc$,oldwo$,newwo$,i[1],status
			endif

			rem --- Update PO to OP link

			if cvs(poe_pohdr.customer_id$+poe_pohdr.order_no$,2)<>""
				dim poe_linked$:fattr(poe_linked$)
				poe_linked.firm_id$=firm_id$
				poe_linked.po_no$=poe_pohdr.po_no$
				poe_linked.poedet_seq_ref$=poe_podet.internal_seq_no$
				poe_linked.customer_id$=poe_pohdr.customer_id$
				poe_linked.order_no$=poe_pohdr.order_no$
				poe_linked.opedet_seq_ref$=poe_podet.so_int_seq_ref$
				poe_linked$=field(poe_linked$)
				write record (poe_linked_dev) poe_linked$
			endif

		wend

		rem --- delete the requisition

		status=0
		dim files[20]
    		files[2]=poc_linecode_dev
		files[3]=poe_reqhdr_dev
    		files[4]=poe_reqdet_dev
    		files[5]=poe_reqprint_dev
		files[13]=poe_linked_dev
	
		sf_installed$=str(callpoint!.getDevObject("SF_installed"))
        		dtl_tpl$=fattr(poe_reqdet$)
        		hdr_pri_key$=poe_reqhdr.firm_id$+poe_reqhdr.req_no$
       		hdr_alt_key1$=poe_reqhdr.firm_id$+poe_reqhdr.vendor_id$+poe_reqhdr.req_no$
		dim ivs_params$:fnget_tpl$("IVS_PARAMS")
		ivs_params$=str(callpoint!.getDevObject("ivs_params_rec"))
        		call stbl("+DIR_PGM")+"poc_deletepo.aon","R",files[all],sf_installed$,ivs_params$,hdr_pri_key$,hdr_alt_key1$,dtl_tpl$,status

		callpoint!.setStatus("RECORD:["+firm_id$+po_no$+"]")

	else

		callpoint!.setStatus("ABORT")

	endif
endif
	
[[POE_POHDR.ARNF]]
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
	callpoint!.setColumnData("POE_POHDR.WAREHOUSE_ID",ivs_params.warehouse_id$)
	gosub whse_addr_info
	callpoint!.setColumnData("POE_POHDR.ORD_DATE",sysinfo.system_date$)
	callpoint!.setColumnData("POE_POHDR.AP_TERMS_CODE",apm02a.ap_terms_code$)
	callpoint!.setColumnData("POE_POHDR.PO_FRT_TERMS",pos_params.po_frt_terms$)
	callpoint!.setColumnData("POE_POHDR.AP_SHIP_VIA",pos_params.ap_ship_via$)
	callpoint!.setColumnData("POE_POHDR.FOB",pos_params.fob$)
	callpoint!.setColumnData("POE_POHDR.HOLD_FLAG",pos_params.hold_flag$)
	callpoint!.setColumnData("POE_POHDR.PO_MSG_CODE",pos_params.po_msg_code$)
[[POE_POHDR.WAREHOUSE_ID.AVAL]]
gosub whse_addr_info
[[POE_POHDR.REQD_DATE.AVAL]]
tmp$=callpoint!.getUserInput()
if tmp$<>"" and tmp$<callpoint!.getColumnData("POE_POHDR.ORD_DATE") then callpoint!.setStatus("ABORT")
[[POE_POHDR.NOT_B4_DATE.AVAL]]
not_b4_date$=cvs(callpoint!.getUserInput(),2)
if not_b4_date$<>"" then
	if not_b4_date$<callpoint!.getColumnData("POE_POHDR.ORD_DATE") then callpoint!.setStatus("ABORT")
	if not_b4_date$>callpoint!.getColumnData("POE_POHDR.REQD_DATE") then callpoint!.setStatus("ABORT")
	promise_date$=cvs(callpoint!.getColumnData("POE_POHDR.PROMISE_DATE"),2)
	if promise_date$<>"" and not_b4_date$>promise_date$ then callpoint!.setStatus("ABORT")
endif
[[POE_POHDR.PROMISE_DATE.AVAL]]
tmp$=cvs(callpoint!.getUserInput(),2)
if tmp$<>"" and tmp$<callpoint!.getColumnData("POE_POHDR.ORD_DATE") then callpoint!.setStatus("ABORT")
[[POE_POHDR.BSHO]]
rem print 'show';rem debug
rem --- inits

	use ::ado_util.src::util

rem --- Open Files
	num_files=17
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="IVS_PARAMS",open_opts$[2]="OTA"
	open_tables$[3]="POS_PARAMS",open_opts$[3]="OTA"
	open_tables$[4]="APM_VENDHIST",open_opts$[4]="OTA"
	open_tables$[5]="IVM_ITEMWHSE",open_opts$[5]="OTA"
	open_tables$[6]="IVM_ITEMVEND",open_opts$[6]="OTA"
	open_tables$[7]="POE_REQHDR",open_opts$[7]="OTA"
	open_tables$[8]="POE_REQDET",open_opts$[8]="OTA"
	open_tables$[9]="POE_POPRINT",open_opts$[9]="OTA"
	open_tables$[10]="IVM_ITEMMAST",open_opts$[10]="OTA"
	open_tables$[11]="POE_LINKED",open_opts$[11]="OTA"
	open_tables$[12]="IVM_ITEMSYN",open_opts$[12]="OTA"
	open_tables$[13]="POE_REQPRINT",open_opts$[13]="OTA"
	open_tables$[14]="POE_QAHDR",open_opts$[14]="OTA"
	open_tables$[15]="POE_RECHDR",open_opts$[15]="OTA"
	open_tables$[16]="POE_INVDET",open_opts$[16]="OTA"
	open_tables$[17]="APM_VENDCMTS",open_opts$[17]="OTA"

	gosub open_tables

	aps_params_dev=num(open_chans$[1]),aps_params_tpl$=open_tpls$[1]
	ivs_params_dev=num(open_chans$[2]),ivs_params_tpl$=open_tpls$[2]
	pos_params_dev=num(open_chans$[3]),pos_params_tpl$=open_tpls$[3]
	apm_vendhist_dev=num(open_chans$[4]),apm_vendhist_tpl$=open_tpls$[4]
	ivm_itemwhse_dev=num(open_chans$[5]),ivm_itemwhse_tpl$=open_tpls$[5]
	ivm_itemvend_dev=num(open_chans$[6]),ivm_itemvend_tpl$=open_tpls$[6]
	poe_reqhdr_dev=num(open_chans$[7]),poe_reqhdr_tpl$=open_tpls$[7]
	poe_reqdet_dev=num(open_chans$[8]),poe_reqdet_tpl$=open_tpls$[8]
	poe_poprint_dev=num(open_chans$[9]),poe_poprint_tpl$=open_tpls$[9]

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
	
rem --- get IV precision

	dim ivs_params$:fnget_tpl$("IVS_PARAMS")
	read record (ivs_params_dev,key=firm_id$+"IV00")ivs_params$
	callpoint!.setDevObject("iv_prec",ivs_params.precision$)
	callpoint!.setDevObject("ivs_params_rec",ivs_params$)	

rem --- store dtlGrid! and column for sales order line# reference listbutton (within grid) in devObject

	dtlWin!=Form!.getChildWindow(1109)
	dtlGrid!=dtlWin!.getControl(5900)
	callpoint!.setDevObject("dtl_grid",dtlGrid!)
	callpoint!.setDevObject("so_seq_ref_col",14)
[[POE_POHDR.PURCH_ADDR.AVAL]]
vendor_id$=callpoint!.getColumnData("POE_POHDR.VENDOR_ID")
purch_addr$=callpoint!.getUserInput()
gosub purch_addr_info
[[POE_POHDR.ARAR]]
vendor_id$=callpoint!.getColumnData("POE_POHDR.VENDOR_ID")
purch_addr$=callpoint!.getColumnData("POE_POHDR.PURCH_ADDR")
gosub vendor_info
gosub purch_addr_info
gosub whse_addr_info
gosub form_inits

rem ---	depending on whether or not drop-ship flag is selected and OE is installed...
rem ---	if drop-ship is selected, load up sales order line#'s for the detail grid's so reference listbutton

if callpoint!.getColumnData("POE_POHDR.DROPSHIP")="Y"

	if callpoint!.getDevObject("OP_installed")="Y"
		tmp_customer_id$=callpoint!.getColumnData("POE_POHDR.CUSTOMER_ID")
		tmp_order_no$=callpoint!.getColumnData("POE_POHDR.ORDER_NO")
		gosub get_dropship_order_lines

	endif
endif
[[POE_POHDR.<CUSTOM>]]
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
		warehouse_id$=callpoint!.getColumnData("POE_POHDR.WAREHOUSE_ID")
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
	callpoint!.setColumnData("POE_POHDR.SHIPTO_NO",shipto_no$)
	if cvs(shipto_no$,3)=""
		gosub shipto_cust
	endif
	if num(shipto_no$,err=*endif)=99
		read record (ope_ordship_dev,key=firm_id$+tmp_customer_id$+tmp_order_no$,dom=*next)ope_ordship$
		dim rec$:fattr(ope_ordship$)
		rec$=ope_ordship$
		gosub fill_dropship_address
		callpoint!.setColumnData("POE_POHDR.DS_NAME",rec.name$)
	endif
	if num(shipto_no$,err=*endif)>0 and num(shipto_no$,err=*endif)<99
		read record (arm_custship_dev,key=firm_id$+tmp_customer_id$+shipto_no$,dom=*next)arm_custship$
		dim rec$:fattr(arm_custship$)
		rec$=arm_custship$
		gosub fill_dropship_address
		callpoint!.setColumnData("POE_POHDR.DS_NAME",rec.name$)
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
	callpoint!.setColumnData("POE_POHDR.DS_NAME",rec.customer_name$)

return

fill_dropship_address:
	callpoint!.setColumnData("POE_POHDR.DS_ADDR_LINE_1",rec.addr_line_1$)
	callpoint!.setColumnData("POE_POHDR.DS_ADDR_LINE_2",rec.addr_line_2$)
	callpoint!.setColumnData("POE_POHDR.DS_ADDR_LINE_3",rec.addr_line_3$)
	callpoint!.setColumnData("POE_POHDR.DS_ADDR_LINE_4",rec.addr_line_4$)
	callpoint!.setColumnData("POE_POHDR.DS_CITY",rec.city$)
	callpoint!.setColumnData("POE_POHDR.DS_STATE_CD",rec.state_code$)
	callpoint!.setColumnData("POE_POHDR.DS_ZIP_CODE",rec.zip_code$)
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

	read (ope_orddet_dev,key=firm_id$+ope_ordhdr.ar_type$+ope_ordhdr.customer_id$+ope_ordhdr.order_no$,knum="AO_CUST_ORD_LINE",dom=*next)

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

callpoint!.setTableColumnAttribute("POE_POHDR.CUSTOMER_ID","MINL","0")	
callpoint!.setTableColumnAttribute("POE_POHDR.ORDER_NO","MINL","0")

return

enable_dropship_fields:
rem disables/enables dropship fields if detail has (or hasn't) been created for this requisition
rem since warehouse in hdr can't be changed once detail is posted, handling that control here, too.

if callpoint!.getDevObject("dtl_posted")="Y"
	callpoint!.setColumnEnabled("POE_POHDR.WAREHOUSE_ID",0)
	if callpoint!.getDevObject("OP_installed")="Y"
		callpoint!.setColumnEnabled("POE_POHDR.DROPSHIP",0)
		callpoint!.setColumnEnabled("POE_POHDR.CUSTOMER_ID",0)
		callpoint!.setColumnEnabled("POE_POHDR.ORDER_NO",0)			
	else
		callpoint!.setColumnEnabled("POE_POHDR.DROPSHIP",1)
		callpoint!.setColumnEnabled("POE_POHDR.CUSTOMER_ID",1)
		callpoint!.setColumnEnabled("POE_POHDR.ORDER_NO",0)		
	endif
else
	callpoint!.setColumnEnabled("POE_POHDR.WAREHOUSE_ID",1)
	if callpoint!.getColumnData("POE_POHDR.DROPSHIP")="Y"
		callpoint!.setColumnEnabled("POE_POHDR.DROPSHIP",1)
		callpoint!.setColumnEnabled("POE_POHDR.CUSTOMER_ID",1)
		callpoint!.setColumnEnabled("POE_POHDR.ORDER_NO",1)
	else
		callpoint!.setColumnEnabled("POE_POHDR.DROPSHIP",1)
		callpoint!.setColumnEnabled("POE_POHDR.CUSTOMER_ID",0)
		callpoint!.setColumnEnabled("POE_POHDR.ORDER_NO",0)
	endif
endif


callpoint!.setStatus("REFRESH")

return

queue_for_printing:

	poe_poprint_dev=fnget_dev("POE_POPRINT")
	dim poe_poprint$:fnget_tpl$("POE_POPRINT")

	poe_poprint.firm_id$=firm_id$
	poe_poprint.vendor_id$=callpoint!.getColumnData("POE_POHDR.VENDOR_ID")
	poe_poprint.po_no$=callpoint!.getColumnData("POE_POHDR.PO_NO")

	writerecord (poe_poprint_dev)poe_poprint$

return
