/**********************************************************************************************/
* TAXIPP 0.3 11autres_impots0_3.do                                                             *
*                                                                                              *
* Simulation des autres impôts:                                                                *
*      - 1. DMTG                                                                               *
*      - 2. TVA et TP, incidence facteurs                                                      *
*      - 3. Revenus disponibles                                                                *
*      - 4. TVA et TP, incidence consommation                                                  *
*      - 5. Revenus primaires et secondaires                                                   *
*                                                                                              *
* Brice Fabre et Antoine Bozio 10/2012                                                         *
/**********************************************************************************************/


******************************************************************
/* 1. Simulation des droits de donations et successions (DMTG)  */
******************************************************************
  
	cap gen pondvr=round(100*pondv)
	cumul k_cn [w=pondvr], gen(pk)
	replace pk=100*pk
	egen seuil_topk=max(k_cn*cond(pk<95,1,0))
	egen masse_topk=total((k_cn-seuil_topk)*cond(pk>95,1,0)*pondv/1000000000)
	gen dmtg=0
	replace dmtg=(k_cn-seuil_topk)*${masse_dmtg_cn}/masse_topk if pk>95
	gen dmtg_foy=dmtg*(1+marie)
	

*************************************************************************************************************************
/* 2. Simulation des taxes indirectes (TVA, tabac, etc.) et TP: part incidence facteurs (calculs au niveau individuel) */
*************************************************************************************************************************


	gen ya_cn_priv = ya_cn
	replace ya_cn_priv = 0 if public==1

	egen masse_ya_cn_priv = total(ya_cn_priv*pondv/1000000000)
	egen masse_rfin_dist_cn = total(rfin_dist_cn_foy*decl*pondv/1000000000)

	gen ratio_yk_profits=($masse_profit_dist_cn+$masse_is_cn)/masse_rfin_dist_cn
	
	* Répartition des taxes indirectes sur le prix des facteurs
	gen taxes_conso_fact_trav = ya_cn_priv*(1-$alpha_tva)*$masse_tva_cn/(masse_ya_cn_priv+${masse_profit_dist_cn}+${masse_is_cn})
	gen taxes_conso_fact_cap  = ratio_yk_profits*(rfin_dist_cn_foy/(1+marie))*(1-$alpha_tva)*$masse_tva_cn/(masse_ya_cn_priv+${masse_profit_dist_cn}+${masse_is_cn})
	gen taxes_conso_fact      = taxes_conso_fact_trav + taxes_conso_fact_cap

	* Répartition de la TP sur le prix des facteurs
	gen tp_fact_trav = ya_cn_priv*(1-$alpha_tp)*$masse_tp_cn/(masse_ya_cn_priv+$masse_profit_dist_cn+$masse_is_cn)
	gen tp_fact_cap = ratio_yk_profits*(rfin_dist_cn_foy/(1+marie))*(1-$alpha_tp)*$masse_tp_cn/(masse_ya_cn_priv+$masse_profit_dist_cn+$masse_is_cn)
	gen tp_fact = tp_fact_trav + tp_fact_cap

	* Revenus primaires des facteurs (au coût des facteurs)
	gen ya_cn_fact = ya_cn + taxes_conso_fact_trav + tp_fact_trav
	gen yk_cn_fact = yk_cn + taxes_conso_fact_cap + tp_fact_cap
	gen y_cn_fact = ya_cn_fact + yk_cn_fact
	
	* On vérifie que l'on simule bien toute la masse des taxes impactant les prix des facteurs
	egen masse_taxes_conso_fact_sim=total(taxes_conso_fact*pondv/1000000000)
	gen ratio_taxes_conso_fact=masse_taxes_conso_fact_sim/((1-$alpha_tva)*$masse_tva_cn)
	egen masse_tp_fact_sim=total(tp_fact*pondv/1000000000)
	gen ratio_tp_fact=masse_tp_fact_sim/((1-$alpha_tp)*$masse_tp_cn)


*****************************
/* 3. Revenus disponibles  */
*****************************
	
	* Définitions de variables au niveau du foyer fiscal
	foreach var of varlist taxes_conso_fact_trav taxes_conso_fact_cap tp_fact_trav tp_fact_cap taxes_conso_fact tp_fact ya_cn_fact yk_cn_fact y_cn_fact loyer_verse loyer_fictif {
	bys id_foyf: egen `var'_foy = total(`var')
	}
	
	* Au niveau individuel
	gen ya_disp = ya_cn_fact - cs_cn - tsmo_cn - csg_ya - irpp_sal - taxe_HR_trav - irpp_nonsal - th_trav - taxes_conso_fact_trav - tp_fact_trav - taxe_75
	gen yk_disp = yk_cn_fact - irpp_rfon - irpp_rfin - irpp_pv - taxe_HR_cap - (csg_yk_foy + crds_yk_foy + csk_foy + pl_foy + is_distr_foy + tf_foy + rfin_nondist_cn_foy)/(1+marie) + bouclier_reel - isf - th_cap - taxes_conso_fact_cap - tp_fact_cap
	gen yr_disp = yr_brut - csg_yr - irpp_chom - irpp_pens - taxe_HR_remp - th_remp
	gen yp_disp = (pens_alim_rec_foy - pens_alim_ver_foy)/(1+marie) - irpp_alim
	gen yt_disp = transf - crds_transf
	gen y_disp = ya_disp + yk_disp + yr_disp + yt_disp
	
	* Au niveau foyer fiscal
	gen ya_disp_foy = ya_cn_fact_foy - cs_cn_foy - tsmo_cn_foy - csg_ya_foy - irpp_sal_foy - irpp_nonsal_foy - taxe_HR_foy_trav - th_foy_trav - taxes_conso_fact_trav_foy - tp_fact_trav_foy - taxe_75_foy
	gen yk_disp_foy = yk_cn_fact_foy - irpp_rfon_foy - irpp_rfin_foy - irpp_pv_foy - taxe_HR_foy_cap - (csg_yk_foy + crds_yk_foy + csk_foy + pl_foy + is_distr_foy + tf_foy + rfin_nondist_cn_foy) + bouclier_foy_reel - isf_foy - th_foy_cap - taxes_conso_fact_cap_foy - tp_fact_cap_foy
	gen yr_disp_foy = yr_brut_foy - csg_yr_foy - irpp_chom_foy - irpp_pens_foy - taxe_HR_foy_remp - th_foy_remp
	gen yp_disp_foy = pens_alim_rec_foy - pens_alim_ver_foy - irpp_alim_foy
	gen yt_disp_foy = (transf - crds_transf)*(1 + marie)
	gen y_disp_foy = ya_disp_foy + yk_disp_foy + yr_disp_foy + yt_disp_foy 

	* Masses agrégées
	egen masse_y_disp     = total(y_disp*pondv/1000000000)
	egen masse_y_disp_foy = total(y_disp_foy*decl*pondv/1000000000)
	
	
******************************************************************************************
/* 4. Imputation des taxes indirectes (TVA, TIPP etc.) et TP, incidence prix à la conso */
******************************************************************************************

*******************************
/* 4.1 Au niveau individuel  */
*******************************


	/* 4.1.1. Estimation de l'épargne et de la consommation */
	********************************************************

	cumul y_disp [aw=pondv], gen(py)

	* Calage 1 sur les masses d'épargne agrégées
	gen epargne            = $landa_epargne*py*y_disp
	egen seuil_topydisp    = max(y_disp*cond(py<0.95,1,0))
	replace epargne        = epargne + $landa_epargne*py*(y_disp-seuil_topydisp) if py>0.95 & py~=.
	egen masse_epargne_sim = total(epargne*pondv/1000000000)
	replace epargne        = epargne + y_disp*($masse_epargne_men_cn-masse_epargne_sim)/masse_y_disp

	* Ajustement pour consommation <0
	gen loyer     = (loyer_verse + loyer_fictif)
	gen conso     = y_disp - epargne - loyer
	replace epargne = epargne + conso if conso <0
	replace conso = 0 if conso <0

	* Calage 2 sur les masses d'épargne agrégées
	egen masse_epargne_sim2 = total(epargne*pondv/1000000000)
	egen masse_conso_sim    = total(conso*pondv/1000000000)
	replace epargne = epargne + conso*($masse_epargne_men_cn-masse_epargne_sim2)/masse_conso_sim
	replace conso   = max(y_disp - epargne - loyer,0)


	/* 4.1.2. Calcul des taxes sur la consommation et de la TP payés sur la conso */
	*****************************************************************************

	/* 4.1.2.1. Simulation des taxes à la consommation */

	* Décile de consommation par UC
	xtile deciles_conso = conso [w=pondv], nq(10)

	* Catégories de ménage
	gen cat_menage=5
	replace cat_menage=1 if couple==0 & nenf-nenfnaiss+nenfmaj==0
	replace cat_menage=2 if couple==0 & nenf-nenfnaiss+nenfmaj>0
	replace cat_menage=3 if couple==1 & nenf-nenfnaiss+nenfmaj==0
	replace cat_menage=4 if couple==1 & nenf-nenfnaiss+nenfmaj>0

	* Taux d'effort
	gen taux_effort_tva      =0
	gen taux_effort_boissons =0
	gen taux_effort_tabac    =0
	gen taux_effort_tipp     =0
	gen taux_effort_assur    =0

	forvalues i=1/5 {
	forvalues j=1/10 {
	foreach var of varlist taux_effort_tva taux_effort_boissons taux_effort_tabac taux_effort_tipp taux_effort_assur {
	qui replace `var'=${`var'`i'_`j'} if cat_menage==`i' & deciles_conso==`j'
	}
	}
	}
	
	* Masse de consommation
	egen masse_conso=total(conso*pondv/1000000000)

	* Taxes indirectes 
	gen tva_conso           = conso*$alpha_tva*taux_effort_tva
	gen taxe_boissons_conso = conso*$alpha_tva*taux_effort_boissons
	gen taxe_tabac_conso    = conso*$alpha_tva*taux_effort_tabac
	gen tipp_conso          = conso*$alpha_tva*taux_effort_tipp
	gen taxe_assur_conso    = conso*$alpha_tva*taux_effort_assur

	* Calage sur masses
	
	egen masse_taxes_conso_sim = total((tva_conso + taxe_boissons_conso + taxe_tabac_conso + tipp_conso + taxe_assur_conso)*pondv/1000000000)
	
	foreach var of varlist tva_conso taxe_boissons_conso taxe_tabac_conso tipp_conso taxe_assur_conso {
	replace `var'=`var'*$alpha_tva*$masse_tva_cn/masse_taxes_conso_sim
	}
	
	* On vérifie qu'on simule bien toute la masse
	egen masse_taxes_conso_cal_sim = total((tva_conso + taxe_boissons_conso + taxe_tabac_conso + tipp_conso + taxe_assur_conso)*pondv/1000000000)
	gen ratio_taxes_conso=masse_taxes_conso_cal_sim/($alpha_tva*$masse_tva_cn)
	
	/* 4.1.2.2. Simulation de la taxe professionnelle */

	gen tp_conso = conso*$alpha_tp*$masse_tp_cn/masse_conso
	
	* On vérifie qu'on simule bien toute la masse
	egen masse_tp_conso_cal_sim = total(tp_conso*pondv/1000000000)
	gen ratio_tp_conso=masse_tp_conso_cal_sim/($alpha_tp*$masse_tp_cn)

	
	
*********************************
/* 4.2 Au niveau foyer fiscal  */
*********************************

	/* 4.2.1. Estimation de l'épargne et de la consommation */
	********************************************************
    
	drop py
	cumul y_disp_foy [aw=pondv] if decl==1, gen(py)

	* Calage 1 sur les masses d'épargne agrégées
	gen epargne_foy                = $landa_epargne*py*y_disp_foy
	egen seuil_topydisp_foy        = max(y_disp_foy*cond(py<0.95,1,0))
	replace epargne_foy            = epargne_foy + $landa_epargne*py*(y_disp_foy-seuil_topydisp_foy) if py>0.95 & py~=.
	egen masse_epargne_foy_sim     = total(epargne_foy*decl*pondv/1000000000)
	replace epargne_foy            = epargne_foy + y_disp_foy*($masse_epargne_men_cn-masse_epargne_foy_sim)/masse_y_disp_foy 

	* Ajustement pour consommation <0
	gen loyer_foy       = (loyer_verse + loyer_fictif)*(1+marie) if decl==1 
	gen conso_foy       = y_disp_foy - epargne_foy - loyer_foy
	replace epargne_foy = epargne_foy + conso_foy if conso_foy <0
	replace conso_foy   = 0 if conso_foy <0

	* Calage 2 sur les masses d'épargne agrégées
	egen masse_epargne_foy_sim2 = total(epargne_foy*decl*pondv/1000000000)
	egen masse_conso_foy_sim    = total(conso_foy*decl*pondv/1000000000)
	replace epargne_foy = epargne_foy + conso_foy*($masse_epargne_men_cn-masse_epargne_foy_sim2)/masse_conso_foy_sim
	replace conso_foy   = max(y_disp_foy - epargne_foy - loyer_foy,0)


	/* 4.2.2. Calcul des taxes sur la consommation et de la TP payés sur la conso */
	*****************************************************************************

	/* 4.2.2.1. Simulation des taxes à la consommation */

	* Consommation du foyer (fiscal) par unité de consommation (du foyer fiscal)
	gen uc = 1 + 0.5*(marie + nenf1415 + nenf1617 + nenfmaj) + 0.3*(nenf02 + nenf35 + nenf610 + nenf1113)
	gen conso_foy_uc = conso_foy/uc if decl==1
	gen epargne_foy_uc = epargne_foy/uc if decl==1

	* Décile de consommation par UC
	xtile deciles_conso_uc = conso_foy_uc [w=pondv] if decl==1, nq(10)

	* Attribution des taux d'effort
	forvalues i=1/5 {
	forvalues j=1/10 {
	foreach var of varlist taux_effort_tva taux_effort_boissons taux_effort_tabac taux_effort_tipp taux_effort_assur {
	qui replace `var'=${`var'`i'_`j'} if cat_menage==`i' & deciles_conso_uc==`j'
	}
	}
	}
	
	* Masse de consommation
	egen masse_conso_foy=total(conso_foy*decl*pondv/1000000000)

	* Taxes indirectes (au niveau du foyer social)
	gen tva_conso_foy           = conso_foy*$alpha_tva*taux_effort_tva
	gen taxe_boissons_conso_foy = conso_foy*$alpha_tva*taux_effort_boissons
	gen taxe_tabac_conso_foy    = conso_foy*$alpha_tva*taux_effort_tabac
	gen tipp_conso_foy          = conso_foy*$alpha_tva*taux_effort_tipp
	gen taxe_assur_conso_foy    = conso_foy*$alpha_tva*taux_effort_assur

	* Calage sur masses
	
	egen masse_taxes_conso_foy_sim = total((tva_conso_foy + taxe_boissons_conso_foy + taxe_tabac_conso_foy + tipp_conso_foy + taxe_assur_conso_foy)*decl*pondv/1000000000)
	
	foreach var of varlist tva_conso_foy taxe_boissons_conso_foy taxe_tabac_conso_foy tipp_conso_foy taxe_assur_conso_foy {
	replace `var'=`var'*$alpha_tva*$masse_tva_cn/masse_taxes_conso_foy_sim
	}
	
	* On vérifie qu'on simule bien toute la masse
	egen masse_taxes_conso_foy_cal_sim = total((tva_conso_foy + taxe_boissons_conso_foy + taxe_tabac_conso_foy + tipp_conso_foy + taxe_assur_conso_foy)*decl*pondv/1000000000)
	gen ratio_taxes_conso_foy=masse_taxes_conso_foy_cal_sim/($alpha_tva*$masse_tva_cn)
	
	/* 4.2.2.2. Simulation de la taxe professionnelle */

	gen tp_conso_foy = conso_foy*$alpha_tp*$masse_tp_cn/masse_conso_foy
	
	* On vérifie qu'on simule bien toute la masse
	egen masse_tp_conso_foy_cal_sim = total(tp_conso_foy*decl*pondv/1000000000)
	gen ratio_tp_conso_foy=masse_tp_conso_foy_cal_sim/($alpha_tp*$masse_tp_cn)


******************************************
/* 5. Revenus primaires et secondaires  */
******************************************

******************************************************************
/* 5.1 Attribution aux facteurs de TVA et TP payés sur la conso */
******************************************************************
	
	replace y_disp=0.0001 if y_disp==0
	replace y_disp_foy=0.0001 if y_disp_foy==0

	
	foreach var of varlist tva_conso taxe_boissons_conso taxe_tabac_conso tipp_conso taxe_assur_conso tp_conso {
	gen `var'_trav = `var'*ya_disp/y_disp
	gen `var'_cap = `var'*yk_disp/y_disp 
	gen `var'_remp = `var'*yr_disp/y_disp 
	gen `var'_tran = `var'*yt_disp/y_disp 
	} 
	
	foreach var of varlist tva_conso_foy taxe_boissons_conso_foy taxe_tabac_conso_foy tipp_conso_foy taxe_assur_conso_foy tp_conso_foy {
	gen `var'_trav = `var'*ya_disp_foy/y_disp_foy 
	gen `var'_cap = `var'*yk_disp_foy/y_disp_foy 
	gen `var'_remp = `var'*yr_disp_foy/y_disp_foy 
	gen `var'_tran = `var'*yt_disp_foy/y_disp_foy 
	} 
	
	foreach typ in trav cap remp tran {
	gen taxes_conso_`typ' = tva_conso_`typ' + taxe_boissons_conso_`typ' + taxe_tabac_conso_`typ' + tipp_conso_`typ' + taxe_assur_conso_`typ'
	}
	
	foreach typ in trav cap remp tran {
	gen taxes_conso_`typ'_foy = tva_conso_foy_`typ' + taxe_boissons_conso_foy_`typ' + taxe_tabac_conso_foy_`typ' + tipp_conso_foy_`typ' + taxe_assur_conso_foy_`typ'
	}
	
	* Revenus financiers non distribués
	replace y_disp     = y_disp     + rfin_nondist_cn_foy/(1+marie)
	replace y_disp_foy = y_disp_foy + rfin_nondist_cn_foy
	

***********************************************************************************************************
/* 5.2 Calcul des revenus primaires, des impôts totaux sur revenus primaires, et des revenus secondaires */
***********************************************************************************************************	

    /* 5.2.1. Revenus primaires */
	******************************
	
	* Au niveau individuel
	gen ya_prim = ya_cn_fact + taxes_conso_trav + tp_conso_trav
	gen yk_prim = yk_cn_fact + taxes_conso_cap + tp_conso_cap
	gen y_prim  = ya_prim + yk_prim               
	
	gen yr_prim = yr_brut + taxes_conso_remp + tp_conso_remp
	gen yt_prim = transf + taxes_conso_tran + tp_conso_tran  

	
	* Au niveau foyer fiscal
	gen ya_prim_foy = ya_cn_fact_foy + taxes_conso_trav_foy + tp_conso_foy_trav
	gen yk_prim_foy = yk_cn_fact_foy + taxes_conso_cap_foy + tp_conso_foy_cap
	gen y_prim_foy  = ya_prim_foy + yk_prim_foy        

	gen yr_prim_foy = yr_brut_foy + taxes_conso_remp_foy + tp_conso_foy_remp
	gen yt_prim_foy = transf*(1+marie) + taxes_conso_tran_foy + tp_conso_foy_tran  
	
	
    /* 5.2.2. Impôts totaux */
	**************************

	* Au niveau individuel
	gen impot_trav = cs_cn + tsmo_cn + csg_ya + irpp_sal + irpp_nonsal + taxe_HR_trav + th_trav + taxes_conso_fact_trav + tp_fact_trav + taxes_conso_trav + tp_conso_trav + taxe_75
	gen impot_cap  = irpp_rfon + irpp_rfin + irpp_pv + taxe_HR_cap + (is_foy + tf_foy + csk_foy + csg_yk_foy + crds_yk_foy)/(1+marie) - bouclier_reel + isf + dmtg + th_cap + taxes_conso_fact_cap + tp_fact_cap + tva_conso_cap + tp_conso_cap
	gen impot_prim = impot_trav + impot_cap
		
	gen impot_remp = csg_yr + irpp_chom + irpp_pens + taxe_HR_remp + th_remp + tva_conso_remp + tp_conso_remp
	gen impot_tran = crds_transf + tva_conso_tran + tp_conso_tran
	gen impot      = impot_prim + impot_remp + impot_tran
	
	* Au niveau foyer fiscal
	gen impot_trav_foy = cs_cn_foy + tsmo_cn_foy + csg_ya_foy + irpp_sal_foy + irpp_nonsal_foy + taxe_HR_foy_trav + th_foy_trav + taxes_conso_fact_trav_foy + tp_fact_trav_foy + taxes_conso_trav_foy + tp_conso_foy_trav + taxe_75_foy
	gen impot_cap_foy  = irpp_rfon_foy + irpp_rfin_foy + irpp_pv_foy + taxe_HR_foy_cap + is_foy + tf_foy + csk_foy + csg_yk_foy + crds_yk_foy + isf_foy - bouclier_foy_reel + dmtg_foy + th_foy_cap + taxes_conso_fact_cap_foy + tp_fact_cap_foy + taxes_conso_cap_foy + tp_conso_foy_cap
	gen impot_prim_foy = impot_trav_foy + impot_cap_foy
	
	gen impot_remp_foy = csg_yr_foy + irpp_chom_foy + irpp_pens_foy + taxe_HR_foy_remp + th_foy_remp + taxes_conso_remp_foy + tp_conso_foy_remp
	gen impot_tran_foy = crds_transf*(1+marie) + taxes_conso_tran_foy + tp_conso_foy_tran
	gen impot_foy      = impot_prim_foy + impot_remp_foy + impot_tran_foy
	

	/* 5.2.3. Revenus secondaires */
	********************************
	
	* Au niveau individuel
	egen masse_yr_prim  = total(yr_prim*pondv/1000000000)
	egen masse_cs_contr_cn = total(cs_contr_cn*pondv/1000000000)
	
	gen y_sec  = y_prim - cs_contr_cn + yr_prim*(masse_cs_contr_cn/masse_yr_prim)
	
	* Au niveau foyer fiscal
	
	gen y_sec_foy = y_prim_foy - cs_contr_cn_foy + yr_prim_foy*(masse_cs_contr_cn/masse_yr_prim)
	
	gen taxes_conso1 = taxes_conso_trav + taxes_conso_cap + taxes_conso_fact
	gen taxes_conso2 = taxes_conso_trav + taxes_conso_cap + taxes_conso_remp + taxes_conso_tran + taxes_conso_fact
	egen masse_taxes_conso1 = total(taxes_conso1*pondv/1000000000)	
	egen masse_taxes_conso2 = total(taxes_conso2*pondv/1000000000)	

	
	
	
***************************************	
/* 6. Sauvegarde d'un fichier simulé */
***************************************
/*
gen annee=$annee_sim

/* Sélection des variables à garder */
#delimit;
keep annee id_indiv pondv dmtg* taxes_conso_fact* tp_fact* ya_cn_fact* yk_cn_fact* y_cn_fact* y_disp* ya_disp* yk_disp* yr_disp* yt_disp* yp_disp* conso* epargne* 
tva_conso* taxe_boissons_conso* taxe_tabac_conso* tipp_conso* taxe_assur_conso* tp_conso* taxes_conso_trav* taxes_conso_cap* taxes_conso_remp* taxes_conso_tran*
y_prim* ya_prim* yk_prim* yr_prim* yt_prim* y_sec* impot* ;
#delimit cr

*/

/* Création des labels */
do "$taxipp\Programmes\Labels\label autres_impots 0_1.do"

/* Sauvegarde */
sort id_indiv
*save "$taxipp\Fichiers simules/$annee\indiv_autres_impots_$annee.dta", replace


