[[SFR_CALENDAR.<CUSTOM>]]
#include std_missing_params.src
[[SFR_CALENDAR.OP_CODE.AVAL]]
files=1,begfile=1,endfile=1
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="SFM_OPCALNDR";options$[1]="OTA"
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
sfm04_dev=num(chans$[1])
dim sfm04a$:templates$[1]
    more=1
    firm_id$=sysinfo.firm_id$
    opcode$=callpoint!.getUserInput()
first_date$=""
    read (sfm04_dev,key=firm_id$+opcode$,dom=*next)
    k$=key(sfm04_dev,end=label1)
    if pos(firm_id$+opcode$=k$)=1 then 
        read record (sfm04_dev,key=k$) sfm04a$
        x$="01"
        for ii=1 to sfm04a.days_in_mth
            if nfield(sfm04a$,"hrs_per_day_"+str(ii:"00"))>=0 then let x$=str(ii:"00"); break
        next ii
        first_date$=fndate$(sfm04a.year$+sfm04a.month$+x$)
    endif 
label1:
    last_date$=""
    read (sfm04_dev,key=firm_id$+opcode$,dom=*next)
    while more
        k$=key(sfm04_dev,end=*break)
        if pos(firm_id$+opcode$=k$)<>1 then break
        read record (sfm04_dev,key=k$) sfm04a$
        x$=str(sfm04a.days_in_mth:"00")
        for ii=sfm04a.days_in_mth to 1 step -1
            if nfield(sfm04a$,"hrs_per_day_"+str(ii:"00"))>=0 then let x$=str(ii:"00"); break
        next ii
        let last_date$=fndate$(sfm04a.year$+sfm04a.month$+x$)
    wend   
callpoint!.setColumnData("SFR_CALENDAR.FIRST_DATE",first_date$)
callpoint!.setColumnData("SFR_CALENDAR.LAST_DATE",last_date$)
callpoint!.setColumnData("SFR_CALENDAR.PERIOD",first_date$(1,2))
callpoint!.setColumnData("SFR_CALENDAR.PERIOD1",last_date$(1,2))
callpoint!.setColumnData("SFR_CALENDAR.YEAR",first_date$(7,4))
callpoint!.setColumnData("SFR_CALENDAR.YEAR1",last_date$(7,4))
callpoint!.setStatus("REFRESH")
