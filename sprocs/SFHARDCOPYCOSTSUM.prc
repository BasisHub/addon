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
	temp$="OP_CODE:C(1*), DESC:C(1*), STD_HRS:C(1*), ACT_HRS:C(1*), VAR_HRS:C(1*), VAR_HRS_PCT:C(1*), "
	temp$=temp$+"STD_AMT:C(1*), ACT_AMT:C(1*), VAR_AMT:C(1*), VAR_AMT_PCT:C(1*) "

	rs! = BBJAPI().createMemoryRecordSet(temp$)

rem --- Get Barista System Program directory

	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)

rem --- Get masks

	pgmdir$=stbl("+DIR_PGM",err=*next)

	iv_cost_mask$=fngetmask$("iv_cost_mask","###,##0.0000-",masks$)
	sf_hours_mask$=fngetmask$("sf_hours_mask","#,##0.00",masks$)
	sf_pct_mask$=fngetmask$("sf_pct_mask","###.00",masks$)
	
	
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
    if status goto std_exit

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
	open_tables$[2]="SFT_CLSMATTR",     open_opts$[2] = "OTA"
	open_tables$[3]="SFT_CLSOPRTR",     open_opts$[3] = "OTA"
	open_tables$[4]="SFT_CLSSUBTR",     open_opts$[4] = "OTA"
	open_tables$[5]="SFT_OPNMATTR",     open_opts$[5] = "OTA"
	open_tables$[6]="SFT_OPNOPRTR",     open_opts$[6] = "OTA"
	open_tables$[7]="SFT_OPNSUBTR",     open_opts$[7] = "OTA"
	
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

	sfs_params = num(open_chans$[1])
	sft_clsmattr=num(open_chans$[2])
	sft_clsoprtr=num(open_chans$[3])
	sft_clssubtr=num(open_chans$[4])
	sft_opnmattr=num(open_chans$[5])
	sft_opnoprtr=num(open_chans$[6])
	sft_opnsubtr=num(open_chans$[7])
	
	dim sfs_params$:open_tpls$[1]
	dim sft_clsmattr$:open_tpls$[2]
	dim sft_clsoprtr$:open_tpls$[3]
	dim sft_clssubtr$:open_tpls$[4]
	dim sft_opnmattr$:open_tpls$[5]
	dim sft_opnoprtr$:open_tpls$[6]
	dim sft_opnsubtr$:open_tpls$[7]
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
    if status goto std_exit
	
	opcode_dev=channels[8]
	dim opcode_tpl$:templates$[8]

rem --- Build SQL statement

	sql_prep$="select op_code, total_time, tot_std_cost, direct_rate, ovhd_rate, internal_seq_no "
	sql_prep$=sql_prep$+"from sfe_wooprtn where firm_id = '"+firm_id$+"' and wo_no = '"+wo_no$+"' and line_type = 'S'"
	
	sql_chan=sqlunt
	sqlopen(sql_chan,err=*next)stbl("+DBNAME")
	sql_chan1=sqlunt
	sqlopen(sql_chan1,err=*next)stbl("+DBNAME")
	sqlprep(sql_chan)sql_prep$
	dim read_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)

rem --- Trip Read

	while 1
		read_tpl$ = sqlfetch(sql_chan,end=*break)

		data! = rs!.getEmptyRecordData()

		gosub get_op_trans
		
		dim opcode_tpl$:fattr(opcode_tpl$)
		read record (opcode_dev,key=firm_id$+read_tpl.op_code$,dom=*next) opcode_tpl$
		data!.setFieldValue("OP_CODE",read_tpl.op_code$)
		data!.setFieldValue("DESC",opcode_tpl.code_desc$)
		data!.setFieldValue("STD_HRS",str(read_tpl.total_time:sf_hours_mask$))
		data!.setFieldValue("ACT_HRS",str(act_op_hrs:sf_hours_mask$))
		data!.setFieldValue("VAR_HRS",str(read_tpl.total_time-act_op_hrs:sf_hours_mask$))
		if read_tpl.total_time<>0
			data!.setFieldValue("VAR_HRS_PCT",str((read_tpl.total_time-act_op_hrs)/read_tpl.total_time*100:sf_pct_mask$))
		else
			data!.setFieldValue("VAR_HRS_PCT",str(0:sf_pct_mask$))
		endif
		data!.setFieldValue("STD_AMT",str(read_tpl.tot_std_cost:iv_cost_mask$))
		data!.setFieldValue("ACT_AMT",str(act_op_amt:iv_cost_mask$))
		data!.setFieldValue("VAR_AMT",str(read_tpl.tot_std_cost-act_op_amt:iv_cost_mask$))
		if read_tpl.tot_std_cost<>0
			data!.setFieldValue("VAR_AMT_PCT",str((read_tpl.tot_std_cost-act_op_amt)/read_tpl.tot_std_cost*100:sf_pct_mask$))
		else
			data!.setFieldValue("VAR_AMT_PCT",str(0:sf_pct_mask$))
		endif
		rs!.insert(data!)

		tot_std_dir=tot_std_dir+read_tpl.total_time*read_tpl.direct_rate
		tot_std_oh=tot_std_oh+read_tpl.total_time*read_tpl.ovhd_rate
		tot_act_hrs=tot_act_hrs+act_op_hrs
		tot_act_amt=tot_act_amt+act_op_amt
		tot_act_dir=0
		tot_act_oh=0
		wo_tot_std_hrs=wo_tot_std_hrs+read_tpl.total_time
		wo_tot_act_hrs=wo_tot_act_hrs+act_op_hrs
		wo_tot_std_amt=wo_tot_std_amt+read_tpl.tot_std_cost
		wo_tot_act_amt=wo_tot_act_amt+act_op_amt

	wend

rem --- Get Material Requirements Totals

	sql_prep$="select sum(total_cost) "
	sql_prep$=sql_prep$+"from sfe_womatl where firm_id = '"+firm_id$+"' and wo_no = '"+wo_no$+"' and line_type = 'S'"

	sqlprep(sql_chan)sql_prep$
	dim read_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)
	
	read_tpl$ = sqlfetch(sql_chan,err=*next)
	
	std_mat_amt=read_tpl.col001

rem --- Get Subcontract Requirements Totals

	sql_prep$="select sum(total_cost) "
	sql_prep$=sql_prep$+"from sfe_wosubcnt where firm_id = '"+firm_id$+"' and wo_no = '"+wo_no$+"' and line_type = 'S'"

	sqlprep(sql_chan)sql_prep$
	dim read_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)
	
	read_tpl$ = sqlfetch(sql_chan,err=*next)
	
	std_sub_amt=read_tpl.col001
	
	rem --- Get Material Actual Totals

	act_mat_amt=0

	tran_dev=sft_opnmattr
	dim tran_rec$:fattr(sft_opnmattr$)
	while tran_dev>0
		read (tran_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)
		while 1
			read record (tran_dev,end=*break) tran_rec$
			if pos(firm_id$+wo_loc$+wo_no$=tran_rec$)<>1 break
			act_mat_amt=act_mat_amt+tran_rec.ext_cost
		wend
		if tran_dev=sft_opnmattr
			tran_dev=sft_clsmattr
			dim tran_rec$:fattr(sft_clsmattr$)
		else
			tran_dev=0
		endif
	wend

rem --- Get Subcontract Actual Totals

	act_sub_amt=0

	tran_dev=sft_opnsubtr
	dim tran_rec$:fattr(sft_opnsubtr$)
	while tran_dev>0
		read (tran_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)
		while 1
			read record (tran_dev,end=*break) tran_rec$
			if pos(firm_id$+wo_loc$+wo_no$=tran_rec$)<>1 break
			act_sub_amt=act_sub_amt+tran_rec.ext_cost
		wend
		if tran_dev=sft_opnsubtr
			tran_dev=sft_clssubtr
			dim tran_rec$:fattr(sft_clssubtr$)
		else
			tran_dev=0
		endif
	wend
	
rem --- Output Totals

	data! = rs!.getEmptyRecordData()
	data!.setFieldValue("STD_AMT",fill(20,"_"))
	data!.setFieldValue("ACT_AMT",fill(20,"_"))
	data!.setFieldValue("VAR_AMT",fill(20,"_"))
	data!.setFieldValue("VAR_AMT_PCT",fill(20,"_"))
	rs!.insert(data!)
	
	data! = rs!.getEmptyRecordData()
	data!.setFieldValue("DESC","Direct Total")
	data!.setFieldValue("STD_AMT",str(tot_std_dir:iv_cost_mask$))
	data!.setFieldValue("ACT_AMT",str(act_op_dir_amt:iv_cost_mask$))
	data!.setFieldValue("VAR_AMT",str(tot_std_dir-act_op_dir_amt:iv_cost_mask$))
	if tot_std_dir<>0
		data!.setFieldValue("VAR_AMT_PCT",str((tot_std_dir-act_op_dir_amt)/tot_std_dir*100:sf_pct_mask$))
	else
		data!.setFieldValue("VAR_AMT_PCT",str(0:sf_pct_mask$))
	endif
	rs!.insert(data!)

		data! = rs!.getEmptyRecordData()
	data!.setFieldValue("DESC","Overhead Total")
	data!.setFieldValue("STD_AMT",str(tot_std_oh:iv_cost_mask$))
	data!.setFieldValue("ACT_AMT",str(act_op_oh_amt:iv_cost_mask$))
	data!.setFieldValue("VAR_AMT",str(tot_std_oh-act_op_oh_amt:iv_cost_mask$))
	if tot_std_oh<>0
		data!.setFieldValue("VAR_AMT_PCT",str((tot_std_oh-act_op_oh_amt)/tot_std_oh*100:sf_pct_mask$))
	else
		data!.setFieldValue("VAR_AMT_PCT",str(0:sf_pct_mask$))
	endif
	rs!.insert(data!)
	
	data! = rs!.getEmptyRecordData()
	data!.setFieldValue("STD_AMT",fill(20,"_"))
	data!.setFieldValue("ACT_AMT",fill(20,"_"))
	data!.setFieldValue("VAR_AMT",fill(20,"_"))
	data!.setFieldValue("VAR_AMT_PCT",fill(20,"_"))
	rs!.insert(data!)

	data! = rs!.getEmptyRecordData()
	data!.setFieldValue("DESC","Labor Total")
	data!.setFieldValue("STD_AMT",str(tot_std_dir+tot_std_oh:iv_cost_mask$))
	data!.setFieldValue("ACT_AMT",str(act_op_dir_amt+act_op_oh_amt:iv_cost_mask$))
	data!.setFieldValue("VAR_AMT",str((tot_std_dir+tot_std_oh)-(act_op_dir_amt+act_op_oh_amt):iv_cost_mask$))
	if tot_std_dir+tot_std_oh<>0
		data!.setFieldValue("VAR_AMT_PCT",str(((tot_std_dir+tot_std_oh)-(act_op_dir_amt+act_op_oh_amt))/(tot_std_dir+tot_std_oh)*100:sf_pct_mask$))
	else
		data!.setFieldValue("VAR_AMT_PCT",str(0:sf_pct_mask$))
	endif
	rs!.insert(data!)

	data! = rs!.getEmptyRecordData()
	rs!.insert(data!)

	data! = rs!.getEmptyRecordData()
	data!.setFieldValue("DESC","Materials")
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
	data!.setFieldValue("DESC","Subcontracts")
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

	data! = rs!.getEmptyRecordData()
	data!.setFieldValue("STD_HRS",fill(20,"_"))
	data!.setFieldValue("ACT_HRS",fill(20,"_"))
	data!.setFieldValue("VAR_HRS",fill(20,"_"))
	data!.setFieldValue("VAR_HRS_PCT",fill(20,"_"))
	data!.setFieldValue("STD_AMT",fill(20,"_"))
	data!.setFieldValue("ACT_AMT",fill(20,"_"))
	data!.setFieldValue("VAR_AMT",fill(20,"_"))
	data!.setFieldValue("VAR_AMT_PCT",fill(20,"_"))
	rs!.insert(data!)

	data! = rs!.getEmptyRecordData()
	data!.setFieldValue("DESC","WO Totals")
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
	data!.setFieldValue("STD_HRS",fill(20,"_"))
	data!.setFieldValue("ACT_HRS",fill(20,"_"))
	data!.setFieldValue("VAR_HRS",fill(20,"_"))
	data!.setFieldValue("VAR_HRS_PCT",fill(20,"_"))
	data!.setFieldValue("STD_AMT",fill(20,"_"))
	data!.setFieldValue("ACT_AMT",fill(20,"_"))
	data!.setFieldValue("VAR_AMT",fill(20,"_"))
	data!.setFieldValue("VAR_AMT_PCT",fill(20,"_"))
	rs!.insert(data!)

	data! = rs!.getEmptyRecordData()
	data!.setFieldValue("DESC","Per Unit Totals")
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

get_op_trans:

	sql_prep$="select * from vw_sfx_wotranxr as vw_trans where vw_trans.firm_id = '"+firm_id$+"' and "
	sql_prep$=sql_prep$+"record_id = 'O' and wo_no = '"+wo_no$+"' and seq_ref = '"+read_tpl.internal_seq_no$+"'"
	act_op_hrs=0
	act_op_amt=0

	sqlprep(sql_chan1)sql_prep$
	dim tran_tpl$:sqltmpl(sql_chan1)
	sqlexec(sql_chan1)
	
	while 1
		tran_tpl$ = sqlfetch(sql_chan1,end=*break)
		if tran_tpl.trans_type$="OpenOprs"
			tran_dev=sft_opnoprtr
			dim tran_rec$:fattr(sft_opnoprtr$)
		else
			tran_dev=sft_clsoprtr
			dim tran_rec$:fattr(sft_clsoprtr$)
		endif
		read (tran_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)
		while 1
			read record (tran_dev,end=*break) tran_rec$
			if pos(firm_id$+wo_loc$+wo_no$=tran_rec$)<>1 break
			if tran_rec.oper_seq_ref$=read_tpl.internal_seq_no$
				act_op_hrs=act_op_hrs+tran_rec.units+tran_rec.setup_time
				act_op_amt=act_op_amt+((tran_rec.units+tran_rec.setup_time)*tran_rec.unit_cost)
				act_op_dir_amt=act_op_dir_amt+(tran_rec.units*tran_rec.direct_rate)
				act_op_oh_amt=act_op_oh_amt+(tran_rec.ext_cost-(tran_rec.units*tran_rec.direct_rate))
			endif
		wend
		break
	wend
	
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


	std_exit:
	
	end
