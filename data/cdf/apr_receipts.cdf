[[APR_RECEIPTS.AREC]]
rem --- Initialize beginning and ending dates
	endDate$=stbl("+SYSTEM_DATE",err=*next)
	if len(endDate$)=8 then
		endYYYY=num(endDate$(1,4),err=*next)
		endMM=num(endDate$(5,2),err=*next)
		endDD=num(endDate$(7,2),err=*next)
		callpoint!.setColumnData("APR_RECEIPTS.PICK_DATE_1",date(jul(endYYYY,endMM,endDD,err=*next)-365:"%Yd%Mz%Dz",err=*next),1)
		callpoint!.setColumnData("APR_RECEIPTS.PICK_DATE_2",endDate$,1)
	endif
