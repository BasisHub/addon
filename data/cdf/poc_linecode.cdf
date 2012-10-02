[[POC_LINECODE.BNEX]]
rem - set defaults for new records

callpoint!.setColumnData("POC_LINECODE.LINE_TYPE","S")

callpoint!.setColumnData("POC_LINECODE.DROPSHIP","N")

callpoint!.setColumnData("POC_LINECODE.ADD_OPTIONS","N")

callpoint!.setColumnData("POC_LINECODE.LAND_CST_FLG","Y")

callpoint!.setColumnData("POC_LINECODE.LEAD_TIM_FLG","Y")

callpoint!.setStatus("REFRESH")
[[POC_LINECODE.LINE_TYPE.AVAL]]
rem - some line types don't used landed cost flag


if pos(callpoint!.getUserInput()="MV")>0 then
	callpoint!.setColumnData("POC_LINECODE.LAND_CST_FLG","N")
	ctl_name$="POC_LINECODE.LAND_CST_FLG"
	ctl_stat$="D"
	gosub disable_fields
else
	escape; rem print callpoint!.getRecordTemplate()

	ctl_name$="POC_LINECODE.LAND_CST_FLG"
	ctl_stat$=" "
	gosub disable_fields
endif

rem - line types that don't use lead time flag

if pos(callpoint!.getUserInput()="ONMV")>0 then
	callpoint!.setColumnData("POC_LINECODE.LEAD_TIM_FLG","N")
	ctl_name$="POC_LINECODE.LEAD_TIM_FLG"
	ctl_stat$="D"
	gosub disable_fields
else
	ctl_name$="POC_LINECODE.LEAD_TIM_FLG"
	ctl_stat$=" "
	gosub disable_fields
endif

rem - line types that don't use gl accounts 

if pos(callpoint!.getUserInput()="MSV")>0 then
	callpoint!.setColumnData("POC_LINECODE.GL_EXP_ACCT","")
	callpoint!.setColumnData("POC_LINECODE.GL_PPV_ACCT","")
	ctl_name$="POC_LINECODE.GL_EXP_ACCT"
	ctl_stat$="D"
	gosub disable_fields
	ctl_name$="POC_LINECODE.GL_PPV_ACCT"
	gosub disable_fields
else
	escape
	ctl_name$="POC_LINECODE.GL_EXP_ACCT"
	ctl_stat$=" "
	gosub disable_fields
	ctl_name$="POC_LINECODE.GL_PPV_ACCT"
	gosub disable_fields
endif

rem - don't use gl accounts if GL not installed

if gl$<>"Y"  then
	callpoint!.setColumnData("POC_LINECODE.GL_EXP_ACCT","")
	callpoint!.setColumnData("POC_LINECODE.GL_PPV_ACCT","")
	ctl_name$="POC_LINECODE.GL_EXP_ACCT"
	ctl_stat$="D"
	gosub disable_fields
	ctl_name$="POC_LINECODE.GL_PPV_ACCT"
	gosub disable_fields
endif
[[POC_LINECODE.<CUSTOM>]]
#include std_missing_params.src

disable_fields:
 rem --- used to disable/enable controls depending on parameter settings
 rem --- send in control to toggle (format "ALIAS.CONTROL_NAME"), and D or space to disable/enable
 
 wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
 wmap$=callpoint!.getAbleMap()
 wpos=pos(wctl$=wmap$,8)
 wmap$(wpos+6,1)=ctl_stat$
 callpoint!.setAbleMap(wmap$)
 callpoint!.setStatus("ABLEMAP-REFRESH")
 
return
[[POC_LINECODE.BSHO]]
rem --- Open/Lock files

files=1,begfile=1,endfile=files
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="POS_PARAMS";rem --- ads-01

for wkx=begfile to endfile
	options$[wkx]="OTA"
next wkx

call stbl("+DIR_SYP")+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                 chans$[all],templates$[all],table_chans$[all],batch,status$

if status$<>""  goto std_exit

ads01_dev=num(chans$[1])

rem --- Retrieve miscellaneous templates

files=1,begfile=1,endfile=files
dim ids$[files],templates$[files]
ids$[1]="pos-01A:POS_PARAMS"

call stbl("+DIR_PGM")+"adc_template.aon",begfile,endfile,ids$[all],templates$[all],status
if status goto std_exit

rem --- Dimension miscellaneous string templates

dim pos01a$:templates$[1]

rem --- init/parameters

pos01a_key$=firm_id$+"PO00"
find record (ads01_dev,key=pos01a_key$,err=std_missing_params) pos01a$

dim info$[20]

call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
gl$=info$[20]
