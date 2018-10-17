[[GLE_JRNLDET.BDGX]]
rem --- Disable comments
	callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"GLE_JRNLDET.MEMO_1024",0)
	callpoint!.setOptionEnabled("COMM",0)
[[GLE_JRNLDET.MEMO_1024.AVAL]]
rem --- store first part of memo_1024 in gl_post_memo
rem --- this AVAL is hit if user navigates via arrows or clicks on the memo_1024 field, and double-clicks or ctrl-F to bring up editor
rem --- if on a memo line or using ctrl-C or Comments button, code in the comment_entry: subroutine is hit instead

	disp_text$=callpoint!.getUserInput()
	if disp_text$<>callpoint!.getColumnUndoData("GLE_JRNLDET.MEMO_1024")
		memo_len=len(callpoint!.getColumnData("GLE_JRNLDET.GL_POST_MEMO"))
		memo$=disp_text$
		memo$=memo$(1,min(memo_len,(pos($0A$=memo$+$0A$)-1)))

		callpoint!.setColumnData("GLE_JRNLDET.MEMO_1024",disp_text$)
		callpoint!.setColumnData("GLE_JRNLDET.GL_POST_MEMO",memo$,1)

		callpoint!.setStatus("MODIFIED")
	endif
[[GLE_JRNLDET.AOPT-COMM]]
rem --- Launch Comments dialog
	gosub comment_entry
	callpoint!.setStatus("ABORT")
[[GLE_JRNLDET.GL_POST_MEMO.BINP]]
rem --- Launch Comments dialog
	gosub comment_entry
	callpoint!.setStatus("ABORT")
[[GLE_JRNLDET.GL_ACCOUNT.AVAL]]
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
[[GLE_JRNLDET.AGRN]]
rem --- recal/display tots when entering a grid row
	gosub calc_grid_tots
	gosub disp_totals

rem --- Enable comments
	if callpoint!.isEditMode() then
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"GLE_JRNLDET.MEMO_1024",1)
		callpoint!.setOptionEnabled("COMM",1)
	else
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"GLE_JRNLDET.MEMO_1024",0)
		callpoint!.setOptionEnabled("COMM",0)
	endif
[[GLE_JRNLDET.AGRE]]
rem --- recal/display tots when leaving a grid row
	gosub calc_grid_tots
	gosub disp_totals

[[GLE_JRNLDET.ADGE]]
rem --- set default value for memo lines to the description entered in the header
	description$=callpoint!.getHeaderColumnData("GLE_JRNLHDR.DESCRIPTION")
	callpoint!.setTableColumnAttribute("GLE_JRNLDET.GL_POST_MEMO","DFLT",description$)
	callpoint!.setTableColumnAttribute("GLE_JRNLDET.MEMO_1024","DFLT",description$)
[[GLE_JRNLDET.AGCL]]
rem --- set preset val for batch_no

callpoint!.setTableColumnAttribute("GLE_JRNLDET.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)

rem --- Set column size for memo_1024 field very small so it doesn't take up room, but still available for hover-over of memo contents
	use ::ado_util.src::util

	grid! = util.getGrid(Form!)
	col_hdr$=callpoint!.getTableColumnAttribute("GLE_JRNLDET.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(grid!, col_hdr$)
	grid!.setColumnWidth(memo_1024_col,15)
[[GLE_JRNLDET.AUDE]]
rem --- recal/display tots after deleting a grid row
gosub calc_grid_tots
gosub disp_totals
[[GLE_JRNLDET.ADEL]]
rem --- recal/display tots after deleting a grid row
gosub calc_grid_tots
gosub disp_totals
[[GLE_JRNLDET.UNITS.AVAL]]
gosub calc_grid_tots
gosub disp_totals
[[GLE_JRNLDET.DEBIT_AMT.AVAL]]
rem set credit amt to zero (since entering debit), then recalc/display hdr disp columns
                    
if num(callpoint!.getUserInput())<>0 callpoint!.setColumnData("GLE_JRNLDET.CREDIT_AMT",str(0),1)

callpoint!.setStatus("MODIFIED")
[[GLE_JRNLDET.DEBIT_AMT.AVEC]]
gosub calc_grid_tots
gosub disp_totals
[[GLE_JRNLDET.CREDIT_AMT.AVAL]]
rem set debit amt to zero (since entering credit), then recalc/display hdr disp columns
                    
if num(callpoint!.getUserInput())<>0 callpoint!.setColumnData("GLE_JRNLDET.DEBIT_AMT",str(0),1)

callpoint!.setStatus("MODIFIED")
[[GLE_JRNLDET.CREDIT_AMT.AVEC]]
gosub calc_grid_tots
gosub disp_totals
[[GLE_JRNLDET.<CUSTOM>]]
#include std_functions.src
rem calculate total debits/credits/units and display in form header

calc_grid_tots:

	recVect!=GridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs=recVect!.size()
	if numrecs>0
		for reccnt=0 to numrecs-1
			gridrec$=recVect!.getItem(reccnt)
			if cvs(gridrec$,3) <> "" and callpoint!.getGridRowDeleteStatus(reccnt)<>"Y"
				tdb=tdb+num(gridrec.debit_amt$)
				tcr=tcr+num(gridrec.credit_amt$)
				tunits=tunits+num(gridrec.units$)
				rem print 'show',gridrec.debit_amt$," ",gridrec.credit_amt$," ",tdb,tcr
			endif
		next reccnt

		tbal=tdb-tcr
		user_tpl.tot_db$=str(tdb)
		user_tpl.tot_cr$=str(tcr)
		user_tpl.tot_units$=str(tunits)
		user_tpl.tot_bal$=str(tbal)
	endif
return


disp_totals:

	rem --- get context and ID of display controls, and redisplay w/ amts from calc_grid_tots
	    
	debits!=UserObj!.getItem(num(user_tpl.debits_ofst$))
	debits!.setValue(num(user_tpl.tot_db$))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.DEBIT_AMT",user_tpl.tot_db$)

	credits!=UserObj!.getItem(num(user_tpl.credits_ofst$))
	credits!.setValue(num(user_tpl.tot_cr$))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.CREDIT_AMT",user_tpl.tot_cr$)

	bal!=UserObj!.getItem(num(user_tpl.bal_ofst$))
	bal!.setValue(num(user_tpl.tot_bal$))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.BALANCE",user_tpl.tot_bal$)

	units!=UserObj!.getItem(num(user_tpl.units_ofst$))
	units!.setValue(num(user_tpl.tot_units$))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.UNITS",user_tpl.tot_units$)

return

rem ==========================================================================
comment_entry:
rem --- pop the new memo_1024 editor instead entering the gl_post_memo cell
rem --- the editor can be popped on demand for any line using the Comments button (alt-C)
rem ==========================================================================

	disp_text$=callpoint!.getColumnData("GLE_JRNLDET.MEMO_1024")
	sv_disp_text$=disp_text$

	editable$="YES"
	force_loc$="NO"
	baseWin!=null()
	startx=0
	starty=0
	shrinkwrap$="NO"
	html$="NO"
	dialog_result$=""

	call stbl("+DIR_SYP")+ "bax_display_text.bbj",
:		"Comments/Message Line",
:		disp_text$, 
:		table_chans$[all], 
:		editable$, 
:		force_loc$, 
:		baseWin!, 
:		startx, 
:		starty, 
:		shrinkwrap$, 
:		html$, 
:		dialog_result$

	if disp_text$<>sv_disp_text$
		gl_post_memo$=disp_text$(1,pos($0A$=disp_text$+$0A$)-1)
		callpoint!.setColumnData("GLE_JRNLDET.MEMO_1024",disp_text$,1)
		callpoint!.setColumnData("GLE_JRNLDET.GL_POST_MEMO",gl_post_memo$,1)
		callpoint!.setStatus("MODIFIED")
	endif

	callpoint!.setStatus("ACTIVATE")

	return
