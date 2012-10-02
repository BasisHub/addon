[[GLM_BANKMASTER.AOPT-POST]]
rem " --- Recalc Summary Info

	gosub calc_totals

	balanced$="Y"
	if over_under$<>"" 
		call stbl("+DIR_PGM")+"adc_getmask.aon","","GL","A","",m1$,0,0
		balanced$="N"
		msg_id$="BANK_OOB"
		dim msg_tokens$[2]
		msg_tokens$[1]=over_under$
		msg_tokens$[2]=str(abs(num(callpoint!.getColumnData("GLM_BANKMASTER.BOOK_BALANCE"))-end_bal):m1$)
		msg_opt$=""
		gosub disp_message
	endif

rem " --- See if they want to print
	
	msg_id$="PRINT_TRANS"
	dim msg_tokens$[1]
	msg_opt$=""
	gosub disp_message
	if msg_opt$="Y"
		gl_account$=callpoint!.getColumnData("GLM_BANKMASTER.GL_ACCOUNT")
		call stbl("+DIR_PGM")+"glr_bankmaster.aon",gl_account$
	endif

rem " --- If balanced, see if they want to remove paid transactions

	if balanced$="Y"
		msg_id$="REMOVE_PAID"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		if msg_opt$="Y"
rem " --- Remove Paid Checks"           
			read (glt05_dev,key=firm_id$+gl_acct$,dom=*next)
			while 1
				dim glt05a$:user_tpl.glt05_tpl$
				readrecord (glt05_dev,end=*break)glt05a$
				if glt05a.firm_id$<>firm_id$ break
				if glt05a.gl_account$<>gl_acct$ break
				if glt05a.paid_code$<>"P" continue
				if glt05a.bnk_chk_date$>st_date$ continue
				remove (glt05_dev,key=glt05a.firm_id$+glt05a.gl_account$+glt05a.check_no$,dom=*next)
			wend

rem " --- Remove Paid Transactions"
			read (glt15_DEV,key=firm_id$+gl_acct$,dom=*next)
			while 1
				dim glt15a$:user_tpl.glt15_tpl$
				readrecord (glt15_dev,end=*break)glt15a$
				if glt15a.firm_id$<>firm_id$ break
				if glt15a.gl_account$<>gl_acct$ break
				if glt15a.posted_code$<>"P" continue
				if glt15a.trns_date$>st_date$ continue
				remove (glt15_dev,key=glt15a.firm_id$+glt15a.gl_account$+glt15a.trans_no$,dom=*next)
			wend
		endif
		callpoint!.setColumnData("GLM_BANKMASTER.PRI_END_DATE",callpoint!.getColumnData("GLM_BANKMASTER.CURSTM_DATE"))
		callpoint!.setColumnData("GLM_BANKMASTER.CURSTM_DATE","")
		callpoint!.setColumnData("GLM_BANKMASTER.PRI_END_AMT",callpoint!.getColumnData("GLM_BANKMASTER.CUR_STMT_AMT"))
		callpoint!.setColumnData("GLM_BANKMASTER.CUR_STMT_AMT","0")
		callpoint!.setColumnData("GLM_BANKMASTER.BOOK_BALANCE","0")
		rec_data.pri_end_date$=callpoint!.getColumnData("GLM_BANKMASTER.PRI_END_DATE")
		rec_data.curstm_date$=callpoint!.getColumnData("GLM_BANKMASTER.CURSTM_DATE")
		rec_data.pri_end_amt$=callpoint!.getColumnData("GLM_BANKMASTER.PRI_END_AMT")
		rec_data.cur_stmt_amt$=callpoint!.getColumnData("GLM_BANKMASTER.CUR_STMT_AMT")
		rec_data.book_balance$=callpoint!.getColumnData("GLM_BANKMASTER.BOOK_BALANCE")
		writerecord(fnget_dev("GLM_BANKMASTER"))rec_data$
	endif
[[GLM_BANKMASTER.CUR_STMT_AMT.AVAL]]
rem " --- Recalc Summary Info

	gosub calc_totals
[[GLM_BANKMASTER.ARAR]]
rem " --- Calculate Summary info

  	gosub calc_totals
[[GLM_BANKMASTER.CURSTM_DATE.AVAL]]
rem " --- Recalc Summary Info

	gosub calc_totals
[[GLM_BANKMASTER.AOPT-DETL]]
rem " --- Recalc Summary Info

	gosub calc_totals

	gl_account$=callpoint!.getColumnData("GLM_BANKMASTER.GL_ACCOUNT")
	call stbl("+DIR_PGM")+"glr_bankmaster.aon",gl_account$
[[GLM_BANKMASTER.BSHO]]
rem --- Open/Lock files
	dir_pgm$=stbl("+DIR_PGM")
	sys_pgm$=stbl("+DIR_SYP")

	num_files=5
	dim files$[num_files],options$[num_files],ids$[num_files],templates$[num_files],channels[num_files]
	files$[1]="gls_params",ids$[1]="GLS_PARAMS",options$[1]="OTA"
	files$[2]="glt-06",ids$[2]="GLT_TRANSDETAIL",options$[2]="OTA"; rem ars-10D
	files$[3]="glm-02",ids$[3]="GLM_ACCTSUMMARY",options$[3]="OTA"
	files$[4]="glt-05",ids$[4]="GLT_BANKCHECKS",options$[4]="OTA"
	files$[5]="glt-15",ids$[5]="GLT_BANKOTHER",options$[5]="OTA"
	call stbl("+DIR_PGM")+"adc_fileopen.aon",action,1,num_files,files$[all],options$[all],
:                              ids$[all],templates$[all],channels[all],batch,status
	if status then
		remove_process_bar:
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
	 	release
	endif

	gls01_dev=channels[1]
	glt06_dev=channels[2]
	glm02_dev=channels[3]
	glt05_dev=channels[4]
	glt15_dev=channels[5]

rem --- Set up user_tpl$

	dim user_tpl$:"gls01_tpl:c(2048),glt06_tpl:c(1024),glm02_tpl:c(1024),glt05_tpl:c(1024),glt15_tpl:c(1024),"+
:	"gls01_dev:n(4),glt06_dev:n(4),glm02_dev:n(4),glt05_dev:n(4),glt15_dev:n(4)"

	user_tpl.gls01_tpl$=templates$[1]
	user_tpl.glt06_tpl$=templates$[2]
	user_tpl.glm02_tpl$=templates$[3]
	user_tpl.glt05_tpl$=templates$[4]
	user_tpl.glt15_tpl$=templates$[5]
	user_tpl.gls01_dev=gls01_dev
	user_tpl.glt06_dev=glt06_dev
	user_tpl.glm02_dev=glm02_dev
	user_tpl.glt05_dev=glt05_dev
	user_tpl.glt15_dev=glt15_dev

rem - Set up disabled controls

	dim dctl$[6]
	dctl$[1]="<<DISPLAY>>.STMT_AMT"
	dctl$[2]="<<DISPLAY>>.CHECKS_OUT"
	dctl$[3]="<<DISPLAY>>.TRANS_OUT"
	dctl$[4]="<<DISPLAY>>.END_BAL"
	dctl$[5]="<<DISPLAY>>.NO_CHECKS"
	dctl$[6]="<<DISPLAY>>.NO_TRANS"
	gosub disable_ctls
[[GLM_BANKMASTER.<CUSTOM>]]
check_date: rem " --- Check Statement Ending Date"

	status=0
	call stbl("+DIR_PGM")+"glc_ctlcreate.aon",pgm(-2),"GL","","",status
	if status release
	call stbl("+DIR_PGM")+"glc_datecheck.aon",stmtdate$,"Y",stmtperiod$,stmtyear$,status
	stmtperiod=num(stmtperiod$)
	stmtperiod$=str(stmtperiod:"00")
	stmtyear=num(stmtyear$)
	if gls01a.gl_yr_closed$="Y" currentgl=num(gls01a.current_year$) else currentgl=num(gls01a.current_year$)-1; rem "GL year end closed?
	priorgl=currentgl-1
	nextgl=currentgl+1
	if stmtyear<priorgl and stmtyear>nextgl
		dim message$[1]
		message$[0]="Date is not in prior, current or next G/L year."
		message$[1]="       Press <Enter> to Continue"
		call stbl("+DIR_PGM")+ "adc.stdmessage.aon",2,message$[all],1,0,0,v$,v3
		status=1
	endif
	return

calc_totals: rem " --- Calculate Totals for Summary Information

	glt05_dev=user_tpl.glt05_dev
	glt15_dev=user_tpl.glt15_dev
	gl_acct$=callpoint!.getColumnData("GLM_BANKMASTER.GL_ACCOUNT")
	st_date$=callpoint!.getColumnData("GLM_BANKMASTER.CURSTM_DATE")
	out_checks_amt=0
	out_checks=0
	out_trans_amt=0
	out_trans=0
	over_under$=""
	statement_amt=num(callpoint!.getColumnData("GLM_BANKMASTER.CUR_STMT_AMT"))
	callpoint!.setColumnData("<<DISPLAY>>.STMT_AMT",str(statement_amt))

rem " --- Find Outstanding Checks"           
	read (glt05_dev,key=firm_id$+gl_acct$,dom=*next)
	while 1
		dim glt05a$:user_tpl.glt05_tpl$
		readrecord (glt05_dev,end=*break)glt05a$
		if glt05a.firm_id$<>firm_id$ break
		if glt05a.gl_account$<>gl_acct$ break
		if glt05a.paid_code$<>"O" continue
		if glt05a.bnk_chk_date$>st_date$ continue
		out_checks_amt=out_checks_amt+glt05a.check_amount,out_checks=out_checks+1
	wend

rem " --- Find Outstanding Transactions"
	read (glt15_DEV,key=firm_id$+gl_acct$,dom=*next)
	while 1
		dim glt15a$:user_tpl.glt15_tpl$
		readrecord (glt15_dev,end=*break)glt15a$
		if glt15a.firm_id$<>firm_id$ break
		if glt15a.gl_account$<>gl_acct$ break
		if glt15a.posted_code$<>"O" continue
		if glt15a.trns_date$>st_date$ continue
		out_trans_amt=out_trans_amt+glt15a.trans_amt,out_trans=out_trans+1
	wend

rem " --- Setup display variables

	callpoint!.setColumnData("<<DISPLAY>>.CHECKS_OUT",str(out_checks_amt))
	callpoint!.setColumnData("<<DISPLAY>>.NO_CHECKS",str(out_checks))
	callpoint!.setColumnData("<<DISPLAY>>.TRANS_OUT",str(out_trans_amt))
	callpoint!.setColumnData("<<DISPLAY>>.NO_TRANS",str(out_trans))
	end_bal=statement_amt-out_checks_amt+out_trans_amt
	callpoint!.setColumnData("<<DISPLAY>>.END_BAL",str(end_bal))
	callpoint!.setStatus("REFRESH")
	if end_bal<num(callpoint!.getColumnData("GLM_BANKMASTER.BOOK_BALANCE")) over_under$="SHORT"
	if end_bal>num(callpoint!.getColumnData("GLM_BANKMASTER.BOOK_BALANCE")) over_under$="OVER"
	return

disable_ctls:rem --- disable selected control

	for dctl=1 to 6
		dctl$=dctl$[dctl]
		if dctl$<>""
			wctl$=str(num(callpoint!.getTableColumnAttribute(dctl$,"CTLI")):"00000")
			wmap$=callpoint!.getAbleMap()
			wpos=pos(wctl$=wmap$,8)
			wmap$(wpos+6,1)="I"
			callpoint!.setAbleMap(wmap$)
			callpoint!.setStatus("ABLEMAP")
		endif
	next dctl
	return
[[GLM_BANKMASTER.AOPT-RECL]]
rem --- Validate Current Statement Date
	stmtdate$=callpoint!.getColumnData("GLM_BANKMASTER.CURSTM_DATE")
	if num(stmtdate$)=0
		msg_id$="INVALID_DATE"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		break
	endif

rem --- Find G/L Record"
	dim glm02a$:user_tpl.glm02_tpl$
	dim glt06a$:user_tpl.glt06_tpl$
	dim gls01a$:user_tpl.gls01_tpl$
	glm02_dev=user_tpl.glm02_dev
	glt06_dev=user_tpl.glt06_dev
	gls01_dev=user_tpl.gls01_dev
	readrecord(gls01_dev,key=firm_id$+"GL00")gls01a$
	gosub check_date
	if status exit

	r0$=firm_id$+callpoint!.getColumnData("GLM_BANKMASTER.GL_ACCOUNT"),s0$=""
	if stmtyear=priorgl s0$=r0$+"2"; rem "Use prior year actual
	if stmtyear=currentgl s0$=r0$+"0"; rem "Use current year actual
	if stmtyear=nextgl s0$=r0$+"4"; rem "Use next year actual
	if s0$="" 
		msg_id$="INVALID_DATE"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		exit; rem "Invalid statement year
	endif
	read record (glm02_dev,key=s0$,dom=*next) glm02a$

rem --- Calculate Balance"
	total_amt=glm02a.begin_amt,total_units=glm02a.begin_units
	for x=1 to stmtperiod
		total_amt=total_amt+nfield(glm02a$,"period_amt_"+str(x:"00"))
		total_units=total_units+nfield(glm02a$,"period_units_"+str(x:"00"))
	next x
	call stbl("+DIR_PGM")+"adc_daydates.aon",stmtdate$,nextday$,1
	d0$=r0$+stmtyear$+stmtperiod$+nextday$,amount=0
	readrecord (glt06_dev,key=d0$,dom=*next)

rem --- Accumulate transactions for period after statement date"
	while 1
		k$=key(glt06_dev,END=*break)
		if pos(r0$=k$)<>1 break
		if k$(13,4)<>stmtyear$+stmtperiod$ break
		dim glt06a$:fattr(glt06a$)
		read record (glt06_dev,key=K$)glt06a$
		amount=amount+glto6a.trans_amt
	wend

rem --- Back out transactions for period after statement date"
	total_amt=total_amt-amount

rem --- All Done"
	callpoint!.setColumnData("GLM_BANKMASTER.BOOK_BALANCE",str(total_amt))
	callpoint!.setStatus("REFRESH")

rem " --- Recalc Summary Info

	gosub calc_totals
