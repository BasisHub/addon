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

if status$<>"" goto std_exit
pom01_dev=num(chans$[1])
dim pom01a$:templates$[1]

more=1
firm_id$=sysinfo.firm_id$

rem --- Init Data

    begdate$=""
    enddate$=""

rem --- Position file

    read (pom01_dev,key=firm_id$,dom=*next)
rem --- Get First Day Scheduled


    pom01a_key$=key(pom01_dev,end=label1)
    if pos(firm_id$=pom01a_key$)=1 
       read record (pom01_dev) pom01a$
       for i = 1 to 31
            workday$=field(pom01a$,"day_status_"+str(i:"00"))
            if workday$<>" " then 
                workday$ = str(i:"00")
                break
            fi    
       next i 
       if workday$="00" then  workday$="01"
       begdate$=fndate$(pom01a.year$+pom01a.month$+workday$)
    fi 

label1: rem --- Position file


    read (pom01_dev,key=firm_id$+$ff$,dom=*next)

rem --- Get Last Day Scheduled

    pom01a_key$=keyp(pom01_dev,end=done)
    if pos(firm_id$=pom01a_key$)=1
        read record (pom01_dev,key=pom01a_key$) pom01a$
        i = 31
	while i >= 1
            workday$=field(pom01a$,"day_status_"+str(i:"00")) 
            if workday$<>" " then 
                workday$ = str(i:"00")
                break   
            fi    
            i=i-1
	wend
        if workday$="00" then workday$="01"
        enddate$=fndate$(pom01a.year$+pom01a.month$+workday$)
    endif

done: rem --- All done

callpoint!.setColumnData("POR_CALENDAR.FIRST_DATE",begdate$)
callpoint!.setColumnData("POR_CALENDAR.LAST_DATE",enddate$)
callpoint!.setColumnData("POR_CALENDAR.BEGINNING_MONTH",begdate$(1,2))
callpoint!.setColumnData("POR_CALENDAR.ENDING_MONTH",enddate$(1,2))
callpoint!.setColumnData("POR_CALENDAR.BEGINNING_YEAR",begdate$(7,4))
callpoint!.setColumnData("POR_CALENDAR.ENDING_YEAR",enddate$(7,4))
callpoint!.setStatus("REFRESH")
[[POR_CALENDAR.<CUSTOM>]]
#include std_missing_params.src
