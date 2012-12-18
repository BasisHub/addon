//#charset: windows-1252

VERSION "4.0"

WINDOW 1000 "Executive Summary As Of " 100 100 597 428
BEGIN
    DIALOGBEHAVIOR
    EVENTMASK 1073742856
    INVISIBLE
    KEYBOARDNAVIGATION
    MANAGESYSCOLOR
    NAME "grp_status"
    TOOLBUTTON 2000, "", 5, 5, 20, 20
    BEGIN
        JUSTIFICATION 32768
        NAME "btn_prev_yr"
        SHORTCUE "Previous year"
    END

    TOOLBUTTON 2001, "", 24, 5, 20, 20
    BEGIN
        NAME "btn_prev_mo"
        SHORTCUE "Previous month"
    END

    TOOLBUTTON 2002, "", 126, 5, 20, 20
    BEGIN
        NAME "btn_next_mo"
        SHORTCUE "Next month"
    END

    TOOLBUTTON 2003, "", 145, 5, 20, 20
    BEGIN
        NAME "btn_next_yr"
        SHORTCUE "Next year"
    END

    TOOLBUTTON 2004, "", 164, 5, 20, 20
    BEGIN
        NAME "btn_curr_mo"
        SHORTCUE "Current month"
    END

    TREE 3000, 5, 28, 180, 64
    BEGIN
        CLIENTEDGE
        FONT "Tahoma" 8
        NAME "tre_options"
    END

    EDIT 2100, "", 44, 6, 82, 18
    BEGIN
        CLIENTEDGE
        FONT "Tahoma" 8,bold
        JUSTIFICATION 16384
        NAME "Edit Control"
        READONLY
    END

    TABCONTROL 4000, "", 190, 4, 398, 407
    BEGIN
        AUTOMANAGEMENT
        NAME "tab_type"
        TAB "Calendar" 0 10010
        TAB "Chart" 0 10020
    END

    CHILD-WINDOW 10010, 10010, 0, 0
    BEGIN
        NAME "cwn_calendar"
    END

    CHILD-WINDOW 10020, 10020, 0, 0
    BEGIN
        NAME "cwn_chart_bar"
    END

END

CHILD-WINDOW 10010 0 0 494 394
BEGIN
    BACKGROUNDCOLOR RGB(252,252,254)
    BORDERLESS
    EVENTMASK 3287287492
    KEYBOARDNAVIGATION
    NAME "cwn_calendar"
    GRID 5000, "", 5, 5, 391, 248
    BEGIN
        CLIENTEDGE
        COLUMNHEAD 20, 5001
        COLUMNS 255
        HORIZLINES
        MAXCOLS 2147483647
        NAME "grd_calendar"
        ROWS 0
        NOT TABTRAVERSABLE
        USERSIZE
        VERTLINES
    END

END

CHILD-WINDOW 10020 0 0 494 394
BEGIN
    BACKGROUNDCOLOR RGB(252,252,254)
    BORDERLESS
    EVENTMASK 3287287492
    KEYBOARDNAVIGATION
    NAME "cwn_chart_bar"
END

