[[ARE_CASHHDR.PAYMENT_AMT.BINP]]
rem --- store value in control prior to input so we'll know at AVAL if it changed
user_tpl.binp_pay_amt=num(callpoint!.getColumnData("ARE_CASHHDR.PAYMENT_AMT"))
[[ARE_CASHHDR.ARNF]]
rem --- ARNF; record not found (i.e., entered date/customer/receipt cd/chk # for new tran)
ctl_stat$="D"
gosub disable_key_fields
gosub get_open_invoices
if len(currdtl$)
	rem escape;rem for testing -- shouldn't ever contain anything at this point
	gosub include_new_OA_trans
endif
disp_applied=chk_applied+gl_applied
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
			gosub process_gridInvoice_event
			callpoint!.setStatus("REFRESH-MODIFIED")
		break
	swend
endif
[[ARE_CASHHDR.ADEL]]
gosub delete_cashdet_cashbal
[[ARE_CASHHDR.ADIS]]
rem --- ADIS; existing are-01/11 tran
tmp_cust_id$=callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID")
gosub get_customer_balance
wk_cash_cd$=callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD")
gosub get_cash_rec_cd
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
read (are_cashdet_dev,key=callpoint!.getRecordKey(),dom=*next)
while more_dtl
	read record(are_cashdet_dev,end=*break)are11a$
	if are11a$(1,len(callpoint!.getRecordKey()))=callpoint!.getRecordKey()
		dim wk$(40)
		wk$(1)=callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")
		wk$(11)=are11a.ar_inv_no$
		wk$(21)=are11a.apply_amt$
		wk$(31)=are11a.discount_amt$
		pymt_dist$=pymt_dist$+wk$
		existing_dtl$=existing_dtl$+wk$
	else
		more_dtl=0
	endif
wend
rem --- read thru existing are-21's and store total GL amt posted this check
more_dtl=1
read(are_cashgl_dev,key=callpoint!.getRecordKey(),dom=*next)
while more_dtl
	read record(are_cashgl_dev,end=*break)are21a$
	if are21a$(1,len(callpoint!.getRecordKey()))=callpoint!.getRecordKey()
		gl_applied=gl_applied+num(are21a.gl_post_amt$)
	else
		more_dtl=0
	endif
wend
if gl_applied
	Form!.getControl(num(user_tpl.GLind_id$)).setText("* includes GL distributions")
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
disp_applied=chk_applied+gl_applied
disp_bal=num(callpoint!.getColumnData("ARE_CASHHDR.PAYMENT_AMT"))-disp_applied
callpoint!.setColumnData("<<DISPLAY>>.DISP_APPLIED",str(disp_applied))
callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",str(disp_bal))
gosub fill_bottom_grid
callpoint!.setStatus("REFRESH")
[[ARE_CASHHDR.AOPT-OACT]]
gosub apply_on_acct
[[ARE_CASHHDR.AOPT-GLED]]
rem --- change below to "Y" instead of "N" for production
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
Form!.getControl(num(user_tpl.GLind_id$)).setText("")
Form!.getControl(num(user_tpl.GLstar_id$)).setText("")
[[ARE_CASHHDR.ASIZ]]
if UserObj!<>null()
	gridInvoice!=UserObj!.getItem(num(user_tpl.inv_grid$))
	gridInvoice!.setSize(Form!.getWidth()-(gridInvoice!.getX()*2),Form!.getHeight()-(gridInvoice!.getY()+40))
	gridInvoice!.setFitToGrid(1)
	gridInvoice!.setColumnWidth(0,25)
endif
[[ARE_CASHHDR.AWIN]]
rem --- Open/Lock files
use ::ado_util.src::util
files=30,begfile=1,endfile=11
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
files$[11]="GLS_PARAMS";rem --- gls-01"
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
gls01_dev=num(chans$[11])
rem --- Dimension miscellaneous string templates
dim ars01a$:templates$[10],gls01a$:templates$[11]
user_tpl_str$="firm_id:c(2),glint:c(1),glyr:c(4),glper:c(2),glworkfile:c(16),"
user_tpl_str$=user_tpl_str$+"cash_flag:c(1),disc_flag:c(1),arglboth:c(1),amt_msk:c(15),existing_chk:c(1),"
user_tpl_str$=user_tpl_str$+"OA_chkbox_id:c(5),zbal_chkbox_id:c(5),asel_chkbox_id:c(5),"
user_tpl_str$=user_tpl_str$+"gridCheck_id:c(5),gridInvoice_id:c(5),gridCheck_cols:c(5),gridInvoice_cols:c(5),"
user_tpl_str$=user_tpl_str$+"gridCheck_rows:c(5),gridInvoice_rows:c(5),"
user_tpl_str$=user_tpl_str$+"chk_grid:c(5),inv_grid:c(5),chk_vect:c(5),inv_vect:c(5),chk_sel_vect:c(5),"
user_tpl_str$=user_tpl_str$+"inv_sel_vect:c(5),cur_bal_ofst:c(5),avail_disc_ofst:c(5),"
user_tpl_str$=user_tpl_str$+"applied_amt_ofst:c(5),disc_taken_ofst:c(5),new_bal_ofst:c(5),pymt_dist:c(5),"
user_tpl_str$=user_tpl_str$+"existing_dtl:c(5),GLind_id:c(5),GLstar_id:c(5),gl_applied:c(10),binp_pay_amt:n(15)"
dim user_tpl$:user_tpl_str$
user_tpl.firm_id$=firm_id$
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
rem --- Retrieve parameter data - not keeping any of it here, just make sure params exist
ars01a_key$=firm_id$+"AR00"
find record (ars01_dev,key=ars01a_key$,err=std_missing_params) ars01a$
user_tpl.amt_msk$=ars01a.amount_mask$
call stbl("+DIR_PGM")+"adc_getmask.aon","","AR","A",imsk$,omsk$,ilen,olen
user_tpl.amt_msk$=imsk$
gls01a_key$=firm_id$+"GL00"
find record (gls01_dev,key=gls01a_key$,err=std_missing_params) gls01a$
rem --- add custom controls, checkboxes and grids
UserObj!=SysGUI!.makeVector()
nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))
OA_chkbox!=Form!.addCheckBox(nxt_ctlID,555,52,200,20,"Show On-Account and Credits?",$04$)
zbal_chkbox!=Form!.addCheckBox(nxt_ctlID+1,555,72,200,20,"Show zero-balance invoices?",$$)
asel_chkbox!=Form!.addCheckBox(nxt_ctlID+2,555,92,200,20,"Auto-select by Invoice?",$$)
gridInvoice!=Form!.addGrid(nxt_ctlID+3,5,160,700,210)
Form!.addStaticText(nxt_ctlID+4,450,140,200,20,"")
Form!.addStaticText(nxt_ctlID+5,530,118,20,20,"")
rem --- store ctl ID's of custom controls				
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
user_tpl.gridInvoice_rows$="10"				
user_tpl.inv_grid$="0"				
user_tpl.inv_vect$="1"				
user_tpl.inv_sel_vect$="2"
user_tpl.cur_bal_ofst$="5"
user_tpl.avail_disc_ofst$="6"
user_tpl.applied_amt_ofst$="8"
user_tpl.disc_taken_ofst$="9"
user_tpl.new_bal_ofst$="10"
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
gridInvoice!.setCallback(gridInvoice!.ON_GRID_SELECT_ROW,"custom_event")
gridInvoice!.setCallback(gridInvoice!.ON_GRID_SELECT_COLUMN,"custom_event")
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
gridInvoice!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)
[[ARE_CASHHDR.AWRI]]
gosub update_cashhdr_cashdet_cashbal
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
wk_cash_cd$=callpoint!.getUserInput()
gosub get_cash_rec_cd
[[ARE_CASHHDR.CUSTOMER_ID.AVAL]]
tmp_cust_id$=callpoint!.getUserInput()
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
rem --- gl$="N";rem --- testing
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
disable_key_fields:
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
disable_fields:
	rem --- used to disable/enable controls
	rem --- ctl_name$ sent in with name of control to enable/disable (format "ALIAS.CONTROL_NAME")
	rem --- ctl_stat$ sent in as D (or I) or space, meaning disable/enable, respectively
	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
return
get_cash_rec_cd:
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
get_customer_balance:
	rem --- tmp_cust_id$ being set prior to gosub
	arm_custdet_dev=fnget_dev("ARM_CUSTDET")
	dim arm02a$:fnget_tpl$("ARM_CUSTDET")
	arm02a.firm_id$=firm_id$,arm02a.customer_id$=tmp_cust_id$,arm02a.ar_type$="  "
	readrecord(arm_custdet_dev,key=arm02a.firm_id$+arm02a.customer_id$+arm02a.ar_type$,err=*next)arm02a$
	callpoint!.setColumnData("<<DISPLAY>>.DISP_CUST_BAL",
:		str(num(arm02a.aging_future$)+num(arm02a.aging_cur$)+num(arm02a.aging_30$)+
:       num(arm02a.aging_60$)+num(arm02a.aging_90$)+num(arm02a.aging_120$)))
return
check_required_fields:
	if cvs(callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE"),3)="" or 
:		cvs(callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID"),3)="" or
:		cvs(callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD"),3)="" or
:		cvs(callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO"),3)=""
		if data_present$="NO-MSG"
			msg_id$="AR_REQ_DATA"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	else
		data_present$="Y"
	endif
return
update_cashhdr_cashdet_cashbal:
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
		are11a.ar_inv_no$=cvs(pymt_dist$(updt_loop+10,10),3)
		are31a.ar_inv_no$=are11a.ar_inv_no$
		old_pay=0,old_disc=0
rem --- cashhdr, are-01
		readrecord(are_cashhdr_dev,key=are01a.firm_id$+are01a.ar_type$+are01a.reserved_key_01$+are01a.receipt_date$+
:			are01a.customer_id$+are01a.cash_rec_cd$+are11a.ar_check_no$+are01a.reserved_key_02$,dom=*next)are01a$		
		are01a.payment_amt$=callpoint!.getColumnData("ARE_CASHHDR.PAYMENT_AMT")
		are01a.cash_check$=callpoint!.getColumnData("ARE_CASHHDR.CASH_CHECK")
		are01a.aba_no$=callpoint!.getColumnData("ARE_CASHHDR.ABA_NO")		
		are01a$=field(are01a$)
		writerecord(are_cashhdr_dev,key=are01a.firm_id$+are01a.ar_type$+are01a.reserved_key_01$+
:			are01a.receipt_date$+are01a.customer_id$+are01a.cash_rec_cd$+are11a.ar_check_no$+are01a.reserved_key_02$)are01a$
		apply_amt=num(pymt_dist$(updt_loop+20,10))
		disc_amt=num(pymt_dist$(updt_loop+30,10))
rem --- cashdet, are-11
		readrecord(are_cashdet_dev,key=are11a.firm_id$+are11a.ar_type$+are11a.reserved_key_01$+are11a.receipt_date$+
:			are11a.customer_id$+are11a.cash_rec_cd$+are11a.ar_check_no$+are11a.reserved_key_02$+are11a.ar_inv_no$,dom=*next)are11a$
		if num(are11a.apply_amt)<>0 or num(are11a.discount_amt$)<>0
			old_pay=num(are11a.apply_amt$)
			old_disc=num(are11a.discount_amt$)
		endif
		are11a.apply_amt$=str(apply_amt)
		are11a.discount_amt$=str(disc_amt)
		if apply_amt<>0 or disc_amt<>0
			are11a$=field(are11a$)
			writerecord(are_cashdet_dev,key=are11a.firm_id$+are11a.ar_type$+are11a.reserved_key_01$+
:				are11a.receipt_date$+are11a.customer_id$+are11a.cash_rec_cd$+are11a.ar_check_no$+are11a.reserved_key_02$+
:				are11a.ar_inv_no$)are11a$
		else
			remove(are_cashdet_dev,key=are11a.firm_id$+are11a.ar_type$+are11a.reserved_key_01$+are11a.receipt_date$+
:				are11a.customer_id$+are11a.cash_rec_cd$+are11a.ar_check_no$+are11a.reserved_key_02$+are11a.ar_inv_no$,dom=*next)
		endif
rem --- cashbal, are-31
		readrecord(are_cashbal_dev,key=are31a.firm_id$+are31a.ar_type$+are31a.reserved_str$+are31a.customer_id$+
:			are31a.ar_inv_no$,dom=*next)are31a$
		are31a.apply_amt$=str(num(are31a.apply_amt)-old_pay+num(are11a.apply_amt$))
		are31a.discount_amt$=str(num(are31a.discount_amt$)-old_disc+num(are11a.discount_amt$))
		if num(are31a.apply_amt$)<>0 or num(are31a.discount_amt$)<>0
			are31a$=field(are31a$)
			writerecord(are_cashbal_dev,key=are31a.firm_id$+are31a.ar_type$+are31a.reserved_str$+
:				are31a.customer_id$+are31a.ar_inv_no$)are31a$
		else
			remove(are_cashbal_dev,key=are31a.firm_id$+are31a.ar_type$+are31a.reserved_str$+are31a.customer_id$+
:				are31a.ar_inv_no$,dom=*next)
		endif
	next updt_loop
	endif
	callpoint!.setStatus("NEWREC"); rem sets up for new record
	
return
validate_before_writing:
	validate_passed$="Y"
	if num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))<>0
		msg_id$="AR_NOT_DIST"
		gosub disp_message
		validate_passed$=msg_opt$
	endif
	rem	gosub check_for_neg_invoices; rem --- not sure I care about this routine?
return
check_for_neg_invoices:
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
apply_on_acct:
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
	endif
	callpoint!.setStatus("RECORD:["+firm_id$+
:		callpoint!.getColumnData("ARE_CASHHDR.AR_TYPE")+
:		callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_01")+
:		callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")+
:		callpoint!.getColumnData("ARE_CASHHDR.CUSTOMER_ID")+
:		callpoint!.getColumnData("ARE_CASHHDR.CASH_REC_CD")+
:		callpoint!.getColumnData("ARE_CASHHDR.AR_CHECK_NO")+
:		callpoint!.getColumnData("ARE_CASHHDR.RESERVED_KEY_02")+"]")
return
delete_cashdet_cashbal:
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
			readrecord(are_cashbal_dev,key=are31a.firm_id$+are31a.ar_type$+are31a.reserved_str$+are31a.customer_id$+
:				are31a.ar_inv_no$)are31a$
			are31a.apply_amt$=str(num(are31a.apply_amt)-del_pay)
			are31a.discount_amt$=str(num(are31a.discount_amt$)-del_disc)
			if num(are31a.apply_amt$)<>0 or num(are31a.discount_amt$)<>0
				are31a$=field(are31a$);writerecord(are_cashbal_dev,key=are31a.firm_id$+are31a.ar_type$+are31a.reserved_str$+
:					are31a.customer_id$+are31a.ar_inv_no$)are31a$
			else
				remove(are_cashbal_dev,key=are31a.firm_id$+are31a.ar_type$+are31a.reserved_str$+are31a.customer_id$+
:					are31a.ar_inv_no$)
			endif
		else
			more_dtl=0
		endif
	wend
	gridInvoice!=UserObj!.getItem(num(user_tpl.inv_grid$))
	gridInvoice!.clearMainGrid()
return
gl_distribution:
	user_id$=stbl("+USER_ID")
	dim dflt_data$[1,1]
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
	callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))-glapp))
	callpoint!.setColumnData("<<DISPLAY>>.DISP_APPLIED",str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_APPLIED"))+glapp))
	Form!.getControl(num(user_tpl.GLind_id$)).setText("* includes GL distributions")
	Form!.getControl(num(user_tpl.GLstar_id$)).setText("*")
	callpoint!.setStatus("REFRESH")
return
delete_cashgl:
rem escape; rem for testing
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
get_open_invoices:
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
	other_avail=0
	chk_applied=0
	read(art_invhdr_dev,key=inv_key$,dom=*next)
	more_hdrs=1
	while more_hdrs
		read record(art_invhdr_dev,end=*break)art01a$
		if art01a.firm_id$+art01a.ar_type$+art01a.customer_id$=inv_key$
			inv_amt=num(art01a.invoice_amt$),orig_inv_amt=inv_amt
			if user_tpl.disc_flag$="Y" and callpoint!.getColumnData("ARE_CASHHDR.RECEIPT_DATE")<= pad(art01a.disc_date$,8) 
				disc_amt=num(art01a.disc_allowed$)
			else
				disc_amt=0
			endif
			read(art_invdet_dev,key=art01a.firm_id$+art01a.ar_type$+art01a.customer_id$+art01a.ar_inv_no$,dom=*next)
			more_dtl=1
			while more_dtl
				read record(art_invdet_dev,end=*break)art11a$
				if art11a.firm_id$+art11a.ar_type$+art11a.customer_id$+art11a.ar_inv_no$=
:					art01a.firm_id$+art01a.ar_type$+art01a.customer_id$+art01a.ar_inv_no$
					if art11a.trans_type$<>" "
						inv_amt=inv_amt+num(art11a.trans_amt$)+num(art11a.adjdisc_amt$)
						disc_amt=disc_amt+num(art11a.adjdisc_amt$)
					endif
				else
					more_dtl=0
				endif
			wend
			if inv_amt=0 disc_amt=0
			disp_applied=0
			disp_disc_applied=0
			disp_bal=inv_amt
			gosub applied_but_not_posted
			chk_sel$="N"
			if len(currdtl$) gosub include_curr_tran_amts
			rem --- now load invoice vector w/ data to display in grid		
		
				if inv_amt or zbal_chkbox!.isSelected() 
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
					vectInvoice!.addItem("")
					if chk_sel$="Y" vectInvSel!.addItem("Y") else vectInvSel!.addItem("N")
				endif
						
		else
			more_hdrs=0
		endif
	wend
		
 	UserObj!.setItem(num(user_tpl.inv_vect$),vectInvoice!)
	UserObj!.setItem(num(user_tpl.inv_sel_vect$),vectInvSel!)
return
applied_but_not_posted:
	are_cashbal_dev=fnget_dev("ARE_CASHBAL")
	dim are31a$:fnget_tpl$("ARE_CASHBAL")
	read record(are_cashbal_dev,key=art01a.firm_id$+art01a.ar_type$+are31a.reserved_str$+
:				art01a.customer_id$+art01a.ar_inv_no$,dom=*next)are31a$
	inv_amt=inv_amt-num(are31a.apply_amt$)-num(are31a.discount_amt$)	
	if user_tpl.disc_flag$="Y" disc_amt=disc_amt-num(are31a.discount_amt$)
	disp_bal=disp_bal-num(are31a.apply_amt$)-num(are31a.discount_amt$)
return
include_curr_tran_amts:
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
include_new_OA_trans:
rem --- should only happen if new check applied OA, and this OA inv rec not in art-01/11
rem --- will add information for the OA tran to both vectInvoice! and vectInvSel!
	rem if len(currdtl$)<>40 then escape;rem --- for testing... shouldn't happen
	rem if currdtl$(11,2)<>"OA" then escape;rem --- for testing... shouldn't happen
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
fill_bottom_grid:
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
process_OA_chkbox:
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
process_zbal_chkbox:
	pymt_dist$=UserObj!.getItem(num(user_tpl.pymt_dist$))
	currdtl$=pymt_dist$
	gosub get_open_invoices
	if len(currdtl$)
		gosub include_new_OA_trans
	endif
	gosub fill_bottom_grid
	gosub refresh_asel_amounts
return
process_asel_chkbox:
	
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
auto_select_on:
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
auto_select_off:
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
refresh_asel_amounts:
	asel_chkbox!=Form!.getControl(num(user_tpl.asel_chkbox_id$))
	if asel_chkbox!.isSelected()
		for on_off=0 to 1
			gosub process_asel_chkbox
		next on_off
	endif
return
process_gridInvoice_event:
	vectInvoice!=UserObj!.getItem(num(user_tpl.inv_vect$))
	vectInvSel!=UserObj!.getItem(num(user_tpl.inv_sel_vect$))
	gridInvoice!=UserObj!.getItem(num(user_tpl.inv_grid$))
	cols=num(user_tpl.gridInvoice_cols$)
	clicked_row=dec(notice.row$)
	pymt_dist$=UserObj!.getItem(num(user_tpl.pymt_dist$))
	if vectInvoice!.size()=0 then return
	switch dec(notice.code$)
		case 7;rem --- edit stop
			rem --- only column 8 and 9 are enabled (except for checkbox at 0); 8=pay, 9=discount
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
:					str(num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.new_bal_ofst$)))+old_pay-new_pay+old_disc-new_disc))
			gridInvoice!.setCellText(clicked_row,num(user_tpl.applied_amt_ofst$),str(new_pay))
			gridInvoice!.setCellText(clicked_row,num(user_tpl.disc_taken_ofst$),str(new_disc))
			gridInvoice!.setCellText(clicked_row,num(user_tpl.new_bal_ofst$),
:					vectInvoice!.getItem(clicked_row*cols+num(user_tpl.new_bal_ofst$)))
			rem --- if this is an OA/CM line (test inv amt, curr amt), then applied amt just increases total to apply
			if num(vectInvoice!.getItem(clicked_row*cols+4))<0
:				or num(vectInvoice!.getItem(clicked_row*cols+num(user_tpl.cur_bal_ofst$))) <0
				callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",
:					str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))+old_pay-new_pay))
			else
				callpoint!.setColumnData("<<DISPLAY>>.DISP_APPLIED",
:					str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_APPLIED"))-old_pay+new_pay))
				callpoint!.setColumnData("<<DISPLAY>>.DISP_BAL",
:					str(num(callpoint!.getColumnData("<<DISPLAY>>.DISP_BAL"))+old_pay-new_pay))
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
			callpoint!.setStatus("REFRESH-MODIFIED"); rem "added MODIFIED 19sept07.CH, as events in dtl grid no longer 'turning on' save icon
			
		break
		case 8;rem --- edit start
			if dec(notice.col$)<>0
				vectInvSel!.setItem(clicked_row,"Y")
				gridInvoice!.setCellStyle(clicked_row,0,SysGUI!.GRID_STYLE_CHECKED)
			endif
		break
		case 19; rem --- select row
			clicked_inv$=vectInvoice!.getItem(clicked_row*cols+1)
			if gridInvoice!.getSelectedColumn()=0
				inv_onoff=gridInvoice!.getCellState(clicked_row,0)
				if inv_onoff=0 inv_onoff=1 else inv_onoff=0;rem --- toggle
				gosub invoice_chk_onoff
				gridInvoice!.setSelectedColumn(1)
				Form!.getControl(num(user_tpl.asel_chkbox_id$)).setSelected(0)
			endif
		break
		case 2;rem --- selected column
			if gridInvoice!.getSelectedColumn()=0
				inv_onoff=gridInvoice!.getCellState(clicked_row,0)
				if inv_onoff=0 inv_onoff=1 else inv_onoff=0;rem --- toggle
				gosub invoice_chk_onoff
				gridInvoice!.setSelectedColumn(1)
				Form!.getControl(num(user_tpl.asel_chkbox_id$)).setSelected(0)
			endif
		break
		case default
		break
	
	swend
return
invoice_chk_onoff:
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
format_grids:
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
	attr_inv_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Invoice"
	attr_inv_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="70"
	attr_inv_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="INV_DATE"
	attr_inv_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Inv Date"
	attr_inv_col$[3,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	attr_inv_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="70"
	attr_inv_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DUE_DATE"
	attr_inv_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Due Date"
	attr_inv_col$[4,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	attr_inv_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="70"
	attr_inv_col$[5,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="INV_AMOUNT"
	attr_inv_col$[5,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Inv Amount"
	attr_inv_col$[5,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[5,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="75"
	attr_inv_col$[5,fnstr_pos("MSKI",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[5,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[6,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="CURR_BAL"
	attr_inv_col$[6,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Opening Bal"
	attr_inv_col$[6,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[6,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="75"
	attr_inv_col$[6,fnstr_pos("MSKI",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[6,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[7,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="AVAIL_DISC"
	attr_inv_col$[7,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Avail Disc"
	attr_inv_col$[7,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[7,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="70"
	attr_inv_col$[7,fnstr_pos("MSKI",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[7,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[8,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DISC_DATE"
	attr_inv_col$[8,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Disc Date"
	attr_inv_col$[8,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	attr_inv_col$[8,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="70"
	attr_inv_col$[9,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="APPLY"
	attr_inv_col$[9,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Applied"
	attr_inv_col$[9,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[9,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="75"
	attr_inv_col$[9,fnstr_pos("MSKI",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[9,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[10,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DISC"
	attr_inv_col$[10,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Disc Amt"
	attr_inv_col$[10,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[10,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="75"
	attr_inv_col$[10,fnstr_pos("MSKI",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[10,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[11,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="BALANCE"
	attr_inv_col$[11,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="End Balance"
	attr_inv_col$[11,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[11,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="75"
	attr_inv_col$[11,fnstr_pos("MSKI",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[11,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=user_tpl.amt_msk$
	attr_inv_col$[12,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SPACER"
	attr_inv_col$[12,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=""
	attr_inv_col$[12,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"
	for curr_attr=1 to def_inv_cols
		attr_inv_col$[0,1]=attr_inv_col$[0,1]+pad("CASH_REC_INV."+attr_inv_col$[curr_attr,
:			fnstr_pos("DVAR",attr_def_col_str$[0,0],5)],40)
	next curr_attr
	attr_disp_col$=attr_inv_col$[0,1]
	call dir_pgm$+"bam_grid_init.bbj",gui_dev,gridInvoice!,"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC-DATES-CHECKS",num_inv_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_inv_col$[all]
return
disable_ctls:rem --- disable selected controls
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
#include std_missing_params.src
