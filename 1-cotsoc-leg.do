/*********************************************************************************/
* TAXIPP 0.3 cotsoc_leg.do                                                        *
*                                                                                 *
*   1. Calcul des cotisations sociales sur les revenus d'activit�                 *
*                                                                                 *
* Antoine Bozio 02/2013                                                           *
* Quentin Laff�ter 02/2013                                                        *
/*********************************************************************************/

* Ce dofile calcule les cotisations sociales, salariales et patronales pour les salariés, les 
* non-salari�s et d�tenteurs de revenus de remplacement � partir des variables input suivantes :

global varinput "id_indiv id_foyf id_foys pondv sal_brut public cadre nbh_sal nonsal_brut nbh_nonsal tva taille_ent tx_csp_priv_fac tx_csp_pub_0 chom_brut pension_brut"
*(mettre � jour)
  
	* On supprime les variables de revenu IRPP (pour pouvoir les calculer directement)
	drop sal_h_brut nonsal_h_brut sal_irpp nonsal_irpp pension_irpp chom_irpp
	
	* Salaire horaire brut 
	gen sal_h_brut = sal_brut/nbh_sal
	gen nonsal_h_brut = nonsal_brut/nbh_nonsal
	
***********************************************************************
/*** 1. Calcul des cotisations sociales sur les revenus d'activit� ***/
***********************************************************************
		
	**************************			
	/** 1.1. Secteur priv� **/
	**************************
	
	   	* Hypot�ses:
		* - Les plafonds de S�curit� sociale sont appliqu�s au salaire horaire (calcul� avec la variable EE nbh_sal)
		* - Pas de distinction cadre/non-cadre: taux cadre retenu (d'o� pas de distinction 3PSS)
		* - Pas distinction taux Alsace-Moselle
		* - Accidents du travail aux taux bureaux
		* - On traite séparément les contributions non classées comme cotisations sociales par la CN (voir 2.3)
		
				
/* 1.1.1. Calcul des cotisations sociales salariales */
******************************************************
global pss_h_brut = ${pss_m}/${htp}
		
gen css_ret=0
gen css_cho=0
gen css_nco=0
		
foreach type in cho ret nco { 
	replace css_`type'=${s1prc_`type'}*sal_brut if sal_h_brut<=${pss_h_brut} & public==0 & cadre==1
	replace css_`type'=${s1prc_`type'}*${pss_h_brut}*nbh_sal+${s2prc_`type'}*(sal_brut-${pss_h_brut}*nbh_sal) if sal_h_brut>${pss_h_brut} & sal_h_brut<=4*${pss_h_brut} & public==0 & cadre==1
	replace css_`type'=${s1prc_`type'}*${pss_h_brut}*nbh_sal+${s2prc_`type'}*3*${pss_h_brut}*nbh_sal+${s3prc_`type'}*(sal_brut-4*${pss_h_brut}*nbh_sal) if sal_h_brut>4*${pss_h_brut} & sal_h_brut<=8*${pss_h_brut} & public==0 & cadre==1
	replace css_`type'=${s1prc_`type'}*${pss_h_brut}*nbh_sal+${s2prc_`type'}*3*${pss_h_brut}*nbh_sal+${s3prc_`type'}*4*${pss_h_brut}*nbh_sal+${s4prc_`type'}*(sal_brut-8*${pss_h_brut}*nbh_sal) if sal_h_brut>8*${pss_h_brut} & public==0 & cadre==1
	}
	    
foreach type in cho ret nco { 
	replace css_`type'=${s1prn_`type'}*sal_brut if sal_h_brut<=${pss_h_brut} & public==0 & cadre==0
	replace css_`type'=${s1prn_`type'}*${pss_h_brut}*nbh_sal+${s2prn_`type'}*(sal_brut-${pss_h_brut}*nbh_sal) if sal_h_brut>${pss_h_brut} & sal_h_brut<=4*${pss_h_brut} & public==0 & cadre==0
	replace css_`type'=${s1prn_`type'}*${pss_h_brut}*nbh_sal+${s2prn_`type'}*3*${pss_h_brut}*nbh_sal+${s3prn_`type'}*(sal_brut-4*${pss_h_brut}*nbh_sal) if sal_h_brut>4*${pss_h_brut} & sal_h_brut<=8*${pss_h_brut} & public==0 & cadre==0
	replace css_`type'=${s1prn_`type'}*${pss_h_brut}*nbh_sal+${s2prn_`type'}*3*${pss_h_brut}*nbh_sal+${s3prn_`type'}*4*${pss_h_brut}*nbh_sal+${s4prn_`type'}*(sal_brut-8*${pss_h_brut}*nbh_sal) if sal_h_brut>8*${pss_h_brut} & public==0 & cadre==0
	}
		
gen css = css_ret + css_cho + css_nco
		
/* 1.1.2. Calcul des cotisations sociales patronales */
*******************************************************
				
foreach type in cho ret nco { 
	gen csp_`type'=0
	replace csp_`type'=${p1prc_`type'}*sal_brut if sal_h_brut<${pss_h_brut} & public==0 & cadre==1
	replace csp_`type'=${p1prc_`type'}*nbh_sal*${pss_h_brut}+${p2prc_`type'}*(sal_brut-nbh_sal*${pss_h_brut}) if sal_h_brut>=${pss_h_brut} & sal_h_brut<4*${pss_h_brut} & public==0 & cadre==1
	replace csp_`type'=${p1prc_`type'}*nbh_sal*${pss_h_brut}+${p2prc_`type'}*3*nbh_sal*${pss_h_brut}+${p3prc_`type'}*(sal_brut-4*nbh_sal*${pss_h_brut}) if sal_h_brut>=4*${pss_h_brut} & sal_h_brut<8*${pss_h_brut} & public==0 & cadre==1
	replace csp_`type'=${p1prc_`type'}*nbh_sal*${pss_h_brut}+${p2prc_`type'}*3*nbh_sal*${pss_h_brut}+${p3prc_`type'}*4*nbh_sal*${pss_h_brut}+${p4prc_`type'}*(sal_brut-8*nbh_sal*${pss_h_brut}) if sal_h_brut>=8*${pss_h_brut} & public==0 & cadre==1
	}
        
foreach type in cho ret nco { 
	replace csp_`type'=${p1prn_`type'}*sal_brut if sal_h_brut<${pss_h_brut} & public==0 & cadre==0
	replace csp_`type'=${p1prn_`type'}*nbh_sal*${pss_h_brut}+${p2prn_`type'}*(sal_brut-nbh_sal*${pss_h_brut}) if sal_h_brut>=${pss_h_brut} & sal_h_brut<3*${pss_h_brut} & public==0 & cadre==0
	replace csp_`type'=${p1prn_`type'}*nbh_sal*${pss_h_brut}+${p2prn_`type'}*2*nbh_sal*${pss_h_brut} + ${p3prn_`type'}*(sal_brut-3*nbh_sal*${pss_h_brut}) if sal_h_brut>3*${pss_h_brut} & sal_h_brut<=4*${pss_h_brut} & public==0 & cadre==0
	replace csp_`type'=${p1prn_`type'}*nbh_sal*${pss_h_brut}+${p2prn_`type'}*2*nbh_sal*${pss_h_brut} + ${p3prn_`type'}*nbh_sal*${pss_h_brut} + (sal_brut-4*nbh_sal*${pss_h_brut}) if sal_h_brut>4*${pss_h_brut} & public==0 & cadre==0
	}

gen csp = csp_cho + csp_ret + csp_nco
		
/* 1.1.3. Calcul des abattements de cotisations patronales sur les bas salaires */
**********************************************************************************
		
		* Note: Plusieurs systèmes d'abattement ont été mis en place une même année; il s'agit ici d'une application approximative
		*       Les abattements 35h ne sont notamment pas détaillés.
		*       Les abattements Fillon pour les entreprises de moins de 20 salariés ne sont pas estimés
		*       On utilise la formule des exonérations Fillon plutôt que Aubry II 
		*       La référence est le salaire horaire (calculé à partir du salaire annuel et d'une estimation par EE du nombre annuel d'heures travaillées)
		*       Possible complication avec le niveau du Smic qui a servi à corriger l'estimation des salaires dans la version 0.0 (année 2006 uniquement?)
		
gen tx_exo =0
gen csp_exo = 0

* Exonérations AF (1993-1996)
*foreach smic in 1 2 3 5 6 {
*replace tx_exo = $exo1_`smic' if public==0 & $annee>=1993 & $annee<=1995 & sal_h_brut<=1.`smic'*smic_h_irpp
*}

* Exonération dégressive Juppé (1996-2003)
replace tx_exo = ((0.55*(1.33*${smic_h} - sal_h_brut)))/sal_h_brut   if ${annee_sim}>=1996 & ${annee_sim}<=1999  & sal_h_brut > ${smic_h} & sal_h_brut<=1.33*${smic_h}
replace tx_exo = 0.182                                               if ${annee_sim}>=1996 & ${annee_sim}<=1999  & sal_h_brut <= ${smic_h}

* Exonérations Aubry II (2000-2002)
*replace tx_exo = (($aubryII1*smic_h_irpp/sal_h_brut) - $aubryII2)/sal_brut if $annee>=2000 & $annee<=2002

* Exonérations Fillon (2003-2012)
replace tx_exo = (0.26/0.6)*(max(1.6*(${smic_h}/sal_h_brut)-1,0)) if public==0 & ${annee_sim}>= 2000 
				
replace csp_exo = tx_exo*sal_brut if public==0
		
/* 1.1.4. Estimation des cotisations patronales facultatives du secteur privé */
********************************************************************************
				
gen csp_fac = 0
replace csp_fac = tx_csp_priv_fac*sal_brut if public==0
		

***************************	
/** 1.2. Secteur public **/
***************************
	
		* Hypothèses:
		* - On impute des primes moyennes proportionnelles
		* - Fonctionnaire est titulaire de l'Etat
						
/* 1.2.1. Calcul des cotisations sociales salariales */
*******************************************************
		
replace css_ret = ${st_ret}*(1-${tx_primes})*sal_brut 
		
replace css_nco = ${st_nco}*sal_brut                if sal_brut<= ${fds_seuil} & public==1
replace css_nco = (${st_nco} + ${fds_s_0_4})*sal_brut if sal_brut> ${fds_seuil} & sal_h_brut<=4*${pss_h_brut} & public==1
replace css_nco = ${st_nco}*sal_brut                if sal_h_brut>4*${pss_h_brut} & public==1
	
replace css = css_ret + css_nco if public==1
		
/* 1.2.2. Estimation des cotisations patronales secteur public */
*****************************************************************
		
replace csp     = tx_csp_pub_0*sal_brut if public==1 
replace csp_ret = (${pt_ret}/${pt})*csp if public==1  
replace csp_nco = (${pt_nco}/${pt})*csp if public==1  
	

*******************************************************************
/** 1.3. Calcul des impôts sur les salaires et la main d'oeuvre **/
*******************************************************************
	
	* Notes: ces taxes correspondent à l'ensemble des contributions sur les salaires que la CN classe en D291 ainsi que les contributions pour 
	*        l'effort de construction qui sont classées en D993.
	
	
	* Taxe sur les salaires (pour les entreprises non assujeties à la TVA)
	gen ts = 0
	replace ts = ${taxsal1}*sal_brut if tva==0
	replace ts = ts + ${taxsal_maj1}*(sal_brut-${taxsal_plaf1}) if sal_brut>=${taxsal_plaf1} & sal_brut < ${taxsal_plaf2} & tva==0
	replace ts = ts + ${taxsal_maj1}*(${taxsal_plaf2}-${taxsal_plaf1}) + ${taxsal_maj2}*(sal_brut-${taxsal_plaf2}) if sal_brut>=${taxsal_plaf2} & tva==0
		
	* Versement transport (taux de Lyon)
	gen vt = ${vt_lyon}*sal_brut
	
	* FNAL, CSA, taxe d'apprentissage, formation continue
	gen mo = 0
	replace mo     = ${ts_20_0_1}*sal_brut if (sal_h_brut <${pss_h_brut} & taille_ent==20)
	replace mo = ${ts_20_1_}*sal_brut if (sal_h_brut >= ${pss_h_brut} & taille_ent==20)
	
	* Total des taxes sur les salaires et la main d'oeuvre
	gen tsmo = ts + vt + mo
	

*************************	 
/** 1.4. Non-salariés **/
*************************
				
/* 1.4.1. Cotisations des non-salariés */
****************************************
		
gen cs_nonsal =${tx_cs_nonsal_0}*nonsal_brut
	
gen cs_nonsal_contr=0
replace cs_nonsal_contr=${tx_cs_nonsal_contr_0}*nonsal_brut                                                                         if nonsal_h_brut<=$pss_h_brut & nonsal_brut>0
replace cs_nonsal_contr=$tx_cs_nonsal_contr_0*$pss_h_brut*nbh_nonsal+$tx_cs_nonsal_contr_pss*(nonsal_brut-$pss_h_brut*nbh_nonsal) if nonsal_h_brut>$pss_h_brut & nonsal_h_brut<=4*$pss_h_brut & nonsal_brut>0
replace cs_nonsal_contr=$tx_cs_nonsal_contr_0*$pss_h_brut*nbh_nonsal+$tx_cs_nonsal_contr_pss*3*$pss_h_brut*nbh_nonsal+$tx_cs_nonsal_contr_4pss*(nonsal_brut-4*$pss_h_brut*nbh_nonsal) if nonsal_h_brut>4*$pss_h_brut & nonsal_brut>0 
		
gen cs_nonsal_noncontr=0
replace cs_nonsal_noncontr=$tx_cs_nonsal_noncontr_0*nonsal_brut if nonsal_h_brut<=$pss_h_brut & nonsal_brut>0
replace cs_nonsal_noncontr=$tx_cs_nonsal_noncontr_0*$pss_h_brut*nbh_nonsal+$tx_cs_nonsal_noncontr_pss*(nonsal_brut-$pss_h_brut*nbh_nonsal) if nonsal_h_brut>$pss_h_brut & nonsal_h_brut<=4*$pss_h_brut & nonsal_brut>0
replace cs_nonsal_noncontr=$tx_cs_nonsal_noncontr_0*$pss_h_brut*nbh_nonsal+$tx_cs_nonsal_noncontr_pss*3*$pss_h_brut*nbh_nonsal+$tx_cs_nonsal_noncontr_4pss*(nonsal_brut-4*$pss_h_brut*nbh_nonsal) if nonsal_h_brut>4*$pss_h_brut & nonsal_brut>0 
		
************************************************************
/** 2. Calcul de la CSG-CRDS pour les revenus d'activité **/
************************************************************
	
	/* 2.1 CSG et CRDS (salariés public et privé) */
	************************************************
		
gen csg_sal     = 0
replace csg_sal = ${csg_act}*(1-${csg_abt_0_4})*sal_brut if sal_h_brut<=4*$pss_h_brut
replace csg_sal = ${csg_act}*(1-${csg_abt_4_})*sal_brut if sal_h_brut>4*$pss_h_brut
		
gen csg_sal_ded     = 0
replace csg_sal_ded = ${csg_act_ded}*(1-${csg_abt_0_4})*sal_brut if sal_h_brut<=4*${pss_h_brut}
replace csg_sal_ded = ${csg_act_ded}*(1-${csg_abt_4_})*sal_brut if sal_h_brut>4*${pss_h_brut}
		
gen crds_sal     = 0
replace crds_sal = ${crds}*(1-${csg_abt_0_4})*sal_brut if sal_h_brut<=4*$pss_h_brut
replace crds_sal = ${crds}*(1-${csg_abt_4_})*sal_brut if sal_h_brut>4*$pss_h_brut
		
	/* 2.2 CSG/CRDS des non-salariés */
	***********************************	
		
gen csg_nonsal     = 0
replace csg_nonsal = ${csg_act}*(1-${csg_abt_0_4})*nonsal_brut if nonsal_h_brut<=4*$pss_h_brut
replace csg_nonsal = ${csg_act}*(1-${csg_abt_4_})*nonsal_brut if nonsal_h_brut>4*$pss_h_brut
		
gen csg_nonsal_ded     = 0
replace csg_nonsal_ded = ${csg_act_ded}*(1-${csg_abt_0_4})*nonsal_brut if nonsal_h_brut<=4*$pss_h_brut
replace csg_nonsal_ded = ${csg_act_ded}*(1-${csg_abt_4_})*nonsal_brut if nonsal_h_brut>4*$pss_h_brut
		
gen crds_nonsal = 0
replace crds_nonsal = ${crds}*(1-${csg_abt_0_4})*nonsal_brut if nonsal_h_brut<=4*$pss_h_brut
replace crds_nonsal = ${crds}*(1-${csg_abt_4_})*nonsal_brut if nonsal_h_brut>4*$pss_h_brut
	
		
*******************************************************************
/*** 3. Calcul de la CSG-CRDS pour les revenus de remplacement ***/
*******************************************************************
	
		* CSG et CRDS sur pensions
	gen csg_pens     = 0 if pension_brut==0 | rfr_irpp_foy_N2 <= ${seuil_exo_tf_th}+2*(nbp-1)*${seuil_exo_tf_th_demipart}
	replace csg_pens = ${csg_pens_red}*pension_brut if rfr_irpp_foy_N2 > ${seuil_exo_tf_th}+2*(nbp-1)*${seuil_exo_tf_th_demipart} & irpp_net_foy_N2 <= 0
	replace csg_pens = ${csg_pens}*pension_brut if rfr_irpp_foy_N2 > ${seuil_exo_tf_th}+2*(nbp-1)*${seuil_exo_tf_th_demipart} & irpp_net_foy_N2 > 0
		
	gen csg_pens_ded     = 0 if pension_brut==0 | rfr_irpp_foy_N2 <= ${seuil_exo_tf_th}+2*(nbp-1)*${seuil_exo_tf_th_demipart}
	replace csg_pens_ded = csg_pens if rfr_irpp_foy_N2 > ${seuil_exo_tf_th}+2*(nbp-1)*${seuil_exo_tf_th_demipart} & irpp_net_foy_N2 <= 0
	replace csg_pens_ded = ${csg_pens_ded}*pension_brut if rfr_irpp_foy_N2 > ${seuil_exo_tf_th}+2*(nbp-1)*${seuil_exo_tf_th_demipart} & irpp_net_foy_N2 > 0
		
	gen crds_pens = 0
	replace crds_pens = ${crds}*pension_brut if rfr_irpp_foy_N2 > ${seuil_exo_tf_th}+2*(nbp-1)*${seuil_exo_tf_th_demipart}

		* CSG et CRDS sur allocations chômages 
	gen csg_chom = 0 if chom_brut==0 | rfr_irpp_foy_N2 <= ${seuil_exo_tf_th}+2*(nbp-1)*${seuil_exo_tf_th_demipart}
	replace csg_chom = ${csg_cho_ded}*chom_brut if rfr_irpp_foy_N2 > ${seuil_exo_tf_th}+2*(nbp-1)*${seuil_exo_tf_th_demipart} & irpp_net_foy_N2 <= 0
	replace csg_chom = ${csg_cho}*chom_brut if rfr_irpp_foy_N2 > ${seuil_exo_tf_th}+2*(nbp-1)*${seuil_exo_tf_th_demipart} & irpp_net_foy_N2 > 0
		
	gen csg_chom_ded     = 0 if chom_brut==0 | rfr_irpp_foy_N2 <= ${seuil_exo_tf_th}+2*(nbp-1)*${seuil_exo_tf_th_demipart}
	replace csg_chom_ded = csg_chom if rfr_irpp_foy_N2 > ${seuil_exo_tf_th}+2*(nbp-1)*${seuil_exo_tf_th_demipart} & irpp_net_foy_N2 <= 0
	replace csg_chom_ded = ${csg_cho}*chom_brut if rfr_irpp_foy_N2 > ${seuil_exo_tf_th}+2*(nbp-1)*${seuil_exo_tf_th_demipart} & irpp_net_foy_N2 > 0
		
	gen crds_chom     = 0
	replace crds_chom = ${crds}*chom_brut if rfr_irpp_foy_N2 > ${seuil_exo_tf_th}+2*(nbp-1)*${seuil_exo_tf_th_demipart}
			
	replace csg_chom = 0 if csg_chom ==.
	replace csg_pens = 0 if csg_chom ==.
	replace csg_chom_ded = 0 if csg_chom ==.
	replace csg_pens_ded = 0 if csg_chom ==.
		
****************************************	 
/*** 4. Calcul de variables finales ***/
****************************************		

	/* 4.1 Salaires super-bruts  */
	*******************************
	gen sal_superbrut = sal_brut + csp + csp_fac + tsmo - csp_exo
		
	/* 4.2 Revenus nets  */
	***********************
	gen pension_net = pension_brut - csg_pens - crds_pens
	gen chom_net = chom_brut - csg_chom - crds_chom
	gen sal_net = sal_brut - css - csg_sal - crds_sal
	gen nonsal_net = nonsal_brut - cs_nonsal - csg_nonsal - crds_nonsal
	
	/* 4.3 Revenus imposables à l'IRPP  */
	******************************************************
	gen pension_irpp = pension_brut - csg_pens_ded
	gen chom_irpp    = chom_brut    - csg_chom_ded
	gen sal_irpp     = sal_brut     - csg_sal_ded    - css
	gen nonsal_irpp  = nonsal_brut  - csg_nonsal_ded - cs_nonsal 

	/* 4.4 Variables agrégées de revenus */
	***************************************
	
		* Besoin de déduire les variables _conj et _pac de la liste.
	global variables "sal_irpp nonsal_irpp pension_irpp chom_irpp sal_net nonsal_net pension_net chom_net"
	drop sal_irpp_foy nonsal_irpp_foy pension_irpp_foy chom_irpp_foy
	global exist_foy 0
	global exist_conj 0
	global exist_pac 0
	do "$dofiles\variables foyer fiscal.do"
	
	gen yr_irpp = pension_irpp + chom_irpp
	gen yr_irpp_conj = pension_irpp_conj + chom_irpp_conj
	gen yr_irpp_pac = pension_irpp_pac + chom_irpp_pac
	gen yr_irpp_foy = yr_irpp + yr_irpp_conj + yr_irpp_pac
	
	gen yr_net = pension_net + chom_net
	gen yr_net_conj = pension_net_conj + chom_net_conj
	gen yr_net_pac = pension_net_pac + chom_net_pac
	gen yr_net_foy = yr_net + yr_net_conj + yr_net_pac

	gen yr_brut = pension_brut + chom_brut
	gen yr_brut_conj = pension_brut_conj + chom_brut_conj
	gen yr_brut_pac = pension_brut_pac + chom_brut_pac
	gen yr_brut_foy = yr_brut + yr_brut_conj + yr_brut_pac
	
	gen ya_irpp = sal_irpp + nonsal_irpp
	gen ya_irpp_conj = sal_irpp_conj + nonsal_irpp_conj
	gen ya_irpp_pac = sal_irpp_pac + nonsal_irpp_pac
	gen ya_irpp_foy = ya_irpp + ya_irpp_conj + ya_irpp_pac
	
	gen ya_net = sal_net + nonsal_net
	gen ya_net_conj = sal_net_conj + nonsal_net_conj
	gen ya_net_pac = sal_net_pac + nonsal_net_pac
	gen ya_net_foy = ya_net + ya_net_conj + ya_net_pac

	gen ya_brut = sal_net + nonsal_net
	gen ya_brut_conj = sal_net_conj + nonsal_net_conj
	gen ya_brut_pac = sal_net_pac + nonsal_net_pac
	gen ya_brut_foy = ya_net + ya_net_conj + ya_net_pac

gen crds_yr = crds_pens + crds_chom
gen csg_yr = csg_pens + csg_chom	
gen crds_ya = crds_sal + crds_nonsal
gen csg_ya = csg_sal + csg_nonsal	

bys id_foyf : egen crds_yr_foy = total(crds_yr)
bys id_foyf : egen crds_ya_foy = total(crds_ya)
bys id_foyf : egen csg_yr_foy = total(csg_yr)
bys id_foyf : egen csg_ya_foy = total(csg_ya)
