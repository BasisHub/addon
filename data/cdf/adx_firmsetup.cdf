[[ADX_FIRMSETUP.BSHO]]
rem --- Open adm_procmaster (adm-09)

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ADM_PROCMASTER",open_opts$[1]="OTA"
	gosub open_tables
[[ADX_FIRMSETUP.<CUSTOM>]]
validate_firm_id: rem --- Validate New Firm ID

	rem --- Can't use afirms 99 and ZZ
	if pos(firm_id$="99ZZ",2) then
		msg_id$="AD_FIRM_ID_USED"
		dim msg_tokens$[1]
		msg_tokens$[1]=firm_id$
		gosub disp_message
		callpoint!.setFocus("ADX_FIRMSETUP.NEW_FIRM_ID")
		callpoint!.setStatus("ABORT")
		return
	endif

	rem --- Can't use an existing firm unless coming from the Install Wizard
	rem --- Check for firm in adm_procmaster (adm-09)
	if !num(callpoint!.getColumnData("ADX_FIRMSETUP.NEW_INSTALL")) then
		adm09_dev=fnget_dev("ADM_PROCMASTER")
		dim adm09a$:fnget_tpl$("ADM_PROCMASTER")
		read(adm09_dev,key=firm_id$,dom=*next)
		readrecord(adm09_dev,err=*next)adm09a$
		if adm09a$.firm_id$=firm_id$ or pos(firm_id$="99ZZ",2) then
			msg_id$="AD_FIRM_ID_USED"
			dim msg_tokens$[1]
			msg_tokens$[1]=firm_id$
			gosub disp_message
			callpoint!.setFocus("ADX_FIRMSETUP.NEW_FIRM_ID")
			callpoint!.setStatus("ABORT")
		endif
	endif

	return
[[ADX_FIRMSETUP.ASVA]]
rem --- Validate New Firm ID

	firm_id$=callpoint!.getColumnData("ADX_FIRMSETUP.NEW_FIRM_ID")
	gosub validate_firm_id
[[ADX_FIRMSETUP.AREC]]
rem --- Initialize new record
	rem --- Disable install_type when coming from the Install Wizard
	if num(callpoint!.getColumnData("ADX_FIRMSETUP.NEW_INSTALL")) then
		callpoint!.setColumnEnabled("ADX_FIRMSETUP.INSTALL_TYPE",0)
	endif

	rem --- Install Wizard passes in data_location
	if cvs(callpoint!.getColumnData("ADX_FIRMSETUP.DATA_LOCATION"),2)="" then
		callpoint!.setColumnData("ADX_FIRMSETUP.DATA_LOCATION",stbl("+DIR_DAT"))
	endif
[[ADX_FIRMSETUP.NEW_FIRM_ID.AVAL]]
rem --- Validate New Firm ID

	firm_id$=callpoint!.getUserInput()
	gosub validate_firm_id
