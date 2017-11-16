[[POT_INVHDR.AREC]]
rem --- Disable Invoice Detail button
	callpoint!.setOptionEnabled("INVD",0)
[[POT_INVHDR.AOPT-INVD]]
rem --- Launch PO Invoice History Detail Inquiry
	ap_type$=callpoint!.getColumnData("POT_INVHDR.AP_TYPE")
	vendor_id$=callpoint!.getColumnData("POT_INVHDR.VENDOR_ID")
	ap_inv_no$=callpoint!.getColumnData("POT_INVHDR.AP_INV_NO")
	sequence_ref$=callpoint!.getColumnData("POT_INVHDR.SEQUENCE_REF")

	pfx$=firm_id$+ap_type$+vendor_id$+ap_inv_no$+sequence_ref$

	dim dflt_data$[4,1]
	dflt_data$[1,0]="AP_TYPE"
	dflt_data$[1,1]=ap_type$
	dflt_data$[2,0]="VENDOR_ID"
	dflt_data$[2,1]=vendor_id$
	dflt_data$[3,0]="AP_INV_NO"
	dflt_data$[3,1]=ap_inv_no$
	dflt_data$[4,0]="SEQUENCE_REF"
	dflt_data$[4,1]=sequence_ref$

	call stbl("+DIR_SYP")+"bam_run_prog.bbj","POT_INVDET",stbl("+USER_ID"),"INQ",pfx$,table_chans$[all],"",dflt_data$[all]
[[POT_INVHDR.ADIS]]
vendor_info: rem --- get and display Vendor Information
	apm01_dev=fnget_dev("APM_VENDMAST")
	dim apm01a$:fnget_tpl$("APM_VENDMAST")
	vendor_id$=callpoint!.getColumnData("POT_INVHDR.VENDOR_ID")
	read record(apm01_dev,key=firm_id$+vendor_id$,dom=*next)apm01a$
	callpoint!.setColumnData("<<DISPLAY>>.V_ADDR1",apm01a.addr_line_1$,1)
	callpoint!.setColumnData("<<DISPLAY>>.V_ADDR2",apm01a.addr_line_2$,1)
	callpoint!.setColumnData("<<DISPLAY>>.V_CITY",cvs(apm01a.city$,3)+", "+apm01a.state_code$+"  "+apm01a.zip_code$,1)
	callpoint!.setColumnData("<<DISPLAY>>.V_CONTACT",apm01a.contact_name$,1)
	callpoint!.setColumnData("<<DISPLAY>>.V_PHONE",apm01a.phone_no$,1)
	if pos("0"<>cvs(apm01a.fax_no$,2))>0 then
		callpoint!.setColumnData("<<DISPLAY>>.V_FAX",apm01a.fax_no$,1)
	endif

rem --- Enable Invoice Detail button
	callpoint!.setOptionEnabled("INVD",1)
[[POT_INVHDR.BSHO]]
rem --- Open/Lock files
	files=1,begfile=1,endfile=1
	dim files$[files],options$[files],chans$[files],templates$[files]
	files$[1]="APM_VENDMAST"; options$[1]="OTA"
	call stbl("+DIR_SYP")+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                   chans$[all],templates$[all],table_chans$[all],batch,status$
	if status$ <> ""  then goto std_exit
