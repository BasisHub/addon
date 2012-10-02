[[POR_CALENDAR.ASVA]]
rem --- make sure beg mo/yr and end mo/yr are in calendar, and that ending > beginning

begdt$=callpoint!.getDevObject("begdt")
enddt$=callpoint!.getDevObject("enddt")

if begdt$="" and enddt$=""
	msg_id$="PO_NO_CAL_PRINT"
	gosub disp_message
	release
endif

if begdt$<>""
	if callpoint!.getColumnData("POR_CALENDAR.BEGINNING_YEAR")+
:	callpoint!.getColumnData("POR_CALENDAR.BEGINNING_MONTH") < begdt$
		callpoint!.setStatus("ABORT")
endif

if enddt$<>""
	if callpoint!.getColumnData("POR_CALENDAR.ENDING_YEAR")+
:	callpoint!.getColumnData("POR_CALENDAR.ENDING_MONTH") > enddt$
		callpoint!.setStatus("ABORT")
endif

if callpoint!.getColumnData("POR_CALENDAR.BEGINNING_YEAR")+
:	callpoint!.getColumnData("POR_CALENDAR.BEGINNING_MONTH") >
:	callpoint!.getColumnData("POR_CALENDAR.ENDING_YEAR")+
:	callpoint!.getColumnData("POR_CALENDAR.ENDING_MONTH")		
		callpoint!.setStatus("ABORT")
endif
[[POR_CALENDAR.ARAR]]
pom_calendar_dev=fnget_dev("POM_CALENDAR")
dim pom_calendar$:fnget_tpl$("POM_CALENDAR")

more=1
firm_id$=sysinfo.firm_id$

rem --- Init Data

    begdt$=""
    begdate$=""
    enddt$=""
    enddate$=""

rem --- Retrieve first/last date scheduled

    call stbl("+DIR_PGM")+"poc_firstlast.aon",pom_calendar_dev,fattr(pom_calendar$),firm_id$,begdate$,enddate$,status

    if begdate$="" 
	callpoint!.setDevObject("begdt","")
	begdate$=Translate!.getTranslation("AON_NONE")
    else	
	callpoint!.setDevObject("begdt",begdate$(1,6))
	begdate$=fndate$(begdate$)
    endif
    if enddate$="" 
	callpoint!.setDevObject("enddt","")
	enddate$=Translate!.getTranslation("AON_NONE")
    else
	callpoint!.setDevObject("enddt",enddate$(1,6))
	enddate$=fndate$(enddate$)
    endif
  
callpoint!.setColumnData("POR_CALENDAR.FIRST_DATE",begdate$)
callpoint!.setColumnData("POR_CALENDAR.LAST_DATE",enddate$)
if len(begdate$)=10
  callpoint!.setColumnData("POR_CALENDAR.BEGINNING_MONTH",begdate$(1,2))
  callpoint!.setColumnData("POR_CALENDAR.BEGINNING_YEAR",begdate$(7,4))
endif
if len(enddate$)=10
  callpoint!.setColumnData("POR_CALENDAR.ENDING_MONTH",enddate$(1,2))
  callpoint!.setColumnData("POR_CALENDAR.ENDING_YEAR",enddate$(7,4))
endif
callpoint!.setStatus("REFRESH")
[[POR_CALENDAR.BSHO]]
files=1,begfile=1,endfile=1
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="POM_CALENDAR";options$[1]="OTA"

call stbl("+DIR_SYP")+"bac_open_tables.bbj",
:	begfile,
:	endfile,
:	files$[all],
:	options$[all],
:	chans$[all],
:	templates$[all],
:	table_chans$[all],
:	batch,
:	status$

if status$<>"" then
	remove_process_bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif
[[POR_CALENDAR.<CUSTOM>]]
#include std_missing_params.src
