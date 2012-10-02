//#charset: windows-1252

VERSION "4.0"

WINDOW 1000 "DataPort Utility" 100 100 500 400
BEGIN
    INVISIBLE
    KEYBOARDNAVIGATION
    MANAGESYSCOLOR
    EVENTMASK 1073742856
    NAME "win_data_port"

    BUTTON 3, "Process", 400, 32, 85, 23
    BEGIN
        NAME "btn_process"
        DISABLED
    END

    BUTTON 4, "Scan", 400, 5, 85, 23
    BEGIN
        NAME "btn_scan"
        DISABLED
    END

    BUTTON 2, "Exit", 400, 59, 85, 23
    BEGIN
        NAME "btn_exit"
    END

    GROUPBOX 10000, "", 5, 0, 387, 82
    BEGIN
        NAME "grp_directories"
    END

    STATICTEXT 2000, "Version:", 8, 15, 110, 20
    BEGIN
        JUSTIFICATION 32768
        NAME "lbl_version"
        NOT OPAQUE
    END

    STATICTEXT 2010, "Source Directory:", 8, 37, 110, 20
    BEGIN
        JUSTIFICATION 32768
        NAME "lbl_source"
        NOT OPAQUE
    END

    STATICTEXT 2020, "Target Directory:", 8, 59, 110, 20
    BEGIN
        JUSTIFICATION 32768
        NAME "lbl_target"
    END

    LISTBUTTON 3000, "", 120, 12, 149, 90
    BEGIN
        SELECTIONHEIGHT 20
        NAME "lsb_version"
    END

    EDIT 3010, "", 120, 34, 225, 20
    BEGIN
        NAME "edt_source"
        CLIENTEDGE
    END

    BUTTON 3011, "...", 346, 34, 20, 20
    BEGIN
        NAME "btn_search_source"
    END

    EDIT 3020, "", 120, 56, 225, 20
    BEGIN
        NAME "edt_target"
        CLIENTEDGE
    END

    BUTTON 3021, "...", 346, 56, 20, 20
    BEGIN
        NAME "btn_search_target"
    END

    GRID 5000, "", 5, 90, 487, 297
    BEGIN
        ROWS 0
        COLUMNHEAD 20, 5010
        COLUMNS 4
        HORIZLINES
        VERTLINES
        GRIDCOLWIDTH 0, 30
        GRIDCOLWIDTH 1, 80
        GRIDCOLTITLE 1, "File ID"
        GRIDCOLTITLE 2, "Rec ID"
        GRIDCOLWIDTH 3, 300
        GRIDCOLTITLE 3, "Description"
        NAME "grd_files"
        CLIENTEDGE
    END
END

