[[BME_TOTALS.ARAR]]
rem --- Display initial values

	prod_date$=callpoint!.getColumnData("BME_TOTALS.PROD_DATE")
	whse$=callpoint!.getColumnData("BME_TOTALS.WAREHOUSE_ID")
	gosub show_totals
[[BME_TOTALS.WAREHOUSE_ID.AVAL]]
rem --- Display Totals

	prod_date$=callpoint!.getColumnData("BME_TOTALS.PROD_DATE")
	whse$=callpoint!.getUserInput()
	gosub show_totals
[[BME_TOTALS.PROD_DATE.AVAL]]
rem --- Display Totals

	prod_date$=callpoint!.getUserInput()
	whse$=callpoint!.getColumnData("BME_TOTALS.WAREHOUSE_ID")
	gosub show_totals
[[BME_TOTALS.<CUSTOM>]]
rem  ==============================================================
show_totals:
rem prod_date$ (in)
rem whse$ (in)
rem  ==============================================================

	if cvs(prod_date$,2)<>"" and cvs(whse$,2)<>""
		bill_no$=callpoint!.getDevObject("master_bill")
		lot_size=callpoint!.getDevObject("lotsize")
		ap$=callpoint!.getDevObject("ap_installed")
		call "bmc_getcost.aon",bill_no$,lot_size,prod_date$,ap$,"N",1,
:			mat_cost,lab_cost,oh_cost,sub_cost,lot_size,lot_size,"N",whse$,ea_status
		tot_cost=mat_cost+lab_cost+oh_cost+sub_cost
		callpoint!.setColumnData("BME_TOTALS.MAT_COST",str(mat_cost))
		callpoint!.setColumnData("BME_TOTALS.DIR_COST",str(lab_cost))
		callpoint!.setColumnData("BME_TOTALS.OH_COST",str(oh_cost))
		callpoint!.setColumnData("BME_TOTALS.SUB_COST",str(sub_cost))
		callpoint!.setColumnData("BME_TOTALS.TOT_COST",str(tot_cost))
		callpoint!.setStatus("REFRESH")
	endif

	return
