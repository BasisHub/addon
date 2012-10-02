[[GLE_ALLOCHDR.BWRI]]
tot_pct=0
recVect!=GridVect!.getItem(0)
        dim gridrec$:dtlg_param$[1,3]
        numrecs=recVect!.size()
        if numrecs>0
            for reccnt=0 to numrecs-1
	            gridrec$=recVect!.getItem(reccnt)
	            if cvs(gridrec$,3)<>"" and callpoint!.getGridRowDeleteStatus(reccnt)<>"Y"
			 tot_pct=tot_pct+num(gridrec.percentage$)
		    endif
            next reccnt
	endif

if tot_pct<>100
	msg_id$="GL_ALLOC_PCT"
	dim msg_tokens$[1]
	msg_tokens$[1]=str(tot_pct)
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
