[[GLT_BANKCHECKS.ACUS]]
rem --- Process custom event

rem --- Handle grid pop-up menu selections
	dim gui_event$:tmpl(gui_dev)
	gui_event$=SysGUI!.getLastEventString()
	grid!=Form!.getControl(num(stbl("+GRID_CTL")))

	rem --- Verify event from grid
	if dec(gui_event.ID$) <> grid!.getID() then break; rem --- exit callpoint

	rem --- Get selected pop-up menu item
	popUpMenu!=grid!.getPopupMenu()
	menuItem!=popUpMenu!.getMenuItem(gui_event.y)
	itemText$=menuItem!.getText()
	tmpText$=itemText$+"( )"
	itemCode$=tmpText$(pos("("=tmpText$)+1)
	itemCode$=itemCode$(1,pos(")"=itemCode$)-1)
	item=gui_event.y-200

rem --- Update paid_code for selected grid rows
	col=5; rem --- paid_code grid column
	if itemCode$<>"" then
		gltBankChecks_dev=fnget_dev("GLT_BANKCHECKS")
		dim gltBankChecks$:fnget_tpl$("GLT_BANKCHECKS")
		selectedRows!=grid!.getSelectedRows()
		if selectedRows!.size=0 then break
		for i=0 to selectedRows!.size()-1
			rem --- Update grid row
			row=selectedRows!.getItem(i)
			rem --- Check if current row and update "classically" if so
			if row=callpoint!.getValidationRow() then
				if callpoint!.getColumnData("GLT_BANKCHECKS.PAID_CODE")<>itemCode$ then
					callpoint!.setColumnData("GLT_BANKCHECKS.PAID_CODE",itemCode$,1)
					callpoint!.setStatus("MODIFIED")
				endif
			else
				grid!.setCellListSelection(row,col,item,1)
				rem --- Update record image, if necessary
 				gltBankChecks$=GridVect!.getItem(row)
				if gltBankChecks.paid_code$<>itemCode$ then
 					gltBankChecks.paid_code$=itemCode$
					GridVect!.setItem(row,gltBankChecks$)
					rem --- Set row as modified (disk icon)
					callpoint!.setGridRowModifyStatus(row,1)
				endif
			endif
		next i
	endif
[[GLT_BANKCHECKS.BSHO]]
rem --- Add pop-up menu to match ListButton items for paid_code
	popUpMenu!=SysGUI!.addPopupMenu()
	ldat$=callpoint!.getTableColumnAttribute("GLT_BANKCHECKS.PAID_CODE","LDAT")
	item=0
	xpos=pos(";"=ldat$)
	while xpos
		item$=ldat$(1,xpos-1)
		ldat$=ldat$(xpos+1)
		ypos=pos("~"=item$)
		desc$=cvs(item$(1,ypos-1),3)
		code$=cvs(item$(ypos+1),3)

		menuItem! = popUpMenu!.addMenuItem(-(200+item),desc$+" ("+code$+")")
		menuItem!.setCallback(menuItem!.ON_POPUP_ITEM_SELECT,"custom_event")
	
		item=item+1
		xpos=pos(";"=ldat$)
	wend

rem --- Make grid multi-select with pop-up menu
	grid!=Form!.getControl(num(stbl("+GRID_CTL")))
	grid!.setMultipleSelection(1)
	grid!.setSelectionMode(grid!.GRID_SELECT_ROW)
	grid!.setPopupMenu(popUpMenu!)
[[GLT_BANKCHECKS.CHECK_NO.AVEC]]
callpoint!.setColumnData("GLT_BANKCHECKS.CHECK_TYPE","E")
callpoint!.setColumnData("GLT_BANKCHECKS.PAID_CODE","O")
callpoint!.setStatus("REFRESH")
