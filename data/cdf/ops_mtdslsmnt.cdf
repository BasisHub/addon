[[OPS_MTDSLSMNT.ASVA]]
rem --- populate variables
	ops_mtdsales_dev=fnget_dev("OPS_MTDSALES")
	dim ops_mtdsales$:fnget_tpl$("OPS_MTDSALES")
	ars_mtdcash_dev=fnget_dev("ARS_MTDCASH")
	dim ars_mtdcash$:fnget_tpl$("ARS_MTDCASH")
	readrecord(ops_mtdsales_dev,key=firm_id$+"S",dom=*next)ops_mtdsales$
	readrecord(ars_mtdcash_dev,key=firm_id$+"C",dom=*next)ars_mtdcash$

	ops_mtdsales.firm_id$=firm_id$
	ops_mtdsales.record_id_s$="S"
	ars_mtdcash.firm_id$=firm_id$
	ars_mtdcash.record_id_c$="C"
	ars_mtdcash.mtd_cash=num(callpoint!.getColumnData("OPS_MTDSLSMNT.MTD_CASH"))
	ops_mtdsales.mtd_cost=num(callpoint!.getColumnData("OPS_MTDSLSMNT.MTD_COST"))
	ars_mtdcash.mtd_csh_disc=num(callpoint!.getColumnData("OPS_MTDSLSMNT.MTD_CSH_DISC"))
	ars_mtdcash.mtd_csh_gl=num(callpoint!.getColumnData("OPS_MTDSLSMNT.MTD_CSH_GL"))
	ops_mtdsales.mtd_csh_sale=num(callpoint!.getColumnData("OPS_MTDSLSMNT.MTD_CSH_SALE"))
	ops_mtdsales.mtd_discount=num(callpoint!.getColumnData("OPS_MTDSLSMNT.MTD_DISCOUNT"))
	ops_mtdsales.mtd_freight=num(callpoint!.getColumnData("OPS_MTDSLSMNT.MTD_FREIGHT"))
	ops_mtdsales.mtd_returns=num(callpoint!.getColumnData("OPS_MTDSLSMNT.MTD_RETURNS"))
	ops_mtdsales.mtd_sales=num(callpoint!.getColumnData("OPS_MTDSLSMNT.MTD_SALES"))
	ops_mtdsales.mtd_tax=num(callpoint!.getColumnData("OPS_MTDSLSMNT.MTD_TAX"))
	ars_mtdcash.nmtd_cashgl=num(callpoint!.getColumnData("OPS_MTDSLSMNT.NMTD_CASHGL"))
	ops_mtdsales.nmtd_cashsl=num(callpoint!.getColumnData("OPS_MTDSLSMNT.NMTD_CASHSL"))
	ars_mtdcash.nmtd_cash_ds=num(callpoint!.getColumnData("OPS_MTDSLSMNT.NMTD_CASH_DS"))
	ops_mtdsales.nmtd_returns=num(callpoint!.getColumnData("OPS_MTDSLSMNT.NMTD_RETURNS"))
	ops_mtdsales.nmtd_sales=num(callpoint!.getColumnData("OPS_MTDSLSMNT.NMTD_SALES"))
	ops_mtdsales.nmtd_tax=num(callpoint!.getColumnData("OPS_MTDSLSMNT.NMTD_TAX"))
	ars_mtdcash.nxt_mtd_cash=num(callpoint!.getColumnData("OPS_MTDSLSMNT.NXT_MTD_CASH"))
	ops_mtdsales.nxt_mtd_cost=num(callpoint!.getColumnData("OPS_MTDSLSMNT.NXT_MTD_COST"))
	ops_mtdsales.nxt_mtd_disc=num(callpoint!.getColumnData("OPS_MTDSLSMNT.NXT_MTD_DISC"))
	ops_mtdsales.nxt_mtd_frgt=num(callpoint!.getColumnData("OPS_MTDSLSMNT.NXT_MTD_FRGT"))

	ars_mtdcash$=field(ars_mtdcash$)
	ops_mtdsales$=field(ops_mtdsales$)

	writerecord(ars_mtdcash_dev)ars_mtdcash$
	writerecord(ops_mtdsales_dev)ops_mtdsales$
[[OPS_MTDSLSMNT.ARAR]]
rem --- populate variables
	ops_mtdsales_dev=fnget_dev("OPS_MTDSALES")
	dim ops_mtdsales$:fnget_tpl$("OPS_MTDSALES")
	ars_mtdcash_dev=fnget_dev("ARS_MTDCASH")
	dim ars_mtdcash$:fnget_tpl$("ARS_MTDCASH")
	readrecord(ops_mtdsales_dev,key=firm_id$+"S",dom=*next)ops_mtdsales$
	readrecord(ars_mtdcash_dev,key=firm_id$+"C",dom=*next)ars_mtdcash$

	callpoint!.setColumnData("OPS_MTDSLSMNT.MTD_CASH",str(ars_mtdcash.mtd_cash))
	callpoint!.setColumnData("OPS_MTDSLSMNT.MTD_COST",str(ops_mtdsales.mtd_cost))
	callpoint!.setColumnData("OPS_MTDSLSMNT.MTD_CSH_DISC",str(ars_mtdcash.mtd_csh_disc))
	callpoint!.setColumnData("OPS_MTDSLSMNT.MTD_CSH_GL",str(ars_mtdcash.mtd_csh_gl))
	callpoint!.setColumnData("OPS_MTDSLSMNT.MTD_CSH_SALE",str(ops_mtdsales.mtd_csh_sale))
	callpoint!.setColumnData("OPS_MTDSLSMNT.MTD_DISCOUNT",str(ops_mtdsales.mtd_discount))
	callpoint!.setColumnData("OPS_MTDSLSMNT.MTD_FREIGHT",str(ops_mtdsales.mtd_freight))
	callpoint!.setColumnData("OPS_MTDSLSMNT.MTD_RETURNS",str(ops_mtdsales.mtd_returns))
	callpoint!.setColumnData("OPS_MTDSLSMNT.MTD_SALES",str(ops_mtdsales.mtd_sales))
	callpoint!.setColumnData("OPS_MTDSLSMNT.MTD_TAX",str(ops_mtdsales.mtd_tax))
	callpoint!.setColumnData("OPS_MTDSLSMNT.NMTD_CASHGL",str(ars_mtdcash.nmtd_cashgl))
	callpoint!.setColumnData("OPS_MTDSLSMNT.NMTD_CASHSL",str(ops_mtdsales.nmtd_cashsl))
	callpoint!.setColumnData("OPS_MTDSLSMNT.NMTD_CASH_DS",str(ars_mtdcash.nmtd_cash_ds))
	callpoint!.setColumnData("OPS_MTDSLSMNT.NMTD_RETURNS",str(ops_mtdsales.nmtd_returns))
	callpoint!.setColumnData("OPS_MTDSLSMNT.NMTD_SALES",str(ops_mtdsales.nmtd_sales))
	callpoint!.setColumnData("OPS_MTDSLSMNT.NMTD_TAX",str(ops_mtdsales.nmtd_tax))
	callpoint!.setColumnData("OPS_MTDSLSMNT.NXT_MTD_CASH",str(ars_mtdcash.nxt_mtd_cash))
	callpoint!.setColumnData("OPS_MTDSLSMNT.NXT_MTD_COST",str(ops_mtdsales.nxt_mtd_cost))
	callpoint!.setColumnData("OPS_MTDSLSMNT.NXT_MTD_DISC",str(ops_mtdsales.nxt_mtd_disc))
	callpoint!.setColumnData("OPS_MTDSLSMNT.NXT_MTD_FRGT",str(ops_mtdsales.nxt_mtd_frgt))
	callpoint!.setStatus("REFRESH")
[[OPS_MTDSLSMNT.BSHO]]
rem --- Open parameter tables
	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ops_mtdsales",open_opts$[1]="OTA"
	open_tables$[2]="ars_mtdcash",open_opts$[2]="OTA"
	gosub open_tables
	ops_mtdsales_dev=num(open_chans$[1]),ops_mtdsales$=open_tpls$[1]
	ars_mtdcash_dev=num(open_chans$[2]),ars_mtdcash$=open_tpls$[2]
