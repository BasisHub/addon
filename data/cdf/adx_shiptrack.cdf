[[ADX_SHIPTRACK.ASVA]]
rem --- Create view for company_id
	company_id$=callpoint!.getColumnData("ADX_SHIPTRACK.COMPANY_ID")
	viewName$="OPV_SHIPTRACK_"+company_id$
	dbName$=stbl("+DBNAME_API")

	call stbl("+DIR_SYP")+"bac_em_login.bbj",SysGUI!,Form!,admin!,rd_status$
	db!=admin!.getDatabase(dbName$)
	db!.dropView(viewName$)
	view!=db!.createView(viewName$)
	view!.setString(BBjAdminView.DESCRIPTION,"Firm "+company_id$+" View for 3rd party shipping software data pull")
	view!.setString(BBjAdminView.SELECT,"
:		SELECT
:			hdr.firm_id, 
:			hdr.ar_type, 
:			hdr.customer_id, 
:			hdr.order_no, 
:			hdr.ship_seq_no, 
:			hdr.order_no AS search_field,   
:			CASE hdr.shipto_type
:				WHEN 'S' THEN ship.name
:				WHEN 'B' THEN cust.customer_name  
:				WHEN 'M' THEN manual.name  
:			END AS name,
:			CASE hdr.shipto_type
:				WHEN 'S' THEN ship.addr_line_1
:				WHEN 'B' THEN cust.addr_line_1
:				WHEN 'M' THEN manual.addr_line_1
:			END AS addr_line_1,
:			CASE hdr.shipto_type
:				WHEN 'S' THEN ship.addr_line_2
:				WHEN 'B' THEN cust.addr_line_2 
:				WHEN 'M' THEN manual.addr_line_2 
:			END AS addr_line_2, 
:			CASE hdr.shipto_type
:				WHEN 'S' THEN ship.addr_line_3 
:				WHEN 'B' THEN cust.addr_line_3 
:				WHEN 'M' THEN manual.addr_line_3 
:			END AS addr_line_3, 
:			CASE hdr.shipto_type
:				WHEN 'S' THEN ship.addr_line_4 
:				WHEN 'B' THEN cust.addr_line_4 
:				WHEN 'M' THEN manual.addr_line_4 
:			END AS addr_line_4, 
:			CASE hdr.shipto_type
:				WHEN 'S' THEN ship.city 
:				WHEN 'B' THEN cust.city 
:				WHEN 'M' THEN manual.city 
:			END AS city, 
:			CASE hdr.shipto_type
:				WHEN 'S' THEN ship.state_code 
:				WHEN 'B' THEN cust.state_code 
:				WHEN 'M' then manual.state_code  
:			END as STATE_CODE, 
:			CASE hdr.shipto_type
:				WHEN 'S' THEN ship.zip_code 
:				WHEN 'B' THEN cust.zip_code 
:				WHEN 'M' THEN manual.zip_code 
:			END AS zip_code, 
:			CASE hdr.shipto_type
:				WHEN 'S' THEN ship.contact_name 
:				WHEN 'B' THEN cust.contact_name 
:				WHEN 'M' THEN cust.contact_name 
:			END AS contact_name,
:			hdr.shipping_email AS email_to, 
:			CASE hdr.shipto_type
:				WHEN 'S' THEN ship.country 
:				WHEN 'B' THEN cust.country 
:				WHEN 'M' THEN cust.country 
:			END AS country, 
:			CASE hdr.shipto_type
:				WHEN 'S' THEN ship.cntry_id 
:				WHEN 'B' THEN cust.cntry_id 
:				WHEN 'M' THEN cust.cntry_id 
:			END AS cntry_id, 
:			hdr.ar_ship_via,
:			hdr.shipping_id,
:			via.scac_code,
:			via.carrier_code,
:			hdr.shipto_type,
:			hdr.customer_po_no
:		FROM ope_invhdr hdr
:		LEFT OUTER JOIN arm_custmast cust ON cust.firm_id=hdr.firm_id AND cust.customer_id=hdr.customer_id 
:		LEFT OUTER JOIN arm_custship ship ON ship.firm_id=hdr.firm_id AND ship.customer_id=hdr.customer_id AND ship.shipto_no=hdr.shipto_no 
:		LEFT OUTER JOIN ope_ordship manual ON manual.firm_id=hdr.firm_id AND manual.customer_id=hdr.customer_id AND manual.order_no=hdr.order_no 
:		LEFT OUTER JOIN arc_shipviacode via ON hdr.firm_id=via.firm_id AND hdr.ar_ship_via=via.ar_ship_via
:		WHERE hdr.trans_status='E' and hdr.firm_id='"+company_id$+"'
:		ORDER BY hdr.firm_id, hdr.customer_id, hdr.order_no
:		")
	view!.commit()

rem --- Created view in database
	msg_id$="AD_VIEW_CREATED"
	dim msg_tokens$[2]
	msg_tokens$[1]=viewName$
	msg_tokens$[2]=dbName$
	gosub disp_message
[[ADX_SHIPTRACK.AREC]]
rem --- Initialize company_id to current firm_id
	callpoint!.setColumnData("ADX_SHIPTRACK.COMPANY_ID",firm_id$,1)
