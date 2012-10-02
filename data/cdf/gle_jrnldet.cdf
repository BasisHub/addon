[[GLE_JRNLDET.AGRN]]
rem --- recal/display tots when entering a grid row
gosub calc_grid_tots
gosub disp_totals
[[GLE_JRNLDET.AGRE]]
rem --- recal/display tots when leaving a grid row
gosub calc_grid_tots
gosub disp_totals
[[GLE_JRNLDET.ADGE]]
rem --- set default value for memo lines to the description entered in the header

callpoint!.setTableColumnAttribute("GLE_JRNLDET.GL_POST_MEMO","DFLT",callpoint!.getHeaderColumnData("GLE_JRNLHDR.DESCRIPTION"))
[[GLE_JRNLDET.AGCL]]
rem --- set preset val for batch_no

callpoint!.setTableColumnAttribute("GLE_JRNLDET.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[GLE_JRNLDET.AUDE]]
rem --- recal/display tots after deleting a grid row
gosub calc_grid_tots
gosub disp_totals
[[GLE_JRNLDET.ADEL]]
rem --- recal/display tots after deleting a grid row
gosub calc_grid_tots
gosub disp_totals
[[GLE_JRNLDET.UNITS.AVAL]]
gosub calc_grid_tots
gosub disp_totals
[[GLE_JRNLDET.DEBIT_AMT.AVAL]]
rem set credit amt to zero (since entering debit), then recalc/display hdr disp columns
                    
if num(callpoint!.getUserInput())<>0 callpoint!.setColumnData("GLE_JRNLDET.CREDIT_AMT",str(0))

callpoint!.setStatus("MODIFIED-REFRESH")
[[GLE_JRNLDET.DEBIT_AMT.AVEC]]
gosub calc_grid_tots
gosub disp_totals
[[GLE_JRNLDET.CREDIT_AMT.AVAL]]
rem set debit amt to zero (since entering credit), then recalc/display hdr disp columns
                    
if num(callpoint!.getUserInput())<>0 callpoint!.setColumnData("GLE_JRNLDET.DEBIT_AMT",str(0))

callpoint!.setStatus("MODIFIED-REFRESH")
[[GLE_JRNLDET.CREDIT_AMT.AVEC]]
gosub calc_grid_tots
gosub disp_totals
[[GLE_JRNLDET.<CUSTOM>]]
rem calculate total debits/credits/units and display in form header

calc_grid_tots:

	recVect!=GridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs=recVect!.size()
	if numrecs>0
		for reccnt=0 to numrecs-1
			gridrec$=recVect!.getItem(reccnt)
			if cvs(gridrec$,3) <> "" and callpoint!.getGridRowDeleteStatus(reccnt)<>"Y"
				tdb=tdb+num(gridrec.debit_amt$)
				tcr=tcr+num(gridrec.credit_amt$)
				tunits=tunits+num(gridrec.units$)
				rem print 'show',gridrec.debit_amt$," ",gridrec.credit_amt$," ",tdb,tcr
			endif
		next reccnt

		tbal=tdb-tcr
		user_tpl.tot_db$=str(tdb)
		user_tpl.tot_cr$=str(tcr)
		user_tpl.tot_units$=str(tunits)
		user_tpl.tot_bal$=str(tbal)
	endif
return



disp_totals:

	rem --- get context and ID of display controls, and redisplay w/ amts from calc_grid_tots
	    
	debits!=UserObj!.getItem(num(user_tpl.debits_ofst$))
	debits!.setValue(num(user_tpl.tot_db$))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.DEBIT_AMT",user_tpl.tot_db$)

	credits!=UserObj!.getItem(num(user_tpl.credits_ofst$))
	credits!.setValue(num(user_tpl.tot_cr$))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.CREDIT_AMT",user_tpl.tot_cr$)

	bal!=UserObj!.getItem(num(user_tpl.bal_ofst$))
	bal!.setValue(num(user_tpl.tot_bal$))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.BALANCE",user_tpl.tot_bal$)

	units!=UserObj!.getItem(num(user_tpl.units_ofst$))
	units!.setValue(num(user_tpl.tot_units$))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.UNITS",user_tpl.tot_units$)

return
