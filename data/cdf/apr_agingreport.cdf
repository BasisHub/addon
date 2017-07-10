[[APR_AGINGREPORT.AGING_DATE.AVAL]]
rem --- Verify calendar exists for fiscal year of aging_date
	aging_date$=callpoint!.getUserInput()
	call pgmdir$+"adc_fiscalperyr.aon",firm_id$,aging_date$,period$,year$,table_chans$[all],status
	if status then
		callpoint!.setStatus("ABORT")
		break
	endif
