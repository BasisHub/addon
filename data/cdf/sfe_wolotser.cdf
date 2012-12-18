[[SFE_WOLOTSER.ADEL]]
rem --- Enable/disable additional options
	gosub enable_options
[[SFE_WOLOTSER.LOTSER_NO.BINP]]
rem --- Capture current lotser_no so can skip validation if it hasn't changed
	prev_lotser_no$=callpoint!.getColumnData("SFE_WOLOTSER.LOTSER_NO")
	callpoint!.setDevObject("prev_lotser_no",prev_lotser_no$)
[[SFE_WOLOTSER.AWRI]]
rem --- Enable/disable additional options
	gosub enable_options
[[SFE_WOLOTSER.AREC]]
rem --- Enable/disable additional options
	gosub enable_options
[[SFE_WOLOTSER.COMPLETE_FLG.AVAL]]
rem --- Enable/disable additional options
	gosub enable_options
[[SFE_WOLOTSER.COMPLETE_FLG.BINP]]
rem --- Initialize complete flag
	this_ls_sch_qty=num(callpoint!.getColumnData("SFE_WOLOTSER.SCH_PROD_QTY"))
	this_cls_inp_qty=num(callpoint!.getColumnData("SFE_WOLOTSER.CLS_INP_QTY"))
	this_ls_cls_todt=num(callpoint!.getColumnData("SFE_WOLOTSER.QTY_CLS_TODT"))
	if this_ls_sch_qty=this_cls_inp_qty+this_ls_cls_todt and
:	callpoint!.getColumnData("SFE_WOLOTSER.COMPLETE_FLG")<>"Y" then
		callpoint!.setColumnData("SFE_WOLOTSER.COMPLETE_FLG","Y",1)
		callpoint!.setStatus("MODIFIED")

		rem --- Enable/disable additional options
		gosub enable_options
	endif
[[SFE_WOLOTSER.CLS_INP_QTY.BINP]]
rem --- Capture current lot/ser cls_inpt_qty so can make adjustments if it gets changed
	prev_cls_inp_qty=num(callpoint!.getColumnData("SFE_WOLOTSER.CLS_INP_QTY"))
	callpoint!.setDevObject("prev_cls_inp_qty",prev_cls_inp_qty)

	rem --- Initialize cls_inpt_qty as needed
	this_ls_sch_qty=num(callpoint!.getColumnData("SFE_WOLOTSER.SCH_PROD_QTY"))
	this_ls_cls_todt=num(callpoint!.getColumnData("SFE_WOLOTSER.QTY_CLS_TODT"))
	if prev_cls_inp_qty=0 and  this_ls_cls_todt<>this_ls_sch_qty then
		this_cls_inp_qty=this_ls_sch_qty-this_ls_cls_todt
		callpoint!.setColumnData("SFE_WOLOTSER.CLS_INP_QTY",str(this_cls_inp_qty),1)
		callpoint!.setStatus("MODIFIED")

		rem --- Adjust how many lot/serial items have been closed
		ls_close_qty=callpoint!.getDevObject("ls_close_qty")
		ls_close_qty=ls_close_qty+(this_ls_sch_qty-this_ls_cls_todt)
		callpoint!.setDevObject("ls_close_qty",ls_close_qty)

		rem --- Update complete flag and closed cost
		this_ls_sch_qty=num(callpoint!.getColumnData("SFE_WOLOTSER.SCH_PROD_QTY"))
		this_ls_cls_todt=num(callpoint!.getColumnData("SFE_WOLOTSER.QTY_CLS_TODT"))
		if this_cls_inp_qty<>0 then
			if this_cls_inp_qty=this_ls_sch_qty-this_ls_cls_todt and
:			callpoint!.getColumnData("SFE_WOLOTSER.COMPLETE_FLG")<>"Y" then
				callpoint!.setColumnData("SFE_WOLOTSER.COMPLETE_FLG","Y",1)
			endif
			if num(callpoint!.getColumnData("SFE_WOLOTSER.CLOSED_COST"))=0 then
				callpoint!.setColumnData("SFE_WOLOTSER.CLOSED_COST",str(callpoint!.getDevObject("closed_cost")),1)
			endif
		else
			if callpoint!.getColumnData("SFE_WOLOTSER.COMPLETE_FLG")<>"" then
				callpoint!.setColumnData("SFE_WOLOTSER.COMPLETE_FLG","",1)
			endif
			if num(callpoint!.getColumnData("SFE_WOLOTSER.CLOSED_COST"))<>0 then
				callpoint!.setColumnData("SFE_WOLOTSER.CLOSED_COST",str(0),1)
			endif
		endif

		rem --- Enable/disable additional options
		gosub enable_options
	endif
[[SFE_WOLOTSER.AUDE]]
rem --- Adjust how many lot/serial items have been scheduled
	ls_sch_qty=callpoint!.getDevObject("ls_sch_qty")
	ls_sch_qty=ls_sch_qty+num(callpoint!.getColumnData("SFE_WOLOTSER.SCH_PROD_QTY"))
	callpoint!.setDevObject("ls_sch_qty",ls_sch_qty)

rem --- Adjust how many lot/serial items have been closed
	ls_close_qty=callpoint!.getDevObject("ls_close_qty")
	ls_close_qty=ls_close_qty+num(callpoint!.getColumnData("SFE_WOLOTSER.CLS_INP_QTY"))
	callpoint!.setDevObject("ls_close_qty",ls_close_qty)

rem --- Enable/disable additional options
	gosub enable_options
[[SFE_WOLOTSER.BDEL]]
rem --- Adjust how many lot/serial items have been scheduled
	ls_sch_qty=callpoint!.getDevObject("ls_sch_qty")
	ls_sch_qty=ls_sch_qty-num(callpoint!.getColumnData("SFE_WOLOTSER.SCH_PROD_QTY"))
	callpoint!.setDevObject("ls_sch_qty",ls_sch_qty)

rem --- Adjust how many lot/serial items have been closed
	ls_close_qty=callpoint!.getDevObject("ls_close_qty")
	ls_close_qty=ls_close_qty-num(callpoint!.getColumnData("SFE_WOLOTSER.CLS_INP_QTY"))
	callpoint!.setDevObject("ls_close_qty",ls_close_qty)
[[SFE_WOLOTSER.SCH_PROD_QTY.BINP]]
rem --- Capture current lot/ser sch_prod_qty so can make adjustments if it gets changed
	prev_ls_sch_qty=num(callpoint!.getColumnData("SFE_WOLOTSER.SCH_PROD_QTY"))
	callpoint!.setDevObject("prev_ls_sch_qty",prev_ls_sch_qty)

rem --- Initialize sch_prod_qty for lotted item
	if prev_ls_sch_qty=0 and callpoint!.getDevObject("lotser")="L" then
		wo_close_qty=num(callpoint!.getDevObject("cls_inp_qty"))
		if callpoint!.getDevObject("wolotser_action")="close" then
			rem --- Only being used with sfe_woclose form
			ls_close_qty=callpoint!.getDevObject("ls_close_qty")
			callpoint!.setColumnData("SFE_WOLOTSER.SCH_PROD_QTY",str(wo_close_qty-ls_close_qty),1)
			callpoint!.setStatus("MODIFIED")

			rem --- Adjust how many lot/serial items have been scheduled
			ls_sch_qty=callpoint!.getDevObject("ls_sch_qty")
			ls_sch_qty=ls_sch_qty+(wo_close_qty-ls_close_qty)
			callpoint!.setDevObject("ls_sch_qty",ls_sch_qty)

			rem --- Enable/disable additional options
			gosub enable_options
		else
			rem --- Not being used with sfe_woclose form
			wo_sch_qty=num(callpoint!.getDevObject("prod_qty"))
			wo_cls_todt=num(callpoint!.getDevObject("qty_cls_todt"))
			callpoint!.setColumnData("SFE_WOLOTSER.SCH_PROD_QTY",str(wo_sch_qty-(wo_close_qty+wo_cls_todt)),1)
			callpoint!.setStatus("MODIFIED")

			rem --- Adjust how many lot/serial items have been scheduled
			ls_sch_qty=callpoint!.getDevObject("ls_sch_qty")
			ls_sch_qty=ls_sch_qty+(wo_sch_qty-(wo_close_qty+wo_cls_todt))
			callpoint!.setDevObject("ls_sch_qty",ls_sch_qty)

			rem --- Enable/disable additional options
			gosub enable_options
		endif
	endif
[[SFE_WOLOTSER.AGRN]]
rem --- Validate lot/serial quantities the first time in the grid
	if callpoint!.getDevObject("check_ls_qty") then
		callpoint!.setDevObject("check_ls_qty",0)
		gosub validate_ls_qty
	endif

rem --- Enable/disable additional options
	gosub enable_options
[[SFE_WOLOTSER.AOPT-ACLS]]
rem --- Close lot/serial items
	ls_sch_qty=callpoint!.getDevObject("ls_sch_qty")
	ls_close_qty=callpoint!.getDevObject("ls_close_qty")
	max_qty=max(ls_sch_qty-ls_close_qty,0)
	callpoint!.setDevObject("max_qty",max_qty)
	callpoint!.setDevObject("sequence_no",callpoint!.getColumnData("SFE_WOLOTSER.SEQUENCE_NO"))
	wo_location$=callpoint!.getColumnData("SFE_WOLOTSER.WO_LOCATION")
	wo_no$=callpoint!.getColumnData("SFE_WOLOTSER.WO_NO")

	dim dflt_data$[4,1]
	dflt_data$[1,0]="LOTSER_NO"
	dflt_data$[1,1]=callpoint!.getColumnData("SFE_WOLOTSER.LOTSER_NO")
	dflt_data$[2,0]="CLOSE_QTY"
	dflt_data$[2,1]=str(max_qty)
	dflt_data$[3,0]="WO_LOCATION"
	dflt_data$[3,1]=wo_location$
	dflt_data$[4,0]="WO_NO"
	dflt_data$[4,1]=wo_no$

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"SFE_AUTOCLOSELS",
:		stbl("+USER_ID"),
:		"",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]

rem --- Adjust how many lot/serial items have been closed
	ls_close_qty=callpoint!.getDevObject("ls_close_qty")
	ls_close_qty=ls_close_qty+callpoint!.getDevObject("ls_closed")
	callpoint!.setDevObject("ls_close_qty",ls_close_qty)

rem --- Refresh grid with new sfe_wolotser records just created
	callpoint!.setStatus("CLEAR-REFGRID")

rem --- Enable/disable additional options
	gosub enable_options
[[SFE_WOLOTSER.BEND]]
rem --- Get how many lot/serial items need to be closed
	gosub get_close_qty_needed

rem --- Validate lot/serial quantities
rem --- Register will prevents running update if have bad  lot/serial quantities
	gosub validate_ls_qty
[[SFE_WOLOTSER.<CUSTOM>]]
rem ==========================================================================
get_close_qty_needed: rem --- Get how many lot/serial items have been closed, and how many have been scheduled
rem ==========================================================================
	wolotser_dev=fnget_dev("SFE_WOLOTSER")
	dim wolotser$:fnget_tpl$("SFE_WOLOTSER")

	ls_sch_qty=0
	ls_close_qty=0
	wo_location$=callpoint!.getDevObject("wo_loc")
	wo_no$=callpoint!.getDevObject("wo_no")
	read (wolotser_dev,key=firm_id$+wo_location$+wo_no$,dom=*next)
	while 1		
		wolotser_key$=key(wolotser_dev,end=*break)
		if pos(firm_id$+wo_location$+wo_no$=wolotser_key$)<>1 then break
		readrecord (wolotser_dev)wolotser$
		if cvs(wolotser.closed_date$,2)="" then 
			ls_sch_qty=ls_sch_qty+wolotser.sch_prod_qty
			ls_close_qty=ls_close_qty+(wolotser.cls_inp_qty+wolotser.qty_cls_todt)
		endif
	wend
	callpoint!.setDevObject("ls_sch_qty",ls_sch_qty)
	callpoint!.setDevObject("ls_close_qty",ls_close_qty)
	return

rem ==========================================================================
validate_ls_qty: rem --- Validate lot/serial quantities
rem --- validation_err: output
rem ==========================================================================
	validation_err=0
	sf_units_mask$=callpoint!.getDevObject("sf_units_mask")
	wo_sch_qty=num(callpoint!.getDevObject("prod_qty"))
	wo_close_qty=num(callpoint!.getDevObject("cls_inp_qty"))
	wo_cls_todt=num(callpoint!.getDevObject("qty_cls_todt"))
	ls_sch_qty=callpoint!.getDevObject("ls_sch_qty")
	ls_close_qty=callpoint!.getDevObject("ls_close_qty")

	if callpoint!.getDevObject("wolotser_action")<>"close" then
		rem --- Not being used with sfe_woclose form

		if ls_sch_qty<>0 and ls_sch_qty<wo_sch_qty-wo_cls_todt then
			msg_id$="SF_LS_SCH_LT_WO_SCH"
			dim msg_tokens$[2]
			msg_tokens$[1]=cvs(str(ls_sch_qty:sf_units_mask$),3)
			msg_tokens$[2]=cvs(str(wo_sch_qty-wo_cls_todt:sf_units_mask$),3)
			gosub disp_message
			validation_err=1
		endif

		if ls_sch_qty>wo_sch_qty-wo_cls_todt then
			msg_id$="SF_LS_SCH_GT_WO_SCH"
			dim msg_tokens$[2]
			msg_tokens$[1]=cvs(str(ls_sch_qty:sf_units_mask$),3)
			msg_tokens$[2]=cvs(str(wo_sch_qty-wo_cls_todt:sf_units_mask$),3)
			gosub disp_message
			validation_err=2
		endif
	else
		rem --- Only being used with sfe_woclose form

		if ls_sch_qty<wo_close_qty then
			msg_id$="SF_LS_SCH_LT_WO_CLS"
			dim msg_tokens$[2]
			msg_tokens$[1]=cvs(str(ls_sch_qty:sf_units_mask$),3)
			msg_tokens$[2]=cvs(str(wo_close_qty:sf_units_mask$),3)
			gosub disp_message
			validation_err=3
		endif

		if ls_sch_qty>wo_close_qty then
			msg_id$="SF_LS_SCH_GT_WO_CLS"
			dim msg_tokens$[2]
			msg_tokens$[1]=cvs(str(ls_sch_qty:sf_units_mask$),3)
			msg_tokens$[2]=cvs(str(wo_close_qty:sf_units_mask$),3)
			gosub disp_message
			validation_err=4
		endif

		if ls_close_qty<ls_sch_qty then
			msg_id$="SF_LS_CLS_LT_LS_SCH"
			dim msg_tokens$[2]
			msg_tokens$[1]=cvs(str(ls_close_qty:sf_units_mask$),3)
			msg_tokens$[2]=cvs(str(ls_sch_qty:sf_units_mask$),3)
			gosub disp_message
			validation_err=5
		endif

		if ls_close_qty>ls_sch_qty then
			msg_id$="SF_LS_CLS_GT_LS_SCH"
			dim msg_tokens$[2]
			msg_tokens$[1]=cvs(str(ls_close_qty:sf_units_mask$),3)
			msg_tokens$[2]=cvs(str(ls_sch_qty:sf_units_mask$),3)
			gosub disp_message
			validation_err=6
		endif
	endif
	return

rem ==========================================================================
enable_options: rem --- Enable/disable additional options
rem ==========================================================================
	rem --- Disable auto-assign and auto-close options when grid has been modified.
	rem --- Need to force write of current grid rows to file so they can be updated in these additional options.
	grid_modified=0
	for row=0 to GridVect!.size()-1
		if callpoint!.getGridRowModifyStatus(row)="Y" or callpoint!.getGridRowDeleteStatus(row)="Y" then
			grid_modified=1
			break
		endif
	next row

	if callpoint!.getDevObject("lotser")<>"S" or grid_modified then
		rem --- Disable auto-assign and auto-close options when not serialized, or grid is in modified state
		callpoint!.setOptionEnabled("AUTO",0)
		callpoint!.setOptionEnabled("ACLS",0)
	else
		rem --- Disable auto-assign option when don't need more than one
		close_qty_needed=num(callpoint!.getDevObject("cls_inp_qty"))-callpoint!.getDevObject("ls_sch_qty")
		if close_qty_needed<=1 then
			callpoint!.setOptionEnabled("AUTO",0)
		else
			callpoint!.setOptionEnabled("AUTO",1)
		endif

		rem --- Disable auto-close option when not being used with sfe_woclose form 
		rem --- or don't have more than one ready to close
		ls_qty_not_closed=callpoint!.getDevObject("ls_sch_qty")-callpoint!.getDevObject("ls_close_qty")
		if callpoint!.getDevObject("wolotser_action")<>"close" or ls_qty_not_closed<=1 then
			callpoint!.setOptionEnabled("ACLS",0)
		else
			callpoint!.setOptionEnabled("ACLS",1)
		endif
	endif
	return
[[SFE_WOLOTSER.AGDR]]
rem --- Disable all input fields if lot/serial has been closed
	if callpoint!.getColumnData("SFE_WOLOTSER.CLOSED_FLAG")="Y" then
		this_row=callpoint!.getValidationRow()
		callpoint!.setColumnEnabled(this_row,"SFE_WOLOTSER.LOTSER_NO",0)
		callpoint!.setColumnEnabled(this_row,"SFE_WOLOTSER.WO_LS_CMT",0)
		callpoint!.setColumnEnabled(this_row,"SFE_WOLOTSER.SCH_PROD_QTY",0)
		callpoint!.setColumnEnabled(this_row,"SFE_WOLOTSER.CLS_INP_QTY",0)
		callpoint!.setColumnEnabled(this_row,"SFE_WOLOTSER.COMPLETE_FLG",0)
	endif

rem --- Initialize complete flag as necessary
	complete_flg$=callpoint!.getColumnData("SFE_WOLOTSER.COMPLETE_FLG")
	if pos(complete_flg$="YN")=0 then
		callpoint!.setColumnData("SFE_WOLOTSER.COMPLETE_FLG","N",1)
	endif
[[SFE_WOLOTSER.CLS_INP_QTY.AVAL]]
rem --- Validate this cls_inp_qty if changed
	this_cls_inp_qty=num(callpoint!.getUserInput())
	prev_cls_inp_qty=callpoint!.getDevObject("prev_cls_inp_qty")
	if this_cls_inp_qty<>prev_cls_inp_qty
		rem --- Restrict cls_inp_qty value for serialized items
		if callpoint!.getDevObject("lotser")="S" and (this_cls_inp_qty<0 or this_cls_inp_qty>1) then
			callpoint!.setStatus("ABORT")
			break
		endif

		rem --- Adjust how many lot/serial items have been closed
		ls_close_qty=callpoint!.getDevObject("ls_close_qty")
		ls_close_qty=ls_close_qty+(this_cls_inp_qty-prev_cls_inp_qty)
		callpoint!.setDevObject("ls_close_qty",ls_close_qty)

		rem --- Update complete flag and closed cost
		this_ls_sch_qty=num(callpoint!.getColumnData("SFE_WOLOTSER.SCH_PROD_QTY"))
		this_ls_cls_todt=num(callpoint!.getColumnData("SFE_WOLOTSER.QTY_CLS_TODT"))
		if this_cls_inp_qty<>0 then
			if this_cls_inp_qty=this_ls_sch_qty-this_ls_cls_todt and
:			callpoint!.getColumnData("SFE_WOLOTSER.COMPLETE_FLG")<>"Y" then
				callpoint!.setColumnData("SFE_WOLOTSER.COMPLETE_FLG","Y",1)
			endif
			if num(callpoint!.getColumnData("SFE_WOLOTSER.CLOSED_COST"))=0 then
				callpoint!.setColumnData("SFE_WOLOTSER.CLOSED_COST",str(callpoint!.getDevObject("closed_cost")),1)
			endif
		else
			if callpoint!.getColumnData("SFE_WOLOTSER.COMPLETE_FLG")<>"" then
				callpoint!.setColumnData("SFE_WOLOTSER.COMPLETE_FLG","",1)
			endif
			if num(callpoint!.getColumnData("SFE_WOLOTSER.CLOSED_COST"))<>0 then
				callpoint!.setColumnData("SFE_WOLOTSER.CLOSED_COST",str(0),1)
			endif
		endif

		rem --- Enable/disable additional options
		gosub enable_options

		rem --- Validate this_cls_inp_qty
		if this_cls_inp_qty+this_ls_cls_todt<this_ls_sch_qty then
			msg_id$="SF_LS_CLS_LT_LS_SCH"
			dim msg_tokens$[2]
			msg_tokens$[1]=cvs(str(this_cls_inp_qty+this_ls_cls_todt:sf_units_mask$),3)
			msg_tokens$[2]=cvs(str(this_ls_sch_qty:sf_units_mask$),3)
			gosub disp_message
		endif
		if this_cls_inp_qty+this_ls_cls_todt>this_ls_sch_qty then
			msg_id$="SF_LS_CLS_GT_LS_SCH"
			dim msg_tokens$[2]
			msg_tokens$[1]=cvs(str(this_cls_inp_qty+this_ls_cls_todt:sf_units_mask$),3)
			msg_tokens$[2]=cvs(str(this_ls_sch_qty:sf_units_mask$),3)
			gosub disp_message
		endif
	endif
[[SFE_WOLOTSER.AOPT-AUTO]]
rem --- Generate new lot/serial numbers
	wo_close_qty=num(callpoint!.getDevObject("cls_inp_qty"))
	ls_sch_qty=callpoint!.getDevObject("ls_sch_qty")
	max_qty=max(wo_close_qty-ls_sch_qty,0)
	callpoint!.setDevObject("max_qty",max_qty)
	callpoint!.setDevObject("sequence_no",callpoint!.getColumnData("SFE_WOLOTSER.SEQUENCE_NO"))
	wo_location$=callpoint!.getColumnData("SFE_WOLOTSER.WO_LOCATION")
	wo_no$=callpoint!.getColumnData("SFE_WOLOTSER.WO_NO")

	dim dflt_data$[6,1]
	dflt_data$[1,0]="LOTSER_NO"
	dflt_data$[1,1]=callpoint!.getColumnData("SFE_WOLOTSER.LOTSER_NO")
	dflt_data$[2,0]="GEN_QTY"
	dflt_data$[2,1]=str(max_qty)
	dflt_data$[3,0]="WO_LOCATION"
	dflt_data$[3,1]=wo_location$
	dflt_data$[4,0]="WO_NO"
	dflt_data$[4,1]=wo_no$
	dflt_data$[5,0]="WAREHOUSE_ID"
	dflt_data$[5,1]=callpoint!.getDevObject("warehouse_id")
	dflt_data$[6,0]="ITEM_ID"
	dflt_data$[6,1]=callpoint!.getDevObject("item_id")

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"SFE_AUTOGENLS",
:		stbl("+USER_ID"),
:		"",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]

rem --- Adjust how many lot/serial items have been scheduled
	ls_sch_qty=callpoint!.getDevObject("ls_sch_qty")
	ls_sch_qty=ls_sch_qty+callpoint!.getDevObject("ls_created")
	callpoint!.setDevObject("ls_sch_qty",ls_sch_qty)

rem --- Refresh grid with new sfe_wolotser records just created
	callpoint!.setStatus("CLEAR-REFGRID")

rem --- Enable/disable additional options
	gosub enable_options
[[SFE_WOLOTSER.LOTSER_NO.AVAL]]
rem --- Do not validate unless lotser_no has changed
	lotser_no$=callpoint!.getUserInput()
	prev_lotser_no$=callpoint!.getDevObject("prev_lotser_no")
	if lotser_no$=prev_lotser_no$ then break

rem --- Verify lot/serial not currently in inventory
	lsmaster_dev=fnget_dev("@IVM_LSMASTER")
	dim lsmaster$:fnget_tpl$("@IVM_LSMASTER")
	warehouse_id$=callpoint!.getDevObject("warehouse_id")
	item_id$=callpoint!.getDevObject("item_id")
	lsmaster_found=0
	findrecord(lsmaster_dev,key=firm_id$+warehouse_id$+item_id$+lotser_no$,dom=*next)lsmaster$; lsmaster_found=1
	if lsmaster_found and lsmaster.qty_on_hand-lsmaster.qty_commit>0 then
		if callpoint!.getDevObject("lotser")="S" then
			rem --- Can't use serial number that is already on hand
			msg_id$="SF_SERIAL_ON_HAND"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		else
			rem --- Warn that items are already on hand for this lot
			msg_id$="SF_LOT_AVAILABLE"
			gosub disp_message
		endif
	endif

rem --- Verify lot/serial can be used
	rem --- Has this lotser_no already been entered for this work order?
	wo_no$=callpoint!.getColumnData("SFE_WOLOTSER.WO_NO")
	dim wolotser$:fnget_tpl$("@SFE_WOLOTSER")
	lotser_used=0
	for row=0 to GridVect!.size()-1
		wolotser$=GridVect!.getItem(row)
		if lotser_no$=wolotser.lotser_no$ then
			rem --- This lotser_no already entered for this work order being closed.
			lotser_used=1
			msg_id$="SF_LS_ENTERED"
			dim msg_tokens$[2]
			msg_tokens$[1]=cvs(lotser_no$,3)
			msg_tokens$[2]=cvs(wo_no$,3)
			gosub disp_message
			break
		endif
	next row
	if lotser_used then
		callpoint!.setStatus("ABORT")
		break
	endif

	rem --- Has this lotser_no already been written to sfe_wolotser?
	wolotser_dev=fnget_dev("@SFE_WOLOTSER")
	wolotser_found=0
	findrecord(wolotser_dev,key=firm_id$+lotser_no$,knum="AO_LOTSER",dom=*next)wolotser$; wolotser_found=1
	if wolotser_found then
		rem --- This lotser_no already entered for a work order being closed.
		wo_location$=callpoint!.getColumnData("SFE_WOLOTSER.WO_LOCATION")
		if wolotser.wo_location$=wo_location$ and wolotser.wo_no$=wo_no$ then
			rem --- This lotser_no already entered for this work order being closed.
			msg_id$="SF_LS_ENTERED"
			dim msg_tokens$[2]
			msg_tokens$[1]=cvs(lotser_no$,3)
			msg_tokens$[2]=cvs(wolotser.wo_no$,3)
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		else
			rem --- This lotser_no already entered for a different work order being closed.
			rem --- Is that other work order for the same item (finished good)?
			womastr_dev=fnget_dev("@SFE_WOMASTR")
			dim womastr$:fnget_tpl$("@SFE_WOMASTR")
			womastr_found=0
			findrecord(womastr_dev,key=firm_id$+wolotser.wo_location$+wolotser.wo_no$,dom=*next)womastr$; womastr_found=1
			if womastr_found and womastr.warehouse_id$=warehouse_id$ and womastr.item_id$=item_id$ then
				msg_id$="SF_LS_ENTERED"
				dim msg_tokens$[2]
				msg_tokens$[1]=cvs(lotser_no$,3)
				msg_tokens$[2]=cvs(wolotser.wo_no$,3)
				gosub disp_message
				callpoint!.setStatus("ABORT")
				break
			endif
		endif
	endif

rem --- Initialize serialized quantity to one
	if callpoint!.getDevObject("lotser")="S" and
:	callpoint!.getColumnData("SFE_WOLOTSER.SCH_PROD_QTY")="0" then
		callpoint!.setColumnData("SFE_WOLOTSER.SCH_PROD_QTY","1",1)

		rem --- CLS_INP_QTY is disabled for serialized items, so adjust lot/serial quantity here
		ls_sch_qty=callpoint!.getDevObject("ls_sch_qty")
		ls_sch_qty=ls_sch_qty+1
		callpoint!.setDevObject("ls_sch_qty",ls_sch_qty)
	endif

rem --- Enable/disable additional options
	gosub enable_options
[[SFE_WOLOTSER.SCH_PROD_QTY.AVAL]]
rem --- Validate this sch_prod_qty if changed
	this_ls_sch_qty=num(callpoint!.getUserInput())
	prev_ls_sch_qty=callpoint!.getDevObject("prev_ls_sch_qty")
	if this_ls_sch_qty<>prev_ls_sch_qty then
		rem --- Adjust how many lot/serial items have been scheduled
		ls_sch_qty=callpoint!.getDevObject("ls_sch_qty")
		ls_sch_qty=ls_sch_qty+(this_ls_sch_qty-prev_ls_sch_qty)
		callpoint!.setDevObject("ls_sch_qty",ls_sch_qty)

		rem --- Enable/disable additional options
		gosub enable_options

		rem --- Validate this_ls_sch_qty
		wo_close_qty=num(callpoint!.getDevObject("cls_inp_qty"))
		if this_ls_sch_qty<wo_close_qty then
			msg_id$="SF_LS_SCH_LT_WO_CLS"
			dim msg_tokens$[2]
			msg_tokens$[1]=cvs(str(this_ls_sch_qty:sf_units_mask$),3)
			msg_tokens$[2]=cvs(str(ls_close_qty:sf_units_mask$),3)
			gosub disp_message
		endif
		if this_ls_sch_qty>wo_close_qty then
			msg_id$="SF_LS_SCH_GT_WO_CLS"
			dim msg_tokens$[2]
			msg_tokens$[1]=cvs(str(this_ls_sch_qty:sf_units_mask$),3)
			msg_tokens$[2]=cvs(str(wo_close_qty:sf_units_mask$),3)
			gosub disp_message
		endif
	endif
[[SFE_WOLOTSER.BSHO]]
rem --- Open Files
	num_files=3
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFE_WOMASTR",open_opts$[1]="OTA@"
	open_tables$[2]="SFE_WOLOTSER",open_opts$[2]="OTA@"
	open_tables$[3]="IVM_LSMASTER",open_opts$[3]="OTA@"

	gosub open_tables

rem --- Disable all input fields if work order has been closed
	if callpoint!.getDevObject("wo_status")="C" then
		callpoint!.setColumnEnabled(-1,"SFE_WOLOTSER.LOTSER_NO",-1)
		callpoint!.setColumnEnabled(-1,"SFE_WOLOTSER.WO_LS_CMT",-1)
		callpoint!.setColumnEnabled(-1,"SFE_WOLOTSER.SCH_PROD_QTY",-1)
		callpoint!.setColumnEnabled(-1,"SFE_WOLOTSER.CLS_INP_QTY",-1)
		callpoint!.setColumnEnabled(-1,"SFE_WOLOTSER.COMPLETE_FLG",-1)
	endif

rem --- Disable fields when closing work order, or not
	if callpoint!.getDevObject("wolotser_action")<>"close" then
		rem --- Not being used with sfe_woclose form
		callpoint!.setColumnEnabled(-1,"SFE_WOLOTSER.CLS_INP_QTY",-1)
		callpoint!.setColumnEnabled(-1,"SFE_WOLOTSER.COMPLETE_FLG",-1)
	endif

rem --- Disable sch_prod_qty field if serialized
	if callpoint!.getDevObject("lotser")="S" 		
		callpoint!.setColumnEnabled(-1,"SFE_WOLOTSER.SCH_PROD_QTY",-1)
	endif

rem --- Get how many lot/serial items need to be closed
	gosub get_close_qty_needed
	callpoint!.setDevObject("check_ls_qty",1)

rem --- Enable/disable additional options
	gosub enable_options

rem --- Get SF unit mask
	call stbl("+DIR_PGM")+"adc_getmask.aon","","SF","U","",sf_units_mask$,0,0
	callpoint!.setDevObject("sf_units_mask",sf_units_mask$)
