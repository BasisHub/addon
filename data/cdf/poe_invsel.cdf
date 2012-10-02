[[POE_INVSEL.AGDR]]
rem --- don't allow change on existing invsel row... user can delete/add
util.disableGridRow(Form!,num(callpoint!.getValidationRow()))
[[POE_INVSEL.RECEIVER_NO.AVEC]]
gosub calc_grid_tots
gosub disp_totals
[[POE_INVSEL.PO_NO.AVEC]]
gosub calc_grid_tots
gosub disp_totals
[[POE_INVSEL.AUDE]]
gosub calc_grid_tots
gosub disp_totals
[[POE_INVSEL.ADEL]]
gosub calc_grid_tots
gosub disp_totals
[[POE_INVSEL.PO_NO.AVAL]]
gosub accum_receiver_tot; rem accumulate total for po/receiver# entered
[[POE_INVSEL.AWRI]]
rem --- accum tot for po/receiver# entered and write to poe-25 for new/modified rows
rem --- existing rows are disabled, so their info won't go to poe-25 again

if callpoint!.getGridRowNewStatus(num(callpoint!.getValidationRow()))="Y" or 
: 	callpoint!.getGridRowModifyStatus(num(callpoint!.getValidationRow()))="Y"
		gosub accum_receiver_tot
endif
[[POE_INVSEL.AGRE]]
gosub receiver_already_selected
[[POE_INVSEL.AGCL]]
rem print 'show';rem debug

use ::ado_util.src::util
[[POE_INVSEL.RECEIVER_NO.AVAL]]
gosub accum_receiver_tot; rem accumulate total for po/receiver# entered
[[POE_INVSEL.<CUSTOM>]]
receiver_already_selected:
rem --- given a po/receiver (or po w/ no receiver) see if it's already in gridvect

if callpoint!.getGridRowDeleteStatus(num(callpoint!.getValidationRow()))<>"Y"

	curr_row=callpoint!.getValidationRow()
	curr_po_no$=callpoint!.getColumnData("POE_INVSEL.PO_NO")
	curr_receiver_no$=callpoint!.getColumnData("POE_INVSEL.RECEIVER_NO")
	already_sel$=""
	g!=gridVect!.getItem(0)
	if g!.size()
		dim rec$:dtlg_param$[1,3]
		for x=0 to g!.size()-1
			if x<>curr_row
				rec$=g!.getItem(x)
				if cvs(rec$,3)<>"" and callpoint!.getGridRowDeleteStatus(x)<>"Y"
					this_po_no$=rec.po_no$
					this_receiver_no$=rec.receiver_no$
					if this_po_no$+this_receiver_no$=curr_po_no$+curr_receiver_no$ then already_sel$="Y"
					if cvs(this_receiver_no$,3)="" then if this_po_no$=curr_po_no$ then already_sel$="Y"
					if cvs(curr_receiver_no$,3)="" then if this_po_no$=curr_po_no$ then already_sel$="Y"						
				endif
			endif
		next x
	endif

	if already_sel$="Y"
		msg_id$="PO_REC_SEL"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		callpoint!.setFocus("POE_INVSEL.RECEIVER_NO")
	endif
endif

return

accum_receiver_tot:
rem --- given a po/receiver (or po w/ no receiver), retrieve/display pot-14 info -- display part doesn't currently work due to limitation in grids
rem --- this routine invoked from rec# AVAL and from AWRI

pot_rechdr_dev=fnget_dev("POT_RECHDR")
pot_recdet_dev=fnget_dev("POT_RECDET")
poc_linecode_dev=fnget_dev("POC_LINECODE")
apc_termscode_dev=fnget_dev("APC_TERMSCODE")

dim pot_rechdr$:fnget_tpl$("POT_RECHDR")
dim pot_recdet$:fnget_tpl$("POT_RECDET")
dim poc_linecode$:fnget_tpl$("POC_LINECODE")
dim apc_termscode$:fnget_tpl$("APC_TERMSCODE")

event$=callpoint!.getCallpointEvent()
po_no$=callpoint!.getColumnData("POE_INVSEL.PO_NO")
receiver_no$=callpoint!.getColumnData("POE_INVSEL.RECEIVER_NO")

if pos("POE_INVSEL.RECEIVER_NO.AVAL"=event$)
	receiver_no$=callpoint!.getUserInput()
endif
if pos("POE_INVSEL.PO_NO.AVAL"=event$)
	po_no$=callpoint!.getUserInput()
endif

ky_po_rec$=firm_id$+po_no$+receiver_no$
foundone=0
line_tot=0

read (pot_recdet_dev,key=ky_po_rec$,dom=*next)

while 1
	read record (pot_recdet_dev,end=*break)pot_recdet$
	if pos(pot_recdet.firm_id$+pot_recdet.po_no$=ky_po_rec$)<>1 then break
	if cvs(receiver_no$,3)<>"" and pot_recdet.receiver_no$<>receiver_no$ then break
	find record (poc_linecode_dev,key=firm_id$+pot_recdet.po_line_code$,dom=*next)poc_linecode$
	if pos(poc_linecode.line_type$="VM")<>0 then continue
	if poc_linecode.line_type$<>"O"
		if (pot_recdet.qty_received>=0 and pot_recdet.qty_received<=pot_recdet.qty_invoiced) or
:			(pot_recdet.qty_received<=0 and pot_recdet.qty_received>=pot_recdet.qty_invoiced) then continue
	endif
	foundone=1
	line_tot=line_tot+round(pot_recdet.qty_received*pot_recdet.unit_cost,2)
	if pos(".AWRI"=event$)<>0 then gosub write_poe_invdet
wend



if pos(".AVAL"=event$)<>0
	if foundone
		read record (pot_rechdr_dev,key=firm_id$+pot_recdet.po_no$+pot_recdet.receiver_no$,dom=*next)pot_rechdr$
		find record (apc_termscode_dev,key=firm_id$+"C"+pot_rechdr.ap_terms_code$,dom=*next)apc_termscode$
		disp_info$="Ordered: "+fndate$(pot_rechdr.ord_date$)+", Received: "+fndate$(pot_rechdr.recpt_date$)+", Terms: "+pot_rechdr.ap_terms_code$+"("+cvs(apc_termscode.code_desc$,3)+")"
		callpoint!.setColumnData("POE_INVSEL.TOTAL_AMOUNT",str(line_tot))
rem		callpoint!.setColumnData("<<DISPLAY>>.DISP_REC_INFO",disp_info$)
		callpoint!.setStatus("REFRESH"); rem --- tabbing to new grid row wasn't working until this was rem'd ?
	else
		msg_id$="PO_REC_INVOICED"
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif
endif

return

write_poe_invdet:
	
	poe_invdet_dev=fnget_dev("POE_INVDET")
	dim poe_invdet$:fnget_tpl$("POE_INVDET")

	poe_invdet.firm_id$=firm_id$
	poe_invdet.ap_type$=callpoint!.getHeaderColumnData("POE_INVHDR.AP_TYPE")
	poe_invdet.vendor_id$=callpoint!.getHeaderColumnData("POE_INVHDR.VENDOR_ID")
	poe_invdet.ap_inv_no$=callpoint!.getHeaderColumnData("POE_INVHDR.AP_INV_NO")

	read (poe_invdet_dev,key=poe_invdet.firm_id$+poe_invdet.ap_type$+poe_invdet.vendor_id$+poe_invdet.ap_inv_no$+$FF$,dom=*next)

	k$=keyp(poe_invdet_dev,end=*next)
	if pos(poe_invdet.firm_id$+poe_invdet.ap_type$+poe_invdet.vendor_id$+poe_invdet.ap_inv_no$=k$)=1
		read record (poe_invdet_dev,key=k$)poe_invdet$
		seq=num(poe_invdet.line_no$)
	else
		seq=0
	endif
	seq=seq+1
	poe_invdet.line_no$=str(seq:"000")
	poe_invdet.po_no$=pot_recdet.po_no$
	poe_invdet.po_int_seq_ref$=pot_recdet.po_int_seq_ref$
	poe_invdet.po_line_no$=pot_recdet.po_line_no$
	poe_invdet.receiver_no$=pot_recdet.receiver_no$
	poe_invdet.po_line_code$=pot_recdet.po_line_code$
	poe_invdet.order_memo$=pot_recdet.order_memo$
	poe_invdet.unit_cost$=pot_recdet.unit_cost$
	poe_invdet.qty_received$=pot_recdet.qty_received$
	poe_invdet.receipt_cost$=pot_recdet.unit_cost$
	if poc_linecode.line_type$="O" then let poe_invdet.qty_received$="1"
print "writing poe_invdet: ",poe_invdet$
	write record (poe_invdet_dev)poe_invdet$
return

calc_grid_tots:

	recVect!=GridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs=recVect!.size()
	tdist=0
	if numrecs>0
		for reccnt=0 to numrecs-1
			gridrec$=recVect!.getItem(reccnt)
			if cvs(gridrec$,3)<> "" and callpoint!.getGridRowDeleteStatus(reccnt)<>"Y" 
				tdist=tdist+num(gridrec.total_amount)
			endif
		next reccnt
		callpoint!.setDevObject("tot_dist",str(tdist))
	endif
return

disp_totals:

rem --- get context and ID of display controls, and redisplay w/ amts from calc_grid_tots
    	
	dist_bal=num(callpoint!.getHeaderColumnData("POE_INVHDR.INVOICE_AMT"))-num(callpoint!.getDevObject("tot_dist"))-num(callpoint!.getDevObject("tot_gl"))
	dist_bal!=callpoint!.getDevObject("dist_bal_control")
	dist_bal!.setValue(dist_bal)
	callpoint!.setHeaderColumnData("<<DISPLAY>>.DIST_BAL",str(dist_bal))
return


rem #include fndate.src

    def fndate$(q$)
        q1$=""
        q1$=date(jul(num(q$(1,4)),num(q$(5,2)),num(q$(7,2)),err=*next),err=*next)
        if q1$="" q1$=q$
        return q1$
    fnend

rem #endinclude fndate.src
