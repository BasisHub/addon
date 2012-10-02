[[GLR_BUDGETUPDATE.<CUSTOM>]]
ctl_toggle:
	for x=0 to ctls_to_toggle!.size()-1
		ctl_name$=ctls_to_toggle!.getItem(x)
		gosub disable_fields
	next x
return
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
[[GLR_BUDGETUPDATE.BUDGET_REVS.AVAL]]
glm08_dev=fnget_dev("GLM_BUDGETMASTER")
dim glm08a$:fnget_tpl$("GLM_BUDGETMASTER")
glm08a.firm_id$=firm_id$
budget_code$=callpoint!.getUserInput()
glm08a.budget_code$=budget_code$(1,1)
glm08a.amt_or_units$=budget_code$(2,1)
read record (glm08_dev,key=glm08a.firm_id$+glm08a.budget_code$+glm08a.amt_or_units$,dom=*next)glm08a$
callpoint!.setColumnData("GLR_BUDGETUPDATE.GL_ACCOUNT_1",glm08a.gl_account_01$)
callpoint!.setColumnData("GLR_BUDGETUPDATE.GL_ACCOUNT_2",glm08a.gl_account_02$)
callpoint!.setColumnData("GLR_BUDGETUPDATE.GL_WILDCARD",glm08a.gl_wildcard$)
callpoint!.setColumnData("GLR_BUDGETUPDATE.ROUNDING",glm08a.rounding$)
callpoint!.setColumnData("GLR_BUDGETUPDATE.UPDATE_TYPE","C")
ctl_stat$=" "
ctls_to_toggle!=userObj!.getItem(num(user_tpl.ctls_to_toggle_ofst$))
gosub ctl_toggle
[[GLR_BUDGETUPDATE.BSHO]]
rem --- store some ctls we'll be disabling/enabling
ctls_to_toggle!=SysGUI!.makeVector()
ctls_to_toggle!.addItem("GL_ACCOUNT_1")
ctls_to_toggle!.addItem("GL_ACCOUNT_2")
ctls_to_toggle!.addItem("GL_WILDCARD")
ctls_to_toggle!.addItem("ROUNDING")
ctls_to_toggle!.addItem("UPDATE_TYPE")
user_tpl_str$="ctls_to_toggle_ofst:c(5)"
dim user_tpl$:user_tpl_str$
userObj!=SysGUI!.makeVector()
userObj!.addItem(ctls_to_toggle!)
ctl_stat$="I"
gosub ctl_toggle

