[[ARM_CUSTRPT_CTL.EMAIL_YN.AVAL]]
if callpoint!.getUserInput()="Y"
	arm_emailfax_dev=fnget_dev("ARM_EMAILFAX")
	arm01_dev=fnget_dev("ARM_CUSTMAST")
	dim arm_emailfax$:fnget_tpl$("ARM_EMAILFAX")
	dim arm01a$:fnget_tpl$("ARM_CUSTMAST")
	readrecord (arm_emailfax_dev,key=firm_id$+callpoint!.getColumnData("ARM_CUSTRPT_CTL.CUSTOMER_ID"),dom=*next)arm_emailfax$
	readrecord (arm01_dev,key=firm_id$+callpoint!.getColumnData("ARM_CUSTRPT_CTL.CUSTOMER_ID"),dom=*next)arm01a$	
	if cvs(callpoint!.getColumnData("ARM_CUSTRPT_CTL.EMAIL_TO"),3)=""
		callpoint!.setColumnData("ARM_CUSTRPT_CTL.EMAIL_TO",arm_emailfax.email_to$)	
	endif
	if cvs(callpoint!.getColumnData("ARM_CUSTRPT_CTL.EMAIL_CC"),3)=""
		callpoint!.setColumnData("ARM_CUSTRPT_CTL.EMAIL_CC",arm_emailfax.email_cc$)
	endif
endif
[[ARM_CUSTRPT_CTL.FAX_YN.AVAL]]
if callpoint!.getUserInput()="Y"
	arm_emailfax_dev=fnget_dev("ARM_EMAILFAX")
	arm01_dev=fnget_dev("ARM_CUSTMAST")
	dim arm_emailfax$:fnget_tpl$("ARM_EMAILFAX")
	dim arm01a$:fnget_tpl$("ARM_CUSTMAST")
	readrecord (arm_emailfax_dev,key=firm_id$+callpoint!.getColumnData("ARM_CUSTRPT_CTL.CUSTOMER_ID"),dom=*next)arm_emailfax$
	readrecord (arm01_dev,key=firm_id$+callpoint!.getColumnData("ARM_CUSTRPT_CTL.CUSTOMER_ID"),dom=*next)arm01a$	
	if cvs(callpoint!.getColumnData("ARM_CUSTRPT_CTL.FAX_NOS"),3)=""
		callpoint!.setColumnData("ARM_CUSTRPT_CTL.FAX_NOS",arm_emailfax.fax_nos$)	
	endif
	if cvs(callpoint!.getColumnData("ARM_CUSTRPT_CTL.CUSTOMER_NAME"),3)=""
		callpoint!.setColumnData("ARM_CUSTRPT_CTL.CUSTOMER_NAME",arm01a.customer_name$)
	endif
	if cvs(callpoint!.getColumnData("ARM_CUSTRPT_CTL.FAX_TO"),3)=""
		callpoint!.setColumnData("ARM_CUSTRPT_CTL.FAX_TO",arm_emailfax.fax_to$)
	endif
endif
[[ARM_CUSTRPT_CTL.BSHO]]
rem -- open arm_emailfax  to get defaults
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ARM_EMAILFAX",open_opts$[1]="OTA"
gosub open_tables

