[[APM_VENDRPT_CTL.FAX_YN.AVAL]]
if callpoint!.getUserInput()="Y"
	APM_EMAILFAX_dev=fnget_dev("APM_EMAILFAX")
	APM01_dev=fnget_dev("APM_VENDMAST")
	compinfo_dev=fnget_dev("ADS_COMPINFO")
	user_dev=fnget_dev("ADM_USER")
	dim APM_EMAILFAX$:fnget_tpl$("APM_EMAILFAX")
	dim APM01a$:fnget_tpl$("APM_VENDMAST")
	dim compinfo$:fnget_tpl$("ADS_COMPINFO")
	dim user$:fnget_tpl$("ADM_USER")
	dim vendrpt$:fnget_tpl$("APM_VENDRPT_CTL")
	readrecord (APM_EMAILFAX_dev,key=firm_id$+callpoint!.getColumnData("APM_VENDRPT_CTL.VENDOR_ID"),dom=*next)APM_EMAILFAX$
	readrecord (APM01_dev,key=firm_id$+callpoint!.getColumnData("APM_VENDRPT_CTL.VENDOR_ID"),dom=*next)APM01a$	
	readrecord (compinfo_dev,key=firm_id$,dom=*next)compinfo$	
	readrecord (user_dev,key=sysinfo.user_id$,dom=*next)user$	
	if cvs(callpoint!.getColumnData("APM_VENDRPT_CTL.FAX_NOS"),3)=""
		callpoint!.setColumnData("APM_VENDRPT_CTL.FAX_NOS",APM_EMAILFAX.fax_nos$,1)	
	endif
	if cvs(callpoint!.getColumnData("APM_VENDRPT_CTL.VENDOR_NAME"),3)=""
		callpoint!.setColumnData("APM_VENDRPT_CTL.VENDOR_NAME",APM01a.vendor_name$,1)
	endif
	if cvs(callpoint!.getColumnData("APM_VENDRPT_CTL.FAX_TO"),3)=""
		callpoint!.setColumnData("APM_VENDRPT_CTL.FAX_TO",APM_EMAILFAX.fax_to$,1)
	endif
	if cvs(callpoint!.getColumnData("APM_VENDRPT_CTL.FROM_COMPANY"),3)=""
		callpoint!.setColumnData("APM_VENDRPT_CTL.FROM_COMPANY",pad(compinfo.firm_name$,len(vendrpt.from_company$)),1)
	endif
	if cvs(callpoint!.getColumnData("APM_VENDRPT_CTL.FROM_NAME"),3)=""
		callpoint!.setColumnData("APM_VENDRPT_CTL.FROM_NAME",user.name$,1)
	endif
endif

[[APM_VENDRPT_CTL.EMAIL_YN.AVAL]]
if callpoint!.getUserInput()="Y"
	APM_EMAILFAX_dev=fnget_dev("APM_EMAILFAX")
	user_dev=fnget_dev("ADM_USER")
	dim APM_EMAILFAX$:fnget_tpl$("APM_EMAILFAX")
	dim user$:fnget_tpl$("ADM_USER")
	dim vendrpt$:fnget_tpl$("APM_VENDRPT_CTL")
	readrecord (APM_EMAILFAX_dev,key=firm_id$+callpoint!.getColumnData("APM_VENDRPT_CTL.VENDOR_ID"),dom=*next)APM_EMAILFAX$
	readrecord (user_dev,key=sysinfo.user_id$,dom=*next)user$	
	if cvs(callpoint!.getColumnData("APM_VENDRPT_CTL.EMAIL_TO"),3)=""
		callpoint!.setColumnData("APM_VENDRPT_CTL.EMAIL_TO",APM_EMAILFAX.email_to$,1)	
	endif
	if cvs(callpoint!.getColumnData("APM_VENDRPT_CTL.EMAIL_CC"),3)=""
		callpoint!.setColumnData("APM_VENDRPT_CTL.EMAIL_CC",APM_EMAILFAX.email_cc$,1)
	endif
	if cvs(callpoint!.getColumnData("APM_VENDRPT_CTL.EMAIL_FROM"),3)=""
		callpoint!.setColumnData("APM_VENDRPT_CTL.EMAIL_FROM",pad(user.email_address$,len(vendrpt.email_from$)),1)
	endif
	if cvs(callpoint!.getColumnData("APM_VENDRPT_CTL.EMAIL_REPLYTO"),3)=""
		callpoint!.setColumnData("APM_VENDRPT_CTL.EMAIL_REPLYTO",pad(user.email_address$,len(vendrpt.email_from$)),1)
	endif
endif
[[APM_VENDRPT_CTL.BSHO]]
rem -- open apm_emailfax to get defaults
num_files=4
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="APM_EMAILFAX",open_opts$[1]="OTA"
open_tables$[2]="APM_VENDMAST",open_opts$[2]="OTA"
open_tables$[3]="ADS_COMPINFO",open_opts$[3]="OTA"
open_tables$[4]="ADM_USER",open_opts$[4]="OTA"
gosub open_tables
