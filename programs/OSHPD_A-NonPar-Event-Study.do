/*

- This program runs the non-parametric event study
- It is called from a shell file which feeds the program the dataset, variables to analyze, 
weights, sample selections, etc.

*/

* Preliminaries
cd "C:\Data\Secure\To Save"
clear all
set more off
set matsize 9000
set rmsg on
local log "C:\Research\Health Insurance and Financial Protection\2. Analysis August 20 2015\Logs"
local output "C:\Research\Health Insurance and Financial Protection\2. Analysis August 20 2015\Output"

cap log close
log using "`log'\ES_yrFEs_`samp'_`data_name'_`weight_name'.log", replace

* Pull in the data from the shell file and make sample restrictions
use `data' if `sample', clear

* Drop any results from prior runs
capture matrix drop results_coefs
capture matrix drop results_ses
capture matrix drop results_coefs_c
capture matrix drop results_ses_c

* Initiate locals for columns of output
local col_list ""
local col_list_c ""
est clear

* Create event time dummies
cap drop evt_*
cap drop z_evt*
forvalues i = -47/72 {
	if (`i' < 0) {
		local j = abs(`i')
		gen evt_f`j' = (diff == `i')
	}
	else {
		gen evt_l`i' = (diff == `i')
	}
}
* Recode the event time dummies so they don't run on outcomes where there's no data
* We have to do this because medical and non-medical collections are only present beginning in 2005
forv month = 36/47 {
	rename evt_f`month' z_evt_f`month'
}

* Create year fixed effects
cap drop _I*
cap drop z_I*
xi i.year_tu
* Recode the fixed effects so they don't run on outcomes where there's no data
rename _Iyear_tu_2003 z_Iyear_tu_2003 
rename _Iyear_tu_2004 z_Iyear_tu_2004 
rename _Iyear_tu_2005 z_Iyear_tu_2005

* DROP diff=-1 dummy to normalize
drop evt_f1

* Generate list of outcomes to run and save
ds `outcomes', detail
local cols `r(varlist)'

* Loop over outcomes 
local j = 1
foreach v of varlist `outcomes' {
	
	* Set locals to exclude early years of data where missing (med/non-med coll bals)
	local no_coll=""
	local coll=1
	if (regexm("`v'", "z1a_coll_bal_med")==0 & regexm("`v'", "z1a_coll_bal_nonmed")==0) {
		local no_coll="z_*"
		local coll=0
	}
 
 	* Run event study regressions
	di "Outcome: `v'"
	reg `v' evt_* _I* `no_coll' [pweight=`weight'], cluster(unique_id)
	
	*Saves N, number of individuals, and effective sample size to matrix
	local N = e(N)
	local C = e(N_clust)
	local R= e(r2)
	
	* Saves share of sample included in regression
	gen share=`weight' if `v'~=.
	egen tot1=total(share)
	sum tot1
	local E1 = r(max)
	drop tot share
	
	* Save first four rows as N, unique individuals, weighted individuals, and R-squared
	di "`N' \ `C' \ `E1' \ `R' " 
	mat input N=(`N' \ `C' \ `E1' \ `R' )
	mat rown N="N" "Indiv" "N_weight1" "R2"
	
	* Save coefficients and add to column
	matrix eb = e(b)
	matrix eb = (N\ eb')

	* Save variance-covariance matrix
	matrix var= (e(V))
	local colnames: coln var
	
	local n=0
	* Drop SE matrix from prior run
	cap mat drop se
	
	* Clean up matrices for output
	foreach col in `colnames'  {
		local n=`n'+1
		mat c`n'=var[`n'..., `n']
		local rownames: rown c`n'

		foreach w of local rownames  {
			local rw_c`n' `rw_c`n'' `w'_`col'
		}
		
		matrix rown c`n'= `rw_c`n''
		matrix coln c`n'= `v'
		matrix se=(nullmat(se)\ c`n')
		cap mat drop c`n' 
		local rw_c`n' ""
	}
	
	if `coll'==0 {
		mat se=(N\se)
		matrix results_ses=(nullmat(results_ses), se)
		matrix results_coefs = (nullmat(results_coefs), eb)
		local col_list `col_list' `v'
	}
	
	if `coll'==1 {
		mat se_c=(N\se)
		matrix results_ses_c=(nullmat(results_ses_c), se_c)
		matrix results_coefs_c = (nullmat(results_coefs_c), eb)
		local col_list_c `col_list_c' `v'
	}

} // end foreach v of varlist

* Outputting and saving results
local types = "coefs ses"
foreach type of local types {
 	 drop _all
	 mat coln results_`type'=`col_list'
	 svmat2 results_`type', names(col) rnames(var) full
	 tempfile all
	 save `all'
	 drop _all
	 mat coln results_`type'_c=`col_list_c'
	 svmat2 results_`type'_c, names(col) rnames(var) full
	 merge 1:1 var using `all', nogen
	 order var
	 outsheet using "`output'\ES_yrFEs_`type'_`samp'_`data_name'_`weight_name'.txt", replace
 
} // end foreach type of local types


log close











