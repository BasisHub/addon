[[OPE_INVCASH.ADEL]]
rem --- Set devObjects to tell ope_invhdr there aren't any ope_invcash transactions for this invoice.
	callpoint!.setDevObject("print_invoice", "N")
	callpoint!.setDevObject("cash_code_type","")

rem --- There is only one ope_invcash recprd per invoice, so exit form after record deleted.
	callpoint!.setStatus("EXIT")
[[OPE_INVCASH.BWRI]]
rem --- Initialize RTP modified fields for modified existing records
	if callpoint!.getRecordMode()="C" then
		rec_data.mod_user$=sysinfo.user_id$
		rec_data.mod_date$=date(0:"%Yd%Mz%Dz")
		rec_data.mod_time$=date(0:"%Hz%mz")
	endif
[[OPE_INVCASH.AREC]]
rem --- Initialize RTP trans_status and created fields
	rem --- TRANS_STATUS set to "E" via form Preset Value
	callpoint!.setColumnData("OPE_INVCASH.CREATED_USER",sysinfo.user_id$)
	callpoint!.setColumnData("OPE_INVCASH.CREATED_DATE",date(0:"%Yd%Mz%Dz"))
	callpoint!.setColumnData("OPE_INVCASH.CREATED_TIME",date(0:"%Hz%mz"))
	callpoint!.setColumnData("OPE_INVCASH.AUDIT_NUMBER","0")
[[OPE_INVCASH.BWAR]]
rem --- if a credit card transaction, perform mod10 check on pymt ID field and mask
rem --- note: only for backward compatability; credit card # in its own field as of v12
rem --- but used to be stored in pymt ID field

	wtype$=callpoint!.getDevObject("cash_code_type")
	ccmask$="X"
	ccmask$=stbl("+CARD_FILL_CHAR",ERR=*next)
	if wtype$="P" and cvs(callpoint!.getColumnData("OPE_INVCASH.PAYMENT_ID"),3)<>""
		cc_card_raw$=cvs(callpoint!.getColumnData("OPE_INVCASH.PAYMENT_ID"),3)
		cc_card$=""
		cc_status$=""
		for x=1 to len(cc_card_raw$)
			if cc_card_raw$(x,1)>="0" and cc_card_raw$(x,1)<="9"
				cc_card$=cc_card$+cc_card_raw$(x,1)
			endif
		next x
		if len(cc_card$)>4 
			gosub mod10_check
			if cc_status$=""
				cc_card_raw$(1,len(cc_card_raw$)-4)=fill(len(cc_card_raw$)-4,ccmask$)
				callpoint!.setColumnData("OPE_INVCASH.PAYMENT_ID",cc_card_raw$)
			endif
		endif
	endif
[[OPE_INVCASH.<CUSTOM>]]
#include std_missing_params.src

rem ==============================================
rem -- mod10_check; see if payment ID field contains valid cc# format
rem -- incoming cc_card$ is the ope_invcash.payment_id field
rem -- return cc_status$ of blank or INVALID
rem ==============================================
mod10_check:

    cc_digits$ = ""
    cc_curr_digit = 0

    for cc_temp = len(cc_card$) to 1 step -1
        cc_curr_digit = cc_curr_digit + 1
        cc_no = num(cc_card$(cc_temp,1)) * iff(mod(cc_curr_digit,2)=0, 2, 1)
        cc_digits$ = str(cc_no) + cc_digits$
    next cc_temp

    cc_total = 0
    for cc_temp = 1 to len(cc_digits$)
        cc_total = cc_total + num(cc_digits$(cc_temp, 1))
    next cc_temp

    if mod(cc_total, 10) <> 0 then cc_status$ = "INVALID"

    return
[[OPE_INVCASH.BREX]]
rem --- Set invoice printing global

	callpoint!.setDevObject( "print_invoice", callpoint!.getColumnData("<<DISPLAY>>.PRINT") )
[[OPE_INVCASH.ARAR]]
print "OPE_INVCASH:ARAR"; rem debug

rem --- Set table_chans$[all] into util object for getDev() and getTmpl()

	declare ArrayObject tableChans!

	call stbl("+DIR_PGM")+"adc_array.aon::str_array2object", table_chans$[all], tableChans!, status
	if status = 999 then goto std_exit
	util.setTableChans(tableChans!)

rem --- Order Helper object

	declare OrderHelper ordHelp!
	ordHelp! = new OrderHelper(firm_id$, callpoint!)

rem --- Total detail lines

	cust_id$  = callpoint!.getColumnData("OPE_INVCASH.CUSTOMER_ID")
	order_no$ = callpoint!.getColumnData("OPE_INVCASH.ORDER_NO")
	print "---customer: ", cust_id$; rem debug
	print "---order_no: ", order_no$; rem debug

	ordHelp!.totalSalesDisk(cust_id$, order_no$)
	
	user_tpl.ext_price = ordHelp!.getExtPrice()
	user_tpl.taxable   = ordHelp!.getTaxable()
	user_tpl.ext_cost  = ordHelp!.getExtCost()

rem --- Set Invoice Amount

	tax_amount   = num(callpoint!.getDevObject("tax_amount"))
	freight_amt  = num(callpoint!.getDevObject("freight_amt"))
	discount_amt = num(callpoint!.getDevObject("discount_amt"))
	invoice_amt  = user_tpl.ext_price + tax_amount - discount_amt + freight_amt

	if invoice_amt <> num(callpoint!.getColumnData("OPE_INVCASH.INVOICE_AMT")) then
		callpoint!.setColumnData("OPE_INVCASH.INVOICE_AMT", str(invoice_amt))
		callpoint!.setStatus("MODIFIED;REFRESH")
	endif

rem --- Set customer name default

	if cvs(callpoint!.getColumnData("OPE_INVCASH.CUSTOMER_NAME"), 2) = "" then
		file_name$ = "ARM_CUSTMAST"
		dim custmast_rec$:fnget_tpl$(file_name$)
		find record (fnget_dev(file_name$), key=firm_id$+callpoint!.getColumnData("OPE_INVCASH.CUSTOMER_ID")) custmast_rec$
		callpoint!.setTableColumnAttribute("OPE_INVCASH.CUSTOMER_NAME","DFLT", custmast_rec.customer_name$)
		print "---Customer Name set: ", custmast_rec.customer_name$; rem debug
	endif

rem --- Set change amount

	tendered = num(callpoint!.getColumnData("OPE_INVCASH.TENDERED_AMT"))

	if tendered - invoice_amt > 0 then
		callpoint!.setColumnData("<<DISPLAY>>.CHANGE", str(tendered - invoice_amt))
		callpoint!.setStatus("REFRESH")
		print "---Set Change Amount:", tendered - invoice_amt; rem debug
	endif
[[OPE_INVCASH.TENDERED_AMT.AVAL]]
print "OPE_INVCASH.TENDERED_AMT:AVAL"; rem debug

rem --- Tendered enough?

	tendered    = num(callpoint!.getUserInput())
	invoice_amt = num(callpoint!.getColumnData("OPE_INVCASH.INVOICE_AMT"))

	if tendered < invoice_amt then
		msg_id$ = "OP_TENDER_MORE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

rem --- Set change amount

	callpoint!.setColumnData("<<DISPLAY>>.CHANGE", str(tendered - invoice_amt))
	callpoint!.setStatus("REFRESH")
[[OPE_INVCASH.EXPIRE_DATE.AVAL]]
print "OPE_INVCASH.EXPIRE_DATE:AVAL"; rem debug

rem --- Expiration date can't by more than today

	if callpoint!.getUserInput() <= sysinfo.system_date$ then
		msg_id$="OP_CC_EXPIRED"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[OPE_INVCASH.CASH_REC_CD.AVAL]]
print "OPE_INVCASH.CASH_REC_CD:AVAL"; rem debug

rem --- Validate cash receipt code
	code$ = callpoint!.getUserInput()
	file_name$ = "ARC_CASHCODE"
	dim cashcode_rec$:fnget_tpl$(file_name$)
	found = 0
	find record (fnget_dev(file_name$), key=firm_id$+"C"+code$, dom=*endif) cashcode_rec$; found = 1
	if found then
		if pos(cashcode_rec.trans_type$="$CP")=0 then
			callpoint!.setStatus("ABORT")
			break; rem --- exit callpoint
		endif
		callpoint!.setDevObject("cash_code_type",cashcode_rec.trans_type$)

		rem --- If using Bank Rec, verify the Cash Receipts Code’s GL Cash Account is set up in GLM_BANKMASTER (glm-05)
		if callpoint!.getDevObject("br_interface")="Y" then
			glm05_dev=fnget_dev("@GLM_BANKMASTER")
			dim glm05a$:fnget_tpl$("@GLM_BANKMASTER")
			findrecord(glm05_dev,key=firm_id$+cashcode_rec.gl_cash_acct$,dom=*next)glm05a$
			if cvs(glm05a.gl_account$,2)="" then
				msg_id$="AR_NOT_BNKREC_CASHCD"
				gosub disp_message
				callpoint!.setStatus("ABORT")
				break
			endif
		endif
	else
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

rem --- Disable fields and set minimums by trans type

	if cashcode_rec.trans_type$ = "C" then
 		callpoint!.setColumnData("OPE_INVCASH.EXPIRE_DATE","",1)
		callpoint!.setColumnData("OPE_INVCASH.CREDIT_CARD_NO","",1)
		callpoint!.setColumnEnabled("OPE_INVCASH.AR_CHECK_NO", 1)
		callpoint!.setColumnEnabled("OPE_INVCASH.PAYMENT_ID", 1)
		callpoint!.setColumnEnabled("OPE_INVCASH.EXPIRE_DATE", 0)		
		callpoint!.setColumnEnabled("OPE_INVCASH.CREDIT_CARD_NO", 0)
		callpoint!.setTableColumnAttribute("OPE_INVCASH.AR_CHECK_NO","MINL","1")
	else
		if cashcode_rec.trans_type$ = "P" then
 			callpoint!.setColumnData("OPE_INVCASH.AR_CHECK_NO","",1)
			callpoint!.setColumnData("OPE_INVCASH.PAYMENT_ID","",1)
			callpoint!.setColumnEnabled("OPE_INVCASH.EXPIRE_DATE", 1)
			callpoint!.setColumnEnabled("OPE_INVCASH.CREDIT_CARD_NO", 1)		
			callpoint!.setColumnEnabled("OPE_INVCASH.AR_CHECK_NO", 0)			
			callpoint!.setColumnEnabled("OPE_INVCASH.PAYMENT_ID", 0)
			callpoint!.setTableColumnAttribute("OPE_INVCASH.EXPIRE_DATE","MINL","1")
		else
			if cashcode_rec.trans_type$ = "$" then
 				callpoint!.setColumnData("OPE_INVCASH.AR_CHECK_NO","",1)
				callpoint!.setColumnData("OPE_INVCASH.PAYMENT_ID","",1)
 				callpoint!.setColumnData("OPE_INVCASH.EXPIRE_DATE","",1)
				callpoint!.setColumnData("OPE_INVCASH.CREDIT_CARD_NO","",1)
				callpoint!.setColumnEnabled("OPE_INVCASH.PAYMENT_ID", 0)
				callpoint!.setColumnEnabled("OPE_INVCASH.AR_CHECK_NO", 0)
				callpoint!.setColumnEnabled("OPE_INVCASH.EXPIRE_DATE", 0)
				callpoint!.setColumnEnabled("OPE_INVCASH.CREDIT_CARD_NO", 0)
			endif
		endif
	endif

rem --- Check for discount

	if discount_amt<>0 and cashcode_rec.disc_flag$<>"Y" then
		msg_id$="OP_NO_DISCOUNT"
		gosub disp_message
		callpoint!.setStauts("ABORT")
		break; rem --- exit callpoint
	endif

rem --- Set default Tendered Amount

	terndered_amt = num(callpoint!.getColumnData("OPE_INVCASH.TENDERED_AMT"))

	if cashcode_rec.trans_type$ = "P" or (cashcode_rec.trans_type$ = "C" and terndered_amt = 0) then
		callpoint!.setTableColumnAttribute("OPE_INVCASH.TENDERED_AMT","DFLT", str(invoice_amt))
	endif
[[OPE_INVCASH.BSHO]]
print "OPE_INVCASH:BSHO"; rem debug

rem --- Inits

	use ::ado_util.src::util
	use ::ado_order.src::OrderHelper
	use ::adc_array.aon::ArrayObject

rem --- Open files

	num_files = 3
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="ARM_CUSTMAST", open_opts$[1]="OTA"
	open_tables$[2]="ARC_CASHCODE", open_opts$[2]="OTA"
	open_tables$[3]="ARS_PARAMS", open_opts$[3]="OTA@"

	gosub open_tables

	ars01_dev=num(open_chans$[3])
	dim ars01a$:open_tpls$[3]

rem --- Retrieve AR parameter data

	ars01a_key$=firm_id$+"AR00"
	find record (ars01_dev,key=ars01a_key$,err=std_missing_params) ars01a$
	callpoint!.setDevObject("br_interface",ars01a.br_interface$)

rem --- Additional/optional opens

	num_files = 1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLM_BANKMASTER", open_opts$[1]="OTA@"

	gosub open_tables

rem --- Global string templates

	dim user_tpl$:"ext_price:n(15), taxable:n(15), ext_cost:n(15)"

rem --- Print Invoice global

	callpoint!.setDevObject("print_invoice", "N")
	callpoint!.setDevObject("cash_code_type","")
