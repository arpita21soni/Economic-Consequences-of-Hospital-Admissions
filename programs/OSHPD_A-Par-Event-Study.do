/*

- This program runs the parametric event study
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
log using "`log'\Splines_YrFEs_`samp'_`data_name'_`weight_name'.log", replace

use `data' if `sample', clear

* Drop any results from prior runs
capture matrix drop results_coefs
capture matrix drop results_ses
capture matrix drop results_coefs_lb
capture matrix drop results_ses_lb
capture matrix drop results_coefs_c
capture matrix drop results_ses_c
capture matrix drop results_IEs

* Create variables for spline regression
assert diff>-48 & diff<=72
gen diff1= cond(diff > -48, diff, 0)
	gen diff1alt= cond(diff > -35, diff, 0)
	* Check that the spline recode worked
	assert diff1!=0 if diff!=0
	assert diff1!=0 if diff!=0 & !missing(z1a_coll_bal_med)
gen diff2 = cond(diff > 0, (diff-0)^2, 0)
gen diff3 = cond(diff > 0, (diff-0)^3, 0)
gen k1 = cond(diff > 12, (diff-12)^3, 0)
gen k2 = cond(diff > 24, (diff-24)^3, 0)
gen k3 = cond(diff > 6, (diff-6)^3, 0)
gen k4 = cond(diff > 18, (diff-18)^3, 0)

* Set locals for variable names to output
local col_list ""
local col_list_lb ""
local col_list_c ""
local col_list_IE ""
est clear

* Updating TU year fixed effects to account for missing collections data
cap drop _I*
cap drop z_I*
xi i.year_tu

rename _Iyear_tu_2003 z_Iyear_tu_2003 
rename _Iyear_tu_2004 z_Iyear_tu_2004 
rename _Iyear_tu_2005 z_Iyear_tu_2005

* Define rows and columns for outputting of results
ds `outcomes', detail
local cols `r(varlist)'

* Defining number of variables for implied effects output
local J = 0
foreach outcome of varlist `outcomes' {
	local J = `J'+1
}
matrix define results_IEs = J(14,`J',.)

* Running Spline Regressions
local j = 1
foreach v of varlist `outcomes' {
	
	* Set indicators to run different regressions of med/non-med collections and 12m look-backs
	local no_coll=""
	local coll=1
	local lookback=0
	if (regexm("`v'", "z1a_coll_bal_med")==0 & regexm("`v'", "z1a_coll_bal_nonmed")==0) {
		local no_coll="z_I*"
		local coll=0
	}
	if (regexm("`v'", "_12m")==1) {
		local lookback=1
	}	
	
	* Run parametric event study regressions with appropriate specifications
	if `coll'==0 & `lookback'==0 {
		reg `v' diff1 diff2 diff3 k1 k2 _I* `no_coll' [pweight=`weight'], cluster(unique_id)
	}
	if `coll'==0 & `lookback'==1 {
		reg `v' diff1 diff2 diff3 k1 k2 k3 k4 _I* `no_coll' [pweight=`weight'], cluster(unique_id)
	}
	if `coll'==1 {
		reg `v' diff1alt diff2 diff3 k1 k2 _I* `no_coll' [pweight=`weight'], cluster(unique_id)
	}
	
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
	
	if `coll'==0 & `lookback'==0 {
		mat se=(N\se)
		matrix results_ses=(nullmat(results_ses), se)
		matrix results_coefs = (nullmat(results_coefs), eb)
		local col_list `col_list' `v'			
	}
	if `coll'==0 & `lookback'==1 {
		mat se_lb=(N\se)
		matrix results_ses_lb =(nullmat(results_ses_lb), se_lb)
		matrix results_coefs_lb = (nullmat(results_coefs_lb), eb)
		local col_list_lb `col_list_lb' `v'			
	}
	if `coll'==1 {
		mat se_c=(N\se)
		matrix results_ses_c=(nullmat(results_ses_c), se_c)
		matrix results_coefs_c = (nullmat(results_coefs_c), eb)
		local col_list_c `col_list_c' `v'
	}
	
	* Calculating implied effects
	if `lookback'==0 {
		* Implied effects at 12, 24, 36, and 48 months
		lincom 144*diff2+1728*diff3
			matrix results_IEs[1,`j']=r(estimate)
			matrix results_IEs[2,`j']=r(se)
		lincom 576*diff2+13824*diff3+1728*k1
			matrix results_IEs[3,`j']=r(estimate)
			matrix results_IEs[4,`j']=r(se)
		lincom 1296*diff2+46656*diff3+13824*k1+1728*k2
			matrix results_IEs[5,`j']=r(estimate)
			matrix results_IEs[6,`j']=r(se)
		lincom 2304*diff2+110592*diff3+46656*k1+13824*k2
			matrix results_IEs[7,`j']=r(estimate)
			matrix results_IEs[8,`j']=r(se)
		lincom 5814*diff2+373248*diff3+216000*k1+110592*k2
			matrix results_IEs[9,`j']=r(estimate)
			matrix results_IEs[10,`j']=r(se)
		* Test whether implied effects at 12 and 48 months are the same
		test 144*diff2+1728*diff3 = 2304*diff2+110592*diff3+46656*k1+13824*k2
			matrix results_IEs[11,`j']=r(p)
		* Test whether implied effects at 48 and 72 months are the same
		test 2304*diff2+110592*diff3+46656*k1+13824*k2 = 5814*diff2+373248*diff3+216000*k1+110592*k2
	}
	if `lookback'==1 {
		* Implied effects at 12, 24, 36, and 48 months
		lincom 144*diff2+1728*diff3+216*k3
			matrix results_IEs[1,`j']=r(estimate)
			matrix results_IEs[2,`j']=r(se)
		lincom 576*diff2+13824*diff3+1728*k1+5832*k3+216*k4
			matrix results_IEs[3,`j']=r(estimate)
			matrix results_IEs[4,`j']=r(se)
		lincom 1296*diff2+46656*diff3+13824*k1+1728*k2+27000*k3+5832*k4
			matrix results_IEs[5,`j']=r(estimate)
			matrix results_IEs[6,`j']=r(se)
		lincom 2304*diff2+110592*diff3+46656*k1+13824*k2+74088*k3+27000*k4
			matrix results_IEs[7,`j']=r(estimate)
			matrix results_IEs[8,`j']=r(se)
		lincom 5814*diff2+373248*diff3+216000*k1+110592*k2+287496*k3+157464*k4
			matrix results_IEs[9,`j']=r(estimate)
			matrix results_IEs[10,`j']=r(se)
		* Test whether implied effects at 12 and 48 months are the same			
		test 144*diff2+1728*diff3+216*k3 = 2304*diff2+110592*diff3+46656*k1+13824*k2+74088*k3+27000*k4
			matrix results_IEs[13,`j']=r(p)
		* Test whether implied effects at 48 and 72 months are the same
		test 2304*diff2+110592*diff3+46656*k1+13824*k2+74088*k3+27000*k4 = 5814*diff2+373248*diff3+216000*k1+110592*k2+287496*k3+157464*k4
			matrix results_IEs[14,`j']=r(p)	
	}
	
	* Save out coefficient and standard error on pretrends
	if `coll'==0 {
		lincom 12*diff1
			matrix results_IEs[11,`j']=r(estimate)
			matrix results_IEs[12,`j']=r(se)
	}
	if `coll'==1 {
		lincom 12*diff1alt
			matrix results_IEs[11,`j']=r(estimate)
			matrix results_IEs[12,`j']=r(se)
	}
	
	local col_list_IE `col_list_IE' `v'
	local j = `j' + 1

} // end foreach v of varlist

* Labeling rows of implied effects table
local r="b12 se12 b24 se24 b36 se36 b48 se48 b72 se72 bpre sepre ttest12_48 ttest48_72"
mat rown results_IEs=`r'

* Outputting and saving results
foreach type in coefs ses {

	drop _all
	mat coln results_`type'=`col_list'
	svmat2 results_`type', names(col) rnames(var) full
	tempfile all
	save `all'
	drop _all
	
	drop _all
	mat coln results_`type'_lb=`col_list_lb'
	svmat2 results_`type'_lb, names(col) rnames(var) full
	tempfile all_lb
	save `all_lb'
	drop _all	
	
	mat coln results_`type'_c=`col_list_c'
	svmat2 results_`type'_c, names(col) rnames(var) full
	merge 1:1 var using `all', nogen
	merge 1:1 var using `all_lb', nogen
	order var
	outsheet using "`output'\Splines_YrFEs_`type'_`samp'_`data_name'_`weight_name'.txt", replace
	
} // end foreach type of local types

drop _all
mat coln results_IEs=`col_list_IE'
svmat2 results_IEs, names(col) rnames(var) full
order var
outsheet using "`output'\Splines_YrFEs_IEs_`samp'_`data_name'_`weight_name'.txt", replace


log close
