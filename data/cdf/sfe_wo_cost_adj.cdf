[[SFE_WO_COST_ADJ.BEND]]
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

rem --- remove soft lock on Work Order

        lock_table$="SFE_WOMASTR"
        lock_record$=firm_id$+callpoint!.getColumnData("SFE_WO_COST_ADJ.WO_NO")
        lock_type$="X"
        lock_status$=""
        lock_disp$=""
        call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$
[[SFE_WO_COST_ADJ.BFMC]]
rem --- Get Batch information

	call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]
	callpoint!.setTableColumnAttribute("SFE_WO_COST_ADJ.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[SFE_WO_COST_ADJ.<CUSTOM>]]
#include std_missing_params.src
[[SFE_WO_COST_ADJ.ASVA]]
rem --- Call Correct Form

if callpoint!.getColumnData("SFE_WO_COST_ADJ.LEVEL_SELECTION")="O"
	if cvs(callpoint!.getColumnData("SFE_WO_COST_ADJ.WO_NO"),2)<>""

		callpoint!.setDevObject("wo_no",callpoint!.getColumnData("SFE_WO_COST_ADJ.WO_NO"))
		call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:			"SFE_WO_OPSADJ",
:			stbl("+USER_ID"),
:			"MNT",
:			"",
:			table_chans$[all],
:			"",
:			dflt_data$[all]
	endif
endif

if callpoint!.getColumnData("SFE_WO_COST_ADJ.LEVEL_SELECTION")="S"
	if cvs(callpoint!.getColumnData("SFE_WO_COST_ADJ.WO_NO"),2)<>""

		callpoint!.setDevObject("wo_no",callpoint!.getColumnData("SFE_WO_COST_ADJ.WO_NO"))
		call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:			"SFE_WO_SUBADJ",
:			stbl("+USER_ID"),
:			"MNT",
:			"",
:			table_chans$[all],
:			"",
:			dflt_data$[all]
	endif
endif

callpoint!.setStatus("ABORT-ACTIVATE")
[[SFE_WO_COST_ADJ.WO_NO.AVAL]]
rem --- Fill form

	sfe_womast=fnget_dev("SFE_WOMASTR")
	dim sfe_womast$:fnget_tpl$("SFE_WOMASTR")
	wo_no$=callpoint!.getUserInput()

	if cvs(wo_no$,2)<>""
		callpoint!.setDevObject("wo_loc",sfe_womast.wo_location$)
		read record (sfe_womast,key=firm_id$+sfe_womast.wo_location$+wo_no$) sfe_womast$

		if sfe_womast.wo_status$="C"
			msg_id$="WO_CLOSED"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif

rem --- Soft lock the Work Order

		if callpoint!.getDevObject("current_wo")<>wo_no$
			lock_table$="SFE_WOMASTR"
			lock_record$=firm_id$+wo_no$
			lock_type$="S"
			lock_status$=""
			lock_disp$="M"
			call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$
			if lock_status$<>""
				callpoint!.setStatus("ABORT")
				break
			endif
		endif

rem --- check to see if recs exist for a different batch

		found$=""
		adj_dev=fnget_dev("SFE_WOOPRADJ")
		dim adj_tpl$:fnget_tpl$("SFE_WOOPRADJ")
		while 1
			read (adj_dev,key=firm_id$+adj_tpl.wo_location$+wo_no$,dom=*next)
			read record(adj_dev,end=*break) adj_tpl$
			if adj_tpl.batch_no$<>callpoint!.getColumnData("SFE_WO_COST_ADJ.BATCH_NO")
				found$=adj_tpl.batch_no$
			endif
			break
		wend
		adj_dev=fnget_dev("SFE_WOSUBADJ")
		dim adj_tpl$:fnget_tpl$("SFE_WOSUBADJ")
		while 1
			read (adj_dev,key=firm_id$+adj_tpl.wo_location$+wo_no$,dom=*next)
			read record(adj_dev,end=*break) adj_tpl$
			if adj_tpl.batch_no$<>callpoint!.getColumnData("SFE_WO_COST_ADJ.BATCH_NO")
				found$=adj_tpl.batch_no$
			endif
			break
		wend
		if found$<>""
			msg_id$="SF_ADJ_ANOTHERBATCH"
			dim msg_tokens$[1]
			msg_tokens$[1]=found$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif

rem --- passed all tests - go ahead and show the info

		callpoint!.setColumnData("<<DISPLAY>>.WO_CATEGORY",sfe_womast.wo_category$,1)
		callpoint!.setColumnData("<<DISPLAY>>.WO_STATUS",sfe_womast.wo_status$,1)
		callpoint!.setColumnData("<<DISPLAY>>.WO_TYPE",sfe_womast.wo_type$,1)
		callpoint!.setColumnData("<<DISPLAY>>.BILL_NO",sfe_womast.item_id$,1)
		if sfe_womast.wo_category$<>"I"
			callpoint!.setColumnData("<<DISPLAY>>.DESCRIPTION",sfe_womast.description_01$,1)
		endif
		callpoint!.setColumnData("<<DISPLAY>>.UNIT_MEASURE",sfe_womast.unit_measure$,1)
		callpoint!.setColumnData("<<DISPLAY>>.WAREHOUSE_ID",sfe_womast.warehouse_id$,1)
		callpoint!.setDevObject("current_wo",wo_no$)
	endif
[[SFE_WO_COST_ADJ.BSHO]]
rem --- Set Custom Query for BOM Item Number

	callpoint!.setTableColumnAttribute("<<DISPLAY>>.BILL_NO", "IDEF", "BOM_LOOKUP")

rem --- Open tables

	num_files=4
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFE_WOMASTR",open_opts$[1]="OTA"
	open_tables$[2]="SFS_PARAMS",open_opts$[2]="OTA"
	open_tables$[3]="SFE_WOOPRADJ",open_opts$[3]="OTA"
	open_tables$[4]="SFE_WOSUBADJ",open_opts$[4]="OTA"
	gosub open_tables

	sfs_params=num(open_chans$[2])
	dim sfs_params$:open_tpls$[2]

	read record(sfs_params,key=firm_id$+"SF00",dom=std_missing_params)sfs_params$
	pr$=sfs_params.pr_interface$

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	if pr$="Y"
		open_tables$[1]="PRM_EMPLMAST",open_opts$[1]="OTA"
	else
		open_tables$[1]="SFM_EMPLMAST",open_opts$[1]="OTA"
	endif

	gosub open_tables

	callpoint!.setDevObject("pr",pr$)

rem --- Additional Init

	callpoint!.setDevObject("current_wo","")
	gl$="N"
	status=0
	source$=pgm(-2)
	call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"AP",glw11$,gl$,status
	if status<>0 goto std_exit
