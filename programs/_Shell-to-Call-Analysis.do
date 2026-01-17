/*

- This is a shell file we use to call the analysis programs with an "include" statement
- The include statement allows us to feed the program locals (as opposed to "do")
- This allows us to run many programs in succession to maximize efficiency

*/

* 25-64 Insured
local sample "pv_plus_mc"
local samp "INS" 
local data "pdd_TU_25to64_Aug2015.dta" 
local data_name "UB"
local z_num "z1a_num_coll_ever z1a_num_med_coll_ever z1a_num_nonmed_coll_ever"
local z_bal "z1a_coll_bal z1a_coll_bal_med z1a_coll_bal_nonmed"
local z_cred "z2a_tot_bal_all_rev z3a_cred_limit_v2 z3a_cred_limit_obs z3a_credit_score"
local z_eff "z3a_num_auto_trades z3a_auto_trade_balance z2a_any_bkrt_ever z2a_any_bkrt_12m"
local outcomes "`z_num' `z_bal' `z_cred' `z_eff'"
local weight "represents_exact"
local weight_name "RE"
include "C:\Research\Health Insurance and Financial Protection\2. Analysis August 20 2015\Programs\OSHPD_A Summary Stats.do"
include "C:\Research\Health Insurance and Financial Protection\2. Analysis August 20 2015\Programs\OSHPD_A NonPar Event Study.do"
include "C:\Research\Health Insurance and Financial Protection\2. Analysis August 20 2015\Programs\OSHPD_A Par Event Study.do"

* 25-64 Uninsured
local sample "self_pay"
local samp "SP" 
local data "pdd_TU_25to64_Aug2015.dta" 
local data_name "UB"
local z_num "z1a_num_coll_ever z1a_num_med_coll_ever z1a_num_nonmed_coll_ever"
local z_bal "z1a_coll_bal z1a_coll_bal_med z1a_coll_bal_nonmed"
local z_cred "z2a_tot_bal_all_rev z3a_cred_limit_v2 z3a_cred_limit_obs z3a_credit_score"
local z_eff "z3a_num_auto_trades z3a_auto_trade_balance z2a_any_bkrt_ever z2a_any_bkrt_12m"
local outcomes "`z_num' `z_bal' `z_cred' `z_eff'"
local weight "represents_exact"
local weight_name "RE"
include "C:\Research\Health Insurance and Financial Protection\2. Analysis August 20 2015\Programs\OSHPD_A Summary Stats.do"
include "C:\Research\Health Insurance and Financial Protection\2. Analysis August 20 2015\Programs\OSHPD_A NonPar Event Study.do"
include "C:\Research\Health Insurance and Financial Protection\2. Analysis August 20 2015\Programs\OSHPD_A Par Event Study.do"

* 65+
local sample "freq"
local samp "65plus" 
local data "pdd_TU_65plus_Aug2015.dta" 
local data_name "UB"
local z_num "z1a_num_coll_ever z1a_num_med_coll_ever z1a_num_nonmed_coll_ever"
local z_bal "z1a_coll_bal z1a_coll_bal_med z1a_coll_bal_nonmed"
local z_cred "z2a_tot_bal_all_rev z3a_cred_limit_v2 z3a_cred_limit_obs z3a_credit_score"
local z_eff "z3a_num_auto_trades z3a_auto_trade_balance z2a_any_bkrt_ever z2a_any_bkrt_12m"
local outcomes "`z_num' `z_bal' `z_cred' `z_eff'"
local weight "represents_exact"
local weight_name "RE"
include "C:\Research\Health Insurance and Financial Protection\2. Analysis August 20 2015\Programs\OSHPD_A Summary Stats.do"
include "C:\Research\Health Insurance and Financial Protection\2. Analysis August 20 2015\Programs\OSHPD_A NonPar Event Study.do"
include "C:\Research\Health Insurance and Financial Protection\2. Analysis August 20 2015\Programs\OSHPD_A Par Event Study.do"


* ... many other shell files were produced to run all of the various subsamples, but they all follow this template















