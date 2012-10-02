//#charset: windows-1252

VERSION "4.0"

WINDOW 1001 "AddonSoftware v8.x Upgrade" 260 180 500 445
BEGIN
    KEYBOARDNAVIGATION
    NOMENUBARLINE
    NOT SIZABLE
    EVENTMASK 3287287748
    NAME "frmSystemUpgrade"

    STATUSBAR 9999
    BEGIN
        INITIALCONTENTS  " " 
        NAME "Status Bar" 
    END

    STATICTEXT 2002, "Phase:", 5, 30, 50, 16
    BEGIN
        JUSTIFICATION 32768
        NAME "txtPhase" 
    END

    STATICTEXT 4002, " ", 60, 30, 430, 40
    BEGIN
        NAME "txtPhaseDescription" 
    END

    STATICTEXT 2003, "Step:", 5, 75, 50, 16
    BEGIN
        JUSTIFICATION 32768
        NAME "txtStep" 
    END

    STATICTEXT 4003, " ", 60, 75, 330, 40
    BEGIN
        NAME "txtStepDescription" 
    END

    LISTBOX 4004, " ", 5, 114, 490, 277
    BEGIN
        NAME "lstFiles" 
        CLIENTEDGE
    END

    BUTTON 1, "OK", 350, 396, 70, 24
    BEGIN
        NAME "btnOK" 
    END

    BUTTON 2, "Cancel", 425, 396, 70, 24
    BEGIN
        NAME "btnCancel" 
    END

    STATICTEXT 2001, "Updating:", 5, 5, 50, 16
    BEGIN
        JUSTIFICATION 32768
        NAME "txtUpdating" 
    END

    STATICTEXT 4001, " ", 60, 5, 430, 20
    BEGIN
        NAME "txtDataPath" 
    END

    STATICTEXT 2005, " Total Items:", 395, 75, 60, 16
    BEGIN
        JUSTIFICATION 32768
        NAME "txtTotalFiles" 
    END

    STATICTEXT 4005, " ", 460, 75, 35, 20
    BEGIN
        JUSTIFICATION 32768
        NAME "txtCount" 
    END
END

