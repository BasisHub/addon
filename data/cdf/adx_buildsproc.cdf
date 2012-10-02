[[ADX_BUILDSPROC.ARER]]
db!=fnget_control!("DATABASE")
db!.selectIndex(0)
[[ADX_BUILDSPROC.BSHO]]
use java.util.Arrays
[[ADX_BUILDSPROC.AWIN]]
rem --- load database listbutton w/ databases

db!=fnget_control!("DATABASE")
db!.removeAllItems()
sqllist! = sqllist(0)
list! = Arrays.asList(sqllist!.split($0a$))
if list!.size()<>0
	for i=0 to list!.size()-1
		db$ = str(list!.get(i))
		db!.addItem(db$)
	next i
else
	db!.addItem("(none)")
endif
[[ADX_BUILDSPROC.<CUSTOM>]]
rem fnget_control.src

def fnget_control!(ctl_name$)

ctlContext=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLC"))
ctlID=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI"))
get_control!=SysGUI!.getWindow(ctlContext).getControl(ctlID)
return get_control!

fnend



[[ADX_BUILDSPROC.ASVA]]
rem --- check to see if pathnames are valid

svdir$=dir("")
msg_id$="INVALID_PATH" 
dim msg_tokens$[1]
dim wdir$[1,1]

wdir$[0,0]=callpoint!.getColumnData("ADX_BUILDSPROC.SPROC_PATH")
wdir$[0,1]="ADX_BUILDSPROC.SPROC_PATH"
wdir$[1,0]=callpoint!.getColumnData("ADX_BUILDSPROC.BARISTA_CFG_PATH")
wdir$[1,1]="ADX_BUILDSPROC.BARISTA_CFG_PATH"

for x=0 to 1
	while pos("\"=wdir$[x,0])<>0
			wdir$[x,0](pos("\"=wdir$[x,0]),1)="/"
	wend
	if wdir$[x,0](len(wdir$[x,0]),1)<>"/" wdir$[x,0]=wdir$[x,0]+"/"
	callpoint!.setColumnData(wdir$[x,1],wdir$[x,0])
next x

for x=0 to 1
	chdir wdir$[x,0],err=*next;continue
	msg_tokens$[1]=msg_tokens$[1]+$0A$+wdir$[x,0]
next x

chdir svdir$

if msg_tokens$[1]<>""
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif

db!=fnget_control!("DATABASE")
if db!.getSelectedIndex()<0
	x=msgbox("No Database Selected")
	callpoint!.setStatus("ABORT")
else
	if pos("(none)"=db!.getItemAt(db!.getSelectedIndex()))<>0
		x=msgbox("No Database Selected")
		callpoint!.setStatus("ABORT")
	else
		callpoint!.setColumnData("ADX_BUILDSPROC.DATABASE",db!.getItemAt(db!.getSelectedIndex()))
endif
