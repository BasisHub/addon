[[SFE_RELEASEWO.<CUSTOM>]]
rem =====================================================
format_grid: rem --- format the grid that will display component shortages

rem =====================================================

	call stbl("+DIR_PGM")+"adc_getmask.aon","","IV","U","",m1$,0,0

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()
	def_cols=7
	num_rows=0
	dim attr_col$[def_cols,len(attr_def_col_str$[0,0])/5]

	attr_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ITEM"
	attr_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ITEM_ID")
	attr_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="100"

	attr_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DESC"
	attr_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DESCRIPTION")
	attr_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="200"

	attr_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="REQ"
	attr_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_REQUIRED")
	attr_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_col$[3,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_col$[3,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="OH"
	attr_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ON_HAND")
	attr_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_col$[4,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_col$[4,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_col$[5,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="COMM"
	attr_col$[5,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_COMMITTED")
	attr_col$[5,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_col$[5,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_col$[5,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_col$[6,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="AVAIL"
	attr_col$[6,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_AVAILABLE")
	attr_col$[6,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_col$[6,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_col$[6,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_col$[7,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="OO"
	attr_col$[7,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ON_ORDER")
	attr_col$[7,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_col$[7,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_col$[7,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	for curr_attr=1 to def_cols

		attr_col$[0,1]=attr_col$[0,1]+pad("FILES."+attr_col$[curr_attr,
:			fnstr_pos("DVAR",attr_def_col_str$[0,0],5)],40)

	next curr_attr

	attr_disp_col$=attr_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridAvail!,"COLH-SIZEC-LIGHT-LINES-HIGHO",num_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_col$[all]

	rem -- size grid on form
	gridAvail!=callpoint!.getDevObject("avail_grid")

	gridAvail!.setSize(Form!.getWidth()-(gridAvail!.getX()*2),Form!.getHeight()-(gridAvail!.getY()+40))
	gridAvail!.setFitToGrid(1)



	return

rem =====================================================
load_grid: rem --- create vector of availability info and load grid

rem =====================================================

	sfe22_dev=fnget_dev("SFE_WOMATL")
	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	ivm02_dev=fnget_dev("IVM_ITEMWHSE")

	dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
	dim ivm_itemwhse$:fnget_tpl$("IVM_ITEMWHSE")

	vectAvail!=SysGUI!.makeVector()

	wo_loc$=callpoint!.getDevObject("wo_loc")
	wo_no$=callpoint!.getDevObject("wo_no")
	allow_release$="Y"

	read (sfe22_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)

	while 1
		sfe22_key$=key(sfe22_dev,end=*break)
		read record (sfe22_dev)sfe_womatl$
		if pos(firm_id$+wo_loc$+wo_no$=sfe_womatl$)<>1 then break
		if sfe_womatl.line_type$="M" then continue
		read record (ivm02_dev,key=firm_id$+sfe_womatl.warehouse_id$+sfe_womatl.item_id$,dom=*next)ivm_itemwhse$
		if cvs(ivm_itemwhse.item_id$,3)="" 
			at_whse$=" - Not at warehouse!"
			allow_release$="N"
			callpoint!.setColumnEnabled("SFE_RELEASEWO.RELEASE",0)
		else
			at_whse$=""
			callpoint!.setColumnEnabled("SFE_RELEASEWO.RELEASE",1)
		endif
		read record (ivm01_dev,key=firm_id$+sfe_womatl.item_id$,dom=*next)ivm_itemmast$
		vectAvail!.addItem(sfe_womatl.item_id$)
		vectAvail!.addItem(cvs(ivm_itemmast.item_desc$,3)+at_whse$)
		vectAvail!.addItem(sfe_womatl.total_units$)
		vectAvail!.addItem(ivm_itemwhse.qty_on_hand$)
		vectAvail!.addItem(ivm_itemwhse.qty_commit$)
		vectAvail!.addItem(str(num(ivm_itemwhse.qty_on_hand$)-num(ivm_itemwhse.qty_commit$)))
		vectAvail!.addItem(ivm_itemwhse.qty_on_order$)
	wend

	gridAvail!=callpoint!.getDevObject("avail_grid")
	if vectAvail!.size()
		numrow=vectAvail!.size()/gridAvail!.getNumColumns()
		gridAvail!.clearMainGrid()
		gridAvail!.setNumRows(numrow)
		gridAvail!.setCellText(0,0,vectAvail!)
	endif

	if numrow
		for curr_row=0 to numrow-1
			req=num(gridAvail!.getCellText(curr_row,2))
			avail=num(gridAvail!.getCellText(curr_row,5))
			if req>avail
				gridAvail!.setRowBackColor(curr_row,callpoint!.getDevObject("error_color"))
			endif
		next curr_row
	endif

	if allow_release$="N"
		callpoint!.setColumnEnabled("SFE_RELEASEWO.RELEASE",-1)
	else
		callpoint!.setColumnEnabled("SFE_RELEASEWO.RELEASE",1)
	endif


	return
[[SFE_RELEASEWO.ARAR]]
rem --- Set defaults

	if callpoint!.getDevObject("wo_status")="O"
		callpoint!.setColumnData("SFE_RELEASEWO.RELEASE","Y",1)
		callpoint!.setColumnEnabled("SFE_RELEASEWO.RELEASE",0)
	endif
[[SFE_RELEASEWO.ASVA]]
rem --- init for commit/release

	wo_no$=callpoint!.getDevObject("wo_no")
	wo_loc$=callpoint!.getDevObject("wo_loc")

rem --- Write rec for traveler/pick	

	if callpoint!.getColumnData("SFE_RELEASEWO.PRINT_TRAVEL")="Y"
		opened_wo=fnget_dev("SFE_OPENEDWO")
		dim opened_wo$:fnget_tpl$("SFE_OPENEDWO")
		opened_wo.firm_id$=firm_id$
		opened_wo.wo_no$=wo_no$
		opened_wo$=field(opened_wo$)
		write record (opened_wo) opened_wo$
	endif

	if callpoint!.getColumnData("SFE_RELEASEWO.PRINT_PICK")="Y"
		wocommit=fnget_dev("SFE_WOCOMMIT")
		dim wocommit$:fnget_tpl$("SFE_WOCOMMIT")
		wocommit.firm_id$=firm_id$
		wocommit.wo_no$=wo_no$
		wocommit$=field(wocommit$)
		write record (wocommit) wocommit$
	endif

rem --- Release/commit

	if callpoint!.getColumnData("SFE_RELEASEWO.RELEASE")="Y" and pos(callpoint!.getDevObject("wo_status")="PQ")<>0
		
		rem --- Initialize inventory item update
		call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

		sfe01_dev=fnget_dev("SFE_WOMASTR")
		sfe13_dev=fnget_dev("SFE_WOMATHDR")
		sfe22_dev=fnget_dev("SFE_WOMATL")
		sfe23_dev=fnget_dev("SFE_WOMATDTL")

		dim sfe_womastr$:fnget_tpl$("SFE_WOMASTR")
		dim sfe_womathdr$:fnget_tpl$("SFE_WOMATHDR")
		dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")
		dim sfe_womatdtl$:fnget_tpl$("SFE_WOMATDTL")

		read record (sfe01_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)sfe_womastr$
		if pos(firm_id$+wo_loc$+wo_no$=sfe_womastr$)=1

			rem --- update on order qty
			items$[1]=sfe_womastr.warehouse_id$
			items$[2]=sfe_womastr.item_id$
			refs[0]=sfe_womastr.sch_prod_qty
			call stbl("+DIR_PGM")+"ivc_itemupdt.aon","OO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

			rem --- process womathdr/dtl
			read (sfe13_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)
			read record (sfe13_dev,end=*next)sfe_womathdr$
			if pos(firm_id$+wo_loc$+wo_no$=sfe_womathdr$)<>1

				sfe_womathdr.firm_id$=firm_id$
				sfe_womathdr.wo_location$=wo_loc$
				sfe_womathdr.wo_no$=wo_no$
				sfe_womathdr.wo_type$=sfe_womastr.wo_type$
				sfe_womathdr.wo_category$=sfe_womastr.wo_category$
				sfe_womathdr.warehouse_id$=sfe_womastr.warehouse_id$
				sfe_womathdr.item_id$=sfe_womastr.item_id$

				read (sfe22_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)
				
				while 1
					sfe22_key$=key(sfe22_dev,end=*break)
					if pos(firm_id$+wo_loc$+wo_no$=sfe22_key$)<>1 then break
					read record (sfe22_dev)sfe_womatl$
					if sfe_womatl.line_type$="M" then continue

					sfe_womatdtl.firm_id$=firm_id$
					sfe_womatdtl.wo_location$=wo_loc$
					sfe_womatdtl.wo_no$=wo_no$
					sfe_womatdtl.material_seq$=sfe_womatl.material_seq$
					sfe_womatdtl.unit_measure$=sfe_womatl.unit_measure$
					sfe_womatdtl.require_date$=sfe_womatl.require_date$
					sfe_womatdtl.warehouse_id$=sfe_womathdr.warehouse_id$
					sfe_womatdtl.item_id$=sfe_womatl.item_id$
					
					find (sfe23_dev,key=firm_id$+wo_loc$+wo_no$+sfe_womatdtl.material_seq$,dom=*next);continue

					sfe_womatdtl.qty_ordered=sfe_womatl.total_units
					sfe_womatdtl.unit_cost=sfe_womatl.iv_unit_cost
					sfe_womatdtl.issue_cost=sfe_womatdtl.unit_cost

					items$[1]=sfe_womatdtl.warehouse_id$
					items$[2]=sfe_womatdtl.item_id$
					refs[0]=sfe_womatdtl.qty_ordered
					call stbl("+DIR_PGM")+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

					internal_seq_no$=""
					call stbl("+DIR_SYP")+"bas_sequences.bbj","INTERNAL_SEQ_NO",internal_seq_no$,table_chans$[all],"QUIET"
					sfe_womatdtl.internal_seq_no$=internal_seq_no$

					sfe_womatdtl$=field(sfe_womatdtl$)
					write record(sfe23_dev)sfe_womatdtl$
				wend

				sfe_womathdr$=field(sfe_womathdr$)
				write record (sfe13_dev)sfe_womathdr$

			endif

			sfe_womastr.wo_status$="O"
			sfe_womastr$=field(sfe_womastr$)
			write record (sfe01_dev)sfe_womastr$
			callpoint!.setDevObject("wo_status","O")

		endif
	endif
[[SFE_RELEASEWO.BSHO]]
rem --- Open needed tables

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFE_OPENEDWO",open_opts$[1]="OTA"
	open_tables$[2]="SFE_WOCOMMIT",open_opts$[2]="OTA"
	gosub open_tables

rem --- create grid to display shortages

	nxt_ctlID = num(stbl("+CUSTOM_CTL"))
	callpoint!.setDevObject("grid_ctlID",str(nxt_ctlID))
	wctl!=callpoint!.getControl("SFE_RELEASEWO.PRINT_PICK")
	gridAvail!=Form!.addGrid(nxt_ctlID,10,num(wctl!.getX())+75,700,200)
	callpoint!.setDevObject("avail_grid",gridAvail!)

	call stbl("+DIR_SYP")+"bac_create_color.bbj","+ENTRY_ERROR_COLOR","255,224,224",error_color!,""
	callpoint!.setDevObject("error_color",error_color!)
	
	gosub format_grid
	gosub load_grid
