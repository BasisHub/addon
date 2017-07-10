Be sure that you go into the
Barista Development -> Maintenance ->
  Inquires -> Query Definitions

Pull up AP_INV_VEND

On the DB Column where the Column ID is VENDOR_ID

Click on the Expand Grid Record  -- Cloverleaf?
  In the Inquiry Program.
    Remove the entry "api_invend.aon"
     This new routine does its work in the Query instead
     of calling this other routine for each line.

If doing this after a GIT Patch, instead Delete the Query AP_INV_VEND
before doing the Barista Sync Process.


