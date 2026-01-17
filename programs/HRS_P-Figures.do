/*
- This is an example of the programs used to generate the figures for the HRS outcomes in the
  paper.
- There are a number of additional versions, but they all follow this same basic template.
*/

clear all
set more off, perm
set matsize 5000
graph set window fontface "Times New Roman"

* Set Current Directory to Output Folder from Shell File
cd "/Users/kluender/Desktop/DFKN Replication Kit/HRS/Output"

* Set the outcomes to plot
local outcomes1 "oop_spend riearnsemp siearnsemp hgovt hitot_inc log_hitot_inc hitot_old log_hitot_old"
local outcomes2 "working working_ft working_pt unemployed partly_retired retired disabled not_in_lbrf health_limited"
local outcomes3 "a_hgovt rgovt ripena hipena hicap_une hiothr"
local outcomes4 "hisdi hissi hiunem hisret annual_hours log_rwgihr"
local list  `outcomes1' `outcomes2' `outcomes3' `outcomes4' 

* Set figure titles for each variable
local oop_spendn "Out-of-Pocket Medical Spending"
local workingn "Working Part or Full-Time"
local health_limitedn "Work Limited by Health"
local a_hgovtn "Any Household Social Insurance Payments"
local workingn "Working Part or Full-Time"
local riearnsempn "Respondent Earnings"
local siearnsempn "Spousal Earnings"
local rgovtn "Respondent Social Insurance Payments"
local hgovtn "Household Social Insurance Payments"
local ripenan "Respondent Pension+Annuity Income"
local hipenan "Household Pension+Annuity Income"
local hicap_unen "Household Capital and Business Income"
local hiothrn "Other Household Income"
local hitot_incn "Total Household Income"
local log_hitot_incn "Log(Total Household Income)"
local hitot_oldn "Total Household Income" "Plus Business, Capital, and Other Income"
local log_hitot_oldn "Log(Total Household Income" "Plus Business, Capital, and Other Income)"
local annual_hoursn "Annual Hours"
local log_rwgihrn "Log(Hourly Wage)"
local working_ftn "Working Full-Time"
local working_ptn "Working Part-Time"
local unemployedn "Unemployed"
local partly_retiredn "Partly-Retired"
local retiredn "Retired"
local disabledn "Disabled"
local not_in_lbrfn "Not in Labor Force"
local hisdin "Household SSDI Income"
local hissin "Household SSI Income"
local hiunemn "Household Unemployment Income"
local hisretn "Household SS Retirement Income"

* Set subtitles for each sample
local age60to64_INSn "Age 60 to 64 Insured"
local over65n "Elderly"
local under60_INSn "Non-Elderly Insured (Under 60)"

* Set the y-axes for the primary outcomes for comparability across samples/specifications
local oop_spendy "ylabel(-500(500)2500,nogrid)"
local riearnsempy "ylabel(-20000(5000)5000,nogrid)"
local siearnsempy "ylabel(-15000(5000)5000,nogrid)"
local hgovty "ylabel(-2000(2000)10000,nogrid)"
local hitoty "ylabel(-20000(10000)10000,nogrid)"

* Set the length of the window on either side of the hospitalization (balanced panel is shorter)
local range_freq 3
local range_bal 2
local range_incamsc 3

* Set samples, spousal requirement, FE, and specification
foreach samp in over65 age60to64_INS under60_INS {
foreach spouse in freq {
foreach fe in cohortXwave { 
foreach spec in freq { 

* Import data to calculate pre-hospitalization mean
use "/Users/kluender/Desktop/HRS/HRS_long.dta" if ever_hospitalized==1 & `samp'==1 & `spouse'==1 & evt_time==-1, clear

* Calculate pre-hospitalization mean, round, and store in local
foreach var in `list' {
	sum `var' [aweight=rwtresp]
	
	if r(mean)<1000 {
		local `var'_mean = string(r(mean),"%12.1fc")
	}
	else {
		local `var'_mean = string(r(mean),"%12.0fc")
	}
}

* Import the parameteric event study results in order to obtain the trend line
insheet using "HRS_ES_coefs_`samp'_`spouse'_`spec'_FE`fe'.txt", clear

keep if inlist(var,"evt_time","_cons","evt_l1","evt_l0","N","Indiv")==1

replace var = "_cons_linear" if var=="_cons"
replace var = "est0" if var=="evt_l0"
replace var = "est1" if var=="evt_l1"

tempfile trend
save `trend'

* Import the non-parameteric event study results to obtain the points
insheet using "HRS_FullES_coefs_`samp'_`spouse'_`spec'_FE`fe'.txt", clear

keep if regexm(var, "evt_")==1|var=="_cons"

replace var=substr(var, 5, .) if var!="_cons"
replace var=regexr(var, "f", "-")
replace var=regexr(var, "l", "")
replace var = "-1" if var=="_cons"
destring var, gen(diff)

* Combine them
append using `trend'

foreach var in `list' {
	
	* Add constant to non-parametric coefficients
	sum `var' if diff==-1
	local constant = r(mean)
	
	sum `var' if var=="_cons_linear"
	local constant2 = r(mean)	
	
	replace `var' = 0 if diff==-1

	* Generate counterfactual trend based on trend estimates
	sum `var' if var=="evt_time"
	local est = r(mean)

	gen p`var' = `constant2'-`constant' + diff*`est'
}

tempfile points
save `points'

* Pull in standard errors for confidence intervals
insheet using "HRS_FullES_ses_`samp'_`spouse'_`spec'_FE`fe'.txt", clear

keep if inlist(var,"evt_l1_evt_l1","evt_l0_evt_l0","evt_l2_evt_l2","evt_l3_evt_l3")==1 | ///
	inlist(var,"evt_f2_evt_f2","evt_f3_evt_f3")==1

append using `points'
gen year = 2*diff + 1

foreach var in `list' {
	
	replace `var' = sqrt(`var') if inlist(var,"evt_f2_evt_f2","evt_f3_evt_f3","evt_l1_evt_l1","evt_l0_evt_l0","evt_l2_evt_l2","evt_l3_evt_l3")==1
	
	sum `var' if var=="evt_f3_evt_f3"
	local sen3 = r(mean)
	sum `var' if var=="evt_f2_evt_f2"
	local sen2 = r(mean)
	sum `var' if var=="est1"
	local est1 = string(r(mean),"%7.0gc")
	sum `var' if var=="evt_l1_evt_l1"
	local se1 = round(r(mean),0.001)
	sum `var' if var=="est0"
	local est0 = string(r(mean),"%7.0gc")
	sum `var' if var=="evt_l0_evt_l0"
	local se0 = round(r(mean),0.001)
	sum `var' if var=="evt_l2_evt_l2"
	local se2 = r(mean)	
	sum `var' if var=="N"
	local N = string(r(mean),"%7.0gc")
	sum `var' if var=="Indiv"
	local I = string(r(mean),"%7.0gc")

	* Generate confidence intervals
	gen `var'_lb = .
		replace `var'_lb = `var' - 1.96*`sen3' if diff==-3
		replace `var'_lb = `var' - 1.96*`sen2' if diff==-2		
		replace `var'_lb = `var' - 1.96*`se0' if diff==0
		replace `var'_lb = `var' - 1.96*`se1' if diff==1
		replace `var'_lb = `var' - 1.96*`se2' if diff==2
	gen `var'_ub = .
		replace `var'_ub = `var' + 1.96*`sen3' if diff==-3
		replace `var'_ub = `var' + 1.96*`sen2' if diff==-2		
		replace `var'_ub = `var' + 1.96*`se0' if diff==0
		replace `var'_ub = `var' + 1.96*`se1' if diff==1
		replace `var'_ub = `var' + 1.96*`se2' if diff==2
	
	if ("`spec'"=="freq") {
		sum `var' if var=="evt_l3_evt_l3"
		local se3 = r(mean)
		replace `var'_lb = `var' - 1.96*`se3' if diff==3
		replace `var'_ub = `var' + 1.96*`se3' if diff==3
	}
	
	local se0 = string(`se0',"%7.0gc")
	local se1 = string(`se1',"%7.0gc")

	sort diff
	di "``samp'n' `spousetitle'"
	* Plot
	twoway (line p`var' diff, lwidth(medthick) lpattern(longdash) lcolor(gs5)) /// 
		(scatter `var'_lb diff, msymbol(circle_hollow) mcolor(gs9)) ///
		(scatter `var'_ub diff, msymbol(circle_hollow)  mcolor(gs9)) /// 
		(scatter `var' diff if year~=., mcolor(maroon) yline(0, lcolor(gs13)) ///
		xline(-.5, lc(gs13))  xlabel(-3(1)3) ///
		ytitle("") title("``var'n'") leg(off) ///
		xtitle("Survey Wave relative to Hospitalization") ylabel(,nogrid) ``var'y' ///
		graphregion(fcolor(white)) ///
		caption("Pre-Hospitalization Mean = ``var'_mean'"))
	 graph export "../Figures/HRS_`samp'_`spouse'_`spec'_FE`fe'_`var'.pdf", replace	
	 
} // foreach var
} // foreach samp
} // foreach spouse
} // foreach spec
} // fe



























