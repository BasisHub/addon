[[IVR_VALUATIONRPT.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVR_VALUATIONRPT.ARAR]]
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"
gosub open_tables
ivs01a_chn=num(open_chans$[1])
ivs01a_tpl$=open_tpls$[1]

dim ivs_params$:ivs01a_tpl$
readrecord(ivs01a_chn,key=firm_id$+"IV00")ivs_params$

 lf$="N",report_option$="B",cost_method$=ivs_params.cost_method$
 rpt_level$="D",pick_check$="N",pick_flag$="N"
 if ivs_params.lifofifo$<>"N" lf$="Y"
 if lf$="Y" report_option$="O"

callpoint!.setColumnData("COST_METHOD",cost_method$)
callpoint!.setColumnData("RPT_LEVEL",rpt_level$)
callpoint!.setColumnData("PICK_CHECK",pick_check$)
callpoint!.setColumnData("PICK_FLAG",pick_flag$)
callpoint!.setColumnData("REPORT_OPTION",report_option$)
callpoint!.setStatus("REFRESH")
