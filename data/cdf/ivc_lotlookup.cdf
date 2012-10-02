[[IVC_LOTLOOKUP.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVC_LOTLOOKUP.AWIN]]
rem --- open files

	use ::ado_util.src::util
	use ::ado_func.src::func

	num_files=4
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APM_VENDMAST", open_opts$[1]="OTA"
	open_tables$[2]="IVM_LSMASTER", open_opts$[2]="OTA"
	rem open_tables$[3]="APS_PARAMS",   open_opts$[3]="OTA"
	open_tables$[4]="IVS_PARAMS",   open_opts$[4]="OTA"

	gosub open_tables

	apm_vendmast_dev=num(open_chans$[1]); dim apm_vendmast$:open_tpls$[1]
	ivm_lsmaster_dev=num(open_chans$[2]); dim ivm_lsmaster$:open_tpls$[2]
	rem aps_params_dev=num(open_chans$[3]);   dim aps_params$:open_tpls$[3]
	ivs_params_dev=num(open_chans$[4]);   dim ivs_params$:open_tpls$[4]

rem --- Retrieve parameter records

    rem find record (aps_params_dev,key=firm_id$+"AP00",err=std_missing_params) aps_params$
    find record (ivs_params_dev,key=firm_id$+"IV00",err=std_missing_params) ivs_params$

rem --- Parameters

    dim p[5]   
    if pos(ivs_params.lotser_flag$="SL")=0 goto std_exit
    p[0]=num(ivs_params.item_id_len$)
    p[1]=num(ivs_params.vendor_prd_len$)
    p[3]=num(ivs_params.ls_no_len$)
    p[2]=num(ivs_params.desc_len_01$)
    p[4]=num(ivs_params.desc_len_02$)
    p[5]=num(ivs_params.desc_len_03$)
    call stbl("+DIR_PGM")+"adc_application.aon","AP",info$[all]
    callpoint!.setDevObject("ap_installed",info$[20])

rem ---  Set up grid

	dims_tmpl$ = "x:u(2),y:u(2),w:u(2),h:u(2)"
	dim g$:dims_tmpl$
	g.x = 10, g.y = 75, g.w = 300, g.h = 220
	callpoint!.setDevObject("dims_tmpl", dims_tmpl$)
	callpoint!.setDevObject("grid_dims", g$)

	nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))
	gridLots!=Form!.addGrid(nxt_ctlID, g.x, g.y, g.w, g.h)
	gridLots!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)

	gridLots!.setColumnEditable(0,0)
	gridLots!.setColumnEditable(1,0)

	gridLots!.setCallback(gridLots!.ON_GRID_MOUSE_UP,"custom_event")
	gridLots!.setCallback(gridLots!.ON_GRID_SELECT_ROW,"custom_event")

	callpoint!.setDevObject("gridLots",gridLots!)

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()
	def_grid_cols=2
	num_rows=10
	dim attr_grid_col$[def_grid_cols,len(attr_def_col_str$[0,0])/5]

	dvar_pos = fnstr_pos("DVAR", attr_def_col_str$[0,0], 5)
	labs_pos = fnstr_pos("LABS", attr_def_col_str$[0,0], 5)
	ctlw_pos = fnstr_pos("CTLW", attr_def_col_str$[0,0], 5)
	
	attr_grid_col$[1,dvar_pos]="LOT NO"
	attr_grid_col$[1,labs_pos]=Translate!.getTranslation("AON_LOT/SERIAL_NO")
	attr_grid_col$[1,ctlw_pos]="125"

	attr_grid_col$[2,dvar_pos]="STATUS"
	attr_grid_col$[2,labs_pos]=Translate!.getTranslation("AON_STATUS")
	attr_grid_col$[2,ctlw_pos]="125"	
	
	for curr_attr=1 to def_grid_cols
		attr_grid_col$[0,1] = attr_grid_col$[0,1] + 
:			pad( "IVC_LOTLOOKUP." + attr_grid_col$[curr_attr, dvar_pos], 40 )
	next curr_attr

	attr_disp_col$=attr_grid_col$[0,1]
	
	call stbl("+DIR_SYP")+"bam_grid_init.bbj",
:		gui_dev,
:		gridLots!,
:		"LINES",
:		num_rows,
:		attr_def_col_str$[all],
:		attr_disp_col$,
:		attr_grid_col$[all]

rem --- Create Lot Information window			
		
	dim w$:dims_tmpl$
	w.x = 330, w.y = 65, w.w = 400, w.h = 225
	callpoint!.setDevObject("child_window_dims", w$)

	cxt=SysGUI!.getAvailableContext()
	lotWin!=form!.addChildWindow(15000, w.x, w.y, w.w, w.h, "", $00000800$, cxt)
	SysGUI!.setContext(cxt)

	lotWin!.addGroupBox(15999,5,5,380,220,Translate!.getTranslation("AON_LOT/SERIAL_INFORMATION"),$$)
	
	lotWin!.addStaticText(15001,10,25,75,15,Translate!.getTranslation("AON_VENDOR:"),$8000$)
	lotWin!.addStaticText(15002,10,45,75,15,Translate!.getTranslation("AON_COMMENT:"),$8000$)
	lotWin!.addStaticText(15003,10,65,75,15,Translate!.getTranslation("AON_RECEIVED:"),$8000$)
	lotWin!.addStaticText(15009,175,65,75,15,Translate!.getTranslation("AON_ISSUED:"),$8000$)

	lotWin!.addStaticText(15004,10,105,75,15,Translate!.getTranslation("AON_COST:"),$8000$)
	lotWin!.addStaticText(15005,175,105,75,15,Translate!.getTranslation("AON_LOCATION:"),$8000$)

	lotWin!.addStaticText(15006,10,145,75,15,Translate!.getTranslation("AON_ON_HAND:"),$8000$)
	lotWin!.addStaticText(15007,10,165,75,15,Translate!.getTranslation("AON_COMMITTED:"),$8000$)
	lotWin!.addStaticText(15008,10,185,75,15,Translate!.getTranslation("AON_AVAILABLE:"),$8000$)

	callpoint!.setDevObject("vendor_id",  str(15101))
	callpoint!.setDevObject("comment_id", str(15102))
	callpoint!.setDevObject("receipt_id", str(15103))
	callpoint!.setDevObject("issued_id",  str(15109))

	lotWin!.addStaticText(15101,95,25,175,15,"",$0000$)
	lotWin!.addStaticText(15102,95,45,275,15,"",$0000$)
	lotWin!.addStaticText(15103,95,65,75,15,"",$0000$)
	lotWin!.addStaticText(15109,260,65,75,15,"",$0000$)

	callpoint!.setDevObject("cost_id",     str(15104))
	callpoint!.setDevObject("location_id", str(15105))

	lotWin!.addStaticText(15104,95,105,75,15,"",$0000$)
	lotWin!.addStaticText(15105,260,105,75,15,"",$0000$)

	callpoint!.setDevObject("onhand_id",    str(15106))
	callpoint!.setDevObject("committed_id", str(15107))
	callpoint!.setDevObject("available_id", str(15108))

	lotWin!.addStaticText(15106,95,145,75,15,"",$0000$)
	lotWin!.addStaticText(15107,95,165,75,15,"",$0000$)
	lotWin!.addStaticText(15108,95,185,75,15,"",$0000$)

	callpoint!.setDevObject("lotInfo",lotWin!)			

	if !util.alreadyResized() then 
		util.resizeWindow(Form!, SysGui!)
	endif
	
[[IVC_LOTLOOKUP.LOTS_TO_DISP.AVAL]]
rem -- User changed lot type -- re-read/display selected lot type

	lots_to_disp$ = callpoint!.getUserInput()
	gosub read_and_display_lot_grid
[[IVC_LOTLOOKUP.AREC]]
rem --- Item_id, warehouse_id, and type of lot (open,closed, etc.) coming from calling program

	lots_to_disp$ = callpoint!.getColumnData("IVC_LOTLOOKUP.LOTS_TO_DISP")
	gosub read_and_display_lot_grid
[[IVC_LOTLOOKUP.ACUS]]
rem --- Process custom event -- used in this pgm to select lot and display info.
rem
rem --- See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info.
rem
rem --- This routine is executed when callbacks have been set to run a "custom event".
rem
rem --- Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind
rem --- of event it is... in this case, we're toggling checkboxes on/off in form grid control.

rem --- Get the control ID of the event

	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ctl_ID=dec(gui_event.ID$)

	rem --- Get Grid's ID

	gridLots!=callpoint!.getDevObject("gridLots")
	wctl=gridLots!.getID()
	
	rem --- This is a grid event

	if ctl_ID=wctl
	
		if gui_event.code$="N"
			notify_base$=notice(gui_dev,gui_event.x%)
			dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
			notice$=notify_base$
		endif
		
		numcols=gridLots!.getNumColumns()
		vectLots!=callpoint!.getDevObject("vectLots")
		curr_row=dec(notice.row$)
		curr_col=dec(notice.col$)
		
		switch notice.code
			case 19; rem grid_key_press
			case 14; rem grid_mouse_up
				callpoint!.setDevObject("selected_lot",gridLots!.getCellText(curr_row,0))				
				gosub get_lot_info
				break
		swend
	endif
[[IVC_LOTLOOKUP.ASIZ]]
rem gridLots!=callpoint!.getDevObject("gridLots")
rem if gridLots!<>Null()
rem	gridLots!.setSize(300,Form!.getHeight()-(gridLots!.getY()+40))
rem	gridLots!.setFitToGrid(1)
rem endif
[[IVC_LOTLOOKUP.<CUSTOM>]]
rem ==========================================================================
read_and_display_lot_grid:
rem ==========================================================================

rem --- Position ivm-07 file

	vectLots!=SysGUI!.makeVector()
	ivm_lsmaster_dev=fnget_dev("IVM_LSMASTER")
	dim ivm_lsmaster$:fnget_tpl$("IVM_LSMASTER")
	
	whse_id$ = callpoint!.getColumnData("IVC_LOTLOOKUP.WAREHOUSE_ID")
	item_id$ = callpoint!.getColumnData("IVC_LOTLOOKUP.ITEM_ID")
	
	read (ivm_lsmaster_dev,key=firm_id$+whse_id$+item_id$,dom=*next)

	while 1 
		read record (ivm_lsmaster_dev,end=*break) ivm_lsmaster$
		
		if ivm_lsmaster.firm_id$<>firm_id$ 
:			or ivm_lsmaster$.warehouse_id$<>whse_id$
:			or ivm_lsmaster.item_id$<>item_id$
:		then break

		if lots_to_disp$="O" and ivm_lsmaster.closed_flag$<>" " then continue
		if lots_to_disp$="C" and ivm_lsmaster.closed_flag$<>"C" then continue
		if lots_to_disp$="Z" and (ivm_lsmaster.qty_on_hand-ivm_lsmaster.qty_commit<=0 or ivm_lsmaster.closed_flag$="C") then continue
		
		switch pos(ivm_lsmaster.closed_flag$=" CL")
			case 1
				desc$=Translate!.getTranslation("AON_OPEN")
			break
			case 2
				desc$=Translate!.getTranslation("AON_CLOSED")
			break
			case 3
				desc$=Translate!.getTranslation("AON_LOCKED")
			break
			case default
				desc$=Translate!.getTranslation("AON_NOT_FOUND")
			break
		swend		
		
		vectLots!.addItem(ivm_lsmaster.lotser_no$)
		vectLots!.addItem(desc$)
	wend

	gridLots!=callpoint!.getDevObject("gridLots")

	if vectLots!.size()
		numrows=vectLots!.size()/gridLots!.getNumColumns()
		gridLots!.clearMainGrid()
		gridLots!.setNumRows(numrows)
		gridLots!.setCellText(0,0,vectLots!)
		gridLots!.resort()
		gridLots!.deselectAllCells()
	else
		gridLots!.clearMainGrid()
		gridLots!.setNumRows(0)
	endif

	callpoint!.setDevObject("vectLots",vectLots!)

return

rem ==========================================================================
get_lot_info:
rem ==========================================================================

	ivm_lsmaster_dev=fnget_dev("IVM_LSMASTER")
	apm_vendmast_dev=fnget_dev("APM_VENDMAST")

	dim ivm_lsmaster$:fnget_tpl$("IVM_LSMASTER")
	dim apm_vendmast$:fnget_tpl$("APM_VENDMAST")

	whse_id$ = callpoint!.getColumnData("IVC_LOTLOOKUP.WAREHOUSE_ID")
	item_id$ = callpoint!.getColumnData("IVC_LOTLOOKUP.ITEM_ID")

	get_lot$=callpoint!.getDevObject("selected_lot")

	rem --- added knum="PRIMARY" to below, because if user typed their own lot#, Barista validation logic would
	rem --- have used knum="AO_ITEM_WH_LOT"...
	read (ivm_lsmaster_dev,key=firm_id$+whse_id$+item_id$+cvs(get_lot$,3),knum="PRIMARY",dom=*next)

	lotWin!=callpoint!.getDevObject("lotInfo")	

	while 1
		readrecord(ivm_lsmaster_dev,end=*break) ivm_lsmaster$
		
		if ivm_lsmaster.firm_id$<>firm_id$ 
:			or ivm_lsmaster$.warehouse_id$<>whse_id$
:			or ivm_lsmaster.item_id$<>item_id$
:			or ivm_lsmaster.lotser_no$<>get_lot$ 
:	   then break

		callpoint!.setDevObject("selected_lot_loc",ivm_lsmaster.ls_location$)
		callpoint!.setDevObject("selected_lot_cmt",ivm_lsmaster.ls_comments$)
		callpoint!.setDevObject("selected_lot_cost",ivm_lsmaster.unit_cost$)
		callpoint!.setDevObject("selected_lot_avail",str(ivm_lsmaster.qty_on_hand-ivm_lsmaster.qty_commit))

		rem --- Retrieve vendor name

		vendor$=""
		vendor_id = num( callpoint!.getDevObject("vendor_id") )
		
		if callpoint!.getDevObject("ap_installed") = "Y"
			vendor$=ivm_lsmaster.vendor_id$
			disp_vendor$=Translate!.getTranslation("AON_(UNKNOWN)")

			if cvs(vendor$,2)<>""
				find record (apm_vendmast_dev,key=firm_id$+vendor$,dom=*next) apm_vendmast$
				disp_vendor$=apm_vendmast.vendor_id$+" "+cvs(apm_vendmast.vendor_name$,2)
			endif

			w!=lotWin!.getControl(vendor_id)
			w!.setText(disp_vendor$)
		endif

		rem --- Display grid info
		
		w!=lotWin!.getControl( num( callpoint!.getDevObject("comment_id") ) )
		w!.setText(ivm_lsmaster.ls_comments$)
		receipt$=func.formatDate(func.latestDate(ivm_lsmaster.lstrec_date$,ivm_lsmaster.lstblt_date$))
		issue$=func.formatDate(func.latestDate(ivm_lsmaster.lstsal_date$,ivm_lsmaster.lstiss_date$))
		w!=lotWin!.getControl( num( callpoint!.getDevObject("receipt_id") ) )
		w!.setText(receipt$)
		w!=lotWin!.getControl( num( callpoint!.getDevObject("issued_id") ) )
		w!.setText(issue$)
		w!=lotWin!.getControl( num( callpoint!.getDevObject("cost_id") ) )
		w!.setText(ivm_lsmaster.unit_cost$);rem need mask
		w!=lotWin!.getControl( num( callpoint!.getDevObject("location_id") ) )
		w!.setText(ivm_lsmaster.ls_location$)
		w!=lotWin!.getControl( num( callpoint!.getDevObject("onhand_id") ) )
		w!.setText(ivm_lsmaster.qty_on_hand$)
		w!=lotWin!.getControl( num( callpoint!.getDevObject("committed_id") ) )
		w!.setText(ivm_lsmaster.qty_commit$)
		w!=lotWin!.getControl( num( callpoint!.getDevObject("available_id") ) )
		w!.setText(str(ivm_lsmaster.qty_on_hand-ivm_lsmaster.qty_commit))

	wend

return

rem ==========================================================================
#include std_missing_params.src
rem ==========================================================================
