[[OPE_ORDHDR.ORDER_DATE.AVAL]]
rem --- Set user template info
	user_tpl.order_date$=callpoint!.getUserInput()
[[OPE_ORDHDR.PRICING_CODE.AVAL]]
rem --- Set user template info
	user_tpl.pricing_code$=callpoint!.getUserInput()
[[OPE_ORDHDR.PRICE_CODE.AVAL]]
rem --- Set user template info
	user_tpl.price_code$=callpoint!.getUserInput()
[[OPE_ORDHDR.SHIPTO_TYPE.BINP]]
rem --- Do we need to create a new order number?
	if cvs(callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO"),2)=""
		call stbl("+DIR_SYP")+"bas_sequences.bbj","ORDER_NO",seq_id$,rd_table_chans$[all]
		if len(seq_id$)=0 
			callpoint!.setStatus("ABORT")
			break
		else
			callpoint!.setColumnData("OPE_ORDHDR.ORDER_NO",seq_id$)
			callpoint!.setStatus("REFRESH")
		endif
	endif
[[OPE_ORDHDR.ADIS]]
cust$=callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
gosub disp_cust_comments

rem --- Disable Cost field if there is a value in it
g!=form!.getChildWindow(1109).getControl(5900)
enable_color!=g!.getCellBackColor(0,0)
disable_color!=g!.getLineColor()
numcols=g!.getNumColumns()

rem --- process_line_types

recVect!=GridVect!.getItem(0)
dim gridrec$:dtlg_param$[1,3]
numrecs=recVect!.size()
if numrecs>0
for reccnt=0 to numrecs-1
	gridrec$=recVect!.getItem(reccnt)

	if gridrec.unit_cost=0
		g!.setCellEditable(reccnt,5,1)
		g!.setCellBackColor(reccnt,5,enable_color!)
	else
		g!.setCellEditable(reccnt,5,0)
		g!.setCellBackColor(reccnt,5,disable_color!)
	endif
next reccnt
endif
[[OPE_ORDHDR.ASIZ]]
rem --- Create Empty Availability window
g!=form!.getChildWindow(1109).getControl(5900)
g!.setSize(g!.getWidth(),g!.getHeight()-75)
cwin!=form!.getChildWindow(1109).getControl(15000)
cwin!.setLocation(cwin!.getX(),g!.getY()+g!.getHeight())
cwin!.setSize(g!.getWidth(),cwin!.getHeight())
[[OPE_ORDHDR.AFMC]]
rem --- Create Inventory Availability window
g!=form!.getChildWindow(1109).getControl(5900)
userObj!=sysgui!.makeVector()
mwin!=form!.getChildWindow(1109).addChildWindow(15000,0,10,100,75,"",$00000800$,10)
mwin!.addGroupBox(15999,0,5,g!.getWidth()-5,65,"Inventory Availability",$$)
userObj!.addItem(g!) 
userObj!.addItem(mwin!)
mwin!.addStaticText(15001,15,25,75,15,"On Hand:",$$)
mwin!.addStaticText(15002,15,40,75,15,"Committed:",$$)
mwin!.addStaticText(15003,215,25,75,15,"Available:",$$)
mwin!.addStaticText(15004,215,40,75,15,"On Order:",$$)
mwin!.addStaticText(15005,415,25,75,15,"Warehouse:",$$)
mwin!.addStaticText(15006,415,40,75,15,"Type:",$$)
userObj!.addItem(mwin!.addStaticText(15101,90,25,75,15,"",$8000$))
userObj!.addItem(mwin!.addStaticText(15102,90,40,75,15,"",$8000$))
userObj!.addItem(mwin!.addStaticText(15103,295,25,75,15,"",$8000$))
userObj!.addItem(mwin!.addStaticText(15104,295,40,75,15,"",$8000$))
userObj!.addItem(mwin!.addStaticText(15105,490,25,75,15,"",$0000$))
userObj!.addItem(mwin!.addStaticText(15106,490,40,75,15,"",$0000$))
userObj!.addItem(mwin!.addStaticText(15107,695,25,75,15,"",$0000$));rem Drop Ship text
[[OPE_ORDHDR.BDEL]]
rem --- remove committments for detail records by calling ATAMO
	ope11_dev=fnget_dev("OPE_ORDDET")
	dim ope11a$:fnget_tpl$("OPE_ORDDET")
	opc_linecode_dev=fnget_dev("OPC_LINECODE")
	dim opc_linecode$:fnget_tpl$("OPC_LINECODE")
	ivs01_dev=fnget_dev("IVS_PARAMS")
	dim ivs01a$:fnget_tpl$("IVS_PARAMS")
	ope33_dev=fnget_dev("OPE_ORDSHIP")
	readrecord(ivs01_dev,key=firm_id$+"IV00")ivs01a$
	ar_type$=callpoint!.getColumnData("OPE_ORDHDR.AR_TYPE")
	cust$=callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
	ord$=callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")
	read(ope11_dev,key=firm_id$+ar_type$+cust$+ord$,dom=*next)
	while 1
		readrecord(ope11_dev,end=*break)ope11a$
		if pos(firm_id$+ar_type$+cust$+ord$=ope11a.firm_id$+ope11a.ar_type$+
:			ope11a.customer_id$+ope11a.order_no$)<>1 break
		readrecord(opc_linecode_dev,key=firm_id$+ope11a.line_code$)opc_linecode$
		if opc_linecode.dropship$<>"Y" and ope11a.commit_flag$="Y" and
:			callpoint!.getColumnData("OPE_ORDHDR.INVOICE_TYPE")<>"P"
			if pos(opc_linecode.line_type$="SP")
				wh_id$=ope11a.warehouse_id$
				item_id$=ope11a.item_id$
				ls_id$=""
				qty=ope11a.qty_ordered
				line_sign=-1
				gosub update_totals
			endif
		if pos(ivs01a.lotser_flag$="LS") 
			ord_seq$=ope11a.line_no$
			gosub remove_lot_ser_det
		endif
	wend
	remove(ope33_dev,key=firm_id$+cust$+ord$,dom=*next)
	cashrct_dev=fnget_dev("OPE_INVCASH")
	remove (cashrct_dev,key=firm_id$+
:		callpoint!.getColumnData("OPE_ORDHDR.AR_TYPE")+
:		callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")+
:		callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO"),err=*next)
	if user_tpl.credit_installed$="Y"
		ars_cred_dev=fnget_dev("OPE_CREDCUST")
		dim ars_credcust$:fnget_tpl$("OPE_CREDCUST")
		remove (ars_cred_dev,key=firm_id$+
:			callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")+
:			callpoint!.getColumnData("OPE_ORDHDR.ORDER_DATE")+
:		callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO"),err=*next)			
	endif
[[OPE_ORDHDR.AOPT-CINV]]
rem --- Credit Historical Invoice
	if cvs(callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID"),2)="" or
:	   cvs(callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO"),2)<>""
		msg_id$="OP_NO_HIST"
		gosub disp_message
	else
		key_pfx$=firm_id$+
:			callpoint!.getColumnData("OPE_ORDHDR.AR_TYPE")+
:			callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
			line_sign=-1
			gosub copy_order
		endif
	endif
[[OPE_ORDHDR.AOPT-DINV]]
rem --- Duplicate Historical Invoice
	if cvs(callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID"),2)="" or
:	   cvs(callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO"),2)<>""
		msg_id$="OP_NO_HIST"
		gosub disp_message
	else
		key_pfx$=firm_id$+
:			callpoint!.getColumnData("OPE_ORDHDR.AR_TYPE")+
:			callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
			line_sign=1
			gosub copy_order
		endif
	endif
[[OPE_ORDHDR.SHIPTO_NO.AVAL]]
rem --- Display Ship to information
	ship_to_type$=callpoint!.getColumnData("OPE_ORDHDR.SHIPTO_TYPE")
	ship_to_no$=callpoint!.getUserInput()
	cust_id$=callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
	ord_no$=callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")
	gosub ship_to_info
[[OPE_ORDHDR.ORDER_NO.AVAL]]
rem --- Do we need to create a new order number?
rem	if callpoint!.getUserInput()=""
rem		call stbl("+DIR_SYP")+"bas_sequences.bbj","ORDER_NO",seq_id$,rd_table_chans$[all]
rem		if len(seq_id$)=0 
rem			callpoint!.setStatus("ABORT")
rem			break
rem		else
rem			callpoint!.setColumnData("OPE_ORDHDR.ORDER_NO",seq_id$)
rem			callpoint!.setStatus("REFRESH")
rem		endif
rem	endif

rem --- set default values
	ope01_dev=fnget_dev("OPE_ORDHDR")
	ope01a$=fnget_tpl$("OPE_ORDHDR")
	dim ope01a$:ope01a$
	find record(ope01_dev,key=firm_id$+
:		callpoint!.getColumnData("OPE_ORDHDR.AR_TYPE")+
:		callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")+
:		callpoint!.getUserInput(),dom=*next)ope01a$;goto rec_exist
	user_tpl.new_rec$="Y"
rec_exist:
	if user_tpl.new_rec$<>"Y"
		gosub check_lock_flag
		if locked=1
			callpoint!.setStatus("ABORT")
		endif
		user_tpl.price_code$=ope01a.price_code$
		user_tpl.pricing_code$=ope01a.pricing_code$
		user_tpl.order_date$=ope01a.order_date$
	endif
rem --- new record
	if user_tpl.new_rec$="Y"
		callpoint!.setColumnData("OPE_ORDHDR.INVOICE_TYPE","S")
		arm02_dev=fnget_dev("ARM_CUSTDET")
		arm02a$=fnget_tpl$("ARM_CUSTDET")
		dim arm02a$:arm02a$
		read record (arm02_dev,key=firm_id$+
:			callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")+"  ",dom=*next)arm02a$
		arm01_dev=fnget_dev("ARM_CUSTMAST")
		arm01a$=fnget_tpl$("ARM_CUSTMAST")
		dim arm01a$:arm01a$
		read record (arm01_dev,key=firm_id$+
:			callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID"),dom=*next)arm01a$
		callpoint!.setColumnData("OPE_ORDHDR.SHIPMNT_DATE",user_tpl.def_ship$)
		callpoint!.setColumnData("OPE_ORDHDR.INVOICE_TYPE","S")
		callpoint!.setColumnData("OPE_ORDHDR.ORDINV_FLAG","O")
		callpoint!.setColumnData("OPE_ORDHDR.INVOICE_DATE",sysinfo.system_date$)
		callpoint!.setColumnData("OPE_ORDHDR.AR_SHIP_VIA",arm01a.ar_ship_via$)
		callpoint!.setColumnData("OPE_ORDHDR.SLSPSN_CODE",arm02a.slspsn_code$)
		callpoint!.setColumnData("OPE_ORDHDR.TERMS_CODE",arm02a.ar_terms_code$)
		callpoint!.setColumnData("OPE_ORDHDR.DISC_CODE",arm02a.disc_code$)
		callpoint!.setColumnData("OPE_ORDHDR.DIST_CODE",arm02a.ar_dist_code$)
		callpoint!.setColumnData("OPE_ORDHDR.PRINT_STATUS","N")
		callpoint!.setColumnData("OPE_ORDHDR.MESSAGE_CODE",arm02a.message_code$)
		callpoint!.setColumnData("OPE_ORDHDR.TERRITORY",arm02a.territory$)
		callpoint!.setColumnData("OPE_ORDHDR.ORDER_DATE",sysinfo.system_date$)
		callpoint!.setColumnData("OPE_ORDHDR.TAX_CODE",arm02a.tax_code$)
		callpoint!.setColumnData("OPE_ORDHDR.PRICING_CODE",arm02a.pricing_code$)
		callpoint!.setColumnData("OPE_ORDHDR.CASH_SALE","N")
		gosub get_op_params
		if callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")=ars01a.customer_id$
			callpoint!.setColumnData("OPE_ORDHDR.CASH_SALE","Y")
		endif
		callpoint!.setColumnData("OPE_ORDHDR.LOCK_STATUS","Y")
		user_tpl.price_code$=""
		user_tpl.pricing_code$=arm02a.pricing_code$
		user_tpl.order_date$=sysinfo.system_date$
	endif
	user_tpl.new_rec$="N"
[[OPE_ORDHDR.SHIPTO_TYPE.AVAL]]
rem -- Deal with which Ship To type
	callpoint!.setColumnData("<<DISPLAY>>.SNAME","")
	callpoint!.setColumnData("<<DISPLAY>>.SADD1","")
	callpoint!.setColumnData("<<DISPLAY>>.SADD2","")
	callpoint!.setColumnData("<<DISPLAY>>.SADD3","")
	callpoint!.setColumnData("<<DISPLAY>>.SADD4","")
	callpoint!.setColumnData("<<DISPLAY>>.SCITY","")
	callpoint!.setColumnData("<<DISPLAY>>.SSTATE","")
	callpoint!.setColumnData("<<DISPLAY>>.SZIP","")
	dim dctl$[10]
	ship_to_type$=callpoint!.getUserInput()
	ship_to_no$=callpoint!.getColumnData("OPE_ORDHDR.SHIPTO_NO")
	cust_id$=callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
	ord_no$=callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")
	gosub ship_to_info
	dctl$[1]="<<DISPLAY>>.SNAME"
	dctl$[2]="<<DISPLAY>>.SADD1"
	dctl$[3]="<<DISPLAY>>.SADD2"
	dctl$[4]="<<DISPLAY>>.SADD3"
	dctl$[5]="<<DISPLAY>>.SADD4"
	dctl$[6]="<<DISPLAY>>.SCITY"
	dctl$[7]="<<DISPLAY>>.SSTATE"
	dctl$[8]="<<DISPLAY>>.SZIP"
	if ship_to_type$="M"
		dmap$=""
	else
		dmap$="I"
	endif
	gosub disable_ctls
[[OPE_ORDHDR.ASHO]]
rem --- get default dates
	call stbl("+DIR_SYP")+"bam_run_prog.bbj","OPE_ORDDATES",stbl("+USER_ID"),"MNT","",table_chans$[all]
	user_tpl.def_ship$=stbl("OPE_DEF_SHIP")
	user_tpl.def_commit$=stbl("OPE_DEF_COMMIT")
[[OPE_ORDHDR.INVOICE_TYPE.AVAL]]
rem --- enable/disable expire date based on value
	dim dctl$[10]
	dctl$[1]="OPE_ORDHDR.EXPIRE_DATE"
	if callpoint!.getUserInput()<>"P"
		dmap$="I"
	else
		dmap$=""
	endif
	gosub disable_ctls
	if rec_data.invoice_type$="S"
		if callpoint!.getUserInput()="P"
			msg_id$="OP_NO_CONVERT"
			gosub  disp_message
			callpoint!.setStatus("ABORT-REFRESH")
		endif
	else
		if rec_data.invoice_type$="P"
			if callpoint!.getUserInput()="S"
				msg_id$="CONVERT_QUOTE"
				gosub disp_message
				if msg_opt$="Y"
					callpoint!.setColumnData("OPE_ORDHDR.PRINT_STATUS","N")
					ope11_dev=fnget_dev("OPE_ORDDET")
					dim ope11a$:fnget_tpl$("OPE_ORDDET")
					ivs01_dev=fnget_dev("IVS_PARAMS")
					dim ivs01a$:fnget_tpl$("IVS_PARAMS")
					opc_linecode_dev=fnget_dev("OPC_LINECODE")
					dim opc_linecode$:fnget_tpl$("OPC_LINECODE")
					read record(ivs01_dev,key=firm_id$+"IV00")ivs01a$
					precision num(ivs01a.precision$)
					ar_type$=callpoint!.getColumnData("OPE_ORDHDR.AR_TYPE")
					cust$=callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
					ord$=callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")
					read record (ope11_dev,key=firm_id$+ar_type$+cust$+ord$,dom=*next)
					while 1
						readrecord (ope11_dev,end=*break)ope11a$
						if pos(firm_id$+ar_type$+cust$+ord$=ope11a.firm_id$+
:							ope11a.ar_type$+ope11a.customer_id$+ope11a.order_no$)<>1 break
						readrecord (opc_linecode_dev,key=firm_id$+ope11a.line_code$,dom=*continue)opc_linecode$
						ope11a.commit_flag$="Y"
						ope11a.pick_flag$="N"
						if ope11a.est_shp_date$>user_tpl.def_commit$ ope11a.commit_flag$="N"
						if ope11a.commit_flag$="N" 
							if opc_linecode.line_type$<>"O" 
								ope11a.qty_backord=0
								ope11a.qty_shipped=0
								ope11a.ext_price=0
								ope11a.taxable_amt=0
							else 
								if ope11a.ext_price<>0
									ope11a.unit_price=ope11a.ext_price
									ope11a.ext_price=0
									ope11a.taxable_amt=0
								endif
							endif
						endif
						if pos(opc_linecode.line_type$="SP")>0 and opc_linecode.dropship$<>"N" and
:							ope11a.commit_flag$<>"N"
							wh_id$=ope11a.warehouse_id$
							item_id$=ope11a.item_id$
							ls_id$=""
							qty=ope11a.qty_ordered
							line_sign=1
							gosub update_totals
						endif
						ope11a$=field(ope11a$)
						writerecord (ope11_dev)ope11a$
					wend
					precision 2
					rec_data.invoice_type$="S"
				endif
			endif
		endif
	endif
[[OPE_ORDHDR.AREC]]
rem --- reset expiration date to enabled
	callpoint!.setColumnData("<<DISPLAY>>.ORDER_TOT","")
	callpoint!.setColumnData("OPE_ORDHDR.ORD_TAKEN_BY",sysinfo.user_id$)
	dim dctl$[10]
	dctl$[1]="OPE_ORDHDR.EXPIRE_DATE"
	dmap$=""
	gosub disable_ctls

rem --- Clear Pricing data from user template
	user_tpl.price_code$=""
	user_tpl.pricing_code$=""
	user_tpl.order_date$=""

rem --- Clear Availability Window
	userObj!.getItem(num(user_tpl.avail_oh$)).setText("")
	userObj!.getItem(num(user_tpl.avail_comm$)).setText("")
	userObj!.getItem(num(user_tpl.avail_avail$)).setText("")
	userObj!.getItem(num(user_tpl.avail_oo$)).setText("")
	userObj!.getItem(num(user_tpl.avail_wh$)).setText("")
	userObj!.getItem(num(user_tpl.avail_type$)).setText("")
	userObj!.getItem(num(user_tpl.dropship_flag$)).setText("")
[[OPE_ORDHDR.CUSTOMER_ID.AINP]]
rem --- If cash customer, get correct customer number
	gosub get_op_params
	if ars01a.cash_sale$="Y" and cvs(callpoint!.getUserInput(),1+2+4)="C" 
		callpoint!.setColumnData("OPE_ORDHDR.CUSTOMER_ID",ars01a.customer_id$)
		callpoint!.setColumnData("OPE_ORDHDR.CASH_SALE","Y")
		callpoint!.setStatus("REFRESH")
	endif
[[OPE_ORDHDR.CUSTOMER_ID.AVAL]]
rem --- Show customer data
	cust_id$=callpoint!.getUserInput()
	gosub bill_to_info
	cust$=callpoint!.getUserInput()
	gosub disp_cust_comments
[[OPE_ORDHDR.AWRI]]
rem --- Write/Remove manual ship to file
	cust_id$=callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")
	ord_no$=callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO")
	ordship_dev=fnget_dev("OPE_ORDSHIP")
	
	if callpoint!.getColumnData("OPE_ORDHDR.SHIPTO_TYPE")<>"M"
		remove (ordship_dev,key=firm_id$+cust_id$+ord_no$,dom=*next)
	else
		ordship_tpl$=fnget_tpl$("OPE_ORDSHIP")
		dim ordship_tpl$:ordship_tpl$
		read record (ordship_dev,key=firm_id$+cust_id$+ord_no$,dom=*next) ordship_tpl$
		ordship_tpl.firm_id$=firm_id$
		ordship_tpl.customer_id$=cust_id$
		ordship_tpl.order_no$=ord_no$
		ordship_tpl.name$=callpoint!.getColumnData("<<DISPLAY>>.SNAME")
		ordship_tpl.addr_line_1$=callpoint!.getColumnData("<<DISPLAY>>.SADD1")
		ordship_tpl.addr_line_2$=callpoint!.getColumnData("<<DISPLAY>>.SADD2")
		ordship_tpl.addr_line_3$=callpoint!.getColumnData("<<DISPLAY>>.SADD3")
		ordship_tpl.addr_line_4$=callpoint!.getColumnData("<<DISPLAY>>.SADD4")
		ordship_tpl.city$=callpoint!.getColumnData("<<DISPLAY>>.SCITY")
		ordship_tpl.state_code$=callpoint!.getColumnData("<<DISPLAY>>.SSTATE")
		ordship_tpl.zip_code$=callpoint!.getColumnData("<<DISPLAY>>.SZIP")
		write record (ordship_dev,key=firm_id$+cust_id$+ord_no$) ordship_tpl$
	endif
[[OPE_ORDHDR.<CUSTOM>]]
bill_to_info: rem --- get and display Bill To Information
	custmast_dev=fnget_dev("ARM_CUSTMAST")
	custmast_tpl$=fnget_tpl$("ARM_CUSTMAST")
	dim custmast_tpl$:custmast_tpl$
	read record (custmast_dev,key=firm_id$+cust_id$,dom=*next) custmast_tpl$
	callpoint!.setColumnData("<<DISPLAY>>.BADD1",custmast_tpl.addr_line_1$)
	callpoint!.setColumnData("<<DISPLAY>>.BADD2",custmast_tpl.addr_line_2$)
	callpoint!.setColumnData("<<DISPLAY>>.BADD3",custmast_tpl.addr_line_3$)
	callpoint!.setColumnData("<<DISPLAY>>.BADD4",custmast_tpl.addr_line_4$)
	callpoint!.setColumnData("<<DISPLAY>>.BCITY",custmast_tpl.city$)
	callpoint!.setColumnData("<<DISPLAY>>.BSTATE",custmast_tpl.state_code$)
	callpoint!.setColumnData("<<DISPLAY>>.BZIP",custmast_tpl.zip_code$)
	custdet_dev=fnget_dev("ARM_CUSTDET")
	custdet_tpl$=fnget_tpl$("ARM_CUSTDET")
	dim custdet_tpl$:custdet_tpl$
	read record(custdet_dev,key=firm_id$+cust_id$+"  ",dom=*next) custdet_tpl$
	ar_balance=custdet_tpl.aging_future+
:		custdet_tpl.aging_cur+
:		custdet_tpl.aging_30+
:		custdet_tpl.aging_60+
:		custdet_tpl.aging_90+
:		custdet_tpl.aging_120
	if user_tpl.credit_installed$="Y" and user_tpl.display_bal$="A"
		callpoint!.setColumnData("<<DISPLAY>>.AGING_120",custdet_tpl.aging_120$)
		callpoint!.setColumnData("<<DISPLAY>>.AGING_30",custdet_tpl.aging_30$)
		callpoint!.setColumnData("<<DISPLAY>>.AGING_60",custdet_tpl.aging_60$)
		callpoint!.setColumnData("<<DISPLAY>>.AGING_90",custdet_tpl.aging_90$)
		callpoint!.setColumnData("<<DISPLAY>>.AGING_CUR",custdet_tpl.aging_cur$)
		callpoint!.setColumnData("<<DISPLAY>>.AGING_FUTURE",custdet_tpl.aging_future$)
		callpoint!.setColumnData("<<DISPLAY>>.TOT_AGING",str(ar_balance))
	else
		callpoint!.setColumnData("<<DISPLAY>>.AGING_120","")
		callpoint!.setColumnData("<<DISPLAY>>.AGING_30","")
		callpoint!.setColumnData("<<DISPLAY>>.AGING_60","")
		callpoint!.setColumnData("<<DISPLAY>>.AGING_90","")
		callpoint!.setColumnData("<<DISPLAY>>.AGING_CUR","")
		callpoint!.setColumnData("<<DISPLAY>>.AGING_FUTURE","")
		callpoint!.setColumnData("<<DISPLAY>>.TOT_AGING","")
	endif
	callpoint!.setStatus("REFRESH")
return

ship_to_info: rem --- get and display Bill To Information
	ordship_dev=fnget_dev("OPE_ORDSHIP")
	if ship_to_type$<>"M"
		if ship_to_type$="S"
			custship_dev=fnget_dev("ARM_CUSTSHIP")
			custship_tpl$=fnget_tpl$("ARM_CUSTSHIP")
			dim custship_tpl$:custship_tpl$
			read record (custship_dev,key=firm_id$+cust_id$+ship_to_no$,dom=*next) custship_tpl$
			callpoint!.setColumnData("<<DISPLAY>>.SNAME",custship_tpl.name$)
			callpoint!.setColumnData("<<DISPLAY>>.SADD1",custship_tpl.addr_line_1$)
			callpoint!.setColumnData("<<DISPLAY>>.SADD2",custship_tpl.addr_line_2$)
			callpoint!.setColumnData("<<DISPLAY>>.SADD3",custship_tpl.addr_line_3$)
			callpoint!.setColumnData("<<DISPLAY>>.SADD4",custship_tpl.addr_line_4$)
			callpoint!.setColumnData("<<DISPLAY>>.SCITY",custship_tpl.city$)
			callpoint!.setColumnData("<<DISPLAY>>.SSTATE",custship_tpl.state_code$)
			callpoint!.setColumnData("<<DISPLAY>>.SZIP",custship_tpl.zip_code$)
		else
			callpoint!.setColumnData("<<DISPLAY>>.SNAME","Same")
			callpoint!.setColumnData("<<DISPLAY>>.SADD1","")
			callpoint!.setColumnData("<<DISPLAY>>.SADD2","")
			callpoint!.setColumnData("<<DISPLAY>>.SADD3","")
			callpoint!.setColumnData("<<DISPLAY>>.SADD4","")
			callpoint!.setColumnData("<<DISPLAY>>.SCITY","")
			callpoint!.setColumnData("<<DISPLAY>>.SSTATE","")
			callpoint!.setColumnData("<<DISPLAY>>.SZIP","")
		endif
	else
		ordship_tpl$=fnget_tpl$("OPE_ORDSHIP")
		dim ordship_tpl$:ordship_tpl$
		read record (ordship_dev,key=firm_id$+cust_id$+ord_no$,dom=*next) ordship_tpl$
		callpoint!.setColumnData("<<DISPLAY>>.SNAME",ordship_tpl.name$)
		callpoint!.setColumnData("<<DISPLAY>>.SADD1",ordship_tpl.addr_line_1$)
		callpoint!.setColumnData("<<DISPLAY>>.SADD2",ordship_tpl.addr_line_2$)
		callpoint!.setColumnData("<<DISPLAY>>.SADD3",ordship_tpl.addr_line_3$)
		callpoint!.setColumnData("<<DISPLAY>>.SADD4",ordship_tpl.addr_line_4$)
		callpoint!.setColumnData("<<DISPLAY>>.SCITY",ordship_tpl.city$)
		callpoint!.setColumnData("<<DISPLAY>>.SSTATE",ordship_tpl.state_code$)
		callpoint!.setColumnData("<<DISPLAY>>.SZIP",ordship_tpl.zip_code$)
	endif
	callpoint!.setStatus("REFRESH")
return

disable_ctls: rem --- disable selected control
for dctl=1 to 10
	dctl$=dctl$[dctl]
	if cvs(dctl$,2)<>""
		wctl$=str(num(callpoint!.getTableColumnAttribute(dctl$,"CTLI")):"00000")
		wmap$=callpoint!.getAbleMap()
		wpos=pos(wctl$=wmap$,8)
		wmap$(wpos+6,1)=dmap$
		callpoint!.setAbleMap(wmap$)
		callpoint!.setStatus("ABLEMAP-REFRESH")
	endif
next dctl
return

get_op_params:
	ars01_dev=fnget_dev("ARS_PARAMS")
	ars01a$=fnget_tpl$("ARS_PARAMS")
	dim ars01a$:ars01a$
	read record (ars01_dev,key=firm_id$+"AR00") ars01a$
return

disp_ord_tot:
	user_tpl.ord_tot=0
	ope11_dev=fnget_dev("OPE_ORDDET")
	dim ope11a$:fnget_tpl$("OPE_ORDDET")
	opc_linecode_dev=fnget_dev("OPC_LINECODE")
	dim opc_linecode$:fnget_tpl$("OPC_LINECODE")
	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")
	read record(ope11_dev,key=firm_id$+callpoint!.getColumnData("OPE_ORDHDR.AR_TYPE")+
:		callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")+
:		callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO"),dom=*next)
	while 1
		read record(ope11_dev,end=*break)ope11a$
		if ope11a.firm_id$+ope11a.ar_type$+ope11a.customer_id$+ope11a.order_no$<>
:			firm_id$+callpoint!.getColumnData("OPE_ORDHDR.AR_TYPE")+
:			callpoint!.getColumnData("OPE_ORDHDR.CUSTOMER_ID")+
:			callpoint!.getColumnData("OPE_ORDHDR.ORDER_NO") break
		dim opc_linecode$:fattr(opc_linecode$)
		read record(opc_linecode_dev,key=firm_id$+ope11a.line_code$,dom=*next)opc_linecode$
		if pos(opc_linecode.line_type$="SNP")
			user_tpl.ord_tot=user_tpl.ord_tot+(ope11a.unit_price*ope11a.qty_ordered)
		endif
		if opc_linecode.line_type$="O"
			user_tpl.ord_tot=user_tpl.ord_tot+ope11a.ext_price
		endif
		dim ivm01a$:fattr(ivm01a$)
		read record(ivm01_dev,key=firm_id$+ope11a.item_id$,dom=*next)ivm01a$;
:			if ivm01a.taxable_flag$="Y" and opc_linecode.taxable_flag$="Y" ope11a.taxable_amt=ope11a.ext_price
rem		U[0]=U[0]+ope11a.ext_price
rem		U[1]=U[1]+ope11a.taxable_amt
rem		U[2]=U[2]+ope11a.unit_cost*ope11a.qty_shipped
	wend
	callpoint!.setColumnData("<<DISPLAY>>.ORDER_TOT",str(user_tpl.ord_tot))
return

check_lock_flag:
	locked=0
	on pos(callpoint!.getColumnData("OPE_ORDHDR.LOCK_STATUS")="NYS12") goto 
:		end_lock,end_lock,locked,on_invoice,update_stat,update_stat
locked:
	msg_id$="ORD_LOCKED"
	dim msg_tokens$[1]
	if callpoint!.getColumnData("OPE_ORDHDR.PRINT_STATUS")="B" 
		msg_tokens$[1]=" by Batch Print."
		gosub disp_message
		if msg_opt$="Y"
			callpoint!.setColumnData("OPE_ORDHDR.LOCK_STATUS","N")
			goto end_lock
		else
			locked=1
			goto end_lock
		endif
	else
		goto end_lock
	endif
on_invoice:
	msg_id$="ORD_ON_REG"
	gosub disp_message
	locked=1
	goto end_lock
update_stat:
	msg_id$="INVOICE_IN_UPDATE"
	gosub disp_message
	locked=1
end_lock:
	return

copy_order: rem --- Duplicate or Credit Historical Invoice
	copy_ok$="Y"
	while 1
		rd_key$=""
		call stbl("+DIR_SYP")+"bam_inquiry.bbj",
:			gui_dev,
:			Form!,
:			"OPT_ORDHDR",
:			"LOOKUP",
:			table_chans$[all],
:			key_pfx$,
:			"PRIMARY",
:			rd_key$
		if cvs(rd_key$,2)<>""
			key_pfx_det$=rd_key$
			call stbl("+DIR_SYP")+"bam_inquiry.bbj",
:				gui_dev,
:				Form!,
:				"OPT_ORDDET",
:				"LOOKUP",
:				table_chans$[all],
:				key_pfx_det$,
:				"PRIMARY",
:				rd_key_det$
			if cvs(rd_key_det$,2)<>""
				opt01a$=fnget_tpl$("OPT_ORDHDR")
				opt01_dev=fnget_dev("OPT_ORDHDR")
				dim opt01a$:opt01a$
				readrecord(opt01_dev,key=rd_key$)opt01a$
				break
			endif
		else
			copy_ok$="N"
			break
		endif
	wend
	reprice$="N"
	if copy_ok$="Y"
		if line_sign=1
			msg_id$="OP_REPRICE_ORD"
			gosub disp_message
			reprice$=msg_opt$
		endif
	endif
	if copy_ok$="Y"
		call stbl("+DIR_SYP")+"bas_sequences.bbj","ORDER_NO",seq_id$,rd_table_chans$[all]
		if len(seq_id$)>0
			ope01_dev=fnget_dev("OPE_ORDHDR")
			dim ope01a$:fnget_tpl$("OPE_ORDHDR")
			call stbl("+DIR_PGM")+"adc_copyfile.aon",opt01a$,ope01a$,status
			ope01a.ar_inv_no$=""
			ope01a.backord_flag$=""
			ope01a.comm_amt=ope01a.comm_amt*line_sign
			ope01a.customer_po_no$=""
			ope01a.discount_amt=ope01a.discount_amt*line_sign
			ope01a.expire_date$=""
			ope01a.freight_amt=ope01a.freight_amt*line_sign
			ope01a.invoice_date$=user_tpl.def_ship$
			ope01a.invoice_type$="S"
			ope01a.order_date$=sysinfo.system_date$
			ope01a.order_no$=seq_id$
			ope01a.ordinv_flag$="O"
			ope01a.ord_taken_by$=sysinfo.user_id$
			ope01a.print_status$="N"
			ope01a.reprint_flag$=""
			ope01a.shipmnt_date$=user_tpl.def_ship$
			ope01a.taxable_amt=ope01a.taxable_amt*line_sign
			ope01a.tax_amount=ope01a.tax_amount*line_sign
			ope01a.total_cost=ope01a.total_cost*line_sign
			ope01a.total_sales=ope01a.total_sales*line_sign
			writerecord(ope01_dev)ope01a$
			user_tpl.price_code$=ope01a.price_code$
			user_tpl.pricing_code$=ope01a.pricing_code$
			user_tpl.order_date$=ope01a.order_date$
rem --- copy Manual Ship To if any
			if opt01a.shipto_type$="M"
				dim ope31a$:fnget_tpl$("OPE_ORDSHIP")
				ope31_dev=fnget_dev("OPE_ORDSHIP")
				dim opt31a$:fnget_tpl$("OPT_INVSHIP")
				opt31_dev=fnget_dev("OPT_INVSHIP")
				readrecord(opt31_dev,key=firm_id$+opt01a.customer_id$+opt01a.ar_inv_no$,dom=*next)opt31a$
				call stbl("+DIR_PGM")+"adc_copyfile.aon",opt31a$,ope31a$,status
				ope31a.order_no$=ope01a.order_no$
				writerecord(ope31_dev)ope31a$
			endif
rem --- copy detail lines
			dim opt11a$:fnget_tpl$("OPT_ORDDET")
			opt11_dev=fnget_dev("OPT_ORDDET")
			dim ope11a$:fnget_tpl$("OPE_ORDDET")
			ope11_dev=fnget_dev("OPE_ORDDET")
			ivm01_dev=fnget_dev("IVM_ITEMMAST")
			dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")
			read(opt11_dev,key=firm_id$+opt01a.ar_type$+opt01a.customer_id$+opt01a.ar_inv_no$,dom=*next)
			opc_linecode_dev=fnget_dev("OPC_LINECODE")
			dim opc_linecode$:fnget_tpl$("OPC_LINECODE")
			while 1
				read record(opt11_dev,end=*break) opt11a$
				if firm_id$+opt01a.ar_type$+opt01a.customer_id$+opt01a.ar_inv_no$<>
:					opt11a.firm_id$+opt11a.ar_type$+opt11a.customer_id$+opt11a.ar_inv_no$ break
				call stbl("+DIR_PGM")+"adc_copyfile.aon",opt11a$,ope11a$,status
				if cvs(opt11a.line_code$,2)<>""
					read record (opc_linecode_dev,key=firm_id$+opt11a.line_code$,dom=*next)opc_linecode$
				endif
				if pos(opc_linecode.line_type$="SP") and reprice$="Y"
					gosub pricing
				endif
				if opc_linecode.line_type$<>"M"
					if opc_linecode.line_type$="O" and ope11a.commit_flag$="N"
						ope11a.ext_price=ope11a.unit_price
						ope11a.unit_price=0			
					endif
					if line_sign<0
						ope11a.qty_ordered=-ope11a.qty_shipped
						ope11a.ext_price=-ope11a.ext_price
					endif
					if opc_linecode.line_type$<>"O"
						ope11a.qty_shipped=ope11a.qty_ordered
						ope11a.qty_backord=0
						ope11a.taxable_amt=0
						ope11a.ext_price=round(ope11a.unit_price*ope11a.qty_shipped,2)
					endif
					if pos(opc_linecode.line_type$="SP")=0
						if opc_linecode.taxable_flag$="Y"
							ope11a.taxable_amt=ope11a.ext_price
						endif
					else
						read record (ivm01_dev,key=firm_id$+ope11a.item_id$,dom=*next)ivm01a$
						if opc_linecode.taxable_flag$="Y" and ivm01a.taxable_flag$="Y"
							ope11a.taxable_amt=ope11a.ext_price
						endif
					endif
				endif
				ope11a.order_no$=ope01a.order_no$
				ope11a.est_shp_date$=ope01a.shipmnt_date$
				ope11a.commit_flag$="Y"
				ope11a.pick_flag$="N"
				if ope11a.est_shp_date$>user_tpl.def_commit$
					ope11a.commit_flag$="N"
				endif
				if user_tpl.blank_whse$="N" and cvs(ope11a.warehouse_id$,2)="" 
:					and opc_linecode.dropship$="Y" and user_tpl.dropship_whse$="N"
					ope11a.warehouse_id$=user_tpl.def_whse$
				endif
				writerecord(ope11_dev)ope11a$
			wend
			callpoint!.setStatus("RECORD:"+firm_id$+ope01a.ar_type$+ope01a.customer_id$+ope01a.order_no$)
		endif
	endif
	return

update_totals: rem --- Update Order/Invoice Totals & Commit Inventory
rem --- need to send in wh_id$, item_id$, ls_id$, and qty
rem	dim iv_files[44],iv_info$[3],iv_params$[4],iv_refs$[11],iv_refs[5]
	call "ivc_itemupdt.aon::init",iv_files[all],ivs01a$,iv_info$[all],iv_refs$[all],iv_refs[all],table_chans$[all],status
rem	iv_files[0]=fnget_dev("GLS_PARAMS")
rem	iv_files[1]=fnget_dev("IVM_ITEMMAST")
rem	iv_files[2]=fnget_dev("IVM_ITEMWHSE")
rem	iv_files[4]=fnget_dev("IVM_ITEMTIER")
rem	iv_files[5]=fnget_dev("IVM_ITEMVEND")
rem	iv_files[7]=fnget_dev("IVM_LSMASTER")
rem	iv_files[12]=fnget_dev("IVM_ITEMACCT")
rem	iv_files[17]=fnget_dev("IVM_LSACT")
rem	iv_files[41]=fnget_dev("IVT_LSTRANS")
rem	iv_files[42]=fnget_dev("IVX_LSCUST")
rem	iv_files[43]=fnget_dev("IVX_LSVEND")
rem	iv_files[44]=fnget_dev("IVT_ITEMTRAN")
rem	ivs01_dev=fnget_dev("IVS_PARAMS")
rem	dim ivs01a$:fnget_tpl$("IVS_PARAMS")
rem	readrecord(ivs01_dev,key=firm_id$+"IV00")ivs01a$
	iv_info$[1]=wh_id$
	iv_info$[2]=item_id$
	iv_info$[3]=ls_id$
	iv_refs[0]=qty
	while 1
rem	jpb need to figure this one out"	if pos(S8$(2,1)="SP")=0 break
rem	jpb need to figure this one out"	if s8$(3,1)="Y" or a0$(21,1)="P" break; REM "Drop ship or quote
		if line_sign>0 iv_action$="OE" else iv_action$="UC"
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon",iv_action$,iv_files[all],ivs01a$,
:			iv_info$[all],iv_refs$[all],iv_refs[all],table_chans$[all],iv_status
		break
	wend
return

remove_lot_ser_det: rem " --- Remove Lot/Serial Detail"
	ope21_dev=fnget_dev("OPE_ORDLSDET")
	dim ope21a$:fnget_tpl$("OPE_ORDLSDET")
	read (ope21_dev,key=firm_id$+ar_type$+cust$+ord$+ord_seq$,dom=*next)
	while 1
		readrecord(ope21_dev,end=*break)ope21a$
		if pos(firm_id$+ar_type$+cust$+ord$+ord_seq$=ope21a.firm_id$+ope21a.ar_type$+ope21a.customer_id$+ope21a.order_no$+ope21a.line_no$)<>1 break
		if opc_linecode.dropship$<>"Y" and
:			callpoint!.getColumnData("OPE_ORDHDR.INVOICE_TYPE")<>"P"
			wh_id$=ope11a.warehouse_id$
			item_id$=ope11a.item_id$
			ls_id$=""
			qty=ope21a.qty_ordered
			line_sign=1
			gosub update_totals
			ls_id$=ope21a.lotser_no$
			line_sign=-1
			gosub update_totals
		endif
		remove (ope21_dev,key=firm_id$+ar_type$+cust$+ord$+ord_seq$+ope21a.sequence_no$)
	wend
	return

pricing: rem "Call Pricing routine
        ope01_dev=fnget_dev("OPE_ORDHDR")
	dim ope01a$:fnget_tpl$("OPE_ORDHDR")
	ivm02_dev=fnget_dev("IVM_ITEMWHSE")
	dim ivm02a$:fnget_tpl$("IVM_ITEMWHSE")
	ivs01_dev=fnget_dev("IVS_PARAMS")
	dim ivs01a$:fnget_tpl$("IVS_PARAMS")
	ordqty=ope11a.qty_ordered
	wh$=ope11a.warehouse_id$
	item$=ope11a.item_id$
	ar_type$=ope11a.ar_type$
	cust$=ope11a.customer_id$
	ord$=seq_id$
	readrecord(ope01_dev,key=firm_id$+ar_type$+cust$+ord$)ope01a$
	dim pc_files[6]
	pc_files[1]=fnget_dev("IVM_ITEMMAST")
	pc_files[2]=ivm02_dev
	pc_files[3]=fnget_dev("IVM_ITEMPRIC")
	pc_files[4]=fnget_dev("IVC_PRICCODE")
	pc_files[5]=fnget_dev("ARS_PARAMS")
	pc_files[6]=ivs01_dev
	call stbl("+DIR_PGM")+"opc_pc.aon",pc_files[all],firm_id$,wh$,item$,user_tpl.price_code$,cust$,
:		user_tpl.order_date$,user_tpl.pricing_code$,ordqty,typeflag$,price,disc,status
	if price=0
		msg_id$="ENTER_PRICE"
		gosub disp_message
	else
		ope11a.unit_price=price
		ope11a.disc_percent=disc
	endif
	if disc=100
		readrecord(ivm02_dev,key=firm_id$+wh$+item$)ivm02a$
		ope11a.std_list_prc=ivm02a.cur_price
	else
		readrecord(ivs01_dev,key=firm_id$+"IV00")ivs01a$
		precision  num(ivs01a.precision$)+3
		factor=100/(100-disc)
		precision num(ivs01a.precision$)
		ope11a.std_list_prc=price*factor
return

disp_cust_comments:
	cmt_text$=""
	arm05_dev=fnget_dev("ARM_CUSTCMTS")
	dim arm05a$:fnget_tpl$("ARM_CUSTCMTS")
	arm05_key$=firm_id$+cust$
	more=1
	read(arm05_dev,key=arm05_key$,dom=*next)
	while more
		readrecord(arm05_dev,end=*break)arm05a$
		if arm05a.firm_id$+arm05a.customer_id$<>firm_id$+cust$ break
			cmt_text$=cmt_text$+cvs(arm05a.std_comments$,3)+$0A$
		endif				
	wend
	callpoint!.setColumnData("<<DISPLAY>>.comments",cmt_text$)
	callpoint!.setStatus("REFRESH")
return
[[OPE_ORDHDR.ARAR]]
rem --- display order total
	gosub disp_ord_tot
rem --- Populate address fields
	cust_id$=rec_data.customer_id$
	gosub bill_to_info
	ship_to_type$=rec_data.shipto_type$
	ship_to_no$=rec_data.shipto_no$
	ord_no$=rec_data.order_no$
	user_tpl.price_code$=rec_data.price_code$
	user_tpl.pricing_code$=rec_data.pricing_code$
	user_tpl.order_date$=rec_data.order_date$
	gosub ship_to_info
	dim dctl$[10]
	dctl$[1]="<<DISPLAY>>.SNAME"
	dctl$[2]="<<DISPLAY>>.SADD1"
	dctl$[3]="<<DISPLAY>>.SADD2"
	dctl$[4]="<<DISPLAY>>.SADD3"
	dctl$[5]="<<DISPLAY>>.SADD4"
	dctl$[6]="<<DISPLAY>>.SCITY"
	dctl$[7]="<<DISPLAY>>.SSTATE"
	dctl$[8]="<<DISPLAY>>.SZIP"
	if rec_data.shipto_type$="M"
		dmap$=""
	else
		dmap$="I"
	endif
	gosub disable_ctls
	dim dctl$[10]
	dctl$[1]="OPE_ORDHDR.EXPIRE_DATE"
	if rec_data.invoice_type$<>"P"
		dmap$="I"
	else
		dmap$=""
	endif
	gosub disable_ctls
rem --- Clear Availability Window
	userObj!.getItem(num(user_tpl.avail_oh$)).setText("")
	userObj!.getItem(num(user_tpl.avail_comm$)).setText("")
	userObj!.getItem(num(user_tpl.avail_avail$)).setText("")
	userObj!.getItem(num(user_tpl.avail_oo$)).setText("")
	userObj!.getItem(num(user_tpl.avail_wh$)).setText("")
	userObj!.getItem(num(user_tpl.avail_type$)).setText("")
	userObj!.getItem(num(user_tpl.dropship_flag$)).setText("")
[[OPE_ORDHDR.BSHO]]
rem --- open needed files
	num_files=33
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARM_CUSTMAST",open_opts$[1]="OTA"
	open_tables$[2]="ARM_CUSTSHIP",open_opts$[2]="OTA"
	open_tables$[3]="OPE_ORDSHIP",open_opts$[3]="OTA"
	open_tables$[4]="ARS_PARAMS",open_opts$[4]="OTA"
	open_tables$[5]="ARM_CUSTDET",open_opts$[5]="OTA"
	open_tables$[6]="OPE_INVCASH",open_opts$[6]="OTA"
	open_tables$[7]="ARS_CREDIT",open_opts$[7]="OTA"
	open_tables$[8]="OPC_LINECODE",open_opts$[8]="OTA"
	open_tables$[9]="GLS_PARAMS",open_opts$[9]="OTA"
	open_tables$[10]="GLS_PARAMS",open_opts$[10]="OTA"
	open_tables$[11]="IVM_LSMASTER",open_opts$[11]="OTA"
	open_tables$[12]="IVX_LSCUST",open_opts$[12]="OTA"
	open_tables$[13]="IVM_ITEMMAST",open_opts$[13]="OTA"
	open_tables$[15]="IVX_LSVEND",open_opts$[15]="OTA"
	open_tables$[16]="IVM_ITEMWHSE",open_opts$[16]="OTA"
	open_tables$[17]="IVM_ITEMACT",open_opts$[17]="OTA"
	open_tables$[18]="IVT_ITEMTRAN",open_opts$[18]="OTA"
	open_tables$[19]="IVM_ITEMTIER",open_opts$[19]="OTA"
	open_tables$[20]="IVM_ITEMACT",open_opts$[20]="OTA"
	open_tables$[21]="IVM_ITEMVEND",open_opts$[21]="OTA"
	open_tables$[22]="IVT_LSTRANS",open_opts$[22]="OTA"
	open_tables$[23]="OPT_ORDHDR",open_opts$[23]="OTA"
	open_tables$[24]="OPT_ORDDET",open_opts$[24]="OTA"
	open_tables$[25]="OPE_ORDDET",open_opts$[25]="OTA"
	open_tables$[26]="OPT_INVSHIP",open_opts$[26]="OTA"
	open_tables$[27]="OPE_CREDCUST",open_opts$[27]="OTA"
	open_tables$[28]="IVC_WHSECODE",open_opts$[28]="OTA"
	open_tables$[29]="IVS_PARAMS",open_opts$[29]="OTA"
	open_tables$[30]="OPE_ORDLSDET",open_opts$[30]="OTA"
	open_tables$[31]="IVM_ITEMPRIC",open_opts$[31]="OTA"
	open_tables$[32]="IVC_PRICCODE",open_opts$[32]="OTA"
	open_tables$[33]="ARM_CUSTCMTS",open_opts$[33]="OTA"
	gosub open_tables
rem --- get AR Params
	dim ars01a$:open_tpls$[4]
	read record(num(open_chans$[4]),key=firm_id$+"AR00")ars01a$
rem --- get IV Params
	dim ivs01a$:open_tpls$[29]
	read record(num(open_chans$[29]),key=firm_id$+"IV00")ivs01a$
rem --- see if blank warehouse exists
	blank_whse$="N"
	dim ivm10c$:open_tpls$[28]
	read record(num(open_chans$[28]),key=firm_id$+"C"+ivm10c.warehouse_id$,dom=*next)ivm10c$;rem blank_whse$="Y"
rem --- disable display fields
	dim dctl$[10]
	dmap$="I"
	dctl$[1]="<<DISPLAY>>.BADD1"
	dctl$[2]="<<DISPLAY>>.BADD2"
	dctl$[3]="<<DISPLAY>>.BADD3"
	dctl$[4]="<<DISPLAY>>.BADD4"
	dctl$[5]="<<DISPLAY>>.BCITY"
	dctl$[6]="<<DISPLAY>>.BSTATE"
	dctl$[7]="<<DISPLAY>>.BZIP"
	dctl$[8]="<<DISPLAY>>.ORDER_TOT"
	if ars01a.job_nos$<>"Y" 
		dctl$[9]="OPE_ORDHDR.JOB_NO"
	endif
	gosub disable_ctls
	dmap$="I"
	dctl$[1]="<<DISPLAY>>.SNAME"
	dctl$[2]="<<DISPLAY>>.SADD1"
	dctl$[3]="<<DISPLAY>>.SADD2"
	dctl$[4]="<<DISPLAY>>.SADD3"
	dctl$[5]="<<DISPLAY>>.SADD4"
	dctl$[6]="<<DISPLAY>>.SCITY"
	dctl$[7]="<<DISPLAY>>.SSTATE"
	dctl$[8]="<<DISPLAY>>.SZIP"
	gosub disable_ctls
	dctl$[1]="<<DISPLAY>>.AGING_FUTURE"
	dctl$[2]="<<DISPLAY>>.AGING_CUR"
	dctl$[3]="<<DISPLAY>>.AGING_30"
	dctl$[4]="<<DISPLAY>>.AGING_60"
	dctl$[5]="<<DISPLAY>>.AGING_90"
	dctl$[6]="<<DISPLAY>>.AGING_120"
	dctl$[7]="<<DISPLAY>>.TOT_AGING"
	gosub disable_ctls
rem --- set up UserObj! as vector
rem	UserObj!=SysGUI!.makeVector()
	ctlContext=num(callpoint!.getTableColumnAttribute("<<DISPLAY>>.ORDER_TOT","CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute("<<DISPLAY>>.ORDER_TOT","CTLI"))
	tamt!=SysGUI!.getWindow(ctlContext).getControl(ctlID)
	UserObj!.addItem(tamt!)
rem --- Setup user_tpl$
	ars_credit_dev=num(open_chans$[7])
	dim ars_credit$:open_tpls$[7]
	read record (ars_credit_dev,key=firm_id$+"AR01")ars_credit$
	user_tpl$="new_rec:c(1),credit_installed:c(1),display_bal:c(1),ord_tot:n(15),"
	user_tpl$=user_tpl$+"line_boqty:n(15),line_shipqty:n(15),def_ship:c(8),def_commit:c(8),blank_whse:c(1),"
	user_tpl$=user_tpl$+"dropship_whse:c(1),def_whse:c(10),avail_oh:c(5),avail_comm:c(5),avail_avail:c(5),"
	user_tpl$=user_tpl$+"avail_oo:c(5),avail_wh:c(5),avail_type:c(5*),dropship_flag:c(5*),ord_tot_1:c(5*),cur_row:n(5),"
	user_tpl$=user_tpl$+"price_code:c(2),pricing_code:c(4),order_date:c(8),lot_ser:c(1)"
	dim user_tpl$:user_tpl$
	user_tpl.credit_installed$=ars_credit.sys_install$
	user_tpl.display_bal$=ars_credit.display_bal$
	user_tpl.blank_whse$=blank_whse$
	user_tpl.dropship_whse$=ars01a.dropshp_whse$
	user_tpl.def_whse$=ivs01a.warehouse_id$
	user_tpl.avail_oh$="2"
	user_tpl.avail_comm$="3"
	user_tpl.avail_avail$="4"
	user_tpl.avail_oo$="5"
	user_tpl.avail_wh$="6"
	user_tpl.avail_type$="7"
	user_tpl.dropship_flag$="8"
	user_tpl.ord_tot_1$="9"
	user_tpl.cur_row=-1
	user_tpl.lot_ser$=ivs01a.lotser_flag$
