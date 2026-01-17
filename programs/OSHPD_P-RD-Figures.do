/*

- This program takes the coefficient estimates produced using the OSHPD_A RD programs, fits lines
based on the coefficient estimates, and adds the points from the RD collapse to produce RD figures.
It also pulls the RD estimate and adds it to the figure notes.

*/

* Preliminaries
set more off
clear all
graph drop _all
graph set window fontfaceserif Times

* Set current directory to results (which are reviewed and disclosed by OSHPD to allow us to take
* them off-site)
cd "/Users/kluender/Dropbox (MIT)/Health Insurance and Financial Protection/OSHPD_disclosures/aug20_2015/Output"
* Set location of pre-formatted excel table for output
local output "/Users/kluender/Dropbox (MIT)/Health Insurance and Financial Protection/February 2016 Results"
* Locate the Stata program which generates a nice name for the variable name (e.g. "Number of Collections 
* to Date" to replace z1a_num_coll_ever).
local varnames "/Users/kluender/Dropbox (MIT)/Health Insurance and Financial Protection/Off-Site Analysis/Nov2015 Do Files"

* Choose sample type(s) to produce figures for
local types = "er_admit"

* List variables to generate figures for
local z_coll2 "dz1a_num_coll_ever dz1a_num_med_coll_ever dz1a_num_nonmed_coll_ever"
local z_coll3 "dz1a_coll_bal dz1a_coll_bal_med dz1a_coll_bal_nonmed"
local z_eff "dz2a_any_bkrt_ever dz3a_cred_limit_v2 dz3a_credit_score"
local z_new "dz3a_num_auto_trades dz3a_auto_trade_balance dz2a_tot_bal_all_rev"
local list "`z_coll2' `z_coll3' `z_eff' `z_new'"

* Label the reference year relative to the hospitalization
local name1 "One Year"
local name4 "Four Years"

* Loop over reference year, sample, and variables
foreach post in 1 4 {
foreach type of local types {
foreach var in `list' {

* Set rounding for estimates in the notes separately for eaach outcome
if inlist("`var'", "dz2a_any_bkrt_ever", "dz1a_any_coll_ever", "dz1a_any_med_coll_ever", "dz1a_any_nonmed_coll_ever", "dz3a_has_credit_score") {
	local round = 4
}
else if inlist("`var'", "dz1a_coll_bal","dz1a_coll_bal_med", "dz1a_coll_bal_nonmed", "dz3a_credit_score", "dz3a_cred_limit_v2", "dz2a_tot_bal_all_rev", "dz3a_auto_trade_balance") {
	local round = 1
}
else {
	local round = 3
}

* Include nice variable names to replace variable names in data
include "`varnames'/Varnames.do"

* Pull in RD coefficient estimates
insheet using "RD_Baseline_`post'yrpost_coefs_`type'.txt" , clear

keep `var' var

tempfile coefficients
save `coefficients'

* Pull in RD standard error estimates from variance-covariance matrix
insheet using "RD_Baseline_`post'yrpost_ses_`type'.txt" , clear

keep `var' var
keep if var=="over65_over65"
replace `var' = sqrt(`var')

tempfile ses
save `ses'

* Pull in collapse data for the scatter points in the figure
insheet using "RD_Collapse_Means_`type'_W.txt", clear

local N = _N+1
set obs `N'

replace age = 64.99 if _n == _N
keep if age>60 & age<70

keep if y_diff==`post'
keep age `var'

* Bring everything together
append using `coefficients'
append using `ses'

* Send all coefficients into locals in order to calculate the line implied by the regression estimates
sum `var' if var=="age_centered"
local age_centered = r(mean)
sum `var' if var=="age_centered2"
local age_centered2 = r(mean)
sum `var' if var=="over65"
local over65 = r(mean)
sum `var' if var=="ageXover65"
local ageXover65 = r(mean)
sum `var' if var=="age2Xover65"
local age2Xover65 = r(mean)
sum `var' if var=="_cons"
local constant = r(mean)

* Normalize age
gen age_centered = age - 65
* Create lines implied by regression estimates
gen xb = `constant' + `age_centered'*age_centered + `age_centered2'*(age_centered^2)
	replace xb = xb + `over65' + `ageXover65'*age_centered + `age2Xover65'*(age_centered^2) if age_centered>=0

* Final formatting of the estimates in the notes
local mean: di %5.`round'f `over65'
sum `var' if var=="over65_over65"
local se: di %5.`round'f r(mean)

* Drop everything we don't want to plot
keep if !missing(age)

 * Plot and save RD figures
 twoway /// 
   (scatter `var' age, msize(medsmall) scheme(s2mono)) ///
   (connected xb age if age < 65, msymbol(i) lwidth(thick) lpattern(dash) lcolor(maroon)) ///
   (connected xb age if age >= 65, msymbol(i) lwidth(thick) lpattern(dash) lcolor(maroon) ///
   title("`varname'") graphregion(fcolor(white)) ylabel(,nogrid) ///
   caption("RD Estimate: `mean' (`se')") ///
   legend(off) xtitle("Age at Hospitalization") ytitle(""))
 graph export "`output'/RD_`post'yearpost_`type'_`var'.`filetype'", replace	
 
} // end var loop

} // end type loop 

} // post




























