[[OPM_SHIPTRACK.ASVA]]
rem --- Launch Shipment Tracking Maintenance form
	ar_type$=callpoint!.getDevObject("ar_type")
	customer_id$=callpoint!.getDevObject("customer_id")
	order_no$=callpoint!.getDevObject("order_no")
	ship_seq_no$=callpoint!.getDevObject("ship_seq_no")
	key_pfx$=firm_id$+ar_type$+customer_id$+order_no$+ship_seq_no$

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"OPT_SHIPTRACK",
:		stbl("+USER_ID"),
:       	"MNT",
:      		key_pfx$,
:       	table_chans$[all]

	callpoint!.setStatus("ACTIVATE-ABORT")
[[OPM_SHIPTRACK.ORDER_NO.AINV]]
rem --- Warn order not found without allowing user to create it.
	msg_id$="OP_ORDER_TYPE"
	gosub disp_message
	callpoint!.setStatus("ABORT-QUIET")
[[OPM_SHIPTRACK.ORDER_NO.AINP]]
rem --- As necessary, get customer for this order
	if cvs(callpoint!.getColumnData("OPM_SHIPTRACK.CUSTOMER_ID"),2)="" then
		optInvHdr_dev=fnget_dev("@OPT_INVHDR")
		dim optInvHdr$:fnget_tpl$("@OPT_INVHDR")
		order_no$=pad(callpoint!.getUserInput(),len(optInvHdr.order_no$),"R","0")
		trip_key$=firm_id$+"  "+order_no$
		read(optInvHdr_dev,key=trip_key$,knum="AO_ORD_CUST",dom=*next)
		while 1
			optInvHdr_key$=key(optInvHdr_dev,end=*break)
			if pos(trip_key$=optInvHdr_key$)<>1 then break
			readrecord(optInvHdr_dev)optInvHdr$
			if optInvHdr.trans_status$<>"E" then continue
			callpoint!.setColumnData("OPM_SHIPTRACK.CUSTOMER_ID",optInvHdr.customer_id$,1)
			break
		wend
	endif
[[OPM_SHIPTRACK.ORDER_NO.BINQ]]
rem --- Use AR_OPEN_ORDERS custom quiry instead of default order_no lookup in order to parse selected key
	customer_id$=callpoint!.getColumnData("OPM_SHIPTRACK.CUSTOMER_ID")

	dim filter_defs$[3,2]
	filter_defs$[0,0]="OPT_INVHDR.FIRM_ID"
	filter_defs$[0,1]="='"+firm_id$+"'"
	filter_defs$[0,2]="LOCK"
	filter_defs$[1,0]="OPT_INVHDR.AR_TYPE"
	filter_defs$[1,1]="='"+callpoint!.getColumnData("OPM_SHIPTRACK.AR_TYPE")+"'"
	filter_defs$[1,2]="LOCK"
	if cvs(customer_id$,2)<>"" then
		filter_defs$[0,0]="OPT_INVHDR.CUSTOMER_ID"
		filter_defs$[0,1]="='"+customer_id$+"'"
		filter_defs$[0,2]="LOCK"
	endif

	call STBL("+DIR_SYP")+"bax_query.bbj",
:		gui_dev, 
:		Form!,
:		"AR_OPEN_ORDERS",
:		"DEFAULT",
:		table_chans$[all],
:		sel_key$,
:		filter_defs$[all]

	if sel_key$<>""
		call stbl("+DIR_SYP")+"bac_key_template.bbj",
:			"OPT_INVHDR",
:			"PRIMARY",
:			optInvHdr_key$,
:			table_chans$[all],
:			status$
		dim optInvHdr_key$:optInvHdr_key$
		optInvHdr_key$=sel_key$
		callpoint!.setColumnData("OPM_SHIPTRACK.CUSTOMER_ID",optInvHdr_key.customer_id$,1)
		callpoint!.setColumnData("OPM_SHIPTRACK.ORDER_NO",optInvHdr_key.order_no$,1)
	endif	

	callpoint!.setStatus("ACTIVATE-ABORT")
[[OPM_SHIPTRACK.AOPT-SHPT]]
rem --- Launches carrier's shipment tracking web page for a package (tracking number)
	shipTrack_grid!=callpoint!.getDevObject("shipTrack_grid")
	trackingCell!=shipTrack_grid!.getCell(shipTrack_grid!.getSelectedRow(),0)
	carrierCell!=shipTrack_grid!.getCell(shipTrack_grid!.getSelectedRow(),6)
	tracking_no$=trackingCell!.getText()
	carrier_code$=carrierCell!.getText()

	rem --- Get carrier's website URL from arc_carriercode
	arcCarrierCode_dev=fnget_dev("@ARC_CARRIERCODE")
	dim arcCarrierCode$:fnget_tpl$("@ARC_CARRIERCODE")
	readrecord(arcCarrierCode_dev,key=firm_id$+carrier_code$,dom=*next)arcCarrierCode$

	rem --- Launch web page for the tracking number
	carrier_url$=cvs(arcCarrierCode.carrier_url$,3)
	if carrier_url$<>"" then
		if carrier_url$(len(carrier_url$))<>"=" then carrier_url$=carrier_url$+"="
		BBjAPI().getThinClient().browse(carrier_url$+cvs(tracking_no$,2))
	else
		msg_id$="AR_MISSING_CARRIER_C"
		dim msg_tokens$[1]
		msg_tokens$[1]=carrier_code$
		gosub disp_message
	endif
[[OPM_SHIPTRACK.AOPT-EDIT]]
rem --- Launch Shipment Tracking Maintenance form
	ar_type$=callpoint!.getDevObject("ar_type")
	customer_id$=callpoint!.getDevObject("customer_id")
	order_no$=callpoint!.getDevObject("order_no")
	ship_seq_no$=callpoint!.getDevObject("ship_seq_no")
	key_pfx$=firm_id$+ar_type$+customer_id$+order_no$+ship_seq_no$

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"OPT_SHIPTRACK",
:		stbl("+USER_ID"),
:       	"MNT",
:      		key_pfx$,
:       	table_chans$[all]

	callpoint!.setStatus("ACTIVATE")
[[OPM_SHIPTRACK.ACUS]]
rem --- Process custom event
rem This routine is executed when callbacks have been set to run a 'custom event'.
rem Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind of event it is.
rem See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info.

	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ctl_ID=dec(gui_event.ID$)

	notify_base$=notice(gui_dev,gui_event.x%)
	dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
	notice$=notify_base$

	rem --- The Option Entry form
	if ctl_ID=Form!.getID() then
		switch notice.code
			case 22; rem --- ON_WINDOW_GAINED_FOCUS
				order_no$=callpoint!.getColumnData("OPM_SHIPTRACK.ORDER_NO")
				optInvHdr_dev=fnget_dev("@OPT_INVHDR")
				dim optInvHdr$:fnget_tpl$("@OPT_INVHDR")
				trip_key$=firm_id$+"  "+order_no$
				orderFound=0
				read(optInvHdr_dev,key=trip_key$,knum="AO_ORD_CUST",dom=*next)
				while 1
					optInvHdr_key$=key(optInvHdr_dev,end=*break)
					if pos(trip_key$=optInvHdr_key$)<>1 then break
					readrecord(optInvHdr_dev)optInvHdr$
					if optInvHdr.trans_status$<>"E" then continue
					orderFound=1
					break
				wend

				if orderFound then
					rem --- Refresh the grid as it may get changed in the opt_shiptrack maintenance grid
					SysGUI!.setRepaintEnabled(0)
					shipTrack_grid!=callpoint!.getDevObject("shipTrack_grid")
					shipTrack_grid!.clearMainGrid()
					gosub getTrackingInfo
					SysGUI!.setRepaintEnabled(1)
				endif
			break
		swend
	endif

	rem --- The grid
	if ctl_ID=num(callpoint!.getDevObject("shipTrack_grid_id")) then
		switch notice.code
			case 13; rem --- ON_GRID_LOST_FOCUS
				callpoint!.setOptionEnabled("SHPT",0)
			break
			case 19; rem --- ON_GRID_SELECT_ROW
				callpoint!.setOptionEnabled("SHPT",1)
			break
		swend
	endif
[[OPM_SHIPTRACK.AREC]]
rem --- Clear the grid for a new order
	SysGUI!.setRepaintEnabled(0)
	shipTrack_grid!=callpoint!.getDevObject("shipTrack_grid")
	shipTrack_grid!.clearMainGrid()
	SysGUI!.setRepaintEnabled(1)

rem --- Disable Additional Options
	callpoint!.setOptionEnabled("EDIT",0)
	
[[OPM_SHIPTRACK.ASIZ]]
rem --- Resize grids
	formHeight=Form!.getHeight()
	formWidth=Form!.getWidth()
	shipTrack_grid!=callpoint!.getDevObject("shipTrack_grid")
	gridYpos=shipTrack_grid!.getY()
	gridXpos=shipTrack_grid!.getX()
	availableHeight=formHeight-gridYpos

	shipTrack_grid!.setSize(formWidth-2*gridXpos,availableHeight-8)
	shipTrack_grid!.setFitToGrid(1)
[[OPM_SHIPTRACK.<CUSTOM>]]
rem ==========================================================================
format_grid: rem --- Use Barista program to format the grid
rem ==========================================================================

	call stbl("+DIR_PGM")+"adc_getmask.aon","","AR","A","",ar_a_mask$,0,0

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0] = callpoint!.getColumnAttributeTypes()
	def_inv_cols = callpoint!.getDevObject("shipTrack_grid_def_cols")
	num_rpts_rows = callpoint!.getDevObject("shipTrack_grid_min_rows")
	dim attr_inv_col$[def_inv_cols,len(attr_def_col_str$[0,0])/5]

	column_no = 1
	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="TRACKING_NO"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_TRACKING_NUM")
	attr_inv_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="325"

	column_no = column_no +1
	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="VOID_FLAG"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_VOID?")
	attr_inv_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="40"

	column_no = column_no +1
	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="WEIGHT"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_WEIGHT")
	attr_inv_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="60"
	attr_inv_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]="###0.00"

	column_no = column_no +1
	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ACT_FREIGHT_AMT"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ACTUAL")+" "+
:		Translate!.getTranslation("AON_FREIGHT_AMT")
	attr_inv_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="105"
	attr_inv_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=ar_a_mask$

	column_no = column_no +1
	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="CUST_FREIGHT_AMT"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_CUSTOMER")+" "+
:		Translate!.getTranslation("AON_FREIGHT_AMT")
	attr_inv_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="105"
	attr_inv_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=ar_a_mask$

	column_no = column_no +1
	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="CREATE_DATE"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_SHIP")+" "+
:		Translate!.getTranslation("AON_DATE")
	attr_inv_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="80"
	attr_inv_col$[column_no,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"

	column_no = column_no +1
	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="CARRIER_CODE"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_CARRIER_SERVICE_CODE")
	attr_inv_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="95"

	column_no = column_no +1
	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SCAC_CODE"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_SCAC_CODE")
	attr_inv_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="85"

	for curr_attr=1 to def_inv_cols
		attr_inv_col$[0,1] = attr_inv_col$[0,1] + 
:			pad("OPM_SHIPTRACK." + attr_inv_col$[curr_attr, fnstr_pos("DVAR", attr_def_col_str$[0,0], 5)], 40)
	next curr_attr

	attr_disp_col$=attr_inv_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,shipTrack_grid!,"COLH-LINES-LIGHT-AUTO-SIZEC-DATES",num_rpts_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_inv_col$[all]

	return

rem ==========================================================================
getTrackingInfo: rem --- Get Tracking information for this order
rem ==========================================================================

	ar_type$=optInvHdr.ar_type$
	callpoint!.setDevObject("ar_type",ar_type$)
	customer_id$=optInvHdr.customer_id$
	callpoint!.setDevObject("customer_id",customer_id$)
	order_no$=optInvHdr.order_no$
	callpoint!.setDevObject("order_no",order_no$)
	ship_seq_no$=optInvHdr.ship_seq_no$
	callpoint!.setDevObject("ship_seq_no",ship_seq_no$)

	optShipTrack_dev=fnget_dev("OPT_SHIPTRACK")
	dim optShipTrack$:fnget_tpl$("OPT_SHIPTRACK")
	gridRowVect!=SysGUI!.makeVector()
	trip_key$=firm_id$+ar_type$+customer_id$+order_no$+ship_seq_no$
	read(optShipTrack_dev,key=trip_key$,dom=*next)
	while 1
		optShipTrack_key$=key(optShipTrack_dev,end=*break)
		if pos(trip_key$=optShipTrack_key$)<>1 then break
		readrecord(optShipTrack_dev)optShipTrack$
		gridRowVect!.addItem(optShipTrack.tracking_no$)
		gridRowVect!.addItem(optShipTrack.void_flag$)
		gridRowVect!.addItem(optShipTrack.weight)
		gridRowVect!.addItem(optShipTrack.act_freight_amt)
		gridRowVect!.addItem(optShipTrack.cust_freight_amt)
		gridRowVect!.addItem(date(jul(optShipTrack.create_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		gridRowVect!.addItem(optShipTrack.carrier_code$)
		gridRowVect!.addItem(optShipTrack.scac_code$)
	wend
	callpoint!.setDevObject("gridRowVect",gridRowVect!)

	rem --- Fill grid with tracking information for this order
	SysGUI!.setRepaintEnabled(0)
	shipTrack_grid!=callpoint!.getDevObject("shipTrack_grid")
	if gridRowVect!.size()
		numrow=gridRowVect!.size()/shipTrack_grid!.getNumColumns()
		shipTrack_grid!.clearMainGrid()
		shipTrack_grid!.setNumRows(numrow)
		shipTrack_grid!.setCellText(0,0,gridRowVect!)
	endif
	SysGUI!.setRepaintEnabled(1)

	return
[[OPM_SHIPTRACK.ORDER_NO.AVAL]]
rem --- Get shipping and tracking information for this order
	order_no$=callpoint!.getUserInput()
	optInvHdr_dev=fnget_dev("@OPT_INVHDR")
	dim optInvHdr$:fnget_tpl$("@OPT_INVHDR")
	trip_key$=firm_id$+"  "+order_no$
	orderFound=0
	read(optInvHdr_dev,key=trip_key$,knum="AO_ORD_CUST",dom=*next)
	while 1
		optInvHdr_key$=key(optInvHdr_dev,end=*break)
		if pos(trip_key$=optInvHdr_key$)<>1 then break
		readrecord(optInvHdr_dev)optInvHdr$
		if optInvHdr.trans_status$<>"E" then continue
		orderFound=1
		break
	wend

	if !orderFound then
		msg_id$="OP_ORDER_TYPE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	else
		rem --- Customer for this order
		callpoint!.setColumnData("OPM_SHIPTRACK.CUSTOMER_ID",optInvHdr.customer_id$,1)
		callpoint!.setColumnData("<<DISPLAY>>.SHIPPING_ID",optInvHdr.shipping_id$,1)
		callpoint!.setColumnData("<<DISPLAY>>.SHIPPING_EMAIL",optInvHdr.shipping_email$,1)
		callpoint!.setColumnData("<<DISPLAY>>.AR_SHIP_VIA",optInvHdr.ar_ship_via$,1)

		rem --- Shipping information for this order
		switch pos(optInvHdr.shipto_type$="BMS")
			case default
			case 1; rem --- Use Bill-To address
				armCustMast_dev=fnget_dev("@ARM_CUSTMAST")
				dim tpl$:fnget_tpl$("@ARM_CUSTMAST")
				findrecord(armCustMast_dev, key=firm_id$+optInvHdr.customer_id$,dom=*next)tpl$
				sname$=tpl.customer_name$
			break
			case 2; rem --- Use manual ship-to address
				opeOrdShip_dev=fnget_dev("@OPE_ORDSHIP")
				dim tpl$:fnget_tpl$("@OPE_ORDSHIP")
				findrecord(opeOrdShip_dev, key=firm_id$+optInvHdr.customer_id$+optInvHdr.order_no$+optInvHdr.ar_inv_no$, dom=*next)tpl$
				sname$=tpl.name$
			break
			case 3; rem --- use Ship-To address
				armCustShip_dev=fnget_dev("@ARM_CUSTSHIP")
				dim tpl$:fnget_tpl$("@ARM_CUSTSHIP")
				findrecord(armCustShip_dev, key=firm_id$+optInvHdr.customer_id$+optInvHdr.shipto_no$,dom=*next)tpl$
				sname$=tpl.name$
			break
		swend
		callpoint!.setColumnData("<<DISPLAY>>.SNAME",sname$,1)
		callpoint!.setColumnData("<<DISPLAY>>.SADD1",tpl.addr_line_1$,1)
		callpoint!.setColumnData("<<DISPLAY>>.SADD2",tpl.addr_line_2$,1)
		callpoint!.setColumnData("<<DISPLAY>>.SADD3",tpl.addr_line_3$,1)
		callpoint!.setColumnData("<<DISPLAY>>.SADD4",tpl.addr_line_4$,1)
		callpoint!.setColumnData("<<DISPLAY>>.SCITY",tpl.city$,1)
		callpoint!.setColumnData("<<DISPLAY>>.SSTATE",tpl.state_code$,1)
		callpoint!.setColumnData("<<DISPLAY>>.SZIP",tpl.zip_code$,1)
		callpoint!.setColumnData("<<DISPLAY>>.SCNTRY",tpl.cntry_id$,1)

		rem --- Tracking information for this order
		gosub getTrackingInfo

		rem --- Enable Additional Options
		callpoint!.setOptionEnabled("EDIT",1)
	endif
[[OPM_SHIPTRACK.BSHO]]
rem --- Open files
	num_files=6
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="OPT_SHIPTRACK",open_opts$[1]="OTA"
	open_tables$[2]="OPT_INVHDR",open_opts$[2]="OTA@"
	open_tables$[3]="ARM_CUSTMAST",open_opts$[3]="OTA@"
	open_tables$[4]="ARM_CUSTSHIP",open_opts$[4]="OTA@"
	open_tables$[5]="OPE_ORDSHIP",open_opts$[5]="OTA@"
	open_tables$[6]="ARC_CARRIERCODE",open_opts$[6]="OTA@"

	gosub open_tables
[[OPM_SHIPTRACK.AWIN]]
rem --- Declare classes used
	use ::ado_util.src::util

rem --- Add shipment tracking grid to form
	nxt_ctlID = util.getNextControlID()
	tmpCtl!=callpoint!.getControl("<<DISPLAY>>.SCNTRY")
	grid_y=tmpCtl!.getY()+tmpCtl!.getHeight()+5
	shipTrack_grid! = Form!.addGrid(nxt_ctlID,5,grid_y,895,125); rem --- ID, x, y, width, height
	callpoint!.setDevObject("shipTrack_grid",shipTrack_grid!)
	callpoint!.setDevObject("shipTrack_grid_id",str(nxt_ctlID))
	callpoint!.setDevObject("shipTrack_grid_def_cols",8)
	callpoint!.setDevObject("shipTrack_grid_min_rows",5)

	gosub format_grid

	shipTrack_grid!.setTabAction(SysGUI!.GRID_NAVIGATE_GRID)
	shipTrack_grid!.setTabActionSkipsNonEditableCells(1)

rem --- Set minimum form size
	Form!.setSize(max(Form!.getWidth(),905), max(Form!.getHeight(),290))

rem --- Set callbacks - processed in ACUS callpoint
	Form!.setCallback(Form!.ON_WINDOW_GAINED_FOCUS,"custom_event")
	shipTrack_grid!.setCallback(shipTrack_grid!.ON_GRID_LOST_FOCUS,"custom_event")
	shipTrack_grid!.setCallback(shipTrack_grid!.ON_GRID_SELECT_ROW,"custom_event")
