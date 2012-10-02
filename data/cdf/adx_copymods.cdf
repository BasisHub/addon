[[ADX_COPYMODS.NEW_CONFIG_LOC.BINP]]
rem --- Initialize new config location

	if cvs(callpoint!.getColumnData("ADX_COPYMODS.NEW_CONFIG_LOC"),3)="" then
		targetDir$=callpoint!.getDevObject("target_dir")
		callpoint!.setColumnData("ADX_COPYMODS.NEW_CONFIG_LOC",targetDir$)
		callpoint!.setStatus("REFRESH")
	endif
[[ADX_COPYMODS.NEW_CONFIG_LOC.AVAL]]
rem --- Validate new config location

	config_loc$=callpoint!.getUserInput()
	gosub validate_config_loc
	callpoint!.setUserInput(config_loc$)
	if abort then break

	if cvs(config_loc$,3)<>cvs(callpoint!.getDevObject("prev_config_loc"),3)
		rem --- Capture current config location value so can tell later if it's been changed
		callpoint!.setDevObject("prev_config_loc",config_loc$)

		rem --- Update grid
		vectRows!=callpoint!.getDevObject("vectRows")
		if vectRows!.size()>0 then
			numCols=num(callpoint!.getDevObject("def_rpts_cols"))
			for i=0 to vectRows!.size()-1 step numCols
				source_value$=vectRows!.getItem(i+2)
				if cvs(vectRows!.getItem(i+3),3)="" then
					gosub source_target_value
					vectRows!.setItem(i+3, target_value$)
				endif
			next i

			gosub fill_grid
			util.resizeWindow(Form!, SysGui!)
		endif
	endif
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

rem --- Validate new config location

	config_loc$=callpoint!.getColumnData("ADX_COPYMODS.NEW_CONFIG_LOC")
	gosub validate_config_loc
	callpoint!.setColumnData("ADX_COPYMODS.NEW_CONFIG_LOC", config_loc$)
	if abort then break

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
		type$=cvs(gridStbls!.getCellText(i/numCols,0),3)

		if type$="STBL" or type$="SYSSTBL"
			aList!=new ArrayList()
			aList!.add(gridStbls!.getCellText(i/numCols,2)); rem --- source value
			aList!.add(gridStbls!.getCellText(i/numCols,3)); rem --- target value
			stblMap!.put(gridStbls!.getCellText(i/numCols,1), aList!)
		endif

		if type$="PREFIX" or type$="SYSPFX"
			aList!=new ArrayList()
			aList!.add(gridStbls!.getCellText(i/numCols,2)); rem --- source value
			aList!.add(gridStbls!.getCellText(i/numCols,3)); rem --- target value
			pfxList!.add(aList!)
		endif
	next i

	callpoint!.setDevObject("stblMap",stblMap!)
	callpoint!.setDevObject("pfxList",pfxList!)
[[ADX_COPYMODS.BSHO]]
rem --- Declare Java classes used

	use java.io.File
	use java.util.ArrayList
	use java.util.HashMap
	use ::ado_file.src::FileObject

rem --- Initialize current values so can tell later if they've been changed
	callpoint!.setDevObject("prev_src_syn_file","")
	callpoint!.setDevObject("prev_config_loc","")
[[ADX_COPYMODS.SOURCE_SYN_FILE.AVAL]]
rem --- Validate source syn file

	source_syn$=callpoint!.getUserInput()
	gosub validate_source_syn
	
	if success and cvs(source_syn$,3)<>cvs(callpoint!.getDevObject("prev_src_syn_file"),3)
		rem --- Capture current source syn file value so can tell later if it's been changed
		callpoint!.setDevObject("prev_src_syn_file",source_syn$)

		rem --- Set default for new config location to MODS_DIR/vnnnn/
		rem --- Get vnnnn from VERSION_ID in the ADM_MODULES table
		rem --- Where ASC_COMP_ID comes from the SYSCOMP/ACOMP line of source syn file
		rem --- And ASC_PROD_ID comes from the SYSAPP/APROG line of source syn file
		synVersion$="00",comp_id$="",prod_id$=""
		synChan=unt
		open(synChan,isz=-1, err=file_not_found)source_syn$
		while 1
			read(synChan,end=*break)record$
			if(pos("="=record$)) then
				key$=record$(1,pos("="=record$)-1)

				rem --- locate lines to parse
				switch (BBjAPI().TRUE)
					case key$ = "ACOMP"
					case key$ = "SYSCOMP"
						rem --- parse ASC_COMP_ID from SYSCOMP/ACOMP line
						xpos=len(key$)+2
						comp_id$=record$(xpos, pos(";"=record$(xpos))-1)
						break
					case key$ = "APROD"
					case key$ = "SYSAPP"
						rem --- parse ASC_PROD_ID from SYSAPP/APROD line
						xpos=len(key$)+2
						prod_id$=record$(xpos, pos(";"=record$(xpos))-1)
						break
					case default
						break
				swend                    
			endif
			if comp_id$<>"" and prod_id$<>"" then break
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
		callpoint!.setDevObject("target_dir",targetDir$+"/config")
		synVersion$=version$
		callpoint!.setDevObject("syn_version",synVersion$)

		rem --- Initialize grid
		callpoint!.setStatus("REFRESH")
		gosub create_reports_vector
		gosub fill_grid
		util.resizeWindow(Form!, SysGui!)
	endif
	break

file_not_found:
	rem --- Cannot open syn file, so can't do much
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

	config_loc$=cvs(callpoint!.getColumnData("ADX_COPYMODS.NEW_CONFIG_LOC"),3)
	more=0
	synDev=unt
	open(synDev,isz=-1,err=*next)testfile$; more=1

	vectRows!=SysGUI!.makeVector()
	while more
		read(synDev,end=*break)record$

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
	callpoint!.setDevObject("vectRows",vectRows!)
	
	return

source_target_value: rem -- Set default new target value based on new config location

	rem --- If source holds a path, then need to initialize default new target value
	declare File aFile!
	aFile! = new File(source_value$)
	if aFile!.exists()
		target_value$=""
		filePath$=source_value$
		gosub fix_path
		sourcePath$=filePath$
		
		if config_loc$<>""
			rem --- Add version directory to path
			synVersion$="v"+callpoint!.getDevObject("syn_version")
			modsDir$=callpoint!.getDevObject("mods_dir")
			modsDir$=modsDir$(pos(":"=modsDir$)+1)+"/"; rem --- strip possible Windows drive ID and add trailing slash
			if aFile!.isDirectory() and filePath$(len(sourcePath$))<>"/" then sourcePath$=sourcePath$+"/"
			if pos(modsDir$=sourcePath$)

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
				newModsDir$=config_loc$(1,pos("/config/"=config_loc$+"/",-1))
				target_value$=newModsDir$+verDir$
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
		endif

		rem --- Target path needs to end with trailing slash (or not), the same as source path
		if filePath$(len(filePath$))="/"
			rem -- Add trailing slash as needed to target path
			if len(target_value$)>0 and target_value$(len(target_value$))<>"/" then target_value$=target_value$+"/"
		else
			rem -- Remove trailing slash as needed to target path
			if len(target_value$)>0 and target_value$(len(target_value$))="/" then target_value$=target_value$(1,(len(target_value$)-1))
		endif
	else
		target_value$=source_value$
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

validate_config_loc: rem --- Validate new config location

	abort=0
	filePath$=config_loc$
	gosub fix_path
	config_loc$=filePath$

	rem --- Remove trailing slashes (/ or \) from new config location

	while len(config_loc$) and pos(config_loc$(len(config_loc$),1)="/\")
		config_loc$ = config_loc$(1, len(config_loc$)-1)
	wend

	rem --- As necessary, add trailing “/config” or remove everything after it

	if pos("/config/"=config_loc$+"/")=0 then
		config_loc$=config_loc$+"/config"
	endif

	if pos("/config/"=config_loc$+"/",-1)<>len(config_loc$)-6 then
		config_loc$=config_loc$(1,pos("/config/"=config_loc$,-1)+6)
	endif

	rem --- Don’t allow current download location

	testLoc$=config_loc$
	gosub verify_not_download_loc
	if !loc_ok
		callpoint!.setColumnData("ADX_COPYMODS.NEW_CONFIG_LOC", config_loc$)
		callpoint!.setFocus("ADX_COPYMODS.NEW_CONFIG_LOC")
		callpoint!.setStatus("ABORT")
		abort=1
		return
	endif

	rem --- Cannot be same as sync file location

	source_syn$=callpoint!.getColumnData("ADX_COPYMODS.SOURCE_SYN_FILE")
	if ((new File(source_syn$)).getAbsolutePath()).toLowerCase().startsWith((new File(config_loc$)).getAbsolutePath().toLowerCase()+File.separator)
		msg_id$="AD_INSTALL_LOC_USED"
		gosub disp_message
		callpoint!.setColumnData("ADX_COPYMODS.NEW_CONFIG_LOC", config_loc$)
		callpoint!.setFocus("ADX_COPYMODS.NEW_CONFIG_LOC")
		callpoint!.setStatus("ABORT")
		abort=1
		return
	endif

	rem --- Read-Write-Execute directory permissions are required

	if !FileObject.isDirWritable(config_loc$)
		msg_id$="AD_DIR_NOT_WRITABLE"
		dim msg_tokens$[1]
		msg_tokens$[1]=config_loc$
		gosub disp_message

		callpoint!.setColumnData("ADX_COPYAON.NEW_INSTALL_LOC", config_loc$)
		callpoint!.setFocus("ADX_COPYAON.NEW_INSTALL_LOC")
		callpoint!.setStatus("ABORT")
		abort=1
		return
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
	rem --- Currently ON_GRID_CELL_VALIDATION results in the loss of user input when they Run Process (F5)
	rem --- before leaving the cell where text was entered. So don't use ON_GRID_CELL_VALIDATION for now.
	rem gridStbls!.setCallback(gridStbls!.ON_GRID_CELL_VALIDATION,"custom_event")
