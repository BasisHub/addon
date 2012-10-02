[[OPR_OPNORDDETAIL.QUOTED.AVAL]]
 gosub enable_listbutton
[[OPR_OPNORDDETAIL.CREDIT.AVAL]]
 gosub enable_listbutton
[[OPR_OPNORDDETAIL.NON_STOCK.AVAL]]
 gosub enable_listbutton
[[OPR_OPNORDDETAIL.BACKORDERS.AVAL]]
 gosub enable_listbutton
[[OPR_OPNORDDETAIL.OPEN.AVAL]]
 gosub enable_listbutton
[[OPR_OPNORDDETAIL.<CUSTOM>]]
enable_listbutton:

        ctl_name$="OPR_OPNORDDETAIL.non_stock_option"

        if callpoint!.getColumnData("OPR_OPNORDDETAIL.open")="N" and
:               callpoint!.getColumnData("OPR_OPNORDDETAIL.quoted")="N" and
:               callpoint!.getColumnData("OPR_OPNORDDETAIL.backorders")="N" and
:               callpoint!.getColumnData("OPR_OPNORDDETAIL.credit")="N" and
:               callpoint!.getColumnData("OPR_OPNORDDETAIL.non_stock")="Y"
                        ctl_stat$=" "
        else
                        ctl_stat$="D"
        endif
        gosub disable_fields
       
callpoint!.setStatus("ABLEMAP-ACTIVATE-REFRESH:OPR_OPNORDDETAIL.non_stock_option")
return

disable_fields:
        rem --- used to disable/enable controls depending on parameter settings
        rem --- send in control to toggle (format "ALIAS.CONTROL_NAME"), and D or space to disable/enable

       
wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
        wmap$=callpoint!.getAbleMap()
        wpos=pos(wctl$=wmap$,8)
        wmap$(wpos+6,1)=ctl_stat$
        callpoint!.setAbleMap(wmap$)
        callpoint!.setStatus("ABLEMAP-REFRESH")

return
