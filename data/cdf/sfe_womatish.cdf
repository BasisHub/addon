[[SFE_WOMATISH.AREA]]
rem --- Hold on to sfe_womatish key

	wo_no$=callpoint!.getColumnData("SFE_WOMATISH.WO_NO")
	callpoint!.setDevObject("wo_no",wo_no$)
	wo_location$=callpoint!.getColumnData("SFE_WOMATISH.WO_LOCATION")
	callpoint!.setDevObject("wo_location",wo_location$)
	sfe_womatish_key$=firm_id$+callpoint!.getColumnData("SFE_WOMATISH.BATCH_NO")+wo_location$+wo_no$
	callpoint!.setDevObject("sfe_womatish_key",sfe_womatish_key$)
	firm_loc_wo$=firm_id$+callpoint!.getColumnData("SFE_WOMATISH.WO_LOCATION")+wo_no$
	callpoint!.setDevObject("firm_loc_wo",firm_loc_wo$)
[[SFE_WOMATISH.WO_NO.AVAL]]
rem --- Hold on to sfe_womatish key

	wo_no$=callpoint!.getUserInput()
	callpoint!.setDevObject("wo_no",wo_no$)
	wo_location$=callpoint!.getColumnData("SFE_WOMATISH.WO_LOCATION")
	callpoint!.setDevObject("wo_location",wo_location$)
	sfe_womatish_key$=firm_id$+callpoint!.getColumnData("SFE_WOMATISH.BATCH_NO")+wo_location$+wo_no$
	callpoint!.setDevObject("sfe_womatish_key",sfe_womatish_key$)
	firm_loc_wo$=firm_id$+callpoint!.getColumnData("SFE_WOMATISH.WO_LOCATION")+wo_no$
	callpoint!.setDevObject("firm_loc_wo",firm_loc_wo$)
[[SFE_WOMATISH.BDEQ]]
rem --- Suppress Barista's default delete message
	callpoint!.setStatus("QUIET")
[[SFE_WOMATISH.BDEL]]
rem --- Retain commitment on delete?

	if callpoint!.getColumnData("SFE_WOMATISH.WO_CATEGORY") = "R"
		msg_id$="SF_DELETE_ISSUE_REC"
	else
		msg_id$="SF_DELETE_ISSUE"
	endif

	gosub disp_message
	if msg_opt$="C" then
		callpoint!.setStatus("ABORT")
		break
	endif
	del_issue_only$=msg_opt$
	callpoint!.setDevObject("del_issue_only",msg_opt$)

rem --- Initialize inventory item update
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

rem --- Delete inventory issues and commitments. Must do this before sfe_womatisd records are removed.
	sfe_womatisd_dev=fnget_dev("SFE_WOMATISD")
	dim sfe_womatisd$:fnget_tpl$("SFE_WOMATISD")
	sfe_womatdtl_dev=fnget_dev("SFE_WOMATDTL")
	dim sfe_womatdtl$:fnget_tpl$("SFE_WOMATDTL")
	sfe_wolsissu_dev=fnget_dev("SFE_WOLSISSU")
	dim sfe_wolsissu$:fnget_tpl$("SFE_WOLSISSU")

	firm_loc_wo$=callpoint!.getDevObject("firm_loc_wo")
	read(sfe_womatisd_dev,key=firm_loc_wo$,knum="AO_DISP_SEQ",dom=*next)
	while 1
		sfe_womatisd_key$=key(sfe_womatisd_dev,end=*break)
		if pos(firm_loc_wo$=sfe_womatisd_key$)<>1 then break
		readrecord(sfe_womatisd_dev)sfe_womatisd$

		rem --- Delete lot/serial commitments, but keep inventory commitments (for now)
		if pos(callpoint!.getDevObject("lotser")="LS") then
			read(sfe_wolsissu_dev,key=firm_loc_wo$+sfe_womatisd.internal_seq_no$,dom=*next)
			while 1
				sfe_wolsissu_key$=key(sfe_wolsissu_dev,end=*break)
				if pos(firm_loc_wo$+sfe_womatisd.internal_seq_no$=sfe_wolsissu_key$)<>1 then break
				readrecord(sfe_wolsissu_dev)sfe_wolsissu$

				rem --- Delete lot/serial commitments
				items$[1]=sfe_womatisd.warehouse_id$
				items$[2]=sfe_womatisd.item_id$
				items$[3]=sfe_wolsissu.lotser_no$
				refs[0]=sfe_wolsissu.qty_issued
				call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

				rem --- Keep inventory commitments (for now)
				items$[3]=" "
				call stbl("+DIR_PGM")+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

				rem --- Barista currently cascades deletes only one level, re Bug 3963
				remove(sfe_wolsissu_dev,key=sfe_wolsissu_key$)
			wend
		endif

        rem --- Delete inventory commitments
		items$[1]=sfe_womatisd.warehouse_id$
		items$[2]=sfe_womatisd.item_id$
		if del_issue_only$="N" then
            rem --- Not retaining committments, so delete all of them
			refs[0]=max(0,sfe_womatisd.qty_ordered-sfe_womatisd.tot_qty_iss)
			call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

			found=0
			sfe_womatdtl_key$=firm_loc_wo$+sfe_womatisd.womatdtl_seq_ref$
			extractrecord(sfe_womatdtl_dev,key=sfe_womatdtl_key$,dom=*next)sfe_womatdtl$; found=1
			if found then
				sfe_womatdtl.qty_ordered=sfe_womatdtl.tot_qty_iss
				writerecord(sfe_womatdtl_dev)sfe_womatdtl$
			endif
		else
			rem --- Retaining committments, so only delete additional committments made after WO was released
			if cvs(sfe_womatisd.womatdtl_seq_ref$,2)="" then
				rem --- Not part of released WO, so uncommit all
				refs[0]=max(0,sfe_womatisd.qty_ordered-sfe_womatisd.tot_qty_iss)
				call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
			else
				rem --- Only uncommit portion of issue's qty_issued that is greater than released WO's qty_ordered
				found=0
				sfe_womatdtl_key$=firm_loc_wo$+sfe_womatisd.womatdtl_seq_ref$
				readrecord(sfe_womatdtl_dev,key=sfe_womatdtl_key$,dom=*next)sfe_womatdtl$; found=1
				if found then
					if max(0,sfe_womatisd.qty_ordered-sfe_womatisd.tot_qty_iss)>max(0,sfe_womatdtl.qty_ordered-sfe_womatdtl.tot_qty_iss) then
						refs[0]=max(0,sfe_womatisd.qty_ordered-sfe_womatisd.tot_qty_iss)-max(0,sfe_womatdtl.qty_ordered-sfe_womatdtl.tot_qty_iss)
						call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
					endif
				endif
			endif
		endif
	wend
[[SFE_WOMATISH.ADEL]]
rem ---  Delete work order transactions

	firm_loc_wo$=callpoint!.getDevObject("firm_loc_wo")

	rem --- Delete work order issues transactions
	remove(fnget_dev("SFE_WOTRANS"),key=firm_loc_wo$,dom=*next)

	rem --- Delete work order commit transactions if not being retained
	if callpoint!.getDevObject("del_issue_only")="N" then
		remove(fnget_dev("SFE_WOCOMMIT"),key=firm_loc_wo$,dom=*next)
	endif
[[SFE_WOMATISH.BEND]]
rem --- Remove software lock on batch when batching
	batch$=stbl("+BATCH_NO",err=*next)
	if num(batch$)<>0
		lock_table$="ADM_PROCBATCHES"
		lock_record$=firm_id$+stbl("+PROCESS_ID")+batch$
		lock_type$="X"
		lock_status$=""
		lock_disp$=""
		call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$
	endif
[[SFE_WOMATISH.BTBL]]
rem --- Get Batch information
	call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]
	callpoint!.setTableColumnAttribute("SFE_WOMATISH.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[SFE_WOMATISH.AREC]]
rem --- Init no existing materials issues
	wotrans=0
	callpoint!.setDevObject("wotrans",wotrans)
	
[[SFE_WOMATISH.ADIS]]
rem --- Init <<DISPLAY>> fields
	sfe_womastr_dev=fnget_dev("SFE_WOMASTR")
	dim sfe_womastr$:fnget_tpl$("SFE_WOMASTR")

	findrecord(sfe_womastr_dev,key=firm_id$+"  "+callpoint!.getColumnData("SFE_WOMATISH.WO_NO"))sfe_womastr$

	callpoint!.setColumnData("<<DISPLAY>>.DESCRIPTION_01",sfe_womastr.description_01$,1)
	callpoint!.setColumnData("<<DISPLAY>>.DESCRIPTION_02",sfe_womastr.description_02$,1)
	callpoint!.setColumnData("<<DISPLAY>>.WO_STATUS",sfe_womastr.wo_status$,1)

rem --- Hold on to the Warehouse ID and Issued Date
	callpoint!.setDevObject("warehouse_id",callpoint!.getColumnData("SFE_WOMATISH.WAREHOUSE_ID"))
	callpoint!.setDevObject("issued_date",callpoint!.getColumnData("SFE_WOMATISH.ISSUED_DATE"))

rem --- Existing materials issues?
	wotrans=0
	sfe_wotrans_dev=fnget_dev("SFE_WOTRANS")
	sfe_wotrans_key$=firm_id$+callpoint!.getColumnData("SFE_WOMATISH.WO_LOCATION")+callpoint!.getColumnData("SFE_WOMATISH.WO_NO")
	find(sfe_wotrans_dev,key=sfe_wotrans_key$,dom=*next); wotrans=1
	callpoint!.setDevObject("wotrans",wotrans)

	if !wotrans then
		rem --- Materials already commited?
		wocommit=0
		sfe_wocommit_dev=fnget_dev("SFE_WOCOMMIT")
		sfe_wocommit_key$=firm_id$+callpoint!.getColumnData("SFE_WOMATISH.WO_LOCATION")+callpoint!.getColumnData("SFE_WOMATISH.WO_NO")
		find(sfe_wocommit_dev,key=sfe_wocommit_key$,dom=*next); wocommit=1

		if wocommit then
			msg_id$="WO_PICKLIST_NOT_DONE"
			gosub disp_message
		endif
	endif
[[SFE_WOMATISH.ISSUED_DATE.AVAL]]
rem --- When GL installed, verify date is in an open period.
	issued_date$=callpoint!.getUserInput()
	if callpoint!.getDevObject("gl")="Y" then
		call stbl("+DIR_PGM")+"glc_datecheck.aon",issued_date$,"Y",per$,yr$,status
		if status>99 then 
			callpoint!.setStatus("ABORT")
			break
		endif
	endif
	callpoint!.setDevObject("issued_date",issued_date$)


rem --- New materials issues entry or no existing materials issues
	if callpoint!.getRecordMode()="A" or !callpoint!.getDevObject("wotrans") then

		rem --- Write SFE_WOMATISH and SFE_WOMATISD so can be reloaded to display new detail in grid
		sfe_womatish_dev=fnget_dev("SFE_WOMATISH")
		dim sfe_womatish$:fnget_tpl$("SFE_WOMATISH")
		sfe_womatish.firm_id$=firm_id$
		sfe_womatish.wo_location$=callpoint!.getColumnData("SFE_WOMATISH.WO_LOCATION")
		sfe_womatish.wo_no$=callpoint!.getColumnData("SFE_WOMATISH.WO_NO")
		sfe_womatish.wo_type$=callpoint!.getColumnData("SFE_WOMATISH.WO_TYPE")
		sfe_womatish.wo_category$=callpoint!.getColumnData("SFE_WOMATISH.WO_CATEGORY")
		sfe_womatish.unit_measure$=callpoint!.getColumnData("SFE_WOMATISH.UNIT_MEASURE")
		sfe_womatish.warehouse_id$=callpoint!.getColumnData("SFE_WOMATISH.WAREHOUSE_ID")
		sfe_womatish.item_id$=callpoint!.getColumnData("SFE_WOMATISH.ITEM_ID")
		sfe_womatish.issued_date$=issued_date$
		sfe_womatish.batch_no$=callpoint!.getColumnData("SFE_WOMATISH.BATCH_NO")

		writerecord(sfe_womatish_dev)sfe_womatish$

		rem --- Initialize SFE_WOMATISD Material Issues from SFE_WOMATDTL Material Detail
		sfe_womatisd_dev=fnget_dev("SFE_WOMATISD")
		dim sfe_womatisd$:fnget_tpl$("SFE_WOMATISD")
		sfe_womatdtl_dev=fnget_dev("SFE_WOMATDTL")
		dim sfe_womatdtl$:fnget_tpl$("SFE_WOMATDTL")

		firm_loc_wo$=callpoint!.getDevObject("firm_loc_wo")
		read(sfe_womatdtl_dev,key=firm_loc_wo$,dom=*next)
		while 1
			sfe_womatdtl_key$=key(sfe_womatdtl_dev,end=*break)
			if pos(firm_loc_wo$=sfe_womatdtl_key$)<>1 then break
			readrecord(sfe_womatdtl_dev)sfe_womatdtl$

			sfe_womatisd.firm_id$=sfe_womatdtl.firm_id$
			sfe_womatisd.wo_location$=sfe_womatdtl.wo_location$
			sfe_womatisd.wo_no$=sfe_womatdtl.wo_no$
			sfe_womatisd.material_seq$=sfe_womatdtl.material_seq$
			sfe_womatisd.internal_seq_no$=sfe_womatdtl.internal_seq_no$
			sfe_womatisd.unit_measure$=sfe_womatdtl.unit_measure$
			sfe_womatisd.womatdtl_seq_ref$=sfe_womatdtl.internal_seq_no$
			sfe_womatisd.warehouse_id$=sfe_womatdtl.warehouse_id$
			sfe_womatisd.item_id$=sfe_womatdtl.item_id$
			sfe_womatisd.require_date$=sfe_womatdtl.require_date$
			sfe_womatisd.qty_ordered=sfe_womatdtl.qty_ordered
			sfe_womatisd.tot_qty_iss=sfe_womatdtl.tot_qty_iss
			sfe_womatisd.unit_cost=sfe_womatdtl.unit_cost
			sfe_womatisd.qty_issued=sfe_womatdtl.qty_issued
			sfe_womatisd.issue_cost=sfe_womatdtl.issue_cost
			sfe_womatisd.batch_no$=sfe_womatish.batch_no$

			writerecord(sfe_womatisd_dev)sfe_womatisd$
		wend

		rem --- Issue all?
		ivm_itemwhse_dev=fnget_dev("IVM_ITEMWHSE")
		ivm_itemwhse_tpl$=fnget_tpl$("IVM_ITEMWHSE")

		msg_id$="WO_PULLED_COMPLETE"
		gosub disp_message
		if msg_opt$="Y" then

			rem --- Pull complete
			read(sfe_womatisd_dev,key=firm_loc_wo$,knum="AO_DISP_SEQ",dom=*next)
			while 1
				sfe_womatisd_key$=key(sfe_womatisd_dev,end=*break)
				if pos(firm_loc_wo$=sfe_womatisd_key$)<>1 then break
				extractrecord(sfe_womatisd_dev)sfe_womatisd$

				dim ivm_itemwhse$:ivm_itemwhse_tpl$
				findrecord(ivm_itemwhse_dev,key=firm_id$+sfe_womatisd.warehouse_id$+sfe_womatisd.item_id$,dom=*next)ivm_itemwhse$

				sfe_womatisd.qty_issued=sfe_womatisd.qty_ordered-sfe_womatisd.tot_qty_iss
				sfe_womatisd.issue_cost=ivm_itemwhse.unit_cost

				writerecord(sfe_womatisd_dev)sfe_womatisd$
			wend

		else

			rem --- Partial issue
			rem --- Launch form to get operation sequence and production quantity
			call stbl("+DIR_SYP")+"bam_run_prog.bbj", "SFE_WOMATISO", stbl("+USER_ID"), "MNT", "", table_chans$[all]
			qty_to_issue=callpoint!.getDevObject("qty_to_issue")
			selected_ops!=callpoint!.getDevObject("selected_ops")
			rem --- Check if all operations were selected
			all_selected=1
			iter!=selected_ops!.values().iterator()

			while iter!.hasNext()
				op$=iter!.next()
				if op$="" then
					all_selected=0
					break
				endif
			wend

			rem --- Calculate quantities     
			if qty_to_issue<>0 then
				sfe_womastr_dev=fnget_dev("SFE_WOMASTR")
				dim sfe_womastr$:fnget_tpl$("SFE_WOMASTR")
				sfe_womatl_dev=fnget_dev("SFE_WOMATL")

				findrecord(sfe_womastr_dev,key=firm_id$+"  "+callpoint!.getColumnData("SFE_WOMATISH.WO_NO"))sfe_womastr$

				read(sfe_womatisd_dev,key=firm_loc_wo$,knum="AO_DISP_SEQ",dom=*next)
				while 1
					sfe_womatisd_key$=key(sfe_womatisd_dev,end=*break)
					if pos(firm_loc_wo$=sfe_womatisd_key$)<>1 then break
					extractrecord(sfe_womatisd_dev)sfe_womatisd$

					dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")
					findrecord(sfe_womatl_dev,key=firm_loc_wo$+sfe_womatisd.womatdtl_seq_ref$,knum="AO_MAT_SEQ",dom=*next)sfe_womatl$
					if sfe_womatl.oper_seq_ref$="" then continue

					rem --- Was this operation selected?
					if !all_selected then
						oprtn_selected=0
						iter!=selected_ops!.keySet().iterator()
						while iter!.hasNext()
							op_seq$=iter!.next()
							if selected_ops!.get(op_seq$)="" then continue
							if selected_ops!.get(op_seq$)=sfe_womatl.oper_seq_ref$ then
								oprtn_selected=1
								break
							endif
						wend
						if !oprtn_selected then
							read (sfe_womatisd_dev)
							continue
						endif
					endif

					dim ivm_itemwhse$:ivm_itemwhse_tpl$
					findrecord(ivm_itemwhse_dev,key=firm_id$+sfe_womatisd.warehouse_id$+sfe_womatisd.item_id$,dom=*next)ivm_itemwhse$

					if sfe_womastr.sch_prod_qty=0 then sfe_womastr.sch_prod_qty=1
					sfe_womatisd.qty_issued=min(sfe_womatisd.qty_ordered-sfe_womatisd.tot_qty_iss,sfe_womatisd.qty_ordered*qty_to_issue/sfe_womastr.sch_prod_qty)
					sfe_womatisd.issue_cost=ivm_itemwhse.unit_cost

					writerecord(sfe_womatisd_dev)sfe_womatisd$
				wend
			endif

		endif

		sfe_wotrans_dev=fnget_dev("SFE_WOTRANS")
		dim sfe_wotrans$:fnget_tpl$("SFE_WOTRANS")
		sfe_wotrans.firm_id$=firm_id$
		sfe_wotrans.wo_location$=sfe_womatish.wo_location$
		sfe_wotrans.wo_no$=sfe_womatish.wo_no$
		writerecord(sfe_wotrans_dev)sfe_wotrans$

	        rem --- Reload and display with new detail
		sfe_womatish_key$=callpoint!.getDevObject("sfe_womatish_key")
		callpoint!.setStatus("RECORD:["+sfe_womatish_key$+"]")
	endif
[[SFE_WOMATISH.ISSUED_DATE.BINP]]
rem -- Verify WO status
	gosub verify_wo_status
	if bad_wo then break
[[SFE_WOMATISH.<CUSTOM>]]
#include std_missing_params.src

verify_wo_status: rem -- Verify WO status
	status$=callpoint!.getColumnData("<<DISPLAY>>.WO_STATUS")
	bad_wo=0

	if status$="C" then
		msg_id$="WO_CLOSED"
		gosub disp_message
		callpoint!.setStatus("NEWREC")
		bad_wo=1
	endif

	if !bad_wo and pos(status$="PQ") then
		msg_id$="WO_NOT_RELEASED"
		gosub disp_message
		callpoint!.setStatus("NEWREC")
		bad_wo=1
	endif

	return
[[SFE_WOMATISH.BSHO]]
rem --- Init Java classes

	use java.util.HashMap
	use java.util.Iterator

rem --- Open Files
	num_files=14
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="IVS_PARAMS",open_opts$[2]="OTA"
	open_tables$[3]="SFE_WOMASTR",open_opts$[3]="OTA"
	open_tables$[4]="SFE_WOOPRTN",open_opts$[4]="OTA"
	open_tables$[5]="SFE_OPENEDWO",open_opts$[5]="OTA"
	open_tables$[6]="SFE_WOCOMMIT",open_opts$[6]="OTA"
	open_tables$[7]="SFE_WOTRANS",open_opts$[7]="OTA"
	open_tables$[8]="SFE_WOMATHDR",open_opts$[8]="OTA"
	open_tables$[9]="SFE_WOMATDTL",open_opts$[9]="OTA"
	open_tables$[10]="SFE_WOMATL",open_opts$[10]="OTA"
	open_tables$[11]="SFC_OPRTNCOD",open_opts$[11]="OTA"
	open_tables$[12]="SFC_WOTYPECD",open_opts$[12]="OTA"
	open_tables$[13]="IVM_ITEMMAST",open_opts$[13]="OTA"
	open_tables$[14]="IVM_ITEMWHSE",open_opts$[14]="OTA"

	gosub open_tables

	sfs_params_dev=num(open_chans$[1]),sfs_params_tpl$=open_tpls$[1]
	ivs_params_dev=num(open_chans$[2]),ivs_params_tpl$=open_tpls$[2]
	sfe_womastr_dev=num(open_chans$[3]),sfe_womastr_tpl$=open_tpls$[3]
	callpoint!.setDevObject("opcode_dev",num(open_chans$[11]))
	callpoint!.setDevObject("opcode_tpl",open_tpls$[11])

rem --- Get SF parameters
	dim sfs_params$:sfs_params_tpl$
	read record (sfs_params_dev,key=firm_id$+"SF00",dom=std_missing_params) sfs_params$
	bm$=sfs_params.bm_interface$
	gl$=sfs_params.post_to_gl$

	if bm$="Y"
		call stbl("+DIR_PGM")+"adc_application.aon","BM",info$[all]
		bm$=info$[20]
	endif
	callpoint!.setDevObject("bm",bm$)

	if gl$="Y"
		gl$="N"
		status=0
		source$=pgm(-2)
		call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"SF",glw11$,gl$,status
		if status<>0 goto std_exit
	endif
	callpoint!.setDevObject("gl",gl$)

rem --- Get IV parameters
	dim ivs_params$:ivs_params_tpl$
	read record (ivs_params_dev,key=firm_id$+"IV00",dom=std_missing_params) ivs_params$
	lotser$=ivs_params.lotser_flag$
	callpoint!.setDevObject("lotser",lotser$)
	precision$=ivs_params.precision$
	callpoint!.setDevObject("precision",precision$)
	precision num(precision$)

rem --- Additional file opens
	num_files=4
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	if bm$="Y" then
		open_tables$[1]="BMC_OPCODES",open_opts$[1]="OTA"
	else
		open_tables$[1]="SFC_OPRTNCOD",open_opts$[1]="OTA"
	endif
	if pos(lotser$="LS") then
		open_tables$[2]="SFE_WOLSISSU",open_opts$[2]="OTA"
		open_tables$[3]="IVM_LSMASTER",open_opts$[3]="OTA"
		open_tables$[4]="IVM_LSACT",open_opts$[4]="OTA"
	endif

	gosub open_tables

	if bm$="Y" then
		callpoint!.setDevObject("opcode_dev",num(open_chans$[1]))
		callpoint!.setDevObject("opcode_tpl",open_tpls$[1])
	endif
	if pos(lotser$="LS") then
		sfe_wolsissu_dev=num(open_chans$[2]),sfe_wolsissu_tpl$=open_tpls$[2]
		ivm_lsmaster_dev=num(open_chans$[3]),ivm_lsmaster_tpl$=open_tpls$[3]
		ivm_lsact_dev=num(open_chans$[4]),ivm_lsact_tpl$=open_tpls$[4]
	endif

rem --- Other inits for sfe_womatisd
	callpoint!.setDevObject("ls_lookup_row",-1)
[[SFE_WOMATISH.ARNF]]
rem --- Init new Materials Issues Entry record
	sfe_womastr_dev=fnget_dev("SFE_WOMASTR")
	dim sfe_womastr$:fnget_tpl$("SFE_WOMASTR")

	findrecord(sfe_womastr_dev,key=firm_id$+"  "+callpoint!.getColumnData("SFE_WOMATISH.WO_NO"))sfe_womastr$

	callpoint!.setColumnData("SFE_WOMATISH.WO_TYPE",sfe_womastr.wo_type$,1)
	callpoint!.setColumnData("SFE_WOMATISH.ITEM_ID",sfe_womastr.item_id$,1)
	callpoint!.setColumnData("<<DISPLAY>>.DESCRIPTION_01",sfe_womastr.description_01$,1)
	callpoint!.setColumnData("<<DISPLAY>>.DESCRIPTION_02",sfe_womastr.description_02$,1)
	callpoint!.setColumnData("<<DISPLAY>>.WO_STATUS",sfe_womastr.wo_status$,1)
	callpoint!.setColumnData("SFE_WOMATISH.WO_CATEGORY",sfe_womastr.wo_category$,1)
	callpoint!.setColumnData("SFE_WOMATISH.WAREHOUSE_ID",sfe_womastr.warehouse_id$,1)
	callpoint!.setColumnData("SFE_WOMATISH.UNIT_MEASURE",sfe_womastr.unit_measure$,1)
	callpoint!.setColumnData("SFE_WOMATISH.ISSUED_DATE","",1)

	rem --- Default issued_date to today
	dim sysinfo$:stbl("+SYSINFO_TPL")
	sysinfo$=stbl("+SYSINFO")
	callpoint!.setColumnData("SFE_WOMATISH.ISSUED_DATE",sysinfo.system_date$,1)
	callpoint!.setStatus("MODIFIED")

rem --- Hold on to the Warehouse ID and Issued Date
	callpoint!.setDevObject("warehouse_id",sfe_womastr.warehouse_id$)
	callpoint!.setDevObject("issued_date",sysinfo.system_date$)
