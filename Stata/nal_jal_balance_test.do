/*******************************************************************************
TITLE:				nal_jal_balance_test.do
	
COMPONENT: 			Balance Test

AUTHOR:				Swathi C S

CONTACT:			swathi.cs.1999@gmail.com
		
DATE:				05/01/2024

INPUT DATASET: 		(1)	Merged SEC-Antyodaya dataset - sec_ant_final_match_full
					(2)	Antyodaya dataset - antodaya_village_bihar_clean
					(3) Village-level controls - GPVillageAmenities_clean
					(4)	Ward-level controls - Ward Winners Clean


INTERMEDIATE DATASETS: 	(1) Ward Winners Clean_balance
						(2)	sec_gp_matched
						(3)	WardPopulations_blnce

DESCRIPTION: 		This .do file conducts balance tests between
					(1)	Matched and unmatched Census Villages from the Antyodaya
						dataset
					(2) Matched and unmatched electoral wards from the Bihar State
						Election Commission (SEC) dataset

SSC PROGRAMS: 		

NOTES:				This .do file follows nal_jal_match.do, where we matched
					observations from Antyodaya and SEC datasets using fuzzy merge.

--------------------------------------------------------------------------------
TABLE OF CONTENTS:

	0. Set up the environment
	
	PART I. Merge the matched dataset with full Antyodaya dataset
	
	PART II: Conduct balance tests
		
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
* 1. Merge the matched dataset with full Antyodaya dataset
*-------------------------------------------------------------------------------*

*	Merging SEC full dataset with Antyodaya
	
	use "$gates_db/Output/sec_ant_final_match_full.dta", clear
	
	count if VillageName_rep==""
		//	482
		
	replace VillageName_rep = "." if VillageName_rep==""
	
	count
		//	109,689
		
	sort UGP VillageName_rep uniq_vil_all_1 uniq_vil_all_2 uniq_vil_all_3 uniq_vil_all_4, stable
	
	*br UGP VillageName_rep uniq_vil_all_1
	
		//	missing comes last.
		
	count if Antyodaya_VillageName_1==""
	
		//	20,872
		
	count if Antyodaya_VillageName_1!=""
	
		//	88,817
		
*	Reshape to long on Antyodaya_VillageName_1
	
	isid UGP VillageName_rep WardNo
	
	reshape long Antyodaya_VillageName_ uniq_vil_all_ VillageCode2011_ total_hhd_ hhd_piped_water_ percent_hhd_piped_water_, i(UGP VillageName_rep WardNo)
			
	/*
		Data                               Wide   ->   Long
		-----------------------------------------------------------------------------
		Number of observations          109,689   ->   438,756
		Number of variables                  35   ->   18
	*/
	
	count if Antyodaya_VillageName_==""
	
	drop if Antyodaya_VillageName_==""
	
	count
		//	88,943
	
	duplicates drop UGP VillageCode2011_ total_hhd_ hhd_piped_water_ percent_hhd_piped_water_, force
	
	count
	
		//	19,674. Matched Antyodaya Villages
		
	count
		
	dis 19674/37314
	
		//	52.72%
		
	rename *_ *
	
	drop _j
	
	rename Antyodaya_VillageName VillageName
	
	drop vil_matched_2 vil_merge vil_matched sec_merge block_id total_hhd hhd_piped_water percent_hhd_piped_water
		
	merge 1:1 UGP VillageCode2011 using "$gates_db/Input/antodaya_village_bihar_clean.dta", gen(ant_match)

	/*
		 Result                      Number of obs
    -----------------------------------------
    Not matched                        17,640
        from master                         0  (ant_match==1)
        from using                     17,640  (ant_match==2)

    Matched                            19,674  (ant_match==3)
    -----------------------------------------
	*/	
		
	label var ant_match "Antyodaya final match results"
	
	save "$gates_db/Output/antodaya_full_matched.dta", replace

*----------------------------------------------------------------------------------*
*	2.	Balance tests
*----------------------------------------------------------------------------------*
	
*----------------------------------------------------------------------*
*	2.1	Villages in Antyodaya: Matched vs Unmatched		*----------------------------------------------------------------------*
	
	use "$gates_db/Output/antodaya_full_matched.dta", clear
	
	count
	
		//	37,314
		
	tab ant_match, mi
	
	/*
	Matching result from|
                  merge |      Freq.     Percent        Cum.
------------------------+-----------------------------------
         Using only (2) |     17,640       47.27       47.27
            Matched (3) |     19,674       52.73      100.00
------------------------+-----------------------------------
                  Total |     37,314      100.00
	*/
	
	duplicates tag UGP VillageName, gen(dup_vil)
	
	count if dup_vil>0 & ant_match==3
		//	159.
	
	recode ant_match (2=0) (3=1)
	
	egen ant_block_id = group(DistrictName SubDistrictName), mi label
	
	label var ant_block_id "Antyodaya block ID final"
	  
	 balancetable (mean if ant_match==0) (mean if ant_match==1) total_hhd total_hhd_having_piped_water_con percent_hhd_piped_water using "$gates_db/Output/Regression results/BalanceAnt.tex", ///
ctitles("Unmatched" "Matched") replace vce(robust) fe(UGP) starlevels(* 0.10 ** 0.05 *** 0.01)

	balancetable (mean if ant_match==0) (mean if ant_match==1) total_hhd total_hhd_having_piped_water_con percent_hhd_piped_water using "$gates_db/Output/Regression results/BalanceAnt_block.tex", ///
ctitles("Unmatched" "Matched") replace vce(robust) fe(ant_block_id) starlevels(* 0.10 ** 0.05 *** 0.01)

*----------------------------------------------------------------------*
*	2.2	Merging with datasets with village characteristics
*----------------------------------------------------------------------*
		
		merge 1:1 UGP VillageCode2011 using "$gates_db/Input/GPVillageAmenities_clean.dta", gen(gp_am_merge)
		
		/*
			Result                      Number of obs
    -----------------------------------------
    Not matched                         7,820
        from master                         0  (gp_am_merge==1)
        from using                      7,820  (gp_am_merge==2)

    Matched                            37,314  (gp_am_merge==3)
    -----------------------------------------
	
		*/
		
	keep if gp_am_merge==1|gp_am_merge==3
	
	count
	
	gen PropSCPop = TotalScheduledCastesPopulatio/TotalPopulationofVillage
	
	summ PropSCPop
	
label var total_hhd "No. of households"
label var total_hhd_having_piped_water_con "No. of households with piped water"
label var percent_hhd_piped_water "Proportion of households with piped water"
label var DistrictHeadQuarterDistance "Distance from district HQ (in km)"
label var NearestStatutoryTownDistance "Distance from nearest town (in km)"
label var TotalGeographicalAreainHect "Area (in hac)"
label var TotalPopulationofVillage "Population"
label var TotalScheduledCastesPopulatio "SC Population"
label var PropSCPop "Proportion of SC in population"
label var GovtPrimarySchoolNumbers "No. of gvt. primary schools"
label var PrimaryHeallthSubCentreNumb "No. of PHCs/SCs"
label var TapWaterUntreated_bin "If 100% households have water access"
label var AllWeatherRoad_bin "Has all-weather road"
	
	balancetable (mean if ant_match==0) (mean if ant_match==1) DistrictHeadQuarterDistance NearestStatutoryTownDistance TotalGeographicalAreainHect TotalPopulationofVillage TotalScheduledCastesPopulatio PropSCPop GovtPrimarySchoolNumbers PrimaryHeallthSubCentreNumb TapWaterUntreated_bin AllWeatherRoad_bin using "$gates_db/Output/Regression results/BalanceAnt_controls.tex", ///
ctitles("Unmatched" "Matched") replace vce(robust) fe(UGP) starlevels(* 0.10 ** 0.05 *** 0.01)

	balancetable (mean if ant_match==0) (mean if ant_match==1) DistrictHeadQuarterDistance NearestStatutoryTownDistance TotalGeographicalAreainHect TotalPopulationofVillage TotalScheduledCastesPopulatio PropSCPop GovtPrimarySchoolNumbers PrimaryHeallthSubCentreNumb TapWaterUntreated_bin AllWeatherRoad_bin using "$gates_db/Output/Regression results/BalanceAnt_controls_block.tex", ///
ctitles("Unmatched" "Matched") replace vce(robust) fe(ant_block_id) starlevels(* 0.10 ** 0.05 *** 0.01)

	*	All balance test variables (in Excel)
	
	balancetable (mean if ant_match==0) (mean if ant_match==1) total_hhd total_hhd_having_piped_water_con percent_hhd_piped_water DistrictHeadQuarterDistance NearestStatutoryTownDistance TotalGeographicalAreainHect TotalPopulationofVillage TotalScheduledCastesPopulatio PropSCPop GovtPrimarySchoolNumbers PrimaryHeallthSubCentreNumb TapWaterUntreated_bin AllWeatherRoad_bin using "$gates_db/Output/Regression results/Balance_Test_NalJal_2.xlsx", ///
ctitles("Unmatched" "Matched") vce(robust) fe(UGP) starlevels(* 0.10 ** 0.05 *** 0.01) varlabels nonumbers sheet("Antyodaya_UGP") replace

			*----------------------------------------------------------------------------------*
*	2.3	Wards in SEC: Matched versus Unmatched
*----------------------------------------------------------------------------------*
	
	use "$gates_db/Output/sec_ant_final_match_full", clear
	
	tab sec_merge
	
		//	GP-level match
		
	tab UGP if sec_merge==2
	
	drop if sec_merge==2
	
	count
	
		//	103,878
		
	drop vil_matched vil_matched_2 vil_merge
	
	count if WardNo==-777
	
	drop if WardNo==-777
	
	count
	
		//	103,872
	
	gen sec_ant_vil_matched = 0
	
	replace sec_ant_vil_matched = 1 if Antyodaya_VillageName_1!="" | Antyodaya_VillageName_2 != "" | Antyodaya_VillageName_3 != "" | Antyodaya_VillageName_4 != ""
	
	tab sec_ant_vil_matched
	
	/*
	
sec_ant_vil |
   _matched |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |     15,055       14.49       14.49
          1 |     88,817       85.51      100.00
------------+-----------------------------------
      Total |    103,872      100.00

	  */
	
	label var sec_ant_vil_matched "SEC-Antyodaya final match"
		
	duplicates tag UGP WardNo, gen(dup_ward)
	
	tab dup_ward
	
		//	12 obs have a duplicate each
		
	duplicates drop UGP WardNo, force
	
	drop dup_ward
		
	save "$gates_db/Intermediate/sec_gp_matched", replace
	
*----------------------------------------------------------------------------------*
*	2.4	Open ward-level control datasets
*----------------------------------------------------------------------------------*
	
	*	Look at ward winners clean data
	
	use "$gates_db/Input/Controls/Ward Winners Clean.dta", clear
	
	count
	
		//	90,791
		
	isid UGP WardNo
	
	codebook, compact
	
	gen wm_edu_illtrt = EduDum4
	
	tab wm_edu_illtrt, mi
	
	gen wm_edu_ltrt = EduDum6
	
	tab wm_edu_ltrt, mi
	
	save "$gates_db/Intermediate/Ward Winners Clean_balance.dta", replace
	
	*	Look at ward population data
	
	use "$gates_db/Input/Controls/WardPopulations.dta", clear
	
	count
	
		//	100,456
		
	count if WardNo==.
	
		//	3
		
	drop if WardNo==.
	
	codebook, compact
	
	count if pop_total==0
	
		//	32
		
	drop if pop_total==0
	
	summ pop_total
	
		//	807.9473 is the mean
		
	gen st_share = pop_st/pop_total
	
	summ st_share
	
		//	only 79,559 obs
	
	save "$gates_db/Intermediate/WardPopulations_blnce.dta", replace
	
*----------------------------------------------------------------------------------*
*	2.5	Merge with ward-level control dataset 
*----------------------------------------------------------------------------------*
	
		*	1.	Balance table from ward winner data
	
	use "$gates_db/Intermediate/sec_gp_matched", clear
	
	merge 1:1 UGP WardNo using "$gates_db/Intermediate/Ward Winners Clean_balance.dta", gen(ward_win_merg)
	
	/*
	Result                      Number of obs
    -----------------------------------------
    Not matched                        28,471
        from master                    20,773  (ward_win_merg==1)
        from using                      7,698  (ward_win_merg==2)

    Matched                            83,093  (ward_win_merg==3)
    -----------------------------------------
	*/
	
	tab ward_win_merg if sec_ant_vil_matched==0
	
		//	Master: 20%; matched: 79.6%
	
	tab ward_win_merg if sec_ant_vil_matched==1
	
		//	Master: 19.93%; matched: 80%
	
	keep if ward_win_merg == 3 | ward_win_merg == 1
	
	count
	
		//	103,866
		
	tab wm_edu_illtrt
		
	local balance_vars_win "sc_reserved_2016 st_reserved_2016 obc_reserved_2016 women_2016 MoVProp wm_edu_illtrt wm_edu_ltrt SCWard"
	
	balancetable (mean if sec_ant_vil_matched==0) (mean if sec_ant_vil_matched==1) `balance_vars_win' using "$gates_db/Output/Regression results/BalanceSEC_UGP.tex", ///
ctitles("Unmatched" "Matched") replace vce(robust) fe(UGP) starlevels(* 0.10 ** 0.05 *** 0.01)

	balancetable (mean if sec_ant_vil_matched==0) (mean if sec_ant_vil_matched==1) `balance_vars_win' using "$gates_db/Output/Regression results/BalanceSEC_block.tex", ///
ctitles("Unmatched" "Matched") replace vce(robust) fe(block_id) starlevels(* 0.10 ** 0.05 *** 0.01)


		*	2.	Balance table from ward population data
		
	merge 1:1 UGP WardNo using "$gates_db/Intermediate/WardPopulations_blnce.dta", gen(ward_pop_merge)
	
	/*
	
	Result                      Number of obs
    -----------------------------------------
    Not matched                        13,315
        from master                     8,380  (ward_pop_merge==1)
        from using                      4,935  (ward_pop_merge==2)

    Matched                            95,486  (ward_pop_merge==3)
    -----------------------------------------

	*/
	
	tab ward_pop_merge if sec_ant_vil_matched==0
	
		//	8.7% master; 91.3% match
		
	tab ward_pop_merge if sec_ant_vil_matched==1
	
		//	7.96% master; 92.04% match
	
	keep if ward_pop_merge == 3 | ward_pop_merge == 1
	
	count
	
label var pop_total "Population"
label var sc_share "Proportion of SC in population"
label var st_share "Proportion of ST in population"
label var sc_reserved_2016 "Ward SC reserved (2016)"
label var st_reserved_2016 "Ward ST reserved (2016)"
label var obc_reserved_2016 "Ward OBC reserved (2016)"
label var women_2016 "Ward female reserved (2016)"
label var MoVProp "Margin of victory proportion"
label var wm_edu_illtrt "Education status: Illiterate"
label var wm_edu_ltrt "Education status: Literate"
label var SCWard "SC ward member"

	local balance_vars_pop "pop_total sc_share st_share"
	
	balancetable (mean if sec_ant_vil_matched==0) (mean if sec_ant_vil_matched==1) `balance_vars_pop' using "$gates_db/Output/Regression results/BalanceSEC_UGP_pop.tex", ///
ctitles("Unmatched" "Matched") replace vce(robust) fe(UGP) starlevels(* 0.10 ** 0.05 *** 0.01)

	balancetable (mean if sec_ant_vil_matched==0) (mean if sec_ant_vil_matched==1) `balance_vars_pop' using "$gates_db/Output/Regression results/BalanceSEC_block_pop.tex", ///
ctitles("Unmatched" "Matched") replace vce(robust) fe(block_id) starlevels(* 0.10 ** 0.05 *** 0.01)

	*	3.	All balance variables
	
	local balance_vars_pop "pop_total sc_share st_share"
	
	local balance_vars_win "sc_reserved_2016 st_reserved_2016 obc_reserved_2016 women_2016 MoVProp wm_edu_illtrt wm_edu_ltrt SCWard"
	
	balancetable (mean if sec_ant_vil_matched==0) (mean if sec_ant_vil_matched==1) `balance_vars_pop' `balance_vars_win' using "$gates_db/Output/Regression results/BalanceSEC_UGP_pop.tex", ///
ctitles("Unmatched" "Matched") replace vce(robust) fe(UGP) starlevels(* 0.10 ** 0.05 *** 0.01)

balancetable (mean if sec_ant_vil_matched==0) (mean if sec_ant_vil_matched==1) `balance_vars_win' using "$gates_db/Output/Regression results/Balance_Test_NalJal_3.xlsx", ///
sheet("SEC_UGP") ctitles("Unmatched" "Matched") replace vce(robust) fe(UGP) starlevels(* 0.10 ** 0.05 *** 0.01) varlabels nonumbers
