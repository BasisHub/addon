[[SFR_CLSDWOVAR.BILL_NO.BINQ]]
	whse$=callpoint!.getColumnData("SFR_CLSDWOVAR.WAREHOUSE_ID")
        callpoint!.setDevObject("whse",whse$)
[[SFR_CLSDWOVAR.PERIOD.AVAL]]
rem --- Show date range for entered period

	call stbl("+DIR_PGM")+"adc_perioddates.aon",num(callpoint!.getUserInput()),
:		num(callpoint!.getDevObject("current_year")),begdate$,enddate$,table_chans$[all],status
	if status=0
		begdate$=date(jul(begdate$,"%Yd%Mz%Dz"):stbl("+DATE_MASK"))
		enddate$=date(jul(enddate$,"%Yd%Mz%Dz"):stbl("+DATE_MASK"))
		callpoint!.setColumnData("<<DISPLAY>>.DATE_RANGE",begdate$+"  -  "+enddate$,1)
	else
		callpoint!.setColumnData("<<DISPLAY>>.DATE_RANGE","",1)
	endif
[[SFR_CLSDWOVAR.ARAR]]
rem --- Default year and period
	sfs01_dev=fnget_dev("SFS_PARAMS")
	dim sfs01a$:fnget_tpl$("SFS_PARAMS")

	readrecord(sfs01_dev,key=firm_id$+"SF00",dom=std_missing_params)sfs01a$
	call stbl("+DIR_PGM")+"adc_perioddates.aon",num(sfs01a.current_per$),
:		num(sfs01a.current_year$),begdate$,enddate$,table_chans$[all],status
	callpoint!.setColumnData("SFR_CLSDWOVAR.PERIOD",sfs01a.current_per$)
	callpoint!.setColumnData("SFR_CLSDWOVAR.YEAR",sfs01a.current_year$)
	callpoint!.setDevObject("current_year",sfs01a.current_year$)
	if status=0
		begdate$=date(jul(begdate$,"%Yd%Mz%Dz"):stbl("+DATE_MASK"))
		enddate$=date(jul(enddate$,"%Yd%Mz%Dz"):stbl("+DATE_MASK"))
		callpoint!.setColumnData("<<DISPLAY>>.DATE_RANGE",begdate$+"  -  "+enddate$)
	endif

rem --- Set min/max values for period
	
	max_gl_pers$=callpoint!.getDevObject("max_gl_pers")

	callpoint!.setTableColumnAttribute("SFR_CLSDWOVAR.PERIOD","MINV","01")
	callpoint!.setTableColumnAttribute("SFR_CLSDWOVAR.PERIOD","MAXV",str(num(max_gl_pers$):"00"))

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

num_files=2
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="SFS_PARAMS",open_opts$[1]="OTA"
open_tables$[2]="GLS_CALENDAR",open_opts$[2]="OTA"
gosub open_tables
sfs01_dev=num(open_chans$[1]),sfs_params_tpl$=open_tpls$[1]
gls_calendar_dev=num(open_chans$[2]),gls_calendar_tpl$=open_tpls$[2]
			
dim sfs01a$:sfs_params_tpl$
dim gls_calendar$:gls_calendar_tpl$
		
readrecord(sfs01_dev,key=firm_id$+"SF00",dom=std_missing_params)sfs01a$
bm$=sfs01a.bm_interface$
op$=sfs01a.ar_interface$

readrecord(gls_calendar_dev,key=firm_id$+sfs01a.current_year$,dom=std_missing_params)gls_calendar$
callpoint!.setDevObject("max_gl_pers",gls_calendar.total_pers$)
			
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
