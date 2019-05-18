[[ADC_BANKACCTCODE.<CUSTOM>]]
#include std_functions.src
[[ADC_BANKACCTCODE.BSHO]]
rem --- Open tables
	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APS_ACH",open_opts$[1]="OTA"
	open_tables$[2]="GLM_BANKMASTER",   open_opts$[2]="OTA"
	gosub open_tables
[[ADC_BANKACCTCODE.BDEL]]
rem --- Don’t allow deletinging BNK_ACCT_CD if currently in use in either APS_ACH or GLM_BANKMASTER (glm-05)
	bnk_acct_cd$=callpoint!.getColumnData("ADC_BANKACCTCODE.BNK_ACCT_CD")

	rem --- Check for using APS_ACH
	apsAch_dev=fnget_dev("APS_ACH")
	dim apsAch$:fnget_tpl$("APS_ACH")
	readrecord(apsAch_dev,key=firm_id$+"AP00",dom=*next)apsAch$
	if apsAch.bnk_acct_cd$=bnk_acct_cd$ then
		rem --- Cannot delete this Bank Account Code. It is currently used for ACH Payments in AP Parameters.
		msg_id$="AD_BNKACCTCD_ACH"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

	rem --- Check for using GLM_BANKMASTER (glm-05)
	bnkAcctCd_used=0
	glm05_dev=fnget_dev("GLM_BANKMASTER")
	dim glm05a$:fnget_tpl$("GLM_BANKMASTER")
	read(glm05_dev,key=firm_id$,dom=*next)
	while 1
		readrecord(glm05_dev,end=*next)glm05a$
		if glm05a.firm_id$<>firm_id$ then break
		if glm05a.bnk_acct_cd$<>bnk_acct_cd$ then continue
		bnkAcctCd_used=1
		break
	wend
	if bnkAcctCd_used then
		rem --- Cannot delete this Bank Account Code. It is currently used in Bank Reconciliation for account %1.
    		call stbl("+DIR_PGM")+"adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,gl_size
		msg_id$="AD_BNKACCTCD_BNKREC"
		dim msg_tokens$[1]
		msg_tokens$[1]=fnmask$(glm05a.gl_account$(1,gl_size),m0$)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif
[[ADC_BANKACCTCODE.BNK_ACCT_NO.AVAL]]
rem --- Bank account number required for Checking and Savings accounts
	aba_no$=callpoint!.getUserInput()
	bnk_acct_type$=callpoint!.getColumnData("ADC_BANKACCTCODE.BNK_ACCT_TYPE")
	if pos(bnk_acct_type$="CS") and cvs(aba_no$,2)="" then
		msg_id$="AD_BNKACCT_REQ"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[ADC_BANKACCTCODE.ABA_NO.AVAL]]
rem --- Bank routing number required for Checking and Savings accounts
	aba_no$=callpoint!.getUserInput()
	bnk_acct_type$=callpoint!.getColumnData("ADC_BANKACCTCODE.BNK_ACCT_TYPE")
	if pos(bnk_acct_type$="CS") and cvs(aba_no$,2)="" then
		msg_id$="AD_ABANO_REQ"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
