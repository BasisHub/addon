[[OPE_CREDMNT.BEND]]
rem --- One last chance to update the tickler date
	gosub update_tickler
[[OPE_CREDMNT.AOPT-MDAT]]
rem --- Modify Tickler date
	ctl_name$="<<DISPLAY>>.TICK_DATE"
	ctl_stat$=" "
	gosub disable_fields
[[OPE_CREDMNT.AOPT-RELO]]
rem --- Release an Order from Credit Hold

	gosub update_tickler
	cust$=callpoint!.getColumnData("OPE_CREDMNT.CUSTOMER_ID")
	ord$=callpoint!.getDevObject("order")
	if cvs(ord$,2)="" goto no_rel

	dim msg_tokens$[1]
	msg_tokens$[1]=ord$
	msg_id$="OP_CONFIRM_REL"
	gosub disp_message
	if msg_opt$="N" goto no_rel

	ope03_dev=fnget_dev("OPE_ORDHDR")
	dim ope03a$:fnget_tpl$("OPE_ORDHDR")
	arc_terms_dev=fnget_dev("ARC_TERMCODE")
	while 1
		readrecord(ope03_dev,key=firm_id$+ope03a.ar_type$+cust$+ord$,dom=*break)ope03a$
		rem --- allow change to Terms Code
		callpoint!.setDevObject("terms",ope03a.terms_code$)
		call stbl("+DIR_SYP")+"bam_run_prog.bbj","OPE_CREDTERMS",stbl("+USER_ID"),"MNT","",table_chans$[all]
		ope03a.terms_code$=callpoint!.getDevObject("terms")
		readrecord(arc_terms_dev,key=firm_id$+"A"+ope03a.terms_code$,dom=*next);goto good_code
		continue
good_code:
		ope03a.credit_flag$="R"
		ope03a$=field(ope03a$)
		writerecord(ope03_dev)ope03a$
		break
	wend

	gosub remove_tickler

rem --- Print the order?

	msg_id$="OP_ORDREL"
	gosub disp_message
	if msg_opt$="N" goto no_rel
escape;rem what's cust$ and ord$
	x$=stbl("on_demand","Y"+cust$+ord$)
	run "opr_oderpicklst.aon"

no_rel:
	callpoint!.setStatus("REFRESH")
[[OPE_CREDMNT.AOPT-CMTS]]
rem --- Comment Maintenance
	gosub update_tickler
	cust_id$=callpoint!.getColumnData("OPE_CREDMNT.CUSTOMER_ID")
	user_id$=stbl("+USER_ID")
	dim dflt_data$[2,1]
	dflt_data$[1,0]="CUSTOMER_ID"
	dflt_data$[1,1]=cust_id$
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:                       "ARM_CUSTCMTS",
:                       user_id$,
:                   	"MNT",
:                       firm_id$+cust_id$,
:                       table_chans$[all],
:                       "",
:                       dflt_data$[all]

	gosub disp_cust_comments
[[OPE_CREDMNT.AOPT-IDTL]]
rem Invoice Dtl Inquiry
	gosub update_tickler
	cp_cust_id$=callpoint!.getColumnData("OPE_CREDMNT.CUSTOMER_ID")
	user_id$=stbl("+USER_ID")
	dim dflt_data$[2,1]
	dflt_data$[1,0]="CUSTOMER_ID"
	dflt_data$[1,1]=cp_cust_id$
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:                       "ARR_INVDETAIL",
:                       user_id$,
:                   	"",
:                       "",
:                       table_chans$[all],
:                       "",
:                       dflt_data$[all]
[[OPE_CREDMNT.AOPT-ORIV]]
rem Order/Invoice History Inq
	gosub update_tickler
	cp_cust_id$=callpoint!.getColumnData("OPE_CREDMNT.CUSTOMER_ID")
	user_id$=stbl("+USER_ID")
	dim dflt_data$[2,1]
	dflt_data$[1,0]="CUSTOMER_ID"
	dflt_data$[1,1]=cp_cust_id$
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"ARR_ORDINVHIST",
:		user_id$,
:		"",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]
[[OPE_CREDMNT.ADIS]]
rem --- Set display fields
	tick_date$=callpoint!.getDevObject("tick_date")
	ord$=callpoint!.getDevObject("order")
	ord_date$=callpoint!.getDevObject("ord_date")
	ship_date$=callpoint!.getDevObject("ship_date")

	callpoint!.setColumnData("<<DISPLAY>>.TICK_DATE",tick_date$(5,4)+tick_date$(1,4))
	callpoint!.setColumnData("<<DISPLAY>>.ORD",ord$)
	if cvs(ord_date$,2)<>"" callpoint!.setColumnData("<<DISPLAY>>.ORD_DATE",ord_date$(5,4)+ord_date$(1,4))
	if cvs(ship_date$,2)<>"" callpoint!.setColumnData("<<DISPLAY>>.SHP_DATE",ship_date$(5,4)+ship_date$(1,4))

	cust_id$=callpoint!.getColumnData("OPE_CREDMNT.CUSTOMER_ID")
	gosub disp_cust_comments
[[OPE_CREDMNT.BSHO]]
rem --- Open tables
	num_files=4
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARM_CUSTCMTS",open_opts$[1]="OTA"
	open_tables$[2]="OPE_ORDHDR",open_opts$[1]="OTA"
	open_tables$[3]="ARC_TERMCODE",open_opts$[1]="OTA"
	open_tables$[4]="OPE_CREDDATE",open_opts$[1]="OTA"
	gosub open_tables
	arm05_dev=num(open_chans$[1])
	ope03_dev=num(open_chans$[2])
	arc_terms_dev=num(open_chans$[3])
	ope03_dev=num(open_chans$[4])

rem --- Enable 2 credit fields
	ctl_name$="ARM_CUSTDET.CREDIT_LIMIT"
	ctl_stat$=" "
	gosub disable_fields
	ctl_name$="ARM_CUSTDET.CRED_HOLD"
	gosub disable_fields
[[OPE_CREDMNT.<CUSTOM>]]
disable_fields:
	rem --- used to disable/enable controls
	rem --- ctl_name$ sent in with name of control to enable/disable (format "ALIAS.CONTROL_NAME")
	rem --- ctl_stat$ sent in as D or space, meaning disable/enable, respectively

	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")

return

disp_cust_comments:
	
rem --- You must pass in cust_id$ because we don't know whether it's verified or not
	cmt_text$=""
	arm05_dev=fnget_dev("ARM_CUSTCMTS")
	dim arm05a$:fnget_tpl$("ARM_CUSTCMTS")
	arm05_key$=firm_id$+cust_id$
	more=1
	read(arm05_dev,key=arm05_key$,dom=*next)
	while more
		readrecord(arm05_dev,end=*break)arm05a$
		 
		if arm05a.firm_id$ = firm_id$ and arm05a.customer_id$ = cust_id$ then
			cmt_text$ = cmt_text$ + cvs(arm05a.std_comments$,3)+$0A$
		endif				
	wend
	callpoint!.setColumnData("<<DISPLAY>>.comments",cmt_text$)
	callpoint!.setStatus("REFRESH")
return

update_tickler: rem --- Modify Tickler date
	ctl_name$="<<DISPLAY>>.TICK_DATE"
	ctl_stat$="D"
	gosub disable_fields
	ope03_dev=fnget_dev("OPE_CREDDATE")
	dim ope03a$:fnget_tpl$("OPE_CREDDATE")
	gosub remove_tickler
	tick_date$=callpoint!.getColumnData("<<DISPLAY>>.TICK_DATE")
	ord$=callpoint!.getDevObject("order")
	cust_no$=callpoint!.getColumnData("OPE_CREDMNT.CUSTOMER_ID")
	ope03a.firm_id$=firm_id$
	ope03a.rev_date$=tick_date$
	ope03a.customer_id$=cust_no$
	ope03a.order_no$=ord$
	ope03a$=field(ope03a$)
	writerecord(ope03_dev)ope03a$
	callpoint!.setDevObject("tick_date",tick_date$)
return

remove_tickler:
	ope03_dev=fnget_dev("OPE_CREDDATE")
	dim ope03a$:fnget_tpl$("OPE_CREDDATE")
	tick_date$=callpoint!.getDevObject("tick_date")
	ord$=callpoint!.getDevObject("order")
	cust_no$=callpoint!.getColumnData("OPE_CREDMNT.CUSTOMER_ID")
	remove(ope03_dev,key=firm_id$+tick_date$(5,4)+tick_date$(1,4)+cust_no$+ord$,dom=*next)
return
