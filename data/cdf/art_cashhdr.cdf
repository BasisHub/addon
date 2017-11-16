[[ART_CASHHDR.AREC]]
rem --- Disable GL Distribution until record selected
	callpoint!.setOptionEnabled("GLED",0)
[[ART_CASHHDR.AOPT-GLED]]
rem --- Launch GL Dist grid if posting to GL
	if callpoint!.getDevObject("gl")="Y" then
		gosub gl_distribution
	else
		msg_id$="AR_NO_GL"
		gosub disp_message							
	endif
[[ART_CASHHDR.<CUSTOM>]]
#include std_missing_params.src

rem ==================================================================
get_customer_balance:
rem ==================================================================
	arm_custdet_dev=fnget_dev("ARM_CUSTDET")
	dim arm02a$:fnget_tpl$("ARM_CUSTDET")
	customer_id$=callpoint!.getColumnData("ART_CASHHDR.CUSTOMER_ID")
	ar_type$=callpoint!.getColumnData("ART_CASHHDR.AR_TYPE")
	readrecord(arm_custdet_dev,key=firm_id$+customer_id$+ar_type$,err=*next)arm02a$
	callpoint!.setColumnData("<<DISPLAY>>.DISP_CUST_BAL",
:		str(num(arm02a.aging_future$)+num(arm02a.aging_cur$)+num(arm02a.aging_30$)+
:       num(arm02a.aging_60$)+num(arm02a.aging_90$)+num(arm02a.aging_120$)),1)

	return

rem ==================================================================
gl_distribution:
rem ==================================================================
	user_id$=stbl("+USER_ID")
	dim dflt_data$[1,1]
	key_pfx$=callpoint!.getRecordKey()
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"ART_CASHGL",
:		user_id$,
:		"MNT",
:		key_pfx$,
:		table_chans$[all],
:		"",
:		dflt_data$[all]

	return
[[ART_CASHHDR.ADIS]]
rem --- Get description for bank deposit
	deposit_id$=callpoint!.getColumnData("ART_CASHHDR.DEPOSIT_ID")
	if cvs(deposit_id$,2)<>"" then
		artDeposit_dev=fnget_dev("ART_DEPOSIT")
		dim artDeposit$:fnget_tpl$("ART_DEPOSIT")
		readrecord(artDeposit_dev,key=firm_id$+deposit_id$,dom=*endif)artDeposit$
		callpoint!.setColumnData("<<DISPLAY>>.DEPOSIT_DESC",artDeposit.description$,1)
	endif

rem --- Get Cash Receipt Code and enable/disable GL Distribution
	arcCashCode_dev=fnget_dev("ARC_CASHCODE")
	dim arcCashCode$:fnget_tpl$("ARC_CASHCODE")
	cash_rec_cd$=callpoint!.getColumnData("ART_CASHHDR.CASH_REC_CD")
	readrecord(arcCashCode_dev,key=firm_id$+"C"+cash_rec_cd$,dom=*next)arcCashCode$
	if arcCashCode.arglboth$="A" then
		callpoint!.setOptionEnabled("GLED",0)
	else
		callpoint!.setOptionEnabled("GLED",1)
	endif

rem --- Get Customer Balance
	gosub get_customer_balance

rem --- Get Applied and Remaining to Apply amounts
	cash_applied=0
	recVect!=GridVect!.getItem(0)
	if recVect!.size() then
		dim gridrec$:dtlg_param$[1,3]
		for i=0 to recVect!.size()-1
			gridrec$=recVect!.getItem(i)
			cash_applied=cash_applied+gridrec.apply_amt
		next i
	endif

	artCashGL_dev=fnget_dev("ART_CASHGL")
	dim artCashGL$:fnget_tpl$("ART_CASHGL")
	artCashHdr_key$=callpoint!.getRecordKey()
	gl_applied=0
	read(artCashGL_dev,key=artCashHdr_key$,dom=*next)
	while 1
		read record(artCashGL_dev,end=*break)artCashGL$
		if pos(artCashHdr_key$=artCashGL$)<>1 then break
		gl_applied=gl_applied+num(artCashGL.gl_post_amt$)
	wend

	applied=cash_applied+gl_applied
	remaining=num(callpoint!.getColumnData("ART_CASHHDR.PAYMENT_AMT"))-applied
	callpoint!.setColumnData("<<DISPLAY>>.DISP_APPLIED",str(applied),1)
	callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",str(remaining),1)
	if gl_applied
		Form!.getControl(callpoint!.getDevObject("GLind_id")).setText(Translate!.getTranslation("AON_*_INCLUDES_GL_DISTRIBUTIONS"))
		Form!.getControl(callpoint!.getDevObject("GLstar_id")).setText("*")
	else
		Form!.getControl(callpoint!.getDevObject("GLind_id")).setText("")
		Form!.getControl(callpoint!.getDevObject("GLstar_id")).setText("")
	endif	
[[ART_CASHHDR.AWIN]]
rem --- Open/Lock files
	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="ARM_CUSTDET",open_opts$[1]="OTA"
	open_tables$[2]="ART_DEPOSIT",open_opts$[2]="OTA"
	open_tables$[3]="ART_INVHDR",open_opts$[3]="OTA"
	open_tables$[4]="ART_CASHGL",open_opts$[4]="OTA"
	open_tables$[5]="ARC_CASHCODE",open_opts$[5]="OTA"

	gosub open_tables

rem --- Posting to GL?
	gl$="N"
	call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,pgm(-2),"AR",glw11$,gl$,status
	if status<>0 goto std_exit
	callpoint!.setDevObject("gl",gl$)

rem --- Set up relative to the Applied control, static text controls to show when there is a GL distribution included
	applied_ctl!=callpoint!.getControl("<<DISPLAY>>.DISP_APPLIED")
	app_x=applied_ctl!.getX()
	app_y=applied_ctl!.getY()
	app_w=applied_ctl!.getWidth()
	app_h=applied_ctl!.getHeight()

	Form!.addStaticText(nxt_ctlID+4,app_x,195,200,app_h,"")
	Form!.addStaticText(nxt_ctlID+5,app_x+app_w+10,175,20,app_h,"")

	callpoint!.setDevObject("GLind_id",nxt_ctlID+4)
	callpoint!.setDevObject("GLstar_id",nxt_ctlID+5)
