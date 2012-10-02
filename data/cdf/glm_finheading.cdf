[[GLM_FINHEADING.AWIN]]
use ::ado_util.src::util

heading_id=num(callpoint!.getTableColumnAttribute("GLM_FINHEADING.RPT_HEADING","CTLI"))
heading!=form!.getControl(heading_id)
currFont!=heading!.getFont()
myFont!=SysGUI!.makeFont("courier",currFont!.getSize(),currFont!.getStyle())
heading!.setFont(myFont!)

guide_id=num(callpoint!.getTableColumnAttribute("<<DISPLAY>>.GUIDE","CTLI"))
guide!=form!.getControl(guide_id)
currFont!=guide!.getFont()
myFont!=SysGUI!.makeFont("courier",currFont!.getSize(),currFont!.getStyle())
guide!.setFont(myFont!)

util.resizeWindow(Form!, SysGui!)

ctl_name$="<<DISPLAY>>.GUIDE"
ctl_stat$="I"
gosub disable_fields

dim user_tpl$:"ruler:c(135*)"

for x=1 to 13
	wk$=wk$+"----+----"+str(mod(x,10))
next x

user_tpl.ruler$=wk$
[[GLM_FINHEADING.ADIS]]
gosub show_guide
[[GLM_FINHEADING.<CUSTOM>]]
show_guide:

callpoint!.setColumnData("<<DISPLAY>>.GUIDE",user_tpl.ruler$)
callpoint!.setStatus("REFRESH")

return


rem #include disable_fields.src

disable_fields:
	rem --- used to disable/enable controls
	rem --- ctl_name$ sent in with name of control to enable/disable (format "ALIAS.CONTROL_NAME")
	rem --- ctl_stat$ sent in as D or space, meaning disable/enable, respectively

	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")

return

rem #endinclude disable_fields.src
[[GLM_FINHEADING.AREC]]
gosub show_guide
