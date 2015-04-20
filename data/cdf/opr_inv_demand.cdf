[[OPR_INV_DEMAND.AREC]]
rem --- use ReportControl object to see if this customer is set up for email/fax of the invoice

	use ::ado_rptControl.src::ReportControl

	rpt_id$=pad("OPR_INVOICE",16);rem use OPR_INVOICE for regular (batch) invoices and on-demand, so customers don't have to be set up multiple times

rem --- See if this document/recipient is set up in Addon Report Control

	reportControl!=new ReportControl()
	found=reportControl!.getRecipientInfo(rpt_id$,callpoint!.getColumnData("OPR_INV_DEMAND.CUSTOMER_ID"),"")
	
	if found and (reportControl!.getEmailYN()="Y" or reportControl!.getFaxYN()="Y")
		callpoint!.setColumnEnabled("OPR_INV_DEMAND.PICK_CHECK",1)
	else
		callpoint!.setColumnEnabled("OPR_INV_DEMAND.PICK_CHECK",0)
	endif
