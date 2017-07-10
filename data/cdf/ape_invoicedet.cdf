[[APE_INVOICEDET.GL_ACCOUNT.AVAL]]
rem "GL INACTIVE FEATURE"
   glm01_dev=fnget_dev("GLM_ACCT")
   glm01_tpl$=fnget_tpl$("GLM_ACCT")
   dim glm01a$:glm01_tpl$
   glacctinput$=callpoint!.getUserInput()
   glm01a_key$=firm_id$+glacctinput$
   find record (glm01_dev,key=glm01a_key$,err=*break) glm01a$
   if glm01a.acct_inactive$="Y" then
      call stbl("+DIR_PGM")+"adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,gl_size
      msg_id$="GL_ACCT_INACTIVE"
      dim msg_tokens$[2]
      msg_tokens$[1]=fnmask$(glm01a.gl_account$(1,gl_size),m0$)
      msg_tokens$[2]=cvs(glm01a.gl_acct_desc$,2)
      gosub disp_message
      callpoint!.setStatus("ACTIVATE-ABORT")
   endif
[[APE_INVOICEDET.ADGE]]
rem --- Verify totals balance

	gosub calc_grid_tots
	gosub disp_totals
[[APE_INVOICEDET.AWRI]]
rem --- Verify totals balance

	gosub calc_grid_tots
	gosub disp_totals
[[APE_INVOICEDET.BDGX]]
rem --- Verify totals balance

	gosub calc_grid_tots
	gosub disp_totals
[[APE_INVOICEDET.AGRN]]
rem --- entering grid row; default the amount to balance on invoice; if row 0, default GL acct# 

if user_tpl.glint$="Y"

	if num(callpoint!.getColumnData("APE_INVOICEDET.GL_POST_AMT"))=0
		dist_bal!=UserObj!.getItem(num(user_tpl.dist_bal_ofst$))
		callpoint!.setColumnData("APE_INVOICEDET.GL_POST_AMT",dist_bal!.getText())
		callpoint!.setStatus("REFRESH:APE_INVOICEDET.GL_POST_AMT")
	endif

	if num(callpoint!.getValidationRow())=0 and cvs(callpoint!.getColumnData("APE_INVOICEDET.GL_ACCOUNT"),3)=""
		callpoint!.setColumnData("APE_INVOICEDET.GL_ACCOUNT",user_tpl.dflt_gl_account$)
		callpoint!.setStatus("MODIFIED-REFRESH:APE_INVOICEDET.GL_ACCOUNT")
	endif

endif




[[APE_INVOICEDET.AGCL]]
rem --- set preset val for batch_no
callpoint!.setTableColumnAttribute("APE_INVOICEDET.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[APE_INVOICEDET.AUDE]]
rem --- after deleting a row from detail grid, recalc/redisplay balance left to distribute
gosub calc_grid_tots
gosub disp_totals
[[APE_INVOICEDET.ADEL]]
rem --- after deleting a row from detail grid, recalc/redisplay balance left to distribute
gosub calc_grid_tots
gosub disp_totals
[[APE_INVOICEDET.GL_POST_AMT.AVEC]]
rem --- add up dist lines and display diff between total inv amt entered and dist line total

gosub calc_grid_tots
gosub disp_totals
[[APE_INVOICEDET.<CUSTOM>]]
#include std_functions.src
calc_grid_tots:

	recVect!=GridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs=recVect!.size()
	tdist=0
	if numrecs>0
		for reccnt=0 to numrecs-1
			gridrec$=recVect!.getItem(reccnt)
			if cvs(gridrec.gl_account$,3)<> "" and callpoint!.getGridRowDeleteStatus(reccnt)<>"Y" 
				tdist=tdist+num(gridrec.gl_post_amt$)
			endif
		next reccnt
	endif
	user_tpl.tot_dist$=str(tdist)
return


disp_totals:

rem --- get context and ID of display controls, and redisplay w/ amts from calc_grid_tots
    	
	dist_bal=num(user_tpl.inv_amt$)-num(user_tpl.tot_dist$)
	dist_bal!=UserObj!.getItem(num(user_tpl.dist_bal_ofst$))
	dist_bal!.setValue(dist_bal)
	callpoint!.setHeaderColumnData("<<DISPLAY>>.DIST_BAL",str(dist_bal))


return
