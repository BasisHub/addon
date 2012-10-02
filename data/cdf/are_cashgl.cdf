[[ARE_CASHGL.BSHO]]
rem --- Get Batch information

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]
callpoint!.setTableColumnAttribute("ARE_CASHGL.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[ARE_CASHGL.GL_POST_AMT.AVAL]]
rem escape;rem post amt aval
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
