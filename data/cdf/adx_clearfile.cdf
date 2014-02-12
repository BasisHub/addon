[[ADX_CLEARFILE.ASVA]]
rem --- Confirm ready to clear data
	table_alias$=cvs(callpoint!.getColumnData("ADX_CLEARFILE.DD_TABLE_ALIAS"),2)
	dim msg_tokens$[2]
	msg_tokens$[0]=table_alias$
	if callpoint!.getColumnData("ADX_CLEARFILE.ACTIVE") = "Y"
		msg_tokens$[1]=Translate!.getTranslation("AON_FIRM")+" "+firm_id$
	else
		msg_tokens$[1]=Translate!.getTranslation("AON_ALL_FIRMS")
	endif
	msg_id$="AD_CLEAR_FIRM_CONF"
	gosub disp_message
	if msg_opt$<>"Y"then
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Clear selected data
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]=table_alias$,open_opts$[1]="OTA"

	gosub open_tables

	table_dev=num(open_chans$[1])

	if callpoint!.getColumnData("ADX_CLEARFILE.ACTIVE") = "Y"
		call "adc_clearpartial.aon","",table_dev,firm_id$,status
		if status = 0
			prompt$=table_alias$+" "+Translate!.getTranslation("AON_CLEARED_FOR")+" "+Translate!.getTranslation("AON_FIRM")+" "+firm_id$+"."
			x=msgbox(prompt$,64,Form!.getTitle())
		endif
	else
		call "adc_clearfile.aon",table_dev
		if table_dev<>0
			prompt$=table_alias$+" "+Translate!.getTranslation("AON_CLEARED_FOR")+" "+Translate!.getTranslation("AON_ALL_FIRMS")+"."
			x=msgbox(prompt$,64,Form!.getTitle())
		endif
	endif
[[ADX_CLEARFILE.ARAR]]
rem --- Set Current Firm to true
	callpoint!.setColumnData("ADX_CLEARFILE.ACTIVE","Y")
	callpoint!.setStatus("REFRESH")
[[ADX_CLEARFILE.DD_TABLE_ALIAS.AVAL]]
rem --- Enable button
	callpoint!.setOptionEnabled("CLRF",1)
