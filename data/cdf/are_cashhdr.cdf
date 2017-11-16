[[ARE_CASHHDR.BPRK]]
rem --- Is previous record for the current deposit?
	are01_dev=fnget_dev("ARE_CASHHDR")
	dim are01a$:fnget_tpl$("ARE_CASHHDR")

	rem --- Position the file at the correct record
	batch_no$=callpoint!.getColumnData("ARE_CASHHDR.BATCH_NO")
	ar_type$=callpoint!.getColumnData("ARE_CASHHDR.AR_TYPE")
	start_key$=firm_id$+batch_no$+ar_type$
	trip_key$=start_key$+callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_01")
	trip_key$=trip_key$+callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")
	trip_key$=trip_key$+callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID")
	trip_key$=trip_key$+callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD")
	trip_key$=trip_key$+callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")
	trip_key$=trip_key$+callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_02")
	read record (are01_dev,key=trip_key$,dir=0,dom=*next)

	hit_eof=0
	deposit_id$=callpoint!.getDevObject("deposit_id")
	while 1
		p_key$ = keyp(are01_dev, end=eof_pkey)
		read record (are01_dev, key=p_key$)are01a$
		if are01a.firm_id$+are01a.batch_no$+are01a.ar_type$=start_key$ then
			if are01a.deposit_id$=deposit_id$ then
				rem --- Have a keeper, stop looking
				break
			else
				rem --- Keep looking
				read (are01_dev, key=p_key$, dir=0)
				continue
			endif
		endif
		rem --- End-of-firm

eof_pkey: rem --- If end-of-file or end-of-firm, rewind to last record in this firm
		read (are01_dev, key=start_key$+$ff$, dom=*next)
		hit_eof=hit_eof+1
		if hit_eof>1 then
			msg_id$ = "AR_DEPOSIT_NO_RCPTS"
			gosub disp_message
			callpoint!.setStatus("ABORT-NEWREC")
			break
		endif
	wend
[[ARE_CASHHDR.BNEK]]
rem --- Is next record for the current deposit?
	are01_dev=fnget_dev("ARE_CASHHDR")
	dim are01a$:fnget_tpl$("ARE_CASHHDR")

	rem --- Position the file at the correct record
	batch_no$=callpoint!.getColumnData("ARE_CASHHDR.BATCH_NO")
	ar_type$=callpoint!.getColumnData("ARE_CASHHDR.AR_TYPE")
	start_key$=firm_id$+batch_no$+ar_type$
	trip_key$=start_key$+callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_01")
	trip_key$=trip_key$+callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")
	trip_key$=trip_key$+callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID")
	trip_key$=trip_key$+callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD")
	trip_key$=trip_key$+callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")
	trip_key$=trip_key$+callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_02")
	read record (are01_dev,key=trip_key$,dom=*next)

	hit_eof=0
	deposit_id$=callpoint!.getDevObject("deposit_id")
	while 1
		read record (are01_dev, dir=0, end=eof)are01a$
		if are01a.firm_id$+are01a.batch_no$+are01a.ar_type$=start_key$ then
			if are01a.deposit_id$=deposit_id$ then
				rem --- Have a keeper, stop looking
				break
			else
				rem --- Keep looking
				read (are01_dev, end=*endif)
				continue
			endif
		endif
		rem --- End-of-firm

eof: rem --- If end-of-file or end-of-firm, rewind to first record of the firm
		read (are01_dev, key=start_key$, dom=*next)
		hit_eof=hit_eof+1
		if hit_eof>1 then
			msg_id$ = "AR_DEPOSIT_NO_RCPTS"
			gosub disp_message
			callpoint!.setStatus("ABORT-NEWREC")
			break
		endif
	wend
[[ARE_CASHHDR.BLST]]
rem --- Set flag that Last Record has been selected
	callpoint!.setDevObject("FirstLastRecord","LAST")
[[ARE_CASHHDR.BFST]]
rem --- Set flag that First Record has been selected
	callpoint!.setDevObject("FirstLastRecord","FIRST")
[[ARE_CASHHDR.AOPT-DPST]]
rem --- Launch Bank Deposit Entry form if using Bank Rec.
	if callpoint!.getDevObject("br_interface")="Y" then
		call stbl("+DIR_SYP")+"bam_run_prog.bbj", "ARE_DEPOSIT", stbl("+USER_ID"), "MNT", "", table_chans$[all]

		rem --- Start a new Cash Receipt record if the deposit_id has changed
		if callpoint!.getDevObject("deposit_id")<>callpoint!.getColumnData("ARE_CASHHDR.DEPOSIT_ID") then
			callpoint!.setStatus("NEWREC")
			break
		endif
	endif
[[ARE_CASHHDR.ASHO]]
rem --- Launch Bank Deposit Entry form if using Bank Rec.
	if callpoint!.getDevObject("br_interface")="Y" then
		call stbl("+DIR_SYP")+"bam_run_prog.bbj", "ARE_DEPOSIT", stbl("+USER_ID"), "MNT", "", table_chans$[all]

		rem --- DEPOSIT_ID is required, so terminate process if we don't have one.
		if callpoint!.getDevObject("deposit_id")="" and callpoint!.getColumnData("ARE_CASHHDR.DEPOSIT_ID")=""  then
			callpoint!.setStatus("EXIT")

			rem --- Remove software lock on batch, if batching
			batch$=stbl("+BATCH_NO",err=*next)
			if num(batch$)<>0
				lock_table$="ADM_PROCBATCHES"
				lock_record$=firm_id$+stbl("+PROCESS_ID")+batch$
				lock_type$="X"
				lock_status$=""
				lock_disp$=""
				call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$
			endif
			break
		endif
	endif
[[ARE_CASHHDR.AR_CHECK_NO.AVAL]]
rem --- temporary workaround to Barista bug not padding ar_check_no when nothing is entered for it
	dim are01a$:fnget_tpl$("ARE_CASHHDR")
	wk$=fattr(are01a$,"ar_check_no")
	ar_check_no$=pad(callpoint!.getUserInput(),dec(wk$(10,2)))
	callpoint!.setUserInput(ar_check_no$)
[[ARE_CASHHDR.ARAR]]
rem --- If First/Last Record was used, did it return a record for the current deposit?
	if callpoint!.getDevObject("FirstLastRecord")<>null() and callpoint!.getDevObject("FirstLastRecord")<>"" then
		whichRecord$=callpoint!.getDevObject("FirstLastRecord")
		callpoint!.setDevObject("FirstLastRecord","")

		deposit_id$=callpoint!.getDevObject("deposit_id")
		if callpoint!.getColumnData("ARE_CASHHDR.DEPOSIT_ID")<>deposit_id$ then
			are01_dev = fnget_dev("ARE_CASHHDR")
			dim are01a$:fnget_tpl$("ARE_CASHHDR")
			batch_no$=callpoint!.getColumnData("ARE_CASHHDR.BATCH_NO")
			ar_type$=callpoint!.getColumnData("ARE_CASHHDR.AR_TYPE")
			next_key$=""

			if whichRecord$="FIRST" then
				rem --- Locate FIRST valid record to display
				while 1
					read record (are01_dev, dir=0, end=*break) are01a$
					if are01a.firm_id$+are01a.batch_no$+are01a.ar_type$<>firm_id$+batch_no$+ar_type$ then break
					if are01a.deposit_id$=deposit_id$ then
						rem --- Have a keeper, stop looking
						next_key$=key(are01_dev)
						break
					else
						rem --- Keep looking
						read (are01_dev, end=*endif)
						continue
					endif
				wend
			endif

			if whichRecord$="LAST" then
				rem --- Locate LAST valid record to display
				while 1
					p_key$ = keyp(are01_dev, end=*break)
					read record (are01_dev, key=p_key$) are01a$
					if are01a.firm_id$+are01a.batch_no$+are01a.ar_type$<>firm_id$+batch_no$+ar_type$ then break
					if are01a.deposit_id$=deposit_id$ then
						rem --- Have a keeper, stop looking
						next_key$=p_key$
						break
					else
						rem --- Keep looking
						read (are01_dev, key=p_key$, dir=0)
						continue
					endif
				wend
			endif

			rem --- Display next record
			if next_key$<>"" then
				callpoint!.setStatus("RECORD:["+next_key$+"]")
				break
			else
				msg_id$ = "AR_DEPOSIT_NO_RCPTS"
				gosub disp_message
				callpoint!.setStatus("ABORT-NEWREC")
				break
			endif
		endif
	endif

rem --- Enable/disable controls based on Cash Receipt code
	wk_cash_cd$=callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD")
	gosub get_cash_rec_cd
	gosub able_controls
[[ARE_CASHHDR.AABO]]
rem --- User has elected to not save changes. 
rem --- For new records only, remove any are_cashgl recs already added (don't want orphans).

if callpoint!.getRecordMode()="A" then

	rem --- read thru are-21's just written (if any) and remove them
	rem --- alternative might be to set "no_out" flag and just give a warning, then  ABORT, but
	rem --- while BEND has an ABORT, BREX doesn't, so if user wasn't closing, but just moving on, ABORT won't be seen

	are_cashgl_dev=fnget_dev("ARE_CASHGL")
	dim are21a$:fnget_tpl$("ARE_CASHGL")

	key_pfx$=callpoint!.getColumnData("ARE_CASHHDR.FIRM_ID")+callpoint!.getColumnData("ARE_CASHHDR.AR_TYPE")+
:		callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_01")+callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")+
:		callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID")+callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD")+
:		callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")+callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_02")

	read(are_cashgl_dev,key=key_pfx$,dom=*next)
	while 1	
		ky$=key(are_cashgl_dev,end=*break)
		if pos(key_pfx$=ky$)<>1 then break
		remove (are_cashgl_dev,key=ky$)	
	wend
endif
[[ARE_CASHHDR.BEND]]
rem --- remove software lock on batch, if batching

	batch$=stbl("+BATCH_NO",err=*next)
	if num(batch$)<>0
		lock_table$="ADM_PROCBATCHES"
		lock_record$=firm_id$+stbl("+PROCESS_ID")+batch$
		lock_type$="X"
		lock_status$=""
		lock_disp$=""
		call stbl("+DIR_SYP")+"bac_lock_record.bbj",lock_table$,lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$
	endif

rem --- If using Bank Rec, check the Deposit’s TOT_DEPOSIT_AMT when ending a Deposit
	if callpoint!.getDevObject("br_interface")="Y" then
		deposit_id$=callpoint!.getDevObject("deposit_id")
		tot_deposit_amt=num(callpoint!.getDevObject("tot_deposit_amt"))
		tot_receipts_amt=num(callpoint!.getDevObject("tot_receipts_amt"))
		if tot_deposit_amt=0 then
			rem --- When TOT_DEPOSIT_AMT is zero, set it equal to the sum of the PAYMENT_AMTs, i.e., tot_receipts_amt
			gosub updateDepositAmt
		else
			rem --- Warn TOT_DEPOSIT_AMT it is not equal to the sum of the PAYMENT_AMTs, i.e., tot_receipts_amt
			if tot_deposit_amt<>tot_receipts_amt then
				call stbl("+DIR_PGM")+"adc_getmask.aon","","AR","A","",AmtMsk$,0,0
				msg_id$="AR_DEPOSIT_AMT_BAD"
				dim msg_tokens$[2]
				msg_tokens$[1]=cvs(str(tot_deposit_amt:AmtMsk$),3)
				msg_tokens$[2]=cvs(str(tot_receipts_amt:AmtMsk$),3)
				gosub disp_message
				if msg_opt$="C" then
					rem --- Change the deposit amount, set it equal to the sum of the PAYMENT_AMTs, i.e., tot_receipts_amt
					gosub updateDepositAmt
				endif
				if msg_opt$="E" then
					rem --- Edit the cash receipts for this Deposit
					callpoint!.setStatus("ABORT")
					break
				endif
				if msg_opt$="L" then
					rem --- Exit as-is
					rem --- Warn that Cash Receipt Register can't be updated
					msg_id$="AR_NO_UPDT_CSHRCPT"
					gosub disp_message
				endif
			endif
		endif
	endif
[[ARE_CASHHDR.BTBL]]
rem --- Get Batch information

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]
callpoint!.setTableColumnAttribute("ARE_CASHHDR.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[ARE_CASHHDR.PAYMENT_AMT.BINP]]
rem --- store value in control prior to input so we'll know at AVAL if it changed
user_tpl.binp_pay_amt=num(callpoint!.getColumnData("ARE_CASHHDR.PAYMENT_AMT"))
[[ARE_CASHHDR.ARNF]]
rem --- ARNF; record not found (i.e., entered date/customer/receipt cd/chk # for new tran)
ctl_stat$="D"
gosub disable_key_fields

commentMap!=new HashMap()
callpoint!.setDevObject("commentMap",commentMap!)
gosub get_open_invoices

if len(currdtl$)
	gosub include_new_OA_trans
endif
disp_applied=chk_applied-gl_applied
disp_bal=num(callpoint!.getColumnData("ARE_CASHHDR.PAYMENT_AMT"))-disp_applied
callpoint!.setColumnData("<<DISPLAY>>.DISP_APPLIED",str(disp_applied))
callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",str(disp_bal))
gosub fill_bottom_grid
callpoint!.setStatus("REFRESH-ABLEMAP")
[[ARE_CASHHDR.BWRI]]
gosub validate_before_writing
switch pos(validate_passed$="NO")
	case 1; rem validation didn't pass, user elected not to update
		callpoint!.setStatus("ABORT")
	break
	case 2; rem user elected to apply undistributed amt on account
		gosub apply_on_acct
		gosub get_open_invoices
	break
	case default
	break
swend
[[ARE_CASHHDR.BSHO]]
rem --- disable display fields
	dim dctl$[3]
 	dctl$[1]="<<DISPLAY>>.DISP_CUST_BAL"
	dctl$[2]="<<DISPLAY>>.DISP_BAL"
	dctl$[3]="<<DISPLAY>>.DISP_APPLIED"
	gosub disable_ctls

rem --- Disable Bank Rec. related controls
	if callpoint!.getDevObject("br_interface")<>"Y" then
		rem --- Disable New Deposit button if not using Bank Rec.
		callpoint!.setOptionEnabled("DPST",0)
	else
		rem --- Disable fields coming from Bank Rec deposit when using Bank Rec.
		callpoint!.setColumnEnabled("ARE_CASHHDR.CASH_REC_CD",-1)
	endif
[[ARE_CASHHDR.ACUS]]
data_present$="N"
gosub check_required_fields
if data_present$="Y"
	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ctl_ID=dec(gui_event.ID$)
	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
	endif
	switch ctl_id
		case num(user_tpl.OA_chkbox_id$)					
			gosub process_OA_chkbox
			callpoint!.setStatus("REFRESH")
		break
		case num(user_tpl.zbal_chkbox_id$)
			gosub process_zbal_chkbox
			callpoint!.setStatus("REFRESH")			
		break
		case num(user_tpl.asel_chkbox_id$)
			if num(callpoint!.getColumnData("ARE_CASHHDR.PAYMENT_AMT"))<0
				msg_id$="AR_NEG_CHK"
				gosub disp_message
				Form!.getControl(num(user_tpl.asel_chkbox_id$)).setSelected(0)
			else
				if user_tpl.existing_chk$="Y"
					msg_id$="AR_CHK_EXISTS"
					gosub disp_message
					Form!.getControl(num(user_tpl.asel_chkbox_id$)).setSelected(0)
				else
					on_off=dec(gui_event.flags$)
					gosub process_asel_chkbox
					callpoint!.setStatus("REFRESH")
				endif
			endif
		break
		case num(user_tpl.gridInvoice_id$)
			gridInvoice!=UserObj!.getItem(num(user_tpl.inv_grid$))                             
			if callpoint!.isEditMode() then
				gridInvoice!.setColumnEditable(0,1)
				gridInvoice!.setColumnEditable(8,1)
				gridInvoice!.setColumnEditable(9,1)
				gridInvoice!.setColumnEditable(11,1)
				if user_tpl.disc_flag$="Y" then
					gridInvoice!.setColumnEditable(num(user_tpl.disc_taken_ofst$),1)
				else
					gridInvoice!.setColumnEditable(num(user_tpl.disc_taken_ofst$),0)
				endif
			else
				gridInvoice!.setEditable(0)
			endif
			gosub process_gridInvoice_event
		break
	swend
endif
[[ARE_CASHHDR.ADEL]]
gosub delete_cashdet_cashbal

rem --- If using Bank Rec, adjust tot_receipts_amt when receipt is deleted
	if callpoint!.getDevObject("br_interface")="Y" then
		tot_receipts_amt=num(callpoint!.getDevObject("tot_receipts_amt"))
		tot_receipts_amt=tot_receipts_amt-num(callpoint!.getDevObject("saved_payment_amt"))
		callpoint!.setDevObject("tot_receipts_amt",tot_receipts_amt)
	endif
[[ARE_CASHHDR.ADIS]]
tmp_cust_id$=callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID")
gosub get_customer_balance
wk_cash_cd$=callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD")
gosub get_cash_rec_cd
gosub able_controls
Form!.getControl(num(user_tpl.asel_chkbox_id$)).setSelected(0);rem --- force auto-select off for existing tran
rem -- Form!.getControl(num(user_tpl.zbal_chkbox_id$)).setSelected(0);rem --- force zero-bal disp off for existing tran
are_cashdet_dev=fnget_dev("ARE_CASHDET")
are_cashgl_dev=fnget_dev("ARE_CASHGL")
dim are11a$:fnget_tpl$("ARE_CASHDET")
dim are21a$:fnget_tpl$("ARE_CASHGL")
existing_dtl$=""
pymt_dist$=""
user_tpl.gl_applied$="0"
user_tpl.existing_chk$="Y"

rem --- read thru/store existing are-11 info
more_dtl=1
commentMap!=new HashMap()
are01_key$=callpoint!.getColumnData("ARE_CASHHDR.FIRM_ID")+
:	callpoint!.getColumnData("ARE_CASHHDR.AR_TYPE")+
:	callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_01")+
:	callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")+
:	callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID")+
:	callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD")+
:	callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")+
:	callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_02")

read (are_cashdet_dev,key=are01_key$,dom=*next)
while more_dtl
	read record(are_cashdet_dev,end=*break)are11a$
	if pos(are01_key$=are11a$)<>1 then break
	dim wk$(40)
	wk$(1)=callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")
	wk$(11)=are11a.ar_inv_no$
	wk$(21)=are11a.apply_amt$
	wk$(31)=are11a.discount_amt$
	pymt_dist$=pymt_dist$+wk$
	existing_dtl$=existing_dtl$+wk$
	commentMap!.put(are11a.ar_inv_no$,are11a.memo_1024$)
wend
callpoint!.setDevObject("commentMap",commentMap!)

rem --- read thru existing are-21's and store total GL amt posted this check
more_dtl=1
read(are_cashgl_dev,key=are01_key$,dom=*next)
while more_dtl
	read record(are_cashgl_dev,end=*break)are21a$
	if pos(are01_key$=are21a$)<>1 then break
	gl_applied=gl_applied+num(are21a.gl_post_amt$)
wend

if gl_applied
	Form!.getControl(num(user_tpl.GLind_id$)).setText(Translate!.getTranslation("AON_*_INCLUDES_GL_DISTRIBUTIONS"))
	Form!.getControl(num(user_tpl.GLstar_id$)).setText("*")
else
	Form!.getControl(num(user_tpl.GLind_id$)).setText("")
	Form!.getControl(num(user_tpl.GLstar_id$)).setText("")
endif

user_tpl.gl_applied$=str(-gl_applied)
UserObj!.setItem(num(user_tpl.pymt_dist$),pymt_dist$)
UserObj!.setItem(num(user_tpl.existing_dtl$),existing_dtl$)
currdtl$=pymt_dist$
gosub get_open_invoices
if len(currdtl$)
	gosub include_new_OA_trans
endif
disp_applied=chk_applied-gl_applied
disp_bal=num(callpoint!.getColumnData("ARE_CASHHDR.PAYMENT_AMT"))-disp_applied
callpoint!.setColumnData("<<DISPLAY>>.DISP_APPLIED",str(disp_applied))
callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",str(disp_bal))
gosub fill_bottom_grid
callpoint!.setStatus("REFRESH")

rem --- Using Bank Rec?
if callpoint!.getDevObject("br_interface")="Y" then
	rem --- This receipt must be in the current deposit.
	deposit_id$=callpoint!.getDevObject("deposit_id")
	if callpoint!.getColumnData("ARE_CASHHDR.DEPOSIT_ID")<>deposit_id$ then
		msg_id$="AR_DEPOSIT_WRONG"
		dim msg_tokens$[2]
		msg_tokens$[1]=deposit_id$
		msg_tokens$[2]=callpoint!.getColumnData("ARE_CASHHDR.DEPOSIT_ID")
		gosub disp_message
		callpoint!.setStatus("NEWREC")
		break
	endif
	callpoint!.setColumnData("<<DISPLAY>>.DEPOSIT_DESC",str(callpoint!.getDevObject("deposit_desc")),1)

	rem --- Capture currently saved payment_amt so can adjust tot_receipts_amt if payment_amt is changed
	callpoint!.setDevObject("saved_payment_amt",num(callpoint!.getColumnData("ARE_CASHHDR.PAYMENT_AMT")))
endif
[[ARE_CASHHDR.AOPT-OACT]]
gosub apply_on_acct
[[ARE_CASHHDR.AOPT-GLED]]
rem --- call up GL Dist grid if GL installed
if user_tpl.glint$="Y"
	gosub gl_distribution
else
	msg_id$="AR_NO_GL"
	gosub disp_message							
endif
[[ARE_CASHHDR.AREC]]
rem --- clear custom controls (grids) and UserObj! items

gridInvoice!=UserObj!.getItem(num(user_tpl.inv_grid$))                             
gridInvoice!.clearMainGrid()				
gridInvoice!.setColumnStyle(0,SysGUI!.GRID_STYLE_UNCHECKED)				
gridInvoice!.setSelectedCell(0,0)
vectInvoice!=SysGUI!.makeVector()
vectInvSel!=SysGUI!.makeVector()
UserObj!.setItem(num(user_tpl.inv_vect$),vectInvoice!)				
UserObj!.setItem(num(user_tpl.inv_sel_vect$),vectInvSel!)
UserObj!.setItem(num(user_tpl.pymt_dist$),"")
UserObj!.setItem(num(user_tpl.existing_dtl$),"")
user_tpl.existing_chk$=""
user_tpl.gl_applied$="0"
user_tpl.binp_pay_amt=0

commentMap!=new HashMap()
callpoint!.setDevObject("commentMap",commentMap!)

Form!.getControl(num(user_tpl.GLind_id$)).setText("")
Form!.getControl(num(user_tpl.GLstar_id$)).setText("")

callpoint!.setColumnEnabled("ARE_CASHHDR.PAYMENT_AMT",0)

rem --- Initialize fields for Bank Rec deposit.
	if callpoint!.getDevObject("br_interface")="Y" then
		deposit_id$=callpoint!.getDevObject("deposit_id")
		callpoint!.setColumnData("ARE_CASHHDR.DEPOSIT_ID",deposit_id$,1)
		callpoint!.setColumnData("<<DISPLAY>>.DEPOSIT_DESC",str(callpoint!.getDevObject("deposit_desc")),1)

		wk_cash_cd$=callpoint!.getDevObject("cash_rec_cd")
		callpoint!.setColumnData("ARE_CASHHDR.CASH_REC_CD",wk_cash_cd$,1)
		callpoint!.setColumnEnabled("ARE_CASHHDR.CASH_REC_CD",-1)
		gosub get_cash_rec_cd
		gosub able_controls

		rem --- Capture currently saved payment_amt so can adjust tot_receipts_amt if payment_amt is changed
		callpoint!.setDevObject("saved_payment_amt",0)
	else
		callpoint!.setDevObject("deposit_id",callpoint!.getColumnData("ARE_CASHHDR.DEPOSIT_ID"))
	endif
[[ARE_CASHHDR.ASIZ]]
if UserObj!<>null()
	gridInvoice!=UserObj!.getItem(num(user_tpl.inv_grid$))
	gridInvoice!.setSize(Form!.getWidth()-(gridInvoice!.getX()*2),Form!.getHeight()-(gridInvoice!.getY()+40))
	gridInvoice!.setFitToGrid(1)
	gridInvoice!.setColumnWidth(0,25)
endif
[[ARE_CASHHDR.AWIN]]
use ::ado_util.src::util
use java.util.HashMap

rem --- Open/Lock files
files=30,begfile=1,endfile=10
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="ARE_CASHHDR";rem --- "are-01"
files$[2]="ARE_CASHDET";rem --- "are-11"
files$[3]="ARE_CASHGL";rem --- "are-21"
files$[4]="ARE_CASHBAL";rem --- "are-31"
files$[5]="ART_INVHDR";rem --- "art-01"
files$[6]="ART_INVDET";rem --- "art-11"
files$[7]="ARM_CUSTMAST";rem --- "arm-01"
files$[8]="ARM_CUSTDET";rem --- "arm-02
files$[9]="ARC_CASHCODE";rem --- "arm-10C"
files$[10]="ARS_PARAMS";rem --- "ars-01"
for wkx=begfile to endfile
	options$[wkx]="OTA"
next wkx
call dir_pgm$+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                   chans$[all],templates$[all],table_chans$[all],batch,status$
if status$<>"" then
	remove_process_bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif
ars01_dev=num(chans$[10])

rem --- Dimension miscellaneous string templates
dim ars01a$:templates$[10]
user_tpl_str$="firm_id:c(2),glint:c(1),glyr:c(4),glper:c(2),glworkfile:c(16),"
user_tpl_str$=user_tpl_str$+"cash_flag:c(1),disc_flag:c(1),arglboth:c(1),amt_msk:c(15),existing_chk:c(1),"
user_tpl_str$=user_tpl_str$+"OA_chkbox_id:c(5),zbal_chkbox_id:c(5),asel_chkbox_id:c(5),"
user_tpl_str$=user_tpl_str$+"gridCheck_id:c(5),gridInvoice_id:c(5),gridCheck_cols:c(5),gridInvoice_cols:c(5),"
user_tpl_str$=user_tpl_str$+"gridCheck_rows:c(5),gridInvoice_rows:c(5),"
user_tpl_str$=user_tpl_str$+"chk_grid:c(5),inv_grid:c(5),chk_vect:c(5),inv_vect:c(5),chk_sel_vect:c(5),"
user_tpl_str$=user_tpl_str$+"inv_sel_vect:c(5),cur_bal_ofst:c(5),avail_disc_ofst:c(5),"
user_tpl_str$=user_tpl_str$+"applied_amt_ofst:c(5),disc_taken_ofst:c(5),new_bal_ofst:c(5),cmt_ofst:c(5),pymt_dist:c(5),"
user_tpl_str$=user_tpl_str$+"existing_dtl:c(5),GLind_id:c(5),GLstar_id:c(5),gl_applied:c(10),binp_pay_amt:n(15)"
dim user_tpl$:user_tpl_str$
user_tpl.firm_id$=firm_id$

rem --- Retrieve parameter data
ars01a_key$=firm_id$+"AR00"
find record (ars01_dev,key=ars01a_key$,err=std_missing_params) ars01a$
callpoint!.setDevObject("br_interface",ars01a.br_interface$)
call stbl("+DIR_PGM")+"adc_getmask.aon","","AR","A",imsk$,omsk$,ilen,olen
user_tpl.amt_msk$=imsk$

rem --- Additional File Opens
gl$="N"
status=0
source$=pgm(-2)
call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"AR",glw11$,gl$,status
if status<>0 goto std_exit
user_tpl.glint$=gl$
user_tpl.glworkfile$=glw11$
if gl$="Y"
	files=21,begfile=20,endfile=21
	dim files$[files],options$[files],chans$[files],templates$[files]
	files$[20]="GLM_ACCT",options$[20]="OTA";rem --- "glm-01"
	files$[21]=glw11$,options$[21]="OTAS";rem --- s means no err if tmplt not found
	rem --- will need alias name, not disk name, when opening work file
	rem --- will also need option to lock/clear file [21]; not using in this pgm for now, so bypassing.CAH
	call dir_pgm$+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:	                  chans$[all],templates$[all],table_chans$[all],batch,status$
	if status$<>"" then
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif
endif

if ars01a.br_interface$="Y" then
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARE_DEPOSIT",open_opts$[1]="OTA[1]"

	gosub open_tables
	if status$ <> ""  then goto std_exit
endif

rem --- add custom controls, checkboxes and grids
UserObj!=SysGUI!.makeVector()
nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))

base_ctl!=callpoint!.getControl("<<DISPLAY>>.DISP_CUST_BAL")
base_x=base_ctl!.getX()
tmp_x=base_x+base_ctl!.getWidth()+95
tmp_y=base_ctl!.getY()+55
tmp_h=base_ctl!.getHeight()
tmp_w=200

applied_ctl!=callpoint!.getControl("<<DISPLAY>>.DISP_APPLIED")
app_x=applied_ctl!.getX()
app_y=applied_ctl!.getY()
app_w=applied_ctl!.getWidth()
app_h=applied_ctl!.getHeight()

rem --- position the three checkboxes relative to the Customer Balance control
OA_chkbox!=Form!.addCheckBox(nxt_ctlID,tmp_x,tmp_y,tmp_w,tmp_h,Translate!.getTranslation("AON_SHOW_ON-ACCOUNT_AND_CREDITS?"),$04$)
zbal_chkbox!=Form!.addCheckBox(nxt_ctlID+1,tmp_x,tmp_y+tmp_h+1,tmp_w,tmp_h,Translate!.getTranslation("AON_SHOW_ZERO-BALANCE_INVOICES?"),$$)
asel_chkbox!=Form!.addCheckBox(nxt_ctlID+2,tmp_x,tmp_y+(tmp_h+1)*2,tmp_w,tmp_h,Translate!.getTranslation("AON_AUTO-SELECT_BY_INVOICE?"),$$)

gridInvoice!=Form!.addGrid(nxt_ctlID+3,5,220,700,210)

rem --- position the static text (to show when there is a GL dist included) relative to the Applied Amt control
Form!.addStaticText(nxt_ctlID+4,app_x,195,tmp_w,tmp_h,"")
Form!.addStaticText(nxt_ctlID+5,app_x+app_w+10,175,20,tmp_h,"")

rem --- store ctl ID's of custom controls #3				
user_tpl.OA_chkbox_id$=str(nxt_ctlID)
user_tpl.zbal_chkbox_id$=str(nxt_ctlID+1)
user_tpl.asel_chkbox_id$=str(nxt_ctlID+2)				
user_tpl.gridInvoice_id$=str(nxt_ctlID+3)
user_tpl.GLind_id$=str(nxt_ctlID+4)
user_tpl.GLstar_id$=str(nxt_ctlID+5)

rem --- Reset window size
util.resizeWindow(Form!, SysGui!)

rem --- set user-friendly names for controls' positions in UserObj vector, num grid cols, data pos w/in vector, etc.				
user_tpl.gridInvoice_cols$="12"				
user_tpl.inv_grid$="0"				
user_tpl.inv_vect$="1"				
user_tpl.inv_sel_vect$="2"
user_tpl.cur_bal_ofst$="5"
user_tpl.avail_disc_ofst$="6"
user_tpl.applied_amt_ofst$="8"
user_tpl.disc_taken_ofst$="9"
user_tpl.new_bal_ofst$="10"
user_tpl.cmt_ofst$="11"
user_tpl.pymt_dist$="3"
user_tpl.existing_dtl$="4"
gosub format_grids

rem --- store grid, vectors, and existing/newly posted detail strings in UserObj!				
UserObj!.addItem(gridInvoice!)				
UserObj!.addItem(SysGUI!.makeVector());rem --- vector for open (and maybe closed) invoices				
UserObj!.addItem(SysGUI!.makeVector());rem --- vector for open invoice grid's checkbox values
UserObj!.addItem("");rem --- string for pymt_dist$, containing chk#/inv#/pd/disc, 10 char ea
UserObj!.addItem("");rem --- string for existing_dtl$;same format as pymt_dist$,but corres to existing are-11's

rem --- set callbacks - processed in ACUS callpoint
gridInvoice!.setCallback(gridInvoice!.ON_GRID_EDIT_START,"custom_event")
gridInvoice!.setCallback(gridInvoice!.ON_GRID_EDIT_STOP,"custom_event")
gridInvoice!.setCallback(gridInvoice!.ON_GRID_KEY_PRESS,"custom_event")
gridInvoice!.setCallback(gridInvoice!.ON_GRID_MOUSE_UP,"custom_event")
OA_chkbox!.setCallback(OA_chkbox!.ON_CHECK_OFF,"custom_event")
OA_chkbox!.setCallback(OA_chkbox!.ON_CHECK_ON,"custom_event")
zbal_chkbox!.setCallback(zbal_chkbox!.ON_CHECK_OFF,"custom_event")
zbal_chkbox!.setCallback(zbal_chkbox!.ON_CHECK_ON,"custom_event")	
asel_chkbox!.setCallback(asel_chkbox!.ON_CHECK_OFF,"custom_event")
asel_chkbox!.setCallback(asel_chkbox!.ON_CHECK_ON,"custom_event")

rem --- misc other init
gridInvoice!.setColumnEditable(0,1)
gridInvoice!.setColumnEditable(8,1)
gridInvoice!.setColumnEditable(9,1)
gridInvoice!.setColumnEditable(11,1)
gridInvoice!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)
gridInvoice!.setTabActionSkipsNonEditableCells(1)
[[ARE_CASHHDR.AWRI]]
gosub update_cashhdr_cashdet_cashbal

rem ---  When using Bank Rec, sum up tot_receipts_amt for current Deposit
	if callpoint!.getDevObject("br_interface")="Y" then
		rem --- Adjust tot_receipts_amt for changes in payment_amt
		gosub adjustTotReceiptsAmt
	endif
[[ARE_CASHHDR.CASH_CHECK.AVAL]]
if callpoint!.getUserInput()="$"
	ctl_name$="ABA_NO"
	ctl_stat$="D"
	gosub disable_fields
	
else
	ctl_name$="ABA_NO"
	ctl_stat$=" "
	gosub disable_fields
endif
callpoint!.setStatus("REFRESH-ABLEMAP-ACTIVATE")
[[ARE_CASHHDR.CASH_REC_CD.AVAL]]
rem --- Enable/disable controls based on Cash Receipt code
	wk_cash_cd$=callpoint!.getUserInput()
	gosub get_cash_rec_cd
	gosub able_controls
[[ARE_CASHHDR.CUSTOMER_ID.AVAL]]
tmp_cust_id$=callpoint!.getUserInput()
rem "Customer Inactive Feature"
arm01_dev=fnget_dev("ARM_CUSTMAST")
arm01_tpl$=fnget_tpl$("ARM_CUSTMAST")
dim arm01a$:arm01_tpl$
arm01a_key$=firm_id$+tmp_cust_id$
find record (arm01_dev,key=arm01a_key$,err=*break) arm01a$
if arm01a.cust_inactive$="Y" then
   call stbl("+DIR_PGM")+"adc_getmask.aon","CUSTOMER_ID","","","",m0$,0,customer_size
   msg_id$="AR_CUST_INACTIVE"
   dim msg_tokens$[2]
   msg_tokens$[1]=fnmask$(arm01a.customer_id$(1,customer_size),m0$)
   msg_tokens$[2]=cvs(arm01a.customer_name$,2)
   gosub disp_message
   callpoint!.setStatus("ACTIVATE-ABORT")
   goto std_exit
endif

gosub get_customer_balance
callpoint!.setStatus("REFRESH")
[[ARE_CASHHDR.PAYMENT_AMT.AVAL]]
rem --- after check amt entered, alter remaining balance and re-do autopay, if turned on
pymt_dist$=UserObj!.getItem(num(user_tpl.pymt_dist$))
old_pay=user_tpl.binp_pay_amt
new_pay=num(callpoint!.getUserInput())
if old_pay<>new_pay
	pay_id$=callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")
	callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",
:		str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))-old_pay+new_pay))
	if Form!.getControl(num(user_tpl.asel_chkbox_id$)).isSelected()
		to_pay=new_pay-old_pay
		gosub auto_select_on
	endif								
	callpoint!.setStatus("REFRESH")
	user_tpl.binp_pay_amt=new_pay
endif
[[ARE_CASHHDR.RECEIPT_DATE.AVAL]]
if len(callpoint!.getUserInput())<6 or pos("9"<>callpoint!.getUserInput())=0 then callpoint!.setUserInput(stbl("+SYSTEM_DATE"))
gl$=user_tpl.glint$
recpt_date$=callpoint!.getUserInput()        
if gl$="Y" 
	call stbl("+DIR_PGM")+"glc_datecheck.aon",recpt_date$,"Y",per$,yr$,status
	if status>99
		callpoint!.setStatus("ABORT")
	else
		user_tpl.glyr$=yr$
		user_tpl.glper$=per$
	endif
endif
[[ARE_CASHHDR.<CUSTOM>]]
#include std_functions.src
rem ==================================================================
disable_key_fields:
rem ==================================================================
	rem --- used after entering check amount to disable key fields, or on new rec to re-enable them, depending on ctl_stat$
	dim key_fields$[3]
	key_fields$[0]="RECEIPT_DATE"
	key_fields$[1]="CUSTOMER_ID"
	key_fields$[2]="CASH_REC_CD"
	key_fields$[3]="AR_CHECK_NO"
	for wk=0 to 3
		ctl_name$=key_fields$[wk]
		gosub disable_fields
	next wk
return

rem ==================================================================
disable_fields:
rem ==================================================================
	rem --- used to disable/enable controls
	rem --- ctl_name$ sent in with name of control to enable/disable (format "ALIAS.CONTROL_NAME")
	rem --- ctl_stat$ sent in as D (or I) or space, meaning disable/enable, respectively
	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
return

rem ==================================================================
get_cash_rec_cd:
rem ==================================================================
	arm10_dev=fnget_dev("ARC_CASHCODE")
	dim arm10c$:fnget_tpl$("ARC_CASHCODE")
	read record(arm10_dev,key=firm_id$+"C"+wk_cash_cd$,dom=*next)arm10c$
	user_tpl.cash_flag$=arm10c.cash_flag$
	user_tpl.disc_flag$=arm10c.disc_flag$
	user_tpl.arglboth$=arm10c.arglboth$
	gridInvoice!=userObj!.getItem(num(user_tpl.inv_grid$))
	if arm10c.disc_flag$="Y"
		gridInvoice!.setColumnEditable(num(user_tpl.disc_taken_ofst$),1)
	else
		gridInvoice!.setColumnEditable(num(user_tpl.disc_taken_ofst$),0)
	endif
return

rem ==================================================================
 able_controls: rem --- Enable/disable controls based on Cash Receipt code
rem ==================================================================
	if user_tpl.cash_flag$="Y" then
		callpoint!.setColumnEnabled("ARE_CASHHDR.PAYMENT_AMT",1)
	else
		callpoint!.setColumnEnabled("ARE_CASHHDR.PAYMENT_AMT",0)
	endif

	gridInvoice!=UserObj!.getItem(num(user_tpl.inv_grid$))
	OA_chkbox!=Form!.getControl(num(user_tpl.OA_chkbox_id$))
	zbal_chkbox!=Form!.getControl(num(user_tpl.zbal_chkbox_id$))
	asel_chkbox!=Form!.getControl(num(user_tpl.asel_chkbox_id$))
	switch (BBjAPI().TRUE)
		case user_tpl.arglboth$="A"
			rem --- Post to AR only
			callpoint!.setOptionEnabled("GLED",0)
			callpoint!.setOptionEnabled("OACT",1)
			gridInvoice!.setEnabled(1)
			OA_chkbox!.setEditable(1)
			zbal_chkbox!.setEditable(1)
			asel_chkbox!.setEditable(1)
			break
		case user_tpl.arglboth$="G"
			rem --- Post to GL only
			callpoint!.setOptionEnabled("GLED",1)
			callpoint!.setOptionEnabled("OACT",0)
			gridInvoice!.clearMainGrid()				
			gridInvoice!.setColumnStyle(0,SysGUI!.GRID_STYLE_UNCHECKED)				
			gridInvoice!.setSelectedCell(0,0)
			gridInvoice!.setEnabled(0)
			OA_chkbox!.setSelected(0)
			OA_chkbox!.setEditable(0)
			zbal_chkbox!.setSelected(0)
			zbal_chkbox!.setEditable(0)
			asel_chkbox!.setSelected(0)
			asel_chkbox!.setEditable(0)
			break
		case default
			rem --- Post to both AR and GL
			callpoint!.setOptionEnabled("GLED",1)
			callpoint!.setOptionEnabled("OACT",1)
			gridInvoice!.setEnabled(1)
			OA_chkbox!.setEditable(1)
			zbal_chkbox!.setEditable(1)
			asel_chkbox!.setEditable(1)
			break
	swend

	callpoint!.setStatus("REFRESH")
return

rem ==================================================================
get_customer_balance:
rem ==================================================================
	rem --- tmp_cust_id$ being set prior to gosub
	arm_custdet_dev=fnget_dev("ARM_CUSTDET")
	dim arm02a$:fnget_tpl$("ARM_CUSTDET")
	arm02a.firm_id$=firm_id$,arm02a.customer_id$=tmp_cust_id$,arm02a.ar_type$="  "
	readrecord(arm_custdet_dev,key=arm02a.firm_id$+arm02a.customer_id$+arm02a.ar_type$,err=*next)arm02a$
	callpoint!.setColumnData("<<DISPLAY>>.DISP_CUST_BAL",
:		str(num(arm02a.aging_future$)+num(arm02a.aging_cur$)+num(arm02a.aging_30$)+
:       num(arm02a.aging_60$)+num(arm02a.aging_90$)+num(arm02a.aging_120$)))
return

rem ==================================================================
check_required_fields:
rem ==================================================================
	if cvs(callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE"),3)="" or 
:		cvs(callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID"),3)="" or
:		cvs(callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD"),3)="" 
		if data_present$="NO-MSG"
			msg_id$="AR_REQ_DATA"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	else
		data_present$="Y"
	endif
return

rem ==================================================================
update_cashhdr_cashdet_cashbal:

rem --- gosub'd from AWRI or AOPT-OACT only - this is where actual writes to disk are done
rem --- don't gosub this routine from anywhere else unless you're prepared to write code to also undo the writes
rem ==================================================================

	are_cashhdr_dev=fnget_dev("ARE_CASHHDR")
	are_cashdet_dev=fnget_dev("ARE_CASHDET")
	are_cashbal_dev=fnget_dev("ARE_CASHBAL")
	are_cashgl_dev=fnget_dev("ARE_CASHGL")
	pymt_dist$=UserObj!.getItem(num(user_tpl.pymt_dist$))
	if cvs(pymt_dist$,3)<>""
	for updt_loop=1 to len(pymt_dist$) step 40
		dim are01a$:fnget_tpl$("ARE_CASHHDR")
		dim are11a$:fnget_tpl$("ARE_CASHDET")
		dim are31a$:fnget_tpl$("ARE_CASHBAL")
		dim are21a$:fnget_tpl$("ARE_CASHGL")
		are01a.firm_id$=firm_id$,are11a.firm_id$=firm_id$,are31a.firm_id$=firm_id$,are21a.firm_id$=firm_id$
		are01a.batch_no$=callpoint!.getColumnData("ARE_CASHHDR.BATCH_NO")
		are01a.ar_type$=callpoint!.getColumnData("ARE_CASHHDR.AR_TYPE")
		are01a.reserved_key_01$=callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_01")
		are01a.receipt_date$=callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")
		are11a.receipt_date$=are01a.receipt_date$
		are21a.receipt_date$=are01a.receipt_date$
		are01a.customer_id$=callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID")
		are11a.customer_id$=are01a.customer_id$
		are31a.customer_id$=are01a.customer_id$
		are21a.customer_id$=are01a.customer_id$
		are01a.cash_rec_cd$=callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD")
		are11a.cash_rec_cd$=are01a.cash_rec_cd$
		are21a.cash_rec_cd$=are01a.cash_rec_cd$
		are01a.ar_check_no$=callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")
		are11a.ar_check_no$=are01a.ar_check_no$
		are21a.ar_check_no$=are01a.ar_check_no$
		are01a.reserved_key_02$=callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_02")	
		are11a.ar_inv_no$=cvs(pymt_dist$(updt_loop+10,10),3)
		are31a.ar_inv_no$=are11a.ar_inv_no$
		old_pay=0,old_disc=0
rem --- cashhdr, are-01
		are01_key$=are01a.firm_id$+are01a.batch_no$+are01a.ar_type$+are01a.reserved_key_01$+are01a.receipt_date$+
:			are01a.customer_id$+are01a.cash_rec_cd$+are11a.ar_check_no$+are01a.reserved_key_02$
		extractrecord(are_cashhdr_dev,key=are01_key$,dom=*next)are01a$;rem Advisory Locking
		are01a.payment_amt$=callpoint!.getColumnData("ARE_CASHHDR.PAYMENT_AMT")
		are01a.cash_check$=callpoint!.getColumnData("ARE_CASHHDR.CASH_CHECK")
		are01a.aba_no$=callpoint!.getColumnData("ARE_CASHHDR.ABA_NO")
		rem --- Update deposit info if using Bank Rec
		if callpoint!.getDevObject("br_interface")="Y" then
			are01a.deposit_id$=callpoint!.getDevObject("deposit_id")
			rem --- Adjust tot_receipts_amt for changes in payment_amt
			gosub adjustTotReceiptsAmt
		endif
		are01a$=field(are01a$)
		writerecord(are_cashhdr_dev)are01a$
		extractrecord(are_cashhdr_dev,key=are01_key$)are01a$;rem Advisory Locking
		apply_amt=num(pymt_dist$(updt_loop+20,10))
		disc_amt=num(pymt_dist$(updt_loop+30,10))
rem --- cashdet, are-11
		extractrecord(are_cashdet_dev,key=are11a.firm_id$+are11a.ar_type$+are11a.reserved_key_01$+are11a.receipt_date$+
:			are11a.customer_id$+are11a.cash_rec_cd$+are11a.ar_check_no$+are11a.reserved_key_02$+are11a.ar_inv_no$,dom=*next)are11a$;rem Advisory Locking
		if num(are11a.apply_amt)<>0 or num(are11a.discount_amt$)<>0
			old_pay=num(are11a.apply_amt$)
			old_disc=num(are11a.discount_amt$)
		endif
		are11a.apply_amt$=str(apply_amt)
		are11a.discount_amt$=str(disc_amt)
		if apply_amt<>0 or disc_amt<>0 then
			are11a.batch_no$=stbl("+BATCH_NO")
			are11a$=field(are11a$)
			writerecord(are_cashdet_dev)are11a$
		else
			remove(are_cashdet_dev,key=are11a.firm_id$+are11a.ar_type$+are11a.reserved_key_01$+are11a.receipt_date$+
:				are11a.customer_id$+are11a.cash_rec_cd$+are11a.ar_check_no$+are11a.reserved_key_02$+are11a.ar_inv_no$,dom=*next)
		endif
rem --- cashbal, are-31
		extractrecord(are_cashbal_dev,key=are31a.firm_id$+are31a.ar_type$+are31a.reserved_str$+are31a.customer_id$+
:			are31a.ar_inv_no$,dom=*next)are31a$;rem Advisory Locking
		are31a.apply_amt$=str(num(are31a.apply_amt)-old_pay+num(are11a.apply_amt$))
		are31a.discount_amt$=str(num(are31a.discount_amt$)-old_disc+num(are11a.discount_amt$))
		if num(are31a.apply_amt$)<>0 or num(are31a.discount_amt$)<>0
			are31a$=field(are31a$)
			writerecord(are_cashbal_dev)are31a$
		else
			remove(are_cashbal_dev,key=are31a.firm_id$+are31a.ar_type$+are31a.reserved_str$+are31a.customer_id$+
:				are31a.ar_inv_no$,dom=*next)
		endif
	next updt_loop
	endif

	rem --- Save chanded detail comments
	vectInvoice!=UserObj!.getItem(num(user_tpl.inv_vect$))
	if vectInvoice!.size() then
		dim are11a$:fnget_tpl$("ARE_CASHDET")
		cols=num(user_tpl.gridInvoice_cols$)
		for voffset=0 to vectInvoice!.size()-1 step cols
			redim are11a$
			are11a.firm_id$=firm_id$
			are11a.ar_type$=callpoint!.getColumnData("ARE_CASHHDR.AR_TYPE")
			are11a.reserved_key_01$=callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_01")
			are11a.receipt_date$=callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")
			are11a.customer_id$=callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID")
			are11a.cash_rec_cd$=callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD")
			are11a.ar_check_no$=callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")
			are11a.reserved_key_02$=callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_02")
			are11a.ar_inv_no$=vectInvoice!.getItem(voffset+1)
			extractrecord(are_cashdet_dev,key=are11a.firm_id$+are11a.ar_type$+are11a.reserved_key_01$+are11a.receipt_date$+
:			are11a.customer_id$+are11a.cash_rec_cd$+are11a.ar_check_no$+are11a.reserved_key_02$+are11a.ar_inv_no$,dom=*next)are11a$;rem Advisory Locking
			if are11a.memo_1024$<>vectInvoice!.getItem(voffset+num(user_tpl.cmt_ofst$)) then
				are11a.memo_1024$=vectInvoice!.getItem(voffset+num(user_tpl.cmt_ofst$))
				are11a$=field(are11a$)
				writerecord(are_cashdet_dev)are11a$
			else
				read(are_cashdet_dev,end=*next)
			endif
		next voffset
	endif

	callpoint!.setStatus("NEWREC"); rem sets up for new record
return

rem ==================================================================
validate_before_writing:
rem ==================================================================
	validate_passed$="Y"
	if num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))<>0
		msg_id$="AR_NOT_DIST"
		gosub disp_message
		validate_passed$=msg_opt$
	endif
	rem	gosub check_for_neg_invoices; rem --- not sure I care about this routine?
return

rem ==================================================================
check_for_neg_invoices:
rem ==================================================================
	vectInvoice!=UserObj!.getItem(num(user_tpl.inv_vect$))
	cols=num(user_tpl.gridInvoice_cols$)
	if vectInvoice!.size()
		neg_bal=0
		for check_loop=0 to vectInvoice!.size()-1 step cols
			if num(vectInvoice!.getItem(check_loop+num(user_tpl.new_bal_ofst$)))<0
				neg_bal=neg_bal+1
			endif
		next check_loop
		if neg_bal<>0
			msg_id$="AR_NEG_BAL"
			gosub disp_message
			if msg_opt$="N"
				validate_passed$="N"
			endif
		endif
	endif
return

rem ==================================================================
apply_on_acct:
rem ==================================================================
	oa_date$=callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")
	oa_date$=oa_date$(4)
	dim wk$(40)
	wk$(1)=callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")
	wk$(11)="OA"+oa_date$
	wk$(21)=str(num((callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))))

	if num(wk$(21,10))<>0
		pymt_dist$=UserObj!.getItem(num(user_tpl.pymt_dist$))
		wk=pos(wk$(1,20)=pymt_dist$)
			if wk<>0
				pymt_dist$(wk+20,10)=str(num(pymt_dist$(wk+20,10))+num(wk$(21,10)))
				pymt_dist$(wk+30,10)=str(num(pymt_dist$(wk+30,10))+num(wk$(31,10)))
			else
				pymt_dist$=pymt_dist$+wk$
			endif
		UserObj!.setItem(num(user_tpl.pymt_dist$),pymt_dist$)
		gosub update_cashhdr_cashdet_cashbal
	
		callpoint!.setStatus("RECORD:["+firm_id$+
:			callpoint!.getColumnData("ARE_CASHHDR.BATCH_NO")+
:			callpoint!.getColumnData("ARE_CASHHDR.AR_TYPE")+
:			callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_01")+
:			callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")+
:			callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID")+
:			callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD")+
:			callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")+
:			callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_02")+"]")
	endif
return

rem ==================================================================
delete_cashdet_cashbal:
rem ==================================================================
rem --- letting Barista delete are-21 based on delete cascade in form
rem --- can't let Barista just delete are-11 and 31, 
rem ---  because 31 may or may not be deleted, based on it's bal after deleting are-11's...
rem ---  so delete are-11 and 31 manually here.
	are_cashdet_dev=fnget_dev("ARE_CASHDET")
	are_cashbal_dev=fnget_dev("ARE_CASHBAL")	
	dim are11a$:fnget_tpl$("ARE_CASHDET")
	dim are31a$:fnget_tpl$("ARE_CASHBAL")	
	are11a.firm_id$=firm_id$,are31a.firm_id$=firm_id$
	are11a.receipt_date$=callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")
	are11a.customer_id$=callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID"),are31a.customer_id$=are11a.customer_id$
	are11a.cash_rec_cd$=callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD")
	are11a.ar_check_no$=callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")		
	read(are_cashdet_dev,key=are11a.firm_id$+are11a.ar_type$+are11a.reserved_key_01$+are11a.receipt_date$+are11a.customer_id$+
:		are11a.cash_rec_cd$+are11a.ar_check_no$+are11a.reserved_key_02$,dom=*next)
	more_dtl=1
	while more_dtl
		rem --- cashdet, are-11
		readrecord(are_cashdet_dev,end=*break)are11a$
		if are11a.firm_id$=firm_id$ and are11a.receipt_date$=callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE") and
:										are11a.customer_id$=callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID") and 
:										are11a.cash_rec_cd$=callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD") and
:										are11a.ar_check_no$=callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")
			del_pay=num(are11a.apply_amt$)
			del_disc=num(are11a.discount_amt$)
			are31a.ar_inv_no$=are11a.ar_inv_no$
			remove(are_cashdet_dev,key=are11a.firm_id$+are11a.ar_type$+are11a.reserved_key_01$+are11a.receipt_date$+
:				are11a.customer_id$+are11a.cash_rec_cd$+are11a.ar_check_no$+are11a.reserved_key_02$+are11a.ar_inv_no$)
		
			rem --- cashbal, are-31
			extractrecord(are_cashbal_dev,key=are31a.firm_id$+are31a.ar_type$+are31a.reserved_str$+are31a.customer_id$+
:				are31a.ar_inv_no$,dom=*next)are31a$;rem Advisory Locking
			are31a.apply_amt$=str(num(are31a.apply_amt)-del_pay)
			are31a.discount_amt$=str(num(are31a.discount_amt$)-del_disc)
			if num(are31a.apply_amt$)<>0 or num(are31a.discount_amt$)<>0
				are31a$=field(are31a$)
				writerecord(are_cashbal_dev)are31a$
			else
				remove(are_cashbal_dev,key=are31a.firm_id$+are31a.ar_type$+are31a.reserved_str$+are31a.customer_id$+
:					are31a.ar_inv_no$,dom=*next)
			endif
		else
			more_dtl=0
		endif
	wend
	gridInvoice!=UserObj!.getItem(num(user_tpl.inv_grid$))
	gridInvoice!.clearMainGrid()
return

rem ==================================================================
gl_distribution:
rem ==================================================================
	user_id$=stbl("+USER_ID")
	dim dflt_data$[1,1]
	callpoint!.setDevObject("dflt_gl_amt",str(-num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))))
	key_pfx$=callpoint!.getColumnData("ARE_CASHHDR.FIRM_ID")+callpoint!.getColumnData("ARE_CASHHDR.AR_TYPE")+
:				callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_01")+callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")+
:				callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID")+callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD")+
:				callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")+callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_02")
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"ARE_CASHGL",
:		user_id$,
:		"MNT",
:		key_pfx$,
:		table_chans$[all],
:		"",
:		dflt_data$[all]
	rem --- read thru are-21's just written/updated (if any) to update applied and bal amts
	are_cashgl_dev=fnget_dev("ARE_CASHGL")
	dim are21a$:fnget_tpl$("ARE_CASHGL")
	gl_applied=0
	more_dtl=1
	read(are_cashgl_dev,key=key_pfx$,dom=*next)
	while more_dtl
		read record(are_cashgl_dev,end=*break)are21a$
		if are21a$(1,len(key_pfx$))=key_pfx$
			gl_applied=gl_applied+num(are21a.gl_post_amt$)
		else
			more_dtl=0
		endif
	wend

	glapp=num(user_tpl.gl_applied$)+gl_applied
	user_tpl.gl_applied$=str(-gl_applied);rem added 5/16/07.ch
	callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))+glapp))
	callpoint!.setColumnData("<<DISPLAY>>.DISP_APPLIED",str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_APPLIED"))-glapp))
	if gl_applied
		Form!.getControl(num(user_tpl.GLind_id$)).setText(Translate!.getTranslation("AON_*_INCLUDES_GL_DISTRIBUTIONS"))
		Form!.getControl(num(user_tpl.GLstar_id$)).setText("*")
	else
		Form!.getControl(num(user_tpl.GLind_id$)).setText("")
		Form!.getControl(num(user_tpl.GLstar_id$)).setText("")
	endif	
	callpoint!.setStatus("REFRESH")
return

rem ==================================================================
delete_cashgl:
rem ==================================================================
rem --- intended to use if oper cancels out after having already done GL dist in separate grid/process, so need to be able to remove them
rem --- waiting for BCAN event in Barista
rem --- monitor gl dist remove
	are_cashgl_dev=fnget_dev("ARE_CASHGL")
	dim are21a$:fnget_tpl$("ARE_CASHGL")
	are21a.firm_id$=firm_id$
	are21a.receipt_date$=callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")
	are21a.customer_id$=callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID")
	are21a.cash_rec_cd$=callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD")
	are21a.ar_check_no$=callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")	
	read(are_cashgl_dev,key=are21a.firm_id$+are21a.ar_type$+are21a.reserved_key_01$+are21a.receipt_date$+are21a.customer_id$+
:		are21a.cash_rec_cd$+are21a.ar_check_no$+are21a.reserved_key_02$,dom=*next)
	more_dtl=1
	while more_dtl
		readrecord(are_cashgl_dev)are21a$
		if are21a.firm_id$=firm_id$ and are21a.receipt_date$=callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE") and
:										are21a.customer_id$=callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID") and 
:										are21a.cash_rec_cd$=callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD") and
:										are21a.ar_check_no$=callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")
			remove(are_cashgl_dev,key=are21a.firm_id$+are21a.ar_type$+are21a.reserved_key_01$+are21a.receipt_date$+
:				are21a.customer_id$+are21a.cash_rec_cd$+are21a.ar_check_no$+are21a.reserved_key_02$+are21a.gl_account$)
		else
			more_dtl=0
		endif
	wend
return

rem ==================================================================
get_open_invoices:
rem ==================================================================
rem --- use this routine both for new payment trans, and existing (already present in are-01/11)
rem --- invoked from ADIS (existing), ARNF (new), process_OA_chkbox, process_zbal_chkbox
rem --- diff is, for existing, will set already applied/discounted amounts according to are-11 (using UserObj! item containing existing_dtl$)
rem --- this routine initializes two vectors corresponding to the grid on the form: 
rem ---   vectInvoice! contains invoice info from art01/11, updated with applied/discount from are-31, and from existing_dtl$ as mentioned above.  
rem ---   vectInvSel! contains Y/N values to correspond to checkboxes in first column of grid.
rem ---   once vectors are built, they're stored in UserObj!
	inv_key$=firm_id$+"  "+callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID")
	art_invhdr_dev=fnget_dev("ART_INVHDR")
	art_invdet_dev=fnget_dev("ART_INVDET")
	dim art01a$:fnget_tpl$("ART_INVHDR")
	dim art11a$:fnget_tpl$("ART_INVDET")
 	vectInvoice!=SysGUI!.makeVector()
 	vectInvSel!=SysGUI!.makeVector()
	OA_chkbox!=Form!.getControl(num(user_tpl.OA_chkbox_id$))
	zbal_chkbox!=Form!.getControl(num(user_tpl.zbal_chkbox_id$))
	zbal_checked=zbal_chkbox!.isSelected()
	other_avail=0
	chk_applied=0
	read(art_invhdr_dev,key=inv_key$,dom=*next)
	more_hdrs=1
	while more_hdrs
		read record(art_invhdr_dev,end=*break)art01a$
		if art01a.firm_id$+art01a.ar_type$+art01a.customer_id$=inv_key$
			orig_inv_amt=art01a.invoice_amt
			inv_amt=art01a.invoice_bal
			disc_taken=art01a.disc_taken
			if inv_amt<>0 and user_tpl.disc_flag$="Y" and callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")<= pad(art01a.disc_date$,8) 
				disc_amt=art01a.disc_allowed-disc_taken
				if disc_amt<0 then disc_amt=0
			else
				disc_amt=0
			endif
			disp_applied=0
			disp_disc_applied=0
			disp_bal=inv_amt
			gosub applied_but_not_posted
			chk_sel$="N"
			if len(currdtl$) gosub include_curr_tran_amts
			rem --- now load invoice vector w/ data to display in grid		
		
				if inv_amt or zbal_checked 
					vectInvoice!.addItem("")
					vectInvoice!.addItem(art01a.ar_inv_no$)
					vectInvoice!.addItem(fnmdy$(art01a.invoice_date$))
					vectInvoice!.addItem(fnmdy$(art01a.inv_due_date$))
					vectInvoice!.addItem(str(orig_inv_amt))
					vectInvoice!.addItem(str(inv_amt))
					vectInvoice!.addItem(str(disc_amt))
					vectInvoice!.addItem(fnmdy$(pad(art01a.disc_date$,8)))
					vectInvoice!.addItem(str(disp_applied))
					vectInvoice!.addItem(str(disp_disc_applied))
					vectInvoice!.addItem(str(disp_bal))
					commentMap!=callpoint!.getDevObject("commentMap")
					if commentMap!.get(art01a.ar_inv_no$)<>null() then
						vectInvoice!.addItem(commentMap!.get(art01a.ar_inv_no$))
					else
						vectInvoice!.addItem(art01a.memo_1024$)
					endif
					if chk_sel$="Y" vectInvSel!.addItem("Y") else vectInvSel!.addItem("N")
				endif
						
		else
			more_hdrs=0
		endif
	wend
		
 	UserObj!.setItem(num(user_tpl.inv_vect$),vectInvoice!)
	UserObj!.setItem(num(user_tpl.inv_sel_vect$),vectInvSel!)
return

rem ==================================================================
applied_but_not_posted:
rem ==================================================================
	are_cashbal_dev=fnget_dev("ARE_CASHBAL")
	dim are31a$:fnget_tpl$("ARE_CASHBAL")
	read record(are_cashbal_dev,key=art01a.firm_id$+art01a.ar_type$+are31a.reserved_str$+
:				art01a.customer_id$+art01a.ar_inv_no$,dom=*next)are31a$
	inv_amt=inv_amt-num(are31a.apply_amt$)-num(are31a.discount_amt$)	
	if user_tpl.disc_flag$="Y" disc_amt=disc_amt-num(are31a.discount_amt$)
	disp_bal=disp_bal-num(are31a.apply_amt$)-num(are31a.discount_amt$)
return

rem ==================================================================
include_curr_tran_amts:
rem ==================================================================
	existing_dtl$=UserObj!.getItem(num(user_tpl.existing_dtl$))
	existing_dtl=0
	if len(existing_dtl$)<>0 existing_dtl=pos(art01a.ar_inv_no$=existing_dtl$(11),40)
	rem --- existing_dtl$ contains info already in are-11
	if existing_dtl<>0
		exist_applied=num(existing_dtl$(existing_dtl+20,10))
		exist_disc=num(existing_dtl$(existing_dtl+30,10))
	else
		exist_applied=0
		exist_disc=0
	endif
	
	rem --- currdtl$ contains applied/discount amounts in vectInvoice, but not necessarily in are-11
	curr_dtl=pos(art01a.ar_inv_no$=currdtl$(11),40)
	if curr_dtl<>0
		inv_amt=inv_amt+exist_applied+exist_disc
		disc_amt=disc_amt+exist_disc
		disp_applied=num(currdtl$(curr_dtl+20,10))
		disp_disc_applied=num(currdtl$(curr_dtl+30,10))
 		disp_bal=inv_amt-disp_applied-disp_disc_applied
		chk_applied=chk_applied+disp_applied
		if disp_applied<>0 or disp_disc<>0 then chk_sel$="Y"
		currdtl$=currdtl$(1,curr_dtl-1)+currdtl$(curr_dtl+40)
	else
		disp_applied=0
		disp_disc_applied=0
	endif
return

rem ==================================================================
include_new_OA_trans:
rem ==================================================================
rem --- should only happen if new check applied OA, and this OA inv rec not in art-01/11
rem --- will add information for the OA tran to both vectInvoice! and vectInvSel!
	vectInvoice!.addItem("")
	vectInvoice!.addItem(currdtl$(11,10))
	vectInvoice!.addItem(fnmdy$(callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")))
	vectInvoice!.addItem(fnmdy$(callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")))
	vectInvoice!.addItem(currdtl$(21,10))
	vectInvoice!.addItem(currdtl$(31,10))
	vectInvoice!.addItem(str(0))
	vectInvoice!.addItem(fnmdy$(callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")))
	vectInvoice!.addItem(str(currdtl$(21,10)))
	vectInvoice!.addItem(str(0))
	vectInvoice!.addItem(str(0))
	vectInvoice!.addItem("")				
	vectInvSel!.addItem("Y")
	chk_applied=chk_applied+num(currdtl$(21,10))
return

rem ==================================================================
fill_bottom_grid:
rem ==================================================================
	rem --- Don't fill grid when Cash Receipt code posts to GL only
	if user_tpl.arglboth$="G" then return

rem	SysGUI!.setRepaintEnabled(0)
	gridInvoice!=UserObj!.getItem(num(user_tpl.inv_grid$))
	minrows=num(user_tpl.gridInvoice_rows$)
	if vectInvoice!.size()
		numrow=vectInvoice!.size()/gridInvoice!.getNumColumns()
		gridInvoice!.clearMainGrid()
		gridInvoice!.setColumnStyle(0,SysGUI!.GRID_STYLE_UNCHECKED)
		gridInvoice!.setNumRows(numrow)
		gridInvoice!.setCellText(0,0,vectInvoice!)
		if vectInvSel!.size()
			for wk=0 to vectInvSel!.size()-1
				if vectInvSel!.getItem(wk)="Y"
					gridInvoice!.setCellStyle(wk,0,SysGUI!.GRID_STYLE_CHECKED)
				endif
			next wk
		endif
		gridInvoice!.resort()
		gridInvoice!.setSelectedRow(0)
		gridInvoice!.setSelectedColumn(1)
	endif
rem	SysGUI!.setRepaintEnabled(1)
return

rem ==================================================================
process_OA_chkbox:
rem ==================================================================
	rem --- OA checkbox has been unchecked, remove any OA/CM lines from grid
	rem --- if checked on, read art-01/11 to build vectCheck! with OA/CM's, and add after actual check, if there is one
	on_off=dec(gui_event.flags$)
	pymt_dist$=UserObj!.getItem(num(user_tpl.pymt_dist$))
	if on_off=0		
		vectInvoice!=UserObj!.getItem(num(user_tpl.inv_vect$))
		vectInvSel!=UserObj!.getItem(num(user_tpl.inv_sel_vect$))
		cols=num(user_tpl.gridInvoice_cols$)
		if vectInvoice!.size()
			voffset=0
			while voffset < vectInvoice!.size()
				orig_inv_amt=num(vectInvoice!.getItem(voffset+4))
				cur_inv_amt=num(vectInvoice!.getItem(voffset+num(user_tpl.cur_bal_ofst$)))
				rem --- stmt below used to say if orig_inv_amt<0 or cur_inv_amt<0...not sure we care about cur_inv_amt?
				if orig_inv_amt<0 
					remove_amt=num(vectInvoice!.getItem(voffset+num(user_tpl.applied_amt_ofst$)))
					remove_disc=num(vectInvoice!.getItem(voffset+num(user_tpl.disc_taken_ofst$)))
					remove_inv$=vectInvoice!.getItem(voffset+1)
					for wk=1 to cols
						vectInvoice!.removeItem(voffset)						
					next wk
					dim wk$(20)
					wk$(1)=callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")
					wk$(11)=remove_inv$
					wk=pos(wk$=pymt_dist$,40)
					if wk<>0
						pymt_dist$(wk+20,10)=str(num(pymt_dist$(wk+20,10))-remove_amt)
						pymt_dist$(wk+30,10)=str(num(pymt_dist$(wk+30,10))-remove_disc)
					endif
					vectInvSel!.removeItem(voffset/cols)
					callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",
:						str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))+remove_amt))					
				else
					voffset=voffset+cols
				endif
			wend
			UserObj!.setItem(num(user_tpl.pymt_dist$),pymt_dist$)
		endif
	else
		
		currdtl$=pymt_dist$
		gosub get_open_invoices
		if len(currdtl$)
			gosub include_new_OA_trans
		endif
	endif
	gosub fill_bottom_grid	
	gosub refresh_asel_amounts
	
return

rem ==================================================================
process_zbal_chkbox:
rem ==================================================================
	pymt_dist$=UserObj!.getItem(num(user_tpl.pymt_dist$))
	currdtl$=pymt_dist$
	gosub get_open_invoices
	if len(currdtl$)
		gosub include_new_OA_trans
	endif
	gosub fill_bottom_grid
	gosub refresh_asel_amounts
return

rem ==================================================================
process_asel_chkbox:
rem ==================================================================
	
	if on_off=0
		gosub auto_select_off		
		UserObj!.setItem(num(user_tpl.pymt_dist$),"")
	else
		gosub auto_select_off;rem --- turn off/reset amts before turning on
		pymt_dist$=""
		pay_id$=callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")
		to_pay=num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))
		gosub auto_select_on										
	endif
return

rem ==================================================================
auto_select_on:
rem ==================================================================
	vectInvoice!=UserObj!.getItem(num(user_tpl.inv_vect$))
	vectInvSel!=UserObj!.getItem(num(user_tpl.inv_sel_vect$))
	gridInvoice_cols=num(user_tpl.gridInvoice_cols$)
	if vectInvoice!.size()
		for payloop=0 to vectInvoice!.size()-1  step gridInvoice_cols
				inv_bal=num(vectInvoice!.getItem(payloop+num(user_tpl.new_bal_ofst$)))
:					-num(vectInvoice!.getItem(payloop+num(user_tpl.avail_disc_ofst$)))
:					+num(vectInvoice!.getItem(payloop+num(user_tpl.disc_taken_ofst$)))
				disc_amt=num(vectInvoice!.getItem(payloop+num(user_tpl.avail_disc_ofst$)))-
:					num(vectInvoice!.getItem(payloop+num(user_tpl.disc_taken_ofst$)))
				if inv_bal>0
					if inv_bal<=to_pay
						pd_amt=inv_bal
						vectInvoice!.setItem(payloop+num(user_tpl.applied_amt_ofst$),
:							str(num(vectInvoice!.getItem(payloop+num(user_tpl.applied_amt_ofst$)))+inv_bal))
						vectInvoice!.setItem(payloop+num(user_tpl.disc_taken_ofst$),
:							str(num(vectInvoice!.getItem(payloop+num(user_tpl.disc_taken_ofst$)))+disc_amt))
						vectInvoice!.setItem(payloop+num(user_tpl.new_bal_ofst$),"0")
						to_pay=to_pay-inv_bal
						vectInvSel!.setItem(int(payloop/gridInvoice_cols),"Y")
					else
						pd_amt=to_pay
						vectInvoice!.setItem(payloop+num(user_tpl.applied_amt_ofst$),
:							str(num(vectInvoice!.getItem(payloop+num(user_tpl.applied_amt_ofst$)))+to_pay))
						vectInvoice!.setItem(payloop+num(user_tpl.disc_taken_ofst$),
:							str(num(vectInvoice!.getItem(payloop+num(user_tpl.disc_taken_ofst$)))+disc_amt))
						vectInvoice!.setItem(payloop+num(user_tpl.new_bal_ofst$),str(inv_bal-to_pay))
						to_pay=0
						vectInvSel!.setItem(int(payloop/gridInvoice_cols),"Y")
					endif
					callpoint!.setColumnData("<<DISPLAY>>.DISP_APPLIED",
:						str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_APPLIED"))+pd_amt))
					callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",
:						str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))-pd_amt))
					dim wk$(40)
					wk$(1)=pay_id$
					wk$(11)=vectInvoice!.getItem(payloop+1)
					wk=pos(wk$(1,20)=pymt_dist$)
					if wk<>0
						pymt_dist$(wk+20,10)=str(num(pymt_dist$(wk+20,10))+pd_amt)
						pymt_dist$(wk+30,10)=str(num(pymt_dist$(wk+30,10))+disc_amt)
					else
						wk$(21)=str(pd_amt)
						wk$(31)=str(disc_amt)
						pymt_dist$=pymt_dist$+wk$
					endif
				endif
				if to_pay=0 then break
		next payloop
		gosub fill_bottom_grid
		UserObj!.setItem(num(user_tpl.inv_vect$),vectInvoice!)
		UserObj!.setItem(num(user_tpl.inv_sel_vect$),vectInvSel!)
		UserObj!.setItem(num(user_tpl.pymt_dist$),pymt_dist$)
	endif
return

rem ==================================================================
auto_select_off:
rem ==================================================================
	vectInvoice!=UserObj!.getItem(num(user_tpl.inv_vect$))
	vectInvSel!=UserObj!.getItem(num(user_tpl.inv_sel_vect$))
	gridInvoice_cols=num(user_tpl.gridInvoice_cols$)
	if vectInvoice!.size()
		for payloop=0 to vectInvoice!.size()-1  step gridInvoice_cols		
					vectInvoice!.setItem(payloop+num(user_tpl.applied_amt_ofst$),"0")
					vectInvoice!.setItem(payloop+num(user_tpl.disc_taken_ofst$),"0")
					vectInvoice!.setItem(payloop+num(user_tpl.new_bal_ofst$),
:						str(num(vectInvoice!.getItem(payloop+num(user_tpl.cur_bal_ofst$)))))				
					vectInvSel!.setItem(int(payloop/gridInvoice_cols),"N")		
		next payloop
		gosub fill_bottom_grid
		callpoint!.setColumnData("<<DISPLAY>>.DISP_APPLIED",str(0))
		callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",callpoint!.getColumnData("ARE_CASHHDR.PAYMENT_AMT"))
		UserObj!.setItem(num(user_tpl.inv_vect$),vectInvoice!)
		UserObj!.setItem(num(user_tpl.inv_sel_vect$),vectInvSel!)
	endif
return

rem ==================================================================
refresh_asel_amounts:
rem ==================================================================
	asel_chkbox!=Form!.getControl(num(user_tpl.asel_chkbox_id$))
	if asel_chkbox!.isSelected()
		for on_off=0 to 1
			gosub process_asel_chkbox
		next on_off
	endif
return

rem ==================================================================
process_gridInvoice_event:
rem ==================================================================
	vectInvoice!=UserObj!.getItem(num(user_tpl.inv_vect$))
	vectInvSel!=UserObj!.getItem(num(user_tpl.inv_sel_vect$))
	gridInvoice!=UserObj!.getItem(num(user_tpl.inv_grid$))
	cols=num(user_tpl.gridInvoice_cols$)
	clicked_row=dec(notice.row$)
	pymt_dist$=UserObj!.getItem(num(user_tpl.pymt_dist$))
	if vectInvoice!.size()=0 then return

	switch dec(notice.code$)
		case 7;rem --- edit stop
			rem --- only columns 0 (SELECT), 8 (APPLY), 9 (DISC) and 11 (COMMENT) are enabled
	 		switch dec(notice.col$)
 				case 0; rem --- SELECET
	 				break
 				case num(user_tpl.applied_amt_ofst$); rem --- APPLY
 				case num(user_tpl.disc_taken_ofst$); rem --- DISC
					rem --- don't allow discount if not paying anything
					old_pay=num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.applied_amt_ofst$)))
					old_disc=num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.disc_taken_ofst$)))
					new_pay=0
					new_disc=0
					if dec(notice.col$)=8
						new_pay=num(notice.buf$)
						new_disc=old_disc
						if new_pay=0 new_disc=0
					else
						new_disc=num(notice.buf$)
						new_pay=old_pay
						if new_pay=0 new_disc=0
					endif
					vectInvoice!.setItem(clicked_row*cols+num(user_tpl.applied_amt_ofst$),str(new_pay))
					vectInvoice!.setItem(clicked_row*cols+num(user_tpl.disc_taken_ofst$),str(new_disc))
					vectInvoice!.setItem(clicked_row*cols+num(user_tpl.new_bal_ofst$),
:						str(num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.new_bal_ofst$)))+old_pay-new_pay+old_disc-new_disc))
					gridInvoice!.setCellText(clicked_row,num(user_tpl.applied_amt_ofst$),str(new_pay))
					gridInvoice!.setCellText(clicked_row,num(user_tpl.disc_taken_ofst$),str(new_disc))
					gridInvoice!.setCellText(clicked_row,num(user_tpl.new_bal_ofst$),
:						vectInvoice!.getItem(clicked_row*cols+num(user_tpl.new_bal_ofst$)))
					rem --- Warn when End Balance goes negative
					if num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.new_bal_ofst$)))<0 and (old_pay<>new_pay or old_disc<>new_disc)
						msg_id$="AR_CREDIT_BALANCE"
						gosub disp_message
					endif
					rem --- if this is an OA/CM line (test inv amt, curr amt), then applied amt just increases total to apply
					if num(vectInvoice!.getItem(clicked_row*cols+4))<0
:					or num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.cur_bal_ofst$))) <0
						callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",
:						str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))+old_pay-new_pay))
					else
						callpoint!.setColumnData("<<DISPLAY>>.DISP_APPLIED",
:							str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_APPLIED"))-old_pay+new_pay))
						callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",
:							str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))+old_pay-new_pay))
					endif
					if new_pay=0
						vectInvSel!.setItem(clicked_row,"N")
						gridInvoice!.setCellStyle(clicked_row,0,SysGUI!.GRID_STYLE_UNCHECKED)
					endif
					dim wk$(40)
					wk$(1)=callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")
					wk$(11)=vectInvoice!.getItem(clicked_row*cols+1)
					wk=pos(wk$(1,20)=pymt_dist$)
					if wk<>0
						pymt_dist$(wk+20,10)=str(num(pymt_dist$(wk+20,10))+(new_pay-old_pay))
						pymt_dist$(wk+30,10)=str(num(pymt_dist$(wk+30,10))+(new_disc-old_disc))
					else
						wk$(21)=str(new_pay-old_pay)
						wk$(31)=str(new_disc-old_disc)
						pymt_dist$=pymt_dist$+wk$
					endif
					Form!.getControl(num(user_tpl.asel_chkbox_id$)).setSelected(0)
					UserObj!.setItem(num(user_tpl.pymt_dist$),pymt_dist$)
					callpoint!.setStatus("REFRESH-MODIFIED")
	 				break
 				case num(user_tpl.cmt_ofst$); rem --- COMMENT
	 				break
 				case default
	 				break
	 		swend
		break
		case 8;rem --- edit start
			rem --- only columns 0 (SELECT), 8 (APPLY), 9 (DISC) and 11 (COMMENT) are enabled
	 		switch dec(notice.col$)
 				case 0; rem --- SELECT
	 				break
 				case num(user_tpl.applied_amt_ofst$); rem --- APPLY
 				case num(user_tpl.disc_taken_ofst$); rem --- DISC
					vectInvSel!.setItem(clicked_row,"Y")
					gridInvoice!.setCellStyle(clicked_row,0,SysGUI!.GRID_STYLE_CHECKED)
	 				break
 				case num(user_tpl.cmt_ofst$); rem --- COMMENT
					disp_text$=gridInvoice!.getCellText(clicked_row,num(user_tpl.cmt_ofst$))
					sv_disp_text$=disp_text$

					editable$="YES"
					force_loc$="NO"
					baseWin!=null()
					startx=0
					starty=0
					shrinkwrap$="NO"
					html$="NO"
					dialog_result$=""
					spellcheck=1

					call stbl("+DIR_SYP")+ "bax_display_text.bbj",
:						"Cash Receipts Detail Comments",
:						disp_text$, 
:						table_chans$[all], 
:						editable$, 
:						force_loc$, 
:						baseWin!, 
:						startx, 
:						starty, 
:						shrinkwrap$, 
:						html$, 
:						dialog_result$,
:						spellcheck

					if disp_text$<>sv_disp_text$
						gridInvoice!.setCellText(clicked_row,num(user_tpl.cmt_ofst$),disp_text$)
						vectInvoice!.setItem(clicked_row*cols+num(user_tpl.cmt_ofst$),disp_text$)
						callpoint!.setStatus("MODIFIED")
					endif

					callpoint!.setStatus("ACTIVATE")
	 				break
 				case default
	 				break
	 		swend
		break
		case 12;rem --- grid_key_press (allow space-bar toggle of checkbox)
			if notice.wparam=32 
				inv_onoff=gridInvoice!.getCellState(clicked_row,0)
				if inv_onoff=0 inv_onoff=1 else inv_onoff=0;rem --- toggle
				gosub invoice_chk_onoff
				gridInvoice!.setSelectedColumn(1)
				Form!.getControl(num(user_tpl.asel_chkbox_id$)).setSelected(0)			
				callpoint!.setStatus("REFRESH-MODIFIED")
			endif
		break
		case 14; rem --- grid_mouse_up
			if notice.col=0 then
				inv_onoff=gridInvoice!.getCellState(clicked_row,0)
				if inv_onoff=0 inv_onoff=1 else inv_onoff=0;rem --- toggle
				gosub invoice_chk_onoff
				gridInvoice!.setSelectedColumn(1)
				Form!.getControl(num(user_tpl.asel_chkbox_id$)).setSelected(0)			
				callpoint!.setStatus("REFRESH-MODIFIED")
			endif
		break
		case default
		break
	
	swend
return

rem ==================================================================
invoice_chk_onoff:
rem ==================================================================
	switch inv_onoff
		case 0;rem --- de-select line; reverse applied and remaining amts (unless OA, then just reverse remaining)
			dim wk$(20)
			wk$(1)=callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")
			wk$(11)=vectInvoice!.getItem(clicked_row*cols+1)
			pd_pos=pos(wk$=pymt_dist$,40)
			inv_applied=0
			if pd_pos<>0
				inv_applied=num(pymt_dist$(pd_pos+20,10))
				disc_taken=num(pymt_dist$(pd_pos+30,10))
				vectInvoice!.setItem(clicked_row*cols+num(user_tpl.applied_amt_ofst$),
:                           str(num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.applied_amt_ofst$)))-inv_applied))
				vectInvoice!.setItem(clicked_row*cols+num(user_tpl.disc_taken_ofst$),
:                           str(num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.disc_taken_ofst$)))-disc_taken))
				if num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.applied_amt_ofst$)))=0
					vectInvoice!.setItem(clicked_row*cols+num(user_tpl.disc_taken_ofst$),"0")
					vectInvSel!.setItem(clicked_row,"N")
					gridInvoice!.setCellStyle(clicked_row,0,SysGUI!.GRID_STYLE_UNCHECKED)
				endif
				vectInvoice!.setItem(clicked_row*cols+num(user_tpl.new_bal_ofst$),
:                           str(num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.cur_bal_ofst$)))-
:                           num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.applied_amt_ofst$)))-
:                           num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.disc_taken_ofst$)))))	
				gridInvoice!.setCellText(clicked_row,num(user_tpl.applied_amt_ofst$),
:                           str(num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.applied_amt_ofst$)))))
				gridInvoice!.setCellText(clicked_row,num(user_tpl.disc_taken_ofst$),
:                           str(num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.disc_taken_ofst$)))))
				gridInvoice!.setCellText(clicked_row,num(user_tpl.new_bal_ofst$),
:                           str(num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.new_bal_ofst$)))))
				pymt_dist$(pd_pos+20,10)=str(num(pymt_dist$(pd_pos+20,10))-inv_applied)
				pymt_dist$(pd_pos+30,10)=str(num(pymt_dist$(pd_pos+30,10))-disc_taken)
			endif
			UserObj!.setItem(num(user_tpl.pymt_dist$),pymt_dist$)
			new_pay=0
			old_pay=inv_applied
			rem --- if this is an OA/CM line (test inv amt, curr amt), then applied amt just increases total to apply
			if num(vectInvoice!.getItem(clicked_row*cols+4))<0
:						or num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.cur_bal_ofst$))) <0
					callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",
:								str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))+old_pay-new_pay))
			else
				callpoint!.setColumnData("<<DISPLAY>>.DISP_APPLIED",
:							str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_APPLIED"))-old_pay+new_pay))
				callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",
:							str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))+old_pay-new_pay))
			endif
		break
		case 1; rem --- look at amt left to apply, and apply to selected line
			to_pay=num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))
				vectInvSel!.setItem(clicked_row,"Y")
				gridInvoice!.setCellStyle(clicked_row,0,SysGUI!.GRID_STYLE_CHECKED)
				inv_bal=num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.new_bal_ofst$)))-
:							num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.avail_disc_ofst$)))+
:							num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.disc_taken_ofst$)))
				disc_amt=num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.avail_disc_ofst$)))-
:							num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.disc_taken_ofst$)))
					if (inv_bal>0 and inv_bal<=to_pay) or inv_bal<0 or to_pay<=0
						pd_amt=inv_bal
						vectInvoice!.setItem(clicked_row*cols+num(user_tpl.applied_amt_ofst$),
:									str(num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.applied_amt_ofst$)))+inv_bal))
						vectInvoice!.setItem(clicked_row*cols+num(user_tpl.disc_taken_ofst$),
:									str(num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.disc_taken_ofst$)))+disc_amt))
						vectInvoice!.setItem(clicked_row*cols+num(user_tpl.new_bal_ofst$),"0")
						to_pay=to_pay-inv_bal					
					else
						pd_amt=to_pay
						vectInvoice!.setItem(clicked_row*cols+num(user_tpl.applied_amt_ofst$),
:									str(num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.applied_amt_ofst$)))+to_pay))
						vectInvoice!.setItem(clicked_row*cols+num(user_tpl.disc_taken_ofst$),
:									str(num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.disc_taken_ofst$)))+disc_amt))
						vectInvoice!.setItem(clicked_row*cols+num(user_tpl.new_bal_ofst$),str(inv_bal-to_pay))
						to_pay=0
					endif
					gridInvoice!.setCellText(clicked_row,num(user_tpl.applied_amt_ofst$),
:								str(num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.applied_amt_ofst$)))))
					gridInvoice!.setCellText(clicked_row,num(user_tpl.disc_taken_ofst$),
:								str(num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.disc_taken_ofst$)))))
					gridInvoice!.setCellText(clicked_row,num(user_tpl.new_bal_ofst$),
:								str(num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.new_bal_ofst$)))))
					new_pay=pd_amt
					old_pay=0
					rem --- if this is an OA/CM line (test inv amt, curr amt), then app amt just increases total to apply
					if num(vectInvoice!.getItem(clicked_row*cols+4))<0
:								or num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.cur_bal_ofst$))) <0
						callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",
:									str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))+old_pay-new_pay))
					else
						callpoint!.setColumnData("<<DISPLAY>>.DISP_APPLIED",
:									str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_APPLIED"))-old_pay+new_pay))
						callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",
:									str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))+old_pay-new_pay))
					endif
					dim wk$(40)
					wk$(1)=callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")
					wk$(11)=vectInvoice!.getItem(clicked_row*cols+1)
					wk=pos(wk$(1,20)=pymt_dist$)
					if wk<>0
						pymt_dist$(wk+20,10)=str(new_pay)
						pymt_dist$(wk+30,10)=str(disc_amt)
					else
						wk$(21)=str(new_pay)
						wk$(31)=str(disc_amt)
						pymt_dist$=pymt_dist$+wk$
					endif
					UserObj!.setItem(num(user_tpl.pymt_dist$),pymt_dist$)
		break
	swend
return

rem ==================================================================
format_grids:
rem ==================================================================
	rem --- logic from Sam -- set attributes and use public to build consistent grids, rather
	rem --- than creating manually w/in each callpoint
	rem --- invoice grid
	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()
	def_inv_cols=num(user_tpl.gridInvoice_cols$)
	num_inv_rows=num(user_tpl.gridInvoice_rows$)
	dim attr_inv_col$[def_inv_cols,len(attr_def_col_str$[0,0])/5]
	attr_inv_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SELECT"
	attr_inv_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=""
	attr_inv_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"
	attr_inv_col$[1,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="1"
	attr_inv_col$[1,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="C"
	attr_inv_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="INVOICE"
	attr_inv_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_INVOICE")
	attr_inv_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="70"
	attr_inv_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="INV_DATE"
	attr_inv_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_INV_DATE")
	attr_inv_col$[3,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	attr_inv_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="70"
	attr_inv_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DUE_DATE"
	attr_inv_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DUE_DATE")
	attr_inv_col$[4,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	attr_inv_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="70"
	attr_inv_col$[5,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="INV_AMOUNT"
	attr_inv_col$[5,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_INV_AMOUNT")
	attr_inv_col$[5,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[5,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="75"
	attr_inv_col$[5,fnstr_pos("MSKI",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[5,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[6,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="CURR_BAL"
	attr_inv_col$[6,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_OPENING_BAL")
	attr_inv_col$[6,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[6,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="75"
	attr_inv_col$[6,fnstr_pos("MSKI",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[6,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[7,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="AVAIL_DISC"
	attr_inv_col$[7,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_AVAIL_DISC")
	attr_inv_col$[7,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[7,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="70"
	attr_inv_col$[7,fnstr_pos("MSKI",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[7,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[8,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DISC_DATE"
	attr_inv_col$[8,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DISC_DATE")
	attr_inv_col$[8,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	attr_inv_col$[8,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="70"
	attr_inv_col$[9,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="APPLY"
	attr_inv_col$[9,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_APPLIED")
	attr_inv_col$[9,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[9,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="75"
	attr_inv_col$[9,fnstr_pos("MSKI",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[9,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[10,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DISC"
	attr_inv_col$[10,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DISC_AMT")
	attr_inv_col$[10,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[10,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="75"
	attr_inv_col$[10,fnstr_pos("MSKI",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[10,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[11,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="BALANCE"
	attr_inv_col$[11,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_END_BALANCE")
	attr_inv_col$[11,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[11,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="75"
	attr_inv_col$[11,fnstr_pos("MSKI",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[11,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[12,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="COMMENT"
	attr_inv_col$[12,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_COMMENTS")
	attr_inv_col$[12,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="300"
	for curr_attr=1 to def_inv_cols
		attr_inv_col$[0,1]=attr_inv_col$[0,1]+pad("CASH_REC_INV."+attr_inv_col$[curr_attr,
:			fnstr_pos("DVAR",attr_def_col_str$[0,0],5)],40)
	next curr_attr
	attr_disp_col$=attr_inv_col$[0,1]
	call dir_pgm$+"bam_grid_init.bbj",gui_dev,gridInvoice!,"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC-DATES-CHECKS",num_inv_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_inv_col$[all]
return

rem ==================================================================
disable_ctls:rem --- disable selected controls
rem ==================================================================
	for dctl=1 to 3
		dctl$=dctl$[dctl]
		if dctl$<>""
			wctl$=str(num(callpoint!.getTableColumnAttribute(dctl$,"CTLI")):"00000")
			wmap$=callpoint!.getAbleMap()
			wpos=pos(wctl$=wmap$,8)
			wmap$(wpos+6,1)="I"
			callpoint!.setAbleMap(wmap$)
			callpoint!.setStatus("ABLEMAP")
		endif
	next dctl
	return

rem ==================================================================
updateDepositAmt: 	rem --- Set Deposit's tot_deposit_amt equal the total of the receipt payments in the deposit tot_receipts_amt
	rem --- input data:
		rem --- deposit_id$
		rem --- tot_deposit_amt
		rem --- tot_receipts_amt
rem ==================================================================
	deposit_dev=fnget_dev("1ARE_DEPOSIT")
	dim deposit_tpl$:fnget_tpl$("1ARE_DEPOSIT")
	batch_no$=callpoint!.getColumnData("ARE_CASHHDR.BATCH_NO")
	extractrecord(deposit_dev,key=firm_id$+batch_no$+"E"+deposit_id$,knum="AO_BATCH_STAT",dom=*next)deposit_tpl$
	if deposit_tpl.deposit_id$=deposit_id$ then
		deposit_tpl.tot_deposit_amt=tot_receipts_amt
		deposit_tpl$=field(deposit_tpl$)
		writerecord(deposit_dev)deposit_tpl$
	endif
	return

rem ==================================================================
adjustTotReceiptsAmt: 	rem --- Adjust tot_receipts_amt for changes in payment_amt
rem ==================================================================
	current_payment_amt=num(callpoint!.getColumnData("ARE_CASHHDR.PAYMENT_AMT"))
	saved_payment_amt=num(callpoint!.getDevObject("saved_payment_amt"))
	delta_payment_amt=current_payment_amt-saved_payment_amt
	tot_receipts_amt=num(callpoint!.getDevObject("tot_receipts_amt"))
	tot_receipts_amt=tot_receipts_amt+delta_payment_amt
	callpoint!.setDevObject("tot_receipts_amt",tot_receipts_amt)
	callpoint!.setDevObject("saved_payment_amt",current_payment_amt)
	return

#include std_missing_params.src
