/**********************************************************************************************/
* TAXIPP 0.3 10bouclier_fiscal0_3.do                                                           *
*                                                                                              *
* Simulation du bouclier fiscal                                                                *
*                                                                                              *
* Brice Fabre 10/2012                                                                          *
/**********************************************************************************************/

********************************
/* 1. Années avec le bouclier */
********************************

*if $annee>=2005 & $annee<=2010 {

/* 1.1 Détermination des impôts à prendre en compte */
******************************************************

g csg_y_conj=${csg_act}*1/(1-${csg_act_ded})*(sal_irpp_conj+nonsal_irpp_conj) + ${csg_pens}*1/(1-${csg_pens_ded})*(pension_irpp_conj) + ${csg_cho}*1/(1-${csg_cho_ded})*(chom_irpp_conj)
g crds_y_conj=${crds}*1/(1-${csg_act_ded})*(sal_irpp_conj+nonsal_irpp_conj) + ${crds}*1/(1-${csg_pens_ded})*(pension_irpp_conj) + ${crds}*1/(1-${csg_cho_ded})*(chom_irpp_conj)

gen sommeimpots_bouclier     = isf_foy + irpp_net_ppe_foy + tf_foy + th_foy + pl_foy if $annee==2005
replace sommeimpots_bouclier = isf_foy + irpp_net_ppe_foy + tf_foy + th_foy + pl_foy + csg_yk_foy + crds_yk_foy + csk_foy + csg_ya + csg_yr + crds_ya + crds_yr + csg_y_conj + crds_y_conj if $annee>=2006 & $annee<=2009
replace sommeimpots_bouclier = isf_foy + irpp_net_ppe_foy - (irpp_foy_bouclier_trav + irpp_foy_bouclier_cap + irpp_foy_bouclier_remp) + tf_foy + th_foy + pl_foy + csg_yk_foy + crds_yk_foy + csk_foy_bouclier + csg_ya + csg_yr + crds_ya + crds_yr + csg_y_conj + crds_y_conj if $annee==2010


/* 1.2 Détermination des revenus à prendre en compte */
*******************************************************
  		   
gen sommerevenus_bouclier= max(0, rfr_irpp_foy + rfin_int_pl_foy + rfin_div_pl_irpp_foy + rfin_int_livret_foy + rfin_int_pel_csg_foy + (rfin_av_csg_foy-rfin_av_imp_foy) + rfin_div_pea_csg_foy)
replace sommerevenus_bouclier=0.01 if sommerevenus_bouclier==0 

/* 1.3 Calcul du bouclier avec take-up parfait */
*************************************************

/* Calcul au niveau du foyer fiscal */
gen reduc_bouclier_foy = max(0, sommeimpots_bouclier - ${tx_bouclier}*sommerevenus_bouclier)
gen ratio_bouclier = sommeimpots_bouclier/sommerevenus_bouclier
gen tbouclier = (ratio_bouclier>$tx_bouclier)
gen bouclier_foy = reduc_bouclier_foy

/* Calcul au niveau individuel */
gen rev_bou     = y_irpp + cond(pac==0,(rfin_int_pl_foy + rfin_div_pl_irpp_foy + rfin_int_livret_foy + rfin_int_pel_csg_foy + (rfin_av_csg_foy-rfin_av_imp_foy) + rfin_div_pea_csg_foy)/(1+marie),0)
gen rev_bou_foy = y_irpp_foy + rfin_int_livret_foy + rfin_int_pel_csg_foy + (rfin_av_csg_foy-rfin_av_imp_foy) 
replace rev_bou=0 if rev_bou_foy==0
replace rev_bou_foy=0.01 if rev_bou_foy==0
gen part_bouclier = rev_bou/rev_bou_foy
gen bouclier = reduc_bouclier_foy*part_bouclier


/*
/* 1.4 Calcul du bouclier avec take-up imparfait */
***************************************************

g takeupbouclier = 0
forvalues i=1/7 {
replace takeupbouclier = ${takeupbouclier`i'} if tranche==`i'-1
}

set seed 1234
bys tranche: g uni=uniform() if tbouclier==1

g boucliertaker=(uni<=takeupbouclier)

gen bouclier_foy_reel     = bouclier_foy*boucliertaker
gen bouclier_reel         = bouclier*boucliertaker
*/

/*
/* 1.5 Calage sur tranche d'ISF */
**********************************

gen bouclier_foy_reel_avt_cal     = bouclier_foy_reel
gen bouclier_reel_avt_cal         = bouclier_reel
forvalues i=1/7 {
sum bouclier_foy_reel [w=pondv] if decl == 1 & tranche==`i'-1
global masse_boucl_foy_`i' = r(sum)/1000000000
sum bouclier_reel [w=pondv] if tranche==`i'-1
global masse_boucl_`i' = r(sum)/1000000000
replace bouclier_foy_reel=bouclier_foy_reel*${cout_bouclier_isf`i'}/${masse_boucl_foy_`i'} if tranche==`i'-1
replace bouclier_reel=bouclier_reel*${cout_bouclier_isf`i'}/${masse_boucl_`i'} if tranche==`i'-1
}
*/

/*
/* 1.6 Calage sur masse globale */
**********************************

sum bouclier_foy_reel [w=pondv] if decl == 1
global masse_boucl_foy = r(sum)/1000000000


replace bouclier_foy_reel=bouclier_foy_reel*${cout_bouclier_tot}/${masse_boucl_foy} 

sum bouclier_reel [w=pondv]
global masse_boucl = r(sum)/1000000000

replace bouclier_reel=bouclier_reel*${cout_bouclier_tot}/${masse_boucl} 

*/
}

********************************
/* 2. Années sans le bouclier */
********************************

if $annee<2005 | $annee>2010 {
gen bouclier_foy=0
gen bouclier=0
gen bouclier_foy_reel=0
gen bouclier_reel=0
}


/* Création des labels */
*do "$taxipp\Programmes\Labels\label bouclier_fiscal 0_1.do"

/* Sauvegarde */
sort id_indiv id_foyf
*save "$taxipp\Fichiers simules/$annee\indiv_bouclier_$annee", replace
