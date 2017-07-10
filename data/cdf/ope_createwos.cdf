[[OPE_CREATEWOS.BEND]]
rem --- Set form exit status for Cancel
	callpoint!.setDevObject("createWOs_status","Cancel")
[[OPE_CREATEWOS.BSHO]]
rem --- Set form's default exit status for OK
	callpoint!.setDevObject("createWOs_status","OK")

rem --- Disable all fields except the custom grid
	callpoint!.setColumnEnabled("OPE_CREATEWOS.CUSTOMER_ID",-1)
	callpoint!.setColumnEnabled("OPE_CREATEWOS.ORDER_NO",-1)
