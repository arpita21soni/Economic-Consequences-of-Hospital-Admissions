/*

- This program takes the implied effects and coefficient estimates produced using the OSHPD_A
files, appends and formats them, and outputs them to a pre-formatted Excel table

*/

* Preliminaries
set more off
clear all

* Set current directory to results (which are reviewed and disclosed by OSHPD to allow us to take
* them off-site)
cd "/Users/kluender/Dropbox (MIT)/Health Insurance and Financial Protection/OSHPD_disclosures/aug20_2015/Output"
* Set location of pre-formatted excel table for output
local output "/Users/kluender/Dropbox (MIT)/Health Insurance and Financial Protection/February 2016 Results"
* Locate the Stata program which generates a nice name for the variable name (e.g. "Number of Collections 
* to Date" to replace z1a_num_coll_ever).
local varnames "/Users/kluender/Dropbox (MIT)/Health Insurance and Financial Protection/Off-Site Analysis/Nov2015 Do Files"

* List variables to be included in the table
local z_num "z1a_num_coll_ever z1a_num_med_coll_ever z1a_num_nonmed_coll_ever"
local z_bal "z1a_coll_bal z1a_coll_bal_med z1a_coll_bal_nonmed"
local z_cred "z2a_any_bkrt_ever z3a_cred_limit_v2 z3a_credit_score"
local z_eff "z2a_tot_bal_all_rev z3a_auto_trade_balance"
local outcomes "`z_num' `z_bal' `z_cred' `z_eff'"

* Set columns for Table 3
local col3_1 "B"
local col3_2 "C"
local col3_3 "D"
local col3_4 "F"
local col3_5 "G"
local col3_6 "H"

* Set columns for Table 4
local col4_1 "B"
local col4_2 "C"
local col4_3 "D"
local col4_4 "E"
local col4_5 "F"

* Set initial rows for output for each table
local row3 = 6
local row4 = 5

* Loop over our three main analysis samples
foreach samp in INS SP 65plus {

	*************************************
	* Pull in pre-hospitalization means *
	*************************************
	insheet using "SumStats_`samp'_UB_RE.txt", clear
		keep if statistic=="mean"
		gen diff = .
		rename statistic _varname
		keep _varname `outcomes'
	tempfile prehosp
	save `prehosp'

	**************
	* Pull in Ns *
	**************
	insheet using "Splines_post72_YrFEs_coefs_`samp'_UB_RE.txt", clear
		rename var _varname
		keep if inlist(_varname,"Indiv","N")
		keep _varname `outcomes'
	tempfile N
	save `N'

	************************************
	* Pull in implied effect estimates *
	************************************
	insheet using "Splines_post72_YrFEs_IEs_`samp'_UB_RE.txt", clear

	rename var _varname
	keep _varname `outcomes'
	drop if _varname=="ttest12_48"
	xpose, clear v

	* Genereate p-values from the estimates and standard errors
	foreach mth in 12 24 36 48 pre {
			gen pv`mth'=2*normal(-abs(b`mth'/se`mth'))		
	} // end mth
		
	keep *12 *48  _varname
	xpose, clear v

	* Pull together N, pre-hospitalization mean, and estimates
	append using `prehosp'
	append using `N'

	* Label rows to facilitate sorting
	replace _varname="30_b12" if _varname=="b12"
	replace _varname="40_se12" if _varname=="se12"
	replace _varname="50_pv12" if _varname=="pv12"
	replace _varname="60_b48" if _varname=="b48"
	replace _varname="70_se48" if _varname=="se48"
	replace _varname="80_pv48" if _varname=="pv48"
	replace _varname="90_prehosp" if _varname=="mean"
	replace _varname="91_Indiv" if _varname=="Indiv"
	replace _varname="92_N" if _varname=="N"

	* Order and sort
	order _v
	sort _v

	local sheet = 0
	* Loop over different types of outcomes to round appropriately, format
	* estimates as text, and add labels
	foreach varlist in num bal cred eff {		
		foreach var in `z_`varlist'' {
			gen double `var'm=round(`var' ,10^(min(-2, int(log10(abs(`var')))-2)))
			drop `var' 
			rename `var'm `var'
			replace `var'=0 if `var'<.001 & regexm(_varname, "pv")==1
			format `var' %12.1gc
			replace `var' = round(`var', 0.01) if _varname=="93_R2"
			if inlist("`var'", "z1a_num_coll_ever", "z1a_num_med_coll_ever", "z1a_num_nonmed_coll_ever") {
				replace `var' = round(`var', 0.001) if regexm(_varname,"pv")==0
			}
			if inlist("`var'", "z1a_coll_bal", "z1a_coll_bal_med", "z1a_coll_bal_nonmed", "z3a_cred_limit_v2") {
				replace `var' = round(`var', 1) if regexm(_varname,"pv")==0
			}
			if ("`var'"=="z3a_credit_score") {
				replace `var' = round(`var', 0.1) if regexm(_varname,"pv")==0
			}
			tostring `var', replace force u
			replace `var'="<.001" if `var'=="0" & regexm(_varname, "pv")==1
			replace `var'="["+`var'+"]"  if regexm(_varname, "pv")==1
			replace `var'="("+`var'+")"	if regexm(_varname, "se")==1
			include "`varnames'/Varnames.do"
			label var `var' "`varname'"
		}	
		order _all, alpha
		order _varname

	} // varlist

	* Drop estimates over different time periods which we don't include in tables
	drop if inlist(_varname, "b24","b36","bcum48","bpre","se24","se36","secum48","sepre")

	* Output estimates to the designated pre-formatted excel tables
	local col = 0 
	foreach var in `z_num' {
		local col = `col' + 1
		di "`col3_`col''`row3'"
		export excel `var' using "`output'/Tables_Feb2016.xls", sheet("Table 3") sheetmod cell("`col3_`col''`row3'")
	}
	foreach var in `z_bal' {
		local col = `col' + 1
		export excel `var' using "`output'/Tables_Feb2016.xls", sheet("Table 3") sheetmod cell("`col3_`col''`row3'")
	}
	local col = 0 
	foreach var in `z_cred' {
		local col = `col' + 1
		export excel `var' using "`output'/Tables_Feb2016.xls", sheet("Table 4") sheetmod cell("`col4_`col''`row4'")
	} 
	foreach var in `z_eff' {
		local col = `col' + 1
		export excel `var' using "`output'/Tables_Feb2016.xls", sheet("Table 4") sheetmod cell("`col4_`col''`row4'")
	}

	local row3 = `row3' + 10
	local row4 = `row4' + 10
} // samp















