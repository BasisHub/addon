rem ----------------------------------------------------------------------------
rem Program: BOMMATLDET.prc
rem Description: Stored Procedure to get the BOM Materials Detail info into iReports
rem
rem AddonSoftware
rem Copyright BASIS International Ltd.  All Rights Reserved.
rem ----------------------------------------------------------------------------

GOTO SKIP_DEBUG
Debug$= "C:\temp\BOMMATLDET_DebugPRC.txt" 
string Debug$
DebugChan=unt
open(DebugChan)Debug$   
write(DebugChan)"Top of BOMMATLDET"
SKIP_DEBUG:

 seterr sproc_error

rem --- Set of utility methods

	use ::bmo_BmUtils.aon::BmUtils
    declare BmUtils bmUtils!

rem --- Declare some variables ahead of time

	declare BBjStoredProcedureData sp!
	declare BBjRecordSet rs!
	declare BBjRecordData data!

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get the IN parameters used by the procedure
	
	firm_id$ = sp!.getParameter("FIRM_ID")
    whse$ = sp!.getParameter("WHSE")
	bill_no$ = sp!.getParameter("BILL_NO")
    est_yield = num(sp!.getParameter("EST_YIELD"))
    bm_precision$ = sp!.getParameter("BM_PRECISION")
    iv_precision$ = sp!.getParameter("IV_PRECISION")
    barista_wd$ = sp!.getParameter("BARISTA_WD")
    masks$ = sp!.getParameter("MASKS")

    if num(iv_precision$)>num(bm_precision$) then
        this_precision=num(iv_precision$)
    else
        this_precision=num(bm_precision$)
    endif
    
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
    temp$=temp$+"FIRM_ID:C(1*), BILL_NO:C(1*), MATERIAL_SEQ:C(1*), ITEM_ID:C(1*), LINE_TYPE:C(1*), UNIT_MEASURE:C(1*), EXT_COMMENTS:C(1*), "
    temp$=temp$+"EFFECT_DATE:C(1*), OBSOLT_DATE:C(1*), QTY_REQUIRED:C(1*), ALT_FACTOR:C(1*), DIVISOR:C(1*), SCRAP_FACTOR:C(1*), OP_INT_SEQ_REF:C(1*), "
    temp$=temp$+"ITEMDESC:C(1*), UNITCOST:C(1*), B_COUNT:N(1*), MAT_COST:C(1*), NET_REQUIRED:C(1*), TOT_MAT_COST:N(1*)"

    rs! = BBJAPI().createMemoryRecordSet(temp$)

rem --- Get Barista System Program directory

	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)

rem --- Get masks

    bm_cost_mask$=fngetmask$("bm_cost_mask","#,##0.000",masks$)
    bm_hour_mask$=fngetmask$("bm_hour_mask","#,##0.00",masks$)
    bm_mFactor_mask$=fngetmask$("bm_mFactor_mask","##.00",masks$)
    bm_rate_mask$=fngetmask$("bm_rate_mask","###.00",masks$)
    bm_unit_mask$=fngetmask$("bm_unit_mask","#,##0.0000-",masks$)
    iv_cost_mask$=fngetmask$("iv_cost_mask","###,##0.0000-",masks$)
    iv_units_mask$=fngetmask$("iv_units_mask","#,##0.0000-",masks$)

rem --- Build SQL statement

    sql_prep$=""
    sql_prep$=sql_prep$+"SELECT firm_id, bill_no, material_seq, bmm_billmat.item_id, line_type, unit_measure, ext_comments, "+$0a$
    sql_prep$=sql_prep$+"  effect_date, obsolt_date, qty_required, alt_factor, divisor, scrap_factor, op_int_seq_ref, "+$0a$
    sql_prep$=sql_prep$+"  ivm_itemmast.item_desc as itemdesc, ivm_itemwhse.unit_cost as unitcost, count(bmm_billmast.firm_id) as b_count"+$0a$
    sql_prep$=sql_prep$+"FROM bmm_billmat"+$0a$
    sql_prep$=sql_prep$+"LEFT OUTER JOIN bmm_billmast"+$0a$
    sql_prep$=sql_prep$+"ON bmm_billmast.firm_id = bmm_billmat.firm_id AND bmm_billmast.bill_no = bmm_billmat.item_id"+$0a$
    sql_prep$=sql_prep$+"LEFT OUTER JOIN ivm_itemmast"+$0a$
    sql_prep$=sql_prep$+"ON bmm_billmat.firm_id = ivm_itemmast.firm_id AND bmm_billmat.item_id = ivm_itemmast.item_id"+$0a$
    sql_prep$=sql_prep$+"LEFT OUTER JOIN ivm_itemwhse"+$0a$
    sql_prep$=sql_prep$+"ON bmm_billmat.firm_id = ivm_itemwhse.firm_id AND ivm_itemwhse.warehouse_id = '"+whse$+"' AND ivm_itemwhse.item_id = bmm_billmat.item_id"+$0a$
    sql_prep$=sql_prep$+"WHERE firm_id = '"+firm_id$+"' AND bill_no = '"+bill_no$+"' "+$0a$
    sql_prep$=sql_prep$+"GROUP BY bmm_billmat.firm_id, bmm_billmat.bill_no, bmm_billmat.material_seq, bmm_billmat.item_id, "+$0a$
    sql_prep$=sql_prep$+"  line_type, unit_measure, ext_comments, effect_date, obsolt_date, qty_required, alt_factor, divisor, "+$0a$
    sql_prep$=sql_prep$+"  scrap_factor, itemdesc, unitcost, op_int_seq_ref"+$0a$
    
    sql_chan=sqlunt
    sqlopen(sql_chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
    sqlprep(sql_chan)sql_prep$
    dim read_tpl$:sqltmpl(sql_chan)
    sqlexec(sql_chan)

rem --- Build result set

    old_prec = tcb(14)
    precision this_precision

    while 1
        read_tpl$ = sqlfetch(sql_chan,end=*break)

        data! = rs!.getEmptyRecordData()
        data!.setFieldValue("FIRM_ID",read_tpl.firm_id$)
        data!.setFieldValue("BILL_NO",read_tpl.bill_no$)
        data!.setFieldValue("MATERIAL_SEQ",read_tpl.material_seq$)
        data!.setFieldValue("LINE_TYPE",read_tpl.line_type$)
        data!.setFieldValue("EFFECT_DATE",cvs(read_tpl.effect_date$,2))
        data!.setFieldValue("OBSOLT_DATE",cvs(read_tpl.obsolt_date$,2))
        if read_tpl.line_type$="M"
            Rem --- Send data row for Memos
            data!.setFieldValue("EXT_COMMENTS",read_tpl.ext_comments$)
        else
            rem --- Send data row for non-Memos
            net_qty=0
            if read_tpl.divisor<>0 then
                net_qty=1*BmUtils.netQuantityRequired(read_tpl.qty_required,read_tpl.alt_factor,read_tpl.divisor,est_yield,read_tpl.scrap_factor)
            endif

            data!.setFieldValue("ITEM_ID",read_tpl.item_id$)
            data!.setFieldValue("UNIT_MEASURE",read_tpl.unit_measure$)
            data!.setFieldValue("QTY_REQUIRED",str(read_tpl.qty_required:iv_units_mask$))
            data!.setFieldValue("ALT_FACTOR",str(read_tpl.alt_factor:bm_mFactor_mask$))
            data!.setFieldValue("DIVISOR",str(read_tpl.divisor:bm_mFactor_mask$))
            data!.setFieldValue("SCRAP_FACTOR",str(read_tpl.scrap_factor:bm_mFactor_mask$))
            data!.setFieldValue("OP_INT_SEQ_REF",read_tpl.op_int_seq_ref$)
            data!.setFieldValue("ITEMDESC",read_tpl.itemdesc$)
            data!.setFieldValue("UNITCOST",str(read_tpl.unitcost:iv_cost_mask$))
            data!.setFieldValue("B_COUNT",read_tpl.b_count$)
            data!.setFieldValue("MAT_COST",str(read_tpl.unitcost*net_qty:iv_cost_mask$))
            data!.setFieldValue("NET_REQUIRED",str(net_qty:iv_units_mask$))
            data!.setFieldValue("TOT_MAT_COST",str(read_tpl.unitcost*net_qty))
        endif
        rs!.insert(data!)           
    wend

    precision old_prec

rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit
    
rem --- Functions

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
