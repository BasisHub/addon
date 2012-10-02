//#charset: windows-1252

VERSION "4.0"

WINDOW 1000 "Purchase Order Calendar" 100 100 588 523
BEGIN
    DIALOGBEHAVIOR
    EVENTMASK 1073742856
    INVISIBLE
    KEYBOARDNAVIGATION
    MANAGESYSCOLOR
    NAME "win_pocal"
    CHILD-WINDOW 1110, 100, 13, 66
    BEGIN
    END

    TOOLBUTTON 101, "BITMAP=sys/images/im_nb_fst_i.png", 19, 19, 20, 20
    BEGIN
        IMAGEFILE "sys/images/im_nb_fst_i.png"
        NAME "btn_prev_yr"
        SHORTCUE "Previous year"
    END

    TOOLBUTTON 102, "BITMAP=sys/images/im_nb_prv_i.png", 38, 19, 20, 20
    BEGIN
        IMAGEFILE "sys/images/im_nb_prv_i.png"
        NAME "btn_prev_mo"
        SHORTCUE "Previous month"
    END

    TOOLBUTTON 103, "BITMAP=sys/images/im_nb_nxt_i.png", 151, 19, 20, 20
    BEGIN
        IMAGEFILE "sys/images/im_nb_nxt_i.png"
        NAME "btn_next_mo"
        SHORTCUE "Next month"
    END

    TOOLBUTTON 104, "BITMAP=sys/images/im_nb_lst_i.png", 170, 19, 20, 20
    BEGIN
        IMAGEFILE "sys/images/im_nb_lst_i.png"
        NAME "btn_next_yr"
        SHORTCUE "Next year"
    END

    TOOLBUTTON 105, "BITMAP=sys/images/im_tb_cal_f.png", 189, 19, 20, 20
    BEGIN
        IMAGEFILE "sys/images/im_tb_cal_f.png"
        NAME "btn_curr_mo"
        SHORTCUE "Current month"
    END

    EDIT 106, "", 60, 19, 90, 21
    BEGIN
        CLIENTEDGE
        FONT "Tahoma" 8,bold
        JUSTIFICATION 16384
        NAME "Edit Control"
        READONLY
    END

    STATICTEXT 107, "Calendar begins", 395, 23, 84, 21
    BEGIN
        JUSTIFICATION 32768
        NAME "txtBegins"
    END

    STATICTEXT 108, "Ends", 447, 47, 32, 21
    BEGIN
        JUSTIFICATION 32768
        NAME "txtEnds"
    END

    EDIT 109, "", 483, 20, 60, 21
    BEGIN
        CLIENTEDGE
        NAME "Edit Control"
        READONLY
    END

    EDIT 110, "", 483, 44, 60, 21
    BEGIN
        CLIENTEDGE
        NAME "Edit Control"
        READONLY
    END

    LISTBUTTON 111, "", 60, 43, 150, 100
    BEGIN
        NAME "lstGaps"
        SELECTIONHEIGHT 21
    END

    STATICTEXT 112, "Gaps", 21, 45, 32, 21
    BEGIN
        JUSTIFICATION 32768
        NAME "txtGaps"
    END

END

CHILD-WINDOW 1110 0 0 440 360
BEGIN
    BORDERLESS
    EVENTMASK 3287287492
    NAME ""
    GRID 100, "", 7, 9, 428, 374
    BEGIN
        CLIENTEDGE
        COLUMNHEAD 20, 5001
        COLUMNS 7
        GRIDROWDEFAULTHEIGHT 40
        HORIZLINES
        MAXCOLS 65535
        NAME "grd_calendar"
        ROWS 6
        USERSIZE
        VERTLINES
    END

END

