[[SFE_WOLOTSER.BEND]]
rem --- loop thru and count lot/ser quantities compared to WO sched prod qty

	sfe_wolotser=fnget_dev("SFE_WOLOTSER")
	dim sfe_wolotser$:fnget_tpl$("SFE_WOLOTSER")

	sch_prod_qty=num(callpoint!.getDevObject("prod_qty"))
	wo_loc$=callpoint!.getColumnData("SFE_WOLOTSER.WO_LOCATION")
	wo_no$=callpoint!.getColumnData("SFE_WOLOTSER.WO_NO")

	tot_lotser=0
	read (sfe_wolotser,key=firm_id$+wo_loc$+wo_no$,dom=*next)

	while 1		
		readrecord (sfe_wolotser,end=*break)sfe_wolotser$
		if pos(firm_id$+wo_loc$+wo_no$=sfe_wolotser$)<>1 then break
		tot_lotser=tot_lotser+num(sfe_wolotser.sch_prod_qty$)
	wend

	if tot_lotser>sch_prod_qty
		msg_id$="SF_TOO_MANY"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif


[[SFE_WOLOTSER.AREC]]
rem --- if serialized, and make qty control read only
	
	if callpoint!.getDevObject("lotser")="S" 		
		callpoint!.setColumnEnabled("SFE_WOLOTSER.SCH_PROD_QTY",0)
	endif
[[SFE_WOLOTSER.ADIS]]
rem --- disable inputs if on a closed WO

	if callpoint!.getDevObject("wo_status")="C" 
		callpoint!.setColumnEnabled("SFE_WOLOTSER.LOTSER_NO",0)
		callpoint!.setColumnEnabled("SFE_WOLOTSER.WO_LS_CMT",0)
		callpoint!.setColumnEnabled("SFE_WOLOTSER.SCH_PROD_QTY",0)
	endif
[[SFE_WOLOTSER.BSHO]]
rem --- dflt qty to 1 if serialized
	
	if callpoint!.getDevObject("lotser")="S"
		callpoint!.setTableColumnAttribute("SFE_WOLOTSER.SCH_PROD_QTY","DFLT","1")
	endif

rem --- if lotted, disable auto-assign option

	if callpoint!.getDevObject("lotser")<>"S"
		callpoint!.setOptionEnabled("AUTO",0)
	endif
