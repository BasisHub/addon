[[POE_POHDR.REQ_NO.AVAL]]
rem " --- Load PO Rec"
	poe01_dev=fnget_dev("POE_REQHDR")
	dim poe02a$: fnget_tpl$("POE_POHDR")
	poe02_dev=fnget_dev("POE_POHDR")
	dim poe01a$: fnget_tpl$("POE_REQHDR")
	poe11_dev=fnget_dev("POE_REQDET")
	dim poe11a$: fnget_tpl$("POE_REQDET")
	poe12_dev=fnget_dev("POE_PODET")
	po_no$=callpoint!.getColumnData("POE_POHDR.PO_NO")
	req_no$=pad(callpoint!.getUserInput(),7,"R","0")
	
	read record (poe01_dev,key=firm_id$+req_no$,dom=*break) poe01a$
	call stbl("+DIR_PGM")+"adc_copyfile.aon",poe01a$,poe02a$,status	
	poe02a.po_no$=po_no$
	write record (poe02_dev) poe02a$
	po_no$=callpoint!.getColumnData("POE_POHDR.PO_NO")
	read record(poe11_dev,key=firm_id$+req_no$,dom=*next)
	while 1
		read record(poe11_dev) poe11a$
		if poe11a.req_no$<>req_no$ or poe11a.firm_id$<>firm_id$ then break
		dim poe12a$:fnget_tpl$("POE_PODET")
		call stbl("+DIR_PGM")+"adc_copyfile.aon",poe11a$,poe12a$,status
		poe12a.po_no$=po_no$
		write record (poe12_dev) poe12a$
	wend
	callpoint!.setStatus("RECORD:"+firm_id$+po_no$)
	
[[POE_POHDR.ARNF]]
rem -- set default values
rem --- IV Params
	ivs_params_chn=fnget_dev("IVS_PARAMS")
	dim ivs_params$:fnget_tpl$("IVS_PARAMS")
	read record(ivs_params_chn,key=firm_id$+"IV00")ivs_params$
rem --- PO Params
	pos_params_chn=fnget_dev("POS_PARAMS")
	dim pos_params$:fnget_tpl$("POS_PARAMS")
	read record(pos_params_chn,key=firm_id$+"PO00")pos_params$
rem --- Set Defaults
	apm02_dev=fnget_dev("APM_VENDHIST")
	dim apm02a$:fnget_tpl$("APM_VENDHIST")
	read record(apm02_dev,key=firm_id$+vendor_id$,dom=*next)
	tmp$=key(apm02_dev,end=done_apm_vendhist)
		if pos(firm_id$+vendir_id$=tmp$)<>1 then goto done_apm_vendhist
		read record(apm02_dev,key=tmp$)apm02a$
	done_apm_vendhist:
	callpoint!.setColumnData("<<DISPLAY>>.ORDER_TOTAL","")
	callpoint!.setColumnData("POE_POHDR.WAREHOUSE_ID",ivs_params.warehouse_id$)
	gosub whse_addr_info
	callpoint!.setColumnData("POE_POHDR.ORD_DATE",sysinfo.system_date$)
	callpoint!.setColumnData("POE_POHDR.TERMS_CODE",apm02a.ap_terms_code$)
	callpoint!.setColumnData("POE_POHDR.REQD_DATE",sysinfo.system_date$)
	callpoint!.setColumnData("POE_POHDR.PO_FRT_TERMS",pos_params.po_frt_terms$)
	callpoint!.setColumnData("POE_POHDR.AP_SHIP_VIA",pos_params.ap_ship_via$)
	callpoint!.setColumnData("POE_POHDR.FOB",pos_params.fob$)
	callpoint!.setColumnData("POE_POHDR.HOLD_FLAG",pos_params.hold_flag$)
	callpoint!.setColumnData("POE_POHDR.PO_MSG_CODE",pos_params.po_req_msg_code$)
[[POE_POHDR.WAREHOUSE_ID.AVAL]]
gosub whse_addr_info
[[POE_POHDR.REQD_DATE.AVAL]]
tmp$=callpoint!.getUserInput()
if tmp$<callpoint!.getColumnData("POE_POHDR.ORD_DATE") then callpoint!.setStatus("ABORT")
[[POE_POHDR.NOT_B4_DATE.AVAL]]
not_b4_date$=cvs(callpoint!.getUserInput(),2)
if not_b4_date$<>"" then
	if not_b4_date$<callpoint!.getColumnData("POE_POHDR.ORD_DATE") then callpoint!.setStatus("ABORT")
	if not_b4_date$>callpoint!.getColumnData("POE_POHDR.REQD_DATE") then callpoint!.setStatus("ABORT")
	promise_date$=cvs(callpoint!.getColumnData("POE_POHDR.PROMISE_DATE"),2)
	if promise_date$<>"" and not_b4_date$>promise_date$ then callpoint!.setStatus("ABORT")
endif
[[POE_POHDR.PROMISE_DATE.AVAL]]
tmp$=cvs(callpoint!.getUserInput(),2)
if tmp$<>"" and tmp$<callpoint!.getColumnData("POE_POHDR.ORD_DATE") then callpoint!.setStatus("ABORT")
[[POE_POHDR.BSHO]]
rem --- Open Files
	num_files=8
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="IVS_PARAMS",open_opts$[2]="OTA"
	open_tables$[3]="POS_PARAMS",open_opts$[3]="OTA"
	open_tables$[4]="APM_VENDHIST",open_opts$[4]="OTA"
	open_tables$[5]="IVM_ITEMWHSE",open_opts$[5]="OTA"
	open_tables$[6]="IVM_ITEMVEND",open_opts$[6]="OTA"
	open_tables$[7]="POE_REQHDR",open_opts$[7]="OTA"
	open_tables$[8]="POE_REQDET",open_opts$[8]="OTA"
	gosub open_tables
	aps_params_dev=num(open_chans$[1]),aps_params_tpl$=open_tpls$[1]
	ivs_params_dev=num(open_chans$[2]),ivs_params_tpl$=open_tpls$[2]
	pos_params_dev=num(open_chans$[3]),pos_params_tpl$=open_tpls$[3]
	apm_vendhist_dev=num(open_chans$[4]),apm_vendhist_tpl$=open_tpls$[4]
	ivm_itemwhse_dev=num(open_chans$[5]),ivm_itemwhse_tpl$=open_tpls$[5]
	ivm_itemvend_dev=num(open_chans$[6]),ivm_itemvend_tpl$=open_tpls$[6]
	poe_reqhdr_dev=num(open_chans$[7]),poe_reqhdr_tpl$=open_tpls$[7]
	poe_reqdet_dev=num(open_chans$[8]),poe_reqdet_tpl$=open_tpls$[8]
rem --- disable display fields
	dim dctl$[9]
	dmap$="I"
	dctl$[1]="<<DISPLAY>>.V_ADDR1"
	dctl$[2]="<<DISPLAY>>.V_ADDR2"
	dctl$[3]="<<DISPLAY>>.V_CITY"
	dctl$[4]="<<DISPLAY>>.V_STATE"
	dctl$[5]="<<DISPLAY>>.V_ZIP"
	dctl$[6]="<<DISPLAY>>.V_CONTACT"
	dctl$[7]="<<DISPLAY>>.V_PHONE"
	dctl$[8]="<<DISPLAY>>.V_FAX"
	gosub disable_ctls
	dmap$="I"
	dctl$[1]="<<DISPLAY>>.PA_ADDR1"
	dctl$[2]="<<DISPLAY>>.PA_ADDR2"
	dctl$[3]="<<DISPLAY>>.PA_CITY"
	dctl$[4]="<<DISPLAY>>.PA_STATE"
	dctl$[5]="<<DISPLAY>>.PA_ZIP"
	gosub disable_ctls
rem --- AP Params
	dim aps_params$:aps_params_tpl$
	read record(aps_params_dev,key=firm_id$+"AP00")aps_params$
rem --- set up UserObj! as vector
	UserObj!=SysGUI!.makeVector()
	ctlContext=num(callpoint!.getTableColumnAttribute("<<DISPLAY>>.ORDER_TOTAL","CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute("<<DISPLAY>>.ORDER_TOTAL","CTLI"))
	tamt!=SysGUI!.getWindow(ctlContext).getControl(ctlID)
	UserObj!.addItem(tamt!)
rem --- Setup user_tpl$
	user_tpl$="change_flag:n(1)"
	dim user_tpl$:user_tpl$
[[POE_POHDR.PURCH_ADDR.AVAL]]
vendor_id$=callpoint!.getColumnData("POE_POHDR.VENDOR_ID")
purch_addr$=callpoint!.getUserInput()
gosub purch_addr_info
[[POE_POHDR.ARAR]]
vendor_id$=callpoint!.getColumnData("POE_POHDR.VENDOR_ID")
purch_addr$=callpoint!.getColumnData("POE_POHDR.PURCH_ADDR")
gosub vendor_info
gosub purch_addr_info
gosub whse_addr_info
[[POE_POHDR.<CUSTOM>]]
vendor_info: rem --- get and siplay Vendor Information
	apm01_dev=fnget_dev("APM_VENDMAST")
	dim apm01a$:fnget_tpl$("APM_VENDMAST")
	read record(apm01_dev,key=firm_id$+vendor_id$,dom=*next)apm01a$
	callpoint!.setColumnData("<<DISPLAY>>.V_ADDR1",apm01a.addr_line_1$)
	callpoint!.setColumnData("<<DISPLAY>>.V_ADDR2",apm01a.addr_line_2$)
	callpoint!.setColumnData("<<DISPLAY>>.V_CITY",apm01a.city$)
	callpoint!.setColumnData("<<DISPLAY>>.V_STATE",apm01a.state_code$)
	callpoint!.setColumnData("<<DISPLAY>>.V_ZIP",apm01a.zip_code$)
	callpoint!.setColumnData("<<DISPLAY>>.V_CONTACT",apm01a.contact_name$)
	callpoint!.setColumnData("<<DISPLAY>>.V_PHONE",apm01a.phone_no$)
	callpoint!.setColumnData("<<DISPLAY>>.V_FAX",apm01a.fax_no$)
	callpoint!.setStatus("REFRESH")
return
purch_addr_info: rem --- get and display Purchase Address Info
	apm05_dev=fnget_dev("APM_VENDADDR")
	dim apm05a$:fnget_tpl$("APM_VENDADDR")
	read record(apm05_dev,key=firm_id$+vendor_id$+purch_addr$,dom=*next)apm05a$
	callpoint!.setColumnData("<<DISPLAY>>.PA_ADDR1",apm05a.addr_line_1$)
	callpoint!.setColumnData("<<DISPLAY>>.PA_ADDR2",apm05a.addr_line_2$)
	callpoint!.setColumnData("<<DISPLAY>>.PA_CITY",apm05a.city$)
	callpoint!.setColumnData("<<DISPLAY>>.PA_STATE",apm05a.state_code$)
	callpoint!.setColumnData("<<DISPLAY>>.PA_ZIP",apm05a.zip_code$)
	callpoint!.setStatus("REFRESH")
return
whse_addr_info: rem --- get and display Warehouse Address Info
	ivc_whsecode_dev=fnget_dev("IVC_WHSECODE")
	dim ivc_whsecode$:fnget_tpl$("IVC_WHSECODE")
	warehouse_id$=callpoint!.getColumnData("POE_POHDR.WAREHOUSE_ID")
	read record(ivc_whsecode_dev,key=firm_id$+"C"+warehouse_id$,dom=*next)ivc_whsecode$
	callpoint!.setColumnData("<<DISPLAY>>.W_ADDR1",ivc_whsecode$.addr_line_1$)
	callpoint!.setColumnData("<<DISPLAY>>.W_ADDR2",ivc_whsecode$.addr_line_2$)
	callpoint!.setColumnData("<<DISPLAY>>.W_CITY",ivc_whsecode$.city$)
	callpoint!.setColumnData("<<DISPLAY>>.W_STATE",ivc_whsecode$.state_code$)
	callpoint!.setColumnData("<<DISPLAY>>.W_ZIP",ivc_whsecode$.zip_code$)
	callpoint!.setStatus("REFRESH")
return
disable_ctls:
for dctl=1 to 9
	dctl$=dctl$[dctl]
	if cvs(dctl$,2)<>""
		wctl$=str(num(callpoint!.getTableColumnAttribute(dctl$,"CTLI")):"00000")
		wmap$=callpoint!.getAbleMap()
		wpos=pos(wctl$=wmap$,8)
		wmap$(wpos+6,1)=dmap$
		callpoint!.setAbleMap(wmap$)
		callpoint!.setStatus("ABLEMAP-REFRESH")
	endif
next dctl
return
[[POE_POHDR.PO_NO.AVAL]]
rem -- see if existing po# was entered
if cvs(callpoint!.getColumnData("POE_POHDR.VENDOR_ID"),2) = "" then
	
     ddm_keys=fnget_dev("DDM_KEYS")
     dim ddm_keys$:fnget_tpl$("DDM_KEYS")
     call stbl("+DIR_SYP")+"bac_key_template.bbj","DDM_KEYS","NAME",key_tpl$,table_chans$[all],status$
     dim ddm_key_tpl$:key_tpl$
     ddm_key_tpl.dd_table_alias$="POE_POHDR",ddm_key_tpl.dd_key_id$="ALT_KEY_01"
     readrecord(ddm_keys,key=ddm_key_tpl$,knum=1)ddm_keys$
     keynum=num(ddm_keys.dd_key_number$)
     poe02_dev=fnget_dev("POE_POHDR")
     dim poe02a$:fnget_tpl$("POE_POHDR")
     po_no$=callpoint!.getUserInput()
     read record(poe02_dev,key=firm_id$+po_no$,knum=keynum,dom=*next)
     while 1
          read record(poe01_dev,err=*next)poe02a$
          if poe02a.firm_id$<>firm_id$ or poe02a.po_no$<>po_no$ then
               rem  vendor!=fnget_control!("POE_POHDR.VENDOR_ID")
               rem  vendor!.focus() 
          else
               callpoint!.setColumnData("POE_POHDR.VENDOR_ID",poe02a.vendor_id$)
          endif
          break
     wend              
endif

