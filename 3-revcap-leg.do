/**********************************************************************************************/
* TAXIPP 0.3 3-revcap.do                                                                       *
*                                                                                              *
* Simulation des prélèvements sur les revenus du capital (revenus fonciers et financiers)      *
*                                                                                              *
*  02/2012                                                                                     *
/**********************************************************************************************/

* Variables nécessaires  (pour la partie 2 pour le moment): 

global varinput "rfon_imp_foy rfin_int_bar_irpp_foy rfin_div_bar_irpp_foy rfin_av_imp_foy rfin_pv_irpp_foy pac id_foyf rfin_int_pel_dec rfin_div_pea_dec rfin_int_pl_irpp_foy rfin_div_pl_irpp_foy rfin_av_pl_irpp_foy"

* Calculer les revenus bruts (notion CSG) et les revenus nets (après CSG et CRDS)

***********************************
/* 1. Calcul de la taxe foncière */
***********************************

/* 1.1. Imputation proportionnelle de la taxe foncière */
*********************************************************
egen masse_loyer_fictif_sim=total(loyer_fictif*pondv/1000000000)
egen masse_loyer_reel_sim=total(loyer_verse*bail_pers_phys_men*pondv/1000000000)
gen masse_loyer_sim=masse_loyer_fictif_sim+masse_loyer_reel_sim

gen masse_tf_fictif=${masse_tf_cn}*(masse_loyer_fictif_sim+0.5*(${masse_loyer_brut_cn}-masse_loyer_sim))/${masse_loyer_brut_cn}
gen masse_tf_reel=${masse_tf_cn}*(masse_loyer_reel_sim+0.5*(${masse_loyer_brut_cn}-masse_loyer_sim))/${masse_loyer_brut_cn}

gen tf_fictif_foy=rfon_fictif_cn_foy*masse_tf_fictif/masse_rfon_fictif
gen tf_reel_foy=rfon_reel_cn_foy*masse_tf_reel/masse_rfon_reel
gen tf_foy=tf_fictif_foy+tf_reel_foy

/* 1.2. Application de l'exonération et du dégrèvement de la taxe foncière */
*****************************************************************************

/* Calcul de l'âge du déclarant principal */
gen age_decl=age
replace age_decl=age_conj if conj==1
gen exo_tf=0
replace exo_tf=1 if (age_decl>=${age_min_exo_tf} & rfr_irpp_foy<${seuil_exo_tf_th}+2*(nbp-1)*${seuil_exo_tf_th_demipart})

/* Dégrèvement de la TF mis en place à partir de 2012 (en guise de remplacement du bouclier fiscal) */
if ${annee}==2012 {
  replace tf_fictif_foy=min(tf_fictif_foy,${tx_plaf_tf}*rfr_irpp_foy) if rfr_irpp_foy<${seuil_plaf_tf}+${seuil_plaf_tf_demipart1}*min(2*(nbp-1),1)+${seuil_plaf_tf_demipartsupp}*2*(max(nbp-1.5,0))
	replace tf_reel_foy=min(tf_reel_foy,${tx_plaf_tf}*rfr_irpp_foy) if rfr_irpp_foy<${seuil_plaf_tf}+${seuil_plaf_tf_demipart1}*min(2*(nbp-1),1)+${seuil_plaf_tf_demipartsupp}*2*(max(nbp-1.5,0))
	}

/* On applique en dernier l'exonération */
replace tf_fictif_foy=0 if exo_tf==1
replace tf_reel_foy=0 if exo_tf==1
replace tf_foy=0 if exo_tf==1

/* Calage final pour recoller avec la comptabilité nationale malgré l'application de l'exonération et du dégrèvement */
*egen masse_tf_fictif_sim=total(tf_fictif_foy*decl*pondv/1000000000)
*egen masse_tf_reel_sim=total(tf_reel_foy*decl*pondv/1000000000)
*replace tf_fictif_foy=tf_fictif_foy*masse_tf_fictif/masse_tf_fictif_sim
*replace tf_reel_foy=tf_reel_foy*masse_tf_reel/masse_tf_reel_sim
*replace tf_foy=tf_fictif_foy+tf_reel_foy

*drop loyer_fictif loyer_verse bail_pers_phys_men

*****************************************************************
/* 2: Revenus financiers (intérêts, dividendes, assurance-vie) */
*****************************************************************

		/* 2.1. Imputation de la CSG-CRDS, des contributions sociales et du PL */
		************************************************************************

/* CSG, CRDS et contributions sociales additionnelles sur revenus du patrimoine */

gen rev_patr_csg_foy     = max(rfon_imp_foy,0)+rfin_int_bar_irpp_foy+rfin_div_bar_irpp_foy+rfin_av_imp_foy+rfin_pv_irpp_foy
replace rev_patr_csg_foy = 0 if pac==1
gen csg_patr_foy  = ${tx_csg_rk_patr}*rev_patr_csg_foy
gen crds_patr_foy = ${tx_crds_rk_patr}*rev_patr_csg_foy
gen csk_patr_foy  = (${tx_ps_patr}+${tx_caps_patr}+${tx_caps_rsa})*rev_patr_csg_foy

/* CSG, CRDS et contributions sociales additionnelles sur produits de placement */

* Préliminaire : création des variables au niveau foyer (elles n'existent qu'au niveau individuel dans la base de données initiale)
bys id_foyf : egen rfin_int_pel_dec_foy = total(rfin_int_pel)
bys id_foyf : egen rfin_div_pea_dec_foy = total(rfin_div_pea)

gen rev_plac_csg_foy     = rfin_int_pel_foy+rfin_int_pl_irpp_foy+rfin_div_pea_foy+rfin_div_pl_irpp_foy+rfin_av_pl_irpp_foy
*rfin_av_residu_foy (ce terme n'a pas d'existence tant qu'on ne cale pas)
* Vérifiez l'effet du calage CSG dans les versions précédentes; caler dans le set-up source.
replace rev_plac_csg_foy = 0 if pac==1
gen csg_plac_foy         = ${tx_csg_rk_plac}*rev_plac_csg_foy
gen crds_plac_foy        = ${tx_crds_rk_plac}*rev_plac_csg_foy
gen csk_plac_foy         = (${tx_ps_plac}+${tx_caps_plac}+${tx_caps_rsa})*rev_plac_csg_foy

/* Variables agrégées */
gen yk_csg_foy  = rev_patr_csg_foy + rev_plac_csg_foy
gen csg_yk_foy  = csg_patr_foy + csg_plac_foy
gen crds_yk_foy = crds_patr_foy + crds_plac_foy
gen csk_foy     = csk_patr_foy + csk_plac_foy

/* Pour les revenus de 2010, on calcule csk avec l'ancien taux de prélèvement social à 2% (au lieu de 2,2%) pour le calcul du bouclier de 2011 */
gen csk_patr_foy_bouclier=0
gen csk_foy_bouclier=0
if  ${annee_sim}==2010 {
replace csk_patr_foy_bouclier=((${tx_ps_patr}-0.002)+${tx_caps_patr}+${tx_caps_rsa})*rev_patr_csg_foy
replace csk_foy_bouclier=csk_patr_foy_bouclier+csk_plac_foy
}
/* Prélèvement libératoire */
* Note : A partir de 2012, une partie des revenus du PL est réintégrée dans le barème de l'IR
if ${annee_sim} <= 2011 {
gen pl_foy=${tx_pl_int}*rfin_int_pl_irpp_foy+${tx_pl_div}*rfin_div_pl_irpp_foy+${tx_pl_av}*rfin_av_pl_irpp_foy
gen rfin_pl_foy =rfin_int_pl_irpp_foy+rfin_div_pl_irpp_foy+rfin_av_pl_irpp_foy
}
if ${annee_sim} >2011 {
gen pl_foy=${tx_pl_int}*rfin_int_pl_foy*cond(rfin_int_pl_foy >=2000,1,0)+${tx_pl_av}*rfin_av_pl_irpp_foy
gen rfin_pl_foy =rfin_int_pl_foy*cond(rfin_int_pl_foy >=2000,1,0)+rfin_av_pl_irpp_foy
}
foreach var of varlist pl_foy rfin_pl_foy {
replace `var'=0 if pac==1
}

/* 2.2. Calcul de l'impôt sur les sociétés */
*********************************************
drop is_foy
gen is_foy=(rfin_int_cn_foy-rfin_int_livret_foy-rfin_int_pel_foy+rfin_div_cn_foy+rfin_av_cn_foy+rfin_nondist_cn_foy)*$masse_is_cn/($masse_rfin_int_cn-$masse_rfin_int_livret-$masse_rfin_int_pel+$masse_rfin_div_cn+$masse_rfin_av_cn+$masse_profit_nondist_cn)
drop is_distr_foy
gen is_distr_foy=(rfin_int_cn_foy-rfin_int_livret_foy-rfin_int_pel_foy+rfin_div_cn_foy+rfin_av_cn_foy)*$masse_is_cn/($masse_rfin_int_cn-$masse_rfin_int_livret-$masse_rfin_int_pel+$masse_rfin_div_cn+$masse_rfin_av_cn)
replace is_foy=0 if is_foy < 0.1   


/* 3. Création des variables catégorielles imposables  */

	* Revenus du capital
gen yk_irpp = rfon_irpp + rfin_irpp
gen y_irpp = ya_irpp + yr_irpp + yk_irpp

bys id_foyf : egen yk_irpp_foy = total(yk_irpp)
gen yk_irpp_conj = 0
replace yk_irpp = yk_irpp_foy/(1+marie) if pac~=1
replace yk_irpp_conj = yk_irpp_foy - yk_irpp if pac~=1

	* Revenu agrégé
gen y_irpp_conj = ya_irpp_conj + yr_irpp_conj + yk_irpp_conj
gen y_irpp_foy = ya_irpp_foy + yr_irpp_foy + yk_irpp_foy



/* 4. Calcul de la Taxe d'habitation (TH) */

	* Règle d'exonération de la TH
gen exo_th=0
replace exo_th=1 if rfr_irpp_foy_N2 < ${seuil_exo_tf_th}+2*(nbp-1)*${seuil_exo_tf_th_demipart}

	* Calcul de la TH au niveau foyer fiscal
egen masse_loyer_conso=total(loyer_conso*(1+marie)*decl*(1-exo_th)*pondv/1000000000)
gen th_foy=loyer_conso*(1+marie)*${masse_th_cn}/masse_loyer_conso if exo_th==0
replace th_foy=0 if exo_th==1

/* Calage des résultats */
*gen th_foy_avt_cal=th_foy
*egen masse_th_sim=total(th_foy*decl*pondv/1000000000)
*replace th_foy=th_foy*${masse_th_cn}/masse_th_sim

/* Répartition de la TH entre les différentes catégories de revenus */
/*gen y_irpp_foy_ajust=y_irpp_foy
replace y_irpp_foy_ajust=0.01 if y_irpp_foy==0
gen th_foy_trav  = th_foy*(ya_irpp_foy)/(y_irpp_foy_ajust)
gen th_foy_cap   = th_foy*(yk_irpp_foy)/(y_irpp_foy_ajust)
gen th_foy_remp  = th_foy*(yr_irpp_foy)/(y_irpp_foy_ajust)
*/

	* Individualisation de la TH

gen th=th_foy*y_irpp/y_irpp_foy if y_irpp_foy~=0
replace th=0 if y_irpp_foy==0

/* Répartition entre les différentes catégories de revenus */
/*gen y_irpp_ajust=y_irpp
replace y_irpp_ajust = 0.01 if y_irpp==0
gen th_trav = th*ya_irpp/(y_irpp_ajust)
gen th_cap  = th*yk_irpp/(y_irpp_ajust)
gen th_remp = th*yr_irpp/(y_irpp_ajust)
*/

/* Création des labels */
*do "$taxipp\Programmes\Labels\label taxe_hab 0_1.do"

sort id_indiv id_foyf
*drop masse_loyer_conso

/
