[[ADM_PROCBATCHES.BATCH_NO.AVAL]]
rem --- don't allow user to assign new batch# -- use Barista seq# (BATCH_NO)
rem --- if user made null entry (to assign next seq automatically) then getRawUserInput() will be empty
rem --- if not empty, then the user typed a number -- if an existing batch#, fine; if not, abort

if cvs(callpoint!.getRawUserInput(),3)<>""
	msk$=callpoint!.getTableColumnAttribute("ADM_PROCBATCHES.BATCH_NO","MSKI")
	process_id$=stbl("+PROCESS_ID",err=*next)
	find_batch$=str(num(callpoint!.getRawUserInput()):msk$)
	adm_procbatches_dev=fnget_dev("ADM_PROCBATCHES")
	dim adm_procbatches$:fnget_tpl$("ADM_PROCBATCHES")
	read record (adm_procbatches_dev,key=firm_id$+process_id$+find_batch$,dom=*next)adm_procbatches$
	if pos(firm_id$+process_id$+find_batch$=adm_procbatches$)<>1
		msg_id$="AD_INVAL_BATCH"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
endif
[[ADM_PROCBATCHES.ARNF]]
rem --- disallow user entering non-existent batch number
	if stbl("+ALLOW_NEW_BATCH",err=*next)<>"Y"
		callpoint!.setStatus("CLEAR-NEWREC")
	else
rem --- set defaults

		callpoint!.setColumnData("ADM_PROCBATCHES.DATE_OPENED",date(0:"%Yd%Mz%Dz"),1)
		callpoint!.setColumnData("ADM_PROCBATCHES.LSTUSE_DATE",date(0:"%Yd%Mz%Dz"),1)
		callpoint!.setColumnData("ADM_PROCBATCHES.LSTUSE_TIME",date(0:"%hz%mz"),1)
		callpoint!.setColumnData("ADM_PROCBATCHES.PROCESS_ID",stbl("+PROCESS_ID"),1)
		callpoint!.setColumnData("ADM_PROCBATCHES.TIME_OPENED",date(0:"%hz%mz"),1)
		callpoint!.setColumnData("ADM_PROCBATCHES.USER_ID",sysinfo.user_id$,1)
		callpoint!.setColumnData("ADM_PROCBATCHES.DESCRIPTION",stbl("+BATCH_DESC"),1)
		callpoint!.setStatus("MODIFIED")
		callpoint!.setColumnEnabled("ADM_PROCBATCHES.BATCH_NO",0)
	endif
[[ADM_PROCBATCHES.BEND]]
rem --- Notify user of the process aborting and release

	msg_id$="PROCESS_ABORT"
	gosub disp_message
	release
[[ADM_PROCBATCHES.BTBL]]
callpoint!.setTableColumnAttribute("ADM_PROCBATCHES.PROCESS_ID","PVAL",$22$+stbl("+PROCESS_ID")+$22$)
if stbl("+ALLOW_NEW_BATCH")<>"Y"
	batch_opts$=callpoint!.getTableColumnAttribute("ADM_PROCBATCHES.BATCH_NO","OPTS")
	x=pos("#;"=batch_opts$,2)
	if x
		batch_opts$=batch_opts$(1,x-1)+batch_opts$(x+2)
		callpoint!.setTableColumnAttribute("ADM_PROCBATCHES.BATCH_NO","OPTS",batch_opts$)
	endif
endif
[[ADM_PROCBATCHES.AOPT-SELB]]
rem --- set exit stbl to be this batch number

x$=stbl("+BATCH_NO",callpoint!.getColumnData("ADM_PROCBATCHES.BATCH_NO"))

lock_table$=callpoint!.getAlias()
lock_record$=firm_id$+callpoint!.getColumnData("ADM_PROCBATCHES.PROCESS_ID")+callpoint!.getColumnData("ADM_PROCBATCHES.BATCH_NO")
lock_type$="S"
lock_status$=""
lock_disp$="M"

call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$

if lock_status$=""
	callpoint!.setStatus("EXIT")
endif
