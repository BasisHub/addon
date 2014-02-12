rem ----------------------------------------------------------------------------
rem Program: SFHARDCOPYCOSTSUM.prc
rem Description: Stored Procedure to get the Shop Floor Hard Copy Cost Summary info into iReports
rem Used for Hard Copy, Traveler, Work Order Closed Detail and Work Order Detail
rem
rem Author(s): J. Brewer
rem Revised: 04.26.2012
rem
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

developing=0; rem Set to 1 to turn on test pattern printing for development/debug

seterr sproc_error

rem --- Set of utility methods

	use ::ado_func.src::func

rem --- Declare some variables ahead of time

	declare BBjStoredProcedureData sp!
	declare BBjRecordSet rs!
	declare BBjRecordData data!

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get the IN parameters used by the procedure

	firm_id$ = sp!.getParameter("FIRM_ID")
	wo_loc$  = sp!.getParameter("WO_LOCATION")
	wo_no$ = sp!.getParameter("WO_NO")
	barista_wd$ = sp!.getParameter("BARISTA_WD")
	masks$ = sp!.getParameter("MASKS")
	prod_qty = num(sp!.getParameter("PROD_QTY"))
	
rem --- masks$ will contain pairs of fields in a single string mask_name^mask|

	if len(masks$)>0
		if masks$(len(masks$),1)<>"|"
			masks$=masks$+"|"
		endif
	endif
	
	sv_wd$=dir("")
	chdir barista_wd$

rem --- Create a memory record set to hold results.
rem --- Columns for the record set are defined using a string template
	
	temp$=""
	temp$=temp$+"REF_NO:C(1*), OP_CODE:C(1*), DESC:C(1*), "
	temp$=temp$+"STD_HRS:C(1*), ACT_HRS:C(1*), VAR_HRS:C(1*), VAR_HRS_PCT:C(1*), "
	temp$=temp$+"STD_AMT:C(1*), ACT_AMT:C(1*), VAR_AMT:C(1*), VAR_AMT_PCT:C(1*), "
	temp$=temp$+"THIS_IS_TOTAL_LINE:C(1*), TOTAL_LABEL:C(1*) "

	rs! = BBJAPI().createMemoryRecordSet(temp$)

rem --- Get Barista System Program directory

	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)

rem --- Get masks

	pgmdir$=stbl("+DIR_PGM",err=*next)

	iv_cost_mask$=fngetmask$("iv_cost_mask","###,##0.0000-",masks$)
	sf_hours_mask$=fngetmask$("sf_hours_mask","#,##0.00-",masks$)
	sf_pct_mask$=fngetmask$("sf_pct_mask","###.00-",masks$)
	
	
rem --- Init totals

	tot_std_dir=0
	tot_std_oh=0
	tot_act_dir=0
	tot_act_oh=0
	wo_tot_std_hrs=0
	wo_tot_act_hrs=0
	wo_tot_std_amt=0
	wo_tot_act_amt=0

rem --- Open files with adc

    files=8,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
	files$[1]="sfs_params",ids$[1]="SFS_PARAMS"
	files$[2]="sft-23",ids$[2]="SFT_CLSMATTR"
	files$[3]="sft-03",ids$[3]="SFT_CLSOPRTR"
	files$[4]="sft-33",ids$[4]="SFT_CLSSUBTR"
	files$[5]="sft-21",ids$[5]="SFT_OPNMATTR"
	files$[6]="sft-01",ids$[6]="SFT_OPNOPRTR"
	files$[7]="sft-31",ids$[7]="SFT_OPNSUBTR"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif

	sfs_params=channels[1]
	sft_clsmattr=channels[2]
	sft_clsoprtr=channels[3]
	sft_clssubtr=channels[4]
	sft_opnmattr=channels[5]
	sft_opnoprtr=channels[6]
	sft_opnsubtr=channels[7]
	
rem --- Dimension string templates

	dim sfs_params$:templates$[1]
	dim sft_clsmattr$:templates$[2]
	dim sft_clsoprtr$:templates$[3]
	dim sft_clssubtr$:templates$[4]
	dim sft_opnmattr$:templates$[5]
	dim sft_opnoprtr$:templates$[6]
	dim sft_opnsubtr$:templates$[7]
	
goto no_bac_open
rem --- Open Files    
    num_files = 8
    dim open_tables$[1:num_files], open_opts$[1:num_files], open_chans$[1:num_files], open_tpls$[1:num_files]

	open_tables$[1]="SFS_PARAMS",     open_opts$[1] = "OTA"
rem 	open_tables$[2]="SFT_CLSMATTR",     open_opts$[2] = "OTA"
rem 	open_tables$[3]="SFT_CLSOPRTR",     open_opts$[3] = "OTA"
rem 	open_tables$[4]="SFT_CLSSUBTR",     open_opts$[4] = "OTA"
rem 	open_tables$[5]="SFT_OPNMATTR",     open_opts$[5] = "OTA"
rem 	open_tables$[6]="SFT_OPNOPRTR",     open_opts$[6] = "OTA"
rem 	open_tables$[7]="SFT_OPNSUBTR",     open_opts$[7] = "OTA"
	
call sypdir$+"bac_open_tables.bbj",
:       open_beg,
:		open_end,
:		open_tables$[all],
:		open_opts$[all],
:		open_chans$[all],
:		open_tpls$[all],
:		table_chans$[all],
:		open_batch,
:		open_status$
    if open_status$<>"" then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif

	sfs_params = num(open_chans$[1])
rem 	sft_clsmattr=num(open_chans$[2])
rem 	sft_clsoprtr=num(open_chans$[3])
rem 	sft_clssubtr=num(open_chans$[4])
rem 	sft_opnmattr=num(open_chans$[5])
rem 	sft_opnoprtr=num(open_chans$[6])
rem 	sft_opnsubtr=num(open_chans$[7])
	
	dim sfs_params$:open_tpls$[1]
rem 	dim sft_clsmattr$:open_tpls$[2]
rem 	dim sft_clsoprtr$:open_tpls$[3]
rem 	dim sft_clssubtr$:open_tpls$[4]
rem 	dim sft_opnmattr$:open_tpls$[5]
rem 	dim sft_opnoprtr$:open_tpls$[6]
rem 	dim sft_opnsubtr$:open_tpls$[7]
no_bac_open:

rem --- Get proper Op Code Maintenance table

	read record (sfs_params,key=firm_id$+"SF00") sfs_params$
	bm$=sfs_params.bm_interface$
	if bm$<>"Y"
		files$[8]="sfm-02",ids$[8]="SFC_OPRTNCOD"
rem		open_tables$[5]="SFC_OPRTNCOD",open_opts$[5]="OTA"
	else
		files$[8]="bmm-08",ids$[8]="BMC_OPCODES"
rem		open_tables$[5]="BMC_OPCODES",open_opts$[5]="OTA"
	endif
    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif
	
	opcode_dev=channels[8]
	dim opcode_tpl$:templates$[8]

rem --- Process Operations (One line per op seq on WO, followed by Dir and Ovhd totals, and WO tots)
rem ---      NOTE: Op req totals are by internal_seq so that 
rem ---            Ops that are repeated on WOs are repeated by line here

	rem --- Build SQL statement for Operations

		sql_prep$=""
		 
		sql_prep$=sql_prep$+"SELECT std.op_code "+$0a$
		sql_prep$=sql_prep$+"     , std.code_desc "+$0a$
		sql_prep$=sql_prep$+"     , std.total_time "+$0a$
		sql_prep$=sql_prep$+"     , std.tot_std_cost "+$0a$
		sql_prep$=sql_prep$+"     , std.direct_rate  "+$0a$
		sql_prep$=sql_prep$+"     , std.ovhd_rate "+$0a$
		sql_prep$=sql_prep$+"     , std.wo_op_ref "+$0a$
		sql_prep$=sql_prep$+"     , acto.op_hours   AS acto_ops_hrs "+$0a$
		sql_prep$=sql_prep$+"     , acto.op_amt     AS acto_ops_amt "+$0a$
		sql_prep$=sql_prep$+"     , acto.op_dir_amt AS acto_ops_dir_amt "+$0a$
		sql_prep$=sql_prep$+"     , acto.op_oh_amt  AS acto_ops_oh_amt "+$0a$
		sql_prep$=sql_prep$+"     , actc.op_hours   AS actc_ops_hrs "+$0a$
		sql_prep$=sql_prep$+"     , actc.op_amt     AS actc_ops_amt "+$0a$
		sql_prep$=sql_prep$+"     , actc.op_dir_amt AS actc_ops_dir_amt "+$0a$
		sql_prep$=sql_prep$+"     , actc.op_oh_amt  AS actc_ops_oh_amt "+$0a$
		sql_prep$=sql_prep$+"  FROM (SELECT firm_id "+$0a$
		sql_prep$=sql_prep$+"             , wo_location "+$0a$
		sql_prep$=sql_prep$+"             , wo_no "+$0a$
		sql_prep$=sql_prep$+"             , op_seq "+$0a$
		sql_prep$=sql_prep$+"             , internal_seq_no "+$0a$
		sql_prep$=sql_prep$+"             , op_code "+$0a$
		sql_prep$=sql_prep$+"             , code_desc "+$0a$
		sql_prep$=sql_prep$+"             , wo_op_ref "+$0a$
		sql_prep$=sql_prep$+"             , total_time "+$0a$
		sql_prep$=sql_prep$+"             , tot_std_cost "+$0a$
		sql_prep$=sql_prep$+"             , direct_rate  "+$0a$
		sql_prep$=sql_prep$+"             , ovhd_rate "+$0a$
		sql_prep$=sql_prep$+"          FROM sfe_wooprtn "+$0a$
		sql_prep$=sql_prep$+"         WHERE firm_id = '"+firm_id$+"' "+$0a$
		sql_prep$=sql_prep$+"           AND wo_location = '"+wo_loc$+"' "+$0a$
		sql_prep$=sql_prep$+"           AND wo_no = '"+wo_no$+"'"+$0a$
		sql_prep$=sql_prep$+"           AND line_type = 'S' "+$0a$		
		sql_prep$=sql_prep$+"       ) AS std "+$0a$
		sql_prep$=sql_prep$+"LEFT JOIN (SELECT firm_id "+$0a$
		sql_prep$=sql_prep$+"                , wo_location "+$0a$
		sql_prep$=sql_prep$+"                , wo_no "+$0a$
		sql_prep$=sql_prep$+"                , oper_seq_ref "+$0a$
		sql_prep$=sql_prep$+"                , SUM(units+setup_time)  AS op_hours "+$0a$
		sql_prep$=sql_prep$+"                , SUM(ext_cost)          AS op_amt "+$0a$
		sql_prep$=sql_prep$+"                , SUM(units*direct_rate) AS op_dir_amt "+$0a$
		sql_prep$=sql_prep$+"                , SUM(ext_cost-(units*direct_rate)) AS op_oh_amt "+$0a$
		sql_prep$=sql_prep$+"             FROM sft_opnoprtr  "+$0a$
		sql_prep$=sql_prep$+"            WHERE firm_id = '"+firm_id$+"' "+$0a$
		sql_prep$=sql_prep$+"              AND wo_location = '"+wo_loc$+"' "+$0a$
		sql_prep$=sql_prep$+"              AND wo_no = '"+wo_no$+"'"+$0a$
		sql_prep$=sql_prep$+"           GROUP BY firm_id,wo_location,wo_no,oper_seq_ref "+$0a$
		sql_prep$=sql_prep$+"          ) AS acto "+$0a$
		sql_prep$=sql_prep$+"       ON std.firm_id=acto.firm_id "+$0a$
		sql_prep$=sql_prep$+"      AND std.wo_location=acto.wo_location "+$0a$
		sql_prep$=sql_prep$+"      AND std.wo_no=acto.wo_no "+$0a$
		sql_prep$=sql_prep$+"      AND std.internal_seq_no=acto.oper_seq_ref "+$0a$
		sql_prep$=sql_prep$+"LEFT JOIN (SELECT firm_id "+$0a$
		sql_prep$=sql_prep$+"                , wo_location "+$0a$
		sql_prep$=sql_prep$+"                , wo_no "+$0a$
		sql_prep$=sql_prep$+"                , oper_seq_ref "+$0a$
		sql_prep$=sql_prep$+"                , SUM(units+setup_time)  AS op_hours "+$0a$
		sql_prep$=sql_prep$+"                , SUM(ext_cost)          AS op_amt "+$0a$
		sql_prep$=sql_prep$+"                , SUM(units*direct_rate) AS op_dir_amt "+$0a$
		sql_prep$=sql_prep$+"                , SUM(ext_cost-(units*direct_rate)) AS op_oh_amt "+$0a$
		sql_prep$=sql_prep$+"             FROM sft_clsoprtr  "+$0a$
		sql_prep$=sql_prep$+"            WHERE firm_id = '"+firm_id$+"' "+$0a$
		sql_prep$=sql_prep$+"              AND wo_location = '"+wo_loc$+"' "+$0a$
		sql_prep$=sql_prep$+"              AND wo_no = '"+wo_no$+"'"+$0a$
		sql_prep$=sql_prep$+"           GROUP BY firm_id,wo_location,wo_no,oper_seq_ref "+$0a$
		sql_prep$=sql_prep$+"          ) AS actc "+$0a$
		sql_prep$=sql_prep$+"       ON std.firm_id=actc.firm_id "+$0a$
		sql_prep$=sql_prep$+"      AND std.wo_location=actc.wo_location "+$0a$
		sql_prep$=sql_prep$+"      AND std.wo_no=actc.wo_no "+$0a$
		sql_prep$=sql_prep$+"      AND std.internal_seq_no=actc.oper_seq_ref "+$0a$
		sql_prep$=sql_prep$+"WHERE std.firm_id = '"+firm_id$+"' "+$0a$
		sql_prep$=sql_prep$+"  AND std.wo_location = '"+wo_loc$+"' "+$0a$
		sql_prep$=sql_prep$+"  AND std.wo_no = '"+wo_no$+"'"+$0a$
		
		sql_chan=sqlunt
		sqlopen(sql_chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
		sqlprep(sql_chan)sql_prep$
		
		dim read_tpl$:sqltmpl(sql_chan)
		sqlexec(sql_chan)
		
	rem --- Read through Ops record set; output Operation line totals
		while 1
			read_tpl$ = sqlfetch(sql_chan,end=*break)
			
			rem --- Assign from read_tpl so references are consolidated here to ease potential mods to SQL
				op_code$=read_tpl.op_code$
				op_code_desc$=read_tpl.code_desc$
				
				rem --- Standards
				std_ops_dir_rate=read_tpl.direct_rate
				std_ops_oh_rate=read_tpl.ovhd_rate
				
				std_ops_tot_time=read_tpl.total_time
				std_ops_amt=read_tpl.tot_std_cost
				
				rem --- Actuals
				act_ops_hrs=read_tpl.acto_ops_hrs+read_tpl.actc_ops_hrs; rem **Open plus Closed
				act_ops_amt=read_tpl.acto_ops_amt+read_tpl.actc_ops_amt; rem **Open plus Closed
				
				act_ops_dir_amt=read_tpl.acto_ops_dir_amt+read_tpl.actc_ops_dir_amt; rem **Open plus Closed
				act_ops_oh_amt=read_tpl.acto_ops_oh_amt+read_tpl.actc_ops_oh_amt;    rem **Open plus Closed

			rem --- Output Operations data

			if developing 
				gosub send_test_pattern
				continue
			endif

			data! = rs!.getEmptyRecordData()

			data!.setFieldValue("THIS_IS_TOTAL_LINE","N")
			data!.setFieldValue("REF_NO",read_tpl.wo_op_ref$)
			data!.setFieldValue("OP_CODE",op_code$)
			data!.setFieldValue("DESC",op_code_desc$)		
			data!.setFieldValue("STD_HRS",str(std_ops_tot_time:sf_hours_mask$))
			
			data!.setFieldValue("ACT_HRS",str(act_ops_hrs:sf_hours_mask$))
			data!.setFieldValue("VAR_HRS",str(std_ops_tot_time-act_ops_hrs:sf_hours_mask$))
			if std_ops_tot_time<>0
				data!.setFieldValue("VAR_HRS_PCT",str((std_ops_tot_time-act_ops_hrs)/std_ops_tot_time*100:sf_pct_mask$))
			else
				data!.setFieldValue("VAR_HRS_PCT",str(0:sf_pct_mask$))
			endif
			data!.setFieldValue("STD_AMT",str(std_ops_amt:iv_cost_mask$))
			data!.setFieldValue("ACT_AMT",str(act_ops_amt:iv_cost_mask$))
			data!.setFieldValue("VAR_AMT",str(std_ops_amt-act_ops_amt:iv_cost_mask$))
			if std_ops_amt<>0
				data!.setFieldValue("VAR_AMT_PCT",str((std_ops_amt-act_ops_amt)/std_ops_amt*100:sf_pct_mask$))
			else
				data!.setFieldValue("VAR_AMT_PCT",str(0:sf_pct_mask$))
			endif
			rs!.insert(data!)

			rem --- Accum totals for Operations	
			tot_std_dir=tot_std_dir+std_ops_tot_time*std_ops_dir_rate
			tot_std_oh=tot_std_oh+std_ops_tot_time*std_ops_oh_rate
			tot_act_hrs=tot_act_hrs+act_ops_hrs
			tot_act_amt=tot_act_amt+act_ops_amt
			tot_act_dir=tot_act_dir+act_ops_dir_amt
			tot_act_oh=tot_act_oh+act_ops_oh_amt
			
			wo_tot_std_hrs=wo_tot_std_hrs+std_ops_tot_time
			wo_tot_act_hrs=wo_tot_act_hrs+act_ops_hrs
			wo_tot_std_amt=wo_tot_std_amt+std_ops_amt
			wo_tot_act_amt=wo_tot_act_amt+act_ops_amt
			wo_tot_act_dir=wo_tot_act_dir+act_ops_dir_amt
			wo_tot_act_oh=tot_act_oh+act_ops_oh_amt
			
		wend
	
	rem --- Output Ops Dir and Ovhd totals lines (Direct Total and Overhead Total) 
		
		data! = rs!.getEmptyRecordData()
		data!.setFieldValue("THIS_IS_TOTAL_LINE","Y")
		data!.setFieldValue("TOTAL_LABEL","Direct Total")
		data!.setFieldValue("STD_AMT",str(tot_std_dir:iv_cost_mask$))
		data!.setFieldValue("ACT_AMT",str(tot_act_dir:iv_cost_mask$))
		data!.setFieldValue("VAR_AMT",str(tot_std_dir-tot_act_dir:iv_cost_mask$))
		if tot_std_dir<>0
			data!.setFieldValue("VAR_AMT_PCT",str((tot_std_dir-tot_act_dir)/tot_std_dir*100:sf_pct_mask$))
		else
			data!.setFieldValue("VAR_AMT_PCT",str(0:sf_pct_mask$))
		endif
		rs!.insert(data!)

		data! = rs!.getEmptyRecordData()
		data!.setFieldValue("THIS_IS_TOTAL_LINE","Y")
		data!.setFieldValue("TOTAL_LABEL","Overhead Total")
		data!.setFieldValue("STD_AMT",str(tot_std_oh:iv_cost_mask$))
		data!.setFieldValue("ACT_AMT",str(tot_act_oh:iv_cost_mask$))
		data!.setFieldValue("VAR_AMT",str(tot_std_oh-tot_act_oh:iv_cost_mask$))
		if tot_std_oh<>0
			data!.setFieldValue("VAR_AMT_PCT",str((tot_std_oh-tot_act_oh)/tot_std_oh*100:sf_pct_mask$))
		else
			data!.setFieldValue("VAR_AMT_PCT",str(0:sf_pct_mask$))
		endif
		rs!.insert(data!)


	rem --- Output Ops WO total line (Labor Total)
		data! = rs!.getEmptyRecordData()
		data!.setFieldValue("THIS_IS_TOTAL_LINE","Y")
		data!.setFieldValue("TOTAL_LABEL","Labor Total")
		data!.setFieldValue("STD_AMT",str(tot_std_dir+tot_std_oh:iv_cost_mask$))
		data!.setFieldValue("ACT_AMT",str(tot_act_dir+tot_act_oh:iv_cost_mask$))
		data!.setFieldValue("VAR_AMT",str((tot_std_dir+tot_std_oh)-(tot_act_dir+tot_act_oh):iv_cost_mask$))
		if tot_std_dir+tot_std_oh<>0
			data!.setFieldValue("VAR_AMT_PCT",str(((tot_std_dir+tot_std_oh)-(tot_act_dir+tot_act_oh))/(tot_std_dir+tot_std_oh)*100:sf_pct_mask$))
		else
			data!.setFieldValue("VAR_AMT_PCT",str(0:sf_pct_mask$))
		endif
		rs!.insert(data!)

		data! = rs!.getEmptyRecordData()
		rs!.insert(data!)

rem --- Process Materials and Subcontracts (one total line for Mats one for Subs)

	rem --- Materials 
	rem --- One total line each so we can SUM() the recs
		sql_prep$=""

		sql_prep$=sql_prep$+"SELECT mstd.std_mat_amt "+$0a$
		sql_prep$=sql_prep$+"     , macto.acto_mat_amt "+$0a$
		sql_prep$=sql_prep$+"     , mactc.actc_mat_amt "+$0a$
		sql_prep$=sql_prep$+"  FROM (SELECT firm_id "+$0a$
		sql_prep$=sql_prep$+"             , wo_location "+$0a$
		sql_prep$=sql_prep$+"             , wo_no "+$0a$
		sql_prep$=sql_prep$+"             , SUM(total_cost) AS std_mat_amt "+$0a$
		sql_prep$=sql_prep$+"          FROM sfe_womatl "+$0a$
		sql_prep$=sql_prep$+"         WHERE firm_id = '"+firm_id$+"' "+$0a$
		sql_prep$=sql_prep$+"           AND wo_location = '"+wo_loc$+"' "+$0a$
		sql_prep$=sql_prep$+"           AND wo_no = '"+wo_no$+"'"+$0a$
		sql_prep$=sql_prep$+"           AND line_type = 'S' "+$0a$
		sql_prep$=sql_prep$+"        GROUP BY firm_id,wo_location,wo_no "	+$0a$
		sql_prep$=sql_prep$+"       ) AS mstd "+$0a$
		sql_prep$=sql_prep$+"LEFT JOIN (SELECT firm_id "+$0a$
		sql_prep$=sql_prep$+"                , wo_location "+$0a$
		sql_prep$=sql_prep$+"                , wo_no "+$0a$
		sql_prep$=sql_prep$+"                , SUM(ext_cost) AS acto_mat_amt "+$0a$
		sql_prep$=sql_prep$+"             FROM sft_opnmattr "+$0a$
		sql_prep$=sql_prep$+"            WHERE firm_id = '"+firm_id$+"' "+$0a$
		sql_prep$=sql_prep$+"              AND wo_location = '"+wo_loc$+"' "+$0a$
		sql_prep$=sql_prep$+"              AND wo_no = '"+wo_no$+"'"+$0a$
		sql_prep$=sql_prep$+"           GROUP BY firm_id,wo_location,wo_no "+$0a$
		sql_prep$=sql_prep$+"          ) AS macto "+$0a$
		sql_prep$=sql_prep$+"       ON mstd.firm_id=macto.firm_id "+$0a$
		sql_prep$=sql_prep$+"      AND mstd.wo_location=macto.wo_location "+$0a$
		sql_prep$=sql_prep$+"      AND mstd.wo_no=macto.wo_no "+$0a$
		sql_prep$=sql_prep$+"LEFT JOIN (SELECT firm_id "+$0a$
		sql_prep$=sql_prep$+"                , wo_location "+$0a$
		sql_prep$=sql_prep$+"                , wo_no "+$0a$
		sql_prep$=sql_prep$+"                , SUM(ext_cost) AS actc_mat_amt "+$0a$
		sql_prep$=sql_prep$+"             FROM sft_clsmattr "+$0a$
		sql_prep$=sql_prep$+"            WHERE firm_id = '"+firm_id$+"' "+$0a$
		sql_prep$=sql_prep$+"              AND wo_location = '"+wo_loc$+"' "+$0a$
		sql_prep$=sql_prep$+"              AND wo_no = '"+wo_no$+"'"+$0a$
		sql_prep$=sql_prep$+"           GROUP BY firm_id,wo_location,wo_no "+$0a$
		sql_prep$=sql_prep$+"          ) AS mactc "+$0a$
		sql_prep$=sql_prep$+"       ON mstd.firm_id=mactc.firm_id "+$0a$
		sql_prep$=sql_prep$+"      AND mstd.wo_location=mactc.wo_location "+$0a$
		sql_prep$=sql_prep$+"      AND mstd.wo_no=mactc.wo_no "+$0a$
		sql_prep$=sql_prep$+"WHERE mstd.firm_id = '"+firm_id$+"' "+$0a$
		sql_prep$=sql_prep$+"  AND mstd.wo_location = '"+wo_loc$+"' "+$0a$
		sql_prep$=sql_prep$+"  AND mstd.wo_no = '"+wo_no$+"'"+$0a$
		
		sqlclose(sql_chan)
		sql_chan=sqlunt
		sqlopen(sql_chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
		sqlprep(sql_chan)sql_prep$
		
		dim read_tpl$:sqltmpl(sql_chan)
		sqlexec(sql_chan)		
			
		read_tpl$ = sqlfetch(sql_chan,err=*next)
		
		rem --- Assign from read_tpl so references are consolidated here to ease potential mods to SQL
			
			rem --- Standards materials
			std_mat_amt=read_tpl.std_mat_amt
			
			rem --- Actuals materials
			act_mat_amt=read_tpl.acto_mat_amt+read_tpl.actc_mat_amt; rem **Open plus Closed

	rem --- Subcontract
	rem --- One total line each so we can SUM() the recs
		sql_prep$=""

		sql_prep$=sql_prep$+"SELECT sstd.std_sub_amt "+$0a$
		sql_prep$=sql_prep$+"     , sacto.acto_sub_amt "+$0a$
		sql_prep$=sql_prep$+"     , sactc.actc_sub_amt "+$0a$
		sql_prep$=sql_prep$+"  FROM (SELECT firm_id "+$0a$
		sql_prep$=sql_prep$+"             , wo_location "+$0a$
		sql_prep$=sql_prep$+"             , wo_no "+$0a$
		sql_prep$=sql_prep$+"             , SUM(total_cost) AS std_sub_amt "+$0a$
		sql_prep$=sql_prep$+"          FROM sfe_wosubcnt "+$0a$
		sql_prep$=sql_prep$+"         WHERE firm_id = '"+firm_id$+"' "+$0a$
		sql_prep$=sql_prep$+"           AND wo_location = '"+wo_loc$+"' "+$0a$
		sql_prep$=sql_prep$+"           AND wo_no = '"+wo_no$+"'"+$0a$
		sql_prep$=sql_prep$+"           AND line_type = 'S' "+$0a$
		sql_prep$=sql_prep$+"        GROUP BY firm_id,wo_location,wo_no "+$0a$
		sql_prep$=sql_prep$+"       ) AS sstd "+$0a$
		sql_prep$=sql_prep$+"LEFT JOIN (SELECT firm_id "+$0a$
		sql_prep$=sql_prep$+"                , wo_location "+$0a$
		sql_prep$=sql_prep$+"                , wo_no "+$0a$
		sql_prep$=sql_prep$+"                , SUM(ext_cost) AS acto_sub_amt "+$0a$
		sql_prep$=sql_prep$+"             FROM sft_opnsubtr "+$0a$
		sql_prep$=sql_prep$+"            WHERE firm_id = '"+firm_id$+"' "+$0a$
		sql_prep$=sql_prep$+"              AND wo_location = '"+wo_loc$+"' "+$0a$
		sql_prep$=sql_prep$+"              AND wo_no = '"+wo_no$+"'"+$0a$
		sql_prep$=sql_prep$+"           GROUP BY firm_id,wo_location,wo_no "+$0a$
		sql_prep$=sql_prep$+"          ) AS sacto "+$0a$
		sql_prep$=sql_prep$+"       ON sstd.firm_id=sacto.firm_id "+$0a$
		sql_prep$=sql_prep$+"      AND sstd.wo_location=sacto.wo_location "+$0a$
		sql_prep$=sql_prep$+"      AND sstd.wo_no=sacto.wo_no "+$0a$
		sql_prep$=sql_prep$+"LEFT JOIN (SELECT firm_id "+$0a$
		sql_prep$=sql_prep$+"                , wo_location "+$0a$
		sql_prep$=sql_prep$+"                , wo_no "+$0a$
		sql_prep$=sql_prep$+"                , SUM(ext_cost) AS actc_sub_amt "+$0a$
		sql_prep$=sql_prep$+"             FROM sft_clssubtr "+$0a$
		sql_prep$=sql_prep$+"            WHERE firm_id = '"+firm_id$+"' "+$0a$
		sql_prep$=sql_prep$+"              AND wo_location = '"+wo_loc$+"' "+$0a$
		sql_prep$=sql_prep$+"              AND wo_no = '"+wo_no$+"'"+$0a$
		sql_prep$=sql_prep$+"           GROUP BY firm_id,wo_location,wo_no "+$0a$
		sql_prep$=sql_prep$+"          ) AS sactc "+$0a$
		sql_prep$=sql_prep$+"       ON sstd.firm_id=sactc.firm_id "+$0a$
		sql_prep$=sql_prep$+"      AND sstd.wo_location=sactc.wo_location "+$0a$
		sql_prep$=sql_prep$+"      AND sstd.wo_no=sactc.wo_no "+$0a$
		sql_prep$=sql_prep$+"WHERE sstd.firm_id = '"+firm_id$+"' "+$0a$
		sql_prep$=sql_prep$+"  AND sstd.wo_location = '"+wo_loc$+"' "+$0a$
		sql_prep$=sql_prep$+"  AND sstd.wo_no = '"+wo_no$+"'"+$0a$		
	
		sqlclose(sql_chan)
		sql_chan=sqlunt
		sqlopen(sql_chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
		sqlprep(sql_chan)sql_prep$
		
		dim read_tpl$:sqltmpl(sql_chan)
		sqlexec(sql_chan)		
			
		read_tpl$ = sqlfetch(sql_chan,err=*next)
		
		rem --- Assign from read_tpl so references are consolidated here to ease potential mods to SQL
		
			rem --- Standards subcontracts
			std_sub_amt=read_tpl.std_sub_amt
			
			rem --- Actuals subcontracts
			act_sub_amt=read_tpl.acto_sub_amt+read_tpl.actc_sub_amt; rem **Open plus Closed
				
	rem --- Output materials and subcontract totals

		data! = rs!.getEmptyRecordData()
		data!.setFieldValue("THIS_IS_TOTAL_LINE","Y")
		data!.setFieldValue("TOTAL_LABEL","Materials")
		data!.setFieldValue("STD_AMT",str(std_mat_amt:iv_cost_mask$))
		data!.setFieldValue("ACT_AMT",str(act_mat_amt:iv_cost_mask$))
		data!.setFieldValue("VAR_AMT",str(std_mat_amt-act_mat_amt:iv_cost_mask$))
		if std_mat_amt<>0
			data!.setFieldValue("VAR_AMT_PCT",str((std_mat_amt-act_mat_amt)/std_mat_amt*100:sf_pct_mask$))
		else
			data!.setFieldValue("VAR_AMT_PCT",str(0:sf_pct_mask$))
		endif
		rs!.insert(data!)

		data! = rs!.getEmptyRecordData()
		rs!.insert(data!)

		data! = rs!.getEmptyRecordData()
		data!.setFieldValue("THIS_IS_TOTAL_LINE","Y")
		data!.setFieldValue("TOTAL_LABEL","Subcontracts")
		data!.setFieldValue("STD_AMT",str(std_sub_amt:iv_cost_mask$))
		data!.setFieldValue("ACT_AMT",str(act_sub_amt:iv_cost_mask$))
		data!.setFieldValue("VAR_AMT",str(std_sub_amt-act_sub_amt:iv_cost_mask$))
		if std_sub_amt<>0
			data!.setFieldValue("VAR_AMT_PCT",str((std_sub_amt-act_sub_amt)/std_sub_amt*100:sf_pct_mask$))
		else
			data!.setFieldValue("VAR_AMT_PCT",str(0:sf_pct_mask$))
		endif
		rs!.insert(data!)

		data! = rs!.getEmptyRecordData()
		rs!.insert(data!)

rem --- Output WO cost summary totals

	data! = rs!.getEmptyRecordData()
	data!.setFieldValue("THIS_IS_TOTAL_LINE","Y")
	data!.setFieldValue("TOTAL_LABEL","WO Totals")
	data!.setFieldValue("STD_HRS",str(wo_tot_std_hrs:iv_cost_mask$))
	data!.setFieldValue("ACT_HRS",str(wo_tot_act_hrs:iv_cost_mask$))
	data!.setFieldValue("VAR_HRS",str(wo_tot_std_hrs-wo_tot_act_hrs:iv_cost_mask$))
	if wo_tot_std_hrs <> 0
		data!.setFieldValue("VAR_HRS_PCT",str((wo_tot_std_hrs-wo_tot_act_hrs)/wo_tot_std_hrs*100:sf_pct_mask$))
	else
		data!.setFieldValue("VAR_HRS_PCT",str(0:sf_pct_mask$))
	endif
	data!.setFieldValue("STD_AMT",str(wo_tot_std_amt+std_mat_amt+std_sub_amt:iv_cost_mask$))
	data!.setFieldValue("ACT_AMT",str(wo_tot_act_amt+act_mat_amt+act_sub_amt:iv_cost_mask$))
	data!.setFieldValue("VAR_AMT",str((wo_tot_std_amt+std_mat_amt+std_sub_amt)-(wo_tot_act_amt+act_mat_amt+act_sub_amt):iv_cost_mask$))
	if wo_tot_std_amt+std_mat_amt+std_sub_amt <> 0
		data!.setFieldValue("VAR_AMT_PCT",str(((wo_tot_std_amt+std_mat_amt+std_sub_amt)-(wo_tot_act_amt+act_mat_amt+act_sub_amt))/(wo_tot_std_amt+std_mat_amt+std_sub_amt)*100:sf_pct_mask$))
	else
		data!.setFieldValue("VAR_AMT_PCT",str(0:sf_pct_mask$))
	endif
	rs!.insert(data!)

	data! = rs!.getEmptyRecordData()
	data!.setFieldValue("THIS_IS_TOTAL_LINE","Y")
	data!.setFieldValue("TOTAL_LABEL","Per Unit Totals")
	if prod_qty<>0
		data!.setFieldValue("STD_HRS",str(wo_tot_std_hrs/prod_qty:iv_cost_mask$))
		data!.setFieldValue("ACT_HRS",str(wo_tot_act_hrs/prod_qty:iv_cost_mask$))
		data!.setFieldValue("VAR_HRS",str((wo_tot_std_hrs/prod_qty)-(wo_tot_act_hrs/prod_qty):iv_cost_mask$))
		if wo_tot_std_hrs/prod_qty <> 0
			data!.setFieldValue("VAR_HRS_PCT",str(((wo_tot_std_hrs/prod_qty)-(wo_tot_act_hrs/prod_qty))/(wo_tot_std_hrs/prod_qty)*100:sf_pct_mask$))
		else
			data!.setFieldValue("VAR_HRS_PCT",str(0:sf_pct_mask$))
		endif
		data!.setFieldValue("STD_AMT",str((wo_tot_std_amt+std_mat_amt+std_sub_amt)/prod_qty:iv_cost_mask$))
		data!.setFieldValue("ACT_AMT",str((wo_tot_act_amt+act_mat_amt+act_sub_amt)/prod_qty:iv_cost_mask$))
		data!.setFieldValue("VAR_AMT",str(((wo_tot_std_amt+std_mat_amt+std_sub_amt)/prod_qty)-((wo_tot_act_amt+act_mat_amt+act_sub_amt)/prod_qty):iv_cost_mask$))
		if (wo_tot_std_amt+std_mat_amt+std_sub_amt)/prod_qty <> 0
			data!.setFieldValue("VAR_AMT_PCT",str((((wo_tot_std_amt+std_mat_amt+std_sub_amt)/prod_qty)-((wo_tot_act_amt+act_mat_amt+act_sub_amt)/prod_qty))/((wo_tot_std_amt+std_mat_amt+std_sub_amt)/prod_qty)*100:sf_pct_mask$))
		else
			data!.setFieldValue("VAR_AMT_PCT",str(0:sf_pct_mask$))
		endif
	else
		data!.setFieldValue("STD_HRS",str(0:iv_cost_mask$))
		data!.setFieldValue("ACT_HRS",str(0:iv_cost_mask$))
		data!.setFieldValue("VAR_HRS",str(0:iv_cost_mask$))
		data!.setFieldValue("VAR_HRS_PCT",str(0:sf_pct_mask$))
		data!.setFieldValue("STD_AMT",str(0:iv_cost_mask$))
		data!.setFieldValue("ACT_AMT",str(0:iv_cost_mask$))
		data!.setFieldValue("VAR_AMT",str(0:iv_cost_mask$))
		data!.setFieldValue("VAR_AMT_PCT",str(0:sf_pct_mask$))
	endif
	rs!.insert(data!)

rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit

rem --- Subroutines
	
	rem --- Print test pattern of main fields for developing/debugging column placement
	send_test_pattern: 
		data! = rs!.getEmptyRecordData()

		data!.setFieldValue("THIS_IS_TOTAL_LINE","N")
		data!.setFieldValue("REF_NO","99999X")
		data!.setFieldValue("OP_CODE",FILL(LEN(op_code$)-1,"W")+"x")
		data!.setFieldValue("DESC",FILL(LEN(op_code_desc$)-1,"W")+"x")
		data!.setFieldValue("STD_HRS","x"+sf_hours_mask$+"x")
		
		data!.setFieldValue("ACT_HRS","x"+sf_hours_mask$+"x")
		data!.setFieldValue("VAR_HRS","x"+sf_hours_mask$+"x")
		if std_ops_tot_time<>0
			data!.setFieldValue("VAR_HRS_PCT","x"+sf_pct_mask$+"x")
		else
			data!.setFieldValue("VAR_HRS_PCT","x"+sf_pct_mask$+"x")
		endif
		data!.setFieldValue("STD_AMT","x"+iv_cost_mask$+"x")
		data!.setFieldValue("ACT_AMT","x"+iv_cost_mask$+"x")
		data!.setFieldValue("VAR_AMT","x"+iv_cost_mask$+"x")
		if std_ops_amt<>0
			data!.setFieldValue("VAR_AMT_PCT","x"+sf_pct_mask$+"x")
		else
			data!.setFieldValue("VAR_AMT_PCT","x"+sf_pct_mask$+"x")
		endif
		rs!.insert(data!)		
	
	return


rem --- Functions

    def fndate$(q$)
        q1$=""
        q1$=date(jul(num(q$(1,4)),num(q$(5,2)),num(q$(7,2)),err=*next),err=*next)
        if q1$="" q1$=q$
        return q1$
    fnend

rem --- fnmask$: Alphanumeric Masking Function (formerly fnf$)

    def fnmask$(q1$,q2$)
        if q2$="" q2$=fill(len(q1$),"0")
        return str(-num(q1$,err=*next):q2$,err=*next)
        q=1
        q0=0
        while len(q2$(q))
              if pos(q2$(q,1)="-()") q0=q0+1 else q2$(q,1)="X"
              q=q+1
        wend
        if len(q1$)>len(q2$)-q0 q1$=q1$(1,len(q2$)-q0)
        return str(q1$:q2$)
    fnend

	def fngetmask$(q1$,q2$,q3$)
		rem --- q1$=mask name, q2$=default mask if not found in mask string, q3$=mask string from parameters
		q$=q2$
		if len(q1$)=0 return q$
		if q1$(len(q1$),1)<>"^" q1$=q1$+"^"
		q=pos(q1$=q3$)
		if q=0 return q$
		q$=q3$(q)
		q=pos("^"=q$)
		q$=q$(q+1)
		q=pos("|"=q$)
		q$=q$(1,q-1)
		return q$
	fnend

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num

	std_exit:
	
	end
