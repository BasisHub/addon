[[OPE_CREDMAINT.ARER]]
rem --- Set dates to CCYYMMDD
	tick_date$=callpoint!.getColumnData("OPE_CREDMAINT.REV_DATE")
	tick_date$=tick_date$(5,4)+tick_date$(1,4)
	callpoint!.setColumnData("OPE_CREDMAINT.REV_DATE",tick_date$)
	callpoint!.setDevObject("old_tick_date",tick_date$)
	ord_date$=callpoint!.getColumnData("OPE_CREDMAINT.ORDER_DATE")
	ord_date$=ord_date$(5,4)+ord_date$(1,4)
	callpoint!.setColumnData("OPE_CREDMAINT.ORDER_DATE",ord_date$)
	ship_date$=callpoint!.getColumnData("OPE_CREDMAINT.SHIPMNT_DATE")
	ship_date$=ship_date$(5,4)+ship_date$(1,4)
	callpoint!.setColumnData("OPE_CREDMAINT.SHIPMNT_DATE",ship_date$)

rem --- Display Comments
	cust_id$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
	gosub disp_cust_comments
[[OPE_CREDMAINT.AOPT-DELO]]
rem --- Delete the Order or the Followup date for the Customer

rem 2700 REM " --- Delete Existing Followup Date - From 4000
rem 2710 IF POS(" "<>C$(16,7))=0 THEN LET V4$="Confirm: Do You Want To Remove The Fo
rem llow-Up Date (Yes/No)?"; GOTO 2730
rem rem 2720 LET V4$="Confirm: Do You Want To Delete The Order And The Date (Yes/No)?"
rem 2730 LET V0$="S",V1$="KC",V2$="NO",V3$="",V0=3,V1=FNV(V4$),V2=22
rem 2740 GOSUB 7000
rem 2750 IF V$="YES" THEN GOSUB 4200; GOTO 1000
rem 2760 IF V$="NO" OR V3=4 THEN GOTO 4000
rem 2770 GOTO 2700

rem 4200 REM " --- Delete the order
rem 4210 DIM A0$(117),A[10],W1$(64),W[14]
rem 4220 LET A0$(1)=N0$+"  "+C$(10)+"000"
rem 4230 READ (ARE03_DEV,KEY=A0$(1,20),DOM=4740)IOL=ARE03A1
rem 4250 IF A0$(22,1)="I" THEN GOSUB WARN_INVOICE; GOTO 4795
rem 4260 READ (ARE13_DEV,KEY=A0$(1,17),DOM=4270)
rem 4270 LET K13$=KEY(ARE13_DEV,END=4700)
rem 4280 IF K13$(1,17)<>A0$(1,17) THEN GOTO 4700
rem 4285 READ (ARE13_DEV)IOL=ARE13A
rem 4290 FIND (ARM10_DEV,KEY=N0$+"E"+W0$(21,1),DOM=4540)IOL=ARM10E
rem 4300 IF POS(Y0$(25,1)="SP")=0 THEN GOTO 4540
rem 4310 IF A0$(21,1)="P" THEN GOTO 4380
rem 4320 IF Y0$(27,1)="Y" OR W1$(44,1)="N" THEN GOTO 4380
rem 4330 REM " --- Uncommit Inventory
rem 4340 LET ITEM$[0]=N0$,ITEM$[1]=W0$(31,2),ITEM$[2]=W0$(33,20)
rem 4350 LET ACTION$="UC",REFS[0]=W[2]
rem 4360 IF POS(I3$(17,1)="LS") THEN GOTO LOT_SERIAL
rem 4370 CALL "IVC.UA",ACTION$,FILES[ALL],PARAMS[ALL],PARAMS$[ALL],ITEM$[ALL],REFS$[
rem ALL],REFS[ALL],STATUS
rem 4380 REMOVE (ARE07_DEV,KEY=N0$+W0$(31)+W0$(3,2)+W0$(11,10)+W0$(5,6),DOM=4390)
rem 4390 GOTO 4490
rem 4400 LOT_SERIAL:
rem 4410 DIM T[2],H[11]
rem 4420 READ (ARE23_DEV,KEY=W0$(1,20),DOM=4430)IOL=ARE23A
rem 4430 LET K9$=KEY(ARE23_DEV,END=4490)
rem 4440 IF K9$(1,20)<>W0$(1,20) THEN GOTO 4490
rem 4450 READ (ARE23_DEV)IOL=ARE23A
rem 4460 LET ITEM$[3]=T1$,REFS[0]=T[0]
rem 4470 CALL "IVC.UA",ACTION$,FILES[ALL],PARAMS[ALL],PARAMS$[ALL],ITEM$[ALL],REFS$[
rem ALL],REFS[ALL],STATUS
rem 4480 REMOVE (ARE23_DEV,KEY=K9$); GOTO 4430
rem 4490 IF W0$(26,1)<>"A" THEN GOTO 4540
rem 4540 REMOVE (ARE13_DEV,KEY=K13$,DOM=4550)
rem 4550 GOTO 4270
rem 4700 REM " --- Remove Header
rem 4710 REMOVE (ARE33_DEV,KEY=N0$+A0$(5,13),DOM=4720)
rem 4720 REMOVE (ARE03_DEV,KEY=A0$(1,20))
rem 4730 REMOVE (ARE04_DEV,KEY=N0$+"O"+A0$(3,15),DOM=4731)
rem 4735 REMOVE (ARE43_DEV,KEY=A0$(1,4)+A0$(11,7)+A0$(5,6),DOM=4736)
rem 4740 GOSUB 2200rem --- remove the tickler record
rem 4750 REM " --- Reset Next Order Number"
rem 4755 DIM N[4]
rem 4760 LET N$=N0$+"N",N[2]=1000,N[3]=1000
rem 4770 EXTRACT (ARS10_DEV,KEY=N$,DOM=4790)IOL=ARS10N
rem 4780 IF NUM(A0$(11,7))=N[2]-1 THEN LET N[2]=NUM(A0$(11,7))
rem 4790 WRITE (ARS10_DEV,KEY=N$)IOL=ARS10N
rem 4795 RETURN
rem 4800 REM " --- Hold/Unhold Customers
rem 4810 EXTRACT (ARM02_DEV,KEY=D0$,ERR=4820)IOL=ARM02A; GOTO 4830
rem 4820 LET V0$="S",V1$="C",V2$="",V3$="",V4$="Unable To Extract Record For Changes
rem . <Enter> To Retry, <F4> To Exit. ",V0=1,V1=FNV(V4$),V2=22; GOSUB 7000; IF V3=4
rem THEN GOTO 4000
rem 4830 LET V0$="S",V1$="C",V2$=D1$(39,1),V3$="YNE",V4$="Y=Yes, N=No, E=Exempt From
rem  Credit Hold",V0=1,V1=57,V2=10
rem 4840 GOSUB 7000
rem 4850 LET D1$(39,1)=V$
rem 4860 WRITE (ARM02_DEV,KEY=D0$)IOL=ARM02A
rem 4870 PRINT @(57,10),D1$(39,1)
rem 4880 GOTO 4000
[[OPE_CREDMAINT.AOPT-ORIV]]
rem Order/Invoice History Inq
	gosub update_tickler
	cp_cust_id$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
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
[[OPE_CREDMAINT.AOPT-IDTL]]
rem Invoice Dtl Inquiry
	gosub update_tickler
	cp_cust_id$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
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
[[OPE_CREDMAINT.AOPT-MDAT]]
rem --- Modify Information

	callpoint!.setDevObject("tick_date",callpoint!.getColumnData("OPE_CREDMAINT.REV_DATE"))
	callpoint!.setDevObject("cred_hold",callpoint!.getColumnData("OPE_CREDMAINT.CRED_HOLD"))
	callpoint!.setDevObject("cred_limit",callpoint!.getColumnData("OPE_CREDMAINT.CREDIT_LIMIT"))
	call stbl("+DIR_SYP")+"bam_run_prog.bbj","OPE_CREDMOD",stbl("+USER_ID"),"MNT","",table_chans$[all]
	tick_date$=callpoint!.getDevObject("tick_date")
	cred_hold$=callpoint!.getDevObject("cred_hold")
	cred_limit$=callpoint!.getDevObject("cred_limit")
	callpoint!.setColumnData("OPE_CREDMAINT.REV_DATE",tick_date$)
	callpoint!.setColumnData("OPE_CREDMAINT.CRED_HOLD",cred_hold$)
	callpoint!.setColumnData("OPE_CREDMAINT.CREDIT_LIMIT",cred_limit$)
	callpoint!.setStatus("REFRESH")

rem --- Update Credit changes to master file
	arm02_dev=fnget_dev("ARM_CUSTDET")
	dim arm02a$:fnget_tpl$("ARM_CUSTDET")
	readrecord(arm02_dev,key=firm_id$+callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")+"  ")arm02a$
	arm02a.cred_hold$=cred_hold$
	arm02a.credit_limit=num(cred_limit$)
	arm02a$=field(arm02a$)
	writerecord(arm02_dev)arm02a$
[[OPE_CREDMAINT.BEND]]
rem --- One last chance to update the tickler date
	gosub update_tickler
[[OPE_CREDMAINT.AOPT-RELO]]
rem --- Release an Order from Credit Hold
	gosub update_tickler
	cust$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
	ord$=callpoint!.getColumnData("OPE_CREDMAINT.ORDER_NO")
	if cvs(ord$,2)="" goto no_rel

	dim msg_tokens$[1]
	msg_tokens$[1]=ord$
	msg_id$="OP_CONFIRM_REL"
	gosub disp_message
	if msg_opt$="N" goto no_rel

	ope01_dev=fnget_dev("OPE_ORDHDR")
	dim ope01a$:fnget_tpl$("OPE_ORDHDR")
	arc_terms_dev=fnget_dev("ARC_TERMCODE")
	while 1
		readrecord(ope01_dev,key=firm_id$+"  "+cust$+ord$,dom=*break)ope01a$
		rem --- allow change to Terms Code
		callpoint!.setDevObject("terms",ope01a.terms_code$)
		call stbl("+DIR_SYP")+"bam_run_prog.bbj","OPE_CREDTERMS",stbl("+USER_ID"),"MNT","",table_chans$[all]
		ope01a.terms_code$=callpoint!.getDevObject("terms")
		readrecord(arc_terms_dev,key=firm_id$+"A"+ope01a.terms_code$,dom=*next);goto good_code
		continue
good_code:
		ope01a.credit_flag$="R"
		ope01a$=field(ope01a$)
		writerecord(ope01_dev)ope01a$
		break
	wend

	gosub remove_tickler

rem --- Print the order?

	msg_id$="OP_ORDREL"
	gosub disp_message
	if msg_opt$="N" goto no_rel
	x$=stbl("on_demand","Y"+cust$+ord$)
	run "opr_oderpicklst.aon"
	callpoint!.setStatus("EXIT")

no_rel:
	callpoint!.setStatus("REFRESH")
[[OPE_CREDMAINT.BSHO]]
rem --- Open tables
	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARM_CUSTCMTS",open_opts$[1]="OTA"
	open_tables$[2]="OPE_ORDHDR",open_opts$[2]="OTA"
	open_tables$[3]="ARC_TERMCODE",open_opts$[3]="OTA"
	open_tables$[4]="OPE_CREDDATE",open_opts$[4]="OTA"
	open_tables$[5]="ARM_CUSTDET",open_opts$[5]="OTA"
	gosub open_tables
	arm05_dev=num(open_chans$[1])
	ope01_dev=num(open_chans$[2])
	arc_terms_dev=num(open_chans$[3])
	ope03_dev=num(open_chans$[4])
	arm02_dev=num(open_chans$[5])
[[OPE_CREDMAINT.<CUSTOM>]]
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
	ope03_dev=fnget_dev("OPE_CREDDATE")
	dim ope03a$:fnget_tpl$("OPE_CREDDATE")
	gosub remove_tickler
	tick_date$=callpoint!.getColumnData("OPE_CREDMAINT.REV_DATE")
	callpoint!.setDevObject("old_tick_date",tick_date$)
	ord$=callpoint!.getColumnData("OPE_CREDMAINT.ORDER_NO")
	cust_no$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
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
	old_tick_date$=callpoint!.getDevObject("old_tick_date")
	ord$=callpoint!.getColumnData("OPE_CREDMAINT.ORDER_NO")
	cust_no$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
	remove(ope03_dev,key=firm_id$+old_tick_date$+cust_no$+ord$,dom=*next)
return
[[OPE_CREDMAINT.AOPT-COMM]]
rem --- Comment Maintenance
	gosub update_tickler
	cust_id$=callpoint!.getColumnData("OPE_CREDMAINT.CUSTOMER_ID")
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
