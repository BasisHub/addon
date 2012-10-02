[[GLR_TRANSHISTORY.ASVA]]
rem --- Check for Ending Period before Beginning Period
	begper$=str(num(callpoint!.getColumnData("GLR_TRANSHISTORY.BEG_YEAR")):"0000")+
:			str(num(callpoint!.getColumnData("GLR_TRANSHISTORY.BEG_GL_PER")):"00")
	endper$=str(num(callpoint!.getColumnData("GLR_TRANSHISTORY.END_YEAR")):"0000")+
:			str(num(callpoint!.getColumnData("GLR_TRANSHISTORY.END_GL_PER")):"00")
	if num(endper$)<>0
		if begper$>endper$
			begper$="Beginning Period/Year "+begper$(5,2)+"/"+begper$(1,4)
			endper$="Ending Period/Year "+endper$(5,2)+"/"+endper$(1,4)
			callpoint!.setMessage("ENTRY_FROM_TO:"+begper$+";"+endper$)
			callpoint!.setStatus("ABORT")
		endif
	endif
[[GLR_TRANSHISTORY.ARAR]]
rem --- Set default values
	gls01_dev=fnget_dev("GLS_PARAMS")
	dim gls01a$:fnget_tpl$("GLS_PARAMS")
	readrecord(gls01_dev,key=firm_id$+"GL00")gls01a$
	callpoint!.setColumnData("GLR_TRANSHISTORY.BEG_GL_PER",gls01a.current_per$)
	callpoint!.setColumnData("GLR_TRANSHISTORY.BEG_YEAR",gls01a.current_year$)
	callpoint!.setColumnData("GLR_TRANSHISTORY.END_GL_PER",gls01a.current_per$)
	callpoint!.setColumnData("GLR_TRANSHISTORY.END_YEAR",gls01a.current_year$)
	callpoint!.setTableColumnAttribute("GLR_TRANSHISTORY.BEG_GL_PER","MINV","01")
	callpoint!.setTableColumnAttribute("GLR_TRANSHISTORY.BEG_GL_PER","MAXV",str(num(gls01a.total_pers$):"00"))
	callpoint!.setTableColumnAttribute("GLR_TRANSHISTORY.END_GL_PER","MINV","01")
	callpoint!.setTableColumnAttribute("GLR_TRANSHISTORY.END_GL_PER","MAXV",str(num(gls01a.total_pers$):"00"))
	callpoint!.setStatus("REFRESH")
[[GLR_TRANSHISTORY.BSHO]]
rem --- Open and get Current Period/Year parameters
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
	gosub open_tables
	gls_params_dev=num(open_chans$[1]),gls_params_tpl$=open_tpls$[1]
