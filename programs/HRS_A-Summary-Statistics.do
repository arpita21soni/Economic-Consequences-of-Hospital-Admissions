/*
- This program gets called by a shell file which passes along a cd, output location, variable list,
  which sample, and sample selection choices for that sample (e.g. whether they have a spouse, 
  unbalanced or balanced panel).
- It runs summary statistics for the HRS in the survey wave preceding the hospitalization.
*/

foreach samp in `samples' {

di "Sample = `samp'"

foreach spouse in `spouses' {
foreach spec in `specs' {

di "Sample = `samp', Spec = `spec', Spouse = `spouse'"
if inlist("`spouse'","ses_q1_","ses_q4_","LM_","HM_","ses_BM_","ses_AM_")==1 {
	local spouse `spouse'`samp'
}

di "Sample = `samp', Spec = `spec', Spouse = `spouse'"
use HRS_long.dta if `samp'==1 & `spec'==1 & `spouse'==1, clear

* Look at pre-hospitalization means
if ("`samp'"=="under60_control") {
	assert missing(evt_time)
	keep if evt_time1==-1
	drop age_hosp
	rename age_hosp1 age_hosp
}
else if ("`samp'"=="over65_control") {
	assert missing(evt_time)
	keep if evt_time2==-1
	drop age_hosp
	rename age_hosp2 age_hosp
}
else if ("`samp'"=="under60_death") {
	assert missing(evt_time)
	keep if evt_time3==-1
	drop age_hosp
	rename age_hosp3 age_hosp
}
else if ("`samp'"=="over65_death") {
	assert missing(evt_time)
	keep if evt_time4==-1
	drop age_hosp
	rename age_hosp4 age_hosp
}
else {
	keep if evt_time==-1
}

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
		qui summ `var' if `var' > 0 & !missing(`var') [aweight=rwtresp], det
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

outsheet using "`output'/HRS_SumStats_`samp'_`spouse'_`spec'.txt", replace


} // spec
} // spouse
} //samp

