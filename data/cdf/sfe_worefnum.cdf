[[SFE_WOREFNUM.BEND]]
rem --- Signal that re-numbering WO reference was cancelled
	callpoint!.setDevObject("worefnum_status","CANCEL")
[[SFE_WOREFNUM.<CUSTOM>]]
rem =========================================================
checkRefnumSize: rem --- Will new refnums be too large?
rem --- data in: inc
rem --- data out: refnum_base$
rem --- data out: refnum_numeric$
rem --- data out: refnum_mask$
rem --- data out: abort
rem =========================================================
	abort=0

	rem --- Get refnum base characters and trailing numeric
	first_refnum$=callpoint!.getColumnData("SFE_WOREFNUM.FIRST_REFNUM")
	refnum$=cvs(first_refnum$,3)
	base_len=len(refnum$)
	while base_len>0
		x=num(refnum$(base_len,1),err=*break)
		base_len=base_len-1
	wend
	refnum_base$=refnum$(1,base_len)
	refnum_numeric$=refnum$(base_len+1)

	rem --- Calculate numeric for last refnum
	num_rows=num(callpoint!.getColumnData("SFE_WOREFNUM.ROW_2"))-num(callpoint!.getColumnData("SFE_WOREFNUM.ROW_1"))
	total_inc=num_rows*inc
	last_num=total_inc+num(refnum_numeric$)

	rem --- Calculate maximum allowable numeric
	dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")
	wk$=fattr(sfe_womatl$,"wo_ref_num")
	max_digits=dec(wk$(10,2))-len(refnum_base$)
	max_num=num(pad("",max_digits,"9"))

	rem --- There must be enough space in refnum to hold all of the new ones
	if last_num>max_num then
		msg_id$="SF_MAX_REF_NUM"
		dim msg_tokens$[2]
		msg_tokens$[1]=refnum_base$+str(last_num)
		msg_tokens$[2]=str(dec(wk$(10,2)))
		gosub disp_message
		abort=1
	endif
	if abort then return

	rem --- Should the refnum numeric be zero filled?
	refnum_mask$=pad("",len(refnum_numeric$),"0")
	if len(str(last_num))>len(refnum_numeric$) then
		if callpoint!.getDevObject("zfill_refnum")="" then
			new_mask$=pad("",len(str(last_num)),"0")
			new_refnum$=refnum_base$+str(num(refnum_numeric$):new_mask$)
			msg_id$="SF_ZFILL_REFNUM"
			dim msg_tokens$[2]
			msg_tokens$[1]=first_refnum$
			msg_tokens$[2]=new_refnum$
			gosub disp_message
			callpoint!.setDevObject("zfill_refnum",msg_opt$)
		endif
		if callpoint!.getDevObject("zfill_refnum")="Y" then
			new_mask$=pad("",len(str(last_num)),"0")
			new_refnum$=refnum_base$+str(num(refnum_numeric$):new_mask$)
			callpoint!.setColumnData("SFE_WOREFNUM.FIRST_REFNUM",new_refnum$,1)
			refnum_mask$=new_mask$
		endif
	endif

	return
[[SFE_WOREFNUM.ASVA]]
rem --- Will new refnums be too large?
	inc=num(callpoint!.getColumnData("SFE_WOREFNUM.INCREMENT"))
	gosub checkRefnumSize
	if abort then
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Generate new refnums
	rem --- (refnum_base$, refnum_numeric$ and refnum_mask$ come from checkRefnumSize routine)
	first_row=num(callpoint!.getColumnData("SFE_WOREFNUM.ROW_1"))
	last_row=num(callpoint!.getColumnData("SFE_WOREFNUM.ROW_2"))
	inc=num(callpoint!.getColumnData("SFE_WOREFNUM.INCREMENT"))
	owrite$=callpoint!.getColumnData("SFE_WOREFNUM.OVERWRITE")

	rem --- Make a temporary working copy of GridVect! and refnumMap!
	GridVect!=callpoint!.getDevObject("GridVect")
	tmpGridVect!=GridVect!.clone()
	refnumMap!=callpoint!.getDevObject("refnumMap")
	tmpRefnumMap!=refnumMap!.clone()

	rem --- Process refnums for range of selected grid rows
	success=1
	dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")
	wk$=fattr(sfe_womatl$,"wo_ref_num")
	refnum_size=dec(wk$(10,2))
	next_num=num(refnum_numeric$)
	for row=first_row to last_row
		rem --- Ok to overwrite existing refnum?
		if owrite$<>"Y" then
			rem --- Skip if this grid row already has a non-blank refnum
			sfe_womatl$=tmpGridVect!.getItem(row-1)
			if cvs(sfe_womatl.wo_ref_num$,2)<>"" then continue
		endif

		rem --- Next refnum
		next_refnum$=pad(refnum_base$+str(next_num:refnum_mask$),refnum_size,"R","")
		next_num=next_num+inc

		rem --- Verify next refnum isn't used already
		if tmpRefnumMap!.containsKey(next_refnum$) then
			msg_id$="SF_DUP_REF_NUM"
			dim msg_tokens$[1]
			msg_tokens$[1]=next_refnum$
			gosub disp_message
			success=0
			break
		endif

		rem --- Update tmp refnum map
		tmpRefnumMap!.put(next_refnum$,"")

		rem --- Update tmp grid vector
		sfe_womatl$=tmpGridVect!.getItem(row-1)
		sfe_womatl.wo_ref_num$=next_refnum$
		tmpGridVect!.setItem(row-1,sfe_womatl$)
	next row

	rem --- If success, update SFE_WOMATL records
	if success then
		sfe22_dev=fnget_dev("SFE_WOMATL")
		for row=first_row to last_row
			sfe_womatl$=tmpGridVect!.getItem(row-1)
			sfe_womatl$=field(sfe_womatl$)
			write(sfe22_dev)sfe_womatl$
		next row
	else
		callpoint!.setStatus("ABORT")
		break
	endif
[[SFE_WOREFNUM.INCREMENT.AVAL]]
rem --- Will new refnums be too large?
	inc=num(callpoint!.getUserInput())
	gosub checkRefnumSize
	if abort then
		callpoint!.setStatus("ABORT")
		break
	endif
[[SFE_WOREFNUM.FIRST_REFNUM.AVAL]]
rem --- Verify first_refnum is unique
	refnumMap!=callpoint!.getDevObject("refnumMap")
	first_refnum$=callpoint!.getUserInput()
	if refnumMap!.containsKey(first_refnum$) then
		msg_id$="SF_DUP_REF_NUM"
		dim msg_tokens$[1]
		msg_tokens$[1]=first_refnum$
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif
[[SFE_WOREFNUM.ROW.AVAL]]
rem --- Beginning row can't be less than 1
	min_row=1
	if num(callpoint!.getUserInput())<min_row then
		msg_id$="AD_MIN_ROW"
		dim msg_tokens$[1]
		msg_tokens$[1]=str(min_row)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Ending row can't be gretter than number of rows
	GridVect!=callpoint!.getDevObject("GridVect")
	max_row=GridVect!.size()
	if num(callpoint!.getUserInput())>max_row then
		msg_id$="AD_MAX_ROW"
		dim msg_tokens$[1]
		msg_tokens$[1]=str(max_row)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif
[[SFE_WOREFNUM.AREC]]
rem --- Initialize data
	dim sfe_womatl$:fnget_tpl$("SFE_WOMATL")
	wk$=fattr(sfe_womatl$,"material_seq")
	callpoint!.setColumnData("SFE_WOREFNUM.ROW_1",pad("1",dec(wk$(10,2)),"R","0"))

	GridVect!=callpoint!.getDevObject("GridVect")
	callpoint!.setColumnData("SFE_WOREFNUM.ROW_2",pad(str(GridVect!.size()),dec(wk$(10,2)),"R","0"))

	incrementer!=callpoint!.getControl("SFE_WOREFNUM.INCREMENT")
	incrementer!.setMinimum(1)
	incrementer!.setMaximum(100)
	callpoint!.setColumnData("SFE_WOREFNUM.INCREMENT","5")

	callpoint!.setDevObject("zfill_refnum","")

