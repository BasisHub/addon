[[OPC_LINECODE.GL_REV_ACCT.AVAL]]
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
      callpoint!.setStatus("ACTIVATE-ABORT")
   endif
[[OPC_LINECODE.LINE_TYPE.AVAL]]
rem --- Disable fields that don't apply
	callpoint!.setColumnData("OPC_LINECODE.LINE_TYPE", callpoint!.getUserInput())
	gosub disable_ctls
[[OPC_LINECODE.AR_DIST_CODE.AVAL]]
rem --- Either fill or blank out 3 G/L display fields
	gosub display_gl_fields
[[OPC_LINECODE.PROD_TYPE_PR.AVAL]]
rem --- Maybe disable Product Type
	callpoint!.setColumnData("OPC_LINECODE.PROD_TYPE_PR", callpoint!.getUserInput())
	gosub disable_ctls
[[OPC_LINECODE.DROPSHIP.AVAL]]
rem --- Maybe disable Distribution Code
	callpoint!.setColumnData("OPC_LINECODE.DROPSHIP", callpoint!.getUserInput())
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
#include std_functions.src
rem ========================================================
disable_ctls:rem --- Disable fields that don't apply
rem ========================================================
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
	if dropship$="Y"
		dmap$[5]=""
	endif

	rem --- Product Type Processing
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

	if cvs(callpoint!.getColumnData("OPC_LINECODE.MESSAGE_TYPE"),3)="" then callpoint!.setColumnData("OPC_LINECODE.MESSAGE_TYPE","B")

	callpoint!.setStatus("REFRESH")

	rem --- either fill or blank out 3 G/L display fields
	gosub display_gl_fields
return

rem ========================================================
display_gl_fields:rem --- fill or clear 3 G/L display fields
rem ========================================================
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
