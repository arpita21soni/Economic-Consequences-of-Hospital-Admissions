/*
	This code make an extension to "The Economic Consequences of Hospital 
Admissions" by Carlos Dobkin, Amy Finkelstein, Raymond Kluender, and Matthew J. Notowidigdo using the HRS portion of the replication kit.
The extension consist in an alternative estimation of the event study empirical strategy using the method of Borusyak, Jaravel, and Spiess, "Revisiting Event Study Designs: Robust and Efficient Estimation" (2021)
.
	
	Date: 05/04/2021
	Author: Leonardo Urrea R. (University of Pittsburgh), IVU1@pitt.edu
	
	You'll use the following commands:
		- did_imputation (Borusyak et al. 2021): available on SSC
		- did_multiplegt (de Chaisemartin and D'Haultfoeuille 2020): available on SSC
		- eventstudyinteract (San and Abraham 2020): available on SSC
		- csdid (Callaway and Sant'Anna 2020): available on SSC

*/



* Preliminaries
set more off, perm
clear all
set maxvar 30000
set seed 19890929

* Set directory to the location of the replication kit
cd "C:\Users\arpit\OneDrive - University of Pittsburgh\Empirical Methods Project\extension_data\HRS_long.dta"

* Import and clean 

use "HRS_long.dta", clear

* keep if ever_hospitalized == 1 & under60_control == 0

 keep if ever_hospitalized == 1 & under60_INS == 1 


* SUMMARY STATISTICS FOR ALL SAMPLES
local samples "under60_INS over65 age60to64_INS under65_INS under60_control over65_control under60_death over65_death under65_INS_nopre over65_nopre"
local spouses "freq"
local fes "cohortXwave"
local specs "freq"
local outcomes "oop_spend age_hosp working riearnsemp siearnsemp hgovt hitot_old log_hitot_old hitot_inc hitot_exc log_hitot_inc log_hitot_exc riearn_c"

// Out of Pocket Spending

// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation oop_spend hhidpn wave first_hosp, allhorizons pretrend(3) autosample
event_plot, default_look graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") ///
	title("Out-of-Pocket Spending INS" ) xlabel(-3(1)10))
	
// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation oop_spend hhidpn wave first_hosp, horizons(0/3) pretrend(3) autosample  controls(risemp sisemp hisemp a_risemp a_sisemp a_hisemp)
event_plot, default_look graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") ///
	title("Out-of-Pocket Spending" ) xlabel(-3(1)5))

	// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation oop_spend hhidpn wave first_hosp, horizons(0/3) pretrend(3) autosample  fe(hhidpn)
event_plot, default_look graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") ///
	title("Out-of-Pocket Spending" ) xlabel(-3(1)5))
	
// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation oop_spend hhidpn wave first_hosp, horizons(0/3) pretrend(3) autosample
event_plot, default_look graph_opt(xtitle("Survey wave relative to hospitalization") ytitle("Average causal effect") ///
	title("Out-of-Pocket Spending INS" ) xlabel(-3(1)4))
	
	// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation oop_spend hhidpn wave first_hosp, horizons(0/4) pretrend(3) autosample nose
event_plot, default_look graph_opt(xtitle("Survey wave relative to hospitalization") ytitle("Average causal effect") ///
	title("Out-of-Pocket Spending INS" ) xlabel(-3(1)4))
	
	"risemp","sisemp","hisemp","a_risemp","a_sisemp","a_hisemp"
	
		// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation oop_spend hhidpn wave first_hosp, horizons(0/4) pretrend(3) autosample tol(0.0000001) maxit(1000) controls(risemp sisemp hisemp a_risemp a_sisemp a_hisemp) fe(hhidpn wave)
event_plot, default_look graph_opt(xtitle("Survey wave relative to hospitalization") ytitle("Average causal effect") ///
	title("Out-of-Pocket Spending INS" ) xlabel(-3(1)4))
	
		// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation oop_spend hhidpn wave first_hosp, horizons(0/4) pretrend(3) autosample tol(0.0000001) maxit(1000)
event_plot, default_look graph_opt(xtitle("Survey wave relative to hospitalization") ytitle("Average causal effect") ///
	title("Out-of-Pocket Spending INS" ) xlabel(-3(1)4))

		// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation oop_spend hhidpn wave first_hosp, horizons(0/4) pretrend(3) autosample nose controls
event_plot, default_look graph_opt(xtitle("Survey wave relative to hospitalization") ytitle("Average causal effect") ///
	title("Out-of-Pocket Spending INS" ) xlabel(-3(1)4))
	
// Earnings 


// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation riearn_c hhidpn wave first_hosp, horizons(0/4) pretrend(3) autosample tol(0.0000001) maxit(1000) controls(risemp sisemp hisemp a_risemp a_sisemp a_hisemp) fe(hhidpn wave)
event_plot, default_look graph_opt(xtitle("Survey wave relative to hospitalization") ytitle("Average causal effect") ///
	title("Respondent Earnings INS" ) xlabel(-3(1)4))

// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation riearn_c hhidpn wave first_hosp, horizons(0/4) pretrend(3) autosample tol(0.0000001) maxit(1000)
event_plot, default_look graph_opt(xtitle("Survey wave relative to hospitalization") ytitle("Average causal effect") ///
	title("Respondent Earnings INS" ) xlabel(-3(1)4))

// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation riearn_c hhidpn wave first_hosp, horizons(0/4) pretrend(3) autosample nose
event_plot, default_look graph_opt(xtitle("Survey wave relative to hospitalization") ytitle("Average causal effect") ///
	title("Respondent Earnings INS" ) xlabel(-3(1)4))
	
// Working Part or Full Time 

// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation working hhidpn wave first_hosp, horizons(0/4) pretrend(3) autosample tol(0.0000001) maxit(1000) controls(risemp sisemp hisemp a_risemp a_sisemp a_hisemp) fe(hhidpn wave)
event_plot, default_look graph_opt(xtitle("Survey wave relative to hospitalization") ytitle("Average causal effect") ///
	title("Working Part- or Full- Time INS" ) xlabel(-3(1)4))

// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation working hhidpn wave first_hosp, horizons(0/4) pretrend(3) autosample
event_plot, default_look graph_opt(xtitle("Survey wave relative to hospitalization") ytitle("Average causal effect") ///
	title("Working Part- or Full- Time INS" ) xlabel(-3(1)4))
	
	// Estimation with did_imputation of Borusyak et al. (2021) 
did_imputation working hhidpn wave first_hosp, horizons(0/4) pretrend(3) autosample tol(0.0000001) maxit(1000)
event_plot, default_look graph_opt(xtitle("Survey wave relative to hospitalization") ytitle("Average causal effect") ///
	title("Working Part- or Full- Time INS" ) xlabel(-3(1)4))
		
		
// Spousal Earnings

// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation siearnsemp hhidpn wave first_hosp, horizons(0/4) pretrend(3) autosample tol(0.0000001) maxit(1000) controls(risemp sisemp hisemp a_risemp a_sisemp a_hisemp) fe(hhidpn wave)
event_plot, default_look graph_opt(xtitle("Survey wave relative to hospitalization") ytitle("Average causal effect") ///
	title("Spousal Earnings INS" ) xlabel(-3(1)4))


// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation siearnsemp hhidpn wave first_hosp, horizons(0/4) pretrend(3) autosample tol(0.0000001) maxit(1000)
event_plot, default_look graph_opt(xtitle("Survey wave relative to hospitalization") ytitle("Average causal effect") ///
	title("Spousal Earnings INS" ) xlabel(-3(1)4))

// Household Social Insurance Payments

// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation hgovt hhidpn wave first_hosp, horizons(0/4) pretrend(3) autosample tol(0.0000001) maxit(1000) controls(risemp sisemp hisemp a_risemp a_sisemp a_hisemp) fe(hhidpn wave)
event_plot, default_look graph_opt(xtitle("Survey wave relative to hospitalization") ytitle("Average causal effect") ///
	title("Household Social Insurance Payments INS" ) xlabel(-3(1)4))

// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation hgovt hhidpn wave first_hosp, horizons(0/4) pretrend(3) autosample tol(0.0000001) maxit(1000)
event_plot, default_look graph_opt(xtitle("Survey wave relative to hospitalization") ytitle("Average causal effect") ///
	title("Household Social Insurance Payments INS" ) xlabel(-3(1)4))
	
	// Household Social Insurance Payments

// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation hitot_inc hhidpn wave first_hosp, horizons(0/4) pretrend(3) autosample tol(0.0000001) maxit(1000)
event_plot, default_look graph_opt(xtitle("Survey wave relative to hospitalization") ytitle("Average causal effect") ///
	title("Household Total Income INS" ) xlabel(-3(1)4))
	
	
