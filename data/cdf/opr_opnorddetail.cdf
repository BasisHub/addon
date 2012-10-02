[[OPR_OPNORDDETAIL.QUOTED.AVAL]]
open$=callpoint!.getColumnData("OPR_OPNORDDETAIL.OPEN")
quoted$=callpoint!.getUserInput()
backorders$=callpoint!.getColumnData("OPR_OPNORDDETAIL.BACKORDERS")
credit$=callpoint!.getColumnData("OPR_OPNORDDETAIL.CREDIT")
non_stock$=callpoint!.getColumnData("OPR_OPNORDDETAIL.NON_STOCK")
gosub enable_listbutton
[[OPR_OPNORDDETAIL.CREDIT.AVAL]]
open$=callpoint!.getColumnData("OPR_OPNORDDETAIL.OPEN")
quoted$=callpoint!.getColumnData("OPR_OPNORDDETAIL.QUOTED")
backorders$=callpoint!.getColumnData("OPR_OPNORDDETAIL.BACKORDERS")
credit$=callpoint!.getUserInput()
non_stock$=callpoint!.getColumnData("OPR_OPNORDDETAIL.NON_STOCK")
gosub enable_listbutton
[[OPR_OPNORDDETAIL.NON_STOCK.AVAL]]
open$=callpoint!.getColumnData("OPR_OPNORDDETAIL.OPEN")
quoted$=callpoint!.getColumnData("OPR_OPNORDDETAIL.QUOTED")
backorders$=callpoint!.getColumnData("OPR_OPNORDDETAIL.BACKORDERS")
credit$=callpoint!.getColumnData("OPR_OPNORDDETAIL.CREDIT")
non_stock$=callpoint!.getUserInput()
gosub enable_listbutton
[[OPR_OPNORDDETAIL.BACKORDERS.AVAL]]
open$=callpoint!.getColumnData("OPR_OPNORDDETAIL.OPEN")
quoted$=callpoint!.getColumnData("OPR_OPNORDDETAIL.QUOTED")
backorders$=callpoint!.getUserInput()
credit$=callpoint!.getColumnData("OPR_OPNORDDETAIL.CREDIT")
non_stock$=callpoint!.getColumnData("OPR_OPNORDDETAIL.NON_STOCK")
gosub enable_listbutton
[[OPR_OPNORDDETAIL.OPEN.AVAL]]
open$=callpoint!.getUserInput()
quoted$=callpoint!.getColumnData("OPR_OPNORDDETAIL.QUOTED")
backorders$=callpoint!.getColumnData("OPR_OPNORDDETAIL.BACKORDERS")
credit$=callpoint!.getColumnData("OPR_OPNORDDETAIL.CREDIT")
non_stock$=callpoint!.getColumnData("OPR_OPNORDDETAIL.NON_STOCK")
gosub enable_listbutton
[[OPR_OPNORDDETAIL.<CUSTOM>]]
enable_listbutton:

	ctl_name$="OPR_OPNORDDETAIL.non_stock_option"

	if open$="N" and quoted$="N" and backorders$="N" and credit$="N" and non_stock$="Y"
		ctl_stat$=" "
	else
		ctl_stat$="D"
	endif
	gosub disable_fields

	callpoint!.setStatus("ABLEMAP-ACTIVATE-REFRESH:OPR_OPNORDDETAIL.non_stock_option")
return

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
