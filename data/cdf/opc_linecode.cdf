[[OPC_LINECODE.LINE_TYPE.AVAL]]
rem --- Disable fields that don't apply
	gosub disable_ctls
[[OPC_LINECODE.AR_DIST_CODE.AVAL]]
rem --- Either fill or blank out 3 G/L display fields
	gosub display_gl_fields
[[OPC_LINECODE.MESSAGE_TYPE.BINP]]
rem --- Set default type
	if message_type$=" "
		callpoint!.setColumnData("OPC_LINECODE.MESSAGE_TYPE","B")
		callpoint!.setStatus("REFRESH")
	endif
[[OPC_LINECODE.PROD_TYPE_PR.AVAL]]
rem --- Maybe disable Product Type
	gosub disable_ctls
[[OPC_LINECODE.DROPSHIP.AVAL]]
rem --- Maybe disable Distribution Code
	gosub disable_ctls
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
rem --- Enable-Disable all fields
	gosub disable_ctls
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
disable_ctls:rem --- Disable fields that don't apply

	dim dctl$[7],dmap$[7]
	dctl$[1]="GL_REV_ACCT"
	dctl$[2]="TAXABLE_FLAG"
	dctl$[3]="DROPSHIP"
	dctl$[4]="PRODUCT_TYPE"
	dctl$[5]="AR_DIST_CODE"
	dctl$[6]="PROD_TYPE_PR"
	dctl$[7]="MESSAGE_TYPE"

	rem --- GL installed
	if user_tpl.gl$<>"Y"
		dmap$[1]="I"
	endif

	rem --- Line Types
	line_type$=callpoint!.getColumnData("OPC_LINECODE.LINE_TYPE")
	if line_type$ = "O"
		dmap$[3]="I"
		dmap$[5]="I"
		dmap$[7]="I"
	endif
	if line_type$="M"
		dmap$[1]="I"
		dmap$[2]="I"
		dmap$[3]="I"
		dmap$[4]="I"
		dmap$[5]="I"
		dmap$[6]="I"
	endif
	if line_type$="N"
		dmap$[1]="I"
		dmap$[7]="I"
	endif
	if line_type$="S"
		dmap$[1]="I"
		dmap$[4]="I"
		dmap$[5]="I"
		dmap$[6]="I"
		dmap$[7]="I"
	endif
	if line_type$="P"
		dmap$[1]="I"
		dmap$[7]="I"
	endif

	rem --- Dropship
	dropship$=callpoint!.getColumnData("OPC_LINECODE.DROPSHIP")
	if rec_data.dropship$="Y"
		dmap$[5]=""
	endif

	rem --- Produce Type Processing
	prod_type_pr$=callpoint!.getColumnData("OPC_LINECODE.PROD_TYPE_PR")
	if prod_type_pr$<>"D"
		dmap$[4]="I"
	endif

	rem --- disable selected controls
	for dctl=1 to 7
		dctl$=dctl$[dctl]
		wctl$=str(num(callpoint!.getTableColumnAttribute(dctl$,"CTLI")):"00000")
		wmap$=callpoint!.getAbleMap()
		wpos=pos(wctl$=wmap$,8)
		wmap$(wpos+6,1)=dmap$[dctl]
		callpoint!.setAbleMap(wmap$)
		callpoint!.setStatus("ABLEMAP")

		rem --- clear disabled fields
		if dmap$[dctl] = "I" then
			callpoint!.setColumnData("OPC_LINECODE."+dctl$,"")
		endif
	next dctl
	callpoint!.setStatus("REFRESH")

	rem --- either fill or blank out 3 G/L display fields
	gosub display_gl_fields
return

display_gl_fields:rem --- fill or clear 3 G/L display fields
	if user_tpl.gl$="Y"
		dist_code$=callpoint!.getColumnData("OPC_LINECODE.AR_DIST_CODE")
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
return
