[[GLE_ALLOCDET.AGCL]]
rem --- set preset val for batch_no
callpoint!.setTableColumnAttribute("GLE_ALLOCDET.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
