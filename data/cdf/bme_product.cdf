[[BME_PRODUCT.BEND]]
rem --- remove software lock on batch, if batching

	batch$=stbl("+BATCH_NO",err=*next)
	if num(batch$)<>0
		lock_table$="ADM_PROCBATCHES"
		lock_record$=firm_id$+stbl("+PROCESS_ID")+batch$
		lock_type$="X"
		lock_status$=""
		lock_disp$=""
		call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$
	endif
[[BME_PRODUCT.ITEM_ID.BINQ]]
rem --- Do custom query

	query_id$="BOM_ITEMS"
	query_mode$="DEFAULT"
	dim filter_defs$[1,1]
	filter_defs$[1,0] = "IVM_ITEMWHSE.WAREHOUSE_ID"
	filter_defs$[1,1] = "='"+callpoint!.getColumnData("BME_PRODUCT.WAREHOUSE_ID")+"'"

	call stbl("+DIR_SYP")+"bax_query.bbj",
:		gui_dev,
:		form!,
:		query_id$,
:		query_mode$,
:		table_chans$[all],
:		sel_key$,filter_defs$[all]

	if sel_key$<>""
		call stbl("+DIR_SYP")+"bac_key_template.bbj",
:			"IVM_ITEMWHSE",
:			"PRIMARY",
:			ivm_whse_key$,
:			table_chans$[all],
:			status$
		dim ivm_whse_key$:ivm_whse_key$
		ivm_whse_key$=sel_key$
		callpoint!.setColumnData("BME_PRODUCT.ITEM_ID",ivm_whse_key.item_id$,1)
	endif
	callpoint!.setStatus("ACTIVATE-ABORT")
[[BME_PRODUCT.BTBL]]
rem --- Get Batch information

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]
callpoint!.setTableColumnAttribute("BME_PRODUCT.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[BME_PRODUCT.ARAR]]
rem --- Get Unit of Sale

	item$=callpoint!.getColumnData("BME_PRODUCT.ITEM_ID")
	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")

	while 1
		read record (ivm01_dev,key=firm_id$+item$,dom=*break)ivm01a$
		callpoint!.setColumnData("<<DISPLAY>>.UNIT_OF_SALE",ivm01a.unit_of_sale$,1)
		break
	wend

	bill_no$=item$
	gosub disp_bill_comments
[[BME_PRODUCT.BWRI]]
rem --- Validate Quantity

	if num(callpoint!.getColumnData("BME_PRODUCT.QTY_ORDERED")) <= 0
		msg_id$="IV_QTY_GT_ZERO"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[BME_PRODUCT.ADIS]]
rem --- set comments

	bill_no$=callpoint!.getColumnData("BME_PRODUCT.ITEM_ID")
	gosub disp_bill_comments
[[BME_PRODUCT.AREC]]
rem --- Set default warehouse

	if callpoint!.getDevObject("multi_wh")<>"Y"
		gosub disable_wh
	else
		wh$=callpoint!.getDevObject("def_wh")
		callpoint!.setColumnData("BME_PRODUCT.WAREHOUSE_ID",wh$)
	endif

	callpoint!.setColumnData("<<DISPLAY>>.COMMENTS","")
[[BME_PRODUCT.QTY_ORDERED.AVAL]]
rem --- Check for zero quantity

	if num(callpoint!.getUserInput()) = 0
		callpoint!.setMessage("IV_QTY_ZERO")
		callpoint!.setStatus("ABORT")
	endif
[[BME_PRODUCT.<CUSTOM>]]
rem ===========================================================================
check_item_whse: rem --- Check that a warehouse record exists for this item
                 rem      IN: wh$
                 rem          item$
                 rem     OUT: setDevObject item_wh_failed
rem ===========================================================================

	file$ = "IVM_ITEMWHSE"
	ivm02_dev = fnget_dev(file$)
	dim ivm02a$:fnget_tpl$(file$)
	callpoint!.setDevObject("item_wh_failed","1")
			
	if cvs(item$, 2) <> "" and cvs(wh$, 2) <> "" then
		find record (ivm02_dev, key=firm_id$+wh$+item$, knum="PRIMARY", dom=*endif) ivm02a$
		callpoint!.setDevObject("item_wh_failed","0")
	endif

	if callpoint!.getDevObject("item_wh_failed") = "1" then 
		callpoint!.setMessage("IV_NO_WHSE_ITEM")
		callpoint!.setStatus("ABORT")
	endif

	return


rem =======================================================
disp_bill_comments:
	rem --- input: bill_no$
rem =======================================================
	cmt_text$=""

	bmm09_dev=fnget_dev("BMM_BILLCMTS")
	dim bmm09a$:fnget_tpl$("BMM_BILLCMTS")
	bmm09_key$=firm_id$+bill_no$
	more=1
	read(bmm09_dev,key=bmm09_key$,dom=*next)
	while more
		readrecord(bmm09_dev,end=*break)bmm09a$
		 
		if bmm09a.firm_id$ = firm_id$ and bmm09a.bill_no$ = bill_no$ then
			cmt_text$ = cmt_text$ + cvs(bmm09a.std_comments$,3)+$0A$
		endif				
	wend
	callpoint!.setColumnData("<<DISPLAY>>.comments",cmt_text$)
	callpoint!.setStatus("REFRESH")
return

disable_wh:
	dim ctl_name$[1]
	dim ctl_stat$[1]
	ctl_name$[1]="BME_PRODUCT.WAREHOUSE_ID"
	ctl_stat$[1]="D"
	wh$=callpoint!.getDevObject("def_wh")
	callpoint!.setColumnData("BME_PRODUCT.WAREHOUSE_ID",wh$,1)
	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$[1],"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$[1]
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")
return
#include std_missing_params.src
[[BME_PRODUCT.PROD_DATE.AVAL]]
rem --- make sure accting date is in an appropriate GL period

	gl$=callpoint!.getDevObject("glint")
	prod_date$=callpoint!.getUserInput()        
	if gl$="Y" 
		call stbl("+DIR_PGM")+"glc_datecheck.aon",prod_date$,"Y",per$,yr$,status
		if status>99
			callpoint!.setStatus("ABORT")
		endif
	endif
[[BME_PRODUCT.ITEM_ID.AVAL]]
rem --- Validate Item/Whse

	item$=callpoint!.getUserInput()
	wh$=callpoint!.getColumnData("BME_PRODUCT.WAREHOUSE_ID")
	gosub check_item_whse
	if callpoint!.getDevObject("item_wh_failed") = "1" break

rem --- Get Unit of Sale

	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")

	while 1
		read record (ivm01_dev,key=firm_id$+item$,dom=*break)ivm01a$
		callpoint!.setColumnData("<<DISPLAY>>.UNIT_OF_SALE",ivm01a.unit_of_sale$,1)
		break
	wend

	bill_no$=item$
	gosub disp_bill_comments
[[BME_PRODUCT.BSHO]]
rem --- Open files

	num_files=4
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVM_ITEMMAST",open_opts$[1]="OTA"
	open_tables$[2]="IVM_ITEMWHSE",open_opts$[2]="OTA"
	open_tables$[3]="IVS_PARAMS",open_opts$[3]="OTA"
	open_tables$[4]="BMM_BILLCMTS",open_opts$[4]="OTA"
	gosub open_tables

rem --- get multiple warehouse flag and default warehouse

	ivs01_dev=num(open_chans$[3])
	dim ivs01a$:open_tpls$[3]
	read record (ivs01_dev,key=firm_id$+"IV00",dom=std_missing_params)ivs01a$

	callpoint!.setDevObject("multi_wh",ivs01a.multi_whse$)
	callpoint!.setDevObject("def_wh",ivs01a.warehouse_id$)
	if ivs01a.multi_whse$<>"Y"
		gosub disable_wh
	else
		callpoint!.setColumnData("BME_PRODUCT.WAREHOUSE_ID",ivs01a.warehouse_id$)
	endif

rem --- Additional Init
	gl$="N"
	status=0
	source$=pgm(-2)
	call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"IV",glw11$,gl$,status
	if status<>0 goto std_exit
	callpoint!.setDevObject("glint",gl$)

rem --- Additional Init

	gl$="N"
	status=0
	source$=pgm(-2)
	call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"BM",glw11$,gl$,status
	if status<>0 goto std_exit
[[BME_PRODUCT.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
