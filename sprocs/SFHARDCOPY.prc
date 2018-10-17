rem ----------------------------------------------------------------------------
rem Program: SFHARDCOPY.prc
rem Description: Stored Procedure to get the Shop Floor Hard Copy info into iReports
rem Used for Hard Copy, Traveler, Work Order Closed Detail and Work Order Detail
rem
rem Author(s): J. Brewer
rem Revised: 04.05.2012
rem
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

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

	report_type$ = sp!.getParameter("REPORT_TYPE"); REM "M/T/E/C Specifies leadin pgm
													rem M = WO Detail Rpt from *M*enu
													rem T = *T*raveler
													rem E = Detail Rpt from WO *E*ntry
													rem C = *C*losed WO Detail Rpt
	firm_id$ = sp!.getParameter("FIRM_ID")
    wo_category$ = sp!.getParameter("WO_CATEGORY",err=*next)
	wo_loc$  = sp!.getParameter("WO_LOCATION")
	from_wo$ = sp!.getParameter("WO_NO_1")
	thru_wo$ = sp!.getParameter("WO_NO_2")
	barista_wd$ = sp!.getParameter("BARISTA_WD")
	report_seq$ = sp!.getParameter("REPORT_SEQ")
	wostatus$ = sp!.getParameter("WOSTATUS")
	from_bill$ = sp!.getParameter("BILL_NO_1")
	thru_bill$ = sp!.getParameter("BILL_NO_2")
	wh_id$ = sp!.getParameter("WAREHOUSE_ID")
	from_cust$ = sp!.getParameter("CUSTOMER_ID_1")
	thru_cust$ = sp!.getParameter("CUSTOMER_ID_2")
	from_type$ = sp!.getParameter("WO_TYPE_1")
	thru_type$ = sp!.getParameter("WO_TYPE_2")
	masks$ = sp!.getParameter("MASKS")
    statusOpen$ = sp!.getParameter("STATUS_OPEN")
    statusPlanned$ = sp!.getParameter("STATUS_PLANNED")
    statusClosed$ = sp!.getParameter("STATUS_CLOSED")
    statusQuoted$ = sp!.getParameter("STATUS_QUOTED")
	
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
	      temp$="FIRM_ID:C(2), WO_NO:C(7*), WO_TYPE:C(1*), WO_CATEGORY:C(1*), WO_STATUS:C(1*), CUSTOMER_ID:C(1*), "
	temp$=temp$+"SLS_ORDER_NO:C(1*), WAREHOUSE_ID:C(1*), ITEM_ID:C(1*), OPENED_DATE:C(1*), LAST_CLOSE:C(1*), "
	temp$=temp$+"TYPE_DESC:C(1*), PRIORITY:C(1*), UOM:C(1*), YIELD:C(1*), PROD_QTY:C(1*), COMPLETED:C(1*), "
	temp$=temp$+"LAST_ACT_DATE:C(1*), ITEM_DESC_1:C(1*), ITEM_DESC_2:C(1*), IMAGE_PATH:C(1*), DRAWING_NO:C(1*), REV:C(1*), "
	temp$=temp$+"INCLUDE_LOTSER:C(1*), MAST_CLS_INP_QTY_STR:C(1*), MAST_CLS_INP_DT:C(1*), MAST_CLOSED_COST_STR:C(1*), "
	temp$=temp$+"COMPLETE_YN:C(1*), COST_MASK:C(1*), UNITS_MASK:C(1*), AMT_MASK:C(1*), "	
	temp$=temp$+"COST_MASK_PATTERN:C(1*), UNITS_MASK_PATTERN:C(1*), AMT_MASK_PATTERN:C(1*), "	
	temp$=temp$+"WO_STATUS_LETTER:C(1*), CLOSED_DATE_RAW:C(1*), "	
	temp$=temp$+"ITEM_LEN_PARAM:C(1*),"	; rem Used in MatStd to get more real estate for desc
	temp$=temp$+"PRINT_COSTS:C(1*)"	; rem Used throughout to determine whether cost(s) and cost header(s) prints
	
	rs! = BBJAPI().createMemoryRecordSet(temp$)

rem --- Get Barista System Program directory
	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)
	pgmdir$=stbl("+DIR_PGM",err=*next)
	
rem --- Get masks

	ad_units_mask$=fngetmask$("ad_units_mask","#,###.00",masks$)
	cust_mask$=fngetmask$("cust_mask","000000",masks$)
	sf_pct_mask$=fngetmask$("sf_pct_mask","##0.00%",masks$)
	sf_cost_mask$=fngetmask$("sf_cost_mask","#,##0.00-",masks$)	
	sf_units_mask$=fngetmask$("sf_units_mask","#,##0.00-",masks$)	
	sf_amt_mask$=fngetmask$("sf_amt_mask","##,##0.00-",masks$)	
	
rem --- Make the 'Patterns' used to mask in iReports from Addon masks
rem       examples:
rem          ##0.00;##0.00-   Includes negatives with minus at the end
rem          ##0.00;-##0.00   Includes negatives with minus at the front
rem          ##0.00;##0.00-   Positives only

	sf_cost_mask_pattern$=fngetPattern$(sf_cost_mask$)
	sf_units_mask_pattern$=fngetPattern$(sf_units_mask$)
	sf_amt_mask_pattern$=fngetPattern$(sf_amt_mask$)

rem --- Open files with adc

    files=6,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="ivm-01",ids$[1]="IVM_ITEMMAST"
	files$[2]="sfm-10",ids$[2]="SFC_WOTYPECD"
	files$[3]="arm-01",ids$[3]="ARM_CUSTMAST"
	files$[4]="ivs_params",ids$[4]="IVS_PARAMS"
	files$[5]="sfs_params",ids$[5]="SFS_PARAMS"
    files$[6]="opt-11",ids$[6]="OPT_INVDET"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif
    ivm_itemmast_dev=channels[1]
	sfc_type_dev=channels[2]
	arm_custmast=channels[3]
	ivs_params=channels[4]
	sfs_params=channels[5]
    opt_invdet=channels[6]
	
rem --- Dimension string templates

	dim ivm_itemmast$:templates$[1]
	dim sfc_type$:templates$[2]
	dim arm_custmast$:templates$[3]
	dim ivs_params$:templates$[4]
	dim sfs_params$:templates$[5]
    dim opt_invdet$:templates$[6]
	
goto no_bac_open
rem --- Open Files    
    num_files = 4
    dim open_tables$[1:num_files], open_opts$[1:num_files], open_chans$[1:num_files], open_tpls$[1:num_files]

	open_tables$[1]="IVM_ITEMMAST",   open_opts$[1] = "OTA"
	open_tables$[2]="SFC_WOTYPECD",   open_opts$[2] = "OTA"
	open_tables$[3]="ARM_CUSTMAST",   open_opts$[3] = "OTA"
	open_tables$[4]="IVS_PARAMS",     open_opts$[4] = "OTA"	

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

	ivm_itemmast_dev  = num(open_chans$[1])
	sfc_type_dev = num(open_chans$[2])
	arm_custmast = num(open_chans$[3])
	ivs_params   = num(open_chans$[4])
	
	dim ivm_itemmast$:open_tpls$[1]
	dim sfc_type$:open_tpls$[2]
	dim arm_custmast$:open_tpls$[3]
	dim ivs_params$:open_tpls$[4]	

no_bac_open:
rem --- Get IV Params for Lot/Serial flag and item length
	ivs_params_key$=firm_id$+"IV00"
    find record (ivs_params,key=ivs_params_key$) ivs_params$
	item_len_param$ = ivs_params.item_id_len$

rem --- Get 'Print Costs on Traveler' SF param

	read record (sfs_params,key=firm_id$+"SF00") sfs_params$
	
rem --- Set constant defining whether to print costs 

	if report_type$<>"T" or (report_type$="T" and sfs_params.print_costs$="Y")
		print_costs$="Y"
	else
		print_costs$="N"
	endif	
	
rem --- Build SQL statement
    sql_prep$=""
	where_clause$=" firm_id = '"+firm_id$+"' AND wo_location = '"+wo_loc$+"' AND "
	order_clause$=""

    rem --- Filter on wo_category
    if wo_category$<>"" then
        where_clause$=where_clause$+" wo_category in ("+wo_category$+") AND "
    endif    
	
	sql_prep$="select * from sfe_womastr "
    action=pos(report_seq$="WBCT")-1
    switch action
        case 0
            order_by$=" ORDER BY wo_no "
			if from_wo$<>"" where_clause$=where_clause$+" wo_no >= '"+from_wo$+"' AND "
			if thru_wo$<>"" where_clause$=where_clause$+" wo_no <= '"+thru_wo$+"' AND "
            break
        case 1
            order_by$=" ORDER BY item_id "
			if from_bill$<>"" where_clause$=where_clause$+" item_id >= '"+from_bill$+"' AND "
			if thru_bill$<>"" where_clause$=where_clause$+" item_id <= '"+thru_bill$+"' AND "
			where_clause$=where_clause$+" warehouse_id = '"+wh_id$+"' AND "
			where_clause$=where_clause$+" item_id <> '' AND "
            break
        case 2
            order_by$=" ORDER BY customer_id "
			where_clause$=where_clause$+" customer_id <> '' AND "
			if from_cust$<>"" where_clause$=where_clause$+" customer_id >= '"+from_cust$+"' AND "
			if thru_cust$<>"" where_clause$=where_clause$+" customer_id <= '"+thru_cust$+"' AND "
            break
        case 3
            order_by$=" ORDER BY wo_type "
			if from_type$<>"" where_clause$=where_clause$+" wo_type >= '"+from_type$+"' AND "
			if thru_type$<>"" where_clause$=where_clause$+" wo_type <= '"+thru_type$+"' AND "
            break
        case default
            break
    swend

	rem --- Limit resultset to Opened/Closed/Planned/Quoted based on wostatus$
	rem --- UNLESS all four of them are specified--indicating all

	if len(wostatus$)>0  
:	 and !(pos("O"=wostatus$)>0 and pos("C"=wostatus$)>0 and pos("P"=wostatus$)>0 and pos("Q"=wostatus$)>0)
		where_clause$=where_clause$+" ("
		if pos("O"=wostatus$)>0 where_clause$=where_clause$+" wo_status = 'O' OR "
		if pos("C"=wostatus$)>0 where_clause$=where_clause$+" wo_status = 'C' OR "
		if pos("P"=wostatus$)>0 where_clause$=where_clause$+" wo_status = 'P' OR "
		if pos("Q"=wostatus$)>0 where_clause$=where_clause$+" wo_status = 'Q' OR "
		where_clause$=where_clause$(1,len(where_clause$)-4)+")"
	endif
		
	if len(where_clause$)>0
		where_clause$=" WHERE "+where_clause$
		if where_clause$(len(where_clause$),1)<>")"
			where_clause$=where_clause$(1,len(where_clause$)-4)
		endif
	endif

rem --- Concatenate the pieces of sql_prep$ based on report_type$
rem  	 	report_type$ rem M = WO Detail Rpt from *M*enu
						 rem T = *T*raveler
						 rem E = Detail Rpt from WO *E*ntry
						 rem C = *C*losed WO Detail Rpt

   report_type=pos(report_type$="TCME")-1
    switch report_type
		rem --- For Travelers, limit WO recs based on sfe_openedwo
		case 0
			gosub get_traveler_join
			sql_prep$=travel_join_pre$+sql_prep$+where_clause$+travel_join_post$+order_by$
            break
		rem --- For Close Data Report, limit WO recs based on sfe_closedwo
        case 1
			gosub get_closedwo_join
			sql_prep$=closedwo_join_pre$+sql_prep$+where_clause$+closedwo_join_post$+order_by$
            break
        case 2
			sql_prep$=sql_prep$+where_clause$+order_by$
            break
        case 3
			sql_prep$=sql_prep$+where_clause$+order_by$
            break			
        case default
            break
    swend


	sql_chan=sqlunt
	sqlopen(sql_chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
	sqlprep(sql_chan)sql_prep$
	dim read_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)

rem --- Trip Read

	while 1
		read_tpl$ = sqlfetch(sql_chan,end=*break)

		data! = rs!.getEmptyRecordData()

		dim ivm_itemmast$:fattr(ivm_itemmast$)
		find record (ivm_itemmast_dev,key=firm_id$+read_tpl.item_id$,dom=*next)ivm_itemmast$

		if pos(ivs_params.lotser_flag$="LS") and ivm_itemmast.lotser_item$="Y"
			include_lotser$="Y"
		else	
			include_lotser$="N"
		endif
		
		data!.setFieldValue("FIRM_ID",firm_id$)
		data!.setFieldValue("WO_NO",read_tpl.wo_no$)
		data!.setFieldValue("WO_TYPE",read_tpl.wo_type$)
		data!.setFieldValue("WO_CATEGORY",read_tpl.wo_category$)
		data!.setFieldValue("ITEM_LEN_PARAM",item_len_param$)
		data!.setFieldValue("PRINT_COSTS",print_costs$)		
			
		if read_tpl.wo_status$="O"
			stat$="**"+statusOpen$+"**"
		else
			if read_tpl.wo_status$="P"
				stat$="*"+statusPlanned$+"*"
			else
				if read_tpl.wo_status$="C"
					stat$="*"+statusClosed$+"*"
				else
					if read_tpl.wo_status$="Q"
						stat$="*"+statusQuoted$+"*"
					else				
						stat$=""
					endif
				endif
			endif
		endif
		data!.setFieldValue("WO_STATUS_LETTER",read_tpl.wo_status$)
		data!.setFieldValue("WO_STATUS",read_tpl.wo_status$+" "+stat$)
		if cvs(read_tpl.customer_id$,3)<>""
			dim arm_custmast$:fattr(arm_custmast$)
			read record (arm_custmast,key=firm_id$+read_tpl.customer_id$,dom=*next) arm_custmast$
			data!.setFieldValue("CUSTOMER_ID","Customer: "+fnmask$(read_tpl.customer_id$,cust_mask$)+" "+arm_custmast.customer_name$)
			if num(read_tpl.order_no$)<>0
                readrecord (opt_invdet,key=firm_id$+opt_invdet.ar_type$+read_tpl.customer_id$+read_tpl.order_no$+opt_invdet.ar_inv_no$+read_tpl.sls_ord_seq_ref$,dom=*next)opt_invdet$
                data!.setFieldValue("SLS_ORDER_NO","Sales Order: "+read_tpl.order_no$+"-"+opt_invdet.line_no$)
			endif
		endif
		data!.setFieldValue("WAREHOUSE_ID",read_tpl.warehouse_id$)
		data!.setFieldValue("ITEM_ID",read_tpl.item_id$)
		data!.setFieldValue("OPENED_DATE",fndate$(read_tpl.opened_date$))
		data!.setFieldValue("CLOSED_DATE_RAW",read_tpl.closed_date$)
		data!.setFieldValue("LAST_CLOSE",fndate$(read_tpl.closed_date$))
		if cvs(read_tpl.closed_date$,3)="" data!.setFieldValue("LAST_CLOSE","")
		dim sfc_type$:fattr(sfc_type$)
		sfc_type.code_desc$="Code Not Found"
		read record (sfc_type_dev,key=firm_id$+"A"+read_tpl.wo_type$,dom=*next) sfc_type$
		data!.setFieldValue("TYPE_DESC",sfc_type.code_desc$)
		data!.setFieldValue("PRIORITY",read_tpl.priority$)
		data!.setFieldValue("UOM",read_tpl.unit_measure$)
		data!.setFieldValue("YIELD",str(read_tpl.est_yield:sf_pct_mask$))
		data!.setFieldValue("PROD_QTY",str(read_tpl.sch_prod_qty:ad_units_mask$))
		data!.setFieldValue("COMPLETED",str(read_tpl.qty_cls_todt:ad_units_mask$))
		data!.setFieldValue("LAST_ACT_DATE",fndate$(read_tpl.lstact_date$))
		if cvs(read_tpl.lstact_date$,3)="" data!.setFieldValue("LAST_ACT_DATE","")
		if cvs(ivm_itemmast.item_desc$,3)=""
			data!.setFieldValue("ITEM_DESC_1",read_tpl.description_01$)
			data!.setFieldValue("ITEM_DESC_2",read_tpl.description_02$)
		else
			data!.setFieldValue("ITEM_DESC_1",ivm_itemmast.item_desc$)
		endif
        if cvs(ivm_itemmast.image_path$,2)<>"" then
            rem --- Get real path to image from image_path, which may include an STBL for the image dir
            image_dir$=""
            image_path$=cvs(ivm_itemmast.image_path$,2)
            if pos("["=image_path$) and pos("]+"=image_path$) then
                image_dir$=stbl(image_path$(pos("["=image_path$)+1,pos("]+"=image_path$)-2),err=*next)
                image_path$=image_path$(pos("]+"=image_path$)+2)
            endif
            if image_path$(1,1)=$22$ then image_path$=image_path$(2) 
            if image_path$(len(image_path$))=$22$ then image_path$=image_path$(1,len(image_path$)-1)
            if image_dir$<>"" then image_path$=image_dir$+image_path$
            image_file$=BBjAPI().getFileSystem().resolvePath(image_path$,err=*endif)
            data!.setFieldValue("IMAGE_PATH",image_file$)
        endif
		data!.setFieldValue("DRAWING_NO",read_tpl.drawing_no$)
		data!.setFieldValue("REV",read_tpl.drawing_rev$)
		data!.setFieldValue("INCLUDE_LOTSER",include_lotser$)
		data!.setFieldValue("MAST_CLS_INP_QTY_STR",str(read_tpl.cls_inp_qty:sf_units_mask$))
		data!.setFieldValue("MAST_CLS_INP_DT",fndate$(read_tpl.cls_inp_date$))
		data!.setFieldValue("MAST_CLOSED_COST_STR",str(read_tpl.closed_cost:sf_cost_mask$))
		if read_tpl.complete_flg$<>"Y"
			data!.setFieldValue("COMPLETE_YN","N")			
		else
			data!.setFieldValue("COMPLETE_YN",read_tpl.complete_flg$)
		endif
		data!.setFieldValue("COST_MASK",sf_cost_mask$)	
		data!.setFieldValue("UNITS_MASK",sf_units_mask$)
		data!.setFieldValue("AMT_MASK",sf_amt_mask$)		

		data!.setFieldValue("COST_MASK_PATTERN",sf_cost_mask_pattern$); rem Pattern used in iReports
		data!.setFieldValue("UNITS_MASK_PATTERN",sf_units_mask_pattern$); rem Pattern used in iReports
		data!.setFieldValue("AMT_MASK_PATTERN",sf_amt_mask_pattern$); rem Pattern used in iReports

		rs!.insert(data!)
	wend
	
rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit

rem --- Build JOIN to wrap Traveler print file, sfe_openedwo, around sfe_womastr JOIN
get_traveler_join:
	tj_pre$=""
	tj_pre$=tj_pre$+"SELECT m.firm_id"
    tj_pre$=tj_pre$+"     , m.wo_location"
    tj_pre$=tj_pre$+"     , m.wo_no"
    tj_pre$=tj_pre$+"     , m.wo_type"
    tj_pre$=tj_pre$+"     , m.wo_category"
    tj_pre$=tj_pre$+"     , m.wo_status"
    tj_pre$=tj_pre$+"     , m.customer_id"
    tj_pre$=tj_pre$+"     , m.order_no"
    tj_pre$=tj_pre$+"     , m.sls_ord_seq_ref"
    tj_pre$=tj_pre$+"     , m.unit_measure"
    tj_pre$=tj_pre$+"     , m.bill_rev"
    tj_pre$=tj_pre$+"     , m.warehouse_id"
    tj_pre$=tj_pre$+"     , m.item_id"
    tj_pre$=tj_pre$+"     , m.opened_date"
    tj_pre$=tj_pre$+"     , m.eststt_date"
    tj_pre$=tj_pre$+"     , m.estcmp_date"
    tj_pre$=tj_pre$+"     , m.act_st_date"
    tj_pre$=tj_pre$+"     , m.lstact_date"
    tj_pre$=tj_pre$+"     , m.closed_date"
    tj_pre$=tj_pre$+"     , m.description_01"
    tj_pre$=tj_pre$+"     , m.description_02"
    tj_pre$=tj_pre$+"     , m.drawing_no"
    tj_pre$=tj_pre$+"     , m.drawing_rev"
    tj_pre$=tj_pre$+"     , m.complete_flg"
    tj_pre$=tj_pre$+"     , m.recalc_flag"
    tj_pre$=tj_pre$+"     , m.lotser_item"
    tj_pre$=tj_pre$+"     , m.priority"
    tj_pre$=tj_pre$+"     , m.sched_flag"
    tj_pre$=tj_pre$+"     , m.forecast"
    tj_pre$=tj_pre$+"     , m.cls_inp_date"
    tj_pre$=tj_pre$+"     , m.sch_prod_qty"
    tj_pre$=tj_pre$+"     , m.qty_cls_todt"
    tj_pre$=tj_pre$+"     , m.cls_cst_todt"
    tj_pre$=tj_pre$+"     , m.cls_inp_qty"
    tj_pre$=tj_pre$+"     , m.closed_cost"
    tj_pre$=tj_pre$+"     , m.est_yield "
	tj_pre$=tj_pre$+" FROM sfe_openedwo AS o"
	tj_pre$=tj_pre$+" INNER JOIN ( "
	
	tj_post$=""
	tj_post$=tj_post$+") AS m "
	tj_post$=tj_post$+"ON o.firm_id=m.firm_id AND "
	tj_post$=tj_post$+"   o.wo_location=m.wo_location AND "
	tj_post$=tj_post$+"   o.wo_no=m.wo_no "
		
	travel_join_pre$=tj_pre$
	travel_join_post$=tj_post$
	
	return

rem --- Build JOIN to wrap Closed WO print file, sfe_closedwo, around sfe_womastr JOIN
get_closedwo_join:
	cw_pre$=""
	cw_pre$=cw_pre$+"SELECT m.firm_id"
    cw_pre$=cw_pre$+"     , m.wo_location"
    cw_pre$=cw_pre$+"     , m.wo_no"
    cw_pre$=cw_pre$+"     , m.wo_type"
    cw_pre$=cw_pre$+"     , m.wo_category"
    cw_pre$=cw_pre$+"     , m.wo_status"
    cw_pre$=cw_pre$+"     , m.customer_id"
    cw_pre$=cw_pre$+"     , m.order_no"
    cw_pre$=cw_pre$+"     , m.sls_ord_seq_ref"
    cw_pre$=cw_pre$+"     , m.unit_measure"
    cw_pre$=cw_pre$+"     , m.bill_rev"
    cw_pre$=cw_pre$+"     , m.warehouse_id"
    cw_pre$=cw_pre$+"     , m.item_id"
    cw_pre$=cw_pre$+"     , m.opened_date"
    cw_pre$=cw_pre$+"     , m.eststt_date"
    cw_pre$=cw_pre$+"     , m.estcmp_date"
    cw_pre$=cw_pre$+"     , m.act_st_date"
    cw_pre$=cw_pre$+"     , m.lstact_date"
    cw_pre$=cw_pre$+"     , m.closed_date"
    cw_pre$=cw_pre$+"     , m.description_01"
    cw_pre$=cw_pre$+"     , m.description_02"
    cw_pre$=cw_pre$+"     , m.drawing_no"
    cw_pre$=cw_pre$+"     , m.drawing_rev"
    cw_pre$=cw_pre$+"     , m.complete_flg"
    cw_pre$=cw_pre$+"     , m.recalc_flag"
    cw_pre$=cw_pre$+"     , m.lotser_item"
    cw_pre$=cw_pre$+"     , m.priority"
    cw_pre$=cw_pre$+"     , m.sched_flag"
    cw_pre$=cw_pre$+"     , m.forecast"
    cw_pre$=cw_pre$+"     , m.cls_inp_date"
    cw_pre$=cw_pre$+"     , m.sch_prod_qty"
    cw_pre$=cw_pre$+"     , m.qty_cls_todt"
    cw_pre$=cw_pre$+"     , m.cls_cst_todt"
    cw_pre$=cw_pre$+"     , m.cls_inp_qty"
    cw_pre$=cw_pre$+"     , m.closed_cost"
    cw_pre$=cw_pre$+"     , m.est_yield "
	cw_pre$=cw_pre$+" FROM sfe_closedwo AS c"
	cw_pre$=cw_pre$+" INNER JOIN ( "
	
	cw_post$=""
	cw_post$=cw_post$+") AS m "
	cw_post$=cw_post$+"ON c.firm_id=m.firm_id AND "
	cw_post$=cw_post$+"   c.wo_location=m.wo_location AND "
	cw_post$=cw_post$+"   c.wo_no=m.wo_no "

		
	closedwo_join_pre$=cw_pre$
	closedwo_join_post$=cw_post$
	
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

rem --- fngetPattern$: Build iReports 'Pattern' from Addon Mask
	def fngetPattern$(q$)
		q1$=q$
		if len(q$)>0
			if pos("-"=q$)
				q1=pos("-"=q$)
				if q1=len(q$)
					q1$=q$(1,len(q$)-1)+";"+q$; rem Has negatives with minus at the end =>> ##0.00;##0.00-
				else
					q1$=q$(2,len(q$)-1)+";"+q$; rem Has negatives with minus at the front =>> ##0.00;-##0.00
				endif
			endif
			if pos("CR"=q$)=len(q$)-1
				q1$=q$(1,pos("CR"=q$)-1)+";"+q$
			endif
			if q$(1,1)="(" and q$(len(q$),1)=")"
				q1$=q$(2,len(q$)-2)+";"+q$
			endif
		endif
		return q1$
	fnend	

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num
	
	std_exit:
	
	end
