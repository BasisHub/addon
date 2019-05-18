[[APX_EXPORT1099.BSHO]]
rem --- Declare Java classes used

	use java.io.File
	use ::ado_file.src::FileObject
[[APX_EXPORT1099.ASVA]]
rem --- validate export directory (create if needed), and confirm read/write access

	export_loc$=cvs(callpoint!.getColumnData("APX_EXPORT1099.EXPORT_LOC"),3)
	abort=0

	if export_loc$=""
		abort=1
	else
		export_loc!=export_loc$
		export_loc$=export_loc!.replace("\","/")

		rem --- Fix path for this OS
		current_dir$=dir("")
		current_drive$=dsk("",err=*next)
		success=0
	    	FileObject.makeDirs(new File(export_loc$),err=*next);success=1
		if success
			success=0
			chdir(export_loc$),err=*next;success=1
			if success
				export_loc$=current_drive$+dir("")
				chdir(current_dir$)

				rem --- Read-Write-Execute directory permissions are required

				if !FileObject.isDirWritable(export_loc$)
					msg_id$="AD_DIR_NOT_WRITABLE"
					dim msg_tokens$[1]
					msg_tokens$[1]=export_loc$
					gosub disp_message
					abort=1
				endif
			else
				abort=1
			endif
		else
			abort=1	
		endif
	endif

	if abort
		callpoint!.setColumnData("APX_EXPORT1099.EXPORT_LOC", export_loc$)
		callpoint!.setFocus("APX_EXPORT1099.EXPORT_LOC")
		callpoint!.setStatus("ABORT")
	endif

