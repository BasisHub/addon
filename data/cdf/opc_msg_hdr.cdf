[[OPC_MSG_HDR.AOPT-LSTG]]
rem --- run the Std Message Listing program
rem --- since this is a header/detail file structure, the built-in 'print all records' option won't work

run stbl("+DIR_PGM")+"opr_stdmessage.aon",err=*next
