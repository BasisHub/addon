[[ADX_COPYMODS.ASIZ]]
rem --- Resize the grid

	gridStbls!=callpoint!.getDevObject("gridStbls")
	gridStbls!.setSize(Form!.getWidth()-(gridStbls!.getX()*2),Form!.getHeight()-(gridStbls!.getY()+10))
	gridStbls!.setFitToGrid(1)
[[ADX_COPYMODS.ACUS]]
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
[[ADX_COPYMODS.ASVA]]
rem --- Validate source syn file

	source_syn$=callpoint!.getColumnData("ADX_COPYMODS.SOURCE_SYN_FILE")
	gosub validate_source_syn
	if !success
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Validate target syn file

	target_syn$=callpoint!.getColumnData("ADX_COPYMODS.TARGET_SYN_FILE")
	gosub validate_target_syn
	if !success
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Make sure we get all entries in the grid by setting focus on some control besides the grid

	ctl!=callpoint!.getControl("ADX_COPYMODS.SOURCE_SYN_FILE")
	ctl!.focus()

rem --- Build hash of STBL source and target values and array of PREFIX source and target values to pass to backend program

	declare HashMap stblMap!
	declare ArrayList aList!

	stblMap!=new HashMap()
	pfxList!=new ArrayList()
	vectRows!=callpoint!.getDevObject("vectRows")
	gridStbls!=callpoint!.getDevObject("gridStbls")
	numCols=num(callpoint!.getDevObject("def_rpts_cols"))

	for i=0 to vectRows!.size() step numCols
		if cvs(gridStbls!.getCellText(i/numCols,0),3)="STBL"
			aList!=new ArrayList()
			aList!.add(gridStbls!.getCellText(i/numCols,2)); rem --- source value
			aList!.add(gridStbls!.getCellText(i/numCols,3)); rem --- target value
			stblMap!.put(gridStbls!.getCellText(i/numCols,1), aList!)
		endif

		if cvs(gridStbls!.getCellText(i/numCols,0),3)="PREFIX"
			aList!=new ArrayList()
			aList!.add(gridStbls!.getCellText(i/numCols,2)); rem --- source value
			aList!.add(gridStbls!.getCellText(i/numCols,3)); rem --- target value
			pfxList!.add(aList!)
		endif
	next i

	callpoint!.setDevObject("stblMap",stblMap!)
	callpoint!.setDevObject("pfxList",pfxList!)
[[ADX_COPYMODS.TARGET_SYN_FILE.AVAL]]
rem --- Validate target syn file

	target_syn$=callpoint!.getUserInput()
	gosub validate_target_syn
[[ADX_COPYMODS.BSHO]]
rem --- Declare Java classes used

	use java.io.File
	use java.util.ArrayList
	use java.util.HashMap

rem --- Initialize current source syn file value so can tell later if it's been changed

	callpoint!.setDevObject("prev_src_syn_file","")
[[ADX_COPYMODS.SOURCE_SYN_FILE.AVAL]]
rem --- Validate source syn file

	source_syn$=callpoint!.getUserInput()
	gosub validate_source_syn

	if success and cvs(source_syn$,3)<>cvs(callpoint!.getDevObject("prev_src_syn_file"),3)
		rem --- Capture current source syn file value so can tell later if it's been changed
		callpoint!.setDevObject("prev_src_syn_file",source_syn$)

		rem --- Set default for target syn file to MODS_DIR/vnnnn/config/MODS_SYN.syn
		rem --- Get vnnnn from VERSION_ID in the ADM_MODULES table
		rem --- Where ASC_COMP_ID comes from the ACOMP line of source syn file
		rem --- And ASC_PROD_ID comes from the APROG line of source syn file
		synVersion$="00",comp_id$="",prod_id$=""
		synChan=unt
		open(synChan,isz=-1, err=file_not_found)source_syn$
		while 1
			read(synChan,end=*break)record$
			rem --- locate ACOMP line
			if(pos("ACOMP="=record$) = 1) then
				rem --- parse ASC_COMP_ID from ACOMP line
				comp_id$=record$(7, pos(";"=record$(7))-1)
			endif
			rem --- locate APROD line
			if(pos("APROD="=record$) = 1) then
				rem --- parse ASC_PROD_ID from APROD line
				prod_id$=record$(7, pos(";"=record$(7))-1)
			endif
		wend
		close(synChan)

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

		rem --- Parse MODS_DIR from source syn path
		rem --- Source syn path may already include a "versioned" directory
		filePath$=source_syn$
		gosub fix_path
		modsDir$=filePath$(1, pos("/config/"=filePath$)-1)
		verDir$=modsDir$(pos("/"=modsDir$,-1)+1)
		if pos("v"=verDir$)=1
			if pos("_"=verDir$)
				rem --- There can be a "_n" at the end of a "versioned" directory
				ver=-1
				ver=num(verDir$(2,pos("_"=verDir$(2))-1),err=*next)
				if ver>=0
					ver=-1
					ver=num(verDir$(pos("_"=verDir$)+1),err=*next)
					if ver>0
						rem --- Source syn path includes a "versioned" directory, so backup one more directory
						modsDir$=modsDir$(1, pos("/"=modsDir$,-1)-1)
					endif
				endif
			else
				ver=-1
				ver=num(verDir$(2),err=*next)
				if ver>=0
					rem --- Source syn path includes a "versioned" directory, so backup one more directory
					modsDir$=modsDir$(1, pos("/"=modsDir$,-1)-1)
				endif
			endif
		endif
		callpoint!.setDevObject("mods_dir",modsDir$)

		rem --- Verify target syn dir doesn't exist
		rem --- As necessary, append _i to target syn dir
		version$=synVersion$
		i=0
		testChan=unt
		while 1
			targetDir$=modsDir$+"/v"+version$
			open(testChan,err=*break)targetDir$
			close(testChan)
			 i=i+1
			version$=synVersion$+"_"+str(i)
		wend
		targetDir$=targetDir$+"/config/"
		synVersion$=version$
		callpoint!.setDevObject("syn_version",synVersion$)

		rem --- Parse MODS_SYN from source syn path
		filePath$=source_syn$
		gosub fix_path
		targetSynFile$=filePath$(pos("/"=filePath$,-1)+1)
		callpoint!.setColumnData("ADX_COPYMODS.TARGET_SYN_FILE",targetDir$+targetSynFile$)
		callpoint!.setStatus("REFRESH")

		gosub create_reports_vector
		gosub fill_grid
		util.resizeWindow(Form!, SysGui!)
	endif
	break

file_not_found:
	rem --- Can't initialize target syn file
[[ADX_COPYMODS.<CUSTOM>]]
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

	SysGUI!.setRepaintEnabled(0)
	vectRows!=callpoint!.getDevObject("vectRows")
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

create_reports_vector: rem --- Create a vector of STBLs from the source syn file to fill the grid

	more=0
	synDev=unt
	open(synDev,isz=-1,err=*next)testfile$; more=1

	vectRows!=SysGUI!.makeVector()
	stbLine$="STBL=SET "
	stbLen=len(stbLine$)
	pfxLine$="PREFIX="
	pfxLen=len(pfxLine$)

	while more
		read(synDev,end=*break)record$

		rem --- process STBL lines
		if(pos(stbLine$=record$) = 1) then
			stbl$ = record$(stbLen+1, pos("="=record$(stbLen+1))-1)
			source_value$=cvs(record$(stbLen+pos("="=record$(stbLen+1))+1),3)
			gosub source_target_value
			vectRows!.addItem("STBL")
			vectRows!.addItem(stbl$)
			vectRows!.addItem(source_value$)
			vectRows!.addItem(target_value$)
		endif

		rem --- process PREFIX lines
		if(pos(pfxLine$=record$) = 1) then
			source_value$=cvs(record$(stbLen+1),3)
			gosub source_target_value
			vectRows!.addItem("PREFIX")
			vectRows!.addItem("")
			vectRows!.addItem(source_value$)
			vectRows!.addItem(target_value$)
		endif
	wend
	close(synDev)
	callpoint!.setDevObject("vectRows",vectRows!)
	
	return

source_target_value: rem -- Set default new target value based on source value

	target_value$=source_value$

	rem --- If source holds a path, then need to update it
	declare File aFile!
	aFile! = new File(source_value$)
	if aFile!.exists()
		rem --- Add version directory to path
		synVersion$="v"+callpoint!.getDevObject("syn_version")
		modsDir$=callpoint!.getDevObject("mods_dir")
		modsDir$=modsDir$(pos(":"=modsDir$)+1)+"/"; rem --- strip possible Windows drive ID and add trailing slash
		filePath$=source_value$
		gosub fix_path
		sourcePath$=filePath$
		if aFile!.isDirectory() and filePath$(len(sourcePath$))<>"/" then sourcePath$=sourcePath$+"/"
		if pos(modsDir$=sourcePath$)
			rem --- Insert new version directory after MODS_DIR
			target_value$=sourcePath$(1,pos(modsDir$=sourcePath$)-1+len(modsDir$))+synVersion$+"/"

			rem --- Remove existing "versioned" directory in source path
			verDir$=sourcePath$(pos(modsDir$=sourcePath$)+len(modsDir$))
			if pos("v"=verDir$)=1
				tmpDir$=verDir$(1,pos("/"=verDir$)-1); rem --- things are easier here without the trailing stuff
				if pos("_"=tmpDir$)
					rem --- There can be a "_n" at the end of a "versioned" directory
					ver=-1
					ver=num(tmpDir$(2,pos("_"=tmpDir$(2))-1),err=*next)
					if ver>=0
						ver=-1
						ver=num(tmpDir$(pos("_"=tmpDir$)+1),err=*next)
						if ver>0
							rem --- This path segement starts with a "versioned" directory, so skip first directory in segement
							verDir$=verDir$(pos("/"=verDir$)+1)
						endif
					endif
				else
					ver=-1
					ver=num(tmpDir$(2),err=*next)
					if ver>=0
						rem --- This path segement starts with a "versioned" directory, so skip first directory in segement
						verDir$=verDir$(pos("/"=verDir$)+1)
					endif
				endif
			endif
			target_value$=target_value$+verDir$
		else
			rem --- Append new version directory to source path
			if aFile!.isDirectory()
				sourceDir$=sourcePath$
				sourceFile$=""
			else
				sourceDir$=sourcePath$(1,pos("/"=sourcePath$,-1))
				sourceFile$=sourcePath$(pos("/"=sourcePath$,-1))
			endif

			rem --- Remove existing "versioned" directory in source path
			verDir$=sourceDir$(pos("/"=sourceDir$,-1,2)+1); rem --- there is a trailing slash
			sourceDir$=sourceDir$(1,pos("/"=sourceDir$,-1,2)); rem --- there is a trailing slash
			if pos("v"=verDir$)=1
				tmpDir$=verDir$(1,pos("/"=verDir$)-1); rem --- things are easier here without the trailing stuff
				if pos("_"=tmpDir$)
					rem --- There can be a "_n" at the end of a "versioned" directory
					ver=-1
					ver=num(tmpDir$(2,pos("_"=tmpDir$(2))-1),err=*next)
					if ver>=0
						ver=-1
						ver=num(tmpDir$(pos("_"=tmpDir$)+1),err=*next)
						if ver>0
							rem --- This is a "versioned" directory, so skip it
							verDir$=""
						endif
					endif
				else
					ver=-1
					ver=num(tmpDir$(2),err=*next)
					if ver>=0
						rem --- This is a "versioned" directory, so skip it
						verDir$=""
					endif
				endif
			endif
			target_value$=sourceDir$+verDir$+synVersion$+sourceFile$
		endif

		rem --- Target path needs to end with trailing slash (or not), the same as source path
		if filePath$(len(filePath$))="/"
			rem -- Add trailing slash as needed to target path
			if target_value$(len(target_value$))<>"/" then target_value$=target_value$+"/"
		else
			rem -- Remove trailing slash as needed to target path
			if target_value$(len(target_value$))="/" then target_value$=target_value$(1,(len(target_value$)-1))
		endif
	endif

	return

validate_source_syn: rem --- Validate source syn file

	success=0

	rem --- File must exist

	testFile$=source_syn$
	gosub verify_file_exists
	if !exists
		callpoint!.setFocus("ADX_COPYMODS.SOURCE_SYN_FILE")
		callpoint!.setStatus("ABORT")
		return
	endif

	rem --- File should end with .syn extension

	testFile$=source_syn$
	gosub verify_syn_file_ext
	if msg_opt$="C"
		callpoint!.setFocus("ADX_COPYMODS.SOURCE_SYN_FILE")
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

	msg_opt$=""
	if len(testFile$)<4 or testFile$(len(testFile$)-3)<>".syn"
		msg_id$="AD_WRONG_FILE_EXT"
		dim msg_tokens$[1]
		msg_tokens$[1]=".syn"
		gosub disp_message
	endif

	return

validate_target_syn: rem --- Validate target syn directory

	success=0

	rem --- Directory must not exist

	targetDir$=target_syn$(1, pos("/config/"=target_syn$)-1)
	exists=0
	testChan=unt
	open(testChan,err=*next)targetDir$; exists=1
	close(testChan)

	if exists
		msg_id$="AD_DIR_EXISTS"
		dim msg_tokens$[1]
		msg_tokens$[1]=targetDir$
		gosub disp_message
		callpoint!.setFocus("ADX_COPYMODS.TARGET_SYN_FILE")
		callpoint!.setStatus("ABORT")
		return
	endif

	success=1
	
	return

fix_path: rem --- Flip directory path separators

	pos=pos("\"=filePath$)
	while pos
		filePath$=filePath$(1, pos-1)+"/"+filePath$(pos+1)
		pos=pos("\"=filePath$)
	 wend

	return
[[ADX_COPYMODS.AWIN]]
rem --- Add grid to form for updating STBL's with paths

	use ::ado_util.src::util

	nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))
	callpoint!.setDevObject("nxt_ctlID",nxt_ctlID)

	gridStbls!=Form!.addGrid(nxt_ctlID,10,60,850,100); rem --- ID, x, y, width, height
	callpoint!.setDevObject("gridStbls",gridStbls!)

	callpoint!.setDevObject("stbl_grid_id",str(nxt_ctlID))
	callpoint!.setDevObject("def_rpts_cols",4)
	callpoint!.setDevObject("min_rpts_rows",4)

	gosub format_grid

	rem --- misc other init
	gridStbls!.setColumnEditable(3,1)
	gridStbls!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)

	gosub create_reports_vector
	gosub fill_grid
	util.resizeWindow(Form!, SysGui!)

	rem --- set callbacks - processed in ACUS callpoint
	gridStbls!.setCallback(gridStbls!.ON_GRID_CELL_VALIDATION,"custom_event")
