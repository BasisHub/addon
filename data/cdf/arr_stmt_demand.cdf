[[ARR_STMT_DEMAND.AREC]]
rem --- use ReportControl object to see if this customer is set up for email/fax statement

	use ::ado_rptControl.src::ReportControl

	rpt_id$=pad("ARR_STATEMENTS",16);rem use ARR_STATEMENTS for regular (batch) and on-demand, so customers don't have to be set up multiple times

rem --- See if this document/recipient is set up in Addon Report Control

	reportControl!=new ReportControl()
	found=reportControl!.getRecipientInfo(rpt_id$,callpoint!.getColumnData("ARR_STMT_DEMAND.CUSTOMER_ID"),"")

	if found and (reportControl!.getEmailYN()="Y" or reportControl!.getFaxYN()="Y")
		callpoint!.setColumnEnabled("ARR_STMT_DEMAND.PICK_CHECK",1)
	else
		callpoint!.setColumnEnabled("ARR_STMT_DEMAND.PICK_CHECK",0)
	endif

	rem --- destroy to close files so they don't get opened repeatedly with each iteration
	reportControl!.destroy()
