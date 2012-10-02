rem ----------------------------------------------------------------------------
rem Program: SFHARDCOPYClsdDet.prc
rem Description: Stored Procedure to get the Shop Floor Hard Copy WO Close Detail into iReports
rem Used for Hard Copy, Traveler, Work Order Closed Detail and Work Order Detail
rem
rem Author(s): C. Johnson
rem Revised: 05.01.2012
rem
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------
	
rem --- Set of utility methods

	use ::ado_func.src::func

rem --- Declare some variables ahead of time

	declare BBjStoredProcedureData sp!
	declare BBjRecordSet rs!
	declare BBjRecordData data!

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get the IN parameters used by the procedure

	firm_id$    = sp!.getParameter("FIRM_ID")
	wo_loc$     = sp!.getParameter("WO_LOCATION")
	wo_no$      = sp!.getParameter("WO_NO")
	barista_wd$ = sp!.getParameter("BARISTA_WD")
	masks$      = sp!.getParameter("MASKS")
	
rem ---
	
	sv_wd$=dir("")
	chdir barista_wd$

rem --- Create a memory record set to hold results.
rem --- Columns for the record set are defined using a string template

	      temp$="CLOSED_DATE:C(1*), WO_TYPE:C(1*), WO_TYPE_DESC:C(1*), "
	temp$=temp$+"LSTACT_DATE:C(1*), LSTACT_DATE_RAW:C(1*), CLS_INP_DATE_RAW:C(1*), "
	temp$=temp$+"COMPLETE_YN:C(1*), CLOSE_AT_STD_ACT:C(1*), "
	temp$=temp$+"CURR_PROD_QTY:C(1*), PRIOR_CLSD_QTY:C(1*), THIS_CLOSE_QTY:C(1*), "
	temp$=temp$+"BAL_STILL_OPEN_QTY:C(1*), IV_UNIT_COST:C(1*), WO_COST_AT_STD:C(1*), "
	temp$=temp$+"WO_COST_AT_ACT:C(1*), PRIOR_CLOSED_AMT:C(1*), CURR_WIP_VALUE:C(1*), "
	temp$=temp$+"CURR_CLOSE_VALUE:C(1*), "

	rem -- GL
	temp$=temp$+"WIP_GL_ACCT_NUM:C(1*), WIP_GL_ACCT_DESC:C(1*), WIP_GL_ACCT_TYPE:C(1*), "
	temp$=temp$+"WIP_GL_DEBIT_AMT:C(1*), WIP_GL_CREDIT_AMT:C(1*), WIP_GL_DEBIT_PERUNIT:C(1*), "
	temp$=temp$+"WIP_GL_CREDIT_PERUNIT:C(1*), "
	
	temp$=temp$+"CLS_To_GL_ACCT_NUM:C(1*), CLS_To_GL_ACCT_DESC:C(1*), CLS_To_GL_ACCT_TYPE:C(1*), "
	temp$=temp$+"CLS_To_GL_DEBIT_AMT:C(1*), CLS_To_GL_CREDIT_AMT:C(1*), CLS_To_GL_DEBIT_PERUNIT:C(1*), "
	temp$=temp$+"CLS_To_GL_CREDIT_PERUNIT:C(1*), "
	
	temp$=temp$+"DIR_VAR_GL_ACCT_NUM:C(1*), DIR_VAR_GL_ACCT_DESC:C(1*), DIR_VAR_GL_ACCT_TYPE:C(1*), "
	temp$=temp$+"DIR_VAR_GL_DEBIT_AMT:C(1*), DIR_VAR_GL_CREDIT_AMT:C(1*), DIR_VAR_GL_DEBIT_PERUNIT:C(1*), "
	temp$=temp$+"DIR_VAR_GL_CREDIT_PERUNIT:C(1*), "
	
	temp$=temp$+"OVRH_VAR_GL_ACCT_NUM:C(1*), OVRH_VAR_GL_ACCT_DESC:C(1*), OVRH_VAR_GL_ACCT_TYPE:C(1*), "
	temp$=temp$+"OVRH_VAR_GL_DEBIT_AMT:C(1*), OVRH_VAR_GL_CREDIT_AMT:C(1*), OVRH_VAR_GL_DEBIT_PERUNIT:C(1*), "
	temp$=temp$+"OVRH_VAR_GL_CREDIT_PERUNIT:C(1*), "
	
	temp$=temp$+"MAT_VAR_GL_ACCT_NUM:C(1*), MAT_VAR_GL_ACCT_DESC:C(1*), MAT_VAR_GL_ACCT_TYPE:C(1*), "
	temp$=temp$+"MAT_VAR_GL_DEBIT_AMT:C(1*), MAT_VAR_GL_CREDIT_AMT:C(1*), MAT_VAR_GL_DEBIT_PERUNIT:C(1*), "
	temp$=temp$+"MAT_VAR_GL_CREDIT_PERUNIT:C(1*), "
	
	temp$=temp$+"SUB_VAR_GL_ACCT_NUM:C(1*), SUB_VAR_GL_ACCT_DESC:C(1*), SUB_VAR_GL_ACCT_TYPE:C(1*), "
	temp$=temp$+"SUB_VAR_GL_DEBIT_AMT:C(1*), SUB_VAR_GL_CREDIT_AMT:C(1*), SUB_VAR_GL_DEBIT_PERUNIT:C(1*), "
	temp$=temp$+"SUB_VAR_GL_CREDIT_PERUNIT:C(1*)"
	
	rs! = BBJAPI().createMemoryRecordSet(temp$)

rem --- Get Barista System Program directory

	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)
	pgmdir$=stbl("+DIR_PGM",err=*next)
	
rem --- Get masks
	
	gl_acct_mask$=fngetmask$("gl_acct_mask","000-000",masks$)		
				
rem --- TEMPORARILY HARDCODED FOR iReport layout development <<======================
CLOSED_DATE$ = "06/15/2012"
WO_TYPE$ = "01"
WO_TYPE_DESC$ = "Standard WO Type"
LSTACT_DATE_RAW$= "20120613"
CLS_INP_DATE_RAW$= "20130512"
CURR_PROD_QTY = 20
PRIOR_CLSD_QTY = 20
THIS_CLOSE_QTY = 5
BAL_STILL_OPEN_QTY = 0
COMPLETE_YN$ = "Y"
IV_UNIT_COST = 285.89
WO_COST_AT_STD = 4881.8
CLOSE_AT_STD_ACT$ = "S"
WO_COST_AT_ACT = 0
PRIOR_CLOSED_AMT = 4881.8
CURR_WIP_VALUE = -4881.8
CURR_CLOSE_VALUE = 0
GL_ACCT_NUM$ = "12500110"
GL_ACCT_DESC$ = "Work In Process"
GL_DEBIT_AMT = 4881.8
GL_CREDIT_AMT = 0
GL_DEBIT_PERUNIT = 0
GL_CREDIT_PERUNIT = 0
GL_ACCT_TYPE$ = "WIP"

GOTO CAJESCAPE_SEND_DATE; REM CAJ ESCAPE testing

rem ===================================================================================
        if sfe01a.wo_category$="I" then
            find record (ivm01a_dev,key=firm_id$+sfe01a.item_id$,dom=label1) ivm01a$
            if ars01a.DIST_BY_ITEM$<>"Y" then
                gl_inventory_acct$=ivm01a.gl_inv_acct$
            else
                find record (ivm02a_dev,key=firm_id$+sfe01a.warehouse_id$+sfe01a.item_id$,dom=label1) ivm02a$
                distribution_code$=ivm02a.ar_dist_code$
                find record (arm10d_dev,key=firm_id$+"D"+distribution_code$,dom=label1) arm10d$
                gl_inventory_acct$=arm10d.gl_inv_acct$; rem "Set the closed to account...
            endif
        endif

label1:
******************
        sfm10a.code_desc$="*** Not On File ***"
        find record (sfm10a_dev,key=firm_id$+"A"+sfe01a.wo_type$,dom=*next) sfm10a$
        if sfe01a.wo_category$="I" then 
            sfm10a.gl_close_to$=gl_inventory_acct$
        endif
		
		
        print (printer_dev)'lf',"**** Closed Detail ****",
:                       @(29),"Closed Date: ",fndate$(sfe01a.cls_inp_date$),
:                       @(55),"WO Type: ",sfm10a.code_desc$,
        if sfe01a.lstact_date$>sfe01a.cls_inp_date$ then
            print (printer_dev)@(89),"***Warning Last Activity Was ",fndate$(sfe01a.lstact_date$),"***",
        endif
		

        if ivm01a.msrp<>0 and ivm01a.msrp<>1 then
            b0=ivm01a.order_point
            if ivm01a.conv_factor<>0 then 
                b1=ivm01a.safety_stock/ivm01a.conv_factor 
                b2=ivm01a.eoq/ivm01a.conv_factor 
            else 
                b1=0
                b2=0
            endif
            if ivm01a.weight<>0 then 
                b3=ivm01a.lead_time/ivm01a.weight 
            else 
                b3=0
            endif
            if ivm01a.msrp+ivm01a.maximum_qty<>0 then 
                b4=ivm01a.reserved_num/(ivm01a.msrp+ivm01a.maximum_qty) 
            else 
                b4=0
            endif
            if ivm01a.msrp<>0 then 
                b5=ivm01a.dealer_num/ivm01a.msrp 
            else 
                b5=0
            endif
            print (printer_dev)@(36),"Per Unit:",@(60-m3),b0:m3$,@(73-m3),b1:m3$,
:                          @(75),stdact_flag$,@(91-m3),b2:m3$,@(105-m3),b3:m3$,
:                          @(119-m3),b4:m3$,@(132-m3),b5:m3$,
        endif

rem --- Calculate Postings

        c[0]=-ivm01a.reserved_num
        c[1]=sfe01a.cls_inp_qty*sfe01a.closed_cost

        if sfe01a.complete_flg$<>"Y"
            c[0]=-c[1]
        else
            if sfm10a.std_act_flag="A" then
                c[1]=ivm01a.reserved_num
            else
rem --- Calculate Variance Postings
                if sfe01a.wo_category$<>"I" and (sfe01a.sch_prod_qty=sfe01a.qty_cls_todt+sfe01a.cls_inp_qty or u[0]=0 or sfe01a.recalc_flag$="N") then
                    prorte=sfe01a.cls_inp_qty*sfe01a.closed_cost+sfe01a.cls_cst_todt
                else
rem --- Prorate Standards If Needed
                    if sfe01a.wo_category$<>"I"
                        if sfe01a.sch_prod_qty<>0 then
                            prorte=u[0]*(sfe01a.qty_cls_todt+sfe01a.cls_inp_qty)/sfe01a.sch_prod_qty
                        else
                            prorte=0
                        endif
                    else
                        prorte=sfe01a.cls_inp_qty*sfe01a.closed_cost+sfe01a.cls_cst_todt
                    endif

                    if prorte<>u[0] then
                        if u[0]=0 then
                            u[3]=0,u[4]=0,u[6]=0
                        else
                            u[3]=u[3]*prorte/u[0]
                            u[4]=u[4]*prorte/u[0]
                            u[6]=u[6]*prorte/u[0]
                        endif
                        u[9]=prorte-(u[3]+u[4]+u[6])
                    endif
                endif
rem --- Now Calculate Variances
                precision 2
                c[2]=(u[2]-u[3])*1
                c[4]=(u[5]-u[4])*1,c[5]=(u[7]-u[6])*1
                c[3]=(ivm01a.eoq-prorte-(c[2]+c[4]+c[5]))*1
                c[0]=c[0]*1
                c[1]=c[1]*1
            endif
        endif

rem --- Print G/L Postings

        precision ivs01_precision
        if gl$="Y"
            print (printer_dev)'lf',"Account Summary: ",@(44+m1),"Debit",@(46+m1*2),"Credit",
            if sfe01a.cls_inp_qty<>0 and sfe01a.cls_inp_qty<>1
                print (printer_dev)@(60+m1*2),"Per Unit Totals",'lf'
            else
                print (printer_dev)'lf'
            endif

            t0=0
            t1=0,t2=0,t3=0

            for x=0 to 5
                if c[x]=0 then continue
                dim g1$(35)
                g1$(1)="*** Not On File ***"
                if x<2 then
                    g9$=sfm10a.gl_close_to$
                else
                    g9$=sfm10a.gl_pur_acct$
                endif

                find (glm01a_dev,key=firm_id$+g9$,dom=*next)*,g1$(1)
                print (printer_dev)fnmask$(g9$(1,g3),g3$),"  ",g1$,

                if c[x]>0 then
                    print (printer_dev)@(50),c[x]:m1$,
                    t0=t0+c[x]
                else
                    print (printer_dev)@(53+m1),abs(c[x]):m1$,
                    t1=t1+abs(c[x])
                endif
                if sfe01a.cls_inp_qty<>0 and sfe01a.cls_inp_qty<>1 then
                    if c[x]/sfe01a.cls_inp_qty>0 then
                        print (printer_dev)@(56+m1*2),c[x]/sfe01a.cls_inp_qty:m3$,
                        t2=t2+c[x]/sfe01a.cls_inp_qty
                    else
                        print (printer_dev)@(59+m1*2+m3),abs(c[x]/sfe01a.cls_inp_qty):m3$,
                        t3=t3+abs(c[x]/sfe01a.cls_inp_qty)
                    endif
                endif
                print (printer_dev)@(110),y9$(x*21+1,21)
            next x

            print (printer_dev)@(50),j$(1,m1),@(53+m1),j$(1,m1),
            if sfe01a.cls_inp_qty<>0 and sfe01a.cls_inp_qty<>1 then
                print (printer_dev)@(56+m1*2),j$(1,m3),@(59+m1*2+m3),j$(1,m3),
            endif
            print (printer_dev)'lf',@(40),"Total: ",@(50),t0:m1$,@(53+m1),t1:m1$,
            if sfe01a.cls_inp_qty<>0 and sfe01a.cls_inp_qty<>1 then
                print (printer_dev)@(56+m1*2),t2:m3$,@(59+m1*2+m3),t3:m3$,
            endif
            print (printer_dev)""
        endif
    wend

done: rem --- End

    goto std_exit
LSTACT_DATE_RAW$= "20120613"
CLS_INP_DATE_RAW$= "20120512"
rem ===================================================================================
rem --- Print totals
CAJESCAPE_SEND_DATE:
	data! = rs!.getEmptyRecordData()
	data!.setFieldValue("CLOSED_DATE",fndate$(closed_date$))
	data!.setFieldValue("WO_TYPE",wo_type$)
	data!.setFieldValue("WO_TYPE_DESC",wo_type_desc$)
	data!.setFieldValue("LSTACT_DATE",fndate$(lstact_date_raw$))
	data!.setFieldValue("LSTACT_DATE_RAW",lstact_date_raw$)	
	data!.setFieldValue("CLS_INP_DATE_RAW",cls_inp_date_raw$)
	
	data!.setFieldValue("CURR_PROD_QTY",str(curr_prod_qty))
	data!.setFieldValue("PRIOR_CLSD_QTY",str(prior_clsd_qty))
	data!.setFieldValue("THIS_CLOSE_QTY",str(this_close_qty))
	data!.setFieldValue("BAL_STILL_OPEN_QTY",str(bal_still_open_qty))
	
	data!.setFieldValue("COMPLETE_YN",complete_yn$)

	data!.setFieldValue("IV_UNIT_COST",str(iv_unit_cost))
	data!.setFieldValue("WO_COST_AT_STD",str(wo_cost_at_std))

	data!.setFieldValue("CLOSE_AT_STD_ACT",close_at_std_act$)

	data!.setFieldValue("WO_COST_AT_ACT",str(wo_cost_at_act))
	data!.setFieldValue("PRIOR_CLOSED_AMT",str(prior_closed_amt))
	data!.setFieldValue("CURR_WIP_VALUE",str(curr_wip_value))
	data!.setFieldValue("CURR_CLOSE_VALUE",str(curr_close_value))

	rem --- GL
	rem 	The accounts (Logic in iReports to print if all amts not-zero):
	rem			Work in Process
	rem			Close to Account
	rem			Direct Variance
	rem 		Overhead Variance
	rem			Material Variance
	rem			Subcontract Variance
	
	for x = 0 to 5
		switch x
			case 0
				AcctAbrv$ = "WIP_";      rem Work in Process
			break
			case 1	
				AcctAbrv$ = "CLS_To_";   rem Close to Account
			break
			case 2
				AcctAbrv$ = "DIR_VAR_";  rem Direct Variance
			break
			case 3	
				AcctAbrv$ = "OVRH_VAR_"; rem Overhead Variance
			break
			case 4
				AcctAbrv$ = "MAT_VAR_";  rem Material Variance
			break
			case 5	
				AcctAbrv$ = "SUB_VAR_";  rem Subcontract Variance
			break
		swend

		
		data!.setFieldValue(AcctAbrv$+"GL_ACCT_NUM",fnmask$(gl_acct_num$,gl_acct_mask$))
		data!.setFieldValue(AcctAbrv$+"GL_ACCT_DESC",gl_acct_desc$)
		
		data!.setFieldValue(AcctAbrv$+"GL_DEBIT_AMT",str(gl_debit_amt))
		data!.setFieldValue(AcctAbrv$+"GL_CREDIT_AMT",str(gl_credit_amt))
		data!.setFieldValue(AcctAbrv$+"GL_DEBIT_PERUNIT",str(gl_debit_perunit))
		data!.setFieldValue(AcctAbrv$+"GL_CREDIT_PERUNIT",str(gl_credit_perunit))
		
		data!.setFieldValue(AcctAbrv$+"GL_ACCT_TYPE",gl_acct_type$)
	
	next x
	

	rs!.insert(data!)
	
rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit

rem --- Subroutines
		
rem --- Functions

rem --- Format inventory item description

	def fnitem$(q$,q1,q2,q3)
		q$=pad(q$,q1+q2+q3)
		return cvs(q$(1,q1)+" "+q$(q1+1,q2)+" "+q$(q1+q2+1,q3),32)
	fnend

rem --- Date/time handling functions

    def fndate$(q$)
        q1$=""
        q1$=date(jul(num(q$(1,4)),num(q$(5,2)),num(q$(7,2)),err=*next),err=*next)
        if q1$="" q1$=q$
        return q1$
    fnend
    
    def fnyy$(q$)=q$(3,2)
    def fnclock$(q$)=date(0:"%hz:%mz %p")
    def fntime$(q$)=date(0:"%Hz%mz")
    def fnh$(q1$)=q1$(5,2)+"/"+q1$(1,4)

rem --- fnmask$: Alphanumeric Masking Function (formerly fnf$)

    def fnmask$(q1$,q2$)
        if q2$="" q2$=fill(len(q1$),"0")
        return str(-num(q1$,err=*next):q2$,err=*next)
        q=1
        q0=0
        while len(q2$(q))
              if pos(q2$(q,1)="-()") q0=q0+1 else q2$(q,1)="X"
              q=q+1
        wend
        if len(q1$)>len(q2$)-q0 q1$=q1$(1,len(q2$)-q0)
        return str(q1$:q2$)
    fnend

	def fngetmask$(q1$,q2$,q3$)
		rem --- q1$=mask name, q2$=default mask if not found in mask string, q3$=mask string from parameters
		q$=q2$
		if len(q1$)=0 return q$
		if q1$(len(q1$),1)<>"^" q1$=q1$+"^"
		q=pos(q1$=q3$)
		if q=0 return q$
		q$=q3$(q)
		q=pos("^"=q$)
		q$=q$(q+1)
		q=pos("|"=q$)
		q$=q$(1,q-1)
		return q$
	fnend



	std_exit:
	
	end
