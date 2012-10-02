[[BMC_COPYBILL.ITEM_ID.AINV]]
rem --- Check for item synonyms

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[BMC_COPYBILL.BSHO]]
rem --- Open tables for copying

	num_files=10
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="BMM_BILLMAST",open_opts$[1]="OTAN[2_]"
	open_tables$[2]="BMM_BILLMAT",open_opts$[2]="OTAN[2_]"
	open_tables$[3]="BMM_BILLOPER",open_opts$[3]="OTAN[2_]"
	open_tables$[4]="BMM_BILLCMTS",open_opts$[4]="OTAN[2_]"
	open_tables$[5]="BMM_BILLSUB",open_opts$[5]="OTAN[2_]"
	open_tables$[6]="BMM_BILLMAST",open_opts$[6]="OTAN[3_]"
	open_tables$[7]="BMM_BILLMAT",open_opts$[7]="OTAN[3_]"
	open_tables$[8]="BMM_BILLOPER",open_opts$[8]="OTAN[3_]"
	open_tables$[9]="BMM_BILLCMTS",open_opts$[9]="OTAN[3_]"
	open_tables$[10]="BMM_BILLSUB",open_opts$[10]="OTAN[3_]"
	gosub open_tables

	callpoint!.setDevObject("oldbillmast",num(open_chans$[1]))
	callpoint!.setDevObject("oldbillmat",num(open_chans$[2]))
	callpoint!.setDevObject("oldbilloper",num(open_chans$[3]))
	callpoint!.setDevObject("oldbillcmts",num(open_chans$[4]))
	callpoint!.setDevObject("oldbillsub",num(open_chans$[5]))
	callpoint!.setDevObject("newbillmast",num(open_chans$[6]))
	callpoint!.setDevObject("newbillmat",num(open_chans$[7]))
	callpoint!.setDevObject("newbilloper",num(open_chans$[8]))
	callpoint!.setDevObject("newbillcmts",num(open_chans$[9]))
	callpoint!.setDevObject("newbillsub",num(open_chans$[10]))
[[BMC_COPYBILL.ASVA]]
rem --- Check to see if the Bill already exists

	old_bmm_mast=callpoint!.getDevObject("oldbillmast")
	new_bill$=callpoint!.getColumnData("BMC_COPYBILL.ITEM_ID")
	while 1
		find (old_bmm_mast,key=firm_id$+new_bill$,dom=*break)
		msg_id$="BILL_EXISTS"
		gosub disp_message
		callpoint!.setStatus("EXIT")
		break
	wend

	if pos("EXIT"=callpoint!.getStatus())>0
		break
	endif

rem -- Do the actual copy

rem --- copy Bill Master

	old_bill$=callpoint!.getDevObject("master_bill")

	new_bmm_mast=callpoint!.getDevObject("newbillmast")
	dim bmm_mast$:fnget_tpl$("BMM_BILLMAST")
	read record (old_bmm_mast,key=firm_id$+old_bill$) bmm_mast$
	bmm_mast.bill_no$=new_bill$
	bmm_mast.create_date$=stbl("+SYSTEM_DATE")
	bmm_mast$=field(bmm_mast$)
	write record (new_bmm_mast) bmm_mast$
	callpoint!.setDevObject("new_bill",new_bill$)

rem --- copy Components

	old_bmm_mat=callpoint!.getDevObject("oldbillmat")
	new_bmm_mat=callpoint!.getDevObject("newbillmat")
	dim bmm_mat$:fnget_tpl$("BMM_BILLMAT")
	read record (old_bmm_mat,key=firm_id$+old_bill$,dom=*next)
	while 1
		read record (old_bmm_mat,end=*break) bmm_mat$
		if pos(firm_id$+old_bill$=bmm_mat$)<>1 break
		bmm_mat.bill_no$=new_bill$
		bmm_mat$=field(bmm_mat$)
		write record (new_bmm_mat) bmm_mat$
	wend

rem --- copy Operations

	old_bmm_oper=callpoint!.getDevObject("oldbilloper")
	new_bmm_oper=callpoint!.getDevObject("newbilloper")
	dim bmm_oper$:fnget_tpl$("BMM_BILLOPER")
	read record (old_bmm_oper,key=firm_id$+old_bill$,dom=*next)
	while 1
		read record (old_bmm_oper,end=*break) bmm_oper$
		if pos(firm_id$+old_bill$=bmm_oper$)<>1 break
		bmm_oper.bill_no$=new_bill$
		bmm_oper$=field(bmm_oper$)
		write record (new_bmm_oper) bmm_oper$
	wend

rem --- copy comments

	old_bmm_cmts=callpoint!.getDevObject("oldbillcmts")
	new_bmm_cmts=callpoint!.getDevObject("newbillcmts")
	dim bmm_cmts$:fnget_tpl$("BMM_BILLCMTS")
	read record (old_bmm_cmts,key=firm_id$+old_bill$,dom=*next)
	while 1
		read record (old_bmm_cmts,end=*break) bmm_cmts$
		if pos(firm_id$+old_bill$=bmm_cmts$)<>1 break
		bmm_cmts.bill_no$=new_bill$
		bmm_cmts$=field(bmm_cmts$)
		write record (new_bmm_cmts) bmm_cmts$
	wend

rem --- copy subcontracts

	old_bmm_sub=callpoint!.getDevObject("oldbillsub")
	new_bmm_sub=callpoint!.getDevObject("newbillsub")
	dim bmm_sub$:fnget_tpl$("BMM_BILLSUB")
	read record (old_bmm_sub,key=firm_id$+old_bill$,dom=*next)
	while 1
		read record (old_bmm_sub,end=*break) bmm_sub$
		if pos(firm_id$+old_bill$=bmm_sub$)<>1 break
		bmm_sub.bill_no$=new_bill$
		bmm_sub$=field(bmm_sub$)
		write record (new_bmm_sub) bmm_sub$
	wend

rem --- Close files

	num_files=10
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="BMM_BILLMAST",open_opts$[1]="C[2_]"
	open_tables$[2]="BMM_BILLMAT",open_opts$[2]="C[2_]"
	open_tables$[3]="BMM_BILLOPER",open_opts$[3]="C[2_]"
	open_tables$[4]="BMM_BILLCMTS",open_opts$[4]="C[2_]"
	open_tables$[5]="BMM_BILLSUB",open_opts$[5]="C[2_]"
	open_tables$[6]="BMM_BILLMAST",open_opts$[6]="C[3_]"
	open_tables$[7]="BMM_BILLMAT",open_opts$[7]="C[3_]"
	open_tables$[8]="BMM_BILLOPER",open_opts$[8]="C[3_]"
	open_tables$[9]="BMM_BILLCMTS",open_opts$[9]="C[3_]"
	open_tables$[10]="BMM_BILLSUB",open_opts$[10]="C[3_]"
	gosub open_tables

rem --- Display Complete message

	msg_id$="COPY_COMPLETE"
	gosub disp_message
[[BMC_COPYBILL.ITEM_ID.AVAL]]
rem --- Verify valid Item

	if callpoint!.getDevObject("master_bill") = callpoint!.getUserInput()
		msg_id$="BM_BAD_COMP_ITEM"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
