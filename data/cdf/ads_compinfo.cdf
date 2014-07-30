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
