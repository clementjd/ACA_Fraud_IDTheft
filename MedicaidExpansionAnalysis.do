********************************************************************************
*
*  Impact of Medicaid Expansion on Fraud/ID Theft Analysis
*
********************************************************************************



********************************* HOUSEKEEPING *********************************

* STATA VERSION
* For future reproducibility, specify use of Stata version 17
version 17

* FILEPATHS
* Filepaths are flexibly referenced with the "here" package
* For documentation, see https://github.com/korenmiklos/here

* To install package, uncomment and run the next line
* net install here, from("https://raw.githubusercontent.com/korenmiklos/here/master/")

* Set working directory
* You will still have to set working directory manually
* After you do that, relative filepaths should work
here, set

************************* EXTRACT/TRANSFORM/LOAD DATA ************************
* Clear anything currently in memory
clear

*** State-level details managed with statastates package
* to install, use command: ssc install statastates

*** Control: Non-farm wages
* State names, FIPS codes etc manipulated with statastates package
import excel "${here}/Controls/NonFarmWages.xls", cellrange(A6:W66) firstrow clear
destring GeoName GeoFips, replace
statastates, name(GeoName) // Add state abbreviations for later use
drop if state_fips == .    // Drop regions that aren't states
drop GeoFips _merge 	   // Drop the GeoFips and _merge variables
rename GeoName state_name
label variable state_name "state_name"
reshape long NonFarmInc, i(state_abbrev) j(year)
label variable NonFarmInc "BEA: Non-Farm Wages Total (USD thousand)"
save "${here}/Controls/nonfarmincome.dta", replace // Save as a .dta file to merge later

*** Control: Per Capita Personal Income
import excel "${here}/Controls/Per Capita Personal Income.xls", cellrange(A6:W58) firstrow clear
destring GeoName GeoFips, replace
statastates, name(GeoName) // Add state abbreviations for later use
drop if state_fips == .    // Drop regions that aren't states
drop GeoFips _merge 	   // Drop the GeoFips and _merge variables
rename GeoName state_name
label variable state_name "State Name"
reshape long PercapIncome, i(state_abbrev) j(year)
label variable PercapIncome "BEA: Per Capita Income (USD)"
save "${here}/Controls/PerCapitaIncome.dta", replace // Save as a .dta file to merge later

*** Control: Population
import excel "${here}/Controls/Population.xls", cellrange(A6:W58) firstrow clear
destring GeoName GeoFips, replace
statastates, name(GeoName) // Add state abbreviations for later use
drop if state_fips == .    // Drop regions that aren't states
drop GeoFips _merge 	   // Drop the GeoFips and _merge variables
rename GeoName state_name
label variable state_name "State Name"
reshape long Population, i(state_abbrev) j(year)
rename Population population
label variable population "BEA: Total Population (Num of Persons)"
save "${here}/Controls/population.dta", replace // Save as a .dta file to merge later

*** Control: Demographics
* Black population
import delimited "${here}/Controls/Black population.txt", clear
drop yearlyjuly1stestimatescode notes
rename population BlackPopulation
label variable BlackPopulation "Black Population (Num of Persons)"
rename yearlyjuly1stestimates year
label variable year "Year"

statastates, name(state) // Add state abbreviations for later use
drop if state_fips == .    // Drop regions that aren't states
drop _merge statecode 	   // Drop the _merge and duplicate FIPS variable
rename state state_name
label variable state_name "State Name"
order state_abbrev state_fips, after(state_name)

save "${here}/Controls/black_population.dta", replace // Save as a .dta file to merge later

* Latino Population
import delimited "${here}/Controls/Latino Population.txt", clear
drop yearlyjuly1stestimatescode notes
rename population LatinoPopulation
label variable LatinoPopulation "Latino Population (Num of Persons)"
rename yearlyjuly1stestimates year
label variable year "Year"

statastates, name(state) // Add state abbreviations for later use
drop if state_fips == .    // Drop regions that aren't states
drop _merge statecode 	   // Drop the _merge and duplicate FIPS variable
rename state state_name
label variable state_name "State Name"
order state_abbrev state_fips, after(state_name)

save "${here}/Controls/latino_population.dta", replace // Save for later

*** Control: Health insurance coverage
* 2008-2019
import excel "${here}/Controls/HealthIns2008-2019.xlsx", cellrange(A4:AX576) firstrow clear
destring, replace
drop if State == "United States"
statastates, name(State) // Add state abbreviations for later use
drop _merge 	   // Drop the GeoFips and _merge variables
rename State state_name
reshape long Estimate MOE Percent MOEpct, i(state_name state_abbrev Coverage) j(year)
rename Estimate LivesCovered
rename MOE LivesCoveredMOE
rename Percent PctCovered
replace Coverage = "AnyCoverage" if Coverage == "Any coverage"
replace Coverage = "_DirectPurchase" if Coverage == "..Direct-purchase"
replace Coverage = "_Employer" if Coverage == "..Employer-based"
replace Coverage = "_VA" if Coverage == "..VA Care"
replace Coverage = "_TRICARE" if Coverage == "..TRICARE"
replace Coverage = "_Medicaid" if Coverage == "..Medicaid"
replace Coverage = "_Medicare" if Coverage == "..Medicare"
reshape wide LivesCovered LivesCoveredMOE PctCovered MOEpct, i(state_name state_abbrev year) j(Coverage) string
keep state_name state_abbrev state_fips year PctCoveredUninsured PctCoveredTotal
save "${here}/Controls/insurance2008-2019.dta", replace // Save as a .dta file to merge later

* 1999-2009
import excel "${here}/Controls/HealthInsCov1999-2009.xls", cellrange(A4:AM576) firstrow clear
drop if State == "United States"
statastates, name(State) // Add state abbreviations for later use
drop _merge 	   // Drop the GeoFips and _merge variables
destring Year, replace
rename Year year
destring PctCoveredUninsured, replace force
rename State state_name
label variable state_name "state_name"
drop if year >= 2008  // Use newer dataset for 2008-2019
keep state_name state_abbrev state_fips year PctCoveredUninsured PctCoveredTotal
save "${here}/Controls/insurance1999-2007.dta", replace // Save for later

* Combine the 1999-2007 and 2008-2019 datasets
clear
append using "${here}/Controls/insurance1999-2007.dta" "${here}/Controls/insurance2008-2019.dta"
order state_abbrev state_fips, after(state_name)
label variable state_name "State Name"
label variable state_abbrev "State Abbreviation"
label variable state_fips "State FIPS Code"
label variable year "Year"
label variable PctCoveredUninsured "Pct of People Uninsured"
label variable PctCoveredTotal "Pct of People w/ Health Insurance"
rename PctCoveredTotal HealthInsPctCovered
rename PctCoveredUninsured HealthInsUninsured
save "${here}/Controls/insurance1999-2019.dta", replace // Save as a .dta file to merge later

*** Control: EHR Adoption - AHA Options
clear
import delimited "${here}/Controls/AHA_EHLTH_data_by_state_2010to2016.csv"
statastates, fips(fstcd)
rename fstcd state_fips
label variable state_abbrev "State Abbreviation"
label variable state_fips "State FIPS Code"
label variable state_name "State Name"
label variable aha_hospitals "No. of hospitals in AHA survey"
label variable aha_beds "No. of beds reported"
label variable ehr_none "AHA EHLTH: Pct of beds not covered by EHR"
label variable ehr_partial "AHA EHLTH: Pct of beds partially covered by EHR"
label variable ehr_full "AHA EHLTH: Pct of beds fully covered by EHR"
label variable ehr_noresponse "AHA EHLTH: Pct of beds no response to EHR Question"
label variable ehr_undetermined "AHA EHLTH: Pct of beds indeterminate response to EHR Question"
label variable state_fips "State FIPS Code"
order state_abbrev state_name, after (state_fips)
drop _merge
save "${here}/Controls/ehr2010-2016.dta", replace // Save for later

*** Control: EHR Adoption - HIMSS Options
clear
import delimited "${here}/Controls/HIMSS EHR Tech Adoption.csv"
rename state state_abbrev
label variable state_abbrev "State Abbreviation"
statastates, abbrev(state_abbrev)
drop _merge
label variable state_fips "State FIPS Code"
label variable state_name "State Name"
label variable hospitals "No. of Hospitals"
label variable total_beds "Total Beds"
label variable emr_adoption_himss_5factor "HIMSS EHR Adoption - 5 modules"
label variable emr_adoption_himss_7factor "HIMSS EHR Adoption - 7 modules"
rename emr_adoption_himss_7factor ehr_himss7
rename emr_adoption_himss_5factor ehr_himss5
order state_name state_fips, after(state_abbrev)
order total_beds, after(hospitals)
destring ehr_himss7, force replace
save "${here}/Controls/himss_ehr2004-2017.dta", replace // Save for later

*** Load Main Data Set
* Load raw data and clean/re-order
import delimited "${here}/raw.csv", clear

rename state state_abbrev

statastates, abbreviation(state_abbrev) // Add state abbreviations for later use
drop _merge 	   // Drop _merge variable (result of statastates matching)
order state_name, first
order state_abbrev state_fips, after(state_name)
order treatmentyear treatment, after(year)
drop stateid
label variable state_name "State Name"
label variable state_abbrev "State Abbreviation"
label variable state_fips "State FIPS Code"
label variable year "Year"
label variable treatmentyear "Year of ACA Medicaid Expansion"
label variable treatment "0/1: Medicaid expanded under ACA"

*** Process the panel to set up for analysis
* Use xtset to initialize panel
xtset state_fips year

* Replace missing treatmentyear values with 9999
replace treatmentyear = 9999 if treatmentyear == .

* Set up relative time dummy variables
forvalues x=0(1)14{
capture drop lq`x'_treated
gen lq`x'_treated = year - treatmentyear ==`x'
}

forvalues x=14(-1)0{
capture drop fq`x'_treated
gen fq`x'_treated = treatmentyear - year==`x'
}

gen fq4_plus = fq14_treated + fq13_treated + fq12_treated + fq11_treated + fq9_treated + fq8_treated + fq7_treated + fq6_treated + fq5_treated 

gen lq4_plus = lq14_treated + lq13_treated + lq12_treated + lq11_treated + lq9_treated + lq8_treated + lq7_treated + lq6_treated + lq5_treated 

save "${here}/final_panel_without_controls.dta", replace

clear
use "${here}/final_panel_without_controls.dta"
*** Join with Controls
* Population
display "Population Merge Results"
merge 1:1 state_abbrev year using "${here}/Controls/population.dta"
drop if _merge == 2
drop _merge

* Per Capita Personal Income
display "Per Capita Income Merge Results"
merge 1:1 state_abbrev year using "${here}/Controls/PerCapitaIncome.dta"
drop if _merge == 2
drop _merge

* Non-Farm Wages
display "NonFarm Wages Merge Results"
merge 1:1 state_abbrev year using "${here}/Controls/nonfarmincome.dta"
drop if _merge == 2
generate nonfarm_wages_percap = NonFarmInc/population // Per Capita Income (thousand)
label variable nonfarm_wages_percap "Non-Farm Wages per Cap (USD Thousand)"
drop _merge NonFarmInc

* Health Insurance Coverage
display "Health Insurance Coverage Merge Results"
merge 1:1 state_abbrev year using "${here}/Controls/insurance1999-2019.dta"
drop if _merge == 2
drop _merge

* Demographics
display "Black Population Merge Results"
merge 1:1 state_abbrev year using "${here}/Controls/black_population.dta"
drop if _merge == 2
generate Demog_pctBlack = BlackPopulation / population // Percent that is Black
label variable Demog_pctBlack "Demographics: Percent Black"
drop _merge BlackPopulation

display "Latino Population Merge Results"
merge 1:1 state_abbrev year using "${here}/Controls/latino_population.dta"
drop if _merge == 2
generate Demog_pctLatino = LatinoPopulation / population // Percent that is Latino
label variable Demog_pctLatino "Demographics: Percent Latino"
drop _merge LatinoPopulation

display "AHA EHR Adoption Merge Results"
merge 1:1 state_fips year using "${here}/Controls/ehr2010-2016.dta"
drop if _merge == 2
drop _merge

display "HIMSS EHR Adoption Merge Results"
merge 1:1 state_abbrev state_fips year using "${here}/Controls/himss_ehr2004-2017.dta"
drop if _merge == 2
drop _merge

*** Save the final dataset to jumpstart analysis
save final_panel, replace // Save as a .dta file to skip ETL process in future
use final_panel

* Create lists of variables
vl create demographic_controls = (population PercapIncome Demog_pctBlack Demog_pctLatino)

vl create ehr_AHAcontrols = (ehr_full ehr_partial ehr_none)





******************************* BASE ESTIMATION *****************************

* OLS - DV: ln(ID Theft)
xtreg logid treatment i.year, fe cluster(state_fips)
outreg2 using "${here}/base.xls", word ctitle(ln(ID Theft))

xtreg logid treatment i.year $demographic_controls, fe cluster(state_fips) //controls
outreg2 using "${here}/base.xls", word ctitle(ln(ID Theft))

xtreg logid treatment i.year HealthInsPctCovered $demographic_controls, fe cluster(state_fips) //controls
outreg2 using "${here}/base.xls", word ctitle(ln(ID Theft))

xtreg logid treatment i.year ehr_himss5 $demographic_controls, fe cluster(state_fips) //controls
outreg2 using "${here}/base.xls", word ctitle(ln(ID Theft))

xtreg logid treatment i.year ehr_himss7 $demographic_controls, fe cluster(state_fips) //controls
outreg2 using "${here}/base.xls", word ctitle(ln(ID Theft))

xtreg logid treatment i.year $ehr_AHAcontrols $demographic_controls, fe cluster(state_fips) //controls
outreg2 using "${here}/base.xls", word ctitle(ln(ID Theft))

* OLS - DV: ln(Fraud)
xtreg lnfraud treatment i.year, fe cluster(state_fips)
outreg2 using "${here}/base.xls", word ctitle(ln(Fraud))

xtreg lnfraud treatment i.year $demographic_controls, fe cluster(state_fips)
outreg2 using "${here}/base.xls", word ctitle(ln(Fraud)) 

xtreg lnfraud treatment i.year HealthInsPctCovered $demographic_controls, fe cluster(state_fips)
outreg2 using "${here}/base.xls", word ctitle(ln(Fraud))

xtreg lnfraud treatment i.year ehr_himss5 $demographic_controls, fe cluster(state_fips)
outreg2 using "${here}/base.xls", word ctitle(ln(Fraud)) 

xtreg lnfraud treatment i.year ehr_himss7 $demographic_controls, fe cluster(state_fips)
outreg2 using "${here}/base.xls", word ctitle(ln(Fraud)) 

xtreg lnfraud treatment i.year $ehr_AHAcontrols $demographic_controls, fe cluster(state_fips)
outreg2 using "${here}/base.xls", word ctitle(ln(Fraud)) 


* Pseudo Poisson Maximum Likelihood (PPML) - DV: ID Theft
xtpoisson numidtheft treatment i.year, fe robust i(state_fips)
outreg2 using "${here}/base.xls", word ctitle(Poisson - ID Theft) 

xtpoisson numidtheft treatment i.year $demographic_controls, fe robust i(state_fips)
outreg2 using "${here}/base.xls", word ctitle(Poisson - ID Theft)

xtpoisson numidtheft treatment i.year HealthInsPctCovered $demographic_controls, fe robust i(state_fips)
outreg2 using "${here}/base.xls", word ctitle(Poisson - ID Theft)

xtpoisson numidtheft treatment i.year ehr_himss5 $demographic_controls, fe robust i(state_fips)
outreg2 using "${here}/base.xls", word ctitle(Poisson - ID Theft) 

xtpoisson numidtheft treatment i.year ehr_himss7 $demographic_controls, fe robust i(state_fips)
outreg2 using "${here}/base.xls", word ctitle(Poisson - ID Theft) 

xtpoisson numidtheft treatment i.year $ehr_AHAcontrols $demographic_controls, fe robust i(state_fips)
outreg2 using "${here}/base.xls", word ctitle(Poisson - ID Theft) 

* PPML- DV: Fraud
xtpoisson numfraud treatment i.year, fe robust i(state_fips)
outreg2 using "${here}/base.xls", word ctitle(Poisson - Fraud) 

xtpoisson numfraud treatment i.year $demographic_controls, fe robust i(state_fips)
outreg2 using "${here}/base.xls", word ctitle(Poisson - Fraud) 

xtpoisson numfraud treatment i.year HealthInsUninsured $demographic_controls, fe robust i(state_fips)
outreg2 using "${here}/base.xls", word ctitle(Poisson - Fraud) 

xtpoisson numfraud treatment i.year ehr_himss5 $demographic_controls, fe robust i(state_fips)
outreg2 using "${here}/base.xls", word ctitle(Poisson - Fraud) 

xtpoisson numfraud treatment i.year ehr_himss7 $demographic_controls, fe robust i(state_fips)
outreg2 using "${here}/base.xls", word ctitle(Poisson - Fraud) 

xtpoisson numfraud treatment i.year HealthInsUninsured $ehr_AHAcontrols $demographic_controls, fe robust i(state_fips)
outreg2 using "${here}/base.xls", word ctitle(Poisson - Fraud) 


* Treatment Margins
xtpoisson numidtheft i.treatment i.year, fe robust i(state_fips)
margins i.treatment, atmeans

xtpoisson numfraud i.treatment i.year, fe robust i(state_fips)
margins i.treatment, atmeans

******************************* RELATIVE TIME *****************************

xtreg logid  fq4_plus fq4_treated-fq1_treated lq1_treated-lq4_treated lq4_plus i.year, fe cluster(state_fips)
outreg2 using "${here}/relative.xls", word ctitle(treated)

xtreg lnfraud fq4_plus fq4_treated-fq1_treated lq1_treated-lq4_treated lq4_plus i.year ehr_himss5, fe cluster(state_fips)
outreg2 using "${here}/relative.xls", word ctitle(treated) 

xtpoisson numidtheft fq4_plus fq4_treated-fq1_treated lq1_treated-lq4_treated lq4_plus i.year ehr_himss5,  fe robust i(state_fips)
outreg2 using "${here}/relative.xls", word ctitle(treated) 

xtpoisson numfraud fq4_plus fq4_treated-fq1_treated lq1_treated-lq4_treated lq4_plus i.year ehr_himss5,  fe robust i(state_fips)
outreg2 using "${here}/relative.xls", word ctitle(treated) 


====================================== Alternate DV ==================================

gen logEvents = ln( numevent + 1)
gen logRecords = ln( numrecords + 1)
gen logEventsOCR = ln( numeventocr + 1)
gen logRecordsOCR = ln( numrecordsocr + 1)

- privacy rights clearinghouse
xtreg logEvents treatment i.year, fe cluster(state_fips)
outreg2 using "${here}/base_alt.xls", word ctitle(treated) 
xtreg logRecords treatment i.year, fe cluster(state_fips)
outreg2 using "${here}/base_alt.xls", word ctitle(treated) 

xtpoisson numevent treatment i.year,  fe robust i(state_fips)
outreg2 using "${here}/base_alt.xls", word ctitle(treated) 
xtpoisson numrecords treatment i.year,  fe robust i(state_fips)
outreg2 using "${here}/base_alt.xls", word ctitle(treated) 

- OCR - breaches of healthcare providers
xtreg logEventsOCR treatment i.year if year > 2008, fe cluster(state_fips)
xtreg logRecordsOCR treatment i.year if year > 2008, fe cluster(state_fips)

xtpoisson numEvent treatment i.year if year > 2008,  fe robust i(state_fips)
xtpoisson numRecords treatment i.year if year > 2008,  fe robust i(state_fips)

######################## Umyarovs Equavalency ##############################

gen psuedo_treat = 0
gen randnum = uniform()
forvalues i=1/1000 {
	replace randnum = uniform()
	sort randnum
	replace psuedo_treat = 0
	replace psuedo_treat = 1 if _n <= 191

	xtreg logID  psuedo_treat i.year, fe cluster(state_fips)
	outreg2 using "C:\Users\bradn\Dropbox\LAW 612 - FTC Seminar\Data\psuedo1.xls", word ctitle(treated) 
	xtreg lnFraud psuedo_treat i.year ehr_himss5, fe cluster(state_fips)
	outreg2 using "C:\Users\bradn\Dropbox\LAW 612 - FTC Seminar\Data\psuedo2.xls", word ctitle(treated) 

	xtpoisson numIDTheft psuedo_treat i.year, fe robust i(state_fips)
	outreg2 using "C:\Users\bradn\Dropbox\LAW 612 - FTC Seminar\Data\psuedo3.xls", word ctitle(treated) 
	xtpoisson numFraud psuedo_treat i.year, fe robust i(state_fips)
	outreg2 using "C:\Users\bradn\Dropbox\LAW 612 - FTC Seminar\Data\psuedo4.xls", word ctitle(treated) 
  }

********************* ROBUSTNESS CHECK: TREATMENT TIMING **********************

*** Goodman-Bacon Decomposition
* Use BACONDECOMP Package; uncomment next line to install
* ssc install bacondecomp

xtreg logid treatment i.year, fe robust
bacondecomp logid treatment, ddetail

xtreg lnfraud treatment i.year, fe robust
bacondecomp lnfraud treatment, ddetail

* Repeat the analysis but exclude states treated after 2014
gen exclude = 1  /// Exclude every state except...
replace exclude = 0 if treatmentYear == 2014 /// ...states treated in 2014
replace exclude = 0 if treatmentYear == .    /// ...never-treated states

* OLS - DV: ln(ID Theft) - Excluding states treated after 2014
xtreg logid treatment i.year if exclude == 0, fe cluster(stateid)
outreg2 using "${here}\FirstTreatmentPeriodOnly.xls", word ctitle(ln(ID Theft)) 

* OLS - DV: ln(Fraud) - Excluding states treated after 2014
xtreg lnfraud treatment i.year if exclude == 0, fe cluster(stateid)
outreg2 using "${here}\FirstTreatmentPeriodOnly.xls", word ctitle(ln(Fraud)) 

* PPML - DV: ID Theft - Excluding states treated after 2014
xtpoisson numidtheft treatment i.year if exclude == 0, fe robust i(stateid)
outreg2 using "${here}\FirstTreatmentPeriodOnly.xls", word ctitle(Poisson - ID Theft) 

* PPML- DV: Fraud - Excluding states treated after 2014
xtpoisson numfraud treatment i.year if exclude == 0, fe robust i(stateid)
outreg2 using "${here}\FirstTreatmentPeriodOnly.xls", word ctitle(Poisson - Fraud)

********************* ROBUSTNESS CHECK: DOUBLY ROBUST DID **********************
* Command is available from ssc
ssc install csdid, replace

* Generate treatment group identifier gvar
gen gvar = treatmentyear
replace gvar = 0 if treatmentyear == 9999

* Identity Theft
csdid logid, gvar(gvar) ivar(state_fips) time(year) tr(treatment)

estat event
csdid_plot

* Fraud
csdid lnfraud, gvar(gvar) ivar(state_fips) time(year) tr(treatment)

estat event
csdid_plot