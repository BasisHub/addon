[[IVE_PHYSICALCAN.AREC]]
rem --- Display default warehouse ID, if any

	if user_tpl.whse_id$ <> "" then
		callpoint!.setColumnData("IVE_PHYSICALCAN.WAREHOUSE_ID", user_tpl.whse_id$)
	endif
	
[[IVE_PHYSICALCAN.ASVA]]
rem --- Check for values in warehouse and cutoff date

	whse$   = callpoint!.getColumnData("IVE_PHYSICALCAN.WAREHOUSE_ID")

	if whse$ = "" then
		callpoint!.setMessage("IV_NEED_WAREHOUSE")
		callpoint!.setStatus("ABORT")
		goto asva_end
	endif

rem --- Roll thru grid rows, saving the pending action of checked records

	grid! = callpoint!.getDevObject("grid_object")
	file_name$ = "IVC_PHYSCODE"
	physcode_dev = fnget_dev(file_name$)
	dim physcode_rec$:fnget_tpl$(file_name$)

	nothing_checked = 1
	selected_all = 1
	more = 1
	
	read (physcode_dev, key=firm_id$+whse$, dom=*next)
	
	while more 
	
		physcode_key$ = key(physcode_dev, end=*break)
		if pos(firm_id$+whse$ = physcode_key$) <> 1 then break
		read record (physcode_dev) physcode_rec$

		if physcode_rec.phys_inv_sts$ = "0" then 
			selected_all = 0
			continue
		endif
		
		found = 0
		
		for row = 0 to grid!.getNumRows() - 1
			if grid!.getCellText(row, 2) = physcode_rec.pi_cyclecode$ then
				found = 1
				break
			endif
		next row
		
		if found and grid!.getCellState(row, 0) then
			physcode_rec.pending_action$ = "5"
			nothing_checked = 0
		else
			physcode_rec.pending_action$ = "0"
			selected_all = 0
		endif
		
		physcode_rec$ = field(physcode_rec$)
		write record (physcode_dev) physcode_rec$
		
	wend

	if nothing_checked then
		callpoint!.setMessage("IV_PI_NONE_SELECTED")
		callpoint!.setStatus("ABORT")
		goto asva_end
	endif

	callpoint!.setDevObject("IVE_PHYSICALCAN.SELECTED_ALL", selected_all)

asva_end:
[[IVE_PHYSICALCAN.ACUS]]
rem --- Process custom event -- used in this section to select/de-select checkboxes in grid
rem --- See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info
rem --- This routine is executed when callbacks have been set to run a 'custom event'
rem --- Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind
rem --- of event it is.  In this case, we're toggling checkboxes on/off in form grid control

	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$ = SysGUI!.getLastEventString()
	this_id    = dec(gui_event.ID$)
	grid!      = callpoint!.getDevObject("grid_object")
	cycleData! = cast(BBjVector, callpoint!.getDevObject("cycle_data"))

	rem --- Is this even for the grid?
	if this_id = user_tpl.grid_id then 

		rem --- Notify events
		if gui_event.code$ = "N" then
			notify_base$ = notice(gui_dev, gui_event.x%)
			dim notice$:noticetpl(notify_base.objtype%, gui_event.flags%)
			notice$  = notify_base$
			this_row = notice.row
			this_col = notice.col
			this_action$ = str( cycleData!.getItem( this_row * 4 + this_col ) )

			rem --- Don't change a record with a panding action of 5 (delete)
			if this_action$ <> "5" then

				switch notice.code

					rem --- Mouse click
					case 14
						if this_col = 0 then gosub toggle_checkbox
						break

					rem --- Key press
					case 12

						rem --- Space bar
						if notice.wparam=32 then gosub toggle_selected
						break

				swend

			endif
		endif
	endif
	
[[IVE_PHYSICALCAN.WAREHOUSE_ID.AVAL]]
rem --- Filter grid on selected warehouse

	whse$ = callpoint!.getUserInput()

	if callpoint!.getColumnUndoData("IVE_PHYSICALCAN.WAREHOUSE_ID") <> whse$ then
		user_tpl.whse_changed = 1
	endif

	gosub fill_grid
	
[[IVE_PHYSICALCAN.AWIN]]
rem print 'show',; rem debug

rem --- Inits

	use ::ado_util.src::util

	dim user_tpl$:"grid_id:u(2), whse_id:c(2), whse_changed:u(1)"
	more = 1
	user_tpl.whse_changed = 0

rem --- Open files

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVC_PHYSCODE", open_opts$[1]="OTA"; rem "open_opts$[1]="OTAL" - bug 4276 - IV File Locking"

	gosub open_tables

	physcode_dev = num(open_chans$[1])
	dim physcode_rec$:open_tpls$[1]

rem --- Display grid

	gosub create_grid
	util.resizeWindow(Form!, SysGui!)
	gosub get_data
	whse$ = user_tpl.whse_id$
	gosub fill_grid

rem --- Set callbacks - processed in ACUS callpoint

	grid!.setCallback(grid!.ON_GRID_KEY_PRESS,"custom_event")
	grid!.setCallback(grid!.ON_GRID_MOUSE_UP, "custom_event")
	
[[IVE_PHYSICALCAN.<CUSTOM>]]
rem ==========================================================================
create_grid: rem --- Create grid
             rem     OUT: grid_id, global in user_tpl.grid_id
             rem          grid!,   global in DevObject("grid_object)
rem ==========================================================================

	grid_id = num( stbl("+CUSTOM_CTL") )
	ignore$ = stbl( "+CUSTOM_CTL", str( grid_id+1 ) )
	user_tpl.grid_id = grid_id

	grid_x = 10
	grid_y = 45
	grid_w = 400
	grid_h = 212
	grid! = Form!.addGrid(grid_id, grid_x, grid_y, grid_w, grid_h)
	callpoint!.setDevObject("grid_object", grid!)

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0] = callpoint!.getColumnAttributeTypes()
	def_inv_cols  = 4
	num_rpts_rows = 10

	dim attr_inv_col$[ def_inv_cols, len(attr_def_col_str$[0,0]) / 5 ]

	attr_inv_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SELECT"
	attr_inv_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=""
	attr_inv_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"
	attr_inv_col$[1,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="1"
	attr_inv_col$[1,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="C"

	attr_inv_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="WAREHOUSE_ID"
	attr_inv_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="WH"
	attr_inv_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"

	attr_inv_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="PI_CYCLECODE"
	attr_inv_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_CYCLE")
	attr_inv_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"

	attr_inv_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DESCRIPTION"
	attr_inv_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DESCRIPTION")
	attr_inv_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="150"

	for curr_attr=1 to def_inv_cols
		attr_inv_col$[0,1] = attr_inv_col$[0,1] + 
:			pad("APT_PAY." + attr_inv_col$[curr_attr, fnstr_pos("DVAR", attr_def_col_str$[0,0], 5)], 40)
	next curr_attr

	attr_disp_col$ = attr_inv_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",
:		gui_dev,
:		grid!,
:		"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC-CHECKS",
:		num_rpts_rows,
:		attr_def_col_str$[all],
:		attr_disp_col$,
:		attr_inv_col$[all]

	return

rem ==========================================================================
get_data: rem --- Get cycle data
          rem      IN: physcode_dev
          rem          physcode_rec$
          rem     OUT: cycleData!, global in setDevObject("cycle_data")
          rem          user_tpl.cutoff_default$
          rem          user_tpl.whse_id$
rem ==========================================================================

	declare BBjVector cycleData!
	cycleData! = BBjAPI().makeVector()

	read (physcode_dev, key=firm_id$, dom=*next)

	while more

		read record (physcode_dev, end=*break) physcode_rec$
		if physcode_rec.firm_id$ <> firm_id$ then break

		if physcode_rec.phys_inv_sts$ <> "0" then 
			cycleData!.addItem(physcode_rec.pending_action$)
			cycleData!.addItem(physcode_rec.warehouse_id$)
			cycleData!.addItem(physcode_rec.pi_cyclecode$)
			cycleData!.addItem(physcode_rec.description$)

			if physcode_rec.pending_action$ = "5" then 
				user_tpl.whse_id$ = physcode_rec.warehouse_id$
			endif

		endif

	wend

	callpoint!.setDevObject("cycle_data", cycleData!)

	return

rem ==========================================================================
fill_grid: rem --- Fill grid with data from a vector
           rem      IN: whse$ - warehouse to filter on, or null
rem ==========================================================================

	SysGUI!.setRepaintEnabled(0)
	grid!      = callpoint!.getDevObject("grid_object")
	cycleData! = cast(BBjVector, callpoint!.getDevObject("cycle_data"))

	if cycleData!.size() then 

		no_of_cells = cycleData!.size()
		no_of_cols  = grid!.getNumColumns()
		no_of_rows  = no_of_cells / no_of_cols

		grid!.clearMainGrid()
		grid!.setNumRows(no_of_rows)

		row = -1

		for i=0 to no_of_cells - 1 step no_of_cols
			if cvs(whse$,2) = "" or cycleData!.getItem(i+1) = whse$ then 
				row = row + 1

				rem --- Checkbox
				if cycleData!.getItem(i) = "5" or 
:					( grid!.getCellState(row, 0) and user_tpl.whse_changed = 0 )
:				then 
					grid!.setCellStyle(row, 0, SysGUI!.GRID_STYLE_CHECKED)
					if cycleData!.getItem(i) = "5" then util.disableGridCell( cast(BBjStandardGrid, grid!), 0, row)
				else
					grid!.setCellStyle(row, 0, SysGUI!.GRID_STYLE_UNCHECKED)
				endif

				grid!.setCellText(row, 0, "")

				rem --- Warehouse
				grid!.setCellText(row, 1, cycleData!.getItem(i+1))

				rem --- Cycle
				grid!.setCellText(row, 2, cycleData!.getItem(i+2))

				rem --- Descr
				grid!.setCellText(row, 3, cycleData!.getItem(i+3))

			endif
		next i

		grid!.setNumRows(row+1)
		rem grid!.resort()

	else

		grid!.clearMainGrid()
		grid!.setColumnStyle(0, SysGUI!.GRID_STYLE_UNCHECKED)
		grid!.setNumRows(0)

	endif

	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
toggle_checkbox: rem --- Toggle the grid checkbox (checked/unchecked)
                 rem      IN: grid! - grid object
                 rem          this_row - toggle checkbox on this row
                 rem          column zero is assumed
rem ==========================================================================

	if grid!.getCellState(this_row, 0) = 0 then 
		grid!.setCellState(this_row, 0, 1)
	else
		grid!.setCellState(this_row, 0, 0)
	endif

	return

rem ==========================================================================
toggle_selected: rem --- Toggle the checkbox on all select grid rows
                 rem      IN: grid! - grid object
                 rem          column zero is assumed
rem ==========================================================================

	declare BBjVector rows!
	rows! = cast(BBjVector, grid!.getSelectedRows())
	state = -1

	rem --- Roll thru selected rows
	rem --- Toggle the first row, then set all rows to that state

	for i = 0 to rows!.size() - 1
		row = num( rows!.getItem(i) )
		if state = -1 then state = !( grid!.getCellState(row, 0) )
		grid!.setCellState(row, 0, state)
	next i

	return
