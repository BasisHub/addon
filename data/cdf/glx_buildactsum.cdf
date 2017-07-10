[[GLX_BUILDACTSUM.ASVA]]
rem --- Must validate beg_year in ASVA instead of AVAL since beg_year is the only input field.

rem --- Beg_year cannot be after the end_year and must have a fiscal calendar.
	beg_year$=callpoint!.getColumnData("GLX_BUILDACTSUM.BEG_YEAR")
	end_year$=callpoint!.getColumnData("GLX_BUILDACTSUM.END_YEAR")
	if num(beg_year$)>num(end_year$) then
		msg_id$="AD_BEGIN_GT_END"
		dim msg_tokens$[1]
		msg_tokens$[1]="year"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Beg_year must have a fiscal calendar.
	glsCalendar_dev=fnget_dev("GLS_CALENDAR")
	dim glsCalendar$:fnget_tpl$("GLS_CALENDAR")
	readrecord(glsCalendar_dev,key=firm_id$+beg_year$,dom=*next)glsCalendar$
	if glsCalendar.firm_id$+glsCalendar.year$<>firm_id$+beg_year$ then
		msg_id$="AD_NO_FISCAL_CAL"
		dim msg_tokens$[1]
		msg_tokens$[1]=beg_year$
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif
[[GLX_BUILDACTSUM.AREC]]
rem --- Default the end_year to one year before the earliest year in GLM_ACCTSUMMARY (glm-02),
rem --- but must be before the current fiscal year.
	glmAcctSummary_dev=fnget_dev("GLM_ACCTSUMMARY")
	dim glmAcctSummary$:fnget_tpl$("GLM_ACCTSUMMARY")
	prior_year=num(callpoint!.getDevObject("current_fiscal_year"))
	read(glmAcctSummary_dev,key=firm_id$,knum="BY_YEAR_ACCT",dom=*next)
	readrecord(glmAcctSummary_dev,end=*next)glmAcctSummary$
	if glmAcctSummary.firm_id$=firm_id$ then
		earliest_year=num(glmAcctSummary.year$)
		end_year$=str(min(earliest_year-1,prior_year))
		callpoint!.setColumnData("GLX_BUILDACTSUM.END_YEAR",end_year$,1)
	else
		rem --- Missing GLM_ACCTSUMMARY (glm-02) records for the current fiscal year.
		msg_id$="GL_NO_ACTSUM_RECS"
		dim msg_tokens$[1]
		msg_tokens$[1]=callpoint!.getDevObject("current_fiscal_year")
		gosub disp_message
		callpoint!.setStatus("EXIT")
		break
	endif

rem --- Default the beg_year to the earliest acceptable year. To be acceptable beg_year
rem --- cannot be after the end_year and must have a fiscal calendar.
	glsCalendar_dev=fnget_dev("GLS_CALENDAR")
	dim glsCalendar$:fnget_tpl$("GLS_CALENDAR")
	beg_year$=""
	testYear$=end_year$
	while 1
		rem --- Find earliest fiscal calendar before end_year
		redim glsCalendar$
		readrecord(glsCalendar_dev,key=firm_id$+testYear$,dom=*break)glsCalendar$
		beg_year$=testYear$
		testYear$=str(num(testYear$)-1)
	wend
	if beg_year$<>"" then
		callpoint!.setColumnData("GLX_BUILDACTSUM.BEG_YEAR",beg_year$,1)
	else
		rem --- Show end_year as beg_year, and report missing fiscal calendar.
		callpoint!.setColumnData("GLX_BUILDACTSUM.BEG_YEAR",end_year$,1)

		msg_id$="AD_NO_FISCAL_CAL"
		dim msg_tokens$[1]
		msg_tokens$[1]=end_year$
		gosub disp_message
		break
	endif
[[GLX_BUILDACTSUM.<CUSTOM>]]
#include std_missing_params.src
[[GLX_BUILDACTSUM.BSHO]]
rem --- Open Files
	num_files=3
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="GLS_CALENDAR",open_opts$[2]="OTA"
	open_tables$[3]="GLM_ACCTSUMMARY",open_opts$[3]="OTA"

	gosub open_tables

	glsParams_dev=num(open_chans$[1])
	dim glsParams$:open_tpls$[1]

rem --- Init/parameters
	find record (glsParams_dev,key=firm_id$+"GL00",err=std_missing_params) glsParams$
	callpoint!.setDevObject("current_fiscal_year",glsParams.current_year$)
