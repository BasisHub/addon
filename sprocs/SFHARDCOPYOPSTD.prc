rem ----------------------------------------------------------------------------
rem Program: SFHARDCOPYOPSTD.prc
rem Description: Stored Procedure to get the Shop Floor Hard Copy Operation info into iReports
rem Used for Hard Copy, Traveler, Work Order Closed Detail and Work Order Detail
rem
rem Author(s): J. Brewer
rem Revised: 04.13.2012
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
	report_type$ = sp!.getParameter("REPORT_TYPE")
	print_costs$ = sp!.getParameter("PRINT_COSTS")
	
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
	temp$=temp$+"REF_NO:C(1*), OP_CODE:C(1*), CODE_DESC:C(1*), COMMENTS:C(1*), "
	temp$=temp$+"REQ_DATE:C(1*), HOURS:C(1*), PC_HR:C(1*), DIRECT:C(1*), "
	temp$=temp$+"OVHD:C(1*), UNITS_EA:C(1*), COST_EA:C(1*), SETUP:C(1*), "
	temp$=temp$+"UNITS_TOT:C(1*), COST_TOT:C(1*), THIS_IS_TOTAL_LINE:C(1*), "	
	temp$=temp$+"COST_EA_RAW:C(1*), COST_TOT_RAW:C(1*) "	

	rs! = BBJAPI().createMemoryRecordSet(temp$)

rem --- Get Barista System Program directory

	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)

rem --- Get masks

	pgmdir$=stbl("+DIR_PGM",err=*next)

	iv_cost_mask$=fngetmask$("iv_cost_mask","###,##0.0000-",masks$)
	sf_cost_mask$=fngetmask$("sf_cost_mask","###,##0.0000-",masks$)
	sf_amt_mask$=fngetmask$("sf_amt_mask","###,##0.00-",masks$)
	sf_units_mask$=fngetmask$("sf_units_mask","#,###.00",masks$)
	sf_hours_mask$=fngetmask$("sf_hours_mask","#,##0.00",masks$)
	sf_rate_mask$=fngetmask$("sf_rate_mask","###.00",masks$)
	
rem --- Init totals

	tot_units_ea=0
	tot_cost_ea=0
	tot_units_tot=0
	tot_cost_tot=0

rem --- Open files with adc

    files=5,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="ivm-01",ids$[1]="IVM_ITEMMAST"
	files$[2]="sfm-10",ids$[2]="SFC_WOTYPECD"
	files$[3]="arm-01",ids$[3]="ARM_CUSTMAST"
	files$[4]="sfs_params",ids$[4]="SFS_PARAMS"

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
	sfs_params=channels[4]

rem --- Dimension string templates

	dim ivm_itemmast$:templates$[1]
	dim sfc_type$:templates$[2]
	dim arm_custmast$:templates$[3]
	dim sfs_params$:templates$[4]
	
rem --- Get proper Op Code Maintenance table

	read record (sfs_params,key=firm_id$+"SF00") sfs_params$
	bm$=sfs_params.bm_interface$
	if bm$<>"Y"
		files$[5]="sfm-02",ids$[5]="SFC_OPRTNCOD"
	else
		files$[5]="bmm-08",ids$[5]="BMC_OPCODES"
	endif
    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif
	
	opcode_dev=channels[5]
	dim opcode_tpl$:templates$[5]

rem --- Build SQL statement

	sql_prep$=""
	sql_prep$=sql_prep$+"SELECT op_code, wo_op_ref, require_date, runtime_hrs "+$0a$
	sql_prep$=sql_prep$+"     , pcs_per_hour, direct_rate, ovhd_rate, setup_time "+$0a$
	sql_prep$=sql_prep$+"     , hrs_per_pce, unit_cost, total_time, tot_std_cost "+$0a$
	sql_prep$=sql_prep$+"     , line_type, memo_1024 "+$0a$
	sql_prep$=sql_prep$+"  FROM sfe_wooprtn "+$0a$
	sql_prep$=sql_prep$+" WHERE firm_id = '"+firm_id$+"' "+$0a$
	sql_prep$=sql_prep$+"   AND wo_location = '"+wo_loc$+"' "+$0a$
	sql_prep$=sql_prep$+"   AND wo_no = '"+wo_no$+"'"+$0a$
	
	sql_chan=sqlunt
	sqlopen(sql_chan,mode="PROCEDURE",err=*next)stbl("+DBNAME")
	sqlprep(sql_chan)sql_prep$
	dim read_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)

rem --- Trip Read

	tot_recs=0
	while 1
		read_tpl$ = sqlfetch(sql_chan,end=*break)

		data! = rs!.getEmptyRecordData()

		dim opcode_tpl$:fattr(opcode_tpl$)
		read record (opcode_dev,key=firm_id$+read_tpl.op_code$,dom=*next) opcode_tpl$

		if developing 
			gosub send_test_pattern
			continue
		endif
				
		if read_tpl.line_type$="M"
			Rem --- Send data row for Memos
            memo_1024$=read_tpl.memo_1024$
            if len(memo_1024$) and memo_1024$(len(memo_1024$))=$0A$ then memo_1024$=memo_1024$(1,len(memo_1024$)-1); rem --- trim trailing newline
			data!.setFieldValue("COMMENTS",memo_1024$)
			rs!.insert(data!)
		else
			rem --- Send data row for non-Memos
			data!.setFieldValue("REF_NO",read_tpl.wo_op_ref$)
			data!.setFieldValue("OP_CODE",read_tpl.op_code$)
			data!.setFieldValue("CODE_DESC",opcode_tpl.code_desc$)
			data!.setFieldValue("REQ_DATE",fndate$(read_tpl.require_date$))
			data!.setFieldValue("HOURS",str(read_tpl.hrs_per_pce:sf_hours_mask$))
			data!.setFieldValue("PC_HR",str(read_tpl.pcs_per_hour:sf_units_mask$))
			data!.setFieldValue("UNITS_EA",str(read_tpl.runtime_hrs:sf_units_mask$))
			data!.setFieldValue("SETUP",str(read_tpl.setup_time:sf_hours_mask$))
			data!.setFieldValue("UNITS_TOT",str(read_tpl.total_time:sf_units_mask$))
			
			if print_costs$="Y"
				data!.setFieldValue("DIRECT",str(read_tpl.direct_rate:sf_rate_mask$))
				data!.setFieldValue("OVHD",str(read_tpl.ovhd_rate:sf_rate_mask$))
				data!.setFieldValue("COST_EA",str(read_tpl.unit_cost:sf_cost_mask$))
				data!.setFieldValue("COST_TOT",str(read_tpl.tot_std_cost:sf_amt_mask$))
			endif
			rs!.insert(data!)			
		endif
		
		tot_recs=tot_recs+1
		
		tot_units_ea=tot_units_ea+read_tpl.runtime_hrs
		tot_cost_ea=tot_cost_ea+read_tpl.unit_cost
		tot_units_tot=tot_units_tot+read_tpl.total_time
		tot_cost_tot=tot_cost_tot+read_tpl.tot_std_cost
	wend

rem --- Output Totals

	if tot_recs>0 
		data! = rs!.getEmptyRecordData()
		data!.setFieldValue("THIS_IS_TOTAL_LINE","Y")
		data!.setFieldValue("OP_CODE","Total Operations")
		data!.setFieldValue("UNITS_EA",str(tot_units_ea:sf_units_mask$))
		data!.setFieldValue("UNITS_TOT",str(tot_units_tot:sf_units_mask$))
			
		if  print_costs$="Y"
			data!.setFieldValue("COST_EA",str(tot_cost_ea:sf_amt_mask$))
			data!.setFieldValue("COST_TOT",str(tot_cost_tot:sf_amt_mask$))
			data!.setFieldValue("COST_EA_RAW",str(tot_cost_ea))
			data!.setFieldValue("COST_TOT_RAW",str(tot_cost_tot))	
		else	
			data!.setFieldValue("COST_EA","0")
			data!.setFieldValue("COST_TOT","0")
			data!.setFieldValue("COST_EA_RAW","0")
			data!.setFieldValue("COST_TOT_RAW","0")	
		endif
		
		rs!.insert(data!)
	endif

rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit

rem --- Subroutines
	
	rem --- Print test pattern of main fields for developing/debugging column placement
	send_test_pattern: 

		if read_tpl.line_type$="M"
			Rem --- Send data row for Memos
			data!.setFieldValue("COMMENTS",FILL(LEN(read_tpl.ext_comments$)-1,"W")+"x")
		else
			rem --- Send data row for non-Memos
			data!.setFieldValue("REF_NO","99999X")
			data!.setFieldValue("OP_CODE",FILL(LEN(read_tpl.op_code$)-1,"W")+"X")
			data!.setFieldValue("CODE_DESC",FILL(LEN(opcode_tpl.code_desc$)-1,"W")+"x")
			data!.setFieldValue("REQ_DATE","98/65/6789")
			data!.setFieldValue("HOURS","x"+sf_hours_mask$+"x")
			data!.setFieldValue("PC_HR","x"+sf_units_mask$+"x")
			data!.setFieldValue("UNITS_EA","x"+sf_units_mask$+"x")
			data!.setFieldValue("SETUP","x"+sf_hours_mask$+"x")
			data!.setFieldValue("UNITS_TOT","x"+sf_units_mask$+"x")
			
			if print_costs$="Y"
				data!.setFieldValue("DIRECT","x"+sf_rate_mask$+"x")
				data!.setFieldValue("OVHD","x"+sf_rate_mask$+"x")
				data!.setFieldValue("COST_EA","x"+sf_cost_mask$+"x")
				data!.setFieldValue("COST_TOT","x"+sf_amt_mask$+"x")
			endif
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
        if cvs(q1$,2)="" return ""
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
