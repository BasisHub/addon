[[ADX_CLEARFILE.BSHO]]
rem --- setup vector
	dim user_tpl$:"file_name:c(16)"
[[ADX_CLEARFILE.ARAR]]
rem --- Set Current Firm to true
	callpoint!.setColumnData("ADX_CLEARFILE.ACTIVE","Y")
	callpoint!.setStatus("REFRESH")
[[ADX_CLEARFILE.DD_TABLE_ALIAS.AVAL]]
rem --- Enable button
	user_tpl.file_name$=callpoint!.getUserInput()
	callpoint!.setOptionEnabled("CLRF",1)
[[ADX_CLEARFILE.AOPT-CLRF]]
rem --- Open/Lock files

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]=user_tpl.file_name$,open_opts$[1]="OTA"

	gosub open_tables

	table_dev=num(open_chans$[1])

	if callpoint!.getColumnData("ADX_CLEARFILE.ACTIVE") = "Y"
		call "adc_clearpartial.aon","",table_dev,firm_id$,status
		if status = 0
			prompt$=cvs(user_tpl.file_name$,2)+" cleared for firm "+firm_id$+"."
			x=msgbox(prompt$,64,task_description$)
		endif
	else
		call "adc_clearfile.aon",table_dev
		if table_dev<>0
			prompt$=cvs(user_tpl.file_name$,2)+" cleared for all firms."
			x=msgbox(prompt$,64,task_description$)
		endif
	endif

	callpoint!.setOptionEnabled("CLRF",0)
	callpoint!.setColumnData("ADX_CLEARFILE.ACTIVE","Y")
	callpoint!.setColumnData("ADX_CLEARFILE.DD_TABLE_ALIAS","")
	callpoint!.setStatus("REFRESH")
