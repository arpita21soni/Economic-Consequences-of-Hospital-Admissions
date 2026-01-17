/*
- This program gets called by a shell file which passes along a cd, output location, variable list,
  which sample, sample selection choices for that sample (e.g. whether they have a spouse, 
  unbalanced or balanced panel), and which set of fixed effects to include.
- It runs our main non-parameteric event study for the HRS, which we use to plot the dots in the 
  figures.
*/

local range_freq 3
local range_bal 2
local range_bal1 2
local range_bal2 2

foreach samp in `samples' {
foreach spouse in `spouses' {
foreach fe in `fes' {
foreach spec in `specs' {

mat drop _all
local colnames ""
local col_list_1 ""
local col_list_2 ""

* Tweak subsample restrictions to allow variables to include sample
di "Sample = `samp', Spec = `spec', Spouse = `spouse'"
if inlist("`spouse'","ses_q1_","ses_q4_","LM_","HM_","ses_BM_","ses_AM_")==1 {
	local spouse `spouse'`samp'
}

* Keep only those hospitalized 
di "Sample = `samp', Spec = `spec', Spouse = `spouse'"
use HRS_long.dta, clear

keep if `samp'==1 & `spec'==1 & `spouse'==1

if ("`samp'"=="under65_control") {
	assert missing(evt_time)
	replace evt_time = evt_time1
}
if ("`samp'"=="over65_control") {
	assert missing(evt_time)
	replace evt_time = evt_time2
}

* Generate event time dummies
tab evt_time, mi

drop if evt_time<-`range_`spec''
drop if evt_time>`range_`spec''

forv i = -`range_`spec''/`range_`spec'' {
	if (`i' < 0) {
		local j = abs(`i')
		gen evt_f`j' = (evt_time == `i')
	}
	else {
		gen evt_l`i' = (evt_time == `i')
	}
}

drop evt_f1
egen cohortXwave = group(hacohort wave)

foreach v of varlist `outcomes' {

	local controls ""
	if "`fe'"=="hhidpn" {
		xi i.wave
		drop _Iwave_11
		local controls "_I*"
		if regexm("`v'","_c")==1 {
			drop _Iwave_2 _Iwave_3 
		}
		if inlist("`v'","risemp","sisemp","hisemp","a_risemp","a_sisemp","a_hisemp")==1 {
			drop _Iwave_2 _Iwave_3 
		}
	}

	di "FE = `fe', Sample = `samp', Spouse = `spouse', Spec = `spec', Var = `v'"
	areg `v' evt_f* evt_l* `controls' [pweight=rwtresp] if `samp', absorb(`fe') cluster(hhidpn)

	*Saves N, number of individuals, and effective sample size to matrix
	local N = e(N)
	local C = e(N_clust)
	local R= e(r2)
	
	* Save first four rows as N, unique individuals, weighted individuals, and R-squared
	di "`N' \ `C' \ `R' " 
	mat input N=(`N' \ `C' \ `R' )
	mat rown N="N" "Indiv" "R2"
	
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
	
	if regexm("`v'","_c")==1 {
		mat se=(N\se)
		matrix results_ses_2=(nullmat(results_ses_2), se)
		matrix results_coefs_2 = (nullmat(results_coefs_2), eb)
		local col_list_2 `col_list_2' `v'
	}	
	else if inlist("`v'","risemp","sisemp","hisemp","a_risemp","a_sisemp","a_hisemp")==1 {
		mat se=(N\se)
		matrix results_ses_2=(nullmat(results_ses_2), se)
		matrix results_coefs_2 = (nullmat(results_coefs_2), eb)
		local col_list_2 `col_list_2' `v'
	}		
	else {
		mat se=(N\se)
		matrix results_ses_1=(nullmat(results_ses_1), se)
		matrix results_coefs_1 = (nullmat(results_coefs_1), eb)
		local col_list_1 `col_list_1' `v'
	}

} // outcomes

* Outputting and saving results
local types = "coefs ses"
foreach type of local types {
 	 drop _all
	 mat coln results_`type'_1=`col_list_1'
	 svmat2 results_`type'_1, names(col) rnames(var) 

	 order var
	 tempfile matrix1
	 save `matrix1', replace
	 
	 drop _all
	 mat coln results_`type'_2=`col_list_2'
	 svmat2 results_`type'_2, names(col) rnames(var) full
	 order var
	 merge 1:1 var using `matrix1', nogen
	 order var
	 
	 outsheet using "`output'/HRS_FullES_`type'_`samp'_`spouse'_`spec'_FE`fe'.txt", replace
 } // end foreach type of local types

} // spec
} // fes
} // spouse
} // samples













