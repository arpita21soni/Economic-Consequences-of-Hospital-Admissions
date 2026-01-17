/*

- This program runs the regression discontinuity on the micro data
- It is called from a shell file which feeds the program the dataset, variables to analyze, 
weights, sample selections, etc.
- It loops over the years relative to the hospitalization beginning with 3 years prior, these
years prior served as a placebo check and examine the RD around the age at hospitalization for
outcomes 1, 2, 3, 4, and 5 years past the hospitalization. The paper focuses on effects at 1 and
4 years.

*/

* Preliminaries
cd "C:\Data\Secure\To Save"
clear all
set more off
set matsize 9000
set rmsg on
local log "C:\Research\Health Insurance and Financial Protection\2. Analysis August 20 2015\Logs"
local output "C:\Research\Health Insurance and Financial Protection\2. Analysis August 20 2015\Output"

capture log close
log using "`log'\RD_MicroByYDiff_`sample'.log", replace

* Pull in the data from the shell file and make sample restrictions
use `data' if `sample', clear

* Drop any results from prior runs
capture matrix drop results_coefs
capture matrix drop results_ses
local col_list ""
est clear

* Generate list of outcomes to run and save
ds `outcomes'
local cols `r(varlist)'
local bw_label = 5

* Running RD Regressions
local count = 0
forv y_diff = -3/5 {

	local count = `count' + 1

	foreach var of varlist `outcomes' {
	
		* Run the quadratic regression specification
		di "reg `var' age_centered age_centered2 over65 ageXover65 age2Xover65 [aw=`weight'] if y_diff==`y_diff', cluster(age)"
		reg `var' age_centered age_centered2 over65 ageXover65 age2Xover65 [aw=`weight'] if y_diff==`y_diff', cluster(age)
 
		*Saves N, number of individuals, and effective sample size to matrix
		local N = e(N)
		local R= e(r2)
		
		* Generate number of unique individuals with non-missing outcome variable
		bysort unique_id y_diff: gen nvals = (_n==1)
		count if nvals & y_diff==`y_diff' & !missing(`var')
		local C = r(N)
		drop nvals
		
		* Generate weighted share of individuals with non-missing variable
		gen share=`weight' if `var'~=.
		egen tot1=total(share)
		sum tot1
		local E1 = r(max)
		
		drop tot share
		di "`y_diff' \ `N' \ `C' \ `E1' \ `R' " 
		mat input N=(`y_diff' \ `N' \ `C' \ `E1' \ `R' )
		mat rown N="y_diff" "N" "Indiv" "N_weight1" "R2"
		
		* Process regression coefficients and prepare matrix to save
		matrix eb = e(b)
		matrix eb = (N\ eb')
		* Process variance-covariance matrix
		matrix var= (e(V))		
		local colnames: coln var		
		
		local n=0
		* Drop SE matrix from prior run
		cap mat drop se
		
		* Clean up matrices for output
			local n=`n'+1
			mat c`n'=var[`n'..., `n']
			local rownames: rown c`n'

			foreach w of local rownames  {
				local rw_c`n' `rw_c`n'' `w'_`col'
			} // w
			
		matrix rown c`n'= `rw_c`n''
		matrix coln c`n'= `var'
		matrix se=(nullmat(se)\ c`n')
		cap mat drop c`n' 
		local rw_c`n' ""
		} // col
		
		* Add variables from this run to the existing results matrices
		mat se=(N\se)
		matrix results_ses=(nullmat(results_ses), se)
		matrix results_coefs = (nullmat(results_coefs), eb)
		local col_list `col_list' `var'`count'
		
	} // var
	
} // y_diff 

* Outputting and saving results
foreach type in coefs ses {

	drop _all
	mat coln results_`type'=`col_list'
	svmat2 results_`type', names(col) rnames(var) full
	order var
	outsheet using "`output'\RD_MicroByYDiff_`type'_`sample'.txt", replace
	
} // end foreach type of local types
		
log close	
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		





