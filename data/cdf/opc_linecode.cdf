[[OPC_LINECODE.AR_DIST_CODE.AVAL]]
rem --- Either fill or blank out 3 G/L display fields
	dist_code$=callpoint!.getUserInput()
	if user_tpl.gl$="Y"
		if cvs(dist_code$,2)=""
			callpoint!.setColumnData("<<DISPLAY>>.GL_COGS_ACCT","")
			callpoint!.setColumnData("<<DISPLAY>>.GL_INV_ACCT","")
			callpoint!.setColumnData("<<DISPLAY>>.GL_SLS_ACCT","")
		else
			dim dist_tpl$:user_tpl.dist_tpl$
			read record (user_tpl.dist_dev,key=firm_id$+"D"+dist_code$,dom=*next) dist_tpl$
			callpoint!.setColumnData("<<DISPLAY>>.GL_SLS_ACCT",dist_tpl.gl_sls_acct$)
			callpoint!.setColumnData("<<DISPLAY>>.GL_INV_ACCT",dist_tpl.gl_inv_acct$)
			callpoint!.setColumnData("<<DISPLAY>>.GL_COGS_ACCT",dist_tpl.gl_cogs_acct$)
		endif
		callpoint!.setStatus("REFRESH")
	endif
[[OPC_LINECODE.MESSAGE_TYPE.BINP]]
rem --- Set default type
	if message_type$=" "
		callpoint!.setColumnData("OPC_LINECODE.MESSAGE_TYPE","B")
		callpoint!.setStatus("REFRESH")
	endif
[[OPC_LINECODE.PROD_TYPE_PR.AVAL]]
rem --- Maybe disable Product Type
	dctl$="PRODUCT_TYPE"
	if callpoint!.getUserInput()<>"D"
		dmap$="I"
	else
		if pos(line_type$="NOP")=0
			dmap$="I"
		else
			dmap$=""
		endif
	endif
	gosub disable_ctl
[[OPC_LINECODE.DROPSHIP.AVAL]]
rem --- Check Distribution Code
	if line_type$="S" and callpoint!.getUserInput()="N"
		callpoint!.setColumnData("OPC_LINECODE.AR_DIST_CODE","")
		callpoint!.setStatus("REFRESH")
	endif
[[OPC_LINECODE.BSHO]]
rem --- Open Distribution Code file
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARC_DISTCODE",open_opts$[1]="OTA"
	gosub open_tables
	arc_dist_dev=num(open_chans$[1]),arc_dist_tpl$=open_tpls$[1]
rem --- setup for G/L Parameter
	call stbl("+DIR_PGM")+"adc_application.aon","OP",info$[all]
	dim user_tpl$:"gl:c(1),dist_dev:n(4),dist_tpl:c(500)"
	user_tpl.gl$=info$[9]
	user_tpl.dist_dev=arc_dist_dev
	user_tpl.dist_tpl$=arc_dist_tpl$
[[OPC_LINECODE.ARAR]]
rem --- Re-enable all fields

	dim dctl$[7],dmap$[7]
	dctl$[1]="GL_REV_ACCT"
	dctl$[2]="TAXABLE_FLAG"
	dctl$[3]="DROPSHIP"
	dctl$[4]="PRODUCT_TYPE"
	dctl$[5]="AR_DIST_CODE"
	dctl$[6]="PROD_TYPE_PR"
	dctl$[7]="MESSAGE_TYPE"
	line_type$=callpoint!.getColumnData("OPC_LINECODE.LINE_TYPE")
	if user_tpl.gl$<>"Y"
		dmap$[1]="I"
	endif
	if rec_data.line_type$ = "O"
		dmap$[3]="I"
		dmap$[5]="I"
		dmap$[7]="I"
	endif
	if rec_data.line_type$="M"
		dmap$[1]="I"
		dmap$[2]="I"
		dmap$[3]="I"
		dmap$[4]="I"
		dmap$[5]="I"
		dmap$[6]="I"
	endif
	if rec_data.line_type$="N"
		dmap$[1]="I"
		dmap$[7]="I"
	endif
	if rec_data.line_type$="S"
		dmap$[1]="I"
		dmap$[4]="I"
		dmap$[5]="I"
		dmap$[6]="I"
		dmap$[7]="I"
	endif
	if rec_data.line_type$="P"
		dmap$[1]="I"
		dmap$[7]="I"
	endif
	if rec_data.dropship$="Y"
		dmap$[5]=""
	endif
	if rec_data.prod_type_pr$<>"D"
		dmap$[4]="I"
	endif
	gosub disable_ctls

rem --- Either fill or blank out 3 G/L display fields

	if user_tpl.gl$="Y"
		if cvs(rec_data.ar_dist_code$,2)=""
			callpoint!.setColumnData("<<DISPLAY>>.GL_COGS_ACCT","")
			callpoint!.setColumnData("<<DISPLAY>>.GL_INV_ACCT","")
			callpoint!.setColumnData("<<DISPLAY>>.GL_SLS_ACCT","")
		else
			dim dist_tpl$:user_tpl.dist_tpl$
			read record (user_tpl.dist_dev,key=firm_id$+"D"+rec_data.ar_dist_code$,dom=*next) dist_tpl$
			callpoint!.setColumnData("<<DISPLAY>>.GL_SLS_ACCT",dist_tpl.gl_sls_acct$)
			callpoint!.setColumnData("<<DISPLAY>>.GL_INV_ACCT",dist_tpl.gl_inv_acct$)
			callpoint!.setColumnData("<<DISPLAY>>.GL_COGS_ACCT",dist_tpl.gl_cogs_acct$)
		endif
	endif
[[OPC_LINECODE.BREA]]
rem --- re-enable all fields
	dim dctl$[7],dmap$[7]
	dctl$[1]="GL_REV_ACCT"
	dctl$[2]="TAXABLE_FLAG"
	dctl$[3]="DROPSHIP"
	dctl$[4]="PRODUCT_TYPE"
	dctl$[5]="AR_DIST_CODE"
	dctl$[6]="PROD_TYPE_PR"
	dctl$[7]="MESSAGE_TYPE"
	gosub disable_ctls
[[OPC_LINECODE.<CUSTOM>]]
disable_ctls:rem --- disable selected controls
for dctl=1 to 7
	dctl$=dctl$[dctl]
	wctl$=str(num(callpoint!.getTableColumnAttribute(dctl$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=dmap$[dctl]
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP")
next dctl
return
disable_ctl:rem --- disable selected controls
	wctl$=str(num(callpoint!.getTableColumnAttribute(dctl$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=dmap$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP")
return

