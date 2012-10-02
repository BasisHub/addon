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
	temp$="OP_CODE:C(1*), REQ_DATE:C(1*), HOURS:C(1*), PC_HR:C(1*), DIRECT:C(1*), OVHD:C(1*), "
	temp$=temp$+"UNITS_EA:C(1*), COST_EA:C(1*), SETUP:C(1*), UNITS_TOT:C(1*), COST_TOT:C(1*)"

	rs! = BBJAPI().createMemoryRecordSet(temp$)

rem --- Get Barista System Program directory

	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)

rem --- Get masks

	pgmdir$=stbl("+DIR_PGM",err=*next)

	iv_cost_mask$=fngetmask$("iv_cost_mask","###,##0.0000-",masks$)
	ad_units_mask$=fngetmask$("ad_units_mask","#,###.00",masks$)
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
    if status goto std_exit
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
    if status goto std_exit
	
	opcode_dev=channels[5]
	dim opcode_tpl$:templates$[5]
	
rem --- Build SQL statement

	sql_prep$="select op_code, require_date, runtime_hrs, pcs_per_hour, direct_rate, ovhd_rate, setup_time, "
	sql_prep$=sql_prep$+"hrs_per_pce, unit_cost, total_time, tot_std_cost, line_type, ext_comments "
	sql_prep$=sql_prep$+"from sfe_wooprtn where firm_id = '"+firm_id$+"' and wo_no = '"+wo_no$+"'"
	
	sql_chan=sqlunt
	sqlopen(sql_chan,err=*next)stbl("+DBNAME")
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
		if read_tpl.line_type$="M"
			data!.setFieldValue("OP_CODE",read_tpl.ext_comments$)
		else
			data!.setFieldValue("OP_CODE",read_tpl.op_code$+" "+opcode_tpl.code_desc$)
			data!.setFieldValue("REQ_DATE",fndate$(read_tpl.require_date$))
			data!.setFieldValue("HOURS",str(read_tpl.hrs_per_pce:sf_hours_mask$))
			data!.setFieldValue("PC_HR",str(read_tpl.pcs_per_hour:ad_units_mask$))
			data!.setFieldValue("DIRECT",str(read_tpl.direct_rate:sf_rate_mask$))
			data!.setFieldValue("OVHD",str(read_tpl.ovhd_rate:sf_rate_mask$))
			data!.setFieldValue("UNITS_EA",str(read_tpl.runtime_hrs:ad_units_mask$))
			data!.setFieldValue("COST_EA",str(read_tpl.unit_cost:iv_cost_mask$))
			data!.setFieldValue("SETUP",str(read_tpl.setup_time:sf_hours_mask$))
			data!.setFieldValue("UNITS_TOT",str(read_tpl.total_time:ad_units_mask$))
			data!.setFieldValue("COST_TOT",str(read_tpl.tot_std_cost:iv_cost_mask$))
		endif
		tot_recs=tot_recs+1
		rs!.insert(data!)
		tot_units_ea=tot_units_ea+read_tpl.runtime_hrs
		tot_cost_ea=tot_cost_ea+read_tpl.unit_cost
		tot_units_tot=tot_units_tot+read_tpl.total_time
		tot_cost_tot=tot_cost_tot+read_tpl.tot_std_cost
	wend

rem --- Output Totals

	if tot_recs>0
		data! = rs!.getEmptyRecordData()
		data!.setFieldValue("UNITS_EA",fill(20,"_"))
		data!.setFieldValue("COST_EA",fill(20,"_"))
		data!.setFieldValue("UNITS_TOT",fill(20,"_"))
		data!.setFieldValue("COST_TOT",fill(20,"_"))
		rs!.insert(data!)
	
		data! = rs!.getEmptyRecordData()
		data!.setFieldValue("OP_CODE","Total Operations")
		data!.setFieldValue("UNITS_EA",str(tot_units_ea:iv_cost_mask$))
		data!.setFieldValue("COST_EA",str(tot_cost_ea:iv_cost_mask$))
		data!.setFieldValue("UNITS_TOT",str(tot_units_tot:iv_cost_mask$))
		data!.setFieldValue("COST_TOT",str(tot_cost_tot:sf_rate_mask$))
		rs!.insert(data!)
	endif

rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit

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
