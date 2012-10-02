[[POM_MAKECAL.AREC]]
rem --- open calendar and retrieve last scheduled date

callpoint!.setColumnData("POM_MAKECAL.FILENAME","POM_CALENDAR")

num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="POM_CALENDAR",open_opts$[1]="OTA"
gosub open_tables
pom_calendar_dev=num(open_chans$[1])
dim pom_calendar$:open_tpls$[1]

rem --- Position file

	read (pom_calendar_dev,key=firm_id$,dom=*next)

rem --- Retrieve last date scheduled

	call stbl("+DIR_PGM")+"poc_firstlast.aon",pom_calendar_dev,fattr(pom_calendar$),firm_id$,begdate$,enddate$,status
	callpoint!.setColumnData("POM_MAKECAL.LAST_SCHED_DT",enddate$)

	if enddate$<>"" 
		call stbl("+DIR_PGM")+"adc_daydates.aon",enddate$,return_date$,1
		callpoint!.setColumnData("POM_MAKECAL.FIRST_SCHED_DT",return_date$)
	endif

callpoint!.setStatus("REFRESH")  
