/*
- This program gets called by a shell file which passes along a cd, output location, variable list,
  which sample, sample selection choices for that sample (e.g. whether they have a spouse, 
  unbalanced or balanced panel), and which set of fixed effects to include.
- It runs our main parameteric event study for the HRS, which we use to calculate implied
  effects based on the timing for each of the variables.
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
local col_list_IE ""

* Tweak subsample restrictions to allow variables to include sample
di "Sample = `samp', Spec = `spec', Spouse = `spouse'"
if inlist("`spouse'","ses_q1_","ses_q4_","LM_","HM_","ses_BM_","ses_AM_")==1 {
	local spouse `spouse'`samp'
}

* Keep only those hospitalized 
di "Sample = `samp', Spec = `spec', Spouse = `spouse'"
use HRS_long.dta if `samp'==1 & `spec'==1 & `spouse'==1, clear

if ("`samp'"=="under65_control") {
	assert missing(evt_time)
	replace evt_time = evt_time1
}
if ("`samp'"=="over65_control") {
	assert missing(evt_time)
	replace evt_time = evt_time2
}

* Generate event time dummies
drop if evt_time<-`range_`spec''
drop if evt_time>`range_`spec''

forv i = 0/`range_`spec'' {
	if (`i' < 0) {
		local j = abs(`i')
		gen evt_f`j' = (evt_time == `i')
	}
	else {
		gen evt_l`i' = (evt_time == `i')
	}
}

egen cohortXwave = group(hacohort wave)

* Define number of variables for "implied effects" matrix
local J = 0
foreach outcome of varlist `outcomes' {
	local J = `J' + 1
}
matrix define results_IEs = J(21,`J',.)

local j = 1
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
	areg `v' evt_time evt_l* `controls' [pweight=rwtresp], absorb(`fe') cluster(hhidpn)

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

	* Calculating implied effects:
	
	* Earnings
	lincom 2.227*evt_l0 - 0.118*evt_l1 + 0.0056*evt_l2
		matrix results_IEs[1,`j'] = r(estimate)
		matrix results_IEs[2,`j'] = r(se)
	lincom -0.954*evt_l0 + 1.550*evt_l1 - 0.073*evt_l2
		matrix results_IEs[3,`j'] = r(estimate)
		matrix results_IEs[4,`j'] = r(se)	
	lincom 0.636*evt_l0 + 0.716*evt_l1 - 0.034*evt_l2
		matrix results_IEs[5,`j'] = r(estimate)
		matrix results_IEs[6,`j'] = r(se)
	test 2.227*evt_l0 - 0.118*evt_l1 + 0.0056*evt_l2 = -0.954*evt_l0 + 1.550*evt_l1 - 0.073*evt_l2
		matrix results_IEs[7,`j'] = r(p)
		
	* OOP
	lincom 1.627*evt_l0 - 0.293*evt_l1 + 0.039*evt_l2
		matrix results_IEs[8,`j'] = r(estimate)
		matrix results_IEs[9,`j'] = r(se)
	lincom -0.248*evt_l0 + 1.373*evt_l1 - 0.182*evt_l2
		matrix results_IEs[10,`j'] = r(estimate)
		matrix results_IEs[11,`j'] = r(se)
	lincom 0.460*evt_l0 + 0.360*evt_l1 - 0.048*evt_l2
		matrix results_IEs[12,`j'] = r(estimate)
		matrix results_IEs[13,`j'] = r(se)
	test 1.627*evt_l0 - 0.293*evt_l1 + 0.039*evt_l2 = -0.248*evt_l0 + 1.373*evt_l1 - 0.182*evt_l2
		matrix results_IEs[14,`j'] = r(p)
		
	* LFP
	lincom 1.627*evt_l0 - 0.293*evt_l1 + 0.0388*evt_l2
		matrix results_IEs[15,`j'] = r(estimate)
		matrix results_IEs[16,`j'] = r(se)
	lincom -0.248*evt_l0 + 1.373*evt_l1 - 0.182*evt_l2
		matrix results_IEs[17,`j'] = r(estimate)
		matrix results_IEs[18,`j'] = r(se)
	lincom 0.689*evt_l0 + 0.540*evt_l1 - 0.072*evt_l2
		matrix results_IEs[19,`j'] = r(estimate)
		matrix results_IEs[20,`j'] = r(se)
	test 1.627*evt_l0 - 0.293*evt_l1 + 0.0388*evt_l2 = -0.248*evt_l0 + 1.373*evt_l1 - 0.182*evt_l2
		matrix results_IEs[21,`j'] = r(p)
	
	local col_list_IE `col_list_IE' `v'	
	local j = `j' + 1

} // outcomes

* Labeling rows of implied effects table
* NOTE: 36a indicate the annual effect at 36 months
	* the 36m are the average annual effects that are presented in the paper
local r="b_12mEarn se_12mEarn b_36mEarn se_36mEarn b_36aEarn se_36aEarn p_Earn b_12mOOP se_12mOOP b_36mOOP se_36mOOP b_36aOOP se_36aOOP p_OOP b_12mLFP se_12mLFP b_36mLFP se_36mLFP b_36aLFP se_36aLFP p_LFP"
mat rown results_IEs=`r'

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
	 
	 outsheet using "`output'/HRS_ES_`type'_`samp'_`spouse'_`spec'_FE`fe'.txt", replace
 } // end foreach type of local types

drop _all
mat coln results_IEs=`col_list_IE'
svmat2 results_IEs, names(col) rnames(var) full
order var
outsheet using "`output'/HRS_IEs_`samp'_`spouse'_`spec'_FE`fe'.txt", replace
 
} // spec
} // samples
} // fes
} // spouse












