[[GLT_BANKOTHER.ACUS]]
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

rem --- Update posted_code for selected grid rows
	col=7; rem --- posted_code grid column
	if itemCode$<>"" then
		gltBankOther_dev=fnget_dev("GLT_BANKOTHER")
		dim gltBankOther$:fnget_tpl$("GLT_BANKOTHER")
		selectedRows!=grid!.getSelectedRows()
		if selectedRows!.size=0 then break
		for i=0 to selectedRows!.size()-1
			rem --- Update grid row
			row=selectedRows!.getItem(i)
			grid!.setCellText(row,col,itemText$)

			rem --- Update record on disc
			gltBankOther$=GridVect!.getItem(row)
			gltBankOther.posted_code$=itemCode$
			writerecord(gltBankOther_dev)gltBankOther$
		next i
	endif
[[GLT_BANKOTHER.BSHO]]
rem --- Open/Lock files
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ART_DEPOSIT",open_opts$[1]="OTA@"

	gosub open_tables
	if status$ <> ""  then goto std_exit

rem --- Add pop-up menu to match ListButton items for posted_code
	popUpMenu!=SysGUI!.addPopupMenu()
	ldat$=callpoint!.getTableColumnAttribute("GLT_BANKOTHER.POSTED_CODE","LDAT")
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
[[GLT_BANKOTHER.TRANS_NO.AVAL]]
rem --- Has the trans_no changed?
	trans_no$=callpoint!.getUserInput()
	if callpoint!.getColumnData("GLT_BANKOTHER.TRANS_NO")<>trans_no$ then
		rem --- Is this a Deposit trans_type"
		if callpoint!.getColumnData("GLT_BANKOTHER.TRANS_TYPE")="D" then
			rem --- Prevent re-using an existing DEPOSIT_ID
			deposit_dev=fnget_dev("@ART_DEPOSIT")
			deposit_tpl$=fnget_tpl$("@ART_DEPOSIT")
			deposit_id$=trans_no$
			found_deposit=0
			find(deposit_dev,key=firm_id$+deposit_id$,dom=*next); found_deposit=1
			if found_deposit then
				rem --- Warn DEPOSIT_ID has already been used
				msg_id$="AR_DEPOSIT_USED"
				gosub disp_message
				if msg_opt$="Y" then
					rem --- Assign next new DEPOSIT_ID
					call stbl("+DIR_SYP")+"bas_sequences.bbj","DEPOSIT_ID",deposit_id$,rd_table_chans$[all],"QUIET"
					callpoint!.setUserInput(deposit_id$)
				else
					callpoint!.setStatus("ABORT")
					break
				endif
			endif
		endif
	endif
[[GLT_BANKOTHER.TRANS_TYPE.AVAL]]
rem --- Has the trans_type changed?
	trans_type$=callpoint!.getUserInput()
	if callpoint!.getColumnData("GLT_BANKOTHER.TRANS_TYPE")<>trans_type$ then
		rem --- Is this a Deposit trans_type"
		if trans_type$="D" then
			rem --- Prevent re-using an existing DEPOSIT_ID
			deposit_dev=fnget_dev("@ART_DEPOSIT")
			deposit_tpl$=fnget_tpl$("@ART_DEPOSIT")
			deposit_id$=callpoint!.getColumnData("GLT_BANKOTHER.TRANS_NO")
			found_deposit=0
			find(deposit_dev,key=firm_id$+deposit_id$,dom=*next); found_deposit=1
			if found_deposit then
				rem --- Warn DEPOSIT_ID has already been used
				msg_id$="AR_DEPOSIT_USED"
				gosub disp_message
				if msg_opt$="Y" then
					rem --- Assign next new DEPOSIT_ID
					call stbl("+DIR_SYP")+"bas_sequences.bbj","DEPOSIT_ID",deposit_id$,rd_table_chans$[all],"QUIET"
					callpoint!.setColumnData("GLT_BANKOTHER.TRANS_NO",deposit_id$,1)
				else
					callpoint!.setStatus("ABORT")
					break
				endif
			endif

			rem --- Endisable the Cash Receipt Code column when the TRANS_TYPE=D.
			callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"GLT_BANKOTHER.CASH_REC_CD",1)
		else
			rem --- Clear and disable the Cash Receipt Code column when the TRANS_TYPE<>D.
			callpoint!.setColumnData("GLT_BANKOTHER.CASH_REC_CD","",1)
			callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"GLT_BANKOTHER.CASH_REC_CD",0)
		endif
	endif
