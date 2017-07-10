[[BM_ITEMWHS_ACT.ASVA]]
gosub convert_userObj_to_array
dim temp$:key_template$
temp$=selected_key$
selected_key$=temp.firm_id$+temp.item_id$
callpoint!.setDevObject("selected_key",selected_key$)
gosub convert_array_to_userObj
[[BM_ITEMWHS_ACT.AOPT-ACTI]]
rem - Inactive Flag
gosub convert_userObj_to_array
show_all_items$=""
gosub get_groupid
rdFuncSpace!=BBjAPI().getGroupNamespace(err=*next)
show_all_items$=rdFuncSpace!.getValue("show_all_items"+grpid$,err=*next)
if show_all_items$<>"Y" then
   rdFuncSpace!.setValue("show_all_items"+grpid$,"Y")
else
   rdFuncSpace!.setValue("show_all_items"+grpid$,"N")
endif
callpoint!.setStatus("REFRESH")
gosub convert_array_to_userObj
[[BM_ITEMWHS_ACT.BOVE]]
gosub convert_userObj_to_array
gosub enum_popup
dim filter_defs$[3,2]
filter_defs$[1,0]="BMM_BILLMAST.FIRM_ID"
filter_defs$[1,1]="='"+stbl("+FIRM_ID")+"'"
filter_defs$[1,2]="LOCK"

rem - Inactive Flag
show_all_items$=""
gosub get_groupid
rdFuncSpace!=BBjAPI().getGroupNamespace(err=*next)
show_all_items$=rdFuncSpace!.getValue("show_all_items"+grpid$,err=*next)
if show_all_items$<>"Y" then
   filter_defs$[2,0]="IVM_ITEMMAST.ITEM_INACTIVE"
   filter_defs$[2,1]="<>'Y'"
   filter_defs$[2,2]="LOCK"
   window_title$="BM Bill Lookup - Active Inventory Items"
   menu_opt$="OPT-ACTI"
   menu_desc$="Show All Items"
else
   window_title$="BM Bill Lookup - All Inventory Items"
   menu_opt$="OPT-ACTI"
   menu_desc$="Show Active Items"
endif

whse!=callpoint!.getDevObject("whse")
if whse!<>null() then
   whse$=whse!
   filter_defs$[3,0]="IVM_ITEMWHSE.WAREHOUSE_ID"
   filter_defs$[3,1]="='"+whse$+"'"
   filter_defs$[3,2]="LOCK"
endif

Form!.setTitle(window_title$)
gosub convert_array_to_userObj
gosub set_popup_menu
callpoint!.setStatus("")
[[BM_ITEMWHS_ACT.<CUSTOM>]]
rem --- Portions Copyright 2016 by Assorted Business Services Inc.
rem ---  All Rights Reserved.

rem -- Convert selected_key$, filter_defs$[all]
rem --- search_defs$[all]  To the UserObj! Client Side
convert_array_to_userObj:
UserObj!.put("selected_key",selected_key$)
call stbl("+DIR_SYP")+"bao_array.bbj::str_array2object",filter_defs$[all],filter_defs!, status
UserObj!.put("filter_defs",filter_defs!)
call stbl("+DIR_SYP")+"bao_array.bbj::str_array2object",search_defs$[all],search_defs!, status
UserObj!.put("search_defs",search_defs!)
rem -- Pass the Popup Menu in the UserObj
return

rem -- Convert the UserObj! to selected_key Client Side
rem -- filter_defs$[all], search_defs$[all], and MenuObject
UserObj!.put("popmenuwin",rdPopMenuWin!)
convert_userObj_to_array:
if UserObj!.containsKey("selected_key") then
   selected_key$=UserObj!.get("selected_key")
endif

if UserObj!.containsKey("key_template") then
   key_template$=UserObj!.get("key_template")
endif

if UserObj!.containsKey("filter_defs") then
   filter_defs!=UserObj!.get("filter_defs")
   call stbl("+DIR_SYP")+"bao_array.bbj::str_object2array",filter_defs!,filter_defs$[all], status
endif

if UserObj!.containsKey("search_defs") then
   search_defs!=UserObj!.get("search_defs")
   call stbl("+DIR_SYP")+"bao_array.bbj::str_object2array",search_defs!,search_defs$[all], status
endif

if UserObj!.containsKey("popmenuwin") then
   PopMenuWin!=UserObj!.get("popmenuwin")
endif
return

rem -- enumerate user options in Popup Menu
enum_popup:
userPopUpMenu!=new java.util.HashMap()
optid=31971
while 1
   menuItem!=PopMenuWin!.getMenuItem(optid,err=*break)
   if menuItem!=null() then
      break
   endif
   userPopUpMenu!.put(menuItem!.getUserData(),str(optid))
   optid=optid+1
wend
return

rem -- Set Item on Requested Popup
set_popup_menu:
optid=num(userPopUpMenu!.get(menu_opt$),err=*return)
menuItem!=PopMenuWin!.getMenuItem(optid)
menuItem!.setText(menu_desc$)
return

get_groupid:
Session!=BBjAPI().getCurrentSessionInfo()
GroupID=Session!.getGroupID()
if GroupID=0 then
   SessionID=Session!.getSessionID()
   sessions!=BBjAPI().getSessionInfos()
   it!=sessions!.iterator()
   while it!.hasNext()
      session!=cast(BBjSessionInfo,it!.next())
      if session!.getSessionID()=SessionID then
         GroupID=session!.getGroupID()
         break
      endif
   wend
endif
grpid$=str(GroupID)
return

