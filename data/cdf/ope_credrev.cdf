[[OPE_CREDREV.AOPT-CRED]]
rem --- get curr row from grid and launch credit maint

	gosub launch_cred_maint
[[OPE_CREDREV.AOPT-NEWC]]
rem --- Add Tickler

	callpoint!.setDevObject("tick_date","")
	callpoint!.setDevObject("customer_id","")
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"OPE_CREDTICK",
:		stbl("+USER_ID"),
:		"MNT",
:		"",
:		table_chans$[all]

	tick_date$=callpoint!.getDevObject("tick_date")
	customer_id$=callpoint!.getDevObject("customer_id")

rem --- Update Credit changes to master file
	if cvs(customer_id$,3)<>"" and cvs(tick_date$,3)<>""
		ope03_dev=fnget_dev("OPE_CREDDATE")
		dim ope03a$:fnget_tpl$("OPE_CREDDATE")
		ope03a.firm_id$=firm_id$
		ope03a.rev_date$=tick_date$
		ope03a.customer_id$=customer_id$
		ope03a$=field(ope03a$)
		writerecord(ope03_dev)ope03a$
	endif
	gosub create_cust_vector
	gosub fill_grid
	callpoint!.setOptionEnabled("NEWC",1)
[[OPE_CREDREV.AOPT-SELR]]
rem --- Run appropriate form
	if user_tpl.cur_sel$="O"
		print 'show'
		print "O"
	else
		print 'show'
		print "C"
	endif
[[OPE_CREDREV.CUST_ORD.AVAL]]
rem --- Change selection
	if user_tpl.cur_sel$="O" and callpoint!.getUserInput()="C"
		user_tpl.cur_sel$="C"
		gosub create_cust_vector
		gosub fill_grid
		callpoint!.setOptionEnabled("NEWC",1)
	endif
	if user_tpl.cur_sel$="C" and callpoint!.getUserInput()="O"
		user_tpl.cur_sel$="O"
		gosub create_orders_vector
		gosub fill_grid
		callpoint!.setOptionEnabled("NEWC",0)
	endif
[[OPE_CREDREV.ACUS]]
rem process custom event -- used in this pgm to select/de-select checkboxes in grid
rem see basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info
rem this routine is executed when callbacks have been set to run a "custom event"
rem analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind
rem of event it is... in this case, we're toggling checkboxes on/off in form grid control

rem --- double click to select the row

dim gui_event$:tmpl(gui_dev)
dim notify_base$:noticetpl(0,0)
gui_event$=SysGUI!.getLastEventString()
ctl_ID=dec(gui_event.ID$)

if ctl_ID=num(user_tpl.gridCreditCtlID$)

	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
	endif

	gosub launch_cred_maint

endif
[[OPE_CREDREV.<CUSTOM>]]
rem --- launch Credit Maint for selected row========================================

launch_cred_maint:

	gridCredit!=UserObj!.getItem(num(user_tpl.gridCreditOffset$))
	numcols=gridCredit!.getNumColumns()
	vectCredit!=UserObj!.getItem(num(user_tpl.vectCreditOffset$))
	curr_row=gridCredit!.getSelectedRow()

	cust_no$=gridCredit!.getCellText(curr_row,1)
	cust$=cust_no$

	callpoint!.setDevObject("tick_date",gridCredit!.getCellText(curr_row,0))
	callpoint!.setDevObject("order",gridCredit!.getCellText(curr_row,3))
	callpoint!.setDevObject("ord_date",gridCredit!.getCellText(curr_row,4))
	callpoint!.setDevObject("ship_date",gridCredit!.getCellText(curr_row,5))

	arm01_dev=fnget_dev("ARM_CUSTMAST")
	dim arm01a$:fnget_tpl$("ARM_CUSTMAST")
	arm02_dev=fnget_dev("ARM_CUSTDET")
	dim arm02a$:fnget_tpl$("ARM_CUSTDET")
	readrecord(arm01_dev,key=firm_id$+cust$,dom=*next)arm01a$
	readrecord(arm02_dev,key=firm_id$+cust$+"  ",dom=*next)arm02a$
	user_id$=stbl("+USER_ID")
	dim dflt_data$[27,1]
	dflt_data$[1,0]="CUSTOMER_ID"
	dflt_data$[1,1]=cust$
	dflt_data$[2,0]="ADDR_LINE_1"
	dflt_data$[2,1]=arm01a.addr_line_1$
	dflt_data$[3,0]="ADDR_LINE_2"
	dflt_data$[3,1]=arm01a.addr_line_2$
	dflt_data$[4,0]="ADDR_LINE_3"
	dflt_data$[4,1]=arm01a.addr_line_3$
	dflt_data$[5,0]="ADDR_LINE_4"
	dflt_data$[5,1]=arm01a.addr_line_4$
	dflt_data$[6,0]="CITY"
	dflt_data$[6,1]=arm01a.city$
	dflt_data$[7,0]="STATE_CODE"
	dflt_data$[7,1]=arm01a.state_code$
	dflt_data$[8,0]="ZIP_CODE"
	dflt_data$[8,1]=arm01a.zip_code$
	dflt_data$[9,0]="COUNTRY"
	dflt_data$[9,1]=arm01a.country$
	dflt_data$[10,0]="CONTACT_NAME"
	dflt_data$[10,1]=arm01a.contact_name$
	dflt_data$[11,0]="PHONE_NO"
	dflt_data$[11,1]=arm01a.phone_no$
	dflt_data$[12,0]="PHONE_EXTEN"
	dflt_data$[12,1]=arm01a.phone_exten$
	dflt_data$[13,0]="FAX_NO"
	dflt_data$[13,1]=arm01a.fax_no$
	dflt_data$[14,0]="SLSPSN_CODE"
	dflt_data$[14,1]=arm02a.slspsn_code$
	dflt_data$[15,0]="AR_TERMS_CODE"
	dflt_data$[15,1]=arm02a.ar_terms_code$
	dflt_data$[16,0]="CRED_HOLD"
	dflt_data$[16,1]=arm02a.cred_hold$
	dflt_data$[17,0]="AGING_FUTURE"
	dflt_data$[17,1]=str(arm02a.aging_future)
	dflt_data$[18,0]="AGING_CUR"
	dflt_data$[18,1]=str(arm02a.aging_cur)
	dflt_data$[19,0]="AGING_30"
	dflt_data$[19,1]=str(arm02a.aging_30)
	dflt_data$[20,0]="AGING_60"
	dflt_data$[20,1]=str(arm02a.aging_60)
	dflt_data$[21,0]="AGING_90"
	dflt_data$[21,1]=str(arm02a.aging_90)
	dflt_data$[22,0]="AGING_120"
	dflt_data$[22,1]=str(arm02a.aging_120)
	dflt_data$[23,0]="CREDIT_LIMIT"
	dflt_data$[23,1]=str(arm02a.credit_limit)
	dflt_data$[24,0]="REV_DATE"
	dflt_data$[24,1]=gridCredit!.getCellText(curr_row,0)
	dflt_data$[25,0]="ORDER_NO"
	dflt_data$[25,1]=gridCredit!.getCellText(curr_row,3)
	dflt_data$[26,0]="ORDER_DATE"
	dflt_data$[26,1]=gridCredit!.getCellText(curr_row,4)
	dflt_data$[27,0]="SHIPMNT_DATE"
	dflt_data$[27,1]=gridCredit!.getCellText(curr_row,5)
	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"OPE_CREDMAINT",
:		user_id$,
:		"",
:		firm_id$+cust$,
:		table_chans$[all],
:		"",
:		dflt_data$[all]

	rem --- redisplay grid
	if user_tpl.cur_sel$="C"
		gosub create_cust_vector
		gosub fill_grid
	endif
	if user_tpl.cur_sel$="O"
		gosub create_orders_vector
		gosub fill_grid
	endif

return

rem ====================================================================
format_grid:

dim attr_def_col_str$[0,0]
attr_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()
def_credit_cols=num(user_tpl.gridCreditCols$)
num_rpts_rows=num(user_tpl.gridCreditRows$)
dim attr_credit_col$[def_credit_cols,len(attr_def_col_str$[0,0])/5]

attr_credit_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="CR_DATE"
attr_credit_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DATE")
attr_credit_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="80"
attr_credit_col$[1,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="D"
attr_credit_col$[1,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
attr_credit_col$[1,fnstr_pos("MSKI",attr_def_col_str$[0,0],5)]=stbl("+DATE_MASK")

attr_credit_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="CUST_NO"
attr_credit_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_CUSTOMER")
attr_credit_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
attr_credit_col$[2,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=str(callpoint!.getDevObject("custmask"))

attr_credit_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="CUST_NAME"
attr_credit_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_NAME")
attr_credit_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="250"

attr_credit_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ORDER"
attr_credit_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ORDER")
attr_credit_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"

attr_credit_col$[5,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="ORD_DATE"
attr_credit_col$[5,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ORDER_DATE")
attr_credit_col$[5,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="80"
attr_credit_col$[5,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="D"
attr_credit_col$[5,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
attr_credit_col$[5,fnstr_pos("MSKI",attr_def_col_str$[0,0],5)]=stbl("+DATE_MASK")

attr_credit_col$[6,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SHIP_DATE"
attr_credit_col$[6,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_SHIP_DATE")
attr_credit_col$[6,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="80"
attr_credit_col$[6,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="D"
attr_credit_col$[6,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
attr_credit_col$[6,fnstr_pos("MSKI",attr_def_col_str$[0,0],5)]=stbl("+DATE_MASK")

for curr_attr=1 to def_credit_cols

	attr_credit_col$[0,1]=attr_credit_col$[0,1]+pad("CREDREV."+attr_credit_col$[curr_attr,
:	fnstr_pos("DVAR",attr_def_col_str$[0,0],5)],40)

next curr_attr

attr_disp_col$=attr_credit_col$[0,1]

call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridCredit!,"COLH-LINES-LIGHT-AUTO-SIZEC-DATES",num_rpts_rows,
:	attr_def_col_str$[all],attr_disp_col$,attr_credit_col$[all]

return

fill_grid:

	SysGUI!.setRepaintEnabled(0)
	gridCredit!=UserObj!.getItem(num(user_tpl.gridCreditOffset$))
	minrows=num(user_tpl.gridCreditRows$)
	if vectCredit!.size()

		numrow=vectCredit!.size()/gridCredit!.getNumColumns()
		gridCredit!.clearMainGrid()
		gridCredit!.setNumRows(numrow)
		gridCredit!.setCellText(0,0,vectCredit!)
		gridCredit!.resort()
	else
		gridCredit!.clearMainGrid()
		gridCredit!.setNumRows(0)
	endif
	SysGUI!.setRepaintEnabled(1)
return

rem ==========================================================================
create_orders_vector:
rem ==========================================================================

	vectCredit! = BBjAPI().makeVector()

	ope03_dev = fnget_dev("OPE_CREDDATE")
	dim ope03a$:fnget_tpl$("OPE_CREDDATE")
	ope01_dev = fnget_dev("OPE_ORDHDR")
	dim ope01a$:fnget_tpl$("OPE_ORDHDR")
	arm01_dev = fnget_dev("ARM_CUSTMAST")
	dim arm01a$:fnget_tpl$("ARM_CUSTMAST")

	more=1
	read (ope03_dev,key=firm_id$,dom=*next)
	rows=0

	while more
		read record (ope03_dev, end=*break) ope03a$
		if pos(firm_id$=ope03a$)<>1 then break
		read record (ope01_dev, key=firm_id$+"  "+ope03a.customer_id$+ope03a.order_no$, dom=*continue) ope01a$

		dim arm01a$:fattr(arm01a$)
		read record (arm01_dev, key=firm_id$+ope01a.customer_id$, dom=*next) arm01a$

	rem --- now fill grid

		vectCredit!.addItem(date(jul(ope03a.rev_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		vectCredit!.addItem(ope03a.customer_id$)
		vectCredit!.addItem(arm01a.customer_name$)
		vectCredit!.addItem(ope03a.order_no$)
		vectCredit!.addItem(date(jul(ope01a.order_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		vectCredit!.addItem(date(jul(ope01a.shipmnt_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		rows=rows+1
	wend

	callpoint!.setStatus("REFRESH")

return

create_cust_vector:

	vectCredit!=SysGUI!.makeVector()

	ope03_dev=fnget_dev("OPE_CREDDATE")
	dim ope03a$:fnget_tpl$("OPE_CREDDATE")
	arm01_dev=fnget_dev("ARM_CUSTMAST")
	dim arm01a$:fnget_tpl$("ARM_CUSTMAST")
	more=1
	read (ope03_dev,key=firm_id$,dom=*next)
	rows=0

	while more
		readrecord (ope03_dev,end=*break)ope03a$
		if pos(firm_id$=ope03a$)<>1 then break
		if cvs(ope03a.order_no$,2)<>"" continue
		dim arm01a$:fattr(arm01a$)
		readrecord(arm01_dev,key=firm_id$+ope03a.customer_id$,dom=*next)arm01a$
rem --- now fill grid
		vectCredit!.addItem(date(jul(ope03a.rev_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		vectCredit!.addItem(ope03a.customer_id$)
		vectCredit!.addItem(arm01a.customer_name$)
		vectCredit!.addItem("")
		vectCredit!.addItem("")
		vectCredit!.addItem("")
		rows=rows+1
	wend
	callpoint!.setStatus("REFRESH")
return

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

#include std_missing_params.src
[[OPE_CREDREV.AWIN]]
rem --- Build custom form
	use ::ado_util.src::util

	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="ARS_CREDIT",open_opts$[1]="OTA"
	open_tables$[2]="OPE_CREDDATE",open_opts$[2]="OTA"
	open_tables$[3]="OPE_ORDHDR",open_opts$[3]="OTA"
	open_tables$[4]="ARM_CUSTMAST",open_opts$[4]="OTA"
	open_tables$[5]="ARM_CUSTDET",open_opts$[5]="OTA"

	gosub open_tables

	ars01c_dev=num(open_chans$[1]),ars01c_tpl$=open_tpls$[1]
	ope03_dev=num(open_chans$[2]),ope03_tpl$=open_tpls$[2]
	ope01_dev=num(open_chans$[3]),ope01_tpl$=open_tpls$[3]
	arm01_dev=num(open_chans$[4]),arm01_tpl$=open_tpls$[4]
	arm02_dev=num(open_chans$[5]),arm02_tpl$=open_tpls$[5]

rem --- Dimension string templates

	dim ars01c$:ars01c_tpl$

rem --- Check Parameters

	read record (ars01c_dev,key=firm_id$+"AR01",dom=std_missing_params)ars01c$
	if ars01c.sys_install$<>"Y" release

rem --- get customer mask

	call stbl("+DIR_PGM")+"adc_getmask.aon","CUSTOMER_ID","","","",m0$,0,cust_len
	callpoint!.setDevObject("custmask",m0$)

rem --- add grid to store credit holds, with checkboxes for user to select one only

	user_tpl_str$="gridCreditOffset:c(5),gridCreditCols:c(5),gridCreditRows:c(5),gridCreditCtlID:c(5)," +
:		"vectCreditOffset:c(5),cur_sel:c(1)"
	dim user_tpl$:user_tpl_str$

	UserObj!=SysGUI!.makeVector()
	nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))

	gridCredit!=Form!.addGrid(nxt_ctlID,5,40,800,400)
	user_tpl.gridCreditCtlID$=str(nxt_ctlID)
	user_tpl.gridCreditCols$="6"
	user_tpl.gridCreditRows$="10"
	user_tpl.gridCreditOffset$="0"
	user_tpl.vectCreditOffset$="1"
	user_tpl.cur_sel$="O"

	gosub format_grid
	util.resizeWindow(Form!, SysGui!)

	UserObj!.addItem(gridCredit!)
	UserObj!.addItem(vectCredit!);rem vector of filtered recs from Credit recs

rem --- misc other init
	gridCredit!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)
	gridCredit!.setTabAction(gridCredit!.GRID_NAVIGATE_GRID)

	gosub create_orders_vector
	gosub fill_grid

rem --- set callbacks - processed in ACUS callpoint
	gridCredit!.setCallback(gridCredit!.ON_GRID_DOUBLE_CLICK,"custom_event")
	gridCredit!.setCallback(gridCredit!.ON_GRID_ENTER_KEY,"custom_event")

rem --- verify New Tickler is disabled and Cred Maint enabled
	callpoint!.setOptionEnabled("NEWC",0)
	callpoint!.setOptionEnabled("CRED",1)
