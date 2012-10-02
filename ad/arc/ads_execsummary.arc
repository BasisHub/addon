//#charset: windows-1252

VERSION "4.0"

WINDOW 1000 "Executive Summary As Of " 100 100 597 428
BEGIN
    DIALOGBEHAVIOR
    INVISIBLE
    KEYBOARDNAVIGATION
    MANAGESYSCOLOR
    EVENTMASK 1073742856
    NAME "grp_status"

    TOOLBUTTON 2000, "", 5, 5, 20, 20
    BEGIN
        IMAGEFILE "sys/images/im_nb_fst_i.png" 
        NAME "btn_prev_yr"
        SHORTCUE "Previous year"
    END

    TOOLBUTTON 2001, "", 24, 5, 20, 20
    BEGIN
        IMAGEFILE "sys/images/im_nb_prv_i.png" 
        NAME "btn_prev_mo"
        SHORTCUE "Previous month"
    END

    TOOLBUTTON 2002, "", 126, 5, 20, 20
    BEGIN
        IMAGEFILE "sys/images/im_nb_nxt_i.png" 
        NAME "btn_next_mo"
        SHORTCUE "Next month"
    END

    TOOLBUTTON 2003, "", 145, 5, 20, 20
    BEGIN
        IMAGEFILE "sys/images/im_nb_lst_i.png" 
        NAME "btn_next_yr"
        SHORTCUE "Next year"
    END

    TOOLBUTTON 2004, "", 164, 5, 20, 20
    BEGIN
        IMAGEFILE "sys/images/im_tb_cal_f.png" 
        NAME "btn_curr_mo"
        SHORTCUE "Current month"
    END

    TREE 3000, 5, 28, 180, 64
    BEGIN
        FONT "Tahoma" 8, Normal
        NAME "tre_options"
        CLIENTEDGE
    END

    EDIT 2100, "", 44, 6, 82, 18
    BEGIN
        READONLY
        JUSTIFICATION 16384
        FONT "Tahoma" 8, Bold
        NAME "Edit Control"
        CLIENTEDGE
    END

    TABCONTROL 4000, "tab_type", 190, 4, 398, 407
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

CHILD-WINDOW 10010 0 0 500 400
BEGIN
    KEYBOARDNAVIGATION
    BORDERLESS
    EVENTMASK 3287287492
    BACKGROUNDCOLOR RGB(252,252,254)
    NAME "cwn_calendar"

    GRID 5000, "ROW=-1COL=0", 5, 5, 391, 248
    BEGIN
        ROWS 0
        MAXCOLS 65535
        COLUMNHEAD 20, 5001
        COLUMNS 255
        HORIZLINES
        VERTLINES
        NAME "grd_calendar"
        CLIENTEDGE
        NOT TABTRAVERSABLE
    END
END

CHILD-WINDOW 10020 0 0 500 400
BEGIN
    KEYBOARDNAVIGATION
    BORDERLESS
    EVENTMASK 3287287492
    BACKGROUNDCOLOR RGB(252,252,254)
    NAME "cwn_chart_bar"
END

