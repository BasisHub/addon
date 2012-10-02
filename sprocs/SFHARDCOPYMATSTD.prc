rem ----------------------------------------------------------------------------
rem Program: SFHARDCOPYOMATSTD.prc
rem Description: Stored Procedure to get the Shop Floor Hard Copy Material info into iReports
rem Used for Hard Copy, Traveler, Work Order Closed Detail and Work Order Detail
rem
rem Author(s): J. Brewer
rem Revised: 04.18.2012
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
	
	sv_wd$=dir("")
	chdir barista_wd$

rem --- Create a memory record set to hold results.
rem --- Columns for the record set are defined using a string template
	temp$="ITEM:C(1*), OP_SEQ:C(1*), SCRAP:C(1*), DIVISOR:C(1*), FACTOR:C(1*), QTY_REQ:C(1*), "
	temp$=temp$+"UNITS_EA:C(1*), COST_EA:C(1*), UNITS_TOT:C(1*), COST_TOT:C(1*)"

	rs! = BBJAPI().createMemoryRecordSet(temp$)

rem --- Get Barista System Program directory

	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)

rem --- Get masks

rem	x$=stbl("+USER_ID","admin")
rem	call stbl("+DIR_SYP")+"bas_process_beg.bbj",stbl("+USER_ID"),rd_table_chans$[all]

rem escape;rem ? 

	pgmdir$=stbl("+DIR_PGM",err=*next)
rem 	call pgmdir$+"adc_getsprocmask.aon",firm_id$,"","SF","U","",m1$,0,m1
rem	call pgmdir$+"adc_getmask.aon","","SF","U","",m1$,0,m1
rem	call pgmdir$+"adc_getmask.aon","","AR","I","",custmask$,0,custmask
	iv_cost_mask$="###,##0.0000-"
	bm_units_mask$="#,##0.00"
	bm_rate_mask$="###.00"
	sf_rate_mask$="###.00"
	bm_hours_mask$="#,##0.00"
	
rem --- Open files with adc

    files=3,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="ivm-01",ids$[1]="IVM_ITEMMAST"
	files$[2]="arm-01",ids$[2]="ARM_CUSTMAST"
	files$[3]="sfs_params",ids$[3]="SFS_PARAMS"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
    if status goto std_exit
    ivm_itemmast_dev=channels[1]
	arm_custmast=channels[2]
	sfs_params=channels[3]

rem --- Dimension string templates

	dim ivm_itemmast$:templates$[1]
	dim arm_custmast$:templates$[2]
	dim sfs_params$:templates$[3]
	
goto no_bac_open
rem --- Open Files    
    num_files = 3
    dim open_tables$[1:num_files], open_opts$[1:num_files], open_chans$[1:num_files], open_tpls$[1:num_files]

	open_tables$[1]="IVM_ITEMMAST",   open_opts$[1] = "OTA"
	open_tables$[2]="ARM_CUSTMAST",   open_opts$[2] = "OTA"
	open_tables$[3]="SFS_PARAMS",     open_opts$[3] = "OTA"
	
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
	arm_custmast = num(open_chans$[2])
	sfs_params = num(open_chans$[3])
	
	dim ivm_itemmast$:open_tpls$[1]
	dim arm_custmast$:open_tpls$[2]
	dim sfs_params$:open_tpls$[3]

no_bac_open:

rem --- Build SQL statement

	sql_prep$="select item_id, oper_seq_ref, scrap_factor, divisor, alt_factor, qty_required, "
	sql_prep$=sql_prep$+"units, unit_cost, total_units, total_cost "
	sql_prep$=sql_prep$+"from sfe_womatl where firm_id = '"+firm_id$+"' and wo_no = '"+wo_no$+"'"
	
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
		read record (ivm_itemmast_dev,key=firm_id$+read_tpl.item_id$,dom=*next) ivm_itemmast$
		data!.setFieldValue("ITEM",read_tpl.item_id$+" "+ivm_itemmast.item_desc$)
rem		data!.setFieldValue("OP_SEQ",fndate$(read_tpl.require_date$))
		data!.setFieldValue("SCRAP",str(read_tpl.scrap_factor:bm_hours_mask$))
		data!.setFieldValue("DIVISOR",str(read_tpl.divisor:bm_units_mask$))
		data!.setFieldValue("FACTOR",str(read_tpl.alt_factor:bm_rate_mask$))
		data!.setFieldValue("QTY_REQ",str(read_tpl.qty_required:sf_rate_mask$))
		data!.setFieldValue("UNITS_EA",str(read_tpl.units:iv_cost_mask$))
		data!.setFieldValue("COST_EA",str(read_tpl.unit_cost:iv_cost_mask$))
		data!.setFieldValue("UNITS_TOT",str(read_tpl.total_units:iv_cost_mask$))
		data!.setFieldValue("COST_TOT",str(read_tpl.total_cost:sf_rate_mask$))
		rs!.insert(data!)
	wend
	
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


	std_exit:
	
	end
