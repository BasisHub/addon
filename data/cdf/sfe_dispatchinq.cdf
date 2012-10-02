[[SFE_DISPATCHINQ.WO_STATUS.AVAL]]
rem --- Populate grid

	op_code$=callpoint!.getColumnData("SFE_DISPATCHINQ.OP_CODE")
	status$=callpoint!.getUserInput()
	pri_code$=callpoint!.getColumnData("SFE_DISPATCHINQ.PRIORITY")
	begdate$=callpoint!.getColumnData("SFE_DISPATCHINQ.DATE_OPENED_1")
	enddate$=callpoint!.getColumnData("SFE_DISPATCHINQ.DATE_OPENED_2")

	gosub create_reports_vector
	gosub fill_grid
[[SFE_DISPATCHINQ.PRIORITY.AVAL]]
rem --- Populate grid

	op_code$=callpoint!.getColumnData("SFE_DISPATCHINQ.OP_CODE")
	status$=callpoint!.getColumnData("SFE_DISPATCHINQ.WO_STATUS")
	pri_code$=callpoint!.getUserInput()
	begdate$=callpoint!.getColumnData("SFE_DISPATCHINQ.DATE_OPENED_1")
	enddate$=callpoint!.getColumnData("SFE_DISPATCHINQ.DATE_OPENED_2")

	gosub create_reports_vector
	gosub fill_grid
[[SFE_DISPATCHINQ.DATE_OPENED.AVAL]]
rem --- Populate grid

	op_code$=callpoint!.getColumnData("SFE_DISPATCHINQ.OP_CODE")
	status$=callpoint!.getColumnData("SFE_DISPATCHINQ.WO_STATUS")
	pri_code$=callpoint!.getColumnData("SFE_DISPATCHINQ.PRIORITY")
	v$ = callpoint!.getVariableName()
	attr_ctli = num(callpoint!.getTableColumnAttribute(v$ + "_1", "CTLI"))
	ctl_id = num(callpoint!.getControlID())
	if ctl_id = attr_ctli then
		rem --- From control
		begdate$=callpoint!.getUserInput()
		enddate$=callpoint!.getColumnData("SFE_DISPATCHINQ.DATE_OPENED_2")
	else
		rem --- To control
		begdate$=callpoint!.getColumnData("SFE_DISPATCHINQ.DATE_OPENED_1")
		enddate$=callpoint!.getUserInput()
	endif

	gosub create_reports_vector
	gosub fill_grid
[[SFE_DISPATCHINQ.OP_CODE.AVAL]]
rem --- Get Queue Time and Pieces per Hour

	opcode=callpoint!.getDevObject("opcode_chan")
	dim opcode$:callpoint!.getDevObject("opcode_tpl")

	read record (opcode,key=firm_id$+callpoint!.getUserInput(),dom=*next) opcode$
	callpoint!.setColumnData("<<DISPLAY>>.PCS_PER_HOUR",str(opcode.pcs_per_hour),1)
	callpoint!.setColumnData("<<DISPLAY>>.QUEUE_TIME",str(opcode.queue_time),1)

	op_code$=callpoint!.getUserInput()
	status$=callpoint!.getColumnData("SFE_DISPATCHINQ.WO_STATUS")
	pri_code$=callpoint!.getColumnData("SFE_DISPATCHINQ.PRIORITY")
	begdate$=callpoint!.getColumnData("SFE_DISPATCHINQ.DATE_OPENED_1")
	enddate$=callpoint!.getColumnData("SFE_DISPATCHINQ.DATE_OPENED_2")

	gosub create_reports_vector
	gosub fill_grid
[[SFE_DISPATCHINQ.AWIN]]
rem --- Open/Lock files

	use ::ado_util.src::util

	num_files=8
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="SFE_WOMASTR",open_opts$[1]="OTA"
	open_tables$[2]="SFE_WOOPRTN",open_opts$[2]="OTA"
	open_tables$[3]="SFE_WOSCHDL",open_opts$[3]="OTA"
	open_tables$[4]="SFM_OPCALNDR",open_opts$[4]="OTA"
	open_tables$[5]="SFT_OPNOPRTR",open_opts$[5]="OTA"
	open_tables$[6]="SFS_PARAMS",open_opts$[6]="OTA"
	open_tables$[7]="IVM_ITEMMAST",open_opts$[7]="OTA"
	open_tables$[8]="SFE_WOOPRTN",open_opts$[8]="OTAN"

	gosub open_tables

	sfe01_dev=num(open_chans$[1]),sfe01_tpl$=open_tpls$[1]
	sfe02_dev=num(open_chans$[2]),sfe02_tpl$=open_tpls$[2]
	sfm05_dev=num(open_chans$[3]),sfm05_tpl$=open_tpls$[3]
	sfm04_dev=num(open_chans$[4]),sfm04_tpl$=open_tpls$[4]
	sft01_dev=num(open_chans$[5]),sft01_tpl$=open_tpls$[5]
	sfs_params=num(open_chans$[6]),sfs_params_tpl$=open_tpls$[6]
	ivm01_dev=num(open_chans$[7])
	callpoint!.setDevObject("sfe02_dev2",num(open_chans$[8]))

rem --- Dimension string templates

	dim sfe01a$:sfe01_tpl$,sfe02a$:sfe02_tpl$,sfm05a$:sfm05_tpl$
	dim sfm04a$:sfm04_tpl$,sft01a$:sft01_tpl$,sfs_params$:sfs_params_tpl$

rem --- Get parameter record

	readrecord(sfs_params,key=firm_id$+"SF00",dom=std_missing_params)sfs_params$
	bm$=sfs_params.bm_interface$

rem --- Figure out which Op Code Maintenance file to open
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	if bm$<>"Y"
		call stbl("+DIR_PGM")+"adc_application.aon","BM",info$[all]
		bm$=info$[20]
		open_tables$[1]="SFC_OPRTNCOD",open_opts$[1]="OTA"
	else
		open_tables$[1]="BMC_OPCODES",open_opts$[1]="OTA"
	endif
	callpoint!.setDevObject("bm",bm$)
	x$=stbl("bm",bm$)

	gosub open_tables

	callpoint!.setDevObject("opcode_chan",num(open_chans$[1]))
	callpoint!.setDevObject("opcode_tpl",open_tpls$[1])

rem --- Add grid to show Dispatch records

	user_tpl_str$ = "gridDispatchOffset:c(5), " +
:		"gridDispatchCols:c(5), " +
:		"gridDispatchRows:c(5), " +
:		"gridDispatchCtlID:c(5)," +
:		"vectDispatchOffset:c(5)"
	dim user_tpl$:user_tpl_str$

	UserObj! = BBjAPI().makeVector()
	vectDispatch! = BBjAPI().makeVector()
	nxt_ctlID = util.getNextControlID()

	gridDispatch! = Form!.addGrid(nxt_ctlID,5,140,800,300); rem --- ID, x, y, width, height

	user_tpl.gridDispatchCtlID$ = str(nxt_ctlID)
	user_tpl.gridDispatchCols$ = "10"
	user_tpl.gridDispatchRows$ = "14"

	gosub format_grid
	util.resizeWindow(Form!, SysGui!)

	UserObj!.addItem(gridDispatch!)
	user_tpl.gridDispatchOffset$="0"

	UserObj!.addItem(vectDispatch!); rem --- vector of filtered recs
	user_tpl.vectDispatchOffset$="1"

rem --- Set mask for tracking

	callpoint!.setDevObject("umask","-#####0.000")
[[SFE_DISPATCHINQ.<CUSTOM>]]
rem ==========================================================================
format_grid: rem --- Use Barista program to format the grid
rem ==========================================================================

	call stbl("+DIR_PGM")+"adc_getmask.aon","","SF","H","",m1$,0,0

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0] = callpoint!.getColumnAttributeTypes()
	def_inv_cols = num(user_tpl.gridDispatchCols$)
	num_rpts_rows = num(user_tpl.gridDispatchRows$)
	dim attr_inv_col$[def_inv_cols,len(attr_def_col_str$[0,0])/5]

	attr_inv_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DATE_REQ"
	attr_inv_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DATE_REQ'D")
	attr_inv_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"

	attr_inv_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="PRI_CODE"
	attr_inv_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_PRIORITY")
	attr_inv_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="10"

	attr_inv_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="WO_STAT"
	attr_inv_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_WO_STATUS")
	attr_inv_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="10"

	attr_inv_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="WO_NO"
	attr_inv_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_WORK_ORDER")
	attr_inv_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="30"

	attr_inv_col$[5,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DESC"
	attr_inv_col$[5,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DESCRIPTION")
	attr_inv_col$[5,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="150"

	attr_inv_col$[6,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="AT_OP"
	attr_inv_col$[6,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_AT_OP")
	attr_inv_col$[6,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="10"

	attr_inv_col$[7,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="FROM_OP"
	attr_inv_col$[7,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_FROM_OP")
	attr_inv_col$[7,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="10"

	attr_inv_col$[8,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SETUP_TIME"
	attr_inv_col$[8,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_SETUP")+" "+Translate!.getTranslation("AON_TIME")
	attr_inv_col$[8,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[8,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	attr_inv_col$[8,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_inv_col$[9,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="RUN_TIME"
	attr_inv_col$[9,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_RUN")+" "+Translate!.getTranslation("AON_TIME")
	attr_inv_col$[9,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[9,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	attr_inv_col$[9,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	attr_inv_col$[10,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="MOVE_TIME"
	attr_inv_col$[10,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_MOVE")+" "+Translate!.getTranslation("AON_TIME")
	attr_inv_col$[10,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[10,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	attr_inv_col$[10,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	for curr_attr=1 to def_inv_cols
		attr_inv_col$[0,1] = attr_inv_col$[0,1] + 
:			pad("SFE_DISPATCH." + attr_inv_col$[curr_attr, fnstr_pos("DVAR", attr_def_col_str$[0,0], 5)], 40)
	next curr_attr

	attr_disp_col$=attr_inv_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridDispatch!,"AUTO-COLH-LINES-LIGHT-DATES-MULTI",num_rpts_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_inv_col$[all]

	return

rem ==========================================================================
fill_grid: rem --- Fill the grid with data in vectDispatch!
rem op_code$:		input
rem ==========================================================================

	if cvs(op_code$,3)="" return

	SysGUI!.setRepaintEnabled(0)
	gridDispatch! = UserObj!.getItem(num(user_tpl.gridDispatchOffset$))
	minrows = num(user_tpl.gridDispatchRows$)
	vectDispatch!=UserObj!.getItem(num(user_tpl.vectDispatchOffset$))

	if vectDispatch!.size() then
		numrow = vectDispatch!.size() / gridDispatch!.getNumColumns()
		gridDispatch!.clearMainGrid()
		gridDispatch!.setNumRows(numrow)
		gridDispatch!.setCellText(0,0,vectDispatch!)
	else
		gridDispatch!.clearMainGrid()
		gridDispatch!.setNumRows(0)
	endif

	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
create_reports_vector: rem --- Create a vector from the file to fill the grid
rem op_code$:		input
rem status$:		input
rem pri_code$:		input
rem begdate$:		input
rem enddate$:		input
rem ==========================================================================

	if cvs(op_code$,3)="" return

	vectDispatch!=UserObj!.getItem(num(user_tpl.vectDispatchOffset$))
	vectDispatch!.clear()

	sfe02_dev=fnget_dev("SFE_WOOPRTN")
	dim sfe02a$:fnget_tpl$("SFE_WOOPRTN")
	sft01_dev=fnget_dev("SFT_OPNOPRTR")
	dim sft01a$:fnget_tpl$("SFT_OPNOPRTR")
	sfm05_dev=fnget_dev("SFE_WOSCHDL")
	dim sfm05a$:fnget_tpl$("SFE_WOSCHDL")
	sfe01_dev=fnget_dev("SFE_WOMASTR")
	dim sfe01a$:fnget_tpl$("SFE_WOMASTR")
	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")
	sft01_dev=fnget_dev("SFT_OPNOPRTR")
	dim sft01a$:fnget_tpl$("SFT_OPNOPRTR")

rem --- Get lengths

	tmp_field$=fattr(sft01a$,"OPER_SEQ_REF")
	op_seq_len=dec(tmp_field$(10,2))
	tmp_field$=fattr(sft01a$,"OP_CODE")
	op_cod_len=dec(tmp_field$(10,2))
	tmp_field$=fattr(sft01a$,"WO_NO")
	wo_len=dec(tmp_field$(10,2))

	call stbl("+DIR_PGM")+"adc_getmask.aon","","SF","H","",m1$,0,0
	more=1
	read (sfe02_dev,key=firm_id$+sfe02a.wo_location$+op_code$,knum="AO_LOC_CD_DT_WO",dom=*next)
	rows=0

	while more
		read record (sfe02_dev, end=*break) sfe02a$
		if pos(firm_id$+sfe02a.wo_location$=sfe02a$)<>1 then break
		if sfe02a.op_code$<>op_code$ break

		read(sft01_dev,key=firm_id$+sfe02a.wo_location$+sfe02a.wo_no$,knum="PRIMARY",dom=*next)
		while 1
			read record (sft01_dev,end=*break) sft01a$
			if pos(firm_id$+sfe02a.wo_location$+sfe02a.wo_no$=sft01a$)<>1 break
			if sft01a.op_code$<>op_code$ continue
			units=units+sft01a.units
			setup=setup+sft01a.setup_time
		wend

rem --- Done with this Work Order

		if units=0 and setup=0 continue
		wostr$=wostr$+sfe02a.wo_no$+str(units:callpoint!.getDevObject("umask"))+str(setup:callpoint!.getDevObject("umask"))
		units=0
		setup=0
	wend

rem --- Position Schedul Detail file
	totset=0
	totrun=0
	dim sfe01a$:fattr(sfe01a$)
	read (sfm05_dev,key=firm_id$+op_code$,dom=*next)
	while 1
		runtime=0
		setup=0
		movetime=0
		read record (sfm05_dev,end=*break) sfm05a$
		if pos(firm_id$+op_code$=sfm05a$)<>1 break
		thisseq$=sfm05a.oper_seq_ref$
		this_wo$=sfm05a.wo_no$

rem --- Retrieve sfe-02 operations record

		dim sfe02a$:fattr(sfe02a$)
		read record (sfe02_dev,key=firm_id$+sfe02a.wo_location$+sfm05a.wo_no$+sfm05a.oper_seq_ref$,knum="AO_OP_SEQ",dom=*continue)sfe02a$
		this_code$=sfe02a.op_code$

rem --- Work order still open?

		if sfe02a.wo_no$<>sfe01a.wo_no$
			movetime=0
			find record(sfe01_dev,key=firm_id$+sfe02a.wo_location$+sfe02a.wo_no$,dom=*continue) sfe01a$
		endif
		if sfe01a.wo_status$="C" continue
		if status$="A" goto include_it
		if sfe01a.wo_status$="P" and pos("P"=status$)>0 goto include_it
		if sfe01a.wo_status$="Q" and pos("Q"=status$)>0 goto include_it
		if sfe01a.wo_status$="O" and pos("O"=status$)>0 goto include_it
		continue

include_it:

		desc$=cvs(ivm01a.item_desc$,2)
		if sfe01a.wo_category$="I" desc$=cvs(sfe01a.item_id$,2)+" "+desc$
		movetime=sfm05a.move_time

rem --- Shall we print it?

		gosub calc_actual
		gosub calc_remaining

		if runtime=0 and setup=0 and movetime=0 continue
		if sfe01a.priority$>pri_code$ continue
		if cvs(begdate$,2)<>"" if sfm05a.sched_date$<begdate$ continue
		if cvs(enddate$,2)<>"" if sfm05a.sched_date$>enddate$ continue
		v3=0
rem --- Add to vector
		vectDispatch!.addItem(fndate$(sfm05a.sched_date$))
		vectDispatch!.addItem(sfe01a.priority$)
		vectDispatch!.addItem(sfe01a.wo_status$)
		vectDispatch!.addItem(sfe01a.wo_no$)
		vectDispatch!.addItem(desc$)
		vectDispatch!.addItem(at$)
		vectDispatch!.addItem(from$)
		vectDispatch!.addItem(str(setup))
		vectDispatch!.addItem(str(runtime))
		vectDispatch!.addItem(str(movetime))

		totset=totset+setup
		totrun=totrun+runtime

	wend

	callpoint!.setColumnData("<<DISPLAY>>.RUNTIME_HRS",str(totrun),1)
	callpoint!.setColumnData("<<DISPLAY>>.SETUP_TIME",str(totset),1)
	vectDispatch!=UserObj!.setItem(num(user_tpl.vectDispatchOffset$),vectDispatch!)
	
	return

rem ==========================================================================
calc_actual:
rem ==========================================================================

rem --- Initialize WO ---
	opnmax=999
	dim runtim[opnmax],setup[opnmax],actrun[opnmax],actset[opnmax]
	opnseq$=""
	opncod$=""
	x0=0
	now=0
	at$=""
	from$=""
	setup=0
	runtime=0
	sfe02_dev2=callpoint!.getDevObject("sfe02_dev2")
	dim sfe02b$:fattr(sfe02a$)
	read (sfe02_dev2,key=firm_id$+sfe01a.wo_location$+sfe01a.wo_no$,dom=*next)

	while 1
		read record (sfe02_dev2,end=*break) sfe02b$
		if pos(firm_id$+sfe01a.wo_location$+sfe01a.wo_no$=sfe02b$)<>1 break
		if sfe02b.line_type$<>"S" continue
		opnseq$=opnseq$+sfe02b.internal_seq_no$
		opncod$=opncod$+sfe02b.op_code$
		runtim[x0]=sfm05a.runtime_hrs
		setup[x0]=sfm05a.setup_time
		x0=x0+1
	wend

rem --- Calculate Actual

	read (sft01_dev,key=firm_id$+sfe01a.wo_location$+sfe01a.wo_no$,knum="PRIMARY",dom=*next)
	while 1
		readrecord (sft01_dev,end=*break) sft01a$
		if pos(firm_id$+sfe01a.wo_location$+sfe01a.wo_no$=sft01a$)<>1 break
		seq$=sft01a.oper_seq_ref$
		cod$=sft01a.op_code$
get_indx:
		indx=pos(seq$=opnseq$,op_seq_len)
		if indx=0 
			opnseq$=opnseq$+seq$
			opncod$=opncod$+cod$
			goto get_indx
		endif
		indx=int(indx/op_seq_len)
		actset[indx]=actset[indx]+sft01a.setup_time
		actrun[indx]=actrun[indx]+sft01a.units
		if now<indx now=indx
	wend

rem --- This operation?

	at$=opncod$(now*op_cod_len+1,op_cod_len)
	thisindx=pos(thisseq$=opnseq$,op_seq_len)
	if thisindx<>0
		thisindx=int(thisindx/op_seq_len)
		xfrom=thisindx-1
		if xfrom<0 xfrom=0
		from$=opncod$(xfrom*op_cod_len+1,op_cod_len)
		runtime=runtim[thisindx]
		setup=setup[thisindx]
	endif

	return

rem ==========================================================================
calc_remaining:
rem ==========================================================================

rem --- Calculate Remaining Units

	umask$=callpoint!.getDevObject("umask")
	umask=len(umask$)

	unitrun=0
	unitset=0
	wopos=pos(sfe01a.wo_no$=wostr$,wo_len+(umask*2))
	if wopos<>0
		unitrun=num(wostr$(wopos+wo_len,umask))
		unitset=num(wostr$(wopos+wo_len+umask,umask))
		runtime=runtime-unitrun
		setup=setup-unitset
		if runtime>=0
			wostr$(wopos+wo_len,umask)=str(0:umask$)
		else
			unitrun=-runtime
			wostr$(wopos+wo_len,umask)=str(unitrun:umask$)
			runtime=0
		endif
		if setup>=0
			wostr$(wopos+wo_len+umask,umask)=str(0:umask$)
		else
			unitset=-unitset
			wostr$(wopos+wo_len+umask,umask)=str(unitset:umask$)
			setup=0
		endif
	endif
	return

rem ==========================================================================
#include std_missing_params.src
rem ==========================================================================
[[SFE_DISPATCHINQ.ASIZ]]
rem --- Resize the grid

	if UserObj!<>null() then
		gridDispatch!=UserObj!.getItem(num(user_tpl.gridDispatchOffset$))
		gridDispatch!.setSize(Form!.getWidth()-(gridDispatch!.getX()*2),Form!.getHeight()-(gridDispatch!.getY()+10))
		gridDispatch!.setFitToGrid(1)
	endif
