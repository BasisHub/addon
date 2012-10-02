rem ----------------------------------------------------------------------------
rem Program: SFHARDCOPYSUBSTD.prc
rem Description: Stored Procedure to get the Shop Floor Hard Copy Subcontract info into iReports
rem Used for Hard Copy, Traveler, Work Order Closed Detail and Work Order Detail
rem
rem Author(s): J. Brewer
rem Revised: 04.20.2012
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
	temp$="VENDOR:C(1*), DESC:C(1*), OP_SEQ:C(1*), DATE_REQ:C(1*), STATUS:C(1*), "
	temp$=temp$+"UNITS_EA:C(1*), COST_EA:C(1*), UNITS_TOT:C(1*), COST_TOT:C(1*)"

	rs! = BBJAPI().createMemoryRecordSet(temp$)

rem --- Get Barista System Program directory

	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)

rem --- Get masks

	pgmdir$=stbl("+DIR_PGM",err=*next)

	iv_cost_mask$=fngetmask$("iv_cost_mask","###,##0.0000-",masks$)
	ad_units_mask$=fngetmask$("ad_units_mask","#,###.00",masks$)
	vendor_mask$=fngetmask$("vendor_mask","000000",masks$)

rem --- Init totals

	tot_cost_ea=0
	tot_cost_tot=0

rem --- Open files with adc

    files=4,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
	files$[1]="apm-01",ids$[1]="APM_VENDMAST"
	files$[2]="sfs_params",ids$[2]="SFS_PARAMS"
	files$[3]="sfe-02",ids$[3]="SFE_WOOPRTN"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
    if status goto std_exit
	apm_vendmast=channels[1]
	sfs_params=channels[2]
	sfe02_dev=channels[3]

rem --- Dimension string templates

	dim apm_vendmast$:templates$[1]
	dim sfs_params$:templates$[2]
	dim sfe02a$:templates$[3]

rem --- Get proper Op Code Maintenance table

	read record (sfs_params,key=firm_id$+"SF00") sfs_params$
	bm$=sfs_params.bm_interface$
	if bm$<>"Y"
		files$[4]="sfm-02",ids$[4]="SFC_OPRTNCOD"
	else
		files$[4]="bmm-08",ids$[4]="BMC_OPCODES"
	endif
    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
    if status goto std_exit
	
	opcode_dev=channels[4]
	dim opcode_tpl$:templates$[4]
	
rem --- generate vector for use with Op Sequence

	SysGUI!=BBjAPI()
	ops_lines!=SysGUI!.makeVector()
	ops_list!=SysGUI!.makeVector()

	read(sfe02_dev,key=firm_id$+wo_loc$+wo_no$,dom=*next)
	while 1
		read record (sfe02_dev,end=*break) sfe02a$
		if pos(firm_id$+wo_loc$+wo_no$=sfe02a$)<>1 break
		if sfe02a.line_type$<>"S" continue
		dim opcode_tpl$:fattr(opcode_tpl$)
		read record (opcode_dev,key=firm_id$+sfe02a.op_code$,dom=*next)opcode_tpl$
		ops_lines!.addItem(sfe02a.internal_seq_no$)
		op_code_list$=op_code_list$+sfe02a.op_code$
		work_var=pos(sfe02a.op_code$=op_code_list$,len(sfe02a.op_code$),0)
		if work_var>1
			work_var$=sfe02a.op_code$+"("+str(work_var)+")"
		else
			work_var$=sfe02a.op_code$
		endif
		ops_list!.addItem(work_var$+" - "+opcode_tpl.code_desc$)
	wend

rem --- Build SQL statement

	sql_prep$="select vendor_id, description, oper_seq_ref, require_date, po_status, "
	sql_prep$=sql_prep$+"units, unit_cost, total_units, total_cost, line_type, ext_comments "
	sql_prep$=sql_prep$+"from sfe_wosubcnt where firm_id = '"+firm_id$+"' and wo_no = '"+wo_no$+"'"
	
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

		dim apm_vendmast$:fattr(apm_vendmast$)
		read record (apm_vendmast,key=firm_id$+read_tpl.vendor_id$,dom=*next) apm_vendmast$
		if read_tpl.line_type$<>"S"
			data!.setFieldValue("VENDOR",read_tpl.ext_comments$)
		else
			data!.setFieldValue("VENDOR",fnmask$(read_tpl.vendor_id$,vendor_mask$)+" "+apm_vendmast.vendor_name$)
rem			data!.setFieldValue("OP_SEQ",fndate$(read_tpl.require_date$))
rem			data!.setFieldValue("DESC",read_tpl.description$)
			data!.setFieldValue("DATE_REQ",fndate$(read_tpl.require_date$))
			data!.setFieldValue("STATUS",read_tpl.po_status$)
			data!.setFieldValue("UNITS_EA",str(read_tpl.units:ad_units_mask$))
			data!.setFieldValue("COST_EA",str(read_tpl.unit_cost:iv_cost_mask$))
			data!.setFieldValue("UNITS_TOT",str(read_tpl.total_units:ad_units_mask$))
			data!.setFieldValue("COST_TOT",str(read_tpl.total_cost:iv_cost_mask$))
		endif
		rs!.insert(data!)

		if read_tpl.line_type$="S"
			data! = rs!.getEmptyRecordData()
			data!.setFieldValue("DESC",read_tpl.description$)
			if cvs(read_tpl.oper_seq_ref$,3)<>""
				if ops_lines!.size()
					for x=0 to ops_lines!.size()-1
						if read_tpl.oper_seq_ref$=ops_lines!.getItem(x)
							data!.setFieldValue("OP_SEQ","Op Code: "+ops_list!.getItem(x))
						endif
					next x
				endif
			endif
			rs!.insert(data!)
		endif

		tot_cost_ea=tot_cost_ea+read_tpl.unit_cost
		tot_cost_tot=tot_cost_tot+read_tpl.total_cost
		tot_recs=tot_recs+1
	wend

rem --- Output Totals
	if tot_recs>0
		data! = rs!.getEmptyRecordData()
		data!.setFieldValue("COST_EA",fill(20,"_"))
		data!.setFieldValue("COST_TOT",fill(20,"_"))
		rs!.insert(data!)
	
		data! = rs!.getEmptyRecordData()
		data!.setFieldValue("VENDOR","Total Subcontracts")
		data!.setFieldValue("COST_EA",str(tot_cost_ea:iv_cost_mask$))
		data!.setFieldValue("COST_TOT",str(tot_cost_tot:iv_cost_mask$))
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
