[[APM_VENDADDR.PURCH_ADDR.AINP]]
if cvs(callpoint!.getUserInput(),2)="" callpoint!.setStatus("ABORT")

if num(callpoint!.getUserInput())=0 callpoint!.setStatus("ABORT")
