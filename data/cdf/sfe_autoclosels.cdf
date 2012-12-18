[[SFE_AUTOCLOSELS.<CUSTOM>]]
rem ==========================================================================
validate_lotser_no: rem --- Verify lotser_no exists for this wo_no
rem --- lotser_no$: input
rem --- warning_msg: input    (0=do not display warning message/1=display warning message)
rem --- valid_lotser_no: output    (0=invalid lotser_no/1=valid lotser_no)
rem ==========================================================================
	wolotser_dev=fnget_dev("@SFE_WOLOTSER")
	dim wolotser$:fnget_tpl$("@SFE_WOLOTSER")
	wo_location$=callpoint!.getColumnData("SFE_AUTOCLOSELS.WO_LOCATION")
	wo_no$=callpoint!.getColumnData("SFE_AUTOCLOSELS.WO_NO")

	valid_lotser_no=1
	wolotser_found=0
	findrecord(wolotser_dev,key=firm_id$+lotser_no$,knum="AO_LOTSER",dom=*next)wolotser$; wolotser_found=1
	if (!wolotser_found or wolotser.wo_location$<>wo_location$ or wolotser.wo_no$<>wo_no$) then
		valid_lotser_no=0
		if warning_msg then
			msg_id$="SF_LS_NOT_ENTERED"
			dim msg_tokens$[2]
			msg_tokens$[1]=cvs(lotser_no$,3)
			msg_tokens$[2]=cvs(wo_no$,3)
			gosub disp_message
		endif
	endif
	return
[[SFE_AUTOCLOSELS.LOTSER_NO.AVAL]]
rem --- Verify lotser_no exists for this wo_no
	lotser_no$=callpoint!.getUserInput()
	warning_msg=1
	gosub validate_lotser_no
	if !valid_lotser_no then
		callpoint!.setStatus("ABORT")
		break
	endif
[[SFE_AUTOCLOSELS.BSHO]]
rem --- Open Files
	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFE_WOLOTSER",open_opts$[1]="OTA@"
	open_tables$[2]="SFE_WOLOTSER",open_opts$[2]="OTA[1]"

	gosub open_tables

rem --- Set close_qty maximum value to max_qty when given
	seterr skip_max_qty
	max_qty=int(callpoint!.getDevObject("max_qty"))
	seterr std_error
	callpoint!.setTableColumnAttribute("SFE_AUTOCLOSELS.CLOSE_QTY","MAXV",str(max_qty))

skip_max_qty:
	seterr std_error
[[SFE_AUTOCLOSELS.ASVA]]
rem --- Valid lotser_no for this wo_no required in order to close
	close_qty=num(callpoint!.getColumnData("SFE_AUTOCLOSELS.CLOSE_QTY"))
	lotser_no$=callpoint!.getColumnData("SFE_AUTOCLOSELS.LOTSER_NO")
	warning_msg=0
	gosub validate_lotser_no
	if valid_lotser_no and close_qty>0 then
		rem --- Close lot/serial items
		wolotser_dev=fnget_dev("1SFE_WOLOTSER")
		dim wolotser$:fnget_tpl$("1SFE_WOLOTSER")
		wo_location$=callpoint!.getColumnData("SFE_AUTOCLOSELS.WO_LOCATION")
		wo_no$=callpoint!.getColumnData("SFE_AUTOCLOSELS.WO_NO")

		need_to_close=close_qty
		read(wolotser_dev,key=firm_id$+wo_location$+wo_no$,dom=*next)
		while need_to_close
			rem --- Note this simple model assumes the records are in lotser_no order
			wolotser_key$=key(wolotser_dev,end=*break)
			if pos(firm_id$+wo_location$+wo_no$=wolotser_key$)<>1 then break
			extractrecord(wolotser_dev)wolotser$; rem Advisory locking
			if wolotser.lotser_no$<lotser_no$ then
				rem --- Skip this lotser_no, it's before starting close lotser_no
				read(wolotser_dev)
				continue
			endif
			if wolotser.closed_flag$="Y" then
				rem --- Already closed
				read(wolotser_dev)
				continue
			endif
			qty_open=max(wolotser.sch_prod_qty-wolotser.qty_cls_todt,0)
			if qty_open=0 then
				rem --- Nothing available to close
				read(wolotser_dev)
				continue
			endif

			rem --- Don't close more than are available, or needed
			wolotser.cls_inp_qty=min(qty_open,need_to_close)
			if wolotser.cls_inp_qty+wolotser.qty_cls_todt>=wolotser.sch_prod_qty then wolotser.complete_flg$="Y"
			writerecord(wolotser_dev)wolotser$
			need_to_close=need_to_close-wolotser.cls_inp_qty
		wend
	endif
    
rem --- Return actually number of lot/serial items closed
	ls_closed=close_qty-need_to_close
	callpoint!.setDevObject("ls_closed",ls_closed)

rem --- Warn if fewer lot/serial items were closed than requested
	if ls_closed<close_qty then
		msg_id$="SF_LS_NOT_CLOSED"
		dim msg_tokens$[2]
		msg_tokens$[1]=str(ls_closed)
		msg_tokens$[2]=str(close_qty)
		gosub disp_message
	endif
