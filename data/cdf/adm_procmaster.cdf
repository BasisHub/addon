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
[[ADM_PROCMASTER.AOPT-ACTL]]
rem call up adm_auditcontrol form

cp_processID$=callpoint!.getColumnData("ADM_PROCMASTER.PROCESS_ID")

user_id$=stbl("+USER_ID")
key_pfx$=firm_id$+cp_processID$

call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"ADM_AUDITCONTROL",
:	user_id$,
:	"",
:	key_pfx$,
:	table_chans$[all],
:	"",
:	""
