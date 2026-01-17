***************************************************************************************************
* This program takes the RAND HRS data (which is produced as a wide file with one observation for *
* each individual and variables labeled to correspond to their survey wave), processes and cleans *
* the variables, and changes the file from wide to long (with an observation as a person-wave) to *
* facilitate regression analysis.                                                                 *
***************************************************************************************************


* Preliminaries
set more off, perm
clear all
set maxvar 30000
set seed 19890929

* Set directory to the location of the replication kit
cd "/Users/kluender/Desktop/DFKN Replication Kit/HRS/Data"

* Import and clean the income and wealth imputation supplement
* We use the supplement to redefine earnings to include self-employment
use "incwlth_o.dta", clear

* Keep variables of interest from the income and wealth supplement
* See included documentation for variable definitions (or variable labels)
keep hhidpn H*IBUSIN H*IRNTIN H*ITRSIN H*IDIVIN H*IBNDIN H*ISTK* H*ICHKIN H*ISAV* H*ICDIN R*IIRA* H*IOTHI* ///
	R*ISEMP S*ISEMP H*IFBUSIN H*IFCAP R*IFSEMP S*IFSEMP
rename *, lower

tempfile income
save `income', replace

* Import the main RAND HRS file
use "rndhrs_o.dta", clear

* Keep only the variables we need
keep hhid* rabyear rabmonth rabdate hacohort r*hosp r*hsptim r*hspnit r*lbrf s*lbrf r*retmon r*retyr ///
	r*age* s*age* r*iearn s*iearn h*icap radmonth raddate radyear r*iwstat s*iwstat raeduc ///
	*iwbeg* *iwmid* *iwend *iwendm *iwendy r*wg* r*wt* r*oopmd r*totmb r*totmbi r*jweek* ///
	r*higov s*higov r*govmd r*govva r*govmr r*govot r*covr s*covr r*covs r*henum r*hiothp ///
	r*hltcf r*hltc r*hlthlm h*itot r*inlbrf r*jhours r*jhour2 r*jphys r*jlift r*jcten ///
	r*ipena r*ipen r*issdi r*isdi r*issi r*isret r*iunwc r*iunem raracem rahispan ///
	h*icap s*ipena s*isdi s*issi s*iunem s*issdi s*isret s*iunwc r*igxfr s*igxfr ///
	h*iothr r*slfemp s*slfemp h*atota r*mstat r*hibpe r*diabe r*cancre r*lunge r*hearte ///
	r*stroke r*psyche r*arthre r*cenreg r*cendiv

* Merge in the income and wealth supplement 
merge 1:1 hhidpn using `income', nogen assert(match)

* Dropping individuals with hospitalizations in wave 1 (no pre-period observation):
gen early_hosp = r1hosp==1
	tab hacohort early_hosp, mi
drop if early_hosp

* Define individuals based on whether we ever observe a hospitalization in their panel
gen ever_hospitalized = 0
forv wave = 1/11 {
	gen r`wave'hospitalized = r`wave'hosp==1
		replace ever_hospitalized = 1 if r`wave'hospitalized==1
} 

* Remove the wave reference for the waves of the survey we want in a long file so we can stack them
forv wave = 1/11 {

preserve
	
	* Keeping wave specific variables because some are not observed in all waves
	if (`wave'==1) {
		keep ra* hhidpn hacohort h`wave'* r`wave'mstat r`wave'cenreg r`wave'cendiv ///
		r`wave'hosp r`wave'hsptim r`wave'hspnit r`wave'lbrf s`wave'lbrf r`wave'retmon r`wave'retyr ///
		r`wave'age* s`wave'age* r`wave'iearn s`wave'iearn radmonth raddate radyear r`wave'iwstat s`wave'iwstat ///
		r`wave'iwbeg r`wave'iwmid r`wave'iwend r`wave'iwendm r`wave'iwendy r`wave'wg* r`wave'wt* ever_* ///
		r`wave'oopmd r`wave'higov r`wave'govmd r`wave'govmr r`wave'govva raeduc ///
		r`wave'covr r`wave'covs r`wave'henum r`wave'hiothp r`wave'hltc r`wave'hlthlm r`wave'inlbrf ///
		r`wave'jhours r`wave'jhour2 r`wave'jweeks r`wave'jweek2 r`wave'jphys r`wave'jlift r`wave'jcten raracem rahispan r`wave'slfemp s`wave'slfemp ///
		r`wave'ipena r`wave'ipen r`wave'issdi r`wave'isdi s`wave'isdi r`wave'issi r`wave'isret r`wave'iunwc r`wave'iunem ///
		s`wave'ipena s`wave'issdi s`wave'isret s`wave'iunwc r`wave'igxfr s`wave'igxfr s`wave'issi s`wave'iunem ///
		r`wave'hibpe r`wave'diabe r`wave'cancre r`wave'lunge r`wave'hearte r`wave'stroke r`wave'psyche r`wave'arthre
		
		* Drop variables from later waves that get included with the h1* list
		drop h10*
		drop h11*
	}
	if (`wave'==2) {
		keep ra* hhidpn hacohort h`wave'* r`wave'mstat r`wave'cenreg r`wave'cendiv ///
		r`wave'hosp r`wave'hsptim r`wave'hspnit r`wave'lbrf s`wave'lbrf r`wave'retmon r`wave'retyr ///
		r`wave'age* s`wave'age* r`wave'iearn s`wave'iearn radmonth raddate radyear r`wave'iwstat s`wave'iwstat ///
		r`wave'iwbeg r`wave'iwmid r`wave'iwend r`wave'iwendm r`wave'iwendy r`wave'wg* r`wave'wt* ever_* ///
		r`wave'oopmd r`wave'higov r`wave'govmd r`wave'govmr r`wave'govva raeduc ///
		r`wave'covr r`wave'covs r`wave'henum r`wave'hiothp r`wave'hltc r`wave'hlthlm r`wave'inlbrf ///
		r`wave'jhours r`wave'jhour2 r`wave'jweeks r`wave'jweek2 r`wave'jphys r`wave'jlift r`wave'jcten raracem rahispan r`wave'slfemp s`wave'slfemp ///
		r`wave'ipena r`wave'ipen r`wave'issdi r`wave'isdi s`wave'isdi r`wave'issi r`wave'isret r`wave'iunwc r`wave'iunem ///
		s`wave'ipena s`wave'issdi s`wave'isret s`wave'iunwc r`wave'igxfr s`wave'igxfr ///
		r`wave'iira1 r`wave'iira2  s`wave'issi s`wave'iunem ///
		r`wave'hibpe r`wave'diabe r`wave'cancre r`wave'lunge r`wave'hearte r`wave'stroke r`wave'psyche r`wave'arthre
	}
	if (`wave'==3) {
		keep ra* hhidpn hacohort h`wave'* r`wave'mstat r`wave'cenreg r`wave'cendiv ///
		r`wave'hosp r`wave'hsptim r`wave'hspnit r`wave'lbrf s`wave'lbrf r`wave'retmon r`wave'retyr ///
		r`wave'age* s`wave'age* r`wave'iearn s`wave'iearn radmonth raddate radyear r`wave'iwstat s`wave'iwstat ///
		r`wave'iwbeg r`wave'iwmid r`wave'iwend r`wave'iwendm r`wave'iwendy r`wave'wg* r`wave'wt* ever_* ///
		r`wave'oopmd r`wave'higov r`wave'govmd r`wave'govmr r`wave'govva ///
		r`wave'covr r`wave'covs r`wave'henum r`wave'hiothp r`wave'hltc r`wave'hlthlm r`wave'inlbrf ///
		r`wave'jhours r`wave'jhour2 r`wave'jweeks r`wave'jweek2 r`wave'jphys r`wave'jlift r`wave'jcten raracem rahispan r`wave'slfemp s`wave'slfemp ///
		r`wave'ipena r`wave'ipen r`wave'issdi r`wave'isdi s`wave'isdi r`wave'issi r`wave'isret r`wave'iunwc r`wave'iunem ///
		s`wave'ipena s`wave'issdi s`wave'isret s`wave'iunwc r`wave'igxfr s`wave'igxfr r`wave'isemp s`wave'isemp ///
		r`wave'ifsemp s`wave'ifsemp s`wave'issi s`wave'iunem raeduc ///
		r`wave'hibpe r`wave'diabe r`wave'cancre r`wave'lunge r`wave'hearte r`wave'stroke r`wave'psyche r`wave'arthre
	}
	if (`wave'==4) {
		keep ra* hhidpn hacohort h`wave'* r`wave'mstat r`wave'cenreg r`wave'cendiv ///
		r`wave'hosp r`wave'hsptim r`wave'hspnit r`wave'lbrf s`wave'lbrf r`wave'retmon r`wave'retyr ///
		r`wave'age* s`wave'age* r`wave'iearn s`wave'iearn radmonth raddate radyear r`wave'iwstat s`wave'iwstat ///
		r`wave'iwbeg r`wave'iwmid r`wave'iwend r`wave'iwendm r`wave'iwendy r`wave'wg* r`wave'wt* ever_* ///
		r`wave'oopmd r`wave'totmb r`wave'totmbi r`wave'higov r`wave'govmd r`wave'govmr r`wave'govva ///
		r`wave'covr r`wave'covs r`wave'henum r`wave'hiothp r`wave'hltc r`wave'hlthlm r`wave'inlbrf ///
		r`wave'jhours r`wave'jhour2 r`wave'jweeks r`wave'jweek2 r`wave'jphys r`wave'jlift r`wave'jcten raracem rahispan r`wave'slfemp s`wave'slfemp ///
		r`wave'ipena r`wave'ipen r`wave'issdi r`wave'isdi s`wave'isdi r`wave'issi r`wave'isret r`wave'iunwc r`wave'iunem ///
		s`wave'ipena s`wave'issdi s`wave'isret s`wave'iunwc r`wave'igxfr s`wave'igxfr r`wave'isemp s`wave'isemp ///
		r`wave'ifsemp s`wave'ifsemp s`wave'issi s`wave'iunem raeduc ///
		r`wave'hibpe r`wave'diabe r`wave'cancre r`wave'lunge r`wave'hearte r`wave'stroke r`wave'psyche r`wave'arthre
	}
	else if inlist(`wave',5,6) {
		keep ra* hhidpn hacohort h`wave'* r`wave'mstat r`wave'cenreg r`wave'cendiv ///
		r`wave'hosp r`wave'hsptim r`wave'hspnit r`wave'lbrf s`wave'lbrf r`wave'retmon r`wave'retyr ///
		r`wave'age* s`wave'age* r`wave'iearn s`wave'iearn radmonth raddate radyear r`wave'iwstat s`wave'iwstat ///
		r`wave'iwbeg r`wave'iwmid r`wave'iwend r`wave'iwendm r`wave'iwendy r`wave'wg* r`wave'wt* ever_* ///
		r`wave'oopmd r`wave'totmb r`wave'totmbi r`wave'higov r`wave'govmd r`wave'govmr r`wave'govva ///
		r`wave'covr r`wave'covs r`wave'henum r`wave'hiothp r`wave'hltc r`wave'hlthlm r`wave'inlbrf ///
		r`wave'jhours r`wave'jhour2 r`wave'jweeks r`wave'jweek2 r`wave'jphys r`wave'jlift r`wave'jcten raracem  rahispan r`wave'slfemp s`wave'slfemp  ///
		r`wave'ipena r`wave'ipen r`wave'issdi r`wave'isdi s`wave'isdi r`wave'issi r`wave'isret r`wave'iunwc r`wave'iunem  ///
		s`wave'ipena s`wave'issdi s`wave'isret s`wave'iunwc r`wave'igxfr s`wave'igxfr r`wave'isemp s`wave'isemp ///
		r`wave'ifsemp s`wave'ifsemp s`wave'issi s`wave'iunem raeduc ///
		r`wave'hibpe r`wave'diabe r`wave'cancre r`wave'lunge r`wave'hearte r`wave'stroke r`wave'psyche r`wave'arthre
	}
	else if inlist(`wave',7,8,9,10) {
		keep ra* hhidpn hacohort h`wave'* r`wave'mstat r`wave'cenreg r`wave'cendiv ///
		r`wave'hosp r`wave'hsptim r`wave'hspnit r`wave'lbrf s`wave'lbrf r`wave'retmon r`wave'retyr ///
		r`wave'age* s`wave'age* r`wave'iearn s`wave'iearn radmonth raddate radyear r`wave'iwstat s`wave'iwstat ///
		r`wave'iwbeg r`wave'iwmid r`wave'iwend r`wave'iwendm r`wave'iwendy r`wave'wg* r`wave'wt* ever_* ///
		r`wave'oopmd r`wave'higov r`wave'govmd r`wave'govmr r`wave'govva ///
		r`wave'covr r`wave'covs r`wave'henum r`wave'hiothp r`wave'hltc r`wave'hlthlm r`wave'inlbrf ///
		r`wave'jhours r`wave'jhour2 r`wave'jweeks r`wave'jweek2 r`wave'jphys r`wave'jlift r`wave'jcten raracem  rahispan r`wave'slfemp s`wave'slfemp ///
		r`wave'ipena r`wave'ipen r`wave'issdi r`wave'isdi s`wave'isdi r`wave'issi r`wave'isret r`wave'iunwc r`wave'iunem ///
		s`wave'ipena s`wave'issdi s`wave'isret s`wave'iunwc r`wave'igxfr s`wave'igxfr r`wave'isemp s`wave'isemp ///
		r`wave'ifsemp s`wave'ifsemp s`wave'issi s`wave'iunem raeduc ///
		r`wave'hibpe r`wave'diabe r`wave'cancre r`wave'lunge r`wave'hearte r`wave'stroke r`wave'psyche r`wave'arthre
	}
	else if inlist(`wave',11) {
		keep ra* hhidpn hacohort h`wave'* r`wave'mstat r`wave'cenreg r`wave'cendiv ///
		r`wave'hosp r`wave'hsptim r`wave'hspnit r`wave'lbrf s`wave'lbrf r`wave'retmon r`wave'retyr ///
		r`wave'age* s`wave'age* r`wave'iearn s`wave'iearn radmonth raddate radyear r`wave'iwstat s`wave'iwstat ///
		r`wave'iwbeg r`wave'iwmid r`wave'iwend r`wave'iwendm r`wave'iwendy r`wave'wg* r`wave'wt* ever_* ///
		r`wave'oopmd r`wave'higov r`wave'govmd r`wave'govmr r`wave'govva ///
		r`wave'covr r`wave'covs r`wave'henum r`wave'hiothp r`wave'hltc r`wave'hlthlm r`wave'inlbrf ///
		r`wave'jhours r`wave'jhour2 r`wave'jweeks r`wave'jweek2 r`wave'jphys r`wave'jlift r`wave'jcten raracem  rahispan r`wave'slfemp s`wave'slfemp ///
		r`wave'ipena r`wave'ipen r`wave'issdi r`wave'isdi s`wave'isdi r`wave'issi r`wave'isret r`wave'iunwc r`wave'iunem  ///
		s`wave'ipena s`wave'issdi s`wave'isret s`wave'iunwc r`wave'igxfr s`wave'igxfr r`wave'isemp s`wave'isemp ///
		r`wave'ifsemp s`wave'ifsemp s`wave'issi s`wave'iunem raeduc ///
		r`wave'hibpe r`wave'diabe r`wave'cancre r`wave'lunge r`wave'hearte r`wave'stroke r`wave'psyche r`wave'arthre
	}

	gen wave = `wave'
	
	* Renaming all variables to remove the wave reference and facilitate appending
	rename r`wave'hosp rhosp
	rename r`wave'hsptim rhsptim
	rename r`wave'hspnit rhspnit
	rename r`wave'lbrf rlbrf
	rename s`wave'lbrf slbrf
	rename r`wave'retmon rretmon
	rename r`wave'retyr rretyyr
	rename r`wave'agem_e ragem_e
	rename r`wave'agem_m ragem_m
	rename r`wave'agem_b ragem_b
	rename r`wave'agey_e ragey_e
	rename r`wave'agey_m ragey_m
	rename r`wave'agey_b ragey_b
	rename s`wave'agem_e sagem_e
	rename s`wave'agem_m sagem_m
	rename s`wave'agem_b sagem_b
	rename s`wave'agey_e sagey_e
	rename s`wave'agey_m sagey_m
	rename s`wave'agey_b sagey_b
	rename r`wave'iearn riearn
	rename s`wave'iearn siearn
	rename h`wave'icap hicap 
	rename r`wave'iwstat riwstat
	rename s`wave'iwstat siwstat
	rename r`wave'iwbeg riwbegy
	rename r`wave'iwmid riwmidy
	rename r`wave'iwend riwend
	rename r`wave'iwendm riwendm
	rename r`wave'iwendy riwendy
	rename r`wave'wgiwk rwgiwk
	rename r`wave'wgihr rwgihr
	rename r`wave'wthh rwthh
	rename r`wave'wtresp rwtresp
	rename r`wave'oopmd roopmd
	rename r`wave'higov rhigov
	rename r`wave'govmd rgovmd
	rename r`wave'govmr rgovmr
	rename r`wave'govva rgovva
	rename r`wave'covr rcovr
	rename r`wave'covs rcovs
	rename r`wave'henum rhenum
	rename r`wave'hiothp rhiothp
	rename r`wave'hltc rhltc
	rename r`wave'hlthlm rhlthlm
	rename h`wave'itot hitot
	rename r`wave'inlbrf rinlbrf
	rename r`wave'jhours rjhours
	rename r`wave'jhour2 rjhour2
	rename r`wave'jweeks rjweeks
	rename r`wave'jweek2 rjweek2
	rename r`wave'jphys rjphys
	rename r`wave'jlift	rjlift
	rename r`wave'jcten rjcten
	rename r`wave'ipena ripena
	rename r`wave'ipen ripen
	rename r`wave'issdi rissdi
	rename r`wave'isdi risdi
	rename r`wave'issi rissi
	rename r`wave'isret risret
	rename r`wave'iunwc riunwc
	rename r`wave'iunem riunem
	rename s`wave'ipena sipena
	rename s`wave'issdi sissdi
	rename s`wave'isdi sisdi
	rename s`wave'issi sissi
	rename s`wave'iunem siunem
	rename s`wave'isret sisret
	rename s`wave'iunwc siunwc
	rename r`wave'igxfr rigxfr
	rename s`wave'igxfr sigxfr
	rename h`wave'iothr hiothr
	rename r`wave'slfemp rslfemp
	rename s`wave'slfemp sslfemp
	rename h`wave'ifbusin hifbusin
	rename h`wave'ifcap hifcap
	rename h`wave'atota hatota
	rename r`wave'mstat rmstat
	rename r`wave'hibpe rhibpe
	rename r`wave'diabe rdiabe
	rename r`wave'cancre rcancre
	rename r`wave'lunge rlunge
	rename r`wave'hearte rhearte
	rename r`wave'stroke rstroke
	rename r`wave'psyche rpsyche 
	rename r`wave'arthre rarthre
	rename r`wave'cenreg rcenreg
	rename r`wave'cendiv rcendiv
	
	
	if inlist(`wave',4,5,6) {
		rename r`wave'totmb rtotmb
		rename r`wave'totmbi rtotmbi
	}
	
	* Variables from income and wealth supplement
	rename h`wave'ibusin hibusin
	rename h`wave'irntin hirntin
	rename h`wave'idivin hidivin
	if (`wave'==1) {
		rename h`wave'iothin hiothin
	}
	if (`wave'==2) {
		rename h`wave'istk1 histk1
		rename h`wave'istk2 histk2
		rename h`wave'isav1 hisav1
		rename h`wave'isav2 hisav2
		rename r`wave'iira1 riira1
		rename r`wave'iira2 riira2
		rename h`wave'iothi1 hiothi1
		rename h`wave'iothi2 hiothi2
		rename h`wave'iothi4 hiothi4
		rename h`wave'iothi5 hiothi5
	}
	if inlist(`wave',1,2,3,4,5,6) {
		rename h`wave'itrsin hitrsin
	}
	if inlist(`wave',3,4,5,6,7,8,9,10,11) {
		rename h`wave'ibndin hibndin
		rename h`wave'ichkin hichkin
		rename h`wave'icdin hicdin
		rename h`wave'iothi1 hiothi1
		rename h`wave'iothi2 hiothi2
		rename r`wave'isemp risemp
		rename s`wave'isemp sisemp
		rename r`wave'ifsemp rifsemp
		rename s`wave'ifsemp sifsemp
	}	
	
	* Clean up any variables that still have wave references
	drop r`wave'* 

	tempfile wave`wave'
	save `wave`wave''
	
restore

}

* Append our new long file
use `wave1', clear
forv wave = 2/11 {
	append using `wave`wave''
} 


* Generate a died indicator using interview status variable
gen responded = (riwstat==1)
gen noresponse = inlist(riwstat,0,4,7,9)
gen dead = inlist(riwstat,5,6)

* This person is a zombie so I drop them after their reported death:
drop if hhidpn==202147020 & wave==11

* Generate indicators for death in the next wave (because we eventually select on being alive)
sort hhidpn wave
by hhidpn: gen died_nextwave = riwstat[_n+1]==5 
	by hhidpn: replace died_nextwave = . if inlist(riwstat[_n+1],0,7)==1
	by hhidpn: replace died_nextwave = . if _n==_N & died_nextwave==0
by hhidpn: gen died_next2waves = died_nextwave
	by hhidpn: replace died_next2waves = 1 if riwstat[_n+2]==5
	by hhidpn: replace died_next2waves = 0 if inlist(riwstat[_n+2],1,4)==1
	by hhidpn: replace died_next2waves = . if _n+1==_N & died_next2waves==0	
by hhidpn: gen died_next3waves = died_next2waves
	by hhidpn: replace died_next3waves = 1 if riwstat[_n+3]==5
	by hhidpn: replace died_next3waves = 0 if inlist(riwstat[_n+3],1,4)==1
	by hhidpn: replace died_next3waves = . if _n+2==_N & died_next3waves==0	
gen died_ever_ind = died_nextwave==1
by hhidpn: egen died_ever = max(died_ever_ind)

assert died_next2waves==1 if died_nextwave==1
assert died_next3waves==1 if died_next2waves==1

* Dropping the AHEAD cohort for the waves before they're in sync with the HRS
drop if inlist(hacohort,0,1) & inlist(wave,1,2,3)

* Look at attrition
tab riwstat, mi
gen index_wave = .
	replace index_wave = wave if inlist(hacohort,3)
	replace index_wave = wave - 3 if inlist(hacohort,0,2,4,1)
	replace index_wave = wave - 6 if inlist(hacohort,5)
	replace index_wave = wave - 9 if inlist(hacohort,6)
	replace index_wave = . if index_wave<1

* Keep only those who respond for the survey wave
keep if riwstat==1

* Confirm that the cohorts are present in the waves they should be and not in the ones they shouldn't:
* Check 1: Cohorts 0, 1, and 3 are present in all waves
tab wave if inlist(hacohort,3,0,1), mi
* Check 2: Cohorts 2 and 4 begin in wave 4
tab wave if inlist(hacohort,2,4), mi
* Check 3: Cohort 5 begins in wave 7
tab wave if hacohort==5, mi
* Check 4: Cohort 6 begins in wave 10
tab wave if hacohort==6, mi

** Generate event time relative to the hospitalization

* Generate hospitalization indices
gen hosp = 0
	replace hosp = 1 if rhosp==1
bysort hhidpn: egen num_hosps = sum(hosp)
tab num_hosps, mi

* Figure out which survey wave an individual is first observed in
by hhidpn: egen first_wave = min(wave) 
tab first_wave, mi

* Code up first wave which references a prior hospitalization
gen wave_hosp = wave if rhosp==1 
by hhidpn: egen first_hosp = min(wave_hosp)
tab first_wave first_hosp, row mi

* Want to set event time to 0 at the time of the individual's FIRST hospitalization
gen evt_time = wave - first_hosp
	
* Code up age of hospitalization so we can use that to select sample
gen temp = ragey_b - 1 if rhosp==1
by hhidpn: egen age_hosp = min(temp)
drop temp

* Generate insurance variables
gen insured_gov = (rhigov==1)
gen medicaid = (rgovmd==1)
gen medicare = (rgovmr==1)
gen cov_va = (rgovva==1)
gen insured_pv = (rcovr==1|rcovs==1)
gen insured_pvgov = (insured_pv==1|insured_gov==1)
gen uninsured = rhenum==0 & insured_gov==0 & insured_pv==0 & rhiothp==0

* Coding up marital status
gen married = rmstat == 1

* Define insurance type and marital status at the survey wave 
* PRECEDING the wave reporting the hospitalization
sort hhidpn wave
foreach ins in medicaid insured_pv uninsured medicare insured_pvgov {
	gen temp = `ins' if first_hosp==(wave+1)
		by hhidpn: egen `ins'_h = min(temp)
	gen temp2 = `ins' if first_hosp==wave
		by hhidpn: egen `ins'_report = min(temp2)
	by hhidpn: gen `ins'_nextwave = `ins'[_n+1]
	by hhidpn: gen `ins'_prevwave = `ins'[_n-1]
	drop temp temp2
}

* Define re-hospitalization rates:
gen rehosp = rhsptim>1 & !missing(rhsptim) if evt_time==0
by hhidpn: gen rehosp_nextwave = rhosp[_n+1]

* Figure out how many individuals have an observation before hospitalization
gen temp = evt_time==-1
	replace temp = 0 if missing(temp)
by hhidpn: egen obs_prehosp = max(temp)
drop temp

* Set samples
gen under65 = age_hosp<65 & obs_prehosp==1
gen under65_INS = age_hosp<65 & (insured_pv_h==1|medicaid_h==1)
	assert obs_prehosp==1 if under65_INS==1
gen under60_INS = age_hosp<60 & (insured_pv_h==1|medicaid_h==1)
	assert obs_prehosp==1 if under60_INS==1
gen under59_INS = age_hosp<59 & (insured_pv_h==1|medicaid_h==1)
	assert obs_prehosp==1 if under59_INS==1
gen age60to64_INS = age_hosp<65 & age_hosp>=60 & (insured_pv_h==1|medicaid_h==1)
	assert obs_prehosp==1 if age60to64_INS==1
gen under65_SP = age_hosp<65 & uninsured_h==1
	assert obs_prehosp==1 if under65_SP==1
gen over65 = age_hosp>=65 & !missing(age_hosp) & obs_prehosp==1
gen no_hosp = first_hosp==.

* Set robustness sample without limiting to an observation pre-hospitalization
gen under65_INS_nopre = age_hosp<65 & (insured_pv_report==1|medicaid_report==1)
gen over65_nopre = age_hosp>=65 & !missing(age_hosp)
gen under60_INS_nopre = age_hosp<60 & (insured_pv_report==1|medicaid_report==1)
gen age60to64_INS_nopre = age_hosp<65 & age_hosp>=60 & (insured_pv_report==1|medicaid_report==1)

* Coding up labor force status
gen working_ft = rlbrf==1
gen working_pt = rlbrf==2
gen working = inlist(rlbrf,1,2)==1
gen unemployed = rlbrf==3
gen partly_retired = rlbrf==4
gen not_in_lbrf = (rlbrf==7)|(rlbrf==.t)
gen retired = (rlbrf==5)|(rlbrf==.a)
gen disabled = rlbrf==6
gen in_lbrf = inlist(rlbrf,1,2,3)
gen health_limited = (rhlthlm==1)
gen worse_health = inlist(rhltc,4,5)

tab rlbrf, mi

* Get distribution of retirement ages
sort hhidpn wave
gen temp = ragey_b if retired==1
by hhidpn: egen age_retired = min(temp)
replace age_retired = . if age_retired!=ragey_b
drop temp

sum age_retired [aweight=rwtresp], det

* Generate a retirement indicator
sort hhidpn wave
by hhidpn: gen retired_nextwave = rlbrf[_n+1]==5
	by hhidpn: replace retired_nextwave = . if riwstat[_n+1]!=1
	by hhidpn: replace retired_nextwave = . if _n==_N & retired_nextwave==0	
by hhidpn: gen retired_next2waves = retired_nextwave
	by hhidpn: replace retired_next2waves = 1 if rlbrf[_n+2]==5
	by hhidpn: replace retired_next2waves = 0 if retired_next2waves==. & rlbrf!=5 & riwstat==1
	by hhidpn: replace retired_next2waves = . if _n+1==_N & retired_next2waves==0	
by hhidpn: gen retired_next3waves = retired_next2waves
	by hhidpn: replace retired_next3waves = 1 if rlbrf[_n+3]==5
	by hhidpn: replace retired_next3waves = 0 if retired_next3waves==. & rlbrf!=5 & riwstat==1
	by hhidpn: replace retired_next3waves = . if _n+2==_N & retired_next3waves==0	
	
* Rename variable for OOP spending
rename roopmd oop_spend

* Replace hours and weeks working for those not working to zero
replace rjhours = 0 if rjhours==.w
replace rjhour2 = 0 if rjhour2==.w
replace rjweeks = 0 if rjweeks==.w
replace rjweek2 = 0 if rjweek2==.w

* Code up balanced panel and number of observations in window
gen tag = 0
forv et = -2/2 {
	replace tag = 1 if evt_time==`et' & rwtresp!=0
}
by hhidpn: egen num_obs_bal = total(tag)

forv et = -3/3 {
	replace tag = 1 if evt_time==`et' & rwtresp!=0
}
by hhidpn: egen num_obs = total(tag)

gen bal = num_obs_bal==5
	replace bal = 0 if evt_time<-2
	replace bal = 0 if evt_time>2
	
* Clean out people who have a zero weight for the observation of their hospitalization
gen temp = rwtresp==0 & evt_time==0
	replace temp = . if temp!=1
	by hhidpn: egen zero_wgt_hosp = min(temp)
	drop temp
	drop if zero_wgt_hosp==1

* Generate indicator that's 1 for everyone for looping purposes
gen freq = 1

* Generate demographics
gen white = raracem == 1
gen black = raracem == 2
gen race_other = raracem==3
gen female = ragender==2
	gen male = ragender==1
gen hispanic = rahispan == 1

* Generate indicators for sample cohort
forv num = 0/6 {
	gen cohort_`num' = hacohort==`num'
}

* Generate approximate year of hospitalization
gen year_hosp = age_hosp + rabyear

* Change cohort (AHEAD+HRS) to AHEAD for sampling purposes
replace hacohort = 1 if hacohort==0

* Code up education
gen lessthan_hs = inlist(raeduc,1,2) // Includes GEDs
gen hs_grad = raeduc==3
gen some_college = raeduc==4
gen collegeplus = raeduc==5 

* Group government income into categories to analyze:
egen rgovt = rowtotal(rissdi riunwc risret rigxfr)
egen sgovt = rowtotal(sissdi siunwc sisret sigxfr)
egen rssall = rowtotal(rissdi risret)
egen sssall = rowtotal(sissdi sisret)
foreach var in govt isdi issi iunem isret ipena ssall {
	egen h`var' = rowtotal(r`var' s`var')
}

* Code up time in between waves
foreach var in riwbegy riwend riwmidy {
	format `var' %td
}
sort hhidpn wave
gen time_since = .
by hhidpn: replace time_since = riwbegy - riwend[_n-1]
gen years_since = time_since/365.25

* Checking timing between waves
sum time_since if under65_INS & evt_time==0
sum time_since if over65 & evt_time==0
sum time_since if under65_INS & evt_time==1
sum time_since if over65 & evt_time==1
sum years_since if under65_INS & evt_time==0
sum years_since if over65 & evt_time==0
sum years_since if under65_INS & evt_time==1
sum years_since if over65 & evt_time==1
sum years_since if evt_time==0 & (under65_INS==1|over65==1), det

* Check timing within year
tab riwendm if under65_INS & evt_time==0
tab riwendm if over65 & evt_time==0
tab riwendm if evt_time==0

* Check and fix the components of household capital income
local vars_1 "hibusin hirntin hitrsin hidivin hichkin"
local vars_2 "hibusin hirntin hitrsin hibndin hidivin histk1 histk2 hichkin hisav1 hisav2 hicdin riira1 riira2"
local vars_36 "hibusin hirntin hitrsin hibndin hidivin histk1 histk2 hichkin hisav1 hisav2 hicdin risemp sisemp hiothi1"
local vars_711 "hibusin hirntin hibndin hidivin histk1 histk2 hichkin hisav1 hisav2 hicdin risemp sisemp hiothi1"

egen hicap_fit = rowtotal(`vars_1') if wave==1
egen hicap_fit2 = rowtotal(`vars_2') if wave==2
	replace hicap_fit = hicap_fit2 if wave==2
egen hicap_fit36 = rowtotal(`vars_36') if inlist(wave,3,4,5,6)
	replace hicap_fit = hicap_fit36 if inlist(wave,3,4,5,6)
egen hicap_fit711 = rowtotal(`vars_711') if inlist(wave,7,8,9,10,11)
	replace hicap_fit = hicap_fit711 if inlist(wave,7,8,9,10,11)
assert !missing(hicap_fit)
assert !missing(hicap)

* The order of the questions in the HRS determined whether household business income
* should be included in the household capital income or whether it was already included
* in other variables (e.g. risemp, hirntin, hitrsin, sisemp) so here I replace household
* business income with zeroes where it appears to be double-counting. This changes the 
* share of fitted hicap observations from ~94% to 98.5%
forv wave = 7/11 {
	gen tag_double = (hicap_fit - hicap > 10)
	replace hicap_fit = hicap_fit - hibusin if tag_double
	replace hibusin = 0 if tag_double
	drop tag_double
}
gen close = abs(hicap - hicap_fit)<1
gen over = hicap_fit > hicap if close==0
gen under = hicap_fit<hicap if close==0
gen mean_over = hicap_fit - hicap if over
gen mean_under = hicap_fit - hicap if under

table wave, c(mean close mean over mean under mean mean_over mean mean_under)
drop close over under mean_over mean_under hicap_fit* 

* Replace missing spousal income with zeroes
tab siwstat rmstat, mi
gen spouse = inlist(rmstat,1,2,3)==1
foreach var in siearn sisemp sipena sissdi sisret siunwc sigxfr {
	replace `var' = 0 if spouse==0
}

* Coding up the earnings + self-employment income
egen riearnsemp = rowtotal(riearn risemp)
egen siearnsemp = rowtotal(siearn sisemp)
egen hisemp = rowtotal(risemp sisemp)

* Generate an unearned income variable (substracting self-employment income)
gen hicap_une = hicap
	replace hicap_une = hicap_une - hisemp if !missing(hisemp)
	replace hicap_une = 0 if hicap_une<0
	
* The fit is poor and variables are measured differently for waves 1 and 2 so change them to missing for alternate check:
foreach var in hicap hibusin hirntin risemp sisemp riearnsemp siearnsemp hisemp riearn hicap_une {
	gen `var'_c = `var'
		replace `var'_c = . if inlist(wave,1,2)
}

* Generate two alternative household income measures (that are hopefully the same):
* "exc" excludes other and unearned income from total household income
* "inc" adds up the elements that are not other/unearned income (earnings, government transfers, and pensions)
assert !missing(hiothr) & !missing(hicap_une) & !missing(hitot)
gen hitot_exc = hitot - hiothr - hicap_une
	replace hitot_exc = 0 if hitot_exc<0
egen hitot_inc = rowtotal(riearnsemp siearnsemp hgovt hipena)
gen diff_hitot_measure = hitot_exc - hitot_inc
sum diff_hitot_measure, det
count if abs(diff_hitot_measure)>10
drop diff_hitot_measure

* Generate extensive margin indicators and censor the top 0.05% of observations for all of our main variables
local mainvars "oop_spend *_c hitot hitot_exc hitot_inc hicap hicap_une hibusin hirntin riearnsemp siearnsemp hisemp risemp sisemp riearn siearn ripena hipena rgovt hgovt hiothr rissi risdi riunem ripen rigxfr risret riunwc hissi hisdi hiunem hisret hatota rssall sssall hssall"
foreach var of varlist `mainvars' {

	* Generate extensive margin indicator
	gen a_`var' = (`var'>0 & `var'!=.)
		replace a_`var'=. if missing(`var')

	* Censor top 0.05% of observations for each variable	
	_pctile `var', p(99.95)
	local topcode = r(r1)
	sum `var', det
	di "Top Code = `topcode'"
	replace `var' = `topcode' if `var'>`topcode' & !missing(`var')
	
}

* Adjust outcomes for inflation:
local dollar_vars1 "oop_spend riearn ripena ripen rissdi risret riunwc rigxfr risdi riunem rissi"
local dollar_vars2 "siearn sipena sissdi sisret siunwc sigxfr rwgihr rwgiwk hatota rssall sssall hssall"
local dollar_vars3 "hicap hiothr hitot hitot_exc hitot_inc rwgihr rwgiwk rtotmb rgovt sgovt hipena hgovt"
local dollar_vars4 "hibusin hirntin risemp sisemp hisemp hicap_une riearnsemp siearnsemp *_c"
gen year = riwendy - 1
cpigen
* Reindexing the CPI variable to 2005
sum cpi if year==2005
local cpi05 = r(mean)
gen cpi_2005 = cpi/`cpi05'
assert !missing(cpi_2005)

foreach var of varlist `dollar_vars1' `dollar_vars2' `dollar_vars3' `dollar_vars4' {
	replace `var' = `var'/cpi_2005
}

* Code up pre-hospitalization wealth quartiles and zero assets
replace hatota = 0 if hatota<0
gen zero_networth_prehosp = 0
	replace zero_networth_prehosp = 1 if hatota==0 & evt_time==-1
foreach samp in freq under65 under65_INS under60_INS age60to64_INS under65_SP over65 {
	di "Wealth for `samp'"
	sum hatota if evt_time==-1 & `samp'==1, det
	xtile temp_ses_q_`samp' = hatota if evt_time==-1 & `samp'==1, n(4)

}
* Assign values to the full panel after defining pre-hospitalization status
sort hhidpn evt_time
by hhidpn: egen ses_zero = max(zero_networth_prehosp)
drop zero_networth_prehosp
foreach samp in freq under65 under65_INS  under60_INS age60to64_INS under65_SP over65 {
	by hhidpn: egen ses_q_`samp' = min(temp_ses_q_`samp')
	gen ses_q1_`samp' = ses_q_`samp' == 1
	gen ses_BM_`samp' = inlist(ses_q_`samp',1,2)==1
	gen ses_AM_`samp' = inlist(ses_q_`samp',3,4)==1
	gen ses_q4_`samp' = ses_q_`samp' == 4
	drop temp_ses_q_`samp'
}

* Create control groups
* Generate indicators for eligible controls
sort hhidpn wave
by hhidpn: gen obs_prevwave = (wave-1)==wave[_n-1]
by hhidpn: gen obs_nextwave = (wave+1)==wave[_n+1]

gen under60_control = (ragey_b < 61) & insured_pvgov_prevwave==1 & ever_hospitalized==0 & obs_nextwave==1 // Because we subtract a year when someone reports a hospitalization
gen age60to64_control = (ragey_b < 65 & ragey_b>=61) & insured_pvgov_prevwave==1 & ever_hospitalized==0 & obs_nextwave==1
gen over65_control = (ragey_b >=66) & ever_hospitalized==0 & obs_prevwave==1 & obs_nextwave==1
gen under60_death = (ragey_b < 61) & insured_pvgov_prevwave==1 & ever_hospitalized==0
gen over65_death = (ragey_b >=66) & ever_hospitalized==0 & obs_prevwave==1
gen age60to64_death = (ragey_b < 65 & ragey_b>=61) & insured_pvgov_prevwave==1 & ever_hospitalized==0

* Generate an artificial hospitalization for the control groups
foreach group in under60 age60to64 over65 {
	sort hhidpn `group'_control
	by hhidpn `group'_control: gen rand = uniform() 
	by hhidpn `group'_control: egen min_rand = min(rand)
	gen keep_rand = min_rand == rand
		replace `group'_control = 0 if `group'_control==1 & keep_rand==0
	drop keep_rand rand min_rand
	
	sort hhidpn `group'_death
	by hhidpn `group'_death: gen rand = uniform() 
	by hhidpn `group'_death: egen min_rand = min(rand)
	gen keep_rand = min_rand == rand
		replace `group'_death = 0 if `group'_death==1 & keep_rand==0
	drop keep_rand rand min_rand

}

* Generate counterfactual age of hospitalization
gen temp1 = ragey_b - 1 if under60_control==1
gen temp2 = ragey_b - 1 if over65_control==1
gen temp3 = ragey_b - 1 if under60_death==1
gen temp4 = ragey_b - 1 if over65_death==1
gen temp5 = ragey_b - 1 if age60to64_control==1
by hhidpn: egen age_hosp1 = min(temp1)
by hhidpn: egen age_hosp2 = min(temp2)
by hhidpn: egen age_hosp3 = min(temp3)
by hhidpn: egen age_hosp4 = min(temp4)
by hhidpn: egen age_hosp5 = min(temp5)
drop temp1 temp2 temp3 temp4 temp5

* Generate counterfactual event time relative to the artificial hospitalization
gen evt_time1 = . 
gen temp1 = wave if under60_control==1
by hhidpn: egen control_hosp1 = min(temp1)
replace evt_time1 = 0 if under60_control==1
	replace evt_time1 = wave - control_hosp1

gen evt_time2 = .
gen temp2 = wave if over65_control==1
by hhidpn: egen control_hosp2 = min(temp2)
replace evt_time2 = 0 if over65_control==1 
	replace evt_time2 = wave - control_hosp2
	
gen evt_time3 = . 
gen temp3 = wave if under60_death==1
by hhidpn: egen control_hosp3 = min(temp3)
replace evt_time3 = 0 if under60_death==1
	replace evt_time3 = wave - control_hosp3

gen evt_time4 = .
gen temp4 = wave if over65_death==1
by hhidpn: egen control_hosp4 = min(temp4)
replace evt_time4 = 0 if over65_death==1 
	replace evt_time4 = wave - control_hosp4
	
gen evt_time5 = .
gen temp9 = wave if age60to64_control==1
by hhidpn: egen control_hosp5 = min(temp9)
replace evt_time5 = 0 if age60to64_control==1 
	replace evt_time5 = wave - control_hosp5

by hhidpn: egen temp5 = max(under60_control)
	replace under60_control = 1 if temp5==1 & under60_control==0
by hhidpn: egen temp6 = max(over65_control)
	replace over65_control = 1 if temp6==1 & over65_control==0
by hhidpn: egen temp7 = max(under60_control)
	replace under60_death = 1 if temp7==1 & under60_death==0
by hhidpn: egen temp8 = max(over65_control)
	replace over65_death = 1 if temp8==1 & over65_death==0
by hhidpn: egen temp10 = max(age60to64_control)
	replace age60to64_control = 1 if temp10==1 & age60to64_control==0

drop temp*

* Generate balanced panel for placebo sample:
* Code up balanced panel and number of observations in window
sort hhidpn evt_time1
gen tag1 = 0
forv et = -2/2 {
	replace tag1 = 1 if evt_time1==`et' & rwtresp!=0
}
by hhidpn: egen num_obs_bal1 = total(tag1)
drop tag1

gen bal1 = num_obs_bal1==5
	replace bal1 = 0 if evt_time1<-2
	replace bal1 = 0 if evt_time1>2

sort hhidpn evt_time2
gen tag2 = 0
forv et = -2/2 {
	replace tag2 = 1 if evt_time2==`et' & rwtresp!=0
}
by hhidpn: egen num_obs_bal2 = total(tag2)
drop tag2

gen bal2 = num_obs_bal2==5
	replace bal2 = 0 if evt_time2<-2
	replace bal2 = 0 if evt_time2>2
	
* Generate indicator for being married pre-hospitalization
gen temp = 0
gen temp1 = 0
gen temp2 = 0
gen temp3 = 0 
gen temp4 = 0 
	replace temp = 1 if evt_time==-1 & spouse==1
	replace temp1 = 1 if evt_time1==-1 & spouse==1
	replace temp2 = 1 if evt_time2==-1 & spouse==1
	replace temp3 = 1 if evt_time==-1 & spouse==1 & (sagey_b<59)
	replace temp4 = 1 if evt_time==-1 & spouse==1 & (sagey_b<58)
	by hhidpn: egen prehosp_spouse = max(temp)
	by hhidpn: egen prehosp_spouse1 = max(temp1)
	by hhidpn: egen prehosp_spouse2 = max(temp2)
	by hhidpn: egen prehosp_spouse_u60 = max(temp3)
	by hhidpn: egen prehosp_spouse_u59 = max(temp4)
	drop temp*
gen noprehosp_spouse = prehosp_spouse==0

* Generate an indicator for having a spouse with zero earnings pre-hospitalization
gen temp = 0
gen temp1 = 0
gen temp2 = 0
	replace temp = 1 if evt_time==-1 & spouse==1 & siearnsemp==0
	replace temp1 = 1 if evt_time1==-1 & spouse==1 & siearnsemp==0
	replace temp2 = 1 if evt_time2==-1 & spouse==1 & siearnsemp==0	
	by hhidpn: egen spouse_zero = max(temp)
	by hhidpn: egen spouse_zero1 = max(temp1)
	by hhidpn: egen spouse_zero2 = max(temp2)
	drop temp*

* Scale all the dummies up to percentages:
local lfp "working working_ft working_pt unemployed partly_retired retired not_in_lbrf disabled health_limited spouse rslfemp"
local chars "male cohort_0 cohort_1 cohort_2 cohort_3 cohort_4 cohort_5 cohort_6 white black hispanic race_other"
local chars2 "medicaid_prevwave insured_pv_prevwave medicare_prevwave rehosp rehosp_nextwave insured_pvgov insured_pvgov_nextwave medicare medicaid insured_pv" 
local chars3 "died_nextwave died_next2waves died_next3waves died_ever retired_nextwave retired_next2waves retired_next3waves"
foreach var of varlist a_* `lfp' `chars' `chars2' `chars3' {
	replace `var' = `var'*100
}

* Generate log variables
* assert hitot!=0 // Assertion is false but small number violate
gen log_hitot = log(hitot+1)
gen log_hitot_inc = log(hitot_inc+1)
gen log_hitot_exc = log(hitot_exc+1)
gen log_rwgihr = log(rwgihr)
gen log_rwgiwk = log(rwgiwk) // Note a small number of people with wages of zero are set to missing.
replace rjhours = 80 if rjhours>80 & !missing(rjhours)
gen annual_hours = rjweeks*rjhours

* Rename previous hitot variable to make sure it doesn't get used
rename hitot hitot_old
rename log_hitot log_hitot_old

* Code up location at time of hospitalization
tab rcenreg, mi
gen west = rcenreg==4
tab rcendiv, mi
gen pacific = rcendiv==9
gen temp = 0
	replace temp = 1 if under60_INS==1 & evt_time==0 & west==1
by hhidpn: egen under60_INSwest = max(temp)
drop temp
gen temp = 0
	replace temp = 1 if under60_INS==1 & evt_time==0 & pacific==1
by hhidpn: egen under60_INSpacific = max(temp)
drop temp

save HRS_long.dta, replace






























