***********************************************************
* NOTE: THIS IS CODE FOR THE NOVEMBER 2015 TRIP TO OSHPD. *
***********************************************************

* Preliminaries
clear
set more off
set matsize 9000
capture log close
cd "C:\Data\Secure\To Save"
set rmsg on
log using "C:\Research\Health Insurance and Financial Protection\2. Analysis August 20 2015\Logs\P08a Data Prep Aug2015.log", replace

* Pull in the most recent version of the hospitalizations-credit report merge
* Note: This includes only hospitalizations which are the first in the last 3 years for an individual
use pdd_TU_03_07_f3year_new.dta, clear

***********************************************************************
* STEP 1: INITIAL DROPS - Pregnancies and Subsequent Hospitalizations *
***********************************************************************

* Keeping only prime-aged and elderly
keep if agyradm>=25

* Drop MDC codes 14 and 15 (pregnancy)
tab mdc, mi
drop if mdc==15 
drop if mdc==14

* Formatting the admission date
gen admit_date = date(admtdate, "MDY")
format admit_date %td

* Check that admission dates are unique after cleaning
duplicates report unique_id admit_date year_tu

* Tag and assess frequency of multiple hospitalizations
sort unique_id admit_date
by unique_id admit_date: gen hosp=1 if _n==1
by unique_id: egen initial_num_hosps=total(hosp)
duplicates report unique_id year_tu
sum initial_num_hosps

* Tag and keep only first hospitalization
by unique_id: egen first_admitdate = min(admit_date)
keep if admit_date==first_admitdate
by unique_id: egen num_hosps=total(hosp)
sum num_hosps
assert num_hosps==1

* Double-check that we have one hospitalization per individual
duplicates report unique_id year_tu

* Drop intermediate variables
drop hosp initial_num_hosps num_hosps

********************************************************
* STEP 2: DROP VARIABLES WE'RE NO LONGER INTERESTED IN *
********************************************************

* Drop variables we're no longer interested in
drop z1b_any_coll_6m z1b_any_coll_24m z1b_any_coll_36m ///
	z1b_any_med_coll_6m z1b_any_med_coll_24m z1b_any_med_coll_36m ///
	z1b_any_nonmed_coll_6m z1b_any_nonmed_coll_24m z1b_any_nonmed_coll_36m ///
	z2b_any_bkrt_24m z2b_any_foreclosure_hown_24m z2b_any_foreclosure_all_24m ///
	z2b_any_lien_24m z4b_any_repossess_24m *_mop02 *_mop03 *_mop04 *mop05 ///
	z4b_rev_trade_chgoff z4b_mort_trade_chgoff z4b_installment_trade_chgoff ///
	z4b_any_rev_trade_chgoff z4b_any_mort_trade_chgoff z4b_any_installment_trade_chgoff

* Fixing too long variable name
rename z2a_total_balance_all_revolving z2a_tot_bal_all_rev	

* Add variables to analysis
rename z4b_any_inquiries z3a_any_inquiries
	
****************************************
* STEP 3: CODE UP ADDITIONAL VARIABLES *
****************************************

* Credit score grades
gen z3a_credit_score_A = z3a_credit_score>900 & z3a_credit_score<=990 if z3a_credit_score~=.
gen z3a_credit_score_B = z3a_credit_score>800 & z3a_credit_score<=900 if z3a_credit_score~=.
gen z3a_credit_score_C = z3a_credit_score>700 & z3a_credit_score<=800 if z3a_credit_score~=.
gen z3a_credit_score_D = z3a_credit_score>600 & z3a_credit_score<=700 if z3a_credit_score~=.
gen z3a_credit_score_F = z3a_credit_score>500 & z3a_credit_score<=600 if z3a_credit_score~=.

* Code up "ever" variables to reflect full past history, exploiting panel data
foreach var in z1a_any_coll z1a_any_med_coll z1a_any_nonmed_coll z2a_any_bkrt z2b_any_foreclosure_all ///
z2b_any_foreclosure_hown z2b_any_lien { 
	di "`var'"
	cap drop `var'_ever
	gen `var'_ever = 0
	sort unique_id diff
	by unique_id: replace `var'_ever = `var'_12m if _n==1
	by unique_id: replace `var'_ever = 1 if (`var'_12m==1|`var'_ever[_n-1]==1) & _n!=1
}
foreach var in z1a_num_coll z1a_num_med_coll z1a_num_nonmed_coll { 
	di "`var'"
	sort unique_id diff
	gen `var'_ever = 0
	by unique_id: replace `var'_ever = `var'_12m if _n==1
	by unique_id: replace `var'_ever = `var'_12m + `var'_ever[_n-1] if _n!=1
}

* Generating new "insured" category
gen pv_plus_mc = (medicaid|private)


***************************
* STEP 4: CENSOR OUTLIERS *
***************************
foreach var of varlist z1* z2* z3* z4* {

	* Tag whether the variable is continuous in order to censor it
	count if `var' < .
	local N = r(N)
	count if `var' == 1
	local N1 = r(N)
	count if `var' == 0
	local N0 = r(N)
	local dummy = (`N0' + `N1' == `N')

	* Censor only if it is not an indicator variable at the 99.95th percentile
	if (`dummy' == 0) {
		_pctile `var' [aw=represents_exact] if !missing(`var'), percentiles(99.95)
		local pct9995 = r(r1)
		di "99.95 percentile of `var' is `pct9995'"
		sum `var', det
		replace `var' = `pct9995' if `var'>`pct9995' & `var'!=.
		di "`var' was censored at `pct9995'"
		sum `var', det
	}
}

**************************
* STEP 5: CODE UP DEATHS *
**************************

* Generate death date from vital stats
gen death_date_fordrop = date(death_date_any, "DM20Y")
format death_date_fordrop %td

gen death_year_fordrop = year(death_date_fordrop)
gen month_of_death = month(death_date_fordrop)

* Rename vital stats died variable
rename died died_vital_ever

* Finally, generate a "died" variable that turns on if any of the vital stats,
	* hospitalization records, or TU records is turned on:
gen died = death_year_fordrop<year_tu
	replace died = 1 if death_year_fordrop==year_tu & month_of_death==1 & died==0

* Check "died" is coded correctly 
* i.e. once you are dead, you stay dead, also that you are alive in the first observation
sort unique_id year_tu diff, stable
by unique_id: assert died==1 if (died[_n-1]==1 & _n!=1)
gen alive=!died
tab diff died

* Generate our death variable for ever died 
by unique_id: egen died_ever=max(died)
tab diff died_ever

* DROP DEAD
drop if died

* Keep only the length of the panel we analyze
keep if diff>-48 & diff<=72

**********************************
* STEP 6: CODE UP SAMPLE WEIGHTS *
**********************************

* Goal of this exercise is to reweight the non-elderly uninsured and the elderly to
* match the non-elderly insured on demographics, median household income for their
* zip code, and some hospitalization characteristics (MDC, chronic indicator)

* Generate dummies for major diagnostic categories
cap drop _I*
xi i.mdc

* Generating p-score weights to match uninsured to insured insurance types
logit pv_plus_mc _I* agyradm male hispanic black white hhinc2011 chronic_any_icd [pweight=represents_exact] if (pv_plus_mc==1|self_pay==1) & agyradm<65
	gen weight_sample = (e(sample)==1)
	predict p	
	gen wlogit=p/(1-p) if self_pay==1 & agyradm<65
	gen weight_SPtoINS = wlogit*represents_exact if self_pay & agyradm<65
		replace weight_SPtoINS =represents_exact if pv_plus_mc & agyradm<65
		replace weight_SPtoINS = . if weight_sample==0
drop p wlogit weight_sample

* Generating p-score weights to match 65+ to 25-64 insured
gen INS_25to64 = pv_plus_mc & agyradm>=25 & agyradm<65
logit INS_25to64 _I* male hispanic black white hhinc2011 chronic_any_icd [pweight=represents_exact] if (INS_25to64==1|agyradm>=65)
	gen weight_sample = (e(sample)==1)
	predict p	
	gen wlogit=p/(1-p) if agyradm>=65
	gen weight_65toINS = wlogit*represents_exact if agyradm>=65
		replace weight_65toINS=represents_exact if INS_25to64==1
		replace weight_65toINS= . if weight_sample==0
drop p wlogit weight_sample

*****************************************************
* STEP 7: CODE UP SUBSAMPLES OF THE BASELINE SAMPLE *
*****************************************************

* Generating predicted financial severity (charges) 
gen log_charges = log(charge_tot+1)
gen log_LOS = log(los+1)
areg log_charges _I* log_LOS [aweight=represents_exact] if charge_tot>=500 & diff<=-12 & diff>=-23, absorb(proc_p)
predict financial_severity
xtile pcharge_quartile = financial_severity [aweight=represents_exact], nq(4)

* Predict mortality 
drop _I*
xi i.agyradm
areg died_ever _I* if diff<=-12 & diff>=-23, absorb(drg)
predict died_hat, xbd
xtile pred_mort_quartile = died_hat, n(4)
drop _I*

* Car Crashes
gen car_accident = 0
forv e = 8100/8259 {
	replace car_accident = 1 if ecode_p=="E`e'"
}

* All External Injuries, Cancer, AMIs
gen external_injury = ecode_p!=""
gen icd_2 = substr(diag_p,1,2)
gen icd_3 = substr(diag_p,1,3)
gen cancer = inlist(icd_2,"14","15","16","17","18","19","20","21","22")
	replace cancer = 1 if icd_2=="23"
gen ami = 0 
	replace ami = 1 if icd_3=="410"
drop icd_2 icd_3

* Save out 25+ dataset
saveold pdd_TU_25plus_Aug2015.dta, replace

* Save out 25-64 sample
keep if agyradm<65
saveold pdd_TU_25to64_Aug2015.dta, replace

* Save out 65+ sample
use pdd_TU_25plus_Aug2015 if agyradm>=65, clear
saveold pdd_TU_65plus_Aug2015.dta, replace

*****************************
* STEP 8: CODE UP RD SAMPLE *
*****************************

* Pull in cleaned data
use pdd_TU_25plus_Aug2015 if diff>-48 & diff<=72 & agyradm >= 60 & agyradm <= 70, clear

gen pre_partD = admtyear<2006
gen post_partD = admtyear>2006

* Create variables for quadratic RD specification
gen rel_bthdate = mdy(month(admit_date),1,year(admit_date)) - mdy(month(bthdate),1,year(bthdate))
* Format relative birthdate at a monthly level
format rel_bthdate %tm

* Check relative birthday is coded correctly:
tab rel_bthdate, mi
* Also check against the age variable as a sanity check in the data

* Subtract number of months to 65 to center
gen age_centered = rel_bthdate - 780
gen over65 = (age_centered >= 0)
gen ageXover65 = age_centered * over65
gen age_centered2 = age_centered * age_centered
gen age2Xover65 = (age_centered)^2 * over65

* Generate indicator for being insured
gen insured = medicaid|private|medicare

* Normalize variables by pre-hospitalization observation
foreach var of varlist z1a* z2a* z3a* {
	gen pre_obs = `var' if y_diff==-1
	bysort unique_id: egen temp = min(pre_obs)
	gen d`var' = `var' - temp
	drop pre_obs temp
	* Recode this to be missing for pre-hospitalization observations
	replace d`var' = . if y_diff<0
}

saveold pdd_TU_RD_sample_Oct2015, replace

**********************************
* STEP 9: CODE UP BALANCED PANEL *
**********************************

use pdd_TU_25plus_Aug2015.dta, clear

*Limit Panel
keep if diff>-24 & diff<=48

* Drop people who have died within 48 months of the hospitalization
drop if died48mo==1

/* Note we used to drop individuals missing ANY variable
 This severely limited the sample because the medical and non-medical collections variables
 are missing for all of the years up to 2005 so we basically could only use 2006 and 2007 
 admissions and had to drop 2003-2005.
 
 The medical collections variable dropped 2.1 million observations. Later credit score also
 dropped 260K observations.
 
 Now we want to limit the sample only by dropping only individuals missing standard variables
 for parts of the panel (e.g. collections balance). */
 
foreach var of varlist z1a_num_coll_ever z1a_num_med_coll_ever z1a_num_nonmed_coll_ever ///
	z1a_coll_bal z3a_credit_score z2a_any_bkrt_ever z3a_cred_limit_v2 ///
	z3a_num_auto_trades z3a_auto_trade_balance z2a_tot_bal_all_rev {

	gen m`var'=(`var'==.)
	bysort unique_id: egen t`var'=total(m`var')
	di "drop missing observations for `var'"
	drop if t`var'>0
	drop m`var' t`var'

}

*Assert balanced
bysort unique_id: egen panel=count(diff)
tab panel
drop if panel!=6

tab year_tu admtyear

saveold pdd_TU_ES_fullbal_Aug2015.dta, replace

****************************************************
* STEP 10: CODE UP LONG POST-PERIOD BALANCED PANEL *
****************************************************

use pdd_TU_25plus_Aug2015.dta, clear

*Limit Panel
keep if diff>-24 & diff<=72

* Drop people who have EVER DIED
drop if died_ever==1

* Drop individuals who are missing any of the core variables at any point in the long balanced panel 
foreach var of varlist z1a_num_coll_ever z1a_num_med_coll_ever z1a_num_nonmed_coll_ever ///
	z1a_coll_bal z3a_credit_score z2a_any_bkrt_ever z3a_cred_limit_v2 ///
	z3a_num_auto_trades z3a_auto_trade_balance z2a_tot_bal_all_rev {

	gen m`var'=(`var'==.)
	bysort unique_id: egen t`var'=total(m`var')
	di "drop missing observations for `var'"
	drop if t`var'>0
	drop m`var' t`var'

}

*Assert balanced
bysort unique_id: egen panel=count(diff)
tab panel
drop if panel!=8

tab year_tu admtyear

saveold pdd_TU_ES_longpostbal_Aug2015.dta, replace

****************************************************
* STEP 11: CODE UP LONG PRE-PERIOD BALANCED PANEL *
****************************************************

use pdd_TU_25plus_Aug2015.dta, clear

*Limit Panel
keep if diff>-48 & diff<=48

* Drop people who have EVER DIED
drop if died48mo==1

* Drop individuals who are missing any of the core variables at any point in the long balanced panel 
foreach var of varlist z1a_num_coll_ever z1a_num_med_coll_ever z1a_num_nonmed_coll_ever ///
	z1a_coll_bal z3a_credit_score z2a_any_bkrt_ever z3a_cred_limit_v2 ///
	z3a_num_auto_trades z3a_auto_trade_balance z2a_tot_bal_all_rev {

	gen m`var'=(`var'==.)
	bysort unique_id: egen t`var'=total(m`var')
	di "drop missing observations for `var'"
	drop if t`var'>0
	drop m`var' t`var'

}

*Assert balanced
bysort unique_id: egen panel=count(diff)
tab panel
drop if panel!=8

tab year_tu admtyear

saveold pdd_TU_ES_longprebal_Aug2015.dta, replace

log close

