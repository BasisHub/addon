[[SFR_SCHEDWO.BEND]]
rem --- Clear sched_method to signal sfe_womastr that sfr_schedwo was exited without scheduling
	callpoint!.setDevObject("sched_method","")
[[SFR_SCHEDWO.ESTSTT_DATE.AVAL]]
rem --- Completion date can't be before start date
	if callpoint!.getColumnData("SFR_SCHEDWO.ESTCMP_DATE")<>"" and
:	callpoint!.getColumnData("SFR_SCHEDWO.ESTCMP_DATE")<callpoint!.getUserInput() then
		msg_id$="SF_ESTCMP_B4_ESTSTT"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif
[[SFR_SCHEDWO.ESTCMP_DATE.AVAL]]
rem --- Start date can't be after completion date
	if callpoint!.getColumnData("SFR_SCHEDWO.ESTSTT_DATE")<>"" and
:	callpoint!.getColumnData("SFR_SCHEDWO.ESTSTT_DATE")>callpoint!.getUserInput() then
		msg_id$="SF_ESTCMP_B4_ESTSTT"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif
[[SFR_SCHEDWO.SCHED_FLAG.AVAL]]
rem --- Set default Start and Completion Date for Manual

	if callpoint!.getColumnData("SFR_SCHEDWO.SCHED_FLAG")<>callpoint!.getUserInput() then
		ivm_itemwhse=fnget_dev("IVM_ITEMWHSE")
		dim ivm_itemwhse$:fnget_tpl$("IVM_ITEMWHSE")
		read record (ivm_itemwhse,key=firm_id$+callpoint!.getDevObject("default_wh")+
:			callpoint!.getDevObject("item_id"),dom=*next)ivm_itemwhse$
		new_date$=""
		leadtime=ivm_itemwhse.lead_time
		call stbl("+DIR_PGM")+"adc_daydates.aon",stbl("+SYSTEM_DATE"),new_date$,leadtime
		if new_date$<>"N"
			callpoint!.setColumnData("SFR_SCHEDWO.ESTSTT_DATE",stbl("+SYSTEM_DATE"),1)
			callpoint!.setColumnData("SFR_SCHEDWO.ESTCMP_DATE",new_date$,1)
			switch pos(callpoint!.getUserInput()="MFB")
				case 1
					callpoint!.setColumnData("SFR_SCHEDWO.ESTSTT_DATE",stbl("+SYSTEM_DATE"),1)
					callpoint!.setColumnData("SFR_SCHEDWO.ESTCMP_DATE",new_date$,1)
					break
				case 2
					callpoint!.setColumnData("SFR_SCHEDWO.ESTSTT_DATE",stbl("+SYSTEM_DATE"),1)
					callpoint!.setColumnData("SFR_SCHEDWO.ESTCMP_DATE","",1)
					break
				case 3
					callpoint!.setColumnData("SFR_SCHEDWO.ESTSTT_DATE","",1)
					callpoint!.setColumnData("SFR_SCHEDWO.ESTCMP_DATE",new_date$,1)
					break
				case default
					callpoint!.setColumnData("SFR_SCHEDWO.ESTSTT_DATE","",1)
					callpoint!.setColumnData("SFR_SCHEDWO.ESTCMP_DATE","",1)
					break
			swend
		endif
	endif
[[SFR_SCHEDWO.BSHO]]
rem --- set default DevObjects
	callpoint!.setDevObject("start_date","")
	callpoint!.setDevObject("comp_date","")
	callpoint!.setDevObject("sched_method","")

rem --- Open Files
	num_files=4
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFE_WOSCHDL",open_opts$[1]="OTA[1]"
	open_tables$[2]="SFE_WOOPRTN",open_opts$[2]="OTA[1]"
	open_tables$[3]="SFE_WOMATL",open_opts$[3]="OTA[1]"
	open_tables$[4]="SFE_WOMATDTL",open_opts$[4]="OTA[1]"

	gosub open_tables
[[SFR_SCHEDWO.ASVA]]
rem --- Calculate dates
	gosub calc_dates

	if status$(2,1)<>"0" then
		rem " --- Error calculating date
		callpoint!.setStatus("ABORT")
		break
	else
		rem --- Write/update records with new dates
		eststt_date$=callpoint!.getColumnData("SFR_SCHEDWO.ESTSTT_DATE")
		estcmp_date$=callpoint!.getColumnData("SFR_SCHEDWO.ESTCMP_DATE")
		sched_flag$=callpoint!.getColumnData("SFR_SCHEDWO.SCHED_FLAG")
		wo_no$=callpoint!.getDevObject("wo_no")
		wo_location$=callpoint!.getDevObject("wo_location")

		rem --- Save new dates for sfe_womastr
		callpoint!.setDevObject("start_date",eststt_date$)
		callpoint!.setDevObject("comp_date",estcmp_date$)
		callpoint!.setDevObject("sched_method",sched_flag$)

		rem --- Used Manual scheduling
		if sched_flag$="M" then
			sfe_woschdl1_dev=fnget_dev("1SFE_WOSCHDL")
			dim sfe_woschdl1$:fnget_tpl$("1SFE_WOSCHDL")
			sfe_wooprtn1_dev=fnget_dev("1SFE_WOOPRTN")
			dim sfe_wooprtn1$:fnget_tpl$("1SFE_WOOPRTN")
			opcode_dev=callpoint!.getDevObject("opcode_chan")
			opcode_tpl$=callpoint!.getDevObject("opcode_tpl")

			rem --- Clear old sfe_woschdl records
			while 1
				read(sfe_woschdl1_dev,key=firm_id$+wo_no$,knum="AON_WONUM",dom=*next)
				extractrecord(sfe_woschdl1_dev,end=*break)sfe_woschdl1$; rem --- Advisory locking
				if firm_id$+wo_no$<>sfe_woschdl1.firm_id$+sfe_woschdl1.wo_no$ then read(sfe_woschdl1_dev); break
				remove (sfe_woschdl1_dev,key=sfe_woschdl1.firm_id$+sfe_woschdl1.op_code$+sfe_woschdl1.sched_date$+sfe_woschdl1.wo_no$+sfe_woschdl1.oper_seq_ref$,dom=*next)
			wend

			rem --- Process operation records
			read(sfe_wooprtn1_dev,key=firm_id$+wo_location$+wo_no$,dom=*next)
			while 1
				rem --- Write/update sfe_wooprtn
				sfe_wooprtn1_key$=key(sfe_wooprtn1_dev,end=*break)
				if pos(firm_id$+wo_location$+wo_no$=sfe_wooprtn1_key$)<>1 then break
				extractrecord(sfe_wooprtn1_dev)sfe_wooprtn1$; rem --- Advisory locking
				sfe_wooprtn1.require_date$=eststt_date$
				writerecord(sfe_wooprtn1_dev)sfe_wooprtn1$

				rem --- Write/update sfe_wooschdl
				dim opcode$:opcode_tpl$
				findrecord(opcode_dev,key=firm_id$+sfe_wooprtn1.op_code$,dom=*continue)opcode$
				dim sfe_woschdl1$:fattr(sfe_woschdl1$)
				sfe_woschdl1.firm_id$=firm_id$
				sfe_woschdl1.op_code$=sfe_wooprtn1.op_code$
				sfe_woschdl1.sched_date$=sfe_wooprtn1.require_date$
				sfe_woschdl1.wo_no$=sfe_wooprtn1.wo_no$
				sfe_woschdl1.oper_seq_ref$=sfe_wooprtn1.internal_seq_no$
				sfe_woschdl1.queue_time=opcode.queue_time
				sfe_woschdl1.setup_time=sfe_wooprtn1.setup_time
				sfe_woschdl1.runtime_hrs=sfe_wooprtn1.total_time-sfe_wooprtn1.setup_time
				sfe_woschdl1.move_time=sfe_wooprtn1.move_time
				writerecord(sfe_woschdl1_dev)sfe_woschdl1$
			wend
		endif

		rem --- Write/update sfe_womatl
		sfe_womatl1_dev=fnget_dev("1SFE_WOMATL")
		dim sfe_womatl1$:fnget_tpl$("1SFE_WOMATL")
		read(sfe_womatl1_dev,key=firm_id$+wo_location$+wo_no$,dom=*next)
		while 1
			sfe_womatl1_key$=key(sfe_womatl1_dev,end=*break)
			if pos(firm_id$+wo_location$+wo_no$=sfe_womatl1_key$)<>1 then break
			extractrecord(sfe_womatl1_dev)sfe_womatl1$; rem --- Advisory locking
			sfe_womatl1.require_date$=eststt_date$
			writerecord(sfe_womatl1_dev)sfe_womatl1$
		wend

		rem --- Write/update sfe_womatdtl
		sfe_womatdtl1_dev=fnget_dev("1SFE_WOMATDTL")
		dim sfe_womatdtl1$:fnget_tpl$("1SFE_WOMATDTL")
		read(sfe_womatdtl1_dev,key=firm_id$+wo_location$+wo_no$,dom=*next)
		while 1
			sfe_womatdtl1_key$=key(sfe_womatdtl1_dev,end=*break)
			if pos(firm_id$+wo_location$+wo_no$=sfe_womatdtl1_key$)<>1 then break
			extractrecord(sfe_womatdtl1_dev)sfe_womatdtl1$; rem --- Advisory locking
			sfe_womatdtl1.require_date$=eststt_date$
			writerecord(sfe_womatdtl1_dev)sfe_womatdtl1$
		wend
	endif
[[SFR_SCHEDWO.<CUSTOM>]]
rem --- Calculate Estimated Start/Completion Date"
rem ========================================================
calc_dates:
rem ========================================================

	status$="00"
	sched_flag$=callpoint!.getColumnData("SFR_SCHEDWO.SCHED_FLAG")
	wo_no$=callpoint!.getDevObject("wo_no")
	start_date$=callpoint!.getColumnData("SFR_SCHEDWO.ESTSTT_DATE")
	end_date$=callpoint!.getColumnData("SFR_SCHEDWO.ESTCMP_DATE")

	if sched_flag$<>"M"
		if sched_flag$="F"
			f_date$=start_date$
		else
			f_date$=end_date$
		endif
		opcode_dev=callpoint!.getDevObject("opcode_chan")
		opcode_tpl$=callpoint!.getDevObject("opcode_tpl")
		call "sfc_schdayfore.aon",wo_no$,f_date$,new_date$,sched_flag$,opcode_dev,status$,opcode_tpl$

		if status$(1,1)="1"
			msg_id$="SF_SUB_CHANGED"
			gosub disp_message
		endif
		if status$(2,1)<>"0"
			if status$(2,1)="1"
				msg_id$="SF_UNSCHED_DATE"
				gosub disp_message
			endif
			if status$(2,1)="3"
				msg_id$="SF_MISSING_FILE"
				gosub disp_message
			endif
			if status$(2,1)="5"
				msg_id$="SF_UNSCHED_DATE_SUB"
				gosub disp_message
			endif
		else
			if sched_flag$="F"
				callpoint!.setColumnData("SFR_SCHEDWO.ESTCMP_DATE",new_date$,1)
			else
				callpoint!.setColumnData("SFR_SCHEDWO.ESTSTT_DATE",new_date$,1)
			endif
		endif
	endif

	return
