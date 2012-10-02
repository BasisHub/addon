[[IVM_ITEMMAST.AOPT-CITM]]
cp_item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[1,1]
dflt_data$[1,0]="OLD_ITEM"
dflt_data$[1,1]=cp_item_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"IVM_COPYITEM",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]
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

	ivs10d_dev=fnget_dev("IVS_DEFAULT")
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
[[IVM_ITEMMAST.ARAR]]
rem --- Enable/disable Alt/Sup Item #
	ctl_name$="IVM_ITEMMAST.ALT_SUP_ITEM"
	if callpoint!.getColumnData("IVM_ITEMMAST.ALT_SUP_FLAG")="N"
		ctl_stat$="I"
	else
		ctl_stat$=" "
	endif
	wmap$=callpoint!.getAbleMap()
	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP")
[[IVM_ITEMMAST.ALT_SUP_FLAG.AVAL]]
rem --- Enable/disable Alt/Sup Item #
	ctl_name$="IVM_ITEMMAST.ALT_SUP_ITEM"
	if callpoint!.getColumnData("IVM_ITEMMAST.ALT_SUP_FLAG")="N"
		ctl_stat$="I"
	else
		ctl_stat$=" "
	endif
	wmap$=callpoint!.getAbleMap()
	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP")
[[IVM_ITEMMAST.ITEM_ID.AVAL]]
rem --- See if Auto Numbering in effect
	ivs01_dev=fnget_dev("IVS_PARAMS")
	dim ivs01a$:fnget_tpl$("IVS_PARAMS")
	ivs10_dev=fnget_dev("IVS_NUMBERS")
	dim ivs10n$:fnget_tpl$("IVS_NUMBERS")

	read record(ivs01_dev,key=firm_id$+"IV00") ivs01a$
	if len(callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID"))=0
		if ivs01a.auto_no_iv$<>"N" 
			item_len=num(callpoint!.getTableColumnAttribute("IVM_ITEMMAST.ITEM_ID","MAXL"))
			if item_len=0 item_len=20;rem Needed?
			chk_digit$=""
			if ivs01a.auto_no_iv$="C" item_len=item_len-1
			read record (ivs10_dev,key=firm_id$+"N",dom=*next) ivs10n$
			ivs10n.firm_id$=firm_id$
			ivs10n.record_id_n$="N"
			if ivs10n.nxt_item_id=0
				next_num=1
			else
				next_num=ivs10n.nxt_item_id
			endif
			dim max_num$(min(item_len,10),"9")
			if next_num>num(max_num$)
				msg_id$="NO_MORE_NUMBERS"
				gosub disp_message
				callpoint!.setStatus("ABORT")
			else
				ivs10n.nxt_item_id=next_num+1
				ivs10n$=field(ivs10n$)
				write record (ivs10_dev,key=firm_id$+"N") ivs10n$
				next_num$=str(next_num)
				if ivs01a.auto_no_iv$="C"
					precision 4
					chk_digit$=str(tim*10000),chk_digit$=chk_digit$(len(chk_digit$),1)
					precision num(ivs01a.precision$)
				endif
				callpoint!.setColumnData("IVM_ITEMMAST.ITEM_ID",next_num$+chk_digit$)
				callpoint!.setStatus("REFRESH")
			endif
		else
			callpoint!.setStatus("ABORT")
		endif
	endif
[[IVM_ITEMMAST.AWRI]]
rem --- Populate ivm-02 with Product Type

	ivm02_dev=fnget_dev("IVM_ITEMWHSE")
	ivm02a$=fnget_tpl$("IVM_ITEMWHSE")
	dim ivm02a$:ivm02a$
	item$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
	prod_type$=callpoint!.getColumnData("IVM_ITEMMAST.PRODUCT_TYPE")

	read (ivm02_dev,key=firm_id$+item$,knum=2,dom=*next)
	while 1
		readrecord(ivm02_dev,end=*break) ivm02a$
		if ivm02a.firm_id$<>firm_id$ break
		if ivm02a.item_id$<>item$ break
		ivm02a.product_type$=prod_type$
		ivm02a$=field(ivm02a$)
		writerecord (ivm02_dev)ivm02a$
	wend
[[IVM_ITEMMAST.BDEL]]
rem --- versions 6/7 have a program ivc.da used for deleting

	dim params$[7],params[2]
	params$[0]=firm_id$
	params$[2]=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
	params$[3]=user_tpl.op$
	params$[4]=user_tpl.po$
	params$[5]=user_tpl.wo$
	params$[6]=user_tpl.bm$
	params$[7]=user_tpl.ap$
	params[0]=user_tpl.num_pers
	params[1]=user_tpl.cur_per
	params[2]=user_tpl.cur_yr

	call stbl("+DIR_PGM")+"ivc_deleteitem.aon","I",params$[all],params[all],status
	if status<>0
		callpoint!.setStatus("ABORT")
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
rem -- get default values for new record from ivs-10D, IVS_DEFAULTS

ivs10_dev=fnget_dev("IVS_DEFAULTS")
dim ivs10d$:fnget_tpl$("IVS_DEFAULTS")

findrecord(ivs10_dev,key=firm_id$+"D",dom=*next)ivs10d$
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

ivm10_dev=fnget_dev("IVC_PRODCODE")
dim ivm10a$:fnget_tpl$("IVC_PRODCODE")

findrecord(ivm10_dev,key=firm_id$+"A"+ivs10d.product_type$,dom=*next)ivm10a$
callpoint!.setColumnData("IVM_ITEMMAST.SA_LEVEL",ivm10a.sa_level$)

callpoint!.setStatus("REFRESH")
[[IVM_ITEMMAST.WEIGHT.AVAL]]
if num(callpoint!.getUserInput())<0 or num(callpoint!.getUserInput())>9999.99 callpoint!.setStatus("ABORT")
[[IVM_ITEMMAST.AENA]]
rem --- Retrieve miscellaneous templates

files=1,begfile=1,endfile=files
dim ids$[files],templates$[files]
ids$[1]="ars-01A:ARS_PARAMS"

call stbl("+DIR_PGM")+"adc_template.aon",begfile,endfile,ids$[all],templates$[all],status
if status goto std_exit
dim ars01a$:templates$[1]

call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
gl$=info$[20]

if gl$="Y" 
	call stbl("+DIR_PGM")+"adc_application.aon","IV",info$[all]
	gl$=info$[9]; rem --- if gl installed, does it interface to inventory?
endif

di$="N"

if ar$="Y"
	ars01a_key$=firm_id$+"AR00"
	find record (ars01_dev,key=ars01a_key$,err=std_missing_params) ars01a$
	di$=ars01a.dist_by_item$
	if gl$="N" di$="N"
endif

rem --- if di$="N" and gl$="Y" leave GL tab/fields alone, otherwise disable them
if di$<>"N" or gl$<>"Y"
	fields_to_disable$="GL_INV_ACCT     GL_COGS_ACCT    GL_PUR_ACCT     GL_PPV_ACCT     GL_INV_ADJ      GL_COGS_ADJ     "
	wmap$=callpoint!.getAbleMap()
	ctl_stat$="I"
	for wfield=1 to len(fields_to_disable$)-1 step 16
		ctl_name$="IVM_ITEMMAST."+cvs(fields_to_disable$(wfield,16),3)					
		wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
		wpos=pos(wctl$=wmap$,8)
		wmap$(wpos+6,1)=ctl_stat$
	next wfield
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP")
endif
[[IVM_ITEMMAST.ASHO]]
callpoint!.setStatus("ABLEMAP-REFRESH")
[[IVM_ITEMMAST.<CUSTOM>]]
#include std_missing_params.src
[[IVM_ITEMMAST.BSHO]]
rem --- Open/Lock files
	num_files=6
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="IVS_DEFAULTS",open_opts$[2]="OTA"
	open_tables$[3]="GLS_PARAMS",open_opts$[3]="OTA"
	open_tables$[4]="ARS_PARAMS",open_opts$[4]="OTA"
	open_tables$[5]="IVM_ITEMWHSE",open_opts$[5]="OTA"
	open_tables$[6]="IVS_NUMBERS",open_opts$[6]="OTA"
	gosub open_tables
	if status$<>""  goto std_exit

	ivs01_dev=num(open_chans$[1]),ivs01d_dev=num(open_chans$[2]),gls01_dev=num(open_chans$[3])
	ivm02_dev=num(open_chans$[5]),ivs10_dev=num(open_chans$[6])

rem --- Dimension miscellaneous string templates

	dim ivs01a$:open_tpls$[1],ivs01d$:open_tpls$[2],gls01a$:open_tpls$[3],ars01a$:open_tpls$[4]
	dim ivm02a$:open_tpls$[5],ivs10n$:open_tpls$[6]

rem --- init/parameters

disable_str$=""
enable_str$=""
dim info$[20]

ivs01a_key$=firm_id$+"IV00"
find record (ivs01_dev,key=ivs01a_key$,err=std_missing_params) ivs01a$

gls01a_key$=firm_id$+"GL00"
find record (gls01_dev,key=gls01a_key$,err=std_missing_params) gls01a$

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
call dir_pgm1$+"adc_application.aon","SA",info$[all]
sa$=info$[20]

rem --- Setup user_tpl$
	dim user_tpl$:"ar:c(1),ap:c(1),bm:c(1),gl:c(1),op:c(1),po:c(1),wo:c(1),sa:c(1),"+
:	"num_pers:n(2),cur_per:n(2),cur_yr:n(4)"
	user_tpl.ar$=ar$
	user_tpl.ap$=ap$
	user_tpl.bm$=bm$
	user_tpl.gl$=gl$
	user_tpl.op$=op$
	user_tpl.po$=po$
	user_tpl.wo$=wo$
	user_tpl.sa$=sa$
	user_tpl.num_pers=num(gls01a.total_pers$)
	user_tpl.cur_per=num(gls01a.current_per$)
	user_tpl.cur_yr=num(gls01a.current_year$)

if ap$<>"Y" disable_str$=disable_str$+"IVM_ITEMVEND;"; rem --- this is a detail window, give alias name
if pos(ivs01a.lifofifo$="LF")=0 disable_str$=disable_str$+"LIFO;"; rem --- these are AOPTions, give AOPT code only
if pos(ivs01a.lotser_flag$="LS")=0 disable_str$=disable_str$+"LTRN;"
if op$<>"Y" disable_str$=disable_str$+"SORD;"
if po$<>"Y" disable_str$=disable_str$+"PORD;"
				
if disable_str$<>"" call stbl("+DIR_SYP")+"bam_enable_pop.bbj",Form!,enable_str$,disable_str$

rem --- additional file opens, depending on which apps are installed, param values, etc.

more_files$="",files=0
if pos(ivs01a.lifofifo$="LF")<>0 then more_files$=more_files$+"IVM_ITEMTIER;",files=files+1
if pos(ivs01a.lotser_flag$="LS")<>0 then more_files$=more_files$+"IVM_LSMASTER;IVM_LSACT;IVT_LSTRANS;",files=files+3
if ivs01a.master_flag_01$="Y" or ivs01a.master_flag_02$="Y" or ivs01a.master_flag_03$="Y"
	more_files$=more_files$+"IVM_DESCRIP1;IVM_DESCRIP2;IVM_DESCRIP3;"
	files=files+3
endif 
if ar$="Y" then more_files$=more_files$+"ARM_CUSTMAST;ARC_DISTCODE;",files=files+2
if bm$="Y" then more_files$=more_files$+"BMM_BILLMAST;BMM_BILLMAT;",files=files+2
if op$="Y" then more_files$=more_files$+"OPE_ORDHDR;OPE_ORDDET;OPE_ORDITEM;",files=files+3
if po$="Y" then more_files$=more_files$+"POE_REQHDR;POE_POHDR;POE_REQDET;POE_PODET;"
:	+"POC_LINECODES;POT_RECHDR;POT_RECDET;",files=files+7
if wo$="Y" then more_files$=more_files$+"SFE_WOMASTER;SFE_WOMATL;",files=files+2

if files
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
:                                 	chans$[all],templates$[all],table_chans$[all],batch,status$

	if status$<>"" goto std_exit

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
