[[OPE_CREATEWOS.ACUS]]
rem --- Process custom event

rem This routine is executed when callbacks have been set to run a 'custom event'.
rem Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind of event it is.
rem See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info.

	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ctl_ID=dec(gui_event.ID$)

	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
	endif

	rem --- Edit wo grid
	if ctl_ID=num(callpoint!.getDevObject("wo_grid_id")) then

		e!=SysGUI!.getLastEvent()
		woGrid!=callpoint!.getDevObject("woGrid")
		soCreateWO!=callpoint!.getDevObject("soCreateWO")
		woList!=soCreateWO!.getWOList()
		woVect! = woList!.get(e!.getRow())

		switch notice.code
			case 12; rem --- ON_GRID_KEY_PRESS
				rem ---  Allow space-bar toggle of checkbox
				if e!.getColumn()=0 and notice.wparam=32 then
					onoff=iff(woGrid!.getCellState(e!.getRow(),e!.getColumn()),0,1)
					if onoff then
						rem --- Checked
						woVect!.setItem(soCreateWO!.getCREATE_WO(),1)
					else
						rem --- Unchecked
						woVect!.setItem(soCreateWO!.getCREATE_WO(),0)
					endif
				endif
			break
			case 30; rem --- ON_GRID_CHECK_ON and ON_GRID_CHECK_OFF
				rem --- isChecked() is the state when event sent before control is updated,
				rem --- so use !isChecked() to get current state of control
				if e!.getColumn()=0 then
					onoff=!e!.isChecked()
					if onoff then
						rem --- Checked
						woVect!.setItem(soCreateWO!.getCREATE_WO(),1)
					else
						rem --- Unchecked
						woVect!.setItem(soCreateWO!.getCREATE_WO(),0)
					endif
				endif
			break
		swend
	endif
[[OPE_CREATEWOS.ASVA]]
rem --- Create selected Work Orders
	soCreateWO! = callpoint!.getDevObject("soCreateWO")
	soCreateWO!.createWOs()
	callpoint!.setStatus("ACTIVATE")
[[OPE_CREATEWOS.ASIZ]]
rem --- Resize grids

	formHeight=Form!.getHeight()
	formWidth=Form!.getWidth()
	woGrid!=callpoint!.getDevObject("woGrid")
	woYpos=woGrid!.getY()
	woXpos=woGrid!.getX()
	availableHeight=formHeight-woYpos-40

	rem --- Resize application grid
	woGrid!.setSize(formWidth-2*woXpos,availableHeight)
	woGrid!.setFitToGrid(1)
[[OPE_CREATEWOS.<CUSTOM>]]
format_wo_grid: rem --- Format Work Order grid

	call stbl("+DIR_PGM")+"adc_getmask.aon","","IV","U","",iv_u_mask$,0,0

	wo_grid_def_cols=callpoint!.getDevObject("wo_grid_def_cols")
	wo_rpts_rows=callpoint!.getDevObject("wo_grid_min_rows")

	dim wo_def_col_str$[0,0]
	wo_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()

	dim wo_rpts_col$[wo_grid_def_cols,len(wo_def_col_str$[0,0])/5]
	wo_rpts_col$[1,fnstr_pos("DVAR",wo_def_col_str$[0,0],5)]="CREATE_WO"
	wo_rpts_col$[1,fnstr_pos("LABS",wo_def_col_str$[0,0],5)]=""
	wo_rpts_col$[1,fnstr_pos("CTLW",wo_def_col_str$[0,0],5)]="25"
	wo_rpts_col$[1,fnstr_pos("MAXL",wo_def_col_str$[0,0],5)]="1"
	wo_rpts_col$[1,fnstr_pos("CTYP",wo_def_col_str$[0,0],5)]="C"

	wo_rpts_col$[2,fnstr_pos("DVAR",wo_def_col_str$[0,0],5)]="LINE_NO"
	wo_rpts_col$[2,fnstr_pos("LABS",wo_def_col_str$[0,0],5)]=aon_line_no_label$
	wo_rpts_col$[2,fnstr_pos("CTLW",wo_def_col_str$[0,0],5)]="40"

	wo_rpts_col$[3,fnstr_pos("DVAR",wo_def_col_str$[0,0],5)]="ITEM_ID"
	wo_rpts_col$[3,fnstr_pos("LABS",wo_def_col_str$[0,0],5)]=aon_item_id_label$
	wo_rpts_col$[3,fnstr_pos("CTLW",wo_def_col_str$[0,0],5)]="115"

	wo_rpts_col$[4,fnstr_pos("DVAR",wo_def_col_str$[0,0],5)]="ITEM_DESC"
	wo_rpts_col$[4,fnstr_pos("LABS",wo_def_col_str$[0,0],5)]=aon_item_desc_label$
	wo_rpts_col$[4,fnstr_pos("CTLW",wo_def_col_str$[0,0],5)]="345"

	wo_rpts_col$[5,fnstr_pos("DVAR",wo_def_col_str$[0,0],5)]="QTY_SHIPPED"
	wo_rpts_col$[5,fnstr_pos("LABS",wo_def_col_str$[0,0],5)]=aon_qty_shipped_label$
	wo_rpts_col$[5,fnstr_pos("CTLW",wo_def_col_str$[0,0],5)]="55"
	wo_rpts_col$[5,fnstr_pos("MSKO",wo_def_col_str$[0,0],5)]=iv_u_mask$

	wo_rpts_col$[6,fnstr_pos("DVAR",wo_def_col_str$[0,0],5)]="EST_SHP_DATE"
	wo_rpts_col$[6,fnstr_pos("LABS",wo_def_col_str$[0,0],5)]=aon_est_shp_date_lable$
	wo_rpts_col$[6,fnstr_pos("CTLW",wo_def_col_str$[0,0],5)]="55"

	wo_rpts_col$[7,fnstr_pos("DVAR",wo_def_col_str$[0,0],5)]="WO_NO"
	wo_rpts_col$[7,fnstr_pos("LABS",wo_def_col_str$[0,0],5)]=aon_wo_no_label$
	wo_rpts_col$[7,fnstr_pos("CTLW",wo_def_col_str$[0,0],5)]="80"

	wo_rpts_col$[8,fnstr_pos("DVAR",wo_def_col_str$[0,0],5)]="SCH_PROD_QTY"
	wo_rpts_col$[8,fnstr_pos("LABS",wo_def_col_str$[0,0],5)]=aon_sch_prod_qty_label$
	wo_rpts_col$[8,fnstr_pos("CTLW",wo_def_col_str$[0,0],5)]="55"
	wo_rpts_col$[8,fnstr_pos("MSKO",wo_def_col_str$[0,0],5)]=iv_u_mask$

	wo_rpts_col$[9,fnstr_pos("DVAR",wo_def_col_str$[0,0],5)]="ESTCMP_DATE"
	wo_rpts_col$[9,fnstr_pos("LABS",wo_def_col_str$[0,0],5)]=aon_estcmp_date_label$
	wo_rpts_col$[9,fnstr_pos("CTLW",wo_def_col_str$[0,0],5)]="55"

	wo_rpts_col$[10,fnstr_pos("DVAR",wo_def_col_str$[0,0],5)]="WARNINGS"
	wo_rpts_col$[10,fnstr_pos("LABS",wo_def_col_str$[0,0],5)]=aon_warnings_label$
	wo_rpts_col$[10,fnstr_pos("CTLW",wo_def_col_str$[0,0],5)]="400"

	for curr_col=1 to wo_grid_def_cols
		wo_rpts_col$[0,1]=wo_rpts_col$[0,1]+pad("CREATEWOS."+wo_rpts_col$[curr_col,
:			fnstr_pos("DVAR",wo_def_col_str$[0,0],5)],40)
	next curr_col

	wo_disp_col$=wo_rpts_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,woGrid!,"COLH-LINES-LIGHT-SIZEC-HSCROLL-CHECKS-HIGHO",wo_rpts_rows,
:		wo_def_col_str$[all],wo_disp_col$,wo_rpts_col$[all]
	return

rem =========================================================
get_RGB: rem --- Parse Red, Green and Blue segments from RGB$ string
	rem --- input: RGB$
	rem --- output: R
	rem --- output: G
	rem --- output: B
rem =========================================================
	comma1=pos(","=RGB$,1,1)
	comma2=pos(","=RGB$,1,2)
	R=num(RGB$(1,comma1-1))
	G=num(RGB$(comma1+1,comma2-comma1-1))
	B=num(RGB$(comma2+1))
	return
[[OPE_CREATEWOS.AWIN]]
rem --- Add grid to form

	use ::ado_util.src::util

	rem --- Get column headings for grid
	aon_create_wo_label$=Translate!.getTranslation("AON_CREATE")
	aon_line_no_label$=Translate!.getTranslation("AON_LINE_NO")
	aon_item_id_label$=Translate!.getTranslation("AON_ITEM_ID")
	aon_item_desc_label$=Translate!.getTranslation("AON_ITEM_DESCRIPTION")
	aon_qty_shipped_label$=Translate!.getTranslation("AON_QTY")+" "+Translate!.getTranslation("AON_SHIPPED")
	aon_est_shp_date_lable$=Translate!.getTranslation("AON_EST")+" "+Translate!.getTranslation("AON_SHIP")+" "+Translate!.getTranslation("AON_DATE")
	aon_wo_no_label$=Translate!.getTranslation("AON_WO_NO.")
	aon_sch_prod_qty_label$=Translate!.getTranslation("AON_SCH")+" "+Translate!.getTranslation("AON_PROD")+" "+Translate!.getTranslation("AON_QTY")
	aon_estcmp_date_label$=Translate!.getTranslation("AON_EST")+" "+Translate!.getTranslation("AON_COMP")+" "+Translate!.getTranslation("AON_DATE")
	aon_warnings_label$=Translate!.getTranslation("AON_WARNINGS")

	rem --- Add grid to form for candidate Work Orders that could be created
	soCreateWO!=callpoint!.getDevObject("soCreateWO")
	nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))
	woGrid!=Form!.addGrid(nxt_ctlID,10,60,1200,125); rem --- ID, x, y, width, height
	callpoint!.setDevObject("woGrid",woGrid!)
	callpoint!.setDevObject("wo_grid_id",str(nxt_ctlID))
	callpoint!.setDevObject("wo_grid_def_cols",10)
	callpoint!.setDevObject("wo_grid_min_rows",soCreateWO!.woCount())
	gosub format_wo_grid
	woGrid!.setColumnStyle(0,SysGUI!.GRID_STYLE_UNCHECKED)
	woGrid!.setColumnEditable(0,1)
	woGrid!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)

	rem --- set callbacks - processed in ACUS callpoint
	woGrid!.setCallback(woGrid!.ON_GRID_CHECK_ON,"custom_event")
	woGrid!.setCallback(woGrid!.ON_GRID_CHECK_OFF,"custom_event")
	woGrid!.setCallback(woGrid!.ON_GRID_KEY_PRESS,"custom_event")

	rem --- misc other init
	util.resizeWindow(Form!, SysGui!)
[[OPE_CREATEWOS.BEND]]
rem --- Set form exit status for Cancel
	callpoint!.setDevObject("createWOs_status","Cancel")
[[OPE_CREATEWOS.BSHO]]
rem --- Set form's default exit status for OK
	callpoint!.setDevObject("createWOs_status","OK")

rem --- Open needed files          
	num_files=1
	dim open_tables$[1:num_files], open_opts$[1:num_files], open_chans$[1:num_files], open_tpls$[1:num_files]
	open_tables$[1] ="OPS_PARAMS",    open_opts$[1] = "OTA"
        
	call stbl("+DIR_SYP")+"bac_open_tables.bbj",open_beg,open_end,open_tables$[all],open_opts$[all],open_chans$[all],open_tpls$[all],rd_table_chans$[all],open_batch,open_status$
        
	ops_params_dev = num(open_chans$[1])
	dim ops_params$:open_tpls$[1]

 rem --- Get needed OP params
	readrecord(ops_params_dev,key=firm_id$+"AR00")ops_params$
	wo_type$ = ops_params.op_create_wo_typ$

rem --- Disable all fields except the custom grid
	callpoint!.setColumnEnabled("OPE_CREATEWOS.CUSTOMER_ID",-1)
	callpoint!.setColumnEnabled("OPE_CREATEWOS.ORDER_NO",-1)

rem --- Reset soCreateWO! warn flag
	soCreateWO!=callpoint!.getDevObject("soCreateWO")
	soCreateWO!.setWarn(0)

rem --- Initialize woGrid! with info in soCreateWo!
	SysGUI!.setRepaintEnabled(0)
	woGrid!=callpoint!.getDevObject("woGrid")
	woList!=soCreateWO!.getWOList()
	if woList!.size()
		rem --- Get warning highlight color
		RGB$="255,182,193"
		RGB$=stbl("+ENTRY_ERROR_COLOR",err=*next)
		gosub get_RGB
		warningHighlight! = BBjAPI().getSysGui().makeColor(R,G,B)

		rem --- Get bold font for warning text
		font!=woGrid!.getCellFont(0,9)
		boldFont!=SysGui!.makeFont(font!.getName(),font!.getSize(),SysGui!.BOLD)

		rem --- Get red color for warning text
		RGB$="220,20,60"
		gosub get_RGB
		redColor! = BBjAPI().getSysGui().makeColor(R,G,B)

		rem --- Set cell properties in each grid row
		for row=0 to woList!.size()-1
			woVect! = woList!.get(row)

			rem --- Set WO checkbox
			if woVect!.getItem(soCreateWO!.getCREATE_WO()) then
				woGrid!.setCellStyle(row, 0, SysGUI!.GRID_STYLE_CHECKED)
				rem --- Disable checkbox if WO exists and is wrong type
				if woVect!.getItem(soCreateWO!.getWO_NO())<>"" and woVect!.getItem(soCreateWO!.getWO_TYPE())<>wo_type$ then
					woGrid!.setCellEditable(row, 0, 0)
				endif
			else
				woGrid!.setCellStyle(row, 0, SysGUI!.GRID_STYLE_UNCHECKED)
			endif
			woGrid!.setCellText(row, 0, "")

			rem --- Set SO detail line number
			woGrid!.setCellText(row, 1, woVect!.getItem(soCreateWO!.getSOLINE_NO()))

			rem  --- Set SO detail line item
			woGrid!.setCellText(row, 2, woVect!.getItem(soCreateWO!.getSOLINE_ITEM()))

			rem  --- Set SO detail line item description
			woGrid!.setCellText(row, 3, woVect!.getItem(soCreateWO!.getSOLINE_ITEMDESC()))

			rem  --- Set SO detail line ship quantity
			woGrid!.setCellText(row, 4, str(woVect!.getItem(soCreateWO!.getSOLINE_SHIPQTY())))

			rem  --- Set SO detail line ship date
			shipdate$=woVect!.getItem(soCreateWO!.getSOLINE_SHIPDATE())
			woGrid!.setCellText(row, 5, date(jul(shipdate$,"%Yd%Mz%Dz"):stbl("+DATE_MASK")))

			rem  --- Set WO number
			woGrid!.setCellText(row, 6, woVect!.getItem(soCreateWO!.getWO_NO()))

			rem  --- Set WO scheduled production quantity
			woGrid!.setCellText(row, 7, str(woVect!.getItem(soCreateWO!.getWO_SCHPRODQTY())))

			rem  --- Set WO estimated completion date
			cmpdate$=woVect!.getItem(soCreateWO!.getWO_ESTCMPDATE())
			woGrid!.setCellText(row, 8, date(jul(cmpdate$,"%Yd%Mz%Dz"):stbl("+DATE_MASK")))

			rem  --- Set Warnings
			warnings$=woVect!.getItem(soCreateWO!.getWARNINGS())
			if cvs(warnings$,3)<>"" then
				rem --- Bold red warning
				woGrid!.setCellFont(row,9,boldFont!)
				woGrid!.setCellForeColor(row,9,redColor!)
				woGrid!.setCellText(row, 9, warnings$)

				rem --- Highlight row
				woGrid!.setRowBackColor(row, warningHighlight!)
			endif
		next row
	endif
	SysGUI!.setRepaintEnabled(1)
