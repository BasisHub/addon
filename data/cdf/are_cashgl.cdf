[[ARE_CASHGL.AGDR]]
rem --- Initialize Comments from memo_1024
	disp_text$=callpoint!.getColumnUndoData("ARE_CASHGL.MEMO_1024")
	dim comment$(40)
	comment$(1)=disp_text$(1,pos($0A$=disp_text$+$0A$)-1)
	callpoint!.setColumnData("<<DISPLAY>>.COMMENT",comment$,1)
[[ARE_CASHGL.MEMO_1024.AVAL]]
rem --- Store first part of memo_1024 in Comment.
rem --- This AVAL is hit if user navigates via arrows or clicks on the memo_1024 field, and double-clicks or ctrl-F to bring up editor.
rem --- If use Comment field, or use ctrl-C or Comments button, code in the comment_entry subroutine is hit instead.
	disp_text$=callpoint!.getUserInput()
	if disp_text$<>callpoint!.getColumnUndoData("ARE_CASHGL.MEMO_1024")
		dim comment$(40)
		comment$(1)=disp_text$(1,pos($0A$=disp_text$+$0A$)-1)
		callpoint!.setColumnData("ARE_CASHGL.MEMO_1024",disp_text$,1)
		callpoint!.setColumnData("<<DISPLAY>>.COMMENT",comment$,1)
		callpoint!.setStatus("MODIFIED")
	endif
[[ARE_CASHGL.AOPT-COMM]]
rem --- Invoke the comments dialog
	gosub comment_entry
[[<<DISPLAY>>.COMMENT.BINP]]
rem --- Invoke the comments dialog
	gosub comment_entry
[[ARE_CASHGL.<CUSTOM>]]
#include std_functions.src

comment_entry: rem --- When the Comment field is accessed, launch the new memo_1024 editor instead
	disp_text$=callpoint!.getColumnData("ARE_CASHGL.MEMO_1024")
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
:		"GL Distribution Comments",
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
		dim comment$(40)
		comment$(1)=disp_text$(1,pos($0A$=disp_text$+$0A$)-1)
		callpoint!.setColumnData("ARE_CASHGL.MEMO_1024",disp_text$,1)
		callpoint!.setColumnData("<<DISPLAY>>.COMMENT",comment$,1)
		callpoint!.setStatus("MODIFIED")
	endif
	callpoint!.setStatus("ACTIVATE")

	return
[[ARE_CASHGL.GL_ACCOUNT.AVAL]]
rem --- set default amount

	callpoint!.setColumnData("ARE_CASHGL.GL_POST_AMT",str(callpoint!.getDevObject("dflt_gl_amt")),1)
	callpoint!.setDevObject("dflt_gl_amt","")

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
[[ARE_CASHGL.BSHO]]
rem --- Get Batch information

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]
callpoint!.setTableColumnAttribute("ARE_CASHGL.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)

rem --- Set column size for memo_1024 field very small so it doesn't take up room, but still available for hover-over of memo contents
	use ::ado_util.src::util

	maintGrid!=Form!.getControl(num(stbl("+GRID_CTL")))
	col_hdr$=callpoint!.getTableColumnAttribute("ARE_CASHGL.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(maintGrid!, col_hdr$)
	maintGrid!.setColumnWidth(memo_1024_col,15)
[[ARE_CASHGL.BEND]]
rem --- used to prevent user from getting out of GL grid until they posted something... not sure why
rem --- so rem'd the message and abort lines below rather than ripping out all code, 
rem --- (just in case we remember why we did this) 

num_recs=gridVect!.size()
dim wkrec$:fattr(rec_data$)
msg_id$=""
if num_recs
	for wk=0 to num_recs-1
		wkrec$=gridVect!.getItem(wk)
		if wkrec$<>""
			if cvs(wkrec.gl_account$,3)=""
				msg_id$="AR_GL_ERR"
			endif
		endif
	next wk
	if msg_id$<>""
rem		gosub disp_message
rem		callpoint!.setStatus("ABORT")
	endif
endif
