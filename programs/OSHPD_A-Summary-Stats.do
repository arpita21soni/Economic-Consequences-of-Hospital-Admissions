*******************************
* PRE-HOSP SUMMARY STATISTICS *
*******************************

/*

- This program calculates summary statistics, unconditionally and conditional on greater than zero,
for all of the credit report variables and a wide range of demographics
- It runs the summarize command, then outputs the relevant statistics to a matrix which we export
and use off-site

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
log using "`log'\SumStats_`samp'_`data_name'_`weight_name'.log", replace

use `data' if `sample' & diff<=-12 & diff>=-23, clear

* Get total number of individuals and weighted sum
sum `weight'
local weight_sum = r(sum)
di "Sum of `weight' = `weight_sum'"
sum freq
local number_individuals = r(sum)
di "N = `number_individuals'"

* Generate dummies for MDC categories
xi i.mdc, noomit

* Determine number of variables to set columns of output matrix
local numvar = 0
foreach i of varlist `outcomes' {
	local numvar = `numvar'+1
}
matrix results = J(18, `numvar', .)

* Set column names
ds `outcomes'
local vars `r(varlist)'
matrix colnames results = `vars'

* Loop over the list of outcomes
local j = 1
foreach var of varlist `outcomes' {

	count if `var' < .
	local N = r(N)
	count if `var' == 1
	local N1 = r(N)
	count if `var' == 0
	local N0 = r(N)
	local dummy = (`N0' + `N1' == `N')
  
	* Compute unconditional mean, median, etc.
	qui summ `var' [aweight=`weight'], det
	matrix results[1,`j'] = r(N)
	matrix results[3,`j'] = r(mean)
	matrix results[4,`j'] = r(sd)
	matrix results[5,`j'] = r(p10)
	matrix results[6,`j'] = r(p25)
	matrix results[7,`j'] = r(p50)
	matrix results[8,`j'] = r(p75)
	matrix results[9,`j'] = r(p90)
	gen share = `weight' if !missing(`var')
	egen tot1=total(share)
	sum tot1
	local E1 = r(max)
	drop tot1 share
	matrix results[2,`j'] = `E1'

	** Compute CONDITIONAL mean, median, etc. 
	**  (CONDITIONAL ON X>0; only for non-dummy variables)
	if (`dummy' == 0) {
		qui summ `var' if `var' > 0 & !missing(`var') [aweight=`weight'], det
		matrix results[10,`j'] = r(N)
		matrix results[12,`j'] = r(mean)
		matrix results[13,`j'] = r(sd)
		matrix results[14,`j'] = r(p10)
		matrix results[15,`j'] = r(p25)
		matrix results[16,`j'] = r(p50)
		matrix results[17,`j'] = r(p75)
		matrix results[18,`j'] = r(p90)
		
		gen share = `weight' if !missing(`var') & `var'>0
		egen tot1=total(share)
		sum tot1
		local E1 = r(max)
		drop tot1 share
		matrix results[11,`j'] = `E1'
	}
  
	local j = `j'+1
}
matrix list results

drop _all
svmat results, names(col)

gen statistic = ""
replace statistic = "N" if _n == 1
replace statistic = "Wgt" if _n==1
replace statistic = "mean" if _n == 3
replace statistic = "sd" if _n == 4
replace statistic = "p10" if _n == 5
replace statistic = "p25" if _n == 6
replace statistic = "median" if _n == 7
replace statistic = "p75" if _n == 8
replace statistic = "p90" if _n == 9

replace statistic = "N_g0" if _n == 10
replace statistic = "Wgt_g0" if _n==11
replace statistic = "mean_g0" if _n == 12
replace statistic = "sd_g0" if _n == 13
replace statistic = "p10_g0" if _n == 14
replace statistic = "p25_g0" if _n == 15
replace statistic = "median_g0" if _n == 16
replace statistic = "p75_g0" if _n == 17
replace statistic = "p90_g0" if _n == 18

order statistic

outsheet using "`output'\SumStats_`samp'_`data_name'_`weight_name'.txt", replace

log close

