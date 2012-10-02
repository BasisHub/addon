[[ADM_PROCBATCHMNT.PROCESS_ID.AVAL]]
rem --- enable orph scan button

callpoint!.setOptionEnabled("ORPH",1)
[[ADM_PROCBATCHMNT.AREC]]
callpoint!.setOptionEnabled("ORPH",0)
[[ADM_PROCBATCHMNT.AOPT-ORPH]]
rem --- read thru entry files for this process and see if there are any batches not in the batch file

adm_proctables_dev=fnget_dev("ADM_PROCTABLES")
dim adm_proctables$:fnget_tpl$("ADM_PROCTABLES")

adm_procbatches_dev=fnget_dev("ADM_PROCBATCHMNT")
dim adm_procbatches$:fnget_tpl$("ADM_PROCBATCHMNT")

batch_no$=callpoint!.getColumnData("ADM_PROCBATCHMNT.BATCH_NO")
process_id$=callpoint!.getColumnData("ADM_PROCBATCHMNT.PROCESS_ID")

if process_id$<>""

	msg_id$=""

	read (adm_proctables_dev,key=firm_id$+process_id$,dom=*next)

	while 1
		read record (adm_proctables_dev,end=*break)adm_proctables$
		if pos(firm_id$+process_id$=adm_proctables$)<>1 then break
		if pos("GLW_DAILYDETAIL"=adm_proctables.dd_table_alias$) then continue

		num_files=1
		dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
		open_tables$[1]=adm_proctables.dd_table_alias$,open_opts$[1]="OTA"
		gosub open_tables
		file_dev=num(open_chans$[1])
		dim file_rec$:open_tpls$[1]


		while file_dev

			read (file_dev,key=firm_id$,knum=1,dom=*next,err=*break)
			sv_batch$=""
			orph_batches! = BBjAPI().makeVector()
			while 1
				read record (file_dev,end=*break)file_rec$
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
			break
		wend

		if file_dev
			num_files=1
			dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
			open_tables$[1]=adm_proctables.dd_table_alias$,open_opts$[1]="C"
			gosub open_tables
		endif
	wend

	if msg_id$=""
		msg_id$="AD_BATCH_NO_ORPH"
		gosub disp_message
	endif
endif
[[ADM_PROCBATCHMNT.BDEL]]
rem --- don't allow delete if batch contains data

if callpoint!.getDevObject("can_delete")="NO"
	msg_id$="AD_BATCH_DTL"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
[[ADM_PROCBATCHMNT.ADIS]]
rem ---  don't allow delete if this batch is referenced in entry files

adm_proctables_dev=fnget_dev("ADM_PROCTABLES")
dim adm_proctables$:fnget_tpl$("ADM_PROCTABLES")

read (adm_proctables_dev,key=firm_id$+process_id$,dom=*next)
callpoint!.setDevObject("can_delete","")
batch_no$=callpoint!.getColumnData("ADM_PROCBATCHMNT.BATCH_NO")
process_id$=callpoint!.getColumnData("ADM_PROCBATCHMNT.PROCESS_ID")

form_opts$=callpoint!.getTableAttribute("OPTS")

while 1
	read record (adm_proctables_dev,end=*break)adm_proctables$
	if pos(firm_id$+process_id$=adm_proctables$)<>1 then break
	if pos("GLW_DAILYDETAIL"=adm_proctables.dd_table_alias$) then continue

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]=adm_proctables.dd_table_alias$,open_opts$[1]="OTA"
	gosub open_tables
	file_dev=num(open_chans$[1])

	while file_dev
		read (file_dev,key=firm_id$+batch_no$,knum=1,dom=*next,err=*break)
		k$=key(file_dev,end=*break)
		if pos(firm_id$+batch_no$=k$)=1 then callpoint!.setDevObject("can_delete","NO")		
		break
	wend

	if file_dev
		num_files=1
		dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
		open_tables$[1]=adm_proctables.dd_table_alias$,open_opts$[1]="C"
		gosub open_tables
	endif
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

num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ADM_PROCTABLES",open_opts$[1]="OTA"
gosub open_tables

callpoint!.setOptionEnabled("ORPH",0)
