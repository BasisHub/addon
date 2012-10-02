[[SAM_DISTCODE.ARAR]]
rem --- Create totals

	gosub calc_totals
[[SAM_DISTCODE.AREC]]
rem --- Enable key fields
	ctl_name$="SAM_DISTCODE.YEAR"
	ctl_stat$=""
	gosub disable_fields
	ctl_name$="SAM_DISTCODE.AR_DIST_CODE"
	ctl_stat$=""
	gosub disable_fields
	ctl_name$="SAM_DISTCODE.PRODUCT_TYPE"
	ctl_stat$=""
	gosub disable_fields
	ctl_name$="SAM_DISTCODE.ITEM_ID"
	ctl_stat$=""
	gosub disable_fields
	callpoint!.setColumnData("<<DISPLAY>>.TCST","0")
	callpoint!.setColumnData("<<DISPLAY>>.TQTY","0")
	callpoint!.setColumnData("<<DISPLAY>>.TSLS","0")
	callpoint!.setStatus("REFRESH")
[[SAM_DISTCODE.BSHO]]
rem --- Check for parameter record
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SAS_PARAMS",open_opts$[1]="OTA"
	gosub open_tables
	sas01_dev=num(open_chans$[1]),sas01a$=open_tpls$[1]

	dim sas01a$:sas01a$
	read record (sas01_dev,key=firm_id$+"SA00")sas01a$
	if sas01a.by_dist_code$<>"Y"
		msg_id$="INVALID_SA"
		dim msg_tokens$[1]
		msg_tokens$[1]="Dist Code"
		gosub disp_message
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif

rem --- disable total elements
	ctl_name$="<<DISPLAY>>.TQTY"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="<<DISPLAY>>.TCST"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="<<DISPLAY>>.TSLS"
	ctl_stat$="I"
	gosub disable_fields
	callpoint!.setStatus("ABLEMAP-ACTIVATE-REFRESH")
[[SAM_DISTCODE.<CUSTOM>]]
disable_fields:
rem --- used to disable/enable controls depending on parameter settings
rem --- send in control to toggle (format "ALIAS.CONTROL_NAME"), and D or space to disable/enable

	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)

	return

calc_totals:
	
	tcst=0
	tqty=0
	tsls=0
	For x=1 to 13
		tcst=tcst+num(callpoint!.getColumnData("SAM_DISTCODE.TOTAL_COST_"+str(x:"00")))
		tqty=tqty+num(callpoint!.getColumnData("SAM_DISTCODE.QTY_SHIPPED_"+str(x:"00")))
		tsls=tsls+num(callpoint!.getColumnData("SAM_DISTCODE.TOTAL_SALES_"+str(x:"00")))
	next x
	callpoint!.setColumnData("<<DISPLAY>>.TCST",str(tcst))
	callpoint!.setColumnData("<<DISPLAY>>.TQTY",str(tqty))
	callpoint!.setColumnData("<<DISPLAY>>.TSLS",str(tsls))
	callpoint!.setStatus("REFRESH")

	return
[[SAM_DISTCODE.AOPT-SALU]]
rem -- call inquiry program to view Sales Analysis records

syspgmdir$=stbl("+DIR_SYP",err=*next)

key_pfx$=firm_id$
if cvs(callpoint!.getColumnData("SAM_DISTCODE.YEAR"),2) <>"" then
	key_pfx$=key_pfx$+callpoint!.getColumnData("SAM_DISTCODE.YEAR")
	if cvs(callpoint!.getColumnData("SAM_DISTCODE.AR_DIST_CODE"),2) <>"" then
		key_pfx$=key_pfx$+callpoint!.getColumnData("SAM_DISTCODE.AR_DIST_CODE")
		if cvs(callpoint!.getColumnData("SAM_DISTCODE.PRODUCT_TYPE"),2) <>"" then
			key_pfx$=key_pfx$+callpoint!.getColumnData("SAM_DISTCODE.PRODUCT_TYPE")
			if cvs(callpoint!.getColumnData("SAM_DISTCODE.ITEM_ID"),2) <>"" then
				key_pfx$=key_pfx$+callpoint!.getColumnData("SAM_DISTCODE.ITEM_ID")
			endif
		endif
	endif
endif

call syspgmdir$+"bac_key_template.bbj","SAM_DISTCODE","PRIMARY",key_temp$,table_chans$[all],rd_stat$
dim rd_key$:key_temp$
call syspgmdir$+"bam_inquiry.bbj",
:	gui_dev,
:	Form!,
:	"SAM_DISTCODE",
:	"LOOKUP",
:	table_chans$[all],
:	key_pfx$,
:	"PRIMARY",
:	rd_key$

rem --- get record and redisplay

sam_tpl$=fnget_tpl$("SAM_DISTCODE")
dim sam_tpl$:sam_tpl$
while 1
	readrecord(fnget_dev("SAM_DISTCODE"),key=rd_key$,dom=*break)sam_tpl$
	callpoint!.setColumnData("SAM_DISTCODE.YEAR",rd_key.year$)
	callpoint!.setColumnData("SAM_DISTCODE.AR_DIST_CODE",rd_key.ar_dist_code$)
	callpoint!.setColumnData("SAM_DISTCODE.PRODUCT_TYPE",rd_key.product_type$)
	callpoint!.setColumnData("SAM_DISTCODE.ITEM_ID",rd_key.item_id$)
	For x=1 to 13
		callpoint!.setColumnData("SAM_DISTCODE.QTY_SHIPPED_"+str(x:"00"),FIELD(sam_tpl$,"qty_shipped_"+str(x:"00")))
		callpoint!.setColumnData("SAM_DISTCODE.TOTAL_COST_"+str(x:"00"),FIELD(sam_tpl$,"total_cost_"+str(x:"00")))
		callpoint!.setColumnData("SAM_DISTCODE.TOTAL_SALES_"+str(x:"00"),FIELD(sam_tpl$,"total_sales_"+str(x:"00")))
	next x
	gosub calc_totals
	ctl_name$="SAM_DISTCODE.YEAR"
	ctl_stat$="D"
	gosub disable_fields
	ctl_name$="SAM_DISTCODE.AR_DIST_CODE"
	ctl_stat$="D"
	gosub disable_fields
	ctl_name$="SAM_DISTCODE.PRODUCT_TYPE"
	ctl_stat$="D"
	gosub disable_fields
	ctl_name$="SAM_DISTCODE.ITEM_ID"
	ctl_stat$="D"
	gosub disable_fields
	callpoint!.setRecordStatus("CLEAR")
	callpoint!.setStatus("ABLEMAP-ACTIVATE-REFRESH")
	break
wend
