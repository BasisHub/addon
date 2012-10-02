[[GLE_ALLOCHDR.BEND]]
rem --- remove software lock on batch, if batching

	batch$=stbl("+BATCH_NO",err=*next)
	if num(batch$)<>0
		lock_table$="ADM_PROCBATCHES"
		lock_record$=firm_id$+stbl("+PROCESS_ID")+batch$
		lock_type$="U"
		lock_status$=""
		lock_disp$=""
		call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$
	endif
[[GLE_ALLOCHDR.BTBL]]
rem --- Get Batch information

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]
callpoint!.setTableColumnAttribute("GLE_ALLOCHDR.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)


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
