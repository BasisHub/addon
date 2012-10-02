[[SFR_WOHARDCOPY.INCLUDE_TRANS.AVAL]]
rem -- Change transaction-related controls based on user input
	
	if callpoint!.getUserInput()="Y"
		switch_on=1
		gosub set_trans_ctls
	else
		switch_on=0
		gosub set_trans_ctls
	endif

[[SFR_WOHARDCOPY.<CUSTOM>]]
set_trans_ctls:
rem -- Set transaction-related controls 

	if switch_on then 
 		callpoint!.setColumnData("SFR_WOHARDCOPY.TRANS_DATE_1","")
 		callpoint!.setColumnData("SFR_WOHARDCOPY.TRANS_DATE_2","")
 		callpoint!.setColumnData("SFR_WOHARDCOPY.SF_TRANSTYPE_M","Y")
 		callpoint!.setColumnData("SFR_WOHARDCOPY.SF_TRANSTYPE_O","Y")
 		callpoint!.setColumnData("SFR_WOHARDCOPY.SF_TRANSTYPE_S","Y")
	else
 		callpoint!.setColumnData("SFR_WOHARDCOPY.TRANS_DATE_1","")
 		callpoint!.setColumnData("SFR_WOHARDCOPY.TRANS_DATE_2","")
 		callpoint!.setColumnData("SFR_WOHARDCOPY.SF_TRANSTYPE_M","N")
 		callpoint!.setColumnData("SFR_WOHARDCOPY.SF_TRANSTYPE_O","N")
 		callpoint!.setColumnData("SFR_WOHARDCOPY.SF_TRANSTYPE_S","N")
	endif

callpoint!.setStatus("REFRESH")

return
[[SFR_WOHARDCOPY.BSHO]]
rem -- Initialize transaction-related controls to N
	switch_on=0
	gosub set_trans_ctls
