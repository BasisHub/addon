[[POE_INVGL.AGRN]]
if callpoint!.getDevObject("units_flag")<>"Y"
	callpoint!.setColumnEnabled("POE_INVGL.UNITS",-1)
	callpoint!.setStatus("REFRESH")
endif

rem - To avoid problems with GL lookup (bug 4923), force GL_ACCOUNT into edit mode
rem - if not previously entered.
if cvs(callpoint!.getColumnData("POE_INVGL.GL_ACCOUNT"),3)=""
	callpoint!.setFocus("POE_INVGL.GL_ACCOUNT")
endif
[[POE_INVGL.AREC]]
if callpoint!.getDevObject("units_flag")<>"Y"
	callpoint!.setColumnEnabled("POE_INVGL.UNITS",-1)
	callpoint!.setStatus("REFRESH")
endif
