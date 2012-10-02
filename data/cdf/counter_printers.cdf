[[COUNTER_PRINTERS.<CUSTOM>]]
rem ==========================================================================
create_grid: rem --- Create grid
             rem     OUT: grid_id, global in user_tpl.grid_id
             rem          grid!,   global in DevObject("grid_object)
rem ==========================================================================

	grid_id = num( stbl("+CUSTOM_CTL") )
	ignore$ = stbl( "+CUSTOM_CTL", str( grid_id+1 ) )
	user_tpl.grid_id = grid_id

	grid_x = 130
	grid_y = 180
	grid_w = 400
	grid_h = 212
	grid! = Form!.addGrid(grid_id, grid_x, grid_y, grid_w, grid_h)
	callpoint!.setDevObject("grid_object", grid!)

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0] = callpoint!.getColumnAttributeTypes()
	def_inv_cols  = 2
	num_rpts_rows = 10

	dim attr_inv_col$[ def_inv_cols, len(attr_def_col_str$[0,0]) / 5 ]

	attr_inv_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="PRINTER_NAME"
	attr_inv_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_PRINTER_NAME")
	attr_inv_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="150"

	attr_inv_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="CLIENT_SERVER"
	attr_inv_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_WHERE?")
	attr_inv_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="30"

	for curr_attr=1 to def_inv_cols
		attr_inv_col$[0,1] = attr_inv_col$[0,1] + 
:			pad("COUNTER_PRINTERS." + attr_inv_col$[curr_attr, fnstr_pos("DVAR", attr_def_col_str$[0,0], 5)], 40)
	next curr_attr

	attr_disp_col$ = attr_inv_col$[0,1]

	call stbl("+DIR_PGM")+"adx_typesafe.aon::grid_init",
:		gui_dev,
:		grid!,
:		"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC-CHECKS",
:		num_rpts_rows,
:		attr_def_col_str$[all],
:		attr_disp_col$,
:		attr_inv_col$[all]

	return

rem ==========================================================================
is_name_in_grid: rem --- Is this printer name in the grid?
                 rem      IN: printer_name$
                 rem     OUT: name_is_in_grid - true/false
                 rem          grid_row
rem ==========================================================================

	name_is_in_grid = 0

	for i=0 to user_tpl.last_grid_row - 1
		if grid!.getCellText(i, 0) = printer_name$ then
			name_is_in_grid = 1
			grid_row = i
			break
		endif
	next i

	return
[[COUNTER_PRINTERS.ACUS]]
rem --- Interpret Events

	grid!      = callpoint!.getDevObject("grid_object")
	client_lb! = callpoint!.getDevObject("client_lb")
	server_lb! = callpoint!.getDevObject("server_lb")
	lastEvent! = BBjAPI().getLastEvent()
	control!   = lastEvent!.getControl()

rem --- Double-click on grid

	if control! = grid! then
		row = lastEvent!.getRow()
		printer_name$  = grid!.getCellText(row, 0)

		if cvs(printer_name$, 2) <> "" then
			client_server$ = grid!.getCellText(row, 1)
			callpoint!.setColumnData("COUNTER_PRINTERS.SELECTED_PRINTER", cvs(printer_name$, 2) + ": " + client_server$)
		endif
	else

	rem --- Double-click on client listbox

		if control! = client_lb! then 
			lb_index% = client_lb!.getSelectedIndex()

			if lb_index% >= 0 then
				printer_name$ = str( client_lb!.getItemAt(lb_index%) )
				gosub is_name_in_grid

				if name_is_in_grid
					grid!.deleteRow(grid_row)
					user_tpl.last_grid_row = user_tpl.last_grid_row - 1
				else
					grid!.setCellText(user_tpl.last_grid_row, 0, printer_name$)
					grid!.setCellText(user_tpl.last_grid_row, 1, Translate!.getTranslation("AON_CLIENT"))
					user_tpl.last_grid_row = user_tpl.last_grid_row + 1
				endif
			endif
		else

		rem --- Double-click on server listbox

			if control! = server_lb! then
				lb_index% = client_lb!.getSelectedIndex()

				if lb_index% >= 0 then
					printer_name$ = str( server_lb!.getItemAt(lb_index%) )
					gosub is_name_in_grid

					if name_is_in_grid
						grid!.deleteRow(grid_row)
						user_tpl.last_grid_row = user_tpl.last_grid_row - 1	
					else				
						grid!.setCellText(user_tpl.last_grid_row, 0, printer_name$)
						grid!.setCellText(user_tpl.last_grid_row, 1, Translate!.getTranslation("AON_SERVER"))
						user_tpl.last_grid_row = user_tpl.last_grid_row + 1
					endif
				endif
			endif
		endif
	endif

	callpoint!.setStatus("REFRESH")
[[COUNTER_PRINTERS.AWIN]]
rem --- Inits

	use ::ado_util.src::util

	use javax.print.attribute
	use javax.print.attribute.standard

	dim user_tpl$:"grid_id:u(2), last_grid_row:u(2)"
	user_tpl.last_grid_row = 0
	client = 0
	server = 1

	declare auto BBjListBox        client_lb!
	declare auto BBjListBox        server_lb!
	declare      BBjVector         clientPrinters!
	declare      BBjVector         serverPrinters!
	declare      BBjTopLevelWindow Form!
	declare      BBjSysGui         SysGui!
	declare auto BBjStandardGrid   grid!
	declare auto BBjControl        control!

	declare javax.print.attribute.HashPrintServiceAttributeSet printerAttributes!

rem --- Get list box controls

	client_lb! = util.getControl(callpoint!, "COUNTER_PRINTERS.CLIENT_PRINTERS")
	client_lb!.setSize(200, 100)
	callpoint!.setDevObject("client_lb", client_lb!)
	server_lb! = util.getControl(callpoint!, "COUNTER_PRINTERS.SERVER_PRINTERS")
	server_lb!.setSize(200, 100)
	callpoint!.setDevObject("server_lb", server_lb!)

rem --- List client printers
	
	start_block = 1

	if start_block then
		printerAttributes! = new attribute.HashPrintServiceAttributeSet()
		printerAttributes!.add(standard.PrinterIsAcceptingJobs.ACCEPTING_JOBS)
		clientPrinters! = BBjAPI().lookupPrinters(printerAttributes!, client, err=*endif)

		for i=0 to clientPrinters!.size() - 1
    		client_lb!.addItem( str(clientPrinters!.get(i)) )
		next i
	endif

rem --- List server printers
	
	start_block = 1

	if start_block then
		printerAttributes! = new attribute.HashPrintServiceAttributeSet()
		printerAttributes!.add(standard.PrinterIsAcceptingJobs.ACCEPTING_JOBS)
		serverPrinters! = BBjAPI().lookupPrinters(printerAttributes!, server, err=*endif)

		for i=0 to serverPrinters!.size() - 1
			add_printer = 1

			for j=0 to clientPrinters!.size() - 1
				if serverPrinters!.get(i) = clientPrinters!.get(j) then
					add_printer = 0
					break
				endif
			next j

    		if add_printer then server_lb!.addItem( str(serverPrinters!.get(i)) )
		next i
	endif

rem --- Set Callbacks

	client_lb!.setCallback(client_lb!.ON_LIST_DOUBLE_CLICK, "custom_event")
	server_lb!.setCallback(server_lb!.ON_LIST_DOUBLE_CLICK, "custom_event")

rem --- Create grid

	gosub create_grid
	util.resizeWindow(Form!, Sysgui!)

rem --- Set Grid Callbacks

	grid!.setCallback(grid!.ON_GRID_DOUBLE_CLICK, "custom_event")
