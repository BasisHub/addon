[[IVE_TRANSHDR.BSHO]]
rem --- open files

	num_files=1
	dim files$[num_files],options$[num_files],ids$[num_files],templates$[num_files],channels[num_files]
	files$[1]="ivs_params",ids$[1]="IVS_PARAMS",options$[1]="OTA"
	call stbl("+DIR_PGM")+"adc_fileopen.aon",action,1,num_files,files$[all],options$[all],
:			ids$[all],templates$[all],channels[all],batch,status
	if status goto std_exit
	ivs01_dev=channels[1]

rem --- get template(s)

	dim ivs01a$:templates$[1]

rem --- get parameter record and disable columns if necessary

	readrecord(ivs01_dev,key=firm_id$+"IV00",dom=std_error)ivs01a$
escape
