[[ADM_PROCMASTER.BDEL]]
rem --- don't allow delete if any batches are out there

adm_procbatches_dev=fnget_dev("ADM_PROCBATCHES")
dim adm_procbatches$:fnget_tpl$("ADM_PROCBATCHES")

process_id$=callpoint!.getColumnData("ADM_PROCMASTER.PROCESS_ID")

read (adm_procbatches_dev,key=firm_id$+process_id$,dom=*next)
while 1
	k$=key(adm_procbatches_dev,end=*break)
	if pos(firm_id$+process_id$=k$)<>1 then break
	msg_id$="AD_BATCH_EXISTS"
	gosub disp_message
	callpoint!.setStatus("ABORT")
	break
wend
[[ADM_PROCMASTER.AOPT-BCHS]]
rem --- launch inquiry of existing batches this process

key_pfx$=firm_id$+callpoint!.getColumnData("ADM_PROCMASTER.PROCESS_ID")
call stbl("+DIR_SYP")+"bam_inquiry.bbj",gui_dev,Form!,"ADM_PROCBATCHES","VIEW",table_chans$[all],key_pfx$
[[ADM_PROCMASTER.ADIS]]
rem --- look in adm_proctables file to see which tables are batched; make sure they're empty before allowing batching toggle

adm_proctables_dev=fnget_dev("ADM_PROCTABLES")
dim adm_proctables$:fnget_tpl$("ADM_PROCTABLES")
process_id$=callpoint!.getColumnData("ADM_PROCMASTER.PROCESS_ID")

read (adm_proctables_dev,key=firm_id$+process_id$,dom=*next)
keys_used=0
file_count=0

while 1
	read record (adm_proctables_dev,end=*break)adm_proctables$
	if pos(firm_id$+process_id$=adm_proctables$)<>1 then break
	if pos("GLW_DAILYDETAIL"=adm_proctables.dd_table_alias$) then continue
	file_count=file_count+1
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]=adm_proctables.dd_table_alias$,open_opts$[1]="OTA"
	gosub open_tables
	if num(open_chans$[1])
		x$=fin(num(open_chans$[1]))
		keys_used=keys_used+dec(x$(77,4))

	endif
wend

if file_count>0 and keys_used=0
	callpoint!.setColumnEnabled("ADM_PROCMASTER.BATCH_ENTRY",1)
else
	callpoint!.setColumnEnabled("ADM_PROCMASTER.BATCH_ENTRY",0)
endif

callpoint!.setStatus("REFRESH")
[[ADM_PROCMASTER.AWRI]]
update_posting_control:

glm06_dev=fnget_dev("ADM_AUDITCONTROL")
dim glm06a$:fnget_tpl$("ADM_AUDITCONTROL")

recVect!=GridVect!.getItem(0)
dim gridrec$:dtlg_param$[1,3]
numrecs=recVect!.size()
if numrecs>0
	for reccnt=0 to numrecs-1
		gridrec$=recVect!.getItem(reccnt)
		if cvs(gridrec$,3)<> "" 
			while 1
				readrecord(glm06_dev,key=firm_id$+gridrec$.process_id$ +gridrec.sequence_no$, dom=*break)glm06a$	
				glm06a.process_alias$=gridrec.dd_table_alias$
				glm06a.process_program$=gridrec.program_name$
				glm06a$=field(glm06a$)
				writerecord(glm06_dev)glm06a$
				break
			wend
		endif
	next reccnt
endif
[[ADM_PROCMASTER.BSHO]]
rem --- open gl posting control file (glm-06); any writes to adm-19 (adm_procdetail) need to propagate alias/prog name to glm-06
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ADM_AUDITCONTROL",open_opts$[1]="OTA"
gosub open_tables
