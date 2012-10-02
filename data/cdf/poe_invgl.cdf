[[POE_INVGL.AGRN]]
if callpoint!.getDevObject("units_flag")<>"Y"
	callpoint!.setColumnEnabled("POE_INVGL.UNITS",-1)
	callpoint!.setStatus("REFRESH")
endif
[[POE_INVGL.AREC]]
if callpoint!.getDevObject("units_flag")<>"Y"
	callpoint!.setColumnEnabled("POE_INVGL.UNITS",-1)
	callpoint!.setStatus("REFRESH")
endif
