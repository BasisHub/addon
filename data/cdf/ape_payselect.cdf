[[APE_PAYSELECT.AOPT-DELA]]
rem --- Turn all selected invoices off

	on_value$="N"
	gosub set_value
[[APE_PAYSELECT.AOPT-SELA]]
rem --- Turn all selected invoices on

	on_value$="Y"
	gosub set_value
[[APE_PAYSELECT.ARAR]]
rem --- If mult AP types = N, disable AP Type field

	aps_params=fnget_dev("APS_PARAMS")
	dim aps_params$:fnget_tpl$("APS_PARAMS")
	read record(aps_params, key=firm_id$+"AP00", dom=std_missing_params) aps_params$

	if aps_params.multi_types$<>"Y" then 
		callpoint!.setColumnEnabled("APE_PAYSELECT.AP_TYPE", 0)
	endif

rem --- Disable the entire Retention column (does this do anything?)

	gridInvoices! = UserObj!.getItem(num(user_tpl.gridInvoicesOfst$))
	util.disableGridColumn(gridInvoices!, user_tpl.retention_col)
[[APE_PAYSELECT.DISC_DATE_DT.AVAL]]
rem --- Set filters on grid
	gosub filter_recs
[[APE_PAYSELECT.DUE_DATE_DT.AVAL]]
rem --- Set filters on grid
	gosub filter_recs
[[APE_PAYSELECT.DISC_DATE_OP.AVAL]]
rem --- Set filters on grid
	gosub filter_recs
[[APE_PAYSELECT.PAYMENT_GRP.AVAL]]
rem --- Set filters on grid
	gosub filter_recs
[[APE_PAYSELECT.DUE_DATE_OP.AVAL]]
rem --- Set filters on grid
	gosub filter_recs
[[APE_PAYSELECT.VENDOR_ID.AVAL]]
rem --- Set filters on grid
	gosub filter_recs
[[APE_PAYSELECT.AP_TYPE.AVAL]]
rem --- Set filters on grid
	gosub filter_recs
[[APE_PAYSELECT.<CUSTOM>]]
rem ==========================================================================
format_grid: rem --- Use Barista program to format the grid
rem ==========================================================================

	call stbl("+DIR_PGM")+"adc_getmask.aon","","AP","A","",m1$,0,0

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0] = callpoint!.getColumnAttributeTypes()
	def_inv_cols = num(user_tpl.gridInvoicesCols$)
	num_rpts_rows = num(user_tpl.gridInvoicesRows$)
	dim attr_inv_col$[def_inv_cols,len(attr_def_col_str$[0,0])/5]

	attr_inv_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SELECT"
	attr_inv_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=""
	attr_inv_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"
	attr_inv_col$[1,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="1"
	attr_inv_col$[1,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="C"

	attr_inv_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="PYMNT_GRP"
	attr_inv_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_PAYMENT_GROUP")
	attr_inv_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"

	attr_inv_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="AP_TYPE"
	attr_inv_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_A/P_TYPE")
	attr_inv_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"

	attr_inv_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="VEND_ID"
	attr_inv_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_VENDOR")
	attr_inv_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"

	attr_inv_col$[5,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="VEND_NAME"
	attr_inv_col$[5,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_NAME")
	attr_inv_col$[5,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="150"

	attr_inv_col$[6,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="INVOICE_NO"
	attr_inv_col$[6,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_INVOICE")
	attr_inv_col$[6,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"

	attr_inv_col$[7,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DUE_DATE"
	attr_inv_col$[7,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DUE_DATE")
	attr_inv_col$[7,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_inv_col$[7,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="5"
	attr_inv_col$[7,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"

	attr_inv_col$[8,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DISC_DATE"
	attr_inv_col$[8,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DISCOUNT_DATE")
	attr_inv_col$[8,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_inv_col$[8,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="5"
	attr_inv_col$[8,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"

	attr_inv_col$[9,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="AMT_DUE"
	attr_inv_col$[9,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_AMOUNT_DUE")
	attr_inv_col$[9,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[9,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_inv_col$[9,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_inv_col$[10,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DISC_AMT"
	attr_inv_col$[10,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DISC_AMT")
	attr_inv_col$[10,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[10,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_inv_col$[10,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_inv_col$[11,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="PYMNT_AMT"
	attr_inv_col$[11,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_PAYMENT")
	attr_inv_col$[11,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[11,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_inv_col$[11,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_inv_col$[12,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="RETEN_AMT"
	attr_inv_col$[12,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_RETENTION")
	attr_inv_col$[12,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[12,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_inv_col$[12,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	for curr_attr=1 to def_inv_cols
		attr_inv_col$[0,1] = attr_inv_col$[0,1] + 
:			pad("APT_PAY." + attr_inv_col$[curr_attr, fnstr_pos("DVAR", attr_def_col_str$[0,0], 5)], 40)
	next curr_attr

	attr_disp_col$=attr_inv_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridInvoices!,"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC-CHECKS-DATES",num_rpts_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_inv_col$[all]

	return

rem ==========================================================================
fill_grid: rem --- Fill the grid with data in vectInvoices!
rem ==========================================================================

	SysGUI!.setRepaintEnabled(0)
	gridInvoices! = UserObj!.getItem(num(user_tpl.gridInvoicesOfst$))
	minrows = num(user_tpl.gridInvoicesRows$)

	if vectInvoices!.size() then
		numrow = vectInvoices!.size() / gridInvoices!.getNumColumns()
		gridInvoices!.clearMainGrid()
		gridInvoices!.setColumnStyle(0,SysGUI!.GRID_STYLE_UNCHECKED)
		gridInvoices!.setNumRows(numrow)
		gridInvoices!.setCellText(0,0,vectInvoices!)

		for wk=0 to vectInvoices!.size()-1 step gridInvoices!.getNumColumns()
			if vectInvoices!.getItem(wk) = "Y" then 
				gridInvoices!.setCellStyle(wk / gridInvoices!.getNumColumns(), 0, SysGUI!.GRID_STYLE_CHECKED)
			endif
			gridInvoices!.setCellText(wk / gridInvoices!.getNumColumns(), 0, "")
		next wk

		gridInvoices!.resort()
	else
		gridInvoices!.clearMainGrid()
		gridInvoices!.setColumnStyle(0, SysGUI!.GRID_STYLE_UNCHECKED)
		gridInvoices!.setNumRows(0)
	endif

	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
create_reports_vector: rem --- Create a vector from the file to fill the grid
rem ==========================================================================

	call stbl("+DIR_PGM")+"adc_getmask.aon","VENDOR_ID","","","",m0$,0,vendor_len
	more=1
	read (apt01_dev,key=firm_id$,dom=*next)
	rows=0

	while more
		read record (apt01_dev, end=*break) apt01a$
		if pos(firm_id$=apt01a$)<>1 then break
		read (ape01_dev, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, dom=*next); continue
		dim apm01a$:fattr(apm01a$)
		read record(apm01_dev, key=firm_id$+apt01a.vendor_id$, dom=*next) apm01a$
		read record(apt11_dev, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, dom=*next)

		while more
			readrecord(apt11_dev,end=*break)apt11a$

			if pos(firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$ =
:				    firm_id$+apt11a.ap_type$+apt11a.vendor_id$+apt11a.ap_inv_no$) <> 1 
:			then 
				break
			endif

			apt01a.invoice_amt = apt01a.invoice_amt + apt11a.trans_amt
			apt01a.discount_amt = apt01a.discount_amt + apt11a.trans_disc
		wend
		if apt01a.discount_amt<0 then apt01a.discount_amt=0

	rem --- override discount and payment amounts if already in ape04 (computer checks)

		disc_amt=apt01a.discount_amt
		pymnt_amt=0
		dim ape04a$:fattr(ape04a$)
		read record(ape04_dev, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, dom=*next) ape04a$

		if cvs(ape04a.firm_id$,2)<>""
			disc_amt  = ape04a.discount_amt
			pymnt_amt = ape04a.invoice_amt
		endif

	rem --- Now fill vectors
	rem --- Items 1 thru n+1 in InvoicesMaster must equal items 0 thru n in Invoices

		if apt01a.invoice_amt<>0 then
			vectInvoices!.addItem(apt01a.selected_for_pay$); rem 0
			vectInvoices!.addItem(apt01a.payment_grp$); rem 1
			vectInvoices!.addItem(apt01a.ap_type$); rem 2
			vectInvoices!.addItem(func.alphaMask(apt01a.vendor_id$(1,vendor_len),m0$)); rem 3
			vectInvoices!.addItem(apm01a.vendor_name$); rem 4
			vectInvoices!.addItem(apt01a.ap_inv_no$); rem 5
			vectInvoices!.addItem(date(jul(apt01a.inv_due_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID"))); rem 6
			vectInvoices!.addItem(date(jul(apt01a.disc_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID"))); rem 7
			vectInvoices!.addItem(str(apt01a.invoice_amt - apt01a.retention - disc_amt - pymnt_amt)); rem 8
			vectInvoices!.addItem(str(disc_amt)); rem 9
			vectInvoices!.addItem(str(pymnt_amt)); rem 10
			vectInvoices!.addItem(apt01a.retention$); rem 11

			vectInvoicesMaster!.addItem("Y"); rem 0
			vectInvoicesMaster!.addItem(apt01a.selected_for_pay$); rem 1
			vectInvoicesMaster!.addItem(apt01a.payment_grp$); rem 2
			vectInvoicesMaster!.addItem(apt01a.ap_type$); rem 3
			vectInvoicesMaster!.addItem(func.alphaMask(apt01a.vendor_id$(1,vendor_len),m0$)); rem 4
			vectInvoicesMaster!.addItem(apm01a.vendor_name$); rem 5
			vectInvoicesMaster!.addItem(apt01a.ap_inv_no$); rem 6
			vectInvoicesMaster!.addItem(date(jul(apt01a.inv_due_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID"))); rem 7
			vectInvoicesMaster!.addItem(date(jul(apt01a.disc_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID"))); rem 8
			vectInvoicesMaster!.addItem(str(apt01a.invoice_amt - apt01a.retention - disc_amt - pymnt_amt)); rem 9
			vectInvoicesMaster!.addItem(str(disc_amt)); rem 10
			vectInvoicesMaster!.addItem(str(pymnt_amt)); rem 11
			vectInvoicesMaster!.addItem(apt01a.retention$); rem 12
			vectInvoicesMaster!.addItem(apt01a.inv_due_date$); rem 13
			vectInvoicesMaster!.addItem(apt01a.vendor_id$); rem 14
			vectInvoicesMaster!.addItem(apt01a.disc_date$); rem 15
			vectInvoicesMaster!.addItem(apt01a.invoice_amt$); rem 16
			rows=rows+1
		endif
	wend

	callpoint!.setStatus("REFRESH")
	
	return

rem ==========================================================================
switch_value: rem --- Switch Check Values
rem ==========================================================================

	apm01_dev = fnget_dev("APM_VENDMAST")
	dim apm01a$:fnget_tpl$("APM_VENDMAST")
	apt01_dev = fnget_dev("APT_INVOICEHDR")
	dim apt01a$:fnget_tpl$("APT_INVOICEHDR")
	apt11_dev = fnget_dev("APT_INVOICEDET")
	dim apt11a$:fnget_tpl$("APT_INVOICEDET")

	SysGUI!.setRepaintEnabled(0)

	gridInvoices!       = UserObj!.getItem(num(user_tpl.gridInvoicesOfst$))
	vectInvoices!       = UserObj!.getItem(num(user_tpl.vectInvoicesOfst$))
	vectInvoicesMaster! = UserObj!.getItem(num(user_tpl.vectInvoicesMasterOfst$))

	TempRows! = gridInvoices!.getSelectedRows()
	numcols   = gridInvoices!.getNumColumns()

	if TempRows!.size() > 0 then
		for curr_row=1 to TempRows!.size()
			row_no = num(TempRows!.getItem(curr_row-1))

		rem --- Not checked -> checked

			if gridInvoices!.getCellState(row_no,0) = 0 then
				vend$ = gridInvoices!.getCellText(row_no,3)
				gosub strip_dashes
				read record (apm01_dev, key=firm_id$+
:					vend$, dom=*next) apm01a$

rem --- Following lines removed to allow payment of open invoices for a held vendor
rem				if apm01a.hold_flag$="Y" then
rem					msg_id$="AP_VEND_HOLD"
rem					gosub disp_message
rem					break
rem				endif

				read record (apt01_dev, key=firm_id$+
:					gridInvoices!.getCellText(row_no,2)+
:					vend$+
:					gridInvoices!.getCellText(row_no,5), dom=*next) apt01a$

				if apt01a.hold_flag$="Y" then
					msg_id$="AP_INV_HOLD"
					gosub disp_message
					break
				endif
				
				read record(apt11_dev, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, dom=*next)
				while 1
					readrecord(apt11_dev,end=*break)apt11a$
					if pos(firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$ =
:						    firm_id$+apt11a.ap_type$+apt11a.vendor_id$+apt11a.ap_inv_no$) <> 1 
:					then 
						break
					endif

					apt01a.invoice_amt = apt01a.invoice_amt + apt11a.trans_amt
					apt01a.discount_amt = apt01a.discount_amt + apt11a.trans_disc
				wend
				if apt01a.discount_amt<0 then apt01a.discount_amt=0

				gridInvoices!.setCellState(row_no,0,1)

				if callpoint!.getColumnData("APE_PAYSELECT.INCLUDE_DISC")="Y" or
:					apt01a.disc_date$ >= sysinfo.system_date$
:				then
					gridInvoices!.setCellText(row_no, 9, apt01a.discount_amt$)
				endif

				gridInvoices!.setCellText(row_no, 8, "0.00")
				payment_amt = apt01a.invoice_amt - num(gridInvoices!.getCellText(row_no,9)) - apt01a.retention
				gridInvoices!.setCellText(row_no, 10, str(payment_amt))
				vectInvoices!.setItem(row_no * numcols, "Y")
				dummy = fn_setmast_flag(
:					vectInvoices!.getItem(row_no*numcols+2),
:					vectInvoices!.getItem(row_no*numcols+3),
:					vectInvoices!.getItem(row_no*numcols+5),
:					"Y",
:					gridInvoices!.getCellText(row_no,8)
:				)
				dummy = fn_setmast_amts(
:					vectInvoices!.getItem(row_no*numcols+2),
:					vectInvoices!.getItem(row_no*numcols+3),
:					vectInvoices!.getItem(row_no*numcols+5),
:					gridInvoices!.getCellText(row_no, 9),
:					str(payment_amt)
:				)

		rem --- Checked -> not checked

			else
				rem --- re-initialize
				vend$ = gridInvoices!.getCellText(row_no,3)
				gosub strip_dashes
				read record (apt01_dev, key=firm_id$+
:					gridInvoices!.getCellText(row_no,2)+
:					vend$+
:					gridInvoices!.getCellText(row_no,5), dom=*next) apt01a$
				
				read record(apt11_dev, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, dom=*next)
				while 1
					readrecord(apt11_dev,end=*break)apt11a$
					if pos(firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$ =
:						    firm_id$+apt11a.ap_type$+apt11a.vendor_id$+apt11a.ap_inv_no$) <> 1 
:					then 
						break
					endif

					apt01a.invoice_amt = apt01a.invoice_amt + apt11a.trans_amt
					apt01a.discount_amt = apt01a.discount_amt + apt11a.trans_disc
				wend
				if apt01a.discount_amt<0 then apt01a.discount_amt=0

				gridInvoices!.setCellState(row_no,0,0)
				gridInvoices!.setCellText(row_no, 8, str(str(apt01a.invoice_amt - apt01a.retention - apt01a.discount_amt)))
				gridInvoices!.setCellText(row_no,9,str(apt01a.discount_amt))
				gridInvoices!.setCellText(row_no,10,"0.00")
				dummy = fn_setmast_flag(
:					vectInvoices!.getItem(row_no*numcols+2),
:					vectInvoices!.getItem(row_no*numcols+3),
:					vectInvoices!.getItem(row_no*numcols+5),
:					"N",
:					"0"
:				)
				dummy = fn_setmast_amts(
:					vectInvoices!.getItem(row_no*numcols+2),
:					vectInvoices!.getItem(row_no*numcols+3),
:					vectInvoices!.getItem(row_no*numcols+5),
:					str(apt01a.discount_amt),
:					"0"
:				)
			endif
		next curr_row
	endif

	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
filter_recs: rem --- Set grid vector based on filters
rem ==========================================================================

	vectInvoicesMaster! = UserObj!.getItem(num(user_tpl.vectInvoicesMasterOfst$))
	vectInvoices! = UserObj!.getItem(num(user_tpl.vectInvoicesOfst$))
	vect_size = num(vectInvoicesMaster!.size())

	if vect_size then 

	rem --- Reset all select to include flags to Yes

		for x=1 to vect_size step user_tpl.MasterCols
			vectInvoicesMaster!.setItem(x-1,"Y")
		next x

	rem --- Set variables using either getColumnData or getUserInput, depending on where gosub'd from

		if callpoint!.getVariableName()="APE_PAYSELECT.DISC_DATE_DT"
			filter_pymnt_grp$=callpoint!.getColumnData("APE_PAYSELECT.PAYMENT_GRP")
			filter_aptype$=callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE")
			filter_vendor$=callpoint!.getColumnData("APE_PAYSELECT.VENDOR_ID")
			filter_due_op$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_OP")
			filter_due_date$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT")
			filter_disc_op$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_OP")
			filter_disc_date$=callpoint!.getUserInput()
		else
			if callpoint!.getVariableName()="APE_PAYSELECT.DUE_DATE_DT"
				filter_pymnt_grp$=callpoint!.getColumnData("APE_PAYSELECT.PAYMENT_GRP")
				filter_aptype$=callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE")
				filter_vendor$=callpoint!.getColumnData("APE_PAYSELECT.VENDOR_ID")
				filter_due_op$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_OP")
				filter_due_date$=callpoint!.getUserInput()
				filter_disc_op$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_OP")
				filter_disc_date$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT")
			else
				if callpoint!.getVariableName()="APE_PAYSELECT.DISC_DATE_OP"
					filter_pymnt_grp$=callpoint!.getColumnData("APE_PAYSELECT.PAYMENT_GRP")
					filter_aptype$=callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE")
					filter_vendor$=callpoint!.getColumnData("APE_PAYSELECT.VENDOR_ID")
					filter_due_op$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_OP")
					filter_due_date$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT")
					filter_disc_op$=callpoint!.getUserInput()
					filter_disc_date$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT")
				else
					if callpoint!.getVariableName()="APE_PAYSELECT.DUE_DATE_OP"
						filter_pymnt_grp$=callpoint!.getColumnData("APE_PAYSELECT.PAYMENT_GRP")
						filter_aptype$=callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE")
						filter_vendor$=callpoint!.getColumnData("APE_PAYSELECT.VENDOR_ID")
						filter_due_op$=callpoint!.getUserInput()
						filter_due_date$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT")
						filter_disc_op$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_OP")
						filter_disc_date$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT")
					else
						if callpoint!.getVariableName()="APE_PAYSELECT.PAYMENT_GRP"
							filter_pymnt_grp$=callpoint!.getUserInput()
							filter_aptype$=callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE")
							filter_vendor$=callpoint!.getColumnData("APE_PAYSELECT.VENDOR_ID")
							filter_due_op$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_OP")
							filter_due_date$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT")
							filter_disc_op$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_OP")
							filter_disc_date$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT")
						else
							if callpoint!.getVariableName()="APE_PAYSELECT.VENDOR_ID"
								filter_pymnt_grp$=callpoint!.getColumnData("APE_PAYSELECT.PAYMENT_GRP")
								filter_aptype$=callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE")
								filter_vendor$=callpoint!.getUserInput()
								filter_due_op$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_OP")
								filter_due_date$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT")
								filter_disc_op$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_OP")
								filter_disc_date$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT")
							else
								if callpoint!.getVariableName()="APE_PAYSELECT.AP_TYPE"
									filter_pymnt_grp$=callpoint!.getColumnData("APE_PAYSELECT.PAYMENT_GRP")
									filter_aptype$=callpoint!.getUserInput()
									filter_vendor$=callpoint!.getColumnData("APE_PAYSELECT.VENDOR_ID")
									filter_due_op$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_OP")
									filter_due_date$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT")
									filter_disc_op$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_OP")
									filter_disc_date$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT")
								else
										filter_pymnt_grp$=callpoint!.getColumnData("APE_PAYSELECT.PAYMENT_GRP")
										filter_aptype$=callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE")
										filter_vendor$=callpoint!.getColumnData("APE_PAYSELECT.VENDOR_ID")
										filter_due_op$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_OP")
										filter_due_date$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT")
										filter_disc_op$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_OP")
										filter_disc_date$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT")									
								endif
							endif
						endif
					endif
				endif
			endif
		endif

		if cvs(filter_vendor$,3)="" filter_vendor$=""

	rem --- Set all excluded filtered flags to No 

		for x=1 to vect_size step user_tpl.MasterCols
			select_rec$="Y"

			if filter_pymnt_grp$<>"" and filter_pymnt_grp$<>vectInvoicesMaster!.getItem(x-1+2)
				select_rec$="N"
			endif

			if filter_aptype$<>"" and filter_aptype$<>vectInvoicesMaster!.getItem(x-1+3)
				select_rec$="N"
			endif

			if filter_vendor$<>"" and filter_vendor$<>vectInvoicesMaster!.getItem(x-1+14)
				select_rec$="N"
			endif

			if filter_due_op$<>"0" and filter_due_date$<>""
				if fn_filter_txt(filter_due_op$,vectInvoicesMaster!.getItem(x-1+13),filter_due_date$)=0
					select_rec$="N"
				endif
			endif

			if filter_disc_op$<>"0" and filter_disc_date$<>""
				if fn_filter_txt(filter_disc_op$,vectInvoicesMaster!.getItem(x-1+15),filter_disc_date$)=0
					select_rec$="N"
				endif
			endif

			if select_rec$="N"
				vectInvoicesMaster!.setItem(x-1,"N")
			endif
		next x

	rem --- Clear and reset visible grid

		vectInvoices!.clear()

		for x=1 to vect_size step user_tpl.MasterCols
			if vectInvoicesMaster!.getItem(x-1)="Y"
				for y=1 to num(user_tpl.gridInvoicesCols$)
					vectInvoices!.addItem(vectInvoicesMaster!.getItem(x-1+y))
				next y
			endif
		next x

		UserObj!.setItem(num(user_tpl.vectInvoicesMasterOfst$),vectInvoicesMaster!)
		UserObj!.setItem(num(user_tpl.vectInvoicesOfst$),vectInvoices!)
		gosub fill_grid
	endif

	return

rem ==========================================================================
strip_dashes: rem --- Strip dashes from Vendor Number and pad with zeros if necessary
rem ==========================================================================

	new_vend$=""

	for dashes=1 to len(vend$)
		if vend$(dashes,1)<>"-" then new_vend$=new_vend$+vend$(dashes,1)
	next dashes

	vend_len=num(callpoint!.getTableColumnAttribute("APE_PAYSELECT.VENDOR_ID","MAXL"))
	vend$=pad(new_vend$,vend_len,"L","0")

	return

rem ==========================================================================
set_value: rem --- Set Check Values for all rows - on/off
		rem --- on_value$="Y" to set all to on
		rem --- on_value$="N" to set all to off
rem ==========================================================================

	apm01_dev = fnget_dev("APM_VENDMAST")
	dim apm01a$:fnget_tpl$("APM_VENDMAST")
	apt01_dev = fnget_dev("APT_INVOICEHDR")
	dim apt01a$:fnget_tpl$("APT_INVOICEHDR")
	apt11_dev = fnget_dev("APT_INVOICEDET")
	dim apt11a$:fnget_tpl$("APT_INVOICEDET")

	SysGUI!.setRepaintEnabled(0)

	gridInvoices!       = UserObj!.getItem(num(user_tpl.gridInvoicesOfst$))
	vectInvoices!       = UserObj!.getItem(num(user_tpl.vectInvoicesOfst$))
	vectInvoicesMaster! = UserObj!.getItem(num(user_tpl.vectInvoicesMasterOfst$))

	TempRows! = gridInvoices!.getSelectedRows()
	numcols   = gridInvoices!.getNumColumns()

	vect_size = num(vectInvoicesMaster!.size())
	rows = 0

	for x=1 to vect_size step user_tpl.MasterCols
		if vectInvoicesMaster!.getItem(x-1)="Y"
			rows=rows+1
		endif
	next x

	if rows > 0 then
		for curr_row=1 to rows
			row_no = curr_row-1

		rem --- set as checked
			if on_value$="Y" then
				vend$ = gridInvoices!.getCellText(row_no,3)
				gosub strip_dashes
				read record (apm01_dev, key=firm_id$+
:					vend$, dom=*next) apm01a$

rem --- Following lines removed to allow payment of open invoices for a held vendor
rem				if apm01a.hold_flag$="Y" then
rem					msg_id$="AP_VEND_HOLD"
rem					gosub disp_message
rem					break
rem				endif

				read record (apt01_dev, key=firm_id$+
:					gridInvoices!.getCellText(row_no,2)+
:					vend$+
:					gridInvoices!.getCellText(row_no,5), dom=*next) apt01a$

				if apt01a.hold_flag$="Y" then
					msg_id$="AP_INV_HOLD"
					gosub disp_message
					continue
				endif

				read record(apt11_dev, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, dom=*next)
				while 1
					readrecord(apt11_dev,end=*break)apt11a$
					if pos(firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$ =
:						    firm_id$+apt11a.ap_type$+apt11a.vendor_id$+apt11a.ap_inv_no$) <> 1 
:					then 
						break
					endif

					apt01a.invoice_amt = apt01a.invoice_amt + apt11a.trans_amt
					apt01a.discount_amt = apt01a.discount_amt + apt11a.trans_disc
				wend
				if apt01a.discount_amt<0 then apt01a.discount_amt=0

				gridInvoices!.setCellState(row_no,0,1)

				if callpoint!.getColumnData("APE_PAYSELECT.INCLUDE_DISC")="Y" or
:					apt01a.disc_date$ >= sysinfo.system_date$
:				then
					gridInvoices!.setCellText(row_no, 9, apt01a.discount_amt$)
				endif

				gridInvoices!.setCellText(row_no, 8, "0.00")
				payment_amt = apt01a.invoice_amt - num(gridInvoices!.getCellText(row_no,9)) - apt01a.retention
				gridInvoices!.setCellText(row_no, 10, str(payment_amt))
				vectInvoices!.setItem(row_no * numcols, "Y")
				dummy = fn_setmast_flag(
:					vectInvoices!.getItem(row_no*numcols+2),
:					vectInvoices!.getItem(row_no*numcols+3),
:					vectInvoices!.getItem(row_no*numcols+5),
:					"Y",
:					gridInvoices!.getCellText(row_no,8)
:				)
				dummy = fn_setmast_amts(
:					vectInvoices!.getItem(row_no*numcols+2),
:					vectInvoices!.getItem(row_no*numcols+3),
:					vectInvoices!.getItem(row_no*numcols+5),
:					gridInvoices!.getCellText(row_no, 9),
:					str(payment_amt)
:				)

		rem --- Checked -> not checked

			else
				rem --- re-initialize
				vend$ = gridInvoices!.getCellText(row_no,3)
				gosub strip_dashes
				read record (apt01_dev, key=firm_id$+
:					gridInvoices!.getCellText(row_no,2)+
:					vend$+
:					gridInvoices!.getCellText(row_no,5), dom=*next) apt01a$

				read record(apt11_dev, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, dom=*next)
				while 1
					readrecord(apt11_dev,end=*break)apt11a$
					if pos(firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$ =
:						    firm_id$+apt11a.ap_type$+apt11a.vendor_id$+apt11a.ap_inv_no$) <> 1 
:					then 
						break
					endif

					apt01a.invoice_amt = apt01a.invoice_amt + apt11a.trans_amt
					apt01a.discount_amt = apt01a.discount_amt + apt11a.trans_disc
				wend
				if apt01a.discount_amt<0 then apt01a.discount_amt=0

				gridInvoices!.setCellState(row_no,0,0)
				gridInvoices!.setCellText(row_no, 8, str(str(apt01a.invoice_amt - apt01a.retention - apt01a.discount_amt)))
				gridInvoices!.setCellText(row_no,9,str(apt01a.discount_amt))
				gridInvoices!.setCellText(row_no,10,"0.00")
				dummy = fn_setmast_flag(
:					vectInvoices!.getItem(row_no*numcols+2),
:					vectInvoices!.getItem(row_no*numcols+3),
:					vectInvoices!.getItem(row_no*numcols+5),
:					"N",
:					"0"
:				)
				dummy = fn_setmast_amts(
:					vectInvoices!.getItem(row_no*numcols+2),
:					vectInvoices!.getItem(row_no*numcols+3),
:					vectInvoices!.getItem(row_no*numcols+5),
:					str(apt01a.discount_amt),
:					"0"
:				)
			endif
		next curr_row
	endif

	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
get_master_offset:
rem ==========================================================================

	inv_x=0
	for mast_x=0 to vectInvoicesMaster!.size() step num(user_tpl.MasterCols)
		if vectInvoicesMaster!.getItem(mast_x+4)=vend_id$ and
:			vectInvoicesMaster!.getItem(mast_x+3)=ap_type$ and
:			vectInvoicesMaster!.getItem(mast_x+6)=inv_no$
			mast_offset=mast_x
			exitto offset_return
		endif
		inv_x=inv_x+11;rem vectInvoices size
	next mast_x
offset_return:
	return

rem ==========================================================================
rem --- Functions
rem ==========================================================================

rem --- fn_filter_txt: Check Operator data for text fields

	def fn_filter_txt(q1$,q2$,q3$)
		ret_val=0
		switch num(q1$)
			case 1; if q2$<q3$ ret_val=1; endif; break
			case 2; if q2$=q3$ ret_val=1; endif; break
			case 3; if q2$>q3$ ret_val=1; endif; break
			case 4; if q2$<=q3$ ret_val=1; endif; break
			case 5; if q2$>=q3$ ret_val=1; endif; break
			case 6; if q2$<>q3$ ret_val=1; endif; break
		swend
		return ret_val
	fnend

rem --- Set Selected Flag and Invoice Amount in InvoiceMaster vector

	def fn_setmast_flag(q1$,q2$,q3$,flag$,f_invamt$)
		for q=0 to vectInvoicesMaster!.size()-1 step user_tpl.MasterCols
			if vectInvoicesMaster!.getItem(q+3) = q1$ and
:				vectInvoicesMaster!.getItem(q+4) = q2$ and
:				vectInvoicesMaster!.getItem(q+6) = q3$
:			then
				vectInvoicesMaster!.setItem(q+1,flag$)
				vectInvoicesMaster!.setItem(q+11,f_invamt$)
				return 0
			endif
		next q

		return 0
	fnend

rem --- Set Discount and Payment Amount in InvoiceMaster vector

	def fn_setmast_amts(q1$,q2$,q3$,f_disc_amt$,f_pmt_amt$)
		for q=0 to vectInvoicesMaster!.size()-1 step user_tpl.MasterCols
			if vectInvoicesMaster!.getItem(q+3) = q1$ and
:				vectInvoicesMaster!.getItem(q+4) = q2$ and
:				vectInvoicesMaster!.getItem(q+6) = q3$
:			then
				vectInvoicesMaster!.setItem(q+10,f_disc_amt$)
				vectInvoicesMaster!.setItem(q+11,f_pmt_amt$)
				return 0
			endif
		next q

		return 0
	fnend

rem ==========================================================================
#include std_missing_params.src
rem ==========================================================================
[[APE_PAYSELECT.ASVA]]
rem --- Update apt-01 (remove/write) based on what's checked in the grid

	apt01_dev = fnget_dev("APT_INVOICEHDR")
	dim apt01a$:fnget_tpl$("APT_INVOICEHDR")
	ape04_dev = fnget_dev("APE_CHECKS")
	dim ape04a$:fnget_tpl$("APE_CHECKS")
	apt11_dev = fnget_dev("APT_INVOICEDET")
	dim apt11a$:fnget_tpl$("APT_INVOICEDET")

	vectInvoicesMaster! = UserObj!.getItem(num(user_tpl.vectInvoicesMasterOfst$))

	if vectInvoicesMaster!.size()
rem --- First check to see if user_tpl.ap_check_seq$ is Y and multiple AP Types are selected
		aptypes$=""
		if user_tpl.ap_check_seq$="Y"
			for row=0 to vectInvoicesMaster!.size()-1 step user_tpl.MasterCols
				if vectInvoicesMaster!.getItem(row+1)="Y"
					if aptypes$<>""
						if vectInvoicesMaster!.getItem(row+3)<>aptypes$
							callpoint!.setMessage("AP_NO_SELECT")
							aptypes$="ABORT"
						endif
					else
						aptypes$=vectInvoicesMaster!.getItem(row+3)
					endif
				endif
			next row
		endif

		if aptypes$<>"ABORT"
			call stbl("+DIR_PGM")+"adc_clearpartial.aon","N",ape04_dev,firm_id$,status

			for row=0 to vectInvoicesMaster!.size()-1 step user_tpl.MasterCols
				vend$ = vectInvoicesMaster!.getItem(row+4)
				gosub strip_dashes
				apt01_key$=firm_id$+vectInvoicesMaster!.getItem(row+3)+
:								   vend$+
:								   vectInvoicesMaster!.getItem(row+6)
				read record (apt01_dev, key=apt01_key$) apt01a$
				orig_inv_amt   = num(vectInvoicesMaster!.getItem(row+16))
				disc_to_take = num(vectInvoicesMaster!.getItem(row+10))
				amt_to_pay   = num(vectInvoicesMaster!.getItem(row+11))

				if vectInvoicesMaster!.getItem(row+1)<>"Y"
					apt01a.selected_for_pay$="N"
					remove (ape04_dev, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, dom=*next)
				else
					apt01a.selected_for_pay$="Y"
					dim ape04a$:fattr(ape04a$)

					ape04a.firm_id$      = firm_id$
					ape04a.ap_type$      = apt01a.ap_type$
					ape04a.vendor_id$    = apt01a.vendor_id$
					ape04a.ap_inv_no$    = apt01a.ap_inv_no$
					ape04a.reference$    = apt01a.reference$
					ape04a.ap_inv_memo$  = apt01a.ap_inv_memo$
					ape04a.invoice_date$ = apt01a.invoice_date$
					ape04a.inv_due_date$ = apt01a.inv_due_date$
					ape04a.disc_date$    = apt01a.disc_date$
					ape04a.invoice_amt   = amt_to_pay
					ape04a.discount_amt  = disc_to_take
					ape04a.retention     = apt01a.retention
					ape04a.orig_inv_amt  = orig_inv_amt

					ape04a$=field(ape04a$)
					write record (ape04_dev) ape04a$
				endif

				apt01a$ = field(apt01a$)
				write record (apt01_dev) apt01a$
			next row
		endif
	endif
[[APE_PAYSELECT.AWIN]]
rem --- Open/Lock files

	use ::ado_util.src::util
	use ::ado_func.src::func

	num_files=7
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="APT_INVOICEHDR",open_opts$[1]="OTA"
	open_tables$[2]="APT_INVOICEDET",open_opts$[2]="OTA"
	open_tables$[3]="APM_VENDMAST",open_opts$[3]="OTA"
	open_tables$[4]="APE_CHECKS",open_opts$[4]="OTA"
	open_tables$[5]="APW_CHECKINVOICE",open_opts$[5]="OTA"
	open_tables$[6]="APE_INVOICEHDR",open_opts$[6]="OTA"
	open_tables$[7]="APS_PARAMS",open_opts$[7]="OTA"

	gosub open_tables

	apt01_dev=num(open_chans$[1]),apt01_tpl$=open_tpls$[1]
	apt11_dev=num(open_chans$[2]),apt11_tpl$=open_tpls$[2]
	apm01_dev=num(open_chans$[3]),apm01_tpl$=open_tpls$[3]
	ape04_dev=num(open_chans$[4]),ape04_tpl$=open_tpls$[4]
	apw01_dev=num(open_chans$[5])
	ape01_dev=num(open_chans$[6]),ape01_tpl$=open_tpls$[6]
	aps_params=num(open_chans$[7]),aps_params_tpl$=open_tpls$[7]

rem --- Dimension string templates

	dim apt01a$:apt01_tpl$,apt11a$:apt11_tpl$,apm01a$:apm01_tpl$,ape04a$:ape04_tpl$
	dim ape01a$:ape01_tpl$,aps_params$:aps_params_tpl$

rem --- Get parameter record

	readrecord(aps_params,key=firm_id$+"AP00")aps_params$

rem --- See if Check Printing has already been started

	k$=""	
	read (apw01_dev,key=firm_id$,dom=*next)
	k$=key(apw01_dev,end=*next)
	if pos(firm_id$=k$)=1 then
		msg_id$="CHECKS_IN_PROGRESS"
		gosub disp_message
		if pos("PASSVALID"=msg_opt$)=0 then
			bbjAPI!=bbjAPI()
			rdFuncSpace!=bbjAPI!.getGroupNamespace()
			rdFuncSpace!.setValue("+build_task","OFF")
			release
		endif
	endif

rem --- See if we need to clear out ape-04 (computer checks)

	while 1
		read(ape04_dev,key=firm_id$,dom=*next)
		ape04_key$=key(ape04_dev,end=*break)
		if pos(firm_id$=ape04_key$)<>1 break

		msg_id$="CLEAR_SEL"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message

		if msg_opt$="Y" then
			call stbl("+DIR_PGM")+"adc_clearpartial.aon","N",ape04_dev,firm_id$,status
			read(apt01_dev,key=firm_id$,dom=*next)
			more=1

			while more
				apt01_key$=key(apt01_dev,end=*break)
				if pos(firm_id$=apt01_key$)<>1 then break
				read record (apt01_dev, key=apt01_key$) apt01a$
				apt01a.selected_for_pay$="N"
				apt01a$=field(apt01a$)
				write record (apt01_dev) apt01a$
			wend	
		endif

		break
	wend

rem --- Add grid to store invoices, with checkboxes for user to select one or more

	user_tpl_str$ = "gridInvoicesOfst:c(5), " +
:		"gridInvoicesCols:c(5), " +
:		"gridInvoicesRows:c(5), " +
:		"gridInvoicesCtlID:c(5)," +
:		"vectInvoicesOfst:c(5), " +
:		"vectInvoicesMasterOfst:c(5), " +
:		"MasterCols:n(5), " +
:		"retention_col:u(1), " +
:		"ap_check_seq:c(1)"
	dim user_tpl$:user_tpl_str$

	UserObj! = BBjAPI().makeVector()
	vectInvoices! = BBjAPI().makeVector()
	vectInvoicesMaster! = BBjAPI().makeVector()
	nxt_ctlID = util.getNextControlID()

	gridInvoices! = Form!.addGrid(nxt_ctlID,5,140,800,300); rem --- ID, x, y, width, height

	user_tpl.gridInvoicesCtlID$ = str(nxt_ctlID)
	user_tpl.gridInvoicesCols$ = "12"
	user_tpl.gridInvoicesRows$ = "10"
	user_tpl.MasterCols = 17
	user_tpl.retention_col = 12
	user_tpl.ap_check_seq$=aps_params.ap_check_seq$

	gosub format_grid
	util.resizeWindow(Form!, SysGui!)

	UserObj!.addItem(gridInvoices!)
	user_tpl.gridInvoicesOfst$="0"

	UserObj!.addItem(vectInvoices!); rem --- vector of filtered recs from Open Invoices
	user_tpl.vectInvoicesOfst$="1"

	UserObj!.addItem(vectInvoicesMaster!); rem --- vector of all Open Invoices
	user_tpl.vectInvoicesMasterOfst$="2"

rem --- Misc other init

	gridInvoices!.setColumnEditable(0,1)
	gridInvoices!.setColumnEditable(9,1)
	gridInvoices!.setColumnEditable(10,1)
	gridInvoices!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)
	gridInvoices!.setTabAction(gridInvoices!.GRID_NAVIGATE_GRID)
	gridInvoices!.setTabActionSkipsNonEditableCells(1)

	gosub create_reports_vector
	gosub fill_grid

rem --- Set callbacks - processed in ACUS callpoint

	gridInvoices!.setCallback(gridInvoices!.ON_GRID_KEY_PRESS,"custom_event")
	gridInvoices!.setCallback(gridInvoices!.ON_GRID_MOUSE_UP,"custom_event")
	gridInvoices!.setCallback(gridInvoices!.ON_GRID_EDIT_STOP,"custom_event")
[[APE_PAYSELECT.ASIZ]]
rem --- Resize the grid

	if UserObj!<>null() then
		gridInvoices!=UserObj!.getItem(num(user_tpl.gridInvoicesOfst$))
		gridInvoices!.setColumnWidth(0,25)
		gridInvoices!.setColumnWidth(1,50)
		gridInvoices!.setSize(Form!.getWidth()-(gridInvoices!.getX()*2),Form!.getHeight()-(gridInvoices!.getY()+10))
		gridInvoices!.setFitToGrid(1)
	endif
[[APE_PAYSELECT.ACUS]]
rem --- Process custom event
rem --- Select/de-select checkboxes in grid and edit payment and discount amounts

rem This routine is executed when callbacks have been set to run a 'custom event'.
rem Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind of event it is.
rem See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info.

	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ctl_ID=dec(gui_event.ID$)

	if ctl_ID <> num(user_tpl.gridInvoicesCtlID$) then break; rem --- exit callpoint

	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
	endif

	gridInvoices! = UserObj!.getItem(num(user_tpl.gridInvoicesOfst$))
	numcols = gridInvoices!.getNumColumns()
	vectInvoices! = UserObj!.getItem(num(user_tpl.vectInvoicesOfst$))
	vectInvoicesMaster! = UserObj!.getItem(num(user_tpl.vectInvoicesMasterOfst$))
	curr_row = dec(notice.row$)
	curr_col = dec(notice.col$)

	switch notice.code
		case 12; rem --- grid_key_press
			if notice.wparam=32 gosub switch_value
			break

		case 14; rem --- grid_mouse_up
			if notice.col=0 gosub switch_value
			break

		case 7; rem --- edit stop

			apm01_dev = fnget_dev("APM_VENDMAST")
			dim apm01a$:fnget_tpl$("APM_VENDMAST")
			apt01_dev = fnget_dev("APT_INVOICEHDR")
			dim apt01a$:fnget_tpl$("APT_INVOICEHDR")

		rem --- Discount Amount

		if curr_col = 9 then
				ap_type$ = gridInvoices!.getCellText(curr_row,2)
				vend_id$ = gridInvoices!.getCellText(curr_row,3)
				inv_no$ = gridInvoices!.getCellText(curr_row,5)
				inv_amt  = num(gridInvoices!.getCellText(curr_row,8))
				disc_amt = num(gridInvoices!.getCellText(curr_row,9))
				pmt_amt  = num(gridInvoices!.getCellText(curr_row,10))
				retent_amt = num(gridInvoices!.getCellText(curr_row,11))
				gosub get_master_offset
				orig_inv_amt = num(vectInvoicesMaster!.getItem((mast_offset)+16))

				if sgn(disc_amt) <> sgn(orig_inv_amt) then 
					disc_amt = abs(disc_amt) * sgn(orig_inv_amt)
					gridInvoices!.setCellText(curr_row,9,str(disc_amt))
				endif

				if abs(disc_amt) <> abs(orig_inv_amt) - abs(retent_amt) - abs(pmt_amt)
					if pmt_amt=0 or abs(disc_amt) > abs(orig_inv_amt) - abs(retent_amt) - abs(pmt_amt)  then 
						pmt_amt = (abs(orig_inv_amt) - abs(retent_amt) - abs(disc_amt)) * sgn(orig_inv_amt)
						gridInvoices!.setCellText(curr_row,10,str(pmt_amt))
					endif
					inv_amt = orig_inv_amt -  (abs(retent_amt) + abs(disc_amt) + abs(pmt_amt)) * sgn(orig_inv_amt)
					gridInvoices!.setCellText(curr_row,8,str(inv_amt))
				endif

				if disc_amt<>0 or inv_amt<>0 then 
					if gridInvoices!.getCellState(curr_row,0)=0 then
						vend$ = gridInvoices!.getCellText(row_no,3)
						gosub strip_dashes
						read record(apm01_dev, key=firm_id$+
:							vend$, dom=*next) apm01a$

rem --- Following lines removed to allow payment of open invoices for a held vendor
rem						if apm01a.hold_flag$="Y" then 
rem							gridInvoices!.setCellText(curr_row,9,str(0))
rem							gridInvoices!.setCellText(curr_row,10,str(0))
rem							msg_id$="AP_VEND_HOLD"
rem							gosub disp_message
rem							break
rem						endif

						read record(apt01_dev, key=firm_id$+
:							gridInvoices!.getCellText(curr_row,2)+
:							vend$+
:							gridInvoices!.getCellText(curr_row,5), dom=*next) apt01a$

						if apt01a.hold_flag$="Y" then 
							gridInvoices!.setCellText(curr_row,9,str(0))
							gridInvoices!.setCellText(curr_row,10,str(0))
							msg_id$="AP_INV_HOLD"
							gosub disp_message
							break
						endif

						gridInvoices!.setCellState(curr_row,0,1)
						dummy = fn_setmast_flag(
:							vectInvoices!.getItem(curr_row*numcols+2),
:							vectInvoices!.getItem(curr_row*numcols+3),
:							vectInvoices!.getItem(curr_row*numcols+5),
:							"Y",
:							str(pmt_amt)
:						)
					endif
				else
					if gridInvoices!.getCellState(curr_row,0)=1
						gridInvoices!.setCellState(curr_row,0,0)
						dummy = fn_setmast_flag(
:							vectInvoices!.getItem(curr_row*numcols+2),
:							vectInvoices!.getItem(curr_row*numcols+3),
:							vectInvoices!.getItem(curr_row*numcols+5),
:							"N",
:							"0"
:						)
					endif
				endif

				vectInvoices!.setItem(curr_row*num(user_tpl.gridInvoicesCols$)+9,str(disc_amt))
				vectInvoices!.setItem(curr_row*num(user_tpl.gridInvoicesCols$)+10,str(pmt_amt))
				dummy = fn_setmast_amts(
:					vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+2),
:					vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+3),
:					vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+5),
:					str(disc_amt),
:					str(pmt_amt)
:				)
			endif

		rem --- Payment Amount

			if curr_col=10
				ap_type$ = gridInvoices!.getCellText(curr_row,2)
				vend_id$ = gridInvoices!.getCellText(curr_row,3)
				inv_no$ = gridInvoices!.getCellText(curr_row,5)
				inv_amt  = num(gridInvoices!.getCellText(curr_row,8))
				disc_amt = num(gridInvoices!.getCellText(curr_row,9))
				pmt_amt  = num(gridInvoices!.getCellText(curr_row,10))
				retent_amt = num(gridInvoices!.getCellText(curr_row,11))
				gosub get_master_offset
				orig_inv_amt = num(vectInvoicesMaster!.getItem((mast_offset)+16))
					
				if sgn(pmt_amt) <> sgn(orig_inv_amt) then 
					pmt_amt = abs(pmt_amt) * sgn(orig_inv_amt)
					gridInvoices!.setCellText(curr_row,10,str(pmt_amt))
				endif

				if abs(pmt_amt) > abs(orig_inv_amt) - abs(retent_amt) - abs(disc_amt) then 
					pmt_amt = (abs(orig_inv_amt) - abs(retent_amt) - abs(disc_amt)) * sgn(orig_inv_amt)
					gridInvoices!.setCellText(curr_row,10,str(pmt_amt))
				endif

				if pmt_amt=0 then
					rem --- de-select payment
					if gridInvoices!.getCellState(curr_row,0) = 1 then 
						x=curr_row
						gosub switch_value
						curr_row=x
					endif
				else
					if gridInvoices!.getCellState(curr_row,0)=0 then
						vend$ = gridInvoices!.getCellText(row_no,3)
						gosub strip_dashes
						read record (apm01_dev, key=firm_id$+
:							vend$, dom=*next) apm01a$

rem --- Following lines removed to allow payment of open invoices for a held vendor
rem						if apm01a.hold_flag$="Y" then 
rem							gridInvoices!.setCellText(curr_row,9,str(0))
rem							gridInvoices!.setCellText(curr_row,10,str(0))
rem							msg_id$="AP_VEND_HOLD"
rem							gosub disp_message
rem							break
rem						endif

						read record (apt01_dev, key=firm_id$+
:							gridInvoices!.getCellText(curr_row,2)+
:							vend$+
:							gridInvoices!.getCellText(curr_row,5), dom=*next) apt01a$

						if apt01a.hold_flag$="Y" then 
							gridInvoices!.setCellText(curr_row,9,str(0))
							gridInvoices!.setCellText(curr_row,10,str(0))
							msg_id$="AP_INV_HOLD"
							gosub disp_message
							break
						endif

						gridInvoices!.setCellState(curr_row,0,1)
						dummy = fn_setmast_flag(
:							vectInvoices!.getItem(curr_row*numcols+2),
:							vectInvoices!.getItem(curr_row*numcols+3),
:							vectInvoices!.getItem(curr_row*numcols+5),
:							"Y",
:							str(pmt_amt)
:						)
					endif
				endif

				inv_amt = orig_inv_amt -  (abs(retent_amt) + abs(disc_amt) + abs(pmt_amt)) * sgn(orig_inv_amt)
				gridInvoices!.setCellText(curr_row,8,str(inv_amt))
				vectInvoices!.setItem(curr_row*num(user_tpl.gridInvoicesCols$)+9,str(disc_amt))
				vectInvoices!.setItem(curr_row*num(user_tpl.gridInvoicesCols$)+10,str(pmt_amt))
				dummy = fn_setmast_amts(
:					vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+2),
:					vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+3),
:					vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+5),
:					str(disc_amt),
:					str(pmt_amt)
:				)
			endif
		break
	swend
