[[BMM_BILLMAT.MEMO_1024.AVAL]]
rem --- Store first part of memo_1024 in ext_comment.
rem --- This AVAL is hit if user navigates via arrows or clicks on the memo_1024 field, and double-clicks or ctrl-F to bring up editor.
rem --- If use Comment field, or use ctrl-C or Comments button, code in the comment_entry subroutine is hit instead.
	disp_text$=callpoint!.getUserInput()
	if disp_text$<>callpoint!.getColumnUndoData("BMM_BILLMAT.MEMO_1024")
		dim ext_comments$(60)
		ext_comments$(1)=disp_text$(1,pos($0A$=disp_text$+$0A$)-1)
		callpoint!.setColumnData("BMM_BILLMAT.MEMO_1024",disp_text$,1)
		callpoint!.setColumnData("BMM_BILLMAT.EXT_COMMENTS",ext_comments$,1)
		callpoint!.setStatus("MODIFIED")
	endif
[[BMM_BILLMAT.EXT_COMMENTS.BINP]]
rem --- Launch Comments dialog
	gosub comment_entry
	callpoint!.setStatus("ABORT")
[[BMM_BILLMAT.AOPT-COMM]]
rem --- Launch Comments dialog
	gosub comment_entry
[[BMM_BILLMAT.LINE_TYPE.AVAL]]
rem --- Enable/disable Comments button
	line_type$=callpoint!.getColumnData("BMM_BILLMAT.LINE_TYPE")
	gosub enable_comments
[[BMM_BILLMAT.MEMO_1024.BINQ]]
rem --- (Barista Bug 9179 workaround) If grid cell isn't editable, then abort so new text can't be entered via edit control.
	maintGrid!=Form!.getControl(num(stbl("+GRID_CTL")))
	col_hdr$=callpoint!.getTableColumnAttribute("BMM_BILLMAT.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(maintGrid!, col_hdr$)
	this_row=callpoint!.getValidationRow()
	isEditable=maintGrid!.isCellEditable(this_row,memo_1024_col)
	if !isEditable then callpoint!.setStatus("ABORT")
[[BMM_BILLMAT.AREC]]
rem --- Maintain count of inserted rows (don't count if last row)
	if GridVect!.size()>1+callpoint!.getValidationRow() then
		insertedRows=callpoint!.getDevObject("insertedRows")
		insertedRows=insertedRows+1
		callpoint!.setDevObject("insertedRows",insertedRows)
	endif
[[BMM_BILLMAT.AOPT-AUTO]]
rem --- Update displayed row nums for inserted and deleted rows, or
	if callpoint!.getDevObject("insertedRows")+callpoint!.getDevObject("deletedRows") then
		msg_id$="SF_UPDATE_ROW_NO"
		gosub disp_message

		callpoint!.setDevObject("insertedRows",0)
		callpoint!.setDevObject("deletedRows",0)
		callpoint!.setStatus("REFGRID")
		break
	endif

rem --- Auto create Reference Numbers
	callpoint!.setDevObject("MatlTable","BMM_BILLMAT")
	callpoint!.setDevObject("GridVect",GridVect!)

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"SFE_WOREFNUM",
:		stbl("+USER_ID"),
:		"MNT",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]

rem --- Update grid with changes
	callpoint!.setStatus("REFGRID")
[[BMM_BILLMAT.AGRN]]
rem --- Set ROW_NUM
	dim bmm_billmat$:fnget_tpl$("BMM_BILLMAT")
	wk$=fattr(bmm_billmat$,"material_seq")
	new_row_num=1+callpoint!.getValidationRow()
	callpoint!.setColumnData("<<DISPLAY>>.ROW_NUM",pad(str(new_row_num),dec(wk$(10,2)),"R","0"),1)

rem --- Enable/disable Comments button
	line_type$=callpoint!.getColumnData("BMM_BILLMAT.LINE_TYPE")
	gosub enable_comments
[[BMM_BILLMAT.AGDR]]
rem --- Set ROW_NUM (material_seq may not be numbered sequentially from one when DataPorted)
	dim bmm_billmat$:fnget_tpl$("BMM_BILLMAT")
	wk$=fattr(bmm_billmat$,"material_seq")
	new_row_num=1+callpoint!.getValidationRow()
	callpoint!.setColumnData("<<DISPLAY>>.ROW_NUM",pad(str(new_row_num),dec(wk$(10,2)),"R","0"),1)

rem --- Track wo_ref_num in Map to insure they are unique
	refnumMap!=callpoint!.getDevObject("refnumMap")
	wo_ref_num$=callpoint!.getColumnData("BMM_BILLMAT.WO_REF_NUM")
	if cvs(wo_ref_num$,2)<>"" then
		refnumMap!.put(wo_ref_num$,"")
	endif

rem --- Enable/disable Comments button
	line_type$=callpoint!.getColumnData("BMM_BILLMAT.LINE_TYPE")
	gosub enable_comments
[[BMM_BILLMAT.WO_REF_NUM.AVAL]]
rem --- Verify wo_ref_num is unique
	wo_ref_num$=callpoint!.getUserInput()
	prev_wo_ref_num$=callpoint!.getDevObject("prev_wo_ref_num")
	refnumMap!=callpoint!.getDevObject("refnumMap")
	if wo_ref_num$<>prev_wo_ref_num$ then
		if refnumMap!.containsKey(wo_ref_num$) then
			msg_id$="SF_DUP_REF_NUM"
			dim msg_tokens$[1]
			msg_tokens$[1]=wo_ref_num$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		else
			if cvs(wo_ref_num$,2)<>"" then refnumMap!.put(wo_ref_num$,"")
			if cvs(prev_wo_ref_num$,2)<>"" then refnumMap!.remove(prev_wo_ref_num$)
		endif
	endif
[[BMM_BILLMAT.BDEL]]
rem --- Update refnumMap!
	refnumMap!=callpoint!.getDevObject("refnumMap")
	wo_ref_num$=callpoint!.getColumnData("BMM_BILLMAT.WO_REF_NUM")
	if cvs(wo_ref_num$,2)<>"" then
		refnumMap!.remove(wo_ref_num$)
	endif

rem --- Maintain count of deleted rows
	deletedRows=callpoint!.getDevObject("deletedRows")
	deletedRows=deletedRows+1
	callpoint!.setDevObject("deletedRows",deletedRows)
[[BMM_BILLMAT.WO_REF_NUM.BINP]]
rem --- Capture starting wo_ref_num
	prev_wo_ref_num$=callpoint!.getColumnData("BMM_BILLMAT.WO_REF_NUM")
	callpoint!.setDevObject("prev_wo_ref_num",prev_wo_ref_num$)
[[BMM_BILLMAT.BUDE]]
rem --- verify wo_ref_num is unique
	refnumMap!=callpoint!.getDevObject("refnumMap")
	wo_ref_num$=callpoint!.getColumnData("BMM_BILLMAT.WO_REF_NUM")
	if cvs(wo_ref_num$,2)<>"" then
		if refnumMap!.containsKey(wo_ref_num$) then
			msg_id$="SF_DUP_REF_NUM"
			dim msg_tokens$[1]
			msg_tokens$[1]=wo_ref_num$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		else
			refnumMap!.put(wo_ref_num$,"")
		endif
	endif

rem --- Maintain count of deleted rows
	deletedRows=callpoint!.getDevObject("deletedRows")
	deletedRows=deletedRows-1
	callpoint!.setDevObject("deletedRows",deletedRows)
[[BMM_BILLMAT.BWRI]]
rem --- Divisor and Alt Factor need to be 1 if 0

	if callpoint!.getColumnData("BMM_BILLMAT.LINE_TYPE")="S"
		if num(callpoint!.getColumnData("BMM_BILLMAT.DIVISOR"))=0
			callpoint!.setColumnData("BMM_BILLMAT.DIVISOR","1")
		endif
		if num(callpoint!.getColumnData("BMM_BILLMAT.ALT_FACTOR"))=0
			callpoint!.setColumnData("BMM_BILLMAT.ALT_FACTOR","1")
		endif

		if num(callpoint!.getColumnData("BMM_BILLMAT.QTY_REQUIRED"))=0
			msg_id$="IV_QTY_GT_ZERO"
			gosub disp_message
			callpoint!.setFocus(callpoint!.getValidationRow(),"BMM_BILLMAT.QTY_REQUIRED")
		endif
	endif
[[BMM_BILLMAT.OP_INT_SEQ_REF.AINP]]
	ops_lines!=SysGUI!.makeVector()
	ops_items!=SysGUI!.makeVector()
	ops_list!=SysGUI!.makeVector()

	ops_lines!=callpoint!.getDevObject("ops_lines")
	ops_items!=callpoint!.getDevObject("ops_items")
	ops_list!=callpoint!.getDevObject("ops_list")
[[BMM_BILLMAT.OBSOLT_DATE.AVAL]]
rem --- Check for valid dates

	eff_date$=callpoint!.getColumnData("BMM_BILLMAT.EFFECT_DATE")
	obs_date$=callpoint!.getUserInput()
	msg_id$="BM_EFF_OBS"
	gosub check_dates
[[BMM_BILLMAT.EFFECT_DATE.AVAL]]
rem --- Check for valid dates

	eff_date$=callpoint!.getUserInput()
	obs_date$=callpoint!.getColumnData("BMM_BILLMAT.OBSOLT_DATE")
	msg_id$="BM_OBS_EFF"
	gosub check_dates
[[BMM_BILLMAT.AGRE]]
rem --- Display Net Quantity

	if callpoint!.getColumnData("BMM_BILLMAT.LINE_TYPE")="S"
		qty_req=num(callpoint!.getColumnData("BMM_BILLMAT.QTY_REQUIRED"))
		alt_fact=num(callpoint!.getColumnData("BMM_BILLMAT.ALT_FACTOR"))
		divisor=num(callpoint!.getColumnData("BMM_BILLMAT.DIVISOR"))
		scrap_fact=num(callpoint!.getColumnData("BMM_BILLMAT.SCRAP_FACTOR"))
		gosub calc_net
		item$=callpoint!.getColumnData("BMM_BILLMAT.ITEM_ID")
		gosub check_sub
	endif
[[BMM_BILLMAT.BGDR]]
rem --- Display Net Quantity

	qty_req=num(callpoint!.getColumnData("BMM_BILLMAT.QTY_REQUIRED"))
	alt_fact=num(callpoint!.getColumnData("BMM_BILLMAT.ALT_FACTOR"))
	divisor=num(callpoint!.getColumnData("BMM_BILLMAT.DIVISOR"))
	scrap_fact=num(callpoint!.getColumnData("BMM_BILLMAT.SCRAP_FACTOR"))
	gosub calc_net
	item$=callpoint!.getColumnData("BMM_BILLMAT.ITEM_ID")
	gosub check_sub
[[BMM_BILLMAT.ITEM_ID.AVAL]]
rem "Inventory Inactive Feature"
item_id$=callpoint!.getUserInput()
ivm01_dev=fnget_dev("IVM_ITEMMAST")
ivm01_tpl$=fnget_tpl$("IVM_ITEMMAST")
dim ivm01a$:ivm01_tpl$
ivm01a_key$=firm_id$+item_id$
find record (ivm01_dev,key=ivm01a_key$,err=*break)ivm01a$
if ivm01a.item_inactive$="Y" then
   msg_id$="IV_ITEM_INACTIVE"
   dim msg_tokens$[2]
   msg_tokens$[1]=cvs(ivm01a.item_id$,2)
   msg_tokens$[2]=cvs(ivm01a.display_desc$,2)
   gosub disp_message
   callpoint!.setStatus("ACTIVATE")
endif

rem --- Component must not be the same as the Master Bill

	item$=callpoint!.getUserInput()
	if item$ = callpoint!.getColumnData("BMM_BILLMAT.BILL_NO")
		msg_id$="BM_BAD_COMP_ITEM"
		gosub disp_message
		callpoint!.setUserInput("")
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Check to see if item is a Sub Bill

	gosub check_sub

rem --- Set defaults for new record

	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y"
		callpoint!.setColumnData("BMM_BILLMAT.ALT_FACTOR","1")
		callpoint!.setColumnData("BMM_BILLMAT.DIVISOR","1")
		item_dev=fnget_dev("IVM_ITEMMAST")
		dim item_tpl$:fnget_tpl$("IVM_ITEMMAST")
		readrecord(item_dev,key=firm_id$+item$)item_tpl$
		callpoint!.setColumnData("BMM_BILLMAT.UNIT_MEASURE",item_tpl.unit_of_sale$)
		callpoint!.setStatus("REFRESH")
	endif
[[BMM_BILLMAT.SCRAP_FACTOR.AVAL]]
rem --- Display Net Quantity

	qty_req=num(callpoint!.getColumnData("BMM_BILLMAT.QTY_REQUIRED"))
	alt_fact=num(callpoint!.getColumnData("BMM_BILLMAT.ALT_FACTOR"))
	divisor=num(callpoint!.getColumnData("BMM_BILLMAT.DIVISOR"))
	scrap_fact=num(callpoint!.getUserInput())
	gosub calc_net
[[BMM_BILLMAT.DIVISOR.AVAL]]
rem --- Display Net Quantity

	qty_req=num(callpoint!.getColumnData("BMM_BILLMAT.QTY_REQUIRED"))
	alt_fact=num(callpoint!.getColumnData("BMM_BILLMAT.ALT_FACTOR"))
	divisor=num(callpoint!.getUserInput())
	scrap_fact=num(callpoint!.getColumnData("BMM_BILLMAT.SCRAP_FACTOR"))
	gosub calc_net
[[BMM_BILLMAT.ALT_FACTOR.AVAL]]
rem --- Display Net Quantity

	qty_req=num(callpoint!.getColumnData("BMM_BILLMAT.QTY_REQUIRED"))
	alt_fact=num(callpoint!.getUserInput())
	divisor=num(callpoint!.getColumnData("BMM_BILLMAT.DIVISOR"))
	scrap_fact=num(callpoint!.getColumnData("BMM_BILLMAT.SCRAP_FACTOR"))
	gosub calc_net
[[BMM_BILLMAT.QTY_REQUIRED.AVAL]]
rem --- Display Net Quantity

	if callpoint!.getColumnData("BMM_BILLMAT.LINE_TYPE")="S"
		if num(callpoint!.getUserInput())=0
			msg_id$="IV_QTY_GT_ZERO"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	endif
	qty_req=num(callpoint!.getUserInput())
	alt_fact=num(callpoint!.getColumnData("BMM_BILLMAT.ALT_FACTOR"))
	divisor=num(callpoint!.getColumnData("BMM_BILLMAT.DIVISOR"))
	scrap_fact=num(callpoint!.getColumnData("BMM_BILLMAT.SCRAP_FACTOR"))
	gosub calc_net
[[BMM_BILLMAT.<CUSTOM>]]
rem ===================================================================
calc_net:
rem --- qty_req:		input
rem --- alt_fact:			input
rem --- divisor:			input
rem --- scrap_fact:		input
rem ===================================================================

	old_prec = tcb(14)
	precision callpoint!.getDevObject("this_precision")

	if divisor=0 divisor=1
	yield_pct=callpoint!.getDevObject("yield")
	net_qty=1*BmUtils.netQuantityRequired(1*qty_req,1*alt_fact,1*divisor,1*yield_pct,1*scrap_fact)
	callpoint!.setColumnData("<<DISPLAY>>.NET_REQD",str(net_qty))
	whse$=callpoint!.getDevObject("dflt_whse")
	item$=callpoint!.getColumnData("BMM_BILLMAT.ITEM_ID")
	ivm02_dev=fnget_dev("IVM_ITEMWHSE")
	dim ivm02$:fnget_tpl$("IVM_ITEMWHSE")
	read record (ivm02_dev,key=firm_id$+whse$+item$,dom=*next) ivm02$
	callpoint!.setColumnData("<<DISPLAY>>.UNIT_COST",ivm02.unit_cost$)
	callpoint!.setColumnData("<<DISPLAY>>.TOTAL_COST",str(ivm02.unit_cost*net_qty))

	precision old_prec

	return

rem ===================================================================
check_sub:
rem --- item$:			input
rem ===================================================================

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="BMM_BILLMAST",open_opts$[1]="OTAN[2_]"
	gosub open_tables
	sub_bill$=""
	while 1
		find (num(open_chans$[1]),key=firm_id$+item$,dom=*break)
		sub_bill$="*"
		break
	wend
	open_opts$[1]="CX[2_]"
	gosub open_tables
	callpoint!.setColumnData("<<DISPLAY>>.SUB_BILL",sub_bill$,1)

	return

rem ===================================================================
check_dates:
rem eff_date$	input
rem obs_date$	input
rem msg_id$	input
rem ===================================================================

	if cvs(obs_date$,3)<>""
		if obs_date$<=eff_date$
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	endif

	return

rem ==========================================================================
comment_entry:
rem --- on a line where you can access the ext_comments field, pop the new memo_1024 editor instead
rem --- the editor can be popped on demand for any line using the Comments button (alt-C),
rem --- but will automatically pop for lines where the ext_comments field is enabled.
rem ==========================================================================

	disp_text$=callpoint!.getColumnData("BMM_BILLMAT.MEMO_1024")
	sv_disp_text$=disp_text$

	rem --- Comments are only editable for line type M
	line_type$=callpoint!.getColumnData("BMM_BILLMAT.LINE_TYPE")
	if line_type$="M" then
		editable$="YES"
	else
		editable$="NO"
	endif

	force_loc$="NO"
	baseWin!=null()
	startx=0
	starty=0
	shrinkwrap$="NO"
	html$="NO"
	dialog_result$=""

	call stbl("+DIR_SYP")+ "bax_display_text.bbj",
:		"Comments/Message Line",
:		disp_text$, 
:		table_chans$[all], 
:		editable$, 
:		force_loc$, 
:		baseWin!, 
:		startx, 
:		starty, 
:		shrinkwrap$, 
:		html$, 
:		dialog_result$

	if disp_text$<>sv_disp_text$
		ext_comments$=disp_text$(1,pos($0A$=disp_text$+$0A$)-1)
		callpoint!.setColumnData("BMM_BILLMAT.MEMO_1024",disp_text$,1)
		callpoint!.setColumnData("BMM_BILLMAT.EXT_COMMENTS",ext_comments$,1)
		callpoint!.setStatus("MODIFIED")
	endif

	callpoint!.setStatus("ACTIVATE")

	return

rem ========================================================
enable_comments:
rem line_type:	input
rem ========================================================

	if line_type$="M" then
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"BMM_BILLMAT.MEMO_1024",1)
		callpoint!.setOptionEnabled("COMM",1)
	else
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"BMM_BILLMAT.MEMO_1024",0)
		callpoint!.setOptionEnabled("COMM",0)
	endif

	return
[[BMM_BILLMAT.BSHO]]
rem --- Setup java class for Derived Data Element

	use ::ado_util.src::util
	use ::bmo_BmUtils.aon::BmUtils
	declare BmUtils bmUtils!

rem --- Set column size for memo_1024 field very small so it doesn't take up room, but still available for hover-over of memo contents

	maintGrid!=Form!.getControl(num(stbl("+GRID_CTL")))
	col_hdr$=callpoint!.getTableColumnAttribute("BMM_BILLMAT.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(maintGrid!, col_hdr$)
	maintGrid!.setColumnWidth(memo_1024_col,15)

rem --- init data

	refnumMap!=new java.util.HashMap()
	callpoint!.setDevObject("refnumMap",refnumMap!)
	callpoint!.setDevObject("insertedRows",0)
	callpoint!.setDevObject("deletedRows",0)

rem --- Open files for later use

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVM_ITEMMAST",open_opts$[1]="OTAN[2_]"
	open_tables$[2]="IVM_ITEMWHSE",open_opts$[2]="OTA"
	gosub open_tables

rem --- fill listbox for use with Op Sequence

	bmm03_dev=fnget_dev("BMM_BILLOPER")
	dim bmm03a$:fnget_tpl$("BMM_BILLOPER")
	bmm08_dev=fnget_dev("BMC_OPCODES")
	dim bmm08a$:fnget_tpl$("BMC_OPCODES")
	bill_no$=callpoint!.getDevObject("master_bill")

	ops_lines!=SysGUI!.makeVector()
	ops_items!=SysGUI!.makeVector()
	ops_list!=SysGUI!.makeVector()
	ops_lines!.addItem("000000000000")
	ops_items!.addItem("")
	ops_list!.addItem("")
	op_code_list$=""

	read(bmm03_dev,key=firm_id$+bill_no$,dom=*next)
	while 1
		read record (bmm03_dev,end=*break) bmm03a$
		if pos(firm_id$+bill_no$=bmm03a$)<>1 break
		if bmm03a.line_type$<>"S" continue
		dim bmm08a$:fattr(bmm08a$)
		read record (bmm08_dev,key=firm_id$+bmm03a.op_code$,dom=*next)bmm08a$
		ops_lines!.addItem(bmm03a.internal_seq_no$)
		op_code_list$=op_code_list$+bmm03a.op_code$
		ops_items!.addItem(bmm03a.wo_op_ref$)
		ops_list!.addItem(bmm03a.wo_op_ref$+" - "+bmm03a.op_code$+" - "+bmm08a.code_desc$)
	wend

	if ops_lines!.size()>0
		ldat$=""
		for x=0 to ops_lines!.size()-1
			ldat$=ldat$+ops_items!.getItem(x)+"~"+ops_lines!.getItem(x)+";"
		next x
	endif

	callpoint!.setTableColumnAttribute("BMM_BILLMAT.OP_INT_SEQ_REF","LDAT",ldat$)
	my_grid!=Form!.getControl(5000)
	col_hdr$=callpoint!.getTableColumnAttribute("BMM_BILLMAT.OP_INT_SEQ_REF","LABS")
	col_ref=util.getGridColumnNumber(my_grid!, col_hdr$)
	my_control!=my_grid!.getColumnListControl(col_ref)
	my_control!.removeAllItems()
	my_control!.insertItems(0,ops_list!)
	my_grid!.setColumnListControl(col_ref,my_control!)

rem --- Disable WO_REF_NUM when locked
	if callpoint!.getDevObject("lock_ref_num")="Y" then
		opts$=callpoint!.getTableColumnAttribute("BMM_BILLMAT.WO_REF_NUM","OPTS")
		callpoint!.setTableColumnAttribute("BMM_BILLMAT.WO_REF_NUM","OPTS",opts$+"C"); rem --- makes read only
		callpoint!.setOptionEnabled("AUTO",0)
	endif
[[BMM_BILLMAT.ITEM_ID.AINV]]
rem --- Check for item synonyms

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
