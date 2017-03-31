[[ARU_FINANCECHARG.BEND]]
rem --- remove software lock on batch, if batching
	batch$=stbl("+BATCH_NO",err=*next)
	if num(batch$)<>0
		lock_table$="ADM_PROCBATCHES"
		lock_record$=firm_id$+stbl("+PROCESS_ID")+batch$
		lock_type$="X"
		lock_status$=""
		lock_disp$=""
		call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$
	endif
[[ARU_FINANCECHARG.BFMC]]
rem --- Get Batch information
	call stbl("+DIR_PGM")+"adc_getbatch.aon","ARE_FINCHG","",table_chans$[all]
	callpoint!.setTableColumnAttribute("ARU_FINANCECHARG.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[ARU_FINANCECHARG.ASVA]]
rem --- Get user approval to clearing non-updated previously created/entered finance charges
	if num(callpoint!.getColumnData("ARU_FINANCECHARG.CLEAR_ARE02")) then
		msg_id$="AR_DEL_FIN_CHRG"
		gosub disp_message
		if msg_opt$="Y" then
			are02_dev=fnget_dev("ARE_FINCHG")
			dim are02a$:fnget_tpl$("ARE_FINCHG")

			batch_no$=callpoint!.getColumnData("ARU_FINANCECHARG.BATCH_NO")
			read (are02_dev,key=firm_id$,dom=*next)
			while 1
				k$=key(are02_dev,end=*break)
				if pos(firm_id$=k$)<>1 break
				read record (are02_dev) are02a$
				if are02a.batch_no$<>batch_no$ then continue
				if are02a.invoice_type$="F" remove (are02_dev,key=k$)
			wend
		endif
	endif
[[ARU_FINANCECHARG.BSHO]]
rem --- Open/Lock files
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARE_FINCHG",open_opts$[1]="OTA"

	gosub open_tables
[[ARU_FINANCECHARG.AREC]]
rem --- Default to clearing non-updated previously created/entered finance charges
	callpoint!.setColumnData("ARU_FINANCECHARG.CLEAR_ARE02","1",1)
