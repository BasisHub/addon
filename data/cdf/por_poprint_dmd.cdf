[[POR_POPRINT_DMD.AREC]]
rem --- use ReportControl object to see if this vendor is set up for email/fax of the PO

	use ::ado_rptControl.src::ReportControl

	rpt_id$=pad("POR_POPRINT",16);rem use POR_POPRINT for regular (batch) POs and on-demand, so vendor recipients don't need to be set up multiple times

rem --- See if this document/recipient is set up in Addon Report Control

	reportControl!=new ReportControl()
	found=reportControl!.getRecipientInfo(rpt_id$,"",callpoint!.getColumnData("POR_POPRINT_DMD.VENDOR_ID"))
	
	if found and (reportControl!.getEmailYN()="Y" or reportControl!.getFaxYN()="Y")
		callpoint!.setColumnEnabled("POR_POPRINT_DMD.RPT_CONTROL",1)
	else
		callpoint!.setColumnEnabled("POR_POPRINT_DMD.RPT_CONTROL",0)
	endif
