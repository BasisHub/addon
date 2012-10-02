[[OPC_TAXCODE.OP_TAX_CODE.AVAL]]
rem --- Don't allow add of blank code
while 1
	code$=callpoint!.getUserInput()
	if cvs(code$,2)=""
		find (user_tpl.opm06_dev,key=firm_id$+code$,dom=*next);break
		callpoint!.setMessage("INVALID_ENTRY")
		callpoint!.setStatus("ABORT")
	endif
	break
wend
[[OPC_TAXCODE.GL_ACCOUNT.BINP]]
if user_tpl.gl_installed$="Y"
	callpoint!.setTableColumnAttribute("OPC_TAXCODE.GL_ACCOUNT","MINL","1")
endif
[[OPC_TAXCODE.TAX_RATE.AVAL]]
rem --- Enable/Disable G/L Account"
	if user_tpl.gl$<>"Y" or num(callpoint!.getUserInput())=0
		enableit$="I"
	else
		enableit$=""
	endif
	gosub able_gl

	user_tpl.this_rate=num(callpoint!.getUserInput())
	gosub calc_total
[[OPC_TAXCODE.AR_TOT_CODE_10.AVAL]]
rem --- Put new rate into array and calc total
	cur_fld=10
	gosub check_code
	if ok$="Y"
		opm06_dev=user_tpl.opm06_dev
		dim opm06a$:user_tpl.opm06_tpl$
		next_code$=callpoint!.getUserInput()
		read record (opm06_dev,key=firm_id$+next_code$,dom=*next) opm06a$
		field user_tpl$,"code",[10]=callpoint!.getUserInput()
		field user_tpl$,"rate",[10]=opm06a.tax_rate
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_10",opm06a.code_desc$)
		callpoint!.setColumnData("<<DISPLAY>>.TAX_RATE_10",opm06a.tax_rate$)
		gosub calc_total
	else
		callpoint!.setUserInput("")
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_10","")
		callpoint!.setStatus("REFRESH")
	endif
[[OPC_TAXCODE.AR_TOT_CODE_09.AVAL]]
rem --- Put new rate into array and calc total
	cur_fld=9
	gosub check_code
	if ok$="Y"
		opm06_dev=user_tpl.opm06_dev
		dim opm06a$:user_tpl.opm06_tpl$
		next_code$=callpoint!.getUserInput()
		read record (opm06_dev,key=firm_id$+next_code$,dom=*next) opm06a$
		field user_tpl$,"code",[9]=callpoint!.getUserInput()
		field user_tpl$,"rate",[9]=opm06a.tax_rate
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_09",opm06a.code_desc$)
		callpoint!.setColumnData("<<DISPLAY>>.TAX_RATE_09",opm06a.tax_rate$)
		gosub calc_total
	else
		callpoint!.setUserInput("")
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_09","")
		callpoint!.setStatus("REFRESH")
	endif
[[OPC_TAXCODE.AR_TOT_CODE_06.AVAL]]
rem --- Put new rate into array and calc total
	cur_fld=6
	gosub check_code
	if ok$="Y"
		opm06_dev=user_tpl.opm06_dev
		dim opm06a$:user_tpl.opm06_tpl$
		next_code$=callpoint!.getUserInput()
		read record (opm06_dev,key=firm_id$+next_code$,dom=*next) opm06a$
		field user_tpl$,"code",[6]=callpoint!.getUserInput()
		field user_tpl$,"rate",[6]=opm06a.tax_rate
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_06",opm06a.code_desc$)
		callpoint!.setColumnData("<<DISPLAY>>.TAX_RATE_06",opm06a.tax_rate$)
		gosub calc_total
	else
		callpoint!.setUserInput("")
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_06","")
		callpoint!.setStatus("REFRESH")
	endif
[[OPC_TAXCODE.AR_TOT_CODE_07.AVAL]]
rem --- Put new rate into array and calc total
	cur_fld=7
	gosub check_code
	if ok$="Y"
		opm06_dev=user_tpl.opm06_dev
		dim opm06a$:user_tpl.opm06_tpl$
		next_code$=callpoint!.getUserInput()
		read record (opm06_dev,key=firm_id$+next_code$,dom=*next) opm06a$
		field user_tpl$,"code",[7]=callpoint!.getUserInput()
		field user_tpl$,"rate",[7]=opm06a.tax_rate
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_07",opm06a.code_desc$)
		callpoint!.setColumnData("<<DISPLAY>>.TAX_RATE_07",opm06a.tax_rate$)
		gosub calc_total
	else
		callpoint!.setUserInput("")
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_07","")
		callpoint!.setStatus("REFRESH")
	endif
[[OPC_TAXCODE.AR_TOT_CODE_08.AVAL]]
rem --- Put new rate into array and calc total
	cur_fld=8
	gosub check_code
	if ok$="Y"
		opm06_dev=user_tpl.opm06_dev
		dim opm06a$:user_tpl.opm06_tpl$
		next_code$=callpoint!.getUserInput()
		read record (opm06_dev,key=firm_id$+next_code$,dom=*next) opm06a$
		field user_tpl$,"code",[8]=callpoint!.getUserInput()
		field user_tpl$,"rate",[8]=opm06a.tax_rate
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_08",opm06a.code_desc$)
		callpoint!.setColumnData("<<DISPLAY>>.TAX_RATE_08",opm06a.tax_rate$)
		gosub calc_total
	else
		callpoint!.setUserInput("")
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_08","")
		callpoint!.setStatus("REFRESH")
	endif
[[OPC_TAXCODE.AR_TOT_CODE_05.AVAL]]
rem --- Put new rate into array and calc total
	cur_fld=5
	gosub check_code
	if ok$="Y"
		opm06_dev=user_tpl.opm06_dev
		dim opm06a$:user_tpl.opm06_tpl$
		next_code$=callpoint!.getUserInput()
		read record (opm06_dev,key=firm_id$+next_code$,dom=*next) opm06a$
		field user_tpl$,"code",[5]=callpoint!.getUserInput()
		field user_tpl$,"rate",[5]=opm06a.tax_rate
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_05",opm06a.code_desc$)
		callpoint!.setColumnData("<<DISPLAY>>.TAX_RATE_05",opm06a.tax_rate$)
		gosub calc_total
	else
		callpoint!.setUserInput("")
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_05","")
		callpoint!.setStatus("REFRESH")
	endif
[[OPC_TAXCODE.AR_TOT_CODE_04.AVAL]]
rem --- Put new rate into array and calc total
	cur_fld=4
	gosub check_code
	if ok$="Y"
		opm06_dev=user_tpl.opm06_dev
		dim opm06a$:user_tpl.opm06_tpl$
		next_code$=callpoint!.getUserInput()
		read record (opm06_dev,key=firm_id$+next_code$,dom=*next) opm06a$
		field user_tpl$,"code",[4]=callpoint!.getUserInput()
		field user_tpl$,"rate",[4]=opm06a.tax_rate
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_04",opm06a.code_desc$)
		callpoint!.setColumnData("<<DISPLAY>>.TAX_RATE_04",opm06a.tax_rate$)
		gosub calc_total
	else
		callpoint!.setUserInput("")
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_04","")
		callpoint!.setStatus("REFRESH")
	endif
[[OPC_TAXCODE.AR_TOT_CODE_03.AVAL]]
rem --- Put new rate into array and calc total
	cur_fld=3
	gosub check_code
	if ok$="Y"
		opm06_dev=user_tpl.opm06_dev
		dim opm06a$:user_tpl.opm06_tpl$
		next_code$=callpoint!.getUserInput()
		read record (opm06_dev,key=firm_id$+next_code$,dom=*next) opm06a$
		field user_tpl$,"code",[3]=callpoint!.getUserInput()
		field user_tpl$,"rate",[3]=opm06a.tax_rate
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_03",opm06a.code_desc$)
		callpoint!.setColumnData("<<DISPLAY>>.TAX_RATE_03",opm06a.tax_rate$)
		gosub calc_total
	else
		callpoint!.setUserInput("")
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_03","")
		callpoint!.setStatus("REFRESH")
	endif
[[OPC_TAXCODE.AR_TOT_CODE_02.AVAL]]
rem --- Put new rate into array and calc total
	cur_fld=2
	gosub check_code
	if ok$="Y"
		opm06_dev=user_tpl.opm06_dev
		dim opm06a$:user_tpl.opm06_tpl$
		next_code$=callpoint!.getUserInput()
		read record (opm06_dev,key=firm_id$+next_code$,dom=*next) opm06a$
		field user_tpl$,"code",[2]=callpoint!.getUserInput()
		field user_tpl$,"rate",[2]=opm06a.tax_rate
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_02",opm06a.code_desc$)
		callpoint!.setColumnData("<<DISPLAY>>.TAX_RATE_02",opm06a.tax_rate$)
		gosub calc_total
	else
		callpoint!.setUserInput("")
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_02","")
		callpoint!.setStatus("REFRESH")
	endif
[[OPC_TAXCODE.BREC]]
rem --- clear out temporary rates
	for x=1 to 10
		field user_tpl$,"code",[x]=""
		field user_tpl$,"rate",[x]=0
	next x
	field user_tpl$,"this_rate"=0
	field user_tpl$,"this_code"=""
[[OPC_TAXCODE.AR_TOT_CODE_01.AVAL]]
rem --- Put new rate into array and calc total
	cur_fld=1
	gosub check_code
	if ok$="Y"
		opm06_dev=user_tpl.opm06_dev
		dim opm06a$:user_tpl.opm06_tpl$
		next_code$=callpoint!.getUserInput()
		read record (opm06_dev,key=firm_id$+next_code$,dom=*next) opm06a$
		field user_tpl$,"code",[1]=callpoint!.getUserInput()
		field user_tpl$,"rate",[1]=opm06a.tax_rate
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_01",opm06a.code_desc$)
		callpoint!.setColumnData("<<DISPLAY>>.TAX_RATE_01",opm06a.tax_rate$)
		gosub calc_total
	else
		callpoint!.setUserInput("")
		callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_01","")
		callpoint!.setStatus("REFRESH")
	endif
[[OPC_TAXCODE.ARAR]]
rem --- Calculate and display all the extra tax codes
	if user_tpl.gl$<>"Y" or rec_data.tax_rate=0
		enableit$="I"
	else
		enableit$=""
	endif
	gosub able_gl
	opm06_dev=user_tpl.opm06_dev
	dim opm06a$:user_tpl.opm06_tpl$
	callpoint!.setColumnData("<<DISPLAY>>.TAX_TOTAL","0")
	total_pct=num(rec_data.tax_rate$)
	for x=1 to 10
		dim opm06a$:fattr(opm06a$)
		next_code$=field(rec_data$,"AR_TOT_CODE_"+str(x:"00"))
		if cvs(next_code$,2)<>""
			read record (opm06_dev,key=firm_id$+next_code$,dom=*next) opm06a$
			callpoint!.setColumnData("<<DISPLAY>>.TAX_RATE_"+str(x:"00"),opm06a.tax_rate$)
			callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_"+str(x:"00"),opm06a.code_desc$)
			total_pct=total_pct+num(opm06a.tax_rate$)
			field user_tpl$,"code",[x]=next_code$
			field user_tpl$,"rate",[x]=num(opm06a.tax_rate$)
		else
			callpoint!.setColumnData("<<DISPLAY>>.TAX_RATE_"+str(x:"00"),"")
			callpoint!.setColumnData("<<DISPLAY>>.TAX_DESC_"+str(x:"00"),"")
			field user_tpl$,"rate",[x]=0
		endif
	next x
	field user_tpl$,"this_rate"=rec_data.tax_rate
	field user_tpl$,"this_code"=rec_data.op_tax_code$
	callpoint!.setColumnData("<<DISPLAY>>.TAX_TOTAL",str(total_pct))
	callpoint!.setStatus("REFRESH-ABLEMAP")
[[OPC_TAXCODE.<CUSTOM>]]
able_gl: rem --- enable/disable selected control
	wctl$=str(num(callpoint!.getTableColumnAttribute("OPC_TAXCODE.GL_ACCOUNT","CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=enableit$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP")
return

calc_total: rem Calculate Total Tax rate
	total_pct=user_tpl.this_rate
	for x=1 to 10
		total_pct=total_pct+nfield(user_tpl$,"rate",x)
	next x
	callpoint!.setColumnData("<<DISPLAY>>.TAX_TOTAL",str(total_pct))
	callpoint!.setStatus("REFRESH")
return

check_code: rem --- Check code
	ok$="Y"
	if cvs(callpoint!.getUserInput(),2)=cvs(user_tpl.this_code$,2) and
:		cvs(callpoint!.getUserInput(),2)<>""
		msg_id$="OP_SUBTAX_DUPE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		ok$="N"
	endif
	for taxcode=1 to 10
		if taxcode<>cur_fld
			if cvs(callpoint!.getUserInput(),2)=cvs(field(user_tpl$,"code",taxcode),3) and
:				cvs(callpoint!.getUserInput(),2)<>""
				msg_id$="OP_TOTCODE_DUPE"
				gosub disp_message
				callpoint!.setStatus("ABORT")
				ok$="N"
			endif
		endif
	next taxcode
return
[[OPC_TAXCODE.BSHO]]
rem --- Open second channel to OPC_TAXCODE
	files=1,begfile=1,endfile=files
	dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
	files$[1]="opm-06",ids$[1]="OPC_TAXCODE"
	call stbl("+DIR_PGM")+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:					ids$[all],templates$[all],channels[all],batch,status
	if status then
		remove_process_bar:
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
	 	release
	endif

rem --- Keep info in user_tpl$
	dim user_tpl$:"opm06_dev:n(4),opm06_tpl:c(500),this_rate:n(10),code[10]:c(10),rate[10]:n(10),this_code:c(10),gl:C(1),gl_installed:c(1)"
	user_tpl.opm06_dev=channels[1]
	user_tpl.opm06_tpl$=templates$[1]
	call stbl("+DIR_PGM")+"adc_application.aon","OP",info$[all]
	user_tpl.gl$=info$[9]
	if info$[9]<>"Y"
		enableit$="I"
		gosub able_gl
	endif
	call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
	user_tpl.gl_installed$=info$[20]
