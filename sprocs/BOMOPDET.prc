rem ----------------------------------------------------------------------------
rem Program: BOMOPDET.prc
rem Description: Stored Procedure to get the BOM Operations Detail info into iReports
rem
rem AddonSoftware
rem Copyright BASIS International Ltd.  All Rights Reserved.
rem ----------------------------------------------------------------------------

GOTO SKIP_DEBUG
Debug$= "C:\temp\BOMOPDET_DebugPRC.txt" 
string Debug$
DebugChan=unt
open(DebugChan)Debug$   
write(DebugChan)"Top of BOMOPDET"
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
	bill_no$ = sp!.getParameter("BILL_NO")
    est_yield = num(sp!.getParameter("EST_YIELD"))
    lot_size = num(sp!.getParameter("STD_LOT_SIZE"))
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
    temp$=temp$+"FIRM_ID:C(1*), BILL_NO:C(1*), OP_SEQ:C(1*), OP_CODE:C(1*), LINE_TYPE:C(1*), EXT_COMMENTS:C(1*), "
    temp$=temp$+"HRS_PER_PCE:C(1*), PCS_PER_HOUR:C(1*), SETUP_TIME:C(1*), MOVE_TIME:C(1*), EFFECT_DATE:C(1*), "
    temp$=temp$+"OBSOLT_DATE:C(1*), INTERNAL_SEQ_NO:C(1*), QUEUE:C(1*), CODEDESC:C(1*), DIRECT_RATE:C(1*), "
    temp$=temp$+"NET_HRS:C(1*), DIR_COST:C(1*), OH_COST:C(1*), OP_COST:C(1*), TOT_DIR_COST:N(1*), TOT_OH_COST:N(1*)"

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
    sql_prep$=sql_prep$+"SELECT firm_id, bill_no, op_seq, op_code, line_type, memo_1024, hrs_per_pce, pcs_per_hour, "+$0a$
    sql_prep$=sql_prep$+"  setup_time, move_time, effect_date, obsolt_date, internal_seq_no, bmc_opcodes.queue_time as queue, "+$0a$
    sql_prep$=sql_prep$+"  bmc_opcodes.code_desc as codedesc, bmc_opcodes.direct_rate as direct_rate, bmc_opcodes.ovhd_factor as ovhd_factor"+$0a$
    sql_prep$=sql_prep$+"FROM bmm_billoper"+$0a$
    sql_prep$=sql_prep$+"LEFT JOIN bmc_opcodes"+$0a$
    sql_prep$=sql_prep$+"ON bmm_billoper.firm_id = bmc_opcodes.firm_id AND bmm_billoper.op_code = bmc_opcodes.op_code"+$0a$
    sql_prep$=sql_prep$+"WHERE firm_id = '"+firm_id$+"' AND bill_no = '"+bill_no$+"' "+$0a$
    
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
        data!.setFieldValue("OP_SEQ",read_tpl.op_seq$)
        data!.setFieldValue("LINE_TYPE",read_tpl.line_type$)
        data!.setFieldValue("INTERNAL_SEQ_NO",read_tpl.internal_seq_no$)
        data!.setFieldValue("EFFECT_DATE",cvs(read_tpl.effect_date$,2))
        data!.setFieldValue("OBSOLT_DATE",cvs(read_tpl.obsolt_date$,2))
        if read_tpl.line_type$="M"
            Rem --- Send data row for Memos
            data!.setFieldValue("EXT_COMMENTS",read_tpl.memo_1024$)
        else
            rem --- Send data row for non-Memos
            net_hrs=0
            if read_tpl.pcs_per_hour*est_yield*lot_size<>0 then
                net_hrs=100*(read_tpl.hrs_per_pce/read_tpl.pcs_per_hour)/est_yield+read_tpl.setup_time/lot_size
            endif
            direct_cost=1*BmUtils.directCost(read_tpl.hrs_per_pce,read_tpl.direct_rate,read_tpl.pcs_per_hour,est_yield,read_tpl.setup_time,lot_size)
            oh_cost=direct_cost*read_tpl.ovhd_factor

            data!.setFieldValue("OP_CODE",read_tpl.op_code$)
            data!.setFieldValue("QUEUE",str(read_tpl.queue:bm_hour_mask$))
            data!.setFieldValue("SETUP_TIME",str(read_tpl.setup_time:bm_unit_mask$))
            data!.setFieldValue("HRS_PER_PCE",str(read_tpl.hrs_per_pce:bm_hour_mask$))
            data!.setFieldValue("PCS_PER_HOUR",str(read_tpl.pcs_per_hour:bm_unit_mask$))
            data!.setFieldValue("MOVE_TIME",str(read_tpl.move_time:bm_unit_mask$))
            data!.setFieldValue("CODEDESC",read_tpl.codedesc$)
            data!.setFieldValue("DIRECT_RATE",str(read_tpl.direct_rate:bm_rate_mask$))
            data!.setFieldValue("NET_HRS",str(net_hrs:bm_hour_mask$))
            data!.setFieldValue("DIR_COST",str(direct_cost:bm_cost_mask$))
            data!.setFieldValue("OH_COST",str(oh_cost:bm_cost_mask$))
            data!.setFieldValue("OP_COST",str(direct_cost+oh_cost:bm_cost_mask$))
            data!.setFieldValue("TOT_DIR_COST",str(direct_cost))
            data!.setFieldValue("TOT_OH_COST",str(oh_cost))
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
