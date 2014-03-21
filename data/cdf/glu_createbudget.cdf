[[GLU_CREATEBUDGET.<CUSTOM>]]
#include std_missing_params.src
[[GLU_CREATEBUDGET.ASHO]]
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"

gosub open_tables

gls01_dev=num(open_chans$[1])
dim gls01a$:open_tpls$[1]
readrecord(gls01_dev,key=firm_id$+"GL00",err=std_missing_params)gls01a$
if gls01a.budget_flag$<>"Y"
	msg_id$="GL_NO_BUDG"
	gosub disp_message
	rem --- remove process bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif
