[[OPC_MESSAGE.AOPT-PRNT]]
rem --- create message listing


call stbl("+DIR_SYP")+"bam_run_prog.bbj","OPR_STDMSGLIST",stbl("+USER_ID"),"","",table_chans$[all]

[[OPC_MESSAGE.AOPT-PPVW]]
rem --- generate Jasper to show how messages will look on Pick List and Invoice 

	use ::bbjasper.bbj::BBJasperReport
	use ::bbjasper.bbj::BBJasperViewerWindow
	use ::bbjasper.bbj::BBJasperViewerControl

	use ::sys/prog/bao_utilities.bbj::BarUtils
	    
	ScreenSize!   = bbjAPI().getSysGui().getSystemMetrics().getScreenSize()
	screen_width  = ScreenSize!.width - 50; rem -50 keeps it in the MDI w/ no scroll bars
	screen_height = ScreenSize!.height - 50
	    
rem --- Get HashMap of Values in Options Entry Form

	params! = new java.util.HashMap()

	params!.put("FIRM_ID",firm_id$)
	params!.put("MESSAGE_CODE",callpoint!.getColumnData("OPC_MESSAGE.MESSAGE_CODE"))

rem --- Set Report Name & Subreport directory

	reportDir$ = BBjAPI().getFileSystem().resolvePath(stbl("+DIR_REPORTS",err=*next))+"/"
	repTitle!="Standard_Message_Formatting"
	reportBaseName$ = "OPMessageFormat"
	filename$ = reportDir$ + reportBaseName$ + ".jasper"

	declare BBJasperReport report!

rem --- Check for user authentication

	report! = BarUtils.getBBJasperReport(filename$)
	report!.putParams(params!)

	locale$ = stbl("!LOCALE")
	locale$ = stbl("+USER_LOCALE",err=*next)
	report!.setLocale(locale$)

rem --- Fill Report and Show

	rc=report!.fill(1)
	if rc<>BBJasperReport.getSUCCESS() then break

	declare BBJasperViewerWindow viewerWindow!
	viewerWindow! = new BBJasperViewerWindow(report!,0,0,screen_width,screen_height,repTitle$,$00080093$)

	viewerControl! = viewerWindow!.getViewerControl()
	viewerControl!.setFitWidth()

	viewerWindow!.setReleaseOnClose(0)
	viewerWindow!.show(1);rem 1 means let Jasper manage process_events
