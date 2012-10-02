[[ARR_STATEMENTS.REPORT_SEQUENCE.AVAL]]
rem --- If report option is Restart, enable/disable fields
	if cvs(callpoint!.getColumnData("ARR_STATEMENTS.REPORT_OPTION"),2)<>""
		dctl$="ARR_STATEMENTS.CUSTOMER_ID"
		if callpoint!.getUserInput() = "C"
			dmap$=" "
		else
			dmap$="I"
		endif
		gosub disable_ctls
		dctl$="ARR_STATEMENTS.ALT_SEQUENCE"
		if callpoint!.getUserInput() = "C"
			dmap$="I"
		else
			dmap$=" "
		endif
		gosub disable_ctls
	endif
[[ARR_STATEMENTS.REPORT_OPTION.AVAL]]
rem --- enable/disable fields based on selected option
	seq$=callpoint!.getColumnData("ARR_STATEMENTS.REPORT_SEQUENCE")
	option$=callpoint!.getUserInput()
	if option$="R"
		dctl$="ARR_STATEMENTS.CUSTOMER_ID"
		if seq$="C"
			dmap$=" "
		else
			dmap$="I"
		endif
		gosub disable_ctls
		dctl$="ARR_STATEMENTS.ALT_SEQUENCE"
		if seq$="C"
			dmap$="I"
		else
			dmap$=" "
		endif
		gosub disable_ctls
		dctl$="ARR_STATEMENTS.REPORT_SEQUENCE"
		dmap$=" "
		gosub disable_ctls
	endif
	if cvs(option$,2)=""
		dctl$="ARR_STATEMENTS.CUSTOMER_ID"
		dmap$="I"
		gosub disable_ctls
		dctl$="ARR_STATEMENTS.ALT_SEQUENCE"
		dmap$="I"
		gosub disable_ctls
		dctl$="ARR_STATEMENTS.REPORT_SEQUENCE"
		dmap$=" "
		gosub disable_ctls
	endif
	if option$="S"
		dctl$="ARR_STATEMENTS.CUSTOMER_ID"
		dmap$=" "
		gosub disable_ctls
		dctl$="ARR_STATEMENTS.ALT_SEQUENCE"
		dmap$="I"
		gosub disable_ctls
		dctl$="ARR_STATEMENTS.REPORT_SEQUENCE"
		dmap$="I"
		gosub disable_ctls
		callpoint!.setColumnData("ARR_STATEMENTS.REPORT_SEQUENCE","C")
	endif
	callpoint!.setStatus("REFRESH-ABLEMAP-ACTIVATE")
[[ARR_STATEMENTS.<CUSTOM>]]
disable_ctls:rem --- disable selected control - I = inactive, blank = active
	if dctl$<>""
		wctl$=str(num(callpoint!.getTableColumnAttribute(dctl$,"CTLI")):"00000")
		wmap$=callpoint!.getAbleMap()
		wpos=pos(wctl$=wmap$,8)
		wmap$(wpos+6,1)=dmap$
		callpoint!.setAbleMap(wmap$)
		callpoint!.setStatus("ABLEMAP-ACTIVATE")
	endif
	return
[[ARR_STATEMENTS.ARAR]]
rem --- Set default value
	callpoint!.setColumnData("ARR_STATEMENTS.CURSTM_DATE",date(0:"%Yd%Mz%Dz"))
	callpoint!.setStatus("REFRESH")
	dctl$="ARR_STATEMENTS.CUSTOMER_ID"
	dmap$="I"
	gosub disable_ctls
	dctl$="ARR_STATEMENTS.ALT_SEQUENCE"
	dmap$="I"
	gosub disable_ctls
	dctl$="ARR_STATEMENTS.REPORT_SEQUENCE"
	dmap$=" "
	gosub disable_ctls

