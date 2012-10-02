[[ADM_PROCDETAIL.PROGRAM_NAME.AVAL]]
rem can only have alias or program name, not both

if cvs(callpoint!.getColumnData("ADM_PROCDETAIL.PROGRAM_NAME"),3)<>""
	callpoint!.setColumnData("ADM_PROCDETAIL.DD_TABLE_ALIAS","")
	callpoint!.setStatus("REFRESH")
endif

[[ADM_PROCDETAIL.DD_TABLE_ALIAS.AVAL]]
rem can only have alias or program name, not both

if cvs(callpoint!.getColumnData("ADM_PROCDETAIL.DD_TABLE_ALIAS"),3)<>""
	callpoint!.setColumnData("ADM_PROCDETAIL.PROGRAM_NAME","")
	callpoint!.setStatus("REFRESH")
endif

