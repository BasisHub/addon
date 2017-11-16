[[POT_INVDET.MEMO_1024.BINQ]]
rem --- Launch Comments dialog
	gosub comment_entry
	callpoint!.setStatus("ABORT")
[[POT_INVDET.<CUSTOM>]]
comment_entry: rem --- When the Comment field is accessed, launch the new memo_1024 editor instead
	disp_text$=callpoint!.getColumnData("POT_INVDET.MEMO_1024")
	editable$="NO"
	force_loc$="NO"
	baseWin!=null()
	startx=0
	starty=0
	shrinkwrap$="NO"
	html$="NO"
	dialog_result$=""

	call stbl("+DIR_SYP")+ "bax_display_text.bbj",
:		"PO Invoice Detail Comments",
:		disp_text$, 
:		table_chans$[all], 
:		editable$, 
:		force_loc$, 
:		baseWin!, 
:		startx, 
:		starty, 
:		shrinkwrap$, 
:		html$, 
:		dialog_result$

	return
[[POT_INVDET.AOPT-COMM]]
rem --- Launch Comments dialog
	gosub comment_entry
[[POT_INVDET.AGDS]]
rem --- Set column size for memo_1024 field very small so it doesn't take up room, but still available for hover-over of memo contents
	use ::ado_util.src::util
	grid! = form!.getControl(num(stbl("+GRID_CTL")))
	col_hdr$=callpoint!.getTableColumnAttribute("POT_INVDET.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(grid!, col_hdr$)
	grid!.setColumnWidth(memo_1024_col,15)
