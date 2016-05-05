[[GLT_BANKOTHER.BSHO]]
rem --- Open/Lock files
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ART_DEPOSIT",open_opts$[1]="OTA@"

	gosub open_tables
	if status$ <> ""  then goto std_exit
[[GLT_BANKOTHER.TRANS_NO.AVAL]]
rem --- Has the trans_no changed?
	trans_no$=callpoint!.getUserInput()
	if callpoint!.getColumnData("GLT_BANKOTHER.TRANS_NO")<>trans_no$ then
		rem --- Is this a Deposit trans_type"
		if callpoint!.getColumnData("GLT_BANKOTHER.TRANS_TYPE")="D" then
			rem --- Prevent re-using an existing DEPOSIT_ID
			deposit_dev=fnget_dev("@ART_DEPOSIT")
			deposit_tpl$=fnget_tpl$("@ART_DEPOSIT")
			deposit_id$=trans_no$
			found_deposit=0
			find(deposit_dev,key=firm_id$+deposit_id$,dom=*next); found_deposit=1
			if found_deposit then
				rem --- Warn DEPOSIT_ID has already been used
				msg_id$="AR_DEPOSIT_USED"
				gosub disp_message
				if msg_opt$="Y" then
					rem --- Assign next new DEPOSIT_ID
					call stbl("+DIR_SYP")+"bas_sequences.bbj","DEPOSIT_ID",deposit_id$,rd_table_chans$[all],"QUIET"
					callpoint!.setUserInput(deposit_id$)
				else
					callpoint!.setStatus("ABORT")
					break
				endif
			endif
		endif
	endif
[[GLT_BANKOTHER.TRANS_TYPE.AVAL]]
rem --- Has the trans_type changed?
	trans_type$=callpoint!.getUserInput()
	if callpoint!.getColumnData("GLT_BANKOTHER.TRANS_TYPE")<>trans_type$ then
		rem --- Is this a Deposit trans_type"
		if trans_type$="D" then
			rem --- Prevent re-using an existing DEPOSIT_ID
			deposit_dev=fnget_dev("@ART_DEPOSIT")
			deposit_tpl$=fnget_tpl$("@ART_DEPOSIT")
			deposit_id$=callpoint!.getColumnData("GLT_BANKOTHER.TRANS_NO")
			found_deposit=0
			find(deposit_dev,key=firm_id$+deposit_id$,dom=*next); found_deposit=1
			if found_deposit then
				rem --- Warn DEPOSIT_ID has already been used
				msg_id$="AR_DEPOSIT_USED"
				gosub disp_message
				if msg_opt$="Y" then
					rem --- Assign next new DEPOSIT_ID
					call stbl("+DIR_SYP")+"bas_sequences.bbj","DEPOSIT_ID",deposit_id$,rd_table_chans$[all],"QUIET"
					callpoint!.setColumnData("GLT_BANKOTHER.TRANS_NO",deposit_id$,1)
				else
					callpoint!.setStatus("ABORT")
					break
				endif
			endif

			rem --- Endisable the Cash Receipt Code column when the TRANS_TYPE=D.
			callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"GLT_BANKOTHER.CASH_REC_CD",1)
		else
			rem --- Clear and disable the Cash Receipt Code column when the TRANS_TYPE<>D.
			callpoint!.setColumnData("GLT_BANKOTHER.CASH_REC_CD","",1)
			callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"GLT_BANKOTHER.CASH_REC_CD",0)
		endif
	endif
