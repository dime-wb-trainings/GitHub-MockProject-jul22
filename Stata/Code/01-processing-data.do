* Clean Data
*------------------------------------------------------------------------------*
*	Part 1: Load raw data
*------------------------------------------------------------------------------*

	* Load original data
	use "${data}/Raw/ALB_ES_2017.dta", clear 

*------------------------------------------------------------------------------*
*	Part 2: Ensure proper ID variable
*------------------------------------------------------------------------------*  
  
  * Test for proper ID variable - commented out if error is expected
  // isid id // not proper id 
  
  duplicates report id //investigate this id - close enough to use in ieduplicates
  
  * Use ieduplicates - see the list-of-diffs column. No difference in any variable with data,
  * we can then immedeatly conclude this is a true duplicate and not two different observations assigned the same ID
  ieduplicates id using "${data}/Documentation/duplicates_report.xlsx" , uniquevars(unique_key) nodaily
  
  * Test id again
  isid id
  
  
*------------------------------------------------------------------------------*
*	Part 3a: Make sure data is stored in correct format and have labels
*------------------------------------------------------------------------------*   
  
  * rename string variable to replace
  rename Region      region_str
  
  * Pre-define lable
  label define region 1 "North" 2 "Central" 3 "South"
  
  * Encode old region variable. Always use label() with a predefined label.
  * Otherwise Stata assignes labels alphabetically, and if data changes, then 
  * codes changes. This is unstable and can lead to errors. noextend throws an
  * error if any value does not have a predefined label
  encode region_str, gen(region) label(region) noextend
  
  * Order new variable next to old and then drop old
  order  region, after(region_str)
  drop   region_str

  * Convert numbers stored as strings
  destring County_code       , replace
  destring Municipality_code , replace
  destring m1_02 , replace
 
*------------------------------------------------------------------------------*
*	Part 3b: Missing values
*------------------------------------------------------------------------------*   
  
  * Identify values with missing codes stored as numbers
  ds, has(type numeric) 
  // summarize `r(varlist)' - initially ran here, but moved to after recode
  
  * After making sure none of the -888 and -999 are valid data, update in bulk.
  * Only update in bulk if you are 100% sure these codes will never be data. 
  * The benefit of updating in bulk is that you make sure the same codes are 
  * used consistently. Always have .a, .b etc represent the same reason for
  * missing data
  recode `r(varlist)' (-888 = .a) (-999 = .b)
  
  * Confirm no further codes
  summarize `r(varlist)'
  
*------------------------------------------------------------------------------*
*	Part 4: Save cleaned data
*------------------------------------------------------------------------------*
  
  * This command saves the data in verision 14 so that it can be used by users
  * using older versions of Stata. And it re-confirms that the ID variables still
  * fully and uniquely identifies the data.
  iesave "${data}/Intermediate/firmdata_cleaned.dta", idvars(id) version(14.1) replace 
  
  
*------------------------------------------------------------------------------*
*	Part 5a: Share in untidy
*------------------------------------------------------------------------------*
  
  * Keep only relevant variables to make it simpler
  keep id m2_05_t1 m2_05_t2 m2_10_t1 m2_10_t2
  
  preserve 
  
    * Dummy for higher education
    gen edu_1 = (m2_10_t1 == 4 | m2_10_t1 == 5 | m2_10_t1 == 6 | m2_10_t1 == 7) if !missing(m2_10_t1)
    gen edu_2 = (m2_10_t2 == 4 | m2_10_t2 == 5 | m2_10_t2 == 6 | m2_10_t2 == 7) if !missing(m2_10_t2)
    
    * Dummy if hire exists
    gen tot_1 = 1 if !missing(m2_10_t1)
    gen tot_2 = 1 if !missing(m2_10_t2)
    
    * Sum across rows
    egen edu = rowtotal(edu_?)
    egen tot = rowtotal(tot_?)
    
    * Store the countrs in locals and calculate share
    sum edu
    local edu_count = r(sum) 
    sum tot
    local tot_count = r(sum)   
    local share = `edu_count' / `tot_count'
    
    display "Share of new hires with higher education: `share'"
    
  restore
  
  
  *------------------------------------------------------------------------------*
  *	Part 5b: Tidy data
  *------------------------------------------------------------------------------*
  
  keep id m2_05_t1 m2_05_t2 m2_10_t1 m2_10_t2
   
  * Transform the data to tidy format
  reshape long m2_05_t m2_10_t, i(id) j(occupation_type)
  
  * Optional, remove rows without a corresponding observation
  //drop if m2_05_t == 0
  
  * Dummy for higher education
  gen edu = (m2_10_t == 4 | m2_10_t == 5 | m2_10_t == 6 | m2_10_t == 7) if m2_05_t != 0 & !missing(m2_10_t)
  
  * Calculate share
  sum edu 
  display "Share of new hires with higher education: `r(mean)'"
  
