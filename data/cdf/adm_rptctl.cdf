[[ADM_RPTCTL.BDEQ]]
rem --- don't allow delete if there are recipient records in arm_rptctl_rcp

	adm_rptctl_rcp=fnget_dev("@ADM_RPTCTL_RCP")
	dim adm_rptctl_rcp$:fnget_tpl$("@ADM_RPTCTL_RCP")

	rpt_id$=callpoint!.getColumnData("ADM_RPTCTL.DD_TABLE_ALIAS")

	if adm_rptctl_rcp<>0

		read (adm_rptctl_rcp,key=firm_id$+rpt_id$,dom=*next)
		while 1
			readrecord (adm_rptctl_rcp,end=*break)adm_rptctl_rcp$
			if adm_rptctl_rcp.dd_table_alias$=rpt_id$
				msg_id$="AD_RPTCTL_NODEL"
				gosub disp_message
				callpoint!.setStatus("ABORT")
			endif
			break
		wend

	endif
[[ADM_RPTCTL.BWRI]]
rem --- check for default email account; warn if none supplied

	if cvs(callpoint!.getColumnData("ADM_RPTCTL.EMAIL_ACCOUNT"),3)=""
		msg_id$="AD_RPTCTL_NOEMAIL"
		msg_opt$=""
		gosub disp_message
		if msg_opt$="C" then callpoint!.setStatus("ABORT")
	endif
[[ADM_RPTCTL.BSHO]]
rem --- open Company Info table to get default email account

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ADS_COMPINFO",open_opts$[1]="OTA@"
	open_tables$[2]="ADM_RPTCTL_RCP",open_opts$[2]="OTA@"

	gosub open_tables

	ads_compinfo=num(open_chans$[1])
	dim ads_compinfo$:open_tpls$[1]

	readrecord(ads_compinfo,key=firm_id$,dom=*next)ads_compinfo$

	callpoint!.setTableColumnAttribute("ADM_RPTCTL.EMAIL_ACCOUNT","DFLT",ads_compinfo.email_account$)
