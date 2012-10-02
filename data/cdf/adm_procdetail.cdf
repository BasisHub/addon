[[ADM_PROCDETAIL.PROGRAM_NAME.AVAL]]
rem can only have alias or program name, not both
if cvs(callpoint!.getUserInput(),3)<>""
	callpoint!.setColumnData("ADM_PROCDETAIL.DD_TABLE_ALIAS","")
	callpoint!.setStatus("REFRESH")
endif
[[ADM_PROCDETAIL.DD_TABLE_ALIAS.AVAL]]
rem can only have alias or program name, not both
if cvs(callpoint!.getUserInput(),3)<>""
	callpoint!.setColumnData("ADM_PROCDETAIL.PROGRAM_NAME","")
	callpoint!.setStatus("REFRESH")
endif

