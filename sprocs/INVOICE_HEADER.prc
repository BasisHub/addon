rem ----------------------------------------------------------------------------
rem Program: INVOICE_HEADER.prc
rem Description: Stored Procedure to get the header and footer informations to print on the invoices
rem
rem Author(s): S. Birster
rem Revised: 02.23.2011
rem ----------------------------------------------------------------------------

rem Set of utility methods
use ::ado_func.src::func

rem Declare some variables ahead of time
declare BBjStoredProcedureData sp!
declare BBjRecordSet rs!
declare BBjRecordData data!

rem Get the infomation object for the Stored Procedure
sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem Get the IN parameters used by the procedure
firm_id$ = sp!.getParameter("FIRM_ID")
customer_id$ = sp!.getParameter("CUSTOMER_ID")
order_no$ = sp!.getParameter("ORDER_NO")

barista_wd$=stbl("BARISTA_WD",err=*next)

if barista_wd$="" then
    barista_wd$="/usr2/dev_addon/barista/"
endif

sv_wd$=dir("")
chdir barista_wd$


rem Create a memory record set to hold results.
rem Columns for the record set are defined using a string template
rs! = BBJAPI().createMemoryRecordSet("INVOICE_DATE:C(8), INVOICE_NO:C(7), COMP_ADDR_LINE_1:C(30), COMP_ADDR_LINE_2:C(30), COMP_ADDR_LINE_3:C(30), COMP_ADDR_LINE_4:C(30),
:                                                            BILL_ADDR_LINE_1:C(30), BILL_ADDR_LINE_2:C(30), BILL_ADDR_LINE_3:C(30), BILL_ADDR_LINE_4:C(30), BILL_ADDR_LINE_5:C(30), BILL_ADDR_LINE_6:C(30),
:                                                            SHIP_ADDR_LINE_1:C(30), SHIP_ADDR_LINE_2:C(30), SHIP_ADDR_LINE_3:C(30), SHIP_ADDR_LINE_4:C(30), SHIP_ADDR_LINE_5:C(30), SHIP_ADDR_LINE_6:C(30),
:                                                            ORDER_DATE:C(8), SLS_CODE:C(3), SLS_DESC:C(20), PO_NO:C(20), SHIP_VIA:C(10), SHIP_DATE:C(8), TERMS_CODE:C(2), TERMS_DESC:C(20),
:                                                            MESSAGE:C(40*), SALES_AMOUNT:N(7), DISCOUNT:N(7), SALES_TAX:N(7), FREIGHT:N(7), TOTAL:N(7)")

line_width = 30


rem --- Open Files    
    num_files = 9
    dim open_tables$[1:num_files], open_opts$[1:num_files], open_chans$[1:num_files], open_tpls$[1:num_files]

    open_tables$[1] = "ARM_CUSTMAST", open_opts$[1] = "OTA"
    open_tables$[2] = "ARM_CUSTSHIP", open_opts$[2] = "OTA"
    open_tables$[3] = "ARC_TERMCODE", open_opts$[3] = "OTA"
    open_tables$[4] = "ARC_SALECODE", open_opts$[4] = "OTA"
    open_tables$[5] = "ARS_REPORT", open_opts$[5] = "OTA"
    open_tables$[6] = "OPE_ORDHDR", open_opts$[6] = "OTA"
    open_tables$[7] = "OPE_ORDSHIP", open_opts$[7] = "OTA"
    open_tables$[8] = "OPE_ORDDET", open_opts$[8] = "OTA"
    open_tables$[9]= "OPC_MSG_DET",  open_opts$[9] = "OTA"


rem Get Barista System Program directory
sypdir$=""
sypdir$=stbl("+DIR_SYP",err=*next)

if sypdir$="" then
    syndir$="/usr2/dev_addon/barista/sys/prog/"
endif

call sypdir$+"bac_open_tables.bbj",
:       open_beg,
:		open_end,
:		open_tables$[all],
:		open_opts$[all],
:		open_chans$[all],
:		open_tpls$[all],
:		table_chans$[all],
:		open_batch,
:		open_status$
arm_custmat_chan = num(open_chans$[1])
arm_custship_chan = num(open_chans$[2])
arc_termcode_chan = num(open_chans$[3])
arc_salecode_chan = num(open_chans$[4])
ars_report_chan = num(open_chans$[5])
ope_ordhdr_chan = num(open_chans$[6])
ope_ordship_chan = num(open_chans$[7])
ope_orddet_chan = num(open_chans$[8])
opc_msg_det_chan = num(open_chans$[9])

dim arm_custmat$:open_tpls$[1]
dim arm_custship$:open_tpls$[2]
dim arc_termcode$:open_tpls$[3]
dim arc_salecode$:open_tpls$[4]
dim ars_report$:open_tpls$[5]
dim ope_ordhdr$:open_tpls$[6]
dim ope_ordship$:open_tpls$[7]
dim ope_orddet$:open_tpls$[8]
dim opc_msg_det$:open_tpls$[9]

data! = rs!.getEmptyRecordData()

rem Get Order entry header
find record (ope_ordhdr_chan, key=firm_id$+"  "+customer_id$+order_no$, dom=*continue) ope_ordhdr$

data!.setFieldValue("INVOICE_DATE", func.formatDate(ope_ordhdr.invoice_date$))
data!.setFieldValue("INVOICE_NO", ope_ordhdr.ar_inv_no$)

rem Get Company address from Report Form Parameters table
ars_report! = BBjAPI().makeTemplatedString(fattr(ars_report$))
find record (ars_report_chan, key=firm_id$+"AR02") ars_report!
comp_addr$ = func.formatAddress(ars_report!, line_width, 4)

data!.setFieldValue("COMP_ADDR_LINE_1", comp_addr$(1,line_width))
data!.setFieldValue("COMP_ADDR_LINE_2", comp_addr$(31,line_width))
data!.setFieldValue("COMP_ADDR_LINE_3", comp_addr$(61,line_width))
data!.setFieldValue("COMP_ADDR_LINE_4", comp_addr$(91,line_width))

dim bill_addr$(5*line_width)
bill_addr$ = pad("Customer not found", line_width*5)

arm_custmat! = BBjAPI().makeTemplatedString(fattr(arm_custmat$))

rem Get Bill To address from Customer Master table
if BBjAPI().TRUE then
    find record (arm_custmat_chan, key=firm_id$+customer_id$, dom=*endif) arm_custmat!
    bill_addr$ = func.formatAddress(arm_custmat!, line_width, 5)
    bill_addr$ = pad(str(customer_id$:"00-0000"),line_width) + bill_addr$
endif

data!.setFieldValue("BILL_ADDR_LINE_1", bill_addr$(1,line_width))
data!.setFieldValue("BILL_ADDR_LINE_2", bill_addr$(31,line_width))
data!.setFieldValue("BILL_ADDR_LINE_3", bill_addr$(61,line_width))
data!.setFieldValue("BILL_ADDR_LINE_4", bill_addr$(91,line_width))
data!.setFieldValue("BILL_ADDR_LINE_5", bill_addr$(121,line_width))
data!.setFieldValue("BILL_ADDR_LINE_6", bill_addr$(151,line_width))

ship_addr$ = bill_addr$

rem Get Ship To address from Manual Ship To table
if ope_ordhdr.shipto_type$="M" then
    ope_ordship! = BBjAPI().makeTemplatedString(fattr(ope_ordship$))
    find record (ope_ordship_chan, key=firm_id$+customer_id$+order_no$, dom=*endif) ope_ordship!
    ship_addr$ = func.formatAddress(ope_ordship!, line_width, 6)
endif

rem Get Ship To address from Customer Ship To table
if ope_ordhdr.shipto_type$="S" then
    arm_custship! = BBjAPI().makeTemplatedString(fattr(arm_custship$))
    find record (arm_custship_chan,key=firm_id$+customer_id$+ope_ordhdr.shipto_no$, dom=*endif) arm_custship!
    ship_addr$ = func.formatAddress(arm_custship!, line_width, 6)
endif

data!.setFieldValue("SHIP_ADDR_LINE_1", func.alphaMask(ship_addr$(1,line_width),m0$))
data!.setFieldValue("SHIP_ADDR_LINE_2", ship_addr$(31,line_width))
data!.setFieldValue("SHIP_ADDR_LINE_3", ship_addr$(61,line_width))
data!.setFieldValue("SHIP_ADDR_LINE_4", ship_addr$(91,line_width))
data!.setFieldValue("SHIP_ADDR_LINE_5", ship_addr$(121,line_width))
data!.setFieldValue("SHIP_ADDR_LINE_6", ship_addr$(151,line_width))

rem Get Salesperson code
find record (arc_salecode_chan,key=firm_id$+"F"+ope_ordhdr.slspsn_code$,dom=*next) arc_salecode$

rem Get Terms code
find record (arc_termcode_chan,key=firm_id$+"A"+ope_ordhdr.terms_code$,dom=*next) arc_termcode$

data!.setFieldValue("ORDER_DATE", func.formatDate(ope_ordhdr.order_date$))
data!.setFieldValue("SLS_CODE", ope_ordhdr.slspsn_code$)
data!.setFieldValue("SLS_DESC", arc_salecode.code_desc$)
data!.setFieldValue("PO_NO", ope_ordhdr.customer_po_no$)
data!.setFieldValue("SHIP_VIA", ope_ordhdr.ar_ship_via$)
data!.setFieldValue("SHIP_DATE", func.formatDate(ope_ordhdr.shipmnt_date$))
data!.setFieldValue("TERMS_CODE", ope_ordhdr.terms_code$)
data!.setFieldValue("TERMS_DESC", arc_termcode.code_desc$)

rem Get message from Standard Message Detail table
message$ = ""
read (opc_msg_det_chan, key=firm_id$+ope_ordhdr.message_code$, dom=*next)

while BBjAPI().TRUE
    read record (opc_msg_det_chan, end=*break)opc_msg_det$
    if opc_msg_det.firm_id$<>firm_id$ or opc_msg_det.message_code$<>ope_ordhdr.message_code$ then break
    message$ = message$ + pad(opc_msg_det.message_text$, 40) + $0D$
wend

data!.setFieldValue("MESSAGE", message$)

rem Calculates the sales amount
rem Sums the extended price from the Order/Invoice detail entry
sales_amount = 0
read (ope_orddet_chan, key=firm_id$+"  "+customer_id$+order_no$, knum="AO_CUST_ORD_LINE", dom=*next)

while BBjAPI().TRUE
    read record (ope_orddet_chan, end=*break) ope_orddet$
    if ope_orddet.firm_id$ <> firm_id$ or
:       ope_orddet.customer_id$ <> customer_id$ or
:       ope_orddet.order_no$ <> order_no$ then
        break
    endif

    sales_amount = sales_amount + ope_orddet.ext_price
wend

rem Calculates Total Due
total = sales_amount - ope_ordhdr.discount_amt + ope_ordhdr.tax_amount + ope_ordhdr.freight_amt

data!.setFieldValue("SALES_AMOUNT", str(sales_amount))
data!.setFieldValue("DISCOUNT", str(-ope_ordhdr.discount_amt))
data!.setFieldValue("SALES_TAX", str(ope_ordhdr.tax_amount))
data!.setFieldValue("FREIGHT", str(ope_ordhdr.freight_amt))
data!.setFieldValue("TOTAL", str(total))

rs!.insert(data!)

rem Tell the stored procedure to return the result set.
sp!.setRecordSet(rs!)

