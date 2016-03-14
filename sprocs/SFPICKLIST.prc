rem --- Shop Floor Pick List
rem --- Program: SFPICKLIST.prc

rem --- AddonSoftware
rem --- Copyright BASIS International Ltd.  All Rights Reserved.

rem --- 3/2016 ------------------------
rem --- Replaced BBjForm-based SF Pick List with Jasper-based

rem ----------------------------------------------------------------------------

    seterr sproc_error   

rem --- Use statements and Declares
	
    use ::ado_func.src::func
    use java.util.HashMap

    declare BBjStoredProcedureData sp!
    declare BBjRecordSet rs!
    declare BBjRecordData data!

rem --- Get the infomation object for the Stored Procedure

    sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- get SPROC parameters

    firm_id$=sp!.getParameter("FIRM_ID")
    wo_location$=sp!.getParameter("WO_LOCATION")
    wo_no$=sp!.getParameter("WO_NO")
    cust_mask$=sp!.getParameter("CUST_MASK")
    qty_mask$=sp!.getParameter("QTY_MASK")
    bm$=sp!.getParameter("BOM_INTERFACE")
    key_num$=sp!.getParameter("KEY_NUM")
    iv_precision=num(sp!.getParameter("IV_PRECISION"))
    iv_lotser$=sp!.getParameter("IV_LOTSER")
    info31$=sp!.getParameter("INFO_31")
    barista_wd$=sp!.getParameter("BARISTA_WD")

    chdir barista_wd$

rem --- Create the in-memory recordset for return
rem --- Because of the requirement to do a page break on op step, which comes from the detail, 
rem --- each record in this recordset contains both header and detail info. The header info is redundant,
rem --- but makes it easy to set a grouping/report break in the Jasper report itself.

    dataTemplate$ = ""
    dataTemplate$ = dataTemplate$ + "wo_type:C(1*),wo_cat_cd:C(1*),wo_category:C(1*),op_step:C(1*),bill_no:C(1*),wo_desc1:C(1*),wo_desc2:C(1*),"
    dataTemplate$ = dataTemplate$ + "open_date:C(1*),start_date:C(1*),completion_date:C(1*),"
    dataTemplate$ = dataTemplate$ + "drawing_no:C(1*),rev_no:C(1*),customer:C(1*),order:C(1*),warehouse:C(1*),prod_qty:C(1*),"
    dataTemplate$ = dataTemplate$ + "wh_loc:C(1*),req_qty:C(1*),item_no:C(1*),item_desc:C(1*),lotser_prompt:C(1*),lotser_prompt2:C(1*), "
    dataTemplate$ = dataTemplate$ + "qty_OH:C(1*),qty_CO:C(1*),qty_AV:C(1*),qty_OO:C(1*)"

    rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

rem --- Init

    pgmdir$=stbl("+DIR_PGM",err=*next)
    precision iv_precision
    more=1
    
rem --- Open Files
rem --- Note 'files' and 'channels[]' are used in close loop, so don't re-use

    files=13,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]    

    files$[1]="sfe-01",ids$[1]="SFE_WOMASTR"
    files$[2]="sfe-13",ids$[2]="SFE_WOMATHDR"
    files$[3]="arm-01",ids$[3]="ARM_CUSTMAST"
    files$[4]="ivc_whsecode",ids$[4]="IVC_WHSECODE"
    files$[5]="sfm-10",ids$[5]="SFC_WOTYPECD"
    files$[6]="sfw-13",ids$[6]="SFW_PICKLCTN"
    files$[7]="ivm-01",ids$[7]="IVM_ITEMMAST"
    files$[8]="ivm-02",ids$[8]="IVM_ITEMWHSE"
    files$[9]="sfe-23",ids$[9]="SFE_WOMATDTL"
    files$[10]="sfe-22",ids$[10]="SFE_WOMATL"
    files$[11]="sfe-02",ids$[11]="SFE_WOOPRTN"

    if bm$="Y"
        files$[12]="bmm-08",ids$[12]="BMC_OPCODES"
    else
        files$[12]="sfm-02",ids$[12]="SFC_OPRTNCOD"    
    endif

    files$[13]="opt-11",ids$[13]="OPT_INVDET"

	call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status

    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif
    
	files_opened = files; rem used in loop to close files
	
    sfe_womastr = channels[1]
    sfe_womathdr = channels[2]
    arm_custmast = channels[3]
    ivc_whsecode = channels[4]
    sfc_wotypecd = channels[5]	
    sfw_picklctn = channels[6]
    ivm_itemmast = channels[7]
    ivm_itemwhse = channels[8]
    sfe_womatdtl = channels[9]
    sfe_womatl = channels[10]
    sfe_wooprtn = channels[11]
    op_code = channels[12]
    opt_invdet = channels[13]

    dim sfe_womastr$:templates$[1]
    dim sfe_womathdr$:templates$[2]
    dim arm_custmast$:templates$[3]
    dim ivc_whsecode$:templates$[4]
    dim sfc_wotypecd$:templates$[5]
    dim sfw_picklctn$:templates$[6]
    dim ivm_itemmast$:templates$[7]
    dim ivm_itemwhse$:templates$[8]
    dim sfe_womatdtl$:templates$[9]
    dim sfe_womatl$:templates$[10]
    dim sfe_wooprtn$:templates$[11]
	dim op_code$:templates$[12]
    dim opt_invdet$:templates$[13]

rem --- Get Work Order

    read record (sfe_womathdr,key=firm_id$+wo_location$+wo_no$,err=all_done) sfe_womathdr$
    read record (sfe_womastr,key=sfe_womathdr.firm_id$+sfe_womathdr.wo_location$+sfe_womathdr.wo_no$,err=all_done) sfe_womastr$
    gosub get_op_seqs
		
rem --- Find Customer

    customer$=""
    order$=""
    if pos(" "<> sfe_womastr.customer_id$)<>0
        find record (arm_custmast,key=firm_id$+sfe_womastr.customer_id$,dom=*endif) arm_custmast$
        customer$=fnmask$(sfe_womastr.customer_id$,cust_mask$)+" "+arm_custmast.customer_name$
        order$=sfe_womastr.order_no$
        redim opt_invdet$
        redim ivm_itemmast$

        readrecord (opt_invdet,key=firm_id$+opt_invdet.ar_type$+sfe_womastr.customer_id$+sfe_womastr.order_no$+opt_invdet.ar_inv_no$+sfe_womastr.sls_ord_seq_ref$,dom=*next)opt_invdet$
        if cvs(opt_invdet.item_id$,3)<>""
            readrecord (ivm_itemmast,key=firm_id$+opt_invdet.item_id$,dom=*next)ivm_itemmast$
            order$=order$+" ("+opt_invdet.line_no$+") - "+cvs(opt_invdet.item_id$,3)+" "+func.displayDesc(ivm_itemmast.item_desc$)
        endif
    endif

rem --- Find Warehouse

    whse_short$=""
    find record (ivc_whsecode,key=firm_id$+"C"+sfe_womathdr.warehouse_id$,dom=*next) ivc_whsecode$
    whse_short$=sfe_womathdr.warehouse_id$+" "+ivc_whsecode.short_name$

rem --- Type

    wo_type$=""
    find record (sfc_wotypecd,key=firm_id$+"A"+sfe_womathdr.firm_id$,dom=*next) sfc_wotypecd$
    wo_type$=sfe_womathdr.wo_type$+" "+sfc_wotypecd.code_desc$

rem --- Category (these will be printed using str() function in the Jasper, which takes care of the translation)

    wo_cat_cd$=sfe_womathdr.wo_category$
    bill_no$=""
    if wo_cat_cd$="I"
        wo_category$="AON_INVENTORY"
        bill_no$=sfe_womathdr.item_id$
    endif
    if wo_cat_cd$="N" then wo_category$="AON_NON-STOCK"
    if wo_cat_cd$="R" then wo_category$="AON_RECURRING"

rem --- Other header fields

    wo_desc1$=""
    wo_desc2$=""
    find record (ivm_itemmast,key=firm_id$+sfe_womathdr.item_id$,dom=*next) ivm_itemmast$
    if sfe_womathdr.wo_category$="I" then let wo_desc1$=func.displayDesc(ivm_itemmast.item_desc$)
    if sfe_womathdr.wo_category$<>"I" then let wo_desc1$=sfe_womastr.description_01$,wo_desc2$=sfe_womastr.description_02$
    open_date$=fndate$(sfe_womastr.opened_date$)
    start_date$=fndate$(sfe_womastr.eststt_date$)
    completion_date$=fndate$(sfe_womastr.estcmp_date$)
    drawing_no$=sfe_womastr.drawing_no$
    rev_no$=sfe_womastr.drawing_rev$
    prod_qty$=str(sfe_womastr.sch_prod_qty-sfe_womastr.qty_cls_todt:qty_mask$)

rem --- Get Header level comments

    read (sfw_picklctn,key=sfe_womathdr.firm_id$+sfe_womathdr.wo_location$+sfe_womathdr.wo_no$,knum=key_num$,dom=*next)
    
    head_comm$=""
    gosub get_wo_hdr_cmnts
    cmt_len=len(sfe_womatl.ext_comments$)
    if head_comm$<>""
        for x=1 to len(head_comm$) step cmt_len*2
            item_no$=head_comm$(x,cmt_len)
			if len(head_comm$)>x+cmt_len
                item_desc$=head_comm$(x+cmt_len,cmt_len)
            endif
            gosub add_to_recordset
		next x
	endif

rem --- Get details

    while more

        read record (sfw_picklctn,end=*break) sfw_picklctn$
        if sfw_picklctn.firm_id$+sfw_picklctn.wo_location$+sfw_picklctn.wo_no$<>sfe_womathdr.firm_id$+sfe_womathdr.wo_location$+sfe_womathdr.wo_no$ then break
        op_seq$=sfw_picklctn.oper_seq_ref$
        op_step$=""

        if cvs(op_seq$,3)<>""
            op_step$=opslist!.get(op_seq$)
        endif
        
        read record (sfe_womatdtl,key=sfw_picklctn.firm_id$+sfw_picklctn.wo_location$+sfw_picklctn.wo_no$+sfw_picklctn.material_seq$,knum="AO_DISP_SEQ",dom=*continue) sfe_womatdtl$
        find record (ivm_itemmast,key=firm_id$+sfe_womatdtl.item_id$,dom=*next) ivm_itemmast$
        find record (ivm_itemwhse,key=firm_id$+sfe_womatdtl.warehouse_id$+sfe_womatdtl.item_id$,dom=*next) ivm_itemwhse$

        wh_loc$=ivm_itemwhse.location$
        req_qty$=str(sfe_womatdtl.qty_ordered-sfe_womatdtl.tot_qty_iss:qty_mask$)
        item_no$=sfe_womatdtl.item_id$
        item_desc$=func.displayDesc(ivm_itemmast.item_desc$)
        qty_OH$=str(ivm_itemwhse.qty_on_hand:qty_mask$)
        qty_CO$=str(ivm_itemwhse.qty_commit-(sfe_womatdtl.qty_ordered-sfe_womatdtl.tot_qty_iss):qty_mask$)
        qty_AV$=str(ivm_itemwhse.qty_on_hand-num(qty_CO$):qty_mask$)
        qty_OO$=str(ivm_itemwhse.qty_on_order:qty_mask$)

        gosub add_to_recordset

    rem --- Put out mat line comments

        line_comm$=""
        gosub get_mat_line_cmnts
        cmt_len=len(sfe_womatl.ext_comments$)
        if line_comm$<>""
            for x=1 to len(line_comm$) step cmt_len*2
                item_no$=line_comm$(x,cmt_len)
                if len(line_comm$)>x+cmt_len
                    item_desc$=line_comm$(x+cmt_len,cmt_len)
                endif
                gosub add_to_recordset
            next x
        endif

    rem --- Put out the lot/serial lines

        ls_count=0
        lot_ser$=""
        lot_ser2$=""
        
        if iv_lotser$="S" and (ivm_itemmast.lotser_item$+ivm_itemmast.inventoried$)="YY"
            lot_ser$="AON_SERIAL_#:"
            lot_ser2$="AON_SERIAL_#:"
            ls_count=sfe_womatdtl.qty_ordered-sfe_womatdtl.tot_qty_iss
        endif
        
        if iv_lotser$="L" and (ivm_itemmast.lotser_item$+ivm_itemmast.inventoried$)="YY"
            lot_ser$="AON_LOT_#:"
            lot_ser2$="AON_LOT_#:"
            ls_count=5
        endif

        if ls_count
            for x=1 to ls_count step 2
                item_no$=fill(30,"_")
                if ls_count>x
                    item_desc$=fill(30,"_")
                else
                    lot_ser2$=""
                endif
                gosub add_to_recordset
            next x
        endif

        lot_ser$=""
        lot_ser2$=""

    wend

all_done:
rem Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
    
	goto std_exit


add_to_recordset: rem --- add header, detail and/or comment info to recordset

    data! = rs!.getEmptyRecordData()
    data!.setFieldValue("wo_type",wo_type$)
    data!.setFieldValue("wo_cat_cd",wo_cat_cd$)
    data!.setFieldValue("wo_category",wo_category$)
    data!.setFieldValue("op_step",op_step$)
    data!.setFieldValue("bill_no",bill_no$)
    data!.setFieldValue("wo_desc1",wo_desc1$)
    data!.setFieldValue("wo_desc2",wo_desc2$)
    data!.setFieldValue("open_date",open_date$)
    data!.setFieldValue("start_date",start_date$)
    data!.setFieldValue("completion_date",completion_date$)
    data!.setFieldValue("drawing_no",drawing_no$)
    data!.setFieldValue("rev_no",rev_no$)
    data!.setFieldValue("customer",customer$)
    data!.setFieldValue("order",order$)
    data!.setFieldValue("warehouse",whse_short$)
    data!.setFieldValue("prod_qty",prod_qty$)
    
    data!.setFieldValue("wh_loc",wh_loc$)
    data!.setFieldValue("req_qty",req_qty$)
    data!.setFieldValue("item_no",item_no$)
    data!.setFieldValue("item_desc",item_desc$)
    data!.setFieldValue("lotser_prompt",lot_ser$)
    data!.setFieldValue("lotser_prompt2",lot_ser2$)
    data!.setFieldValue("qty_OH",qty_OH$)
    data!.setFieldValue("qty_CO",qty_CO$)
    data!.setFieldValue("qty_AV",qty_AV$)
    data!.setFieldValue("qty_OO",qty_OO$)

    rs!.insert(data!)

    wh_loc$=""
    req_qty$=""
    item_no$=""
    item_desc$=""
    qty_OH$=""
    qty_CO$=""
    qty_AV$=""
    qty_OO$=""  

    return

get_mat_line_cmnts: rem --- Get comments for this material line

    read record (sfe_womatl,key=sfe_womatdtl.firm_id$+sfe_womatdtl.wo_location$+sfe_womatdtl.wo_no$+sfe_womatdtl.material_seq$,dom=*next) sfe_womatl$

    while more
        sfe_womatl_key$=key(sfe_womatl,end=*break)
        if pos(sfe_womathdr.firm_id$+sfe_womathdr.wo_location$+sfe_womathdr.wo_no$=sfe_womatl_key$)<>1 then break
		redim sfe_womatl$
        read record (sfe_womatl) sfe_womatl$
        if sfe_womatl.line_type$<>"M" then break 
		line_comm$=line_comm$+sfe_womatl.ext_comments$
    wend
    return

get_wo_hdr_cmnts: rem --- Get header comments for this Work Order

    read (sfe_womatl,key=sfe_womathdr.firm_id$+sfe_womathdr.wo_location$+sfe_womathdr.wo_no$,dom=*next)
    while more
        sfe_womatl_key$=key(sfe_womatl,end=*break)
        if pos(sfe_womathdr.firm_id$+sfe_womathdr.wo_location$+sfe_womathdr.wo_no$=sfe_womatl_key$)<>1 then break
		redim sfe_womatl$
        read record (sfe_womatl) sfe_womatl$
        if sfe_womatl.line_type$<>"M" then break
		head_comm$=head_comm$+sfe_womatl.ext_comments$		
    wend
    return

get_op_seqs: rem --- create hashmap of ops ISN > description for op step in hdr

	SysGUI!=BBjAPI()
    opslist! = new java.util.HashMap()
	op_code_list$=""

	read(sfe_wooprtn,key=firm_id$+sfe_womastr.wo_location$+sfe_womastr.wo_no$,dom=*next)
	while 1
		read record (sfe_wooprtn,end=*break) sfe_wooprtn$
		if pos(firm_id$+sfe_womastr.wo_location$+sfe_womastr.wo_no$=sfe_wooprtn$)<>1 break
		if sfe_wooprtn.line_type$<>"S" continue
		redim op_code$
		read record (op_code,key=firm_id$+sfe_wooprtn.op_code$,dom=*next)op_code$
		op_code_list$=op_code_list$+sfe_wooprtn.op_code$
		work_var=pos(sfe_wooprtn.op_code$=op_code_list$,len(sfe_wooprtn.op_code$),0)
		if work_var>1
			work_var$=sfe_wooprtn.op_code$+"("+str(work_var)+")"
		else
			work_var$=sfe_wooprtn.op_code$
		endif
		opslist!.put(str(sfe_wooprtn.internal_seq_no$),work_var$+" - "+op_code.code_desc$)
	wend	
	return

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

sproc_error:rem --- SPROC error trap/handler

    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num
	
std_exit:

	rem --- Close files
		x = files_opened
		while x>=1
			close (channels[x],err=*next)
			x=x-1
		wend

    end