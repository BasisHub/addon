[[ADX_DEMOYEAR.ASHO]]
rem --- verify working with demo data, not production data

msg_id$="DEMO_DATA_ONLY"
gosub disp_message
if msg_opt$="C"
	rem --- remove process bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif
[[ADX_DEMOYEAR.AREC]]
rem -- show current fiscal year

cur_fiscal_yr$=callpoint!.getDevObject("cur_fiscal_yr")
callpoint!.setColumnData("ADX_DEMOYEAR.CURRENT_YEAR",cur_fiscal_yr$)
[[ADX_DEMOYEAR.<CUSTOM>]]
#include std_missing_params.src
[[ADX_DEMOYEAR.BSHO]]
rem -- get current fiscal year

num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="GLS_CALENDAR",open_opts$[1]="OTA"
gosub open_tables
cal_dev=num(open_chans$[1])
dim cal_rec$:open_tpls$[1]

find record(cal_dev,key=firm_id$+"GL00",err=std_missing_params)cal_rec$
callpoint!.setDevObject("cur_fiscal_yr",cal_rec.current_year$)
