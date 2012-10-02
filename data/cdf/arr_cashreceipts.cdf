[[ARR_CASHRECEIPTS.BSHO]]
rem --- see if batching

call stbl("+DIR_PGM")+"adc_getbatch.aon",callpoint!.getAlias(),"",table_chans$[all]
