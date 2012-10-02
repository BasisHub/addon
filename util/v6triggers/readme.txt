AddonSoftware readme.txt: Using Triggers for Hybrid Installations

+Version 6 triggers currently defined for Payroll:

The trigger definition (.trigger) and source (.src) files in the <install>/apps/aon/util/v6triggers/ directories are usable with a standard install of Barista/Addon coupled with Addon Version 6 in a hybrid environment. 

A given trigger definition may specify more than one trigger for a database file, so you will find one or more files in the src directory corresponding to each trigger definition file. 

The .trigger file(s) should be placed in the same directory as the version 6 data files, and the .src file(s) should be placed in a src directory directly underneath the version 6 data directory.  

APM-11 Bank Reconciliation
GLM-03 Journal ID Codes
GLT-04 Daily Transaction Detail
GLT-05 Transaction Detail Sort
IVM-02 Inventory Warehouse/Item Master
SYM-04 System Master
SYM-06 Firm Master
SYS-01 System Control

+Barista/Addon triggers currently defined for Payroll:

In addition, there is one trigger that should be placed in the Barista/Addon database.  The .trigger file should be placed in the same directory as the corresponding Barista/Addon data files, and the related .src files should be placed in a src directory directly underneath the Barista/Addon data directory.

GLM-01 Account Master