/*
- This program stands alone and calculates background summary statistics on demographics, 
  insurance status, and survey information for Table 1, and Appendix Tables 1 and 4.
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

* SAMPLE CHARACTERISTICS
local outcomes1 "cohort_0 cohort_1 cohort_2 cohort_3 cohort_4 cohort_5 cohort_6"
local outcomes2 "age_analyze male year_analyze spouse white black hispanic race_other medicaid insured_pv medicare"
local outcomes3 "medicaid_prevwave medicare_prevwave insured_pv_prevwave rehosp rehosp_nextwave insured_pvgov insured_pvgov_nextwave"
local outcomes `outcomes1' `outcomes2' `outcomes3'

foreach samp in under60_control under60_INS_nopre under60_INS age60to64_control age60to64_INS_nopre age60to64_INS over65_control over65_nopre over65 {

use HRS_long.dta, clear

gen age_analyze = ragey_b-1 
format riwbegy %td
gen year_analyze = year(riwbegy) - 1

* Determine number of variables to set columns of output matrix
local numvar = 0
foreach i of varlist `outcomes' {
	local numvar = `numvar'+1
}
matrix results = J(18, `numvar', .)

* Keep only those hospitalized and in our window
keep if `samp'==1
if inlist("`samp'","under60_INS","under60_INS_nopre","age60to64_INS_nopre","age60to64_INS","over65","over65_nopre","under60_INSwest","under60_INSpacific") {
	keep if evt_time==0
}
else if inlist("`samp'","under60_control") {
	keep if evt_time1==0
}
else if inlist("`samp'","over65_control") {
	keep if evt_time2==0
}
else if inlist("`samp'","age60to64_control") {
	keep if evt_time5==0
}
	
* Set column names
ds `outcomes'
local vars `r(varlist)'
matrix colnames results = `vars'

* Loop over the list of outcomes
local j = 1
foreach var of varlist `outcomes' {

	di "Running Variable: `var'"
	count if `var' < .
	local N = r(N)
	count if `var' == 1
	local N1 = r(N)
	count if `var' == 0
	local N0 = r(N)
	local dummy = (`N0' + `N1' == `N')
  
	* Compute unconditional mean, median, etc.
	summ `var' [aweight=rwtresp], det
	matrix results[1,`j'] = r(N)
	matrix results[3,`j'] = r(mean)
	matrix results[4,`j'] = r(sd)
	matrix results[5,`j'] = r(p10)
	matrix results[6,`j'] = r(p25)
	matrix results[7,`j'] = r(p50)
	matrix results[8,`j'] = r(p75)
	matrix results[9,`j'] = r(p90)
	gen share = rwtresp if !missing(`var')
	egen tot1=total(share)
	sum tot1
	local E1 = r(max)
	drop tot1 share
	matrix results[2,`j'] = `E1'

	** Compute CONDITIONAL mean, median, etc. 
	**  (CONDITIONAL ON X>0; only for non-dummy variables)
	if (`dummy' == 0) {
		summ `var' if `var' > 0 & !missing(`var') [aweight=rwtresp], det
		matrix results[10,`j'] = r(N)
		matrix results[12,`j'] = r(mean)
		matrix results[13,`j'] = r(sd)
		matrix results[14,`j'] = r(p10)
		matrix results[15,`j'] = r(p25)
		matrix results[16,`j'] = r(p50)
		matrix results[17,`j'] = r(p75)
		matrix results[18,`j'] = r(p90)
		
		gen share = rwtresp if !missing(`var') & `var'>0
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
replace statistic = "Wgt" if _n==2
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

outsheet using "`output'/HRS_SampChars_`samp'.txt", replace


} // samp


