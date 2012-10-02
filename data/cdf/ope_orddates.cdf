[[OPE_ORDDATES.BEND]]
release
[[OPE_ORDDATES.ARAR]]
rem --- Setup default dates
	ars01_dev=fnget_dev("ARS_PARAMS")
	ars01a$=fnget_tpl$("ARS_PARAMS")
	dim ars01a$:ars01a$
	read record (ars01_dev,key=firm_id$+"AR00") ars01a$
	orddate$=date(0:"%Y%Mz%Dz")
	comdate$=orddate$
	shpdate$=orddate$
	comdays=num(ars01a.commit_days$)
	shpdays=num(ars01a.def_shp_days$)
	if comdays<>0 call stbl("+DIR_PGM")+"adc_daydates.aon",orddate$,comdate$,comdays
	if shpdays<>0 call stbl("+DIR_PGM")+"adc_daydates.aon",orddate$,shpdate$,shpdays
	callpoint!.setColumnData("OPE_ORDDATES.DEF_COMMIT",comdate$)
	callpoint!.setColumnData("OPE_ORDDATES.DEF_SHIP",shpdate$)
	callpoint!.setStatus("REFRESH")
	temp_stbl$=stbl("OPE_DEF_SHIP",shpdate$)
	temp_stbl$=stbl("OPE_DEF_COMMIT",comdate$)
