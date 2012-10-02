[[ADM_PROCTABLES.DD_FILE_NAME.BINP]]
rem --- fill in disk file name

ddm_tables_dev=fnget_dev("DDM_TABLES")
dim ddm_tables$:fnget_tpl$("DDM_TABLES")

read record (ddm_tables_dev,key=callpoint!.getColumnData("ADM_PROCTABLES.DD_TABLE_ALIAS"),dom=*next) ddm_tables$
callpoint!.setColumnData("ADM_PROCTABLES.DD_FILE_NAME",ddm_tables.dd_file_name$)
callpoint!.setStatus("REFRESH")
