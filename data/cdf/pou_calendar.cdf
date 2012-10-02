[[POU_CALENDAR.ARAR]]
pom_calendar_dev=fnget_dev("POM_CALENDAR")
dim pom_calendar$:fnget_tpl$("POM_CALENDAR")

more=1
firm_id$=sysinfo.firm_id$

rem --- Retrieve first/last date scheduled

    call stbl("+DIR_PGM")+"poc_firstlast.aon",pom_calendar_dev,fattr(pom_calendar$),firm_id$,begdate$,enddate$,status

    if begdate$="" 
	begdate$=Translate!.getTranslation("AON_NONE")	
    else
	begdate$=fndate$(begdate$)
    endif
    if enddate$="" 
	enddate$=Translate!.getTranslation("AON_NONE")
    else
	callpoint!.setColumnData("POU_CALENDAR.PURGE_THROUGH",enddate$)
	enddate$=fndate$(enddate$)
    endif


callpoint!.setColumnData("POU_CALENDAR.FIRST_DATE",begdate$)
callpoint!.setColumnData("POU_CALENDAR.LAST_DATE",enddate$)

callpoint!.setColumnData("POU_CALENDAR.FILENAME","POM_CALENDAR")

callpoint!.setStatus("REFRESH")
[[POU_CALENDAR.BSHO]]
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
