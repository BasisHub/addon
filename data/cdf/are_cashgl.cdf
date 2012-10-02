[[ARE_CASHGL.GL_POST_AMT.AVAL]]
rem escape;rem post amt aval
[[ARE_CASHGL.BEND]]
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
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
endif
