[[IVE_TRANSHDR.ADEQ]]
print "HEADER: After delete query (ADEQ)"; rem debug
[[IVE_TRANSHDR.BOVE]]
print "HEADER: before table overview (BOVE)"; rem debug
[[IVE_TRANSHDR.BDEQ]]
print "HEADER: before delete query (BDEQ)"; rem debug
[[IVE_TRANSHDR.BDEL]]
print "HEADER: before record delete (BDEL)"; rem debug
[[IVE_TRANSHDR.ADIS]]
print "HEADER: After display record (ADIS)"; rem debug
[[IVE_TRANSHDR.AWRI]]
print "HEADER: after write record (AWRI)"; rem debug
[[IVE_TRANSHDR.ARER]]
print "HEADER: after new record ready (ARER)"; rem debug
[[IVE_TRANSHDR.ARAR]]
print "HEADER: after array transfer (ARAR)"; rem debug
[[IVE_TRANSHDR.BWRI]]
print "HEADER: before record write (BWRI)"; rem debug
[[IVE_TRANSHDR.AREA]]
print "HEADER: after record read (AREA)"; rem debug

rem --- Get trans code record and set flags
	
	rem can't use the method below because the data is not displayed yet
	rem trans_code$ = callpoint!.getColumnData("IVE_TRANSHDR.TRANS_CODE")
	trans_code$ = rec_data.trans_code$
	gosub get_trans_rec
[[IVE_TRANSHDR.AREC]]
print "HEADER: after new record (AREC)"; rem debug
[[IVE_TRANSHDR.TRANS_CODE.AINP]]
rem --- You can't modify the trans code use you've entered the record

	trans_code$      = pad( callpoint!.getUserInput(), 2)
	orig_trans_code$ = callpoint!.getColumnDiskData("IVE_TRANSHDR.TRANS_CODE")

	if cvs( orig_trans_code$, 2 ) <> "" and trans_code$ <> orig_trans_code$ then
		callpoint!.setMessage("IV_TRANS_CODE_CHANGE")
		callpoint!.setStatus("ABORT")
	endif
[[IVE_TRANSHDR.TRANS_CODE.AVAL]]
print "in TRANS_CODE.AVAL"; rem debug

rem --- Get trans code record and set flags

	trans_code$ = callpoint!.getUserInput()
	gosub get_trans_rec
[[IVE_TRANSHDR.TRANS_DATE.AVAL]]
rem --- Does date fall into the GL period?

	if user_tpl.gl$ = "Y" then
		date$ = callpoint!.getUserInput()
		call stbl("+DIR_PGM")+"glc_datecheck.aon",date$,"Y",period$,year$,status
		if status > 99 then callpoint!.setStatus("ABORT")
	endif
[[IVE_TRANSHDR.<CUSTOM>]]
rem --------------------------------------------------------------------------
get_trans_rec: rem --- Get Transaction Code Record
               rem  IN: trans_code$, file opened
               rem OUT: flags set
rem --------------------------------------------------------------------------

	transcode_dev  = fnget_dev("IVC_TRANCODE")
	trans_rec_tpl$ = fnget_tpl$("IVC_TRANCODE")
	dim trans_rec$:trans_rec_tpl$

	trans_key$ = firm_id$ + "B" + trans_code$
	find record(transcode_dev,key=trans_key$) trans_rec$

	user_tpl.trans_type$     = trans_rec.trans_type$
	user_tpl.trans_post_gl$  = trans_rec.post_gl$
	user_tpl.trans_adj_acct$ = trans_rec.gl_adj_acct$

	print "in get_trans_rec: Got transaction code and set user_tpl$; post to GL = ", user_tpl.trans_post_gl$; rem debug

	rem --- Disable grid columns based on params 
	if user_tpl.gl$ <> "Y" or user_tpl.trans_post_gl$ <> "Y" then 
		util.disableGridColumn(Form!, 3)
		print "G/L entry should be disabled"; rem debug
	endif

return

rem --------------------------------------------------------------------------
rem #include fnget_control.src
rem --------------------------------------------------------------------------

	rem   IN: ctl_name$    = name of control
	rem  OUT: get_control! = control object

	def fnget_control!(ctl_name$)
		ctlContext   = num( callpoint!.getTableColumnAttribute(ctl_name$,"CTLC") )
		ctlID        = num( callpoint!.getTableColumnAttribute(ctl_name$,"CTLI") )
		get_control! = SysGUI!.getWindow(ctlContext).getControl(ctlID)
		return get_control!
	fnend

rem #endinclude fnget_control.src

rem --------------------------------------------------------------------------
#include std_missing_params.src
rem --------------------------------------------------------------------------
[[IVE_TRANSHDR.BSHO]]
print 'show', ; rem debug

rem --- Pre-inits
	
	use ::ado_util.src::util
	pgmdir$ = stbl("+DIR_PGM")

rem --- Open files

	num_files=7
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVS_PARAMS",   open_opts$[1]="OTA"
	open_tables$[2]="GLS_PARAMS",   open_opts$[2]="OTA"
	open_tables$[3]="IVC_TRANCODE", open_opts$[3]="OTA"
	open_tables$[4]="IVE_TRANSDET", open_opts$[4]="OTA"
	open_tables$[5]="IVM_ITEMMAST", open_opts$[5]="OTA"
	open_tables$[6]="IVM_ITEMWHSE", open_opts$[6]="OTA"
	open_tables$[7]="IVM_LSMASTER", open_opts$[7]="OTA"

	gosub open_tables

	ivs01_dev=num(open_chans$[1])
	gls01_dev=num(open_chans$[2])
	dim ivs01a$:open_tpls$[1]
	dim gls01a$:open_tpls$[2]

rem --- Setup user template and object

	UserObj! = SysGUI!.makeVector(); rem to store objects in

	user_tpl_str$ = ""
	user_tpl_str$ = user_tpl_str$ + "gl:c(1),glw11:c(1*),ls:c(1),lf:c(1),m9:c(1*),prod_type:c(3),"
	user_tpl_str$ = user_tpl_str$ + "location_obj:u(1),qoh_obj:u(1),commit_obj:u(1),avail_obj:u(1),"
	user_tpl_str$ = user_tpl_str$ + "trans_post_gl:c(1),trans_type:c(1),trans_adj_acct:c(1*),"
	user_tpl_str$ = user_tpl_str$ + "this_item_lot_or_ser:u(1),lotted:u(1),serialized:u(1),ls_found:u(1),"
	user_tpl_str$ = user_tpl_str$ + "multi_whse:u(1),warehouse_id:c(2),avail:n(1*),commit:n(1*),qoh:n(1*),"
	user_tpl_str$ = user_tpl_str$ + "pgmdir:c(1*)"
	dim user_tpl$:user_tpl_str$

	user_tpl.pgmdir$ = pgmdir$

rem --- Setup for display fields on header

	location!    = fnget_control!( "<<DISPLAY>>.LOCATION" )
	qty_on_hand! = fnget_control!( "<<DISPLAY>>.QTY_ON_HAND" )
	qty_commit!  = fnget_control!( "<<DISPLAY>>.QTY_COMMIT" )
	qty_avail!   = fnget_control!( "<<DISPLAY>>.QTY_AVAIL" )

	user_tpl.location_obj = 0
	user_tpl.qoh_obj      = 1
	user_tpl.commit_obj   = 2
	user_tpl.avail_obj    = 3

	UserObj!.addItem( location! )
	UserObj!.addItem( qty_on_hand! )
	UserObj!.addItem( qty_commit! )
	UserObj!.addItem( qty_avail! )

rem --- Get parameter records

	find record(ivs01_dev,key=firm_id$+"IV00",dom=std_missing_params) ivs01a$
	find record(gls01_dev,key=firm_id$+"GL00",err=set_iv_params) gls01a$

	set_iv_params:
	user_tpl.multi_whse$ = ivs01a.multi_whse$
	user_tpl.warehouse_id$ = ivs01a.warehouse_id$

	rem --- If we're not multi-warehouse, disable column
	if ivs01a.multi_whse$ <> "Y" then
		util.disableGridColumn(Form!, 0)
	endif

rem --- Numeric masks

	user_tpl.m9$ = ivs01a.price_mask$
	call pgmdir$+"adc_sizemask.aon",user_tpl.m9$,ignore,8,10

rem --- Lotted flags, Lifo/fifo

	user_tpl.lotted = 0
	user_tpl.serialized = 0
	user_tpl.ls$ = "N"

	if ivs01a.lotser_flag$="L" then 
		user_tpl.ls$="Y"
		user_tpl.lotted=1
	else 
		if ivs01a.lotser_flag$="S" then 
			user_tpl.ls$="Y"
			user_tpl.serialized=1
		endif
	endif

	if pos(ivs01a.lifofifo$="LF") then user_tpl.lf$="Y" else user_tpl.lf$ = "N"

rem --- Is GL installed?

	status=0
	call pgmdir$+"glc_ctlcreate.aon",err=*next,pgm(-2),"IV",glw11$,gl$,status
	if status then goto std_exit
	user_tpl.gl$    = gl$
	user_tpl.glw11$ = glw11$

rem --- Final inits

	precision num(ivs01a.precision$)
