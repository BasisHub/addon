[[IVR_VENDLIST.ITEM_ID.AINV]]
rem --- Item synonym processing

	call stbl("+DIR_PGM")+"ivc_itemsyn.aon::option_entry"
[[IVR_VENDLIST.BSHO]]
num_files=3
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="IVS_PARAMS",open_opts$[1]="OTA"
open_tables$[2]="APS_PARAMS",open_opts$[2]="OTA"
open_tables$[3]="GLS_PARAMS",open_opts$[3]="OTA"
gosub open_tables
ivs01_dev=num(open_chans$[1])
aps01_dev=num(open_chans$[2]),aps_params_tpl$=open_tpls$[2]
gls01_dev=num(open_chans$[3]),gls_params_tpl$=open_tpls$[3]

rem --- check to see if main AP param rec (firm/AP/00) exists; if not, tell user to set it up first
    dim aps01a$:aps_params_tpl$
    aps01a_key$=firm_id$+"AP00"
    find record (aps01_dev,key=aps01a_key$,err=*next) aps01a$
    if cvs(aps01a.current_per$,2)=""
        msg_id$="AP_PARAM_ERR"
       dim msg_tokens$[1]
       msg_opt$=""
       gosub disp_message
       gosub remove_process_bar
       release
    endif

rem --- check to see if main GL param rec (firm/GL/00) exists; if not, tell user to set it up first
    dim gls01a$:gls_params_tpl$
    gls01a_key$=firm_id$+"GL00"
    find record (gls01_dev,key=gls01a_key$,err=*next) gls01a$
    if cvs(gls01a.current_per$,2)=""
        msg_id$="GL_PARAM_ERR"
       dim msg_tokens$[1]
       msg_opt$=""
       gosub disp_message
       gosub remove_process_bar
       release
    endif

rem "see if app param recs are present
    ivs01a_key$=firm_id$+"IV00"
    find record (ivs01_dev,key=ivs01a_key$,err=std_missing_params) ivs01a$
[[IVR_VENDLIST.<CUSTOM>]]
remove_process_bar: rem -- remove process bar
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
return

#include std_missing_params.src
