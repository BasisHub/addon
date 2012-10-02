[[IVM_STOCK.SAFETY_STOCK.AVAL]]
if num(callpoint!.getUserInput())<0 then callpoint!.setStatus("ABORT")
[[IVM_STOCK.ORDER_POINT.AVAL]]
if num(callpoint!.getUserInput())<0 then callpoint!.setStatus("ABORT")
[[IVM_STOCK.MAXIMUM_QTY.AVAL]]
if num(callpoint!.getUserInput())<0 then callpoint!.setStatus("ABORT")
[[IVM_STOCK.LEAD_TIME.AVAL]]
if num(callpoint!.getUserInput())<0 or fpt(num(callpoint!.getUserInput())) then callpoint!.setStatus("ABORT")
[[IVM_STOCK.EOQ.AVAL]]
if num(callpoint!.getUserInput())<0 then callpoint!.setStatus("ABORT")
[[IVM_STOCK.ABC_CODE.AVAL]]
if (callpoint!.getUserInput()<"A" or callpoint!.getUserInput()>"Z") and callpoint!.getUserInput()<>" " callpoint!.setStatus("ABORT")
