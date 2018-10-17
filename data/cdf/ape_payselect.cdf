[[APE_PAYSELECT.AP_INV_NO.AVAL]]
rem --- Set filters on grid if value was changed
	if callpoint!.getUserInput()<>callpoint!.getDevObject("prev_inv_no") then
		gosub filter_recs
	endif
[[APE_PAYSELECT.AP_INV_NO.BINP]]
rem --- Capture current value so will know in AVAL if it's changed
	callpoint!.setDevObject("prev_inv_no",callpoint!.getColumnData("APE_PAYSELECT.AP_INV_NO"))
[[APE_PAYSELECT.AOPT-VIEW]]
rem --- When using pay auth, bring up previously scanned invoice for for review

	gridInvoices! = UserObj!.getItem(num(user_tpl.gridInvoicesOfst$))
	rowsSelected! = gridInvoices!.getSelectedRows()
	numcols = gridInvoices!.getNumColumns()
	vectInvoices! = UserObj!.getItem(num(user_tpl.vectInvoicesOfst$))
	vectInvoicesMaster! = UserObj!.getItem(num(user_tpl.vectInvoicesMasterOfst$))
	statusVect! = callpoint!.getDevObject("status_vect")
    
	gosub view_images
[[APE_PAYSELECT.AOPT-UNDO]]
rem --- When using pay auth, allow undo on a line-by-line basis

	gridInvoices! = UserObj!.getItem(num(user_tpl.gridInvoicesOfst$))
	rowsSelected! = gridInvoices!.getSelectedRows()
	numcols = gridInvoices!.getNumColumns()
	vectInvoices! = UserObj!.getItem(num(user_tpl.vectInvoicesOfst$))
	vectInvoicesMaster! = UserObj!.getItem(num(user_tpl.vectInvoicesMasterOfst$))
	statusVect! = callpoint!.getDevObject("status_vect")
    
	gosub  undo_pay_auth
[[APE_PAYSELECT.AOPT-PROC]]
rem --- Process selected rows
rem --- If no pay auth, this is a simple select/de-select toggle
rem --- With pay auth, sets to reviewed or approved (prelim or final) according to current user's role

	gridInvoices! = UserObj!.getItem(num(user_tpl.gridInvoicesOfst$))
	rowsSelected! = gridInvoices!.getSelectedRows()
	numcols = gridInvoices!.getNumColumns()
	vectInvoices! = UserObj!.getItem(num(user_tpl.vectInvoicesOfst$))
	vectInvoicesMaster! = UserObj!.getItem(num(user_tpl.vectInvoicesMasterOfst$))
	statusVect! = callpoint!.getDevObject("status_vect")
	gosub change_invoice_status
[[APE_PAYSELECT.VENDOR_ID.BINQ]]
rem --- Set filter_defs$[] to only show vendors of given AP Type

ap_type$=callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE")

dim filter_defs$[2,2]
filter_defs$[0,0]="APM_VENDMAST.FIRM_ID"
filter_defs$[0,1]="='"+firm_id$+"'"
filter_defs$[0,2]="LOCK"

if cvs(ap_type$,3)<>""
	filter_defs$[1,0]="APM_VENDHIST.AP_TYPE"
	filter_defs$[1,1]="='"+ap_type$+"'"
	filter_defs$[1,2]="LOCK"
endif

call STBL("+DIR_SYP")+"bax_query.bbj",
:		gui_dev, 
:		form!,
:		"AP_VEND_LK",
:		"DEFAULT",
:		table_chans$[all],
:		sel_key$,
:		filter_defs$[all]

if sel_key$<>""
	call stbl("+DIR_SYP")+"bac_key_template.bbj",
:		"APM_VENDMAST",
:		"PRIMARY",
:		apm_vend_key$,
:		table_chans$[all],
:		status$
	dim apm_vend_key$:apm_vend_key$
	apm_vend_key$=sel_key$
	callpoint!.setColumnData("APE_PAYSELECT.VENDOR_ID",apm_vend_key.vendor_id$,1)
endif	
callpoint!.setStatus("ACTIVATE-ABORT")
[[APE_PAYSELECT.VENDOR_ID.BINP]]
rem --- Capture current value so will know in AVAL if it's changed
	callpoint!.setDevObject("prev_vendor_id",callpoint!.getColumnData("APE_PAYSELECT.VENDOR_ID"))
[[APE_PAYSELECT.DUE_DATE_DT.BINP]]
rem --- Capture current value so will know in AVAL if it's changed
	callpoint!.setDevObject("prev_due_date_dt",callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT"))
[[APE_PAYSELECT.DISC_DATE_DT.BINP]]
rem --- Capture current value so will know in AVAL if it's changed
	callpoint!.setDevObject("prev_disc_date_dt",callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT"))
[[APE_PAYSELECT.AP_TYPE.BINP]]
rem --- Capture current value so will know in AVAL if it's changed
	callpoint!.setDevObject("prev_ap_type",callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE"))
[[APE_PAYSELECT.PAYMENT_GRP.BINP]]
rem --- Capture current value so will know in AVAL if it's changed
	callpoint!.setDevObject("prev_payment_grp",callpoint!.getColumnData("APE_PAYSELECT.PAYMENT_GRP"))
[[APE_PAYSELECT.BSHO]]    
rem --- Disable View Images option as needed

	if !callpoint!.getDevObject("use_pay_auth") or callpoint!.getDevObject("scan_docs_to")="NOT" then
			callpoint!.setOptionEnabled("VIMG",0)
	endif

rem --- Disable Approve Invoices option as needed

	if !callpoint!.getDevObject("use_pay_auth")  then
			callpoint!.setOptionEnabled("AINV",0)
	endif
[[APE_PAYSELECT.BEND]]
rem --- Warn if user opts to leave via the close button rather than green arrow (run process)
rem --- Don't warn if using pay auth and user isn't a reviewer or approver (i.e., can't have made any changes)
rem --- Don't warn if using pay auth and nothing changed (nothing in approvalsEntered! or undo_flag$ not set)

    warn=0
    if !callpoint!.getDevObject("use_pay_auth")
        if callpoint!.getDevObject("selections_made")="Y" then warn=1
    else
        dim apm_approvers$:fnget_tpl$("@APM_APPROVERS")
        apm_approvers!=callpoint!.getDevObject("apm_approvers")
        apm_approvers$=apm_approvers!.toString()
        if apm_approvers.prelim_approval or apm_approvers.check_signer then warn=1
        if cast(BBjVector,callpoint!.getDevObject("approvalsEntered")).size()=0 and callpoint!.getDevObject("undo_flag")<>"Y" then warn=0
    endif
    if warn
        msg_id$="AP_PAYSELECT_EXIT "
        gosub disp_message
        if msg_opt$<>"Y"then callpoint!.setStatus("ABORT")
    endif

[[APE_PAYSELECT.ARAR]]
rem --- If mult AP types = N, disable AP Type field

	if callpoint!.getDevObject("multi_types")<>"Y" then 
		callpoint!.setColumnEnabled("APE_PAYSELECT.AP_TYPE", 0)
	endif

rem --- Disable the entire Retention column (does this do anything?)

	gridInvoices! = UserObj!.getItem(num(user_tpl.gridInvoicesOfst$))
	util.disableGridColumn(gridInvoices!, user_tpl.retention_col)

rem --- Display calculated total payments

	tot_payments=num(callpoint!.getDevObject("tot_payments"))
	callpoint!.setColumnData("<<DISPLAY>>.TOT_PAYMENTS",str(tot_payments),1)
[[APE_PAYSELECT.DISC_DATE_DT.AVAL]]
rem --- Set filters on grid if value was changed
	if callpoint!.getUserInput()<>callpoint!.getDevObject("prev_disc_date_dt") then
		gosub filter_recs
	endif
[[APE_PAYSELECT.DUE_DATE_DT.AVAL]]
rem --- Set filters on grid if value was changed
	if callpoint!.getUserInput()<>callpoint!.getDevObject("prev_due_date_dt") then
		gosub filter_recs
	endif
[[APE_PAYSELECT.DISC_DATE_OP.AVAL]]
rem --- Set filters on grid if value was changed
	disc_date_op$=callpoint!.getUserInput()
	if disc_date_op$<>callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_OP") then
		rem --- No need to filter if not doing All dates, and date hasn't been entered
		if disc_date_op$="0" or cvs(callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT"),2)<>"" then
			gosub filter_recs
		endif
	endif
[[APE_PAYSELECT.PAYMENT_GRP.AVAL]]
rem --- Set filters on grid if value was changed
	if callpoint!.getUserInput()<>callpoint!.getDevObject("prev_payment_grp") then
		gosub filter_recs
	endif
[[APE_PAYSELECT.DUE_DATE_OP.AVAL]]
rem --- Set filters on grid if value was changed
	due_date_op$=callpoint!.getUserInput()
	if due_date_op$<>callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_OP") then
		rem --- No need to filter if not doing All dates, and date hasn't been entered
		if due_date_op$="0" or cvs(callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT"),2)<>"" then
			gosub filter_recs
		endif
	endif
[[APE_PAYSELECT.VENDOR_ID.AVAL]]
rem "VENDOR INACTIVE - FEATURE"
vendor_id$ = callpoint!.getUserInput()
apm01_dev=fnget_dev("APM_VENDMAST")
apm01_tpl$=fnget_tpl$("APM_VENDMAST")
dim apm01a$:apm01_tpl$
apm01a_key$=firm_id$+vendor_id$
find record (apm01_dev,key=apm01a_key$,dom=*next) apm01a$
if apm01a.vend_inactive$="Y" then
   call stbl("+DIR_PGM")+"adc_getmask.aon","VENDOR_ID","","","",m0$,0,vendor_size
   msg_id$="AP_VEND_INACTIVE"
   dim msg_tokens$[2]
   msg_tokens$[1]=fnmask$(apm01a.vendor_id$(1,vendor_size),m0$)
   msg_tokens$[2]=cvs(apm01a.vendor_name$,2)
   gosub disp_message
   callpoint!.setStatus("ACTIVATE")
   goto std_exit
endif

rem --- Set filters on grid if value was changed
	if callpoint!.getUserInput()<>callpoint!.getDevObject("prev_vendor_id") then
		gosub filter_recs
	endif
[[APE_PAYSELECT.AP_TYPE.AVAL]]
rem --- Set filters on grid if value was changed
	if callpoint!.getUserInput()<>callpoint!.getDevObject("prev_ap_type") then
		gosub filter_recs
	endif
[[APE_PAYSELECT.<CUSTOM>]]
rem ==========================================================================
load_invoice_approval_status: rem --- Set grid row background colors and selections
rem ==========================================================================
	rem --- Shouldn't get here unless using Payment Authorization.
	if !callpoint!.getDevObject("use_pay_auth")  then return

	dim apm_approvers$:fnget_tpl$("@APM_APPROVERS")
	apm_approvers$=callpoint!.getDevObject("apm_approvers")
    
	rem --- Get grid row background colors
	gosub get_grid_back_colors

	rem --- HashMap to hold approved invoice totals for each vendor
    if callpoint!.getDevObject("vendorTotalsMap")=null()
        vendorTotalsMap!=new java.util.HashMap()
        callpoint!.setDevObject("vendorTotalsMap",vendorTotalsMap!)

        rem --- Pre-pass to get total of reviewed/approved invoices on grid by vendor
        numrows = gridInvoices!.getNumRows()
        if numrows > 0 then
            for row = 0 to numrows-1
                vendor_id$ = gridInvoices!.getCellText(row,3)
                pmt_amt  = num(gridInvoices!.getCellText(row,12))
                inv_amt=num(gridInvoices!.getCellText(row,10))
                approval_amt=iff(pmt_amt=0,inv_amt,pmt_amt)
                ap_inv_no$ = gridInvoices!.getCellText(row,5)

                if !vendorTotalsMap!.containsKey(vendor_id$) then vendorTotalsMap!.put(vendor_id$, 0)
                rem --- Check approvals table; if approved, accumulate to compare against 2-signature threshold
                rem --- Accumulates inv_amt if prelim approval, or pmt_amt (from ape_checks/ape-04) if final
                read(apt_invapproval, key=firm_id$ + vendor_id$ + ap_inv_no$,dom=*next)
                while 1
                    readrecord(apt_invapproval,end=*break)apt_invapproval$
                    if pos(firm_id$ + vendor_id$ + ap_inv_no$ = apt_invapproval$)<>1 then break
                    if apt_invapproval.approval_type$="S"
                        vendorTotalsMap!.put(vendor_id$, approval_amt+cast(BBjNumber, vendorTotalsMap!.get(vendor_id$)))
                        break
                    endif
                wend
            next row
        endif
    else
        vendorTotalsMap!=callpoint!.getDevObject("vendorTotalsMap")
    endif

	rem --- Update invoice selections, and grid row background color
	numrows = gridInvoices!.getNumRows()
    numcols=gridInvoices!.getNumColumns()
	if numrows > 0 then
		for row = 0 to numrows-1
			vendor_id$ = gridInvoices!.getCellText(row,3)
			vendor_name$ = gridInvoices!.getCellText(row,4)
			ap_inv_no$ = gridInvoices!.getCellText(row,5)
			inv_amt  = num(gridInvoices!.getCellText(row,9))
			thisVendor_total = cast(BBjNumber, vendorTotalsMap!.get(vendor_id$))
			gosub get_pay_auth_invoice_status	

			rem --- Update grid row backgound color
			gridInvoices!.setSelectedRow(row)
			gridInvoices!.setRowBackColor(row, defaultColor!)
			gridInvoices!.setCellText(row,0,statusVect!.get(0))
            gridInvoices!.setRowFont(row,callpoint!.getDevObject("plain_font"))

			if reviewed =1 then
				if approved = 0 then
					rem --- Reviewed and no approvals
                    vectInvoices!.set(row*numcols,"2");rem Reviewed
                    dummy = fn_setmast_flag(
:					    vectInvoices!.getItem(row*numcols+2),
:					    vectInvoices!.getItem(row*numcols+3),
:					    vectInvoices!.getItem(row*numcols+5),
:					    "2",
:					    "0"
:				    )                    
					gridInvoices!.setRowBackColor(row, reviewedColor!)
					gridInvoices!.setCellText(row,0,statusVect!.get(2))
				else
					rem --- Reviewed and at least one approval
					if approved = 1 and callpoint!.getDevObject("two_sig_req") and thisVendor_total > callpoint!.getDevObject("two_sig_amt") then
						rem --- Second approval needed
                        vectInvoices!.set(row*numcols,"3");rem Approved
                        dummy = fn_setmast_flag(
:					        vectInvoices!.getItem(row*numcols+2),
:					        vectInvoices!.getItem(row*numcols+3),
:					        vectInvoices!.getItem(row*numcols+5),
:					        "3",
:					        "0"
:				        )
						gridInvoices!.setRowBackColor(row, partiallyApproved!)
						gridInvoices!.setCellText(row,0,statusVect!.get(3))
						gridInvoices!.setRowFont(row,callpoint!.getDevObject("plain_font"))
					else
						rem --- Fully approved
                        vectInvoices!.set(row*numcols,"4");rem Approved
                        dummy = fn_setmast_flag(
:					        vectInvoices!.getItem(row*numcols+2),
:					        vectInvoices!.getItem(row*numcols+3),
:					        vectInvoices!.getItem(row*numcols+5),
:					        "4",
:					        str(inv_amt)
:				        )
						gridInvoices!.setRowBackColor(row, fullyApproved!)
						gridInvoices!.setCellText(row,0,statusVect!.get(4))
						gridInvoices!.setRowFont(row,callpoint!.getDevObject("bold_font"))
					endif
					if apm_approvers.prelim_approval then gridInvoices!.setRowEditable(row,0)
				endif
			else
				if apm_approvers.check_signer then gridInvoices!.setRowEditable(row,0)
			endif

		next row

		rem --- Ensure that there are no rows selected
		gridInvoices!.setSelectedRow(0);rem --- added to position us back at the top of the grid so we don't have to scroll up
		gridInvoices!.deselectAllCells()
	endif

	return

rem ==========================================================================
get_pay_auth_invoice_status: rem --- Get status of an invoice when using pay auth
rem ==========================================================================
rem --- called from load_invoice_approval_status, change_invoice_status, find_rows_needing_action, and send_payauth_email
rem --- returns reviewed=0/1, approved=0/1/2, user id for reviewer$ and/or approved_by$

	rem --- Shouldn't get here unless using Payment Authorization.
	if !callpoint!.getDevObject("use_pay_auth")  then return

	apt_invapproval=fnget_dev("@APT_INVAPPROVAL")
	dim apt_invapproval$:fnget_tpl$("@APT_INVAPPROVAL")

	reviewed=0
	approved=0
    sequence_num=-1
	approved_by$ = ""
	reviewer$ = ""

	rem --- Check the table first
    approvalsUndone!=callpoint!.getDevObject("approvalsUndone")
	read record(apt_invapproval, key=firm_id$ + vendor_id$ + ap_inv_no$,dom=*next)apt_invapproval$
	while 1
		invapproval_key$=key(apt_invapproval,end=*break)
		if pos(firm_id$ + vendor_id$ + ap_inv_no$ = invapproval_key$)<>1 then break
        if approvalsUndone!.get(invapproval_key$)<>null() then read(apt_invapproval);continue;rem --- skip if this is a record that has been 'undone'
		read record(apt_invapproval)apt_invapproval$
        sequence_num=num(apt_invapproval.sequence_num$)
		if apt_invapproval.approval_type$ = "R" then
			reviewed=1
			reviewer$=apt_invapproval.user_id$
		else
			if apt_invapproval.approval_type$ = "S" then
				approved = approved + 1
				approved_by$ = apt_invapproval.user_id$
			endif
		endif
	wend

	rem --- Check the vector
	approvalsEntered! = callpoint!.getDevObject("approvalsEntered")
	if approvalsEntered!.size() > 0 then
		for ouritem = 0 to approvalsEntered!.size() - 1
			apt_invapproval! = approvalsEntered!.getItem(ouritem)
			apt_invapproval$ = apt_invapproval!.getString()
			if firm_id$ + vendor_id$ + ap_inv_no$ <> apt_invapproval.firm_id$ + apt_invapproval.vendor_id$ + apt_invapproval.ap_inv_no$ then 
				continue
			endif
			if apt_invapproval.approval_type$ = "R" then
				reviewed=1
			else
				if apt_invapproval.approval_type$ = "S" then
					already_approved=0
					findrecord(apt_invapproval,key=firm_id$+vendor_id$+ap_inv_no$+apt_invapproval.sequence_num$,dom=*next); already_approved=1
					if already_approved then
						rem --- Don't count if record is in apt_invapproval, it's already been counted once
						continue
					endif
					approved = approved + 1
					approved_by$ = apt_invapproval.user_id$
				endif
			endif
		next ouritem
	endif

	return

rem ==========================================================================
change_invoice_status:
rem ==========================================================================
rem --- called from ACUS (when using popup menu), and AOPT-PROC
rem --- in: rowsSelected!
    
    rem --- if no pay auth, toggles from new to selected and vice versa
    rem --- when using pay auth, perform next step in the process in accordance with current status and user type
    rem --- if not a reviewer or approver, no action allowed except to view images, so shouldn't get here

	if !callpoint!.getDevObject("use_pay_auth")
		if rowsSelected!.size()
			gosub selected_or_fully_approved
		endif
	else
		rem --- get user and approver
		dim apm_approvers$:fnget_tpl$("@APM_APPROVERS")
		dim adm_user$:fnget_tpl$("@ADM_USER")

		apm_approvers$=callpoint!.getDevObject("apm_approvers")
		adm_user$=callpoint!.getDevObject("adm_user") 

		rem --- Are all selected rows eligible for the action chosen by the user?
		if rowsSelected!.size() > 0 then
			gosub find_rows_needing_action
		endif

		if rowsSelected!.size() =  0 and new_index>=0 then
			msg_id$="GENERIC_WARN"
			dim msg_tokens$[1]
			msg_tokens$[1]=Translate!.getTranslation("AON_NO_ELIGIBLE_ROWS")
			gosub disp_message
			gridInvoices!.deselectAllCells()
			return
		endif

		rem --- Confirm review/approval

        invCount = rowsSelected!.size() 
        if apm_approvers.prelim_approval then
            if apm_approvers.check_signer then
                msg_id$="AP_INV_PAY_REVW_APPV"
            else
                msg_id$="AP_INV_PAY_REVWD"
            endif
        else
            msg_id$="AP_INV_PAY_APPVD"
        endif
        dim msg_tokens$[1]
        if invCount > 1 then 
            msg_tokens$[1] = Translate!.getTranslation("AON_THESE")+" "+str(invCount)+ " "+Translate!.getTranslation("AON_INVOICES")
        else
            msg_tokens$[1] = Translate!.getTranslation("AON_THIS")+" "+Translate!.getTranslation("AON_INVOICE")
        endif
        gosub disp_message
        gridInvoices!.deselectAllCells()
        if msg_opt$<>"Y" then return

		rem --- Get grid row background colors
		gosub get_grid_back_colors

		rem --- Get the approval vector and approvalsUndone hash
		approvalsEntered! = callpoint!.getDevObject("approvalsEntered")
        approvalsUndone!=callpoint!.getDevObject("approvalsUndone")

		rem --- Process each selected row
		vendorTotalsMap!=callpoint!.getDevObject("vendorTotalsMap")
        hold_warn=0
		for item = 0 to rowsSelected!.size() - 1
			rem --- Get needed data for this row
			curr_row = num(rowsSelected!.getItem(item))
			vendor_id$ = gridInvoices!.getCellText(curr_row,3)
			vendor_name$ = gridInvoices!.getCellText(curr_row,4)
			ap_inv_no$ = gridInvoices!.getCellText(curr_row,5)
			hold=gridInvoices!.getCellState(curr_row,6)
			inv_amt  = num(gridInvoices!.getCellText(curr_row,9))
            pmt_amt=num(gridInvoices!.getCellText(curr_row,12))
			thisVendor_total = cast(BBjNumber, vendorTotalsMap!.get(vendor_id$))
			gosub get_pay_auth_invoice_status	

			rem --- Record approval
			dim apt_invapproval$:fattr(apt_invapproval$)
			apt_invapproval.firm_id$ = firm_id$
			apt_invapproval.vendor_id$ = vendor_id$
			apt_invapproval.ap_inv_no$ = ap_inv_no$
			apt_invapproval.sequence_num$ = str(sequence_num + 1:callpoint!.getDevObject("seq_no_mask"))
			apt_invapproval.approval_type$ = ""
			apt_invapproval.user_id$ = user$
			apt_invapproval.name$ = adm_user.name$
			apt_invapproval.appv_timestamp$ = date(0:"%Y%Mz%Dz %Hz:%mz:%sz")

			rem --- Skip held invoices
			if hold 
				if rowsSelected!.size()>1 then
                    if !hold_warn
                        msg_id$="AP_INV_SEL_HOLD"
                        gosub disp_message
                        hold_warn=1
                    endif
					continue
				else
					msg_id$="AP_INV_RMVHOLD"
					gosub disp_message
					if msg_opt$<>"Y" then continue
				endif
			endif

			rem --- Not reviewed, and user is not a reviewer
			if !reviewed and !apm_approvers.prelim_approval then
				continue
			endif

			rem --- Not reviewed, and user is a reviewer
			if !reviewed and apm_approvers.prelim_approval then
                previously_undone!=null()
                rem --- If re-doing a review/approval that is in the approvalsUndone! hash, just remove it from there. No need to add into approvalsEntered!
                previously_undone!=approvalsUndone!.remove(apt_invapproval.firm_id$+apt_invapproval.vendor_id$+apt_invapproval.ap_inv_no$+apt_invapproval.sequence_num$,err=*next)
                
                if previously_undone!=null()
                    rem --- Set approval type to reviewed
                    apt_invapproval.approval_type$ = "R"

                    rem --- Update approvalsEntered!, grid, and vectors
                    apt_invapproval! = BBjAPI().makeTemplatedString(fattr(apt_invapproval$))
                    apt_invapproval!.setString(apt_invapproval$)
                    approvalsEntered!.addItem(apt_invapproval!)
                endif
                
                gridInvoices!.setCellText(curr_row,0,statusVect!.get(2))
				gridInvoices!.setRowBackColor(curr_row, reviewedColor!)
				vectInvoices!.setItem(curr_row * numcols, "2")
                dummy = fn_setmast_flag(
:				    vectInvoices!.getItem(curr_row*numcols+2),
:					vectInvoices!.getItem(curr_row*numcols+3),
:					vectInvoices!.getItem(curr_row*numcols+5),
:					"2",
:					str(pmt_amt)
:					)
				continue
			endif	

			rem --- Reviewed by this user that is also an approver. Reviewer cannot also approve.
			if reviewed and (cvs(reviewer$,3)=cvs(user$,3) or cvs(reviewer$,3)="") then
				continue
			endif

			rem --- Not approved, and user is not an approver
			if !approved and !apm_approvers.check_signer then
				continue
			endif

			rem --- Not approved, and user is an approver
			if !approved and apm_approvers.check_signer then

				rem --- Is check over approvers limit?
				if apm_approvers.limit_auth and thisVendor_total+inv_amt>num(apm_approvers.max_auth_amt) then
                    msg_id$="GENERIC_WARN"
                    dim msg_tokens$[1]
                    msg_tokens$[1]=Translate!.getTranslation("AON_AP_OVER_APPROVER_LIMIT")
                    gosub disp_message
					continue
				endif
                
                previously_undone!=null()
                rem --- If re-doing a review/approval that is in the approvalsUndone! hash, remove it from there. No need to add into approvalsEntered!
                previously_undone!=approvalsUndone!.remove(apt_invapproval.firm_id$+apt_invapproval.vendor_id$+apt_invapproval.ap_inv_no$+apt_invapproval.sequence_num$,err=*next)
                
                if previously_undone!=null()
                    rem --- Set approval type
                    apt_invapproval.approval_type$ = "S"

                    rem --- Update approvalsEntered!, grid, and vectors
                    apt_invapproval! = BBjAPI().makeTemplatedString(fattr(apt_invapproval$))
                    apt_invapproval!.setString(apt_invapproval$)
                    approvalsEntered!.addItem(apt_invapproval!)
                endif

				approved = approved + 1
				vendorTotalsMap!.put(vendor_id$,num(vendorTotalsMap!.get(vendor_id$))+inv_amt)
				thisVendor_total = cast(BBjNumber, vendorTotalsMap!.get(vendor_id$))
				gosub set_invoice_row_approval_status
				continue
			endif	

			rem --- One approval by this user
			if approved = 1 and approved_by$ = user$ then
				continue
			endif

			rem --- One approval, and less than threshhold for two approvals
			if approved = 1 and callpoint!.getDevObject("two_sig_req") and thisVendor_total <= callpoint!.getDevObject("two_sig_amt") then
				continue
			endif

			rem --- One approval, over threshhold for two approvals,  and user is an approver
			if approved = 1 and thisVendor_total >= callpoint!.getDevObject("two_sig_amt") and apm_approvers.check_signer then

				rem --- Is check over approvers limit?
                rem --- Not currently using this routine; an approver w/ an individual limit should be able to provide second approval, just not first approval
                while skipping
				if apm_approvers.limit_auth and thisVendor_total>num(apm_approvers.max_auth_amt) then
                    msg_id$="GENERIC_WARN"
                    dim msg_tokens$[1]
                    msg_tokens$[1]=Translate!.getTranslation("AON_AP_OVER_APPROVER_LIMIT")
                    gosub disp_message
					continue
				endif
                wend

                previously_undone!=null()
                rem --- If re-doing a review/approval that is in the approvalsUndone! hash, remove it from there. No need to add into approvalsEntered!
                previously_undone!=approvalsUndone!.remove(apt_invapproval.firm_id$+apt_invapproval.vendor_id$+apt_invapproval.ap_inv_no$+apt_invapproval.sequence_num$,err=*next)
                
                if previously_undone!=null()
                    rem --- Set approval type
                    apt_invapproval.approval_type$ = "S"

                    rem --- Update approvalsEntered! and grid row background color
                    apt_invapproval! = BBjAPI().makeTemplatedString(fattr(apt_invapproval$))
                    apt_invapproval!.setString(apt_invapproval$)
                    approvalsEntered!.addItem(apt_invapproval!)
                endif

				approved = approved + 1			
				gosub set_invoice_row_approval_status
				continue
			endif	
		next item
	endif

	return

rem ==========================================================================
set_invoice_row_approval_status: rem --- Determine if partial or final approval
rem ==========================================================================
rem --- called from change_invoice_status routine when doing first or second approval
rem --- updates grid and vectors accordingly

	rem --- Shouldn't get here unless using Payment Authorization.
	if !callpoint!.getDevObject("use_pay_auth")  then return

    rem --- this vector and use of setSelectedRows(vector!) is temporary until BUI issue with using setSelectedRow() after having deselected the row gets fixed CAH
    rem --- orig line was gridInvoices!.setSelectedRow(curr_row)
    tempVect!=BBjAPI().makeVector()
    tempVect!.add(curr_row)
    gridInvoices!.setSelectedRows(tempVect!)

	rem --- Check invoice for approved status and switch values if needed
	if approved = 1 then
		if callpoint!.getDevObject("two_sig_req") and thisVendor_total > callpoint!.getDevObject("two_sig_amt") 
			gridInvoices!.setRowBackColor(curr_row, partiallyApproved!)
            gridInvoices!.setCellText(curr_row,0,statusVect!.get(3))
			vectInvoices!.setItem(curr_row * numcols, "3")
            dummy = fn_setmast_flag(
:				vectInvoices!.getItem(curr_row*numcols+2),
:			    vectInvoices!.getItem(curr_row*numcols+3),
:				vectInvoices!.getItem(curr_row*numcols+5),
:				"3",
:				"0"
:			)
			rem --- Look for other invoices this vendor that may have been previously approved, and demote to partially approved since we're now over threshold
            if thisVendor_total-inv_amt < callpoint!.getDevObject("two_sig_amt")
                for demote_row=0 to vectInvoicesMaster!.size()-1 step num(user_tpl.MasterCols)
                    if vectInvoicesMaster!.get(demote_row+4)>vendor_id$ then break
                    if vectInvoicesMaster!.get(demote_row+4)=vendor_id$ and vectInvoicesMaster!.get(demote_row+1)="4"
                        vectInvoicesMaster!.set(demote_row+1,"3")
                        vend_id$=vectInvoicesMaster!.get(demote_row+4)
                        ap_type$=vectInvoicesMaster!.get(demote_row+3)
                        inv_no$=vectInvoicesMaster!.get(demote_row+6)
                        if vectInvoicesMaster!.get(demote_row)="Y"
                            gosub get_vectInvoices_offset
                            if vect_offset>=0
                            rem -- if newly-demoted invoice is showing in the grid, set vectInvoices and grid, too
                                if vectInvoices!.get(vect_offset)="4"
                                    gridInvoices!.setSelectedRow(vect_offset/numcols);rem switch selected row to newly-demoted row
                                    gridInvoices!.setRowBackColor(vect_offset/numcols, partiallyApproved!)
                                    selected_flag$="3";rem back to prelim approval
                                    selected=0
                                    gosub selected_or_fully_approved
                                endif
                            endif
                        else
                        rem --- demoted invoice isn't showing in the grid, but still need to reset vectInvoicesMaster back to orig invoice/discount amount and nothing being paid
                            apt01_dev = fnget_dev("APT_INVOICEHDR")
                            dim apt01a$:fnget_tpl$("APT_INVOICEHDR")
                            apt11_dev = fnget_dev("APT_INVOICEDET")
                            dim apt11a$:fnget_tpl$("APT_INVOICEDET")

                            read record (apt01_dev, key=firm_id$+ap_type$+vend_id$+inv_no$,dom=*next) apt01a$
				
                            read record(apt11_dev, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, dom=*next)
                            while 1
                                readrecord(apt11_dev,end=*break)apt11a$
                                if pos(firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$=firm_id$+apt11a.ap_type$+apt11a.vendor_id$+apt11a.ap_inv_no$) <> 1 then break
                                apt01a.invoice_amt = apt01a.invoice_amt + apt11a.trans_amt
                                apt01a.discount_amt = apt01a.discount_amt + apt11a.trans_disc
                                apt01a.retention = apt01a.retention + apt11a.trans_ret
                            wend

                            tot_payments=num(callpoint!.getDevObject("tot_payments"))
                            tot_payments=tot_payments-num(vectInvoicesMaster!.get(demote_row+13))
                            callpoint!.setDevObject("tot_payments",str(tot_payments))
                            callpoint!.setColumnData("<<DISPLAY>>.TOT_PAYMENTS",str(tot_payments),1)
                            if apt01a.discount_amt<0 and apt01a.invoice_amt>0 then apt01a.discount_amt=0
                            vectInvoicesMaster!.set(demote_row+12,apt01a.discount_amt$)
                            vectInvoicesMaster!.set(demote_row+13,"0")
                        endif
                    endif
                next demote_row
                gridInvoices!.setSelectedRow(curr_row);rem set it back to originally select row
            endif
		else
			gridInvoices!.setRowBackColor(curr_row, fullyApproved!)
			selected=1
			gosub selected_or_fully_approved
		endif
	endif
	if approved > 1 then
		gridInvoices!.setRowBackColor(curr_row, fullyApproved!)
		selected=1
		gosub selected_or_fully_approved
	endif


	rem --- clear the row selection
	gridInvoices!.deselectAllCells()

	return

rem ==========================================================================
find_rows_needing_action: rem --- From a set of selected rows, find those needing action by the user
rem ==========================================================================
rem --- called from change_invoice_status
rem --- selected is index of popup menu selection when not running with pay auth (0=new/not selected, 1=selected)
rem --- when using pay auth, see which rows are eligible for the next step in the process in accordance with current status and user type
rem --- note: if user is both a reviewer and approver, does not currently allow 'jump' from new directly to approved (must go from new to reviewed to approved)

	if !callpoint!.getDevObject("use_pay_auth")

		newRowsSelected! = BBjAPI().makeVector()

		for item = 0 to rowsSelected!.size() - 1
			row = num(rowsSelected!.getItem(item))	
			if selected and vectInvoices!.get(row*num(user_tpl.gridInvoicesCols$))<>"1"
				newRowsSelected!.add(row)
			else
                if !selected and vectInvoices!.get(row*num(user_tpl.gridInvoicesCols$))="1"
                    newRowsSelected!.add(row)
                endif
			endif
		next item
	else

		user$=sysinfo.user_id$
		usertype$=""
		if apm_approvers.prelim_approval then
			rem --- Reviewer
			usertype$ = "R"
		endif
		if apm_approvers.check_signer then
			rem --- Approver
			usertype$ = usertype$+"A"
		endif
		if usertype$="" then
			rem --- Not reviewer or approver
			return
		endif

		newRowsSelected! = BBjAPI().makeVector()
		for item = 0 to rowsSelected!.size() - 1
			row = num(rowsSelected!.getItem(item))
			vendor_id$ = gridInvoices!.getCellText(row,3)
			ap_inv_no$ = gridInvoices!.getCellText(row,5)
	        inv_amt  = num(gridInvoices!.getCellText(curr_row,9))
			vendorTotalsMap!=callpoint!.getDevObject("vendorTotalsMap")
			thisVendor_total = cast(BBjNumber, vendorTotalsMap!.get(vendor_id$))
			gosub get_pay_auth_invoice_status

			if !reviewed and pos("R"=usertype$) then
				newRowsSelected!.add(row)
				continue
			endif

			if reviewed and cvs(reviewer$,3)=cvs(user$,3)  then
				rem --- Reviewer cannot also be the approver
				continue
			endif

			if reviewed and !approved and pos("A"=usertype$) then     
                newRowsSelected!.add(row)
                continue
			endif

			if reviewed and approved > 1 and pos("A"=usertype$) then
				rem --- Already has two approvals
				continue
			endif				

			if reviewed and approved = 1 and pos("A"=usertype$) then
				rem --- One approval in. Is it by this user
				if user$ = approved_by$ then
					rem --- Already approved by this approver
					continue
				endif

				rem --- If two signatures required, is it less than the threshold
				if callpoint!.getDevObject("two_sig_req") and thisVendor_total <= callpoint!.getDevObject("two_sig_amt") then
					rem --- Second approval not needed
					continue
				endif

				rem --- If two signatures required, is it greater than the threshold
				if callpoint!.getDevObject("two_sig_req") and thisVendor_total > callpoint!.getDevObject("two_sig_amt") then
					rem --- second approval needed
                    newRowsSelected!.add(row)
                    continue
				endif
			endif
		next item
	endif

	rem --- Replace selection vectors
	gridInvoices!.deselectAllCells()
	rowsSelected! = newRowsSelected!
	gridInvoices!.setSelectedRows(rowsSelected!)

	return

rem ==========================================================================
send_payauth_email: rem --- Send Payment Authorization notification emails
rem ==========================================================================
	rem --- Shouldn't get here unless using Payment Authorization.
	if !callpoint!.getDevObject("use_pay_auth")  then return

	adm_user=fnget_dev("@ADM_USER")
	dim adm_user$:fnget_tpl$("@ADM_USER")
	apm_approvers=fnget_dev("@APM_APPROVERS")
	dim apm_approvers$:fnget_tpl$("@APM_APPROVERS")
	apt_invapproval=fnget_dev("@APT_INVAPPROVAL")
	dim apt_invapproval$:fnget_tpl$("@APT_INVAPPROVAL")

        seq_no_mask$=callpoint!.getDevObject("seq_no_mask")

	rem --- Verify current user is a reviewer or approver
	found=0
	user$=sysinfo.user_id$
	usertype$=""
	read record(apm_approvers,key=firm_id$ + user$,dom=*next)apm_approvers$; found=1
	if !found then
		rem --- Not reviewer or approver
		return
	endif
	if apm_approvers.prelim_approval then
		rem --- Reviewer
		usertype$ = "R"
	endif
	if apm_approvers.check_signer then
		rem --- Approver
		usertype$ = usertype$+"A"
	endif
	if usertype$="" then
		rem --- Not reviewer or approver
		return
	endif

	rem --- Set the from, cc, bcc and replyto email addresses
	read record(adm_user,key=apm_approvers.user_id$,dom=*next)adm_user$
	rem -- for both usertype$ the current user will be a cc
	from$=cvs(adm_user.email_address$,3)
	cc$=cvs(adm_user.email_address$,3)
	
	rem --- Set the to email address, and complete the cc email addresses
	to$ = ""
	read record(apm_approvers,key=firm_id$,dom=*next)
	while 1
		approvers_key$=key(apm_approvers,end=*break)
		if pos(firm_id$=approvers_key$)<>1 then break
		read record(apm_approvers)apm_approvers$

		rem --- Skip the current user
		if apm_approvers.user_id$ = user$ then continue

		rem --- Get this user's email address
		dim adm_user$:fattr(adm_user$)
		read record(adm_user, key=apm_approvers.user_id$,dom=*next)adm_user$
		rem --- Skip if no email address
		if cvs(adm_user.email_address$,2)<>"" then
			if apm_approvers.check_signer then
				rem --- Approver
				if pos("R"=usertype$) then
					if len(to$) then to$ = to$ + ", "
					to$ = to$ + adm_user.email_address$
				else
					if len(cc$) then cc$ = cc$ + ", " 
					cc$ = cc$ + adm_user.email_address$
				endif
			else
				if apm_approvers.prelim_approval then
					rem --- Reviewer
					if pos("A"=usertype$) then
						if len(to$) then to$ = to$ + ", "
						to$ = to$ + ", " + adm_user.email_address$
					endif
				else
					rem --- Not approver or reviewer
					if len(cc$) then cc$ = cc$ + ", " 
					cc$ = cc$ + adm_user.email_address$
				endif
			endif
		endif
	wend
	if cvs(to$,2)="" then to$=from$

	subject$ = Translate!.getTranslation("AON_INVOICES")
	if pos("A"=usertype$) then 
		subject$ = subject$+" "+Translate!.getTranslation("AON_APPROVAL_STATUS")
	else
		subject$ = subject$+" "+Translate!.getTranslation("AON_AWAITING_APPROVAL")
	endif

	msgHtml$ = "<html><body>" + $0A$
	if pos("A"=usertype$) then
		msgText$ = Translate!.getTranslation("AON_APPROVER")+" " + cvs(user$,3) + " "+Translate!.getTranslation("AON_EXITED_PAY_SELECTION")
		msgHtml$ = msgHtml$ + msgText$+" <br><br>" + $0A$
		msgHtml$ = msgHtml$ + Translate!.getTranslation("AON_STATUS_OF_AP_INVOICES:")+" <br><br>" + $0A$
	else
		msgText$ = Translate!.getTranslation("AON_AP_INV_WAITING_APPROVAL")
		msgHtml$ = msgHtml$ + msgText$+" "
		msgHtml$ = msgHtml$ + Translate!.getTranslation("AON_AP_REVIEW_INVOICES:")+" <br><br>" + $0A$ 
	endif
	msgText$=msgText$+" "+Translate!.getTranslation("AON_SEE_ATTACHMENT")+"."
	
	rem --- Process each grid row
	approved_invoices=0
	partially_approved=0
	reviewed_but_not_approved=0
	not_reviewed=0
	approved_invoices$=""
	partially_approved$=""
	reviewed_but_not_approved$=""
	not_reviewed$=""
	m1$=callpoint!.getDevObject("ap_a_mask")

	vendorTotalsMap!=callpoint!.getDevObject("vendorTotalsMap")
	gridInvoices! = UserObj!.getItem(num(user_tpl.gridInvoicesOfst$))
	numrows = gridInvoices!.getNumRows()
	if numrows=0 then return; rem --- There are no emails to send

	for row = 0 to numrows-1
		rem --- Get needed data for this row
		vendor_id$ = gridInvoices!.getCellText(row,3)
		vendor_name$ = gridInvoices!.getCellText(row,4)
		ap_inv_no$ = gridInvoices!.getCellText(row,5)
		hold_indicator$=iff(gridInvoices!.getCellState(row,6),"**","")
		inv_amt  = num(gridInvoices!.getCellText(row,9))
		vendorTotalsMap!=callpoint!.getDevObject("vendorTotalsMap")
		thisVendor_total = cast(BBjNumber, vendorTotalsMap!.get(vendor_id$))

		gosub get_pay_auth_invoice_status

		line$ = "<tr><td>" + hold_indicator$+ap_inv_no$ + "</td>" + $0A$
		line$ = line$ + "<td>" + vendor_id$ + "</td>" + $0A$
		line$ = line$ + "<td>" + vendor_name$ + "</td>" + $0A$
		line$ = line$ + "<td align=right>" + cvs(str(inv_amt:m1$),3) + "</td></tr>" + $0A$
		if reviewed = 0 and approved = 0 then
			not_reviewed = not_reviewed + 1
			not_reviewed$ = not_reviewed$ + line$
		else
			if reviewed = 1 and approved = 0 then
				reviewed_but_not_approved = reviewed_but_not_approved + 1
				reviewed_but_not_approved$ = reviewed_but_not_approved$ + line$
			else
                			if reviewed = 1 and approved = 1 and !callpoint!.getDevObject("two_sig_req") then
                    			approved_invoices = approved_invoices +1
                   			approved_invoices$ = approved_invoices$ + line$
                			else
                    			if reviewed =1 and approved = 1 and callpoint!.getDevObject("two_sig_req") and thisVendor_total <= callpoint!.getDevObject("two_sig_amt") then
	                    			approved_invoices = approved_invoices +1
        		           			approved_invoices$ = approved_invoices$ + line$
					else
                    				if reviewed =1 and approved = 1 and callpoint!.getDevObject("two_sig_req") and thisVendor_total > callpoint!.getDevObject("two_sig_amt") then
                        					partially_approved = partially_approved + 1
                        					partially_approved$ = partially_approved$ + line$
                    				else
                        					if reviewed = 1 and approved > 1 then
                            					approved_invoices = approved_invoices + 1
                            					approved_invoices$ = approved_invoices$ + line$
							endif
                    				endif
					endif
                			endif
			endif
		endif
	next row

	if pos("A"=usertype$) then
		rem --- User is an approver
		if len(not_reviewed$) <> 0 then msgHtml$ = msgHtml$ + Translate!.getTranslation("AON_INV_NOT_REVIEWED:")+" <br>" + $0A$ + "<table border=1>" + not_reviewed$ + "</table><br>" +$0A$
		if len(reviewed_but_not_approved$) <> 0 then msgHtml$ = msgHtml$ + Translate!.getTranslation("AON_INV_REVIEWED_NO_APPROVALS:")+" <br>" + $0A$ + "<table border=1>" + reviewed_but_not_approved$ + "</table><br>" + $0A$
		if len(partially_approved$) <> 0 then msgHtml$ = msgHtml$ + Translate!.getTranslation("AON_INV_REVIEWED_REQUIRE_ANOTHER_APPROVAL:")+" <br>" + $0A$ + "<table border=1>" + partially_approved$ + "</table><br>" + $0A$
		if len(approved_invoices$) <> 0 then msgHtml$ = msgHtml$ + Translate!.getTranslation("AON_INV_APPROVED_READY_FOR_PAYMENT:")+" <br>" + $0A$ + "<table border=1>" + approved_invoices$ + "</table><br>" + $0A$
	else
		rem --- User is the reviewer
		msgHtml$ = msgHtml$ + "<table border=1>" + reviewed_but_not_approved$ + partially_approved$ + "</table>" + $0A$
	endif	
	gosub build_bui_url
	msgHtml$ = msgHtml$ + "<br><a href=" + chr(34) + buiurl$ +chr(34) + ">"+Translate!.getTranslation("AON_LAUNCH_BARISTA_IN_BROWSER")+"</a><br>"
	msgHtml$ = msgHtml$ + "</body></html>"

	msg$ = Translate!.getTranslation("AON_INV_NOT_REVIEWED")+": " +str(not_reviewed) + $0A$
	msg$ = msg$ +Translate!.getTranslation("AON_INV_REVIEWED_APPROVAL_NOT_COMPLETE:")+" " + str(reviewed_but_not_approved + partially_approved) + $0A$
	msg$ = msg$ +Translate!.getTranslation("AON_INV_APPROVED_READY")+": " + str(approved_invoices) + $0A$ + $0A$

	if pos("A"=usertype$)=0 and not_reviewed<>0 then
		rem --- Reviewer only, not an approver.
		rem --- Report it and go, all invoices must be reviewed prior to emailing the approvers
		msg$ = msg$ + Translate!.getTranslation("AON_INV_AWAITING_REVIEW")
		msg_id$="GENERIC_WARN"
		dim msg_tokens$[1]
		msg_tokens$[1]=msg$
		gosub disp_message
	else
		if pos("A"=usertype$)=0 and not_reviewed = 0 and reviewed_but_not_approved = 0 and partially_approved = 0 then
			rem --- Reviewer only, not an approver.
			rem --- Report it and go, all invoices have been approved
			msg$ = msg$ + Translate!.getTranslation("AON_INV_APPROVED_READY_FOR_PAYMENT")
			msg_id$="GENERIC_OK"
			dim msg_tokens$[1]
			msg_tokens$[1]=msg$
			gosub disp_message
		else
			if pos("A"=usertype$)=0 then
				rem --- Reviewer only, not an approver.
				if callpoint!.getDevObject("send_email")  then
					rem ---- give them a choice
					msg_id$="AP_PAYAUTH_EMAIL"
				else
					msg_id$="GENERIC_OK"
				endif
				dim msg_tokens$[1]
				msg_tokens$[1]=msg$
				gosub disp_message
				if msg_opt$="Y" then
					gosub queue_email
				endif
			else
				rem --- pos("A"=usertype$)>0 an approver, give courtesy recap message and send the email
                msg_id$="GENERIC_OK"
                dim msg_tokens$[1]
                msg_tokens$[1]=msg$
                gosub disp_message
				if callpoint!.getDevObject("send_email")  then
					gosub queue_email
				endif
			endif
		endif
	endif

	return

rem ==========================================================================
build_bui_url: rem --- Build a url to launch Barista Application Framework in BUI
rem ==========================================================================

	rem --- Check if web server is running in SSL
	sslEnabled!=System.getProperty("com.basis.jetty.enableSSL")
	
	if (sslEnabled! = null() or sslEnabled!.equals("true"))
	     protocol$="https"
	     port$ = System.getProperty("com.basis.jetty.sslPort")
	     if port$="" then port$="8443"
	else
	     rem --- default to http/8888 if no properties are set
	     protocol$="http"
	     port$="8888"
	endif 
	
	
	host$ = System.getProperty("com.basis.jetty.host")
	if host$="" then host$ = info(3,4)
	
	bui_name$="BaristaApplicationFramework"
	
	buiurl$ = protocol$ + "://" + host$ + ":" + port$ + "/apps/" + bui_name$ + "?locale=" + stbl("+USER_LOCALE")
	
	return

rem ==========================================================================
queue_email: rem --- Make email entry in Barista's Doc Processing Queue
rem ==========================================================================
	rem --- Get next Barista document number
	call stbl("+DIR_SYP")+"bas_sequences.bbj","DOC_NO",next_docno$,table_chans$[all]

rem --- Write HTML message to file so it can be sent as an attachment
	docDir$=stbl("+DOC_DIR_HTM")
	docName$="PayAuthNotifiction_"+next_docno$+".htm"
	outFile!=new java.io.FileWriter(docDir$+docName$)
	outFile!.write(msgHtml$)
	outFile!.close()

rem --- Create entry for zip/txt file in ads_documents
	date_stamp$=date(0:"%Yd%Mz%Dz")
	time_stamp$=date(0:"%Hz%mz%sz")
	docTitle$=Translate!.getTranslation("AON_PAYAUTH_NOTIFICATION")+": "+next_docno$

	call stbl("+DIR_SYP")+"bac_documents.bbj",
:		next_docno$,
:		date_stamp$,
:		time_stamp$,
:		"E",
:		"HTM",
:		docDir$,
:		"",
:		"",
:		"AP",
:		"",
:		table_chans$[all],
:		"NOREPRINT",
:		docName$,
:		docTitle$,
:		""

rem --- Make email entry in Doc Processing Queue
	docQueue!=callpoint!.getDevObject("docQueue")
	docQueue!.clear()
	docQueue!.setFirmID(firm_id$)
	docQueue!.setDocumentID(next_docno$)
	docQueue!.setDocumentExt("HTM")
	docQueue!.setProcessType("E")
	docQueue!.setStatus("A");rem Auto-detect.  Queue will switch it to "Ready" if all required data is present
	docQueue!.setEmailFrom(from$)
	docQueue!.setEmailTo(to$)
	docQueue!.setEmailCC(cc$)
	docQueue!.setSubject(subject$)
	docQueue!.setMessage(msgText$)
	docQueue!.createProcess()
	proc_key$=docQueue!.getFirmID()+docQueue!.getProcessID()
	docQueue!.checkStatus(proc_key$)

	return

rem ==========================================================================
format_grid: rem --- Use Barista program to format the grid
rem ==========================================================================

	m1$=callpoint!.getDevObject("ap_a_mask")

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0] = callpoint!.getColumnAttributeTypes()
	def_inv_cols = num(user_tpl.gridInvoicesCols$)
	num_rpts_rows = num(user_tpl.gridInvoicesRows$)
	dim attr_inv_col$[def_inv_cols,len(attr_def_col_str$[0,0])/5]
	column_no = 1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SELECT"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_STATUS")
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="PYMNT_GRP"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_PAY_GP")
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="AP_TYPE"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_AP_TYPE")
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="VEND_ID"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_VENDOR")
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="VEND_NAME"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_NAME")
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="150"
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="INVOICE_NO"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_INVOICE")
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="60"
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="HOLD_FLAG"
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"
	attr_inv_col$[column_no,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="1"
	attr_inv_col$[column_no,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="C"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_HOLD")
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DUE_DATE"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DUE_DATE")
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_inv_col$[column_no,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="5"
	attr_inv_col$[column_no,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DISC_DATE"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DISCOUNT_DATE")
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_inv_col$[column_no,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="5"
	attr_inv_col$[column_no,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="INV_AMT"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_INVOICE_AMT")
	attr_inv_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_inv_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="AMT_DUE"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_AMOUNT_DUE")
	attr_inv_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_inv_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DISC_AMT"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DISC_AMT")
	attr_inv_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_inv_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="PYMNT_AMT"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_PAYMENT")
	attr_inv_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_inv_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$
	column_no = column_no +1

	attr_inv_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="RETEN_AMT"
	attr_inv_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_RETENTION")
	attr_inv_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_inv_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"
	attr_inv_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=m1$
	column_no = column_no +1

	for curr_attr=1 to def_inv_cols
		attr_inv_col$[0,1] = attr_inv_col$[0,1] + 
:			pad("APT_PAY." + attr_inv_col$[curr_attr, fnstr_pos("DVAR", attr_def_col_str$[0,0], 5)], 40)
	next curr_attr

	attr_disp_col$=attr_inv_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridInvoices!,"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC-CHECKS-DATES",num_rpts_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_inv_col$[all]

	return

rem ==========================================================================
fill_grid: rem --- Fill the grid with data in vectInvoices!
rem ==========================================================================
rem --- called from AWIN and filter_recs

	if info(3,6)<>"5" then SysGUI!.setRepaintEnabled(0);rem --- not available in BUI
	gridInvoices! = UserObj!.getItem(num(user_tpl.gridInvoicesOfst$))
	minrows = num(user_tpl.gridInvoicesRows$)
    statusVect!=callpoint!.getDevObject("status_vect")

	if vectInvoices!.size() then
		numrow = vectInvoices!.size() / gridInvoices!.getNumColumns()
		gridInvoices!.clearMainGrid()
		gridInvoices!.setColumnStyle(6,SysGUI!.GRID_STYLE_UNCHECKED)
		gridInvoices!.setNumRows(numrow)
		gridInvoices!.setCellText(0,0,vectInvoices!)

		for wk=0 to vectInvoices!.size()-1 step gridInvoices!.getNumColumns()
            gridInvoices!.setCellText(wk/gridInvoices!.getNumColumns(),0,statusVect!.getItem(num(vectInvoices!.getItem(wk))))
			if vectInvoices!.getItem(wk) = "1"
                gridInvoices!.setRowFont(wk/gridInvoices!.getNumColumns(),callpoint!.getDevObject("bold_font"))
            else
                gridInvoices!.setRowFont(wk/gridInvoices!.getNumColumns(),callpoint!.getDevObject("plain_font"))
            endif
			if vectInvoices!.getItem(wk+6) = "Y"
				gridInvoices!.setCellStyle(wk / gridInvoices!.getNumColumns(), 6, SysGUI!.GRID_STYLE_CHECKED)
			endif
			gridInvoices!.setCellText(wk / gridInvoices!.getNumColumns(), 6, "")
		next wk

		gridInvoices!.resort()
	else
		gridInvoices!.clearMainGrid()
		gridInvoices!.setColumnStyle(6, SysGUI!.GRID_STYLE_UNCHECKED)
		gridInvoices!.setNumRows(0)
	endif

	rem --- Update grid row background colors and selections when using Payment Authorization 
	if callpoint!.getDevObject("use_pay_auth")  then
		gosub load_invoice_approval_status
	endif

	if info(3,6)<>"5" then SysGUI!.setRepaintEnabled(1);rem --- not available in BUI

	return

rem ==========================================================================
create_invoices_vector: rem --- Create a vector from the file to fill the grid
rem ==========================================================================

	invoiceMap! = new java.util.TreeMap()
	rows=0
	tot_payments=0
	sql_chan=sqlunt
	sqlopen(sql_chan)stbl("+DBNAME")
	sql_prep$="SELECT firm_id,ap_type,vendor_id,ap_inv_no "
	sql_prep$=sql_prep$+"FROM apt_invoicehdr "
	sql_prep$=sql_prep$+"WHERE firm_id='"+firm_id$+"' and invoice_bal<>0"
	sqlprep(sql_chan)sql_prep$
	sqlexec(sql_chan)

	dim select_tpl$:sqltmpl(sql_chan)
	while 1
		select_tpl$=sqlfetch(sql_chan,err=*break) 
		readrecord(apt01_dev,key=select_tpl$,dom=*continue)apt01a$
		read (ape01_dev, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, dom=*next); continue
		dim apm01a$:fattr(apm01a$)
		read record(apm01_dev, key=firm_id$+apt01a.vendor_id$, dom=*next) apm01a$
		read record(apt11_dev, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, dom=*next)

		while 1
			readrecord(apt11_dev,end=*break)apt11a$

			if pos(firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$ =
:				    firm_id$+apt11a.ap_type$+apt11a.vendor_id$+apt11a.ap_inv_no$) <> 1 
:			then 
				break
			endif

			apt01a.invoice_amt = apt01a.invoice_amt + apt11a.trans_amt
			apt01a.discount_amt = apt01a.discount_amt + apt11a.trans_disc
			apt01a.retention = apt01a.retention + apt11a.trans_ret
		wend
		if apt01a.discount_amt<0 and apt01a.invoice_amt>0 then apt01a.discount_amt=0
		inv_amt = apt01a.invoice_amt
		disc_amt = apt01a.discount_amt
		ret_amt = apt01a.retention
		amt_due = inv_amt - ret_amt - disc_amt
		pymnt_amt=0

	rem --- override discount and payment amounts if already in ape04 (computer checks)

		dim ape04a$:fattr(ape04a$)
		read record(ape04_dev, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, dom=*next) ape04a$

		if cvs(ape04a.firm_id$,2)<>""
			inv_amt = ape04a.invoice_amt
			disc_amt = ape04a.discount_amt
			ret_amt = ape04a.retention
			pymnt_amt = ape04a.payment_amt
			amt_due = inv_amt - ret_amt - disc_amt - pymnt_amt
		endif

		rem --- Need vectInvoices! and vectInvoicesMaster! sorted in PRIMARY key order, not AO_INVBAL order
		if apt01a.invoice_amt<>0 then
			tmpVect!=new BBjVector()
			tmpVect!.addItem(iff(apt01a.selected_for_pay$="Y","1","0")); rem 0, initial value 1 if selected, 0 otherwise; if using pay auth, will be adjusted in load_invoice_approval_status routine
			tmpVect!.addItem(apt01a.payment_grp$); rem 1
			tmpVect!.addItem(apt01a.ap_type$); rem 2
			tmpVect!.addItem(apt01a.vendor_id$); rem 3
			tmpVect!.addItem(apm01a.vendor_name$); rem 4
			tmpVect!.addItem(apt01a.ap_inv_no$); rem 5
			tmpVect!.addItem(apt01a.hold_flag$);rem 6
			tmpVect!.addItem(date(jul(apt01a.inv_due_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID"))); rem 7
			tmpVect!.addItem(date(jul(apt01a.disc_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID"))); rem 8
			tmpVect!.addItem(str(inv_amt)); rem 9
			tmpVect!.addItem(str(amt_due)); rem 10
			tmpVect!.addItem(str(disc_amt)); rem 11
			tmpVect!.addItem(str(pymnt_amt)); rem 12
			tmpVect!.addItem(str(ret_amt)); rem 13
			tmpVect!.addItem(apt01a.inv_due_date$); rem 14
			tmpVect!.addItem(apt01a.vendor_id$); rem 15
			tmpVect!.addItem(apt01a.disc_date$); rem 16
			tmpVect!.addItem(apt01a.invoice_amt$); rem 17

			mapkey$=apt01a.firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$
			invoiceMap!.put(mapkey$,tmpVect!)

			rows=rows+1
			tot_payments=tot_payments+pymnt_amt
		endif
	wend
	sqlclose(sql_chan)

	rem --- Now fill vectors
	rem --- Items 1 thru n+1 in InvoicesMaster must equal items 0 thru n in Invoices
	iter!=invoiceMap!.keySet().iterator()
	while iter!.hasNext()
		mapkey$=iter!.next()
		tmpVect!=cast(BBjVector, invoiceMap!.get(mapkey$))

		vectInvoices!.addAll(tmpVect!.subList(0, 14))

		vectInvoicesMaster!.addItem("Y")
		vectInvoicesMaster!.addAll(tmpVect!)
	wend

	callpoint!.setDevObject("tot_payments",str(tot_payments))
	callpoint!.setColumnData("<<DISPLAY>>.TOT_PAYMENTS",str(tot_payments),1)
	callpoint!.setStatus("REFRESH")

	return

rem ==========================================================================
selected_or_fully_approved: rem --- Set or unset selected (no pay auth) or final approval (pay auth)
rem ==========================================================================
rem --- in: gridInvoices!
rem --- in: selected flag; if 1, bolds font and sets pay/disc amts; if 0, set back to plain font and zero out amts

	apm01_dev = fnget_dev("APM_VENDMAST")
	dim apm01a$:fnget_tpl$("APM_VENDMAST")
	apt01_dev = fnget_dev("APT_INVOICEHDR")
	dim apt01a$:fnget_tpl$("APT_INVOICEHDR")
	apt11_dev = fnget_dev("APT_INVOICEDET")
	dim apt11a$:fnget_tpl$("APT_INVOICEDET")

	rem SysGUI!.setRepaintEnabled(0) ... not available in BUI

	vectInvoices!       = UserObj!.getItem(num(user_tpl.vectInvoicesOfst$))
	vectInvoicesMaster! = UserObj!.getItem(num(user_tpl.vectInvoicesMasterOfst$))

	TempRows! = gridInvoices!.getSelectedRows()
	numcols   = gridInvoices!.getNumColumns()
	tot_payments=num(callpoint!.getDevObject("tot_payments"))
    hold_warn=0

	if TempRows!.size() > 0 then
		for temp_row=1 to TempRows!.size()
			row_no = num(TempRows!.getItem(temp_row-1))
            
            if !callpoint!.getDevObject("use_pay_auth")
                selected=iff(vectInvoices!.get(row_no*numcols)="0",1,0);rem when no pay auth, toggles selected to new and vice versa
                if !selected then selected_flag$="0"
                callpoint!.setDevObject("selections_made","Y")
            endif

			if selected
            rem --- setting to 'selected' (no pay auth), or 'approved' (final approval for pay auth)

                selected_flag$=iff(callpoint!.getDevObject("use_pay_auth"),"4","1");rem 4 for final approval when using pay auth, 1 for selected when no pay auth
				vend$ = gridInvoices!.getCellText(row_no,3)
				read record (apm01_dev, key=firm_id$+
:					vend$, dom=*next) apm01a$

				read record (apt01_dev, key=firm_id$+
:					gridInvoices!.getCellText(row_no,2)+
:					vend$+
:					gridInvoices!.getCellText(row_no,5), dom=*next) apt01a$

                if !callpoint!.getDevObject("use_pay_auth")
                    rem --- only warn here when not using pay auth; already warned via change_invoice_status routine when pay auth is used
                    if apt01a.hold_flag$="Y"
                        if TempRows!.size()>1 then
                            if !hold_warn
                                msg_id$="AP_INV_SEL_HOLD"
                                gosub disp_message
                                hold_warn=1
                            endif
                            continue
                        else
                            msg_id$="AP_INV_RMVHOLD"
                            gosub disp_message
                            if msg_opt$<>"Y" then break
                        endif
                    endif
                endif
				
				read record(apt11_dev, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, dom=*next)
				while 1
					readrecord(apt11_dev,end=*break)apt11a$
					if pos(firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$ =
:						    firm_id$+apt11a.ap_type$+apt11a.vendor_id$+apt11a.ap_inv_no$) <> 1 
:					then 
						break
					endif

					apt01a.invoice_amt = apt01a.invoice_amt + apt11a.trans_amt
					apt01a.discount_amt = apt01a.discount_amt + apt11a.trans_disc
					apt01a.retention = apt01a.retention + apt11a.trans_ret
				wend

				if apt01a.discount_amt<0 and apt01a.invoice_amt>0 then apt01a.discount_amt=0

				if callpoint!.getColumnData("APE_PAYSELECT.INCLUDE_DISC")="Y" or
:					apt01a.disc_date$ >= sysinfo.system_date$
:				then
					gridInvoices!.setCellText(row_no, 11, apt01a.discount_amt$)
				else
					gridInvoices!.setCellText(row_no, 11, "0.00")
				endif

				gridInvoices!.setCellText(row_no, 10, "0.00")
				payment_amt = apt01a.invoice_amt - num(gridInvoices!.getCellText(row_no,11)) - apt01a.retention
				gridInvoices!.setCellText(row_no, 12, str(payment_amt))
				vectInvoices!.setItem(row_no * numcols, selected_flag$)
				dummy = fn_setmast_flag(
:					vectInvoices!.getItem(row_no*numcols+2),
:					vectInvoices!.getItem(row_no*numcols+3),
:					vectInvoices!.getItem(row_no*numcols+5),
:					selected_flag$,
:					gridInvoices!.getCellText(row_no,10)
:				)
				dummy = fn_setmast_amts(
:					vectInvoices!.getItem(row_no*numcols+2),
:					vectInvoices!.getItem(row_no*numcols+3),
:					vectInvoices!.getItem(row_no*numcols+5),
:					gridInvoices!.getCellText(row_no, 11),
:					str(payment_amt)
:				)
				tot_payments=tot_payments+payment_amt

				gridInvoices!.setRowFont(row_no,callpoint!.getDevObject("bold_font"))
				gridInvoices!.setCellText(row_no,0,statusVect!.get(num(selected_flag$)))

			else
			rem --- selected=0 means going back to 'new' when no pay auth; if using pay auth, going back to either 2 (reviewed) or 3 (prelim approval)

				vend$ = gridInvoices!.getCellText(row_no,3)
				read record (apt01_dev, key=firm_id$+
:					gridInvoices!.getCellText(row_no,2)+
:					vend$+
:					gridInvoices!.getCellText(row_no,5), dom=*next) apt01a$
				
				read record(apt11_dev, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, dom=*next)
				while 1
					readrecord(apt11_dev,end=*break)apt11a$
					if pos(firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$ =
:						    firm_id$+apt11a.ap_type$+apt11a.vendor_id$+apt11a.ap_inv_no$) <> 1 
:					then 
						break
					endif

					apt01a.invoice_amt = apt01a.invoice_amt + apt11a.trans_amt
					apt01a.discount_amt = apt01a.discount_amt + apt11a.trans_disc
					apt01a.retention = apt01a.retention + apt11a.trans_ret
				wend

				tot_payments=tot_payments-num(gridInvoices!.getCellText(row_no,12))

				if apt01a.discount_amt<0 and apt01a.invoice_amt>0 then apt01a.discount_amt=0

				gridInvoices!.setCellText(row_no, 10, str(str(apt01a.invoice_amt - apt01a.retention - apt01a.discount_amt)))
				gridInvoices!.setCellText(row_no,11,str(apt01a.discount_amt))
				gridInvoices!.setCellText(row_no,12,"0.00")
				vectInvoices!.setItem(row_no * numcols, selected_flag$)
				dummy = fn_setmast_flag(
:					vectInvoices!.getItem(row_no*numcols+2),
:					vectInvoices!.getItem(row_no*numcols+3),
:					vectInvoices!.getItem(row_no*numcols+5),
:					selected_flag$,
:					"0"
:				)
				dummy = fn_setmast_amts(
:					vectInvoices!.getItem(row_no*numcols+2),
:					vectInvoices!.getItem(row_no*numcols+3),
:					vectInvoices!.getItem(row_no*numcols+5),
:					str(apt01a.discount_amt),
:					"0"
:				)

				gridInvoices!.setRowFont(row_no,callpoint!.getDevObject("plain_font"))
				gridInvoices!.setCellText(row_no,0,statusVect!.get(num(selected_flag$)))

			endif
		next temp_row
		callpoint!.setDevObject("tot_payments",str(tot_payments))
		callpoint!.setColumnData("<<DISPLAY>>.TOT_PAYMENTS",str(tot_payments),1)


	endif

	rem SysGUI!.setRepaintEnabled(1) ... not availble in BUI

	return

rem ==========================================================================
filter_recs: rem --- Set grid vector based on filters
rem ==========================================================================

	vectInvoicesMaster! = UserObj!.getItem(num(user_tpl.vectInvoicesMasterOfst$))
	vectInvoices! = UserObj!.getItem(num(user_tpl.vectInvoicesOfst$))
	vect_size = num(vectInvoicesMaster!.size())

	if vect_size then 

	rem --- Reset all select to include flags to Yes

		for x=1 to vect_size step user_tpl.MasterCols
			vectInvoicesMaster!.setItem(x-1,"Y")
		next x

	rem --- Set variables using either getColumnData or getUserInput, depending on where gosub'd from

		if callpoint!.getVariableName()="APE_PAYSELECT.DISC_DATE_DT"
			filter_pymnt_grp$=callpoint!.getColumnData("APE_PAYSELECT.PAYMENT_GRP")
			filter_aptype$=callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE")
			filter_vendor$=callpoint!.getColumnData("APE_PAYSELECT.VENDOR_ID")
			filter_due_op$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_OP")
			filter_due_date$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT")
			filter_disc_op$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_OP")
			filter_disc_date$=callpoint!.getUserInput()
            filter_inv_no$=callpoint!.getColumnData("APE_PAYSELECT.AP_INV_NO")
		else
			if callpoint!.getVariableName()="APE_PAYSELECT.DUE_DATE_DT"
				filter_pymnt_grp$=callpoint!.getColumnData("APE_PAYSELECT.PAYMENT_GRP")
				filter_aptype$=callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE")
				filter_vendor$=callpoint!.getColumnData("APE_PAYSELECT.VENDOR_ID")
				filter_due_op$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_OP")
				filter_due_date$=callpoint!.getUserInput()
				filter_disc_op$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_OP")
				filter_disc_date$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT")
                filter_inv_no$=callpoint!.getColumnData("APE_PAYSELECT.AP_INV_NO")
			else
				if callpoint!.getVariableName()="APE_PAYSELECT.DISC_DATE_OP"
					filter_pymnt_grp$=callpoint!.getColumnData("APE_PAYSELECT.PAYMENT_GRP")
					filter_aptype$=callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE")
					filter_vendor$=callpoint!.getColumnData("APE_PAYSELECT.VENDOR_ID")
					filter_due_op$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_OP")
					filter_due_date$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT")
					filter_disc_op$=callpoint!.getUserInput()
					filter_disc_date$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT")
                    filter_inv_no$=callpoint!.getColumnData("APE_PAYSELECT.AP_INV_NO")
				else
					if callpoint!.getVariableName()="APE_PAYSELECT.DUE_DATE_OP"
						filter_pymnt_grp$=callpoint!.getColumnData("APE_PAYSELECT.PAYMENT_GRP")
						filter_aptype$=callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE")
						filter_vendor$=callpoint!.getColumnData("APE_PAYSELECT.VENDOR_ID")
						filter_due_op$=callpoint!.getUserInput()
						filter_due_date$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT")
						filter_disc_op$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_OP")
						filter_disc_date$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT")
                        filter_inv_no$=callpoint!.getColumnData("APE_PAYSELECT.AP_INV_NO")
					else
						if callpoint!.getVariableName()="APE_PAYSELECT.PAYMENT_GRP"
							filter_pymnt_grp$=callpoint!.getUserInput()
							filter_aptype$=callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE")
							filter_vendor$=callpoint!.getColumnData("APE_PAYSELECT.VENDOR_ID")
							filter_due_op$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_OP")
							filter_due_date$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT")
							filter_disc_op$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_OP")
							filter_disc_date$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT")
                            filter_inv_no$=callpoint!.getColumnData("APE_PAYSELECT.AP_INV_NO")
						else
							if callpoint!.getVariableName()="APE_PAYSELECT.VENDOR_ID"
								filter_pymnt_grp$=callpoint!.getColumnData("APE_PAYSELECT.PAYMENT_GRP")
								filter_aptype$=callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE")
								filter_vendor$=callpoint!.getUserInput()
								filter_due_op$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_OP")
								filter_due_date$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT")
								filter_disc_op$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_OP")
								filter_disc_date$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT")
                                filter_inv_no$=callpoint!.getColumnData("APE_PAYSELECT.AP_INV_NO")
							else
								if callpoint!.getVariableName()="APE_PAYSELECT.AP_TYPE"
									filter_pymnt_grp$=callpoint!.getColumnData("APE_PAYSELECT.PAYMENT_GRP")
									filter_aptype$=callpoint!.getUserInput()
									filter_vendor$=callpoint!.getColumnData("APE_PAYSELECT.VENDOR_ID")
									filter_due_op$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_OP")
									filter_due_date$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT")
									filter_disc_op$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_OP")
									filter_disc_date$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT")
                                    filter_inv_no$=callpoint!.getColumnData("APE_PAYSELECT.AP_INV_NO")
								else
                                    if callpoint!.getVariableName()="APE_PAYSELECT.AP_INV_NO"
                                        filter_pymnt_grp$=callpoint!.getColumnData("APE_PAYSELECT.PAYMENT_GRP")
                                        filter_aptype$=callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE")
                                        filter_vendor$=callpoint!.getColumnData("APE_PAYSELECT.VENDOR_ID")
                                        filter_due_op$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_OP")
                                        filter_due_date$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT")
                                        filter_disc_op$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_OP")
                                        filter_disc_date$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT")
                                        filter_inv_no$=callpoint!.getUserInput()
                                    else
										filter_pymnt_grp$=callpoint!.getColumnData("APE_PAYSELECT.PAYMENT_GRP")
										filter_aptype$=callpoint!.getColumnData("APE_PAYSELECT.AP_TYPE")
										filter_vendor$=callpoint!.getColumnData("APE_PAYSELECT.VENDOR_ID")
										filter_due_op$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_OP")
										filter_due_date$=callpoint!.getColumnData("APE_PAYSELECT.DUE_DATE_DT")
										filter_disc_op$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_OP")
										filter_disc_date$=callpoint!.getColumnData("APE_PAYSELECT.DISC_DATE_DT")
                                        filter_inv_no$=callpoint!.getColumnData("APE_PAYSELECT.AP_INV_NO")
                                    endif
								endif
							endif
						endif
					endif
				endif
			endif
		endif

		if cvs(filter_vendor$,3)="" filter_vendor$=""

	rem --- Set all excluded filtered flags to No 

		for x=1 to vect_size step user_tpl.MasterCols
			select_rec$="Y"

			if filter_pymnt_grp$<>"" and filter_pymnt_grp$<>vectInvoicesMaster!.getItem(x-1+2)
				select_rec$="N"
			endif

			if filter_aptype$<>"" and filter_aptype$<>vectInvoicesMaster!.getItem(x-1+3)
				select_rec$="N"
			endif
         
			if filter_inv_no$<>"" and pos(cvs(filter_inv_no$,3)=vectInvoicesMaster!.getItem(x-1+6))<>1
				select_rec$="N"
			endif

			if filter_vendor$<>"" and filter_vendor$<>vectInvoicesMaster!.getItem(x-1+16)
				select_rec$="N"
			endif

			if filter_due_op$<>"0" and filter_due_date$<>""
				if fn_filter_txt(filter_due_op$,vectInvoicesMaster!.getItem(x-1+15),filter_due_date$)=0
					select_rec$="N"
				endif
			endif

			if filter_disc_op$<>"0" and filter_disc_date$<>""
				if fn_filter_txt(filter_disc_op$,vectInvoicesMaster!.getItem(x-1+17),filter_disc_date$)=0
					select_rec$="N"
				endif
			endif

			if select_rec$="N"
				vectInvoicesMaster!.setItem(x-1,"N")
			endif
		next x

	rem --- Clear and reset visible grid

		vectInvoices!.clear()

		for x=1 to vect_size step user_tpl.MasterCols
			if vectInvoicesMaster!.getItem(x-1)="Y"
				for y=1 to num(user_tpl.gridInvoicesCols$)
					vectInvoices!.addItem(vectInvoicesMaster!.getItem(x-1+y))
				next y
			endif
		next x

		UserObj!.setItem(num(user_tpl.vectInvoicesMasterOfst$),vectInvoicesMaster!)
		UserObj!.setItem(num(user_tpl.vectInvoicesOfst$),vectInvoices!)
		gosub fill_grid
	endif

	return

rem ==========================================================================
view_images: rem --- Display the images associated with the selected invoices in the grid.
rem ==========================================================================

	rem --- Verify an invoice was selected
	if rowsSelected!.size() = 0 then
		callpoint!.setMessage("AD_NO_SELECTION")
		return
	endif

	rem --- Display invoice images in the browser
	invimage_dev=fnget_dev("@APT_INVIMAGE")
	dim invimage$:fnget_tpl$("@APT_INVIMAGE")

    urlVect!=BBjAPI().makeVector()
    
	image_count =0
	for rowCount = 0 to rowsSelected!.size()-1
		rem --- get the row data needed
		curr_row = num(rowsSelected!.getItem(rowCount))
		vendor_id$ = gridInvoices!.getCellText(curr_row,3)
		ap_inv_no$ = gridInvoices!.getCellText(curr_row,5)
		read record(invimage_dev, key=firm_id$+vendor_id$+ap_inv_no$, dom=*next)
		while 1
			invimage_key$=key(invimage_dev,end=*break)
			if pos(firm_id$+vendor_id$+ap_inv_no$=invimage_key$)<>1 then break
			invimage$=fattr(invimage$)
			read record(invimage_dev)invimage$

			switch (BBjAPI().TRUE)
				case invimage.scan_docs_to$="BDA"
					rem --- Do Barista Doc Archive
                    rem --- show all files in the browser
                    sslReq = BBUtils.isWebServerSSLEnabled()
                    url$ = BBUtils.copyFileToWebServer(cvs(invimage.doc_url$,2),"appreviewtemp", sslReq)
                    urlVect!.add(url$)
                    BBjAPI().getThinClient().browse(url$)
					break
				case invimage.scan_docs_to$="GD "
					rem --- Do Google Docs
					BBjAPI().getThinClient().browse(cvs(invimage.doc_url$,2))
					break
				case default
					rem --- Unknown ... skip
					break
			swend
			image_count = image_count + 1
		wend
	next rowCount

	msg_id$="GENERIC_OK"
	dim msg_tokens$[1]
	if image_count then
		msg_tokens$[1] = str(image_count) + " "+Translate!.getTranslation("AON_IMAGES_FOUND")
	else
		msg_tokens$[1]=Translate!.getTranslation("AON_NO_IMAGES_FOUND")
	endif
	gosub disp_message
    
    if urlVect!.size()
        for wk=0 to urlVect!.size()-1
            BBUtils.deleteFromWebServer(urlVect!.get(wk))
        next wk
    endif

	return

rem ==========================================================================
undo_pay_auth: rem --- undo a single approval or review back to previous state
rem ==========================================================================

    if !callpoint!.getDevObject("use_pay_auth") or rowsSelected!.size()<>1 then return;rem --- should only get here with a single row selected for undo when using pay auth

    apt_invapproval=fnget_dev("@APT_INVAPPROVAL")
	dim apt_invapproval$:fnget_tpl$("@APT_INVAPPROVAL")
    
    dim apm_approvers$:fnget_tpl$("@APM_APPROVERS")
	apm_approvers$=callpoint!.getDevObject("apm_approvers")
    
    user$=sysinfo.user_id$
    usertype$=""
    if apm_approvers.prelim_approval then
        rem --- Reviewer
        usertype$ = "R"
    endif
    if apm_approvers.check_signer then
        rem --- Approver
        usertype$ = usertype$+"A"
    endif
    if usertype$="" then
        rem --- Not reviewer or approver
        return
    endif
    
    rem --- Get grid row background colors
    gosub get_grid_back_colors

    rem --- Get vectors/totals map
    approvalsEntered! = callpoint!.getDevObject("approvalsEntered")
    approvalsUndone! = callpoint!.getDevObject("approvalsUndone")
    statusVect!=callpoint!.getDevObject("status_vect")
    vendorTotalsMap!=callpoint!.getDevObject("vendorTotalsMap")

    rem --- Get needed data for this row
    curr_row = num(rowsSelected!.getItem(0))
    vendor_id$ = gridInvoices!.getCellText(curr_row,3)
    vendor_name$ = gridInvoices!.getCellText(curr_row,4)
    ap_inv_no$ = gridInvoices!.getCellText(curr_row,5)
    inv_amt  = num(gridInvoices!.getCellText(curr_row,9))
    pmt_amt=num(gridInvoices!.getCellText(curr_row,12))
    thisVendor_total = cast(BBjNumber, vendorTotalsMap!.get(vendor_id$))

    gosub get_pay_auth_invoice_status

    if !reviewed then return;rem --- this shouldn't actually happen - should only be in this routine if reviewed or approved
 
    rem --- undo a review
    if reviewed and !approved
    
        rem --- get user confirmation
        msg_id$="AP_INV_PAY_UNDO"
        dim msg_tokens$[1]
        msg_tokens$[1]=statusVect!.get(2);rem reviewed
        gosub disp_message
        if msg_opt$<>"Y" then return
   
        rem --- was it reviewed this session (in approvalsEntered!) or previously (in apt_invapproval table)?
        rem --- if the former, take out of approvalsEntered!
        rem --- if the latter, remove from apt_invapproval
        rem --- either way, set back to 'New', and defaultColor!
        
        found_in_vector=0
        if approvalsEntered!.size() > 0 then
            for undo_tmp = 0 to approvalsEntered!.size() - 1
                apt_invapproval! = approvalsEntered!.getItem(undo_tmp)
                apt_invapproval$ = apt_invapproval!.getString()
                if pos(firm_id$+vendor_id$+ap_inv_no$+"00"=apt_invapproval$)=1
                    approvalsEntered!.removeItem(undo_tmp)
                    gosub undo_review
                    found_in_vector=1
                    break
                endif
            next undo_tmp
        endif
            
        if !found_in_vector
            rem --- check table
            dim apt_invapproval$:fattr(apt_invapproval$)
            readrecord(apt_invapproval,key=firm_id$+vendor_id$+ap_inv_no$+"00",dom=*endif)apt_invapproval$
			apt_invapproval! = BBjAPI().makeTemplatedString(fattr(apt_invapproval$))
			apt_invapproval!.setString(apt_invapproval$)
			approvalsUndone!.put(firm_id$+vendor_id$+ap_inv_no$+"00",apt_invapproval!)
            gosub undo_review
        endif
    endif
   
    rem --- undo an approval
    if approved
        rem --- was it approved this session (in approvalsEntered!) or previously (in apt_invapproval table)?
        rem --- if the former
        rem ---    take out of approvalsEntered!
        rem ---    was it final approval (4) in the vector and needing 2 signatures?
        rem ---    if yes and yes, set back to prelim approved (3) and appropriate color
        rem ---    if (yes and no) or (no and yes), set back to reviewed (2) and appropriate color
        rem --- if the latter, set grid status and colors as above, but also remove from apt_invapproval
        rem ---    if yes and yes, remove the second approval (should be sequence num 02)
        rem ---    if (yes and no) or (no and yes), remove the only/prelim approval (sequence num 01)
        
        rem --- Also: if going back to reviewed status, need to back inv_amt out of vendorTotalsMap! 
        rem ---       promotion of other invoices to fully approved may be in order if we're undoing an invoice leaving us under the 2-sig threshold
        rem ---       loop thru other invoices this vendor and if prelim approved (3), set to final (4), update vectors and grid (bold font, fullyApproved color)    
    
        if !pos("A"=usertype$)
            return
        else
            rem --- get user confirmation
            msg_id$="AP_INV_PAY_UNDO"
            dim msg_tokens$[1]
            msg_tokens$[1]=statusVect!.get(3);rem approved
            gosub disp_message
            if msg_opt$<>"Y" then return
          
            found_in_vector=0
            if approvalsEntered!.size() > 0 then
                for undo_tmp = 0 to approvalsEntered!.size() - 1
                    apt_invapproval! = approvalsEntered!.getItem(undo_tmp)
                    apt_invapproval$ = apt_invapproval!.getString()
                    if pos(firm_id$+vendor_id$+ap_inv_no$=apt_invapproval$)=1 
                        if vectInvoices!.get(curr_row*numcols)="3"
                            approvalsEntered!.removeItem(undo_tmp)
                            gosub undo_prelim_approval
                            break
                        endif
                        if vectInvoices!.get(curr_row*numcols)="4"
                            approvalsEntered!.removeItem(undo_tmp)
                            gosub undo_final_approval
                        endif
                        found_in_vector=1
                        break
                    endif
                next undo_tmp
            endif
            
            if !found_in_vector
                rem --- check table
                dim apt_invapproval$:fattr(apt_invapproval$)
                if vectInvoices!.get(curr_row*numcols)="3" 
                    readrecord(apt_invapproval,key=firm_id$+vendor_id$+ap_inv_no$+"01",dom=*endif)apt_invapproval$
                    apt_invapproval! = BBjAPI().makeTemplatedString(fattr(apt_invapproval$))
                    apt_invapproval!.setString(apt_invapproval$)
                    approvalsUndone!.put(firm_id$+vendor_id$+ap_inv_no$+"01",apt_invapproval!)
                    gosub undo_prelim_approval
                endif
                if vectInvoices!.get(curr_row*numcols)="4"
                    if callpoint!.getDevObject("two_sig_req") and thisVendor_total >= num(callpoint!.getDevObject("two_sig_amt"))
                        readrecord(apt_invapproval,key=firm_id$+vendor_id$+ap_inv_no$+"02",dom=*endif)apt_invapproval$
                        apt_invapproval! = BBjAPI().makeTemplatedString(fattr(apt_invapproval$))
                        apt_invapproval!.setString(apt_invapproval$)
                        approvalsUndone!.put(firm_id$+vendor_id$+ap_inv_no$+"02",apt_invapproval!)
                        gosub undo_final_approval
                    else
                        readrecord(apt_invapproval,key=firm_id$+vendor_id$+ap_inv_no$+"01",dom=*endif)apt_invapproval$
                        apt_invapproval! = BBjAPI().makeTemplatedString(fattr(apt_invapproval$))
                        apt_invapproval!.setString(apt_invapproval$)
                        approvalsUndone!.put(firm_id$+vendor_id$+ap_inv_no$+"01",apt_invapproval!)
                        gosub undo_final_approval
                    endif
                endif
                
            endif
        endif
    endif

    return

rem ==========================================================================
undo_review:
rem ==========================================================================
rem --- when undoing a reviewed invoice (back to New), updates the grid/vectors

    gridInvoices!.setCellText(curr_row,0,statusVect!.get(0));rem 'New'
    gridInvoices!.setRowBackColor(curr_row, defaultColor!)
    vectInvoices!.setItem(curr_row*numcols,"0")
    dummy = fn_setmast_flag(
:	    vectInvoices!.getItem(curr_row*numcols+2),
:		vectInvoices!.getItem(curr_row*numcols+3),
:		vectInvoices!.getItem(curr_row*numcols+5),
:		"0",
:		"0"
:	)

    callpoint!.setDevObject("undo_flag","Y")

    return

rem ==========================================================================
undo_prelim_approval:
rem ==========================================================================
rem --- when undoing a preliminary approval (back to Reviewed), updates the grid/vectors
rem --- also promotes remaining invoice(s) for same vendor if the undo has put us under the 2-sig threshold
    
    thisVendor_total=thisVendor_total-inv_amt
    vendorTotalsMap!.put(vendor_id$,thisVendor_total)
    gridInvoices!.setCellText(curr_row,0,statusVect!.get(2));rem 'Reviewed'
    gridInvoices!.setRowBackColor(curr_row, reviewedColor!)
    vectInvoices!.setItem(curr_row*numcols,"2")
    dummy = fn_setmast_flag(
:	    vectInvoices!.getItem(curr_row*numcols+2),
:		vectInvoices!.getItem(curr_row*numcols+3),
:		vectInvoices!.getItem(curr_row*numcols+5),
:		"2",
:		"0"
:	)
    if callpoint!.getDevObject("two_sig_req") and thisVendor_total< num(callpoint!.getDevObject("two_sig_amt"))
        rem --- iterate through other invoices this vendor and promote to final approval, since we are now under 2 sig threshold
        for promote_row=0 to vectInvoicesMaster!.size()-1 step num(user_tpl.MasterCols)
            if vectInvoicesMaster!.get(promote_row+4)>vendor_id$ then break
            if vectInvoicesMaster!.get(promote_row+4)=vendor_id$ and vectInvoicesMaster!.get(promote_row+1)="3"
                vectInvoicesMaster!.set(promote_row+1,"4")
                vectInvoicesMaster!.set(promote_row+13,vectInvoicesMaster!.get(promote_row+10))
                if vectInvoicesMaster!.get(promote_row)="Y"
                    vend_id$=vectInvoicesMaster!.get(promote_row+4)
                    ap_type$=vectInvoicesMaster!.get(promote_row+3)
                    inv_no$=vectInvoicesMaster!.get(promote_row+6)
                    gosub get_vectInvoices_offset
                    if vect_offset>=0
                    rem -- if newly-promoted invoice is showing in the grid, set vectInvoices and grid, too
                        if vectInvoices!.get(vect_offset)="3"
                            gridInvoices!.setSelectedRow(vect_offset/numcols);rem switch selected row to newly-promoted row
                            gridInvoices!.setRowBackColor(vect_offset/numcols, fullyApproved!)
                            selected=1
                            gosub selected_or_fully_approved
                        endif
                    endif
                endif
            endif
        next promote_row
    endif

    callpoint!.setDevObject("undo_flag","Y")

    return

rem ==========================================================================
undo_final_approval:
rem ==========================================================================
rem --- when undoing a final approval (back to Reviewed or Preliminary Approval), updates the grid/vectors

    if callpoint!.getDevObject("two_sig_req") and thisVendor_total >= num(callpoint!.getDevObject("two_sig_amt"))
        rem --- this was a final approval in a 2-sig scenario; set back to prelim approval
        gridInvoices!.setRowBackColor(curr_row, partiallyApproved!)
        selected_flag$="3"
        selected=0
        gosub selected_or_fully_approved
        
rem        gridInvoices!.setCellText(curr_row,0,statusVect!.get(3));rem 'Approved'
rem        gridInvoices!.setRowBackColor(curr_row, partiallyApproved!)
rem        gridInvoices!.setRowFont(curr_row,callpoint!.getDevObject("plain_font"))
rem        vectInvoices!.setItem(curr_row*numcols,"3")
rem        dummy = fn_setmast_flag(
rem :		    vectInvoices!.getItem(curr_row*numcols+2),
rem :			vectInvoices!.getItem(curr_row*numcols+3),
rem :			vectInvoices!.getItem(curr_row*numcols+5),
rem :			"3",
rem :			"0"
rem :		)
    else
        rem --- 2 sig not required, or we were below threshold, i.e., 2 sig not needed; set back to reviewed
        thisVendor_total=thisVendor_total-inv_amt
        vendorTotalsMap!.put(vendor_id$,thisVendor_total)
        gridInvoices!.setRowBackColor(curr_row, reviewedColor!)
        selected_flag$="2"
        selected=0
        gosub selected_or_fully_approved
        
rem        gridInvoices!.setCellText(curr_row,0,statusVect!.get(2));rem 'Reviewed'
rem        gridInvoices!.setRowBackColor(curr_row, reviewedColor!)
rem        gridInvoices!.setRowFont(curr_row,callpoint!.getDevObject("plain_font"))
rem        vectInvoices!.setItem(curr_row*numcols,"2")
rem        dummy = fn_setmast_flag(
rem :		    vectInvoices!.getItem(curr_row*numcols+2),
rem :			vectInvoices!.getItem(curr_row*numcols+3),
rem :			vectInvoices!.getItem(curr_row*numcols+5),
rem :			"2",
rem :			"0"
rem :       )                            
    endif

    callpoint!.setDevObject("undo_flag","Y")

    return
                            
rem ==========================================================================
get_vectInvoices_offset:
rem ==========================================================================

	vect_offset=-1
	for vect_x=0 to vectInvoices!.size() step num(user_tpl.gridInvoicesCols$)
		if vectInvoices!.getItem(vect_x+3)=vend_id$ and
:			vectInvoices!.getItem(vect_x+2)=ap_type$ and
:			vectInvoices!.getItem(vect_x+5)=inv_no$
			vect_offset=vect_x
			exitto vectInvoices_offset_return
		endif
	next vect_x
vectInvoices_offset_return:
	return
    
rem ==========================================================================
get_master_offset:
rem ==========================================================================

	for mast_x=0 to vectInvoicesMaster!.size() step num(user_tpl.MasterCols)
		if vectInvoicesMaster!.getItem(mast_x+4)=vend_id$ and
:			vectInvoicesMaster!.getItem(mast_x+3)=ap_type$ and
:			vectInvoicesMaster!.getItem(mast_x+6)=inv_no$
			mast_offset=mast_x
			exitto offset_return
		endif
	next mast_x
offset_return:
	return

rem =========================================================
get_grid_back_colors: rem --- Get grid row background colors
	rem --- output: defaultColor!
	rem --- output: reviewedColor!
	rem --- output: partiallyApproved!
	rem --- output: fullyApproved!
rem =========================================================
	rem --- Shouldn't get here unless using Payment Authorization.
	if !callpoint!.getDevObject("use_pay_auth")  then return

	rem --- Get grid default color
	RGB$=callpoint!.getDevObject("default_color")
	gosub get_RGB
	defaultColor! = BBjAPI().getSysGui().makeColor(R,G,B) 

	rem --- Get reviewed color (one_auth_color)
	RGB$=callpoint!.getDevObject("one_auth_color")
	gosub get_RGB
	reviewedColor! = BBjAPI().getSysGui().makeColor(R,G,B) 

	rem --- Get partially approved color (two_auth_color), if needed
	if callpoint!.getDevObject("two_sig_req") then
		RGB$=callpoint!.getDevObject("two_pay_auth")
		gosub get_RGB
		partiallyApproved! = BBjAPI().getSysGui().makeColor(R,G,B)
	else
		partiallyApproved! = null()
	endif

	rem --- Get fully approved color (all_auth_color)
	RGB$=callpoint!.getDevObject("all_auth_color")
	gosub get_RGB
	fullyApproved! = BBjAPI().getSysGui().makeColor(R,G,B)

	return

rem =========================================================
get_RGB: rem --- Parse Red, Green and Blue segments from RGB$ string
	rem --- input: RGB$
	rem --- output: R
	rem --- output: G
	rem --- output: B
rem =========================================================
	comma1=pos(","=RGB$,1,1)
	comma2=pos(","=RGB$,1,2)
	R=num(RGB$(1,comma1-1))
	G=num(RGB$(comma1+1,comma2-comma1-1))
	B=num(RGB$(comma2+1))
	return

rem ==========================================================================
rem --- Functions
rem ==========================================================================

rem --- fn_filter_txt: Check Operator data for text fields

	def fn_filter_txt(q1$,q2$,q3$)
		ret_val=0
		switch num(q1$)
			case 1; if q2$<q3$ ret_val=1; endif; break
			case 2; if q2$=q3$ ret_val=1; endif; break
			case 3; if q2$>q3$ ret_val=1; endif; break
			case 4; if q2$<=q3$ ret_val=1; endif; break
			case 5; if q2$>=q3$ ret_val=1; endif; break
			case 6; if q2$<>q3$ ret_val=1; endif; break
		swend
		return ret_val
	fnend

rem --- Set Selected Flag and Invoice Amount in InvoiceMaster vector

	def fn_setmast_flag(q1$,q2$,q3$,flag$,f_invamt$)
		for q=0 to vectInvoicesMaster!.size()-1 step user_tpl.MasterCols
			if vectInvoicesMaster!.getItem(q+3) = q1$ and
:				vectInvoicesMaster!.getItem(q+4) = q2$ and
:				vectInvoicesMaster!.getItem(q+6) = q3$
:			then
				vectInvoicesMaster!.setItem(q+1,flag$)
				vectInvoicesMaster!.setItem(q+13,f_invamt$)
				return 0
			endif
		next q

		return 0
	fnend

rem --- Set Discount and Payment Amount in InvoiceMaster vector

	def fn_setmast_amts(q1$,q2$,q3$,f_disc_amt$,f_pmt_amt$)
		for q=0 to vectInvoicesMaster!.size()-1 step user_tpl.MasterCols
			if vectInvoicesMaster!.getItem(q+3) = q1$ and
:				vectInvoicesMaster!.getItem(q+4) = q2$ and
:				vectInvoicesMaster!.getItem(q+6) = q3$
:			then
				vectInvoicesMaster!.setItem(q+12,f_disc_amt$)
				vectInvoicesMaster!.setItem(q+13,f_pmt_amt$)
				return 0
			endif
		next q

		return 0
	fnend

rem ==========================================================================
#include std_missing_params.src
#include std_functions.src
rem ==========================================================================
[[APE_PAYSELECT.ASVA]]
rem --- Update apt-01 (remove/write) based on what's checked in the grid

	apt01_dev = fnget_dev("APT_INVOICEHDR")
	dim apt01a$:fnget_tpl$("APT_INVOICEHDR")
	ape04_dev = fnget_dev("APE_CHECKS")
	dim ape04a$:fnget_tpl$("APE_CHECKS")
	apt11_dev = fnget_dev("APT_INVOICEDET")
	dim apt11a$:fnget_tpl$("APT_INVOICEDET")

	vectInvoicesMaster! = UserObj!.getItem(num(user_tpl.vectInvoicesMasterOfst$))

	if vectInvoicesMaster!.size()
rem --- First check to see if user_tpl.ap_check_seq$ is Y and multiple AP Types are selected
		aptypes$=""
		if user_tpl.ap_check_seq$="Y"
			for row=0 to vectInvoicesMaster!.size()-1 step user_tpl.MasterCols
				if vectInvoicesMaster!.getItem(row+1)="Y"
					if aptypes$<>""
						if vectInvoicesMaster!.getItem(row+3)<>aptypes$
							callpoint!.setMessage("AP_NO_SELECT")
							aptypes$="ABORT"
						endif
					else
						aptypes$=vectInvoicesMaster!.getItem(row+3)
					endif
				endif
			next row
		endif

		if aptypes$<>"ABORT"
			call stbl("+DIR_PGM")+"adc_clearpartial.aon","N",ape04_dev,firm_id$,status

			for row=0 to vectInvoicesMaster!.size()-1 step user_tpl.MasterCols
				vend$ = vectInvoicesMaster!.getItem(row+4)
				apt01_key$=firm_id$+vectInvoicesMaster!.getItem(row+3)+
:								   vend$+
:								   vectInvoicesMaster!.getItem(row+6)
				extract record (apt01_dev, key=apt01_key$) apt01a$; rem Advisory Locking
				orig_inv_amt   = num(vectInvoicesMaster!.getItem(row+18))
				inv_amt = num(vectInvoicesMaster!.getItem(row+10))
				disc_to_take = num(vectInvoicesMaster!.getItem(row+12))
				amt_to_pay   = num(vectInvoicesMaster!.getItem(row+13))
				payments=0
				retention=0

				read(apt11_dev,key=apt01_key$,dom=*next)
				while 1
					read record(apt11_dev,end=*break)apt11a$
					if pos(apt01_key$=apt11a$)<>1 break
					payments=payments+apt11a.trans_amt
					retention=retention+apt11a.trans_ret
				wend

                rem --- '1' is selected when no pay auth, 4 is final approval when using pay auth
				if pos(vectInvoicesMaster!.getItem(row+1)="14")=0
					apt01a.selected_for_pay$="N"
					remove (ape04_dev, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, dom=*next)
				else
					apt01a.selected_for_pay$="Y"
					dim ape04a$:fattr(ape04a$)

					ape04a.firm_id$      = firm_id$
					ape04a.ap_type$      = apt01a.ap_type$
					ape04a.vendor_id$    = apt01a.vendor_id$
					ape04a.ap_inv_no$    = apt01a.ap_inv_no$
					ape04a.reference$    = apt01a.reference$
					ape04a.ap_inv_memo$  = apt01a.ap_inv_memo$
					ape04a.invoice_date$ = apt01a.invoice_date$
					ape04a.inv_due_date$ = apt01a.inv_due_date$
					ape04a.disc_date$    = apt01a.disc_date$
					ape04a.invoice_amt   = inv_amt
					ape04a.discount_amt  = disc_to_take
					ape04a.retention     = apt01a.retention+retention
					ape04a.orig_inv_amt  = apt01a.invoice_amt
					ape04a.payment_amt = amt_to_pay

					ape04a$=field(ape04a$)
					extract record (ape04_dev, key=apt01_key$, dom=*next) dummy$; rem Advisory Locking
					write record (ape04_dev) ape04a$
				endif

				apt01a$ = field(apt01a$)
				write record (apt01_dev) apt01a$
			next row
		endif
	endif

rem --- Payment Authorization needs to write approvals to file and send emails

	if callpoint!.getDevObject("use_pay_auth") then
    	apt_invapproval=fnget_dev("@APT_INVAPPROVAL")
		dim apt_invapproval$:fnget_tpl$("@APT_INVAPPROVAL")
		rem --- Write approvals to file
		approvalsEntered! = callpoint!.getDevObject("approvalsEntered")
		if approvalsEntered!.size() > 0 then
			for item = 0 to approvalsEntered!.size() - 1
				apt_invapproval! = approvalsEntered!.getItem(item)
				apt_invapproval$ = apt_invapproval!.getString()
				apt_invapproval$ = field(apt_invapproval$)
				write record(apt_invapproval)apt_invapproval$
			next item
		endif
		rem --- Remove undone/reverted approvals from file
		approvalsUndone! = callpoint!.getDevObject("approvalsUndone")
        approvalsUndoneIter!=approvalsUndone!.keySet().iterator()
        while approvalsUndoneIter!.hasNext()
            undoneKey$=approvalsUndoneIter!.next()
			remove(apt_invapproval,key=undoneKey$,err=*next)
		wend

		rem --- Send notification emails
        if approvalsEntered!.size()>0 or callpoint!.getDevObject("undo_flag")="Y" then gosub send_payauth_email
    endif
[[APE_PAYSELECT.AWIN]]
rem --- Open/Lock files

    use ::BBUtils.bbj::BBUtils
	use ::ado_util.src::util
    use java.util.Iterator

	num_files=12
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="APT_INVOICEHDR",open_opts$[1]="OTA"
	open_tables$[2]="APT_INVOICEDET",open_opts$[2]="OTA"
	open_tables$[3]="APM_VENDMAST",open_opts$[3]="OTA"
	open_tables$[4]="APE_CHECKS",open_opts$[4]="OTAL"
	open_tables$[5]="APW_CHECKINVOICE",open_opts$[5]="OTA"
	open_tables$[6]="APE_INVOICEHDR",open_opts$[6]="OTA"
	open_tables$[7]="APS_PARAMS",open_opts$[7]="OTA"
	open_tables$[8]="APS_PAYAUTH",open_opts$[8]="OTA@"
	open_tables$[9]="APT_INVIMAGE",open_opts$[9]="OTA@"
	open_tables$[10]="APT_INVAPPROVAL",open_opts$[10]="OTA@"
	open_tables$[11]="ADM_USER",open_opts$[11]="OTA@"
	open_tables$[12]="APM_APPROVERS",open_opts$[12]="OTA@"

	gosub open_tables

	apt01_dev=num(open_chans$[1]),apt01_tpl$=open_tpls$[1]
	apt11_dev=num(open_chans$[2]),apt11_tpl$=open_tpls$[2]
	apm01_dev=num(open_chans$[3]),apm01_tpl$=open_tpls$[3]
	ape04_dev=num(open_chans$[4]),ape04_tpl$=open_tpls$[4]
	apw01_dev=num(open_chans$[5])
	ape01_dev=num(open_chans$[6]),ape01_tpl$=open_tpls$[6]
	aps_params=num(open_chans$[7]),aps_params_tpl$=open_tpls$[7]
	aps_payauth=num(open_chans$[8]),aps_payauth_tpl$=open_tpls$[8]
	apt_invapproval=num(open_chans$[10]),apt_inapproval_tpl$=open_tpls$[10]

rem --- Dimension string templates

	dim apt01a$:apt01_tpl$
	dim apt11a$:apt11_tpl$
	dim apm01a$:apm01_tpl$
	dim ape04a$:ape04_tpl$
	dim ape01a$:ape01_tpl$
	dim aps_params$:aps_params_tpl$
	dim aps_payauth$:aps_payauth_tpl$
	dim apt_invapproval$:apt_inapproval_tpl$

rem --- Get parameter record

	readrecord(aps_params, key=firm_id$+"AP00", dom=std_missing_params) aps_params$
	callpoint!.setDevObject("multi_types",aps_params.multi_types$)

	readrecord(aps_payauth,key=firm_id$+"AP00",dom=*next)aps_payauth$
	callpoint!.setDevObject("use_pay_auth",aps_payauth.use_pay_auth)
	callpoint!.setDevObject("send_email",aps_payauth.send_email)
	callpoint!.setDevObject("scan_docs_to",aps_payauth.scan_docs_to$)
	callpoint!.setDevObject("all_auth_color",aps_payauth.all_auth_color$)
	callpoint!.setDevObject("default_color","255,255,255"); rem --- white
	callpoint!.setDevObject("one_auth_color",aps_payauth.one_auth_color$)
	callpoint!.setDevObject("two_pay_auth",aps_payauth.two_auth_color$)
	callpoint!.setDevObject("two_sig_req",aps_payauth.two_sig_req)
	callpoint!.setDevObject("two_sig_amt",aps_payauth.two_sig_amt)
    wk$=fattr(apt_invapproval$,"SEQUENCE_NUM")
    callpoint!.setDevObject("seq_no_mask",fill(dec(wk$(10,2)),"0"))
    callpoint!.setDevObject("undo_flag","")
    callpoint!.setDevObject("selections_made","")

rem --- See if Check Printing has already been started

	k$=""	
	read (apw01_dev,key=firm_id$,dom=*next)
	k$=key(apw01_dev,end=*next)
	if pos(firm_id$=k$)=1 then
		msg_id$="CHECKS_IN_PROGRESS"
		gosub disp_message
		if pos("PASSVALID"=msg_opt$)=0 or callpoint!.getDevObject("use_pay_auth") then
			rem --- Password override not currently allowed with Payment Authorization
			bbjAPI!=bbjAPI()
			rdFuncSpace!=bbjAPI!.getGroupNamespace()
			rdFuncSpace!.setValue("+build_task","OFF")
			release
		endif
	endif

rem --- Ask if user wants to clear out ape-04 (computer checks) when running without Payment Authorization

	if !callpoint!.getDevObject("use_pay_auth")
		while 1
			read(ape04_dev,key=firm_id$,dom=*next)
			ape04_key$=key(ape04_dev,end=*break)
			if pos(firm_id$=ape04_key$)<>1 break

			msg_id$="CLEAR_SEL"
			dim msg_tokens$[1]
			msg_opt$=""
			gosub disp_message

			if msg_opt$="Y" then
				read(apt01_dev,key=firm_id$,dom=*next)
				more=1

				while more
					apt01_key$=key(apt01_dev,end=*break)
					if pos(firm_id$=apt01_key$)<>1 then break
					extract record (apt01_dev, key=apt01_key$, err=*break) apt01a$; rem Advisory Locking
					remove (ape04_dev,key=apt01_key$,dom=*next, err=*break); rem Advisory Locking
					apt01a.selected_for_pay$="N"
					apt01a$=field(apt01a$)
					write record (apt01_dev) apt01a$
				wend
			endif

			break
		wend
	endif

rem --- Add grid to store invoices

	user_tpl_str$ = "gridInvoicesOfst:c(5), " +
:		"gridInvoicesCols:c(5), " +
:		"gridInvoicesRows:c(5), " +
:		"gridInvoicesCtlID:c(5)," +
:		"vectInvoicesOfst:c(5), " +
:		"vectInvoicesMasterOfst:c(5), " +
:		"MasterCols:n(5), " +
:		"retention_col:u(1), " +
:		"ap_check_seq:c(1)"
	dim user_tpl$:user_tpl_str$

	UserObj! = BBjAPI().makeVector()
	vectInvoices! = BBjAPI().makeVector()
	vectInvoicesMaster! = BBjAPI().makeVector()
	nxt_ctlID = util.getNextControlID()
    tmpCtl!=callpoint!.getControl("APE_PAYSELECT.DISC_DATE_DT")
    grid_y=tmpCtl!.getY()+tmpCtl!.getHeight()+5
	gridInvoices! = Form!.addGrid(nxt_ctlID,5,grid_y,800,300); rem --- ID, x, y, width, height
    popUpMenu!=SysGUI!.addPopupMenu();rem --- define popup menu for making status changes
    if !callpoint!.getDevObject("use_pay_auth")
        option_text$=Translate!.getTranslation("AON_SELECT_DESELECT")
    else
        option_text$="&"+Translate!.getTranslation("AON_REVIEW_APPROVE")
        callpoint!.setOptionText("PROC",option_text$)
    endif
    
    menuItem_proc!=popUpMenu!.addMenuItem(-(200),option_text$)
    menuItem_proc!.setCallback(menuItem_proc!.ON_POPUP_ITEM_SELECT,"custom_event")

	user_tpl.gridInvoicesCtlID$ = str(nxt_ctlID)
	user_tpl.gridInvoicesCols$ = "14"
	user_tpl.gridInvoicesRows$ = "10"
	user_tpl.MasterCols = 19
	user_tpl.retention_col = 14
	user_tpl.ap_check_seq$=aps_params.ap_check_seq$

	call stbl("+DIR_PGM")+"adc_getmask.aon","","AP","A","",ap_a_mask$,0,0
	callpoint!.setDevObject("ap_a_mask",ap_a_mask$)

	gosub format_grid
	util.resizeWindow(Form!, SysGui!)

	UserObj!.addItem(gridInvoices!)
	user_tpl.gridInvoicesOfst$="0"

	UserObj!.addItem(vectInvoices!); rem --- vector of filtered recs from Open Invoices; this gets cleared/re-built to create the filtered view
	user_tpl.vectInvoicesOfst$="1"

	UserObj!.addItem(vectInvoicesMaster!); rem --- vector of all Open Invoices
	user_tpl.vectInvoicesMasterOfst$="2"

rem --- Misc other init

	call stbl("+DIR_PGM")+"adc_getmask.aon","VENDOR_ID","","","",m0$,0,vendor_len
	gridInvoices!.setColumnMask(3,m0$)

	callpoint!.setDevObject("tot_payments","0")
	gridInvoices!.setColumnEditable(11,1)
	gridInvoices!.setColumnEditable(12,1)
	gridInvoices!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)
	gridInvoices!.setTabAction(gridInvoices!.GRID_NAVIGATE_GRID)
	gridInvoices!.setTabActionSkipsNonEditableCells(1)
    
    statusVect!=BBjAPI().makeVector()
    statusVect!.addItem(Translate!.getTranslation("AON_NEW"))
    statusVect!.addItem(Translate!.getTranslation("AON_SELECTED"))
    statusVect!.addItem(Translate!.getTranslation("AON_REVIEWED"))
    statusVect!.addItem(Translate!.getTranslation("AON_APPROVED"))
    statusVect!.addItem(Translate!.getTranslation("AON_APPROVED"));rem text is the same, but the offset in the vector indicates first approval (3) or final approval (4)
    callpoint!.setDevObject("status_vect",statusVect!)

    if callpoint!.getDevObject("use_pay_auth")

		rem --- Read Approvers&Signers table to get approval level for current user
		rem --- Build popup menu accordingly

		apm_approvers=fnget_dev("@APM_APPROVERS")
		dim apm_approvers$:fnget_tpl$("@APM_APPROVERS")

		user$=sysinfo.user_id$
		read record(apm_approvers,key=firm_id$ + user$,dom=*next)apm_approvers$
		callpoint!.setDevObject("apm_approvers",apm_approvers$)

		if !apm_approvers.prelim_approval and !apm_approvers.check_signer
            rem --- non-reviewer/approver can make no changes to status or pay/disc
            menuItem_proc!.setEnabled(0)
            callpoint!.setOptionEnabled("PROC",0)
			gridInvoices!.setColumnEditable(11,0)
			gridInvoices!.setColumnEditable(12,0)
		else
			if apm_approvers.prelim_approval and !apm_approvers.check_signer                  
                rem --- reviewer cannot change pay/disc
                gridInvoices!.setColumnEditable(11,0)
                gridInvoices!.setColumnEditable(12,0)               
            endif
		endif

		rem --- Make a vector to hold Payment Authorization approvals done in the session
		approvalsEntered! = BBjAPI().makeVector()
		callpoint!.setDevObject("approvalsEntered",approvalsEntered!)
        approvalsUndone!=new java.util.HashMap()
        callpoint!.setDevObject("approvalsUndone",approvalsUndone!)

		rem --- Get Barista's Document Queue object 
		use ::sys/prog/bao_docqueue.bbj::DocumentQueue
		docQueue! = new DocumentQueue()
		callpoint!.setDevObject("docQueue",docQueue!)

		rem --- Get current user's user record
		adm_user=fnget_dev("@ADM_USER")
		dim adm_user$:fnget_tpl$("@ADM_USER")
		read record(adm_user,key=apm_approvers.user_id$,dom=*next)adm_user$
		callpoint!.setDevObject("adm_user",adm_user$)
        
		popUpMenu!.addSeparator()
		menuItem_view!=popUpMenu!.addMenuItem(-300,Translate!.getTranslation("AON_VIEW_IMAGES"))
		menuItem_view!.setCallback(menuItem_view!.ON_POPUP_ITEM_SELECT,"custom_event")
		if callpoint!.getDevObject("scan_docs_to")="NOT"
			menuItem_view!.setEnabled(0)
        endif
        
        if apm_approvers.prelim_approval or apm_approvers.check_signer
            popUpMenu!.addSeparator()
            menuItem_undo!=popUpMenu!.addMenuItem(-400,Translate!.getTranslation("AON_UNDO","Undo"))
            menuItem_undo!.setCallback(menuItem_undo!.ON_POPUP_ITEM_SELECT,"custom_event")
            callpoint!.setDevObject("menu_undo",menuItem_undo!)
        else
            callpoint!.setOptionEnabled("UNDO",0)
        endif
    else
        callpoint!.setOptionEnabled("UNDO",0)
        callpoint!.setOptionEnabled("VIEW",0)
    endif

rem --- Now add the popup menu to the grid

	gridInvoices!.setPopupMenu(popUpMenu!)


rem --- get font for grid, and create a bold font to use for selected/finalized invoices

	plainFont!=gridInvoices!.getRowFont(0)
	boldFont!=sysGUI!.makeFont(plainFont!.getName(),plainFont!.getSize(),BBjFont.FONT_BOLD)
	callpoint!.setDevObject("bold_font",boldFont!)
	callpoint!.setDevObject("plain_font",plainFont!)

	gosub create_invoices_vector
	gosub fill_grid

rem --- Set callbacks - processed in ACUS callpoint

	gridInvoices!.setCallback(gridInvoices!.ON_GRID_EDIT_STOP,"custom_event")
	gridInvoices!.setCallback(gridInvoices!.ON_GRID_RIGHT_MOUSE_DOWN,"custom_event")

[[APE_PAYSELECT.ASIZ]]
rem --- Resize the grid

	if UserObj!<>null() then
		gridInvoices!=UserObj!.getItem(num(user_tpl.gridInvoicesOfst$))
		gridInvoices!.setSize(Form!.getWidth()-(gridInvoices!.getX()*2),Form!.getHeight()-(gridInvoices!.getY()+10))
		gridInvoices!.setFitToGrid(1)
	endif
[[APE_PAYSELECT.ACUS]]
rem --- Process custom event
rem --- Select/de-select checkboxes in grid and edit payment and discount amounts

rem This routine is executed when callbacks have been set to run a 'custom event'.
rem Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind of event it is.
rem See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info.

	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ctl_ID=dec(gui_event.ID$)
	new_popup_index=-1

	if ctl_ID <> num(user_tpl.gridInvoicesCtlID$) then break; rem --- exit callpoint
	gridInvoices! = UserObj!.getItem(num(user_tpl.gridInvoicesOfst$))
	rowsSelected! = gridInvoices!.getSelectedRows()
	numcols = gridInvoices!.getNumColumns()
	vectInvoices! = UserObj!.getItem(num(user_tpl.vectInvoicesOfst$))
	vectInvoicesMaster! = UserObj!.getItem(num(user_tpl.vectInvoicesMasterOfst$))
    statusVect! = callpoint!.getDevObject("status_vect")
    
	rem --- Get selected pop-up menu item
	if gui_event.code$="P"
		popUpMenu!=gridInvoices!.getPopupMenu()
		menuItem!=popUpMenu!.getMenuItem(gui_event.y)
        if gui_event.y=400
            gosub undo_pay_auth
        else
            if gui_event.y=300
                gosub view_images
            else
                new_popup_index=gui_event.y-200
                gosub change_invoice_status
            endif
		endif
	endif

	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
		curr_row = dec(notice.row$)
		curr_col = dec(notice.col$)

		switch notice.code
			case 18; rem --- right_mouse_down
                     rem --- see to it that a right click to get popup menu also selects the clicked row when there are no other rows selected
                     rem --- also disable the 'undo' menu option unless using pay auth and only one row is selected
                
                menuItem_undo!=callpoint!.getDevObject("menu_undo")                     
                     
				if !rowsSelected!.size()
					gridInvoices!.setSelectedRow(curr_row)
                    if menuItem_undo!<>null() then menuItem_undo!.setEnabled(1)
				endif
                
                if menuItem_undo!<>null()
                    if rowsSelected!.size()>1
                        menuItem_undo!.setEnabled(0)
                    else
                        menuItem_undo!.setEnabled(1)
                    endif
                endif

			break

			case 7; rem --- edit_stop

				apm01_dev = fnget_dev("APM_VENDMAST")
				dim apm01a$:fnget_tpl$("APM_VENDMAST")
				apt01_dev = fnget_dev("APT_INVOICEHDR")
				dim apt01a$:fnget_tpl$("APT_INVOICEHDR")
				tot_payments=num(callpoint!.getDevObject("tot_payments"))

                if gridInvoices!.getCellState(curr_row,6) 
                    msg_id$="AP_INV_RMVHOLD"
                    gosub disp_message
                    if msg_opt$<>"Y"
                        gridInvoices!.setCellText(curr_row,11,str(0))
                        gridInvoices!.setCellText(curr_row,12,str(0))
                        break
                    endif
                endif

				rem --- Discount Amount
				
				if curr_col = 11 then
					ap_type$ = gridInvoices!.getCellText(curr_row,2)
					vend_id$ = gridInvoices!.getCellText(curr_row,3)
					inv_no$ = gridInvoices!.getCellText(curr_row,5)
					inv_amt  = num(gridInvoices!.getCellText(curr_row,10))
					disc_amt = num(gridInvoices!.getCellText(curr_row,11))
					pmt_amt  = num(gridInvoices!.getCellText(curr_row,12))
					retent_amt = num(gridInvoices!.getCellText(curr_row,13))
					gosub get_master_offset
					orig_inv_amt = num(vectInvoicesMaster!.getItem((mast_offset)+18))
					tot_payments=tot_payments-pmt_amt;rem back out old payment in prep for adding new one

					if sgn(disc_amt) <> sgn(orig_inv_amt) then 
						disc_amt = abs(disc_amt) * sgn(orig_inv_amt)
						gridInvoices!.setCellText(curr_row,11,str(disc_amt))
					endif

					if abs(disc_amt) <> abs(orig_inv_amt) - abs(retent_amt) - abs(pmt_amt)
						if pmt_amt=0 or abs(disc_amt) > abs(orig_inv_amt) - abs(retent_amt) - abs(pmt_amt)  then 
							pmt_amt = (abs(orig_inv_amt) - abs(retent_amt) - abs(disc_amt)) * sgn(orig_inv_amt)
							gridInvoices!.setCellText(curr_row,12,str(pmt_amt))
						endif
						inv_amt = orig_inv_amt -  (abs(retent_amt) + abs(disc_amt) + abs(pmt_amt)) * sgn(orig_inv_amt)
						gridInvoices!.setCellText(curr_row,10,str(inv_amt))
					endif
                  
                    rem --- if not using pay auth, changing disc/pay amounts doesn't auto-select
                    if !callpoint!.getDevObject("use_pay_auth")                    
                        if disc_amt<>0 or inv_amt<>0 then 
                            dummy = fn_setmast_flag(
:								vectInvoices!.getItem(curr_row*numcols+2),
:								vectInvoices!.getItem(curr_row*numcols+3),
:								vectInvoices!.getItem(curr_row*numcols+5),
:								"1",
:								str(pmt_amt)
:							    )

                                vectInvoices!.setItem(curr_row * numcols, "1")
                                gridInvoices!.setCellText(curr_row,0,statusVect!.get(1))
                                gridInvoices!.setRowFont(curr_row,callpoint!.getDevObject("bold_font"))

                        else 
                            dummy = fn_setmast_flag(
:								vectInvoices!.getItem(curr_row*numcols+2),
:								vectInvoices!.getItem(curr_row*numcols+3),
:								vectInvoices!.getItem(curr_row*numcols+5),
:								"0",
:								"0"
:							    )

                                vectInvoices!.setItem(curr_row * numcols, "0")
                                gridInvoices!.setCellText(curr_row,0,statusVect!.get(0))
                                gridInvoices!.setRowFont(curr_row,callpoint!.getDevObject("plain_font"))
						endif
					endif

					vectInvoices!.setItem(curr_row*num(user_tpl.gridInvoicesCols$)+11,str(disc_amt))
					vectInvoices!.setItem(curr_row*num(user_tpl.gridInvoicesCols$)+12,str(pmt_amt))
					dummy = fn_setmast_amts(
:						vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+2),
:						vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+3),
:						vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+5),
:						str(disc_amt),
:						str(pmt_amt)
:					    )

                    if !callpoint!.getDevObject("use_pay_auth")
                        if pmt_amt=0 then
                            rem --- de-select payment
                            x=curr_row
                            selected_flag$="0"
                            selected=0
                            gosub selected_or_fully_approved
                            curr_row=x
                        else
                            dummy = fn_setmast_flag(
:								vectInvoices!.getItem(curr_row*numcols+2),
:								vectInvoices!.getItem(curr_row*numcols+3),
:								vectInvoices!.getItem(curr_row*numcols+5),
:								"1",
:								str(pmt_amt)
:							    )

                                vectInvoices!.setItem(curr_row * numcols, "1")
                                gridInvoices!.setCellText(curr_row,0,statusVect!.get(1))
                                gridInvoices!.setRowFont(curr_row,callpoint!.getDevObject("bold_font"))
						endif
					endif

					inv_amt = orig_inv_amt -  (abs(retent_amt) + abs(disc_amt) + abs(pmt_amt)) * sgn(orig_inv_amt)
					gridInvoices!.setCellText(curr_row,10,str(inv_amt))
					vectInvoices!.setItem(curr_row*num(user_tpl.gridInvoicesCols$)+11,str(disc_amt))
					vectInvoices!.setItem(curr_row*num(user_tpl.gridInvoicesCols$)+12,str(pmt_amt))
					dummy = fn_setmast_amts(
:						vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+2),
:						vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+3),
:						vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+5),
:						str(disc_amt),
:						str(pmt_amt)
:					)
					tot_payments=tot_payments+num(vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+12))
				endif

				rem --- Payment Amount

				if curr_col=12

					rem --- re-initialize
					apm01_dev = fnget_dev("APM_VENDMAST")
					dim apm01a$:fnget_tpl$("APM_VENDMAST")
					apt01_dev = fnget_dev("APT_INVOICEHDR")
					dim apt01a$:fnget_tpl$("APT_INVOICEHDR")
					apt11_dev = fnget_dev("APT_INVOICEDET")
					dim apt11a$:fnget_tpl$("APT_INVOICEDET")
					vend$ = gridInvoices!.getCellText(curr_row,3)

					read record (apt01_dev, key=firm_id$+
:						gridInvoices!.getCellText(curr_row,2)+
:						vend$+
:						gridInvoices!.getCellText(curr_row,5), dom=*next) apt01a$
					
					read record(apt11_dev, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, dom=*next)
					while 1
						readrecord(apt11_dev,end=*break)apt11a$
						if pos(firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$ =
:							    firm_id$+apt11a.ap_type$+apt11a.vendor_id$+apt11a.ap_inv_no$) <> 1 
:						then 
							break
						endif

						apt01a.invoice_amt = apt01a.invoice_amt + apt11a.trans_amt
						apt01a.discount_amt = apt01a.discount_amt + apt11a.trans_disc
					wend

	                if apt01a.discount_amt<0 and apt01a.invoice_amt>0 then apt01a.discount_amt=0
					gridInvoices!.setCellText(curr_row, 10, str(str(apt01a.invoice_amt - apt01a.retention - apt01a.discount_amt)))

					if callpoint!.getColumnData("APE_PAYSELECT.INCLUDE_DISC")="Y" or
:						apt01a.disc_date$ >= sysinfo.system_date$
:					then
						gridInvoices!.setCellText(curr_row, 11, apt01a.discount_amt$)
					else
						gridInvoices!.setCellText(curr_row, 11, "0.00")
					endif

					rem --- Now calculate proper Amt Due, Payment and Discount amounts

					ap_type$ = gridInvoices!.getCellText(curr_row,2)
					vend_id$ = gridInvoices!.getCellText(curr_row,3)
					inv_no$ = gridInvoices!.getCellText(curr_row,5)
					inv_amt  = num(gridInvoices!.getCellText(curr_row,10))
					disc_amt = num(gridInvoices!.getCellText(curr_row,11))
					pmt_amt  = num(gridInvoices!.getCellText(curr_row,12))
					retent_amt = num(gridInvoices!.getCellText(curr_row,13))
					gosub get_master_offset
					orig_inv_amt = num(vectInvoicesMaster!.getItem((mast_offset)+18))
					tot_payments=tot_payments-num(vectInvoicesMaster!.getItem((mast_offset)+13));rem back out old payment in prep for adding new one
					if sgn(pmt_amt) <> sgn(orig_inv_amt) then 
						pmt_amt = abs(pmt_amt) * sgn(orig_inv_amt)
						gridInvoices!.setCellText(curr_row,12,str(pmt_amt))
					endif

					if abs(pmt_amt)>abs(inv_amt)+abs(disc_amt)
						pmt_amt=(abs(inv_amt)+abs(disc_amt))*sgn(orig_inv_amt)
						gridInvoices!.setCellText(curr_row,12,str(pmt_amt))
					endif

					if abs(disc_amt)=0
						if abs(pmt_amt)>abs(inv_amt)
							pmt_amt=inv_amt
							gridInvoices!.setCellText(curr_row,12,str(pmt_amt))
						endif
					endif

					if abs(disc_amt)>0					
						if abs(pmt_amt)-abs(disc_amt)>=abs(inv_amt)
							disc_amt=(abs(orig_inv_amt)-abs(inv_amt)-abs(disc_amt)) * sgn(orig_inv_amt)
							gridInvoices!.setCellText(curr_row,11,str(disc_amt))
						endif
					endif

					if abs(pmt_amt) > abs(orig_inv_amt) - abs(retent_amt) - abs(disc_amt) then 
						disc_amt = (abs(orig_inv_amt) - abs(retent_amt) - abs(pmt_amt)) * sgn(orig_inv_amt)
						gridInvoices!.setCellText(curr_row,11,str(disc_amt))
					endif

                    if !callpoint!.getDevObject("use_pay_auth")
                        if pmt_amt=0 then
                            rem --- de-select payment
                            x=curr_row
                            selected_flag$="0"
                            selected=0
                            gosub selected_or_fully_approved
                            curr_row=x
                        else
                            dummy = fn_setmast_flag(
:								vectInvoices!.getItem(curr_row*numcols+2),
:								vectInvoices!.getItem(curr_row*numcols+3),
:								vectInvoices!.getItem(curr_row*numcols+5),
:								"1",
:								str(pmt_amt)
:							    )

                                vectInvoices!.setItem(curr_row * numcols, "1")
                                gridInvoices!.setCellText(curr_row,0,statusVect!.get(1))
                                gridInvoices!.setRowFont(curr_row,callpoint!.getDevObject("bold_font"))
						endif
					endif

					inv_amt = orig_inv_amt -  (abs(retent_amt) + abs(disc_amt) + abs(pmt_amt)) * sgn(orig_inv_amt)
					gridInvoices!.setCellText(curr_row,10,str(inv_amt))
					vectInvoices!.setItem(curr_row*num(user_tpl.gridInvoicesCols$)+11,str(disc_amt))
					vectInvoices!.setItem(curr_row*num(user_tpl.gridInvoicesCols$)+12,str(pmt_amt))
					dummy = fn_setmast_amts(
:						vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+2),
:						vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+3),
:						vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+5),
:						str(disc_amt),
:						str(pmt_amt)
:					)
					tot_payments=tot_payments+num(vectInvoices!.getItem(curr_row*num(user_tpl.gridInvoicesCols$)+12))
				endif
				callpoint!.setDevObject("tot_payments",str(tot_payments))
			break
		swend

		tot_payments=num(callpoint!.getDevObject("tot_payments"))
		callpoint!.setColumnData("<<DISPLAY>>.TOT_PAYMENTS",str(tot_payments),1)
