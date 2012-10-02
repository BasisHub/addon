[[IVX_BEGBALS.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVX_BEGBALS.ARAR]]
rem --- open param file to get iv current period/year
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ivs_params",open_opts$[1]="OTA"
gosub open_tables

ivs_params_dev=num(open_chans$[1])
dim ivs_params$:open_tpls$[1]

read record (ivs_params_dev,key=firm_id$+"IV00",err=std_missing_params)ivs_params$
callpoint!.setColumnData("IVX_BEGBALS.PERIOD_YEAR",ivs_params.current_per$+ivs_params.current_year$)
callpoint!.setStatus("REFRESH")
[[IVX_BEGBALS.AWIN]]

[[IVX_BEGBALS.<CUSTOM>]]
#include std_missing_params.src
[[IVX_BEGBALS.BSHO]]


