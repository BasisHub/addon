[[IVM_ITEMMAST.PRODUCT_TYPE.AVAL]]
rem --- Set SA Level if new record
	if callpoint!.getRecordMode()="A"
		ivm10_dev=fnget_dev("IVC_PRODCODE")
		dim ivm10a$:fnget_tpl$("IVC_PRODCODE")
		read record (ivm10_dev,key=firm_id$+"A"+callpoint!.getUserInput()) ivm10a$
		callpoint!.setColumnData("IVM_ITEMMAST.SA_LEVEL",ivm10a.sa_level$,1)
	endif
[[IVM_ITEMMAST.AOPT-BOMU]]
rem --- Display Where Used from BOMs

cp_item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[2,1]
dflt_data$[1,0]="ITEM_ID_1"
dflt_data$[1,1]=cp_item_id$
dflt_data$[2,0]="ITEM_ID_2"
dflt_data$[2,1]=cp_item_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"BMR_MATERIALUSED",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]
[[IVM_ITEMMAST.AOPT-LOOK]]
rem --- call the custom item lookup form, so we can look for an item by product type, synonym, etc.

select_key$=""
call stbl("+DIR_SYP")+"bam_run_prog.bbj","IVC_ITEMLOOKUP",stbl("+USER_ID"),"MNT","",table_chans$[all]
select_key$=str(bbjapi().getObjectTable().get("find_item"))
if select_key$="null" then select_key$=""
if select_key$<>"" then callpoint!.setStatus("RECORD:["+select_key$+"]")
[[IVM_ITEMMAST.BWRI]]
rem --- Is item code blank?

	if cvs(callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID"), 2) = "" then
		msg_id$ = "IV_BLANK_ID"
		gosub disp_message
		callpoint!.setFocus("IVM_ITEMMAST.ITEM_ID")
	endif

	if cvs(callpoint!.getColumnData("IVM_ITEMMAST.ITEM_DESC"),3)="" then 
		msg_id$="IV_BLANK_DESC"
		gosub disp_message
		callpoint!.setFocus("IVM_ITEMMAST.ITEM_DESC")
	endif
[[IVM_ITEMMAST.LOTSER_ITEM.AVAL]]
rem --- Can't change flag is there is QOH

	break; rem *** DISABLED ***

	prev_flag$ = callpoint!.getColumnDiskData("IVM_ITEMMAST.LOTSER_ITEM")
	this_flag$ = callpoint!.getUserInput()

	rem debug
	print "Lot/Serial..."
	print " disk: ", prev_flag$
	print "input: ", this_flag$

	if this_flag$ <> prev_flag$ then
		gosub check_qoh

		if qoh then
			msg_id$ = "IV_CANT_CHANGE_CODE"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	endif
[[IVM_ITEMMAST.INVENTORIED.AVAL]]
rem --- Can't change flag is there is QOH

	break; rem *** DISABLED ***

	prev_flag$ = callpoint!.getColumnDiskData("IVM_ITEMMAST.INVENTORIED")
	this_flag$ = callpoint!.getUserInput()

	rem debug
	print "Inventoried..."
	print " disk: ", prev_flag$
	print "input: ", this_flag$

	if this_flag$ <> prev_flag$ then
		gosub check_qoh

		if qoh then
			msg_id$ = "IV_CANT_CHANGE_CODE"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	endif
[[IVM_ITEMMAST.ARNF]]
rem --- item not found (so assuming new record); default bar code to item id

callpoint!.setColumnData("IVM_ITEMMAST.BAR_CODE", callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID"))
callpoint!.setStatus("REFRESH")
[[<<DISPLAY>>.ITEM_DESC_SEG_3.BINP]]
rem --- Set previous value

	user_tpl.prev_desc_seg_3$ = callpoint!.getColumnData("<<DISPLAY>>.ITEM_DESC_SEG_3")
[[<<DISPLAY>>.ITEM_DESC_SEG_1.BINP]]
rem --- Set previous value

	user_tpl.prev_desc_seg_1$ = callpoint!.getColumnData("<<DISPLAY>>.ITEM_DESC_SEG_1")
[[<<DISPLAY>>.ITEM_DESC_SEG_2.BINP]]
rem --- Set previous value

	user_tpl.prev_desc_seg_2$ = callpoint!.getColumnData("<<DISPLAY>>.ITEM_DESC_SEG_2")
[[IVM_ITEMMAST.ADIS]]
rem --- Set Description Segments

	desc$ = pad(callpoint!.getColumnData("IVM_ITEMMAST.ITEM_DESC"), 90)
	callpoint!.setColumnData("<<DISPLAY>>.ITEM_DESC_SEG_1", desc$(1, user_tpl.desc_len_01))
 	callpoint!.setColumnData("<<DISPLAY>>.ITEM_DESC_SEG_2", desc$(1 + user_tpl.desc_len_01, user_tpl.desc_len_02))
	callpoint!.setColumnData("<<DISPLAY>>.ITEM_DESC_SEG_3", desc$(1 + user_tpl.desc_len_01 + user_tpl.desc_len_02, user_tpl.desc_len_03))

	callpoint!.setStatus("REFRESH")

rem --- Save old Bar Code and UPC Code for Synonym Maintenance

	user_tpl.old_barcode$=callpoint!.getColumnData("IVM_ITEMMAST.BAR_CODE")
	user_tpl.old_upc$=callpoint!.getColumnData("IVM_ITEMMAST.UPC_CODE")

rem --- store lot/serialized flag in devObject for use later

	callpoint!.setDevObject("lot_serial_item",callpoint!.getColumnData("IVM_ITEMMAST.LOTSER_ITEM"))

rem --- set flag in devObject to say we're not on a new record

	callpoint!.setDevObject("new_rec","N")
[[<<DISPLAY>>.ITEM_DESC_SEG_3.AVAL]]
rem --- Set this section back into desc, if modified

	desc$ = pad(callpoint!.getColumnData("IVM_ITEMMAST.ITEM_DESC"), 60)
	seg$  = callpoint!.getUserInput()

	if seg$ <> user_tpl.prev_desc_seg_3$ then
		desc$(1 + user_tpl.desc_len_01 + user_tpl.desc_len_02, user_tpl.desc_len_03) = seg$
		callpoint!.setColumnData("IVM_ITEMMAST.ITEM_DESC", desc$)
		callpoint!.setColumnData("IVM_ITEMMAST.DISPLAY_DESC", func.displayDesc(desc$))
		callpoint!.setStatus("MODIFIED;REFRESH")
	endif
[[<<DISPLAY>>.ITEM_DESC_SEG_2.AVAL]]
rem --- Set this section back into desc, if modified

	desc$ = pad(callpoint!.getColumnData("IVM_ITEMMAST.ITEM_DESC"), 60)
	seg$  = callpoint!.getUserInput()

	if seg$ <> user_tpl.prev_desc_seg_2$ then
		desc$(1 + user_tpl.desc_len_01, user_tpl.desc_len_02) = seg$
		callpoint!.setColumnData("IVM_ITEMMAST.ITEM_DESC", desc$)
		callpoint!.setColumnData("IVM_ITEMMAST.DISPLAY_DESC", func.displayDesc(desc$))
		callpoint!.setStatus("MODIFIED;REFRESH")
	endif
[[<<DISPLAY>>.ITEM_DESC_SEG_1.AVAL]]
rem --- Set this section back into desc, if modified

	desc$ = pad(callpoint!.getColumnData("IVM_ITEMMAST.ITEM_DESC"), 60)
	seg$  = callpoint!.getUserInput()

	if seg$ <> user_tpl.prev_desc_seg_1$ then
		desc$(1, user_tpl.desc_len_01) = seg$
		callpoint!.setColumnData("IVM_ITEMMAST.ITEM_DESC", desc$)
		callpoint!.setColumnData("IVM_ITEMMAST.DISPLAY_DESC", func.displayDesc(desc$))
		callpoint!.setStatus("MODIFIED;REFRESH")
	endif
[[IVM_ITEMMAST.MSRP.AVAL]]
if num(callpoint!.getUserInput())<0 then
	callpoint!.setStatus("ABORT")
endif
[[IVM_ITEMMAST.CONV_FACTOR.AVAL]]
if num(callpoint!.getUserInput())<0 then
	callpoint!.setStatus("ABORT")
endif
[[IVM_ITEMMAST.AOPT-CITM]]
rem --- Copy item

	cp_item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
	user_id$=stbl("+USER_ID")
	dim dflt_data$[1,1]
	dflt_data$[1,0]="OLD_ITEM"
	dflt_data$[1,1]=cp_item_id$

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"IVM_COPYITEM",
:		user_id$,
:		"",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]

rem --- Edit the item just copied

	new_item_id$ = str(callpoint!.getDevObject("new_item_id"))

	if new_item_id$ <> "" then
		callpoint!.setStatus("RECORD:["+firm_id$+new_item_id$+"]")
	endif
[[IVM_ITEMMAST.AOPT-HCPY]]
cp_item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[2,1]
dflt_data$[1,0]="ITEM_ID_1"
dflt_data$[1,1]=cp_item_id$
dflt_data$[2,0]="ITEM_ID_2"
dflt_data$[2,1]=cp_item_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"IVR_ITEMDETAIL",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]
[[IVM_ITEMMAST.AOPT-RORD]]
cp_item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[2,1]
dflt_data$[1,0]="ITEM_ID"
dflt_data$[1,1]=cp_item_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"IVR_POREQS",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]
[[IVM_ITEMMAST.AOPT-STOK]]
rem --- Populate Stocking Info in Warehouses
	cp_item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
	user_id$=stbl("+USER_ID")
	dim dflt_data$[6,1]
	dflt_data$[1,0]="ITEM_ID"
	dflt_data$[1,1]=cp_item_id$
	ivs10d_dev=fnget_dev("IVS_DEFAULTS")
	ivs10d_tpl$=fnget_tpl$("IVS_DEFAULTS")
	dim ivs10d$:ivs10d_tpl$
	read record (ivs10d_dev,key=firm_id$+"D") ivs10d$
	dflt_data$[2,0]="ABC_CODE"
	dflt_data$[2,1]=ivs10d.abc_code$
	dflt_data$[3,0]="BUYER_CODE"
	dflt_data$[3,1]=ivs10d.buyer_code$
	dflt_data$[4,0]="EOQ_CODE"
	dflt_data$[4,1]=ivs10d.eoq_code$
	dflt_data$[5,0]="ORD_PNT_CODE"
	dflt_data$[5,1]=ivs10d.ord_pnt_code$
	dflt_data$[6,0]="SAF_STK_CODE"
	dflt_data$[6,1]=ivs10d.saf_stk_code$
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:                       "IVM_STOCK",
:                       user_id$,
:                   	"",
:                       "",
:                       table_chans$[all],
:                       "",
:                       dflt_data$[all]
[[IVM_ITEMMAST.ITEM_ID.AVAL]]
rem --- See if Auto Numbering in effect

	if cvs(callpoint!.getUserInput(), 2) = "" then 
		ivs01_dev = fnget_dev("IVS_PARAMS")
		dim ivs01a$:fnget_tpl$("IVS_PARAMS")
		ivs10_dev = fnget_dev("IVS_NUMBERS")
		dim ivs10n$:fnget_tpl$("IVS_NUMBERS")
		read record (ivs01_dev, key=firm_id$+"IV00") ivs01a$

		if ivs01a.auto_no_iv$="N" then
			callpoint!.setStatus("ABORT")
		else
			item_len = num(callpoint!.getTableColumnAttribute("IVM_ITEMMAST.ITEM_ID","MAXL"))
			if item_len=0 then item_len=20; rem Needed?
			chk_digit$ = ""
			if ivs01a.auto_no_iv$="C" then item_len=item_len-1
			extract record (ivs10_dev,key=firm_id$+"N",dom=*next) ivs10n$; rem Advisory Locking
			ivs10n.firm_id$ = firm_id$
			ivs10n.record_id_n$ = "N"

			if ivs10n.nxt_item_id=0
				next_num=1
			else
				next_num=ivs10n.nxt_item_id
			endif

			dim max_num$(min(item_len,10),"9")

			if next_num>num(max_num$) then 
				read (ivs10_dev)
				msg_id$="NO_MORE_NUMBERS"
				gosub disp_message
				callpoint!.setStatus("ABORT")
			else
				ivs10n.nxt_item_id=next_num+1
				ivs10n$=field(ivs10n$)
				write record (ivs10_dev) ivs10n$
				next_num$=str(next_num)

				if ivs01a.auto_no_iv$="C" then 
					precision 4
					chk_digit$=str(tim*10000),chk_digit$=chk_digit$(len(chk_digit$),1)
					precision num(ivs01a.precision$)
				endif

				callpoint!.setUserInput(next_num$+chk_digit$)
				callpoint!.setStatus("REFRESH")
			endif
		endif
	endif
[[IVM_ITEMMAST.AWRI]]
rem --- Write synonyms of the Item Number, UPC Code and Bar Code
	ivm_itemsyn_dev=fnget_dev("IVM_ITEMSYN")
	dim ivm_itemsyn$:fnget_tpl$("IVM_ITEMSYN")
	ivm_itemsyn.firm_id$=firm_id$
	item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
	ivm_itemsyn.item_synonym$=item_id$
	ivm_itemsyn.item_id$=item_id$
	ivm_itemsyn_key$=ivm_itemsyn.firm_id$+ivm_itemsyn.item_synonym$+ivm_itemsyn.item_id$
	extract record (ivm_itemsyn_dev,key=ivm_itemsyn_key$,dom=*next)x$; rem Advisory Locking
	ivm_itemsyn$=field(ivm_itemsyn$)
	write record (ivm_itemsyn_dev) ivm_itemsyn$

rem --- Remove old UPC Code and Bar Code
	if cvs(user_tpl.old_barcode$,3)<>"" and user_tpl.old_barcode$<>item_id$
		ivm_itemsyn.item_synonym$=user_tpl.old_barcode$
		ivm_itemsyn.item_id$=item_id$
		remove(ivm_itemsyn_dev,key=firm_id$+ivm_itemsyn.item_synonym$+ivm_itemsyn.item_id$,dom=*next)
	endif
	if cvs(user_tpl.old_upc$,3)<>"" and user_tpl.old_upc$<>item_id$
		ivm_itemsyn.item_synonym$=user_tpl.old_upc$
		ivm_itemsyn.item_id$=item_id$
		remove(ivm_itemsyn_dev,key=firm_id$+ivm_itemsyn.item_synonym$+ivm_itemsyn.item_id$,dom=*next)
	endif

rem --- Add new UPC Code and Bar Code
	if cvs(callpoint!.getColumnData("IVM_ITEMMAST.BAR_CODE"),3)<>""
		ivm_itemsyn.item_synonym$=callpoint!.getColumnData("IVM_ITEMMAST.BAR_CODE")
		ivm_itemsyn.item_id$=item_id$
		ivm_itemsyn_key$=ivm_itemsyn.firm_id$+ivm_itemsyn.item_synonym$+ivm_itemsyn.item_id$
		extract record (ivm_itemsyn_dev,key=ivm_itemsyn_key$,dom=*next)x$; rem Advisory Locking
		ivm_itemsyn$=field(ivm_itemsyn$)
		write record (ivm_itemsyn_dev) ivm_itemsyn$
	endif
	if cvs(callpoint!.getColumnData("IVM_ITEMMAST.UPC_CODE"),3)<>""
		ivm_itemsyn.item_synonym$=callpoint!.getColumnData("IVM_ITEMMAST.UPC_CODE")
		ivm_itemsyn.item_id$=item_id$
		ivm_itemsyn_key$=ivm_itemsyn.firm_id$+ivm_itemsyn.item_synonym$+ivm_itemsyn.item_id$
		extract record (ivm_itemsyn_dev,key=ivm_itemsyn_key$,dom=*next)x$; rem Advisory Locking
		ivm_itemsyn$=field(ivm_itemsyn$)
		write record (ivm_itemsyn_dev) ivm_itemsyn$
	endif

	user_tpl.old_barcode$=callpoint!.getColumnData("IVM_ITEMMAST.BAR_CODE")
	user_tpl.old_upc$=callpoint!.getColumnData("IVM_ITEMMAST.UPC_CODE")

rem --- store lot/serialized flag in devObject for use later

	callpoint!.setDevObject("lot_serial_item",callpoint!.getColumnData("IVM_ITEMMAST.LOTSER_ITEM"))

rem --- if this is a newly added record, launch warehouse/stocking, vendors, and synonymns forms

	if callpoint!.getDevObject("new_rec")="Y"

		user_id$=stbl("+USER_ID")
		dim dflt_data$[2,1]
		dflt_data$[1,0]="ITEM_ID"
		dflt_data$[1,1]=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
		key_pfx$=firm_id$+callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
		call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:			"IVM_ITEMWHSE",
:			user_id$,
:			"",
:			key_pfx$,
:			table_chans$[all],
:			"",
:			dflt_data$[all]

		call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:			"IVM_ITEMVEND",
:			user_id$,
:			"",
:			key_pfx$,
:			table_chans$[all],
:			"",
:			dflt_data$[all]

		call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:			"IVM_ITEMSYN",
:			user_id$,
:			"",
:			key_pfx$,
:			table_chans$[all],
:			"",
:			dflt_data$[all]

	endif
[[IVM_ITEMMAST.BDEL]]
rem --- Allow this item to be deleted?

	action$ = "I"
	whse$   = ""
	item$   = callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")

	if cvs(item$, 2) <> "" then
		call stbl("+DIR_PGM")+"ivc_deleteitem.aon", action$, whse$, item$, rd_table_chans$[all], status
		if status then callpoint!.setStatus("ABORT")
	endif
[[IVM_ITEMMAST.SAFETY_STOCK.AVAL]]
if num(callpoint!.getUserInput())<0 then callpoint!.setStatus("ABORT")
[[IVM_ITEMMAST.EOQ.AVAL]]
if num(callpoint!.getUserInput())<0 then callpoint!.setStatus("ABORT")
[[IVM_ITEMMAST.ORDER_POINT.AVAL]]
if num(callpoint!.getUserInput())<0 then callpoint!.setStatus("ABORT")
[[IVM_ITEMMAST.MAXIMUM_QTY.AVAL]]
if num(callpoint!.getUserInput())<0 then callpoint!.setStatus("ABORT")
[[IVM_ITEMMAST.LEAD_TIME.AVAL]]
if num(callpoint!.getUserInput())<0 or fpt(num(callpoint!.getUserInput())) then callpoint!.setStatus("ABORT")
[[IVM_ITEMMAST.ABC_CODE.AVAL]]
if (callpoint!.getUserInput()<"A" or callpoint!.getUserInput()>"Z") and callpoint!.getUserInput()<>" " callpoint!.setStatus("ABORT")
[[IVM_ITEMMAST.AREC]]
rem -- Get default values for new record from ivs-10D, IVS_DEFAULTS

	ivs10_dev=fnget_dev("IVS_DEFAULTS")
	dim ivs10d$:fnget_tpl$("IVS_DEFAULTS")
	callpoint!.setColumnData("IVM_ITEMMAST.ALT_SUP_FLAG", "N")
	callpoint!.setColumnData("IVM_ITEMMAST.CONV_FACTOR", "1")
	callpoint!.setColumnData("IVM_ITEMMAST.ORDER_POINT", "D")
	callpoint!.setColumnData("IVM_ITEMMAST.BAR_CODE", callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID"))

	find record (ivs10_dev, key=firm_id$+"D", dom=*next) ivs10d$

	callpoint!.setColumnData("IVM_ITEMMAST.PRODUCT_TYPE",ivs10d.product_type$)
	callpoint!.setColumnData("IVM_ITEMMAST.UNIT_OF_SALE",ivs10d.unit_of_sale$)
	callpoint!.setColumnData("IVM_ITEMMAST.PURCHASE_UM",ivs10d.purchase_um$)
	callpoint!.setColumnData("IVM_ITEMMAST.TAXABLE_FLAG",ivs10d.taxable_flag$)
	callpoint!.setColumnData("IVM_ITEMMAST.BUYER_CODE",ivs10d.buyer_code$)
	callpoint!.setColumnData("IVM_ITEMMAST.LOTSER_ITEM",ivs10d.lotser_item$)
	callpoint!.setColumnData("IVM_ITEMMAST.INVENTORIED",ivs10d.inventoried$)
	callpoint!.setColumnData("IVM_ITEMMAST.ITEM_CLASS",ivs10d.item_class$)
	callpoint!.setColumnData("IVM_ITEMMAST.STOCK_LEVEL","W")
	callpoint!.setColumnData("IVM_ITEMMAST.ABC_CODE",ivs10d.abc_code$)
	callpoint!.setColumnData("IVM_ITEMMAST.EOQ_CODE",ivs10d.eoq_code$)
	callpoint!.setColumnData("IVM_ITEMMAST.ORD_PNT_CODE",ivs10d.ord_pnt_code$)
	callpoint!.setColumnData("IVM_ITEMMAST.SAF_STK_CODE",ivs10d.saf_stk_code$)
	callpoint!.setColumnData("IVM_ITEMMAST.ITEM_TYPE",ivs10d.item_type$)
	callpoint!.setColumnData("IVM_ITEMMAST.GL_INV_ACCT",ivs10d.gl_inv_acct$)
	callpoint!.setColumnData("IVM_ITEMMAST.GL_COGS_ACCT",ivs10d.gl_cogs_acct$)
	callpoint!.setColumnData("IVM_ITEMMAST.GL_PUR_ACCT",ivs10d.gl_pur_acct$)
	callpoint!.setColumnData("IVM_ITEMMAST.GL_PPV_ACCT",ivs10d.gl_ppv_acct$)
	callpoint!.setColumnData("IVM_ITEMMAST.GL_INV_ADJ",ivs10d.gl_inv_adj$)
	callpoint!.setColumnData("IVM_ITEMMAST.GL_COGS_ADJ",ivs10d.gl_cogs_adj$)

	if user_tpl.sa$ <> "Y" then
		callpoint!.setColumnData("IVM_ITEMMAST.SA_LEVEL","N")
	else
		ivm10_dev = fnget_dev("IVC_PRODCODE")
		dim ivm10a$:fnget_tpl$("IVC_PRODCODE")
		find record(ivm10_dev, key=firm_id$+"A"+ivs10d.product_type$, dom=*next)ivm10a$
		callpoint!.setColumnData("IVM_ITEMMAST.SA_LEVEL", ivm10a.sa_level$)
	endif

	
	callpoint!.setStatus("REFRESH")

rem --- set flag in devObject to say we're on a new record

	callpoint!.setDevObject("new_rec","Y")
[[IVM_ITEMMAST.WEIGHT.AVAL]]
if num(callpoint!.getUserInput())<0 or num(callpoint!.getUserInput())>9999.99 callpoint!.setStatus("ABORT")
[[IVM_ITEMMAST.ASHO]]
callpoint!.setStatus("ABLEMAP-REFRESH")
[[IVM_ITEMMAST.<CUSTOM>]]
rem ==========================================================================
set_desc_segs: rem --- Set the description segments
               rem      IN: desc$
               rem     OUT: Display segments set
rem ==========================================================================

	desc$ = pad(desc$, 30)
	callpoint!.setColumnData("<<DISPLAY>>.ITEM_DESC_SEG_1", desc$(1, user_tpl.desc_len_1))
	callpoint!.setColumnData("<<DISPLAY>>.ITEM_DESC_SEG_2", desc$(user_tpl.desc_len_1 + 1, user_tpl.desc_len_2))
	callpoint!.setColumnData("<<DISPLAY>>.ITEM_DESC_SEG_3", desc$(user_tpl.desc_len_1 + user_tpl.desc_len_2 + 1, user_tpl.desc_len_3))
	callpoint!.setColumnData("IVM_ITEMMAST.DISPLAY_DESC", func.displayDesc(desc$, user_tpl.desc_len_1, user_tpl.desc_len_2, user_tpl.desc_len_3))

return

rem ==========================================================================
check_qoh: rem --- Check for any QOH for this item
           rem     OUT: qoh - 0 = none, <> 0 = some (may not be exact)
rem ==========================================================================

	item$ = callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
	file$ = "IVM_ITEMWHSE"
	itemwhse_dev = fnget_dev(file$)
	dim itemwhse_rec$:fnget_tpl$(file$)

	read (itemwhse_dev, key=firm_id$+item$, knum="AO_ITEM_WH", dom=*next)
	qoh = 0

	while 1
		read record (itemwhse_dev, end=*break) itemwhse_rec$
		if itemwhse_rec.firm_id$ <> firm_id$ or itemwhse_rec.item_id$ <> item$ then break
		qoh = itemwhse_rec.qty_on_hand
		if qoh then break
	wend

return

rem ==========================================================================
#include std_missing_params.src
rem ==========================================================================
[[IVM_ITEMMAST.BSHO]]
rem --- Inits

	use ::ado_util.src::util
	use ::ado_func.src::func

rem --- Open/Lock files

	num_files=7
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="IVS_DEFAULTS",open_opts$[2]="OTA"
	open_tables$[3]="GLS_PARAMS",open_opts$[3]="OTA"
	open_tables$[4]="ARS_PARAMS",open_opts$[4]="OTA"
	open_tables$[5]="IVM_ITEMWHSE",open_opts$[5]="OTA"
	open_tables$[6]="IVS_NUMBERS",open_opts$[6]="OTA"
	open_tables$[7]="IVM_ITEMSYN",open_opts$[7]="OTA"

	gosub open_tables
	if status$ <> ""  then goto std_exit

	ivs01_dev=num(open_chans$[1]),ivs01d_dev=num(open_chans$[2]),gls01_dev=num(open_chans$[3])
	ars01_dev=num(open_chans$[4]),ivm02_dev=num(open_chans$[5]),ivs10_dev=num(open_chans$[6])

rem --- Dimension miscellaneous string templates

	dim ivs01a$:open_tpls$[1],ivs01d$:open_tpls$[2],gls01a$:open_tpls$[3],ars01a$:open_tpls$[4]
	dim ivm02a$:open_tpls$[5],ivs10n$:open_tpls$[6]

rem --- check to see if main GL param rec (firm/GL/00) exists; if not, tell user to set it up first
	gls01a_key$=firm_id$+"GL00"
	find record (gls01_dev,key=gls01a_key$,err=*next) gls01a$
	if cvs(gls01a.current_per$,2)=""
		msg_id$="GL_PARAM_ERR"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		gosub remove_process_bar
		release
	endif

rem --- init/parameters

	disable_str$=""
	enable_str$=""
	dim info$[20]

	ivs01a_key$=firm_id$+"IV00"
	find record (ivs01_dev,key=ivs01a_key$,err=std_missing_params) ivs01a$

	dir_pgm1$=stbl("+DIR_PGM",err=*next)
	call dir_pgm1$+"adc_application.aon","AR",info$[all]
	ar$=info$[20]
	call dir_pgm1$+"adc_application.aon","AP",info$[all]
	ap$=info$[20]
	call dir_pgm1$+"adc_application.aon","BM",info$[all]
	bm$=info$[20]
	call dir_pgm1$+"adc_application.aon","GL",info$[all]
	gl$=info$[20]
	call dir_pgm1$+"adc_application.aon","OP",info$[all]
	op$=info$[20]
	call dir_pgm1$+"adc_application.aon","PO",info$[all]
	po$=info$[20]
	call dir_pgm1$+"adc_application.aon","SF",info$[all]
	wo$=info$[20]
	callpoint!.setDevObject("wo_installed",wo$)
	call dir_pgm1$+"adc_application.aon","SA",info$[all]
	sa$=info$[20]

rem --- Setup user_tpl$

	dim user_tpl$:"sa:c(1)," +
:                "desc_len_01:n(1*), desc_len_02:n(1*), desc_len_03:n(1*)," +
:                "prev_desc_seg_1:c(1*), prev_desc_seg_2:c(1*), prev_desc_seg_3:c(1*)," +
:                "old_upc:c(1*),old_barcode:c(1*)"

	user_tpl.sa$=sa$

rem --- Setup description lengths

	user_tpl.desc_len_01 = num(ivs01a.desc_len_01$)
	user_tpl.desc_len_02 = num(ivs01a.desc_len_02$)
	user_tpl.desc_len_03 = num(ivs01a.desc_len_03$)

	func.setLen1(int(user_tpl.desc_len_01))
	func.setLen2(int(user_tpl.desc_len_02))
	func.setLen3(int(user_tpl.desc_len_03))

rem --- Set user labels and lengths for description segments 

	util.changeText(Form!, Translate!.getTranslation("AON_SEGMENT_DESCRIPTION_1:"), cvs(ivs01a.user_desc_lb_01$, 2) + ":")
	callpoint!.setTableColumnAttribute("<<DISPLAY>>.ITEM_DESC_SEG_1", "MAXL", str(user_tpl.desc_len_01))
	first_desc!=util.getControl(Form!,callpoint!,"<<DISPLAY>>.ITEM_DESC_SEG_1")
	first_desc!.setMask(fill(user_tpl.desc_len_01,"X"))

	if cvs(ivs01a.user_desc_lb_02$, 2) <> "" then
		util.changeText(Form!, Translate!.getTranslation("AON_SEGMENT_DESCRIPTION_2:"), cvs(ivs01a.user_desc_lb_02$, 2) + ":")
	else
		util.changeText(Form!, Translate!.getTranslation("AON_SEGMENT_DESCRIPTION_2:"), "")
	endif

	if user_tpl.desc_len_02 <> 0 then
		callpoint!.setTableColumnAttribute("<<DISPLAY>>.ITEM_DESC_SEG_2", "MAXL", str(user_tpl.desc_len_02))
		second_desc!=util.getControl(Form!,callpoint!,"<<DISPLAY>>.ITEM_DESC_SEG_2")
		second_desc!.setMask(fill(user_tpl.desc_len_02,"X"))
	else
		callpoint!.setColumnEnabled("<<DISPLAY>>.ITEM_DESC_SEG_2", -1)
	endif

	if cvs(ivs01a.user_desc_lb_03$, 2) <> "" then 
		util.changeText(Form!, Translate!.getTranslation("AON_SEGMENT_DESCRIPTION_3:"), cvs(ivs01a.user_desc_lb_03$, 2) + ":")
	else
		util.changeText(Form!, Translate!.getTranslation("AON_SEGMENT_DESCRIPTION_3:"), "")
	endif

	if user_tpl.desc_len_03 <>0 then
		callpoint!.setTableColumnAttribute("<<DISPLAY>>.ITEM_DESC_SEG_3", "MAXL", str(user_tpl.desc_len_03))
		third_desc!=util.getControl(Form!,callpoint!,"<<DISPLAY>>.ITEM_DESC_SEG_3")
		third_desc!.setMask(fill(user_tpl.desc_len_03,"X"))
	else
		callpoint!.setColumnEnabled("<<DISPLAY>>.ITEM_DESC_SEG_3", -1)
	endif

rem --- Disable option menu items

	callpoint!.setOptionEnabled("STOK",0); rem --- per bug 5774, disabled for now
	if ap$<>"Y" disable_str$=disable_str$+"IVM_ITEMVEND;"; rem --- this is a detail window, give alias name
	if pos(ivs01a.lifofifo$="LF")=0 callpoint!.setOptionEnabled("LIFO",0)
	if pos(ivs01a.lotser_flag$="LS")=0 callpoint!.setOptionEnabled("LTRN",0)
	if op$<>"Y" callpoint!.setOptionEnabled("SORD",0)
	if po$<>"Y" callpoint!.setOptionEnabled("PORD",0)
	if bm$<>"Y" callpoint!.setOptionEnabled("BOMU",0)

	if disable_str$<>"" call stbl("+DIR_SYP")+"bam_enable_pop.bbj",Form!,enable_str$,disable_str$

rem --- additional file opens, depending on which apps are installed, param values, etc.

	more_files$=""
	files=0

	if pos(ivs01a.lifofifo$="LF")<>0 then 
		more_files$=more_files$+"IVM_ITEMTIER;"
		files=files+1
	endif

	if pos(ivs01a.lotser_flag$="LS")<>0 then 
		more_files$=more_files$+"IVM_LSMASTER;IVM_LSACT;IVT_LSTRANS;"
		files=files+3
	endif

	if ivs01a.master_flag_01$="Y" or ivs01a.master_flag_02$="Y" or ivs01a.master_flag_03$="Y"
		more_files$=more_files$+"IVM_DESCRIP1;IVM_DESCRIP2;IVM_DESCRIP3;"
		files=files+3
	endif 

	if ar$="Y" then 
		more_files$=more_files$+"ARM_CUSTMAST;ARC_DISTCODE;"
		files=files+2
	endif

	if bm$="Y" then 
		more_files$=more_files$+"BMM_BILLMAST;BMM_BILLMAT;"
		files=files+2
	endif

	if op$="Y" then 
		more_files$=more_files$+"OPE_ORDHDR;OPE_ORDDET;OPE_ORDITEM;"
		files=files+3
	endif

	if po$="Y" then 
		more_files$=more_files$+"POE_REQHDR;POE_POHDR;POE_REQDET;POE_PODET;POC_LINECODE;POT_RECHDR;POT_RECDET;"
		files=files+7
	endif

	if wo$="Y" then 
		more_files$=more_files$+"SFE_WOMASTR;SFE_WOMATL;"
		files=files+2
	endif

	if files then
		begfile=1,endfile=files,wfile=1
		dim files$[files],options$[files],chans$[files],templates$[files]

		while pos(";"=more_files$)
			files$[wfile]=more_files$(1,pos(";"=more_files$)-1)
			more_files$=more_files$(pos(";"=more_files$)+1)
			wfile=wfile+1
		wend

		for wkx=begfile to endfile
			options$[wkx]="OTA"
		next wkx

		call dir_pgm$+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:	                                 	chans$[all],templates$[all],table_chans$[all],batch,status$
		if status$<>"" then
			remove_process_bar:
			bbjAPI!=bbjAPI()
			rdFuncSpace!=bbjAPI!.getGroupNamespace()
			rdFuncSpace!.setValue("+build_task","OFF")
			release
		endif
	endif

rem --- if gl installed, does it interface to inventory?

	if gl$="Y" 
		call dir_pgm1$+"adc_application.aon","IV",info$[all]
		gl$=info$[9]
	endif

rem --- Distribute GL by item?

	di$="N"
	if ar$="Y"
		rem --- check to see if main AR param rec (firm/AR/00) exists; if not, tell user to set it up first
		ars01a_key$=firm_id$+"AR00"
		find record (ars01_dev,key=ars01a_key$,err=*next) ars01a$
		if cvs(ars01a.current_per$,2)=""
			msg_id$="AR_PARAM_ERR"
			dim msg_tokens$[1]
			msg_opt$=""
			gosub disp_message
			gosub remove_process_bar
			release
		endif

		di$=ars01a.dist_by_item$
		if gl$="N" di$="N"
	endif
	callpoint!.setDevObject("di",di$)

rem --- Disable fields based on parameters

	able_map = 0
	wmap$=callpoint!.getAbleMap()

rem --- if you aren't doing lotted/serialized

	if pos(ivs01a.lotser_flag$="LS")=0 then callpoint!.setColumnEnabled("IVM_ITEMMAST.LOTSER_ITEM",-1)

rem --- If you don't distribute by item, or there's no GL, disable GL fields

	if di$<>"N" or gl$<>"Y"
		fields_to_disable$="GL_INV_ACCT     GL_COGS_ACCT    GL_PUR_ACCT     GL_PPV_ACCT     GL_INV_ADJ      GL_COGS_ADJ     "
		for wfield=1 to len(fields_to_disable$)-1 step 16
			callpoint!.setColumnEnabled("IVM_ITEMMAST."+cvs(fields_to_disable$(wfield,16),3),-1)					
		next wfield
	endif

rem --- Disable Sales Analysis level if SA is not installed 

	if sa$<>"Y" then
		callpoint!.setColumnEnabled("IVM_ITEMMAST.SA_LEVEL",-1)
	endif
[[IVM_ITEMMAST.AOPT-PORD]]
cp_item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[2,1]
dflt_data$[1,0]="ITEM_ID"
dflt_data$[1,1]=cp_item_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"IVR_OPENPO",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]
[[IVM_ITEMMAST.AOPT-SORD]]
cp_item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[2,1]
dflt_data$[1,0]="ITEM_ID"
dflt_data$[1,1]=cp_item_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"IVR_OPENSO",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]
[[IVM_ITEMMAST.AOPT-LTRN]]
cp_item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[2,1]
dflt_data$[1,0]="ITEM_ID_1"
dflt_data$[1,1]=cp_item_id$
dflt_data$[2,0]="ITEM_ID_2"
dflt_data$[2,1]=cp_item_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"IVR_LSTRANHIST",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]
[[IVM_ITEMMAST.AOPT-IHST]]
cp_item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[2,1]
dflt_data$[1,0]="ITEM_ID_1"
dflt_data$[1,1]=cp_item_id$
dflt_data$[2,0]="ITEM_ID_2"
dflt_data$[2,1]=cp_item_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"IVR_TRANSHIST",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]
[[IVM_ITEMMAST.AOPT-LIFO]]
cp_item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[2,1]
dflt_data$[1,0]="ITEM_ID_1"
dflt_data$[1,1]=cp_item_id$
dflt_data$[2,0]="ITEM_ID_2"
dflt_data$[2,1]=cp_item_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"IVR_LIFOFIFO",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]
