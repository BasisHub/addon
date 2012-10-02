[[IVU_ITEMEOQUPDAT.AREC]]
rem --- Initialize check boxes
if num(stbl("+EOQ_CARRY",err=*next))=0 then
	callpoint!.setColumnData("IVU_ITEMEOQUPDAT.EOQ_UPDT","0")
	callpoint!.setColumnEnabled("IVU_ITEMEOQUPDAT.EOQ_UPDT", -1)
else
	callpoint!.setColumnData("IVU_ITEMEOQUPDAT.EOQ_UPDT","1")
endif
callpoint!.setColumnData("IVU_ITEMEOQUPDAT.ORDERPOINT_UPDT","1")
callpoint!.setColumnData("IVU_ITEMEOQUPDAT.SAFETYSTOCK_UPDT","1")
callpoint!.setStatus("REFRESH")
