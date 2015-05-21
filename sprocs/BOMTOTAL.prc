rem ----------------------------------------------------------------------------
rem Program: BOMTOTAL.prc
rem Description: Stored Procedure to get the BOM Total info into iReports
rem
rem AddonSoftware
rem Copyright BASIS International Ltd.  All Rights Reserved.
rem ----------------------------------------------------------------------------

GOTO SKIP_DEBUG
Debug$= "C:\temp\BOMTOTAL_DebugPRC.txt" 
string Debug$
DebugChan=unt
open(DebugChan)Debug$   
write(DebugChan)"Top of BOMTOTAL"
SKIP_DEBUG:

 seterr sproc_error

rem --- Declare some variables ahead of time

	declare BBjStoredProcedureData sp!
	declare BBjRecordSet rs!
	declare BBjRecordData data!

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get the IN parameters used by the procedure
	
	firm_id$ = sp!.getParameter("FIRM_ID")
	bill_no$ = sp!.getParameter("BILL_NO")
    tot_mat_cost = num(sp!.getParameter("TOT_MAT_COST"))
    tot_dir_cost = num(sp!.getParameter("TOT_DIR_COST"))
    tot_oh_cost = num(sp!.getParameter("TOT_OH_COST"))
    tot_sub_cost = num(sp!.getParameter("TOT_SUB_COST"))
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
    temp$=temp$+"TOT_MAT_COST:C(1*), TOT_DIR_COST:C(1*), TOT_OH_COST:C(1*), TOT_SUB_COST:C(1*), TOTAL_COST:C(1*) "

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

    if num(iv_precision$)>=num(bm_precision$) then
        cost_mask$=iv_cost_mask$
    else
        cost_mask$=bm_cost_mask$
    endif

rem --- Build result set

    old_prec = tcb(14)
    precision this_precision

    data! = rs!.getEmptyRecordData()
    data!.setFieldValue("TOT_MAT_COST",str(tot_mat_cost:cost_mask$))
    data!.setFieldValue("TOT_DIR_COST",str(tot_dir_cost:cost_mask$))
    data!.setFieldValue("TOT_OH_COST",str(tot_oh_cost:cost_mask$))
    data!.setFieldValue("TOT_SUB_COST",str(tot_sub_cost:cost_mask$))
    data!.setFieldValue("TOTAL_COST",str(tot_mat_cost+tot_dir_cost+tot_oh_cost+tot_sub_cost:cost_mask$))
    rs!.insert(data!)           

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
