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
	
	sv_wd$=dir("")
	chdir barista_wd$

rem --- Create a memory record set to hold results.
rem --- Columns for the record set are defined using a string template
	temp$="FIRM_ID:C(2), WO_NO:C(7*), WO_TYPE:C(1*), WO_CATEGORY:C(1*), WO_STATUS:C(1*), CUSTOMER_ID:C(1*), "
	temp$=temp$+"SLS_ORDER_NO:C(1*), WAREHOUSE_ID:C(1*), ITEM_ID:C(1*), OPENED_DATE:C(1*), LAST_CLOSE:C(1*), "
	temp$=temp$+"TYPE_DESC:C(1*), PRIORITY:C(1*), UOM:C(1*), YIELD:C(1*), PROD_QTY:C(1*), COMPLETED:C(1*), "
	temp$=temp$+"LAST_ACT_DATE:C(1*), ITEM_DESC_1:C(1*), ITEM_DESC_2:C(1*), DRAWING_NO:C(1*), REV:C(1*)"
	rs! = BBJAPI().createMemoryRecordSet(temp$)

rem --- Get Barista System Program directory
	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)

rem --- Get masks

rem	pgmdir$=stbl("+DIR_PGM",err=*next)
rem	call pgmdir$+"adc_getmask.aon","","SF","U","",m1$,0,m1
rem	call pgmdir$+"adc_getmask.aon","","AR","I","",custmask$,0,custmask
	m1$="#,###.00-"
	cust_mask$="00-0000"
	pct_mask$="##0.0%"
	
rem --- Open files with adc

    files=3,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="ivm-01",ids$[1]="IVM_ITEMMAST"
	files$[2]="sfm-10",ids$[2]="SFC_WOTYPECD"
	files$[3]="arm-01",ids$[3]="ARM_CUSTMAST"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
    if status goto std_exit
    ivm_itemmast_dev=channels[1]
	sfc_type_dev=channels[2]
	arm_custmast=channels[3]

rem --- Dimension string templates

	dim ivm_itemmast$:templates$[1]
	dim sfc_type$:templates$[2]
	dim arm_custmast$:templates$[3]
	
goto no_bac_open
rem --- Open Files    
    num_files = 3
    dim open_tables$[1:num_files], open_opts$[1:num_files], open_chans$[1:num_files], open_tpls$[1:num_files]

	open_tables$[1]="IVM_ITEMMAST",   open_opts$[1] = "OTA"
	open_tables$[2]="SFC_WOTYPECD",   open_opts$[2] = "OTA"
	open_tables$[3]="ARM_CUSTMAST",   open_opts$[3] = "OTA"

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
	sfc_type_dev = num(open_chans$[2])
	arm_custmast = num(open_chans$[3])
	
	dim ivm_itemmast$:open_tpls$[1]
	dim sfc_type$:open_tpls$[2]
	dim arm_custmast$:open_tpls$[3]

no_bac_open:

rem --- Build SQL statement

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
			where_clause$=where_clause$+" item_id$ <> '' AND "
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

	if len(wostatus$)>0
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
	
rem report_type$="T"; rem escape caj

rem --- Concatenate the pieces of sql_prep$
rem --- For Travelers, limit WO recs based on sfe_openedwo
	if report_type$="T" then 
		gosub get_traveler_join
		sql_prep$=travel_join_pre$+sql_prep$+where_clause$+travel_join_post$+order_by$
	else
		sql_prep$=sql_prep$+where_clause$+order_by$
	endif
	
	sql_chan=sqlunt
	sqlopen(sql_chan,err=*next)stbl("+DBNAME")
	sqlprep(sql_chan)sql_prep$
	dim read_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)

rem --- Trip Read

	while 1
		read_tpl$ = sqlfetch(sql_chan,end=*break)

		data! = rs!.getEmptyRecordData()

		dim ivm_itemmast$:fattr(ivm_itemmast$)
		find record (ivm_itemmast_dev,key=firm_id$+read_tpl.item_id$,dom=*next)ivm_itemmast$
		data!.setFieldValue("FIRM_ID",firm_id$)
		data!.setFieldValue("WO_NO",read_tpl.wo_no$)
		data!.setFieldValue("WO_TYPE",read_tpl.wo_type$)
		data!.setFieldValue("WO_CATEGORY",read_tpl.wo_category$)
		if read_tpl.wo_status$="O"
			stat$="**Open**"
		else
			if read_tpl.wo_status$="P"
				stat$="*Planned*"
			else
				if read_tpl.wo_status$="C"
					stat$="*Closed*"
				else
					stat$=""
				endif
			endif
		endif
		data!.setFieldValue("WO_STATUS",read_tpl.wo_status$+" "+stat$)
		if cvs(read_tpl.customer_id$,3)<>""
			dim arm_custmast$:fattr(arm_custmast$)
			read record (arm_custmast,key=firm_id$+read_tpl.customer_id$,dom=*next) arm_custmast$
			data!.setFieldValue("CUSTOMER_ID","Customer: "+fnmask$(read_tpl.customer_id$,cust_mask$)+" "+arm_custmast.customer_name$)
			if num(read_tpl.order_no$)<>0
				data!.setFieldValue("SLS_ORDER_NO","Sales Order: "+read_tpl.order_no$)
			endif
		endif
		data!.setFieldValue("WAREHOUSE_ID",read_tpl.warehouse_id$)
		data!.setFieldValue("ITEM_ID",read_tpl.item_id$)
		data!.setFieldValue("OPENED_DATE",fndate$(read_tpl.opened_date$))
		data!.setFieldValue("LAST_CLOSE",fndate$(read_tpl.closed_date$))
		dim sfc_type$:fattr(sfc_type$)
		read record (sfc_type_dev,key=firm_id$+"A"+read_tpl.wo_type$) sfc_type$
		data!.setFieldValue("TYPE_DESC",sfc_type.code_desc$)
		data!.setFieldValue("PRIORITY",read_tpl.priority$)
		data!.setFieldValue("UOM",read_tpl.unit_measure$)
		data!.setFieldValue("YIELD",str(read_tpl.est_yield:pct_mask$))
		data!.setFieldValue("PROD_QTY",str(read_tpl.sch_prod_qty:m1$))
		data!.setFieldValue("COMPLETED",str(read_tpl.qty_cls_todt:m1$))
		data!.setFieldValue("LAST_ACT_DATE",fndate$(read_tpl.lstact_date$))
		if cvs(ivm_itemmast.item_desc$,3)=""
			data!.setFieldValue("ITEM_DESC_1",read_tpl.description_01$)
			data!.setFieldValue("ITEM_DESC_2",read_tpl.description_02$)
		else
			data!.setFieldValue("ITEM_DESC_1",ivm_itemmast.item_desc$)
		endif
		data!.setFieldValue("DRAWING_NO",read_tpl.drawing_no$)
		data!.setFieldValue("REV",read_tpl.drawing_rev$)
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
	tj_post$=tj_post$+"ON o.firm_id+o.wo_location+o.wo_no"
 	tj_post$=tj_post$+" = m.firm_id+m.wo_location+m.wo_no "
		
	travel_join_pre$=tj_pre$
	travel_join_post$=tj_post$
	
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


	std_exit:
	
	end
