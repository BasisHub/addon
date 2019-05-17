[[ARS_GATEWAYHDR.ASHO]]
rem --- if no records yet, initialize by copying from ZZ records

	ars_gatewayhdr=fnget_dev("ARS_GATEWAYHDR")
	ars_gatewaydet=fnget_dev("ARS_GATEWAYDET")
	dim ars_gatewayhdr$:fnget_tpl$("ARS_GATEWAYHDR")
	dim ars_gatewaydet$:fnget_tpl$("ARS_GATEWAYDET")

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARS_GATEWAYHDR",open_opts$[1]="OTA[1]"
	open_tables$[2]="ARS_GATEWAYDET",open_opts$[2]="OTA[1]"
	gosub open_tables
	ars_gatewayhdr1=num(open_chans$[1])
	ars_gatewaydet1=num(open_chans$[2])

	init_from_zz=1
	read(ars_gatewayhdr,key=firm_id$,dom=*next)

	while 1
		readrecord(ars_gatewayhdr,end=*break)ars_gatewayhdr$
		if ars_gatewayhdr.firm_id$=firm_id$ then init_from_zz=0
		break
	wend

	if init_from_zz
		read(ars_gatewayhdr,key="ZZ",dom=*next)
		while 1
			readrecord(ars_gatewayhdr,end=*break)ars_gatewayhdr$
			if ars_gatewayhdr.firm_id$<>"ZZ" then break
			ars_gatewayhdr.firm_id$=firm_id$
			writerecord(ars_gatewayhdr1)ars_gatewayhdr$			
		wend

		read(ars_gatewaydet,key="ZZ",dom=*next)
		while 1
			readrecord(ars_gatewaydet,end=*break)ars_gatewaydet$
			if ars_gatewaydet.firm_id$<>"ZZ" then break
			ars_gatewaydet.firm_id$=firm_id$
			writerecord(ars_gatewaydet1)ars_gatewaydet$			
		wend
	endif
	
