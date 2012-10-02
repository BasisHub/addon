[[IVC_CLASCODE.BSHO]]
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"
gosub open_tables
ivs_params_chn=num(open_chans$[1]),ivs_params_tpl$=open_tpls$[1]

rem --- Dimension miscellaneous string templates

	dim ivs01a$:ivs_params_tpl$

	ivs01a_key$=firm_id$+"IV00"
	find record (ivs_params_chn,key=ivs01a_key$,err=std_missing_params) ivs01a$
[[IVC_CLASCODE.<CUSTOM>]]
#include std_missing_params.src
