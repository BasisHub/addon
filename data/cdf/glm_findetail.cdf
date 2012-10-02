[[GLM_FINDETAIL.ACCUM_PCT.AVAL]]
if callpoint!.getUserInput()="Y"
	if num(callpoint!.getColumnData("GLM_FINDETAIL.INPUT_PERCNT"))=0
		msg_id$="GL_ZERO_PCT"
		gosub disp_message
		callpoint!.setColumnData("GLM_FINDETAIL.INPUT_PERCNT","1")
		callpoint!.setStatus("REFRESH")
	endif
endif
[[GLM_FINDETAIL.OUTPUT_OPER_05.AVAL]]
gosub validate_oper
if valid$="N" callpoint!.setStatus("ABORT")
[[GLM_FINDETAIL.OUTPUT_OPER_04.AVAL]]
gosub validate_oper
if valid$="N" callpoint!.setStatus("ABORT")
[[GLM_FINDETAIL.OUTPUT_OPER_03.AVAL]]
gosub validate_oper
if valid$="N" callpoint!.setStatus("ABORT")
[[GLM_FINDETAIL.OUTPUT_OPER_02.AVAL]]
gosub validate_oper
if valid$="N" callpoint!.setStatus("ABORT")
[[GLM_FINDETAIL.OUTPUT_OPER_01.AVAL]]
gosub validate_oper
if valid$="N" callpoint!.setStatus("ABORT")
[[GLM_FINDETAIL.INPUT_PERCNT.AVAL]]
if num(callpoint!.getUserInput())=0 
	callpoint!.setColumnData("GLM_FINDETAIL.ACCUM_PCT","N")
callpoint!.setStatus("REFRESH")
[[GLM_FINDETAIL.<CUSTOM>]]
disable_fields:
 rem --- used to disable/enable controls depending on parameter settings
 rem --- send in control to toggle (format "ALIAS.CONTROL_NAME"), and D or space to disable/enable
 
 wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
 wmap$=callpoint!.getAbleMap()
 wpos=pos(wctl$=wmap$,8)
 wmap$(wpos+6,1)=ctl_stat$
 callpoint!.setAbleMap(wmap$)
callpoint!.setStatus("ABLEMAP-REFRESH")
return
validate_oper:
valid$=""
if pos(callpoint!.getUserInput()="+- ")=0
valid$="N"
return
[[GLM_FINDETAIL.LINE_TYPE_LIST.AVAL]]
if pos(callpoint!.getUserInput()="HDTNBC")=0  then callpoint!.setStatus("ABORT-REFRESH")
[[GLM_FINDETAIL.EDITING_CODE.AVAL]]
edits$=cvs(callpoint!.getUserInput(),3)
edlen=len(edits$), reject$=""
if edlen>0
	if edlen >5 reject$="Y"
	 
	for x = 1 to edlen
		if pos(edits$(x,1)="SUDP-CF$")=0 reject$="I"
	next x
	if reject$="Y" 
		MSG_ID$="GL_FIN_EDIT"
		gosub disp_message
		callpoint!.setUserInput("")
		callpoint!.setStatus("ABORT-REFRESH")
	endif
	if reject$="I"
		MSG_ID$="GL_INVALID_EDIT_CD"
		gosub disp_message
		callpoint!.setUserInput("")
		callpoint!.setStatus("ABORT-REFRESH")
	endif
endif
