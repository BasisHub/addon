rem ----------------------------------------------------------------------------
rem Program: SFHARDCOPYTRANS.prc
rem Description: Stored Procedure to get the Shop Floor Hard Copy Transaction info into iReports
rem Used for Hard Copy, Traveler, Work Order Closed Detail and Work Order Detail
rem
rem Author(s): J. Brewer/ C. Johnson
rem Revised: 05.01.2012
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

	firm_id$    = sp!.getParameter("FIRM_ID")
	wo_loc$     = sp!.getParameter("WO_LOCATION")
	wo_no$      = sp!.getParameter("WO_NO")
	barista_wd$ = sp!.getParameter("BARISTA_WD")
	masks$      = sp!.getParameter("MASKS")
	
	datefrom$ = sp!.getParameter("TRANS_DATEFROM")	
	datethru$ = sp!.getParameter("TRANS_DATETHRU")

    transtype$ = sp!.getParameter("TRANSTYPE"); rem list of trans types to include on report
	
	sf_prevper_enddate$ = sp!.getParameter("SF_PREVPER_ENDDATE")

rem --- masks$ will contain pairs of fields in a single string mask_name^mask|

	if len(masks$)>0
		if masks$(len(masks$),1)<>"|"
			masks$=masks$+"|"
		endif
	endif

rem ---
	
	sv_wd$=dir("")
	chdir barista_wd$

rem --- Create a memory record set to hold results.
rem --- Columns for the record set are defined using a string template
	temp$="TRANS_DATE:C(1*), SOURCE:C(1*), ITEM_VEND_OPER:C(1*), "
	temp$=temp$+"DESC:C(1*), PO_NUM:C(1*), COMPLETE_QTY:C(1*), SETUP_HRS:C(1*), "
	temp$=temp$+"UNITS:C(1*), RATE:C(1*), AMOUNT:C(1*)"	

	rs! = BBJAPI().createMemoryRecordSet(temp$)

rem --- If no TransTypes were specified, exit

	if pos("M"=transtype$)=0 and pos("O"=transtype$)=0 and pos("S"=transtype$)=0 goto send_resultset
	
rem --- Get Barista System Program directory

	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)

rem --- Get masks

	pgmdir$=stbl("+DIR_PGM",err=*next)

	sf_cost_mask$=fngetmask$("sf_cost_mask","##,##0.0000-",masks$)
	sf_units_mask$=fngetmask$("sf_units_mask","#,###.0000-",masks$)
	sf_rate_mask$=fngetmask$("sf_rate_mask","#,##0.000-",masks$)
	sf_hours_mask$=fngetmask$("sf_hours_mask","#,##0.00",masks$)
	sf_amt_mask$=fngetmask$("sf_amt_mask","###,##0.00-",masks$)	
	vendor_mask$=fngetmask$("vendor_mask","000000",masks$)
	employee_mask$=fngetmask$("employee_mask","000000",masks$)

rem --- Open files with adc (Change from adc to bac once Barista is enhanced)

    files=10,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="ivm-01",    ids$[1]="IVM_ITEMMAST"
	files$[2]="sfs_params",ids$[2]="SFS_PARAMS"
	files$[3]="ivs_params",ids$[3]="IVS_PARAMS"	
	files$[4]="gls_params",ids$[4]="IVS_PARAMS"		
    files$[5]="sft-01",    ids$[5]="SFT_OPNOPRTR"
	files$[6]="sft-03",    ids$[6]="SFT_CLSOPRTR"
	files$[7]="sft-21",    ids$[7]="SFT_OPNMATTR"
    files$[8]="sft-23",    ids$[8]="SFT_CLSMATTR"
	files$[9]="sft-31",    ids$[9]="SFT_OPNSUBTR"
	files$[10]="sft-33",   ids$[10]="SFT_CLSSUBTR"

	
    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
    if status goto std_exit
	
    ivm_itemmast_dev=channels[1]
	sfs_params=channels[2]
	ivs_params=channels[3]	
	gls_params=channels[4]
	
    sft01a_dev=channels[5]
	sft03a_dev=channels[6]
	sft21a_dev=channels[7]
    sft23a_dev=channels[8]
	sft31a_dev=channels[9]
	sft33a_dev=channels[10]

rem --- Dimension string templates

	dim ivm_itemmast$:templates$[1]
	dim sfs_params$:templates$[2]
	dim ivs_params$:templates$[3]
	dim gls_params$:templates$[4]	
    sft01_tpls$=templates$[5]; dim sft01a$:sft01_tpls$; rem Save template for conditional use
	sft03_tpls$=templates$[6]; dim sft03a$:sft03_tpls$; rem Save template for conditional use
    sft21_tpls$=templates$[7]; dim sft21a$:sft21_tpls$; rem Save template for conditional use
    sft23_tpls$=templates$[8]; dim sft23a$:sft23_tpls$; rem Save template for conditional use
    sft31_tpls$=templates$[9]; dim sft31a$:sft31_tpls$; rem Save template for conditional use
    sft33_tpls$=templates$[10]; dim sft33a$:sft33_tpls$; rem Save template for conditional use
	
goto no_bac_open
rem --- Open Files via bac    (Change from adc to bac once Barista is enhanced)
    num_files = 10
    dim open_tables$[1:num_files], open_opts$[1:num_files], open_chans$[1:num_files], open_tpls$[1:num_files]

	open_tables$[1]="IVM_ITEMMAST", open_opts$[1] = "OTA"
	open_tables$[2]="SFS_PARAMS",   open_opts$[2] = "OTA"
	open_tables$[3]="IVS_PARAMS",   open_opts$[3] = "OTA"
	open_tables$[4]="GLS_PARAMS",   open_opts$[4] = "OTA"	
	open_tables$[5]="SFT_OPNOPRTR", open_opts$[5] = "OTA"; rem sft-01
	open_tables$[6]="SFT_CLSOPRTR", open_opts$[6] = "OTA"; rem sft-03
	open_tables$[7]="SFT_OPNMATTR", open_opts$[7] = "OTA"; rem sft-21
	open_tables$[8]="SFT_CLSMATTR", open_opts$[8] = "OTA"; rem sft-23
	open_tables$[9]="SFT_OPNSUBTR", open_opts$[9] = "OTA"; rem sft-31
	open_tables$[10]="SFT_CLSSUBTR",open_opts$[10] = "OTA"; rem sft-33	
	
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

	ivm_itemmast_dev  = num(open_chans$[1])
	sfs_params = num(open_chans$[2])
	ivs_params = num(open_chans$[3])
	gls_params = num(open_chans$[4])	
	
	sft01a_dev = num(open_chans$[5])
	sft03a_dev = num(open_chans$[6])
	sft21a_dev = num(open_chans$[7])
	sft23a_dev = num(open_chans$[8])
	sft31a_dev = num(open_chans$[9])
	sft33a_dev = num(open_chans$[10])	
	
	rem --- templates
	dim ivm_itemmast$:open_tpls$[1]
	dim sfs_params$:open_tpls$[2]
	dim ivs_params$:open_tpls$[3]
	dim gls_params$:open_tpls$[4]	
	
    sft01_tpls$=open_tpls$[5]; dim sft01a$:sft01_tpls$; rem Save template for conditional use
	sft03_tpls$=open_tpls$[6]; dim sft03a$:sft03_tpls$; rem Save template for conditional use
    sft21_tpls$=open_tpls$[7]; dim sft21a$:sft21_tpls$; rem Save template for conditional use
    sft23_tpls$=open_tpls$[8]; dim sft23a$:sft23_tpls$; rem Save template for conditional use
    sft31_tpls$=open_tpls$[9]; dim sft31a$:sft31_tpls$; rem Save template for conditional use
    sft33_tpls$=open_tpls$[10]; dim sft33a$:sft33_tpls$; rem Save template for conditional use	
	
no_bac_open:

rem --- Retrieve parameter records
rem       NOTE: Params are checked to exist in initial overlay
        gls_params_key$=firm_id$+"GL00"
        find record (gls_params,key=gls_params_key$) gls_params$
	
		sfs_params_key$=firm_id$+"SF00"
        find record (sfs_params,key=sfs_params_key$) sfs_params$
			
		ivs_params_key$=firm_id$+"IV00"
        find record (ivs_params,key=ivs_params_key$) ivs_params$

rem --- Parameters

        bm$=sfs_params.bm_interface$
        op$=sfs_params.ar_interface$
        po$=sfs_params.po_interface$
        pr$=sfs_params.pr_interface$
    
rem --- Additional File Opens
		
		gosub addl_opens_adc; rem Change from adc to bac once Barista's enhanced
		rem gosub addl_opens_bac; rem Change from adc to bac once Barista's enhanced

rem --- Build SQL statement

rem --- Get SQL view joining sfe01 with a mimic of legacy SFM-07 / WOM-07 / SFX_WOTRANXR
rem   - Narrow the query of that view using the selections passed in.
rem   - This record set will be used as driver instead of sfe-01 and sfm-07.

    sql_prep$=""
	select$=""
	where_clause$=""
	order_clause$=""

rem --- Construct the main SELECT list
	select$=select$+"       mast.firm_id "
	select$=select$+"     , mast.wo_location "
	select$=select$+"     , mast.wo_no "
	select$=select$+"     , mast.wo_status "
	select$=select$+"     , mast.closed_date "
	select$=select$+"     , trans.trans_date "
	select$=select$+"     , trans.trans_type "
	select$=select$+"     , trans.record_id "
	select$=select$+"     , trans.trans_seq  "
	select$=select$+"     , trans.seq_ref  "
	select$=select$+"     , trans.trans_warehouse_id  "
	select$=select$+"     , trans.trans_item_id  "
		
rem --- Construct the WHERE clause
	rem Limit recordset to the Firm+Location+WO being reported on
		where_clause$=where_clause$+"WHERE firm_id = '"+firm_id$+"' AND wo_location = '"+wo_loc$+"' AND wo_no = '"+wo_no$+"' AND "

	rem Limit recordset to date range parameters
		if datefrom$<>"" where_clause$=where_clause$+"trans_date >= '"+datefrom$+"' AND "
		if datethru$<>"" where_clause$=where_clause$+"trans_date <= '"+datethru$+"' AND "
	
    rem Remove and trailing 'AND' from the WHERE clause
		where_clause$=cvs(where_clause$,2)
		if where_clause$(len(where_clause$)-2,3)="AND" where_clause$=where_clause$(1,len(where_clause$)-3)

rem --- Construct the ORDER BY clause	
		order_clause$=order_clause$+" ORDER BY trans_date,record_id,trans_seq "
    
rem --- Construct the various potential transaction SELECTs to be UNIONed	
	rem Open Operations Transactions
		opn_ops_select$=" "
		opn_ops_select$=opn_ops_select$+"SELECT oops.firm_id "
		opn_ops_select$=opn_ops_select$+"     , oops.wo_location "
		opn_ops_select$=opn_ops_select$+"     , oops.wo_no "
		opn_ops_select$=opn_ops_select$+"     , oops.trans_date "
		opn_ops_select$=opn_ops_select$+"     , 'OpenOprs' AS trans_type "
		opn_ops_select$=opn_ops_select$+"     , 'O' AS record_id "
		opn_ops_select$=opn_ops_select$+"     , oops.trans_seq  "
		opn_ops_select$=opn_ops_select$+"     , oops.oper_seq_ref AS seq_ref  "
		opn_ops_select$=opn_ops_select$+"     , '' AS trans_warehouse_id  "
		opn_ops_select$=opn_ops_select$+"     , '' AS trans_item_id  "
		opn_ops_select$=opn_ops_select$+"FROM sft_opnoprtr AS oops "
		opn_ops_select$=opn_ops_select$+where_clause$
		
	rem Closed Operations Transactions
		clsd_ops_select$=" "
		clsd_ops_select$=clsd_ops_select$+"SELECT cops.firm_id "
		clsd_ops_select$=clsd_ops_select$+"     , cops.wo_location "
		clsd_ops_select$=clsd_ops_select$+"     , cops.wo_no "
		clsd_ops_select$=clsd_ops_select$+"     , cops.trans_date "
		clsd_ops_select$=clsd_ops_select$+"     , 'ClosedOprs' AS trans_type "
		clsd_ops_select$=clsd_ops_select$+"     , 'O' AS record_id "
		clsd_ops_select$=clsd_ops_select$+"     , cops.trans_seq  "
		clsd_ops_select$=clsd_ops_select$+"     , cops.oper_seq_ref AS seq_ref  "
		clsd_ops_select$=clsd_ops_select$+"     , '' AS trans_warehouse_id  "
		clsd_ops_select$=clsd_ops_select$+"     , '' AS trans_item_id  "
		clsd_ops_select$=clsd_ops_select$+"FROM sft_clsoprtr AS cops "
		clsd_ops_select$=clsd_ops_select$+where_clause$	
		
	rem Open Materials Transactions
		opn_mat_select$=" "
		opn_mat_select$=opn_mat_select$+"SELECT omat.firm_id "
		opn_mat_select$=opn_mat_select$+"     , omat.wo_location "
		opn_mat_select$=opn_mat_select$+"     , omat.wo_no "
		opn_mat_select$=opn_mat_select$+"     , omat.trans_date "
		opn_mat_select$=opn_mat_select$+"     , 'Openmat' AS trans_type "
		opn_mat_select$=opn_mat_select$+"     , 'M' AS record_id "
		opn_mat_select$=opn_mat_select$+"     , omat.trans_seq  "
		opn_mat_select$=opn_mat_select$+"     , omat.material_seq_ref AS seq_ref  "
		opn_mat_select$=opn_mat_select$+"     , omat.warehouse_id AS trans_warehouse_id  "
		opn_mat_select$=opn_mat_select$+"     , omat.item_id AS trans_item_id  "
		opn_mat_select$=opn_mat_select$+"FROM sft_opnmattr AS omat "
		opn_mat_select$=opn_mat_select$+where_clause$
		
	rem Closed Materials Transactions
		clsd_mat_select$=" "
		clsd_mat_select$=clsd_mat_select$+"SELECT cmat.firm_id "
		clsd_mat_select$=clsd_mat_select$+"     , cmat.wo_location "
		clsd_mat_select$=clsd_mat_select$+"     , cmat.wo_no "
		clsd_mat_select$=clsd_mat_select$+"     , cmat.trans_date "
		clsd_mat_select$=clsd_mat_select$+"     , 'Closedmat' AS trans_type "
		clsd_mat_select$=clsd_mat_select$+"     , 'M' AS record_id "
		clsd_mat_select$=clsd_mat_select$+"     , cmat.trans_seq  "
		clsd_mat_select$=clsd_mat_select$+"     , cmat.material_seq_ref AS seq_ref  "
		clsd_mat_select$=clsd_mat_select$+"     , cmat.warehouse_id AS trans_warehouse_id  "
		clsd_mat_select$=clsd_mat_select$+"     , cmat.item_id AS trans_item_id  "
		clsd_mat_select$=clsd_mat_select$+"FROM sft_clsmattr AS cmat "
		clsd_mat_select$=clsd_mat_select$+where_clause$			
		
	rem Open Subcontracts Transactions
		opn_sub_select$=" "
		opn_sub_select$=opn_sub_select$+"SELECT osub.firm_id "
		opn_sub_select$=opn_sub_select$+"     , osub.wo_location "
		opn_sub_select$=opn_sub_select$+"     , osub.wo_no "
		opn_sub_select$=opn_sub_select$+"     , osub.trans_date "
		opn_sub_select$=opn_sub_select$+"     , 'Opensubs' AS trans_type "
		opn_sub_select$=opn_sub_select$+"     , 'S' AS record_id "
		opn_sub_select$=opn_sub_select$+"     , osub.trans_seq  "
		opn_sub_select$=opn_sub_select$+"     , osub.subcont_seq_ref AS seq_ref  "
		opn_sub_select$=opn_sub_select$+"     , '' AS trans_warehouse_id  "
		opn_sub_select$=opn_sub_select$+"     , '' AS trans_item_id  "
		opn_sub_select$=opn_sub_select$+"FROM sft_opnsubtr AS osub "
		opn_sub_select$=opn_sub_select$+where_clause$
		
	rem Closed Subcontracts Transactions
		clsd_sub_select$=" "
		clsd_sub_select$=clsd_sub_select$+"SELECT csub.firm_id "
		clsd_sub_select$=clsd_sub_select$+"     , csub.wo_location "
		clsd_sub_select$=clsd_sub_select$+"     , csub.wo_no "
		clsd_sub_select$=clsd_sub_select$+"     , csub.trans_date "
		clsd_sub_select$=clsd_sub_select$+"     , 'ClosedSubs' AS trans_type "
		clsd_sub_select$=clsd_sub_select$+"     , 'S' AS record_id "
		clsd_sub_select$=clsd_sub_select$+"     , csub.trans_seq  "
		clsd_sub_select$=clsd_sub_select$+"     , csub.subcont_seq_ref AS seq_ref  "
		clsd_sub_select$=clsd_sub_select$+"     , '' AS trans_warehouse_id  "
		clsd_sub_select$=clsd_sub_select$+"     , '' AS trans_item_id  "
		clsd_sub_select$=clsd_sub_select$+"FROM sft_clssubtr AS csub "
		clsd_sub_select$=clsd_sub_select$+where_clause$	
		
rem --- Limit recordset to transaction type parameter
		trans_tbl_query$=""
		
		if pos("O"=transtype$)>0 
			trans_tbl_query$=trans_tbl_query$+opn_ops_select$
			trans_tbl_query$=trans_tbl_query$+" UNION "
			trans_tbl_query$=trans_tbl_query$+clsd_ops_select$
			trans_tbl_query$=trans_tbl_query$+" UNION "			
		endif
		if pos("M"=transtype$)>0 
			trans_tbl_query$=trans_tbl_query$+opn_mat_select$
			trans_tbl_query$=trans_tbl_query$+" UNION "
			trans_tbl_query$=trans_tbl_query$+clsd_mat_select$
			trans_tbl_query$=trans_tbl_query$+" UNION "
		endif

		if pos("S"=transtype$)>0 
			trans_tbl_query$=trans_tbl_query$+opn_sub_select$
			trans_tbl_query$=trans_tbl_query$+" UNION "
			trans_tbl_query$=trans_tbl_query$+clsd_sub_select$
		endif

	rem Remove any trailing 'UNION' from the list of transaction table queries
		trans_tbl_query$=cvs(trans_tbl_query$,2)
		if trans_tbl_query$(len(trans_tbl_query$)-4,5)="UNION" trans_tbl_query$=trans_tbl_query$(1,len(trans_tbl_query$)-5)
	
rem --- Construct sql_prep$	

		sql_prep$=sql_prep$+"SELECT "+select$+" "
		sql_prep$=sql_prep$+"FROM sfe_womastr AS mast "
		sql_prep$=sql_prep$+"LEFT JOIN ("+trans_tbl_query$+" "
		sql_prep$=sql_prep$+"          ) AS trans"
		sql_prep$=sql_prep$+"       ON mast.firm_id+mast.wo_location+mast.wo_no "
		sql_prep$=sql_prep$+"        = trans.firm_id+trans.wo_location+trans.wo_no " 
		sql_prep$=sql_prep$+"WHERE mast.firm_id = '"+firm_id$+"' AND mast.wo_location = '"+wo_loc$+"' AND mast.wo_no = '"+wo_no$+"' "
		sql_prep$=sql_prep$+order_clause$	

	rem Exec the completed query
		sql_chan=sqlunt
		sqlopen(sql_chan,err=*next)stbl("+DBNAME")
		sqlprep(sql_chan)sql_prep$
		dim read_tpl$:sqltmpl(sql_chan)
		sqlexec(sql_chan,err=std_exit)

rem --- Init constants, totals and total-break vars
	more = 1 
	
	date_tot_setup_hours=0
	date_tot_hours=0
	date_tot_cost=0
	doing_end=0
	
	grand_tot_setup_hours=0
	grand_tot_hours=0
	grand_tot_cost=0
			
	prev_date$=""; rem This is t1$ in sfr_wotranshist_o1.aon and v6
	
rem --- Trip Read

	while 1
		read_tpl$ = sqlfetch(sql_chan,end=*break)

		data! = rs!.getEmptyRecordData()
	
rem --- Process Transactions
        if read_tpl.wo_status$<>"C" or read_tpl.closed_date$>sf_prevper_enddate$ then 
            tran01_dev=sft01a_dev; tran01a$=sft01_tpls$
            tran02_dev=sft21a_dev; tran02a$=sft21_tpls$
            tran03_dev=sft31a_dev; tran03a$=sft31_tpls$
        else
            tran01_dev=sft03a_dev; tran01a$=sft03_tpls$
            tran02_dev=sft23a_dev; tran02a$=sft23_tpls$
            tran03_dev=sft33a_dev; tran03a$=sft33_tpls$
        endif

        if read_tpl.record_id$="O" then 
			sftran_dev=tran01_dev
			dim sftran$:tran01a$
			record_id_field$="O"
		endif
        if read_tpl.record_id$="M" then 
			sftran_dev=tran02_dev
			dim sftran$:tran02a$
			record_id_field$="M"
		endif
        if read_tpl.record_id$="S" then  
			sftran_dev=tran03_dev
			dim sftran$:tran03a$
			record_id_field$="S"
		endif

		sftran_read_k$=read_tpl.firm_id$
		sftran_read_k$=sftran_read_k$+read_tpl.wo_location$
		sftran_read_k$=sftran_read_k$+read_tpl.wo_no$
		sftran_read_k$=sftran_read_k$+read_tpl.trans_date$
		sftran_read_k$=sftran_read_k$+read_tpl.trans_seq$
	
		find record (sftran_dev,key=sftran_read_k$,dom=*continue) sftran$
        if transtype$<>"" then if pos(record_id_field$=transtype$)=0 then continue
        if read_tpl.trans_date$(1,6)<>prev_date$ then gosub date_subtot

		rem --- Data common to all transaction types
		data!.setFieldValue("TRANS_DATE",fndate$(sftran.trans_date$))
		data!.setFieldValue("SOURCE",read_tpl.record_id$)
		data!.setFieldValue("UNITS",str(sftran.units:sf_units_mask$))
		data!.setFieldValue("RATE",str(sftran.unit_cost:sf_rate_mask$))
		data!.setFieldValue("AMOUNT",str(sftran.ext_cost:sf_amt_mask$))
		
        rem --- Based on Trans Type, fill type-specific fields

		transtype=pos(read_tpl.record_id$="MOS")-1
		switch transtype
			case 0
				rem --- Materials
				dim ivm_itemmast$:fattr(ivm_itemmast$)
				read record (ivm_itemmast_dev,key=firm_id$+read_tpl.trans_item_id$,dom=*next) ivm_itemmast$

				data!.setFieldValue("ITEM_VEND_OPER",pad(cvs(read_tpl.trans_item_id$,2),20))
				data!.setFieldValue("DESC",ivm_itemmast.item_desc$)
				data!.setFieldValue("PO_NUM","")
				data!.setFieldValue("COMPLETE_QTY","")
				data!.setFieldValue("SETUP_HRS","")
				break
			case 1
				rem --- Operations
				dim opcode$:fattr(opcode$)
				find record (opcode_dev,key=firm_id$+sftran.op_code$,dom=*next) opcode$
				
				dim empcode$:fattr(empcode$)
				find record (empcode_dev,key=firm_id$+sftran.employee_no$,dom=*next) empcode$

				data!.setFieldValue("ITEM_VEND_OPER",sftran.op_code$+"  "+opcode.code_desc$)
				data!.setFieldValue("DESC",fnmask$(sftran.employee_no$,employee_mask$)+" "+empcode.empl_surname$+empcode.empl_givname$)
				data!.setFieldValue("PO_NUM","")
				data!.setFieldValue("COMPLETE_QTY",str(sftran.complete_qty:sf_units_mask$))
				data!.setFieldValue("SETUP_HRS",str(sftran.setup_time:sf_hours_mask$))		
				break
			case 2
				rem --- Subcontracts
				vend_name$=""
				if po$="Y"  
					dim apm01a$:fattr(apm01a$)
					find record (apm01a_dev,key=firm_id$+sftran.vendor_id$,dom=*next) apm01a$
					vend_name$=apm01a.vendor_name$
				endif 
				
				data!.setFieldValue("ITEM_VEND_OPER",fnmask$(sftran.vendor_id$,vendor_mask$)+"  "+vend_name$)
				data!.setFieldValue("DESC","")
				data!.setFieldValue("PO_NUM",sftran.po_no$)
				data!.setFieldValue("COMPLETE_QTY","")
				data!.setFieldValue("SETUP_HRS","")				    	
				break
			case default
				break
		swend
            
        rem --- Accum Totals
		if record_id_field$="O" then 
			date_tot_setup_hours=date_tot_setup_hours+sftran.setup_time
			date_tot_hours=date_tot_hours+sftran.units
			grand_tot_setup_hours=grand_tot_setup_hours+sftran.setup_time
			grand_tot_hours=grand_tot_hours+sftran.units
		endif
		
		date_tot_cost=date_tot_cost+sftran.ext_cost
		grand_tot_cost=grand_tot_cost+sftran.ext_cost

		rs!.insert(data!)
		
		rem tot_cost_ea=tot_cost_ea+read_tpl.unit_cost
		rem tot_cost_tot=tot_cost_tot+read_tpl.total_cost
		
		rem --- Conditionally process Lot/Serial for Materials records

		if read_tpl.record_id$="M"		
			if ivm_itemmast.lotser_item$="Y" and
:			   ivm_itemmast.inventoried$="Y" and
:			   pos(ivs_params.lotser_flag$="LS") then 
				  gosub lotserial_details				
			endif		
		endif
	wend

rem --- Output Totals

	doing_end=1
	gosub date_subtot
	
	data! = rs!.getEmptyRecordData(); rem Add totals' underscores
	data!.setFieldValue("AMOUNT",fill(20,"_"))
	rs!.insert(data!)
	
	data! = rs!.getEmptyRecordData()
	data!.setFieldValue("ITEM_VEND_OPER","Work Order Totals") 		
	data!.setFieldValue("DESC","Total Hours: "+str(grand_tot_hours:sf_hours_mask$)) 			
	data!.setFieldValue("PO_NUM","Setup Hours: "+str(grand_tot_setup_hours:sf_hours_mask$))
	data!.setFieldValue("AMOUNT",str(grand_tot_cost:sf_amt_mask$))	

	rs!.insert(data!)
	
rem --- Tell the stored procedure to return the result set.
send_resultset:

	sp!.setRecordSet(rs!)
	goto std_exit

rem --- Subroutines

rem --- Additional File Opens subroutines
addl_opens_adc:
rem --- Conditionally open L/S files
    if pos(ivs_params.lotser_flag$="LS") then
		files=2,begfile=1,endfile=files
		dim files$[files],options$[files],ids$[files],templates$[files],channels[files]

        files$[1]="sft-11",        ids$[1]="SFT_OPNLSTRN"
        files$[2]="sft-12",        ids$[2]="SFT_CLSLSTRN"
	
		call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
		if status goto std_exit

		sft11a_dev = channels[1]
		sft12a_dev = channels[2]

	rem --- Dimension L/S string templates
        
		sft11_tpls$=templates$[1]; dim sft11a$:sft11_tpls$; rem Save template for conditional use
		sft12_tpls$=templates$[2]; dim sft12a$:sft12_tpls$; rem Save template for conditional use	
	endif 
	
rem --- Open either BM or SF OpCodes file and either PR or SF Employees file
rem --- Conditionally open apm-01 for vendor name
	files=3,begfile=1,endfile=files
	dim files$[files],options$[files],ids$[files],templates$[files],channels[files]

	if bm$="Y" 
		files$[1]="bmm-08", ids$[1]="BMC_OPCODES"
    else 
		files$[1]="sfm-02", ids$[1]="SFC_OPRTNCOD"
	endif
	if pr$="Y" 
		files$[2]="prm-01", ids$[2]="PRM_EMPLMAST"
    else 
		files$[2]="sfm-01", ids$[2]="SFM_EMPLMAST"
	endif	
	if po$="Y" files$[3]="apm-01", ids$[3]="APM_VENDMAST"
	
	call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
	if status goto std_exit

	opcode_dev = channels[1]
	empcode_dev= channels[2]
	apm01a_dev = channels[3]	
	
	rem --- Dimension OpCode, EmpCode, and apm01a string templates	
		dim opcode$:templates$[1]
		dim empcode$:templates$[2]
		if po$="Y" dim apm01a$:templates$[3]
	return
	
addl_opens_bac:	
rem --- Conditionally open L/S files
    if pos(ivs_params.lotser_flag$="LS") then
		num_files=2
		dim open_tables$[1:num_files], open_opts$[1:num_files], open_chans$[1:num_files], open_tpls$[1:num_files]

        open_tables$[1]="SFT_OPNLSTRN", open_opts$[1]="OTA"; rem sft-11
        open_tables$[2]="SFT_CLSLSTRN", open_opts$[2]="OTA"; rem sft-12
  	
		gosub open_tables

		sft11a_dev = num(open_chans$[1])
		sft12a_dev = num(open_chans$[2])
		
	rem --- Dimension L/S string templates			
      	sft11_tpls$=open_tpls$[1]; dim sft11a$:sft11_tpls$; rem Save template for conditional use
		sft12_tpls$=open_tpls$[2]; dim sft12a$:sft12_tpls$; rem Save template for conditional use		
	endif
	
rem --- Open either BM or SF OpCodes file and either PR or SF Employees file
rem --- Conditionally open apm-01 for vendor name
	num_files=3
	dim open_tables$[1:num_files], open_opts$[1:num_files], open_chans$[1:num_files], open_tpls$[1:num_files]

	if bm$="Y" 
		open_tables$[1]="BMC_OPCODES",  open_opts$[1]="OTA"; rem bmm-08
    else
		open_tables$[1]="SFC_OPRTNCOD", open_opts$[1]="OTA"; rem sfm-02
	endif
	if pr$="Y" 
		open_tables$[1]="PRM_EMPLMAST", open_opts$[7]="OTA"; rem prm-01
    else
		open_tables$[2]="SFM_EMPLMAST", open_opts$[2]="OTA"; rem sfm-01
	endif
	if po$="Y" open_tables$[3]="APM_VENDMAST", open_opts$[3]="OTA"; rem apm-01
	
  	gosub open_tables		

	opcode_dev = num(open_chans$[1])
	empcode_dev = num(open_chans$[2])
	apm01a_dev = num(open_chans$[3])
	
	rem --- Dimension OpCode, EmpCode, and apm01a string templates		
      	dim opcode$:open_tpls$[1]	
      	dim empcode$:open_tpls$[2]
		if po$="Y" dim apm01a$:open_tpls$[3]
	return    

lotserial_details: rem --- Lot/Serial Here
rem --- Serial Numbers Here
	if read_tpl.wo_status$<>"C" or read_tpl.closed_date$>sf_prevper_enddate$ then 
        lstran_dev=sft11a_dev
        dim lstran$:sft11_tpls$
    else
        lstran_dev=sft12a_dev
        dim lstran$:sft12_tpls$
    endif

	read_ls_key$=sftran.firm_id$+sftran.wo_location$+sftran.wo_no$+sftran.trans_date$+sftran.trans_seq$
    read (lstran_dev,key=read_ls_key$,dom=*next)

		while more
		data! = rs!.getEmptyRecordData()
		
		read record (lstran_dev,end=*break) lstran$ 

        if pos(read_ls_key$=lstran$)=1 then      
            if ivs_params.lotser_flag$="S" then lotser$="Serial: " else lotser$="Lot: "
			data!.setFieldValue("ITEM_VEND_OPER",lotser$+lstran.lotser_no$)

			if lstran_dev=sft11a_dev then 
				data!.setFieldValue("DESC","Issued:"+str(lstran.cls_inp_qty:sf_units_mask$)) 	
				data!.setFieldValue("PO_NUM","Cost:"+str(lstran.closed_cost:sf_cost_mask$))
            else
				data!.setFieldValue("DESC","Issued:"+str(lstran.qty_closed:sf_units_mask$))
				data!.setFieldValue("PO_NUM","Cost:"+str(lstran.unit_cost:sf_cost_mask$))
			endif
			
			rs!.insert(data!)
        else
			break
		endif
    wend 
	
    return

rem --- Subtotals for date breaks
date_subtot:rem --- Date Subtotal

    if prev_date$<>"" then     

		data! = rs!.getEmptyRecordData(); rem Add totals' underscores
		data!.setFieldValue("AMOUNT",fill(20,"_"))
		rs!.insert(data!)
	
		data! = rs!.getEmptyRecordData()	
		data!.setFieldValue("ITEM_VEND_OPER","Month "+fnh$(prev_date$)+" Total ") 	
        if pos("O"=transtype$)>0 then 
			data!.setFieldValue("DESC","Total Hours: "+str(date_tot_hours:sf_hours_mask$)) 			
			data!.setFieldValue("PO_NUM","Setup Hours: "+str(date_tot_setup_hours:sf_hours_mask$))
		endif
		data!.setFieldValue("AMOUNT",str(date_tot_cost:sf_cost_mask$))
	
		rs!.insert(data!)
		
		data! = rs!.getEmptyRecordData(); rem blank line
		rs!.insert(data!); rem Blank line before Date totals	
    endif

    if doing_end then return

	date_tot_setup_hours=0
	date_tot_hours=0
	date_tot_cost=0
	
    prev_date$=read_tpl.trans_date$(1,6); rem just the year/month
	return
	
rem --- Functions

rem --- Format inventory item description

	def fnitem$(q$,q1,q2,q3)
		q$=pad(q$,q1+q2+q3)
		return cvs(q$(1,q1)+" "+q$(q1+1,q2)+" "+q$(q1+q2+1,q3),32)
	fnend

rem --- Date/time handling functions

    def fndate$(q$)
        q1$=""
        q1$=date(jul(num(q$(1,4)),num(q$(5,2)),num(q$(7,2)),err=*next),err=*next)
        if q1$="" q1$=q$
        return q1$
    fnend
    
    def fnyy$(q$)=q$(3,2)
    def fnclock$(q$)=date(0:"%hz:%mz %p")
    def fntime$(q$)=date(0:"%Hz%mz")
    def fnh$(q1$)=q1$(5,2)+"/"+q1$(1,4)

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
