[[IVR_LOTACTIVITY.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVR_LOTACTIVITY.ARAR]]
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"
gosub open_tables

ivs01a_chn=num(open_chans$[1])
ivs01a_tpl$=open_tpls$[1]

dim ivs_params$:ivs01a_tpl$
readrecord(ivs01a_chn,key=firm_id$+"IV00")ivs_params$

curr_per$=ivs_params.current_year$+ivs_params.current_per$

callpoint!.setColumnData("PERIOD_YEAR_1",curr_per$)
callpoint!.setColumnData("PERIOD_YEAR_2",curr_per$)
callpoint!.setColumnData("PICK_LISTBUTTON","I")
callpoint!.setColumnData("OP_CL_BOTH","B")

callpoint!.setStatus("REFRESH")
