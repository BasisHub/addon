[[PRR_UNIONHIST.YEAR_MONTH.AVAL]]
rem -- Get value from the yesr_month field
	month$=callpoint!.getUserInput()
        juldate=jul(num(month$(3,4)),num(month$(1,2)),1)
rem --- Get Dates For Sundays In The Month
	
	more=1
	i=1
    	xday=juldate
    	xmonth$=month$(1,2),p6$=""
	while more
        		xday$=date(xday:"%Ds%Dz")
        		xmonth$=date(xday:"%Mz"),xday=xday+1
       		if xmonth$<>month$(1,2) then break
        		lastday$=xday$(4,2)
        		if xday$(1,3)<>"Sun" then continue
		let p6$=p6$+lastday$   
		callpoint!.setColumnData("PRR_UNIONHIST.ENDING_DATE_"+str(i),lastday$)
		rem callpoint!.setColumnData("PRR_UNIONHIST.ENDING_DATE_1",lastday$)
		i=i+1
    	wend
    	callpoint!.setStatus("REFRESH")

