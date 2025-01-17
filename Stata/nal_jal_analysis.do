/*******************************************************************************
TITLE:				nal_jal_analysis.do
	
COMPONENT: 			Regression analysis

AUTHOR:				Swathi C S

CONTACT:			swathi.cs.1999@gmail.com
		
DATE:				15/01/2024

INPUT DATASET: 		(1)	Dataset with  sec_ant_phed_clean - 
					(2)	Control datasets


DESCRIPTION: 		

SSC PROGRAMS: 		ssc install addplot
					net install gr0091.pkg

NOTES:	

--------------------------------------------------------------------------------
TABLE OF CONTENTS:

	0. Set up the environment
	
	Part I. 
	
	PART II: 
		
	PART III: 
	
	PART IV: 
	
--------------------------------------------------------------------------------*/

*-------------------------------------------------------------------------------*
* 0. Set up the environment
*-------------------------------------------------------------------------------*
	
* Clear environment
	clear all
	set more off

* Set maxvar
	set maxvar 30000 

* Clear environment
	clear
	clear matrix
	clear mata
	macro drop _all

* Folder setup

	dropbox
	
	global gates_db `"Bihar Gates Team/Nal_Jal"'
	
	global peer_effects_db `"Peer Effects and Role Models/Analysis_Experiment"'
	
*-------------------------------------------------------------------------------*
* 1. Run regressions
*-------------------------------------------------------------------------------*
	
	use "$gates_db/Output/sec_ant_phed_clean.dta", clear
			
	count
		//	88,943
		
	isid UGP VillageCode2011 WardNo
		//	Unique at level of UGP, VillageCode2011 and WardNo
	
	duplicates drop UGP VillageCode2011, force
	
	count
		//	19,674
		
	count if total_hhd==0
		
	summ perc_phed_njal
	
	/*
	
	Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
perc_phed_~l |     19,674    .1962181    .3775871          0          1

	*/
	
	set graphics off
			
		*------------------------------------------------------------------*
		*	1.1 District FE
		*-------------------------------------------------------------------*	
	eststo e1: reghdfe percent_hhd_piped_water perc_phed_njal if percent_hhd_piped_water>=0, abs(DistrictName)
		
	estadd local FE "DistrictName":e1
	
	estadd local Controls "None":e1
		
	esttab e1 using "$gates_db/Output/Regression results/PHED_water_access.tex", replace   ///
 b(3) se(3) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 label booktabs nonotes collabels(none) compress alignment(D{.}{.}{-1}) ///
 stats(N FE Controls, label("Observations" "Fixed Effects" "Controls") fmt(0 0))   ///
 		mtitles("\shortstack{\textbf{Mean}\\\textbf{HHs with piped water}}")
			
	coefplot (e1, keep(perc_phed_njal) label("`: var label percent_hhd_piped_water'")), levels(95) xline(0) mlabel format(%9.2g) mlabposition(12) mlabgap(*2) xtitle("Effect of Nal-Jal implementation by PHED on household access to piped water") order(Control Treatment) note("District Fixed Effects added.", pos(6)) graphregion(color(white))
	
	graph export "$gates_db/Output/Regression results/Effect_PHED_water_access.png", replace

		*------------------------------------------------------------------*
		*	1.2. District + SubDistrictName FE
		*------------------------------------------------------------------*
		
	eststo e1: reghdfe percent_hhd_piped_water perc_phed_njal if percent_hhd_piped_water>=0, abs(block_id)
		
	estadd local FE "DistrictName SubDistrictName":e1
	
	estadd local Controls "None":e1
		
		esttab e1 using "$gates_db/Output/Regression results/PHED_water_access_block_fe.tex", replace   ///
 b(3) se(3) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 label booktabs nonotes collabels(none) compress alignment(D{.}{.}{-1}) ///
 stats(N FE Controls, label("Observations" "Fixed Effects" "Controls") fmt(0 0))   ///
 		mtitles("\shortstack{\textbf{Mean}\\\textbf{HHs with piped water}}")
		
coefplot (e1, keep(perc_phed_njal) label("`: var label percent_hhd_piped_water'")), levels(95) xline(0) mlabel format(%9.2g) mlabposition(12) mlabgap(*2) xtitle("Effect of Nal-Jal implementation by PHED on household access to piped water") order(Control Treatment) note("Block-level Fixed Effects added.", pos(6)) graphregion(color(white))
graph export "$gates_db/Output/Regression results/Effect_PHED_water_access_block_fe.png", replace
	
	
		*------------------------------------------------------------------*
		*	1.3. District + SubDistrictName + GramPanchayatName FE
		*------------------------------------------------------------------*
	
	eststo e1: reghdfe percent_hhd_piped_water perc_phed_njal if percent_hhd_piped_water>=0, abs(UGP)
		
	estadd local FE "DistrictName SubDistrictName GramPanchayatName":e1
	
	estadd local Controls "None":e1
		
		esttab e1 using "$gates_db/Output/Regression results/PHED_water_access_ugp_fe.tex", replace   ///
 b(3) se(3) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 label booktabs nonotes collabels(none) compress alignment(D{.}{.}{-1}) ///
 stats(N FE Controls, label("Observations" "Fixed Effects" "Controls") fmt(0 0))   ///
 		mtitles("\shortstack{\textbf{Mean}\\\textbf{HHs with piped water}}")
		
coefplot (e1, keep(perc_phed_njal) label("`: var label percent_hhd_piped_water'")), levels(95) xline(0) mlabel format(%9.2g) mlabposition(12) mlabgap(*2) xtitle("Effect of Nal-Jal implementation by PHED on household access to piped water") order(Control Treatment) note("UGP-level Fixed Effects added.", pos(6)) graphregion(color(white))
graph export "$gates_db/Output/Regression results/Effect_PHED_water_access_ugp_fe.png", replace
		
		*------------------------------------------------------------------*
		*	1.4. With perc_phed_njal converted to dummy
		*------------------------------------------------------------------*
	
		*------------------------------------------------------------------*
		*	1.4.a District-level FE
		*------------------------------------------------------------------*
	
		tab perc_phed_njal
		
		gen phed_njal = 0 if perc_phed_njal == 0
		
		replace phed_njal = 1 if perc_phed_njal>0 & perc_phed_njal!=.
		
		tab phed_njal
		
		/*
			phed_njal |      Freq.     Percent        Cum.
		------------+-----------------------------------
				  0 |     15,009       76.58       76.58
				  1 |      4,590       23.42      100.00
		------------+-----------------------------------
			  Total |     19,599      100.00

	  */
	  
	  eststo e1: reghdfe percent_hhd_piped_water phed_njal if percent_hhd_piped_water>=0, abs(DistrictName)
		
	estadd local FE "DistrictName":e1
	
	estadd local Controls "None":e1
		
		esttab e1 using "$gates_db/Output/Regression results/PHED_water_access_district_fe_bin.tex", replace   ///
 b(3) se(3) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 label booktabs nonotes collabels(none) compress alignment(D{.}{.}{-1}) ///
 stats(N FE Controls, label("Observations" "Fixed Effects" "Controls") fmt(0 0))   ///
 		mtitles("\shortstack{\textbf{Mean}\\\textbf{HHs with piped water}}")
		
coefplot (e1, keep(phed_njal) label("`: var label percent_hhd_piped_water'")), levels(95) xline(0) mlabel format(%9.2g) mlabposition(12) mlabgap(*2) xtitle("Effect of Nal-Jal implementation by PHED on household access to piped water") order(Control Treatment) note("District-level Fixed Effects added.", pos(6)) graphregion(color(white))
graph export "$gates_db/Output/Regression results/Effect_PHED_water_access_district_fe_bin.png", replace
		
		*------------------------------------------------------------------*
		*	1.4.b Subdistrict-level FE
		*------------------------------------------------------------------*
		
		eststo e1: reghdfe percent_hhd_piped_water phed_njal if percent_hhd_piped_water>=0, abs(block_id)
		
	estadd local FE "DistrictName SubDistrictName":e1
	
	estadd local Controls "None":e1
		
		esttab e1 using "$gates_db/Output/Regression results/PHED_water_access_block_fe_bin.tex", replace   ///
 b(3) se(3) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 label booktabs nonotes collabels(none) compress alignment(D{.}{.}{-1}) ///
 stats(N FE Controls, label("Observations" "Fixed Effects" "Controls") fmt(0 0))   ///
 		mtitles("\shortstack{\textbf{Mean}\\\textbf{HHs with piped water}}")
		
coefplot (e1, keep(phed_njal) label("`: var label percent_hhd_piped_water'")), levels(95) xline(0) mlabel format(%9.2g) mlabposition(12) mlabgap(*2) xtitle("Effect of Nal-Jal implementation by PHED on household access to piped water") order(Control Treatment) note("Block-level Fixed Effects added.", pos(6)) graphregion(color(white))
graph export "$gates_db/Output/Regression results/Effect_PHED_water_access_block_fe_bin.png", replace

		*------------------------------------------------------------------*
		*	1.4.c UGP-level FE
		*------------------------------------------------------------------*
	
		eststo e1: reghdfe percent_hhd_piped_water phed_njal if percent_hhd_piped_water>=0, abs(UGP)
		
			//	7330 UGPs. redendant
		
	estadd local FE "DistrictName SubDistrictName GramPanchayatName":e1
	
	estadd local Controls "None":e1
		
		esttab e1 using "$gates_db/Output/Regression results/PHED_water_access_ugp_fe_bin.tex", replace   ///
 b(3) se(3) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 label booktabs nonotes collabels(none) compress alignment(D{.}{.}{-1}) ///
 stats(N FE Controls, label("Observations" "Fixed Effects" "Controls") fmt(0 0))   ///
 		mtitles("\shortstack{\textbf{Mean}\\\textbf{HHs with piped water}}")
		
coefplot (e1, keep(phed_njal) label("`: var label percent_hhd_piped_water'")), levels(95) xline(0) mlabel format(%9.2g) mlabposition(12) mlabgap(*2) xtitle("Effect of Nal-Jal implementation by PHED on household access to piped water") order(Control Treatment) note("UGP-level Fixed Effects added.", pos(6)) graphregion(color(white))
graph export "$gates_db/Output/Regression results/Effect_PHED_water_access_ugp_fe_bin.png", replace
		
*------------------------------------------------------------------*
*	2.	Histograms
*------------------------------------------------------------------*
	
	histogram perc_phed_njal, percent title("Percentage of wards where Nal-Jal implemented by PHED")
	
	graph export "$gates_db/Output/Regression results/Percent_PHED.png", replace
	
	histogram percent_hhd_piped_water, percent title("Percentage of households in village with access to piped water")
	
	graph export "$gates_db/Output/Regression results/Percent_pipedwater_access.png", replace
	
*------------------------------------------------------------------*
*	3.	Scatter plots
*------------------------------------------------------------------*
	
		*	3.1. District FE
	
	binscatterhist percent_hhd_piped_water perc_phed_njal, absorb(DistrictName) sample note("District fixed effects added", pos(6)) title(Scatterplot) l1title(Proportion of HHs with access to water) b1title(Proportion of wards with PHED Nal-Jal implementation)
	
	graph export "$gates_db/Output/Regression results/scatter_district_FE.png", replace
	
		*	3.2. SubDistrictName FE
		
	binscatterhist percent_hhd_piped_water perc_phed_njal, absorb(block_id) sample note("Block fixed effects added", pos(6)) title(Scatterplot) l1title(Proportion of HHs with access to water) b1title(Proportion of wards with PHED Nal-Jal implementation)
	
	graph export "$gates_db/Output/Regression results/scatter_block_FE.png", replace
	
		*	3.3. UGP FE
		
	binscatterhist percent_hhd_piped_water perc_phed_njal, absorb(UGP) sample note("UGP fixed effects added", pos(6)) title(Scatterplot) l1title(Proportion of HHs with access to water) b1title(Proportion of wards with PHED Nal-Jal implementation)
	
	graph export "$gates_db/Output/Regression results/scatter_UGP_FE.png", replace
	
*------------------------------------------------------------------*
*	4.	Adding controls
*------------------------------------------------------------------*
	
	*	4.4 1a.GPVillageAmenities.dta
	
	use "$gates_db/Input/GPVillageAmenities.dta", clear
	
	count
	
		//	45,134
		
	codebook VillageCode2011
	
		//	187 mi.
		
	codebook VillageCode
	
	count if VillageCode==VillageCode2011
	
		//	Same in 44,947 cases
		
		dis 44947+187

		
	codebook TotalScheduledCastesPopulatio
	
		//	Missing .: 5,775/45,134
		
		count if TotalScheduledCastesPopulatio==0
		
		//	6,400
	
	codebook TotalPopulationofVillage
	
		//	Missing .: 242/45,134
		
		count if TotalPopulationofVillage==0
		
		//	5,533
		
		replace TotalPopulationofVillage=. if TotalPopulationofVillage==0
	
	codebook TotalGeographicalAreainHect
	
		//	Missing .: 242/45,134
		
		count if TotalGeographicalAreainHect==0
		
		//	266
		
		replace TotalGeographicalAreainHect=. if TotalGeographicalAreainHect==0
	
	codebook NearestStatutoryTownDistance
	
	destring NearestStatutoryTownDistance, replace

		//	Missing "": 5,775/45,134
	
	codebook DistrictHeadQuarterDistance
	
		//	 Missing .: 5,775/45,134
	
	codebook GovtPrimarySchoolNumbers
	
		//	Missing .: 5,775/45,134
	
	codebook TapWaterTreatedStatusA1N
	
		//	Only 2 and mis.
	
	codebook TapWaterUntreatedStatusA1
	
	recode TapWaterUntreatedStatusA1 (2=0), gen(TapWaterUntreated_bin)
	
	codebook PrimaryHeallthSubCentreNumb
	
	codebook AllWeatherRoadStatusA1NA
	
	recode AllWeatherRoadStatusA1NA(2=0), gen(AllWeatherRoad_bin)
	
		keep UGP VillageCode TotalScheduledCastesPopulatio TotalPopulationofVillage TotalGeographicalAreainHect NearestStatutoryTownDistance DistrictHeadQuarterDistance GovtPrimarySchoolNumbers TapWaterUntreated_bin PrimaryHeallthSubCentreNumb AllWeatherRoad_bin
		
		rename VillageCode VillageCode2011
		
		isid UGP VillageCode2011
		
		duplicates tag VillageCode2011, gen(dup_vil)
		
		tab dup_vil
		
			*br UGP VillageCode2011 if dup_vil>0
			
		drop dup_vil
		
		save "$gates_db/Input/GPVillageAmenities_clean.dta", replace
		
	*	Merging dataset with GPVillageAmenities_clean
	
		use "$gates_db/Output/sec_ant_phed_clean", clear
		
		count
			
		duplicates drop UGP VillageCode2011, force
		
		count
		
			//	19,674
		
		merge 1:1 UGP VillageCode2011 using "$gates_db/Input/GPVillageAmenities_clean.dta", gen(gp_am_merge)
		
		/*
			Result                      Number of obs
    -----------------------------------------
    Not matched                        25,460
        from master                         0  (gp_am_merge==1)
        from using                     25,460  (gp_am_merge==2)

    Matched                            19,674  (gp_am_merge==3)
    -----------------------------------------


		*/
		
		keep if gp_am_merge==1|gp_am_merge==3
		
		count
		
			//	19674
			
		save "$gates_db/Output/sec_ant_phed_vilamen", replace
		
	*	Running regressions
	
		use "$gates_db/Output/sec_ant_phed_vilamen", clear
		
		findname, any(length("@") > 27)
		
		rename DistrictHeadQuarterDistance DistHQDis
		
		rename NearestStatutoryTownDistance NearTownDis
		
		rename TotalGeographicalAreainHect AreainHect
		
		rename TotalPopulationofVillage VillagePop
		
		rename TotalScheduledCastesPopulatio SCPop
		
		rename GovtPrimarySchoolNumbers GovtPrimarySchoolNo
		
		rename PrimaryHeallthSubCentreNumb PHCNo
		
		codebook, compact
		
		summ VillagePop, det
		
		gen VillagePop_100 = VillagePop/100
		
		summ VillagePop_100
		
		local control_vars "DistHQDis NearTownDis AreainHect VillagePop SCPop GovtPrimarySchoolNo PHCNo TapWaterUntreated_bin AllWeatherRoad_bin"
		
		codebook `control_vars', compact
		
		foreach var in `control_vars'{
			
			label var `var'
			
		}
		
		summ NearTownDis AreainHect, det
		
		label var percent_hhd_piped_water "Proportion of households with piped water"
label var perc_phed_njal "Proportion of wards with PHED"
label var DistHQDis "Distance from district HQ (in km)"
label var NearTownDis "Distance from nearest town (in km)"
label var AreainHect "Area (in hac)"
label var VillagePop_100 "Population (in units of 100)"
label var SCPop "SC Population"
label var GovtPrimarySchoolNo "No. of gvt. primary schools"
label var PHCNo "No. of PHCs/SCs"
label var TapWaterUntreated_bin "If 100% households have water access"
label var AllWeatherRoad_bin "Has all-weather road"
		
		*/
			
	*	1. Independent var continuous: FE at GP-level and all controls

		count
	
		eststo e1: reghdfe percent_hhd_piped_water perc_phed_njal DistHQDis NearTownDis AreainHect VillagePop_100 SCPop GovtPrimarySchoolNo PHCNo TapWaterUntreated_bin AllWeatherRoad_bin if percent_hhd_piped_water>=0, abs(UGP)
		
	estadd local FE "UGP":e1
	
	estadd local Controls "Population,Land Area,Connectivity,Infra,Untreated Water":e1
		
		esttab e1 using "$gates_db/Output/Regression results/PHED_water_access_ugp_fe_cont.tex", replace   ///
 b(3) se(3) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 label booktabs nonotes collabels(none) compress alignment(D{.}{.}{-1}) ///
 stats(N FE Controls, label("Observations" "Fixed Effects" "Controls") fmt(0 0))   ///
 		mtitles("\shortstack{\textbf{Mean}\\\textbf{HHs with piped water}}")
		
		set graphics on
		
coefplot (e1, drop(_cons)), levels(95) xline(0) mlabel format(%9.2g) mlabposition(12) mlabgap(*2) xtitle("Effect of PHED Nal-Jal on household access to piped water") order(Control Treatment) note("UGP-level Fixed Effects and Controls added", pos(6)) graphregion(color(white))

graph export "$gates_db/Output/Regression results/Effect_PHED_ugp_fe_cont.png", replace

	*	For policy brief
	
	esttab e1 using "$gates_db/Output/Regression results/PHED_water_access_ugp_fe_cont_brief.tex", replace   ///
 b(3) se(3) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 label booktabs nonotes collabels(none) compress alignment(D{.}{.}{-1}) ///
 stats(N FE Controls, label("Observations" "Fixed Effects" "Controls") fmt(0 0))   ///
 		mtitles("\shortstack{\textbf{Mean}\\\textbf{HHs with piped water}}") addnotes("Figure 6. Regression table on effect of proportion of wards where Nal Jal implementation by PHED on proportion" "of households with access to piped water in village. Fixed effects at the GP level. Village-level controls" "on population, land area, connectivity, social infrastructure and pre-treatment access to untreated water added.\label{tab1}") nonumbers

	*	2. Independent var binary: FE at GP-level and all controls
		
		tab perc_phed_njal
		
		gen phed_njal = 0 if perc_phed_njal == 0
		
		replace phed_njal = 1 if perc_phed_njal>0 & perc_phed_njal!=.
		
		tab phed_njal
		
		label define phed_njal 0 "Wards with PHED 0%" 1 "Wards with PHED>0%"
		
		label val phed_njal phed_njal
		
		label var phed_njal "Binary variable: Any PHED=1"
		
	eststo e1: reghdfe percent_hhd_piped_water phed_njal DistHQDis NearTownDis AreainHect VillagePop_100 SCPop GovtPrimarySchoolNo PHCNo TapWaterUntreated_bin AllWeatherRoad_bin if percent_hhd_piped_water>=0, abs(UGP)
		
	estadd local FE "UGP":e1
	
	estadd local Controls "Population,Land Area,Connectivity,Infra,Untreated Water":e1
		
		esttab e1 using "$gates_db/Output/Regression results/PHED_water_access_ugp_fe_cont_bin.tex", replace   ///
 b(3) se(3) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 label booktabs nonotes collabels(none) compress alignment(D{.}{.}{-1}) ///
 stats(N FE Controls, label("Observations" "Fixed Effects" "Controls") fmt(0 0))   ///
 		mtitles("\shortstack{\textbf{Mean}\\\textbf{HHs with piped water}}")
		
coefplot (e1, drop(_cons)), levels(95) xline(0) mlabel format(%9.2g) mlabposition(12) mlabgap(*2) xtitle("Effect of PHED Nal-Jal on household access to piped water") order(Control Treatment) note("UGP-level Fixed Effects and Controls added", pos(6)) graphregion(color(white))

graph export "$gates_db/Output/Regression results/Effect_PHED_ugp_fe_cont_bin.png", replace

	*/
	
	*	With different construction of binary variable
	
	tab perc_phed_njal, mi
	
	gen phed_naljal_2 = 0
	
	replace phed_naljal_2 = 1 if perc_phed_njal == 1
	
	label define phed_naljal_2 0 "Wards with PHED <100%" 1 "Wards with PHED = 100%", replace
	
	label val phed_naljal_2 phed_naljal_2
	
	label var phed_naljal_2 "Binary variable: All PHED=1"
	
	gen phed_naljal_3 = 0 if perc_phed_njal<0.5
	
	replace phed_naljal_3 = 1 if perc_phed_njal>=0.5
	
	label define phed_naljal_3 0 "Wards with PHED<50%" 1 "Wards with PHED>=50%"
	
	label val phed_naljal_3 phed_naljal_3
	
	label var phed_naljal_3 "Binary variable: greather than/equal 50% PHED=1"
	
		*	phed_naljal_2
		
		eststo e1: reghdfe percent_hhd_piped_water phed_naljal_2 DistHQDis NearTownDis AreainHect VillagePop_100 SCPop GovtPrimarySchoolNo PHCNo TapWaterUntreated_bin AllWeatherRoad_bin if percent_hhd_piped_water>=0, abs(UGP)
		
	estadd local FE "UGP":e1
	
	estadd local Controls "Population,Land Area,Connectivity,Infra,Untreated Water":e1
		
		esttab e1 using "$gates_db/Output/Regression results/PHED_water_access_ugp_fe_cont_bin_2.tex", replace   ///
 b(3) se(3) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 label booktabs nonotes collabels(none) compress alignment(D{.}{.}{-1}) ///
 stats(N FE Controls, label("Observations" "Fixed Effects" "Controls") fmt(0 0))   ///
 		mtitles("\shortstack{\textbf{Mean}\\\textbf{HHs with piped water}}")
		
coefplot (e1, drop(_cons)), levels(95) xline(0) mlabel format(%9.2g) mlabposition(12) mlabgap(*2) xtitle("Effect of PHED Nal-Jal on household access to piped water") order(Control Treatment) note("UGP-level Fixed Effects and Controls added", pos(6)) graphregion(color(white))

graph export "$gates_db/Output/Regression results/Effect_PHED_ugp_fe_cont_bin_2.png", replace

	*	phed_naljal_3
	
	eststo e1: reghdfe percent_hhd_piped_water phed_naljal_3 DistHQDis NearTownDis AreainHect VillagePop_100 SCPop GovtPrimarySchoolNo PHCNo TapWaterUntreated_bin AllWeatherRoad_bin if percent_hhd_piped_water>=0, abs(UGP)
		
	estadd local FE "UGP":e1
	
	estadd local Controls "Population,Land Area,Connectivity,Infra,Untreated Water":e1
		
		esttab e1 using "$gates_db/Output/Regression results/PHED_water_access_ugp_fe_cont_bin_3.tex", replace   ///
 b(3) se(3) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 label booktabs nonotes collabels(none) compress alignment(D{.}{.}{-1}) ///
 stats(N FE Controls, label("Observations" "Fixed Effects" "Controls") fmt(0 0))   ///
 		mtitles("\shortstack{\textbf{Mean}\\\textbf{HHs with piped water}}")
		
coefplot (e1, drop(_cons)), levels(95) xline(0) mlabel format(%9.2g) mlabposition(12) mlabgap(*2) xtitle("Effect of PHED Nal-Jal on household access to piped water") order(Control Treatment) note("UGP-level Fixed Effects and Controls added", pos(6)) graphregion(color(white))

graph export "$gates_db/Output/Regression results/Effect_PHED_ugp_fe_cont_bin_3.png", replace
	
	*	Regressions at GP-level
	
	use "$gates_db/Output/sec_ant_gp_final", clear
	
	egen block_id_gp = group(DistrictName SubDistrictName)
	
	codebook block_id_gp
	
		//	533
		
		*	Block FE and no controls
	
	eststo e1: reghdfe prop_hhd_water prop_phed_wards if prop_hhd_water>=0, abs(block_id_gp)
		
	estadd local FE "DistrictName SubDistrictName":e1
	
	estadd local Controls "None":e1
		
		esttab e1 using "$gates_db/Output/Regression results/PHED_water_access_gp_level.tex", replace   ///
 b(3) se(3) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 label booktabs nonotes collabels(none) compress alignment(D{.}{.}{-1}) ///
 stats(N FE Controls, label("Observations" "Fixed Effects" "Controls") fmt(0 0))   ///
 		mtitles("\shortstack{\textbf{Mean}\\\textbf{HHs with piped water}}")
		
coefplot (e1, keep(prop_phed_wards) label("Proportion of wards with PHED Nal-Jal implementation")), levels(95) xline(0) mlabel format(%9.2g) mlabposition(12) mlabgap(*2) xtitle("Effect of Nal-Jal implementation by PHED on household access to piped water") order(Control Treatment) note("Block-level Fixed Effects added.", pos(6)) graphregion(color(white))
graph export "$gates_db/Output/Regression results/Effect_PHED_water_access_gp_level.png", replace

		*	Block FE with GP-level controls
		
	use "$gates_db/Input/Controls/GPExtendedControls.dta", clear
	
	count
	
		//	8,392
		
	isid UGP
	
	codebook, compact
	
	rename DistrictHeadQuarterDistance DistHQDis
	
	rename NearestStatutoryTownDistance NearTownDis
	
	gen Tot_Pop2011C_100 = Tot_Pop2011C/100
	
	label var DistHQDis "Distance from district HQ (in km)"
	label var NearTownDis "Distance from nearest town (in km)"
	label var TotalArea "Area (in hac)"
	label var Tot_Pop2011C_100 "Population (in units of 100)"
	label var SCGPProp2011C "Proportion of SC in population"
	label var Villages "No. of villages in GP"
	
	save "$gates_db/Input/Controls/GPExtendedControls_clean.dta", replace
	
	*	Merge GP-level data with controls
	
	use "$gates_db/Output/sec_ant_gp_final", clear
	
	egen block_id_gp = group(DistrictName SubDistrictName)
	
	codebook block_id_gp
	
	merge 1:1 UGP using "$gates_db/Input/Controls/GPExtendedControls_clean.dta", gen(gp_controls)
	
		/*
			Result                      Number of obs
		-----------------------------------------
		Not matched                           701
			from master                         0  (gp_controls==1)
			from using                        701  (gp_controls==2)

		Matched                             7,691  (gp_controls==3)
		-----------------------------------------
		
		*/
		
	local gp_controls "DistHQDis NearTownDis TotalArea Tot_Pop2011C_100 SCGPProp2011C Villages"
		
	eststo e1, re: reghdfe prop_hhd_water prop_phed_wards `gp_controls' if prop_hhd_water>=0, abs(block_id_gp)
		
	estadd local FE "DistrictName SubDistrictName":e1
	
	estadd local Controls "Population,Land Area,No of villages":e1
		
		esttab e1 using "$gates_db/Output/Regression results/PHED_water_access_gp_level_cont.tex", replace   ///
 b(3) se(3) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 label booktabs nonotes collabels(none) compress alignment(D{.}{.}{-1}) ///
 stats(N FE Controls, label("Observations" "Fixed Effects" "Controls") fmt(0 0))   ///
 		mtitles("\shortstack{\textbf{Mean}\\\textbf{HHs with piped water}}")
		
coefplot (e1, drop(_cons) label("Proportion of wards with PHED Nal-Jal implementation")), levels(95) xline(0) mlabel format(%9.2g) mlabposition(12) mlabgap(*2) xtitle("Effect of Nal-Jal implementation by PHED on access to piped water") order(Control Treatment) note("Block-level Fixed Effects and Controls added.", pos(6)) graphregion(color(white))
graph export "$gates_db/Output/Regression results/Effect_PHED_water_access_gp_level_cont.png", replace

	*	For policy brief
	
	esttab e1 using "$gates_db/Output/Regression results/PHED_water_access_gp_level_cont_brief.tex", replace   ///
 b(3) se(3) ///
 star(* 0.10 ** 0.05 *** 0.01) ///
 label booktabs nonotes collabels(none) compress alignment(D{.}{.}{-1}) ///
 stats(N FE Controls, label("Observations" "Fixed Effects" "Controls") fmt(0 0))   ///
 		mtitles("\shortstack{\textbf{Mean}\\\textbf{HHs with piped water}}") addnotes("Figure 8. Regression table on effect of proportion of wards where Nal Jal implementation by PHED" "on proportion of households with access to piped water in village. Fixed effects at the subdistrict level." "GP-level controls on population, land area and number of villages added.\label{tab1}") nonumbers

	*	Histograms
	
	histogram prop_phed_wards, percent title("Proportion of wards where Nal-Jal implemented by PHED")
	
	graph export "$gates_db/Output/Regression results/Percent_PHED_gp.png", replace
	
	histogram prop_hhd_water, percent title("Proportion of households with access to piped water")
	
	graph export "$gates_db/Output/Regression results/Percent_pipedwater_access_gp.png", replace
