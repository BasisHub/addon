[[SFR_CLSDWOVAR.BILL_NO.AVAL]]
rem --- Validate against BOM_BILLMAST

	bmm_billmast=fnget_dev("BMM_BILLMAST")
	found=0
	bill$=callpoint!.getUserInput()
	while 1
		find (bmm_billmast,key=firm_id$+bill$,dom=*break)
		found=1
		break
	wend

	if found=0 and cvs(bill$,3)<>""
		msg_id$="INPUT_ERR_DATA"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[SFR_CLSDWOVAR.BFMC]]
rem --- Set Custom Query for BOM Item Number

	callpoint!.setTableColumnAttribute("SFR_CLSDWOVAR.BILL_NO_1", "IDEF", "BOM_LOOKUP")
	callpoint!.setTableColumnAttribute("SFR_CLSDWOVAR.BILL_NO_2", "IDEF", "BOM_LOOKUP")
[[SFR_CLSDWOVAR.BSHO]]
rem --- will open and read shop floor param to see if BOM and/or OP are installed
rem --- then will build list for the report sequence listbutton accordingly

num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="SFS_PARAMS",open_opts$[1]="OTA"
gosub open_tables
sfs01_dev=num(open_chans$[1]),sfs_params_tpl$=open_tpls$[1]

dim sfs01a$:sfs_params_tpl$

readrecord(sfs01_dev,key=firm_id$+"SF00",dom=std_missing_params)sfs01a$
bm$=sfs01a.bm_interface$
op$=sfs01a.ar_interface$

seq_list$=callpoint!.getTableColumnAttribute("SFR_CLSDWOVAR.REPORT_SEQ","LDAT")
desc_len=pos("~"=seq_list$)
code_len=pos(";"=seq_list$)
bill_no$=""
cust_no$=""

listID=num(callpoint!.getTableColumnAttribute("SFR_CLSDWOVAR.REPORT_SEQ","CTLI"))
list!=Form!.getControl(listID)

if bm$="Y"
	dim bill_no$(code_len)
	bill_no$(1)=Translate!.getTranslation("AON_BILL_NUMBER")
	bill_no$(desc_len,1)="~"
	bill_no$(desc_len+1,1)="B"
	bill_no$(code_len,1)=";"
	list!.addItem(bill_no$(1,desc_len-1))
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="BMM_BILLMAST",open_opts$[1]="OTA"
	gosub open_tables
endif

if op$="Y"
	dim cust_no$(code_len)
	cust_no$(1)=Translate!.getTranslation("AON_CUSTOMER_ID")
	cust_no$(desc_len,1)="~"
	cust_no$(desc_len+1,1)="C"
	cust_no$(code_len,1)=";"
	list!.addItem(cust_no$(1,desc_len-1))
endif

seq_list$=seq_list$+bill_no$+cust_no$
callpoint!.setTableColumnAttribute("SFR_CLSDWOVAR.REPORT_SEQ","LDAT",seq_list$)
[[SFR_CLSDWOVAR.<CUSTOM>]]
#include std_missing_params.src
