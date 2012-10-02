[[SFR_WORDERDET.BSHO]]
rem --- will open and read shop floor param to see if BOM and/or OP are installed
rem --- then will build list for the report sequence listbutton accordingly

num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="sfs_params",open_opts$[1]="OTA"
gosub open_tables
sfs01_dev=num(open_chans$[1]),sfs_params_tpl$=open_tpls$[1]

dim sfs01a$:sfs_params_tpl$

readrecord(sfs01_dev,key=firm_id$+"SF00",dom=std_missing_params)sfs01a$
bm$=sfs01a.bm_interface$
op$=sfs01a.ar_interface$

seq_list$=callpoint!.getTableColumnAttribute("SFR_WORDERDET.REPORT_SEQ","LDAT")
desc_len=pos("~"=seq_list$)
code_len=pos(";"=seq_list$)
bill_no$=""
cust_no$=""

listID=num(callpoint!.getTableColumnAttribute("SFR_WORDERDET.REPORT_SEQ","CTLI"))
list!=Form!.getControl(listID)

if bm$="Y"
	dim bill_no$(code_len)
	bill_no$(1)=Translate!.getTranslation("AON_BILL_NUMBER")
	bill_no$(desc_len,1)="~"
	bill_no$(desc_len+1,1)="B"
	bill_no$(code_len,1)=";"
	list!.addItem(bill_no$(1,desc_len-1))
endif

if op$="Y"
	dim cust_no$(code_len)
	cust_no$(1)=Translate!.getTranslation("AON_CUSTOMER_NUMBER")
	cust_no$(desc_len,1)="~"
	cust_no$(desc_len+1,1)="C"
	cust_no$(code_len,1)=";"
	list!.addItem(cust_no$(1,desc_len-1))
endif

seq_list$=seq_list$+bill_no$+cust_no$
callpoint!.setTableColumnAttribute("SFR_WORDERDET.REPORT_SEQ","LDAT",seq_list$)
[[SFR_WORDERDET.<CUSTOM>]]
#include std_missing_params.src
