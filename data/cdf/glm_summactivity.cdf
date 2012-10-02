[[GLM_SUMMACTIVITY.AWIN]]
rem print 'show'

rem --- init...open tables, define custom grid, etc.
use ::ado_util.src::util
num_files=3
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
open_tables$[2]="GLM_ACCTSUMMARY",open_opts$[2]="OTA"
open_tables$[3]="GLM_RECORDTYPES",open_opts$[3]="OTA"
gosub open_tables

gls01_dev=num(open_chans$[1])
glm18_dev=num(open_chans$[3])

dim gls01a$:open_tpls$[1]
dim glm18a$:open_tpls$[3]

readrecord(gls01_dev,key=firm_id$+"GL00",dom=std_missing_params)gls01a$

call stbl("+DIR_PGM")+"adc_getmask.aon","","GL","A","",m1$,0,0

rem --- load up period abbr names from gls_params
num_pers=num(gls01a.total_pers$)
per_names!=SysGUI!.makeVector()
for x=1 to num_pers
	per_names!.addItem(field(gls01a$,"ABBR_NAME_"+str(x:"00")))
next x

rem ---  load up budget column codes and types from gls_params
cols!=SysGUI!.makeVector()
tps!=SysGUI!.makeVector()
for x=1 to 4
	cols!.addItem(field(gls01a$,"acct_mn_cols_"+str(x:"00")))
	tps!.addItem(field(gls01a$,"acct_mn_type_"+str(x:"00")))
next x
			
rem ---  create list for column zero of grid -- column type drop-down
more=1
codeList!=SysGUI!.makeVector()
codes!=SysGUI!.makeVector()
read(glm18_dev,key="",dom=*next)
while more
	readrecord(glm18_dev,end=*break)glm18a$
	codeList!.addItem(glm18a.rev_title$+"("+glm18a.record_id$+glm18a.amt_or_units$+")")
	codes!.addItem(glm18a.record_id$+glm18a.amt_or_units$)
wend

rem ---  set up grid
nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))
gridActivity!=Form!.addGrid(nxt_ctlID,5,100,1000,100)
gridActivity!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)
gridActivity!.setSelectionMode(gridActivity!.GRID_SELECT_CELL)
gridActivity!.setSelectedRow(0)
gridActivity!.setSelectedColumn(0)

gridActivity!.setCallback(gridActivity!.ON_GRID_EDIT_START,"custom_event")
gridActivity!.setCallback(gridActivity!.ON_GRID_EDIT_STOP,"custom_event")

rem ---  store desired data (mostly offsets of items in UserObj) in user_tpl
tpl_str$="pers:c(5),pers_ofst:c(5),codes_ofst:c(5),codeList_ofst:c(5),grid_ctlID:c(5),grid_ofst:c(5),"+
:		  "cols_ofst:c(5),tps_ofst:c(5),amt_mask:c(15),sv_record_tp:c(30*),vectActivity_ofst:c(5)"

dim user_tpl$:tpl_str$

user_tpl.pers$=str(num_pers)
user_tpl.pers_ofst$="0"
user_tpl.codes_ofst$="1"
user_tpl.codeList_ofst$="2"
user_tpl.grid_ctlID$=str(nxt_ctlID)
user_tpl.grid_ofst$="3"
user_tpl.cols_ofst$="4"
user_tpl.tps_ofst$="5"
user_tpl.vectActivity_ofst$="6"
user_tpl.amt_mask$=m1$

rem ---  store desired vectors/objects in UserObj!
UserObj!=SysGUI!.makeVector()

UserObj!.addItem(per_names!)
UserObj!.addItem(codes!)
UserObj!.addItem(codeList!)
UserObj!.addItem(gridActivity!)
UserObj!.addItem(cols!)
UserObj!.addItem(tps!)
userobj!.addItem(SysGUI!.makeVector());rem placeholder for vectActivity! that will be used to update glm-02

rem format the grid, and set first column to be a pull-down
gosub format_gridActivity
gosub set_column1_list
util.resizeWindow(Form!, SysGui!)
[[GLM_SUMMACTIVITY.AREC]]
rem compare budget columns/types from gls01 with 1st/3rd char of key of glm18
rem set the 4 listbuttons accordingly, and read/display corres glm02 data

cols!=UserObj!.getItem(num(user_tpl.cols_ofst$))
tps!=UserObj!.getItem(num(user_tpl.tps_ofst$))
codes!=UserObj!.getItem(num(user_tpl.codes_ofst$))
gridActivity!=UserObj!.getItem(num(user_tpl.grid_ofst$))
gridActivity!.clearMainGrid()

num_codes=codes!.size()
num_cols=cols!.size()

for x=0 to num_cols-1
	x1=0
	while x1<num_codes-1
		wcd$=codes!.getItem(x1)
		if cols!.getItem(x)=wcd$(1,1) and tps!.getItem(x)=wcd$(2,1)
			gridActivity!.setCellListSelection(x,0,x1,1)
			if pos(wcd$(1,1)="024",1)<>0
				gridActivity!.setRowEditable(x,0)
				gridActivity!.setCellEditable(x,0,1)
			endif
			break
		else
			x1=x1+1
		endif
	wend
	
next x

rem --- gl acct# has come in from main grid (glm_acct); get acct master, set acct tp and detail flag
rem --- then gosub fill_gridActivity, which reads corres. glm-02 recs and displays in the grid

glm01_dev=fnget_dev("GLM_ACCT")
dim glm01a$:fnget_tpl$("GLM_ACCT")

read record (glm01_dev,key=firm_id$+callpoint!.getColumnData("GLM_SUMMACTIVITY.GL_ACCOUNT"),dom=*next)glm01a$
if cvs(glm01a.gl_account$,3)<>""
	callpoint!.setColumnData("GLM_SUMMACTIVITY.GL_ACCT_TYPE",glm01a.gl_acct_type$)
	callpoint!.setColumnData("GLM_SUMMACTIVITY.DETAIL_FLAG",glm01a.detail_flag$)
	gosub fill_gridActivity
else
		callpoint!.setStatus("ABORT")
endif
[[GLM_SUMMACTIVITY.AOPT-REPL]]
gosub replicate_amt

if vectGLSummary!<>null()
	gosub update_glm_acctsummary
else
	callpoint!.setMessage("GL_REPLICATE")
	callpoint!.setStatus("ABORT")
endif
[[GLM_SUMMACTIVITY.ASIZ]]
if UserObj!<>null()
	gridActivity!=UserObj!.getItem(num(user_tpl.grid_ofst$))
	gridActivity!.setSize(Form!.getWidth()-(gridActivity!.getX()*2),Form!.getHeight()-(gridActivity!.getY()+40))
	gridActivity!.setFitToGrid(1)

endif
[[GLM_SUMMACTIVITY.ACUS]]
rem process custom event
rem see basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info
rem this routine is executed when callbacks have been set to run a "custom event"
rem analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind of event it is
			
dim gui_event$:tmpl(gui_dev)
dim notify_base$:noticetpl(0,0)
gui_event$=SysGUI!.getLastEventString()
ctl_ID=dec(gui_event.ID$)
if ctl_ID=num(user_tpl.grid_ctlID$)
	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
	endif

gridActivity!=UserObj!.getItem(num(user_tpl.grid_ofst$))
curr_row=dec(notice.row$)
curr_col=dec(notice.col$)

switch notice.code
	
	case 7;rem edit stop

		if curr_col=0
			record_type$=gridActivity!.getCellText(curr_row,curr_col)
			record_type$=record_type$(pos("("=record_type$,-1,1)+1,2)
			glm02_key$=firm_id$+callpoint!.getColumnData("GLM_SUMMACTIVITY.GL_ACCOUNT")+record_type$(1,1)
			col_type$=record_type$(2,1)
			x=curr_row
			gosub build_vectGLSummary
			gridActivity!.setCellText(curr_row,1,vectGLSummary!)
			if pos(record_type$(1,1)="024",1)<>0
				gridActivity!.setRowEditable(curr_row,0)
				gridActivity!.setCellEditable(curr_row,curr_col,1)
			else
				gridActivity!.setRowEditable(curr_row,1)
			endif
		else
			vectGLSummary!=SysGUI!.makeVector() 
			for x=1 to num(user_tpl.pers$)+1
				vectGLSummary!.addItem(gridActivity!.getCellText(curr_row,x))
			next x
			gosub calculate_end_bal
			gridActivity!.setCellText(curr_row,1,vectGLSummary!)
			gosub update_glm_acctsummary		
		endif
rem ---	gosub build_vectActivity
	break

	case 8;rem edit start
		if curr_col=0 then user_tpl.sv_record_tp$=gridActivity!.getCellText(curr_row,curr_col)
	break

swend

endif
[[GLM_SUMMACTIVITY.<CUSTOM>]]
update_glm_acctsummary:
rem ---  parse thru gridActivity! and write back any budget recs to glm-02

rec_id$=gridActivity!.getCellText(curr_row,0)
cols=vectGLSummary!.size()-2
if cols>0
	glm02_dev=fnget_dev("GLM_ACCTSUMMARY")
	dim glm02a$:fnget_tpl$("GLM_ACCTSUMMARY")
	glm02a.firm_id$=firm_id$
	glm02a.gl_account$=callpoint!.getColumnData("GLM_SUMMACTIVITY.GL_ACCOUNT")
	rec_id$=rec_id$(pos("("=rec_id$,-1,1)+1,2)
	amt_units$=rec_id$(2,1)
	glm02a.record_id$=rec_id$(1,1)

		switch pos(amt_units$="AU")
			case 1;rem amounts
				glm02a.begin_amt$=vectGLSummary!.getItem(0)
				for x=1 to cols
					field glm02a$,"PERIOD_AMT_"+str(x:"00")=vectGLSummary!.getItem(x)
				next x
			break

			case 2; rem units
				glm02a.begin_units$=vectGLSummary!.getCellText(0)
				for x=1 to cols
					field glm02a$,"PERIOD_UNITS_"+str(x:"00")=vectGLSummary!.getItem(x)
				next y
			break
		swend

	rem --- write glm-02

	glm02a$=field(glm02a$)
	writerecord(glm02_dev,key=glm02a.firm_id$+glm02a.gl_account$+glm02a.record_id$)glm02a$

endif

return

format_gridActivity:

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()
	def_grid_cols=num(user_tpl.pers$)+3
	num_rows=4;rem max 4 recs as defined in gls01 rec
	dim attr_grid_col$[def_grid_cols,len(attr_def_col_str$[0,0])/5]
	m1$=user_tpl.amt_mask$

	attr_grid_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="RECORD TP"
	attr_grid_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Record Type"
	attr_grid_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"

	attr_grid_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="BEGIN BAL"
	attr_grid_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Beginning"
	attr_grid_col$[2,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_grid_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="12"
	attr_grid_col$[2,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	nxt_col=3

	for x=0 to num(user_tpl.pers$)-1
		per_name!=UserObj!.getItem(num(user_tpl.pers_ofst$))
		attr_grid_col$[nxt_col+x,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="PER "+str(x+1)
		attr_grid_col$[nxt_col+x,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=per_name!.getItem(x)
		attr_grid_col$[nxt_col+x,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
		attr_grid_col$[nxt_col+x,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="12"
		attr_grid_col$[nxt_col+x,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$
	next x

	attr_grid_col$[nxt_col+x,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="END BAL"
	attr_grid_col$[nxt_col+x,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Ending"
	attr_grid_col$[nxt_col+x,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_grid_col$[nxt_col+x,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="12"
	attr_grid_col$[nxt_col+x,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$
	attr_grid_col$[nxt_col+x,fnstr_pos("OPTS",attr_def_col_str$[0,0],5)]="C"

	for curr_attr=1 to def_grid_cols

		attr_grid_col$[0,1]=attr_grid_col$[0,1]+pad("GLM_SUMMACTIVITY."+attr_grid_col$[curr_attr,
:			fnstr_pos("DVAR",attr_def_col_str$[0,0],5)],40)

	next curr_attr

	attr_disp_col$=attr_grid_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridActivity!,"DESC-COLH-ROWH-EDIT-LINES-LIGHT-HIGHO-CELL-SIZEC",num_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_grid_col$[all]

return

set_column1_list:
	rem create invisible listButton object with list=previously-built codeList! vector (description + code)
	rem set first column in grid to use the listButton to create drop-down

	tmpListCtl!=Form!.addListButton(nxt_ctlID+1,10,10,100,100,"",$0810$)
	codeList!=UserObj!.getItem(num(user_tpl.codeList_ofst$))
	tmpListCtl!.insertItems(0,codeList!)

	gridActivity!=UserObj!.getItem(num(user_tpl.grid_ofst$))
	gridActivity!.setColumnListControl(0,tmpListCtl!) 
return

fill_gridActivity:

	gridActivity!=UserObj!.getItem(num(user_tpl.grid_ofst$))
	cols!=UserObj!.getItem(num(user_tpl.cols_ofst$))
	tps!=UserObj!.getItem(num(user_tpl.tps_ofst$))
	num_cols=cols!.size()	
	gl_account$=callpoint!.getColumnData("GLM_SUMMACTIVITY.GL_ACCOUNT")

	for x=0 to num_cols-1
		glm02_key$=firm_id$+gl_account$+cols!.getItem(x)
		col_type$=tps!.getItem(x)
		gosub build_vectGLSummary
		gridActivity!.setCellText(x,1,vectGLSummary!)
	next x

	callpoint!.setStatus("REFRESH")

return

build_vectActivity:
rem -- this vector is refreshed from grid after an edit - used to drive glm-02 update in ASVA
	vectActivity!=SysGUI!.makeVector()
	gridActivity!=UserObj!.getItem(num(user_tpl.grid_ofst$))
	for x=0 to gridActivity!.getNumRows()-1
		for y=0 to gridActivity!.getNumColumns()-1
			vectActivity!.addItem(gridActivity!.getCellText(x,y))
		next y
	next x 
	UserObj!.setItem(num(user_tpl.vectActivity_ofst$),vectActivity!)

return

build_vectGLSummary:

	glm02_dev=fnget_dev("GLM_ACCTSUMMARY")
	glm02_tpl$=fnget_tpl$("GLM_ACCTSUMMARY")

	dim glm02a$:glm02_tpl$
	num_pers=num(user_tpl.pers$)
	vectGLSummary!=SysGUI!.makeVector()
	m1$=user_tpl.amt_mask$

	readrecord(glm02_dev,key=glm02_key$,dom=*next)glm02a$

	switch pos(col_type$="AU")
		case 1
			vectGLSummary!.addItem(str(num(glm02a.begin_amt$)))
			for x1=1 to num_pers
				vectGLSummary!.addItem(str(num(field(glm02a$,"PERIOD_AMT_"+str(x1:"00")))))
			next x1
			gosub calculate_end_bal			
		break
		case 2
			vectGLSummary!.addItem(glm02a.begin_units$)
			for x1=1 to num_pers
				vectGLSummary!.addItem(field(glm02a$,"PERIOD_UNITS_"+str(x1:"00")))
			next x1
			gosub calculate_end_bal
		break
		case default

		break
	swend
return

calculate_end_bal:
	end_bal=0
	wk=vectGLSummary!.size()
	if wk>0
		for x2=0 to wk-1
			end_bal=end_bal+num(vectGLSummary!.getItem(x2))
		next x2
		vectGLSummary!.addItem(str(end_bal))
	endif
return

replicate_amt:
	
	gridActivity!=UserObj!.getItem(num(user_tpl.grid_ofst$))
	curr_row=gridActivity!.getSelectedRow()
	if gridActivity!.isRowEditable(curr_row)
		curr_col=gridActivity!.getSelectedColumn()
		curr_amt$=gridActivity!.getCellText(curr_row,curr_col)
		vectGLSummary!=SysGUI!.makeVector()
		num_pers=num(user_tpl.pers$)

		for x=1 to num_pers+1
			if x>=curr_col
				vectGLSummary!.addItem(curr_amt$)
			else
				vectGLSummary!.addItem(gridActivity!.getCellText(curr_row,x))
			endif
			next x
			gosub calculate_end_bal
			gridActivity!.setCellText(curr_row,1,vectGLSummary!)
	endif
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


#include std_missing_params.src
