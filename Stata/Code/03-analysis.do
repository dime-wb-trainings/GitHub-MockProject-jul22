* IMF RRF 2024 - Data Analysis Solutions	
*-------------------------------------------------------------------------------	
* Loading Constructed data
*------------------------------------------------------------------------------- 

	use "${data}/Final/firmdata_constructed.dta", clear
	
*-------------------------------------------------------------------------------	
* Summary stats
*------------------------------------------------------------------------------- 
	
	* Defining a a global for summary variables
	global sum_vars profits_usd_w edu_high women_workers

	* Summary statistics by region 
	sumstats 	($sum_vars) ///
				($sum_vars if region == 1) ///
				($sum_vars if region == 2)  ///
				($sum_vars if region == 3)  ///
				using "${outputs}/Tables/summary-statistics-1.xlsx", ///
				stats(mean p50 sd min max n) replace 
				
				
	* Summary using esttab			
	eststo est1: estpost sum $sum_vars
	
	esttab 	est1 using "${outputs}/Tables/summary-statistics-2.csv", ///
			cells("count(label(N)) mean(label(Mean)) sd(label(SD)) min(label(Min)) max(label(Max))" ) ///
			nonumber nomtitle noobs label replace
			
*-------------------------------------------------------------------------------	
* Balance tables
*------------------------------------------------------------------------------- 	
	
	* Balance (if more than half women managers or not)
	iebaltab 	$sum_vars, ///
				grpvar(women_managers) ///
				rowvarlabels	///
				format(%12.3f)	///
				savecsv("${outputs}/Tables/balance-1") ///
				replace 			
				
*-------------------------------------------------------------------------------	
* Regressions
*-------------------------------------------------------------------------------	

	
	* Regression 1: Total profits on college education
	reg profits_usd_w edu_high
	est sto reg1
	
	* Regression 2: controlling for women_managers
	reg profits_usd_w edu_high women_managers
	est sto reg2
	
	* Regression 2: controlling for women_managers + clustering by Municipality
	reg profits_usd_w edu_high women_managers, vce(cl Municipality_code )
	est sto reg3
	
	* exporting regression
	esttab 	reg1 reg2 reg3			///
			using "${outputs}/Tables/regression-1.csv", ///
			label ///
			replace							
			
*-------------------------------------------------------------------------------			
* Graphs 
*-------------------------------------------------------------------------------	

	* Total Profits over region
	gr hbar	profits_usd_w, 	///
			over(region)
			
	* Profits by 1000s for better scaling 
	gen profits_th_usd_w = profits_usd_w/1000
	
	* Adding options
	gr hbar	profits_th_usd_w, 							///
			over(region)								///
			ytitle("Average profits (1000s USD)")		///
			graphregion(color(white)) bgcolor(white)
			
	* Total Profits over region 
	gr hbar (sum) 		profits_th_usd_w, 						///
						over(region) 							///
						ytitle("Total profits (1000s USD)")		///
						graphregion(color(white)) bgcolor(white)
						
	* Total Profits over region and by women managers
	gr hbar  			profits_th_usd_w, 						///
						over(region) 							///
						by(	women_managers, 					///
							graphregion(color(white)) 			///
							bgcolor(white)						///
							title("Profits by proportion of women managers", size(small)))	///
						ytitle("Average profits (1000s USD)")		///
						ylabel(,labs(vsmall)) name(g1, replace)
						
	
	* twoway kdensity
	twoway 	(kdensity women_workers if women_managers == 0) ///
			(kdensity women_workers if women_managers == 1)
			
	* Adding legend label	
	twoway 	(kdensity women_workers if women_managers == 0) 	///
			(kdensity women_workers if women_managers == 1),	///
			legend(	lab(1 "Less than half women managers")  	///
					lab(2 "More than half women managers")		///
					col(1))										///
			graphregion(color(white)) bgcolor(white) 			///
			ytitle(Distribution) 								///
			title("Distribution of women workers by proportion of women managers", size(small)) ///
			xtitle("Share of women workers") name(g2, replace)
			
	* Combining graphs
	gr combine g1 g2, c(1)
			
	* saving graph 					
	graph export  "${outputs}/Figures/graph-1.png", replace				
			
*************************************************************************** end!			
			
