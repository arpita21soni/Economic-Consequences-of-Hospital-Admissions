/*
- This is an example of the programs used to generate the tables for the HRS outcomes in the
  paper. They all export to pre-formatted Excel versions of the tables. 
- There are a number of additional versions, but they all follow this same basic template.
*/

* Preliminaries
set more off, perm
set matsize 5000
clear all

* Set current directory to output specified in shell file
cd "/Users/kluender/Desktop/DFKN Replication Kit/HRS/Output"

* Set list of outcomes
local list "oop_spend working riearnsemp siearnsemp hgovt hitot_inc"

* Set row and column references for excel table
local row_under60_INS 5
local col1 "B"
local col2 "C"
local col3 "D"
local col4 "E"
local col5 "F"
local col6 "G"

local num = 0

foreach samp in under60_INS {

local num = `num' + 1

use "/Users/kluender/Desktop/HRS/HRS_long.dta", clear

* Keep only those hospitalized and in sample to calculate pre-hospitalization mean
keep if ever_hospitalized==1 & `samp'==1 & evt_time==-1

foreach var in `list' {
	sum `var' [aweight=rwtresp]
	local `var'_mean = round(r(mean),0.001)
}

clear
set obs 1
foreach var in `list' {
	gen `var' = ``var'_mean'
}

gen _varname = "mean"

tempfile means
save `means', replace

* Import event study coefficients to obtain sample size
insheet using "HRS_ES_coefs_`samp'_freq_freq_FEcohortXwave.txt", clear
	keep if inlist(var,"Indiv","N")
	keep var `list'
	rename var _varname
tempfile N
save `N'

* Import the implied effects estimates
insheet using "HRS_IEs_`samp'_freq_freq_FEcohortXwave.txt", clear
	
	keep var `list'

	gen _varname = ""
	
	* Keep and reformat implied effects for OOP spending
	foreach var in oop_spend {
		preserve
			keep `var' var _varname
			keep if inlist(var,"b_12mOOP","se_12mOOP","b_36aOOP","se_36aOOP","b_36mOOP","se_36mOOP","p_OOP")
			replace _varname = "b0" if var=="b_12mOOP"
			replace _varname = "se0" if var=="se_12mOOP"
			replace _varname = "b1" if var=="b_36mOOP"
			replace _varname = "se1" if var=="se_36mOOP"
			replace _varname = "b2" if var=="b_36aOOP"
			replace _varname = "se2" if var=="se_36aOOP"			
			replace _varname = "p" if var=="p_OOP"
			tempfile IEs_`var'
			save `IEs_`var''
		restore
	}
	* Keep and reformat implied effects for indicator variables
	foreach var in working {
		preserve
			keep `var' var _varname
			keep if inlist(var,"b_12mLFP","se_12mLFP","b_36aLFP","se_36aLFP","b_36mLFP","se_36mLFP","p_LFP")
			replace _varname = "b0" if var=="b_12mLFP"
			replace _varname = "se0" if var=="se_12mLFP"
			replace _varname = "b1" if var=="b_36mLFP"
			replace _varname = "se1" if var=="se_36mLFP"
			replace _varname = "b2" if var=="b_36aLFP"
			replace _varname = "se2" if var=="se_36aLFP"
			replace _varname = "p" if var=="p_LFP"
			tempfile IEs_`var'
			save `IEs_`var''
		restore
	}
	* Keep and reformat implied effects for income and earnings variables
	foreach var in riearnsemp siearnsemp hgovt hitot_inc {
		preserve
			keep `var' var _varname
			keep if inlist(var,"b_12mEarn","se_12mEarn","b_36aEarn","se_36aEarn","b_36mEarn","se_36mEarn","p_Earn")
			replace _varname = "b0" if var=="b_12mEarn"
			replace _varname = "se0" if var=="se_12mEarn"
			replace _varname = "b1" if var=="b_36mEarn"
			replace _varname = "se1" if var=="se_36mEarn"
			replace _varname = "b2" if var=="b_36aEarn"
			replace _varname = "se2" if var=="se_36aEarn"
			replace _varname = "p" if var=="p_Earn"
			tempfile IEs_`var'
			save `IEs_`var''
		restore
	}	
	
	* Recombine
	use `IEs_riearnsemp', clear
	foreach var in `list' {
		di "`var'"
		merge 1:1 _varname using `IEs_`var'', nogen
	}
	
	drop var
	* Transpose to caluclate p-values
	xpose, clear v
	
	foreach est in 0 1 2 {
			gen pv`est'=2*normal(-abs(b`est'/se`est'))		
	} // end mth		
	keep b0 b1 b2 se0 se1 se2 pv0 pv1 pv2 p _varname
	xpose, clear v

append using `means'
append using `N'

* Rename to set order	
replace _varname = "10_est0" if _varname =="b0"
replace _varname = "20_se0" if _varname =="se0"
replace _varname = "30_pv0" if _varname =="pv0"
replace _varname = "40_est1" if _varname =="b1"
replace _varname = "50_se1" if _varname =="se1"
replace _varname = "60_pv1" if _varname =="pv1"
replace _varname = "61_est2" if _varname =="b2"
replace _varname = "62_se2" if _varname =="se2"
replace _varname = "63_pv2" if _varname =="pv2"
replace _varname = "70_mean" if _varname =="mean"
replace _varname = "80_Indiv" if _varname =="Indiv"
replace _varname = "90_N" if _varname=="N"
replace _varname = "91_pvT" if _varname=="p"

* Format each entry as a string
sort _varname
foreach var in `list' {

	gen double `var'm=round(`var' ,10^(min(-2, int(log10(abs(`var')))-2)))
	drop `var' 
	rename `var'm `var'
	replace `var'=0 if `var'<.001 & regexm(_varname, "pv")==1
	format `var' %12.3gc
	tostring `var', replace force u
	replace `var'="<.001" if `var'=="0" & regexm(_varname, "pv")==1
	replace `var'="["+`var'+"]"  if regexm(_varname, "pv")==1
	replace `var'="("+`var'+")"	if regexm(_varname, "se")==1
	
}

* Export results
drop if _varname=="91_pvT" // This tests for equivalence between 12 and 36 month annual effect results
local col = 1
foreach var in `list' {
	export excel `var' using "../Table Example.xls", sheet("Table 2") sheetmod cell("`col`col''`row_`samp''")
	local col = `col' + 1
}

	
} // samp
