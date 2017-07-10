[[GLS_COLUMNS.BFMC]]
rem --- Initialize displayColumns! object
use ::glo_DisplayColumns.aon::DisplayColumns
displayColumns!=new DisplayColumns(firm_id$)

rem create list for column zero of grid -- column type drop-down
none_list$=pad(Translate!.getTranslation("AON_(NONE)"),20)+"~"+"   ;"
button_list$=displayColumns!.getStringButtonList()
ldat_list$=none_list$+button_list$

for x=1 to 4
	callpoint!.setTableColumnAttribute("<<DISPLAY>>.BUD_CD_"+str(x),"LDAT",ldat_list$)
next x

rem --- Make vector of ListButton codes for quick searching
	codes!=SysGUI!.makeVector()
	while len(ldat_list$)>0
		xpos=pos(";"=ldat_list$)
		this_button$=ldat_list$(1,xpos)
		ldat_list$=ldat_list$(xpos+1)

		record_id$=this_button$(pos("~"=this_button$)+1)
		record_id$=record_id$(1,len(record_id$)-2)
		amt_or_units$=this_button$(len(this_button$)-1,1)
		codes!.addItem(record_id$+amt_or_units$)
	wend
	callpoint!.setDevObject("codes",codes!)

rem --- Eliminate planned budgets from ldat_list$ for Record Codes
ldat_list$=none_list$
	while len(button_list$)>0
		xpos=pos(";"=button_list$)
		this_button$=button_list$(1,xpos)
		button_list$=button_list$(xpos+1)

		record_id$=this_button$(pos("~"=this_button$)+1)
		record_id$=record_id$(1,len(record_id$)-2)
		if len(record_id$)>1 then continue
		ldat_list$=ldat_list$+this_button$
	wend

for x=1 to 4
	callpoint!.setTableColumnAttribute("<<DISPLAY>>.RECORD_CD_"+str(x),"LDAT",ldat_list$)
next x
[[GLS_COLUMNS.<CUSTOM>]]
#include std_missing_params.src
[[GLS_COLUMNS.ADIS]]
rem look at cols and tps in param rec; translate those to matching entry in the <<DISPLAY>> lists and set selected index
codes!=callpoint!.getDevObject("codes")

for x=1 to 4
	cd$=callpoint!.getColumnData("GLS_COLUMNS.ACCT_MN_COLS_"+str(x:"00"))
	tp$=callpoint!.getColumnData("GLS_COLUMNS.ACCT_MN_TYPE_"+str(x:"00"))
	index=0
	for i=0 to codes!.size()-1
		if codes!.getItem(i)=cd$+tp$ then
			index=i
			break
		endif
	next i
	callpoint!.setColumnData("<<DISPLAY>>.RECORD_CD_"+str(x),cd$+tp$ )
	recordListButton!=callpoint!.getControl("<<DISPLAY>>.RECORD_CD_"+str(x))
	recordListButton!.selectIndex(index)
next x

for x=1 to 4
	cd$=callpoint!.getColumnData("GLS_COLUMNS.BUD_MN_COLS_"+str(x:"00"))
	tp$=callpoint!.getColumnData("GLS_COLUMNS.BUD_MN_TYPE_"+str(x:"00"))
	if len(cvs(cd$,2))=1 and pos(cvs(cd$,2)="012345") then cd$=cvs(cd$,2)
	index=0
	for i=0 to codes!.size()-1
		if codes!.getItem(i)=cd$+tp$ then
			index=i
			break
		endif
	next i
	callpoint!.setColumnData("<<DISPLAY>>.BUD_CD_"+str(x),cd$+tp$ )
	budgetListButton!=callpoint!.getControl("<<DISPLAY>>.BUD_CD_"+str(x))
	budgetListButton!.selectIndex(index)
next x
[[GLS_COLUMNS.BWAR]]
rem "set column and type in gl param rec based on items selected from pulldowns

for x=1 to 4
	cd_tp$=pad(callpoint!.getColumnData("<<DISPLAY>>.RECORD_CD_"+str(x)),2)
	callpoint!.setColumnData("GLS_COLUMNS.ACCT_MN_COLS_"+str(x:"00"),cd_tp$(1,1))
	callpoint!.setColumnData("GLS_COLUMNS.ACCT_MN_TYPE_"+str(x:"00"),cd_tp$(2,1))
next x

for x=1 to 4
	cd_tp$=callpoint!.getColumnData("<<DISPLAY>>.BUD_CD_"+str(x))
	callpoint!.setColumnData("GLS_COLUMNS.BUD_MN_COLS_"+str(x:"00"),cd_tp$(1,len(cd_tp$)-1))
	callpoint!.setColumnData("GLS_COLUMNS.BUD_MN_TYPE_"+str(x:"00"),cd_tp$(len(cd_tp$)))
next x
