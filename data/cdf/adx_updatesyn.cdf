[[ADX_UPDATESYN.AWIN]]
rem --- Add grid to form for updating STBL's with paths

	use ::ado_util.src::util

	nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))
	callpoint!.setDevObject("nxt_ctlID",nxt_ctlID)

	gridStbls!=Form!.addGrid(nxt_ctlID,10,80,850,260); rem --- ID, x, y, width, height
	callpoint!.setDevObject("gridStbls",gridStbls!)

	callpoint!.setDevObject("stbl_grid_id",str(nxt_ctlID))
	callpoint!.setDevObject("def_rpts_cols",4)
	callpoint!.setDevObject("min_rpts_rows",15)

	gosub format_grid

	rem --- misc other init
	gridStbls!.setColumnEditable(3,1)
	gridStbls!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)

	callpoint!.setDevObject("updateSynRows",SysGUI!.makeVector())
	callpoint!.setDevObject("oldSynRows",SysGUI!.makeVector())
	gosub create_reports_vector
	gosub fill_grid
	util.resizeWindow(Form!, SysGui!)

	rem --- set callbacks - processed in ACUS callpoint
	rem --- Currently ON_GRID_CELL_VALIDATION results in the loss of user input when they Run Process (F5)
	rem --- before leaving the cell where text was entered. So don't use ON_GRID_CELL_VALIDATION for now.
	rem	gridStbls!.setCallback(gridStbls!.ON_GRID_CELL_VALIDATION,"custom_event")
[[ADX_UPDATESYN.ASIZ]]
	gridStbls!=callpoint!.getDevObject("gridStbls")
	gridStbls!.setSize(Form!.getWidth()-(gridStbls!.getX()*2),Form!.getHeight()-(gridStbls!.getY()+10))
	gridStbls!.setFitToGrid(1)
[[ADX_UPDATESYN.ACUS]]
rem --- Process custom event
rem --- Edit STBL target value

rem This routine is executed when callbacks have been set to run a 'custom event'.
rem Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind of event it is.
rem See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info.

	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ctl_ID=dec(gui_event.ID$)

	if ctl_ID <> num(callpoint!.getDevObject("stbl_grid_id")) then break; rem --- exit callpoint

	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
	endif

	switch notice.code
		case 32; rem --- on_grid_cell_validation
			rem --- Make sure we get all entries in the grid
			e!=SysGUI!.getLastEvent()
			e!.accept(1)
			break
	swend
[[ADX_UPDATESYN.BSHO]]
rem --- Declare Java classes used

	use java.io.File
	use java.util.ArrayList
	use java.util.HashMap

rem --- Initialize update source syn file and old syn file values so can tell later if they have changed

	callpoint!.setDevObject("prev_update_syn_file","")
	callpoint!.setDevObject("prev_old_syn_file","")
[[ADX_UPDATESYN.OLD_SYN_FILE.AVAL]]
rem --- Validate old syn file

	old_syn$ = callpoint!.getUserInput()
	gosub validate_old_syn

rem --- Set defaults for data STBLs
	if success and cvs(old_syn$,3)<>cvs(callpoint!.getDevObject("prev_old_syn_file"),3)
		rem --- Capture old source syn file value so can tell later if it's been changed
		callpoint!.setDevObject("prev_old_syn_file",old_syn$)

		rem --- parse aon directory from update syn file location
		update_syn$=callpoint!.getDevObject("prev_update_syn_file")
		filePath$=update_syn$
		gosub fix_path
		update_syn$=filePath$
		aonDir$=""
		if pos("/config/"=update_syn$) then aonDir$=update_syn$(1, pos("/config/"=update_syn$,-1))

		rem --- Initialize grid
		callpoint!.setStatus("REFRESH")
		synFile$=old_syn$
		gosub create_reports_vector
		callpoint!.setDevObject("oldSynRows",vectRows!)
		gosub fill_grid
		util.resizeWindow(Form!, SysGui!)
	endif
[[ADX_UPDATESYN.UPDATE_SYN_FILE.AVAL]]
rem --- Validate update syn file

	update_syn$ = callpoint!.getUserInput()
	gosub validate_update_syn

	rem --- Set defaults for data STBLs
	if success and cvs(update_syn$,3)<>cvs(callpoint!.getDevObject("prev_update_syn_file"),3)
		rem --- Capture update source syn file value so can tell later if it's been changed
		callpoint!.setDevObject("prev_update_syn_file",update_syn$)

		rem --- parse aon directory from update syn file location
		filePath$=update_syn$
		gosub fix_path
		update_syn$=filePath$
		aonDir$=""
		if pos("/config/"=update_syn$) then aonDir$=update_syn$(1, pos("/config/"=update_syn$,-1))

		rem --- Initialize grid
		callpoint!.setStatus("REFRESH")
		synFile$=update_syn$
		gosub create_reports_vector
		callpoint!.setDevObject("updateSynRows",vectRows!)
		gosub fill_grid
		util.resizeWindow(Form!, SysGui!)
	endif
[[ADX_UPDATESYN.AREC]]
rem --- Initialize aon new install location
rem --- Default to /aon_prod/vnnnn (where nnnn=new version)
rem --- Get vnnnn from VERSION_ID in the ADM_MODULES table

	synVersion$="00"
	comp_id$=STBL("+AON_APPCOMPANY")
	prod_id$="AD"

	sql_chan=sqlunt
	sqlopen(sql_chan)stbl("+DBNAME")
	sql_prep$="SELECT version_id FROM adm_modules"
	sql_prep$=sql_prep$+" WHERE asc_comp_id='" + comp_id$ + "' and asc_prod_id='" + prod_id$ + "'"
	sqlprep(sql_chan)sql_prep$
	dim select_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)
	while 1
		select_tpl$=sqlfetch(sql_chan,err=*break) 
		synVersion$=cvs(select_tpl.version_id$,3)
	wend
	sqlclose(sql_chan)

	rem --- Remove decimal point from version
	dotPos = pos("."=synVersion$)
	if(dotPos) then
		synVersion$ = synVersion$(1, dotPos - 1) + synVersion$(dotPos + 1)
	endif

	synChan=unt
	update_syn$ = "/aon_prod/v" + synVersion$ + "/aon/config/addon.syn"
	open(synChan,isz=-1, err=file_not_found)update_syn$
	close(synChan)

	callpoint!.setColumnData("ADX_UPDATESYN.UPDATE_SYN_FILE", update_syn$)
	callpoint!.setStatus("REFRESH")
	break

file_not_found:
[[ADX_UPDATESYN.<CUSTOM>]]
format_grid: rem --- Format grid

	def_rpts_cols=callpoint!.getDevObject("def_rpts_cols")
	num_rpts_rows=callpoint!.getDevObject("min_rpts_rows")

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()

	dim attr_rpts_col$[def_rpts_cols,len(attr_def_col_str$[0,0])/5]
	attr_rpts_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="TYPE"
	attr_rpts_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_TYPE")
	attr_rpts_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"

	attr_rpts_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="STBL"
	attr_rpts_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="STBL"
	attr_rpts_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="150"

	attr_rpts_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="STBL_SOURCE"
	attr_rpts_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_SOURCE")
	attr_rpts_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="325"

	attr_rpts_col$[4,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="STBL_TARGET"
	attr_rpts_col$[4,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_TARGET")
	attr_rpts_col$[4,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="325"
	attr_rpts_col$[4,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="256"

	for curr_attr=1 to def_rpts_cols
		attr_rpts_col$[0,1]=attr_rpts_col$[0,1]+pad("COPYMODS."+attr_rpts_col$[curr_attr,
:			fnstr_pos("DVAR",attr_def_col_str$[0,0],5)],40)
	next curr_attr

	attr_disp_col$=attr_rpts_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridStbls!,"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC",num_rpts_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_rpts_col$[all]

	return

fill_grid: rem --- Fill the grid with data in vectRows!

	updateSynRows!=callpoint!.getDevObject("updateSynRows")
	oldSynRows!=callpoint!.getDevObject("oldSynRows")
	gosub merge_vect_rows

	SysGUI!.setRepaintEnabled(0)
	gridStbls!=callpoint!.getDevObject("gridStbls")
	if vectRows!.size()
		numrow=vectRows!.size()/gridStbls!.getNumColumns()
		gridStbls!.clearMainGrid()
		gridStbls!.setNumRows(numrow)
		gridStbls!.setCellText(0,0,vectRows!)
		gridStbls!.resort()
		gridStbls!.setSelectedRow(0)
	endif
	SysGUI!.setRepaintEnabled(1)

	return

rem ==========================================================================
merge_vect_rows: rem --- Merge update and old syn row vectors into a single a vector of STBLs and PREFIXs
		rem      IN: updateSynRows!
		rem           oldSynRows!
		rem     OUT: vectRows!
rem ==========================================================================

	vectRows!=updateSynRows!
	if num(callpoint!.getColumnData("ADX_UPDATESYN.UPGRADE"))
		numCols=num(callpoint!.getDevObject("def_rpts_cols"))

		for i=0 to oldSynRows!.size()-1 step numCols
			type$=oldSynRows!.getItem(i+0)
			addLine=0

			rem --- replace target value of STBL and SYSSTBL lines with target value from OLD syn file
			if type$="STBL" or type$="SYSSTBL"
				stbl$=oldSynRows!.getItem(i+1)
				addLine=1
				for j=0 to vectRows!.size()-1 step numCols
					if vectRows!.getItem(j+1)<>stbl$ then continue
					vectRows!.setItem(j+3, oldSynRows!.getItem(i+3))
					addLine=0
					break
				next j
			endif

			rem --- replace target value of PREFIX and SYSPFX lines with target value from OLD syn file
			if type$="PREFIX" or type$="SYSPFX"
				source$=oldSynRows!.getItem(i+2)
				addLine=1
				for j=0 to vectRows!.size()-1 step numCols
					if vectRows!.getItem(j+1)<>source$ then continue
					vectRows!.setItem(j+3, oldSynRows!.getItem(i+3))
					addLine=0
					break
				next j
			endif
				
			rem --- if STBL/SYSSTBL or PREFIX/SYSPFX not found, add it
			if addLine then
				vectRows!.addItem(oldSynRows!.getItem(i+0))
				vectRows!.addItem(oldSynRows!.getItem(i+1))
				vectRows!.addItem(oldSynRows!.getItem(i+2))
				vectRows!.addItem(oldSynRows!.getItem(i+3))
			endif
		next i
	endif

	return

rem ==========================================================================
create_reports_vector: rem --- Create a vector of STBLs and PREFIXs from the source syn file to fill the grid
		rem      IN: aonDir$
		rem          synFile$
		rem     OUT: vectRows!
rem ==========================================================================

	synDev=unt, more=0
	open(synDev,isz=-1,err=*next)synFile$; more=1

	oldaonDir$=""
	vectRows!=SysGUI!.makeVector()
	while more
		read(synDev,end=*break)record$

		rem --- get old aon path from SYSDIR/DIR line
		rem --- it must be replaced everywhere with current aon path.
		if(pos("DIR="=record$) = 1 or pos("SYSDIR="=record$) = 1) then
			xpos = pos("="=record$)
			oldaonDir$= cvs(record$(xpos+1),3)
		endif

		rem --- process SYSSTBL/STBL lines
		if(pos("STBL="=record$) = 1 or pos("SYSSTBL="=record$) = 1) then
			xpos = pos(" "=record$)
			stbl$ = record$(xpos+1, pos("="=record$(xpos+1))-1)
			source_value$=cvs(record$(pos("="=record$,1,2)+1),3)
			gosub source_target_value
			vectRows!.addItem("STBL")
			vectRows!.addItem(stbl$)
			vectRows!.addItem(source_value$)
			vectRows!.addItem(target_value$)
		endif

		rem --- process SYSPFX/PREFIX lines
		if(pos("PREFIX"=record$) = 1 or pos("SYSPFX"=record$) = 1) then
			source_value$=cvs(record$(pos("="=record$)+1),3)
			gosub source_target_value
			vectRows!.addItem("PREFIX")
			vectRows!.addItem("")
			vectRows!.addItem(source_value$)
			vectRows!.addItem(target_value$)
		endif
	wend
	close(synDev)
	
	return

source_target_value: rem -- Set default new target value based on new config location

	target_value$=source_value$

	rem --- If source holds a path, then need to initialize default new target value
	declare File aFile!
	aFile! = new File(source_value$)
	if aFile!.exists() and aonDir$<>"" and oldaonDir$<>"" then
		record$=target_value$
		search$=oldaonDir$
		replace$=aonDir$
		gosub search_replace
		target_value$=record$
	endif

	filePath$=target_value$
	gosub fix_path
	target_value$=filePath$

	return

validate_update_syn: rem --- Validate update syn file

	success=0

	rem --- File must exist

	testFile$=update_syn$
	gosub verify_file_exists
	if !exists
		callpoint!.setFocus("ADX_UPDATESYN.UPDATE_SYN_FILE")
		callpoint!.setStatus("ABORT")
		return
	endif

	rem --- File should end with .syn extension

	testFile$=update_syn$
	gosub verify_syn_file_ext
	if !syn_ok
		callpoint!.setFocus("ADX_UPDATESYN.UPDATE_SYN_FILE")
		callpoint!.setStatus("ABORT")
		return
	endif

	rem --- Don’t allow current download location

	testLoc$=update_syn$
	gosub verify_not_download_loc
	if !loc_ok
		callpoint!.setFocus("ADX_UPDATESYN.UPDATE_SYN_FILE")
		callpoint!.setStatus("ABORT")
		return
	endif

	success=1

	return

validate_old_syn: rem --- Validate old syn file

	success=0

	rem --- File must exist

	testFile$=old_syn$
	gosub verify_file_exists
	if !exists
		callpoint!.setFocus("ADX_UPDATESYN.OLD_SYN_FILE")
		callpoint!.setStatus("ABORT")
		return
	endif

	rem --- File must end with .syn extension

	testFile$=old_syn$
	gosub verify_syn_file_ext
	if !syn_ok
		callpoint!.setFocus("ADX_UPDATESYN.OLD_SYN_FILE")
		callpoint!.setStatus("ABORT")
		return
	endif

	success=1

	return

verify_file_exists: rem --- Verify file exists

	exists=0
	testChan=unt
	open(testChan, err=file_missing)testfile$
	close(testChan)
	exists=1

file_missing:
	if !exists
		msg_id$="AD_FILE_MISSING"
		dim msg_tokens$[1]
		msg_tokens$[1]=testfile$
		gosub disp_message
	endif

	return


verify_syn_file_ext: rem --- Verify file extension is .syn

	syn_ok=1
	if len(testFile$)<4 or testFile$(len(testFile$)-3)<>".syn"
		msg_id$="AD_WRONG_FILE_EXT"
		dim msg_tokens$[1]
		msg_tokens$[1]=".syn"
		gosub disp_message
		syn_ok=0
	endif

	return

verify_not_download_loc: rem --- Verify not using current download location

	loc_ok=1
	bbjHome$ = System.getProperty("basis.BBjHome")
	if ((new File(testLoc$)).getAbsolutePath()).toLowerCase().startsWith((new File(bbjHome$)).getAbsolutePath().toLowerCase()+File.separator)
		msg_id$="AD_INSTALL_LOC_BAD"
		dim msg_tokens$[1]
		msg_tokens$[1]=bbjHome$
		gosub disp_message
		loc_ok=0
	endif

	return

fix_path: rem --- Flip directory path separators

	pos=pos("\"=filePath$)
	while pos
		filePath$=filePath$(1, pos-1)+"/"+filePath$(pos+1)
		pos=pos("\"=filePath$)
	 wend

	return
    
search_replace: rem --- Search record$ for search$, and replace with replace$
	rem --- Assumes only one occurrence of search$ per line so don't have 
	rem --- to deal with situation where pos(search$=replace$)>0
	pos = pos(search$=record$)
	if(pos) then
		record$ = record$(1, pos - 1) + replace$ + record$(pos + len(search$))
	endif
    return
[[ADX_UPDATESYN.ASVA]]
rem --- Validate update syn file

	update_syn$ = callpoint!.getColumnData("ADX_UPDATESYN.UPDATE_SYN_FILE")
	gosub validate_update_syn
	if !success then callpoint!.setStatus("ABORT")

rem --- Validate old syn file

	if num(callpoint!.getColumnData("ADX_UPDATESYN.UPGRADE"))
		old_syn$ = callpoint!.getColumnData("ADX_UPDATESYN.OLD_SYN_FILE")
		gosub validate_old_syn
		if !success then callpoint!.setStatus("ABORT")
	endif

rem --- Make sure we get all entries in the grid by setting focus on some control besides the grid

	ctl!=callpoint!.getControl("ADX_UPDATESYN.UPDATE_SYN_FILE")
	ctl!.focus()

rem --- Build hash of STBL source and target values and array of PREFIX source and target values to pass to backend program

	declare HashMap stblMap!
	declare ArrayList aList!

	stblMap!=new HashMap()
	pfxList!=new ArrayList()
	gridStbls!=callpoint!.getDevObject("gridStbls")

	for i=0 to gridStbls!.getNumRows()-1
		type$=cvs(gridStbls!.getCellText(i,0),3)

		if type$="STBL" or type$="SYSSTBL"
			aList!=new ArrayList()
			aList!.add(gridStbls!.getCellText(i,2)); rem --- source value
			aList!.add(gridStbls!.getCellText(i,3)); rem --- target value
			stblMap!.put(gridStbls!.getCellText(i,1), aList!)
		endif

		if type$="PREFIX" or type$="SYSPFX"
			aList!=new ArrayList()
			aList!.add(gridStbls!.getCellText(i,2)); rem --- source value
			aList!.add(gridStbls!.getCellText(i,3)); rem --- target value
			pfxList!.add(aList!)
		endif
	next i

	callpoint!.setDevObject("stblMap",stblMap!)
	callpoint!.setDevObject("pfxList",pfxList!)
