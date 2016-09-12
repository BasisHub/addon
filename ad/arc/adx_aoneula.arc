// WINDOWBUILDER BETA FILE
//#charset: windows-1252

VERSION "4.01"

WINDOW 1000 "License Agreement" 40 40 700 400
BEGIN
    NAME "AddonEULA"
    RADIOGROUP 1201, 1202

    HTMLVIEW 1101,"", 25, 25, 650, 300
    BEGIN
        NAME "htView1101"
    END

    RADIOBUTTON 1201, "I ACCEPT the terms of the license agreement.", 25, 345, 400, 18
    BEGIN
        GROUP
        NAME "rbAccept"
    END

    RADIOBUTTON 1202, "I DO NOT accept the terms of the license agreement.", 25, 370, 400, 18
    BEGIN
        GROUP
        NAME "rbDecline"
        CHECKED
    END

END

