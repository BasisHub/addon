[[IVE_TRANSHDR.AWRI]]
print "HEADER: after write record"
[[IVE_TRANSHDR.ARER]]
print "HEADER: after new record ready"
[[IVE_TRANSHDR.ARAR]]
print "HEADER: after array transfer"
[[IVE_TRANSHDR.BWRI]]
print "HEADER: before record write"; rem debug

goto bwri_done; rem *** DISABLED ***

curDtl! = SysGUI!.makeVector()
curDtl! = GridVect!.getItem(0)
origDtl! = UserObj!.getItem( user_tpl.orig_dtl ); rem getting the orig rec does not work

rem --- Loop thru each current line, commit inventory

cur_size = curDtl!.size()
transdet_tpl$ = user_tpl.transdet_tpl$
pgmdir$ = stbl("+DIR_PGM")

rem Initialize inventory item update
call pgmdir$+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
if status then goto std_exit

for rec=0 to cur_size - 1
	dim currdet_rec$:transdet_tpl$
	dim origdet_rec$:transdet_tpl$
	currdet_rec$ = curDtl!.getItem(rec)
	
	if currdet_rec$ = "" then 
		break
	endif
	
	curr_whse$   = currdet_rec.warehouse_id$
	curr_item$   = currdet_rec.item_id$
	curr_qty     = num( currdet_rec.trans_qty$ )
	origdet_rec$ = fnget_record$(origDtl!, currdet_rec.sequence_no$)
	
	if origdet_rec$ = "" then
		orig_qty   = 0
		orig_whse$ = ""
		orig_item$ = ""
	else
		orig_qty   = num( origdet_rec.trans_qty$ )
		orig_whse$ = currdet_rec.warehouse_id$
		orig_item$ = currdet_rec.item_id$
	endif
	
	rem 0510 DIM IV_FILES[44],IV_INFO$[3],IV_INFO[0],IV_PARAMS$[4]
	rem 0513 PRECISION I[2]
	rem 0515 DIM IV_PARAMS[5],IV_REFS$[11],IV_REFS[5]
	rem 0520 LET IV_FILES[0]=SYS01_DEV,IV_FILES[1]=IVM01_DEV,IV_FILES[2]=IVM02_DEV
	rem 3530 LET QNTY=W[0]-PREV_QTY,ACTION$="CO"
	rem 5520 LET IV_INFO$[1]=PREV_WH_ITEM$(1,2),IV_INFO$[2]=PREV_WH_ITEM$(3),IV_INFO$[3]=PREV_LOT_SER$
	rem 5530 LET IV_REFS[0]=QNTY
	rem 5550 CALL "ivc_ua.bbx",ACTION$,IV_FILES[ALL],IV_INFO[ALL],IV_PARAMS$[ALL],IV_INFO$[ALL],IV_REFS$[ALL],IV_REFS[ALL],IV_STATUS
	
	print "Current, orig whse: ", curr_whse$, ", ", orig_whse$; rem debug
	print "Current, orig item: ", curr_item$, ", ", orig_item$; rem debug
	print "Current, orig qty : ", curr_qty, ", ", orig_qty; rem debug

	rem Should we commit inventory?
	rem debug: this is the correct logic, but orig rec is not set correctly
	rem debug: force posting

rem 	if	orig_whse$ <> curr_whse$ or 
rem :		orig_item$ <> curr_item$ or 
rem :		( orig_qty <> curr_qty and orig_qty <> 0 ) 
rem :	then

		rem If item and warehouse haven't changed, commit difference
		if orig_whse$ = curr_whse$ and orig_item$ = curr_item$ then
			items$[1] = curr_whse$
			items$[2] = curr_item$
			refs[0]   = curr_qty - orig_qty

			call pgmdir$+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],status
			if status then escape; rem problem committing 
		else
			rem Items are different: uncommit previous
			items$[1] = orig_whse$
			items$[2] = orig_item$
			
			if user_tpl.prod_trans_type$ = "A" then
				refs[0] = -orig_qty
			else
				refs[0] = orig_qty
			endif
			
			call pgmdir$+"ivc_itemupdt.aon","UC",chan[all],ivs01a$,items$[all],refs$[all],refs[all],status
			if status then escape; rem problem uncommitting previous qty
			
			rem Commit current
			items$[1] = curr_whse$
			items$[2] = curr_item$
			refs[0]   = curr_qty
			
			call pgmdir$+"ivc_itemupdt.aon","CO",chan[all],ivs01a$,items$[all],refs$[all],refs[all],status
			if status then escape; rem problem committing current qty
		endif
	
	rem endif
	
next rec

rem --- Find original detail line from the sequence number

def fnget_record$(thisVect!, seq_no$)
	dim this_rec$:transdet_tpl$
	this_size = thisVect!.size()
	found_it = 0

	if this_size = 1 then 
		return ""
	endif

	for ii=0 to this_size-1
		this_rec$ = thisVect!.getItem(ii)
		if this_rec$ <> "" and this_rec.sequence_no$ = seq_no$ then
			found_it = 1
			break
		endif
	next ii

	if found_it then
		return this_rec$
	else
		return ""
	endif

fnend

bwri_done:
[[IVE_TRANSHDR.BWAR]]
print "HEADER: before write array"
[[IVE_TRANSHDR.BREC]]
print "HEADER: before new record"
[[IVE_TRANSHDR.AREA]]
print "HEADER: after record read"; rem debug
[[IVE_TRANSHDR.AREC]]
print "HEADER: after new record"; rem escape
[[IVE_TRANSHDR.TRANS_CODE.AINP]]
rem --- You can't modify the trans code use you've entered the record

trans_code$      = pad( callpoint!.getUserInput(), 2)
orig_trans_code$ = callpoint!.getColumnDiskData("IVE_TRANSHDR.TRANS_CODE")

if cvs( orig_trans_code$, 2 ) <> "" and trans_code$ <> orig_trans_code$ then
	call stbl("+DIR_SYP")+"bac_message.bbj","IV_TRANS_CODE_CHANGE",msg_tokens$[all],msg_opt$,table_chans$[all]
	callpoint!.setStatus("ABORT")
endif
[[IVE_TRANSHDR.TRANS_CODE.AVAL]]
rem --- Get Transaction Code Record

	transcode_dev  = fnget_dev("IVC_TRANCODE")
	trans_rec_tpl$ = fnget_tpl$("IVC_TRANCODE")
	dim trans_rec$:trans_rec_tpl$

	trans_key$ = firm_id$ + "B" + callpoint!.getUserInput()
	find record(transcode_dev,key=trans_key$) trans_rec$

	user_tpl.trans_type$     = trans_rec.trans_type$
	user_tpl.trans_post_gl$  = trans_rec.post_gl$
	user_tpl.trans_adj_acct$ = trans_rec.gl_adj_acct$

	rem --- Disable GL is necessary

	if trans_rec.post_gl$ = "N" then
		w!=Form!.getChildWindow(1109)
		c!=w!.getControl(5900)
		c!.setColumnEditable(3,0)
	endif
[[IVE_TRANSHDR.TRANS_DATE.AVAL]]
rem --- Does date fall into the GL period?

if user_tpl.gl$ = "Y" then
	date$ = callpoint!.getUserInput()
	call stbl("+DIR_PGM")+"glc_datecheck.aon",date$,"Y",period$,year$,status
	if status > 99 then callpoint!.setStatus("ABORT")
endif
[[IVE_TRANSHDR.<CUSTOM>]]
rem #include fnget_control.src

def fnget_control!(ctl_name$)

rem   IN: ctl_name$    = name of control
rem  OUT: get_control! = control object

ctlContext   = num( callpoint!.getTableColumnAttribute(ctl_name$,"CTLC") )
ctlID        = num( callpoint!.getTableColumnAttribute(ctl_name$,"CTLI") )
get_control! = SysGUI!.getWindow(ctlContext).getControl(ctlID)
return get_control!

fnend

rem #endinclude fnget_control.src

#include std_missing_params.src
[[IVE_TRANSHDR.BSHO]]
rem --- Pre-inits

rem print 'show', 
pgmdir$ = stbl("+DIR_PGM")

rem --- Open files

num_files=6
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="IVS_PARAMS",   open_opts$[1]="OTA"
open_tables$[2]="GLS_PARAMS",   open_opts$[2]="OTA"
open_tables$[3]="IVC_TRANCODE", open_opts$[3]="OTA"
open_tables$[4]="IVE_TRANSDET", open_opts$[4]="OTA"
open_tables$[5]="IVM_ITEMMAST", open_opts$[5]="OTA"
open_tables$[6]="IVM_ITEMWHSE", open_opts$[6]="OTA"
gosub open_tables
ivs01_dev=num(open_chans$[1])
gls01_dev=num(open_chans$[2])
dim ivs01a$:open_tpls$[1]
dim gls01a$:open_tpls$[2]

rem --- Setup user template and object

UserObj! = SysGUI!.makeVector(); rem to store objects in

user_tpl_str$ = ""
user_tpl_str$ = user_tpl_str$ + "gl:c(1),ls:c(1),glw11:c(1*),m9:c(1*),prod_type:c(3),"
user_tpl_str$ = user_tpl_str$ + "location_obj:i(1),qoh_obj:i(1),commit_obj:i(1),avail_obj:i(1),"
user_tpl_str$ = user_tpl_str$ + "trans_post_gl:c(1),trans_type:c(1),trans_adj_acct:c(1*),"
user_tpl_str$ = user_tpl_str$ + "prev_wh_item:c(1*),prev_lot_ser:c(1*),prev_qty:n(1),this_item_lot_or_ser:i(1)"
dim user_tpl$:user_tpl_str$

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

dim i[5],g[1]
findrecord(ivs01_dev,key=firm_id$+"IV00",dom=std_missing_params)ivs01a$; rem p1$, p2$, p3$, p4$, m0$, m1$, m2$, m3$
findrecord(gls01_dev,key=firm_id$+"GL00",err=set_iv_params)gls01a$; rem g1$, g2$, g5$
rem g[0] = num(gls01a.acct_length$)
rem g[1] = num(gls01a.max_acct_len$)
rem lf$ = "N"
ls$ = "N"

set_iv_params:
rem i[0] = num(ivs01a.item_id_len$)
rem i[1] = num(ivs01a.ls_no_len$)
rem i[3] = num(ivs01a.desc_len_01$)
rem i[4] = num(ivs01a.desc_len_02$)
rem i[5] = num(ivs01a.desc_len_03$)

rem --- Numeric masks

user_tpl.m9$ = ivs01a.price_mask$
call pgmdir$+"adc_sizemask.aon",user_tpl.m9$,ignore,8,10

rem --- Lotted flags

rem p8$="",lotted=0,serialized=0

if ivs01a.lotser_flag$="L" then 
	ls$="Y"
	rem lotted=1
	rem p8$="Lot Number" 
else 
	if ivs01a.lotser_flag$="S" then 
		ls$="Y"
		rem serialized=1
		rem p8$="Serial Number"
	endif
endif

user_tpl.ls$ = ls$

rem if pos(ivs01a.lifofifo$="LF") then lf$="Y"

rem --- Is GL installed?

status=0
call pgmdir$+"glc_ctlcreate.aon",err=*next,pgm(-2),"IV",glw11$,gl$,status
if status then goto std_exit
user_tpl.gl$    = gl$
user_tpl.glw11$ = glw11$

rem --- Disable grid columns based on params (does this work?)

w!=Form!.getChildWindow(1109)
c!=w!.getControl(5900)

if gl$="N" then c!.setColumnEditable(3,0)

if ls$="N" then
	c!.setColumnEditable(4,0)
	c!.setColumnEditable(5,0)
	c!.setColumnEditable(6,0)
endif

rem --- Final inits

precision num(ivs01a.precision$)
