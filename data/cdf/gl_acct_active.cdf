[[GL_ACCT_ACTIVE.ASVA]]
gosub convert_userObj_to_array
callpoint!.setDevObject("selected_key",selected_key$)
gosub convert_array_to_userObj

[[GL_ACCT_ACTIVE.AOPT-ACTI]]
rem - Inactive Flag
gosub convert_userObj_to_array
show_all_gl_accts$=""
gosub get_groupid
rdFuncSpace!=BBjAPI().getGroupNamespace(err=*next)
show_all_gl_accts$=rdFuncSpace!.getValue("show_all_gl_accts"+grpid$,err=*next)
if show_all_gl_accts$<>"Y" then
   rdFuncSpace!.setValue("show_all_gl_accts"+grpid$,"Y")
else
   rdFuncSpace!.setValue("show_all_gl_accts"+grpid$,"N")
endif
callpoint!.setStatus("REFRESH")
gosub convert_array_to_userObj

[[GL_ACCT_ACTIVE.BOVE]]
gosub convert_userObj_to_array
gosub enum_popup
dim filter_defs$[2,2]
filter_defs$[1,0]="GLM_ACCT.FIRM_ID"
filter_defs$[1,1]="='01'"
filter_defs$[1,2]="LOCK"

rem - Inactive Flag
show_all_gl_accts$=""
gosub get_groupid
rdFuncSpace!=BBjAPI().getGroupNamespace(err=*next)
show_all_gl_accts$=rdFuncSpace!.getValue("show_all_gl_accts"+grpid$,err=*next)
if show_all_gl_accts$<>"Y" then
   filter_defs$[2,0]="GLM_ACCT.ACCT_INACTIVE"
   filter_defs$[2,1]="<>'Y'"
   filter_defs$[2,2]="LOCK"
   window_title$=Translate!.getTranslation("AON_GL_ACCT_LOOKUP")+" - "+Translate!.getTranslation("AON_ACTIVE")+" "+Translate!.getTranslation("AON_ACCOUNTS");rem "GL Accounts Lookup - Active Accounts"
   menu_opt$="OPT-ACTI"
   menu_desc$=Translate!.getTranslation("AON_SHOW")+" "+Translate!.getTranslation("AON_ALL")+" "+Translate!.getTranslation("AON_ACCOUNTS");rem "Show All Accounts"
else
   window_title$=Translate!.getTranslation("AON_GL_ACCT_LOOKUP")+" - "+Translate!.getTranslation("AON_ALL")+" "+Translate!.getTranslation("AON_ACCOUNTS");rem "GL Accounts Lookup - All Accounts"
   menu_opt$="OPT-ACTI"
   menu_desc$=Translate!.getTranslation("AON_SHOW")+" "+Translate!.getTranslation("AON_ACTIVE")+" "+Translate!.getTranslation("AON_ACCOUNTS");rem "Show Active Accounts"
endif
Form!.setTitle(window_title$)
gosub convert_array_to_userObj
gosub set_popup_menu
callpoint!.setStatus("")
[[GL_ACCT_ACTIVE.<CUSTOM>]]
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

