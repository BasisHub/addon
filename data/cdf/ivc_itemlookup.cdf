[[IVC_ITEMLOOKUP.ASVA]]
rem --- set find_item only if OK is clicked

callpoint!.setDevObject("find_item",callpoint!.getDevObject("selected_item"))
[[IVC_ITEMLOOKUP.BEND]]
rem --- since files were forced open on new channels, close to keep tidy

	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	
	open_tables$[1]="IVM_ITEMSYN",   open_opts$[1]="@C"
	open_tables$[2]="IVM_ITEMWHSE",   open_opts$[2]="@C"
	open_tables$[3]="IVS_PARAMS",   open_opts$[3]="@C"
	open_tables$[4]="IVM_ITEMMAST",   open_opts$[4]="@C"	
	open_tables$[5]="IVM_ITEMMAST",   open_opts$[5]="@C"
	gosub open_tables
	
[[IVC_ITEMLOOKUP.SEARCH_KEY.AVAL]]
rem --- set search key/file according to user's selection in the 'search by' listbutton.
rem --- and search text entered here.
rem --- load/display grid

search_by$=callpoint!.getColumnData("IVC_ITEMLOOKUP.SEARCH_BY")
switch pos(search_by$="ISTV")
	case 1; rem by item
		search_dev=fnget_dev("@IVM_ITEMMAST")
		dim searchrec$:fnget_tpl$("@IVM_ITEMMAST")
		search_knum$="PRIMARY"
		search_text$=callpoint!.getUserInput()
		search_field$="ITEM_ID"
		gosub load_and_display_grid
	break
	case 2; rem by synonym
		search_dev=fnget_dev("@IVM_ITEMSYN")
		dim searchrec$:fnget_tpl$("@IVM_ITEMSYN")
		search_knum$="PRIMARY"
		search_text$=callpoint!.getUserInput()
		search_field$="ITEM_SYNONYM"
		gosub load_and_display_grid
	break
	case 3; rem by product type
		search_dev=fnget_dev("@IVM_ITEMMAST")
		dim searchrec$:fnget_tpl$("@IVM_ITEMMAST")
		search_knum$="AO_PROD_ITEM"
		search_text$=callpoint!.getUserInput()
		search_field$="PRODUCT_TYPE"
		gosub load_and_display_grid
	break
	case 4; rem by vendor
		sql_prep$="SELECT ivm_itemvend.vendor_id, ivm_itemvend.item_id, apm_vendmast.vendor_name, ivm_itemmast.item_desc "
		sql_prep$=sql_prep$+"FROM ivm_itemvend "
		sql_prep$=sql_prep$+"INNER JOIN apm_vendmast ON ivm_itemvend.firm_id = apm_vendmast.firm_id "
		sql_prep$=sql_prep$+"AND ivm_itemvend.vendor_id = apm_vendmast.vendor_id "
		sql_prep$=sql_prep$+"INNER JOIN ivm_itemmast on ivm_itemvend.firm_id = ivm_itemmast.firm_id "
		sql_prep$=sql_prep$+"AND ivm_itemvend.item_id = ivm_itemmast.item_id "
		sql_prep$=sql_prep$+"WHERE ivm_itemvend.firm_id = '" + firm_id$ + "' "
		sql_prep$=sql_prep$+"AND apm_vendmast.vendor_name like '" + callpoint!.getRawUserInput() + "%' "
		sql_prep$=sql_prep$+"ORDER BY apm_vendmast.vendor_name"
		gosub load_and_display_grid_sql		
	break
	case default
	break
swend
[[IVC_ITEMLOOKUP.ARER]]
rem --- set default search type to I (by item)
callpoint!.setColumnData("IVC_ITEMLOOKUP.SEARCH_BY","I")

dflt_meth!=callpoint!.getDevObject("default_meth")
if dflt_meth!<>null() callpoint!.setColumnData("IVC_ITEMLOOKUP.SEARCH_BY",dflt_meth!)

dflt_start!=callpoint!.getDevObject("default_start")
if dflt_start!<>null! 
	callpoint!.setColumnData("IVC_ITEMLOOKUP.SEARCH_KEY",dflt_start!)
	search_dev=fnget_dev("@IVM_ITEMSYN")
	dim searchrec$:fnget_tpl$("@IVM_ITEMSYN")
	search_knum$="PRIMARY"
	search_text$=dflt_start!
	search_field$="ITEM_SYNONYM"
	gosub load_and_display_grid
endif

callpoint!.setStatus("REFRESH")
[[IVC_ITEMLOOKUP.AWIN]]
rem --- open files

	use ::ado_util.src::util
	use ::ado_func.src::func

rem --- opening possible search files with force flag (N=force open on another channel) so use of knums won't mess up reads on these files 
rem --- 	that might be going on in in calling programs
rem --- also... saving channel # of first ivm_itemmast open, so I can distinguish 'main' open from extra open for searching by product type, etc. (i.e. different knum)
rem --- the "@" in the open flags is a special prefix used by Barista; since I'm not sure if these files are already open or not, the "@" marks them in
rem --- 	rd_table_chans$[ ], so I can do fnget_dev/fnget_tpl using the @ prefix on the alias,
rem --- 	and I can call open_tables to close these files when done, using "@C" flags, so Barista knows which one to close, i.e., the file(s) I forced 
rem ---	open rather than one that might have already been open on another channel.
 
	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVM_ITEMMAST", open_opts$[1]="@NTA"
	open_tables$[2]="IVM_ITEMSYN",   open_opts$[2]="@NTA"
	open_tables$[3]="IVM_ITEMWHSE",   open_opts$[3]="@NTA"
	open_tables$[4]="IVS_PARAMS",   open_opts$[4]="@NTA"
	open_tables$[5]="IVM_ITEMMAST",   open_opts$[5]="@NTA"	

	gosub open_tables

	callpoint!.setDevObject("ivm_itemmast_dev",open_chans$[1])

rem ---  Set up grid

	dims_tmpl$ = "x:u(2),y:u(2),w:u(2),h:u(2)"
	dim g$:dims_tmpl$
	g.x = 10, g.y = 75, g.w = 400, g.h = 220
	callpoint!.setDevObject("dims_tmpl", dims_tmpl$)
	callpoint!.setDevObject("grid_dims", g$)

	nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))
	gridSearch!=Form!.addGrid(nxt_ctlID, g.x, g.y, g.w, g.h)
	gridSearch!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)

	gridSearch!.setColumnEditable(0,0)
	gridSearch!.setColumnEditable(1,0)

	gridSearch!.setCallback(gridSearch!.ON_GRID_MOUSE_UP,"custom_event")
	gridSearch!.setCallback(gridSearch!.ON_GRID_SELECT_ROW,"custom_event")

	callpoint!.setDevObject("gridSearch",gridSearch!)

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()
	def_grid_cols=3
	num_rows=10
	dim attr_grid_col$[def_grid_cols,len(attr_def_col_str$[0,0])/5]

	dvar_pos = fnstr_pos("DVAR", attr_def_col_str$[0,0], 5)
	labs_pos = fnstr_pos("LABS", attr_def_col_str$[0,0], 5)
	ctlw_pos = fnstr_pos("CTLW", attr_def_col_str$[0,0], 5)
	
	attr_grid_col$[1,dvar_pos]="SEARCH_KEY"
	attr_grid_col$[1,labs_pos]=Translate!.getTranslation("AON_SEARCH_KEY")
	attr_grid_col$[1,ctlw_pos]="125"

	attr_grid_col$[2,dvar_pos]="ITEM_NO"
	attr_grid_col$[2,labs_pos]=Translate!.getTranslation("AON_ITEM")
	attr_grid_col$[2,ctlw_pos]="125"	

	attr_grid_col$[3,dvar_pos]="DESC"
	attr_grid_col$[3,labs_pos]=Translate!.getTranslation("AON_DESCRIPTION")
	attr_grid_col$[3,ctlw_pos]="125"	
	
	for curr_attr=1 to def_grid_cols
		attr_grid_col$[0,1] = attr_grid_col$[0,1] + 
:			pad( "IVC_ITEMLOOKUP." + attr_grid_col$[curr_attr, dvar_pos], 40 )
	next curr_attr

	attr_disp_col$=attr_grid_col$[0,1]
	
	call stbl("+DIR_SYP")+"bam_grid_init.bbj",
:		gui_dev,
:		gridSearch!,
:		"LINES-COLH",
:		num_rows,
:		attr_def_col_str$[all],
:		attr_disp_col$,
:		attr_grid_col$[all]

rem --- Create Item Information window			
		
	dim w$:dims_tmpl$
	w.x = 420, w.y = 65, w.w = 420, w.h = 225
	callpoint!.setDevObject("child_window_dims", w$)

	cxt=SysGUI!.getAvailableContext()
	infoWin!=form!.addChildWindow(15000, w.x, w.y, w.w, w.h, "", $00000800$, cxt)
	SysGUI!.setContext(cxt)

	infoWin!.addGroupBox(15999,5,5,415,220,Translate!.getTranslation("AON_INVENTORY_DETAIL"),$$)
	
	infoWin!.addStaticText(15001,10,25,75,15,Translate!.getTranslation("AON_PRODUCT_TYPE:"),$8000$)

	infoWin!.addStaticText(15003,10,65,75,15,Translate!.getTranslation("AON_UNIT_OF_SALE:"),$8000$)
	infoWin!.addStaticText(15004,10,85,75,15,Translate!.getTranslation("AON_WEIGHT:"),$8000$)

	infoWin!.addStaticText(15005,200,25,75,15,"",$8000$)
	infoWin!.addStaticText(15006,200,45,75,15,Translate!.getTranslation("AON_LAST_RECEIPT:"),$8000$)
	infoWin!.addStaticText(15007,200,65,75,15,Translate!.getTranslation("AON_LAST_ISSUE:"),$8000$)
	infoWin!.addStaticText(15008,200,85,75,15,Translate!.getTranslation("AON_LOT/SERIALIZED?:"),$8000$)

	infoWin!.addStaticText(15009,10,125,75,15,Translate!.getTranslation("AON_ON_HAND:"),$8000$)
	infoWin!.addStaticText(15010,10,145,75,15,Translate!.getTranslation("AON_COMMITTED:"),$8000$)
	infoWin!.addStaticText(15011,10,165,75,15,Translate!.getTranslation("AON_AVAILABLE:"),$8000$)
	infoWin!.addStaticText(15012,10,185,75,15,Translate!.getTranslation("AON_ON_ORDER:"),$8000$)

	rem --- above are labels, now add static text fields for data
	callpoint!.setDevObject("prod_tp",  str(15101))
	infoWin!.addStaticText(15101,95,25,75,15,"",$0000$)

	callpoint!.setDevObject("unit_sale",str(15103))
	infoWin!.addStaticText(15103,95,65,75,15,"",$0000$)

	callpoint!.setDevObject("weight",str(15104))
	infoWin!.addStaticText(15104,95,85,75,15,"",$0000$)

	callpoint!.setDevObject("alt_super_prompt",str(15005))
	callpoint!.setDevObject("alt_super",str(15105))
	infoWin!.addStaticText(15105,285,25,75,15,"",$0000$)

	callpoint!.setDevObject("last_receipt",str(15106))
	infoWin!.addStaticText(15106,285,45,75,15,"",$0000$)

	callpoint!.setDevObject("last_issue",str(15107))
	infoWin!.addStaticText(15107,285,65,75,15,"",$0000$)

	callpoint!.setDevObject("lot_ser",str(15108))
	infoWin!.addStaticText(15108,285,85,75,15,"",$0000$)

	callpoint!.setDevObject("on_hand",str(15109))
	infoWin!.addStaticText(15109,95,125,75,15,"",$0000$)

	callpoint!.setDevObject("committed",str(15110))
	infoWin!.addStaticText(15110,95,145,75,15,"",$0000$)

	callpoint!.setDevObject("available",str(15111))
	infoWin!.addStaticText(15111,95,165,75,15,"",$0000$)

	callpoint!.setDevObject("on_order",str(15112))
	infoWin!.addStaticText(15112,95,185,75,15,"",$0000$)

	callpoint!.setDevObject("infoWin",infoWin!)			

	if !util.alreadyResized() then 
		util.resizeWindow(Form!, SysGui!)
	endif
[[IVC_ITEMLOOKUP.ACUS]]
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

	gridSearch!=callpoint!.getDevObject("gridSearch")
	wctl=gridSearch!.getID()

	rem --- This is a grid event

	if ctl_ID=wctl
	
		if gui_event.code$="N"
			notify_base$=notice(gui_dev,gui_event.x%)
			dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
			notice$=notify_base$
		endif
		
		numcols=gridSearch!.getNumColumns()
		vectSearch!=callpoint!.getDevObject("vectSearch")
		curr_row=dec(notice.row$)
		curr_col=dec(notice.col$)
		
		switch notice.code
			case 19; rem grid_key_press
			case 14; rem grid_mouse_up
				callpoint!.setDevObject("selected_item",firm_id$+gridSearch!.getCellText(curr_row,1))
				gosub get_inventory_detail		
			break
		swend
	endif
[[IVC_ITEMLOOKUP.<CUSTOM>]]
load_and_display_grid:

	ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")

	rem --- Position search file	

	vectSearch!=SysGUI!.makeVector()
	
	read (search_dev,key=firm_id$+cvs(search_text$,3),knum=search_knum$,dom=*next)

	while 1 
		skey$=key(search_dev,end=*break); read record (search_dev) searchrec$		
		if searchrec.firm_id$<>firm_id$ then break
		if len(cvs(search_text$,2)) > 0
			if pos(firm_id$+cvs(search_text$,2)=skey$)<>1 break
		endif
		read record (ivm_itemmast_dev,key=firm_id$+searchrec.item_id$,dom=*next)ivm_itemmast$
	
		vectSearch!.addItem(field(searchrec$,search_field$))
		vectSearch!.addItem(ivm_itemmast.item_id$)
		vectSearch!.addItem(ivm_itemmast.item_desc$)
	wend

	gosub load_vect_into_grid

return

load_vect_into_grid:

	gridSearch!=callpoint!.getDevObject("gridSearch")

	if vectSearch!.size()
		numrows=vectSearch!.size()/gridSearch!.getNumColumns()
		gridSearch!.clearMainGrid()
		gridSearch!.setNumRows(numrows)
		gridSearch!.setCellText(0,0,vectSearch!)
		gridSearch!.resort()
		gridSearch!.deselectAllCells()
	else
		gridSearch!.clearMainGrid()
		gridSearch!.setNumRows(0)
	endif

	callpoint!.setDevObject("vectSearch",vectSearch!)

return

load_and_display_grid_sql:

	vectSearch!=SysGUI!.makeVector()

	rem --- execute the sql statement constructed in sql_prep$
        sql_chan=sqlunt
        sqlopen(sql_chan,err=*next)stbl("+DBNAME")
        sqlprep(sql_chan)sql_prep$
        dim read_tpl$:sqltmpl(sql_chan)
        sqlexec(sql_chan)
		
	rem --- process returned recordset
        while 1
	        read_tpl$=sqlfetch(sql_chan,err=*break) 
		vectSearch!.addItem(read_tpl.vendor_name$)
		vectSearch!.addItem(read_tpl.item_id$)
		vectSearch!.addItem(read_tpl.item_desc$)
 	wend

	gosub load_vect_into_grid

return

get_inventory_detail:
rem --- get/display Inventory Detail info

	ivs_params_dev=fnget_dev("@IVS_PARAMS")
	ivm_itemwhse_dev=fnget_dev("@IVM_ITEMWHSE")
	ivm_itemmast_dev=num(callpoint!.getDevObject("ivm_itemmast_dev"))

	dim ivs_params$:fnget_tpl$("@IVS_PARAMS")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
	dim ivm_itemwhse$:fnget_tpl$("@IVM_ITEMWHSE")

	read record (ivs_params_dev,key=firm_id$+"IV00",dom=*next)ivs_params$
	ls$=ivs_params.lotser_flag$

	read (ivm_itemwhse_dev,key=callpoint!.getDevObject("selected_item"),knum="AO_ITEM_WH",dom=*next)
	on_hand=0
	committed=0
	available=0
	on_order=0

	while 1
		read record(ivm_itemwhse_dev,end=*break)ivm_itemwhse$
		if pos(ivm_itemwhse.firm_id$+ivm_itemwhse.item_id$=callpoint!.getDevObject("selected_item"))<>1 then break
		on_hand=on_hand+ivm_itemwhse.qty_on_hand
		committed=committed+ivm_itemwhse.qty_commit
		on_order=on_order+ivm_itemwhse.qty_on_order
	wend
	available=on_hand-committed

	infoWin!=callpoint!.getDevObject("infoWin")

	read record (ivm_itemmast_dev,key=callpoint!.getDevObject("selected_item"),dom=*next)ivm_itemmast$
	
	w!=infoWin!.getControl( num( callpoint!.getDevObject("prod_tp") ) )
	w!.setText(ivm_itemmast.product_type$)
	w!=infoWin!.getControl( num( callpoint!.getDevObject("unit_sale") ) )
	w!.setText(ivm_itemmast.unit_of_sale$)
	w!=infoWin!.getControl( num( callpoint!.getDevObject("weight") ) )
	w!.setText(ivm_itemmast.weight$)
	switch pos(ivm_itemmast.alt_sup_flag$="AS")
		case 1
			as_prompt$=Translate!.getTranslation("AON_ALTERNATE:")
		break
		case 2
			as_prompt$=Translate!.getTranslation("AON_SUPERSEDED:")
		break
		case default
			as_prompt$=""
		break
	swend
	w!=infoWin!.getControl( num( callpoint!.getDevObject("alt_super_prompt") ) )	
	w!.setText(as_prompt$)
	w!=infoWin!.getControl( num( callpoint!.getDevObject("alt_super") ) )
	w!.setText(ivm_itemmast.alt_sup_item$)
	w!=infoWin!.getControl( num( callpoint!.getDevObject("last_receipt") ) )
	w!.setText(func.formatDate(ivm_itemmast.lstrec_date$))
	w!=infoWin!.getControl( num( callpoint!.getDevObject("last_issue") ) )
	w!.setText(func.formatDate(ivm_itemmast.lstiss_date$))
	switch pos(ls$="LS")
		case 1
			ls_text$=Translate!.getTranslation("AON_LOTTED")
		break
		case 2
			ls_text$=Translate!.getTranslation("AON_SERIALIZED")
		break
		case default
			ls_text$=""
		break
	swend
	w!=infoWin!.getControl( num( callpoint!.getDevObject("lot_ser") ) )	
	w!.setText(ls_text$)
	w!=infoWin!.getControl( num( callpoint!.getDevObject("on_hand") ) )	
	w!.setText(str(on_hand))
	w!=infoWin!.getControl( num( callpoint!.getDevObject("committed") ) )	
	w!.setText(str(committed))
	w!=infoWin!.getControl( num( callpoint!.getDevObject("available") ) )	
	w!.setText(str(available))
	w!=infoWin!.getControl( num( callpoint!.getDevObject("on_order") ) )	
	w!.setText(str(on_order))

return

rem ==========================================================================
rem --- Functions
rem ==========================================================================

rem --- Return the later of two dates

	def fnlatest$(q1$,q2$)
		q3$=""
		if cvs(q1$,2)<>"" then let q3$=q1$
		if cvs(q2$,2)<>"" then if q2$>q3$ then let q3$=q2$
		return q3$
	fnend

rem --- Format date from YYYYMMDD to MM/DD/YY

    def fn_date$(q$)
        q1$=""
        q1$=date( jul( num(q$(1,4)), num(q$(5,2)), num(q$(7,2)),err=*next ),err=*next )
        if q1$="" then q1$=q$
        return q1$
    fnend

rem ==========================================================================
#include std_missing_params.src
rem ==========================================================================
