***********************************************************
* _Shell file to run all the analysis files ("HRS_A ...") *
***********************************************************

/*

- This file uses "include" statements which allows the shell file to pass through locals
with variable lists, sample selection details (which panel, non-elderly versus elderly, etc.),
specification details (primarily which set of fixed effects to include) in order to avoid 
having to run each analysis file individually
- If you want to run one program in particular, you can add the locals to the top of the file
or you can comment out the other analysis files called in this shell. This shell runs virtually
everything from the HRS that is included in the paper.
- These files generally output regression coefficients, summary statistics, and/or implied
effects based on the regression coefficients (using linear combinations of the regression
coefficients), but there are additional files "HRS_P ..." which format the output into the tables
and figures shown in the paper.

*/


* PRELIMINARIES
cap log close
clear all
set more off, perm
set matsize 5000
set maxvar 32767

* Set directory to the location of the replication kit data folder
cd "/Users/kluender/Desktop/DFKN Replication Kit/HRS/Data"
* Set output location
local output "../Output"
* Set programs location
local programs "../Programs"

* Log all analysis
log using "`output'/BigLog.log", replace

* SUMMARY STATISTICS FOR ALL SAMPLES
local samples "under60_INS over65 age60to64_INS under65_INS under60_control over65_control under60_death over65_death under65_INS_nopre over65_nopre"
local spouses "freq"
local fes "cohortXwave"
local specs "freq"
local outcomes "oop_spend age_hosp working riearnsemp siearnsemp hgovt hitot_old log_hitot_old hitot_inc hitot_exc log_hitot_inc log_hitot_exc riearn_c"

include "`programs'/HRS_A Summary Statistics.do"

* MAIN OUTCOMES FOR ALL SPECIFICATIONS FOR TWO PRIMARY SAMPLES
local samples "under60_INS over65"
local spouses "freq prehosp_spouse spouse_zero"
local fes "wave hhidpn cohortXwave"
local specs "freq bal"
local outcomes "oop_spend age_hosp working riearnsemp siearnsemp hgovt hitot_old log_hitot_old hitot_inc hitot_exc log_hitot_inc log_hitot_exc riearn_c"

include "`programs'/HRS_A Summary Statistics.do"
include "`programs'/HRS_A Event Study.do"
include "`programs'/HRS_A PrePost Event Study.do"

* POISSON REGRESSIONS
local samples "under60_INS over65"
local spouses "freq"
local specs "freq bal"
local fes "cohortXwave"
local outcomes "oop_spend working riearnsemp siearnsemp rgovt hgovt hitot_old hitot_inc hitot_exc riearn_c"
include "/Users/kluender/Dropbox (MIT)/Health Insurance and Financial Protection/HRS/Programs/HRS_A ES Poisson.do"
include "/Users/kluender/Dropbox (MIT)/Health Insurance and Financial Protection/HRS/Programs/HRS_A PrePost Poisson.do"

* FULL SET OF OUTCOMES FOR MAIN SAMPLES
local samples "under60_INS over65 age60to64_INS under65_INS"
local spouses "freq"
local fes "cohortXwave"
local specs "freq"
local outcomes1 "spouse oop_spend riearnsemp siearnsemp hgovt hitot_old log_hitot_old hitot_inc hitot_exc log_hitot_inc log_hitot_exc"
local outcomes2 "working working_ft working_pt unemployed partly_retired retired disabled not_in_lbrf health_limited"
local outcomes3 "a_riearnsemp riearnsemp_c riearn_c risemp_c rgovt ripena hipena hicap_une hiothr hatota a_hssall rssall sssall hssall"
local outcomes4 "a_hgovt a_hisdi hisdi a_hissi hissi a_hiunem hiunem a_hisret hisret annual_hours log_rwgihr died_nextwave"
local outcomes `outcomes1' `outcomes2' `outcomes3' `outcomes4'
include "`programs'/HRS_A Summary Statistics.do"
include "`programs'/HRS_A Event Study.do"
include "`programs'/HRS_A PrePost Event Study.do"

* ROBUSTNESS SPECIFICATIONS WITH ADDED CONTROLS
local outcomes "oop_spend working riearnsemp siearnsemp hgovt hitot_old risemp log_hitot_old died_nextwave hitot_inc hitot_exc log_hitot_inc log_hitot_exc"
local fes "cohortXwave"
include "`programs'/HRS_A PrePost ES Alt Controls.do"
include "`programs'/HRS_A Event Study Alt Controls.do"


