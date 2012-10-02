//#charset: windows-1252

VERSION "4.0"

WINDOW 101 "Digital Dashboard" 100 100 976 651
BEGIN
    EVENTMASK 3287287500
    ICON ""
    INVISIBLE
    KEYBOARDNAVIGATION
    NOT MAXIMIZABLE
    NOT SIZABLE
    GROUPBOX 100, "Data Set", 5, 85, 155, 555
    BEGIN
        FONT "Arial" 10,bold
        NAME ""
    END

    GROUPBOX 101, "Zoomed View", 170, 85, 795, 555
    BEGIN
        FONT "Arial" 10,bold
        NAME ""
    END

    SLIDER 102, 91, 25, 869, 30
    BEGIN
        NAME ""
        ORIENTATION 1073741824
        MAXIMUM 12
        MINIMUM 1
        VALUE 7
        MAJORTICKSPACING 2
        PAINTTICKS
        SNAPTOTICKS
    END

    STATICTEXT 103, "Jan", 90, 55, 35, 20
    BEGIN
        NAME ""
        NOT OPAQUE
    END

    STATICTEXT 104, "Mar", 245, 55, 35, 20
    BEGIN
        NAME ""
        NOT OPAQUE
    END

    STATICTEXT 105, "May", 400, 55, 35, 20
    BEGIN
        NAME ""
        NOT OPAQUE
    END

    STATICTEXT 106, "July", 555, 55, 35, 20
    BEGIN
        NAME ""
        NOT OPAQUE
    END

    STATICTEXT 107, "Sept", 710, 55, 35, 20
    BEGIN
        NAME ""
        NOT OPAQUE
    END

    STATICTEXT 108, "Nov", 866, 55, 35, 20
    BEGIN
        NAME ""
        NOT OPAQUE
    END

    GROUPBOX 109, "Time Frame", 5, 5, 960, 70
    BEGIN
        FONT "Arial" 10,bold
        NAME ""
    END

    STATICTEXT 110, "Feb", 170, 55, 35, 20
    BEGIN
        NAME ""
        NOT OPAQUE
    END

    STATICTEXT 111, "Apr", 325, 55, 35, 20
    BEGIN
        NAME ""
        NOT OPAQUE
    END

    STATICTEXT 112, "June", 480, 55, 35, 20
    BEGIN
        NAME ""
        NOT OPAQUE
    END

    STATICTEXT 113, "Aug", 635, 55, 35, 20
    BEGIN
        NAME ""
        NOT OPAQUE
    END

    STATICTEXT 114, "Oct", 790, 55, 35, 20
    BEGIN
        NAME ""
        NOT OPAQUE
    END

    STATICTEXT 115, "Dec", 940, 55, 35, 20
    BEGIN
        NAME ""
        NOT OPAQUE
    END

    LISTBUTTON 116, "", 14, 35, 67, 65
    BEGIN
        NAME "year"
        SELECTIONHEIGHT 21
    END

END

