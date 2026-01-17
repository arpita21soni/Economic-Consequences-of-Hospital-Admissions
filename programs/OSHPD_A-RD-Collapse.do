/* 

This program collapses the RD sample to age in months in order to facilitate visualization of
the RD analysis, along with the opportunity to run additional specifications on the collapsed
version of the data. Unlike the other analysis files, it is not called from the shell.

*/

* Preliminaries
capture log close
log using "C:\Research\Health Insurance and Financial Protection\2. Analysis October 2015\Logs\RD Collapse.log", replace
set more off, perm
clear all
cd "C:\Data\Secure\To Save"

* Here we define a program to collapse the data after selecting on the "restrict_v" restriction
cap pr drop create_rd
program define create_rd
version 12
args i_file restrict_v
	cd "C:\Data\Secure\To Save"
	use `i_file'.dta, replace
	keep if `restrict_v' == 1 
	* This generates an unweighted version of the collapse (which we don't use)
	preserve
		collapse (sum) freq medicaid self_pay private, by(age_centered y_diff) fast
		cd "C:\Research\Health Insurance and Financial Protection\2. Analysis October 2015\Output"
		outsheet using "RD_Collapse_Ns_`restrict_v'_NW.csv", replace
	restore
	* This generates the weighted version which we use
	preserve
		bysort age y_diff: egen sum_wt = sum(represents_exact)
		collapse (sum) freq sum_medicaid=medicaid sum_self_pay=self_pay sum_private=private (mean) hhinc* sum_wt no_charge agyradm home_admit er_unplanned er_admit male medicare medicaid private self_pay indigent other_ins black white hispanic charge los z1* z2* z3* dz1* dz2* dz3* [pweight=represents_exact], by(age_centered y_diff) fast
		outsheet using "RD_Collapse_Means_`restrict_v'_W.csv", replace
	restore
end  

* Run the program for those in the RD sample for non-deferable ER admissions (select_rd),
* those admitted through the ER (not necessarily non-deferable), or all 60-70 year olds
foreach sample in select_rd er_admit freq {
	create_rd pdd_TU_RD_sample_Oct2015 `sample'
}

log close


 
 
