[[POE_REPLENSELECT.ASVA]]
rem --- write poe-07
rem --- run program is old poe.fb that builds poe-06/16/26/36 and 17(?)

poe_repsel_dev=fnget_dev("POE_REPSEL")
dim poe_repsel$:fnget_tpl$("POE_REPSEL")

call stbl("+DIR_SYP")+"bac_key_template.bbj","POE_REPSEL","PRIMARY",key_tpl$,table_chans$[all],rd_stat$
dim k$:key_tpl$

first$=firm_id$+"00"
last$=firm_id$+$FF$

read (poe_repsel_dev,key=last$,dom=*next)
k$=keyp(poe_repsel_dev,end=*next)

if pos(firm_id$=k$)<>1 then k$=first$

if k.sequence_num$<"99"
	poe_repsel.firm_id$=firm_id$
	poe_repsel.sequence_num$=str(num( k.sequence_num$)+1:"00")
	poe_repsel.begin_vend$=callpoint!.getColumnData("POE_REPLENSELECT.VENDOR_ID_1")
	poe_repsel.ending_vend$=callpoint!.getColumnData("POE_REPLENSELECT.VENDOR_ID_2")
	poe_repsel.beg_buyer$=callpoint!.getColumnData("POE_REPLENSELECT.BUYER_CODE_1")
	poe_repsel.end_buyer$=callpoint!.getColumnData("POE_REPLENSELECT.BUYER_CODE_2")
	poe_repsel.from_whse$=callpoint!.getColumnData("POE_REPLENSELECT.WAREHOUSE_ID_1")
	poe_repsel.thru_whse$=callpoint!.getColumnData("POE_REPLENSELECT.WAREHOUSE_ID_2")
	poe_repsel.begrev_date$=callpoint!.getColumnData("POE_REPLENSELECT.REVIEW_DATE_1")
	poe_repsel.endrev_date$=callpoint!.getColumnData("POE_REPLENSELECT.REVIEW_DATE_2")
	poe_repsel.rep_comments$=callpoint!.getColumnData("POE_REPLENSELECT.REP_COMMENTS")

	write record (poe_repsel_dev)poe_repsel$

	rem --- also set hidden seq# field to pass into backend program for use in updating poe-17 (poe_repxref)
	callpoint!.setColumnData("POE_REPLENSELECT.REPLEN_SEQ",poe_repsel.sequence_num$)
else
	callpoint!.setMessage("PO_REP_SEL")
	callpoint!.setStatus("ABORT")
endif
[[POE_REPLENSELECT.AWIN]]
rem --- open tables, poe06/16/26/36/07/17

num_files=6
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="POE_ORDHDR",open_opts$[1]="OTA"
open_tables$[2]="POE_ORDDET",open_opts$[2]="OTA"
open_tables$[3]="POE_ORDTOT",open_opts$[3]="OTA"
open_tables$[4]="POE_REPSURP",open_opts$[4]="OTA"
open_tables$[5]="POE_REPXREF",open_opts$[5]="OTA"
open_tables$[6]="POE_REPSEL",open_opts$[6]="OTA"

gosub open_tables
poe_ordhdr_dev=num(open_chans$[1])
poe_orddet_dev=num(open_chans$[2])
poe_ordtot_dev=num(open_chans$[3])
poe_repsurp_dev=num(open_chans$[4])
poe_repxref_dev=num(open_chans$[5])
poe_repsel_dev=num(open_chans$[6])

rem --- See if we need to clear out poe-07

	while 1
		read(poe_repsel_dev,key=firm_id$,dom=*next)
		k$=key(poe_repsel_dev,end=*break)
		if pos(firm_id$=k$)<>1 break
		msg_id$="CLEAR_SEL"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		if msg_opt$="Y"
			call stbl("+DIR_PGM")+"adc_clearpartial.aon","",poe_ordhdr_dev,firm_id$,status;if status then release
			call stbl("+DIR_PGM")+"adc_clearpartial.aon","",poe_orddet_dev,firm_id$,status; if status then release
			call stbl("+DIR_PGM")+"adc_clearpartial.aon","",poe_ordtot_dev,firm_id$,status; if status then release
			call stbl("+DIR_PGM")+"adc_clearpartial.aon","",poe_repsel_dev,firm_id$,status; if status then release
			call stbl("+DIR_PGM")+"adc_clearpartial.aon","",poe_repsurp_dev,firm_id$,status; if status then release
			call stbl("+DIR_PGM")+"adc_clearpartial.aon","",poe_repxref_dev,firm_id$,status; if status then release
		endif
		break
	wend
