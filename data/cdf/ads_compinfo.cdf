[[ADS_COMPINFO.LOGO_FILE.AINP]]
entry_ctl=num(stbl("+ENTRY_CTL"))
image_ctl=num(stbl("+IMAGE_CTL"))
ctl_id=num(callpoint!.getTableColumnAttribute("ADS_COMPINFO.LOGO_FILE","CTLI"))
ctl_ctx=num(callpoint!.getTableColumnAttribute("ADS_COMPINFO.LOGO_FILE","CTLC"))
minwidth=num(callpoint!.getTableColumnAttribute("ADS_COMPINFO.LOGO_FILE","CTLW"))
minheight=num(callpoint!.getTableColumnAttribute("ADS_COMPINFO.LOGO_FILE","CTLH"))
imgctl!=sysgui!.getWindow(ctl_ctx).getControl(ctl_id-entry_ctl+image_ctl)
img! = imgctl!.getImage()

if img!<>null() imgctl!.setSize(min(minwidth,img!.getWidth()),min(minheight,img!.getHeight()))
[[ADS_COMPINFO.AREC]]
rem --- retrieve/display the firm name from Barista when no company rec yet exists

	callpoint!.setColumnData("ADS_COMPINFO.FIRM_NAME",sysinfo.firm_name$,1)
	callpoint!.setStatus("MODIFIED")
[[ADS_COMPINFO.ADIS]]
rem --- retrieve/display the firm name from Barista

if cvs(callpoint!.getColumnData("ADS_COMPINFO.FIRM_NAME"),3)<>cvs(sysinfo.firm_name$,3)
	callpoint!.setColumnData("ADS_COMPINFO.FIRM_NAME",sysinfo.firm_name$,1)
	callpoint!.setStatus("MODIFIED")
endif

entry_ctl=num(stbl("+ENTRY_CTL"))
image_ctl=num(stbl("+IMAGE_CTL"))
ctl_id=num(callpoint!.getTableColumnAttribute("ADS_COMPINFO.LOGO_FILE","CTLI"))
ctl_ctx=num(callpoint!.getTableColumnAttribute("ADS_COMPINFO.LOGO_FILE","CTLC"))
minwidth=num(callpoint!.getTableColumnAttribute("ADS_COMPINFO.LOGO_FILE","CTLW"))
minheight=num(callpoint!.getTableColumnAttribute("ADS_COMPINFO.LOGO_FILE","CTLH"))
imgctl!=sysgui!.getWindow(ctl_ctx).getControl(ctl_id-entry_ctl+image_ctl)
img! = imgctl!.getImage()

if img!<>null() imgctl!.setSize(min(minwidth,img!.getWidth()),min(minheight,img!.getHeight()))

