[[GLM_ACCTSUMHDR.ADIS]]
rem --- Must manually keep track if the grid has been modified so that changes will get saved
	callpoint!.setDevObject("gridModified","0")
[[GLM_ACCTSUMHDR.ASVA]]
rem --- Save changes to grid
	gridActivity!=UserObj!.getItem(num(user_tpl.grid_ofst$))
	numRows=gridActivity!.getNumRows()
	for curr_row=0 to numRows-1
		vectGLSummary!=SysGUI!.makeVector() 
		for x=1 to num(user_tpl.pers$)+1
			vectGLSummary!.addItem(gridActivity!.getCellText(curr_row,x))
		next x
		gosub update_glm_acctsummary
	next curr_row
[[<<DISPLAY>>.ALIGN_PERIODS.AMOD]]
rem --- Only need to SAVE record if gl_acct_desc, gl_acct_type or detail_flag changed

	gosub check_modified
[[<<DISPLAY>>.ALIGN_PERIODS.AVAL]]
rem --- Update grid data when leave checkbox and value has changed

	alignPeriods$=callpoint!.getUserInput()
	alignPeriods_before$=callpoint!.getColumnData("<<DISPLAY>>.ALIGN_PERIODS")
	if alignPeriods$<>alignPeriods_before$ then
		callpoint!.setDevObject("align_fiscal_periods",alignPeriods$)

		rem --- If aligning fiscal periods, need to update GLW_ACCTSUMMARY using
		rem --- transactions from GLT_TRANSDETAIL for non-aligned selected fiscal years.
		if alignPeriods$="Y" then
			cols!=UserObj!.getItem(num(user_tpl.cols_ofst$))
			recordType$=":"
			for i=0 to cols!.size()-1
				recordType$=recordType$+cols!.getItem(i)+":"
			next i
			alignCalendar! = callpoint!.getDevObject("alignCalendar")
			gls_cur_yr=num(callpoint!.getDevObject("gls_cur_yr"))
			if pos(":4:"=recordType$) then
				nextYear$=str(gls_cur_yr+1:"0000")
				align_next=alignCalendar!.canAlignCalendar(nextYear$)
				if align_next then
					Form!.setCursor(Form!.CURSOR_WAIT)
					nextTripKey$=alignCalendar!.alignCalendar(nextYear$)
					Form!.setCursor(Form!.CURSOR_NORMAL)
				endif
			endif
			for i=1 to user_tpl.years_to_display
				priorYear$=str(gls_cur_yr-i:"0000")
				align_prior=alignCalendar!.canAlignCalendar(priorYear$)
				if align_prior then
					Form!.setCursor(Form!.CURSOR_WAIT)
					priorTripKey$=alignCalendar!.alignCalendar(priorYear$)
					Form!.setCursor(Form!.CURSOR_NORMAL)
					if priorTripKey$="" then break
				endif
			next i
			rem --- Check tripKey$ in case of error
			if (align_prior and priorTripKey$="") or (align_next and nextTripKey$="") then
				msg_id$="GL_CANNOT_ALIGN_PERS"
				dim msg_tokens$[1]
				msg_tokens$[1]=callpoint!.getDevObject("gls_cur_yr")
				gosub disp_message
				callpoint!.setStatus("ABORT")
				break
			endif

			rem --- Update grid rows from not aligned to aligned
			gosub fill_gridActivity
		else
			rem --- Update grid rows from aligned to not aligned
			gosub fill_gridActivity
		endif
	endif
[[GLM_ACCTSUMHDR.BFST]]
rem --- Only need to SAVE record if gl_acct_desc, gl_acct_type or detail_flag changed

	gosub check_modified
[[GLM_ACCTSUMHDR.BLST]]
rem --- Only need to SAVE record if gl_acct_desc, gl_acct_type or detail_flag changed

	gosub check_modified
[[GLM_ACCTSUMHDR.BPRI]]
rem --- Only need to SAVE record if gl_acct_desc, gl_acct_type or detail_flag changed

	gosub check_modified
[[GLM_ACCTSUMHDR.BNEX]]
rem --- Only need to SAVE record if gl_acct_desc, gl_acct_type or detail_flag changed

	gosub check_modified
[[GLM_ACCTSUMHDR.GL_ACCOUNT.AVAL]]
rem "GL INACTIVE FEATURE"
   glm01_dev=fnget_dev("GLM_ACCT")
   glm01_tpl$=fnget_tpl$("GLM_ACCT")
   dim glm01a$:glm01_tpl$
   glacctinput$=callpoint!.getUserInput()
   glm01a_key$=firm_id$+glacctinput$
   find record (glm01_dev,key=glm01a_key$,err=*break) glm01a$
   if glm01a.acct_inactive$="Y" then
      call stbl("+DIR_PGM")+"adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,gl_size
      msg_id$="GL_ACCT_INACTIVE"
      dim msg_tokens$[2]
      msg_tokens$[1]=fnmask$(glm01a.gl_account$(1,gl_size),m0$)
      msg_tokens$[2]=cvs(glm01a.gl_acct_desc$,2)
      gosub disp_message
      callpoint!.setStatus("ACTIVATE")
   endif
[[GLM_ACCTSUMHDR.AOPT-DETL]]
rem --- Run the custom query to show details about the current cell

	gridActivity!=UserObj!.getItem(num(user_tpl.grid_ofst$))
	curr_row=gridActivity!.getSelectedRow()
	curr_col=gridActivity!.getSelectedColumn()

	record_type$=""
	cols!=UserObj!.getItem(num(user_tpl.cols_ofst$))
	if curr_row<cols!.size() then
		label$=gridActivity!.getCellText(curr_row,0)
		if label$<>"" then
			record_type$=label$(pos(" ("=label$,-1)+2)
			record_type$=record_type$(1,len(record_type$)-2)
		endif
	else
		extraRows!=callpoint!.getDevObject("extraRows")
		extraRow$=extraRows!.getItem(curr_row-cols!.size())
		thisYear$=extraRow$(1,pos(":"=extraRow$)-1)
		extra_row_type$=extraRow$(pos(":"=extraRow$)+1)
		if extra_row_type$(1,1)="A" then record_type$="A"
	endif

	if len(cvs(record_type$,2))=1 and pos(record_type$="024A") then
		if record_type$="A" then
			current_year=num(thisYear$)
		else
			current_year=num(callpoint!.getDevObject("gls_cur_yr"))
			if record_type$="2"
				current_year=current_year-1
			else
				if record_type$="4"
					current_year=current_year+1
				endif
			endif
			if callpoint!.getDevObject("gl_yr_closed") <> "Y"
				current_year=current_year+1
			endif
		endif
		posting_year$=str(current_year:"0000")
		posting_per$=str(curr_col-1:"00")

		if callpoint!.getDevObject("align_fiscal_periods")="Y" then
			fiscalYear=num(callpoint!.getDevObject("cur_year"))
			call stbl("+DIR_PGM")+"adc_perioddates.aon",num(posting_per$),fiscalYear,begdate$,enddate$,table_chans$[all],status
			delta=num(begdate$(1,4))-fiscalYear
			start_trns_date$=str(num(posting_year$)+delta:"0000")+begdate$(5)
			delta=num(enddate$(1,4))-fiscalYear
			end_trns_date$=str(num(posting_year$)+delta:"0000")+enddate$(5)
		endif

		dim filter_defs$[3,2]
		filter_defs$[0,0]="GLT_TRANSDETAIL.FIRM_ID"
		filter_defs$[0,1]="='"+firm_id$+"'"
		filter_defs$[0,2]="LOCK"
		filter_defs$[1,0]="GLT_TRANSDETAIL.GL_ACCOUNT"
		filter_defs$[1,1]="='"+callpoint!.getColumnData("GLM_ACCTSUMHDR.GL_ACCOUNT")+"'"
		filter_defs$[1,2]="LOCK"
		if callpoint!.getDevObject("align_fiscal_periods")<>"Y" then
			filter_defs$[2,0]="GLT_TRANSDETAIL.POSTING_YEAR"
			filter_defs$[2,1]="='"+posting_year$+"'"
			filter_defs$[2,2]="LOCK"
			filter_defs$[3,0]="GLT_TRANSDETAIL.POSTING_PER"
			filter_defs$[3,1]="='"+posting_per$+"'"
			filter_defs$[3,2]="LOCK"
		else
			filter_defs$[2,0]="GLT_TRANSDETAIL.TRNS_DATE"
			filter_defs$[2,1]=">='"+start_trns_date$+"' AND  GLT_TRANSDETAIL.TRNS_DATE<='"+end_trns_date$+"'"
			filter_defs$[2,2]="LOCK"
		endif

		call stbl("+DIR_SYP")+"bax_query.bbj",
:			gui_dev, form!,
:			"GL_AMOUNT_INQ",
:			"DEFAULT",
:			table_chans$[all],
:			sel_key$,
:			filter_defs$[all]
	endif
[[GLM_ACCTSUMHDR.ACUS]]
rem process custom event
rem see basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info
rem this routine is executed when callbacks have been set to run a 'custom event'
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

			gridActivity!=UserObj!.getItem(num(user_tpl.grid_ofst$))
			curr_row=dec(notice.row$)
			curr_col=dec(notice.col$)

			gls_calendar_dev=fnget_dev("GLS_CALENDAR")
			dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
			displayColumns!=callpoint!.getDevObject("displayColumns")

			rem --- Update grid if Edit mode has changed
			if user_tpl.curr_editMode$<>str(callpoint!.isEditMode()) then
				user_tpl.curr_editMode$=str(callpoint!.isEditMode())

				if callpoint!.isEditMode() then
					rem --- Only Budget rows are editable
					cols!=UserObj!.getItem(num(user_tpl.cols_ofst$))
					codes!=UserObj!.getItem(num(user_tpl.codes_ofst$))
					tps!=UserObj!.getItem(num(user_tpl.tps_ofst$))

					num_cols=cols!.size()
					num_codes=codes!.size()
					for x=0 to num_cols-1
						this_col$=cols!.getItem(x)
						this_tp$=tps!.getItem(x)
						x1=0
						while x1<num_codes-1
							wcd$=codes!.getItem(x1)
							col$=pad(wcd$(1,len(wcd$)-1),len(this_col$))
							tp$=wcd$(len(wcd$))
							if col$=this_col$ and tp$=this_tp$
								col$=cvs(col$,2)
								if len(col$)=1 and pos(col$="024") then
									gridActivity!.setRowEditable(x,0)
									gridActivity!.setCellEditable(x,0,1)
								else
									gridActivity!.setRowEditable(x,1)

									rem --- Disable periods not in this fiscal calendar
									thisYear$=displayColumns!.getYear(this_col$)
									findrecord(gls_calendar_dev,key=firm_id$+thisYear$,dom=*next)gls_calendar$
									if num(gls_calendar.total_pers$)<num(user_tpl.pers$) then
										for per=num(gls_calendar.total_pers$)+1 to num(user_tpl.pers$)
											gridActivity!.setCellEditable(x,per+1,0)
										next per
									endif
								endif
								break
							else
								x1=x1+1
							endif
						wend
					next x
				else
					gridActivity!.setEditable(0)
				endif
			endif

			switch notice.code

				case 7;rem edit stop
					if curr_col=0
						label$=gridActivity!.getCellText(curr_row,curr_col)
						record_type$=label$(pos(" ("=label$,-1)+2)
						record_type$=record_type$(1,len(record_type$)-2)
						amt_or_units$=label$(len(label$)-1,1)

						thisYear$=displayColumns!.getYear(record_type$)
						actbud$=displayColumns!.getActBud(record_type$)
						gl_account$=callpoint!.getColumnData("GLM_ACCTSUMHDR.GL_ACCOUNT")
						alignCalendar! = callpoint!.getDevObject("alignCalendar")
						if actbud$="P" then
							glm02_key$=firm_id$+gl_account$+record_type$
						else
							if actbud$="A" then
								glm02_key$=firm_id$+gl_account$+thisYear$
								if callpoint!.getDevObject("align_fiscal_periods")="Y" and alignCalendar!.canAlignCalendar(thisYear$) then
									rem --- Use GLW_ACCTSUMMARY when fiscal periods are aligned
									gls_cur_yr$=callpoint!.getDevObject("gls_cur_yr")
									glm02_key$=firm_id$+gl_account$+thisYear$+gls_cur_yr$
								endif
							else
								glm02_key$=firm_id$+gl_account$+thisYear$
							endif
						endif

						col_type$=amt_or_units$
						x=curr_row
						gosub build_vectGLSummary
						gridActivity!.setCellText(curr_row,1,vectGLSummary!)
						if len(cvs(record_type$,2))=1 and pos(record_type$="024")<>0
							gridActivity!.setRowEditable(curr_row,0)
							gridActivity!.setCellEditable(curr_row,curr_col,1)
						else
							gridActivity!.setRowEditable(curr_row,1)

							rem --- Disable periods not in this fiscal calendar
							findrecord(gls_calendar_dev,key=firm_id$+thisYear$,dom=*next)gls_calendar$
							if num(gls_calendar.total_pers$)<num(user_tpl.pers$) then
								for per=num(gls_calendar.total_pers$)+1 to num(user_tpl.pers$)
									gridActivity!.setCellEditable(curr_row,per+1,0)
								next per
							endif
						endif

						rem --- May need to update the list of records in the grid
						gridSelectionChanged=1
						cols!=UserObj!.getItem(num(user_tpl.cols_ofst$))
						if record_type$<>cols!.getItem(curr_row) then
							cols!.setItem(curr_row,record_type$)
							UserObj!.setItem(num(user_tpl.cols_ofst$),cols!)
							gridSelectionChanged=1
						endif
						tps!=UserObj!.getItem(num(user_tpl.tps_ofst$))
						if amt_or_units$<>tps!.getItem(curr_row) then
							tps!.setItem(curr_row,amt_or_units$)
							UserObj!.setItem(num(user_tpl.tps_ofst$),tps!)
							gridSelectionChanged=1
						endif
						rem --- May need to update the extra rows
						if gridSelectionChanged then
							rem --- Check if extra_row_types changed
							gosub identifyExtraRows
							if extra_row_types$<>callpoint!.getDevObject("extra_row_types") then
								callpoint!.setDevObject("extra_row_types",extra_row_types$)
								rem --- Get extra rows description
								gosub extraRowsDescriptions
								callpoint!.setDevObject("extraRows",extraRows!)
								rem --- Display extra rows
								gosub displayExtraRows
							endif
						endif
					else
						start_cell_text$=callpoint!.getDevObject("start_cell_text")
						end_cell_text$=gridActivity!.getCellText(curr_row,curr_col)
						if num(end_cell_text$)<>num(start_cell_text$) then
							callpoint!.setStatus("MODIFIED")
							vectGLSummary!=SysGUI!.makeVector() 
							for x=1 to num(user_tpl.pers$)+1
								vectGLSummary!.addItem(gridActivity!.getCellText(curr_row,x))
							next x
							gosub calculate_end_bal
							gridActivity!.setCellText(curr_row,1,vectGLSummary!)
							rem --- Must manually keep track if the grid has been modified so that changes will get saved
							callpoint!.setDevObject("gridModified","1")
						endif
					endif
				break

				case 8;rem edit start
					callpoint!.setDevObject("start_cell_text",gridActivity!.getCellText(curr_row,curr_col))
				break

				case 14;rem mouse up on a cell
					if curr_col=0 or curr_col=1 then
						callpoint!.setOptionEnabled("DETL",0)
					else
						record_type$=""
						cols!=UserObj!.getItem(num(user_tpl.cols_ofst$))
						if curr_row<cols!.size() then
							label$=gridActivity!.getCellText(curr_row,0)
							if label$<>"" then
								record_type$=label$(pos(" ("=label$,-1)+2)
								record_type$=record_type$(1,len(record_type$)-2)
								thisYear$=displayColumns!.getYear(record_type$)
							endif
						else
							extraRows!=callpoint!.getDevObject("extraRows")
							extraRow$=extraRows!.getItem(curr_row-cols!.size())
							thisYear$=extraRow$(1,pos(":"=extraRow$)-1)
							extra_row_type$=extraRow$(pos(":"=extraRow$)+1)
							if extra_row_type$(1,1)="A" then record_type$="A"
						endif
 						findrecord(gls_calendar_dev,key=firm_id$+thisYear$,dom=*next)gls_calendar$
						if len(cvs(record_type$,2))>1 or pos(record_type$="024A")=0 or curr_col>num(gls_calendar.total_pers$)+1 then
							callpoint!.setOptionEnabled("DETL",0)
						else
							callpoint!.setOptionEnabled("DETL",1)
						endif
					endif
				break

			swend
		endif
	endif
[[GLM_ACCTSUMHDR.ASIZ]]
	if UserObj!<>null()
		gridActivity!=UserObj!.getItem(num(user_tpl.grid_ofst$))
		gridActivity!.setSize(Form!.getWidth()-(gridActivity!.getX()*2),Form!.getHeight()-(gridActivity!.getY()+10))
	endif
[[GLM_ACCTSUMHDR.AREC]]
rem --- Set Default value for Detail Flag

	detail_flag$=callpoint!.getDevObject("detail_flag")
	callpoint!.setColumnData("GLM_ACCTSUMHDR.DETAIL_FLAG",detail_flag$)
	callpoint!.setColumnData("<<DISPLAY>>.SUMM_DTL",detail_flag$,1)

rem compare budget columns/types from gls01 with defined display columns
rem set the 4 listbuttons accordingly, and read/display corres glm02 data

	gls_calendar_dev=fnget_dev("GLS_CALENDAR")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
	displayColumns!=callpoint!.getDevObject("displayColumns")

	cols!=UserObj!.getItem(num(user_tpl.cols_ofst$))
	tps!=UserObj!.getItem(num(user_tpl.tps_ofst$))
	codes!=UserObj!.getItem(num(user_tpl.codes_ofst$))
	gridActivity!=UserObj!.getItem(num(user_tpl.grid_ofst$))

	num_codes=codes!.size()
	num_cols=cols!.size()

	for x=0 to num_cols-1
		this_col$=cols!.getItem(x)
		this_tp$=tps!.getItem(x)
		x1=0
		while x1<num_codes-1
			wcd$=codes!.getItem(x1)
			col$=pad(wcd$(1,len(wcd$)-1),len(this_col$))
			tp$=wcd$(len(wcd$))
			if col$=this_col$ and tp$=this_tp$
				gridActivity!.setCellListSelection(x,0,x1,1)
				col$=cvs(col$,2)
				if len(col$)=1 and pos(col$="024") then
					gridActivity!.setRowEditable(x,0)
					gridActivity!.setCellEditable(x,0,1)
				else
					rem --- Disable periods not in this fiscal calendar
					thisYear$=displayColumns!.getYear(this_col$)
					findrecord(gls_calendar_dev,key=firm_id$+thisYear$,dom=*next)gls_calendar$
					if num(gls_calendar.total_pers$)<num(user_tpl.pers$) then
						for per=num(gls_calendar.total_pers$)+1 to num(user_tpl.pers$)
							gridActivity!.setCellEditable(x,per+1,0)
						next per
					endif
				endif
				break
			else
				x1=x1+1
			endif
		wend
	
	next x
[[GLM_ACCTSUMHDR.AWIN]]
rem --- Needed classes

	use ::glo_AlignFiscalCalendar.aon::AlignFiscalCalendar
	use ::ado_util.src::util

rem --- Initialize displayColumns! object

	use ::glo_DisplayColumns.aon::DisplayColumns
	displayColumns!=new DisplayColumns(firm_id$)
	callpoint!.setDevObject("displayColumns",displayColumns!)

rem --- init...open tables, define custom grid, etc.

	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="GLM_ACCTSUMMARY",open_opts$[2]="OTA"
	open_tables$[4]="GLS_CALENDAR",open_opts$[4]="OTA"

	open_tables$[5]="GLM_ACCT",open_opts$[5]="OTA"
	gosub open_tables

	gls01_dev=num(open_chans$[1])
	gls_calendar_dev=num(open_chans$[4])

	dim gls01a$:open_tpls$[1]
	dim gls_calendar$:open_tpls$[4]

	readrecord(gls01_dev,key=firm_id$+"GL00",dom=std_missing_params)gls01a$
	callpoint!.setDevObject("cur_per",gls01a.current_per$)
	callpoint!.setDevObject("cur_year",gls01a.current_year$)
	x$=stbl("+YEAR",gls01a.current_year$)
	x$=stbl("+PER",gls01a.current_per$)
	callpoint!.setDevObject("gl_yr_closed",gls01a.gl_yr_closed$)
	callpoint!.setDevObject("gls_cur_yr",gls01a.current_year$)
	callpoint!.setDevObject("gls_cur_per",gls01a.current_per$)

	call stbl("+DIR_PGM")+"adc_getmask.aon","","GL","A","",m1$,0,0

rem ---  load up budget column codes and types from gls_params

	cols!=SysGUI!.makeVector()
	tps!=SysGUI!.makeVector()
	for x=1 to 4
		cols!.addItem(field(gls01a$,"acct_mn_cols_"+str(x:"00")))
		tps!.addItem(field(gls01a$,"acct_mn_type_"+str(x:"00")))
	next x

rem --- Get number of years to display in the grid
	years_to_display=5
	years_to_display=abs(int(num(stbl("+GLYEARS",err=*next),err=*next)))
	if years_to_display=0 then
		glm02_dev=fnget_dev("GLM_ACCTSUMMARY")
		dim glm02$:fnget_tpl$("GLM_ACCTSUMMARY")
		read(glm02_dev,key=firm_id$,knum="BY_YEAR_ACCT",dom=*next)
		readrecord(glm02_dev,end=*next)glm02$
		if glm02.firm_id$=firm_id$ then
			years_to_display=min(100,num(gls01a.current_year$)-num(glm02.year$,err=*next)+1)
		endif
		read(glm02_dev,key=firm_id$,knum="PRIMARY",dom=*next)
	endif

rem --- Need to handle possible year in grid with more periods than the current fiscal year
rem --- Check next year and previous years being displayed
	readrecord(gls_calendar_dev,key=firm_id$+gls01a.current_year$,dom=*next)gls_calendar$
	if cvs(gls_calendar.firm_id$,2)="" then
		msg_id$="AD_NO_FISCAL_CAL"
		dim msg_tokens$[1]
		msg_tokens$[1]=gls01a.current_year$
		gosub disp_message
		callpoint!.setStatus("EXIT")
		break
	endif
	num_pers=num(gls_calendar.total_pers$)

	for yr=num(gls01a.current_year$)-years_to_display to num(gls01a.current_year$)+1
		if num_pers=13 then break
		dim thisCalendar$:fattr(gls_calendar$)
		readrecord(gls_calendar_dev,key=firm_id$+str(yr),dom=*continue)thisCalendar$
		if num(thisCalendar.total_pers$)>num_pers then num_pers=num(thisCalendar.total_pers$)
	next yr

rem --- load up period abbr names from gls_calendar

	per_names!=SysGUI!.makeVector()
	for x=1 to num_pers
		abbr_name$=field(gls_calendar$,"ABBR_NAME_"+str(x:"00"))
		if cvs(abbr_name$,2)<>"" then
			per_names!.addItem(abbr_name$)
		else
			per_names!.addItem(str(x:"00"))
		endif
	next x
			
rem ---  create list for column zero of grid -- column type drop-down

	displayColumns!=new DisplayColumns(firm_id$)
	codeList!=displayColumns!.getVectorButtonList()
	codes!=SysGUI!.makeVector()
	for i=0 to codeList!.size()-1
		rem ... label$=rev_title$+" ("+record_id$+amt_or_units$+")"
		label$=codeList!.getItem(i)
		record_id$=label$(pos(" ("=label$,-1)+2)
		record_id$=record_id$(1,len(record_id$)-2)
		amt_or_units$=label$(len(label$)-1,1)
		codes!.addItem(record_id$+amt_or_units$)
	next i

rem --- Determine type of extra rows to display
	gosub identifyExtraRows
	callpoint!.setDevObject("extra_row_types",extra_row_types$)

rem ---  set up grid

	nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))
	gridActivity!=Form!.addGrid(nxt_ctlID,5,140,1000,250)
	gridActivity!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)
	gridActivity!.setSelectionMode(gridActivity!.GRID_SELECT_CELL)
	gridActivity!.setSelectedRow(0)
	gridActivity!.setSelectedColumn(0)

	gridActivity!.setCallback(gridActivity!.ON_GRID_EDIT_START,"custom_event")
	gridActivity!.setCallback(gridActivity!.ON_GRID_EDIT_STOP,"custom_event")
	gridActivity!.setCallback(gridActivity!.ON_GRID_MOUSE_UP,"custom_event")

rem ---  store desired data (mostly offsets of items in UserObj) in user_tpl

	tpl_str$="pers:c(5),pers_ofst:c(5),codes_ofst:c(5),codeList_ofst:c(5),grid_ctlID:c(5),grid_ofst:c(5),"+
:			"cols_ofst:c(5),tps_ofst:c(5),amt_mask:c(15),vectActivity_ofst:c(5),"+
:			"curr_editMode:c(1),years_to_display:n(3)"

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
	user_tpl.curr_editMode$=""
	user_tpl.years_to_display=years_to_display

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
	font!=gridActivity!.getCellFont(0,0)
	boldFont!=SysGUI!.makeFont("Bold"+font!.getName(),font!.getSize(),SysGUI!.BOLD)
	blueColor!=SysGUI!.makeColor(SysGUI!.BLUE)
	for row=0 to cols!.size()-1
		gridActivity!.setCellFont(row,0,boldFont!)
		gridActivity!.setCellForeColor(row,0,blueColor!)
	next row
	util.resizeWindow(Form!, SysGui!)

	callpoint!.setOptionEnabled("DETL",0)
[[GLM_ACCTSUMHDR.ARAR]]
rem --- Set initial values for period and year

	fiscal_per$=callpoint!.getDevObject("gls_cur_per")
	fiscal_yr$=callpoint!.getDevObject("gls_cur_yr")
	callpoint!.setColumnData("<<DISPLAY>>.CURRENT_PER",stbl("+PER"),1)
	callpoint!.setColumnData("<<DISPLAY>>.CURRENT_YEAR",stbl("+YEAR"),1)
	callpoint!.setColumnData("<<DISPLAY>>.FISCAL_PER",fiscal_per$,1)
	callpoint!.setColumnData("<<DISPLAY>>.FISCAL_YEAR",fiscal_yr$,1)

	gosub display_mtd_ytd

rem --- Set current selection in summ_dtl list 
	callpoint!.setColumnData("<<DISPLAY>>.SUMM_DTL",callpoint!.getColumnData("GLM_ACCTSUMHDR.DETAIL_FLAG"),1)

	if cvs(callpoint!.getColumnData("GLM_ACCTSUMHDR.GL_ACCOUNT"),2)<>"" then
		gosub fill_gridActivity
	else
		rem --- Clear gridActivity data
		gridActivity!=UserObj!.getItem(num(user_tpl.grid_ofst$))
		vectGLSummary!=SysGUI!.makeVector()
		for col=1 to gridActivity!.getNumColumns()-1
			vectGLSummary!.addItem("")
		next col
		for row=0 to gridActivity!.getNumRows()-1
			gridActivity!.setCellText(row,1,vectGLSummary!)
		next row
	endif

rem --- Initialize align_periods

	pick_year$=fiscal_yr$
	gosub init_align_periods
[[GLM_ACCTSUMHDR.BSHO]]
rem --- Open/Lock files

files=6,begfile=1,endfile=files
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="GLS_PARAMS",options$[1]="OTA"
files$[2]="GLM_ACCTSUMMARY",options$[2]="OTA"
files$[3]="GLS_CALENDAR",options$[3]="OTA"
files$[4]="GLW_ACCTSUMMARY",options$[4]="OTA"
files$[5]="GLM_ACCTBUDGET",options$[5]="OTA"
files$[6]="GLM_BUDGETPLANS",options$[6]="OTA"

call dir_pgm$+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                 chans$[all],templates$[all],table_chans$[all],batch,status$

if status$<>"" then
	remove_process_bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif

gls01_dev=num(chans$[1])
gls_calendar_dev=num(chans$[3])
dim gls01a$:templates$[1]
dim gls_calendar$:templates$[3]

rem --- init/parameters

gls01a_key$=firm_id$+"GL00"
find record (gls01_dev,key=gls01a_key$,err=std_missing_params) gls01a$
find record (gls_calendar_dev,key=firm_id$+gls01a.current_year$,err=*next) gls_calendar$
if cvs(gls_calendar.firm_id$,2)="" then
	msg_id$="AD_NO_FISCAL_CAL"
	dim msg_tokens$[1]
	msg_tokens$[1]=gls01a.current_year$
	gosub disp_message
	callpoint!.setStatus("EXIT")
	break
endif

	if gls01a.gl_yr_closed$ <> "Y" then 
		record$="4"
	else
		record$="0"
	endif
	callpoint!.setDevObject("rec_id",record$)
	callpoint!.setDevObject("tot_pers",gls_calendar.total_pers$)
	callpoint!.setDevObject("align_fiscal_periods","N")
	callpoint!.setDevObject("alignCalendar",new AlignFiscalCalendar(firm_id$))
	callpoint!.setDevObject("gridModified","0")

	callpoint!.setDevObject("detail_flag",gls01a.detail_flag$)

	tns!=BBjAPI().getNamespace("GLM_ACCT","drill",1)
	tns!.setValue("cur_per",gls01a.current_per$)

rem --- Create Yes-No version of summ_dtl list
	ldat_list$=pad(Translate!.getTranslation("AON_DETAIL"),15)+"~"+"Y ;"
	ldat_list$=ldat_list$+pad(Translate!.getTranslation("AON_SUMMARY"),15)+"~"+"N ;"

	callpoint!.setTableColumnAttribute("<<DISPLAY>>.SUMM_DTL","LDAT",ldat_list$)

	rem --- Remove code from ListButton display
	summ_dtl!=callpoint!.getControl("<<DISPLAY>>.SUMM_DTL")
	summ_dtl!.removeAllItems()
	summ_dtl!.addItem(Translate!.getTranslation("AON_DETAIL"))
	summ_dtl!.addItem(Translate!.getTranslation("AON_SUMMARY"))
[[<<DISPLAY>>.CURRENT_PER.AVAL]]
rem --- set variables

	per$=callpoint!.getUserInput()
	callpoint!.setDevObject("cur_per",per$)
	x$=stbl("+PER",per$)
	tns!=BBjAPI().getNamespace("GLM_ACCT","drill",1)
	tns!.setValue("cur_per",per$)
	gosub check_modified

	gosub display_mtd_ytd
[[<<DISPLAY>>.CURRENT_PER.AINP]]
rem -- Ensure valid period

	period$=callpoint!.getUserInput()
	if num(period$)<1 or num(period$)>num(callpoint!.getDevObject("tot_pers"))
		msg_id$="INVALID_PERIOD"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
[[<<DISPLAY>>.CURRENT_YEAR.AVAL]]
rem --- set variables

	yr$=callpoint!.getUserInput()
	callpoint!.setDevObject("cur_year",yr$)
	x$=stbl("+YEAR",yr$)

rem --- Set proper record ID
	record$=" "
	if num(yr$)=num(callpoint!.getDevObject("gls_cur_yr"))
		if callpoint!.getDevObject("gl_yr_closed") <> "Y"
			record$="4";rem Next Year Actual
		else
			record$="0";rem Current Year Actual
		endif
	endif
	if num(yr$)=num(callpoint!.getDevObject("gls_cur_yr"))-1
		if callpoint!.getDevObject("gl_yr_closed") <> "Y"
			record$="0";rem Current Year Actual
		else
			record$="2";rem Prior Year Actual
		endif
	endif
	if num(yr$)=num(callpoint!.getDevObject("gls_cur_yr"))+1
		if callpoint!.getDevObject("gl_yr_closed") <> "Y"
			record$=" ";rem Undefined
		else
			record$="4";rem Next Year Actual
		endif
	endif
	callpoint!.setDevObject("rec_id",record$)
	gosub check_modified

	gosub display_mtd_ytd
[[GLM_ACCTSUMHDR.<CUSTOM>]]
#include std_functions.src
rem ======================================================
check_modified:
rem ======================================================

	det_flag$=callpoint!.getColumnData("GLM_ACCTSUMHDR.DETAIL_FLAG")
	dsk_det_flag$=callpoint!.getColumnDiskData("GLM_ACCTSUMHDR.DETAIL_FLAG")
	desc$=callpoint!.getColumnData("GLM_ACCTSUMHDR.GL_ACCT_DESC")
	dsk_desc$=callpoint!.getColumnDiskData("GLM_ACCTSUMHDR.GL_ACCT_DESC")
	type$=callpoint!.getColumnData("GLM_ACCTSUMHDR.GL_ACCT_TYPE")
	dsk_type$=callpoint!.getColumnDiskData("GLM_ACCTSUMHDR.GL_ACCT_TYPE")
	gridModified=num(callpoint!.getDevObject("gridModified"))
	if det_flag$=dsk_det_flag$ and desc$=dsk_desc$ and type$=dsk_type$ and !gridModified then
		callpoint!.setStatus("CLEAR")
	endif

	return

rem ======================================================
display_mtd_ytd:
rem ======================================================

rem --- Display MTD and YTD

	glm02_dev=fnget_dev("GLM_ACCTSUMMARY")
	dim glm02$:fnget_tpl$("GLM_ACCTSUMMARY")
	acct_no$=callpoint!.getColumnData("GLM_ACCTSUMHDR.GL_ACCOUNT")
	rec_id$=callpoint!.getDevObject("rec_id")
	displayColumns!=callpoint!.getDevObject("displayColumns")
	year$=displayColumns!.getYear(rec_id$)
	cur_per=num(callpoint!.getDevObject("cur_per"))

	read record (glm02_dev,key=firm_id$+acct_no$+year$,dom=*next) glm02$
	cur_amt=nfield(glm02$,"period_amt_"+str(cur_per:"00"))
	ytd_amt=0
	for x=1 to cur_per
		ytd_amt=ytd_amt+nfield(glm02$,"period_amt_"+str(x:"00"))
	next x

	callpoint!.setColumnData("<<DISPLAY>>.MTD_TOTAL",str(cur_amt),1)
	callpoint!.setColumnData("<<DISPLAY>>.YTD_TOTAL",str(ytd_amt),1)
	callpoint!.setColumnData("<<DISPLAY>>.YTD_BALANCE",str(ytd_amt+glm02.begin_amt),1)

	return

rem ======================================================
update_glm_acctsummary:
rem ======================================================
rem ---  Parse thru gridActivity! and write back any budget recs to glm-02
rem --- Only budget and planned budget rows are editable. Actual rows are disabled

	cols=vectGLSummary!.size()-2
	if cols>0
		label$=gridActivity!.getCellText(curr_row,0)
		record_type$=label$(pos(" ("=label$,-1)+2)
		record_type$=record_type$(1,len(record_type$)-2)
		amt_or_units$=label$(len(label$)-1,1)
		displayColumns!=callpoint!.getDevObject("displayColumns")
		actbud$=displayColumns!.getActBud(record_type$)
		if actbud$="P" then
			budget_dev=fnget_dev("GLM_BUDGETPLANS")
			dim budget$:fnget_tpl$("GLM_BUDGETPLANS")
		else
			if actbud$="B" then
				budget_dev=fnget_dev("GLM_ACCTBUDGET")
				dim budget$:fnget_tpl$("GLM_ACCTBUDGET")
			else
				return
			endif
		endif

		budget.firm_id$=firm_id$
		budget.gl_account$=callpoint!.getColumnData("GLM_ACCTSUMHDR.GL_ACCOUNT")
		if actbud$="P" then
			budget.budget_code$=record_type$
			budget_key$=budget.firm_id$+budget.gl_account$+budget.budget_code$
		else
		budget.year$=displayColumns!.getYear(record_type$)
		budget_key$=budget.firm_id$+budget.gl_account$+budget.year$
		endif
		extractrecord(budget_dev,key=budget_key$,dom=*next)budget$; rem Advisory Locking

			switch pos(amt_or_units$="AU")
				case 1;rem amounts
					budget.begin_amt$=vectGLSummary!.getItem(0)
					for x=1 to cols
						field budget$,"PERIOD_AMT_"+str(x:"00")=vectGLSummary!.getItem(x)
					next x
				break

				case 2; rem units
					budget.begin_units$=vectGLSummary!.getItem(0)
					for x=1 to cols
						field budget$,"PERIOD_UNITS_"+str(x:"00")=vectGLSummary!.getItem(x)
					next x
				break
			swend

rem --- write budget

		budget$=field(budget$)
		writerecord(budget_dev)budget$

	endif

	return

rem ======================================================
format_gridActivity:
rem ======================================================

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()
	def_grid_cols=num(user_tpl.pers$)+3
	num_rows=4;rem max 4 recs as defined in gls01 rec
	dim attr_grid_col$[def_grid_cols,len(attr_def_col_str$[0,0])/5]
	m1$=user_tpl.amt_mask$


	attr_grid_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="RECORD TP"
	attr_grid_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_RECORD_TYPE")
	attr_grid_col$[1,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"
	attr_grid_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="115"

	attr_grid_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="BEGIN BAL"
	attr_grid_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_BEGINNING")
	attr_grid_col$[2,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_grid_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="80"
	attr_grid_col$[2,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$

	nxt_col=3

	for x=0 to num(user_tpl.pers$)-1
		per_name!=UserObj!.getItem(num(user_tpl.pers_ofst$))
		attr_grid_col$[nxt_col+x,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="PER "+str(x+1)
		attr_grid_col$[nxt_col+x,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=per_name!.getItem(x)
		attr_grid_col$[nxt_col+x,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
		attr_grid_col$[nxt_col+x,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="80"
		attr_grid_col$[nxt_col+x,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$
	next x

	attr_grid_col$[nxt_col+x,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="END BAL"
	attr_grid_col$[nxt_col+x,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_ENDING")
	attr_grid_col$[nxt_col+x,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_grid_col$[nxt_col+x,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="80"
	attr_grid_col$[nxt_col+x,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$
	attr_grid_col$[nxt_col+x,fnstr_pos("OPTS",attr_def_col_str$[0,0],5)]="C"

	for curr_attr=1 to def_grid_cols

		attr_grid_col$[0,1]=attr_grid_col$[0,1]+pad("GLM_ACCTSUMHDR."+attr_grid_col$[curr_attr,
:			fnstr_pos("DVAR",attr_def_col_str$[0,0],5)],40)

	next curr_attr

	attr_disp_col$=attr_grid_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridActivity!,"COLH-EDIT-LINES-LIGHT-HIGHO-CELL",num_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_grid_col$[all]

	return

rem ======================================================
set_column1_list:
rem ======================================================
	rem create invisible listButton object with list=previously-built codeList! vector (description + code)
	rem set first column in grid to use the listButton to create drop-down

	tmpListCtl!=Form!.addListButton(nxt_ctlID+1,10,10,100,100,"",$0810$)
	codeList!=UserObj!.getItem(num(user_tpl.codeList_ofst$))
	tmpListCtl!.insertItems(0,codeList!)

	gridActivity!=UserObj!.getItem(num(user_tpl.grid_ofst$))
	cols!=UserObj!.getItem(num(user_tpl.cols_ofst$))
	for row=0 to cols!.size()-1
		gridActivity!.setCellListControl(row,0,tmpListCtl!)
		gridActivity!.setCellListSelection(row,0,0,0)
	next row

	rem --- Get extra rows description
	gosub extraRowsDescriptions
	callpoint!.setDevObject("extraRows",extraRows!)

	return

rem ======================================================
fill_gridActivity:
rem ======================================================

	gridActivity!=UserObj!.getItem(num(user_tpl.grid_ofst$))
	cols!=UserObj!.getItem(num(user_tpl.cols_ofst$))
	tps!=UserObj!.getItem(num(user_tpl.tps_ofst$))
	alignCalendar! = callpoint!.getDevObject("alignCalendar")
	gl_account$=callpoint!.getColumnData("GLM_ACCTSUMHDR.GL_ACCOUNT")

	for x=0 to cols!.size()-1
		recordType$=cols!.getItem(x)
		displayColumns!=callpoint!.getDevObject("displayColumns")
		thisYear$=displayColumns!.getYear(recordType$)
		actbud$=displayColumns!.getActBud(recordType$)
		if actbud$="P" then
			glm02_key$=firm_id$+gl_account$+budgetType$
		else
			if actbud$="A" then
				glm02_key$=firm_id$+gl_account$+thisYear$
				if callpoint!.getDevObject("align_fiscal_periods")="Y" and alignCalendar!.canAlignCalendar(thisYear$) then
					rem --- Use GLW_ACCTSUMMARY when fiscal periods are aligned
					gls_cur_yr$=callpoint!.getDevObject("gls_cur_yr")
					glm02_key$=firm_id$+gl_account$+thisYear$+gls_cur_yr$
				endif
			else
				glm02_key$=firm_id$+gl_account$+thisYear$
			endif
		endif

		col_type$=tps!.getItem(x)
		gosub build_vectGLSummary
		gridActivity!.setCellText(x,1,vectGLSummary!)
	next x

	rem --- Display extra rows data
	gosub displayExtraRows

	callpoint!.setStatus("REFRESH")

	return

rem =======================================================
build_vectGLSummary:
rem glm02_key$:	input
rem actbud$:		input
rem col_type$:		input
rem alignCalendar!:	input
rem =======================================================

	if actbud$="P" then
		glm_budgetplans_dev=fnget_dev("GLM_BUDGETPLANS")
		dim glm_budgetplans$:fnget_tpl$("GLM_BUDGETPLANS")
		readrecord(glm_budgetplans_dev,key=glm02_key$,dom=*next)glm_budgetplans$
	else
		periodsAligned=0
		if actbud$="A" then
			glm02_dev=fnget_dev("GLM_ACCTSUMMARY")
			glm02_tpl$=fnget_tpl$("GLM_ACCTSUMMARY")
			if callpoint!.getDevObject("align_fiscal_periods")="Y" and alignCalendar!.canAlignCalendar(thisYear$) then
				rem --- Use GLW_ACCTSUMMARY when fiscal periods are aligned
				glw_acctsummary_dev=fnget_dev("GLW_ACCTSUMMARY")
				dim glw_acctsummary$:fnget_tpl$("GLW_ACCTSUMMARY")
				periodsAligned=1
			endif
		else
			glm02_dev=fnget_dev("GLM_ACCTBUDGET")
			glm02_tpl$=fnget_tpl$("GLM_ACCTBUDGET")
		endif
		if periodsAligned then
			gls_cur_yr$=callpoint!.getDevObject("gls_cur_yr")
			readrecord(glw_acctsummary_dev,key=glm02_key$,knum="BY_ACCOUNT_YEAR",dom=*next)glw_acctsummary$
			dim glm02a$:glm02_tpl$
			call stbl("+DIR_PGM")+"adc_copyfile.aon",glw_acctsummary$,glm02a$,status
			if status then dim glm02a$:glm02_tpl$
		else
			dim glm02a$:glm02_tpl$
			readrecord(glm02_dev,key=glm02_key$,dom=*next)glm02a$
		endif
	endif

	rem --- Display message when calendars have been aligned
	if callpoint!.getDevObject("align_fiscal_periods")="Y" then
		align_message$=Translate!.getTranslation("AON_ACTUALS")+" "+Translate!.getTranslation("AON_ALIGNED_WITH","Aligned With")+" "+callpoint!.getDevObject("gls_cur_yr")
	else
		align_message$=""
	endif
	callpoint!.setColumnData("<<DISPLAY>>.ALIGN_MESSAGE",align_message$,1)

	num_pers=num(user_tpl.pers$)
	vectGLSummary!=SysGUI!.makeVector()
	m1$=user_tpl.amt_mask$

	switch pos(col_type$="AU")
		case 1
			if actbud$="P" then
				vectGLSummary!.addItem(str(num(glm_budgetplans.begin_amt$)))
				for x1=1 to num_pers
					vectGLSummary!.addItem(str(num(field(glm_budgetplans$,"PERIOD_AMT_"+str(x1:"00")))))
				next x1
			else
				vectGLSummary!.addItem(str(num(glm02a.begin_amt$)))
				for x1=1 to num_pers
					vectGLSummary!.addItem(str(num(field(glm02a$,"PERIOD_AMT_"+str(x1:"00")))))
				next x1
			endif
			gosub calculate_end_bal			
		break
		case 2
			if actbud$="P" then
				vectGLSummary!.addItem(glm_budgetplans.begin_units$)
				for x1=1 to num_pers
					vectGLSummary!.addItem(field(glm_budgetplans$,"PERIOD_UNITS_"+str(x1:"00")))
				next x1
			else
				vectGLSummary!.addItem(glm02a.begin_units$)
				for x1=1 to num_pers
					vectGLSummary!.addItem(field(glm02a$,"PERIOD_UNITS_"+str(x1:"00")))
				next x1
			endif
			gosub calculate_end_bal
		break
		case default

		break
	swend

	return

rem ======================================================
calculate_end_bal:
rem ======================================================
	end_bal=0
	wk=vectGLSummary!.size()
	if wk>0
		for x2=0 to wk-1
			end_bal=end_bal+num(vectGLSummary!.getItem(x2))
		next x2
		vectGLSummary!.addItem(str(end_bal))
	endif

	return

rem ======================================================
disable_fields:
rem ======================================================
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

rem ==========================================================================
init_align_periods: rem --- Initialize align_periods for prior and next year
rem		input: pick_year$
rem ==========================================================================
	alignCalendar! = callpoint!.getDevObject("alignCalendar")
	align=alignCalendar!.canAlignCalendar(str(num(pick_year$)+1))
	for yr=num(pick_year$)-user_tpl.years_to_display to num(pick_year$)
		if align then break
		align=alignCalendar!.canAlignCalendar(str(yr))
	next yr
	if align then
		rem --- can align calendar
		callpoint!.setColumnEnabled("<<DISPLAY>>.ALIGN_PERIODS",1)
	else
		rem --- canNOT align calendar
		callpoint!.setColumnEnabled("<<DISPLAY>>.ALIGN_PERIODS",0)
		callpoint!.setDevObject("align_fiscal_periods","N")
	endif
	align_fiscal_periods$=callpoint!.getDevObject("align_fiscal_periods")
	callpoint!.setColumnData("<<DISPLAY>>.ALIGN_PERIODS",align_fiscal_periods$,1)

	return

rem ==========================================================================
identifyExtraRows: rem --- Determine type of extra rows to display
rem		input: cols!
rem		input: displayColumns!
rem		output: extra_row_types$
rem ==========================================================================

	extra_row_types$=""
	for i=0 to cols!.size()-1
		col$=cvs(cols!.getItem(i),2)
		tp$=tps!.getItem(i)
		if displayColumns!.getActBud(col$)="A" then
			rem --- Actual
			row_type$="A"+tp$
		else
			rem --- Budget
			row_type$="B"+tp$
		endif
		if pos(row_type$=extra_row_types$,2)=0 then
			extra_row_types$=extra_row_types$+row_type$
		endif
	next i

	return

rem ==========================================================================
extraRowsDescriptions: rem --- Get extra rows descriptions
rem		input: Translate!
rem		input: gridActivity!
rem		input: cols!
rem 		output: extraRows!
rem ==========================================================================

	actual$=Translate!.getTranslation("AON_ACTUAL")
	budget$=cvs(Translate!.getTranslation("AON_BUDGET_"),2)
	amt$=Translate!.getTranslation("AON_AMT")
	unit$=Translate!.getTranslation("AON_UNIT")
	extra_row_types$=callpoint!.getDevObject("extra_row_types")
	gridActivity!.setNumRows(cols!.size()+((user_tpl.years_to_display+1)*len(extra_row_types$)/2))
	row=cols!.size()
	gls_cur_yr=num(callpoint!.getDevObject("gls_cur_yr"))
	extraRows!=SysGUI!.makeVector()
	for yr=gls_cur_yr to gls_cur_yr-user_tpl.years_to_display step -1
		for i=1 to len(extra_row_types$) step 2
			actbud$=iff(extra_row_types$(i,1)="A",actual$,budget$)
			amtunit$=iff(extra_row_types$(i+1,1)="A",amt$,unit$)
			gridActivity!.setCellText(row,0,str(yr)+" "+actbud$+" "+amtunit$)
			gridActivity!.setRowEditable(row,0)
			extraRows!.addItem(str(yr)+":"+extra_row_types$(i,2))
			row=row+1
		next i
	next yr

	return

rem ==========================================================================
displayExtraRows: rem --- Display extra rows descriptions and data
rem		input: gl_account$
rem		input: gridActivity!
rem ==========================================================================

	alignCalendar! = callpoint!.getDevObject("alignCalendar")
	extraRows!=callpoint!.getDevObject("extraRows")
	for i=0 to extraRows!.size()-1
		periodsAligned=0
		extraRow$=extraRows!.getItem(i)
		thisYear$=extraRow$(1,pos(":"=extraRow$)-1)
		extra_row_type$=extraRow$(pos(":"=extraRow$)+1)
		if extra_row_type$(1,1)="A" then
			rem --- Actual
			glm02_dev=fnget_dev("GLM_ACCTSUMMARY")
			glm02_tpl$=fnget_tpl$("GLM_ACCTSUMMARY")
			if callpoint!.getDevObject("align_fiscal_periods")="Y" and alignCalendar!.canAlignCalendar(thisYear$) then
				rem --- Use GLW_ACCTSUMMARY when fiscal periods are aligned
				glw_acctsummary_dev=fnget_dev("GLW_ACCTSUMMARY")
				dim glw_acctsummary$:fnget_tpl$("GLW_ACCTSUMMARY")
				periodsAligned=1
			endif
		else
			rem --- Budget
			glm02_dev=fnget_dev("GLM_ACCTBUDGET")
			glm02_tpl$=fnget_tpl$("GLM_ACCTBUDGET")
		endif
		if periodsAligned then
			gls_cur_yr$=callpoint!.getDevObject("gls_cur_yr")
			readrecord(glw_acctsummary_dev,key=firm_id$+gl_account$+thisYear$+gls_cur_yr$,knum="BY_ACCOUNT_YEAR",dom=*next)glw_acctsummary$
			dim glm02a$:glm02_tpl$
			call stbl("+DIR_PGM")+"adc_copyfile.aon",glw_acctsummary$,glm02a$,status
			if status then dim glm02a$:glm02_tpl$
		else
			dim glm02a$:glm02_tpl$
			readrecord(glm02_dev,key=firm_id$+gl_account$+thisYear$,dom=*next)glm02a$
		endif

		vectGLSummary!=SysGUI!.makeVector()
		if extra_row_type$(2,1)="A" then
			rem --- Amount
			vectGLSummary!.addItem(str(num(glm02a.begin_amt$)))
			for x1=1 to num(user_tpl.pers$)
				vectGLSummary!.addItem(str(num(field(glm02a$,"PERIOD_AMT_"+str(x1:"00")))))
			next x1
			gosub calculate_end_bal			
		else
			rem --- Units
			vectGLSummary!.addItem(glm02a.begin_units$)
			for x1=1 to num(user_tpl.pers$)
				vectGLSummary!.addItem(field(glm02a$,"PERIOD_UNITS_"+str(x1:"00")))
			next x1
		endif

		gridActivity!.setCellText(cols!.size()+i,1,vectGLSummary!)
	next i

	return

#include std_missing_params.src
