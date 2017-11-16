[[SFE_WOSUBCNT.MEMO_1024.BINQ]]
rem --- (Barista Bug 9179 workaround) If grid cell isn't editable, then abort so new text can't be entered via edit control.
	maintGrid!=Form!.getControl(num(stbl("+GRID_CTL")))
	col_hdr$=callpoint!.getTableColumnAttribute("SFE_WOSUBCNT.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(maintGrid!, col_hdr$)
	this_row=callpoint!.getValidationRow()
	isEditable=maintGrid!.isCellEditable(this_row,memo_1024_col)
	if !isEditable then callpoint!.setStatus("ABORT")
[[SFE_WOSUBCNT.MEMO_1024.AVAL]]
rem --- Store first part of memo_1024 in ext_comment.
rem --- This AVAL is hit if user navigates via arrows or clicks on the memo_1024 field, and double-clicks or ctrl-F to bring up editor.
rem --- If use Comment field, or use ctrl-C or Comments button, code in the comment_entry subroutine is hit instead.
	disp_text$=callpoint!.getUserInput()
	if disp_text$<>callpoint!.getColumnUndoData("SFE_WOSUBCNT.MEMO_1024")
		dim ext_comments$(60)
		ext_comments$(1)=disp_text$(1,pos($0A$=disp_text$+$0A$)-1)
		callpoint!.setColumnData("SFE_WOSUBCNT.MEMO_1024",disp_text$,1)
		callpoint!.setColumnData("SFE_WOSUBCNT.EXT_COMMENTS",ext_comments$,1)
		callpoint!.setStatus("MODIFIED")
	endif
[[SFE_WOSUBCNT.AOPT-COMM]]
rem --- Launch Comments dialog
	gosub comment_entry
[[SFE_WOSUBCNT.EXT_COMMENTS.BINP]]
rem --- Launch Comments dialog
	gosub comment_entry
	callpoint!.setStatus("ABORT")
[[SFE_WOSUBCNT.VENDOR_ID.AVAL]]
rem "VENDOR INACTIVE - FEATURE"
vendor_id$ = callpoint!.getUserInput()
apm01_dev=fnget_dev("APM_VENDMAST")
apm01_tpl$=fnget_tpl$("APM_VENDMAST")
dim apm01a$:apm01_tpl$
apm01a_key$=firm_id$+vendor_id$
find record (apm01_dev,key=apm01a_key$,err=*break) apm01a$
if apm01a.vend_inactive$="Y" then
   call stbl("+DIR_PGM")+"adc_getmask.aon","VENDOR_ID","","","",m0$,0,vendor_size
   msg_id$="AP_VEND_INACTIVE"
   dim msg_tokens$[2]
   msg_tokens$[1]=fnmask$(apm01a.vendor_id$(1,vendor_size),m0$)
   msg_tokens$[2]=cvs(apm01a.vendor_name$,2)
   gosub disp_message
   callpoint!.setStatus("ACTIVATE")
endif

[[SFE_WOSUBCNT.WO_REF_NUM.BINP]]
rem --- Capture starting wo_ref_num
	prev_wo_ref_num$=callpoint!.getColumnData("SFE_WOSUBCNT.WO_REF_NUM")
	callpoint!.setDevObject("prev_wo_ref_num",prev_wo_ref_num$)
[[SFE_WOSUBCNT.AGDR]]
rem --- Track wo_ref_num in Map to insure they are unique
	refnumMap!=callpoint!.getDevObject("refnumMap")
	wo_ref_num$=callpoint!.getColumnData("SFE_WOSUBCNT.WO_REF_NUM")
	if cvs(wo_ref_num$,2)<>"" then
		refnumMap!.put(wo_ref_num$,"")
	endif

rem --- enable/disable PO-related fields based on PO Status (enabled if P or R)
	line_type$=callpoint!.getColumnData("SFE_WOSUBCNT.LINE_TYPE")
	gosub enable_po_fields
	gosub enable_comments
[[SFE_WOSUBCNT.WO_REF_NUM.AVAL]]
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
[[SFE_WOSUBCNT.BDEL]]
rem --- Update refnumMap!
	refnumMap!=callpoint!.getDevObject("refnumMap")
	wo_ref_num$=callpoint!.getColumnData("SFE_WOSUBCNT.WO_REF_NUM")
	if cvs(wo_ref_num$,2)<>"" then
		refnumMap!.remove(wo_ref_num$)
	endif
[[SFE_WOSUBCNT.BUDE]]
rem --- Verify wo_ref_num is unique
	refnumMap!=callpoint!.getDevObject("refnumMap")
	wo_ref_num$=callpoint!.getColumnData("SFE_WOSUBCNT.WO_REF_NUM")
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
[[SFE_WOSUBCNT.AGRE]]
rem --- look at po/req number; if different than it was when we entered the row, update and/or remove link in corresponding po/req detail line

	po_no_was$=callpoint!.getDevObject("start_po_no")
	po_status_was$=callpoint!.getDevObject("start_po_status")
	po_seq_ref_was$=callpoint!.getDevObject("start_po_seq_ref")

	po_no_now$=callpoint!.getColumnData("SFE_WOSUBCNT.PO_NO")
	po_status_now$=callpoint!.getColumnData("SFE_WOSUBCNT.PO_STATUS")
	po_seq_ref_now$=callpoint!.getColumnData("SFE_WOSUBCNT.PUR_ORD_SEQ_REF")

	poe11_dev=fnget_dev("POE_REQDET")
	poe12_dev=fnget_dev("POE_PODET")

	poe_podet_tpl$=fnget_tpl$("POE_PODET")
	poe_reqdet_tpl$=fnget_tpl$("POE_REQDET")

	if po_status_was$+po_no_was$+po_seq_ref_was$<>po_status_now$+po_no_now$+po_seq_ref_now$
		rem --- figure out from/to device (changed from po to req, req to po, nothing to po, etc.)
		switch pos(po_status_was$="RP ")
			case 1; rem --- was a req
				remove_link_dev=poe11_dev
				dim remove_link$:poe_reqdet_tpl$
			break
			case 2; rem --- was a PO
				remove_link_dev=poe12_dev
				dim remove_link$:poe_podet_tpl$
			break
			case 3; rem --- no previous link
				remove_link_dev=0
				remove_link$=""
			break
		swend
		switch pos(po_status_now$="RP ")
			case 1; rem --- selected a req
				create_link_dev=poe11_dev
				dim create_link$:poe_reqdet_tpl$
			break
			case 2; rem --- selected a PO
				create_link_dev=poe12_dev
				dim create_link$:poe_podet_tpl$
			break
			case 3; rem --- no req/po currently selected
				create_link_dev=0
				create_link$=""
			break
		swend

		rem --- used to reference different po# (i.e., changed from one po# to another, or have now removed the po# from this subs line)
		if cvs(po_no_was$,3)<>""
			extract record (remove_link_dev,key=firm_id$+po_no_was$+po_seq_ref_was$,dom=*endif)remove_link$; rem --- Advisory locking
			remove_link.wo_no$=""
			remove_link.wk_ord_seq_ref$=""
			remove_link$=field(remove_link$)
			write record (remove_link_dev)remove_link$
		endif		
		rem --- now references different po# (i.e., changed from one po# to another, or have now set a po# on this subs line)
		if cvs(po_no_now$,3)<>""
			extract record (create_link_dev,key=firm_id$+po_no_now$+po_seq_ref_now$,dom=*endif)create_link$; rem --- Advisory locking
			create_link.wo_no$=callpoint!.getColumnData("SFE_WOSUBCNT.WO_NO")
			create_link.wk_ord_seq_ref$=callpoint!.getColumnData("SFE_WOSUBCNT.INTERNAL_SEQ_NO")
			create_link$=field(create_link$)
			write record (create_link_dev)create_link$
		endif
	endif
[[SFE_WOSUBCNT.PO_NO.AVAL]]
rem --- need to use custom query so we get back both po# and line#
rem --- throw message to user and abort manual entry

	if cvs(callpoint!.getUserInput(),3)<>""
		if callpoint!.getUserInput()<>callpoint!.getColumnData("SFE_WOSUBCNT.PO_NO")
			if callpoint!.getDevObject("po_looked_up")<>"Y"
				callpoint!.setMessage("SF_USE_QUERY")
				callpoint!.setStatus("ABORT")
			endif
		endif
	else
		callpoint!.setColumnData("SFE_WOSUBCNT.PUR_ORD_SEQ_REF","",1)
	endif

	callpoint!.setDevObject("po_looked_up","N")
[[SFE_WOSUBCNT.BGDR]]
rem --- get PO#/req# and ISN, load up corresponding item info

		switch pos(callpoint!.getColumnData("SFE_WOSUBCNT.PO_STATUS")="RPC ")
			case 1;rem requisition
				call stbl("+DIR_SYP")+"bac_key_template.bbj","POE_REQDET","PRIMARY",key_tpl$,rd_table_chans$[all],status$
				dim po_req_key$:key_tpl$
				po_req_key$=firm_id$+callpoint!.getColumnData("SFE_WOSUBCNT.PO_NO")+callpoint!.getColumnData("SFE_WOSUBCNT.PUR_ORD_SEQ_REF")
				gosub get_po_info
				callpoint!.setColumnData("<<DISPLAY>>.DISP_ITEM",line_desc$,1)
			break
			case 2; rem po		
				call stbl("+DIR_SYP")+"bac_key_template.bbj","POE_PODET","PRIMARY",key_tpl$,rd_table_chans$[all],status$
				dim po_req_key$:key_tpl$
				po_req_key$=firm_id$+callpoint!.getColumnData("SFE_WOSUBCNT.PO_NO")+callpoint!.getColumnData("SFE_WOSUBCNT.PUR_ORD_SEQ_REF")
				gosub get_po_info
				callpoint!.setColumnData("<<DISPLAY>>.DISP_ITEM",line_desc$,1)
			break
			case 3; rem none/receipt
			case 4
			break
		swend
[[SFE_WOSUBCNT.PO_NO.BINQ]]
rem --- call custom inquiry depending on whether we're looking for PO or Req. 
rem --- Query displays PO's/Req's for given firm/vendor, only showing those not already linked to a WO, and only non-stocks (per v6 validation code)

	switch pos(callpoint!.getColumnData("SFE_WOSUBCNT.PO_STATUS")="RP")
		case 1;rem requisition

			call stbl("+DIR_SYP")+"bac_key_template.bbj","POE_REQDET","PRIMARY",key_tpl$,rd_table_chans$[all],status$
			dim po_req_key$:key_tpl$
			dim search_defs$[2]
			dim filter_defs$[4,2]
			filter_defs$[0,0]="POE_REQHDR.FIRM_ID"
			filter_defs$[0,1]="='"+firm_id$ +"'"
			filter_defs$[0,2]="LOCK"
			filter_defs$[1,0]="POE_REQHDR.VENDOR_ID"
			filter_defs$[1,1]="='"+callpoint!.getColumnData("SFE_WOSUBCNT.VENDOR_ID")+"'"
			filter_defs$[1,2]="LOCK"
			filter_defs$[3,0]="POE_REQDET.WO_NO"
			filter_defs$[3,1]="='' "
			filter_defs$[3,2]="LOCK"
			filter_defs$[4,0]="POC_LINECODE.LINE_TYPE"
			filter_defs$[4,1]="='N' "
			filter_defs$[4,2]="LOCK"
 
                		call stbl("+DIR_SYP")+"bax_query.bbj",gui_dev,form!,"REQDETAIL","",table_chans$[all],po_req_key$,filter_defs$[all]
		break
		case 2;rem PO

			call stbl("+DIR_SYP")+"bac_key_template.bbj","POE_PODET","PRIMARY",key_tpl$,rd_table_chans$[all],status$
			dim po_req_key$:key_tpl$
			dim search_defs$[2]
			dim filter_defs$[4,2]
			filter_defs$[1,0]="POE_POHDR.FIRM_ID"
			filter_defs$[1,1]="='"+firm_id$ +"'"
			filter_defs$[1,2]="LOCK"
			filter_defs$[2,0]="POE_POHDR.VENDOR_ID"
			filter_defs$[2,1]="='"+callpoint!.getColumnData("SFE_WOSUBCNT.VENDOR_ID")+"'"
			filter_defs$[2,2]="LOCK"
			filter_defs$[3,0]="POE_PODET.WO_NO"
			filter_defs$[3,1]="='' "
			filter_defs$[3,2]="LOCK"
			filter_defs$[4,0]="POC_LINECODE.LINE_TYPE"
			filter_defs$[4,1]="='N' "
			filter_defs$[4,2]="LOCK"
	
                		call stbl("+DIR_SYP")+"bax_query.bbj",gui_dev,form!,"PODETAIL","",table_chans$[all],po_req_key$,filter_defs$[all]

		break
		case default
		break
	swend

	gosub get_po_info
	
	if cvs(po_req_key$,3)<>""
		callpoint!.setColumnData("SFE_WOSUBCNT.PO_NO",po_req_no$,1)
		callpoint!.setColumnData("SFE_WOSUBCNT.PUR_ORD_SEQ_REF",po_req_line$,1)
		callpoint!.setColumnData("<<DISPLAY>>.DISP_ITEM",line_desc$,1)
		callpoint!.setDevObject("po_looked_up","Y")
		callpoint!.setStatus("MODIFIED")
	else
		callpoint!.setColumnData("SFE_WOSUBCNT.PO_NO","",1)
		callpoint!.setColumnData("SFE_WOSUBCNT.PUR_ORD_SEQ_REF","",1)
		callpoint!.setColumnData("<<DISPLAY>>.DISP_ITEM","",1)
		callpoint!.setDevObject("po_looked_up","N")
	endif

	callpoint!.setStatus("ACTIVATE-ABORT")
	
[[SFE_WOSUBCNT.LINE_TYPE.AVAL]]
rem --- enable/disable PO-related fields based on PO Status (enabled if P or R)
	
	line_type$=callpoint!.getUserInput()
	gosub enable_po_fields
	gosub enable_comments
[[SFE_WOSUBCNT.AGRN]]
rem --- enable/disable PO-related fields based on PO Status (enabled if P or R)
	
	line_type$=callpoint!.getColumnData("SFE_WOSUBCNT.LINE_TYPE")
	gosub enable_po_fields
	gosub enable_comments

rem --- save current po status flag, po/req# and line#

	callpoint!.setDevObject("start_po_no",callpoint!.getColumnData("SFE_WOSUBCNT.PO_NO"))
	callpoint!.setDevObject("start_po_status",callpoint!.getColumnData("SFE_WOSUBCNT.PO_STATUS"))
	callpoint!.setDevObject("start_po_seq_ref",callpoint!.getColumnData("SFE_WOSUBCNT.PUR_ORD_SEQ_REF"))
	callpoint!.setDevObject("po_looked_up","N")
[[SFE_WOSUBCNT.PO_STATUS.AVAL]]
rem --- Disable PO Number and Sequence?

	if cvs(callpoint!.getUserInput(),2)="" or callpoint!.getUserInput()="C"
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOSUBCNT.PUR_ORD_SEQ_REF",0)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOSUBCNT.PO_NO",0)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOSUBCNT.LEAD_TIME",0)
	else
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOSUBCNT.PUR_ORD_SEQ_REF",1)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOSUBCNT.PO_NO",1)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOSUBCNT.LEAD_TIME",1)
	endif
 
	if callpoint!.getUserInput()<>callpoint!.getColumnData("SFE_WOSUBCNT.PO_STATUS") and cvs(callpoint!.getColumnData("SFE_WOSUBCNT.PO_STATUS"),3)<>""
		callpoint!.setColumnData("<<DISPLAY>>.DISP_ITEM","",1)
		callpoint!.setColumnData("SFE_WOSUBCNT.PO_NO","",1)
		callpoint!.setColumnData("SFE_WOSUBCNT.PUR_ORD_SEQ_REF","",1)
	endif
[[SFE_WOSUBCNT.UNITS.AVAL]]
rem --- Verify minimum quantity > 0

	if num(callpoint!.getUserInput())<=0
		msg_id$="IV_QTY_GT_ZERO"
		gosub disp_message
		callpoint!.setColumnData("SFE_WOSUBCNT.UNITS",callpoint!.getColumnData("SFE_WOSUBCNT.UNITS"),1)
		callpoint!.setStatus("ABORT")
	endif

rem --- Calc numbers

	units=num(callpoint!.getUserInput())
	rate=num(callpoint!.getColumnData("SFE_WOSUBCNT.RATE"))
	gosub calc_totals
[[SFE_WOSUBCNT.RATE.AVAL]]
rem --- Calc numbers

	units=num(callpoint!.getColumnData("SFE_WOSUBCNT.UNITS"))
	rate=num(callpoint!.getUserInput())
	gosub calc_totals
[[SFE_WOSUBCNT.<CUSTOM>]]
#include std_functions.src
rem ========================================================
calc_totals:
rem rate:		input
rem units:	input
rem ========================================================

	prod_qty=num(callpoint!.getDevObject("prod_qty"))
	
	callpoint!.setColumnData("SFE_WOSUBCNT.UNIT_COST",str(units*rate),1)
	callpoint!.setColumnData("SFE_WOSUBCNT.TOTAL_UNITS",str(units*prod_qty),1)
	callpoint!.setColumnData("SFE_WOSUBCNT.TOTAL_COST",str(units*rate*prod_qty),1)

	return

rem ========================================================
enable_po_fields:
rem line_type:	input
rem ========================================================

	if line_type$="S" and callpoint!.getColumnData("SFE_WOSUBCNT.PO_STATUS")<>"C"
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOSUBCNT.PO_STATUS",1)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOSUBCNT.PUR_ORD_SEQ_REF",1)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOSUBCNT.PO_NO",1)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOSUBCNT.LEAD_TIME",1)
	else
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOSUBCNT.PO_STATUS",0)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOSUBCNT.PUR_ORD_SEQ_REF",0)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOSUBCNT.PO_NO",0)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOSUBCNT.LEAD_TIME",0)
	endif

	return

rem ========================================================
get_po_info:
rem po_req_key$:	input
rem po_req_no$:	output
rem po_req_line$:	output
rem line_desc$:	output
rem ========================================================

	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")

	poe11_dev=fnget_dev("POE_PODET")
	poe_podet_tpl$=fnget_tpl$("POE_PODET")

	poe12_dev=fnget_dev("POE_REQDET")
	poe_reqdet_tpl$=fnget_tpl$("POE_REQDET")

	line_desc$=""
	

	rem --- po_req_key$ will be firm/po or req#/ISN; need to read that PO line to get item/description for display in grid, and store ISN in subcontract rec.
	if po_req_key$<>""
		if po_req_key$(len(po_req_key$),1)="^" then po_req_key$=po_req_key$(1,len(po_req_key$)-1)
		switch pos(callpoint!.getColumnData("SFE_WOSUBCNT.PO_STATUS")=" RPC")
			case 1; rem none
			break
			case 2;rem requisition
				po_req_dev=poe12_dev	
				po_req_no$=po_req_key.req_no$
				po_req_line$=po_req_key.internal_seq_no$
				dim po_req_det$:poe_reqdet_tpl$
			break
			case 3; rem po/receipt
			case 4
				po_req_dev=poe11_dev
				po_req_no$=po_req_key.po_no$
				po_req_line$=po_req_key.internal_seq_no$
				dim po_req_det$:poe_podet_tpl$
			break
			case default
			break	
		swend
			
		read record(po_req_dev,key=firm_id$+po_req_no$+po_req_line$,err=*next)po_req_det$
		if cvs(po_req_det.item_id$,3)<>""
			read record (ivm01_dev,key=firm_id$+po_req_det.item_id$,dom=*next)ivm_itemmast$
			line_desc$=cvs(ivm_itemmast.item_id$,3)+" - "+cvs(ivm_itemmast.item_desc$,3)
		else
			line_desc$=cvs(po_req_det.order_memo$,3)
		endif		

	endif

	return

comment_entry:
rem --- on a line where you can access the ls_comments field, pop the new memo_1024 editor instead
rem --- the editor can be popped on demand for any line using the Comments button (alt-C),
rem --- but will automatically pop for lines where the ext_comments field is enabled.
rem ==========================================================================

	disp_text$=callpoint!.getColumnData("SFE_WOSUBCNT.MEMO_1024")
	sv_disp_text$=disp_text$

	rem --- Comments are not editable if WO is closed, or line type isn't M or I
	line_type$=callpoint!.getColumnData("SFE_WOSUBCNT.LINE_TYPE")
	if callpoint!.getDevObject("wo_status")="C" or pos(line_type$="MI")=0 then
		editable$="NO"
	else
		editable$="YES"
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
		callpoint!.setColumnData("SFE_WOSUBCNT.MEMO_1024",disp_text$,1)
		callpoint!.setColumnData("SFE_WOSUBCNT.EXT_COMMENTS",ext_comments$,1)
		callpoint!.setStatus("MODIFIED")
	endif

	callpoint!.setStatus("ACTIVATE")

	return

rem ========================================================
enable_comments:
rem line_type:	input
rem ========================================================

	if callpoint!.getDevObject("wo_status")<>"C" and pos(line_type$="MI") then
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOSUBCNT.MEMO_1024",1)
		callpoint!.setOptionEnabled("COMM",1)
	else
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"SFE_WOSUBCNT.MEMO_1024",0)
		callpoint!.setOptionEnabled("COMM",0)
	endif

	return
[[SFE_WOSUBCNT.BSHO]]
rem --- Set column size for memo_1024 field very small so it doesn't take up room, but still available for hover-over of memo contents
	use ::ado_util.src::util

	maintGrid!=Form!.getControl(num(stbl("+GRID_CTL")))
	col_hdr$=callpoint!.getTableColumnAttribute("SFE_WOSUBCNT.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(maintGrid!, col_hdr$)
	maintGrid!.setColumnWidth(memo_1024_col,15)

rem --- init data

	refnumMap!=new java.util.HashMap()
	callpoint!.setDevObject("refnumMap",refnumMap!)

rem --- Disable grid if Closed Work Order or Recurring or PO not installed

	if callpoint!.getDevObject("wo_status")="C" or
:		callpoint!.getDevObject("wo_category")="R" or
:		callpoint!.getDevObject("po")<>"Y" or
:		(callpoint!.getDevObject("wo_category")="I" and callpoint!.getDevObject("bm")="Y")
		opts$=callpoint!.getTableAttribute("OPTS")
		callpoint!.setTableAttribute("OPTS",opts$+"BID")

		x$=callpoint!.getTableColumns()
		worefnumPos=pos("SFE_WOSUBCNT.WO_REF_NUM"=x$)
		for x=1 to len(x$) step 40
			rem --- Don't disable wo_ref_num for Bills Of Materials unless WO is closed
			if x<>worefnumPos or
:			(x=worefnumPos and 
:			(callpoint!.getDevObject("wo_status")="C" or (callpoint!.getDevObject("wo_category")<>"I" and callpoint!.getDevObject("bm")<>"Y")))
:			then
				opts$=callpoint!.getTableColumnAttribute(cvs(x$(x,40),2),"OPTS")
				callpoint!.setTableColumnAttribute(cvs(x$(x,40),2),"OPTS",opts$+"C"); rem - makes cells read only
			endif
		next x
	endif

rem --- fill listbox for use with Op Sequence

	sfe02_dev=fnget_dev("SFE_WOOPRTN")
	dim sfe02a$:fnget_tpl$("SFE_WOOPRTN")
	op_code=callpoint!.getDevObject("opcode_chan")
	dim op_code$:callpoint!.getDevObject("opcode_tpl")
	wo_no$=callpoint!.getDevObject("wo_no")
	wo_loc$=callpoint!.getDevObject("wo_loc")

	ops_lines!=SysGUI!.makeVector()
	ops_items!=SysGUI!.makeVector()
	ops_list!=SysGUI!.makeVector()
	ops_lines!.addItem("000000000000")
	ops_items!.addItem("")
	ops_list!.addItem("")

	read(sfe02_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)
	while 1
		read record (sfe02_dev,end=*break) sfe02a$
		if pos(firm_id$+wo_loc$+wo_no$=sfe02a$)<>1 break
		if sfe02a.line_type$<>"S" continue
		dim op_code$:fattr(op_code$)
		read record (op_code,key=firm_id$+sfe02a.op_code$,dom=*next)op_code$
		ops_lines!.addItem(sfe02a.internal_seq_no$)
        ops_items!.addItem(sfe02a.wo_op_ref$)
        ops_list!.addItem(sfe02a.wo_op_ref$+" - "+sfe02a.op_code$+" - "+op_code.code_desc$)
	wend

	if ops_lines!.size()>0
		ldat$=""
		for x=0 to ops_lines!.size()-1
			ldat$=ldat$+ops_items!.getItem(x)+"~"+ops_lines!.getItem(x)+";"
		next x
	endif

	callpoint!.setTableColumnAttribute("SFE_WOSUBCNT.OPER_SEQ_REF","LDAT",ldat$)
	col_hdr$=callpoint!.getTableColumnAttribute("SFE_WOSUBCNT.OPER_SEQ_REF","LABS")
	my_grid!=Form!.getControl(5000)
	ListColumn=util.getGridColumnNumber(my_grid!, col_hdr$)
	my_control!=my_grid!.getColumnListControl(ListColumn)
	my_control!.removeAllItems()
	my_control!.insertItems(0,ops_list!)
	my_grid!.setColumnListControl(ListColumn,my_control!)
    my_grid!.setColumnHeaderCellText(ListColumn,"Op Ref")

rem --- Check for PO Installed
rem --- confusion in old code - seems subs grid isn't accessible if PO not installed, but other tests in the code look at the PO flag
rem --- so even tho' code above says to disable the entire grid if PO not installed, leaving this if/else as is for now.

	if callpoint!.getDevObject("po")<>"Y"
		callpoint!.setColumnEnabled(-1,"SFE_WOSUBCNT.PO_STATUS",-1)
		callpoint!.setColumnEnabled(-1,"SFE_WOSUBCNT.PUR_ORD_SEQ_REF",-1)
		callpoint!.setColumnEnabled(-1,"SFE_WOSUBCNT.PO_NO",-1)
		callpoint!.setColumnEnabled(-1,"SFE_WOSUBCNT.LEAD_TIME",-1)
	else
		callpoint!.setColumnEnabled(-1,"SFE_WOSUBCNT.PO_STATUS",1)
		callpoint!.setColumnEnabled(-1,"SFE_WOSUBCNT.PUR_ORD_SEQ_REF",1)
		callpoint!.setColumnEnabled(-1,"SFE_WOSUBCNT.PO_NO",1)
		callpoint!.setColumnEnabled(-1,"SFE_WOSUBCNT.LEAD_TIME",1)
	endif

rem --- Disable WO_REF_NUM when locked
	if callpoint!.getDevObject("lock_ref_num")="Y" then
		opts$=callpoint!.getTableColumnAttribute("SFE_WOSUBCNT.WO_REF_NUM","OPTS")
		callpoint!.setTableColumnAttribute("SFE_WOSUBCNT.WO_REF_NUM","OPTS",opts$+"C"); rem --- makes read only
	endif
