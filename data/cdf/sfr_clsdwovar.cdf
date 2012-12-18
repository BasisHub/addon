[[SFR_CLSDWOVAR.PERIOD.AVAL]]

[[SFR_CLSDWOVAR.ARAR]]
rem --- Default year and period
	gls01_dev=fnget_dev("GLS_PARAMS")
	sfs01_dev=fnget_dev("SFS_PARAMS")
	
	dim gls01a$:fnget_tpl$("GLS_PARAMS")
	dim sfs01a$:fnget_tpl$("SFS_PARAMS")

	readrecord(sfs01_dev,key=firm_id$+"SF00",dom=std_missing_params)sfs01a$
	call stbl("+DIR_PGM")+"adc_perioddates.aon",gls01_dev,num(sfs01a.current_per$),
:		num(sfs01a.current_year$),begdate$,enddate$,status
	if status=0
		callpoint!.setColumnData("SFR_CLSDWOVAR.PERIOD",enddate$(5,2))
		callpoint!.setColumnData("SFR_CLSDWOVAR.YEAR",enddate$(1,4))
		callpoint!.setColumnData("<<DISPLAY>>.CURR_PERYR",sfs01a.current_per$+"/"+sfs01a.current_year$)
	endif

rem --- Set min/max values for period
	
	readrecord(gls01_dev,key=firm_id$+"GL00",dom=std_missing_params)gls01a$

	callpoint!.setTableColumnAttribute("SFR_CLSDWOVAR.PERIOD","MINV","01")
	callpoint!.setTableColumnAttribute("SFR_CLSDWOVAR.PERIOD","MAXV",str(num(gls01a.total_pers$):"00"))

	callpoint!.setStatus("REFRESH")
[[SFR_CLSDWOVAR.REPORT_SEQ.AVAL]]
rem ---- If By Bill and a whse hasn't been entered, default whse
			
whse_columndat$=callpoint!.getColumnData("SFR_CLSDWOVAR.WAREHOUSE_ID")

if callpoint!.getUserInput()="B"
	if cvs(whse_columndat$,2)="" then 
		whse$=callpoint!.getDevObject("dflt_whse")
		callpoint!.setColumnData("SFR_CLSDWOVAR.WAREHOUSE_ID",whse$,1)
	endif
endif
[[SFR_CLSDWOVAR.AREC]]
rem --- Set default Warehouse
			
	whse$=callpoint!.getDevObject("dflt_whse")
	callpoint!.setColumnData("SFR_CLSDWOVAR.WAREHOUSE_ID",whse$,1)
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
rem --- Open needed IV tables
rem --- Get default warehouse from IV params
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"
	gosub open_tables
			
	ivs01_dev=num(open_chans$[1])
	dim ivs01a$:open_tpls$[1]
			
	read record (ivs01_dev,key=firm_id$+"IV00")ivs01a$

	callpoint!.setDevObject("multi_wh",ivs01a.multi_whse$)	
	callpoint!.setDevObject("dflt_whse",ivs01a.warehouse_id$)
			
rem --- Open and read shop floor param to see if BOM and/or OP are installed
rem --- Then remove Bill and/or Cust from listbutton based on installed? status
rem           (form builds list w/o regards to the params)
rem --- And open gls_params for max periods

num_files=2
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="sfs_params",open_opts$[1]="OTA"
open_tables$[2]="gls_params",open_opts$[2]="OTA"
gosub open_tables
sfs01_dev=num(open_chans$[1]),sfs_params_tpl$=open_tpls$[1]
gls01_dev=num(open_chans$[2]),gls_params_tpl$=open_tpls$[2]
			
dim sfs01a$:sfs_params_tpl$
dim gls01a$:gls_params_tpl$

readrecord(gls01_dev,key=firm_id$+"GL00",dom=std_missing_params)gls01a$
callpoint!.setDevObject("max_gl_pers",gls01a.total_pers$)
		
readrecord(sfs01_dev,key=firm_id$+"SF00",dom=std_missing_params)sfs01a$
bm$=sfs01a.bm_interface$
op$=sfs01a.ar_interface$
			
rem --  Potentially remove list options based on module installed? status
	if op$<>"Y" or bm$<>"Y"
		listID=num(callpoint!.getTableColumnAttribute("SFR_CLSDWOVAR.REPORT_SEQ","CTLI"))
		list!=Form!.getControl(listID)
			
		tmpVector! = list!.getAllItems()
		tmpVectSize = num(tmpVector!.size())
		indx = tmpVectSize-1
					
		rem -- Work backwards thru vector so index stays aligned with shrinking list!
		while indx >=0
			if bm$<>"Y"
				if pos("B - B"= tmpVector!.getItem(indx))
					list!.removeItemAt(indx)
				endif
			endif
			if op$<>"Y"
				if pos("C - C"= tmpVector!.getItem(indx))
					list!.removeItemAt(indx)
	   			endif
			endif
			indx=indx-1
		wend
	endif
			
	if bm$="Y"
		num_files=1
		dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
		open_tables$[1]="BMM_BILLMAST",open_opts$[1]="OTA"
		gosub open_tables
	endif
[[SFR_CLSDWOVAR.<CUSTOM>]]
#include std_missing_params.src
