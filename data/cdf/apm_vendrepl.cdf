[[APM_VENDREPL.BSHO]]
rem --- Disable Buyer Code if IV not installed
	call stbl("+DIR_PGM")+"adc_application.aon","IV",info$[all]
	iv$=info$[20]
	if iv$<>"Y"
		dim dctl$[1]
		dctl$[1]="APM_VENDREPL.BUYER_CODE"
		gosub disable_ctls
	endif
[[APM_VENDREPL.<CUSTOM>]]
disable_ctls:rem --- disable selected control

    for dctl=1 to 1
        dctl$=dctl$[dctl]
        if dctl$<>""
            wctl$=str(num(callpoint!.getTableColumnAttribute(dctl$,"CTLI")):"00000")
	 wmap$=callpoint!.getAbleMap()
            wpos=pos(wctl$=wmap$,8)
            wmap$(wpos+6,1)="I"
	 callpoint!.setAbleMap(wmap$)
            callpoint!.setStatus("ABLEMAP")
        endif
    next dctl
    return

#include std_missing_params.src
[[APM_VENDREPL.BDEL]]
rem --- check knum3 of ivm-01; if firm/buyer/vendor key is present, disallow deletion

ivm01_dev=fnget_dev("IVM_ITEMMAST")
wky$=firm_id$+callpoint!.getColumnData("APM_VENDREPL.BUYER_CODE")+callpoint!.getColumnData("APM_VENDREPL.VENDOR_ID")
wky1$=""
read(ivm01_dev,knum=9,key=wky$,dom=*next)
wky1$=key(ivm01_dev,end=*next)
if pos(wky$=wky1$)=1
	msg_id$="AP_DEL_REPL"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
