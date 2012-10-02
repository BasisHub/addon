[[POE_RECDFLTS.BSHO]]
rem -- init devObject items

callpoint!.setDevObject("rec_complete","N")
callpoint!.setDevObject("dflt_rec_qty","Y")
[[POE_RECDFLTS.ASVA]]
rem -- store values in devObject and return to create the PO receipt from selected PO.

callpoint!.setDevObject("rec_complete",callpoint!.getColumnData("POE_RECDFLTS.DFLT_REC_COMP"))
callpoint!.setDevObject("dflt_rec_qty",callpoint!.getColumnData("POE_RECDFLTS.DFLT_REC_QTY"))
