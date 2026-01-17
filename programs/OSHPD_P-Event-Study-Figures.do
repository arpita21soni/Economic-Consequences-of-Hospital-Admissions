/*

- This program takes the coefficient estimates produced using the OSHPD_A event study programs, 
fits lines based on the coefficient estimates, and adds the points from the non-parametric
event study specification to produce the event study figures. 
It also pulls the pre-hospitalization mean and adds it to the figure notes.

*/

* Preliminaries
set more off
clear all
graph drop _all
graph set window fontfaceserif Times
local filetype "pdf"

* Set current directory to results (which are reviewed and disclosed by OSHPD to allow us to take
* them off-site)
cd "/Users/kluender/Dropbox (MIT)/Health Insurance and Financial Protection/OSHPD_disclosures/aug20_2015/Output"
* Set location of pre-formatted excel table for output
local output "/Users/kluender/Dropbox (MIT)/Health Insurance and Financial Protection/February 2016 Results"
* Locate the Stata program which generates a nice name for the variable name (e.g. "Number of Collections 
* to Date" to replace z1a_num_coll_ever).
local varnames "/Users/kluender/Dropbox (MIT)/Health Insurance and Financial Protection/Off-Site Analysis/Nov2015 Do Files"

* List variables to generate figures for
local z_num "z1a_num_coll_ever z1a_num_med_coll_ever z1a_num_nonmed_coll_ever"
local z_bal "z1a_coll_bal z1a_coll_bal_med z1a_coll_bal_nonmed"
local z_cred "z2a_tot_bal_all_rev z3a_cred_limit_v2 z3a_cred_limit_obs z3a_credit_score"
local z_eff "z3a_num_auto_trades z3a_auto_trade_balance z2a_any_bkrt_ever"
local list "`z_num' `z_bal' `z_cred' `z_eff'"

* Choose sample type(s) to produce figures for and relabel variables with sample prefix
local INS_rename I
local SP_rename S
local 65plus_rename E
local samples "INS SP 65plus"
local letters "I S E"

* Label sample in the figures
local In "Insured [Baseline]"
local Sn "Uninsured [Baseline]"
local En "Elderly [Baseline]"

**************************************************************
* Pull in pre-hospitalization means and save for graph notes *
**************************************************************
foreach samp in `samples' {
		
	insheet using "SumStats_`samp'_UB_RE.txt", clear
	
	keep if statistic=="mean"
	gen var = "prehosp_mean"
	gen diff = .
		
	tempfile prehosp_``samp'_rename'
	save `prehosp_``samp'_rename''
	
}

* CLEAN EVENT STUDY COEFFICIENTS
foreach samp in `samples' {

	* Pull in data
	insheet using "ES_post`post'_yrFEs_coefs_`samp'_UB_RE.txt", clear

	* Clean up the data and prep for graphs
	gen samp="`samp'"
	foreach var in `list' {
		sum `var' if regexm(var,"_cons")
		local ``samp'_rename'c`var' = r(mean)
	}
	keep if regexm(var, "evt")==1
	replace var=substr(var, 3, .) if regexm(var, "z_")==1
	replace var=substr(var, 5, .) 
	replace var=regexr(var, "f", "-")
	replace var=regexr(var, "l", "")
	destring var, gen(diff)
	moreobs
	replace diff = -1 if missing(diff)
	foreach var in `list' {
		replace `var' = 0 if diff==-1
	}
	
	* Append pre-hospilization means to event study outcome
	desc `list', varlist
	di "`r(varlist)'"
	local list `r(varlist)'
	keep diff `list'
	append using `prehosp_``samp'_rename'', keep(diff var `list')
	
	sort diff
	
	* Rename variables with the sample prefix to differentiate
	foreach var of varlist `list' {
		rename `var' ``samp'_rename'`var'
	}	
	
	tempfile es_`samp'
	save `es_`samp''
	
	* Pull in spline coefficients
	insheet using "Splines_post`post'_YrFEs_coefs_`samp'_UB_RE.txt", clear

	foreach var of varlist `list' {
		rename `var' ``samp'_rename'`var'
	}
	
	tempfile spline_`samp'
	save `spline_`samp''

}  // samp

* Merge outcomes for all samples back together (program is structured this way to allow for
* overlayed figured, which we didn't end up including in the paper)
use `es_INS', clear
foreach samp in `samples' {
	di "`samp'"
	merge 1:1 diff using `es_`samp'', nogen assert(match)
}	
foreach samp in `samples' {
	append using `spline_`samp''
}

foreach var in `list' {

* Set nicer variable names for titles
include "`varnames'/Varnames.do"

* Loop over samples
foreach s in `letters' {

	* Read pre-hospitalization means into local
	sum `s'`var' if diff~=.
	local `s'max=r(max)*.9
	local `s'min=r(min)*1.1
	sum `s'`var' if var=="prehosp_mean"
	
	* Round pre-hospitalization means to appropriate level based on outcome
	if inlist("`var'", "z1a_coll_bal", "z1a_coll_bal_med", "z1a_coll_bal_nonmed", "z3a_credit_score", "z3a_cred_limit_v2", "z2a_tot_bal_all_rev", "z3a_auto_trade_balance") {
		local `s'pre = round(r(mean), 1)
	}
	else {
		local `s'pre = round(r(mean),0.01)
	}
	
	* Check on rounding
	di "``s'pre'"
	local `s'pre = substr(string(``s'pre'), 1, 8)
	di "``s'pre'"
	
	* FIT SPLINES USING COEFFICIENTS FROM MICRO REGRESSION
	* Medical and non-medical collection balances
	if ("`var'"=="z1a_coll_bal_med"|"`var'"=="z1a_coll_bal_nonmed") {
	
		sum `s'`var' if regexm(var,"_cons")
		local cons2_`var' = r(mean)
		local shift = `cons2_`var'' - ``s'c`var''
		sum `s'`var' if regexm(var,"diff1alt")
		local diff1 = r(mean)
		sum `s'`var' if regexm(var,"diff2")
		local diff2 = r(mean)	
		sum `s'`var' if regexm(var,"diff3")
		local diff3 = r(mean)	
		sum `s'`var' if regexm(var,"k1")
		local k1 = r(mean)		
		sum `s'`var' if regexm(var,"k2")
		local k2 = r(mean)				
		
		gen `s'p`var' = `shift'+diff*`diff1' if diff>-36
			replace `s'p`var' = `s'p`var' + `diff2'*(diff^2) + `diff3'*(diff^3) if diff>0
			replace `s'p`var' = `s'p`var' + `k1'*((diff-12)^3) if diff>12
			replace `s'p`var' = `s'p`var' + `k2'*((diff-24)^3) if diff>24
	
	}
	
	* All other variables
	else {

		sum `s'`var' if regexm(var,"_cons")
		local cons2_`var' = r(mean)
		local shift = `cons2_`var'' - ``s'c`var''
		sum `s'`var' if regexm(var,"diff1")
		local diff1 = r(mean)
		sum `s'`var' if regexm(var,"diff2")
		local diff2 = r(mean)	
		sum `s'`var' if regexm(var,"diff3")
		local diff3 = r(mean)	
		sum `s'`var' if regexm(var,"k1")
		local k1 = r(mean)		
		sum `s'`var' if regexm(var,"k2")
		local k2 = r(mean)				
		
		gen `s'p`var' = `shift'+diff*`diff1'
			replace `s'p`var' = `s'p`var' + `diff2'*(diff^2) + `diff3'*(diff^3) if diff>0
			replace `s'p`var' = `s'p`var' + `k1'*((diff-12)^3) if diff>12
			replace `s'p`var' = `s'p`var' + `k2'*((diff-24)^3) if diff>24
	
	} // else
	
} // s

* Loop over samples to produce figures
foreach s in `letters' {

		twoway (scatter `s'`var' diff, scheme(s2mono)) ///
		  (line `s'p`var' diff, lcolor(maroon) lwidth(thick) lpattern(longdash)) if diff<=48,  ///
		  xline(0, lc(gs11)) xlabel(-48(12)48) ///
		  ytitle("") xtitle("") ///
		  title("`varname'" "``s'n'") leg(off) ///
		  xtitle("Months since Hospitalization") ///
		  graphregion(fcolor(white)) ylabel(,nogrid) ///
		  caption("Pre-Hospitalization Mean = ``s'pre'")
		 graph export "`output'/ES_`var'_`s'.`filetype'", replace		
	
} // s
	
graph drop _all

} // var		

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

