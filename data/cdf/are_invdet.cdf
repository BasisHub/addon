[[ARE_INVDET.AGCL]]
rem --- set preset val for batch_no
callpoint!.setTableColumnAttribute("ARE_INVDET.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[ARE_INVDET.AUDE]]
rem --- after deleting a row from detail grid, recalc/redisplay balance left to distribute
gosub calc_grid_tots
gosub disp_totals
[[ARE_INVDET.ADEL]]
rem --- after deleting a row from detail grid, recalc/redisplay balance left to distribute
gosub calc_grid_tots
gosub disp_totals
[[ARE_INVDET.UNITS.AVAL]]
newqty=num(callpoint!.getUserInput())                       
unit_price=num(callpoint!.getColumnData("ARE_INVDET.UNIT_PRICE"))               
new_ext_price=newqty*unit_price

callpoint!.setColumnData("ARE_INVDET.EXT_PRICE",str(new_ext_price))
callpoint!.setStatus("MODIFIED-REFRESH")
[[ARE_INVDET.UNITS.AVEC]]
gosub calc_grid_tots
gosub disp_totals
[[ARE_INVDET.UNIT_PRICE.AVAL]]
new_unit_price=num(callpoint!.getUserInput())
units=num(callpoint!.getColumnData("ARE_INVDET.UNITS"))               
new_ext_price=units*new_unit_price

callpoint!.setColumnData("ARE_INVDET.EXT_PRICE",str(new_ext_price))
callpoint!.setStatus("MODIFIED-REFRESH")
[[ARE_INVDET.UNIT_PRICE.AVEC]]
gosub calc_grid_tots
gosub disp_totals
[[ARE_INVDET.<CUSTOM>]]
calc_grid_tots:

	recVect!=GridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs=recVect!.size()
	if numrecs then
		for reccnt=0 to numrecs-1
			gridrec$=recVect!.getItem(reccnt)
			if cvs(gridrec$,3)<>"" and callpoint!.getGridRowDeleteStatus(reccnt)<>"Y"
				tqty=tqty+gridrec.units
				tamt=tamt+gridrec.ext_price
			endif
		next reccnt
		user_tpl.totqty$=str(tqty)
		user_tpl.totamt$=str(tamt)
	endif
	return

disp_totals:

rem --- get context and ID of total quantity/amount display controls, and redisplay w/ amts from calc_tots
    
	tqty!=UserObj!.getItem(0)
	tqty!.setValue(num(user_tpl.totqty$))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.TOT_QTY",user_tpl.totqty$)

	tamt!=UserObj!.getItem(1)
	tamt!.setValue(num(user_tpl.totamt$))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.TOT_AMT",user_tpl.totamt$)

	return

#include std_missing_params.src
