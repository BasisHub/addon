[[SFR_WOHEADER.BILL_NO.AVAL]]
rem --- Set descriptions

	ivm_itemmast=fnget_dev("IVM_ITEMMAST")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
	item$=callpoint!.getUserInput()
	read record (ivm_itemmast,key=firm_id$+item$,dom=*next) ivm_itemmast$

	if num(callpoint!.getControlID()) = num(callpoint!.getControl("BILL_NO_1").getID()) then
		if cvs(item$,2)<>""
			callpoint!.setColumnData("<<DISPLAY>>.BEG_DESC",ivm_itemmast.item_desc$,1)
		else
			callpoint!.setColumnData("<<DISPLAY>>.BEG_DESC","First",1)
		endif
	endif
	if num(callpoint!.getControlID()) = num(callpoint!.getControl("BILL_NO_2").getID()) then
		if cvs(item$,2)<>""
			callpoint!.setColumnData("<<DISPLAY>>.END_DESC",ivm_itemmast.item_desc$,1)
		else
			callpoint!.setColumnData("<<DISPLAY>>.END_DESC","Last",1)
		endif
	endif
[[SFR_WOHEADER.AREC]]
rem --- Set default Warehouse

	whse$=callpoint!.getDevObject("dflt_whse")
	callpoint!.setColumnData("SFR_WOHEADER.WAREHOUSE_ID",whse$,1)

rem --- Set initial values for descriptions

	callpoint!.setColumnData("<<DISPLAY>>.BEG_DESC","First",1)
	callpoint!.setColumnData("<<DISPLAY>>.END_DESC","Last",1)
[[SFR_WOHEADER.REPORT_SEQ.AVAL]]
rem ---- If By Bill and a whse hasn't been entered, default whse

whse_columndat$=callpoint!.getColumnData("SFR_WOHEADER.WAREHOUSE_ID")

if callpoint!.getUserInput()="B"
	if cvs(whse_columndat$,2)="" then 
		whse$=callpoint!.getDevObject("dflt_whse")
		callpoint!.setColumnData("SFR_WOHEADER.WAREHOUSE_ID",whse$,1)
	endif
endif
[[SFR_WOHEADER.<CUSTOM>]]
#include std_missing_params.src
[[SFR_WOHEADER.BSHO]]
rem --- Open needed IV tables
rem --- Get default warehouse from IV params
	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="IVM_ITEMMAST",open_opts$[2]="OTA"
	gosub open_tables

	ivs01_dev=num(open_chans$[1])
	dim ivs01a$:open_tpls$[1]

	read record (ivs01_dev,key=firm_id$+"IV00")ivs01a$

	callpoint!.setDevObject("multi_wh",ivs01a.multi_whse$)	
	callpoint!.setDevObject("dflt_whse",ivs01a.warehouse_id$)

rem --- Open and read shop floor param to see if BOM and/or OP are installed
rem --- Then remove Bill and/or Cust from listbutton based on installed? status
rem           (form builds list w/o regards to the params)

num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="sfs_params",open_opts$[1]="OTA"
gosub open_tables
sfs01_dev=num(open_chans$[1]),sfs_params_tpl$=open_tpls$[1]

dim sfs01a$:sfs_params_tpl$

readrecord(sfs01_dev,key=firm_id$+"SF00",dom=std_missing_params)sfs01a$
bm$=sfs01a.bm_interface$
op$=sfs01a.ar_interface$

rem --  Potentially remove list options based on module installed? status

	if op$<>"Y" or bm$<>"Y"
		listID=num(callpoint!.getTableColumnAttribute("SFR_WOHEADER.REPORT_SEQ","CTLI"))
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
