[[OPE_INVCASH.BWAR]]
rem --- if a credit card transaction, perform mod10 check on cc# field and mask

	wtype$=callpoint!.getDevObject("cash_code_type")
	ccmask$="X"
	ccmask$=stbl("+CARD_FILL_CHAR",ERR=*next)
	if wtype$="P"
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
[[OPE_INVCASH.<CUSTOM>]]
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

	start_block = 1
	found       = 0

	code$ = callpoint!.getUserInput()
	file_name$ = "ARC_CASHCODE"
	dim cashcode_rec$:fnget_tpl$(file_name$)

	if start_block then
		find record (fnget_dev(file_name$), key=firm_id$+"C"+code$, dom=*endif) cashcode_rec$
		callpoint!.setDevObject("cash_code_type",cashcode_rec.trans_type$)
		found = 1
	endif

	if !found then
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

	if pos(cashcode_rec.trans_type$="$CP")=0 then
		callpoint!.setStatus("ABORT")
		break; rem --- exit callpoint
	endif

rem --- Disable fields and set minimums by trans type

	if cashcode_rec.trans_type$ = "C" then 		
		callpoint!.setColumnEnabled("OPE_INVCASH.AR_CHECK_NO", 1)
		callpoint!.setColumnEnabled("OPE_INVCASH.EXPIRE_DATE", 0)
		callpoint!.setColumnEnabled("OPE_INVCASH.PAYMENT_ID", 1)
		callpoint!.setTableColumnAttribute("OPE_INVCASH.AR_CHECK_NO","MINL","1")
		rem callpoint!.setTableColumnAttribute("OPE_INVCASH.PAYMENT_ID","MINL","1")
	else
		if cashcode_rec.trans_type$ = "P" then 		
			callpoint!.setColumnEnabled("OPE_INVCASH.EXPIRE_DATE", 1)
			callpoint!.setColumnEnabled("OPE_INVCASH.AR_CHECK_NO", 0)
			callpoint!.setColumnEnabled("OPE_INVCASH.PAYMENT_ID", 1)
			callpoint!.setTableColumnAttribute("OPE_INVCASH.EXPIRE_DATE","MINL","1")
			callpoint!.setTableColumnAttribute("OPE_INVCASH.PAYMENT_ID","MINL","1")
		else
			if cashcode_rec.trans_type$ = "$" then
				callpoint!.setColumnEnabled("OPE_INVCASH.PAYMENT_ID", 0)
				callpoint!.setColumnEnabled("OPE_INVCASH.AR_CHECK_NO", 0)
				callpoint!.setColumnEnabled("OPE_INVCASH.EXPIRE_DATE", 0)
			endif
		endif
	endif

rem --- Memo or Credit Card#?

	if cashcode_rec.trans_type$ = "C" then 
		util.changeText(Form!, Translate!.getTranslation("AON_CREDIT_CARD_OR_ABA_NO"), Translate!.getTranslation("AON_ABA_NO"))
		util.changeText(Form!, Translate!.getTranslation("AON_CREDIT_CARD_NO"), Translate!.getTranslation("AON_ABA_NO"))
	else
		if cashcode_rec.trans_type$ = "P" then
			util.changeText(Form!, Translate!.getTranslation("AON_CREDIT_CARD_OR_ABA_NO"), Translate!.getTranslation("AON_CREDIT_CARD_NO"))
			util.changeText(Form!, Translate!.getTranslation("AON_ABA_NO"), Translate!.getTranslation("AON_CREDIT_CARD_NO"))
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

	num_files = 4
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="ARM_CUSTMAST", open_opts$[1]="OTA"
	open_tables$[2]="ARC_CASHCODE", open_opts$[2]="OTA"
	open_tables$[3]="OPE_ORDHDR",   open_opts$[3]="OTA"
	open_tables$[4]="OPE_ORDDET",   open_opts$[4]="OTA"

	gosub open_tables

rem --- Global string templates

	dim user_tpl$:"ext_price:n(15), taxable:n(15), ext_cost:n(15)"

rem --- Print Invoice global

	callpoint!.setDevObject("print_invoice", "N")
	callpoint!.setDevObject("cash_code_type","")
