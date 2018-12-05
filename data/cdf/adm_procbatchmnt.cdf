[[ADM_PROCBATCHMNT.BDEQ]]
rem --- don't allow delete if batch contains data

if callpoint!.getDevObject("can_delete")="NO"
	msg_id$="AD_BATCH_DTL"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
[[ADM_PROCBATCHMNT.PROCESS_ID.AVAL]]
rem --- enable orph scan button

callpoint!.setOptionEnabled("ORPH",1)
[[ADM_PROCBATCHMNT.AREC]]
callpoint!.setOptionEnabled("ORPH",0)
[[ADM_PROCBATCHMNT.AOPT-ORPH]]
rem --- read thru entry files for this process and see if there are any batches not in the batch file

process_id$=callpoint!.getColumnData("ADM_PROCBATCHMNT.PROCESS_ID")
if process_id$<>""
	adm_proctables_dev=fnget_dev("ADM_PROCTABLES")
	dim adm_proctables$:fnget_tpl$("ADM_PROCTABLES")
	adm_procbatches_dev=fnget_dev("ADM_PROCBATCHMNT")
	dim adm_procbatches$:fnget_tpl$("ADM_PROCBATCHMNT")
	ddmKeySegs_dev=fnget_dev("DDM_KEY_SEGS")
	dim ddmKeySegs$:fnget_tpl$("DDM_KEY_SEGS")

	batch_no$=callpoint!.getColumnData("ADM_PROCBATCHMNT.BATCH_NO")
	msg_id$=""

	read (adm_proctables_dev,key=firm_id$+process_id$,dom=*next)
	while 1
		read record (adm_proctables_dev,end=*break)adm_proctables$
		if pos(firm_id$+process_id$=adm_proctables$)<>1 then break

		rem --- Find batch key for this table
		dd_key_number$=""
		dd_segment_seq$="02"
		dd_table_alias$=adm_proctables.dd_table_alias$
		read(ddmKeySegs_dev,key=dd_table_alias$,dom=*next)
		while 1
			readrecord(ddmKeySegs_dev,end=*break)ddmKeySegs$
			if ddmKeySegs.dd_table_alias$<>dd_table_alias$ then continue
			if ddmKeySegs.dd_segment_seq$<>dd_segment_seq$ then continue
			if ddmKeySegs.dd_segment_col$<>"BATCH_NO" then continue
			dd_key_number$=ddmKeySegs.dd_key_number$
			break
		wend
		if dd_key_number$="" then continue

		num_files=1
		dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
		open_tables$[1]=dd_table_alias$,open_opts$[1]="OTA"
		gosub open_tables
		file_dev=num(open_chans$[1])
		dim file_rec$:open_tpls$[1]

		if file_dev
			orph_batches! = BBjAPI().makeVector()
			sv_batch$=""
			read (file_dev,key=firm_id$,knum=num(dd_key_number$),dom=*next)
			while 1
				read record (file_dev,end=*break)file_rec$
				rem --- If a table with a trans_status column, like opt_invdet, is added to a adm_proctables process, then
				rem --- skip records where trans_status$<>"E". (Performance is going to stink reading every record in opt_invdet.)
				if file_rec.batch_no$<>sv_batch$
					sv_batch$=file_rec.batch_no$	
					found=0			
					read (adm_procbatches_dev,key=firm_id$+process_id$+sv_batch$,dom=*next); found=1
					if !found then orph_batches!.addItem(sv_batch$)
				endif
			wend
			x=orph_batches!.size()

			if x
				msg_id$="AD_BATCH_ORPH"
				dim msg_tokens$[2]
				batches$=""
				msg_tokens$[1]=cvs(adm_proctables.dd_table_alias$,3)
				for y=0 to x-1
					batches$=batches$+orph_batches!.getItem(y)+$0A$
				next y
				msg_tokens$[2]=batches$
				gosub disp_message
			endif				

			num_files=1
			dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
			open_tables$[1]=dd_table_alias$,open_opts$[1]="C"
			gosub open_tables
		endif
	wend

	if msg_id$=""
		msg_id$="AD_BATCH_NO_ORPH"
		gosub disp_message
	endif
endif
[[ADM_PROCBATCHMNT.ADIS]]
rem ---  don't allow delete if this batch is referenced in entry files

adm_proctables_dev=fnget_dev("ADM_PROCTABLES")
dim adm_proctables$:fnget_tpl$("ADM_PROCTABLES")
ddmKeySegs_dev=fnget_dev("DDM_KEY_SEGS")
dim ddmKeySegs$:fnget_tpl$("DDM_KEY_SEGS")

callpoint!.setDevObject("can_delete","")
batch_no$=callpoint!.getColumnData("ADM_PROCBATCHMNT.BATCH_NO")
process_id$=callpoint!.getColumnData("ADM_PROCBATCHMNT.PROCESS_ID")

read (adm_proctables_dev,key=firm_id$+process_id$,dom=*next)
while 1
	read record (adm_proctables_dev,end=*break)adm_proctables$
	if pos(firm_id$+process_id$=adm_proctables$)<>1 then break

	rem --- Find batch key for this table
	dd_key_number$=""
	dd_segment_seq$="02"
	dd_table_alias$=adm_proctables.dd_table_alias$
	read(ddmKeySegs_dev,key=dd_table_alias$,dom=*next)
	while 1
		readrecord(ddmKeySegs_dev,end=*break)ddmKeySegs$
		if ddmKeySegs.dd_table_alias$<>dd_table_alias$ then continue
		if ddmKeySegs.dd_segment_seq$<>dd_segment_seq$ then continue
		if ddmKeySegs.dd_segment_col$<>"BATCH_NO" then continue
		dd_key_number$=ddmKeySegs.dd_key_number$
		break
	wend
	if dd_key_number$="" then continue

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]=dd_table_alias$,open_opts$[1]="OTA"
	gosub open_tables
	file_dev=num(open_chans$[1])
	file_tpl$=open_tpls$[1]

	if file_dev
		rem --- If a table with a trans_status column, like opt_invhdr, is added to a adm_proctables process, then
		rem --- need to use a knum for a firm_id+batch_no+trans_status key, like opt_invhdr's AO_BATCH_STAT key,
		rem --- and set tripKey$irm_id$+batch_no$+"E". (Check file_tpl$ for trans_status column.)
		tripKey$=firm_id$+batch_no$
		read (file_dev,key=tripKey$,knum=num(dd_key_number$),dom=*next,err=*endif)
		k$=key(file_dev,end=*endif)
		if pos(tripKey$=k$)=1 then callpoint!.setDevObject("can_delete","NO")		

		num_files=1
		dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
		open_tables$[1]=dd_table_alias$,open_opts$[1]="C"
		gosub open_tables
	endif

	if callpoint!.getDevObject("can_delete")="NO" then break
wend

if callpoint!.getDevObject("can_delete")="NO"
	callpoint!.setColumnData("<<DISPLAY>>.DSP_DATA","Y")
else
	callpoint!.setColumnData("<<DISPLAY>>.DSP_DATA","N")
endif

callpoint!.setOptionEnabled("ORPH",1)
callpoint!.setStatus("REFRESH")
[[ADM_PROCBATCHMNT.BSHO]]
rem --- open files

num_files=2
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ADM_PROCTABLES",open_opts$[1]="OTA"
open_tables$[2]="DDM_KEY_SEGS",open_opts$[2]="OTA"

gosub open_tables

callpoint!.setOptionEnabled("ORPH",0)
