[[APE_MANCHECKDIST.AUDE]]
gosub calc_grid_tots
[[APE_MANCHECKDIST.ADEL]]
gosub calc_grid_tots
[[APE_MANCHECKDIST.<CUSTOM>]]
calc_grid_tots:

glns!=bbjapi().getNamespace("GLNS","GL Dist",1)
dist_amt$=glns!.getValue("dist_amt")
new_dist=0
dim rec$:fattr(rec_data$)
num_recs=gridVect!.size()

for wk=0 to num_recs-1
	rec$=gridVect!.getItem(wk)
	if cvs(rec$,3)<>""  and callpoint!.getGridRowDeleteStatus(wk)<>"Y" then new_dist=new_dist+num(rec.gl_post_amt$)
next wk

glns!.setValue("dist_amt",str(new_dist))

return
[[APE_MANCHECKDIST.BEND]]
glns!=bbjapi().getNamespace("GLNS","GL Dist",1)
dist_amt$=glns!.getValue("dist_amt")
tot_inv$=glns!.getValue("tot_inv")

if num(dist_amt$)<>num(tot_inv$)
	msg_id$="AP_NOBAL"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
[[APE_MANCHECKDIST.GL_ACCOUNT.BINP]]
rem --- default gl account number, if blank
glns!=bbjapi().getNamespace("GLNS","GL Dist",1)
gl$=glns!.getValue("gl_int")

if gl$="Y"
	if cvs(callpoint!.getColumnData("APE_MANCHECKDIST.GL_ACCOUNT"),3)=""
		glns!=bbjapi().getNamespace("GLNS","GL Dist",1)
		callpoint!.setColumnData("APE_MANCHECKDIST.GL_ACCOUNT",glns!.getValue("dflt_gl"))
		callpoint!.setStatus("REFRESH:APE_MANCHECKDIST.GL_ACCOUNT")
	endif
else
	c!=Form!.getAllControls().getItem(0)	
	c!.startEdit(c!.getSelectedRow(),2)
endif
[[APE_MANCHECKDIST.BSHO]]
rem --- if not interfacing to GL, disable gl account column
rem -- also, disable/enable misc and units columns according to params

glns!=bbjapi().getNamespace("GLNS","GL Dist",1)
gl$=glns!.getValue("gl_int")
gl_misc$=glns!.getValue("GLMisc")
gl_units$=glns!.getValue("GLUnits")

c!=Form!.getAllControls().getItem(0)

if gl_misc$="Y" 
	c!.setColumnEditable(2,1)
else
	c!.setColumnEditable(2,0)
endif

if gl_units$="Y" 
	c!.setColumnEditable(4,1)
else
	c!.setColumnEditable(4,0)
endif

if gl$<>"Y"
	c!.setColumnEditable(0,0)
else
	c!.setColumnEditable(0,1)
endif
	
rem --- set preset value for batch_no field
callpoint!.setTableColumnAttribute("APE_MANCHECKDIST.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)

[[APE_MANCHECKDIST.GL_POST_AMT.AVEC]]
gosub calc_grid_tots
	
