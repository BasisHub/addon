Application Task Spreadsheets

These spreadsheets need to be kept up-to-date by everyone participating in AddonSoftware Version 8 development.  Because they reside in the repository, they are comma-separated text documents, rather than regular .xls files.

When you want to make a change to a spreadsheet, always start with a fresh cvs update from the repository.  You can open the spreadsheet in Excel and apply row coloring, do column sizing, etc., for readability.  Note, though, that all the formatting will be lost when you save it back in cvs format.  It’s best to update, alter and re-commit the spreadsheet in quick succession to avoid conflicts.

After altering and saving the spreadsheet, you’ll need to commit it back to cvs.  Start by doing a cvs refresh just to double-check the status of your version against the repository.  If it shows as locally modified, go ahead and do the commit.  If the status indicates conflicts, or that it requires a merge, update or patch, then someone else has altered the spreadsheet in the meantime.  In this case, the easiest thing to do is use Windows Explorer to remove your copy (or move it elsewhere), do another cvs update, re-enter your changes, and try the refresh/commit again.  This should happen rarely, but will avoid cvs attempting to merge differing copies.



Application Task Spreadsheet Legend

Each Application Spreadsheet contains the following columns.  As a developer you will most often alter the final six columns.

Description: The menu item or program name.
Type:  Used for convenience in coloring/filtering spreadsheet.  M corresponds to version 8 application menu, G is a menu group, and T is an individual task/program.
Version 8 Alias:  The name of the Maintenance or Option Entry form/grid in the version 8 Form Manager.
Version 8 Program:  The program name for backend reports, updates and/or publics.
Version 6 Name:  The corresponding version 6 program name. 
Program Type:  Indicates whether this is an Entry form, Report, Update, etc.  Some reports are listed as Input/Report Overlay pairs.
Form Status:  Place WIP and your initials here when you begin work on a form.  When the form is completed, including initial testing, remove the WIP and leave your initials.  Note the date and any other pertinent information in the Comments column.
CodePort:  Programs requiring a pass through the CodePort utility will show "needs" in this column.  Replace with your initials (and BP for BigPond, if applicable) when the CodePort has been completed.
Print Preview Tested:  Once a report has been CodePorted and tested in standard Print Preview mode, place your initials here.
DocOut:  If the report should be converted to use the DocOut utility, the column will contain "needs."  Once the DocOut conversion is done, replace with your initials (and BP for BigPond, if applicable).
DocOut Tested:  Place your initials here once a DocOut’d version of a report has been tested and is ready for release.
Comments:  Any miscellaneous information that will be helpful to you or other developers using the spreadsheet.
