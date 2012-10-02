[[SAX_HISTREBUILD.AREC]]
rem --- Open parameter file

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SAS_PARAMS",open_opts$[1]="OTA"
	gosub open_tables
	sas01_dev=num(open_chans$[1])
	dim sas01a$:open_tpls$[1]

	readrecord (sas01_dev,key=firm_id$+"SA00",dom=std_error)sas01a$

rem --- Set default values for screen and disable those not set in parameters

	callpoint!.setColumnData("SAX_HISTREBUILD.BY_CUSTOMER",sas01a.by_customer$)
	callpoint!.setColumnData("SAX_HISTREBUILD.BY_CUSTOMER_TYPE",sas01a.by_customer_type$)
	callpoint!.setColumnData("SAX_HISTREBUILD.BY_DIST_CODE",sas01a.by_dist_code$)
	callpoint!.setColumnData("SAX_HISTREBUILD.BY_NONSTOCK",sas01a.by_nonstock$)
	callpoint!.setColumnData("SAX_HISTREBUILD.BY_PRODUCT",sas01a.by_product$)
	callpoint!.setColumnData("SAX_HISTREBUILD.BY_SALESPSN",sas01a.by_salespsn$)
	callpoint!.setColumnData("SAX_HISTREBUILD.BY_SHIPTO",sas01a.by_shipto$)
	callpoint!.setColumnData("SAX_HISTREBUILD.BY_SIC_CODE",sas01a.by_sic_code$)
	callpoint!.setColumnData("SAX_HISTREBUILD.BY_TERRITORY",sas01a.by_territory$)
	callpoint!.setColumnData("SAX_HISTREBUILD.BY_VENDOR",sas01a.by_vendor$)
	callpoint!.setColumnData("SAX_HISTREBUILD.BY_WHSE",sas01a.by_whse$)
	callpoint!.setStatus("REFRESH")

	if sas01a.by_customer$<>"Y"
		ctl_name$="SAX_HISTREBUILD.BY_CUSTOMER"
		ctl_stat$="D"
		gosub disable_fields
	endif
	if sas01a.by_customer_type$<>"Y"
		ctl_name$="SAX_HISTREBUILD.BY_CUSTOMER_TYPE"
		ctl_stat$="D"
		gosub disable_fields
	endif
	if sas01a.by_dist_code$<>"Y"
		ctl_name$="SAX_HISTREBUILD.BY_DIST_CODE"
		ctl_stat$="D"
		gosub disable_fields
	endif
	if sas01a.by_nonstock$<>"Y"
		ctl_name$="SAX_HISTREBUILD.BY_NONSTOCK"
		ctl_stat$="D"
		gosub disable_fields
	endif
	if sas01a.by_product$<>"Y"
		ctl_name$="SAX_HISTREBUILD.BY_PRODUCT"
		ctl_stat$="D"
		gosub disable_fields
	endif
	if sas01a.by_salespsn$<>"Y"
		ctl_name$="SAX_HISTREBUILD.BY_SALESPSN"
		ctl_stat$="D"
		gosub disable_fields
	endif
	if sas01a.by_shipto$<>"Y"
		ctl_name$="SAX_HISTREBUILD.BY_SHIPTO"
		ctl_stat$="D"
		gosub disable_fields
	endif
	if sas01a.by_sic_code$<>"Y"
		ctl_name$="SAX_HISTREBUILD.BY_SIC_CODE"
		ctl_stat$="D"
		gosub disable_fields
	endif
	if sas01a.by_territory$<>"Y"
		ctl_name$="SAX_HISTREBUILD.BY_TERRITORY"
		ctl_stat$="D"
		gosub disable_fields
	endif
	if sas01a.by_vendor$<>"Y"
		ctl_name$="SAX_HISTREBUILD.BY_VENDOR"
		ctl_stat$="D"
		gosub disable_fields
	endif
	if sas01a.by_whse$<>"Y"
		ctl_name$="SAX_HISTREBUILD.BY_WHSE"
		ctl_stat$="D"
		gosub disable_fields
	endif
[[SAX_HISTREBUILD.<CUSTOM>]]
disable_fields:
rem --- used to disable/enable controls depending on parameter settings
rem --- send in control to toggle (format "ALIAS.CONTROL_NAME"), and D or space to disable/enable

	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP-REFRESH")
	
	return
