[[APE_MANCHECKDIST.GL_ACCOUNT.AVAL]]
rem "GL INACTIVE FEATURE"
   glm01_dev=fnget_dev("GLM_ACCT")
   glm01_tpl$=fnget_tpl$("GLM_ACCT")
   dim glm01a$:glm01_tpl$
   glacctinput$=callpoint!.getUserInput()
   glm01a_key$=firm_id$+glacctinput$
   find record (glm01_dev,key=glm01a_key$,err=*break) glm01a$
   if glm01a.acct_inactive$="Y" then
      call stbl("+DIR_PGM")+"adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,gl_size
      msg_id$="GL_ACCT_INACTIVE"
      dim msg_tokens$[2]
      msg_tokens$[1]=fnmask$(glm01a.gl_account$(1,gl_size),m0$)
      msg_tokens$[2]=cvs(glm01a.gl_acct_desc$,2)
      gosub disp_message
      callpoint!.setStatus("ACTIVATE-ABORT")
   endif
[[APE_MANCHECKDIST.GL_POST_AMT.AVEC]]
gosub calc_grid_tots
[[APE_MANCHECKDIST.AGDR]]
rem --- if not interfacing to GL, disable gl account column
rem -- also, disable/enable misc and units columns according to params

gl$=callpoint!.getDevObject("gl_int")
gl_misc$=callpoint!.getDevObject("GLMisc")
gl_units$=callpoint!.getDevObject("GLUnits")
curr_row=callpoint!.getValidationRow()

if gl_misc$="Y"
	callpoint!.setColumnEnabled(curr_row,"APE_MANCHECKDIST.MISCELLANEA",1)
else
	callpoint!.setColumnEnabled(curr_row,"APE_MANCHECKDIST.MISCELLANEA",0)
endif

if gl_units$="Y" 
	callpoint!.setColumnEnabled(curr_row,"APE_MANCHECKDIST.UNITS",1)
else
	callpoint!.setColumnEnabled(curr_row,"APE_MANCHECKDIST.UNITS",0)
endif

if gl$<>"Y"
	callpoint!.setColumnEnabled(curr_row,"APE_MANCHECKDIST.GL_ACCOUNT",0)
else
	callpoint!.setColumnEnabled(curr_row,"APE_MANCHECKDIST.GL_ACCOUNT",1)
endif
[[APE_MANCHECKDIST.AREC]]
rem --- Track the remaining amount to post

acct$=callpoint!.getDevObject("dflt_gl")
gl$=callpoint!.getDevObject("gl_int")

if gl$="Y"
	if cvs(callpoint!.getColumnData("APE_MANCHECKDIST.GL_ACCOUNT"),3)=""
		callpoint!.setColumnData("APE_MANCHECKDIST.GL_ACCOUNT",acct$)
		callpoint!.setStatus("REFRESH:APE_MANCHECKDIST.GL_ACCOUNT")
	endif
endif

gosub calc_grid_tots
	
rem --- Set distribution amount

	if num(callpoint!.getColumnData("APE_MANCHECKDIST.GL_POST_AMT"))=0
		invoice_amt=num(callpoint!.getDevObject("invoice_amt"))
		diff=invoice_amt-new_dist
		callpoint!.setColumnData("APE_MANCHECKDIST.GL_POST_AMT",(str(diff)))
		callpoint!.setStatus("MODIFIED")
	endif
[[APE_MANCHECKDIST.BUDE]]
rem --- Subtract from invoice_amt DevObject the amount on the line

	amt=num(callpoint!.getColumnData("APE_MANCHECKDIST.GL_POST_AMT"))
	invoice_amt=num(callpoint!.getDevObject("invoice_amt"))
	callpoint!.setDevObject("invoice_amt",str(invoice_amt-amt))
[[APE_MANCHECKDIST.BDEL]]
rem --- Add back to invoice_amt DevObject the amount on the line

	amt=num(callpoint!.getColumnData("APE_MANCHECKDIST.GL_POST_AMT"))
	invoice_amt=num(callpoint!.getDevObject("invoice_amt"))
	callpoint!.setDevObject("invoice_amt",str(invoice_amt+amt))
[[APE_MANCHECKDIST.AGRN]]
rem --- if not interfacing to GL, disable gl account column
rem -- also, disable/enable misc and units columns according to params

gl$=callpoint!.getDevObject("gl_int")
gl_misc$=callpoint!.getDevObject("GLMisc")
gl_units$=callpoint!.getDevObject("GLUnits")
curr_row=callpoint!.getValidationRow()

if gl_misc$="Y"
	callpoint!.setColumnEnabled(curr_row,"APE_MANCHECKDIST.MISCELLANEA",1)
else
	callpoint!.setColumnEnabled(curr_row,"APE_MANCHECKDIST.MISCELLANEA",0)
endif

if gl_units$="Y" 
	callpoint!.setColumnEnabled(curr_row,"APE_MANCHECKDIST.UNITS",1)
else
	callpoint!.setColumnEnabled(curr_row,"APE_MANCHECKDIST.UNITS",0)
endif

if gl$<>"Y"
	callpoint!.setColumnEnabled(curr_row,"APE_MANCHECKDIST.GL_ACCOUNT",0)
else
	callpoint!.setColumnEnabled(curr_row,"APE_MANCHECKDIST.GL_ACCOUNT",1)
endif
[[APE_MANCHECKDIST.AUDE]]
gosub calc_grid_tots
[[APE_MANCHECKDIST.ADEL]]
gosub calc_grid_tots
[[APE_MANCHECKDIST.<CUSTOM>]]
#include std_functions.src
calc_grid_tots:

dist_amt$=callpoint!.getDevObject("dist_amt")
new_dist=0
dim rec$:fattr(rec_data$)
num_recs=gridVect!.size()

for wk=0 to num_recs-1
	rec$=gridVect!.getItem(wk)
	if cvs(rec$,3)<>""  and callpoint!.getGridRowDeleteStatus(wk)<>"Y"
		new_dist=new_dist+num(rec.gl_post_amt$)
	endif
next wk

callpoint!.setDevObject("dist_amt",str(new_dist))

return
[[APE_MANCHECKDIST.BEND]]
gosub calc_grid_tots

dist_amt$=callpoint!.getDevObject("dist_amt")
tot_inv$=callpoint!.getDevObject("tot_inv")

if num(dist_amt$)<>num(tot_inv$)
	msg_id$="AP_NOBAL"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
[[APE_MANCHECKDIST.GL_ACCOUNT.BINP]]
rem --- default gl account number, if blank

gl$=callpoint!.getDevObject("gl_int")
acct$=callpoint!.getDevObject("dflt_gl")

if gl$="Y"
	if cvs(callpoint!.getColumnData("APE_MANCHECKDIST.GL_ACCOUNT"),3)=""
		callpoint!.setColumnData("APE_MANCHECKDIST.GL_ACCOUNT",acct$)
		callpoint!.setStatus("REFRESH:APE_MANCHECKDIST.GL_ACCOUNT")
	endif
else
	c!=Form!.getAllControls().getItem(0)	
	c!.startEdit(c!.getSelectedRow(),2)
endif
[[APE_MANCHECKDIST.BSHO]]
rem --- set preset value for batch_no field
callpoint!.setTableColumnAttribute("APE_MANCHECKDIST.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)

rem --- calculate current value in the records and subtract from DevObject

	ape12_dev=fnget_dev("APE_MANCHECKDIST")
	dim ape12a$:fnget_tpl$("APE_MANCHECKDIST")
	ape12_key$=callpoint!.getDevObject("key_pfx")
	invoice_amt=0
	read (ape12_dev,key=ape12_key$,dom=*next)
	while 1
		read record (ape12_dev,end=*break) ape12a$
		if pos(ape12_key$=ape12a$)<>1 break
		invoice_amt=invoice_amt+ape12a.gl_post_amt
	wend
	amt=num(callpoint!.getDevObject("invoice_amt"))
	callpoint!.setDevObject("invoice_amt",str(amt-invoice_amt))
