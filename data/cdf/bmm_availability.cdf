[[BMM_AVAILABILITY.WAREHOUSE_ID.AVAL]]
rem --- Refill grid

	wh$=callpoint!.getUserInput()
	qty_req=num(callpoint!.getColumnData("BMM_AVAILABILITY.QTY_REQUIRED"))
	prod_date$=callpoint!.getColumnData("BMM_AVAILABILITY.PROD_DATE")
	gosub create_reports_vector
	gosub fill_grid
[[BMM_AVAILABILITY.QTY_REQUIRED.AVAL]]
rem --- Refill grid

	wh$=callpoint!.getColumnData("BMM_AVAILABILITY.WAREHOUSE_ID")
	qty_req=num(callpoint!.getUserInput())
	prod_date$=callpoint!.getColumnData("BMM_AVAILABILITY.PROD_DATE")
	gosub create_reports_vector
	gosub fill_grid
[[BMM_AVAILABILITY.PROD_DATE.AVAL]]
rem --- Refill grid

	wh$=callpoint!.getColumnData("BMM_AVAILABILITY.WAREHOUSE_ID")
	qty_req=num(callpoint!.getColumnData("BMM_AVAILABILITY.QTY_REQUIRED"))
	prod_date$=callpoint!.getUserInput()
	gosub create_reports_vector
	gosub fill_grid
[[BMM_AVAILABILITY.<CUSTOM>]]
rem ==========================================================================
format_grid: rem --- Use Barista program to format the grid
rem ==========================================================================

	call stbl("+DIR_PGM")+"adc_getmask.aon","","IV","U","",m1$,0,0

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0] = callpoint!.getColumnAttributeTypes()
	def_cols = num(user_tpl.gridCols$)
	num_rpts_rows = num(user_tpl.gridRows$)
	dim attr_col$[def_cols,len(attr_def_col_str$[0,0])/5]

	attr_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SEQ"
	attr_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Seq"
	attr_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="40"

	attr_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="OVERAGE"
	attr_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Over"
	attr_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="40"
	attr_col$[2,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="1"

	attr_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SUB_BILL"
	attr_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Sub"
	attr_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="40"
	attr_col$[3,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="1"

	attr_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ITEM"
	attr_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Item"
	attr_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="120"

	attr_col$[5,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DESC"
	attr_col$[5,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Desc"
	attr_col$[5,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="200"

	attr_col$[6,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="QTY_REQ"
	attr_col$[6,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Qty Req'd"
	attr_col$[6,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_col$[6,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="70"
	attr_col$[6,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_col$[7,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ON_HAND"
	attr_col$[7,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="On Hand"
	attr_col$[7,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_col$[7,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="70"
	attr_col$[7,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_col$[8,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="COMMIT"
	attr_col$[8,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Committed"
	attr_col$[8,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_col$[8,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="70"
	attr_col$[8,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_col$[9,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="AVAIL"
	attr_col$[9,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Available"
	attr_col$[9,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_col$[9,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="70"
	attr_col$[9,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_col$[10,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ONORD"
	attr_col$[10,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="On Order"
	attr_col$[10,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_col$[10,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="70"
	attr_col$[10,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	for curr_attr=1 to def_cols
		attr_col$[0,1] = attr_col$[0,1] + 
:			pad("BMM_AVAILABILITY." + attr_col$[curr_attr, fnstr_pos("DVAR", attr_def_col_str$[0,0], 5)], 40)
	next curr_attr

	attr_disp_col$=attr_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridAvail!,"COLH-LINES-LIGHT-AUTO",num_rpts_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_col$[all]
	gridAvail!.setFitToGrid(gridAvail!.AUTO_RESIZE_LAST_COLUMN)

	gridAvail!.setEditable(0)

	return

rem ==========================================================================
create_reports_vector: rem --- Create a vector from the file to fill the grid
rem --- wh$: input
rem --- qty_req: input
rem --- prod_date$: input
rem ==========================================================================

	vectAvail! = BBjAPI().makeVector()

	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm01$:fnget_tpl$("IVM_ITEMMAST")
	ivm02_dev=fnget_dev("IVM_ITEMWHSE")
	dim ivm02$:fnget_tpl$("IVM_ITEMWHSE")
	bmm02_dev=fnget_dev("BMM_BILLMAT")
	dim bmm02$:fnget_tpl$("BMM_BILLMAT")
	bmm01_dev=fnget_dev("BMM_BILLMAST")

	yield_pct=callpoint!.getDevObject("yield")

	item$=callpoint!.getDevObject("master_bill")
	read (bmm02_dev,key=firm_id$+item$,dom=*next)
	rows=0

	while 1
		read record (bmm02_dev, end=*break) bmm02$
		if pos(firm_id$+item$=bmm02$)<>1 then break
		if bmm02.line_type$<>"S" continue
		if cvs(bmm02.effect_date$,2)<>"" and bmm02.effect_date$>prod_date$ continue
		if cvs(bmm02.obsolt_date$,2)<>"" and bmm02.obsolt_date$<prod_date$ continue

		rem --- Now fill vectors

		read record(ivm02_dev,key=firm_id$+wh$+bmm02.item_id$,dom=*next) ivm02$
		dim ivm01$:fattr(ivm01$)
		find record(ivm01_dev,key=firm_id$+bmm02.item_id$,dom=*next) ivm01$
		avail=ivm02.qty_on_hand-ivm02.qty_commit
		net_qty=BmUtils.netQuantityRequired(bmm02.qty_required,bmm02.alt_factor,bmm02.divisor,yield_pct,bmm02.scrap_factor)
		sub_bill$=""
		read record(bmm01_dev,key=firm_id$+bmm02.item_id$,dom=*next);sub_bill$="*"

		vectAvail!.addItem(bmm02.material_seq$);rem 0

		if avail>=net_qty*qty_req
			vectAvail!.addItem(" ")
		else
			vectAvail!.addItem("*")
		endif
		vectAvail!.addItem(sub_bill$); rem 2 - Sub Bill flag
		vectAvail!.addItem(bmm02.item_id$); rem 3
		vectAvail!.addItem(ivm01.item_desc$); rem 4 - Description
		vectAvail!.addItem(str(net_qty*qty_req)); rem 5 - Qty Req'd
		vectAvail!.addItem(str(ivm02.qty_on_hand)); rem 6 - On Hand
		vectAvail!.addItem(str(ivm02.qty_commit)); rem 7 - Committed
		vectAvail!.addItem(str(avail)); rem 8 - Available
		vectAvail!.addItem(str(ivm02.qty_on_order)); rem 9 - On Order

		rows=rows+1
	wend

	callpoint!.setStatus("REFRESH")
	
	return

rem ==========================================================================
fill_grid: rem --- Fill the grid with data in vectAvail!
rem ==========================================================================

	SysGUI!.setRepaintEnabled(0)
	gridAvail! = UserObj!.getItem(num(user_tpl.gridOfst$))
	minrows = num(user_tpl.gridRows$)

	if vectAvail!.size() then
		numrow = vectAvail!.size() / gridAvail!.getNumColumns()
		gridAvail!.clearMainGrid()
		gridAvail!.setNumRows(numrow)
		gridAvail!.setCellText(0,0,vectAvail!)
		gridAvail!.resort()
	else
		gridAvail!.clearMainGrid()
		gridAvail!.setNumRows(0)
	endif

	SysGUI!.setRepaintEnabled(1)

	return

rem ===================================================================
calc_net:
rem --- qty_req:		input
rem --- alt_fact:			input
rem --- divisor:			input
rem --- scrap_fact:		input
rem ===================================================================

	yield_pct=callpoint!.getDevObject("yield")
	net_qty=BmUtils.netQuantityRequired(qty_req,alt_fact,divisor,yield_pct,scrap_fact)

	return
[[BMM_AVAILABILITY.ASIZ]]
rem --- Resize the grid
break
	if UserObj!<>null() then
		gridAvail!=UserObj!.getItem(num(user_tpl.gridOfst$))
		gridAvail!.setColumnWidth(0,10)
		gridAvail!.setColumnWidth(1,50)
		gridAvail!.setSize(Form!.getWidth()-(gridAvail!.getX()*2),Form!.getHeight()-(gridAvail!.getY()+10))
		gridAvail!.setFitToGrid(1)
	endif
[[BMM_AVAILABILITY.AWIN]]
rem --- Open/Lock files

	use ::bmo_BmUtils.aon::BmUtils
	declare BmUtils bmUtils!

	use ::ado_util.src::util
	use ::ado_func.src::func

	num_files=4
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="IVM_ITEMMAST",open_opts$[1]="OTA"
	open_tables$[2]="IVM_ITEMWHSE",open_opts$[2]="OTA"
	open_tables$[3]="BMM_BILLMAT",open_opts$[3]="OTA"
	open_tables$[4]="BMM_BILLMAT",open_opts$[4]="OTA"

	gosub open_tables

rem --- Add grid to store Availability

	user_tpl_str$ = "gridOfst:c(5), " +
:		"gridCols:c(5), " +
:		"gridRows:c(5), " +
:		"gridCtlID:c(5)," +
:		"vectOfst:c(5)"
	dim user_tpl$:user_tpl_str$

	UserObj! = BBjAPI().makeVector()

	nxt_ctlID = util.getNextControlID()
	gridAvail! = Form!.addGrid(nxt_ctlID,10,100,800,280); rem --- ID, x, y, width, height

	user_tpl.gridCtlID$ = str(nxt_ctlID)
	user_tpl.gridCols$ = "10"
	user_tpl.gridRows$ = "10"

	gosub format_grid
	util.resizeWindow(Form!, SysGui!)

	UserObj!.addItem(gridAvail!)
	user_tpl.gridOfst$="0"

	UserObj!.addItem(vectAvail!); rem --- vector of recs
	user_tpl.vectOfst$="1"

rem --- Misc other init

	gridAvail!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)
	gridAvail!.setTabAction(gridAvail!.GRID_NAVIGATE_GRID)

	wh$=callpoint!.getDevObject("dflt_whse")
	qty_req=1
	prod_date$=stbl("+SYSTEM_DATE")
	gosub create_reports_vector
	gosub fill_grid
