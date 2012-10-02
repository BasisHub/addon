rem ----------------------------------------------------------------------------
rem Program: BOMCOSTING.prc
rem Description: Stored Procedure to get the BOM Costing info into iReports
rem
rem Author(s): J. Brewer
rem Revised: 08.25.2011
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
	from_bill$ = sp!.getParameter("BILL_NO_1")
	thru_bill$ = sp!.getParameter("BILL_NO_2")
	barista_wd$ = sp!.getParameter("BARISTA_WD")

	sv_wd$=dir("")
	chdir barista_wd$

rem --- Create a memory record set to hold results.
rem --- Columns for the record set are defined using a string template
rs! = BBJAPI().createMemoryRecordSet("FIRM_ID:C(2), BILL_NO:C(20), DRAWING_NO:C(25), DRAWING_REV:C(5), BILL_REV:C(2), PHANTOM_BILL:C(1),
:                                     SOURCE_CODE:C(1), UNIT_MEASURE:C(2), LSTRVS_DATE:C(8), LSTACT_DATE:C(8), CREATE_DATE:C(8),
:                                     EST_YIELD:N(5*), STD_LOT_SIZE:N(7*), ITEMDESC:C(60), SUB_ASSMBLY:C(20)")

rem --- Get Barista System Program directory
	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)

rem --- Open files with adc

    files=4,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="bmm-01",ids$[1]="BMM_BILLMAST"
    files$[2]="bmm-01",ids$[2]="BMM_BILLMAST"
    files$[3]="bmm-02",ids$[3]="BMM_BILLMAT"
    files$[4]="ivm-01",ids$[4]="IVM_ITEMMAST"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
    if status goto std_exit
    bmm_billmast_dev = channels[1]
    bmm_billmast_dev1= channels[2]
    bmm_billmat_dev  = channels[3]
    ivm_itemmast_dev = channels[4]

rem --- Dimension string templates

    dim bmm_billmast$:templates$[1]
	dim bmm_billmat$:templates$[3]
	dim ivm_itemmast$:templates$[4]

goto no_bac_open
rem --- Open Files    
    num_files = 4
    dim open_tables$[1:num_files], open_opts$[1:num_files], open_chans$[1:num_files], open_tpls$[1:num_files]

	open_tables$[1]="BMM_BILLMAST",  open_opts$[1] = "OTA"
	open_tables$[2]="BMM_BILLMAST",  open_opts$[2] = "OTA[_2]"
	open_tables$[3]="BMM_BILLMAT",   open_opts$[3] = "OTA"
	open_tables$[4]="IVM_ITEMMAST",   open_opts$[4] = "OTA"

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

	bmm_billmast_dev  = num(open_chans$[1])
	bmm_billmast_dev1 = num(open_chans$[2])
	bmm_billmat_dev   = num(open_chans$[3])
	ivm_itemmast_dev  = num(open_chans$[4])

	dim bmm_billmast$:open_tpls$[1]
	dim bmm_billmat$:open_tpls$[3]
	dim ivm_itemmast$:open_tpls$[4]
no_bac_open:
rem --- Trip Read

	extract record (bmm_billmast_dev, key=firm_id$+from_bill$, dom=*next)
	while 1
		bmm01_key$=key(bmm_billmast_dev,end=*break)
		if pos(firm_id$=bmm01_key$)<>1 break
		readrecord (bmm_billmast_dev,key=bmm01_key$) bmm_billmast$
		if cvs(thru_bill$,2)<>""
			if cvs(bmm_billmast.bill_no$,2)>cvs(thru_bill$,2) break
		endif

		sub_assmbly$=bmm_billmast.bill_no$
		gosub output_bill

rem --- Now find all sub-bills within the main bill
		bill_numbers$=""

		read (bmm_billmat_dev,key=firm_id$+bmm_billmast.bill_no$,dom=*next)
		while 1
			dim bmm_billmat$:fattr(bmm_billmat$)
			readrecord (bmm_billmat_dev,end=*break) bmm_billmat$
			if pos(firm_id$+bmm_billmast.bill_no$=bmm_billmat$)<>1 break
			if bmm_billmat.line_type$<>"S" continue
			find (bmm_billmast_dev1,key=firm_id$+bmm_billmat.item_id$,dom=*continue)
			bill_numbers$=bill_numbers$+"*"+bmm_billmat.item_id$
		wend
		while pos("*"=bill_numbers$,bill_len+1)>0
			bill_pos=pos("*"=bill_numbers$,bill_len+1)
			next_bill$=bill_numbers$(bill_pos+1,bill_len)
			bill_numbers$(bill_pos,1)=" "
			gosub get_next_bill
		wend

rem --- Populate data set with all sub-bills
		if len(bill_numbers$)>0
			for x=1 to len(bill_numbers$) step bill_len+1
				readrecord (bmm_billmast_dev1,key=firm_id$+bill_numbers$(x+1,bill_len)) bmm_billmast$
				gosub output_bill
			next x
		endif
	wend

rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit
	
get_next_bill:
rem --- next_bill$ is the next subbill to use - input

	read(bmm_billmat_dev,key=firm_id$+next_bill$,dom=*next)
	while 1
		dim bmm_billmat$:fattr(bmm_billmat$)
		readrecord (bmm_billmat_dev,end=*break) bmm_billmat$
		if pos(firm_id$+next_bill$=bmm_billmat$)<>1 break
		if bmm_billmat.line_type$<>"S" continue
		find (bmm_billmast_dev1,key=firm_id$+bmm_billmat.item_id$,dom=*continue)
		bill_numbers$=bill_numbers$(1,bill_pos+bill_len)+"*"+bmm_billmat.item_id$+bill_numbers$(bill_pos+bill_len+1)
	wend
	
	return
	
output_bill:

	data! = rs!.getEmptyRecordData()
	
	bill_len=len(bmm_billmast.bill_no$)
		
	dim ivm_itemmast$:fattr(ivm_itemmast$)
	find record (ivm_itemmast_dev,key=firm_id$+bmm_billmast.bill_no$,dom=*next)ivm_itemmast$
	data!.setFieldValue("FIRM_ID",firm_id$)
	data!.setFieldValue("BILL_NO",bmm_billmast.bill_no$)
	data!.setFieldValue("DRAWING_NO",bmm_billmast.drawing_no$)
	data!.setFieldValue("DRAWING_REV",bmm_billmast.drawing_rev$)
	data!.setFieldValue("BILL_REV",bmm_billmast.bill_rev$)
	data!.setFieldValue("PHANTOM_BILL",bmm_billmast.phantom_bill$)
	data!.setFieldValue("SOURCE_CODE",bmm_billmast.source_code$)
	data!.setFieldValue("UNIT_MEASURE",bmm_billmast.unit_measure$)
	data!.setFieldValue("LSTRVS_DATE",bmm_billmast.lstrvs_date$)
	data!.setFieldValue("LSTACT_DATE",bmm_billmast.lstact_date$)
	data!.setFieldValue("CREATE_DATE",bmm_billmast.create_date$)
	data!.setFieldValue("EST_YIELD",bmm_billmast.est_yield$)
	data!.setFieldValue("STD_LOT_SIZE",bmm_billmast.std_lot_size$)
	data!.setFieldValue("ITEMDESC",ivm_itemmast.item_desc$)
	data!.setFieldValue("SUB_ASSMBLY",sub_assmbly$)
	rs!.insert(data!)
	
	return
	
	std_exit:
	
	end
