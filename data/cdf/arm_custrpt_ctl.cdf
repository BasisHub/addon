[[ARM_CUSTRPT_CTL.EMAIL_YN.AVAL]]
if callpoint!.getUserInput()="Y"
	arm_emailfax_dev=fnget_dev("ARM_EMAILFAX")
	user_dev=fnget_dev("ADM_USER")
	dim arm_emailfax$:fnget_tpl$("ARM_EMAILFAX")
	dim user$:fnget_tpl$("ADM_USER")
	dim custrpt$:fnget_tpl$("ARM_CUSTRPT_CTL")
	readrecord (arm_emailfax_dev,key=firm_id$+callpoint!.getColumnData("ARM_CUSTRPT_CTL.CUSTOMER_ID"),dom=*next)arm_emailfax$
	readrecord (user_dev,key=sysinfo.user_id$,dom=*next)user$	
	if cvs(callpoint!.getColumnData("ARM_CUSTRPT_CTL.EMAIL_TO"),3)=""
		callpoint!.setColumnData("ARM_CUSTRPT_CTL.EMAIL_TO",arm_emailfax.email_to$,1)	
	endif
	if cvs(callpoint!.getColumnData("ARM_CUSTRPT_CTL.EMAIL_CC"),3)=""
		callpoint!.setColumnData("ARM_CUSTRPT_CTL.EMAIL_CC",arm_emailfax.email_cc$,1)
	endif
	if cvs(callpoint!.getColumnData("ARM_CUSTRPT_CTL.EMAIL_FROM"),3)=""
		callpoint!.setColumnData("ARM_CUSTRPT_CTL.EMAIL_FROM",pad(user.email_address$,len(custrpt.email_from$)),1)
	endif
	if cvs(callpoint!.getColumnData("ARM_CUSTRPT_CTL.EMAIL_REPLYTO"),3)=""
		callpoint!.setColumnData("ARM_CUSTRPT_CTL.EMAIL_REPLYTO",pad(user.email_address$,len(custrpt.email_from$)),1)
	endif
endif
[[ARM_CUSTRPT_CTL.FAX_YN.AVAL]]
if callpoint!.getUserInput()="Y"
	arm_emailfax_dev=fnget_dev("ARM_EMAILFAX")
	arm01_dev=fnget_dev("ARM_CUSTMAST")
	compinfo_dev=fnget_dev("ADS_COMPINFO")
	user_dev=fnget_dev("ADM_USER")
	dim arm_emailfax$:fnget_tpl$("ARM_EMAILFAX")
	dim arm01a$:fnget_tpl$("ARM_CUSTMAST")
	dim compinfo$:fnget_tpl$("ADS_COMPINFO")
	dim user$:fnget_tpl$("ADM_USER")
	dim custrpt$:fnget_tpl$("ARM_CUSTRPT_CTL")
	readrecord (arm_emailfax_dev,key=firm_id$+callpoint!.getColumnData("ARM_CUSTRPT_CTL.CUSTOMER_ID"),dom=*next)arm_emailfax$
	readrecord (arm01_dev,key=firm_id$+callpoint!.getColumnData("ARM_CUSTRPT_CTL.CUSTOMER_ID"),dom=*next)arm01a$	
	readrecord (compinfo_dev,key=firm_id$,dom=*next)compinfo$	
	readrecord (user_dev,key=sysinfo.user_id$,dom=*next)user$	
	if cvs(callpoint!.getColumnData("ARM_CUSTRPT_CTL.FAX_NOS"),3)=""
		callpoint!.setColumnData("ARM_CUSTRPT_CTL.FAX_NOS",arm_emailfax.fax_nos$,1)	
	endif
	if cvs(callpoint!.getColumnData("ARM_CUSTRPT_CTL.CUSTOMER_NAME"),3)=""
		callpoint!.setColumnData("ARM_CUSTRPT_CTL.CUSTOMER_NAME",arm01a.customer_name$,1)
	endif
	if cvs(callpoint!.getColumnData("ARM_CUSTRPT_CTL.FAX_TO"),3)=""
		callpoint!.setColumnData("ARM_CUSTRPT_CTL.FAX_TO",arm_emailfax.fax_to$,1)
	endif
	if cvs(callpoint!.getColumnData("ARM_CUSTRPT_CTL.FROM_COMPANY"),3)=""
		callpoint!.setColumnData("ARM_CUSTRPT_CTL.FROM_COMPANY",pad(compinfo.firm_name$,len(custrpt.from_company$)),1)
	endif
	if cvs(callpoint!.getColumnData("ARM_CUSTRPT_CTL.FROM_NAME"),3)=""
		callpoint!.setColumnData("ARM_CUSTRPT_CTL.FROM_NAME",user.name$,1)
	endif
endif
[[ARM_CUSTRPT_CTL.BSHO]]
rem -- open arm_emailfax  to get defaults
num_files=4
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ARM_EMAILFAX",open_opts$[1]="OTA"
open_tables$[2]="ARM_CUSTMAST",open_opts$[2]="OTA"
open_tables$[3]="ADS_COMPINFO",open_opts$[3]="OTA"
open_tables$[4]="ADM_USER",open_opts$[4]="OTA"
gosub open_tables
