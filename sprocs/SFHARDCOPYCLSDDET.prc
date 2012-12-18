rem ----------------------------------------------------------------------------
rem Program: SFHARDCOPYClsdDet.prc
rem Description: Stored Procedure to get the Shop Floor Hard Copy WO Close Detail into iReports
rem Used for Hard Copy, Traveler, Work Order Closed Detail and Work Order Detail
rem
rem Author(s): C. Johnson
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

	firm_id$     	= sp!.getParameter("FIRM_ID")
	wo_loc$      	= sp!.getParameter("WO_LOCATION")
	wo_no$       	= sp!.getParameter("WO_NO")
	barista_wd$  	= sp!.getParameter("BARISTA_WD")
	masks$       	= sp!.getParameter("MASKS")
	wo_category$ 	= sp!.getParameter("WO_CATEGORY")
	warehouse_id$	= sp!.getParameter("WAREHOUSE_ID")
	item_id$     	= sp!.getParameter("ITEM_ID")
	wo_type$     	= sp!.getParameter("WO_TYPE")
	prevper_enddate$= sp!.getParameter("SF_PREVPER_ENDDATE")
	wo_status$		= sp!.getParameter("WO_STATUS_LETTER")
	wo_clsddate$ 	= sp!.getParameter("CLOSED_DATE_RAW")
	
rem ---
	
	sv_wd$=dir("")
	chdir barista_wd$

rem --- Create a memory record set to hold results.
rem --- Columns for the record set are defined using a string template

	      temp$="CLOSED_DATE:C(1*), WO_TYPE:C(1*), WO_TYPE_DESC:C(1*), "
	temp$=temp$+"LSTACT_DATE:C(1*), LSTACT_DATE_RAW:C(1*), CLS_INP_DATE_RAW:C(1*), "
	temp$=temp$+"COMPLETE_YN:C(1*), CLOSE_AT_STD_ACT:C(1*), "
	temp$=temp$+"CURR_PROD_QTY:C(1*), PRIOR_CLSD_QTY:C(1*), THIS_CLOSE_QTY:C(1*), "
	temp$=temp$+"BAL_STILL_OPEN_QTY:C(1*), IV_UNIT_COST:C(1*), WO_COST_AT_STD:C(1*), "
	temp$=temp$+"WO_COST_AT_ACT:C(1*), PRIOR_CLOSED_AMT:C(1*), CURR_WIP_VALUE:C(1*), "
	temp$=temp$+"CURR_CLOSE_VALUE:C(1*), "

	temp$=temp$+"PerUnit_WO_COST_AT_STD:C(1*), PerUnit_WO_COST_AT_ACT:C(1*), "
	temp$=temp$+"PerUnit_PRIOR_CLOSED_AMT:C(1*), PerUnit_CURR_WIP_VALUE:C(1*), "
	temp$=temp$+"PerUnit_CURR_CLOSE_VALUE:C(1*), "

	rem -- GL
	temp$=temp$+"WIP_PRINT_FLAG:C(1*), "
	temp$=temp$+"WIP_GL_ACCT_NUM:C(1*), WIP_GL_ACCT_DESC:C(1*), WIP_GL_ACCT_TYPE:C(1*), "
	temp$=temp$+"WIP_GL_DEBIT_AMT:C(1*), WIP_GL_CREDIT_AMT:C(1*), WIP_GL_DEBIT_PERUNIT:C(1*), "
	temp$=temp$+"WIP_GL_CREDIT_PERUNIT:C(1*), "
	
	temp$=temp$+"CLS_TO_PRINT_FLAG:C(1*), "
	temp$=temp$+"CLS_TO_GL_ACCT_NUM:C(1*), CLS_TO_GL_ACCT_DESC:C(1*), CLS_TO_GL_ACCT_TYPE:C(1*), "
	temp$=temp$+"CLS_TO_GL_DEBIT_AMT:C(1*), CLS_TO_GL_CREDIT_AMT:C(1*), CLS_TO_GL_DEBIT_PERUNIT:C(1*), "
	temp$=temp$+"CLS_TO_GL_CREDIT_PERUNIT:C(1*), "
	
	temp$=temp$+"DIR_VAR_PRINT_FLAG:C(1*), "
	temp$=temp$+"DIR_VAR_GL_ACCT_NUM:C(1*), DIR_VAR_GL_ACCT_DESC:C(1*), DIR_VAR_GL_ACCT_TYPE:C(1*), "
	temp$=temp$+"DIR_VAR_GL_DEBIT_AMT:C(1*), DIR_VAR_GL_CREDIT_AMT:C(1*), DIR_VAR_GL_DEBIT_PERUNIT:C(1*), "
	temp$=temp$+"DIR_VAR_GL_CREDIT_PERUNIT:C(1*), "
	
	temp$=temp$+"OVRH_VAR_PRINT_FLAG:C(1*), "
	temp$=temp$+"OVRH_VAR_GL_ACCT_NUM:C(1*), OVRH_VAR_GL_ACCT_DESC:C(1*), OVRH_VAR_GL_ACCT_TYPE:C(1*), "
	temp$=temp$+"OVRH_VAR_GL_DEBIT_AMT:C(1*), OVRH_VAR_GL_CREDIT_AMT:C(1*), OVRH_VAR_GL_DEBIT_PERUNIT:C(1*), "
	temp$=temp$+"OVRH_VAR_GL_CREDIT_PERUNIT:C(1*), "
	
	temp$=temp$+"MAT_VAR_PRINT_FLAG:C(1*), "
	temp$=temp$+"MAT_VAR_GL_ACCT_NUM:C(1*), MAT_VAR_GL_ACCT_DESC:C(1*), MAT_VAR_GL_ACCT_TYPE:C(1*), "
	temp$=temp$+"MAT_VAR_GL_DEBIT_AMT:C(1*), MAT_VAR_GL_CREDIT_AMT:C(1*), MAT_VAR_GL_DEBIT_PERUNIT:C(1*), "
	temp$=temp$+"MAT_VAR_GL_CREDIT_PERUNIT:C(1*), "
	
	temp$=temp$+"SUB_VAR_PRINT_FLAG:C(1*), "
	temp$=temp$+"SUB_VAR_GL_ACCT_NUM:C(1*), SUB_VAR_GL_ACCT_DESC:C(1*), SUB_VAR_GL_ACCT_TYPE:C(1*), "
	temp$=temp$+"SUB_VAR_GL_DEBIT_AMT:C(1*), SUB_VAR_GL_CREDIT_AMT:C(1*), SUB_VAR_GL_DEBIT_PERUNIT:C(1*), "
	temp$=temp$+"SUB_VAR_GL_CREDIT_PERUNIT:C(1*),"
	
	temp$=temp$+"GL_DEBIT_COLTOT:C(1*), GL_CREDIT_COLTOT:C(1*), "
	temp$=temp$+"GL_DEBIT_PERUNIT_COLTOT:C(1*), GL_CREDIT_PERUNIT_COLTOT:C(1*) "
	
	rs! = BBJAPI().createMemoryRecordSet(temp$)

rem --- Get Barista System Program directory

	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)
	pgmdir$=stbl("+DIR_PGM",err=*next)

rem --- Get masks
	
	gl_acct_mask$=fngetmask$("gl_acct_mask","000-000",masks$)		
	
rem --- Open files with adc	    

    files=5,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="ivm-01",ids$[1]="IVM_ITEMMAST"
    files$[2]="ivm-02",ids$[2]="IVM_ITEMWHSE"	
	files$[3]="ARC_DISTCODE",ids$[3]="ARC_DISTCODE"
	files$[4]="ARS_PARAMS",ids$[4]="ARS_PARAMS"
	files$[5]="glm-01",ids$[5]="GLM_ACCT"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
    if status goto std_exit
	
    ivm_itemmast_dev=channels[1]
    ivm_itemwhse_dev=channels[2]	
	arc_distcode_dev=channels[3]
	ars_params_dev=channels[4]
	glm_acct_dev=channels[5]
	
rem --- Dimension string templates

	dim ivm_itemmast$:templates$[1]
    dim ivm_itemwhse$:templates$[2]	
	dim arc_distcode$:templates$[3]
	dim ars_params$:templates$[4]
	dim glm_acct$:templates$[5]
	
rem --- Get AR Params for Distribute by Item flag
	ars_params_key$=firm_id$+"AR00"
    find record (ars_params_dev,key=ars_params_key$) ars_params$	

rem --- Init
	dim GL_Acct_amts[5]; 	rem One per row of possible accts listed
	
	default_precision=tcb(14)
	precision default_precision

rem --- Use SQL queries to gather needed data

	rem --- Use VIEWs, SF_OPNTRAN_VALS and SF_COSTSUMS_ACTO, for Open Transactions 
	rem ---  (NOTE: Closed WO Det and Summary do not use Closed Transactions) 
	rem ---		SFT_OPNOPRTR sft-01
	rem ---		SFT_OPNMATTR sft-21
	rem ---		SFT_OPNSUBTR sft-31
		
		tran_val_view$=" SF_OPNTRAN_VALS "
		tran_costsums_view$=" SF_COSTSUMS_ACTO "; rem ACTO=Use Open Trans files to accum Actual
		
	rem --- Build Main query 
		rem --- Build select statement (cols we want returned from the SQL query)

			select$=""
			select$=select$+"wo.CLOSED_DATE,  wo.WO_TYPE,      wo.COMPLETE_FLG, "
			select$=select$+"wo.LSTACT_DATE,  wo.CLS_INP_DATE, wo.SCH_PROD_QTY, "
			select$=select$+"wo.CLS_INP_QTY,  wo.QTY_CLS_TODT, wo.CLS_CST_TODT, "
			select$=select$+"wo.CLOSED_COST,  wo.RECALC_FLAG, "

			select$=select$+"typ.CODE_DESC,   typ.STDACT_FLAG, typ.GL_PUR_ACCT, "
			select$=select$+"typ.GL_WIP_ACCT, typ.GL_CLOSE_TO, typ.GL_LAB_VAR, "
			select$=select$+"typ.GL_OVH_VAR,  typ.GL_MAT_VAR,  typ.GL_SUB_VAR, "			
			
			select$=select$+"wh.UNIT_COST,    req.TOT_STD_COST,act.TOT_ACT_COST, "
			select$=select$+"cs_std.TOT_STD_DIR_COST, cs_std.TOT_STD_OVH_COST, "	
			select$=select$+"cs_std.TOT_STD_MAT_COST, cs_std.TOT_STD_SUB_COST, "	
			
			select$=select$+"cs_act.TOT_ACT_DIR_COST, cs_act.TOT_ACT_OVH_COST, "	
			select$=select$+"cs_act.TOT_ACT_MAT_COST, cs_act.TOT_ACT_SUB_COST, "	
			select$=select$+"cs_act.TOT_ACT_OPS_COST "			
			
			
		rem --- Build clause for getting the Transactions/Actual cost of WO
		rem ---   Note: This SQL query's resultset(a table) will be JOINed in main query
			actuals$=""
			actuals$=actuals$+" (SELECT tran.Firm_ID"
			actuals$=actuals$+"        ,tran.WO_Location"
			actuals$=actuals$+"        ,tran.WO_No"
			actuals$=actuals$+"        ,SUM(tran.Ext_Cost) AS TOT_ACT_COST"
			actuals$=actuals$+"  FROM "+tran_val_view$+" AS tran"; rem The VIEW used here is determined above
			actuals$=actuals$+"  GROUP BY tran.Firm_ID,tran.WO_Location,tran.WO_No"; rem SUM() based on firm+loc+woNo
			actuals$=actuals$+" ) AS act  "
			
		rem --- Build clause for getting the total Standard/Requirement cost of WO
		rem ---   Note: This SQL query's resultset(a table) will be JOINed in main query
			requirements$=""
			requirements$=requirements$+" (SELECT std.Firm_ID"
			requirements$=requirements$+"        ,std.WO_Location"
			requirements$=requirements$+"        ,std.WO_No"
			requirements$=requirements$+"        ,SUM(std.Total_Cost) AS TOT_STD_COST"
			requirements$=requirements$+"  FROM SF_WO_REQ_VALS AS std"
			requirements$=requirements$+"  GROUP BY std.Firm_ID,std.WO_Location,std.WO_No"; rem SUM() based on firm+loc+woNo
			requirements$=requirements$+" ) AS req  "
			
		rem --- Build clause for getting the Standard Requirements' accumulated costs for GL breakdown (direct, overhead, Mat, Sub)
		rem ---   Note: This SQL query's resultset(a table) will be JOINed in main query
			costsums_std$=""
			costsums_std$=costsums_std$+" (SELECT * "
			costsums_std$=costsums_std$+"  FROM SF_COSTSUMS_STD"
			costsums_std$=costsums_std$+" ) AS cs_std  "

		rem --- Build clause for getting the Standard Requirements' accumulated costs for GL breakdown (direct, overhead, Mat, Sub)
		rem ---   Note: This SQL query's resultset(a table) will be JOINed in main query
			costsums_act$=""
			costsums_act$=costsums_act$+" (SELECT * "
			costsums_act$=costsums_act$+"  FROM "+tran_costsums_view$+" "
			costsums_act$=costsums_act$+" ) AS cs_act  "

						
		rem --- Build the complete SQL SELECT statement

			sql_prep$=""
			sql_prep$=sql_prep$+"SELECT "+select$
			sql_prep$=sql_prep$+"FROM "+requirements$; rem The query, requirements$, is used here as a table
			sql_prep$=sql_prep$+"INNER JOIN SFE_WOMASTR AS wo "
			sql_prep$=sql_prep$+"	ON req.Firm_ID+req.WO_Location+req.WO_No "
			sql_prep$=sql_prep$+"	 = wo.Firm_ID+wo.WO_Location+wo.WO_No "
			sql_prep$=sql_prep$+"LEFT JOIN "+actuals$; rem The query, actuals$, is used here as a table; LEFT JOIN since there may not be transactions
			sql_prep$=sql_prep$+"	ON act.Firm_ID+act.WO_Location+act.WO_No "
			sql_prep$=sql_prep$+"	 = wo.Firm_ID+wo.WO_Location+wo.WO_No "	
			sql_prep$=sql_prep$+"LEFT JOIN "+costsums_std$; rem The query, costsums_std$, is used here as a table; LEFT JOIN since there may not be cs_stdations
			sql_prep$=sql_prep$+"	ON cs_std.Firm_ID+cs_std.WO_Location+cs_std.WO_No "
			sql_prep$=sql_prep$+"	 = wo.Firm_ID+wo.WO_Location+wo.WO_No "				
			sql_prep$=sql_prep$+"LEFT JOIN "+costsums_act$; rem The query, costsums_act$, is used here as a table; LEFT JOIN since there may not be cs_actations
			sql_prep$=sql_prep$+"	ON cs_act.Firm_ID+cs_act.WO_Location+cs_act.WO_No "
			sql_prep$=sql_prep$+"	 = wo.Firm_ID+wo.WO_Location+wo.WO_No "	
			sql_prep$=sql_prep$+"LEFT JOIN IVM_ITEMWHSE AS wh "; rem To get IV UnitCost, if there
			sql_prep$=sql_prep$+"	ON wo.firm_id+wo.warehouse_id+wo.item_id "
			sql_prep$=sql_prep$+"	 = wh.firm_id+wh.warehouse_id+wh.item_id "
			sql_prep$=sql_prep$+"LEFT JOIN SFC_WOTYPECD AS typ "; rem To get TypeCode Desc, STDACT_FLAG, & GL accts, if there
			sql_prep$=sql_prep$+"       ON wo.Firm_ID+'A'+wo.WO_Type "
			sql_prep$=sql_prep$+"        = typ.Firm_ID+'A'+typ.WO_Type	"
			sql_prep$=sql_prep$+"WHERE wo.Firm_ID + wo.WO_Location + wo.WO_No  "; rem Limit to firm+WO_No
			sql_prep$=sql_prep$+"    = '"+firm_id$ + wo_loc$+ wo_no$+"' "
			
			sql_chan=sqlunt
			sqlopen(sql_chan,err=*next)stbl("+DBNAME")
			sqlprep(sql_chan)sql_prep$
			dim read_tpl$:sqltmpl(sql_chan)
			sqlexec(sql_chan)

			read_tpl$ = sqlfetch(sql_chan,end=*break)
		
rem --- Assign values from SQL query

	closed_date$ 	 	= read_tpl.CLOSED_DATE$
	WO_TypeCode_desc$ 	= read_tpl.CODE_DESC$
	lstact_date_raw$ 	= read_tpl.LSTACT_DATE$
	cls_inp_date_raw$	= read_tpl.CLS_INP_DATE$
	curr_prod_qty 	 	= read_tpl.SCH_PROD_QTY
	prior_clsd_qty 	 	= read_tpl.QTY_CLS_TODT
	this_close_qty 	 	= read_tpl.CLS_INP_QTY
	complete_yn$ 	 	= read_tpl.COMPLETE_FLG$
	recalc_flag$ 		= read_tpl.RECALC_FLAG$

	IF complete_yn$<>"Y" THEN 
		LET bal_still_open_qty=curr_prod_qty-(prior_clsd_qty+this_close_qty)
	else
		bal_still_open_qty=0
	endif

	closed_cost         = read_tpl.CLOSED_COST
	iv_unit_cost 	 	= read_tpl.UNIT_COST; rem NOTE: v6 had a bug and was using MaxQty here.
	wo_cost_at_std 	 	= read_tpl.TOT_STD_COST
	close_at_std_act$	= read_tpl.STDACT_FLAG$
	wo_cost_at_act 	 	= read_tpl.TOT_ACT_COST
	prior_closed_amt 	= read_tpl.CLS_CST_TODT
	
	curr_wip_value 		= wo_cost_at_act - prior_closed_amt
	curr_close_value	= this_close_qty * closed_cost
	
	wo_std_dir_Cost		= read_tpl.TOT_STD_DIR_COST
	wo_std_Ovh_Cost		= read_tpl.TOT_STD_OVH_COST
	wo_std_mat_Cost		= read_tpl.TOT_STD_MAT_COST
	wo_std_sub_Cost		= read_tpl.TOT_STD_SUB_COST
			
	wo_act_dir_Cost		= read_tpl.TOT_ACT_DIR_COST
	wo_act_Ovh_Cost		= read_tpl.TOT_ACT_OVH_COST
	wo_act_mat_Cost		= read_tpl.TOT_ACT_MAT_COST
	wo_act_sub_Cost		= read_tpl.TOT_ACT_SUB_COST
	wo_act_Ops_Cost		= read_tpl.TOT_ACT_OPS_COST		

	rem --- Per Unit values from SQL query
	if curr_prod_qty<>0 then
		PerUnit_wo_cost_at_std = wo_cost_at_std/curr_prod_qty
	else
		PerUnit_wo_cost_at_std = 0 
	endif
	
	if curr_prod_qty<>0 then
		PerUnit_wo_cost_at_act = wo_cost_at_act/curr_prod_qty
	else
		PerUnit_wo_cost_at_act = 0
	endif
	
	if prior_clsd_qty<>0 then 
		PerUnit_prior_closed_amt = prior_closed_amt/prior_clsd_qty
	else
		PerUnit_prior_closed_amt = 0
	endif
	
	if this_close_qty + bal_still_open_qty <>0 then
		PerUnit_curr_wip_value = curr_wip_value/(this_close_qty + bal_still_open_qty)
	else
		PerUnit_curr_wip_value = 0
	endif
	
	if this_close_qty<>0 then
		PerUnit_curr_close_value = curr_close_value/this_close_qty
	else
		PerUnit_curr_close_value = 0
	endif

	rem --- GL accts from SQL query (from JOIN to WO Type Code)
	gl_wip_acct$  	  = read_tpl.GL_WIP_ACCT$
	gl_close_to_acct$ = read_tpl.GL_CLOSE_TO$
	gl_pur_acct$	  = read_tpl.GL_PUR_ACCT$
	gl_lab_var_acct$  = read_tpl.GL_LAB_VAR$
	gl_ovh_var_acct$  = read_tpl.GL_OVH_VAR$
	gl_mat_var_acct$  = read_tpl.GL_MAT_VAR$
	gl_sub_var_acct$  = read_tpl.GL_SUB_VAR$
	
rem ========================== beg wor.eb 2070-2140 =======================================
rem --- GL account/postings section	
rem --- Store appropriate amounts in GL_Acct_amts[]
			rem [0] Work in Process
			rem [1] Close to Account
			rem [2] Direct Variance
			rem [3] Overhead Variance
			rem [4] Material Variance
			rem [5] Subcontract Variance
rem --- Decide which columns to populate with those values (Debit or Credit)			
		
	rem --- Init
		dim GL_Acct_amts[5]; 	rem One per row of possible accts listed
		
	rem --- Get GL Inventory Acct based on Dist By Item (for Category 'I' items)
		if wo_category$="I" then
            find record (ivm_itemmast_dev,key=firm_id$+item_id$,dom=Read_WOTypeCd) ivm_itemmast$
            if ars_params.DIST_BY_ITEM$<>"Y" then
                gl_inventory_acct$=ivm_itemmast.gl_inv_acct$
            else
                find record (ivm_itemwhse_dev,key=firm_id$+warehouse_id$+item_id$,dom=Read_WOTypeCd) ivm_itemwhse$
                distribution_code$=ivm_itemwhse.ar_dist_code$
                find record (arc_distcode_dev,key=firm_id$+"D"+distribution_code$,dom=Read_WOTypeCd) arc_distcode$
                gl_inventory_acct$=arc_distcode.gl_inv_acct$; rem "Set the closed to account...
            endif
        endif
	
	Read_WOTypeCd:
	rem --- Get GL Accounts from WO Type Code
        if wo_category$="I" then 
            gl_close_to_acct$=gl_inventory_acct$
        endif
rem ========================== end wor.eb 2070-2140 =======================================

rem --- Calculate Postings to GL

		precision 2
		
        GL_Acct_amts[0]=-curr_wip_value; rem WIP acct
        GL_Acct_amts[1]=curr_close_value; rem Inventory acct

        if complete_yn$<>"Y"
            GL_Acct_amts[0]=-curr_close_value
        else
            if close_at_std_act$="A" 
                GL_Acct_amts[1]=curr_wip_value
            else
			rem --- Calculate Variance Postings
                precision default_precision
				if wo_category$<>"I" and (curr_prod_qty=prior_clsd_qty+this_close_qty 
:									      or wo_cost_at_std=0 
:										  or recalc_flag$="N") then
                    prorte=(this_close_qty*closed_cost)+prior_closed_amt
                else
				rem --- Prorate Standards If Needed
                    if wo_category$<>"I"
                        if curr_prod_qty<>0 
                            prorte=wo_cost_at_std*(prior_clsd_qty+this_close_qty)/curr_prod_qty
                        else
                            prorte=0
                        endif
                    else
                        prorte=(this_close_qty*closed_cost)+prior_closed_amt
                    endif

                    if prorte<>wo_cost_at_std 
                        if wo_cost_at_std=0 
                            wo_std_dir_Cost=0
							wo_std_mat_Cost=0
							wo_std_sub_Cost=0
                        else
                            wo_std_dir_Cost=wo_std_dir_Cost*prorte/wo_cost_at_std
                            wo_std_mat_Cost=wo_std_mat_Cost*prorte/wo_cost_at_std 
                            wo_std_sub_Cost=wo_std_sub_Cost*prorte/wo_cost_at_std
                        endif
                       rem  u[9]=prorte-(wo_std_dir_Cost+wo_std_mat_Cost+wo_std_sub_Cost) rem'd because apparently not used
                    endif
                endif
				
rem --- Now Calculate Variances
                precision 2
				
                GL_Acct_amts[2]=(wo_act_dir_Cost-wo_std_dir_Cost)*1 
                GL_Acct_amts[4]=(wo_act_mat_Cost-wo_std_mat_Cost)*1 
				GL_Acct_amts[5]=(wo_act_sub_Cost-wo_std_sub_Cost)*1
                GL_Acct_amts[3]=(wo_cost_at_act-prorte-(GL_Acct_amts[2]+GL_Acct_amts[4]+GL_Acct_amts[5]))*1
                GL_Acct_amts[0]=GL_Acct_amts[0]*1
                GL_Acct_amts[1]=GL_Acct_amts[1]*1
            endif
        endif

rem --- Print totals (Send non-GL data)
	data! = rs!.getEmptyRecordData()
	data!.setFieldValue("CLOSED_DATE",fndate$(closed_date$))
	data!.setFieldValue("WO_TYPE",wo_type$)
	data!.setFieldValue("WO_TYPE_DESC",WO_TypeCode_desc$)
	data!.setFieldValue("LSTACT_DATE",fndate$(lstact_date_raw$))
	data!.setFieldValue("LSTACT_DATE_RAW",lstact_date_raw$)	
	data!.setFieldValue("CLS_INP_DATE_RAW",cls_inp_date_raw$)
	
	data!.setFieldValue("CURR_PROD_QTY",str(curr_prod_qty))
	data!.setFieldValue("PRIOR_CLSD_QTY",str(prior_clsd_qty))
	data!.setFieldValue("THIS_CLOSE_QTY",str(this_close_qty))
	data!.setFieldValue("BAL_STILL_OPEN_QTY",str(bal_still_open_qty))
	
	data!.setFieldValue("COMPLETE_YN",complete_yn$)

	data!.setFieldValue("IV_UNIT_COST",str(iv_unit_cost))
	data!.setFieldValue("WO_COST_AT_STD",str(wo_cost_at_std))

	data!.setFieldValue("CLOSE_AT_STD_ACT",close_at_std_act$)

	data!.setFieldValue("WO_COST_AT_ACT",str(wo_cost_at_act))
	data!.setFieldValue("PRIOR_CLOSED_AMT",str(prior_closed_amt))
	data!.setFieldValue("CURR_WIP_VALUE",str(curr_wip_value))
	data!.setFieldValue("CURR_CLOSE_VALUE",str(curr_close_value))
	
	data!.setFieldValue("PerUnit_WO_COST_AT_STD",str(PerUnit_wo_cost_at_std))
	data!.setFieldValue("PerUnit_WO_COST_AT_ACT",str(PerUnit_wo_cost_at_act))
	data!.setFieldValue("PerUnit_PRIOR_CLOSED_AMT",str(PerUnit_prior_closed_amt))
	data!.setFieldValue("PerUnit_CURR_WIP_VALUE",str(PerUnit_curr_wip_value))
	data!.setFieldValue("PerUnit_CURR_CLOSE_VALUE",str(PerUnit_curr_close_value))
	
	rem --- GL
	rem 	The accounts (All are sent; logic is in iReports to print if all amts not-zero):
	rem			Work in Process
	rem			Close to Account
	rem			Direct Variance
	rem 		Overhead Variance
	rem			Material Variance
	rem			Subcontract Variance
	
	for x = 0 to 5
		switch x
			case 0
				AcctAbrv$ = "WIP_";      rem Work in Process
				gl_acct_num$= gl_wip_acct$
				gl_acct_type$="Work in Process"
			break
			case 1	
				AcctAbrv$ = "CLS_TO_";   rem Close to Account
				gl_acct_num$= gl_close_to_acct$
				gl_acct_type$="Close to Account"
			break
			case 2
				AcctAbrv$ = "DIR_VAR_";  rem Direct Variance
				gl_acct_num$= gl_lab_var_acct$
				gl_acct_type$="Direct Variance"
			break
			case 3	
				AcctAbrv$ = "OVRH_VAR_"; rem Overhead Variance
				gl_acct_num$= gl_ovh_var_acct$
				gl_acct_type$="Overhead Variance"
			break
			case 4
				AcctAbrv$ = "MAT_VAR_";  rem Material Variance
				gl_acct_num$= gl_mat_var_acct$
				gl_acct_type$="Material Variance"
			break
			case 5	
				AcctAbrv$ = "SUB_VAR_";  rem Subcontract Variance
				gl_acct_num$= gl_sub_var_acct$
				gl_acct_type$="Subcontract Variance"
			break
		swend

		rem -- Set flag to only print non-zero amount GL lines
		if GL_Acct_amts[x]=0 
			glpostingprint_flag$="N"
		else
			glpostingprint_flag$="Y"
		endif
	
		gl_debit_amt=0
		gl_credit_amt=0
		gl_debit_perunit=0
		gl_credit_perunit=0
		
		if GL_Acct_amts[x]>0 
			gl_debit_amt = GL_Acct_amts[x]
		else
			gl_credit_amt = abs(GL_Acct_amts[x])
		endif

		if this_close_qty<>0 and this_close_qty<>1
			if GL_Acct_amts[x]/this_close_qty>0 
				gl_debit_perunit = GL_Acct_amts[x]/this_close_qty
			else
				gl_credit_perunit = abs(GL_Acct_amts[x]/this_close_qty)
			endif
		endif		
		
		rem -- Get GL Acct description
		gl_acct_desc$="Not On File"
		find record (glm_acct_dev,key=firm_id$+gl_acct_num$,dom=done_glacctdesc) glm_acct$
		gl_acct_desc$=glm_acct.gl_acct_desc$
		done_glacctdesc:
		
		rem -- Send GL data
		data!.setFieldValue(AcctAbrv$+"PRINT_FLAG",glpostingprint_flag$)
		data!.setFieldValue(AcctAbrv$+"GL_ACCT_NUM",fnmask$(gl_acct_num$,gl_acct_mask$))
		data!.setFieldValue(AcctAbrv$+"GL_ACCT_DESC",gl_acct_desc$)
		
		data!.setFieldValue(AcctAbrv$+"GL_DEBIT_AMT",str(gl_debit_amt))
		data!.setFieldValue(AcctAbrv$+"GL_CREDIT_AMT",str(gl_credit_amt))
		data!.setFieldValue(AcctAbrv$+"GL_DEBIT_PERUNIT",str(gl_debit_perunit))
		data!.setFieldValue(AcctAbrv$+"GL_CREDIT_PERUNIT",str(gl_credit_perunit))
		
		data!.setFieldValue(AcctAbrv$+"GL_ACCT_TYPE",gl_acct_type$)
	
		rem --- Accum GL column totals
		gl_debit_coltot=gl_debit_coltot+gl_debit_amt
		gl_credit_coltot=gl_credit_coltot+gl_credit_amt
		gl_debit_perunit_coltot=gl_debit_perunit_coltot+gl_debit_perunit
		gl_credit_perunit_coltot=gl_credit_perunit_coltot+gl_credit_perunit
		
	next x
		
	rem --- Send GL Debit/Credit col totals
	data!.setFieldValue("GL_DEBIT_COLTOT",str(gl_debit_coltot))
	data!.setFieldValue("GL_CREDIT_COLTOT",str(gl_credit_coltot))
	data!.setFieldValue("GL_DEBIT_PERUNIT_COLTOT",str(gl_debit_perunit_coltot))
	data!.setFieldValue("GL_CREDIT_PERUNIT_COLTOT",str(gl_credit_perunit_coltot))

	rs!.insert(data!)
	
rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit

rem --- Subroutines
		
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
