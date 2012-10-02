[[IVS_SETCARRY.ACUS]]
rem process custom event
rem see basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info
rem this routine is executed when callbacks have been set to run a "custom event"
rem analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind of event it is
   
dim gui_event$:tmpl(gui_dev)
dim notify_base$:noticetpl(0,0)
gui_event$=SysGUI!.getLastEventString()
ctl_ID=dec(gui_event.ID$)
if ctl_ID=num(user_tpl.gridABCctlID$)	
	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
	endif
 
	gridABC!=UserObj!.getItem(num(user_tpl.gridABCOfst$))
	curr_row=dec(notice.row$)
	curr_col=dec(notice.col$)
 
	switch notice.code
 
	case 7;rem edit stop
		if gridABC!.getCellText(curr_row,curr_col)<>user_tpl.sv_number$
			callpoint!.setStatus("MODIFIED")
		endif
		user_tpl.sv_number$=""
	break
 
	case 8;rem edit start
		if curr_col<>0 then 
			user_tpl.sv_number$=gridABC!.getCellText(curr_row,curr_col)
		endif
	break
	swend
endif
[[IVS_SETCARRY.BWRI]]
rem "update ivs-01 - ABC rec
			
	ivs01_dev=fnget_dev("IVS_ABCPARAM")
	dim ivs01a$:fnget_tpl$("IVS_ABCPARAM")
	tot_pct=0

	gridABC!=UserObj!.getItem(num(user_tpl.gridABCOfst$))
	gridRows=gridABC!.getNumRows()
	if gridRows
		readrecord(ivs01_dev,key=firm_id$+"IV02")ivs01a$
		for row=0 to gridRows-1
			field ivs01a$,"ABC_PERCENTS_"+str(row+1:"00")=gridABC!.getCellText(row,1)
			field ivs01a$,"ABC_FACTORS_"+str(row+1:"00")=gridABC!.getCellText(row,2)
			tot_pct=tot_pct+num(gridABC!.getCellText(row,1))
		next row
		if tot_pct<>100
			msg_id$="ABC_NOT_100"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
		ivs01a$=field(ivs01a$)
		writerecord(ivs01_dev,key=firm_id$+"IV02")ivs01a$
	endif
[[IVS_SETCARRY.ASIZ]]
	if UserObj!<>null()
		gridABC!=UserObj!.getItem(num(user_tpl.gridABCOfst$))
		gridABC!.setColumnWidth(0,5)
		gridABC!.setColumnWidth(1,25)
		gridABC!.setSize(Form!.getWidth()-(gridABC!.getX()*2),Form!.getHeight()-(gridABC!.getY()+40))
		gridABC!.setFitToGrid(1)
	endif
[[IVS_SETCARRY.<CUSTOM>]]
format_grid:

	call stbl("+DIR_PGM")+"adc_getmask.aon","","IV","R","",m1$,0,0
	call stbl("+DIR_PGM")+"adc_getmask.aon","","IV","%","",m2$,0,0

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()
	def_abc_cols=num(user_tpl.gridABCCols$)
	num_rpts_rows=num(user_tpl.gridABCRows$)
	dim attr_col$[def_abc_cols,len(attr_def_col_str$[0,0])/5]
	attr_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="LEVEL"
	attr_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="ABC Level"
	attr_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="5"
	attr_col$[1,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"

	attr_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="PERCENT"
	attr_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Percent"
	attr_col$[2,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"
	attr_col$[2,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m2$

	attr_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="FACTOR"
	attr_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Factor"
	attr_col$[3,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"
	attr_col$[3,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	for curr_attr=1 to def_abc_cols

	attr_col$[0,1]=attr_col$[0,1]+pad("IVS_SETCARRY."+attr_col$[curr_attr,
:		fnstr_pos("DVAR",attr_def_col_str$[0,0],5)],40)

	next curr_attr

	attr_disp_col$=attr_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridABC!,"CELL-EDIT-HIGHO-COLH-DESC-LINES-LIGHT-MULTI",num_rpts_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_col$[all]

	return

fill_grid:

rem	SysGUI!.setRepaintEnabled(0)
	gridABC!=UserObj!.getItem(num(user_tpl.gridABCOfst$))
	minrows=num(user_tpl.gridABCRows$)
	if vectABC!.size()

		numrow=vectABC!.size()/gridABC!.getNumColumns()
		gridABC!.clearMainGrid()
rem		gridABC!.setColumnStyle(0,SysGUI!.GRID_STYLE_UNCHECKED)
		gridABC!.setNumRows(numrow)

		gridABC!.setCellText(0,0,vectABC!)
rem		if vectABCSel!.size()
rem			for wk=0 to vectABCSel!.size()-1
rem				if vectABCSel!.getItem(wk)="Y"
rem					gridABC!.setCellStyle(wk,0,SysGUI!.GRID_STYLE_CHECKED)rem
rem				endif
rem			next wk
rem		endif
rem		gridABC!.resort()
		rem gridABC!.setSelectedRow(0)
		rem gridABC!.setSelectedColumn(1)
	endif
rem	SysGUI!.setRepaintEnabled(1)
return

create_reports_vector:

rem	call stbl("+DIR_PGM")+"adc_getmask.aon","VENDOR_ID","","","",m0$,0,vendor_len
rem	more=1
	dim ivs01a$:fattr(ivs01a$)
	read record (ivs01_dev,key=firm_id$+"IV02") ivs01a$
	vectABC!=SysGUI!.makeVector()
rem	vectABCSel!=SysGUI!.makeVector()
	rows=0

	for x=1 to 26
		vectABC!.addItem(chr(x+64))
		vectABC!.addItem(str(nfield(ivs01a$,"ABC_PERCENTS_"+str(x:"00")),m1$))
		vectABC!.addItem(str(nfield(ivs01a$,"ABC_FACTORS_"+str(x:"00")),m2$))
	next x

	callpoint!.setStatus("REFRESH")
	
return
[[IVS_SETCARRY.AWIN]]
rem --- Open/Lock files

	use ::ado_util.src::util

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	
	open_tables$[1]="IVS_ABCPARAM",open_opts$[1]="OTA"
	
	gosub open_tables
	
	ivs01_dev=num(open_chans$[1]),ivs01_tpl$=open_tpls$[1]
	
rem --- Dimension string templates
	
	 dim ivs01a$:ivs01_tpl$

rem --- add grid to store report master records, with checkboxes for user to select one or more reports
			
	user_tpl_str$="gridABCOfst:c(5),gridABCCols:c(5),gridABCRows:c(5),gridABCCtlID:c(5)," +
:			    	"vectABCOfst:c(5),vectABCSelOfst:c(5),sv_number:c(10)"
	dim user_tpl$:user_tpl_str$
			
	UserObj!=SysGUI!.makeVector()
	nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))
			
	gridABC!=Form!.addGrid(nxt_ctlID,5,100,400,200)
	user_tpl.gridABCCtlID$=str(nxt_ctlID)
	user_tpl.gridABCCols$="3"
	user_tpl.gridABCRows$="26"
	user_tpl.gridABCOfst$="0"
	user_tpl.vectABCOfst$="1"
	user_tpl.vectABCSelOfst$="2"
	gridABC!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)

	gosub format_grid
			
	UserObj!.addItem(gridABC!)
	UserObj!.addItem(SysGUI!.makeVector());rem vector of recs ABC Params
rem	UserObj!.addItem(SysGUI!.makeVector());rem vector of which invoices are selected
			
rem --- misc other init
	gridABC!.setColumnEditable(0,0);rem disable column 0
	gridABC!.setColumnEditable(1,1);rem enable column 1
	gridABC!.setColumnEditable(2,1);rem enable column 2
	gridABC!.setSelectionMode(gridABC!.GRID_SELECT_CELL)
	gridABC!.setSelectedRow(0)
	gridABC!.setSelectedColumn(1)

	gridABC!.setCallback(gridABC!.ON_GRID_EDIT_START,"custom_event")
	gridABC!.setCallback(gridABC!.ON_GRID_EDIT_STOP,"custom_event")
			
	gosub create_reports_vector
	gosub fill_grid

	util.resizeWindow(Form!, SysGUI!)
			
rem --- set callbacks - processed in ACUS callpoint
	gridABC!.setCallback(gridABC!.ON_GRID_KEY_PRESS,"custom_event")
	gridABC!.setCallback(gridABC!.ON_GRID_MOUSE_UP,"custom_event")
