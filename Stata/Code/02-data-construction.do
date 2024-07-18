* Construct Data	
*-------------------------------------------------------------------------------
* Load clean data
*------------------------------------------------------------------------------- 			
	
	use "${data}/Intermediate/firmdata_cleaned.dta", clear
	
*-------------------------------------------------------------------------------
* Data construction - financial variables
*-------------------------------------------------------------------------------	

* Task 2
	* Reshaping to create financial variables
	preserve 
	
		keep m5_12* m5_13* m5_14* id
		
		reshape long m5_12_y m5_13_y m5_14_y, i(id) j(year)
		
		* Define exchange rate to standardize by USD
		local ex_rate 110.95
		
		* Creating usd vars
		foreach var in m5_12 m5_13 m5_14 {
		    
			gen `var'_usd = `var'_y/ `ex_rate'
			
		}
		
		* generating profits (sales - (compensation + expenses))
		gen profits_usd = m5_14_usd - (m5_12_usd + m5_13_usd)
		
		* Task 3 	
		* Checking profits outliers 
		sum profits_usd, det
		hist profits_usd

		* winsorzing at 95th percentile
		winsor profits_usd, p(0.05) gen(profits_usd_w)
		
		* Aggregating to firm level
		collapse (sum) 	m5_14_usd profits_usd profits_usd_w, by(id)
		
		tempfile profits 
		save `profits'
		
	restore
	
	* merge back to clean data
	merge 1:1 id using `profits', assert(3) nogen
	
*-------------------------------------------------------------------------------
* Task 4: Data construction - Share of women workers and indicator for managers
*-------------------------------------------------------------------------------		
	
	* Share of women wokrkers
	gen women_workers = m1_06/m1_04
	
	* If proportion of women managers is more than half
	gen 	women_managers = inlist(m1_13_e1, 2, 3)
	replace women_managers = . 							if mi(m1_13_e1)
	
*-------------------------------------------------------------------------------
* Data construction - Indicator if any emplyee has more than high school educ
*-------------------------------------------------------------------------------		
	
	* Reshapeing education variables
	preserve 

		keep id m2_05_t1 m2_05_t2 m2_10_t1 m2_10_t2

		* Transform the data to tidy format
		reshape long m2_05_t m2_10_t, i(id) j(occupation_type)

		* Optional, remove rows without a corresponding observation
		//drop if m2_05_t == 0

		* Dummy for higher education
		gen edu_high = (m2_10_t == 5 | m2_10_t == 6 | m2_10_t == 7) if m2_05_t != 0 & !missing(m2_10_t)
		
		* Aggregating to firm level
		collapse (max) edu_high, by(id)

		keep id edu_high

		tempfile edu
		save `edu'

	restore
	  
	* merge back to clean data
	merge 1:1 id using `edu', assert(3) nogen
	
*-------------------------------------------------------------------------------
* Preparing data for analysis - labels and subsetting
*-------------------------------------------------------------------------------		
	 
	 * Labeling variables
	lab var m5_14_usd 			"Sales 2015/16 (USD)"
	lab var profits_usd			"Profits 2015/16 (USD)"
	lab var profits_usd_w		"Profits 2015/16 (USD) Winsorized 0.05"
	lab var women_workers 		"Share of women employees"
	lab var women_managers 		"More than half women managers"
	lab var edu_high			"Any employee has more than high school education"
	
	
	* Value labels 
	lab def manage 	0 "Less than half" 		1 "More than half"
	lab def edu 	0 "Less than college" 	1 "College or higher"
	
	lab val women_managers manage
	lab val edu_high edu

	* Keeping variables needed for analysis 
	keep 	region County_code Municipality_code id ///
			profits_usd profits_usd_w ///
			women_workers women_managers edu_high
		
	save 	"${data}/Final/firmdata_constructed.dta", replace
	
*************************************************************************** end!			
