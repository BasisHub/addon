[[ART_CASHDET.BGDR]]
rem --- Get invoice data
	artInvHdr_dev=fnget_dev("ART_INVHDR")
	dim artInvHdr$:fnget_tpl$("ART_INVHDR")
	ar_type$=callpoint!.getColumnData("ART_CASHDET.AR_TYPE")
	customer_id$=callpoint!.getColumnData("ART_CASHDET.CUSTOMER_ID")
	ar_inv_no$=callpoint!.getColumnData("ART_CASHDET.AR_INV_NO")
	artInvHdr_key$=firm_id$+ar_type$+customer_id$+ar_inv_no$+"00"
	readrecord(artInvHdr_dev,key=artInvHdr_key$,dom=*next)artInvHdr$

	rem --- Initialize <DISPLAY> fields
	callpoint!.setColumnData("<<DISPLAY>>.DISC_DATE",artInvHdr.disc_date$)
	callpoint!.setColumnData("<<DISPLAY>>.DUE_DATE",artInvHdr.inv_due_date$)
	callpoint!.setColumnData("<<DISPLAY>>.INVOICE_AMT",str(artInvHdr.invoice_amt))
	callpoint!.setColumnData("<<DISPLAY>>.INV_DATE",artInvHdr.invoice_date$)
