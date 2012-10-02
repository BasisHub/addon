//#charset: windows-1252

VERSION "4.0"

WINDOW 1001 "User Selection" 350 300 404 164
BEGIN
    EVENTMASK 3824158412
    KEYBOARDNAVIGATION
    NAME "frmUserSelection"
    NOT SIZABLE
	
    BUTTON 1, "OK", 110, 128, 80, 24
    BEGIN
        NAME "btnOK"
    END

    BUTTON 2, "Cancel", 201, 128, 80, 24
    BEGIN
        NAME "btnCancel"
    END

    STATICTEXT 102, " ", 25, 11, 356, 35
    BEGIN
        FONT "Microsoft Sans Serif" 10
        JUSTIFICATION 16384
        NAME "txtHeading"
    END

    CUSTOMEDIT 101, "", 30, 57, 337, 60
    BEGIN
        CLIENTEDGE
        NAME "txtResponse"
    END

END

